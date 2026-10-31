<?php

namespace Modules\DkTrack\Providers;

use Illuminate\Support\Facades\Route;
use Illuminate\Foundation\Support\Providers\RouteServiceProvider as ServiceProvider;

class RouteServiceProvider extends ServiceProvider
{
    protected $moduleNamespace = 'Modules\DkTrack\Http\Controllers';

    public function boot()
    {
        parent::boot();
    }

    public function map()
    {
        $this->mapApiRoutes();
        $this->mapWebRoutes();
    }

    protected function mapWebRoutes()
    {
        Route::middleware('web')
            ->namespace($this->moduleNamespace)
            ->group(module_path('DkTrack', '/Routes/web.php'));
    }

    protected function mapApiRoutes()
    {
        Route::prefix('api/v1/dktrack')
            ->middleware('api')
            ->namespace($this->moduleNamespace)
            ->group(module_path('DkTrack', '/Routes/api.php'));
    }
}
