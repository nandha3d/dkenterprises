<?php

namespace App\Services\Operations;

class OperationalFraudAuditService
{
    /**
     * Audit Cafe Cash Drawer for cash skimming or unrecorded register theft.
     *
     * @param float $openingFloat
     * @param float $systemCashSales
     * @param float $systemUpiSales
     * @param float $physicalCashCounted
     * @param float $upiSettledCounted
     * @param float $toleranceAmount (e.g. ₹10 for loose change rounding)
     * @return array
     */
    public function auditCashDrawer(
        float $openingFloat,
        float $systemCashSales,
        float $systemUpiSales,
        float $physicalCashCounted,
        float $upiSettledCounted,
        float $toleranceAmount = 10.0
    ): array {
        $expectedCashInDrawer = $openingFloat + $systemCashSales;
        $totalSystem = $systemCashSales + $systemUpiSales;
        $totalPhysical = ($physicalCashCounted - $openingFloat) + $upiSettledCounted;

        $cashDiscrepancy = $physicalCashCounted - $expectedCashInDrawer;
        $upiDiscrepancy = $upiSettledCounted - $systemUpiSales;
        $netDiscrepancy = $totalPhysical - $totalSystem;

        $isSkimming = $cashDiscrepancy < (-1 * $toleranceAmount);
        $isOver = $cashDiscrepancy > $toleranceAmount;
        $isBalanced = abs($cashDiscrepancy) <= $toleranceAmount && abs($upiDiscrepancy) <= $toleranceAmount;

        $status = $isBalanced ? 'balanced' : ($cashDiscrepancy < 0 ? 'short' : 'over');

        $fraudRisk = 'low';
        $flags = [];

        if ($isSkimming) {
            $fraudRisk = abs($cashDiscrepancy) > 500 ? 'critical' : 'high';
            $flags[] = "POTENTIAL_CASH_SKIMMING: Physical cash in drawer is ₹" . abs($cashDiscrepancy) . " less than system sales.";
        }

        if (abs($upiDiscrepancy) > $toleranceAmount) {
            $flags[] = "UPI_SETTLEMENT_MISMATCH: Bank settlement differs from system sales by ₹" . abs($upiDiscrepancy) . ".";
        }

        return [
            'is_fraud_detected' => $isSkimming,
            'fraud_risk' => $fraudRisk,
            'status' => $status,
            'expected_cash' => $expectedCashInDrawer,
            'physical_cash' => $physicalCashCounted,
            'cash_discrepancy' => $cashDiscrepancy,
            'upi_discrepancy' => $upiDiscrepancy,
            'net_discrepancy' => $netDiscrepancy,
            'flags' => $flags,
        ];
    }

    /**
     * Audit Kitchen Raw Material usage against standard recipe / batch yield.
     *
     * @param float $openingStock
     * @param float $receivedToday
     * @param float $reportedConsumed
     * @param float $theoreticalConsumption
     * @param float $tolerancePercent
     * @return array
     */
    public function auditIngredientConsumption(
        float $openingStock,
        float $receivedToday,
        float $reportedConsumed,
        float $theoreticalConsumption,
        float $tolerancePercent = 15.0
    ): array {
        $availableStock = $openingStock + $receivedToday;
        $flags = [];
        $isFraudDetected = false;
        $risk = 'low';

        // Anomaly 1: Consuming more stock than available (negative stock phantom write-off)
        if ($reportedConsumed > $availableStock) {
            $isFraudDetected = true;
            $risk = 'critical';
            $flags[] = "IMPOSSIBLE_CONSUMPTION: Reported consumption ({$reportedConsumed}) exceeds total available stock ({$availableStock}).";
        }

        // Anomaly 2: Reported consumption exceeds theoretical recipe usage by more than tolerance
        if ($theoreticalConsumption > 0) {
            $variance = $reportedConsumed - $theoreticalConsumption;
            $variancePct = ($variance / $theoreticalConsumption) * 100;

            if ($variancePct > $tolerancePercent) {
                $isFraudDetected = true;
                $risk = $variancePct > 50 ? 'critical' : 'high';
                $flags[] = "PHANTOM_WASTAGE_DETECTED: Consumption exceeds theoretical recipe yield by " . round($variancePct, 1) . "% (Tolerance: {$tolerancePercent}%).";
            }
        }

        return [
            'is_fraud_detected' => $isFraudDetected,
            'fraud_risk' => $risk,
            'available_stock' => $availableStock,
            'closing_stock' => max(0, $availableStock - $reportedConsumed),
            'variance_quantity' => $reportedConsumed - $theoreticalConsumption,
            'flags' => $flags,
        ];
    }

