<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('expenses')) {
            Schema::table('expenses', function (Blueprint $table) {
                if (!Schema::hasColumn('expenses', 'entry_type')) {
                    $table->string('entry_type', 16)->default('OUT');
                }
                if (!Schema::hasColumn('expenses', 'company_tag')) {
                    $table->string('company_tag', 60)->nullable();
                }
                if (!Schema::hasColumn('expenses', 'payment_account')) {
                    $table->string('payment_account', 80)->default('CASH');
                }
                if (!Schema::hasColumn('expenses', 'vehicle_or_staff_tag')) {
                    $table->string('vehicle_or_staff_tag', 80)->nullable();
                }
                if (!Schema::hasColumn('expenses', 'bill_no')) {
                    $table->string('bill_no', 80)->nullable();
                }
                if (!Schema::hasColumn('expenses', 'entry_date')) {
                    $table->date('entry_date')->nullable();
                }
            });
        }

        if (Schema::hasTable('suppliers')) {
            Schema::table('suppliers', function (Blueprint $table) {
                if (!Schema::hasColumn('suppliers', 'company_id')) {
                    $table->unsignedBigInteger('company_id')->nullable()->index();
                }
                if (!Schema::hasColumn('suppliers', 'default_category')) {
                    $table->string('default_category', 80)->nullable();
                }
                if (!Schema::hasColumn('suppliers', 'is_regular_vendor')) {
                    $table->boolean('is_regular_vendor')->default(false);
                }
                if (!Schema::hasColumn('suppliers', 'preferred_payment_mode')) {
                    $table->string('preferred_payment_mode', 40)->default('Cash');
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('suppliers')) {
            Schema::table('suppliers', function (Blueprint $table) {
                $cols = array_values(array_filter([
                    'default_category',
                    'is_regular_vendor',
                    'preferred_payment_mode',
                ], fn (string $c) => Schema::hasColumn('suppliers', $c)));

                if (!empty($cols)) {
                    $table->dropColumn($cols);
                }
            });
        }

        if (Schema::hasTable('expenses')) {
            Schema::table('expenses', function (Blueprint $table) {
                $cols = array_values(array_filter([
                    'entry_type',
                    'company_tag',
                    'payment_account',
                    'vehicle_or_staff_tag',
                    'bill_no',
                    'entry_date',
                ], fn (string $c) => Schema::hasColumn('expenses', $c)));

                if (!empty($cols)) {
                    $table->dropColumn($cols);
                }
            });
        }
    }
};
