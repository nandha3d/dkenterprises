<?php

namespace App\Services\Water;

use App\Models\DeliverySchedule;
use App\Models\WaterCanDelivery;
use App\Models\WaterTankerTrip;
use App\Services\ERP\VerticalSaleSyncService;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Recurring & Customizable Delivery Scheduling Engine for BOTH:
 *  - Packaged Water (20L Can Van Routes)
 *  - Bulk Water Tanker Lorries (KL Tanker Supply)
 *
 * Supports: daily, every_n_days (e.g., every 2 days), weekly (selected ISO weekdays),
 * biweekly, monthly, and one_time schedules. Every materialized schedule occurrence
 * creates an ERP `sales_orders` record linked to an open `water_can_deliveries` or
 * `water_tanker_trips` order tagged with `order_origin = 'scheduled'`.
 */
class DeliveryScheduleService
{
    public const VALID_FREQUENCIES = [
        'daily',
        'every_n_days',
        'weekly',
        'biweekly',
        'monthly',
        'one_time',
    ];

    public function __construct(
        private readonly VerticalSaleSyncService $erpSync
    ) {}

    /**
     * Normalize frequency aliases (e.g. "2_days" -> every_n_days) and weekday arrays.
     */
    public function normalizeFrequency(string $frequency, ?int $intervalDays = null): array
    {
        $freq = strtolower(trim($frequency));
        $interval = max(1, (int) ($intervalDays ?? 1));

        if (in_array($freq, ['2_days', 'alternate', 'every_2_days'], true)) {
            return ['every_n_days', 2];
        }
        if (in_array($freq, ['every_n_days', 'custom_days', 'custom'], true)) {
            return ['every_n_days', max(2, $interval)];
        }
        if (in_array($freq, self::VALID_FREQUENCIES, true)) {
            return [$freq, $freq === 'every_n_days' ? max(2, $interval) : $interval];
        }

        return ['daily', 1];
    }

    /**
     * Normalize day-of-week entries (numbers 1..7 or 'Mon'..'Sun') into sorted ISO ints 1..7.
     */
    public function normalizeDaysOfWeek(?array $days, ?string $fallbackDate = null): array
    {
        $map = [
            'mon' => 1, 'monday' => 1, '1' => 1,
            'tue' => 2, 'tuesday' => 2, '2' => 2,
            'wed' => 3, 'wednesday' => 3, '3' => 3,
            'thu' => 4, 'thursday' => 4, '4' => 4,
            'fri' => 5, 'friday' => 5, '5' => 5,
            'sat' => 6, 'saturday' => 6, '6' => 6,
            'sun' => 7, 'sunday' => 7, '7' => 7,
        ];

        $out = [];
        foreach ($days ?? [] as $d) {
            if (is_int($d) && $d >= 1 && $d <= 7) {
                $out[] = $d;
                continue;
            }
            $k = strtolower(trim((string) $d));
            if (isset($map[$k])) {
                $out[] = $map[$k];
            }
        }
        $out = array_values(array_unique($out));
        sort($out);

        if (empty($out) && $fallbackDate) {
            $out[] = CarbonImmutable::parse($fallbackDate)->dayOfWeekIso;
        }

        return $out;
    }

    /**
     * Compute the first run date on or after `start_date`.
     */
    public function computeFirstRunDate(
        string $startDate,
        string $frequency,
        int $intervalDays = 1,
        array $daysOfWeek = []
    ): string {
        $start = CarbonImmutable::parse($startDate)->startOfDay();
        if (in_array($frequency, ['weekly', 'biweekly'], true) && !empty($daysOfWeek)) {
            for ($offset = 0; $offset < 14; $offset++) {
                $cand = $start->addDays($offset);
                if (in_array($cand->dayOfWeekIso, $daysOfWeek, true)) {
                    return $cand->toDateString();
                }
            }
        }

        return $start->toDateString();
    }

    /**
     * Compute the next scheduled run date strictly AFTER `$afterDate`, or null if ended / one-time.
     */
    public function computeNextOccurrence(
        DeliverySchedule $schedule,
        CarbonImmutable $afterDate
    ): ?CarbonImmutable {
        $freq = strtolower((string) $schedule->frequency);
        if ($freq === 'one_time') {
            return null;
        }

        $start = CarbonImmutable::parse($schedule->start_date)->startOfDay();
        $end = $schedule->end_date ? CarbonImmutable::parse($schedule->end_date)->startOfDay() : null;
        $cursor = $afterDate->startOfDay();

        $candidate = match ($freq) {
            'daily' => $cursor->addDay(),
            'every_n_days' => $cursor->addDays(max(2, (int) ($schedule->interval_days ?: 2))),
            'weekly' => $this->nextWeekday($cursor, $this->normalizeDaysOfWeek($schedule->days_of_week, $start->toDateString()), false, $start),
            'biweekly' => $this->nextWeekday($cursor, $this->normalizeDaysOfWeek($schedule->days_of_week, $start->toDateString()), true, $start),
            'monthly' => $this->nextMonthly($cursor, $start->day),
            default => $cursor->addDay(),
        };

        if ($candidate && $candidate->lt($start)) {
            $candidate = $start;
        }

        if ($candidate && $end && $candidate->gt($end)) {
            return null;
        }

        return $candidate;
    }

