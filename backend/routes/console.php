<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Shared plays carry a TTL, and the media file behind one is the part that
// actually costs something — so the sweep has to run on its own rather than
// waiting for someone to open an expired link. Daily is enough: a link that
// dies a few hours late has already stopped being served.
Schedule::command('shares:prune')->dailyAt('04:00');
