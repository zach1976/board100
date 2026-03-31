<?php

namespace App\Http\Middleware;

use App\Models\User;
use App\Services\JwtAuth;
use Closure;
use Illuminate\Http\Request;

class JwtAuthMiddleware
{
    public function __construct(private JwtAuth $jwt) {}

    public function handle(Request $request, Closure $next)
    {
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json(['error' => 'No token provided'], 401);
        }

        $payload = $this->jwt->verifyToken($token);
        if (!$payload) {
            return response()->json(['error' => 'Invalid token'], 401);
        }

        $user = User::find($payload['sub'] ?? null);
        if (!$user) {
            return response()->json(['error' => 'User not found'], 401);
        }

        $request->attributes->set('auth_user', $user);
        $request->attributes->set('auth_user_id', $user->id);

        return $next($request);
    }
}
