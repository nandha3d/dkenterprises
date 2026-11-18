<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('delivery_schedules')) {
            Schema::create('delivery_schedules', function (Blueprint $table) {
                $table->id();
                $table->unsignedInteger('company_id')->index();
                $table->string('vertical_type', 24)->default('can')->index(); // 'can' | 'tanker'
                $table->unsignedInteger('customer_id')->index();
                $table->unsignedBigInteger('route_id')->nullable()->index();
                $table->unsignedBigInteger('tanker_id')->nullable()->index();
                $table->unsignedInteger('product_id')->nullable();
                $table->decimal('ordered_qty', 12, 3)->default(1);
                $table->decimal('unit_rate', 12, 2)->nullable();
                $table->string('payment_mode', 40)->default('Cash');
                $table->string('frequency', 32)->default('daily'); // daily, every_n_days, weekly, biweekly, monthly, one_time
                $table->unsignedInteger('interval_days')->default(1);
                $table->json('days_of_week')->nullable(); // [1..7] ISO Mon..Sun
                $table->string('preferred_time_slot', 64)->nullable();
                $table->date('start_date');
                $table->date('end_date')->nullable();
                $table->date('next_run_date')->nullable()->index();
                $table->date('last_generated_date')->nullable();
                $table->boolean('is_active')->default(true)->index();
                $table->boolean('auto_start_transit')->default(false);
                $table->string('source_plant', 255)->nullable();
                $table->string('destination_site', 255)->nullable();
                $table->text('notes')->nullable();
                $table->unsignedInteger('created_by')->nullable();
                $table->timestamps();
            });
        }

        if (Schema::hasTable('water_can_deliveries')) {
            Schema::table('water_can_deliveries', function (Blueprint $table) {
                if (!Schema::hasColumn('water_can_deliveries', 'sales_order_id')) {
                    $table->unsignedBigInteger('sales_order_id')->nullable()->after('sale_id')->index();
                }
                if (!Schema::hasColumn('water_can_deliveries', 'schedule_id')) {
                    $table->unsignedBigInteger('schedule_id')->nullable()->after('sales_order_id')->index();
                }
                if (!Schema::hasColumn('water_can_deliveries', 'order_origin')) {
                    $table->string('order_origin', 24)->default('on_day')->after('schedule_id');
                }
                if (!Schema::hasColumn('water_can_deliveries', 'scheduled_for_date')) {
                    $table->date('scheduled_for_date')->nullable()->after('order_origin');
                }
                if (!Schema::hasColumn('water_can_deliveries', 'schedule_label')) {
                    $table->string('schedule_label', 80)->nullable()->after('scheduled_for_date');
                }
            });
        }

        if (Schema::hasTable('water_tanker_trips')) {
            Schema::table('water_tanker_trips', function (Blueprint $table) {
                if (!Schema::hasColumn('water_tanker_trips', 'sale_id')) {
                    $table->unsignedBigInteger('sale_id')->nullable()->after('invoice_id')->index();
                }
                if (!Schema::hasColumn('water_tanker_trips', 'sales_order_id')) {
                    $table->unsignedBigInteger('sales_order_id')->nullable()->after('sale_id')->index();
                }
                if (!Schema::hasColumn('water_tanker_trips', 'schedule_id')) {
                    $table->unsignedBigInteger('schedule_id')->nullable()->after('sales_order_id')->index();
                }
                if (!Schema::hasColumn('water_tanker_trips', 'order_origin')) {
                    $table->string('order_origin', 24)->default('on_day')->after('schedule_id');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'scheduled_for_date')) {
                    $table->date('scheduled_for_date')->nullable()->after('order_origin');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'schedule_label')) {
                    $table->string('schedule_label', 80)->nullable()->after('scheduled_for_date');
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('water_tanker_trips')) {
            Schema::table('water_tanker_trips', function (Blueprint $table) {
                $cols = array_values(array_filter([
                    'sales_order_id',
                    'schedule_id',
                    'order_origin',
                    'scheduled_for_date',
                    'schedule_label',
                ], fn ($c) => Schema::hasColumn('water_tanker_trips', $c)));
                if (!empty($cols)) {
                    $table->dropColumn($cols);
                }
            });
        }

        if (Schema::hasTable('water_can_deliveries')) {
            Schema::table('water_can_deliveries', function (Blueprint $table) {
                $cols = array_values(array_filter([
                    'sales_order_id',
                    'schedule_id',
                    'order_origin',
                    'scheduled_for_date',
                    'schedule_label',
                ], fn ($c) => Schema::hasColumn('water_can_deliveries', $c)));
                if (!empty($cols)) {
                    $table->dropColumn($cols);
                }
            });
        }

        Schema::dropIfExists('delivery_schedules');
    }
};

