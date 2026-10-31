<?php

use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    return response()->json([
        'status' => 'OK',
        'addon' => 'DkTrack Fleet Logistics & Bakery Operations',
        'version' => '1.0.0',
        'timestamp' => now()
    ]);
});
