<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\WaterCanDriverSurrender;
use App\Models\WaterCanSpotAudit;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class MobileApiSecurityAndMeTest extends TestCase
{
    /**
     * 1. Mobile login rejects invalid credentials with HTTP 401
     */
    public function test_mobile_login_rejects_wrong_credentials(): void
    {
        $response = $this->postJson('/api/v1/mobile/login', [
            'username' => 'admin',
            'password' => 'wrong_password_123',
        ]);

        $response->assertStatus(401);
        $response->assertJsonPath('success', false);
        $response->assertJsonPath('message', 'Unauthorized');
    }

    /**
     * 2. Mobile login authenticates against real users table and issues a valid Sanctum token
     */
    public function test_mobile_login_authenticates_with_real_user_and_issues_sanctum_token(): void
    {
        $response = $this->postJson('/api/v1/mobile/login', [
            'username' => 'admin',
            'password' => 'admin',
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('success', true);
        $this->assertNotEmpty($response->json('data.token'));
        $this->assertEquals('Bearer', $response->json('data.token_type'));
        $this->assertNotNull($response->json('data.user.id'));
        $this->assertIsArray($response->json('data.permissions'));
        $this->assertIsArray($response->json('data.companies'));
    }

    /**
     * 3. Mobile login authenticates field driver account
     */
    public function test_mobile_login_authenticates_field_driver(): void
    {
        $response = $this->postJson('/api/v1/mobile/login', [
            'username' => 'driver',
            'password' => 'driver123',
            'role' => 'deliveryDriver',
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('success', true);
        $this->assertEquals('deliveryDriver', $response->json('data.role'));
        $this->assertEquals(3, $response->json('data.user.company_id'));
    }

    /**
     * 4. Unauthenticated access to protected mobile endpoints is blocked with HTTP 401
     */
    public function test_unauthenticated_request_to_mobile_endpoints_is_blocked(): void
    {
        $this->getJson('/api/v1/mobile/customers')->assertStatus(401);
        $this->getJson('/api/v1/mobile/products')->assertStatus(401);
        $this->getJson('/api/v1/mobile/invoices')->assertStatus(401);
        $this->getJson('/api/v1/mobile/financials')->assertStatus(401);
        $this->postJson('/api/v1/mobile/spot-audit', [])->assertStatus(401);
        $this->postJson('/api/v1/mobile/driver-surrender', [])->assertStatus(401);
    }

    /**
     * 5. GET /api/v1/me returns comprehensive user identity, permissions, and company context
     */
    public function test_get_me_returns_identity_permissions_and_companies(): void
    {
        $user = User::where('name', 'admin')->first();
        $token = $user->createToken('test-mobile-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/v1/me');

        $response->assertStatus(200);
        $response->assertJsonPath('success', true);
        $response->assertJsonStructure([
            'data' => [
                'user' => [
                    'id', 'name', 'email', 'phone', 'role', 'role_id'
                ],
                'roles',
                'permissions',
                'companies' => [
                    '*' => [
                        'id', 'code', 'legal_name', 'trade_name', 'industry',
                        'branches', 'fiscal_years', 'active_modules', 'capabilities'
                    ]
                ],
                'active_context' => [
                    'company_id', 'branch_id', 'financial_year_id'
                ]
            ]
        ]);

        $this->assertContains('products-index', $response->json('data.permissions'));
        $this->assertNotEmpty($response->json('data.companies'));
    }

    /**
     * 6. Spot audit persists into water_can_spot_audits table
     */
    public function test_spot_audit_persists_record_in_database(): void
    {
        $user = User::where('name', 'admin')->first();
        $token = $user->createToken('test-spot-audit-token')->plainTextToken;

        $payload = [
            'vehicle_number' => 'TN-59-WA-2026',
            'driver_name' => 'Kannan',
            'physical_units' => 75,
            'expected_units' => 80,
            'physical_cash' => 2600.0,
            'expected_cash' => 2800.0,
            'notes' => 'Route van spot inspection at bypass checkpoint',
        ];

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/v1/mobile/spot-audit', $payload);

        $response->assertStatus(201);
        $response->assertJsonPath('success', true);
        $response->assertJsonPath('data.unit_difference', -5);
        $this->assertTrue($response->json('data.is_fraud_suspected'));

        $this->assertDatabaseHas('water_can_spot_audits', [
            'vehicle_number' => 'TN-59-WA-2026',
            'driver_name' => 'Kannan',
            'physical_units' => 75,
            'expected_units' => 80,
            'unit_difference' => -5,
        ]);
    }

    /**
     * 7. Driver cash surrender persists into water_can_driver_surrenders table
     */
    public function test_driver_cash_surrender_persists_record_in_database(): void
    {
        $user = User::where('name', 'driver')->first();
        $token = $user->createToken('test-surrender-token')->plainTextToken;

        $payload = [
            'route_id' => 1,
            'surrender_date' => date('Y-m-d'),
            'cash_surrendered' => 3200.0,
            'empty_cans_returned' => 85,
            'filled_cans_returned' => 5,
            'damaged_cans_reported' => 0,
            'notes' => 'Route A Tata Ace end-of-shift cash surrender',
        ];

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/v1/mobile/driver-surrender', $payload);

        $response->assertStatus(200);
        $response->assertJsonPath('success', true);
        $response->assertJsonPath('data.cash_surrendered', 3200);
        $response->assertJsonPath('data.empty_cans_returned', 85);
        $this->assertNotEmpty($response->json('data.surrender_receipt'));

        $this->assertDatabaseHas('water_can_driver_surrenders', [
            'route_id' => 1,
            'cash_surrendered' => 3200.0,
            'empty_cans_returned' => 85,
        ]);
    }

    /**
     * 8. Financials returns real-time ledger structure
     */
    public function test_financials_returns_live_ledger_structure(): void
    {
        $user = User::where('name', 'admin')->first();
        $token = $user->createToken('test-fin-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '3')
            ->getJson('/api/v1/mobile/financials');

        $response->assertStatus(200);
        $response->assertJsonPath('success', true);
        $response->assertJsonStructure([
            'data' => [
                'company_id',
                'cash_in_hand_1010',
                'bank_account_1020',
                'accounts_receivable_1030',
                'total_container_deposits',
                'cash_in_transit_drivers',
                'today_collections',
            ]
        ]);
    }

    /**
     * 9. Workspace insights returns multi-company directory and group totals
     */
    public function test_workspace_insights_returns_multi_company_directory(): void
    {
        $user = User::where('name', 'admin')->first();
        $token = $user->createToken('test-ws-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/v1/mobile/workspace');

        $response->assertStatus(200);
        $response->assertJsonPath('success', true);
        $response->assertJsonStructure([
            'data' => [
                'summary' => [
                    'total_turnover',
                    'total_cash_and_bank',
                    'total_receivables',
                    'total_companies_count',
                    'currency',
                    'symbol',
                ],
                'companies' => [
                    '*' => [
                        'id',
                        'code',
                        'name',
                        'legal_name',
                        'industry',
                        'vertical' => [
                            'label',
                            'tagline',
                            'icon',
                            'primary_color',
                            'badge',
                        ],
                        'metrics' => [
                            'sales_turnover',
                            'cash_in_hand',
                            'bank_balance',
                            'cash_and_bank',
                            'receivables',
                        ],
                        'branches_count',
                        'active_fiscal_year',
                    ]
                ]
            ]
        ]);
    }
}