    private function nextWeekday(
        CarbonImmutable $afterDate,
        array $isoDays,
        bool $biweekly,
        CarbonImmutable $anchorStart
    ): ?CarbonImmutable {
        if (empty($isoDays)) {
            $isoDays = [$anchorStart->dayOfWeekIso];
        }

        $anchorWeek = $anchorStart->startOfWeek(CarbonImmutable::MONDAY);
        for ($i = 1; $i <= 28; $i++) {
            $cand = $afterDate->addDays($i);
            if (!in_array($cand->dayOfWeekIso, $isoDays, true)) {
                continue;
            }
            if ($biweekly) {
                $weeks = (int) $anchorWeek->diffInWeeks($cand->startOfWeek(CarbonImmutable::MONDAY));
                if ($weeks % 2 !== 0) {
                    continue;
                }
            }
            return $cand;
        }

        return $afterDate->addWeeks($biweekly ? 2 : 1);
    }

    private function nextMonthly(CarbonImmutable $afterDate, int $targetDay): CarbonImmutable
    {
        $nextMonth = $afterDate->addMonthsNoOverflow(1);
        $clampedDay = min(max(1, $targetDay), $nextMonth->daysInMonth);
        return $nextMonth->setDay($clampedDay);
    }

    /**
     * Skip the next scheduled occurrence without creating an order for that date.
     */
    public function skipNextOccurrence(DeliverySchedule $schedule, ?string $todayDate = null): DeliverySchedule
    {
        $anchor = $schedule->next_run_date
            ? CarbonImmutable::parse($schedule->next_run_date)->startOfDay()
            : CarbonImmutable::parse($todayDate ?? now()->toDateString())->startOfDay();

        $next = $this->computeNextOccurrence($schedule, $anchor);
        $schedule->next_run_date = $next?->toDateString();
        if ($next === null) {
            $schedule->is_active = false;
        }
        $schedule->save();

        return $schedule->fresh();
    }

    /**
     * Idempotently materialize all due active schedules for a company into real
     * ERP `sales_orders` + open Can Orders / Tanker Trips for `$forDate` (defaults today).
     */
    public function materializeDueSchedules(
        int $companyId,
        ?string $verticalType = null,
        ?string $forDate = null,
        ?int $actorId = null
    ): array {
        if (!Schema::hasTable('delivery_schedules')) {
            return [];
        }

        $targetDate = CarbonImmutable::parse($forDate ?? now()->toDateString())->toDateString();

        $schedules = DeliverySchedule::query()
            ->where('company_id', $companyId)
            ->when($verticalType !== null, fn ($q) => $q->where('vertical_type', $verticalType))
            ->where('is_active', true)
            ->whereNotNull('next_run_date')
            ->whereDate('next_run_date', '<=', $targetDate)
            ->orderBy('id')
            ->get();

        $created = [];
        foreach ($schedules as $schedule) {
            $item = $this->materializeSingleSchedule($schedule, $targetDate, $actorId, false);
            if ($item !== null) {
                $created[] = $item;
            }
        }

        return $created;
    }

