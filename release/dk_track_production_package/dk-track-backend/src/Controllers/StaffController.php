<?php
declare(strict_types=1);

namespace DKTrack\Controllers;

use DKTrack\Database;
use PDO;

class StaffController
{
    /**
     * Get All Staff, Drivers & Delivery Boys across DK Enterprises
     */
    public function getStaff(array $queryParams = [], array $body = []): array
    {
        $division = $queryParams['division'] ?? 'all';

        $staff = [
            // Tanker Heavy Drivers
            [
                'id'               => 1,
                'name'             => 'Suresh Kumar',
                'role'             => 'tanker_driver',
                'role_display'     => 'Senior Tanker Driver',
                'division'         => 'tanker',
                'phone'            => '98422 10101',
                'assigned_vehicle' => 'TN 34 AF 4954 (24 KL)',
                'wage_type'        => 'monthly',
                'base_wage'        => 22000.0,
                'batta_rate'       => 250.0,
                'advance_balance'  => 2000.0,
                'license_number'   => 'TN-34-2015-004128',
                'badge_expiry'     => '2028-11-20',
                'is_active'        => true,
                'joined_date'      => '2023-04-10'
            ],
            [
                'id'               => 2,
                'name'             => 'Palanisamy M.',
                'role'             => 'tanker_driver',
                'role_display'     => 'Tanker Driver',
                'division'         => 'tanker',
                'phone'            => '98422 10102',
                'assigned_vehicle' => 'TN 38 CY 5599 (16 KL)',
                'wage_type'        => 'monthly',
                'base_wage'        => 20000.0,
                'batta_rate'       => 250.0,
                'advance_balance'  => 1500.0,
                'license_number'   => 'TN-38-2018-009941',
                'badge_expiry'     => '2027-08-15',
                'is_active'        => true,
                'joined_date'      => '2024-01-15'
            ],
            [
                'id'               => 3,
                'name'             => 'Karthik Raja',
                'role'             => 'tanker_driver',
                'role_display'     => 'Heavy Trailer Driver (40KL)',
                'division'         => 'tanker',
                'phone'            => '98422 10103',
                'assigned_vehicle' => 'TN 38 DZ 8841 (40 KL)',
                'wage_type'        => 'monthly',
                'base_wage'        => 26000.0,
                'batta_rate'       => 300.0,
                'advance_balance'  => 0.0,
                'license_number'   => 'TN-38-2012-001284',
                'badge_expiry'     => '2029-03-10',
                'is_active'        => true,
                'joined_date'      => '2022-08-01'
            ],
            [
                'id'               => 4,
                'name'             => 'Murugesan K.',
                'role'             => 'tanker_driver',
                'role_display'     => 'Tanker Driver',
                'division'         => 'tanker',
                'phone'            => '98422 10104',
                'assigned_vehicle' => 'TN 34 BF 1120 (9 KL)',
                'wage_type'        => 'monthly',
                'base_wage'        => 19000.0,
                'batta_rate'       => 250.0,
                'advance_balance'  => 800.0,
                'license_number'   => 'TN-34-2019-006712',
                'badge_expiry'     => '2027-05-22',
                'is_active'        => true,
                'joined_date'      => '2024-06-12'
            ],

            // 20L Can Delivery Boys
            [
                'id'               => 5,
                'name'             => 'Vigneshwaran (Vicky)',
                'role'             => 'can_delivery_boy',
                'role_display'     => 'Can Delivery Route Lead',
                'division'         => 'can',
                'phone'            => '97871 44120',
                'assigned_vehicle' => 'TN 38 BX 4412 (Tata Ace)',
                'wage_type'        => 'daily',
                'base_wage'        => 1000.0,
                'batta_rate'       => 50.0,
                'advance_balance'  => 1200.0,
                'license_number'   => 'TN-38-2021-008123',
                'badge_expiry'     => '2031-10-10',
                'is_active'        => true,
                'joined_date'      => '2024-03-01'
            ],
            [
                'id'               => 6,
                'name'             => 'Raja Sundaram',
                'role'             => 'can_delivery_boy',
                'role_display'     => 'Can Delivery Helper & Loader',
                'division'         => 'can',
                'phone'            => '97871 44122',
                'assigned_vehicle' => 'TN 38 BX 4412 (Tata Ace)',
                'wage_type'        => 'daily',
                'base_wage'        => 650.0,
                'batta_rate'       => 0.0,
                'advance_balance'  => 500.0,
                'is_active'        => true,
                'joined_date'      => '2024-09-01'
            ],

            // Bakery & Store Staff
            [
                'id'               => 7,
                'name'             => 'Kavin Anna',
                'role'             => 'bakery_counter',
                'role_display'     => 'Store Counter & Closing In-Charge',
                'division'         => 'bakery',
                'phone'            => '98421 00001',
                'wage_type'        => 'monthly',
                'base_wage'        => 25000.0,
                'advance_balance'  => 0.0,
                'is_active'        => true,
                'joined_date'      => '2020-01-01'
            ],
            [
                'id'               => 8,
                'name'             => 'Selvam Master',
                'role'             => 'kitchen_cook',
                'role_display'     => 'Master Baker & Tea Maker',
                'division'         => 'bakery',
                'phone'            => '94420 88123',
                'wage_type'        => 'monthly',
                'base_wage'        => 18000.0,
                'advance_balance'  => 1000.0,
                'is_active'        => true,
                'joined_date'      => '2023-02-15'
            ],
            [
                'id'               => 9,
                'name'             => 'Paati (Periyamma)',
                'role'             => 'store_helper',
                'role_display'     => 'Store Helper & Dishwashing',
                'division'         => 'bakery',
                'phone'            => 'Store Assistant',
                'wage_type'        => 'daily',
                'base_wage'        => 350.0,
                'advance_balance'  => 150.0,
                'is_active'        => true,
                'joined_date'      => '2023-05-10'
            ]
        ];

        if ($division !== 'all') {
            $staff = array_values(array_filter($staff, fn($s) => $s['division'] === $division));
        }

        return [
            'success' => true,
            'count'   => count($staff),
            'data'    => $staff
        ];
    }

