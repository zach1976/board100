<?php

namespace App\Http\Controllers;

use App\Models\Tactic;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TacticController extends Controller
{
    /**
     * GET /api/v1/tactics — list all tactics for the user
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
        ]);

        return response()->json(['status' => 'ok', 'tactics' => $tactics]);
    }

    /**
     * GET /api/v1/tactics/{id} — get a single tactic with full data
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
            ],
        ]);
    }

    /**
     * POST /api/v1/tactics — create or update a tactic (upsert by name + sport_type)
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'sport_type' => 'required|string|max:50',
            'data' => 'required|array',
        ]);

        $userId = $request->attributes->get('auth_user_id');

        $tactic = Tactic::updateOrCreate(
            [
                'user_id' => $userId,
                'name' => $request->input('name'),
                'sport_type' => $request->input('sport_type'),
            ],
            [
                'data' => $request->input('data'),
            ]
        );

        return response()->json([
            'status' => 'ok',
            'tactic' => [
                'id' => $tactic->id,
                'name' => $tactic->name,
                'sport_type' => $tactic->sport_type,
                'updated_at' => $tactic->updated_at->toIso8601String(),
            ],
        ], $tactic->wasRecentlyCreated ? 201 : 200);
    }

    /**
     * DELETE /api/v1/tactics/{id}
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $userId = $request->attributes->get('auth_user_id');
        $tactic = Tactic::where('id', $id)->where('user_id', $userId)->first();

        if (!$tactic) {
            return response()->json(['error' => 'Not found'], 404);
        }

        $tactic->delete();
        return response()->json(['status' => 'ok']);
    }

    /**
     * DELETE /api/v1/tactics — delete by name + sport_type (query params)
     */
    public function destroyByName(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string',
            'sport_type' => 'required|string',
        ]);

        $userId = $request->attributes->get('auth_user_id');
        $deleted = Tactic::where('user_id', $userId)
            ->where('name', $request->input('name'))
            ->where('sport_type', $request->input('sport_type'))
            ->delete();

        return response()->json(['status' => 'ok', 'deleted' => $deleted]);
    }

    /**
     * POST /api/v1/tactics/sync — push all tactics (batch upsert)
     */
    public function sync(Request $request): JsonResponse
    {
        $request->validate([
            'tactics' => 'required|array',
            'tactics.*.name' => 'required|string',
            'tactics.*.sport_type' => 'required|string',
            'tactics.*.data' => 'required|array',
        ]);

        $userId = $request->attributes->get('auth_user_id');
        $count = 0;

        foreach ($request->input('tactics') as $t) {
            Tactic::updateOrCreate(
                [
                    'user_id' => $userId,
                    'name' => $t['name'],
                    'sport_type' => $t['sport_type'],
                ],
                [
                    'data' => $t['data'],
                ]
            );
            $count++;
        }

        return response()->json(['status' => 'ok', 'synced' => $count]);
    }

    /**
     * GET /api/v1/tactics/pull — pull all tactics for cross-device sync
     */
    public function pull(Request $request): JsonResponse
    {
        $userId = $request->attributes->get('auth_user_id');
        $since = $request->query('since');

        $query = Tactic::where('user_id', $userId);
        if ($since) {
            $query->where('updated_at', '>', $since);
        }

        $tactics = $query->get()->map(fn ($t) => [
            'id' => $t->id,
            'name' => $t->name,
            'sport_type' => $t->sport_type,
            'data' => $t->data,
            'updated_at' => $t->updated_at->toIso8601String(),
        ]);

        return response()->json([
            'status' => 'ok',
            'server_time' => now()->toIso8601String(),
            'tactics' => $tactics,
        ]);
    }

    /**
     * GET /health
     */
    public function health(): JsonResponse
    {
        return response()->json(['status' => 'ok', 'timestamp' => now()->toIso8601String()]);
    }
}
