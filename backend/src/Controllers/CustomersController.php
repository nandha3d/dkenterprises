<?php
declare(strict_types=1);

namespace DKTrack\Controllers;

use DKTrack\Database;
use PDO;

class CustomersController
{
    /**
     * Calculate Haversine distance in metres between two coordinates
     */
    public static function haversineDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371000; // in metres
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return round($earthRadius * $c, 2);
    }

    /**
     * Get Customers with Locked GPS Geocodes & Rate Slabs
     */
    public function getCustomers(array $queryParams = [], array $body = []): array
    {
        $customers = [
            [
                'id'                      => 1,
                'company_name'            => 'Aran Cafe - 1',
                'customer_code'           => 'CUST-CAN-001',
                'contact_person'          => 'Mr. Senthil',
                'phone'                   => '98421 55601',
                'division_type'           => 'can',
                'delivery_location_lat'   => 11.018221,
                'delivery_location_lng'   => 76.964119,
                'geofence_radius_meters'  => 75,
                'is_gps_locked'           => true,
                'default_rate_per_can'    => 20.00,
                'credit_limit'            => 5000.00,
                'current_credit_balance'  => 1420.00,
                'last_delivery_at'        => '2026-10-30 09:12:15',
                'last_geofence_status'    => 'verified',
                'last_distance_meters'    => 14.5
            ],
            [
                'id'                      => 2,
                'company_name'            => 'Aran Cafe - 2',
                'customer_code'           => 'CUST-CAN-002',
                'contact_person'          => 'Mr. Ramesh',
                'phone'                   => '98421 55602',
                'division_type'           => 'can',
                'delivery_location_lat'   => 11.021450,
                'delivery_location_lng'   => 76.968920,
                'geofence_radius_meters'  => 75,
                'is_gps_locked'           => true,
                'default_rate_per_can'    => 20.00,
                'credit_limit'            => 5000.00,
                'current_credit_balance'  => 840.00,
                'last_delivery_at'        => '2026-10-30 09:35:40',
                'last_geofence_status'    => 'verified',
                'last_distance_meters'    => 21.0
            ],
            [
                'id'                      => 3,
                'company_name'            => 'Texvalley Corporate Campus',
                'customer_code'           => 'CUST-TNK-001',
                'contact_person'          => 'Estate Manager',
                'phone'                   => '94433 12890',
                'division_type'           => 'tanker',
                'delivery_location_lat'   => 11.332400,
                'delivery_location_lng'   => 77.712100,
                'geofence_radius_meters'  => 150,
                'is_gps_locked'           => true,
                'default_rate_per_can'    => 0.00,
                'credit_limit'            => 100000.00,
                'current_credit_balance'  => 12450.00,
                'rate_slab'               => [
                    'base_fare'           => 2500.00,
                    'base_included_km'    => 15,
                    'extra_per_km_rate'   => 20.00,
                    'motor_rate_per_min'  => 5.00,
                    'wait_rate_per_min'   => 2.50
                ],
                'last_delivery_at'        => '2026-10-30 11:20:00',
                'last_geofence_status'    => 'verified',
                'last_distance_meters'    => 35.0
            ],
            [
                'id'                      => 4,
                'company_name'            => 'The Chennai Silks (Dyeing Unit)',
                'customer_code'           => 'CUST-TNK-002',
                'contact_person'          => 'Purchase Officer',
                'phone'                   => '98430 44810',
                'division_type'           => 'tanker',
                'delivery_location_lat'   => 11.084500,
                'delivery_location_lng'   => 77.294100,
                'geofence_radius_meters'  => 200,
                'is_gps_locked'           => true,
                'default_rate_per_can'    => 0.00,
                'credit_limit'            => 150000.00,
                'current_credit_balance'  => 28400.00,
                'last_delivery_at'        => '2026-10-29 16:45:00',
                'last_geofence_status'    => 'verified',
                'last_distance_meters'    => 48.0
            ],
            [
                'id'                      => 5,
                'company_name'            => 'Black Pekoe Tea',
                'customer_code'           => 'CUST-CAN-003',
                'contact_person'          => 'Mr. Kumar',
                'phone'                   => '99441 33201',
                'division_type'           => 'can',
                'delivery_location_lat'   => 11.014200,
                'delivery_location_lng'   => 76.958700,
                'geofence_radius_meters'  => 75,
                'is_gps_locked'           => true,
                'default_rate_per_can'    => 20.00,
                'credit_limit'            => 3000.00,
                'current_credit_balance'  => 360.00,
                'last_delivery_at'        => '2026-10-30 10:15:00',
                'last_geofence_status'    => 'verified',
                'last_distance_meters'    => 18.2
            ],
            [
                'id'                      => 6,
                'company_name'            => 'Santha Company (Shop)',
                'customer_code'           => 'CUST-CAN-004',
                'contact_person'          => 'Proprietor',
                'phone'                   => '97871 00293',
                'division_type'           => 'can',
                'delivery_location_lat'   => 11.026800,
                'delivery_location_lng'   => 76.974200,
                'geofence_radius_meters'  => 75,
                'is_gps_locked'           => true,
                'default_rate_per_can'    => 20.00,
                'credit_limit'            => 4000.00,
                'current_credit_balance'  => 680.00,
                'last_delivery_at'        => '2026-10-30 13:40:00',
                'last_geofence_status'    => 'mismatch', // Flagged fraud attempt
                'last_distance_meters'    => 420.0
            ]
        ];

        return [
            'success' => true,
            'count'   => count($customers),
            'data'    => $customers
        ];
    }

    /**
     * Lock or update customer shop GPS location (Anti-Fraud Geofencing)
     */
    public function geoLock(array $queryParams = [], array $body = []): array
    {
        $customerId = (int)($body['customer_id'] ?? 0);
        $lat = (float)($body['latitude'] ?? 0.0);
        $lng = (float)($body['longitude'] ?? 0.0);
        $radius = (int)($body['geofence_radius_meters'] ?? 75);

        return [
            'success' => true,
            'message' => 'Customer shop GPS location locked successfully',
            'data'    => [
                'customer_id'            => $customerId,
                'latitude'               => $lat,
                'longitude'              => $lng,
                'geofence_radius_meters' => $radius,
                'locked_at'              => date('Y-m-d H:i:s')
            ]
        ];
    }

    /**
     * Verify driver delivery GPS fix against locked customer shop geocode
     */
    public function verifyDeliveryLocation(array $queryParams = [], array $body = []): array
    {
        $shopLat = (float)($body['shop_lat'] ?? 11.018221);
        $shopLng = (float)($body['shop_lng'] ?? 76.964119);
        $deliveryLat = (float)($body['delivery_lat'] ?? 11.018250);
        $deliveryLng = (float)($body['delivery_lng'] ?? 76.964140);
        $threshold = (float)($body['threshold_meters'] ?? 75.0);

        $distMetres = self::haversineDistance($shopLat, $shopLng, $deliveryLat, $deliveryLng);
        $isWithin = $distMetres <= $threshold;

        return [
            'success'          => true,
            'status'           => $isWithin ? 'verified' : 'mismatch',
            'within_threshold' => $isWithin,
            'distance_meters'  => $distMetres,
            'threshold_meters' => $threshold,
            'message'          => $isWithin 
                ? "Delivery verified within {$distMetres}m of shop." 
                : "FRAUD ALERT: Delivery attempted {$distMetres}m away from locked shop geocode!"
        ];
    }
}