    /**
     * Daily Attendance Log
     */
    public function getAttendance(array $queryParams = [], array $body = []): array
    {
        $date = $queryParams['date'] ?? date('Y-m-d');

        return [
            'success' => true,
            'date'    => $date,
            'data'    => [
                ['id' => 1, 'staff_name' => 'Suresh Kumar', 'division' => 'tanker', 'check_in' => '07:30 AM', 'status' => 'on_trip', 'notes' => 'Texvalley Trip (24KL)'],
                ['id' => 2, 'staff_name' => 'Palanisamy M.', 'division' => 'tanker', 'check_in' => '08:00 AM', 'status' => 'on_trip', 'notes' => 'Amirtha Milk Trip (16KL)'],
                ['id' => 3, 'staff_name' => 'Karthik Raja', 'division' => 'tanker', 'check_in' => '07:00 AM', 'status' => 'on_trip', 'notes' => 'Vinayaga Mill Trip (40KL)'],
                ['id' => 4, 'staff_name' => 'Murugesan K.', 'division' => 'tanker', 'check_in' => '08:15 AM', 'status' => 'half_day', 'notes' => 'Half-day RTO test'],
                ['id' => 5, 'staff_name' => 'Vigneshwaran (Vicky)', 'division' => 'can', 'check_in' => '08:00 AM', 'status' => 'present', 'notes' => '3 plant loads completed'],
                ['id' => 6, 'staff_name' => 'Raja Sundaram', 'division' => 'can', 'check_in' => '08:05 AM', 'status' => 'present', 'notes' => 'Delivery helper on Ace'],
                ['id' => 7, 'staff_name' => 'Kavin Anna', 'division' => 'bakery', 'check_in' => '06:30 AM', 'status' => 'present', 'notes' => 'Counter in-charge'],
                ['id' => 8, 'staff_name' => 'Selvam Master', 'division' => 'bakery', 'check_in' => '05:30 AM', 'status' => 'present', 'notes' => 'Tea & baking batch'],
                ['id' => 9, 'staff_name' => 'Paati (Periyamma)', 'division' => 'bakery', 'check_in' => '09:00 AM', 'status' => 'present', 'notes' => 'Evening ₹350 cash drawer']
            ]
        ];
    }

    /**
     * Disburse Salary or Record Advance
     */
    public function disbursePayroll(array $queryParams = [], array $body = []): array
    {
        $staffId = (int)($body['staff_id'] ?? 1);
        $amount = (float)($body['net_payable'] ?? 0.0);
        $payMode = $body['payment_mode'] ?? 'canara_bank';

        return [
            'success' => true,
            'message' => 'Salary disbursement voucher logged successfully',
            'data'    => [
                'staff_id'     => $staffId,
                'net_payable'  => $amount,
                'payment_mode' => $payMode,
                'voucher_no'   => 'PAY-DISB-' . date('Ymd-His'),
                'disbursed_at' => date('Y-m-d H:i:s')
            ]
        ];
    }

    /**
     * Request or Approve Leave
     */
    public function submitLeave(array $queryParams = [], array $body = []): array
    {
        $staffId = (int)($body['staff_id'] ?? 1);
        $days = (int)($body['days_count'] ?? 1);
        $reason = trim($body['reason'] ?? 'Personal');

        return [
            'success' => true,
            'message' => 'Staff leave request approved & duty substitution assigned',
            'data'    => [
                'staff_id'   => $staffId,
                'days_count' => $days,
                'reason'     => $reason,
                'status'     => 'approved'
            ]
        ];
    }
}
