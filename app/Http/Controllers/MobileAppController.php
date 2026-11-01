<?php

namespace App\Http\Controllers;

use App\Models\Company;
use App\Models\Customer;
use App\Models\Product;
use App\Models\WaterCanRoute;
use App\Models\WaterTanker;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MobileAppController extends Controller
{
    /**
     * Render the Mobile Application Interface (PWA / Mobile Web)
     */
    public function index(Request $request)
    {
        $companies = Company::where('status', 'active')->get();
        $routes = WaterCanRoute::where('is_active', true)->get();
        $tankers = WaterTanker::where('is_active', true)->get();
        $customers = Customer::where('is_active', true)->take(30)->get();
        $dkwCustomers = Customer::where('is_active', true)->where('company_id', 3)->get();
        $tmwsCustomers = Customer::where('is_active', true)->where('company_id', 2)->get();
        if ($dkwCustomers->isEmpty()) {
            $dkwCustomers = $customers;
        }
        if ($tmwsCustomers->isEmpty()) {
            $tmwsCustomers = $customers;
        }

        // Packaged water products (open & dynamic, NOT hardcoded)
        $packagedProducts = Product::where('is_active', true)
            ->where(function ($q) {
                $q->where('code', 'like', 'CAN%')
                  ->orWhere('code', 'like', 'BTL%')
                  ->orWhere('name', 'like', '%Water%')
                  ->orWhere('name', 'like', '%Jar%')
                  ->orWhere('name', 'like', '%Bottle%');
            })
            ->get();

        if ($packagedProducts->isEmpty()) {
            $packagedProducts = collect([
                (object)['id' => 1, 'code' => 'CAN-20L', 'name' => '20L Packaged Drinking Water Jar', 'price' => 35.0, 'unit' => 'CAN', 'is_jar' => true],
                (object)['id' => 2, 'code' => 'CAN-25L', 'name' => '25L Packaged Drinking Water Jar', 'price' => 45.0, 'unit' => 'CAN', 'is_jar' => true],
                (object)['id' => 3, 'code' => 'CAN-10L', 'name' => '10L Easy-Dispense Water Jar', 'price' => 25.0, 'unit' => 'CAN', 'is_jar' => true],
                (object)['id' => 4, 'code' => 'BTL-1L', 'name' => '1 Litre Packaged Drinking Water Box of 12', 'price' => 180.0, 'unit' => 'BOX', 'is_jar' => false],
                (object)['id' => 5, 'code' => 'BTL-2L', 'name' => '2 Litre Packaged Drinking Water Box of 9', 'price' => 180.0, 'unit' => 'BOX', 'is_jar' => false],
                (object)['id' => 6, 'code' => 'BTL-500ML', 'name' => '500ML Mini Bottled Water Box of 24', 'price' => 240.0, 'unit' => 'BOX', 'is_jar' => false],
            ]);
        }

        // Cafe products
        $cafeProducts = Product::where('is_active', true)
            ->where(function ($q) {
                $q->where('code', 'like', 'BEV%')
                  ->orWhere('code', 'like', 'BAK%')
                  ->orWhere('code', 'like', 'SNK%')
                  ->orWhere('name', 'like', '%Coffee%')
                  ->orWhere('name', 'like', '%Tea%')
                  ->orWhere('name', 'like', '%Puff%');
            })
            ->get();

        if ($cafeProducts->isEmpty()) {
            $cafeProducts = collect([
                (object)['id' => 101, 'name' => 'Special Filter Coffee', 'code' => 'BEV-COF', 'price' => 25.0, 'category' => 'Hot Brews', 'emoji' => '☕'],
                (object)['id' => 102, 'name' => 'Masala Ginger Tea', 'code' => 'BEV-TEA', 'price' => 20.0, 'category' => 'Hot Brews', 'emoji' => '🫖'],
                (object)['id' => 103, 'name' => 'Egg Puff (Hot & Crisp)', 'code' => 'BAK-PUFF', 'price' => 30.0, 'category' => 'Bakery', 'emoji' => '🥐'],
                (object)['id' => 104, 'name' => 'Veg Samosa (2 Pcs)', 'code' => 'SNK-SAM', 'price' => 30.0, 'category' => 'Savories', 'emoji' => '🥟'],
                (object)['id' => 105, 'name' => 'Paneer Roll', 'code' => 'BAK-ROLL', 'price' => 55.0, 'category' => 'Bakery', 'emoji' => '🌯'],
                (object)['id' => 106, 'name' => 'Cold Badam Milk', 'code' => 'BEV-BDM', 'price' => 40.0, 'category' => 'Cold Drinks', 'emoji' => '🥤'],
            ]);
        }

        return view('mobile.index', compact(
            'companies',
            'routes',
            'tankers',
            'customers',
            'dkwCustomers',
            'tmwsCustomers',
            'packagedProducts',
            'cafeProducts'
        ));
    }
}
