<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DeliverySchedule extends Model
{
    protected $fillable = [
        'company_id',
        'vertical_type',
        'customer_id',
        'route_id',
        'tanker_id',
        'product_id',
        'ordered_qty',
        'unit_rate',
        'payment_mode',
        'frequency',
        'interval_days',
        'days_of_week',
        'preferred_time_slot',
        'start_date',
        'end_date',
        'next_run_date',
        'last_generated_date',
        'is_active',
        'auto_start_transit',
        'source_plant',
        'destination_site',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'company_id' => 'integer',
        'customer_id' => 'integer',
        'route_id' => 'integer',
        'tanker_id' => 'integer',
        'product_id' => 'integer',
        'ordered_qty' => 'float',
        'unit_rate' => 'float',
        'interval_days' => 'integer',
        'days_of_week' => 'array',
        'start_date' => 'date:Y-m-d',
        'end_date' => 'date:Y-m-d',
        'next_run_date' => 'date:Y-m-d',
        'last_generated_date' => 'date:Y-m-d',
        'is_active' => 'boolean',
        'auto_start_transit' => 'boolean',
    ];

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }

    public function route()
    {
        return $this->belongsTo(WaterCanRoute::class, 'route_id');
    }

    public function tanker()
    {
        return $this->belongsTo(WaterTanker::class, 'tanker_id');
    }

    /**
     * Human-readable schedule badge shown on mobile & web cards so staff distinguish
     * regular scheduled orders from ad-hoc on-day bookings.
     */
    public function describeLabel(): string
    {
        $freq = strtolower((string) $this->frequency);
        $interval = max(1, (int) $this->interval_days);

        return match ($freq) {
            'daily' => 'Regular · Daily',
            'every_n_days' => $interval === 2 ? 'Regular · Every 2 Days' : "Regular · Every {$interval} Days",
            'weekly' => $this->formatWeeklyLabel('Regular · Weekly'),
            'biweekly' => $this->formatWeeklyLabel('Regular · Every 2 Weeks'),
            'monthly' => 'Regular · Monthly',
            'one_time' => 'Scheduled · One-Time',
            default => 'Regular · Scheduled',
        };
    }

    private function formatWeeklyLabel(string $prefix): string
    {
        $names = [1 => 'Mon', 2 => 'Tue', 3 => 'Wed', 4 => 'Thu', 5 => 'Fri', 6 => 'Sat', 7 => 'Sun'];
        $days = array_values(array_filter(array_map('intval', is_array($this->days_of_week) ? $this->days_of_week : []), fn ($d) => isset($names[$d])));
        if (empty($days)) {
            return $prefix;
        }
        $dayText = implode(',', array_map(fn ($d) => $names[$d], $days));
        return "{$prefix} ({$dayText})";
    }
}

