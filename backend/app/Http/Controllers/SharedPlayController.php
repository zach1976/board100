<?php

namespace App\Http\Controllers;

use App\Models\SharedPlay;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

/**
 * Publishing a play as a link.
 *
 * The receiver has no app and no account — the link has to open in whatever
 * browser they tapped it from. So the app uploads what it already renders (an
 * MP4 of the animation, or a PNG of a static board) plus the board JSON, and
 * this serves a page around it.
 *
 * Sharing works signed-out: a coach handing a play to a parent should not have
 * to explain an account first.
 */
class SharedPlayController extends Controller
{
    /** Anything bigger is a video that should have been rendered shorter. */
    private const MAX_MEDIA_BYTES = 12 * 1024 * 1024;

    /** How long a link lives unless the app asks for less. */
    private const DEFAULT_TTL_DAYS = 90;

    /**
     * POST /api/v1/share — publish a play, get a link back.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'nullable|string|max:120',
            'sport_type' => 'required|string|max:32',
            'data' => 'required',
            'ttl_days' => 'nullable|integer|min:1|max:365',
            'media' => 'nullable|file|mimetypes:video/mp4,image/png|max:'.(self::MAX_MEDIA_BYTES / 1024),
        ]);

        // The app posts multipart, so `data` arrives as a JSON string.
        $data = $validated['data'];
        if (is_string($data)) {
            $data = json_decode($data, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'data must be valid JSON',
                ], 422);
            }
        }

        $play = new SharedPlay([
            'slug' => SharedPlay::newSlug(),
            'user_id' => $request->attributes->get('auth_user_id'),
            'title' => $validated['title'] ?? null,
            'sport_type' => $validated['sport_type'],
            'data' => $data,
            'expires_at' => Carbon::now()->addDays(
                $validated['ttl_days'] ?? self::DEFAULT_TTL_DAYS
            ),
        ]);

        if ($request->hasFile('media')) {
            $file = $request->file('media');
            $ext = $file->getMimeType() === 'video/mp4' ? 'mp4' : 'png';
            // Name the file after the slug: one row, one file, trivially
            // cleaned up when the row expires.
            $path = $file->storeAs('shares', $play->slug.'.'.$ext, 'public');
            $play->media_path = $path;
            $play->media_kind = $ext;
        }

        $play->save();

        return response()->json([
            'status' => 'ok',
            'slug' => $play->slug,
            'url' => $play->shareUrl(),
            'expires_at' => $play->expires_at?->toIso8601String(),
        ], 201);
    }

    /**
     * GET /api/v1/share/{slug} — the play as JSON, for the app or a future
     * in-browser renderer.
     */
    public function show(string $slug): JsonResponse
    {
        $play = SharedPlay::where('slug', $slug)->first();
        if (! $play || $play->isExpired()) {
            return response()->json(['status' => 'error', 'message' => 'not found'], 404);
        }

        return response()->json([
            'status' => 'ok',
            'title' => $play->title,
            'sport_type' => $play->sport_type,
            'data' => $play->data,
            'media_url' => $play->mediaUrl(),
            'media_kind' => $play->media_kind,
            'created_at' => $play->created_at->toIso8601String(),
        ]);
    }

    /**
     * GET /p/{slug} — the page a player actually opens.
     */
    public function view(string $slug)
    {
        $play = SharedPlay::where('slug', $slug)->first();
        if (! $play || $play->isExpired()) {
            return response()->view('share_missing', [], 404);
        }

        // Cheap view counter; no per-viewer tracking.
        $play->increment('views');

        return response()->view('share', ['play' => $play]);
    }

    /**
     * DELETE /api/v1/share/{slug} — a coach unpublishing their own link.
     * Requires auth, and only the row's owner may do it.
     */
    public function destroy(Request $request, string $slug): JsonResponse
    {
        $userId = $request->attributes->get('auth_user_id');
        $play = SharedPlay::where('slug', $slug)->first();
        if (! $play) {
            return response()->json(['status' => 'error', 'message' => 'not found'], 404);
        }
        if ($play->user_id === null || $play->user_id !== $userId) {
            return response()->json(['status' => 'error', 'message' => 'forbidden'], 403);
        }
        if ($play->media_path) {
            Storage::disk('public')->delete($play->media_path);
        }
        $play->delete();

        return response()->json(['status' => 'ok']);
    }
}
