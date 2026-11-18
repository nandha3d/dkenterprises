<?php

namespace Database\Seeders;

use App\Services\ERP\VerticalSaleSyncService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Cleans accumulated test customers/orders and seeds realistic,
 * GPS-tagged Madurai & regional customers, 14-day synced ERP+GST sales history,
 * clear Paid/Due/Overdue balances, and clean open orders for all 3 companies.
 */
class CleanGpsCustomersAndOrdersSeeder extends Seeder
{
    public function run(): void
    {
        $sync = app(VerticalSaleSyncService::class);
        $isMysql = DB::getDriverName() === 'mysql';

        if ($isMysql) {
            DB::statement('SET FOREIGN_KEY_CHECKS=0');
        }

        try {
            // 1. Clear operational & test transaction clutter cleanly (never touch master setup/users/COA)
            $companyIds = [1, 2, 3];

            if (Schema::hasTable('gst_transaction_projections')) {
                DB::table('gst_transaction_projections')->whereIn('company_id', $companyIds)->delete();
            }
            if (Schema::hasTable('payments')) {
                DB::table('payments')->whereIn('company_id', $companyIds)->delete();
            }
            if (Schema::hasTable('product_sales')) {
                DB::table('product_sales')->whereIn('company_id', $companyIds)->delete();
            }
            if (Schema::hasTable('sales')) {
                DB::table('sales')->whereIn('company_id', $companyIds)->delete();
            }
            if (Schema::hasTable('journal_entries')) {
                $staleEntryIds = DB::table('journal_entries')
                    ->whereIn('company_id', $companyIds)
                    ->where('reference_type', '!=', 'migration_opening')
                    ->pluck('id');
                if ($staleEntryIds->isNotEmpty()) {
                    DB::table('journal_items')->whereIn('journal_entry_id', $staleEntryIds)->delete();
                    DB::table('journal_entries')->whereIn('id', $staleEntryIds)->delete();
                }
            }

            foreach ([
                'water_can_deliveries',
                'water_tanker_trips',
                'water_can_inventories',
                'water_can_driver_surrenders',
                'water_can_plant_intakes',
                'notifications',
            ] as $tbl) {
                if (Schema::hasTable($tbl)) {
                    DB::table($tbl)->delete();
                }
            }

            // Remove duplicate/test customers while keeping Walk-in Customer (id=1)
            DB::table('customers')->where('id', '>', 1)->delete();
        } finally {
            if ($isMysql) {
                DB::statement('SET FOREIGN_KEY_CHECKS=1');
            }
        }

        // 2. Ensure HSN/SAC codes exist for operational items
        $this->ensureHsnAndProductCodes();

        // 3. Give vehicles real Madurai starting GPS positions
        $this->seedFleetPositions();

        // 4. Seed Company 3 (DK Waters - 20L Packaged Cans)
        $this->seedDkWaters($sync);

        // 5. Seed Company 2 (TMWS - Bulk Commercial Water Tankers)
        $this->seedTmwsTankers($sync);

        // 6. Seed Company 1 (Aran Cafe - Counter POS & Catering)
        $this->seedAranCafe($sync);
    }

    private function ensureHsnAndProductCodes(): void
    {
        if (Schema::hasTable('hsn_sac_codes')) {
            $codes = [
                ['company_id' => 3, 'code' => '22019010', 'kind' => 'hsn', 'description' => 'Packaged Drinking Water 20L Cans & Bottles'],
                ['company_id' => 2, 'code' => '22019090', 'kind' => 'hsn', 'description' => 'Bulk RO / Commercial Non-Packaged Water'],
                ['company_id' => 2, 'code' => '996519', 'kind' => 'sac', 'description' => 'Bulk Water Tanker Freight & Pumping Services'],
                ['company_id' => 1, 'code' => '996331', 'kind' => 'sac', 'description' => 'Cafe Beverage & Bakery Restaurant Service'],
            ];
            foreach ($codes as $row) {
                DB::table('hsn_sac_codes')->updateOrInsert(
                    ['company_id' => $row['company_id'], 'code' => $row['code']],
                    [
                        'kind' => $row['kind'],
                        'description' => $row['description'],
                        'updated_at' => now(),
                        'created_at' => now(),
                    ]
                );
            }
        }

        if (Schema::hasColumn('products', 'hsn_code')) {
            DB::table('products')->where('company_id', 1)->whereNull('hsn_code')->update(['hsn_code' => '996331']);
            DB::table('products')->where('company_id', 2)->where('code', 'like', 'BW-%')->update(['hsn_code' => '22019090']);
            DB::table('products')->where('company_id', 2)->where('code', 'like', 'SRV-%')->update(['hsn_code' => '996519']);
            DB::table('products')->where('company_id', 3)->whereNull('hsn_code')->update(['hsn_code' => '22019010']);
        }
    }

