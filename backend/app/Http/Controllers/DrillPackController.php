<?php

namespace App\Http\Controllers;

use Illuminate\Http\Response;
use Illuminate\Support\Facades\Storage;

/**
 * Serves the drill library as data, so it can grow without an app update.
 *
 * The packs are the same JSON the app bundles (tools/gen_drills.py output),
 * uploaded to storage/app/drills/. The client only replaces its bundled copy
 * when the served `version` is strictly higher, so publishing an old file is
 * harmless and publishing nothing at all is the normal state.
 */
class DrillPackController extends Controller
{
    /** GET /api/v1/drills/{sport} */
    public function show(string $sport): Response
    {
        // The sport is a path segment reaching the filesystem: whitelist the
        // shape rather than trusting it.
        if (!preg_match('/^[a-zA-Z]{1,32}$/', $sport)) {
            abort(404);
        }
        $path = "drills/{$sport}.json";
        if (!Storage::exists($path)) {
            abort(404);
        }
        $body = Storage::get($path);
        // Compress here rather than trusting the web server: nothing in this
        // stack was gzipping PHP responses, and the soccer pack is ~1MB raw
        // against ~140KB compressed — the difference between an update that
        // happens and one that times out on a training-ground connection.
        $accepts = str_contains(request()->header('Accept-Encoding', ''), 'gzip');
        $response = response($accepts ? gzencode($body, 6) : $body, 200)
            ->header('Content-Type', 'application/json')
            // Packs change rarely; an hour of cache keeps 16 apps from
            // hammering one box, and a version bump shows up within it.
            ->header('Cache-Control', 'public, max-age=3600');
        if ($accepts) {
            $response->header('Content-Encoding', 'gzip');
        }
        return $response;
    }
}
