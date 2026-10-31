<?php

namespace Modules\DkTrack\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;

class DkTrackController extends Controller
{
    /**
     * Master Command & Executive Operations Dashboard
     */
    public function index()
    {
        // Sample / Live Fleet Metrics
        $totalTankers = 4;
        $totalCanTrucks = 1;
        $totalKlDeliveredToday = 96.0;
        $totalCansDeliveredToday = 213;
        $totalRevenueToday = 148500.00;
        $totalDieselExpenseToday = 8420.00;
        $netOperatingMarginToday = $totalRevenueToday - $totalDieselExpenseToday;

        return view('dktrack::index', compact(
            'totalTankers',
            'totalCanTrucks',
            'totalKlDeliveredToday',
            'totalCansDeliveredToday',
            'totalRevenueToday',
            'totalDieselExpenseToday',
            'netOperatingMarginToday'
        ));
    }

    /**
     * 1. Bulk Water Tankers Portal
     */
    public function tankers()
    {
        return view('dktrack::tankers');
    }

    /**
     * 2. 20L Water Can Anti-Theft Distribution Portal
     */
    public function waterCans()
    {
        return view('dktrack::water_cans');
    }

    /**
     * 3. Bakery & Cafe Operations Portal
     */
    public function bakery()
    {
        return view('dktrack::bakery');
    }

    /**
     * 4. Customer Management & Anti-Fraud GPS Geo-Locking
     */
    public function customers()
    {
        return view('dktrack::customers');
    }

    /**
     * 5. Live GPS Telematics & Stoppage Audit
     */
    public function telematics()
    {
        return view('dktrack::telematics');
    }

    /**
     * 6. Driver, Delivery Boy & Staff Management (Attendance & Payroll)
     */
    public function staff()
    {
        return view('dktrack::staff');
    }

    /**
     * 7. Field Mobile Simulator
     */
    public function mobileSimulator()
    {
        return view('dktrack::mobile_simulator');
    }
}