    private function seedFleetPositions(): void
    {
        if (Schema::hasTable('water_can_routes')) {
            DB::table('water_can_routes')->where('id', 1)->update([
                'latitude' => 9.9195,
                'longitude' => 78.1462,
                'current_speed' => 18.5,
                'last_ping_at' => now()->subMinutes(2),
            ]);
            DB::table('water_can_routes')->where('id', 2)->update([
                'latitude' => 9.9398,
                'longitude' => 78.1512,
                'current_speed' => 22.0,
                'last_ping_at' => now()->subMinutes(1),
            ]);
        }

        if (Schema::hasTable('water_tankers')) {
            DB::table('water_tankers')->where('id', 1)->update([
                'latitude' => 9.9145,
                'longitude' => 78.0960,
                'current_speed' => 34,
                'last_ping_at' => now()->subMinutes(1),
            ]);
            DB::table('water_tankers')->where('id', 2)->update([
                'latitude' => 9.8825,
                'longitude' => 78.0815,
                'current_speed' => 42,
                'last_ping_at' => now()->subMinutes(3),
            ]);
            DB::table('water_tankers')->where('id', 3)->update([
                'latitude' => 9.9480,
                'longitude' => 78.1635,
                'current_speed' => 0,
                'last_ping_at' => now()->subMinutes(8),
            ]);
        }
    }

    private function insertCustomer(array $data): int
    {
        return (int) DB::table('customers')->insertGetId(array_merge([
            'user_id' => null,
            'type' => 'regular',
            'country' => 'India',
            'state' => 'Tamil Nadu',
            'opening_balance' => 0,
            'geofence_radius' => 150,
            'is_active' => 1,
            'bill_by_bill' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ], $data));
    }

