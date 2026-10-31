<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WaterCanDelivery extends Model
{
    protected $guarded = ['id'];

    public function route()
    {
        return $this->belongsTo(WaterCanRoute::class, 'route_id');
    }

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }
}
