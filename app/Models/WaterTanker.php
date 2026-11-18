<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WaterTanker extends Model
{
    protected $fillable = [
        'company_id',
        'vehicle_number',
        'model_type',
        'vehicle_variant',
        'capacity_kl',
        'capacity_liters',
        'supported_capacities_json',
        'has_compartments',
        'compartment_notes',
        'is_outsourced',
        'vendor_name',
        'vendor_phone',
        'driver_name',
        'driver_phone',
        'is_active'
    ];

    public function trips()
    {
        return $this->hasMany(WaterTankerTrip::class, 'tanker_id');
    }
}