    private function seedDkWaters(VerticalSaleSyncService $sync): void
    {
        $groupId = (int) (DB::table('customer_groups')->where('company_id', 3)->value('id') ?: 10);
        $driverUserId = (int) (DB::table('users')->where('name', 'driver')->value('id') ?: 2);

        $dkCustomers = [
            // [name, company_name, phone, address, city, lat, lng, tax_no, cans_held, deposit, rate, profile(paid|due|overdue)]
            ['Sri Meenakshi Mess & Bhavan', 'Sri Meenakshi Foods', '9842111001', '42 East Masi Street, Teppakulam', 'Madurai', 9.9154, 78.1445, '33AABSM1001E1Z4', 18, 2700, 35, 'paid'],
            ['Madurai Ortho Speciality Clinic', 'Ortho Care Clinic', '9842111002', '18 LIG Colony, Anna Nagar', 'Madurai', 9.9278, 78.1469, '33AABCM1002E1Z2', 24, 3600, 35, 'due'],
            ['Hotel Supreme Residency', 'Supreme Hospitality', '9842111003', '110 West Perumal Maistry St', 'Madurai', 9.9189, 78.1138, '33AABCS1003E1Z8', 30, 4500, 34, 'overdue'],
            ['Bharath Coaching Academy', 'Bharath Education Trust', '9842111004', '24 80 Feet Road, KK Nagar', 'Madurai', 9.9362, 78.1455, null, 15, 2250, 35, 'paid'],
            ['Lakshmi Dental & Scan Centre', 'Lakshmi Diagnostics', '9842111005', '9 Alagar Kovil Main Rd, Tallakulam', 'Madurai', 9.9355, 78.1328, '33AABCL1005E1Z5', 14, 2100, 36, 'due'],
            ['Amman Tex Showrooms', 'Amman Apparels', '9842111006', '78 South Avani Moola St', 'Madurai', 9.9152, 78.1204, '33AABCA1006E1Z9', 20, 3000, 35, 'paid'],
            ['Sathya Gym & Fitness Hub', 'Sathya Fitness', '9842111007', '56 Bypass Road, Ponmeni', 'Madurai', 9.9192, 78.0956, null, 12, 1800, 38, 'overdue'],
            ['Kalpana Ladies Hostel', 'Kalpana Accommodation', '9842111008', '11 Natham Road, Bibikulam', 'Madurai', 9.9442, 78.1318, null, 28, 4200, 34, 'due'],
            ['Nehru Opticals & Pharmacy', 'Nehru Health Retail', '9842111009', '33 Palace Road, Simmakkal', 'Madurai', 9.9250, 78.1246, '33AABCN1009E1Z1', 10, 1500, 36, 'paid'],
            ['Pandian Polytech Campus', 'Pandian Campus', '9842111010', '88 Lake View Road, Mattuthavani', 'Madurai', 9.9438, 78.1558, '33AABCP1010E1Z6', 22, 3300, 35, 'paid'],
        ];

        $seededIds = [];
        foreach ($dkCustomers as $idx => $c) {
            [$name, $compName, $phone, $addr, $city, $lat, $lng, $gstin, $cansHeld, $dep, $rate, $profile] = $c;
            $cid = $this->insertCustomer([
                'customer_group_id' => $groupId,
                'company_id' => 3,
                'name' => $name,
                'print_name' => $name,
                'company_name' => $compName,
                'phone_number' => $phone,
                'wa_number' => $phone,
                'tax_no' => $gstin,
                'address' => $addr,
                'city' => $city,
                'postal_code' => '625020',
                'latitude' => $lat,
                'longitude' => $lng,
                'deposit' => $dep,
                'credit_limit' => 25000,
                'credit_days' => 10,
            ]);
            $seededIds[] = ['id' => $cid, 'data' => $c, 'route_id' => ($idx % 2) + 1];

            DB::table('water_can_inventories')->insert([
                'customer_id' => $cid,
                'total_cans_held' => $cansHeld,
                'deposit_held' => $dep,
                'last_delivery_date' => now()->subDays(1)->toDateString(),
                'can_variance_detected' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // Morning plant intake for today so driver van capacity matches route stock
        if (Schema::hasTable('water_can_plant_intakes')) {
            DB::table('water_can_plant_intakes')->insert([
                'route_id' => 1,
                'driver_id' => $driverUserId,
                'plant_name' => 'DK Waters RO Mother Plant (Melur)',
                'load_sequence' => 2,
                'cans_loaded' => 20,
                'purchase_rate_per_can' => 8.0,
                'intake_time' => now()->subHours(2),
                'notes' => 'Mid-day batch refill from RO Mother Plant',
                'created_at' => now()->subHours(2),
                'updated_at' => now()->subHours(2),
            ]);
        }

        // Seed 14 days of completed deliveries synced cleanly into ERP `sales` + `gst_transaction_projections`
        $seq = 1;
        for ($dayOffset = 13; $dayOffset >= 0; $dayOffset--) {
            $dateObj = now()->subDays($dayOffset);
            $dateStr = $dateObj->toDateString();
            // 3 deliveries per day cycling through customers so every day in 14D graph is populated
            for ($slot = 0; $slot < 3; $slot++) {
                $pick = $seededIds[($dayOffset * 3 + $slot) % count($seededIds)];
                $cid = $pick['id'];
                [$name, $compName, $phone, $addr, $city, $lat, $lng, $gstin, $cansHeld, $dep, $rate, $profile] = $pick['data'];
                $routeId = $pick['route_id'];
                $cans = 12 + (($dayOffset + $slot) % 4) * 5;
                $totalAmt = round($cans * $rate, 2);

                $isPaid = match ($profile) {
                    'paid' => true,
                    'due' => $dayOffset > 5, // older settled, recent credit due
                    'overdue' => $dayOffset < 4 ? true : false, // older >10d invoices unpaid => OVERDUE!
                };
                if ($dayOffset === 0 && $profile === 'paid' && $slot === 2) {
                    $paidAmt = $totalAmt;
                    $mode = 'UPI';
                } elseif ($isPaid) {
                    $paidAmt = $totalAmt;
                    $mode = ($seq % 2 === 0) ? 'UPI' : 'Cash';
                } else {
                    $paidAmt = 0.0;
                    $mode = 'Credit';
                }

                $delNo = 'DEL-' . $dateObj->format('Ymd') . '-' . str_pad($seq++, 3, '0', STR_PAD_LEFT);
                $delId = DB::table('water_can_deliveries')->insertGetId([
                    'delivery_no' => $delNo,
                    'delivery_date' => $dateStr,
                    'route_id' => $routeId,
                    'customer_id' => $cid,
                    'morning_loaded_cans' => 60,
                    'ordered_cans' => $cans,
                    'ordered_by' => $driverUserId,
                    'ordered_at' => $dateObj->copy()->setTime(9, 0),
                    'en_route_at' => $dateObj->copy()->setTime(10, 15),
                    'completed_at' => $dateObj->copy()->setTime(10, 45),
                    'order_source' => 'route_schedule',
                    'cans_delivered' => $cans,
                    'empty_cans_returned' => $cans - 1,
                    'can_rate' => $rate,
                    'total_amount' => $totalAmt,
                    'paid_amount' => $paidAmt,
                    'payment_mode' => $mode,
                    'balance_cans_held' => $cansHeld,
                    'status' => 'completed',
                    'delivery_lat' => $lat,
                    'delivery_lng' => $lng,
                    'created_by' => $driverUserId,
                    'created_at' => $dateObj->copy()->setTime(10, 45),
                    'updated_at' => $dateObj->copy()->setTime(10, 45),
                ]);

                $saleId = $sync->syncCompletedSale([
                    'company_id' => 3,
                    'customer_id' => $cid,
                    'user_id' => $driverUserId,
                    'reference_no' => $delNo,
                    'sale_date' => $dateStr . ' 10:45:00',
                    'paid_amount' => $paidAmt,
                    'payment_mode' => $mode,
                    'sale_type' => 'water_can',
                    'credit_days' => $isPaid ? 0 : 10,
                    'sale_note' => "20L Water Can Route Delivery ({$delNo})",
                    'items' => [[
                        'product_code' => 'CAN-20L',
                        'name' => '20L Packaged Drinking Water Can',
                        'qty' => $cans,
                        'unit_price' => $rate,
                        'hsn_sac' => '22019010',
                    ]],
                ]);
                if ($saleId > 0) {
                    DB::table('water_can_deliveries')->where('id', $delId)->update(['sale_id' => $saleId]);
                }
            }
        }

        // Seed exactly 4 clean Open Orders for today's beat (replaces the old 51 clutter count!)
        $openOrders = [
            [$seededIds[0], 12, 'ordered', 'Kitchen morning jar requirement'],
            [$seededIds[1], 10, 'ordered', 'OPD floor dispenser refill'],
            [$seededIds[3], 8, 'in_transit', 'Afternoon batch students floor'],
            [$seededIds[5], 15, 'ordered', 'Showroom weekend stock'],
        ];
        foreach ($openOrders as $oIdx => [$custMeta, $qty, $status, $note]) {
            $cid = $custMeta['id'];
            $rate = (float) $custMeta['data'][10];
            DB::table('water_can_deliveries')->insert([
                'delivery_no' => 'ORD-' . date('Ymd') . '-00' . ($oIdx + 1),
                'delivery_date' => now()->toDateString(),
                'route_id' => 1,
                'customer_id' => $cid,
                'morning_loaded_cans' => 60,
                'ordered_cans' => $qty,
                'ordered_by' => $driverUserId,
                'ordered_at' => now()->subMinutes(40 - ($oIdx * 8)),
                'en_route_at' => $status === 'in_transit' ? now()->subMinutes(10) : null,
                'order_source' => 'mobile_driver_order',
                'order_notes' => $note,
                'cans_delivered' => 0,
                'empty_cans_returned' => 0,
                'can_rate' => $rate,
                'total_amount' => round($qty * $rate, 2),
                'paid_amount' => 0.0,
                'payment_mode' => 'Cash',
                'balance_cans_held' => (int) $custMeta['data'][8],
                'status' => $status,
                'delivery_lat' => $custMeta['data'][5],
                'delivery_lng' => $custMeta['data'][6],
                'created_by' => $driverUserId,
                'created_at' => now()->subMinutes(40 - ($oIdx * 8)),
                'updated_at' => now()->subMinutes(15),
            ]);
        }
    }

    private function seedTmwsTankers(VerticalSaleSyncService $sync): void
    {
        $groupId = (int) (DB::table('customer_groups')->where('company_id', 2)->value('id') ?: 9);
        $tankerUserId = (int) (DB::table('users')->where('name', 'tanker_driver')->value('id') ?: 3);

        $tmwsSites = [
            ['Meenakshi Mission Hospital', 'Meenakshi Mission Hospital & Research', '9842200101', 'Lake Area, Melur Road, Uthangudi', 'Madurai', 9.9468, 78.1564, '33AABCM2001K1Z3', 'paid'],
            ['Thiagarajar Textile Mills', 'Thiagarajar Mills Pvt Ltd', '9842200102', 'Kappalur Industrial Estate Phase I', 'Madurai', 9.8652, 78.0485, '33AABCT2002K1Z8', 'due'],
            ['Madurai IT Park Phase II', 'ELCOT IT SEZ Campus', '9842200103', 'Ilandhaikulam Ring Road, Pandikovil', 'Madurai', 9.9325, 78.1705, '33AABCE2003K1Z1', 'paid'],
            ['Surya ReadyMix Concrete', 'Surya Infra Builders', '9842200104', 'Viraganoor Ring Road Junction', 'Madurai', 9.9035, 78.1588, '33AABCS2004K1Z5', 'overdue'],
            ['Vadamalayan Hospitals Campus', 'Vadamalayan Trust', '9842200105', 'Chokkikulam Main Road', 'Madurai', 9.9390, 78.1365, '33AABCV2005K1Z7', 'due'],
            ['HCL Tech Satellite Campus', 'HCL Madurai ODC', '9842200106', '120 Feet Road, Mattuthavani', 'Madurai', 9.9452, 78.1492, '33AABCH2006K1Z0', 'paid'],
        ];

        $sites = [];
        foreach ($tmwsSites as $s) {
            [$name, $compName, $phone, $addr, $city, $lat, $lng, $gstin, $profile] = $s;
            $cid = $this->insertCustomer([
                'customer_group_id' => $groupId,
                'company_id' => 2,
                'name' => $name,
                'print_name' => $name,
                'company_name' => $compName,
                'phone_number' => $phone,
                'wa_number' => $phone,
                'tax_no' => $gstin,
                'address' => $addr,
                'city' => $city,
                'postal_code' => '625107',
                'latitude' => $lat,
                'longitude' => $lng,
                'geofence_radius' => 200,
                'credit_limit' => 250000,
                'credit_days' => 10,
            ]);
            $sites[] = ['id' => $cid, 'data' => $s];
        }

        // 14 days of completed tanker trips synced to ERP sales + GST projections
        $odoCursor = 44600;
        $seq = 1;
        for ($dayOffset = 13; $dayOffset >= 0; $dayOffset--) {
            $dateObj = now()->subDays($dayOffset);
            $dateStr = $dateObj->toDateString();

            for ($slot = 0; $slot < 2; $slot++) {
                $pick = $sites[($dayOffset + $slot) % count($sites)];
                $cid = $pick['id'];
                [$name, $compName, $phone, $addr, $city, $lat, $lng, $gstin, $profile] = $pick['data'];
                $tankerId = ($slot % 2 === 0) ? 1 : 2;
                $kl = ($tankerId === 1) ? 20.0 : 40.0;
                $rate = ($tankerId === 1) ? 3200.0 : 5400.0;
                $tripNo = 'TMWS-' . $dateObj->format('Ymd') . '-' . str_pad($seq++, 3, '0', STR_PAD_LEFT);
                $startKm = $odoCursor;
                $endKm = $startKm + 28 + ($slot * 14);
                $odoCursor = $endKm;

                $isPaid = match ($profile) {
                    'paid' => true,
                    'due' => $dayOffset > 4,
                    'overdue' => $dayOffset < 4,
                };
                $paidAmt = $isPaid ? $rate : 0.0;
                $mode = $isPaid ? 'NEFT/UPI' : 'Credit';

                $tripId = DB::table('water_tanker_trips')->insertGetId([
                    'trip_number' => $tripNo,
                    'tanker_id' => $tankerId,
                    'customer_id' => $cid,
                    'trip_date' => $dateStr,
                    'source_plant' => 'Melur RO Borewell Plant',
                    'destination_site' => $name . ', ' . $addr,
                    'water_quantity_kl' => $kl,
                    'start_km' => $startKm,
                    'end_km' => $endKm,
                    'total_km' => $endKm - $startKm,
                    'trip_rate' => $rate,
                    'motor_pumping_minutes' => 35,
                    'motor_pumping_charge' => 350,
                    'waiting_minutes' => 0,
                    'waiting_charge' => 0,
                    'diesel_expense' => 650,
                    'toll_expense' => 80,
                    'driver_batta' => 300,
                    'site_receiver_name' => 'Site Supervisor',
                    'status' => 'completed',
                    'notes' => json_encode(['paid_amount' => $paidAmt, 'payment_mode' => $mode]),
                    'created_by' => $tankerUserId,
                    'created_at' => $dateObj->copy()->setTime(11 + $slot * 3, 20),
                    'updated_at' => $dateObj->copy()->setTime(12 + $slot * 3, 5),
                ]);

                $saleId = $sync->syncCompletedSale([
                    'company_id' => 2,
                    'customer_id' => $cid,
                    'user_id' => $tankerUserId,
                    'reference_no' => $tripNo,
                    'sale_date' => $dateStr . ' 12:00:00',
                    'paid_amount' => $paidAmt,
                    'payment_mode' => $mode,
                    'sale_type' => 'water_tanker',
                    'credit_days' => $isPaid ? 0 : 10,
                    'sale_note' => "Bulk Water Tanker Delivery ({$tripNo}) to {$name}",
                    'items' => [[
                        'product_code' => $tankerId === 1 ? 'BW-20KL' : 'BW-40KL',
                        'name' => "Commercial Bulk Water Supply ({$kl} KL Tanker)",
                        'qty' => $kl,
                        'unit_price' => round($rate / $kl, 4),
                        'hsn_sac' => '22019090',
                    ]],
                ]);
                if ($saleId > 0) {
                    DB::table('water_tanker_trips')->where('id', $tripId)->update(['sale_id' => $saleId]);
                }
            }
        }

        // Seed 2 clean active tanker dispatches for Driver Queue
        DB::table('water_tanker_trips')->insert([
            [
                'trip_number' => 'TMWS-' . date('Ymd') . '-LIVE01',
                'tanker_id' => 1,
                'customer_id' => $sites[0]['id'],
                'trip_date' => now()->toDateString(),
                'source_plant' => 'Melur RO Borewell Plant',
                'destination_site' => $sites[0]['data'][0],
                'water_quantity_kl' => 20.0,
                'start_km' => 45200,
                'end_km' => 45200,
                'total_km' => 0,
                'trip_rate' => 3200.0,
                'status' => 'assigned',
                'notes' => json_encode(['dispatch_priority' => 'high', 'order_note' => 'Hospital emergency sump top-up']),
                'created_by' => 1,
                'created_at' => now()->subMinutes(25),
                'updated_at' => now()->subMinutes(25),
            ],
            [
                'trip_number' => 'TMWS-' . date('Ymd') . '-LIVE02',
                'tanker_id' => 1,
                'customer_id' => $sites[1]['id'],
                'trip_date' => now()->toDateString(),
                'source_plant' => 'Melur RO Borewell Plant',
                'destination_site' => $sites[1]['data'][0],
                'water_quantity_kl' => 20.0,
                'start_km' => 45200,
                'end_km' => 45218,
                'total_km' => 18,
                'trip_rate' => 3500.0,
                'status' => 'in_transit',
                'notes' => json_encode(['dispatch_priority' => 'normal', 'order_note' => 'Dyeing unit overhead tank']),
                'created_by' => 1,
                'created_at' => now()->subMinutes(10),
                'updated_at' => now()->subMinutes(10),
            ],
        ]);
    }

    private function seedAranCafe(VerticalSaleSyncService $sync): void
    {
        $groupId = (int) (DB::table('customer_groups')->where('company_id', 1)->value('id') ?: 8);
        $cashierUserId = (int) (DB::table('users')->where('name', 'cashier')->value('id') ?: 5);

        $cafeClients = [
            ['Aran IT Hub Canteen Account', 'Aran Tech Corp', '9842300101', '77 Race Course Road', 'Madurai', 9.9301, 78.1338, 'paid'],
            ['Madurai Law Chambers Tea Club', 'Chambers Association', '9842300102', '14 KK Nagar High Court Rd', 'Madurai', 9.9388, 78.1460, 'due'],
            ['Surya Clinic Staff Pantry', 'Surya Health Care', '9842300103', '29 Anna Nagar East 2nd St', 'Madurai', 9.9234, 78.1489, 'paid'],
            ['Kaveri Architecture Studio', 'Kaveri Design LLP', '9842300104', '5 Teppakulam West Tower St', 'Madurai', 9.9142, 78.1422, 'due'],
        ];

        $clientIds = [1]; // Include Walk-in Customer ID=1
        foreach ($cafeClients as $cc) {
            $clientIds[] = $this->insertCustomer([
                'customer_group_id' => $groupId,
                'company_id' => 1,
                'name' => $cc[0],
                'print_name' => $cc[0],
                'company_name' => $cc[1],
                'phone_number' => $cc[2],
                'wa_number' => $cc[2],
                'address' => $cc[3],
                'city' => $cc[4],
                'postal_code' => '625002',
                'latitude' => $cc[5],
                'longitude' => $cc[6],
                'credit_limit' => 15000,
                'credit_days' => 7,
            ]);
        }

        // Seed 14 days of Cafe POS + corporate pantry orders synced to ERP sales + GST projections
        $seq = 1;
        for ($dayOffset = 13; $dayOffset >= 0; $dayOffset--) {
            $dateObj = now()->subDays($dayOffset);
            $dateStr = $dateObj->toDateString();

            for ($slot = 0; $slot < 2; $slot++) {
                $cid = $clientIds[($dayOffset + $slot) % count($clientIds)];
                $coffeeQty = 6 + (($dayOffset + $slot) % 6) * 2;
                $croissantQty = 3 + ($dayOffset % 4);
                $totalAmt = ($coffeeQty * 25) + ($croissantQty * 60);
                $isDue = ($cid !== 1 && $slot === 1 && $dayOffset < 4);
                $paidAmt = $isDue ? 0.0 : $totalAmt;
                $mode = $isDue ? 'Credit' : (($seq % 2 === 0) ? 'UPI' : 'Cash');

                $sync->syncCompletedSale([
                    'company_id' => 1,
                    'customer_id' => $cid,
                    'user_id' => $cashierUserId,
                    'reference_no' => 'CAFE-' . $dateObj->format('Ymd') . '-' . str_pad($seq++, 3, '0', STR_PAD_LEFT),
                    'sale_date' => $dateStr . ' 16:30:00',
                    'paid_amount' => $paidAmt,
                    'payment_mode' => $mode,
                    'sale_type' => 'pos',
                    'credit_days' => $isDue ? 7 : 0,
                    'sale_note' => 'Aran Cafe Counter & Pantry Bill',
                    'items' => [
                        ['product_code' => 'CF-FILTER', 'name' => 'South Indian Filter Kaapi (Cup)', 'qty' => $coffeeQty, 'unit_price' => 25, 'hsn_sac' => '996331'],
                        ['product_code' => 'BK-CROISSANT', 'name' => 'Butter Flaky Croissant', 'qty' => $croissantQty, 'unit_price' => 60, 'hsn_sac' => '996331'],
                    ],
                ]);
            }
        }
    }
}
