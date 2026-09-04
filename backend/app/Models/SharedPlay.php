<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class SharedPlay extends Model
{
    protected $fillable = [
        'slug',
        'user_id',
        'title',
        'sport_type',
        'data',
        'media_path',
        'media_kind',
        'expires_at',
    ];

    protected $casts = [
        'data' => 'array',
        'expires_at' => 'datetime',
    ];

    /**
     * A slug short enough to read out loud, long enough not to be guessed:
     * 10 chars of base58 ≈ 58 bits. Ambiguous glyphs (0/O, 1/l/I) are out so
     * a coach can dictate one over the phone.
     */
    public static function newSlug(): string
    {
        $alphabet = '23456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ';
        do {
            $slug = '';
            for ($i = 0; $i < 10; $i++) {
                $slug .= $alphabet[random_int(0, strlen($alphabet) - 1)];
            }
        } while (static::where('slug', $slug)->exists());

        return $slug;
    }

    public function isExpired(): bool
    {
        return $this->expires_at !== null && $this->expires_at->isPast();
    }

    /** Public URL of the rendered media, or null when none was uploaded. */
    public function mediaUrl(): ?string
    {
        return $this->media_path ? asset('storage/'.$this->media_path) : null;
    }

    public function shareUrl(): string
    {
        return url('/p/'.$this->slug);
    }
}
