<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\ContactController;
use App\Http\Controllers\PracticeController;
use App\Http\Controllers\PracticeHistoryController;
use App\Http\Controllers\TacticController;
use App\Http\Middleware\JwtAuthMiddleware;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Public
    Route::get('/health', [TacticController::class, 'health']);
    Route::post('/send-email', [ContactController::class, 'sendEmail']);

    // Auth (public — returns JWT)
    Route::post('/auth/apple', [AuthController::class, 'apple']);
    Route::post('/auth/google', [AuthController::class, 'google']);

    // Protected (requires JWT)
    Route::middleware([JwtAuthMiddleware::class])->group(function () {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        // Tactics CRUD
        Route::get('/tactics', [TacticController::class, 'index']);
        Route::get('/tactics/pull', [TacticController::class, 'pull']);
        Route::post('/tactics', [TacticController::class, 'store']);
        Route::post('/tactics/sync', [TacticController::class, 'sync']);
        Route::delete('/tactics', [TacticController::class, 'destroyByName']);
        Route::get('/tactics/{id}', [TacticController::class, 'show']);
        Route::delete('/tactics/{id}', [TacticController::class, 'destroy']);

        // Practices
        Route::get('/practices', [PracticeController::class, 'index']);
        Route::get('/practices/pull', [PracticeController::class, 'pull']);
        Route::post('/practices', [PracticeController::class, 'store']);
        Route::post('/practices/sync', [PracticeController::class, 'sync']);
        Route::delete('/practices', [PracticeController::class, 'destroyByName']);

        // Practice history
        Route::get('/practice-history', [PracticeHistoryController::class, 'index']);
        Route::post('/practice-history', [PracticeHistoryController::class, 'store']);
        Route::post('/practice-history/sync', [PracticeHistoryController::class, 'sync']);
        Route::delete('/practice-history', [PracticeHistoryController::class, 'clear']);
    });
});
