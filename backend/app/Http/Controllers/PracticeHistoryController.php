<?php

namespace App\Http\Controllers;

use App\Models\PracticeHistory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PracticeHistoryController extends Controller
{
    /**
     * GET /api/v1/practice-history — list sessions
     */
    public function index(Request $request): JsonResponse
    {
        $userId = $request->attributes->get('auth_user_id');
        $sportType = $request->query('sport_type');

        $query = PracticeHistory::where('user_id', $userId);
        if ($sportType) {
            $query->where('sport_type', $sportType);
        }

        $sessions = $query->orderBy('started_at', 'desc')
            ->limit(500)
            ->get()
            ->map(fn ($s) => $this->toPayload($s));

        return response()->json(['status' => 'ok', 'sessions' => $sessions]);
    }

    /**
     * POST /api/v1/practice-history — append one session (dedupes on natural key)
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'sport_type' => 'required|string|max:50',
            'plan_name' => 'required|string|max:255',
            'started_at' => 'required|date',
            'completed_at' => 'nullable|date',
            'items_completed' => 'required|integer|min:0',
            'planned_items' => 'required|integer|min:0',
            'total_seconds_spent' => 'required|integer|min:0',
            'completed' => 'required|boolean',
        ]);

        $userId = $request->attributes->get('auth_user_id');

        $session = PracticeHistory::updateOrCreate(
            [
                'user_id' => $userId,
                'sport_type' => $request->input('sport_type'),
                'plan_name' => $request->input('plan_name'),
                'started_at' => $request->input('started_at'),
            ],
            [
                'completed_at' => $request->input('completed_at'),
                'items_completed' => $request->input('items_completed'),
                'planned_items' => $request->input('planned_items'),
                'total_seconds_spent' => $request->input('total_seconds_spent'),
                'completed' => $request->input('completed'),
            ]
        );

        return response()->json([
            'status' => 'ok',
            'session' => $this->toPayload($session),
        ], $session->wasRecentlyCreated ? 201 : 200);
    }

    /**
     * POST /api/v1/practice-history/sync — batch upsert
     */
    public function sync(Request $request): JsonResponse
    {
        $request->validate([
            'sessions' => 'required|array',
            'sessions.*.sport_type' => 'required|string',
            'sessions.*.plan_name' => 'required|string',
            'sessions.*.started_at' => 'required|date',
            'sessions.*.items_completed' => 'required|integer|min:0',
            'sessions.*.planned_items' => 'required|integer|min:0',
            'sessions.*.total_seconds_spent' => 'required|integer|min:0',
            'sessions.*.completed' => 'required|boolean',
        ]);

        $userId = $request->attributes->get('auth_user_id');
        $count = 0;

        foreach ($request->input('sessions') as $s) {
            PracticeHistory::updateOrCreate(
                [
                    'user_id' => $userId,
                    'sport_type' => $s['sport_type'],
                    'plan_name' => $s['plan_name'],
                    'started_at' => $s['started_at'],
                ],
                [
                    'completed_at' => $s['completed_at'] ?? null,
                    'items_completed' => $s['items_completed'],
                    'planned_items' => $s['planned_items'],
                    'total_seconds_spent' => $s['total_seconds_spent'],
                    'completed' => $s['completed'],
                ]
            );
            $count++;
        }

        return response()->json(['status' => 'ok', 'synced' => $count]);
    }

    /**
     * DELETE /api/v1/practice-history — clear sessions (optionally by sport)
     */
    public function clear(Request $request): JsonResponse
    {
        $userId = $request->attributes->get('auth_user_id');
        $sportType = $request->query('sport_type');

        $query = PracticeHistory::where('user_id', $userId);
        if ($sportType) {
            $query->where('sport_type', $sportType);
        }
        $deleted = $query->delete();

        return response()->json(['status' => 'ok', 'deleted' => $deleted]);
    }

    private function toPayload(PracticeHistory $s): array
    {
        return [
            'id' => $s->id,
            'sport_type' => $s->sport_type,
            'plan_name' => $s->plan_name,
            'started_at' => $s->started_at?->toIso8601String(),
            'completed_at' => $s->completed_at?->toIso8601String(),
            'items_completed' => $s->items_completed,
            'planned_items' => $s->planned_items,
            'total_seconds_spent' => $s->total_seconds_spent,
            'completed' => (bool) $s->completed,
        ];
    }
}
