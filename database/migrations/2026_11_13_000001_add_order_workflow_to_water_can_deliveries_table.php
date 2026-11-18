<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('water_can_deliveries')) {
            return;
        }

        Schema::table('water_can_deliveries', function (Blueprint $table) {
            if (!Schema::hasColumn('water_can_deliveries', 'ordered_cans')) {
                $table->integer('ordered_cans')->default(0)->after('morning_loaded_cans');
            }
            if (!Schema::hasColumn('water_can_deliveries', 'ordered_by')) {
                $table->unsignedInteger('ordered_by')->nullable()->after('ordered_cans');
            }
            if (!Schema::hasColumn('water_can_deliveries', 'ordered_at')) {
                $table->timestamp('ordered_at')->nullable()->after('ordered_by');
            }
            if (!Schema::hasColumn('water_can_deliveries', 'en_route_at')) {
                $table->timestamp('en_route_at')->nullable()->after('ordered_at');
            }
            if (!Schema::hasColumn('water_can_deliveries', 'completed_at')) {
                $table->timestamp('completed_at')->nullable()->after('en_route_at');
            }
            if (!Schema::hasColumn('water_can_deliveries', 'order_source')) {
                $table->string('order_source', 40)->nullable()->after('completed_at');
            }
            if (!Schema::hasColumn('water_can_deliveries', 'order_notes')) {
                $table->text('order_notes')->nullable()->after('order_source');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('water_can_deliveries')) {
            return;
        }

        Schema::table('water_can_deliveries', function (Blueprint $table) {
            $cols = array_values(array_filter([
                'ordered_cans',
                'ordered_by',
                'ordered_at',
                'en_route_at',
                'completed_at',
                'order_source',
                'order_notes',
            ], fn ($c) => Schema::hasColumn('water_can_deliveries', $c)));

            if (!empty($cols)) {
                $table->dropColumn($cols);
            }
        });
    }
};

