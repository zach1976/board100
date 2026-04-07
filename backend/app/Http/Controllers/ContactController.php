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
        ]);

        $email = $request->input('email');
        $subject = $request->input('subject', 'Feedback');
        $body = $request->input('message');
        $app = $request->input('app', 'Tactics Board');

        try {
            // Log the contact message (can be replaced with actual mail sending)
            Log::info("Contact from $app", [
                'email' => $email,
                'subject' => $subject,
                'message' => $body,
            ]);

            // Try to send email if mail is configured
            try {
                Mail::raw("From: $email\nApp: $app\n\n$body", function ($msg) use ($email, $subject) {
                    $msg->to('support@zachsong.com')
                        ->subject("[Tactics Board] $subject")
                        ->replyTo($email);
                });
            } catch (\Exception $mailError) {
                // Mail not configured - just log it
                Log::warning('Mail not configured: ' . $mailError->getMessage());
            }

            return response()->json(['status' => 'ok', 'message' => 'Message received']);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }
}
