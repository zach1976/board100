<?php

namespace App\Providers;

use Illuminate\Database\Schema\Builder;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // MariaDB 5.5 on the shared server indexes utf8mb4 at 4 bytes per
        // character, so a default varchar(255) key blows the 767-byte index
        // limit and the table simply fails to create — Laravel's own cache
        // table (`key` as primary) is one of them. See zachs_app_base.md §11.1.
        Builder::defaultStringLength(191);
    }
}
