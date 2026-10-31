<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->boolean('is_water_logistics')->default(false)->after('negative_stock_policy');
            $table->string('water_vertical_type', 50)->nullable()->after('is_water_logistics');
            $table->string('water_capacity_spec', 50)->nullable()->after('water_vertical_type');
            $table->string('water_compartment_config', 100)->nullable()->after('water_capacity_spec');
            $table->decimal('base_km_limit', 8, 2)->nullable()->default(10.00)->after('water_compartment_config');
            $table->decimal('excess_km_rate', 8, 2)->nullable()->default(45.00)->after('base_km_limit');
            $table->decimal('motor_pump_rate', 8, 2)->nullable()->default(10.00)->after('excess_km_rate');
            $table->decimal('waiting_charge_rate', 8, 2)->nullable()->default(15.00)->after('motor_pump_rate');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn([
                'is_water_logistics',
                'water_vertical_type',
                'water_capacity_spec',
                'water_compartment_config',
                'base_km_limit',
                'excess_km_rate',
                'motor_pump_rate',
                'waiting_charge_rate',
            ]);
        });
    }
};
