<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('customers')) {
            Schema::table('customers', function (Blueprint $table) {
                if (!Schema::hasColumn('customers', 'latitude')) {
                    $table->decimal('latitude', 10, 7)->nullable()->after('postal_code');
                }
                if (!Schema::hasColumn('customers', 'longitude')) {
                    $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
                }
                if (!Schema::hasColumn('customers', 'geofence_radius')) {
                    $table->integer('geofence_radius')->default(100)->after('longitude');
                }
            });
        }

        if (Schema::hasTable('water_tankers')) {
            Schema::table('water_tankers', function (Blueprint $table) {
                if (!Schema::hasColumn('water_tankers', 'latitude')) {
                    $table->decimal('latitude', 10, 7)->nullable()->after('is_active');
                }
                if (!Schema::hasColumn('water_tankers', 'longitude')) {
                    $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
                }
                if (!Schema::hasColumn('water_tankers', 'current_speed')) {
                    $table->integer('current_speed')->default(0)->after('longitude');
                }
                if (!Schema::hasColumn('water_tankers', 'current_odometer_km')) {
                    $table->integer('current_odometer_km')->default(0)->after('current_speed');
                }
                if (!Schema::hasColumn('water_tankers', 'last_ping_at')) {
                    $table->timestamp('last_ping_at')->nullable()->after('current_odometer_km');
                }
            });
        }

        if (Schema::hasTable('water_tanker_trips')) {
            Schema::table('water_tanker_trips', function (Blueprint $table) {
                if (!Schema::hasColumn('water_tanker_trips', 'sale_id')) {
                    $table->unsignedBigInteger('sale_id')->nullable()->after('invoice_id');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'start_km')) {
                    $table->integer('start_km')->default(0)->after('water_quantity_kl');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'end_km')) {
                    $table->integer('end_km')->default(0)->after('start_km');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'total_km')) {
                    $table->integer('total_km')->default(0)->after('end_km');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'motor_pumping_minutes')) {
                    $table->integer('motor_pumping_minutes')->default(0)->after('trip_rate');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'motor_pumping_charge')) {
                    $table->decimal('motor_pumping_charge', 10, 2)->default(0)->after('motor_pumping_minutes');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'waiting_minutes')) {
                    $table->integer('waiting_minutes')->default(0)->after('motor_pumping_charge');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'waiting_charge')) {
                    $table->decimal('waiting_charge', 10, 2)->default(0)->after('waiting_minutes');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'excess_km')) {
                    $table->integer('excess_km')->default(0)->after('waiting_charge');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'excess_km_charge')) {
                    $table->decimal('excess_km_charge', 10, 2)->default(0)->after('excess_km');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'discount_amount')) {
                    $table->decimal('discount_amount', 10, 2)->default(0)->after('excess_km_charge');
                }
            });
        }

        if (Schema::hasTable('water_can_deliveries')) {
            Schema::table('water_can_deliveries', function (Blueprint $table) {
                if (!Schema::hasColumn('water_can_deliveries', 'sale_id')) {
                    $table->unsignedBigInteger('sale_id')->nullable()->after('customer_id');
                }
                if (!Schema::hasColumn('water_can_deliveries', 'delivery_lat')) {
                    $table->decimal('delivery_lat', 10, 7)->nullable()->after('status');
                }
                if (!Schema::hasColumn('water_can_deliveries', 'delivery_lng')) {
                    $table->decimal('delivery_lng', 10, 7)->nullable()->after('delivery_lat');
                }
                if (!Schema::hasColumn('water_can_deliveries', 'refill_photo')) {
                    $table->string('refill_photo')->nullable()->after('delivery_lng');
                }
            });
        }
    }

    public function down(): void
    {
    }
};
