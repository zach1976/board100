<?php

namespace App\Http\Controllers;

use App\Models\Practice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PracticeController extends Controller
{
    /**
     * GET /api/v1/practices — list (metadata only)
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
        ]);

        return response()->json(['status' => 'ok', 'practices' => $practices]);
    }

    /**
     * GET /api/v1/practices/pull — pull all with full data
     */
    public function pull(Request $request): JsonResponse
    {
        $userId = $request->attributes->get('auth_user_id');
        $sportType = $request->query('sport_type');
        $since = $request->query('since');

        $query = Practice::where('user_id', $userId);
        if ($sportType) {
            $query->where('sport_type', $sportType);
        }
        if ($since) {
            $query->where('updated_at', '>', $since);
        }

        $practices = $query->get()->map(fn ($p) => [
            'id' => $p->id,
            'name' => $p->name,
            'sport_type' => $p->sport_type,
            'data' => $p->data,
            'updated_at' => $p->updated_at->toIso8601String(),
        ]);

        return response()->json([
            'status' => 'ok',
            'server_time' => now()->toIso8601String(),
            'practices' => $practices,
        ]);
    }

    /**
     * POST /api/v1/practices — upsert one plan
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'sport_type' => 'required|string|max:50',
            'data' => 'required|array',
        ]);

        $userId = $request->attributes->get('auth_user_id');

        $practice = Practice::updateOrCreate(
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
            'practice' => [
                'id' => $practice->id,
                'name' => $practice->name,
                'sport_type' => $practice->sport_type,
                'updated_at' => $practice->updated_at->toIso8601String(),
            ],
        ], $practice->wasRecentlyCreated ? 201 : 200);
    }

    /**
     * POST /api/v1/practices/sync — batch upsert
     */
    public function sync(Request $request): JsonResponse
    {
        $request->validate([
            'practices' => 'required|array',
            'practices.*.name' => 'required|string',
            'practices.*.sport_type' => 'required|string',
            'practices.*.data' => 'required|array',
        ]);

        $userId = $request->attributes->get('auth_user_id');
        $count = 0;

        foreach ($request->input('practices') as $p) {
            Practice::updateOrCreate(
                [
                    'user_id' => $userId,
                    'name' => $p['name'],
                    'sport_type' => $p['sport_type'],
                ],
                [
                    'data' => $p['data'],
                ]
            );
            $count++;
        }

        return response()->json(['status' => 'ok', 'synced' => $count]);
    }

    /**
     * DELETE /api/v1/practices — delete by name + sport_type
     */
    public function destroyByName(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string',
            'sport_type' => 'required|string',
        ]);

        $userId = $request->attributes->get('auth_user_id');
        $deleted = Practice::where('user_id', $userId)
            ->where('name', $request->input('name'))
            ->where('sport_type', $request->input('sport_type'))
            ->delete();

        return response()->json(['status' => 'ok', 'deleted' => $deleted]);
    }
}
