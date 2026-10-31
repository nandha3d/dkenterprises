<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WaterCanRoute extends Model
{
    protected $guarded = ['id'];

    public function deliveries()
    {
        return $this->hasMany(WaterCanDelivery::class, 'route_id');
    }
}
