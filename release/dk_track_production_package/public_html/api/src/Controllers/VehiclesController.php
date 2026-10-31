<?php
declare(strict_types=1);

namespace DKTrack\Controllers;

use DKTrack\Database;
use PDO;

class VehiclesController
{
    /**
     * Get All Trucks & Vehicles across DK Enterprises
     */
    public function getVehicles(array $queryParams = [], array $body = []): array
    {
        $division = $queryParams['division'] ?? 'all';

        $vehicles = [
            // Tanker Fleet (5 Active + 2 Standby)
            [
                'id'                 => 1,
                'vehicle_number'     => 'TN 34 AF 4954',
                'vehicle_type'       => 'tanker',
                'division'           => 'Bulk Water Tanker',
                'capacity_kl'        => 24.0,
                'driver_name'        => 'Suresh',
                'driver_phone'       => '98422 10101',
                'status'             => 'moving',
                'odometer_km'        => 142870,
                'fuel_tank_capacity' => 200,
                'fc_expiry_date'     => '2027-04-15',
                'fc_days_remaining'  => 167,
                'insurance_expiry'   => '2027-08-20',
                'insurance_status'   => 'VALID',
                'last_speed_kmh'     => 42.0,
                'last_latitude'      => 11.0182,
                'last_longitude'     => 76.9641,
                'last_ping_ago'      => '2 mins ago'
            ],
            [
                'id'                 => 2,
                'vehicle_number'     => 'TN 38 CY 5599',
                'vehicle_type'       => 'tanker',
                'division'           => 'Bulk Water Tanker',
                'capacity_kl'        => 16.0,
                'driver_name'        => 'Palanisamy',
                'driver_phone'       => '98422 10102',
                'status'             => 'moving',
                'odometer_km'        => 218450,
                'fuel_tank_capacity' => 150,
                'fc_expiry_date'     => '2027-02-10',
                'fc_days_remaining'  => 103,
                'insurance_expiry'   => '2027-05-15',
                'insurance_status'   => 'VALID',
                'last_speed_kmh'     => 38.5,
                'last_latitude'      => 11.0421,
                'last_longitude'     => 76.9912,
                'last_ping_ago'      => '5 mins ago'
            ],
            [
                'id'                 => 3,
                'vehicle_number'     => 'TN 38 DZ 8841',
                'vehicle_type'       => 'tanker',
                'division'           => 'Bulk Water Tanker',
                'capacity_kl'        => 40.0, // Open capacity (40KL Semi-Trailer)
                'driver_name'        => 'Karthik',
                'driver_phone'       => '98422 10103',
                'status'             => 'moving',
                'odometer_km'        => 98400,
                'fuel_tank_capacity' => 350,
                'fc_expiry_date'     => '2027-11-30',
                'fc_days_remaining'  => 396,
                'insurance_expiry'   => '2027-12-15',
                'insurance_status'   => 'VALID',
                'last_speed_kmh'     => 45.0,
                'last_latitude'      => 11.1023,
                'last_longitude'     => 77.0145,
                'last_ping_ago'      => '1 min ago'
            ],
            [
                'id'                 => 4,
                'vehicle_number'     => 'TN 34 BF 1120',
                'vehicle_type'       => 'tanker',
                'division'           => 'Bulk Water Tanker',
                'capacity_kl'        => 9.0,
                'driver_name'        => 'Murugesan',
                'driver_phone'       => '98422 10104',
                'status'             => 'stopped',
                'odometer_km'        => 312000,
                'fuel_tank_capacity' => 120,
                'fc_expiry_date'     => '2026-11-20',
                'fc_days_remaining'  => 21, // Renewal due warning
                'insurance_expiry'   => '2027-03-10',
                'insurance_status'   => 'RENEWAL_DUE',
                'last_speed_kmh'     => 0.0,
                'last_latitude'      => 11.0089,
                'last_longitude'     => 76.9540,
                'last_ping_ago'      => '12 mins ago'
            ],
            [
                'id'                 => 5,
                'vehicle_number'     => 'TN 38 ER 3321',
                'vehicle_type'       => 'tanker',
                'division'           => 'Bulk Water Tanker',
                'capacity_kl'        => 28.0,
                'driver_name'        => 'Shanmugam',
                'driver_phone'       => '98422 10105',
                'status'             => 'moving',
                'odometer_km'        => 165200,
                'fuel_tank_capacity' => 220,
                'fc_expiry_date'     => '2027-06-18',
                'fc_days_remaining'  => 231,
                'insurance_expiry'   => '2027-09-05',
                'insurance_status'   => 'VALID',
                'last_speed_kmh'     => 34.0,
                'last_latitude'      => 11.0311,
                'last_longitude'     => 76.9722,
                'last_ping_ago'      => '3 mins ago'
            ],
            // Standby Tankers
            [
                'id'                 => 6,
                'vehicle_number'     => 'TN 38 AZ 9901',
                'vehicle_type'       => 'tanker',
                'division'           => 'Bulk Water Tanker',
                'capacity_kl'        => 16.0,
                'driver_name'        => 'Yard Spare Driver',
                'driver_phone'       => '98422 10106',
                'status'             => 'standby',
                'odometer_km'        => 284100,
                'fuel_tank_capacity' => 150,
                'fc_expiry_date'     => '2027-09-12',
                'fc_days_remaining'  => 317,
                'insurance_expiry'   => '2027-10-01',
                'insurance_status'   => 'VALID',
                'last_speed_kmh'     => 0.0,
                'last_latitude'      => 11.0182,
                'last_longitude'     => 76.9641,
                'last_ping_ago'      => '45 mins ago'
            ],
            [
                'id'                 => 7,
                'vehicle_number'     => 'TN 34 CX 4410',
                'vehicle_type'       => 'tanker',
                'division'           => 'Bulk Water Tanker',
                'capacity_kl'        => 12.0,
                'driver_name'        => 'Under Maintenance',
                'driver_phone'       => '-',
                'status'             => 'maintenance',
                'odometer_km'        => 342100,
                'fuel_tank_capacity' => 120,
                'fc_expiry_date'     => '2026-12-05',
                'fc_days_remaining'  => 36,
                'insurance_expiry'   => '2027-01-15',
                'insurance_status'   => 'VALID',
                'last_speed_kmh'     => 0.0,
                'last_latitude'      => 11.0200,
                'last_longitude'     => 76.9650,
                'last_ping_ago'      => '3 hours ago'
            ],
            // Can Distribution Truck
            [
                'id'                 => 8,
                'vehicle_number'     => 'TN 38 BX 4412',
                'vehicle_type'       => 'can_truck',
                'division'           => '20L Water Can Distribution',
                'capacity_cans'      => 70, // Cans capacity per trip
                'driver_name'        => 'Vignesh',
                'driver_phone'       => '97871 44120',
                'status'             => 'moving',
                'odometer_km'        => 12485,
                'fuel_tank_capacity' => 30,
                'fc_expiry_date'     => '2027-10-10',
                'fc_days_remaining'  => 345,
                'insurance_expiry'   => '2027-11-01',
                'insurance_status'   => 'VALID',
                'last_speed_kmh'     => 28.0,
                'last_latitude'      => 11.0182,
                'last_longitude'     => 76.9641,
                'last_ping_ago'      => 'Just now'
            ]
        ];

        if ($division !== 'all') {
            $vehicles = array_values(array_filter($vehicles, fn($v) => $v['vehicle_type'] === $division));
        }

        return [
            'success' => true,
            'count'   => count($vehicles),
            'data'    => $vehicles
        ];
    }

    /**
     * Add or Update Truck Details
     */
    public function saveVehicle(array $queryParams = [], array $body = []): array
    {
        $vehicleNumber = strtoupper(trim($body['vehicle_number'] ?? ''));
        $capacity = (float)($body['capacity_kl'] ?? 0.0);
        $type = $body['vehicle_type'] ?? 'tanker';

        return [
            'success' => true,
            'message' => 'Vehicle registered / updated successfully',
            'data'    => [
                'id'             => Date('U'),
                'vehicle_number' => $vehicleNumber,
                'vehicle_type'   => $type,
                'capacity_kl'    => $capacity,
                'status'         => 'standby'
            ]
        ];
    }
}
