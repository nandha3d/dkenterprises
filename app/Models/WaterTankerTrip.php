<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WaterTankerTrip extends Model
{
    protected $fillable = [
        'trip_number',
        'tanker_id',
        'customer_id',
        'pickup_point_id',
        'pickup_point_name',
        'is_outsourced_vehicle',
        'external_vehicle_no',
        'external_vendor_name',
        'vendor_payable_amount',
        'trip_date',
        'source_plant',
        'destination_site',
        'water_quantity_kl',
        'start_km',
        'end_km',
        'total_km',
        'trip_rate',
        'motor_pumping_minutes',
        'motor_pumping_charge',
        'waiting_minutes',
        'waiting_charge',
        'excess_km',
        'excess_km_charge',
        'extra_charge',
        'discount_amount',
        'adjustment_note',
        'paid_amount',
        'payment_mode',
        'payment_verification_status',
        'payment_proof_path',
        'payment_verified_at',
        'payment_verified_by',
        'diesel_expense',
        'toll_expense',
        'driver_batta',
        'site_receiver_name',
        'site_receiver_signature',
        'status',
        'invoice_id',
        'sale_id',
        'sales_order_id',
        'schedule_id',
        'order_origin',
        'scheduled_for_date',
        'schedule_label',
        'notes',
        'created_by'
    ];

    public function tanker()
    {
        return $this->belongsTo(WaterTanker::class, 'tanker_id');
    }

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }

    public function pickupPoint()
    {
        return $this->belongsTo(WaterPickupPoint::class, 'pickup_point_id');
    }
}
