<?php

namespace App\Console\Commands;

use App\Models\SharedPlay;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

/**
 * Shared links expire, and their uploaded MP4s are the only thing in this
 * project that grows without bound. Run daily:
 *
 *   php artisan shares:prune
 */
class PruneSharedPlays extends Command
{
    protected $signature = 'shares:prune {--dry-run : list what would go, delete nothing}';

    protected $description = 'Delete expired shared plays and their media files';

    public function handle(): int
    {
        $expired = SharedPlay::whereNotNull('expires_at')
            ->where('expires_at', '<', Carbon::now())
            ->get();

        if ($expired->isEmpty()) {
            $this->info('Nothing expired.');

            return self::SUCCESS;
        }

        $bytes = 0;
        foreach ($expired as $play) {
            if ($play->media_path && Storage::disk('public')->exists($play->media_path)) {
                $bytes += Storage::disk('public')->size($play->media_path);
                if (! $this->option('dry-run')) {
                    Storage::disk('public')->delete($play->media_path);
                }
            }
            $this->line(($this->option('dry-run') ? 'would delete ' : 'deleted ').$play->slug);
            if (! $this->option('dry-run')) {
                $play->delete();
            }
        }

        $this->info(sprintf(
            '%s %d shared play(s), %.1f MB of media.',
            $this->option('dry-run') ? 'Would free' : 'Freed',
            $expired->count(),
            $bytes / 1048576
        ));

        return self::SUCCESS;
    }
}
