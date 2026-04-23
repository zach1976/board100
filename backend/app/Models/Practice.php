<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Practice extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'user_id',
        'name',
        'sport_type',
        'data',
        'client_updated_at',
    ];

    protected $casts = [
        'data' => 'array',
        'client_updated_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
