<?php
declare(strict_types=1);

namespace DKTrack\Controllers;

use DKTrack\Database;
use PDO;

class WaterCansController
{
    /**
     * Get Multi-Plant Refill Intakes (Sequential Loads: 1, 2, 3...)
     */
    public function getIntakes(array $queryParams = [], array $body = []): array
    {
        return [
            'success' => true,
            'data'    => [
                [
                    'id'              => 1,
                    'intake_sequence' => 1,
                    'time'            => '08:15 AM',
                    'cans_loaded'     => 72,
                    'purchase_rate'   => 8.00,
                    'total_cost'      => 576.00,
                    'slip_number'     => 'RO-PLANT-0912'
                ],
                [
                    'id'              => 2,
                    'intake_sequence' => 2,
                    'time'            => '12:45 PM',
                    'cans_loaded'     => 84,
                    'purchase_rate'   => 8.00,
                    'total_cost'      => 672.00,
                    'slip_number'     => 'RO-PLANT-0948'
                ],
                [
                    'id'              => 3,
                    'intake_sequence' => 3,
                    'time'            => '04:15 PM',
                    'cans_loaded'     => 57,
                    'purchase_rate'   => 8.00,
                    'total_cost'      => 456.00,
                    'slip_number'     => 'RO-PLANT-0980'
                ]
            ]
        ];
    }

    /**
     * Record a new plant refill intake
     */
    public function recordIntake(array $queryParams = [], array $body = []): array
    {
        $cansLoaded   = (int)($body['cans_loaded'] ?? 50);
        $purchaseRate = (float)($body['purchase_rate'] ?? 8.00);
        $totalCost    = $cansLoaded * $purchaseRate;

        return [
            'success' => true,
            'message' => 'Plant refill intake recorded successfully',
            'data'    => [
                'intake_sequence' => (int)($body['intake_sequence'] ?? 4),
                'time'            => date('h:i A'),
                'cans_loaded'     => $cansLoaded,
                'purchase_rate'   => $purchaseRate,
                'total_cost'      => $totalCost,
                'slip_number'     => $body['slip_number'] ?? ('RO-PLANT-' . rand(1000, 9999))
            ]
        ];
    }

    /**
     * Live Truck Stock & Financial Reconciliation
     * Formula: Running Stock = Sum(Plant Intakes) - Sum(Delivered Cans)
     */
    public function getLiveStock(array $queryParams = [], array $body = []): array
    {
        $totalLoaded    = 213; // 72 + 84 + 57
        $totalDelivered = 188;
        $expectedOnTruck= $totalLoaded - $totalDelivered; // 25 cans

        $totalCashCollected = 1810.00;
        $totalCreditIssued  = 1960.00;
        $grossSalesValue    = $totalCashCollected + $totalCreditIssued; // 3,770
        $plantCost          = 213 * 8.00; // 1,704
        $driverBatta        = 1000.00;
        $netMarginToday     = $grossSalesValue - ($plantCost + $driverBatta); // 1,266

        return [
            'success' => true,
            'data'    => [
                'total_loaded_cans'     => $totalLoaded,
                'total_delivered_cans'  => $totalDelivered,
                'expected_stock_cans'   => $expectedOnTruck,
                'plant_purchase_cost'   => $plantCost,
                'cash_collected'        => $totalCashCollected,
                'credit_issued'         => $totalCreditIssued,
                'gross_sales_value'     => $grossSalesValue,
                'driver_batta'          => $driverBatta,
                'net_margin_today'      => $netMarginToday,
                'route_distance_km'     => 72.0
            ]
        ];
    }

    /**
     * Surprise Spot Audit Anti-Theft Tool
     */
    public function performSpotAudit(array $queryParams = [], array $body = []): array
    {
        $observedCans = (int)($body['observed_cans'] ?? 25);
        $observedCash = (float)($body['observed_cash'] ?? 1810.00);

        $expectedCans = 25;
        $expectedCash = 1810.00;

        $canDiscrepancy  = $observedCans - $expectedCans;
        $cashDiscrepancy = $observedCash - $expectedCash;

        $isAuditClean = ($canDiscrepancy === 0 && abs($cashDiscrepancy) < 0.01);

        return [
            'success' => true,
            'data'    => [
                'audit_time'        => date('Y-m-d H:i:s'),
                'is_clean'          => $isAuditClean,
                'expected_cans'     => $expectedCans,
                'observed_cans'     => $observedCans,
                'can_discrepancy'   => $canDiscrepancy,
                'expected_cash'     => $expectedCash,
                'observed_cash'     => $observedCash,
                'cash_discrepancy'  => $cashDiscrepancy,
                'audit_status'      => $isAuditClean ? 'VERIFIED_100%_CLEAN' : 'FLAGGED_PILFERAGE_RISK'
            ]
        ];
    }
}
