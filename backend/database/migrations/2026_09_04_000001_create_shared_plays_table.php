<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A play published as a link. The point is that the receiver — a player, a
 * parent, another coach — opens it in a browser with no app and no account,
 * so rows here are public-by-slug and deliberately shallow: no user_id is
 * required, and nothing here is the coach's library.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('shared_plays', function (Blueprint $table) {
            $table->id();
            // Short unguessable id in the URL (/p/{slug}). Not sequential:
            // the whole library must not be walkable from one shared link.
            $table->string('slug', 16)->unique();
            // Nullable: sharing works signed-out, and deleting an account
            // must not break links a coach already handed to a team.
            $table->unsignedBigInteger('user_id')->nullable();
            $table->string('title')->nullable();
            $table->string('sport_type', 32);
            // The board itself, same shape the app saves locally — enough to
            // re-render the play later without re-uploading anything.
            $table->json('data');
            // Rendered MP4 or PNG under storage/app/public/shares/.
            $table->string('media_path')->nullable();
            $table->string('media_kind', 8)->nullable(); // mp4 | png
            $table->unsignedInteger('views')->default(0);
            // Shared links are for a session or a week, not forever; the
            // cleanup command removes expired rows and their media.
            $table->timestamp('expires_at')->nullable()->index();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('shared_plays');
    }
};
