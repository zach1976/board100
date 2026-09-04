<?php

use App\Http\Controllers\SharedPlayController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/privacy', function () {
    return view('privacy');
});

// A play shared from the app. Short path because it gets typed and read aloud.
Route::get('/p/{slug}', [SharedPlayController::class, 'view'])->name('share.view');
