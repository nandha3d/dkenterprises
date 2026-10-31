@php
    $message = $exception ? $exception->getMessage() : 'Forbidden';
    $isCapabilityError = str_contains($message, 'Capability is disabled');
    $capabilityKey = null;
    
    if ($isCapabilityError) {
        $parts = explode(':', $message);
        $capabilityKey = trim(end($parts));
    }
    
    $activeCompanyId = session('company_id');
    $activeCompany = $activeCompanyId ? \App\Models\Company::find($activeCompanyId) : null;
    $user = auth()->user();
    
    // Capability Catalog Mapping
    $capabilityCatalog = [
        'operations.water_logistics' => [
            'title' => 'Water Logistics, Tanker Fleet & Can Distribution',
            'icon' => '💧',
            'badge' => 'Water Logistics Engine',
            'description' => 'Bulk water tanker logistics (trip logging, multi-chamber split deliveries, decanting audit), 20L water can distribution routes (Tata Ace beats, customer ledger), and container security deposits.',
            'industry_target' => 'Commercial Bulk Water Supply & Packaged Drinking Water',
        ],
        'operations.cafe_bakery' => [
            'title' => 'Bakery & Cafe Operations',
            'icon' => '☕',
            'badge' => 'Cafe & Bakery Engine',
            'description' => 'Fast touch POS counter ordering, kitchen raw material consumption tracking, recipe yield calculations, and evening 3-minute cash drawer reconciliation with shortage auditing.',
            'industry_target' => 'Bakery Production & Quick Service Cafe Counters',
        ],
        'sales.route_distribution' => [
            'title' => 'Route Distribution & Van Sales',
            'icon' => '🚚',
            'badge' => 'Route Logistics',
            'description' => 'Customer delivery beats, driver vehicle dispatch sheets, route inventory reconciliation, and collection receipts.',
            'industry_target' => 'Distribution & FMCG Wholesale',
        ],
        'inventory.batch_expiry' => [
            'title' => 'Batch, Lot & Expiry Tracking',
            'icon' => '📦',
            'badge' => 'Batch Management',
            'description' => 'FIFO/FEFO inventory movement, perishable product batching, expiry alerts, and lot number traceability.',
            'industry_target' => 'FMCG, Food & Pharma',
        ],
        'manufacturing.bom' => [
            'title' => 'Bills of Material (BOM)',
            'icon' => '⚙️',
            'badge' => 'Manufacturing',
            'description' => 'Multi-level ingredient formulas, component specifications, and production recipe definitions.',
            'industry_target' => 'Production & Assembly',
        ],
        'manufacturing.production' => [
            'title' => 'Production Orders & Finished Goods Assembly',
            'icon' => '🏭',
            'badge' => 'Production Entry',
            'description' => 'Raw material conversion, WIP tracking, overhead cost allocation, and finished goods stock receipts.',
            'industry_target' => 'Manufacturing & Processing',
        ],
        'sales.pos' => [
            'title' => 'Point of Sale (POS)',
            'icon' => '🛒',
            'badge' => 'POS Terminal',
            'description' => 'High-speed retail barcode scanning, thermal receipt printing, cash drawers, and customer loyalty integration.',
            'industry_target' => 'Retail Stores & Quick Counters',
        ],
        'communications.whatsapp' => [
            'title' => 'WhatsApp Enterprise Communications',
            'icon' => '💬',
            'badge' => 'Instant Messaging',
            'description' => 'Automated PDF bill dispatch, payment reminders, delivery notifications, and order confirmations via WhatsApp.',
            'industry_target' => 'All Enterprises',
        ],
        'hrm.enabled' => [
            'title' => 'Human Resources & Payroll',
            'icon' => '👥',
            'badge' => 'HRM System',
            'description' => 'Employee records, attendance tracking, shift scheduling, and salary payroll processing.',
            'industry_target' => 'Corporate Operations',
        ],
    ];
    
    $capInfo = $capabilityKey && isset($capabilityCatalog[$capabilityKey]) 
        ? $capabilityCatalog[$capabilityKey] 
        : [
            'title' => ucwords(str_replace(['.', '_'], ' ', $capabilityKey ?? 'Requested Feature')),
            'icon' => '🔒',
            'badge' => 'Module Capability',
            'description' => 'This functional capability is disabled in the active company context to maintain a focused workspace.',
            'industry_target' => 'Specialized Enterprise Profile',
        ];
        
    // Find other accessible companies where this capability IS enabled
    $matchingCompanies = collect();
    if ($user && $capabilityKey) {
        $userCompanyIds = \DB::table('company_user')->where('user_id', $user->id)->pluck('company_id');
        $capService = app(\App\Services\Platform\CapabilityService::class);
        foreach ($userCompanyIds as $cId) {
            if ($cId != $activeCompanyId && $capService->enabled($capabilityKey, $cId)) {
                $comp = \App\Models\Company::find($cId);
                if ($comp && $comp->status === 'active') {
                    $matchingCompanies->push($comp);
                }
            }
        }
    }
