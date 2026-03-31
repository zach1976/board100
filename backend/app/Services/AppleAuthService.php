<?php

namespace App\Services;

use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Http;

class AppleAuthService
{
    public function verifyIdentityToken(string $identityToken): array
    {
        $response = Http::get('https://appleid.apple.com/auth/keys');

        if ($response->failed()) {
            throw new \RuntimeException('Failed to fetch Apple public keys');
        }

        $keys = $response->json();
        $jwks = JWK::parseKeySet($keys, 'RS256');
        $decoded = JWT::decode($identityToken, $jwks);
        $payload = (array) $decoded;

        if (($payload['iss'] ?? '') !== 'https://appleid.apple.com') {
            throw new \RuntimeException('Invalid Apple token issuer');
        }

        return $payload;
    }
}
