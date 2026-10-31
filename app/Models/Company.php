<?php

namespace App\Models;

use App\Models\Accounting\FiscalYear;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Company extends Model
{
    protected $fillable = [
        'company_group_id', 'code', 'legal_name', 'trade_name', 'country_code', 'base_currency_id',
        'state_code', 'timezone', 'status', 'settings_json',
    ];

    protected $casts = ['settings_json' => 'array'];

    public function group(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(CompanyGroup::class, 'company_group_id');
    }

    public function branches(): HasMany
    {
        return $this->hasMany(CompanyBranch::class);
    }

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'company_user')
            ->withPivot(['is_default', 'role_id_override'])->withTimestamps();
    }

    public function fiscalYears(): HasMany
    {
        return $this->hasMany(FiscalYear::class);
    }

    public function getIndustryAttribute(): ?string
    {
        if (\Illuminate\Support\Facades\Schema::hasTable('company_industry_settings')) {
            $profile = \Illuminate\Support\Facades\DB::table('company_industry_settings')
                ->where('company_id', $this->id)
                ->value('profile_key');
            if ($profile) {
                return $profile;
            }
        }
        if ($this->code === 'TMWS' || str_contains(strtolower($this->trade_name ?? ''), 'tanker') || str_contains(strtolower($this->trade_name ?? ''), 'murugan')) {
            return 'bulk_water';
        }
        if ($this->code === 'DKWATERS' || str_contains(strtolower($this->trade_name ?? ''), 'water')) {
            return 'packaged_water';
        }
        if ($this->code === 'ARANCAFE' || str_contains(strtolower($this->trade_name ?? ''), 'cafe')) {
            return 'cafe_bakery';
        }
        return null;
    }
}
