<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class GoogleAuthService
{
    public function verifyIdToken(string $idToken): array
    {
        $response = Http::get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $idToken,
        ]);

        if ($response->failed()) {
            throw new \RuntimeException('Google token verification failed');
        }

        return $response->json();
    }
}
