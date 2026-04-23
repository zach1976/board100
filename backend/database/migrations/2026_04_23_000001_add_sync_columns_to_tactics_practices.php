<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Dedupe tactics before adding the unique constraint. The original
        // migration only had a non-unique index, so concurrent writes could
        // produce multiple rows with the same (user_id, sport_type, name).
        $dupes = DB::table('tactics')
            ->select('user_id', 'sport_type', 'name', DB::raw('MAX(id) as keep_id'))
            ->groupBy('user_id', 'sport_type', 'name')
            ->havingRaw('COUNT(*) > 1')
            ->get();
        foreach ($dupes as $d) {
            DB::table('tactics')
                ->where('user_id', $d->user_id)
                ->where('sport_type', $d->sport_type)
                ->where('name', $d->name)
                ->where('id', '!=', $d->keep_id)
                ->delete();
        }

        Schema::table('tactics', function (Blueprint $table) {
            $table->timestamp('client_updated_at')->nullable()->after('data');
            $table->softDeletes();
            $table->unique(['user_id', 'sport_type', 'name'], 'tactics_user_sport_name_unique');
        });

        Schema::table('practices', function (Blueprint $table) {
            $table->timestamp('client_updated_at')->nullable()->after('data');
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::table('tactics', function (Blueprint $table) {
            $table->dropUnique('tactics_user_sport_name_unique');
            $table->dropSoftDeletes();
            $table->dropColumn('client_updated_at');
        });
        Schema::table('practices', function (Blueprint $table) {
            $table->dropSoftDeletes();
            $table->dropColumn('client_updated_at');
        });
    }
};
