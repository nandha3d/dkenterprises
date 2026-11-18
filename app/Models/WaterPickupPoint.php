<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WaterPickupPoint extends Model
{
    protected $table = 'water_pickup_points';

    protected $fillable = [
        'company_id',
        'name',
        'code',
        'location_type',
        'address',
        'latitude',
        'longitude',
        'geofence_radius_m',
        'owner_name',
        'owner_phone',
        'rate_per_load',
        'settlement_cycle',
        'is_active',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'geofence_radius_m' => 'integer',
        'rate_per_load' => 'float',
        'is_active' => 'boolean',
    ];

    public function trips()
    {
        return $this->hasMany(WaterTankerTrip::class, 'pickup_point_id');
    }
}
