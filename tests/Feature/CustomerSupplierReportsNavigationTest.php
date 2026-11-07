<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Company;
use App\Models\Customer;
use App\Models\Supplier;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class CustomerSupplierReportsNavigationTest extends TestCase
{
    use DatabaseTransactions;

    protected Company $company;

    protected function setUp(): void
    {
        parent::setUp();

        $admin = User::first() ?? User::factory()->create(['role_id' => 1]);
        $this->actingAs($admin);

        $this->company = Company::first();
    }

    private function sessionData(): array
    {
        $branch = $this->company->branches()->first() ?? $this->company->branches()->create(['name' => 'Main', 'code' => 'MAIN', 'is_active' => true]);
        $year = $this->company->fiscalYears()->first() ?? $this->company->fiscalYears()->create([
            'name' => '2026-2027',
            'start_date' => '2026-04-01',
            'end_date' => '2027-03-31',
            'status' => 'open',
        ]);

        return [
            'company_id' => $this->company->id,
            'branch_id' => $branch->id,
            'financial_year_id' => $year->id,
            'current_company_id' => $this->company->id,
            'warehouse_id' => 1,
        ];
    }

    public function test_sidebar_contains_customer_and_supplier_report_links(): void
    {
        $response = $this->withSession($this->sessionData())->get('/dashboard');
        $response->assertOk();

        $response->assertSee('id="customer-report-menu"', false);
        $response->assertSee(route('report.customer'), false);

        $response->assertSee('id="due-report-menu"', false);
        $response->assertSee(route('report.customerDueByDate'), false);

        $response->assertSee('id="customer-group-report-menu"', false);
        $response->assertSee(route('report.customer_group'), false);

        $response->assertSee('id="supplier-report-menu"', false);
        $response->assertSee(route('report.supplier'), false);

        $response->assertSee('id="supplier-due-report-menu"', false);
        $response->assertSee(route('report.supplierDueByDate'), false);

        $response->assertSee('id="outstanding-due-report-menu"', false);
        $response->assertSee(route('report.outstandingDues'), false);
    }

    public function test_customer_report_page_loads_successfully(): void
    {
        $response = $this->withSession($this->sessionData())->get(route('report.customer'));
        $response->assertOk();
        $response->assertViewIs('backend.report.customer_report');
        $response->assertSee('id="customer-ledger-table"', false);
        $response->assertSee('ledger-opening-row', false);
        $response->assertSee('Running Balance', false);
        $response->assertSee('Print Complete Ledger', false);
        $response->assertDontSee('desk-report-tabs', false);
        $response->assertDontSee('nav-tabs', false);
    }

    public function test_supplier_report_page_loads_successfully(): void
    {
        $response = $this->withSession($this->sessionData())->get(route('report.supplier'));
        $response->assertOk();
        $response->assertViewIs('backend.report.supplier_report');
        $response->assertSee('id="supplier-ledger-table"', false);
        $response->assertSee('ledger-opening-row', false);
        $response->assertSee('Running Balance', false);
        $response->assertSee('Print Complete Ledger', false);
        $response->assertDontSee('desk-report-tabs', false);
        $response->assertDontSee('nav-tabs', false);
    }

    public function test_customer_report_filter_post(): void
    {
        $customer = Customer::where('is_active', true)->where('type', '!=', 'walkin')->first();
        if ($customer) {
            $response = $this->withSession($this->sessionData())->post(route('report.customer'), [
                'customer_id' => $customer->id,
                'start_date' => date('Y-m-d', strtotime('-30 days')),
                'end_date' => date('Y-m-d'),
                'transaction_type' => 'sale',
            ]);
            $response->assertOk();
            $response->assertViewIs('backend.report.customer_report');
            $response->assertSee('id="customer-ledger-table"', false);
            $response->assertDontSee('desk-report-tabs', false);
        } else {
            $this->assertTrue(true);
        }
    }

    public function test_supplier_report_filter_post(): void
    {
        $supplier = Supplier::where('is_active', true)->first();
        if ($supplier) {
            $response = $this->withSession($this->sessionData())->post(route('report.supplier'), [
                'supplier_id' => $supplier->id,
                'start_date' => date('Y-m-d', strtotime('-30 days')),
                'end_date' => date('Y-m-d'),
                'transaction_type' => 'purchase',
            ]);
            $response->assertOk();
            $response->assertViewIs('backend.report.supplier_report');
            $response->assertSee('id="supplier-ledger-table"', false);
            $response->assertDontSee('desk-report-tabs', false);
        } else {
            $this->assertTrue(true);
        }
    }

    public function test_customer_group_report_page_loads_successfully(): void
    {
        $response = $this->withSession($this->sessionData())->get(route('report.customer_group'));
        $response->assertOk();
        $response->assertViewIs('backend.report.customer_group_report');
    }
}