    /**
     * Audit Tanker Odometer and Distance for tampering or inflated billing claims.
     *
     * @param float $startKm
     * @param float $endKm
     * @param float|null $gpsTelematicsDistanceKm
     * @param float $maxToleranceKm
     * @return array
     */
    public function auditTankerOdometer(
        float $startKm,
        float $endKm,
        ?float $gpsTelematicsDistanceKm = null,
        float $maxToleranceKm = 5.0
    ): array {
        $flags = [];
        $isFraud = false;
        $risk = 'low';

        // Anomaly 1: Reverse odometer tampering (end < start)
        if ($endKm < $startKm) {
            $isFraud = true;
            $risk = 'critical';
            $flags[] = "ODOMETER_ROLLBACK_DETECTED: Ending odometer ({$endKm} KM) is less than starting odometer ({$startKm} KM).";
            $billedDistance = 0;
        } else {
            $billedDistance = $endKm - $startKm;
        }

        // Anomaly 2: Discrepancy against GPS telematics tracking
        if ($gpsTelematicsDistanceKm !== null && $billedDistance > 0) {
            $discrepancy = $billedDistance - $gpsTelematicsDistanceKm;
            if ($discrepancy > $maxToleranceKm) {
                $isFraud = true;
                $risk = $discrepancy > 20 ? 'critical' : 'high';
                $flags[] = "INFLATED_MILEAGE_FRAUD: Claimed distance ({$billedDistance} KM) exceeds GPS tracked distance ({$gpsTelematicsDistanceKm} KM) by " . round($discrepancy, 1) . " KM.";
            }
        }

        return [
            'is_fraud_detected' => $isFraud,
            'fraud_risk' => $risk,
            'billed_distance_km' => $billedDistance,
            'flags' => $flags,
        ];
    }

    /**
     * Audit Bulk Water Decanting against total loaded tanker capacity.
     *
     * @param float $loadedCapacityKl
     * @param float $deliveredVouchersKl
     * @param float $returnedDepotKl
     * @param float $allowedEvaporationLossKl (e.g. 0.2 KL for 20KL tanker)
     * @return array
     */
    public function auditWaterDecanting(
        float $loadedCapacityKl,
        float $deliveredVouchersKl,
        float $returnedDepotKl = 0.0,
        float $allowedEvaporationLossKl = 0.3
    ): array {
        $totalAccountedKl = $deliveredVouchersKl + $returnedDepotKl;
        $unaccountedLossKl = $loadedCapacityKl - $totalAccountedKl;
        $flags = [];
        $isFraud = false;
        $risk = 'low';

        if ($unaccountedLossKl > $allowedEvaporationLossKl) {
            $isFraud = true;
            $risk = $unaccountedLossKl >= 2.0 ? 'critical' : 'high';
            $flags[] = "WATER_THEFT_DETECTED: Unaccounted volume shrinkage of " . round($unaccountedLossKl, 2) . " KL (Allowed tolerance: {$allowedEvaporationLossKl} KL).";
        } elseif ($totalAccountedKl > $loadedCapacityKl) {
            $flags[] = "OVERFILL_ANOMALY: Delivered volume exceeds tanker capacity by " . ($totalAccountedKl - $loadedCapacityKl) . " KL.";
        }

        return [
            'is_fraud_detected' => $isFraud,
            'fraud_risk' => $risk,
            'loaded_kl' => $loadedCapacityKl,
            'accounted_kl' => $totalAccountedKl,
            'unaccounted_loss_kl' => max(0, $unaccountedLossKl),
            'flags' => $flags,
        ];
    }

