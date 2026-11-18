<?php

namespace App\Services\ERP;

use App\Models\Product;
use App\Models\Sale;
use App\Services\Platform\CompanyContext;
use App\Services\Platform\CompanyContextResolver;
use App\Services\Tax\GstProjectionService;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

/**
 * Unified ERP + GST sales projection synchronizer for operational verticals
 * (20L Water Can Distribution, Bulk Water Tankers, and Cafe POS).
 *
 * Ensures every completed delivery/trip/order generates:
 *  - A canonical `sales` header with `posted_at`, `branch_id`, `financial_year_id`, and `tax_snapshot_json`
 *  - Line-level `product_sales` with HSN/SAC, `tax_rate`, CGST/SGST/IGST split, and `tax_snapshot_json`
 *  - A `payments` receipt entry when `paid_amount > 0`
 *  - A `gst_transaction_projections` snapshot for future GSTR-1 / GSTR-3B compliance filings
 *
 * Designed to integrate alongside existing double-entry GL postings in operational controllers
 * without duplicating accounting vouchers.
 */
class VerticalSaleSyncService
{
    public function syncCompletedSale(array $payload): int
    {
        $existingSaleId = (int) ($payload['existing_sale_id'] ?? 0);
        if ($existingSaleId > 0 && DB::table('sales')->where('id', $existingSaleId)->exists()) {
            return $existingSaleId;
        }

        $referenceNo = trim((string) ($payload['reference_no'] ?? ('ERP-' . date('Ymd-His'))));
        $companyId = (int) ($payload['company_id'] ?? 1);

        $alreadyByRef = DB::table('sales')
            ->where('company_id', $companyId)
            ->where('reference_no', $referenceNo)
            ->whereNull('deleted_at')
            ->value('id');
        if ($alreadyByRef) {
            return (int) $alreadyByRef;
        }

        $branchId = $this->resolveBranchId($companyId, $payload['branch_id'] ?? null);
        $warehouseId = $this->resolveWarehouseId($companyId, $branchId, $payload['warehouse_id'] ?? null);
        $billerId = $this->resolveBillerId($companyId, $payload['biller_id'] ?? null);
        $financialYearId = $this->resolveFinancialYearId($companyId, $payload['financial_year_id'] ?? null);
        $currencyId = (int) ($payload['currency_id'] ?? (DB::table('currencies')->where('is_active', 1)->orderBy('id')->value('id') ?: 1));
        $customerId = (int) ($payload['customer_id'] ?? 1);
        $userId = (int) ($payload['user_id'] ?? Auth::id() ?? 1);
        $saleDateRaw = (string) ($payload['sale_date'] ?? now()->toDateTimeString());
        $saleTimestamp = strlen($saleDateRaw) === 10 ? ($saleDateRaw . ' ' . now()->format('H:i:s')) : $saleDateRaw;
        $saleDateOnly = substr($saleTimestamp, 0, 10);

        $customer = DB::table('customers')->where('id', $customerId)->first();
        $registration = DB::table('tax_registrations')
            ->where('company_id', $companyId)
            ->where('status', 'active')
            ->orderBy('id')
            ->first();

        $sellerState = (string) ($registration->state_code ?? DB::table('companies')->where('id', $companyId)->value('state_code') ?? '33');
        $sellerGstin = trim((string) ($registration->gstin ?? ''));
        $isRegisteredSeller = $registration && $registration->registration_type === 'regular' && $sellerGstin !== '';

        $buyerGstin = strtoupper(trim((string) ($customer->tax_no ?? '')));
        $buyerState = preg_match('/^([0-9]{2})[A-Z0-9]{13}$/', $buyerGstin, $m) ? $m[1] : $sellerState;
        $isIntraState = $sellerState === $buyerState;

        $discountTotal = round(max(0.0, (float) ($payload['discount'] ?? 0)), 2);
        $itemsInput = $payload['items'] ?? [];
        if (empty($itemsInput)) {
            return 0;
        }

        $totalQty = 0.0;
        $totalTaxable = 0.0;
        $totalTax = 0.0;
        $totalCgst = 0.0;
        $totalSgst = 0.0;
        $totalIgst = 0.0;
        $preparedLines = [];
        $lineSnapshots = [];

        foreach ($itemsInput as $index => $line) {
            $qty = round((float) ($line['qty'] ?? 0), 4);
            if ($qty <= 0) {
                continue;
            }
            $unitPrice = round((float) ($line['unit_price'] ?? 0), 4);
            $lineDiscount = round((float) ($line['discount'] ?? ($index === 0 ? $discountTotal : 0)), 2);

            $product = $this->resolveProduct(
                $companyId,
                isset($line['product_id']) ? (int) $line['product_id'] : null,
                $line['product_code'] ?? null,
                $line['name'] ?? null
            );

            $productId = (int) ($product?->id ?? $this->fallbackCompanyProductId($companyId));
            $saleUnitId = (int) ($product?->sale_unit_id ?? $product?->unit_id ?? 1);
            $productName = (string) ($line['name'] ?? $product?->name ?? 'Operational Item');
            $productCode = (string) ($line['product_code'] ?? $product?->code ?? 'GEN-001');
            $hsnSac = trim((string) ($line['hsn_sac'] ?? $product?->hsn_code ?? $this->defaultHsnForType((string) ($payload['sale_type'] ?? ''), $productCode)));

            [$supplyType, $taxRate, $inputCreditAllowed] = $this->resolveTaxRule(
                $companyId,
                $product,
                $saleDateOnly,
                $isRegisteredSeller,
                isset($line['tax_rate_override']) ? (float) $line['tax_rate_override'] : null
            );

            $lineGross = round(max(0.0, ($qty * $unitPrice) - $lineDiscount), 2);
            $taxAmount = $taxRate > 0 ? round($lineGross * ($taxRate / 100.0), 2) : 0.0;
            $cgst = ($taxAmount > 0 && $isIntraState) ? round($taxAmount / 2.0, 2) : 0.0;
            $sgst = ($taxAmount > 0 && $isIntraState) ? round($taxAmount - $cgst, 2) : 0.0;
            $igst = ($taxAmount > 0 && !$isIntraState) ? $taxAmount : 0.0;
            $lineTotal = round($lineGross + $taxAmount, 2);

            $snapshot = [
                'taxable_value' => $lineGross,
                'discount' => $lineDiscount,
                'rate' => $taxRate,
                'product_rate' => $taxRate,
                'cess_rate' => 0.0,
                'cgst' => $cgst,
                'sgst' => $sgst,
                'igst' => $igst,
                'cess' => 0.0,
                'hsn_sac' => $hsnSac,
                'place_of_supply' => $buyerState,
                'reverse_charge' => false,
                'supply_type' => $supplyType,
                'input_credit_allowed' => $inputCreditAllowed,
                'product_name' => $productName,
                'product_code' => $productCode,
                'qty' => $qty,
            ];

            $preparedLines[] = [
                'product_id' => $productId,
                'qty' => $qty,
                'sale_unit_id' => $saleUnitId,
                'net_unit_price' => $unitPrice,
                'discount' => $lineDiscount,
                'tax_rate' => $taxRate,
                'tax' => $taxAmount,
                'total' => $lineTotal,
                'tax_snapshot_json' => json_encode($snapshot, JSON_THROW_ON_ERROR),
            ];
            $lineSnapshots[] = $snapshot;

            $totalQty += $qty;
            $totalTaxable += $lineGross;
            $totalTax += $taxAmount;
            $totalCgst += $cgst;
            $totalSgst += $sgst;
            $totalIgst += $igst;
        }

        if (empty($preparedLines)) {
            return 0;
        }

        $grandTotal = round($totalTaxable + $totalTax, 2);
        $paidAmount = round(max(0.0, min($grandTotal, (float) ($payload['paid_amount'] ?? 0))), 2);
        $paymentMode = (string) ($payload['payment_mode'] ?? 'Cash');

        // Payment status codes in ERP: 4 = Paid, 3 = Partial, 2 = Due, 1 = Pending
        if ($grandTotal <= 0 || $paidAmount >= ($grandTotal - 0.01)) {
            $paymentStatus = 4;
        } elseif ($paidAmount > 0.01) {
            $paymentStatus = 3;
        } else {
            $paymentStatus = 2;
        }

        $headerTaxSnapshot = [
            'section' => $buyerGstin !== '' ? 'b2b' : 'b2c',
            'seller_gstin' => $sellerGstin,
            'seller_state' => $sellerState,
            'buyer_gstin' => $buyerGstin,
            'place_of_supply' => $buyerState,
            'registration_type' => $registration->registration_type ?? 'unregistered',
            'reverse_charge' => false,
            'cgst' => round($totalCgst, 2),
            'sgst' => round($totalSgst, 2),
            'igst' => round($totalIgst, 2),
            'cess' => 0.0,
            'sign' => 1,
        ];

        $creditDays = (int) ($payload['credit_days'] ?? (stripos($paymentMode, 'credit') !== false ? 15 : 0));

        $saleId = (int) DB::table('sales')->insertGetId([
            'reference_no' => $referenceNo,
            'user_id' => $userId,
            'customer_id' => $customerId,
            'warehouse_id' => $warehouseId,
            'biller_id' => $billerId,
            'item' => count($preparedLines),
            'total_qty' => round($totalQty, 4),
            'total_discount' => $discountTotal,
            'total_tax' => round($totalTax, 2),
            'total_price' => round($totalTaxable, 2),
            'grand_total' => $grandTotal,
            'currency_id' => $currencyId,
            'exchange_rate' => 1,
            'order_tax_rate' => 0,
            'order_tax' => 0,
            'order_discount' => $discountTotal,
            'shipping_cost' => 0,
            'sale_status' => 1,
            'payment_status' => $paymentStatus,
            'paid_amount' => $paidAmount,
            'sale_note' => $payload['sale_note'] ?? null,
            'sale_type' => $payload['sale_type'] ?? 'standard',
            'credit_days' => $creditDays > 0 ? $creditDays : null,
            'company_id' => $companyId,
            'branch_id' => $branchId,
            'financial_year_id' => $financialYearId,
            'posted_at' => $saleTimestamp,
            'tax_snapshot_json' => json_encode($headerTaxSnapshot, JSON_THROW_ON_ERROR),
            'created_at' => $saleTimestamp,
            'updated_at' => $saleTimestamp,
        ]);

        foreach ($preparedLines as $line) {
            DB::table('product_sales')->insert([
                'sale_id' => $saleId,
                'product_id' => $line['product_id'],
                'qty' => $line['qty'],
                'return_qty' => 0,
                'sale_unit_id' => $line['sale_unit_id'],
                'net_unit_price' => $line['net_unit_price'],
                'discount' => $line['discount'],
                'tax_rate' => $line['tax_rate'],
                'tax' => $line['tax'],
                'total' => $line['total'],
                'is_delivered' => 1,
                'company_id' => $companyId,
                'tax_snapshot_json' => $line['tax_snapshot_json'],
                'created_at' => $saleTimestamp,
                'updated_at' => $saleTimestamp,
            ]);
        }

        if ($paidAmount > 0.01) {
            $isBank = stripos($paymentMode, 'upi') !== false
                || stripos($paymentMode, 'bank') !== false
                || stripos($paymentMode, 'card') !== false
                || stripos($paymentMode, 'neft') !== false;
            $accountId = $this->resolvePaymentAccountId($companyId, $isBank);
            $paymentRef = ($payload['payment_reference'] ?? null) ?: ('PAY-' . $referenceNo);

            DB::table('payments')->insert([
                'sale_id' => $saleId,
                'account_id' => $accountId,
                'payment_reference' => $paymentRef,
                'user_id' => $userId,
                'amount' => $paidAmount,
                'currency_id' => $currencyId,
                'exchange_rate' => 1,
                'payment_at' => $saleDateOnly,
                'change' => 0,
                'paying_method' => $paymentMode,
                'payment_note' => $payload['sale_note'] ?? "Operational payment ({$paymentMode})",
                'company_id' => $companyId,
                'created_at' => $saleTimestamp,
                'updated_at' => $saleTimestamp,
            ]);
        }

        $this->recordGstProjection($saleId, $companyId, $branchId, $financialYearId, $userId, $referenceNo, $saleDateOnly, $sellerGstin, $headerTaxSnapshot, $lineSnapshots);

        $linkedSalesOrderId = (int) ($payload['sales_order_id'] ?? 0);
        if ($linkedSalesOrderId > 0) {
            $this->fulfillSalesOrder($companyId, $linkedSalesOrderId, $saleId, $totalQty, $userId);
        }

        return $saleId;
    }

