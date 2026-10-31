<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WaterTanker extends Model
{
    protected $guarded = ['id'];

    public function trips()
    {
        return $this->hasMany(WaterTankerTrip::class, 'tanker_id');
    }
}