    /**
     * Audit Tanker Motor Pumping Minutes for false delay / inflated surcharge billing.
     *
     * @param float $deliveredVolumeKl
     * @param int $claimedPumpingMinutes
     * @param float $maxMinsPerKl (standard commercial pump discharges ~1KL in 2.5 - 3 mins; max allowable 5 mins/KL)
     * @return array
     */
    public function auditSurchargePumping(
        float $deliveredVolumeKl,
        int $claimedPumpingMinutes,
        float $maxMinsPerKl = 5.0
    ): array {
        $maxReasonableMinutes = ceil($deliveredVolumeKl * $maxMinsPerKl);
        $flags = [];
        $isFraud = false;
        $risk = 'low';

        if ($claimedPumpingMinutes > $maxReasonableMinutes) {
            $isFraud = true;
            $risk = ($claimedPumpingMinutes > $maxReasonableMinutes * 2) ? 'critical' : 'medium';
            $flags[] = "INFLATED_PUMPING_SURCHARGE: Claimed {$claimedPumpingMinutes} mins for {$deliveredVolumeKl} KL exceeds standard maximum ({$maxReasonableMinutes} mins).";
        }

        return [
            'is_fraud_detected' => $isFraud,
            'fraud_risk' => $risk,
            'max_allowed_minutes' => $maxReasonableMinutes,
            'claimed_minutes' => $claimedPumpingMinutes,
            'flags' => $flags,
        ];
    }

    /**
     * Audit Water Can Route Balance for van shortage / driver can siphoning.
     *
     * @param int $morningLoadedCans
     * @param int $deliveredFilledCans
     * @param int $returnedEmptyCans
     * @param int $returnedFilledCans
     * @param int $reportedDamagedCans
     * @return array
     */
    public function auditRouteCanBalance(
        int $morningLoadedCans,
        int $deliveredFilledCans,
        int $returnedEmptyCans,
        int $returnedFilledCans,
        int $reportedDamagedCans = 0
    ): array {
        $flags = [];
        $isFraud = false;
        $risk = 'low';

        // Van bottle inventory conservation:
        // Cans taken out in morning must equal: Delivered filled cans + Brought back filled cans
        $accountedFilledCans = $deliveredFilledCans + $returnedFilledCans;
        $missingFilledCans = $morningLoadedCans - $accountedFilledCans;

        if ($missingFilledCans > 0) {
            $isFraud = true;
            $risk = 'critical';
            $flags[] = "MISSING_FILLED_CANS: Driver left with {$morningLoadedCans} cans but only accounted for {$accountedFilledCans} (Shortage: {$missingFilledCans} cans).";
        }

        // Empty can return ratio:
        // Cans delivered vs empties collected + customer debt
        $emptyShortfall = $deliveredFilledCans - ($returnedEmptyCans + $reportedDamagedCans);

        return [
            'is_fraud_detected' => $isFraud,
            'fraud_risk' => $risk,
            'morning_loaded' => $morningLoadedCans,
            'accounted_filled' => $accountedFilledCans,
            'missing_filled_cans' => max(0, $missingFilledCans),
            'empty_cans_variance' => $emptyShortfall,
            'flags' => $flags,
        ];
    }

    /**
     * Audit Customer Security Deposit Refund Eligibility against live held can balance.
     *
     * @param int $customerHeldCans
     * @param int $requestedRefundCans
     * @param float $depositRatePerCan
     * @return array
     */
    public function auditDepositRefundEligibility(
        int $customerHeldCans,
        int $requestedRefundCans,
        float $depositRatePerCan = 150.0
    ): array {
        $flags = [];
        $isFraud = false;
        $risk = 'low';

        if ($requestedRefundCans > $customerHeldCans) {
            $isFraud = true;
            $risk = 'critical';
            $flags[] = "PHANTOM_DEPOSIT_REFUND_FRAUD: Customer only holds {$customerHeldCans} cans on record, but refund was requested for {$requestedRefundCans} cans.";
            $authorizedRefundCans = $customerHeldCans;
        } else {
            $authorizedRefundCans = $requestedRefundCans;
        }

        return [
            'is_fraud_detected' => $isFraud,
            'fraud_risk' => $risk,
            'customer_held_cans' => $customerHeldCans,
            'requested_refund_cans' => $requestedRefundCans,
            'authorized_refund_cans' => $authorizedRefundCans,
            'authorized_refund_amount' => $authorizedRefundCans * $depositRatePerCan,
            'blocked_refund_amount' => ($requestedRefundCans - $authorizedRefundCans) * $depositRatePerCan,
            'flags' => $flags,
        ];
    }
}