    /**
     * Create or amend an ERP `sales_orders` record (and `commercial_order_items` /
     * `commercial_order_events`) for 20L Water Can or Bulk Water Tanker orders.
     */
    public function syncSalesOrder(array $payload): int
    {
        if (!Schema::hasTable('sales_orders') || !Schema::hasTable('commercial_order_items')) {
            return 0;
        }

        $companyId = (int) ($payload['company_id'] ?? 1);
        $customerId = (int) ($payload['customer_id'] ?? 1);
        $userId = (int) ($payload['user_id'] ?? Auth::id() ?? 1);
        $existingOrderId = (int) ($payload['existing_sales_order_id'] ?? 0);

        $branchId = $this->resolveBranchId($companyId, $payload['branch_id'] ?? null);
        $warehouseId = $this->resolveWarehouseId($companyId, $branchId, $payload['warehouse_id'] ?? null);
        $financialYearId = $this->resolveFinancialYearId($companyId, $payload['financial_year_id'] ?? null);

        $businessDate = substr((string) ($payload['business_date'] ?? now()->toDateString()), 0, 10);
        $promisedDate = substr((string) ($payload['promised_date'] ?? $businessDate), 0, 10);
        if ($promisedDate < $businessDate) {
            $promisedDate = $businessDate;
        }

        $qty = round(max(0.01, (float) ($payload['qty'] ?? 1)), 4);
        $unitRate = round(max(0.0, (float) ($payload['unit_rate'] ?? 0)), 4);
        $note = isset($payload['note']) ? trim((string) $payload['note']) : null;

        $product = $this->resolveProduct(
            $companyId,
            isset($payload['product_id']) ? (int) $payload['product_id'] : null,
            $payload['product_code'] ?? null,
            $payload['product_name'] ?? null
        );
        $productId = $product ? (int) $product->id : $this->fallbackCompanyProductId($companyId);
        $uomId = (int) ($product?->sale_unit_id ?? $product?->unit_id ?? DB::table('units')->orderBy('id')->value('id') ?: 1);

        $attributes = array_filter([
            'source_type' => $payload['source_type'] ?? 'water_can',
            'source_ref' => $payload['source_ref'] ?? null,
            'order_origin' => $payload['order_origin'] ?? 'on_day',
            'schedule_id' => $payload['schedule_id'] ?? null,
            'schedule_label' => $payload['schedule_label'] ?? null,
            'delivery_id' => $payload['delivery_id'] ?? null,
            'trip_id' => $payload['trip_id'] ?? null,
        ], static fn ($v) => $v !== null && $v !== '');

        if ($existingOrderId > 0) {
            $existing = DB::table('sales_orders')->where('id', $existingOrderId)->first();
            if ($existing) {
                $oldAttrs = json_decode((string) ($existing->attributes_json ?? '{}'), true) ?: [];
                $newVersion = (int) ($oldAttrs['order_version'] ?? 1) + 1;
                $mergedAttrs = array_merge($oldAttrs, $attributes, ['order_version' => $newVersion]);

                DB::table('sales_orders')->where('id', $existingOrderId)->update([
                    'promised_date' => $promisedDate,
                    'note' => $note !== null && $note !== '' ? $note : $existing->note,
                    'attributes_json' => json_encode($mergedAttrs, JSON_THROW_ON_ERROR),
                    'updated_at' => now(),
                ]);

                DB::table('commercial_order_items')
                    ->where('company_id', (int) $existing->company_id)
                    ->where('order_kind', 'sale')
                    ->where('order_id', $existingOrderId)
                    ->update([
                        'qty' => $qty,
                        'qty_base' => $qty,
                        'unit_rate' => $unitRate,
                        'updated_at' => now(),
                    ]);

                if (Schema::hasTable('commercial_order_events')) {
                    DB::table('commercial_order_events')->insert([
                        'company_id' => (int) $existing->company_id,
                        'order_kind' => 'sale',
                        'order_id' => $existingOrderId,
                        'user_id' => $userId,
                        'event' => 'amended',
                        'reason' => (string) ($payload['amend_reason'] ?? 'Order customized before closing'),
                        'details_json' => json_encode([
                            'qty' => $qty,
                            'unit_rate' => $unitRate,
                            'promised_date' => $promisedDate,
                            'version' => $newVersion,
                        ], JSON_THROW_ON_ERROR),
                        'created_at' => now(),
                    ]);
                }

                return $existingOrderId;
            }
        }

        $prefix = ($payload['source_type'] ?? '') === 'water_tanker' ? 'SO-TNK-' : 'SO-CAN-';
        $referenceNo = trim((string) ($payload['reference_no'] ?? ''));
        if ($referenceNo === '') {
            $referenceNo = $prefix . date('Ymd') . '-' . strtoupper(bin2hex(random_bytes(3)));
        }
        while (DB::table('sales_orders')->where('company_id', $companyId)->where('reference_no', $referenceNo)->exists()) {
            $referenceNo = $prefix . date('Ymd') . '-' . strtoupper(bin2hex(random_bytes(3)));
        }

        $attributes['order_version'] = 1;

        $orderId = (int) DB::table('sales_orders')->insertGetId([
            'company_id' => $companyId,
            'branch_id' => $branchId,
            'financial_year_id' => $financialYearId,
            'customer_id' => $customerId,
            'warehouse_id' => $warehouseId,
            'user_id' => $userId,
            'reference_no' => $referenceNo,
            'business_date' => $businessDate,
            'promised_date' => $promisedDate,
            'note' => $note,
            'status' => 'open',
            'attributes_json' => json_encode($attributes, JSON_THROW_ON_ERROR),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('commercial_order_items')->insert([
            'company_id' => $companyId,
            'order_kind' => 'sale',
            'order_id' => $orderId,
            'source_line_id' => null,
            'product_id' => $productId,
            'uom_id' => $uomId,
            'variant_id' => null,
            'product_batch_id' => null,
            'batch_no' => null,
            'qty' => $qty,
            'qty_base' => $qty,
            'unit_rate' => $unitRate,
            'cancelled_qty_base' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        if (Schema::hasTable('commercial_order_events')) {
            DB::table('commercial_order_events')->insert([
                'company_id' => $companyId,
                'order_kind' => 'sale',
                'order_id' => $orderId,
                'user_id' => $userId,
                'event' => 'created',
                'reason' => 'Field sales order created',
                'details_json' => json_encode([
                    'date' => $businessDate,
                    'source_type' => $payload['source_type'] ?? 'water_can',
                    'source_ref' => $payload['source_ref'] ?? null,
                    'order_origin' => $payload['order_origin'] ?? 'on_day',
                    'qty' => $qty,
                    'unit_rate' => $unitRate,
                ], JSON_THROW_ON_ERROR),
                'created_at' => now(),
            ]);
        }

        return $orderId;
    }

    /**
     * Link a closed Sales Bill (`sales.id`) to its origin `sales_orders` record via
     * `commercial_order_allocations` and transition the Sales Order status to `fulfilled`.
     */
    public function fulfillSalesOrder(
        int $companyId,
        ?int $salesOrderId,
        int $saleId,
        float $fulfilledQty,
        int $actorId = 1
    ): void {
        if (empty($salesOrderId) || $saleId <= 0 || !Schema::hasTable('sales_orders')) {
            return;
        }

        try {
            $order = DB::table('sales_orders')->where('id', $salesOrderId)->first();
            if (!$order) {
                return;
            }

            $orderCompanyId = (int) $order->company_id;
            $orderItem = Schema::hasTable('commercial_order_items')
                ? DB::table('commercial_order_items')
                    ->where('company_id', $orderCompanyId)
                    ->where('order_kind', 'sale')
                    ->where('order_id', $salesOrderId)
                    ->orderBy('id')
                    ->first()
                : null;

            $saleLine = DB::table('product_sales')->where('sale_id', $saleId)->orderBy('id')->first();
            $saleHeader = DB::table('sales')->where('id', $saleId)->first(['id', 'reference_no', 'grand_total']);

            if ($orderItem && $saleLine && Schema::hasTable('commercial_order_allocations')) {
                foreach (['billing', 'delivery'] as $stage) {
                    $identity = [
                        'company_id' => $orderCompanyId,
                        'order_item_id' => (int) $orderItem->id,
                        'consumer_type' => 'sale',
                        'consumer_item_id' => (int) $saleLine->id,
                        'stage' => $stage,
                    ];
                    if (!DB::table('commercial_order_allocations')->where($identity)->exists()) {
                        DB::table('commercial_order_allocations')->insert($identity + [
                            'consumer_id' => $saleId,
                            'qty_base' => round(max(0.0001, $fulfilledQty), 4),
                            'returned_qty_base' => 0,
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);
                    }
                }
            }

            $attrs = json_decode((string) ($order->attributes_json ?? '{}'), true) ?: [];
            $attrs['sale_id'] = $saleId;
            $attrs['sale_reference_no'] = $saleHeader?->reference_no;
            $attrs['fulfilled_qty'] = round($fulfilledQty, 4);
            $attrs['fulfilled_total'] = (float) ($saleHeader?->grand_total ?? 0);
            $attrs['fulfilled_at'] = now()->toIso8601String();

            DB::table('sales_orders')->where('id', $salesOrderId)->update([
                'status' => 'fulfilled',
                'attributes_json' => json_encode($attrs, JSON_THROW_ON_ERROR),
                'updated_at' => now(),
            ]);

            if (Schema::hasTable('commercial_order_events')) {
                DB::table('commercial_order_events')->insert([
                    'company_id' => $orderCompanyId,
                    'order_kind' => 'sale',
                    'order_id' => $salesOrderId,
                    'user_id' => $actorId,
                    'event' => 'fulfilled',
                    'reason' => 'Closed into Sales Bill ' . ($saleHeader?->reference_no ?? ('#' . $saleId)),
                    'details_json' => json_encode([
                        'sale_id' => $saleId,
                        'sale_reference_no' => $saleHeader?->reference_no,
                        'fulfilled_qty' => round($fulfilledQty, 4),
                    ], JSON_THROW_ON_ERROR),
                    'created_at' => now(),
                ]);
            }
        } catch (\Throwable $e) {
            Log::warning('SalesOrder fulfillment sync skipped: ' . $e->getMessage());
        }
    }

    /**
     * Mark a linked `sales_orders` header cancelled cleanly when an open order is voided.
     */
    public function cancelSalesOrder(?int $salesOrderId, string $reason = '', int $actorId = 1): void
    {
        if (empty($salesOrderId) || !Schema::hasTable('sales_orders')) {
            return;
        }

        try {
            $order = DB::table('sales_orders')->where('id', $salesOrderId)->first();
            if (!$order || $order->status === 'fulfilled') {
                return;
            }

            DB::table('sales_orders')->where('id', $salesOrderId)->update([
                'status' => 'cancelled',
                'updated_at' => now(),
            ]);

            if (Schema::hasTable('commercial_order_events')) {
                DB::table('commercial_order_events')->insert([
                    'company_id' => (int) $order->company_id,
                    'order_kind' => 'sale',
                    'order_id' => $salesOrderId,
                    'user_id' => $actorId,
                    'event' => 'cancelled',
                    'reason' => $reason !== '' ? $reason : 'Order cancelled before delivery',
                    'details_json' => json_encode(['cancelled_at' => now()->toIso8601String()], JSON_THROW_ON_ERROR),
                    'created_at' => now(),
                ]);
            }
        } catch (\Throwable $e) {
            Log::warning('SalesOrder cancel sync skipped: ' . $e->getMessage());
        }
    }

    /**
     * Record GSTR-1 / GSTR-3B projection via GstProjectionService when possible,
     * falling back to direct `gst_transaction_projections` snapshot when compliance
     * runtime flags are disabled (e.g. PHPUnit default env or CLI seeders).
     */
    public function recordGstProjection(
        int $saleId,
        int $companyId,
        int $branchId,
        int $financialYearId,
        int $userId,
        string $referenceNo,
        string $documentDate,
        string $registrationGstin,
        array $headerSnapshot,
        array $lineSnapshots
    ): void {
        try {
            $saleModel = Sale::withoutGlobalScopes()->find($saleId);
            if (!$saleModel || !Schema::hasTable('gst_transaction_projections')) {
                return;
            }

            $recordedViaService = false;
            try {
                $context = app(CompanyContextResolver::class)->resolve($userId, $companyId, $branchId);
                app(GstProjectionService::class)->record($saleModel, 'sale', $lineSnapshots, $context);
                $recordedViaService = DB::table('gst_transaction_projections')
                    ->where('company_id', $companyId)
                    ->where('source_type', 'sale')
                    ->where('source_id', $saleId)
                    ->exists();
            } catch (\Throwable $e) {
                Log::info('VerticalSaleSyncService GST service fallback: ' . $e->getMessage());
            }

            if (!$recordedViaService) {
                $payload = $headerSnapshot + ['lines' => $lineSnapshots];
                DB::table('gst_transaction_projections')->updateOrInsert(
                    [
                        'company_id' => $companyId,
                        'source_type' => 'sale',
                        'source_id' => $saleId,
                    ],
                    [
                        'branch_id' => $branchId,
                        'financial_year_id' => $financialYearId,
                        'document_no' => $referenceNo,
                        'document_date' => CarbonImmutable::parse($documentDate)->toDateString(),
                        'registration_gstin' => $registrationGstin,
                        'version' => 1,
                        'snapshot_json' => json_encode($payload, JSON_THROW_ON_ERROR),
                        'created_at' => now(),
                    ]
                );
            }
        } catch (\Throwable $e) {
            Log::warning('GST projection write skipped: ' . $e->getMessage());
        }
    }

    private function resolveBranchId(int $companyId, ?int $requested): int
    {
        if ($requested && DB::table('company_branches')->where('company_id', $companyId)->where('id', $requested)->exists()) {
            return (int) $requested;
        }
        return (int) (DB::table('company_branches')
            ->where('company_id', $companyId)
            ->where('is_active', 1)
            ->orderByRaw("CASE WHEN branch_type = 'main' THEN 0 ELSE 1 END")
            ->orderBy('id')
            ->value('id') ?: 1);
    }

    private function resolveWarehouseId(int $companyId, int $branchId, ?int $requested): int
    {
        if ($requested && DB::table('warehouses')->where('company_id', $companyId)->where('id', $requested)->exists()) {
            return (int) $requested;
        }
        return (int) (DB::table('warehouses')
            ->where('company_id', $companyId)
            ->where('is_active', 1)
            ->orderBy('id')
            ->value('id') ?: 1);
    }

    private function resolveBillerId(int $companyId, ?int $requested): int
    {
        if ($requested && DB::table('billers')->where('company_id', $companyId)->where('id', $requested)->exists()) {
            return (int) $requested;
        }
        return (int) (DB::table('billers')->where('company_id', $companyId)->where('is_active', 1)->orderBy('id')->value('id')
            ?? DB::table('billers')->orderBy('id')->value('id')
            ?: 1);
    }

    private function resolveFinancialYearId(int $companyId, ?int $requested): int
    {
        if ($requested && DB::table('fiscal_years')->where('company_id', $companyId)->where('id', $requested)->exists()) {
            return (int) $requested;
        }
        return (int) (DB::table('fiscal_years')
            ->where('company_id', $companyId)
            ->where('is_closed', 0)
            ->orderByDesc('id')
            ->value('id') ?: $companyId);
    }

    private function resolveProduct(int $companyId, ?int $productId, ?string $productCode, ?string $name): ?object
    {
        if ($productId) {
            $found = DB::table('products')->where('id', $productId)->first();
            if ($found) {
                return $found;
            }
        }
        if ($productCode) {
            $found = DB::table('products')
                ->where('company_id', $companyId)
                ->where('code', $productCode)
                ->first();
            if ($found) {
                return $found;
            }
        }
        if ($name) {
            $found = DB::table('products')
                ->where('company_id', $companyId)
                ->where('name', 'LIKE', '%' . $name . '%')
                ->first();
            if ($found) {
                return $found;
            }
        }
        return null;
    }

    private function fallbackCompanyProductId(int $companyId): int
    {
        return (int) (DB::table('products')->where('company_id', $companyId)->where('is_active', 1)->orderBy('id')->value('id')
            ?? DB::table('products')->where('is_active', 1)->orderBy('id')->value('id')
            ?: 1);
    }

    private function defaultHsnForType(string $saleType, string $productCode): string
    {
        $codeUpper = strtoupper($productCode);
        if (str_starts_with($codeUpper, 'CAN') || str_starts_with($codeUpper, 'BTL') || $saleType === 'water_can') {
            return '22019010';
        }
        if (str_starts_with($codeUpper, 'SRV-') || $saleType === 'water_tanker_service') {
            return '996519';
        }
        if (str_starts_with($codeUpper, 'BW-') || $saleType === 'water_tanker') {
            return '22019090';
        }
        return '996331';
    }

    private function resolveTaxRule(int $companyId, ?object $product, string $date, bool $isRegisteredSeller, ?float $override): array
    {
        if ($override !== null) {
            return [$override > 0 ? 'taxable' : 'exempt', round($override, 2), $isRegisteredSeller];
        }

        if ($product && !empty($product->tax_category_id)) {
            $cat = DB::table('tax_categories')
                ->where('company_id', $companyId)
                ->where('id', $product->tax_category_id)
                ->first();
            if ($cat) {
                $rate = (float) (DB::table('tax_rates')
                    ->where('company_id', $companyId)
                    ->where('tax_category_id', $cat->id)
                    ->where('effective_from', '<=', $date)
                    ->where(fn ($q) => $q->whereNull('effective_to')->orWhere('effective_to', '>=', $date))
                    ->value('rate') ?? 0.0);

                $chargeable = $cat->supply_type === 'taxable' && $isRegisteredSeller;
                return [
                    (string) $cat->supply_type,
                    $chargeable ? round($rate, 2) : 0.0,
                    $chargeable && (bool) $cat->input_credit_allowed,
                ];
            }
        }

        return ['exempt', 0.0, false];
    }

    private function resolvePaymentAccountId(int $companyId, bool $isBank): int
    {
        $accounts = DB::table('accounts')->where('company_id', $companyId)->where('is_active', 1)->get();
        foreach ($accounts as $acc) {
            $label = strtolower(($acc->name ?? '') . ' ' . ($acc->account_no ?? ''));
            if ($isBank && (str_contains($label, 'bank') || str_contains($label, 'upi') || str_contains($label, 'icici'))) {
                return (int) $acc->id;
            }
            if (!$isBank && str_contains($label, 'cash')) {
                return (int) $acc->id;
            }
        }
        return (int) ($accounts->first()->id ?? 1);
    }
}

