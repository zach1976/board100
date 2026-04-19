<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class ContactController extends Controller
{
    public function sendEmail(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'subject' => 'nullable|string|max:255',
            'message' => 'required|string',
            'app' => 'nullable|string',
            'sport' => 'nullable|string|max:64',
        ]);

        $email = $request->input('email');
        $subject = $request->input('subject', 'Feedback');
        $body = $request->input('message');
        $app = $request->input('app', 'Tactics Board');
        $sport = $request->input('sport', '');

        try {
            Log::info("Contact from $app", [
                'email' => $email,
                'sport' => $sport,
                'subject' => $subject,
                'message' => $body,
            ]);

            $emailBody = "User Email: $email\nSport: $sport\nApp: $app\n\nMessage:\n$body";

            try {
                Mail::raw($emailBody, function ($msg) use ($email, $subject, $app) {
                    $msg->to('zachsong@gmail.com')
                        ->subject("[$app] $subject")
                        ->replyTo($email);
                });
            } catch (\Exception $mailError) {
                Log::warning('Mail not configured: ' . $mailError->getMessage());
            }

            return response()->json(['status' => 'ok', 'message' => 'Message received']);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }
}
