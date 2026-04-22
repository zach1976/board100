<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('practice_history', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('sport_type');
            $table->string('plan_name');
            $table->dateTime('started_at');
            $table->dateTime('completed_at')->nullable();
            $table->unsignedInteger('items_completed')->default(0);
            $table->unsignedInteger('planned_items')->default(0);
            $table->unsignedInteger('total_seconds_spent')->default(0);
            $table->boolean('completed')->default(false);
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->unique(['user_id', 'sport_type', 'plan_name', 'started_at'], 'practice_history_dedupe');
            $table->index(['user_id', 'sport_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('practice_history');
    }
};
