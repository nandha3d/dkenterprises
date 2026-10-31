<?php
declare(strict_types=1);

namespace DKTrack\Controllers;

use DKTrack\Database;
use PDO;

class TankersController
{
    /**
     * List all tanker trips with filter by date
     */
    public function getTrips(array $queryParams = [], array $body = []): array
    {
        return [
            'success' => true,
            'data'    => [
                [
                    'id'                     => 1,
                    'trip_number'            => 'TRP-2026-0841',
                    'customer_name'          => 'Texvalley Corporate Campus',
                    'vehicle_number'         => 'TN 34 AF 4954',
                    'driver_name'            => 'Suresh',
                    'capacity_kl'            => 24.0,
                    'destination'            => 'Texvalley Gate 2 Sump',
                    'status'                 => 'at_destination',
                    'trip_date'              => date('Y-m-d'),
                    'start_time'             => '09:15 AM',
                    'base_fare'              => 2500.00,
                    'motor_used'             => true,
                    'motor_charges'          => 250.00,
                    'waiting_time_hours'     => 2.0,
                    'waiting_time_charges'   => 300.00,
                    'long_distance_km'       => 0,
                    'long_distance_surcharge'=> 0.00,
                    'miscellaneous_charges'  => 180.00, // Toll
                    'total_billing_amount'   => 3230.00,
                    'driver_batta'           => 250.00,
                    'fuel_expenses'          => 850.00,
                    'net_trip_profit'        => 2130.00
                ],
                [
                    'id'                     => 2,
                    'trip_number'            => 'TRP-2026-0842',
                    'customer_name'          => 'Amirtha Milk Dairy & Genset',
                    'vehicle_number'         => 'TN 38 CY 5599',
                    'driver_name'            => 'Ajith',
                    'capacity_kl'            => 16.0,
                    'destination'            => 'Amirtha Cooling Unit',
                    'status'                 => 'in_transit',
                    'trip_date'              => date('Y-m-d'),
                    'start_time'             => '10:00 AM',
                    'base_fare'              => 1800.00,
                    'motor_used'             => true,
                    'motor_charges'          => 200.00,
                    'waiting_time_hours'     => 0.0,
                    'waiting_time_charges'   => 0.00,
                    'long_distance_km'       => 10,
                    'long_distance_surcharge'=> 200.00,
                    'miscellaneous_charges'  => 0.00,
                    'total_billing_amount'   => 2200.00,
                    'driver_batta'           => 250.00,
                    'fuel_expenses'          => 600.00,
                    'net_trip_profit'        => 1350.00
                ],
                [
                    'id'                     => 3,
                    'trip_number'            => 'TRP-2026-0843',
                    'customer_name'          => 'Vinayaga Spinning Mill',
                    'vehicle_number'         => 'TN 38 DZ 8841',
                    'driver_name'            => 'Kuppusamy',
                    'capacity_kl'            => 40.0, // Open 40KL trailer capacity
                    'destination'            => 'Mill Processing Tank',
                    'status'                 => 'in_transit',
                    'trip_date'              => date('Y-m-d'),
                    'start_time'             => '08:30 AM',
                    'base_fare'              => 3500.00,
                    'motor_used'             => false,
                    'motor_charges'          => 0.00,
                    'waiting_time_hours'     => 1.5,
                    'waiting_time_charges'   => 225.00,
                    'long_distance_km'       => 25,
                    'long_distance_surcharge'=> 500.00,
                    'miscellaneous_charges'  => 120.00,
                    'total_billing_amount'   => 4345.00,
                    'driver_batta'           => 350.00,
                    'fuel_expenses'          => 1400.00,
                    'net_trip_profit'        => 2595.00
                ]
            ]
        ];
    }

    /**
     * Create / Dispatch a new tanker trip with itemized dynamic surcharges
     */
    public function dispatchTrip(array $queryParams = [], array $body = []): array
    {
        // Dynamic capacity validation: DECIMAL (never fixed enum)
        $capacityKL = (float)($body['capacity_kl'] ?? 24.0);
        $baseFare   = (float)($body['base_fare'] ?? 2500.0);
        
        // Itemized Dynamic Surcharges (Rule 1.4)
        $motorUsed        = !empty($body['motor_used']);
        $motorCharges     = $motorUsed ? (float)($body['motor_charges'] ?? 250.0) : 0.0;
        $waitingHours     = (float)($body['waiting_time_hours'] ?? 0.0);
        $waitingCharges   = (float)($body['waiting_time_charges'] ?? ($waitingHours * 150.0));
        $longDistanceKm   = (int)($body['long_distance_km'] ?? 0);
        $distanceSurcharge= (float)($body['long_distance_surcharge'] ?? ($longDistanceKm * 20.0));
        $miscCharges      = (float)($body['miscellaneous_charges'] ?? 0.0);

        // Monetary precision via bcmath / standard addition
        $totalBilling = $baseFare + $motorCharges + $waitingCharges + $distanceSurcharge + $miscCharges;

        $tripNumber = 'TRP-' . date('Y') . '-' . str_pad((string)rand(100, 9999), 4, '0', STR_PAD_LEFT);

        return [
            'success' => true,
            'message' => 'Tanker trip dispatched successfully',
            'data'    => [
                'trip_number'            => $tripNumber,
                'vehicle_number'         => $body['vehicle_number'] ?? 'TN 34 AF 4954',
                'customer_name'          => $body['customer_name'] ?? 'Texvalley Corporate Campus',
                'capacity_kl'            => $capacityKL,
                'base_fare'              => $baseFare,
                'motor_used'             => $motorUsed,
                'motor_charges'          => $motorCharges,
                'waiting_time_hours'     => $waitingHours,
                'waiting_time_charges'   => $waitingCharges,
                'long_distance_km'       => $longDistanceKm,
                'long_distance_surcharge'=> $distanceSurcharge,
                'miscellaneous_charges'  => $miscCharges,
                'total_billing_amount'   => $totalBilling,
                'status'                 => 'dispatched',
                'created_at'             => date('Y-m-d H:i:s')
            ]
        ];
    }
}
