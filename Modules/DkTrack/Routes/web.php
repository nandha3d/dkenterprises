<?php

use Illuminate\Support\Facades\Route;
use Modules\DkTrack\Http\Controllers\DkTrackController;
use Modules\DkTrack\Http\Middleware\AutoLoginLocalAdmin;

Route::middleware([
    'web',
    AutoLoginLocalAdmin::class,
    'common',
    'auth',
])->prefix('dktrack')->name('dktrack.')->group(function () {
    Route::get('/', [DkTrackController::class, 'index'])->name('dashboard');
    Route::get('/tankers', [DkTrackController::class, 'tankers'])->name('tankers');
    Route::get('/water-cans', [DkTrackController::class, 'waterCans'])->name('water_cans');
    Route::get('/bakery', [DkTrackController::class, 'bakery'])->name('bakery');
    Route::get('/customers', [DkTrackController::class, 'customers'])->name('customers');
    Route::get('/telematics', [DkTrackController::class, 'telematics'])->name('telematics');
    Route::get('/staff', [DkTrackController::class, 'staff'])->name('staff');
    Route::get('/mobile-simulator', [DkTrackController::class, 'mobileSimulator'])->name('mobile_simulator');
});
