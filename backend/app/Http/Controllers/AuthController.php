<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\AppleAuthService;
use App\Services\GoogleAuthService;
use App\Services\JwtAuth;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class AuthController extends Controller
{
    public function __construct(
        private AppleAuthService $appleAuth,
        private GoogleAuthService $googleAuth,
        private JwtAuth $jwt,
    ) {}

    public function apple(Request $request): JsonResponse
    {
        $request->validate([
            'identity_token' => 'required|string',
            'display_name' => 'nullable|string',
        ]);

        try {
            $payload = $this->appleAuth->verifyIdentityToken($request->input('identity_token'));
            $appleUserId = $payload['sub'];
            $email = $payload['email'] ?? null;
            $displayName = $request->input('display_name');

            $user = User::where('apple_user_id', $appleUserId)->first();
            if (!$user && $email) {
                $user = User::where('email', $email)->first();
            }

            if ($user) {
                if (!$user->apple_user_id) {
                    $user->update(['apple_user_id' => $appleUserId]);
                }
                // Also overwrite the 'Apple User' placeholder if we now have a real name
                // (Apple only returns the name once per Apple ID, so the first login
                // that successfully forwards it wins).
                if ($displayName && (!$user->display_name || $user->display_name === 'Apple User')) {
                    $user->update(['display_name' => $displayName]);
                }
            } else {
                $user = User::create([
                    'email' => $email ?? ($appleUserId . '@privaterelay.appleid.com'),
                    'display_name' => $displayName ?? 'Apple User',
                    'apple_user_id' => $appleUserId,
                ]);
            }

            $token = $this->jwt->issueToken($user->id);

            return response()->json([
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'display_name' => $user->display_name,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Apple auth failed: ' . $e->getMessage());
            return response()->json(['error' => 'Authentication failed', 'message' => $e->getMessage()], 401);
        }
    }

    public function google(Request $request): JsonResponse
    {
        $request->validate([
            'id_token' => 'required|string',
        ]);

        try {
            $googlePayload = $this->googleAuth->verifyIdToken($request->input('id_token'));
            $googleUserId = $googlePayload['sub'];
            $email = $googlePayload['email'] ?? null;
            $displayName = $googlePayload['name'] ?? 'Google User';

            $user = User::where('google_user_id', $googleUserId)->first();
            if (!$user && $email) {
                $user = User::where('email', $email)->first();
            }

            if ($user) {
                if (!$user->google_user_id) {
                    $user->update(['google_user_id' => $googleUserId]);
                }
                if ($displayName && !$user->display_name) {
                    $user->update(['display_name' => $displayName]);
                }
            } else {
                $user = User::create([
                    'email' => $email,
                    'display_name' => $displayName,
                    'google_user_id' => $googleUserId,
                ]);
            }

            $token = $this->jwt->issueToken($user->id);

            return response()->json([
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'display_name' => $user->display_name,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Google auth failed: ' . $e->getMessage());
            return response()->json(['error' => 'Authentication failed', 'message' => $e->getMessage()], 401);
        }
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->attributes->get('auth_user');
        return response()->json([
            'user' => [
                'id' => $user->id,
                'email' => $user->email,
                'display_name' => $user->display_name,
                'avatar_url' => $user->avatar_url,
            ],
        ]);
    }

    public function logout(): JsonResponse
    {
        return response()->json(['message' => 'Logged out']);
    }
}
