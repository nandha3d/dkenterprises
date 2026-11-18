<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WaterCanDelivery extends Model
{
    protected $fillable = [
        'delivery_no',
        'delivery_date',
        'route_id',
        'customer_id',
        'sale_id',
        'sales_order_id',
        'schedule_id',
        'order_origin',
        'scheduled_for_date',
        'schedule_label',
        'morning_loaded_cans',
        'ordered_cans',
        'ordered_by',
        'ordered_at',
        'en_route_at',
        'completed_at',
        'order_source',
        'order_notes',
        'cans_delivered',
        'empty_cans_returned',
        'can_rate',
        'total_amount',
        'extra_charge',
        'discount_amount',
        'adjustment_note',
        'paid_amount',
        'payment_mode',
        'payment_verification_status',
        'payment_proof_path',
        'payment_verified_at',
        'payment_verified_by',
        'item_category',
        'bakery_items_json',
        'bakery_pieces_delivered',
        'balance_cans_held',
        'status',
        'delivery_lat',
        'delivery_lng',
        'refill_photo',
        'created_by'
    ];

    public function route()
    {
        return $this->belongsTo(WaterCanRoute::class, 'route_id');
    }

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }
}
