<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WaterTankerTrip extends Model
{
    protected $guarded = ['id'];

    public function tanker()
    {
        return $this->belongsTo(WaterTanker::class, 'tanker_id');
    }

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }
}
