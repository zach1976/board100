<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PracticeHistory extends Model
{
    protected $table = 'practice_history';

    protected $fillable = [
        'user_id',
        'sport_type',
        'plan_name',
        'started_at',
        'completed_at',
        'items_completed',
        'planned_items',
        'total_seconds_spent',
        'completed',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
        'completed' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
