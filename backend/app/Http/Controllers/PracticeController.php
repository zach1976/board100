<?php

namespace App\Http\Controllers;

use App\Models\Practice;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PracticeController extends Controller
{
    /**
     * GET /api/v1/practices — list (metadata only, live rows).
     */
    public function index(Request $request): JsonResponse
    {
        $userId = $request->attributes->get('auth_user_id');
        $sportType = $request->query('sport_type');

        $query = Practice::where('user_id', $userId);
        if ($sportType) {
            $query->where('sport_type', $sportType);
        }

        $practices = $query->orderBy('updated_at', 'desc')->get()->map(fn ($p) => [
            'id' => $p->id,
            'name' => $p->name,
            'sport_type' => $p->sport_type,
            'updated_at' => $p->updated_at->toIso8601String(),
            'client_updated_at' => $p->client_updated_at?->toIso8601String(),
        ]);

        return response()->json(['status' => 'ok', 'practices' => $practices]);
    }

    /**
     * GET /api/v1/practices/pull — full data, includes tombstones.
     */
    public function pull(Request $request): JsonResponse
    {
        $userId = $request->attributes->get('auth_user_id');
        $sportType = $request->query('sport_type');
        $since = $request->query('since');

        $query = Practice::withTrashed()->where('user_id', $userId);
        if ($sportType) {
            $query->where('sport_type', $sportType);
        }
        if ($since) {
            $query->where(function ($q) use ($since) {
                $q->where('updated_at', '>', $since)
                  ->orWhere('deleted_at', '>', $since);
            });
        }

        $practices = $query->get()->map(fn ($p) => [
            'id' => $p->id,
            'name' => $p->name,
            'sport_type' => $p->sport_type,
            'data' => $p->trashed() ? null : $p->data,
            'updated_at' => $p->updated_at->toIso8601String(),
            'client_updated_at' => $p->client_updated_at?->toIso8601String(),
            'deleted_at' => $p->deleted_at?->toIso8601String(),
        ]);

        return response()->json([
            'status' => 'ok',
            'server_time' => now()->toIso8601String(),
            'practices' => $practices,
        ]);
    }

    /**
     * POST /api/v1/practices — upsert one plan, LWW conflict gate.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'sport_type' => 'required|string|max:50',
            'data' => 'required|array',
            'client_updated_at' => 'nullable|date',
        ]);

        $userId = $request->attributes->get('auth_user_id');
        $incoming = $this->parseClientTs($request->input('client_updated_at'));

        $existing = Practice::withTrashed()
            ->where('user_id', $userId)
            ->where('sport_type', $request->input('sport_type'))
            ->where('name', $request->input('name'))
            ->first();

        $gate = $this->conflictGate($existing, $incoming);
        if ($gate === 'reject') {
            return response()->json([
                'status' => 'conflict',
                'practice' => $this->serializeForConflict($existing),
            ], 409);
        }

        $practice = $this->upsertRow(
            $existing,
            $userId,
            $request->input('name'),
            $request->input('sport_type'),
            $request->input('data'),
            $incoming,
        );

        return response()->json([
            'status' => 'ok',
            'practice' => [
                'id' => $practice->id,
                'name' => $practice->name,
                'sport_type' => $practice->sport_type,
                'updated_at' => $practice->updated_at->toIso8601String(),
                'client_updated_at' => $practice->client_updated_at?->toIso8601String(),
            ],
        ], $practice->wasRecentlyCreated ? 201 : 200);
    }

    /**
     * POST /api/v1/practices/sync — batch upsert with per-item conflict gate.
     */
    public function sync(Request $request): JsonResponse
    {
        $request->validate([
            'practices' => 'required|array',
            'practices.*.name' => 'required|string',
            'practices.*.sport_type' => 'required|string',
            'practices.*.data' => 'required|array',
            'practices.*.client_updated_at' => 'nullable|date',
        ]);

        $userId = $request->attributes->get('auth_user_id');
        $accepted = 0;
        $conflicts = [];

        foreach ($request->input('practices') as $p) {
            $incoming = $this->parseClientTs($p['client_updated_at'] ?? null);
            $existing = Practice::withTrashed()
                ->where('user_id', $userId)
                ->where('sport_type', $p['sport_type'])
                ->where('name', $p['name'])
                ->first();

            $gate = $this->conflictGate($existing, $incoming);
            if ($gate === 'reject') {
                $conflicts[] = $this->serializeForConflict($existing);
                continue;
            }

            $this->upsertRow(
                $existing,
                $userId,
                $p['name'],
                $p['sport_type'],
                $p['data'],
                $incoming,
            );
            $accepted++;
        }

        return response()->json([
            'status' => 'ok',
            'accepted' => $accepted,
            'synced' => $accepted,
            'conflicts' => $conflicts,
        ]);
    }

    /**
     * DELETE /api/v1/practices — soft delete by name+sport_type.
     */
    public function destroyByName(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string',
            'sport_type' => 'required|string',
            'client_updated_at' => 'nullable|date',
        ]);

        $userId = $request->attributes->get('auth_user_id');
        $incoming = $this->parseClientTs($request->input('client_updated_at'))
            ?? Carbon::now();

        $row = Practice::withTrashed()
            ->where('user_id', $userId)
            ->where('name', $request->input('name'))
            ->where('sport_type', $request->input('sport_type'))
            ->first();

        if (!$row) {
            return response()->json(['status' => 'ok', 'deleted' => 0]);
        }

        if (!$row->trashed()
            && $row->client_updated_at
            && $row->client_updated_at->gt($incoming)) {
            return response()->json([
                'status' => 'conflict',
                'practice' => $this->serializeForConflict($row),
            ], 409);
        }

        $row->client_updated_at = $incoming;
        $row->save();
        $row->delete();
        return response()->json(['status' => 'ok', 'deleted' => 1]);
    }

    // ─── internal ──────────────────────────────────────────────────────

    private function parseClientTs($raw): ?Carbon
    {
        if (!$raw) return null;
        try {
            return Carbon::parse($raw);
        } catch (\Throwable $e) {
            return null;
        }
    }

    private function conflictGate(?Practice $existing, ?Carbon $incoming): string
    {
        if (!$existing) return 'accept';

        if ($existing->trashed()) {
            // Tombstone present. Without a client timestamp we can't prove
            // the push is newer than the delete, so keep the tomb — also
            // stops legacy clients (pre-sync-column rollout) from silently
            // resurrecting rows the user just deleted on another device.
            if (!$incoming) return 'reject';
            $tomb = $existing->deleted_at;
            if ($tomb && $incoming->lte($tomb)) return 'reject';
            return 'accept';
        }

        if (!$existing->client_updated_at || !$incoming) {
            return 'accept';
        }
        if ($existing->client_updated_at->gt($incoming)) {
            return 'reject';
        }
        return 'accept';
    }

    private function upsertRow(
        ?Practice $existing,
        int $userId,
        string $name,
        string $sportType,
        array $data,
        ?Carbon $clientTs,
    ): Practice {
        if ($existing) {
            if ($existing->trashed()) {
                $existing->deleted_at = null;
            }
            $existing->data = $data;
            if ($clientTs) $existing->client_updated_at = $clientTs;
            $existing->save();
            return $existing;
        }

        return Practice::create([
            'user_id' => $userId,
            'name' => $name,
            'sport_type' => $sportType,
            'data' => $data,
            'client_updated_at' => $clientTs,
        ]);
    }

    private function serializeForConflict(?Practice $row): ?array
    {
        if (!$row) return null;
        return [
            'id' => $row->id,
            'name' => $row->name,
            'sport_type' => $row->sport_type,
            'data' => $row->trashed() ? null : $row->data,
            'updated_at' => $row->updated_at->toIso8601String(),
            'client_updated_at' => $row->client_updated_at?->toIso8601String(),
            'deleted_at' => $row->deleted_at?->toIso8601String(),
        ];
    }
}
