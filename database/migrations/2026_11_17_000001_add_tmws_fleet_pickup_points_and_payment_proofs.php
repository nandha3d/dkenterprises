<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('water_pickup_points')) {
            Schema::create('water_pickup_points', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('company_id')->nullable()->index();
                $table->string('name');
                $table->string('code', 50)->nullable();
                $table->string('location_type', 40)->default('regular_borewell');
                $table->string('address')->nullable();
                $table->decimal('latitude', 10, 7)->nullable();
                $table->decimal('longitude', 10, 7)->nullable();
                $table->integer('geofence_radius_m')->default(200);
                $table->string('owner_name')->nullable();
                $table->string('owner_phone', 40)->nullable();
                $table->decimal('rate_per_load', 10, 2)->default(0);
                $table->string('settlement_cycle', 30)->default('own');
                $table->boolean('is_active')->default(true);
                $table->timestamps();
            });
        }

        if (Schema::hasTable('water_tankers')) {
            Schema::table('water_tankers', function (Blueprint $table) {
                if (!Schema::hasColumn('water_tankers', 'company_id')) {
                    $table->unsignedBigInteger('company_id')->nullable()->index();
                }
                if (!Schema::hasColumn('water_tankers', 'vehicle_variant')) {
                    $table->string('vehicle_variant', 80)->nullable();
                }
                if (!Schema::hasColumn('water_tankers', 'supported_capacities_json')) {
                    $table->text('supported_capacities_json')->nullable();
                }
                if (!Schema::hasColumn('water_tankers', 'has_compartments')) {
                    $table->boolean('has_compartments')->default(false);
                }
                if (!Schema::hasColumn('water_tankers', 'compartment_notes')) {
                    $table->string('compartment_notes')->nullable();
                }
                if (!Schema::hasColumn('water_tankers', 'is_outsourced')) {
                    $table->boolean('is_outsourced')->default(false);
                }
                if (!Schema::hasColumn('water_tankers', 'vendor_name')) {
                    $table->string('vendor_name')->nullable();
                }
                if (!Schema::hasColumn('water_tankers', 'vendor_phone')) {
                    $table->string('vendor_phone', 40)->nullable();
                }
            });
        }

        if (Schema::hasTable('water_tanker_trips')) {
            Schema::table('water_tanker_trips', function (Blueprint $table) {
                if (!Schema::hasColumn('water_tanker_trips', 'pickup_point_id')) {
                    $table->unsignedBigInteger('pickup_point_id')->nullable()->index();
                }
                if (!Schema::hasColumn('water_tanker_trips', 'pickup_point_name')) {
                    $table->string('pickup_point_name')->nullable();
                }
                if (!Schema::hasColumn('water_tanker_trips', 'is_outsourced_vehicle')) {
                    $table->boolean('is_outsourced_vehicle')->default(false);
                }
                if (!Schema::hasColumn('water_tanker_trips', 'external_vehicle_no')) {
                    $table->string('external_vehicle_no', 60)->nullable();
                }
                if (!Schema::hasColumn('water_tanker_trips', 'external_vendor_name')) {
                    $table->string('external_vendor_name')->nullable();
                }
                if (!Schema::hasColumn('water_tanker_trips', 'vendor_payable_amount')) {
                    $table->decimal('vendor_payable_amount', 12, 2)->default(0);
                }
                if (!Schema::hasColumn('water_tanker_trips', 'extra_charge')) {
                    $table->decimal('extra_charge', 12, 2)->default(0);
                }
                if (!Schema::hasColumn('water_tanker_trips', 'discount_amount')) {
                    $table->decimal('discount_amount', 12, 2)->default(0);
                }
                if (!Schema::hasColumn('water_tanker_trips', 'adjustment_note')) {
                    $table->string('adjustment_note')->nullable();
                }
                if (!Schema::hasColumn('water_tanker_trips', 'paid_amount')) {
                    $table->decimal('paid_amount', 12, 2)->default(0);
                }
                if (!Schema::hasColumn('water_tanker_trips', 'payment_mode')) {
                    $table->string('payment_mode', 40)->default('Credit');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'payment_verification_status')) {
                    $table->string('payment_verification_status', 40)->default('confirmed');
                }
                if (!Schema::hasColumn('water_tanker_trips', 'payment_proof_path')) {
                    $table->string('payment_proof_path')->nullable();
                }
                if (!Schema::hasColumn('water_tanker_trips', 'payment_verified_at')) {
                    $table->timestamp('payment_verified_at')->nullable();
                }
                if (!Schema::hasColumn('water_tanker_trips', 'payment_verified_by')) {
                    $table->unsignedBigInteger('payment_verified_by')->nullable();
                }
            });
        }

        if (Schema::hasTable('water_can_deliveries')) {
            Schema::table('water_can_deliveries', function (Blueprint $table) {
                if (!Schema::hasColumn('water_can_deliveries', 'extra_charge')) {
                    $table->decimal('extra_charge', 12, 2)->default(0);
                }
                if (!Schema::hasColumn('water_can_deliveries', 'discount_amount')) {
                    $table->decimal('discount_amount', 12, 2)->default(0);
                }
                if (!Schema::hasColumn('water_can_deliveries', 'adjustment_note')) {
                    $table->string('adjustment_note')->nullable();
                }
                if (!Schema::hasColumn('water_can_deliveries', 'payment_verification_status')) {
                    $table->string('payment_verification_status', 40)->default('confirmed');
                }
                if (!Schema::hasColumn('water_can_deliveries', 'payment_proof_path')) {
                    $table->string('payment_proof_path')->nullable();
                }
                if (!Schema::hasColumn('water_can_deliveries', 'payment_verified_at')) {
                    $table->timestamp('payment_verified_at')->nullable();
                }
                if (!Schema::hasColumn('water_can_deliveries', 'payment_verified_by')) {
                    $table->unsignedBigInteger('payment_verified_by')->nullable();
                }
                if (!Schema::hasColumn('water_can_deliveries', 'item_category')) {
                    $table->string('item_category', 40)->default('water_can');
                }
                if (!Schema::hasColumn('water_can_deliveries', 'bakery_items_json')) {
                    $table->text('bakery_items_json')->nullable();
                }
                if (!Schema::hasColumn('water_can_deliveries', 'bakery_pieces_delivered')) {
                    $table->integer('bakery_pieces_delivered')->default(0);
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('water_can_deliveries')) {
            Schema::table('water_can_deliveries', function (Blueprint $table) {
                $cols = array_values(array_filter([
                    'extra_charge',
                    'discount_amount',
                    'adjustment_note',
                    'payment_verification_status',
                    'payment_proof_path',
                    'payment_verified_at',
                    'payment_verified_by',
                    'item_category',
                    'bakery_items_json',
                    'bakery_pieces_delivered',
                ], fn (string $c) => Schema::hasColumn('water_can_deliveries', $c)));

                if (!empty($cols)) {
                    $table->dropColumn($cols);
                }
            });
        }

        if (Schema::hasTable('water_tanker_trips')) {
            Schema::table('water_tanker_trips', function (Blueprint $table) {
                if (Schema::hasColumn('water_tanker_trips', 'pickup_point_id') && Schema::hasIndex('water_tanker_trips', 'water_tanker_trips_pickup_point_id_index')) {
                    $table->dropIndex('water_tanker_trips_pickup_point_id_index');
                }
                $cols = array_values(array_filter([
                    'pickup_point_id',
                    'pickup_point_name',
                    'is_outsourced_vehicle',
                    'external_vehicle_no',
                    'external_vendor_name',
                    'vendor_payable_amount',
                    'extra_charge',
                    'adjustment_note',
                    'paid_amount',
                    'payment_mode',
                    'payment_verification_status',
                    'payment_proof_path',
                    'payment_verified_at',
                    'payment_verified_by',
                ], fn (string $c) => Schema::hasColumn('water_tanker_trips', $c)));

                if (!empty($cols)) {
                    $table->dropColumn($cols);
                }
            });
        }

        if (Schema::hasTable('water_tankers')) {
            Schema::table('water_tankers', function (Blueprint $table) {
                if (Schema::hasColumn('water_tankers', 'company_id') && Schema::hasIndex('water_tankers', 'water_tankers_company_id_index')) {
                    $table->dropIndex('water_tankers_company_id_index');
                }
                $cols = array_values(array_filter([
                    'company_id',
                    'vehicle_variant',
                    'supported_capacities_json',
                    'has_compartments',
                    'compartment_notes',
                    'is_outsourced',
                    'vendor_name',
                    'vendor_phone',
                ], fn (string $c) => Schema::hasColumn('water_tankers', $c)));

                if (!empty($cols)) {
                    $table->dropColumn($cols);
                }
            });
        }

        Schema::dropIfExists('water_pickup_points');
    }
};
