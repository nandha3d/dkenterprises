<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Assign existing Titan Corporate Campus to TMWS (Bulk Water Tankers)
        DB::table('customers')
            ->where('name', 'like', '%Titan%')
            ->update([
                'company_id' => 2,
                'latitude' => 11.332400,
                'longitude' => 77.712100,
                'geofence_radius' => 150,
            ]);

        // 2. Ensure TMWS has dedicated industrial bulk water clients
        $tmwsCustomers = [
            [
                'customer_group_id' => 1,
                'name' => 'Texvalley Commercial Complex',
                'company_name' => 'Texvalley Commercial Complex',
                'email' => 'texvalley@water.com',
                'phone_number' => '9443312890',
                'address' => 'NH 544 Gangapuram',
                'city' => 'Erode',
                'country' => 'India',
                'company_id' => 2, // TMWS
                'latitude' => 11.332400,
                'longitude' => 77.712100,
                'geofence_radius' => 150,
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'customer_group_id' => 1,
                'name' => 'The Chennai Silks (Industrial Dyeing Unit)',
                'company_name' => 'The Chennai Silks',
                'email' => 'silks.dyeing@tcs.com',
                'phone_number' => '9843044810',
                'address' => 'SIPCOT Industrial Growth Estate',
                'city' => 'Perundurai',
                'country' => 'India',
                'company_id' => 2, // TMWS
                'latitude' => 11.084500,
                'longitude' => 77.294100,
                'geofence_radius' => 200,
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($tmwsCustomers as $cust) {
            if (!DB::table('customers')->where('name', $cust['name'])->exists()) {
                DB::table('customers')->insert($cust);
            }
        }

        // 3. Ensure DK Waters has dedicated retail and route packaged drinking water clients
        $dkwCustomers = [
            [
                'customer_group_id' => 1,
                'name' => 'Aran Cafe - Main Kitchen',
                'company_name' => 'Aran Cafe Private Limited',
                'email' => 'cafe.main@arancafe.com',
                'phone_number' => '9842155601',
                'address' => 'Race Course Road',
                'city' => 'Madurai',
                'country' => 'India',
                'company_id' => 3, // DK Waters
                'latitude' => 11.018221,
                'longitude' => 76.964119,
                'geofence_radius' => 75,
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'customer_group_id' => 1,
                'name' => 'Santha Provision & General Stores',
                'company_name' => 'Santha Stores',
                'email' => 'santha.stores@gmail.com',
                'phone_number' => '9787100293',
                'address' => 'Town Hall Road',
                'city' => 'Madurai',
                'country' => 'India',
                'company_id' => 3, // DK Waters
                'latitude' => 11.026800,
                'longitude' => 76.974200,
                'geofence_radius' => 75,
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'customer_group_id' => 1,
                'name' => 'Meenakshi Departmental Supermarket',
                'company_name' => 'Meenakshi Supermarket',
                'email' => 'meenakshi.mart@gmail.com',
                'phone_number' => '9842233445',
                'address' => 'KK Nagar 80ft Road',
                'city' => 'Madurai',
                'country' => 'India',
                'company_id' => 3, // DK Waters
                'latitude' => 11.021450,
                'longitude' => 76.968920,
                'geofence_radius' => 75,
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($dkwCustomers as $cust) {
            if (!DB::table('customers')->where('name', $cust['name'])->exists()) {
                DB::table('customers')->insert($cust);
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Reversible if needed
    }
};
