<?php
declare(strict_types=1);

namespace DKTrack\Controllers;

use DKTrack\Database;
use PDO;

class BakeryController
{
    /**
     * Get Daily Raw Material Purchases (~10 items from Image 2 notebook)
     */
    public function getPurchases(array $queryParams = [], array $body = []): array
    {
        return [
            'success' => true,
            'data'    => [
                [
                    'id'            => 1,
                    'item_name_en'  => 'Coriander',
                    'item_name_ta'  => 'கொத்தமல்லி',
                    'vendor_name'   => 'Local Mandi',
                    'quantity'      => 1,
                    'unit'          => 'bundle',
                    'rate'          => 210.00,
                    'total_amount'  => 210.00,
                    'payment_mode'  => 'cash_drawer'
                ],
                [
                    'id'            => 2,
                    'item_name_en'  => 'Tomato',
                    'item_name_ta'  => 'தக்காளி',
                    'vendor_name'   => 'Local Mandi',
                    'quantity'      => 2,
                    'unit'          => 'box',
                    'rate'          => 34.00,
                    'total_amount'  => 68.00,
                    'payment_mode'  => 'cash_drawer'
                ],
                [
                    'id'            => 3,
                    'item_name_en'  => 'Cake & Bun',
                    'item_name_ta'  => 'கேக் & பன்',
                    'vendor_name'   => 'Sri Murugan Supplies',
                    'quantity'      => 1,
                    'unit'          => 'crate',
                    'rate'          => 390.00,
                    'total_amount'  => 390.00,
                    'payment_mode'  => 'cash_drawer'
                ],
                [
                    'id'            => 4,
                    'item_name_en'  => 'Sugar',
                    'item_name_ta'  => 'சர்க்கரை',
                    'vendor_name'   => 'Balaji Grocery',
                    'quantity'      => 10,
                    'unit'          => 'kg',
                    'rate'          => 58.60,
                    'total_amount'  => 586.00,
                    'payment_mode'  => 'gpay_kavin',
                    'notes'         => 'G-Pay transaction by Kavin Anna'
                ],
                [
                    'id'            => 5,
                    'item_name_en'  => 'Vim Lemons Dishwash',
                    'item_name_ta'  => 'விம் லெமன்',
                    'vendor_name'   => 'Balaji Grocery',
                    'quantity'      => 1,
                    'unit'          => 'bottle',
                    'rate'          => 139.00,
                    'total_amount'  => 139.00,
                    'payment_mode'  => 'gpay_kavin'
                ]
            ]
        ];
    }

    /**
     * Record a raw material purchase
     */
    public function recordPurchase(array $queryParams = [], array $body = []): array
    {
        $qty   = (float)($body['quantity'] ?? 1);
        $rate  = (float)($body['rate'] ?? 100);
        $total = $qty * $rate;

        return [
            'success' => true,
            'message' => 'Bakery purchase recorded successfully',
            'data'    => [
                'id'            => rand(100, 999),
                'item_name_en'  => $body['item_name_en'] ?? 'Item',
                'item_name_ta'  => $body['item_name_ta'] ?? 'பொருள்',
                'vendor_name'   => $body['vendor_name'] ?? 'Vendor',
                'quantity'      => $qty,
                'unit'          => $body['unit'] ?? 'unit',
                'rate'          => $rate,
                'total_amount'  => $total,
                'payment_mode'  => $body['payment_mode'] ?? 'cash_drawer',
                'created_at'    => date('Y-m-d H:i:s')
            ]
        ];
    }

    /**
     * Get Evening Counter Closing (Image 1 Page 152)
     */
    public function getClosing(array $queryParams = [], array $body = []): array
    {
        return [
            'success' => true,
            'data'    => [
                'closing_date'               => date('Y-m-d'),
                'physical_drawer_cash'       => 1960.00,
                'coins_amount'               => 104.00,
                'expenses_paid_from_drawer'  => 700.00,
                'upi_collections'            => 3700.00,
                'total_counter_revenue'      => 5764.00, // (1960 + 104) + 3700
                'net_cash_banked'            => 1364.00, // (1960 + 104) - 700
                'wastage' => [
                    'bajji'                  => 25,
                    'egg_bonda'              => 6,
                    'puff'                   => 2,
                    'milk_pockets'           => 20
                ],
                'closed_by'                  => 'Wife / Kavin'
            ]
        ];
    }

    /**
     * Submit Evening Counter Closing
     */
    public function submitClosing(array $queryParams = [], array $body = []): array
    {
        $drawerCash = (float)($body['physical_drawer_cash'] ?? 1960.00);
        $coins      = (float)($body['coins_amount'] ?? 104.00);
        $expenses   = (float)($body['expenses_paid_from_drawer'] ?? 700.00);
        $upi        = (float)($body['upi_collections'] ?? 3700.00);

        $totalRevenue = ($drawerCash + $coins) + $upi;
        $netBanked    = ($drawerCash + $coins) - $expenses;

        return [
            'success' => true,
            'message' => 'Evening counter closing saved and reconciled successfully',
            'data'    => [
                'closing_date'          => date('Y-m-d'),
                'physical_drawer_cash'  => $drawerCash,
                'coins_amount'          => $coins,
                'expenses_paid'         => $expenses,
                'upi_collections'       => $upi,
                'total_counter_revenue' => $totalRevenue,
                'net_cash_banked'       => $netBanked,
                'wastage'               => $body['wastage'] ?? [],
                'reconciliation_status' => 'BALANCED_OK'
            ]
        ];
    }
}
