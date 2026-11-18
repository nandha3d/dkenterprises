<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class TmwsFleetAndPickupPointsSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();
        $tmwsCompanyId = $this->resolveCompanyId('bulk_water', ['TMWS'], '%Tiruchendur%');
        $dkWatersCompanyId = $this->resolveCompanyId('packaged_water', ['DKWATERS', 'DRINKAA'], '%DK Waters%');

        // 1. Seed TMWS Fleet Tankers (9 owned trucks + 1 outside tie-up placeholder)
        if (Schema::hasTable('water_tankers')) {
            $tankerColumns = array_flip(Schema::getColumnListing('water_tankers'));

            $tankers = [
                [
                    'vehicle_number' => 'TN-33-TM-1401',
                    'model_type' => 'Comet 14KL #1',
                    'vehicle_variant' => 'Comet',
                    'capacity_kl' => 14,
                    'capacity_liters' => 14000,
                    'supported_capacities_json' => json_encode([14]),
                    'has_compartments' => false,
                    'compartment_notes' => 'Single tank 14KL full load',
                    'is_outsourced' => false,
                    'is_active' => true,
                ],
                [
                    'vehicle_number' => 'TN-33-TM-1402',
                    'model_type' => 'Comet 14KL #2',
                    'vehicle_variant' => 'Comet',
                    'capacity_kl' => 14,
                    'capacity_liters' => 14000,
                    'supported_capacities_json' => json_encode([14]),
                    'has_compartments' => false,
                    'compartment_notes' => 'Single tank 14KL full load',
                    'is_outsourced' => false,
                    'is_active' => true,
                ],
                [
                    'vehicle_number' => 'TN-33-TM-2501',
                    'model_type' => 'Taurus 25KL #1',
                    'vehicle_variant' => 'Taurus',
                    'capacity_kl' => 25,
                    'capacity_liters' => 25000,
                    'supported_capacities_json' => json_encode([25]),
                    'has_compartments' => false,
                    'compartment_notes' => 'Single tank 25KL full load',
                    'is_outsourced' => false,
                    'is_active' => true,
                ],
                [
                    'vehicle_number' => 'TN-33-TM-2502',
                    'model_type' => 'Taurus 25KL #2',
                    'vehicle_variant' => 'Taurus',
                    'capacity_kl' => 25,
                    'capacity_liters' => 25000,
                    'supported_capacities_json' => json_encode([25]),
                    'has_compartments' => false,
                    'compartment_notes' => 'Single tank 25KL full load',
                    'is_outsourced' => false,
                    'is_active' => true,
                ],
                [
                    'vehicle_number' => 'TN-33-TM-2503',
                    'model_type' => 'Taurus 25KL #3',
                    'vehicle_variant' => 'Taurus',
                    'capacity_kl' => 25,
                    'capacity_liters' => 25000,
                    'supported_capacities_json' => json_encode([25]),
                    'has_compartments' => false,
                    'compartment_notes' => 'Single tank 25KL full load',
                    'is_outsourced' => false,
                    'is_active' => true,
                ],
                [
                    'vehicle_number' => 'TN-33-TM-0901',
                    'model_type' => 'Eicher 9KL #1',
                    'vehicle_variant' => 'Eicher',
                    'capacity_kl' => 9,
                    'capacity_liters' => 9000,
                    'supported_capacities_json' => json_encode([4, 5, 6, 7, 8, 9]),
                    'has_compartments' => true,
                    'compartment_notes' => 'Compartments: 4KL-9KL flexible local/medium loads',
                    'is_outsourced' => false,
                    'is_active' => true,
                ],
                [
                    'vehicle_number' => 'TN-33-TM-0902',
                    'model_type' => 'Eicher 9KL #2',
                    'vehicle_variant' => 'Eicher',
                    'capacity_kl' => 9,
                    'capacity_liters' => 9000,
                    'supported_capacities_json' => json_encode([4, 5, 6, 7, 8, 9]),
                    'has_compartments' => true,
                    'compartment_notes' => 'Compartments: 4KL-9KL flexible local/medium loads',
                    'is_outsourced' => false,
                    'is_active' => true,
                ],
                [
                    'vehicle_number' => 'TN-33-TM-0501',
                    'model_type' => 'Tata 407 5KL',
                    'vehicle_variant' => 'Tata 407',
                    'capacity_kl' => 5,
                    'capacity_liters' => 5000,
                    'supported_capacities_json' => json_encode([2, 3, 4, 5]),
                    'has_compartments' => true,
                    'compartment_notes' => '2 Compartments (2KL + 3KL)',
                    'is_outsourced' => false,
                    'is_active' => true,
                ],
                [
                    'vehicle_number' => 'PY-01-TM-2501',
                    'model_type' => 'Pondicherry Big Tanker',
                    'vehicle_variant' => 'Pondicherry Trailer',
                    'capacity_kl' => 25,
                    'capacity_liters' => 25000,
                    'supported_capacities_json' => json_encode([25, 30, 35, 40]),
                    'has_compartments' => false,
                    'compartment_notes' => '25ft outer industrial/construction vehicle (not for narrow city streets)',
                    'is_outsourced' => false,
                    'is_active' => true,
                ],
                [
                    'vehicle_number' => 'OUTSIDE-TIEUP',
                    'model_type' => 'Outside / Tie-Up Vehicle (வெளி வண்டி)',
                    'vehicle_variant' => 'Outside Vehicle',
                    'capacity_kl' => 14,
                    'capacity_liters' => 14000,
                    'supported_capacities_json' => json_encode([9, 12, 14, 20, 25]),
                    'has_compartments' => false,
                    'compartment_notes' => 'Peak summer / breakdown tie-up outside tanker (வெளி வண்டி)',
                    'is_outsourced' => true,
                    'vendor_name' => 'Tie-Up Outside Tanker Vendor',
                    'is_active' => true,
                ],
            ];

            foreach ($tankers as $tanker) {
                if ($tmwsCompanyId !== null && isset($tankerColumns['company_id'])) {
                    $tanker['company_id'] = $tmwsCompanyId;
                }
                $existing = DB::table('water_tankers')->where('vehicle_number', $tanker['vehicle_number'])->first();
                $payload = array_intersect_key($tanker + [
                    'updated_at' => $now,
                    'created_at' => $existing->created_at ?? $now,
                ], $tankerColumns);

                DB::table('water_tankers')->updateOrInsert(
                    ['vehicle_number' => $tanker['vehicle_number']],
                    $payload
                );
            }
        }

        // 2. Seed 8 Erode Water Pickup / Borewell Points
        if (Schema::hasTable('water_pickup_points')) {
            $pickupColumns = array_flip(Schema::getColumnListing('water_pickup_points'));

            $pickupPoints = [
                [
                    'code' => 'PP-VPM',
                    'name' => 'Veerappampalayam Borewell',
                    'location_type' => 'regular_borewell',
                    'address' => 'Veerappampalayam, Erode',
                    'latitude' => 11.3410000,
                    'longitude' => 77.6970000,
                    'geofence_radius_m' => 200,
                    'rate_per_load' => 0.00,
                    'settlement_cycle' => 'own',
                    'is_active' => true,
                ],
                [
                    'code' => 'PP-KPR',
                    'name' => 'Karungalpalayam River-Side Bore',
                    'location_type' => 'regular_borewell',
                    'address' => 'Karungalpalayam River-Side (கருங்கல்பாளையம் ஆத்தோரம்), Erode',
                    'latitude' => 11.3560000,
                    'longitude' => 77.7410000,
                    'geofence_radius_m' => 200,
                    'rate_per_load' => 0.00,
                    'settlement_cycle' => 'own',
                    'is_active' => true,
                ],
                [
                    'code' => 'PP-SLR',
                    'name' => 'Solar Borewell Point',
                    'location_type' => 'regular_borewell',
                    'address' => 'Solar Pirivu, Erode',
                    'latitude' => 11.3190000,
                    'longitude' => 77.7490000,
                    'geofence_radius_m' => 200,
                    'rate_per_load' => 0.00,
                    'settlement_cycle' => 'own',
                    'is_active' => true,
                ],
                [
                    'code' => 'PP-SRP',
                    'name' => 'Surampatti Regular Point',
                    'location_type' => 'regular_borewell',
                    'address' => 'Surampatti, Erode',
                    'latitude' => 11.3290000,
                    'longitude' => 77.7170000,
                    'geofence_radius_m' => 200,
                    'rate_per_load' => 0.00,
                    'settlement_cycle' => 'own',
                    'is_active' => true,
                ],
                [
                    'code' => 'PP-MKD',
                    'name' => 'Mettukadai Regular Point',
                    'location_type' => 'regular_borewell',
                    'address' => 'Mettukadai, Erode',
                    'latitude' => 11.3070000,
                    'longitude' => 77.6850000,
                    'geofence_radius_m' => 200,
                    'rate_per_load' => 150.00,
                    'settlement_cycle' => 'monthly',
                    'is_active' => true,
                ],
                [
                    'code' => 'PP-CHT',
                    'name' => 'Chithode Outer Pickup',
                    'location_type' => 'outer_paid_borewell',
                    'address' => 'Chithode Highway, Erode',
                    'latitude' => 11.3910000,
                    'longitude' => 77.6690000,
                    'geofence_radius_m' => 250,
                    'rate_per_load' => 250.00,
                    'settlement_cycle' => 'weekly',
                    'is_active' => true,
                ],
                [
                    'code' => 'PP-LKN',
                    'name' => 'Lakshmi Nagar Outer Pickup',
                    'location_type' => 'outer_paid_borewell',
                    'address' => 'Lakshmi Nagar, Bhavani Road, Erode',
                    'latitude' => 11.3770000,
                    'longitude' => 77.7210000,
                    'geofence_radius_m' => 250,
                    'rate_per_load' => 250.00,
                    'settlement_cycle' => 'weekly',
                    'is_active' => true,
                ],
                [
                    'code' => 'PP-PND',
                    'name' => 'Perundurai Road Outer Pickup',
                    'location_type' => 'outer_paid_borewell',
                    'address' => 'Perundurai Road, Erode',
                    'latitude' => 11.3120000,
                    'longitude' => 77.6320000,
                    'geofence_radius_m' => 250,
                    'rate_per_load' => 300.00,
                    'settlement_cycle' => 'monthly',
                    'is_active' => true,
                ],
            ];

            foreach ($pickupPoints as $point) {
                $match = ['code' => $point['code']];
                if ($tmwsCompanyId !== null && isset($pickupColumns['company_id'])) {
                    $point['company_id'] = $tmwsCompanyId;
                    $match['company_id'] = $tmwsCompanyId;
                }
                $existing = DB::table('water_pickup_points')->where($match)->first();
                $payload = array_intersect_key($point + [
                    'updated_at' => $now,
                    'created_at' => $existing->created_at ?? $now,
                ], $pickupColumns);

                DB::table('water_pickup_points')->updateOrInsert($match, $payload);
            }
        }

        // 3. Seed 2 DK Waters / Drinkaa Delivery Vans in water_can_routes
        if (Schema::hasTable('water_can_routes')) {
            $routeColumns = array_flip(Schema::getColumnListing('water_can_routes'));

            $routes = [
                [
                    'route_name' => 'Tata Ace EV (City Local <100km)',
                    'vehicle_no' => 'TN-33-EV-1001 (Tata Ace EV)',
                    'driver_name' => 'R. Muthu',
                    'driver_phone' => '9842100010',
                    'daily_avg_cans' => 80,
                    'is_active' => true,
                ],
                [
                    'route_name' => 'Tata Ace Diesel (Outer Highway - Gobi/Cbe/Salem)',
                    'vehicle_no' => 'TN-33-DL-2001 (Tata Ace Diesel)',
                    'driver_name' => 'P. Selvam',
                    'driver_phone' => '9842100020',
                    'daily_avg_cans' => 110,
                    'is_active' => true,
                ],
            ];

            foreach ($routes as $route) {
                if ($dkWatersCompanyId !== null && isset($routeColumns['company_id'])) {
                    $route['company_id'] = $dkWatersCompanyId;
                }
                $existing = DB::table('water_can_routes')->where('route_name', $route['route_name'])->first();
                $payload = array_intersect_key($route + [
                    'updated_at' => $now,
                    'created_at' => $existing->created_at ?? $now,
                ], $routeColumns);

                DB::table('water_can_routes')->updateOrInsert(
                    ['route_name' => $route['route_name']],
                    $payload
                );
            }
        }
    }

    private function resolveCompanyId(string $profileKey, array $codes, string $nameLike): ?int
    {
        if (
            Schema::hasTable('company_industry_settings')
            && Schema::hasColumn('company_industry_settings', 'profile_key')
            && Schema::hasColumn('company_industry_settings', 'company_id')
        ) {
            $companyId = DB::table('company_industry_settings')
                ->where('profile_key', $profileKey)
                ->value('company_id');
            if ($companyId) {
                return (int) $companyId;
            }
        }

        if (Schema::hasTable('companies')) {
            if (Schema::hasColumn('companies', 'code')) {
                $companyId = DB::table('companies')
                    ->whereIn('code', $codes)
                    ->value('id');
                if ($companyId) {
                    return (int) $companyId;
                }
            }

            if (Schema::hasColumn('companies', 'trade_name') && Schema::hasColumn('companies', 'legal_name')) {
                $companyId = DB::table('companies')
                    ->where('trade_name', 'like', $nameLike)
                    ->orWhere('legal_name', 'like', $nameLike)
                    ->value('id');
                if ($companyId) {
                    return (int) $companyId;
                }
            }
        }

        return null;
    }
}
