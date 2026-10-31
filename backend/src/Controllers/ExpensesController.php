<?php
declare(strict_types=1);

namespace DKTrack\Controllers;

use DKTrack\Database;
use PDO;

class ExpensesController
{
    /**
     * Get All Business Expenses with Vertical & Category Filtering
     */
    public function getExpenses(array $queryParams = [], array $body = []): array
    {
        $division = $queryParams['division'] ?? 'all';

        $expenses = [
            // Tanker Expenses
            [
                'id'            => 1,
                'expense_date'  => '2026-10-30',
                'division'      => 'tanker',
                'category'      => 'fuel_diesel',
                'category_name' => 'Diesel / Fuel (Lorry TN 34 AF 4954)',
                'vehicle'       => 'TN 34 AF 4954',
                'amount'        => 4200.00,
                'payment_mode'  => 'canara_bank',
                'payee'         => 'HP Petrol Bunk, Kangeyam Road',
                'voucher_no'    => 'EXP-TNK-2026-081',
                'notes'         => 'Full tank 44.2 litres for Texvalley trip'
            ],
            [
                'id'            => 2,
                'expense_date'  => '2026-10-30',
                'division'      => 'tanker',
                'category'      => 'driver_batta',
                'category_name' => 'Driver Batta (Suresh)',
                'vehicle'       => 'TN 34 AF 4954',
                'amount'        => 250.00,
                'payment_mode'  => 'cash_drawer',
                'payee'         => 'Driver Suresh',
                'voucher_no'    => 'EXP-TNK-2026-082',
                'notes'         => 'Trip batta for long distance run'
            ],
            [
                'id'            => 3,
                'expense_date'  => '2026-10-29',
                'division'      => 'tanker',
                'category'      => 'tolls_permits',
                'category_name' => 'National Highway Tolls',
                'vehicle'       => 'TN 38 DZ 8841',
                'amount'        => 360.00,
                'payment_mode'  => 'gpay_kavin',
                'payee'         => 'FASTag Toll Plaza',
                'voucher_no'    => 'EXP-TNK-2026-079',
                'notes'         => 'Vijayamangalam Toll FASTag recharge'
            ],
            [
                'id'            => 4,
                'expense_date'  => '2026-10-28',
                'division'      => 'tanker',
                'category'      => 'vehicle_service',
                'category_name' => 'Pumping Motor Servicing & Oil',
                'vehicle'       => 'TN 38 CY 5599',
                'amount'        => 1850.00,
                'payment_mode'  => 'canara_bank',
                'payee'         => 'Lakshmi Auto Garage',
                'voucher_no'    => 'EXP-TNK-2026-075',
                'notes'         => 'Delivery motor impeller seal replaced'
            ],

            // Water Can Expenses
            [
                'id'            => 5,
                'expense_date'  => '2026-10-30',
                'division'      => 'can',
                'category'      => 'water_plant_cost',
                'category_name' => 'RO Plant Water Intake (213 Cans @ ₹8)',
                'vehicle'       => 'TN 38 BX 4412',
                'amount'        => 1704.00,
                'payment_mode'  => 'cash_drawer',
                'payee'         => 'Main RO Mineral Water Plant',
                'voucher_no'    => 'EXP-CAN-2026-041',
                'notes'         => 'Loads 1, 2, and 3 refills total 213 cans'
            ],
            [
                'id'            => 6,
                'expense_date'  => '2026-10-30',
                'division'      => 'can',
                'category'      => 'wages_salaries',
                'category_name' => 'Driver & Delivery Helper Daily Wage',
                'vehicle'       => 'TN 38 BX 4412',
                'amount'        => 1000.00,
                'payment_mode'  => 'cash_drawer',
                'payee'         => 'Vignesh (Driver)',
                'voucher_no'    => 'EXP-CAN-2026-042',
                'notes'         => 'Daily fixed wage for 16 drops'
            ],
            [
                'id'            => 7,
                'expense_date'  => '2026-10-29',
                'division'      => 'can',
                'category'      => 'fuel_diesel',
                'category_name' => 'Diesel for Tata Ace',
                'vehicle'       => 'TN 38 BX 4412',
                'amount'        => 650.00,
                'payment_mode'  => 'gpay_kavin',
                'payee'         => 'Indian Oil Bunk',
                'voucher_no'    => 'EXP-CAN-2026-039',
                'notes'         => '6.5 litres diesel for day route'
            ],

            // Bakery Expenses
            [
                'id'            => 8,
                'expense_date'  => '2026-10-30',
                'division'      => 'bakery',
                'category'      => 'raw_materials',
                'category_name' => 'Daily Ingredients & Supplies (Image 2)',
                'vehicle'       => 'Store Counter',
                'amount'        => 3861.60,
                'payment_mode'  => 'cash_drawer',
                'payee'         => 'Various Mandi & Grocery Vendors',
                'voucher_no'    => 'EXP-BAK-2026-102',
                'notes'         => 'Milk, Tomatoes, Coriander, Puffs, Tea dust'
            ],
            [
                'id'            => 9,
                'expense_date'  => '2026-10-30',
                'division'      => 'bakery',
                'category'      => 'finance_instalment',
                'category_name' => 'Daily Finance Instalment Payment',
                'vehicle'       => 'Store Counter',
                'amount'        => 1000.00,
                'payment_mode'  => 'cash_drawer',
                'payee'         => 'Finance Collection Agent',
                'voucher_no'    => 'EXP-BAK-2026-103',
                'notes'         => 'Daily loan repayment instalment'
            ],
            [
                'id'            => 10,
                'expense_date'  => '2026-10-30',
                'division'      => 'bakery',
                'category'      => 'wages_salaries',
                'category_name' => 'Paati Wages & Helper Advance',
                'vehicle'       => 'Store Counter',
                'amount'        => 350.00,
                'payment_mode'  => 'cash_drawer',
                'payee'         => 'Store Helper (Paati)',
                'voucher_no'    => 'EXP-BAK-2026-104',
                'notes'         => 'Daily washing & cleaning assistance'
            ],

            // General & Administration
            [
                'id'            => 11,
                'expense_date'  => '2026-10-28',
                'division'      => 'general',
                'category'      => 'electricity_utilities',
                'category_name' => 'TNEB Electricity Bill (Bakery & Office)',
                'vehicle'       => 'Head Office / Store',
                'amount'        => 3420.00,
                'payment_mode'  => 'axis_bank',
                'payee'         => 'TNEB Tamil Nadu Electricity Board',
                'voucher_no'    => 'EXP-GEN-2026-015',
                'notes'         => 'Monthly commercial tariff'
            ],
            [
                'id'            => 12,
                'expense_date'  => '2026-10-27',
                'division'      => 'general',
                'category'      => 'miscellaneous',
                'category_name' => 'Accountant Audit & Books Closing',
                'vehicle'       => 'Head Office',
                'amount'        => 2000.00,
                'payment_mode'  => 'gpay_kavin',
                'payee'         => 'Auditor Sundaram & Associates',
                'voucher_no'    => 'EXP-GEN-2026-016',
                'notes'         => 'Monthly tax filing retainership'
            ]
        ];

        if ($division !== 'all') {
            $expenses = array_values(array_filter($expenses, fn($e) => $e['division'] === $division));
        }

        $totalAmount = array_reduce($expenses, fn($acc, $e) => $acc + $e['amount'], 0.0);

        return [
            'success'      => true,
            'total_amount' => $totalAmount,
            'count'        => count($expenses),
            'data'         => $expenses
        ];
    }

    /**
     * Record New Business Expense
     */
    public function recordExpense(array $queryParams = [], array $body = []): array
    {
        $amount = (float)($body['amount'] ?? 0.0);
        $division = $body['division'] ?? 'general';
        $category = $body['category'] ?? 'miscellaneous';
        $paymentMode = $body['payment_mode'] ?? 'cash_drawer';
        $payee = trim($body['payee'] ?? 'Vendor');

        return [
            'success' => true,
            'message' => 'Expense recorded successfully',
            'data'    => [
                'id'           => date('U'),
                'expense_date' => date('Y-m-d'),
                'division'     => $division,
                'category'     => $category,
                'amount'       => $amount,
                'payment_mode' => $paymentMode,
                'payee'        => $payee,
                'voucher_no'   => 'EXP-' . strtoupper(substr($division, 0, 3)) . '-' . date('Ymd-His')
            ]
        ];
    }
}
