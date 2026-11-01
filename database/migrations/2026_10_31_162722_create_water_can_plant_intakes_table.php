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
        if (!Schema::hasTable('water_can_plant_intakes')) {
            Schema::create('water_can_plant_intakes', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('route_id');
                $table->unsignedBigInteger('driver_id')->nullable();
                $table->string('plant_name')->default('Main RO Water Treatment Plant');
                $table->integer('load_sequence')->default(1); // 1 for Load 1, 2 for Load 2, 3 for Load 3
                $table->integer('cans_loaded')->default(0);
                $table->decimal('purchase_rate_per_can', 8, 2)->default(8.00);
                $table->string('slip_number')->nullable();
                $table->string('slip_photo')->nullable();
                $table->integer('odometer_km')->default(0);
                $table->decimal('latitude', 10, 7)->nullable();
                $table->decimal('longitude', 10, 7)->nullable();
                $table->timestamp('intake_time')->nullable();
                $table->text('notes')->nullable();
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('water_can_plant_intakes');
    }
};
