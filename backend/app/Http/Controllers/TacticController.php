<?php

namespace App\Http\Controllers;

use App\Models\Tactic;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TacticController extends Controller
{
    /**
     * GET /api/v1/tactics — list all (live) tactics for the user.
     */
    public function index(Request $request): JsonResponse
    {
        $userId = $request->attributes->get('auth_user_id');
        $sportType = $request->query('sport_type');

        $query = Tactic::where('user_id', $userId);
        if ($sportType) {
            $query->where('sport_type', $sportType);
        }

        $tactics = $query->orderBy('updated_at', 'desc')->get()->map(fn ($t) => [
            'id' => $t->id,
            'name' => $t->name,
            'sport_type' => $t->sport_type,
            'updated_at' => $t->updated_at->toIso8601String(),
            'client_updated_at' => $t->client_updated_at?->toIso8601String(),
        ]);

        return response()->json(['status' => 'ok', 'tactics' => $tactics]);
    }

    /**
     * GET /api/v1/tactics/{id}
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $userId = $request->attributes->get('auth_user_id');
        $tactic = Tactic::where('id', $id)->where('user_id', $userId)->first();

        if (!$tactic) {
            return response()->json(['error' => 'Not found'], 404);
        }

        return response()->json([
            'status' => 'ok',
            'tactic' => [
                'id' => $tactic->id,
                'name' => $tactic->name,
                'sport_type' => $tactic->sport_type,
                'data' => $tactic->data,
                'updated_at' => $tactic->updated_at->toIso8601String(),
                'client_updated_at' => $tactic->client_updated_at?->toIso8601String(),
            ],
        ]);
    }

    /**
     * POST /api/v1/tactics — upsert one tactic, with LWW conflict gate.
     *
     * Returns 200/201 on accept, 409 on conflict with the current server copy
     * so the client can overwrite its local state.
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

        $existing = Tactic::withTrashed()
            ->where('user_id', $userId)
            ->where('sport_type', $request->input('sport_type'))
            ->where('name', $request->input('name'))
            ->first();

        $gate = $this->conflictGate($existing, $incoming);
        if ($gate === 'reject') {
            return response()->json([
                'status' => 'conflict',
                'tactic' => $this->serializeForConflict($existing),
            ], 409);
        }

        $tactic = $this->upsertRow(
            $existing,
            $userId,
            $request->input('name'),
            $request->input('sport_type'),
            $request->input('data'),
            $incoming,
        );

        return response()->json([
            'status' => 'ok',
            'tactic' => [
                'id' => $tactic->id,
                'name' => $tactic->name,
                'sport_type' => $tactic->sport_type,
                'updated_at' => $tactic->updated_at->toIso8601String(),
                'client_updated_at' => $tactic->client_updated_at?->toIso8601String(),
            ],
        ], $tactic->wasRecentlyCreated ? 201 : 200);
    }

    /**
     * POST /api/v1/tactics/sync — batch upsert. Per-item conflict gate; rows
     * the server has a newer copy of are returned in `conflicts[]` so the
     * client can reconcile without aborting the whole push.
     */
    public function sync(Request $request): JsonResponse
    {
        $request->validate([
            'tactics' => 'required|array',
            'tactics.*.name' => 'required|string',
            'tactics.*.sport_type' => 'required|string',
            'tactics.*.data' => 'required|array',
            'tactics.*.client_updated_at' => 'nullable|date',
        ]);

        $userId = $request->attributes->get('auth_user_id');
        $accepted = 0;
        $conflicts = [];

        foreach ($request->input('tactics') as $t) {
            $incoming = $this->parseClientTs($t['client_updated_at'] ?? null);
            $existing = Tactic::withTrashed()
                ->where('user_id', $userId)
                ->where('sport_type', $t['sport_type'])
                ->where('name', $t['name'])
                ->first();

            $gate = $this->conflictGate($existing, $incoming);
            if ($gate === 'reject') {
                $conflicts[] = $this->serializeForConflict($existing);
                continue;
            }

            $this->upsertRow(
                $existing,
                $userId,
                $t['name'],
                $t['sport_type'],
                $t['data'],
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
     * DELETE /api/v1/tactics/{id} — soft delete.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $userId = $request->attributes->get('auth_user_id');
        $tactic = Tactic::where('id', $id)->where('user_id', $userId)->first();

        if (!$tactic) {
            return response()->json(['error' => 'Not found'], 404);
        }

        $tactic->client_updated_at = Carbon::now();
        $tactic->save();
        $tactic->delete();
        return response()->json(['status' => 'ok']);
    }

    /**
     * DELETE /api/v1/tactics — soft delete by name+sport_type.
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

        $row = Tactic::withTrashed()
            ->where('user_id', $userId)
            ->where('name', $request->input('name'))
            ->where('sport_type', $request->input('sport_type'))
            ->first();

        if (!$row) {
            return response()->json(['status' => 'ok', 'deleted' => 0]);
        }

        // If server has a live row written AFTER the client's delete, keep it
        // (another device edited more recently than this device's delete).
        if (!$row->trashed()
            && $row->client_updated_at
            && $row->client_updated_at->gt($incoming)) {
            return response()->json([
                'status' => 'conflict',
                'tactic' => $this->serializeForConflict($row),
            ], 409);
        }

        $row->client_updated_at = $incoming;
        $row->save();
        $row->delete();
        return response()->json(['status' => 'ok', 'deleted' => 1]);
    }

    /**
     * GET /api/v1/tactics/pull — full data sync. Includes tombstones so the
     * client can delete locally; callers filter by `since` to keep it cheap.
     */
    public function pull(Request $request): JsonResponse
    {
        $userId = $request->attributes->get('auth_user_id');
        $since = $request->query('since');

        $query = Tactic::withTrashed()->where('user_id', $userId);
        if ($since) {
            $query->where(function ($q) use ($since) {
                $q->where('updated_at', '>', $since)
                  ->orWhere('deleted_at', '>', $since);
            });
        }

        $tactics = $query->get()->map(fn ($t) => [
            'id' => $t->id,
            'name' => $t->name,
            'sport_type' => $t->sport_type,
            'data' => $t->trashed() ? null : $t->data,
            'updated_at' => $t->updated_at->toIso8601String(),
            'client_updated_at' => $t->client_updated_at?->toIso8601String(),
            'deleted_at' => $t->deleted_at?->toIso8601String(),
        ]);

        return response()->json([
            'status' => 'ok',
            'server_time' => now()->toIso8601String(),
            'tactics' => $tactics,
        ]);
    }

    public function health(): JsonResponse
    {
        return response()->json(['status' => 'ok', 'timestamp' => now()->toIso8601String()]);
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

    /**
     * Decide what to do with an incoming write:
     *   - 'accept' — write (new row or overwrite live row)
     *   - 'reject' — server has a strictly newer copy (or a newer tombstone),
     *     incoming should be dropped and the client told to reconcile.
     */
    private function conflictGate(?Tactic $existing, ?Carbon $incoming): string
    {
        if (!$existing) return 'accept';

        if ($existing->trashed()) {
            // Tombstone present. Without a client timestamp we can't prove
            // the push is newer than the delete, so keep the tomb — this also
            // stops legacy clients (pre-sync-column rollout) from silently
            // resurrecting rows the user just deleted on another device.
            if (!$incoming) return 'reject';
            $tomb = $existing->deleted_at;
            if ($tomb && $incoming->lte($tomb)) return 'reject';
            return 'accept';
        }

        if (!$existing->client_updated_at || !$incoming) {
            // Legacy row with no timestamp — fall back to last-write-wins.
            return 'accept';
        }
        if ($existing->client_updated_at->gt($incoming)) {
            return 'reject';
        }
        return 'accept';
    }

    private function upsertRow(
        ?Tactic $existing,
        int $userId,
        string $name,
        string $sportType,
        array $data,
        ?Carbon $clientTs,
    ): Tactic {
        if ($existing) {
            if ($existing->trashed()) {
                $existing->deleted_at = null;
            }
            $existing->data = $data;
            if ($clientTs) $existing->client_updated_at = $clientTs;
            $existing->save();
            return $existing;
        }

        return Tactic::create([
            'user_id' => $userId,
            'name' => $name,
            'sport_type' => $sportType,
            'data' => $data,
            'client_updated_at' => $clientTs,
        ]);
    }

    private function serializeForConflict(?Tactic $row): ?array
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