@endphp
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>403 — {{ $isCapabilityError ? $capInfo['title'] . ' (Feature Notice)' : 'Access Restricted' }} | zoloERP Pro</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
    <style>
        :root {
            --bg-canvas: #f8fafc;
            --card-bg: #ffffff;
            --border-color: #e2e8f0;
            --text-main: #0f172a;
            --text-muted: #64748b;
            --primary: #4338ca;
            --primary-hover: #3730a3;
            --primary-light: #e0e7ff;
            --amber-bg: #fffbeb;
            --amber-border: #fef3c7;
            --amber-text: #b45309;
            --emerald-bg: #ecfdf5;
            --emerald-border: #a7f3d0;
            --emerald-text: #047857;
            --emerald-btn: #059669;
            --emerald-btn-hover: #047857;
            --shadow: 0 10px 25px -5px rgba(15, 23, 42, 0.08), 0 8px 10px -6px rgba(15, 23, 42, 0.04);
        }

        @media (prefers-color-scheme: dark) {
            :root {
                --bg-canvas: #090d16;
                --card-bg: #141c2e;
                --border-color: #1e293b;
                --text-main: #f8fafc;
                --text-muted: #94a3b8;
                --primary: #6366f1;
                --primary-hover: #4f46e5;
                --primary-light: #1e1b4b;
                --amber-bg: #1e1b13;
                --amber-border: #451a03;
                --amber-text: #f59e0b;
                --emerald-bg: #062b1e;
                --emerald-border: #064e3b;
                --emerald-text: #34d399;
                --emerald-btn: #10b981;
                --emerald-btn-hover: #059669;
                --shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.5);
            }
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: var(--bg-canvas);
            color: var(--text-main);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 24px;
        }

        .notice-container {
            width: 100%;
            max-width: 740px;
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 16px;
            box-shadow: var(--shadow);
            overflow: hidden;
            animation: fadeIn 0.3s cubic-bezier(0.16, 1, 0.3, 1);
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(8px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .notice-header {
            padding: 20px 28px;
            background: linear-gradient(135deg, rgba(67, 56, 202, 0.04) 0%, rgba(99, 102, 241, 0.02) 100%);
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 12px;
        }

        .brand-badge {
            display: flex;
            align-items: center;
            gap: 10px;
            font-weight: 700;
            font-size: 14px;
            letter-spacing: -0.01em;
        }

        .brand-pill {
            background: var(--primary);
            color: #ffffff;
            font-size: 11px;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 6px;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .context-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: var(--primary-light);
            color: var(--primary);
            font-size: 12px;
            font-weight: 600;
            padding: 5px 12px;
            border-radius: 20px;
        }

        .context-dot {
            width: 7px;
            height: 7px;
            border-radius: 50%;
            background: currentColor;
            display: inline-block;
        }

        .notice-body {
            padding: 32px 28px;
        }

        .hero-banner {
            display: flex;
            gap: 18px;
            align-items: flex-start;
            margin-bottom: 24px;
        }

        .hero-icon-box {
            width: 56px;
            height: 56px;
            min-width: 56px;
            border-radius: 14px;
            background: var(--amber-bg);
            border: 1px solid var(--amber-border);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 28px;
        }

        .hero-text h1 {
            font-size: 20px;
            font-weight: 700;
            letter-spacing: -0.02em;
            margin-bottom: 6px;
            color: var(--text-main);
        }

        .hero-text p {
            font-size: 14px;
            color: var(--text-muted);
            line-height: 1.5;
        }

        .explanation-card {
            background: var(--bg-canvas);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 16px 20px;
            margin-bottom: 28px;
            font-size: 13.5px;
            line-height: 1.6;
        }

        .explanation-card strong {
            color: var(--text-main);
        }

        .capability-code {
            display: inline-block;
            font-family: 'JetBrains Mono', monospace;
            font-size: 11.5px;
            background: rgba(100, 116, 139, 0.12);
            padding: 2px 7px;
            border-radius: 4px;
            color: var(--text-main);
        }

        .action-section-title {
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--text-muted);
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .action-section-title i {
            color: var(--primary);
        }

        .company-switch-deck {
            display: flex;
            flex-direction: column;
            gap: 10px;
            margin-bottom: 24px;
        }

        .company-switch-card {
            border: 1px solid var(--emerald-border);
            background: var(--emerald-bg);
            border-radius: 12px;
            padding: 14px 18px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            transition: all 0.2s ease;
        }

        .company-switch-card:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(5, 150, 105, 0.12);
        }

        .company-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .company-avatar {
            width: 38px;
            height: 38px;
            border-radius: 8px;
            background: #ffffff;
            border: 1px solid var(--emerald-border);
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 800;
            font-size: 13px;
            color: var(--emerald-text);
        }

        .company-details h3 {
            font-size: 14px;
            font-weight: 700;
            color: var(--text-main);
            margin-bottom: 2px;
        }

        .company-details span {
            font-size: 12px;
            color: var(--emerald-text);
            font-weight: 500;
        }

        .btn-switch {
            background: var(--emerald-btn);
            color: #ffffff;
            border: none;
            padding: 8px 18px;
            border-radius: 8px;
            font-size: 12.5px;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            white-space: nowrap;
            text-decoration: none;
            transition: background 0.15s ease;
        }

        .btn-switch:hover {
            background: var(--emerald-btn-hover);
        }

        .notice-footer-buttons {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 10px;
            padding-top: 18px;
            border-top: 1px solid var(--border-color);
            flex-wrap: wrap;
        }

        .btn-action {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 13px;
            font-weight: 600;
            padding: 9px 18px;
            border-radius: 8px;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.15s ease;
        }

        .btn-secondary {
            background: transparent;
            color: var(--text-main);
            border: 1px solid var(--border-color);
        }

        .btn-secondary:hover {
            background: rgba(100, 116, 139, 0.08);
            border-color: var(--text-muted);
        }

        .btn-primary {
            background: var(--primary);
            color: #ffffff;
            border: 1px solid var(--primary);
        }

        .btn-primary:hover {
            background: var(--primary-hover);
            border-color: var(--primary-hover);
        }
    </style>
</head>
<body>

    <div class="notice-container">
        <!-- Header -->
        <div class="notice-header">
            <div class="brand-badge">
                <span class="brand-pill">zoloERP Pro</span>
                <span>Operational Capability Bridge</span>
            </div>
            @if($activeCompany)
                <div class="context-pill" title="Currently active workspace context">
                    <span class="context-dot"></span>
                    <span>{{ $activeCompany->trade_name ?: $activeCompany->legal_name }}</span>
                    <span style="opacity: 0.6;">({{ $activeCompany->code }})</span>
                </div>
            @endif
        </div>

        <!-- Body -->
        <div class="notice-body">
            @if($isCapabilityError)
                <!-- Capability Disabled Notice -->
                <div class="hero-banner">
                    <div class="hero-icon-box" title="{{ $capInfo['title'] }}">
                        {{ $capInfo['icon'] }}
                    </div>
                    <div class="hero-text">
                        <h1>{{ $capInfo['title'] }}</h1>
                        <p>{{ $capInfo['description'] }}</p>
                    </div>
                </div>

                <div class="explanation-card">
                    <p style="margin-bottom: 6px;">
                        <strong>Why is this screen restricted?</strong>
                    </p>
                    <p>
                        Your current active workspace is <strong>{{ $activeCompany ? ($activeCompany->trade_name ?: $activeCompany->legal_name) : 'an unconfigured entity' }}</strong>. 
                        In this multi-enterprise system, businesses operate under distinct operational profiles to prevent workflow clutter.
                        The capability <span class="capability-code">{{ $capabilityKey }}</span> is not enabled for this workspace profile.
                    </p>
                </div>

                @if($matchingCompanies->isNotEmpty())
                    <div class="action-section-title">
                        <i class="fa fa-arrow-circle-right"></i> Available In Your Dedicated Enterprises
                    </div>
                    
                    <div class="company-switch-deck">
                        @foreach($matchingCompanies as $mc)
                            <div class="company-switch-card">
                                <div class="company-info">
                                    <div class="company-avatar">
                                        {{ strtoupper(substr($mc->code, 0, 2)) }}
                                    </div>
                                    <div class="company-details">
                                        <h3>{{ $mc->trade_name ?: $mc->legal_name }}</h3>
                                        <span>
                                            <i class="fa fa-check-circle"></i> Enabled for {{ $capInfo['title'] }}
                                        </span>
                                    </div>
                                </div>
                                <form method="POST" action="{{ route('company.choose') }}" style="margin: 0;">
                                    @csrf
                                    <input type="hidden" name="company_id" value="{{ $mc->id }}">
                                    <input type="hidden" name="return_to" value="{{ request()->fullUrl() }}">
                                    <button type="submit" class="btn-switch">
                                        <i class="fa fa-exchange"></i> Switch to {{ $mc->code }} &amp; Proceed
                                    </button>
                                </form>
                            </div>
                        @endforeach
                    </div>
                @endif

            @else
                <!-- Generic Forbidden Notice -->
                <div class="hero-banner">
                    <div class="hero-icon-box" style="background: rgba(239, 68, 68, 0.1); border-color: rgba(239, 68, 68, 0.2); color: #dc2626;">
                        🛡️
                    </div>
                    <div class="hero-text">
                        <h1>Access Restricted</h1>
                        <p>{{ $message ?: 'You do not have administrative clearance to access this resource.' }}</p>
                    </div>
                </div>

                <div class="explanation-card">
                    <p>
                        This resource requires elevated credentials or an authorized company branch session. 
                        Please return to your executive dashboard or switch to an authorized company context.
                    </p>
                </div>
            @endif

            <!-- Navigation Buttons -->
            <div class="notice-footer-buttons">
                @if($user && ($user->role_id == 1 || $user->id == 1))
                    <a href="{{ url('/operations/profiles') }}" class="btn-action btn-secondary" title="View or toggle module capabilities">
                        <i class="fa fa-sliders"></i> Business Profiles
                    </a>
                @endif
                <a href="{{ url('/select-company?manage=1') }}" class="btn-action btn-secondary" title="Open multi-company directory">
                    <i class="fa fa-building-o"></i> All Companies
                </a>
                <a href="{{ url('/dashboard') }}" class="btn-action btn-primary" title="Return to executive dashboard">
                    <i class="fa fa-home"></i> Back to Dashboard
                </a>
            </div>
        </div>
    </div>

</body>
</html>