    /**
     * Immediately generate an order from a schedule on `$forDate` (used both by automatic
     * due-run materialization and manual "Generate Today's Order" action).
     */
    public function materializeSingleSchedule(
        DeliverySchedule $schedule,
        ?string $forDate = null,
        ?int $actorId = null,
        bool $forceManual = true
    ): ?array {
        $targetDate = CarbonImmutable::parse($forDate ?? now()->toDateString())->toDateString();

        if ($schedule->end_date && $targetDate > $schedule->end_date->toDateString()) {
            $schedule->update(['is_active' => false, 'next_run_date' => null]);
            return null;
        }

        if (!$forceManual && $schedule->last_generated_date && $schedule->last_generated_date->toDateString() >= $targetDate) {
            return null;
        }

        return DB::transaction(function () use ($schedule, $targetDate, $actorId, $forceManual) {
            $locked = DeliverySchedule::query()->whereKey($schedule->id)->lockForUpdate()->first();
            if (!$locked || (!$forceManual && !$locked->is_active)) {
                return null;
            }

            $resolvedActor = $actorId ?: (int) ($locked->created_by ?: 1);
            $label = $locked->describeLabel();

            if ($locked->vertical_type === 'tanker') {
                $alreadyExists = Schema::hasColumn('water_tanker_trips', 'schedule_id')
                    && DB::table('water_tanker_trips')
                        ->where('schedule_id', $locked->id)
                        ->whereDate('scheduled_for_date', $targetDate)
                        ->where('status', '!=', 'cancelled')
                        ->exists();

                if ($alreadyExists) {
                    $this->advanceScheduleCursor($locked, $targetDate);
                    return null;
                }

                $customer = DB::table('customers')->where('id', $locked->customer_id)->first();
                $tankerId = (int) ($locked->tanker_id
                    ?: DB::table('water_tankers')->where('is_active', true)->orderBy('id')->value('id')
                    ?: 1);
                $waterKl = round(max(1.0, (float) $locked->ordered_qty), 2);
                $tripRate = round((float) ($locked->unit_rate ?? 0), 2);
                if ($tripRate <= 0) {
                    $tripRate = round($waterKl * 180.0, 2);
                }

                $tripNumber = 'TRIP-' . date('Ymd', strtotime($targetDate)) . '-' . strtoupper(bin2hex(random_bytes(3)));
                $salesOrderId = $this->erpSync->syncSalesOrder([
                    'company_id' => $locked->company_id,
                    'customer_id' => $locked->customer_id,
                    'user_id' => $resolvedActor,
                    'business_date' => $targetDate,
                    'promised_date' => $targetDate,
                    'note' => trim(($locked->notes ?? '') . " [{$label}]"),
                    'source_type' => 'water_tanker',
                    'source_ref' => $tripNumber,
                    'order_origin' => 'scheduled',
                    'schedule_id' => $locked->id,
                    'schedule_label' => $label,
                    'product_id' => $locked->product_id,
                    'product_code' => 'BW-10KL',
                    'product_name' => 'Bulk RO/Industrial Tanker Water (' . $waterKl . ' KL)',
                    'qty' => $waterKl,
                    'unit_rate' => round($tripRate / max(1.0, $waterKl), 4),
                ]);

                $trip = WaterTankerTrip::create([
                    'trip_number' => $tripNumber,
                    'tanker_id' => $tankerId,
                    'customer_id' => $locked->customer_id,
                    'sales_order_id' => $salesOrderId ?: null,
                    'schedule_id' => $locked->id,
                    'order_origin' => 'scheduled',
                    'scheduled_for_date' => $targetDate,
                    'schedule_label' => $label,
                    'trip_date' => $targetDate,
                    'source_plant' => $locked->source_plant ?: 'Main Borewell Station',
                    'destination_site' => $locked->destination_site ?: ($customer?->name ?? 'Customer Sump'),
                    'water_quantity_kl' => $waterKl,
                    'start_km' => (int) (DB::table('water_tankers')->where('id', $tankerId)->value('current_odometer_km') ?? 0),
                    'end_km' => 0,
                    'total_km' => 0,
                    'trip_rate' => $tripRate,
                    'diesel_expense' => 0,
                    'toll_expense' => 0,
                    'driver_batta' => 0,
                    'motor_pumping_minutes' => 0,
                    'motor_pumping_charge' => 0,
                    'waiting_minutes' => 0,
                    'waiting_charge' => 0,
                    'status' => $locked->auto_start_transit ? 'in_transit' : 'dispatched',
                    'notes' => json_encode([
                        'user_note' => $locked->notes,
                        'schedule_id' => $locked->id,
                        'schedule_label' => $label,
                        'preferred_time_slot' => $locked->preferred_time_slot,
                        'payment_mode' => $locked->payment_mode,
                        'sales_order_id' => $salesOrderId,
                    ]),
                    'created_by' => $resolvedActor,
                ]);

                $this->advanceScheduleCursor($locked, $targetDate);

                return [
                    'vertical_type' => 'tanker',
                    'id' => (int) $trip->id,
                    'trip_number' => $trip->trip_number,
                    'sales_order_id' => $salesOrderId ?: null,
                    'schedule_id' => (int) $locked->id,
                    'schedule_label' => $label,
                    'order_origin' => 'scheduled',
                    'is_regular_scheduled' => true,
                    'scheduled_for_date' => $targetDate,
                ];
            }

            // Packaged Water 20L Can order materialization
            $alreadyExists = Schema::hasColumn('water_can_deliveries', 'schedule_id')
                && DB::table('water_can_deliveries')
                    ->where('schedule_id', $locked->id)
                    ->whereDate('scheduled_for_date', $targetDate)
                    ->where('status', '!=', 'cancelled')
                    ->exists();

            if ($alreadyExists) {
                $this->advanceScheduleCursor($locked, $targetDate);
                return null;
            }

            $routeId = (int) ($locked->route_id
                ?: DB::table('water_can_routes')->where('is_active', true)->orderBy('id')->value('id')
                ?: 1);
            $orderedCans = max(1, (int) round((float) $locked->ordered_qty));
            $canRate = round((float) ($locked->unit_rate ?? 0), 2);
            if ($canRate <= 0) {
                $canRate = $this->resolveCustomerCanRate((int) $locked->customer_id);
            }

            $orderNo = 'ORD-' . date('Ymd', strtotime($targetDate)) . '-' . strtoupper(bin2hex(random_bytes(3)));
            $salesOrderId = $this->erpSync->syncSalesOrder([
                'company_id' => $locked->company_id,
                'customer_id' => $locked->customer_id,
                'user_id' => $resolvedActor,
                'business_date' => $targetDate,
                'promised_date' => $targetDate,
                'note' => trim(($locked->notes ?? '') . " [{$label}]"),
                'source_type' => 'water_can',
                'source_ref' => $orderNo,
                'order_origin' => 'scheduled',
                'schedule_id' => $locked->id,
                'schedule_label' => $label,
                'product_id' => $locked->product_id,
                'product_code' => 'CAN-20L',
                'product_name' => '20L Packaged Drinking Water Can Refill',
                'qty' => $orderedCans,
                'unit_rate' => $canRate,
            ]);

            $delivery = WaterCanDelivery::create([
                'delivery_no' => $orderNo,
                'delivery_date' => $targetDate,
                'route_id' => $routeId,
                'customer_id' => $locked->customer_id,
                'sales_order_id' => $salesOrderId ?: null,
                'schedule_id' => $locked->id,
                'order_origin' => 'scheduled',
                'scheduled_for_date' => $targetDate,
                'schedule_label' => $label,
                'morning_loaded_cans' => (int) (DB::table('water_can_routes')->where('id', $routeId)->value('daily_avg_cans') ?? 0),
                'ordered_cans' => $orderedCans,
                'ordered_by' => $resolvedActor,
                'ordered_at' => now(),
                'en_route_at' => $locked->auto_start_transit ? now() : null,
                'order_source' => 'schedule_auto',
                'order_notes' => $locked->notes,
                'cans_delivered' => 0,
                'empty_cans_returned' => 0,
                'can_rate' => $canRate,
                'total_amount' => 0,
                'paid_amount' => 0,
                'payment_mode' => $locked->payment_mode ?: 'Cash',
                'balance_cans_held' => 0,
                'status' => $locked->auto_start_transit ? 'in_transit' : 'ordered',
                'created_by' => $resolvedActor,
            ]);

            $this->advanceScheduleCursor($locked, $targetDate);

            return [
                'vertical_type' => 'can',
                'id' => (int) $delivery->id,
                'order_no' => $delivery->delivery_no,
                'sales_order_id' => $salesOrderId ?: null,
                'schedule_id' => (int) $locked->id,
                'schedule_label' => $label,
                'order_origin' => 'scheduled',
                'is_regular_scheduled' => true,
                'scheduled_for_date' => $targetDate,
            ];
        });
    }

    private function advanceScheduleCursor(DeliverySchedule $schedule, string $generatedForDate): void
    {
        $anchor = CarbonImmutable::parse($generatedForDate)->startOfDay();
        $next = $this->computeNextOccurrence($schedule, $anchor);

        $schedule->last_generated_date = $generatedForDate;
        $schedule->next_run_date = $next?->toDateString();
        if ($next === null) {
            $schedule->is_active = false;
        }
        $schedule->save();
    }

    private function resolveCustomerCanRate(int $customerId): float
    {
        $last = DB::table('water_can_deliveries')
            ->where('customer_id', $customerId)
            ->where('can_rate', '>', 0)
            ->orderByDesc('id')
            ->value('can_rate');

        if ($last !== null && (float) $last > 0) {
            return round((float) $last, 2);
        }

        $productPrice = DB::table('products')
            ->whereIn('code', ['CAN-20L', 'CAN20L'])
            ->where('price', '>', 0)
            ->value('price');

        return $productPrice !== null && (float) $productPrice > 0 ? round((float) $productPrice, 2) : 35.0;
    }
}

