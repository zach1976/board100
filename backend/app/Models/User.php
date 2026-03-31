<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class User extends Model
{
    protected $fillable = [
        'email',
        'display_name',
        'apple_user_id',
        'google_user_id',
        'avatar_url',
    ];

    public function tactics()
    {
        return $this->hasMany(Tactic::class);
    }
}
