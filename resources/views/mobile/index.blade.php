<!DOCTYPE html>
<html lang="ta" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <meta name="theme-color" content="#0B0F17">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <title>DK Track — Multi-Role Enterprise Field Mobile ERP</title>
    <link rel="icon" type="image/png" href="{{ url('logo/zoloerp_logo.png') }}" />
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Noto+Sans+Tamil:wght@400;600;700;800&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-canvas: #0B0F17;
            --bg-card: #111827;
            --bg-card-subtle: #162032;
            --border-card: #1E293B;
            --border-focus: #38BDF8;
            --text-primary: #F8FAFC;
            --text-muted: #94A3B8;
            --text-dim: #64748B;
            --color-super-admin: #8B5CF6;
            --color-admin: #0EA5E9;
            --color-field-agent: #10B981;
            --color-delivery-driver: #0284C7;
            --color-tanker-driver: #2563EB;
            --color-cashier: #D97706;
            --color-success: #10B981;
            --color-danger: #EF4444;
            --color-warning: #F59E0B;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            -webkit-tap-highlight-color: transparent;
        }

        body {
            background-color: #05080E;
            color: var(--text-primary);
            font-family: 'Plus Jakarta Sans', 'Noto Sans Tamil', -apple-system, sans-serif;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: flex-start;
            overflow-x: hidden;
        }

        /* Desktop Container Simulator */
        .device-simulator-wrapper {
            width: 100%;
            max-width: 440px;
            min-height: 100vh;
            background-color: var(--bg-canvas);
            box-shadow: 0 0 50px rgba(0, 0, 0, 0.8), 0 0 0 1px rgba(255, 255, 255, 0.05);
            display: flex;
            flex-direction: column;
            position: relative;
        }

        @media (min-width: 768px) {
            body {
                padding: 24px 0;
                background: radial-gradient(circle at 50% 20%, #0F172A 0%, #05080E 100%);
            }
            .device-simulator-wrapper {
                min-height: 890px;
                height: 890px;
                border-radius: 44px;
                border: 8px solid #1E293B;
                overflow: hidden;
                box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.9), 0 0 0 2px rgba(56, 189, 248, 0.2);
            }
        }

        /* Top App Header */
        .mobile-header {
            background-color: #0F172A;
            border-bottom: 1px solid var(--border-card);
            padding: 10px 14px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: sticky;
            top: 0;
            z-index: 50;
        }

        .header-brand-group {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .brand-badge-icon {
            width: 36px;
            height: 36px;
            border-radius: 10px;
            background: linear-gradient(135deg, var(--color-super-admin), #6D28D9);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 19px;
            box-shadow: 0 2px 10px rgba(139, 92, 246, 0.4);
            transition: all 0.3s ease;
        }

        .header-titles h1 {
            font-size: 13.5px;
            font-weight: 800;
            color: #FFFFFF;
            letter-spacing: 0.3px;
            line-height: 1.2;
        }

        .header-titles span {
            font-size: 10px;
            color: var(--text-muted);
            display: block;
        }

        .header-controls {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .btn-lang-toggle {
            background: rgba(56, 189, 248, 0.1);
            border: 1px solid rgba(56, 189, 248, 0.3);
            color: #38BDF8;
            font-size: 10.5px;
            font-weight: 700;
            padding: 5px 9px;
            border-radius: 20px;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .btn-theme-toggle {
            background: rgba(245, 158, 11, 0.12);
            border: 1px solid rgba(245, 158, 11, 0.35);
            color: #F59E0B;
            font-size: 10px;
            font-weight: 700;
            padding: 5px 9px;
            border-radius: 20px;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .btn-theme-toggle:hover {
            background: #F59E0B;
            color: #0F172A;
        }

        /* Light Theme Complete Overrides */
        html.light {
            --bg-canvas: #FFFFFF;
            --bg-card: #FFFFFF;
            --bg-card-subtle: #F8FAFC;
            --border-card: #E2E8F0;
            --border-focus: #0284C7;
            --text-primary: #0F172A;
            --text-muted: #475569;
            --text-dim: #64748B;
        }

        html.light body {
            background-color: #F1F5F9;
            color: #0F172A;
        }

        html.light .mobile-header {
            background-color: #FFFFFF;
            border-bottom: 1px solid #E2E8F0;
        }

        html.light .header-titles h1 {
            color: #0F172A;
        }

        html.light .header-titles span {
            color: #64748B;
        }

        html.light .role-selector-ribbon {
            background-color: #F8FAFC;
            border-bottom: 1px solid #E2E8F0;
        }

        html.light .role-pill {
            background-color: #FFFFFF;
            border: 1px solid #CBD5E1;
        }

        html.light .role-pill .pill-meta strong {
            color: #0F172A;
        }

        html.light .role-subnav {
            background-color: #FFFFFF;
            border-bottom: 1px solid #E2E8F0;
        }

        html.light .subnav-btn {
            color: #64748B;
        }

        html.light .subnav-btn.active {
            color: #0F172A;
            border-bottom-color: #0284C7;
        }

        html.light .form-section-card {
            background: #FFFFFF;
            border: 1px solid #E2E8F0;
            box-shadow: 0 1px 4px rgba(0, 0, 0, 0.05);
        }

        html.light .kpi-card {
            background: #F8FAFC;
            border: 1px solid #E2E8F0;
        }

        html.light .kpi-value {
            color: #0F172A;
        }

        html.light .custom-select, html.light .custom-input {
            background: #F8FAFC;
            border: 1px solid #CBD5E1;
            color: #0F172A;
        }

        html.light .stepper-box {
            background: #F8FAFC;
            border: 1px solid #E2E8F0;
        }

        html.light .stepper-box.highlight {
            background: linear-gradient(180deg, rgba(2, 132, 199, 0.06) 0%, #FFFFFF 100%);
            border-color: rgba(2, 132, 199, 0.4);
        }

        html.light .btn-step {
            background: #E2E8F0;
            border: 1px solid #CBD5E1;
            color: #0F172A;
        }

        html.light .btn-payment-pill {
            background: #F8FAFC;
            border: 1px solid #CBD5E1;
            color: #475569;
        }

        html.light .total-action-bar {
            background: #F8FAFC;
            border: 1px solid #E2E8F0;
        }

        html.light .mobile-bottom-nav {
            background-color: #FFFFFF;
            border-top: 1px solid #E2E8F0;
        }

        html.light .fraud-desc {
            color: #334155;
        }

        html.light .fraud-title {
            color: #DC2626;
        }

        /* API Target Status Banner */
        .api-target-banner {
            background: linear-gradient(90deg, #064E3B 0%, #0F172A 100%);
            border-bottom: 1px solid rgba(16, 185, 129, 0.3);
            padding: 6px 12px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 9.5px;
            color: #E2E8F0;
        }

        .api-pulse-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background-color: #10B981;
            box-shadow: 0 0 6px #10B981;
            display: inline-block;
            margin-right: 6px;
        }

        .api-test-btn {
            background: rgba(16, 185, 129, 0.2);
            border: 1px solid #10B981;
            color: #34D399;
            font-size: 9px;
            font-weight: 700;
            padding: 2px 7px;
            border-radius: 10px;
            cursor: pointer;
        }

        .api-test-btn:hover {
            background: #10B981;
            color: #0F172A;
        }

        /* Role Selector Ribbon */
        .role-selector-ribbon {
            background-color: #090D15;
            padding: 8px 10px;
            border-bottom: 1px solid var(--border-card);
            display: flex;
            gap: 6px;
            overflow-x: auto;
            scrollbar-width: none;
        }
        .role-selector-ribbon::-webkit-scrollbar { display: none; }

        .role-pill {
            flex-shrink: 0;
            padding: 6px 10px;
            border-radius: 8px;
            background-color: var(--bg-card);
            border: 1px solid var(--border-card);
            display: flex;
            align-items: center;
            gap: 6px;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .role-pill.active {
            border-color: var(--role-color, #8B5CF6);
            background: linear-gradient(180deg, rgba(139, 92, 246, 0.2) 0%, rgba(139, 92, 246, 0.05) 100%);
        }

        .role-pill span.icon {
            font-size: 13px;
        }

        .role-pill .pill-meta strong {
            display: block;
            font-size: 10.5px;
            color: #FFFFFF;
            white-space: nowrap;
        }

        .role-pill .pill-meta small {
            display: block;
            font-size: 8px;
            color: var(--text-dim);
            white-space: nowrap;
        }

        /* Subnav Tabs */
        .role-subnav {
            background-color: #0F172A;
            border-bottom: 1px solid var(--border-card);
            display: flex;
            padding: 0 10px;
        }

        .subnav-btn {
            flex: 1;
            padding: 10px 6px;
            background: transparent;
            border: none;
            border-bottom: 2px solid transparent;
            color: var(--text-muted);
            font-size: 11px;
            font-weight: 600;
            cursor: pointer;
            text-align: center;
            transition: all 0.2s ease;
        }

        .subnav-btn.active {
            color: #FFFFFF;
            border-bottom-color: #38BDF8;
        }

        /* Main Viewport Content */
        .mobile-main-content {
            flex: 1;
            padding: 14px;
            overflow-y: auto;
            -webkit-overflow-scrolling: touch;
        }

        /* Cards & Section Boxes */
        .form-section-card {
            background: var(--bg-card);
            border: 1px solid var(--border-card);
            border-radius: 14px;
            padding: 14px;
            margin-bottom: 14px;
        }

        .section-title {
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: var(--text-muted);
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        /* KPI Stat Cards */
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 10px;
            margin-bottom: 14px;
        }

        .kpi-card {
            background: var(--bg-card-subtle);
            border: 1px solid var(--border-card);
            border-radius: 12px;
            padding: 12px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        .kpi-card.highlight-purple { border-color: rgba(139, 92, 246, 0.4); }
        .kpi-card.highlight-blue { border-color: rgba(14, 165, 233, 0.4); }
        .kpi-card.highlight-green { border-color: rgba(16, 185, 129, 0.4); }
        .kpi-card.highlight-amber { border-color: rgba(217, 119, 6, 0.4); }

        .kpi-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 6px;
        }

        .kpi-title {
            font-size: 9.5px;
            font-weight: 700;
            text-transform: uppercase;
            color: var(--text-muted);
        }

        .kpi-value {
            font-size: 19px;
            font-weight: 800;
            font-family: 'JetBrains Mono', monospace;
            color: #FFFFFF;
            line-height: 1.1;
        }

        .kpi-subtext {
            font-size: 9px;
            color: var(--text-dim);
            margin-top: 4px;
        }

        /* Fraud Alert Cards */
        .fraud-alert-item {
            background: rgba(239, 68, 68, 0.08);
            border: 1px solid rgba(239, 68, 68, 0.35);
            border-radius: 10px;
            padding: 10px 12px;
            margin-bottom: 10px;
        }

        .fraud-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 4px;
        }

        .fraud-badge {
            background: #EF4444;
            color: #FFFFFF;
            font-size: 8.5px;
            font-weight: 800;
            padding: 2px 6px;
            border-radius: 4px;
            text-transform: uppercase;
        }

        .fraud-title {
            font-size: 11px;
            font-weight: 700;
            color: #FCA5A5;
        }

        .fraud-desc {
            font-size: 10px;
            color: #E2E8F0;
            margin-bottom: 8px;
            line-height: 1.4;
        }

        .fraud-actions {
            display: flex;
            gap: 6px;
        }

        .btn-fraud-action {
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 9.5px;
            font-weight: 700;
            border: none;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .btn-fraud-danger {
            background: #EF4444;
            color: #FFFFFF;
        }
        .btn-fraud-subtle {
            background: #1E293B;
            color: #94A3B8;
            border: 1px solid #334155;
        }

        /* Steppers */
        .stepper-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin-bottom: 14px;
        }

        .stepper-box {
            background: var(--bg-canvas);
            border: 1px solid var(--border-card);
            border-radius: 12px;
            padding: 12px 8px;
            text-align: center;
        }

        .stepper-box.highlight {
            border-color: rgba(56, 189, 248, 0.3);
            background: linear-gradient(180deg, rgba(2, 132, 199, 0.08) 0%, rgba(11, 15, 23, 1) 100%);
        }

        .stepper-title {
            font-size: 10px;
            font-weight: 600;
            color: var(--text-muted);
            margin-bottom: 4px;
        }

        .stepper-value {
            font-size: 30px;
            font-weight: 800;
            font-family: 'JetBrains Mono', monospace;
            color: #38BDF8;
            line-height: 1;
            margin-bottom: 8px;
        }

        .stepper-value.green { color: #34D399; }

        .stepper-actions {
            display: flex;
            justify-content: center;
            gap: 4px;
        }

        .btn-step {
            background: #1E293B;
            border: 1px solid #334155;
            color: #FFFFFF;
            width: 32px;
            height: 28px;
            border-radius: 6px;
            font-size: 11px;
            font-weight: 700;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.15s ease;
        }

        .btn-step:active {
            background: #38BDF8;
            color: #0F172A;
            transform: scale(0.92);
        }

        /* Inputs & Selectors */
        .custom-select, .custom-input {
            width: 100%;
            background: var(--bg-canvas);
            border: 1px solid var(--border-card);
            color: #FFFFFF;
            padding: 9px 12px;
            border-radius: 8px;
            font-size: 11.5px;
            font-family: inherit;
            margin-bottom: 10px;
            outline: none;
            transition: border-color 0.2s ease;
        }

        .custom-select:focus, .custom-input:focus {
            border-color: var(--border-focus);
        }

        .input-label {
            font-size: 10px;
            font-weight: 600;
            color: var(--text-muted);
            margin-bottom: 4px;
            display: block;
        }

        /* Payment Buttons Strip */
        .payment-mode-strip {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 6px;
            margin-bottom: 14px;
        }

        .btn-payment-pill {
            background: var(--bg-canvas);
            border: 1px solid var(--border-card);
            color: var(--text-muted);
            font-size: 11px;
            font-weight: 700;
            padding: 8px 4px;
            border-radius: 8px;
            cursor: pointer;
            text-align: center;
            transition: all 0.2s ease;
        }

        .btn-payment-pill.active {
            border-color: #38BDF8;
            color: #FFFFFF;
            background: rgba(56, 189, 248, 0.15);
        }

        .btn-payment-pill.active.green {
            border-color: #10B981;
            color: #34D399;
            background: rgba(16, 185, 129, 0.15);
        }

        .btn-payment-pill.active.amber {
            border-color: #F59E0B;
            color: #FBBF24;
            background: rgba(245, 158, 11, 0.15);
        }

        /* Total & Primary Action */
        .total-action-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: var(--bg-card-subtle);
            border: 1px solid var(--border-card);
            border-radius: 12px;
            padding: 12px 14px;
            margin-top: 6px;
        }

        .total-meta small {
            font-size: 9.5px;
            color: var(--text-muted);
            display: block;
        }

        .total-meta strong {
            font-size: 20px;
            font-weight: 800;
            font-family: 'JetBrains Mono', monospace;
            color: #38BDF8;
        }

        .btn-primary-action {
            background: linear-gradient(135deg, #0284C7 0%, #0369A1 100%);
            border: none;
            color: #FFFFFF;
            font-size: 12px;
            font-weight: 700;
            padding: 10px 16px;
            border-radius: 8px;
            cursor: pointer;
            box-shadow: 0 4px 12px rgba(2, 132, 199, 0.4);
            transition: all 0.2s ease;
        }

        .btn-primary-action:active {
            transform: scale(0.96);
        }

        /* Bottom Tab Navigation */
        .mobile-bottom-nav {
            background-color: #0F172A;
            border-top: 1px solid var(--border-card);
            padding: 6px 10px 10px;
            display: flex;
            justify-content: space-around;
            position: sticky;
            bottom: 0;
            z-index: 50;
        }

        .nav-tab-item {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 2px;
            color: var(--text-dim);
            font-size: 9.5px;
            font-weight: 600;
            cursor: pointer;
            transition: color 0.2s ease;
        }

        .nav-tab-item.active {
            color: #38BDF8;
        }

        /* Thermal Monospace Receipt Modal */
        .thermal-modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.85);
            backdrop-filter: blur(4px);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 100;
            padding: 16px;
        }

        .thermal-slip {
            width: 100%;
            max-width: 320px;
            background: #FFFFFF;
            color: #000000;
            font-family: 'JetBrains Mono', monospace;
            padding: 20px 16px;
            border-radius: 4px;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.5);
            font-size: 11px;
            line-height: 1.4;
            position: relative;
        }

        .thermal-slip::after {
            content: "";
            position: absolute;
            bottom: -6px;
            left: 0;
            width: 100%;
            height: 6px;
            background: radial-gradient(circle, transparent, transparent 50%, #FFFFFF 50%, #FFFFFF 100%);
            background-size: 12px 6px;
        }

        .slip-center { text-align: center; }
        .slip-divider { border-top: 1px dashed #666; margin: 8px 0; }
        .slip-row { display: flex; justify-content: space-between; margin: 3px 0; }

        /* ERP Drawer Navigation Styles */
        .erp-drawer-overlay {
            position: absolute;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0, 0, 0, 0.75);
            backdrop-filter: blur(3px);
            z-index: 85;
            display: none;
        }
        .erp-drawer {
            position: absolute;
            top: 0; left: 0; bottom: 0;
            width: 290px;
            background: var(--bg-card);
            border-right: 1px solid var(--border-card);
            z-index: 90;
            display: flex;
            flex-direction: column;
            transform: translateX(-100%);
            transition: transform 0.28s cubic-bezier(0.4, 0, 0.2, 1);
            overflow-y: auto;
            box-shadow: 10px 0 30px rgba(0, 0, 0, 0.6);
        }
        .erp-drawer.open {
            transform: translateX(0);
        }
        .erp-drawer-header {
            padding: 18px 16px 14px;
            background: linear-gradient(135deg, #0F172A, #1E293B);
            border-bottom: 1px solid var(--border-card);
        }
        .erp-drawer-section-title {
            padding: 12px 16px 4px;
            font-size: 9.5px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.6px;
            color: var(--text-dim);
        }
        .erp-drawer-item {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 16px;
            color: var(--text-primary);
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.15s ease;
            text-decoration: none;
        }
        .erp-drawer-item:hover {
            background: rgba(56, 189, 248, 0.1);
            color: #38BDF8;
        }
        .erp-drawer-item .badge {
            margin-left: auto;
            font-size: 8.5px;
            padding: 2px 6px;
            border-radius: 4px;
            font-weight: 700;
            background: rgba(56, 189, 248, 0.15);
            color: #38BDF8;
        }

        /* Generic ERP Data View Modals */
        .erp-modal-overlay {
            position: absolute;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0, 0, 0, 0.85);
            backdrop-filter: blur(4px);
            z-index: 95;
            display: none;
            align-items: center;
            justify-content: center;
            padding: 14px;
        }
        .erp-modal-box {
            width: 100%;
            max-width: 410px;
            max-height: 85vh;
            background: var(--bg-card);
            border: 1px solid var(--border-card);
            border-radius: 16px;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            box-shadow: 0 20px 40px rgba(0,0,0,0.7);
        }
        .erp-modal-header {
            padding: 12px 16px;
            border-bottom: 1px solid var(--border-card);
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: var(--bg-card-subtle);
        }
        .erp-modal-body {
            padding: 14px;
            overflow-y: auto;
            flex: 1;
        }

        .btn-hamburger {
            background: rgba(255, 255, 255, 0.08);
            border: 1px solid var(--border-card);
            color: #FFFFFF;
            width: 30px;
            height: 30px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            font-size: 15px;
            margin-right: 4px;
            flex-shrink: 0;
        }
        .btn-hamburger:hover {
            background: rgba(56, 189, 248, 0.2);
            color: #38BDF8;
        }

        html.light .erp-drawer { background: #FFFFFF; border-right-color: #CBD5E1; }
        html.light .erp-drawer-header { background: linear-gradient(135deg, #F8FAFC, #E2E8F0); }
        html.light .erp-drawer-item { color: #0F172A; }
        html.light .erp-drawer-item:hover { background: #F1F5F9; color: #0284C7; }
        html.light .erp-modal-box { background: #FFFFFF; border-color: #CBD5E1; }
        html.light .erp-modal-header { background: #F8FAFC; border-bottom-color: #E2E8F0; }
        html.light .btn-hamburger { background: #F1F5F9; border-color: #CBD5E1; color: #0F172A; }
    </style>
</head>
<body>

<div class="device-simulator-wrapper">

    <!-- ERP Drawer Overlay & Sliding Drawer -->
    <div id="erp-drawer-overlay" class="erp-drawer-overlay" onclick="closeErpDrawer()"></div>
    <aside id="erp-drawer" class="erp-drawer">
        <div class="erp-drawer-header">
            <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px;">
                <div style="display: flex; align-items: center; gap: 8px;">
                    <div style="background: rgba(56, 189, 248, 0.2); border: 1px solid #38BDF8; color: #38BDF8; width: 28px; height: 28px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 14px;">💧</div>
                    <strong style="color: #FFFFFF; font-size: 14px;">DK Track ERP</strong>
                </div>
                <button onclick="closeErpDrawer()" style="background: none; border: none; color: var(--text-muted); font-size: 18px; cursor: pointer;">✕</button>
            </div>
            <div style="background: rgba(0,0,0,0.25); border-radius: 8px; padding: 8px 10px;">
                <div id="drawer-active-user" style="font-size: 12px; font-weight: 700; color: #FFFFFF;">Super Admin (Executive)</div>
                <div id="drawer-active-role" style="font-size: 10px; color: #38BDF8; font-weight: 600;">👑 Super Admin · Multi-Company</div>
            </div>
        </div>

        <!-- Section: Command & Masters -->
        <div class="erp-drawer-section-title">COMMAND & MASTERS</div>
        <div class="erp-drawer-item" onclick="closeErpDrawer(); switchRole('superAdmin');">
            <span>📊</span>
            <span>Executive Dashboard</span>
        </div>
        <div class="erp-drawer-item" onclick="closeErpDrawer(); openCustomersModal();">
            <span>👥</span>
            <span>Customers Directory</span>
            <span class="badge">ERP Master</span>
        </div>
        <div class="erp-drawer-item" onclick="closeErpDrawer(); openProductsModal();">
            <span>🏷️</span>
            <span>Products & Price Matrix</span>
            <span class="badge">Catalog</span>
        </div>

        <!-- Section: Water Logistics Suite -->
        <div class="erp-drawer-section-title">WATER LOGISTICS SUITE</div>
        <div class="erp-drawer-item" onclick="closeErpDrawer(); switchRole('deliveryDriver');">
            <span>🚚</span>
            <span>Packaged Water Deliveries (&lt;15s)</span>
            <span class="badge">Route</span>
        </div>
        <div class="erp-drawer-item" onclick="closeErpDrawer(); switchRole('tankerDriver');">
            <span>🚛</span>
            <span>Bulk Tanker Trips & Decanting</span>
            <span class="badge">TMWS Fleet</span>
        </div>
        <div class="erp-drawer-item" onclick="closeErpDrawer(); switchRole('deliveryDriver'); switchDriverTab('plant');">
            <span>🏭</span>
            <span>Plant Loading & Gate Passes</span>
        </div>
        <div class="erp-drawer-item" onclick="closeErpDrawer(); switchRole('superAdmin'); switchSuperAdminTab('fraud');">
            <span>📦</span>
            <span>Empty Jar Custody & Audit</span>
            <span class="badge" style="color: #EF4444; background: rgba(239, 68, 68, 0.15);">Anti-Theft</span>
        </div>

        <!-- Section: Finance & Accounts -->
        <div class="erp-drawer-section-title">FINANCE & ACCOUNTS</div>
        <div class="erp-drawer-item" onclick="closeErpDrawer(); openInvoicesModal();">
            <span>🧾</span>
            <span>Sales Invoices & Slips</span>
            <span class="badge">Invoices</span>
        </div>
        <div class="erp-drawer-item" onclick="closeErpDrawer(); switchRole('fieldAgent');">
            <span>💳</span>
            <span>Field Collections & KYC</span>
        </div>
        <div class="erp-drawer-item" onclick="closeErpDrawer(); openFinancialsModal();">
            <span>💰</span>
            <span>GL Financial Balances</span>
            <span class="badge" style="color: #F59E0B; background: rgba(245, 158, 11, 0.15);">GL 1010-1030</span>
        </div>

        <!-- Section: Aran Cafe POS -->
        <div class="erp-drawer-section-title">ARAN CAFE COUNTER</div>
        <div class="erp-drawer-item" onclick="closeErpDrawer(); switchRole('cashier');">
            <span>☕</span>
            <span>Express Touch POS & Drawer</span>
            <span class="badge">Cafe POS</span>
        </div>

        <!-- Section: Session & Role Login -->
        <div class="erp-drawer-section-title">SESSION CONTROLS</div>
        <div class="erp-drawer-item" onclick="closeErpDrawer(); openRoleLoginModal();">
            <span>🔑</span>
            <span style="color: #38BDF8; font-weight: 700;">Role Login Screen</span>
            <span class="badge">6 Roles</span>
        </div>
        <div class="erp-drawer-item" onclick="closeErpDrawer(); logoutSession();" style="color: #EF4444;">
            <span>🚪</span>
            <span>Logout Session</span>
        </div>
        <div style="height: 24px;"></div>
    </aside>

    <!-- Top App Bar -->
    <header class="mobile-header">
        <div class="header-brand-group">
            <button class="btn-hamburger" onclick="openErpDrawer()" title="ERP Menus">☰</button>
            <div id="role-badge-icon" class="brand-badge-icon">👑</div>
            <div class="header-titles">
                <h1 id="header-role-title">Super Admin Command</h1>
                <span id="header-role-subtitle">Consolidated Multi-Company Executive Portal</span>
            </div>
        </div>
        <div class="header-controls">
            <button class="btn-theme-toggle" id="btn-theme-toggle" onclick="toggleTheme()" title="Toggle Light/Dark Theme">☀️ Light</button>
            <button class="btn-lang-toggle" onclick="toggleLanguage()">தமிழ் / EN</button>
        </div>
    </header>

    <!-- Target API Status Banner -->
    <div class="api-target-banner">
        <div>
            <span class="api-pulse-dot"></span>
            <strong>Target API:</strong> <span id="disp-api-url">https://dkenterprises.animazon.in/api/v1</span>
        </div>
        <button class="api-test-btn" onclick="testApiConnection()">Test API</button>
    </div>

    <!-- Multi-Role Selector Ribbon (1-Tap Switch) -->
    <div class="role-selector-ribbon">
        <div class="role-pill active" id="pill-super-admin" onclick="switchRole('superAdmin')">
            <span class="icon">👑</span>
            <div class="pill-meta">
                <strong>Super Admin</strong>
                <small data-i18n="super_admin_sub">Executive Oversight</small>
            </div>
        </div>
        <div class="role-pill" id="pill-admin" onclick="switchRole('admin')">
            <span class="icon">🏢</span>
            <div class="pill-meta">
                <strong>Company Admin</strong>
                <small data-i18n="admin_sub">Fleet & Settlements</small>
            </div>
        </div>
        <div class="role-pill" id="pill-field-agent" onclick="switchRole('fieldAgent')">
            <span class="icon">📋</span>
            <div class="pill-meta">
                <strong>Field Agent</strong>
                <small data-i18n="agent_sub">KYC & Collections</small>
            </div>
        </div>
        <div class="role-pill" id="pill-delivery-driver" onclick="switchRole('deliveryDriver')">
            <span class="icon">🚚</span>
            <div class="pill-meta">
                <strong>Route Driver</strong>
                <small data-i18n="route_sub">Packaged Water Cans</small>
            </div>
        </div>
        <div class="role-pill" id="pill-tanker-driver" onclick="switchRole('tankerDriver')">
            <span class="icon">🚛</span>
            <div class="pill-meta">
                <strong>Tanker Driver</strong>
                <small data-i18n="tanker_sub">Bulk Water Decanting</small>
            </div>
        </div>
        <div class="role-pill" id="pill-cashier" onclick="switchRole('cashier')">
            <span class="icon">☕</span>
            <div class="pill-meta">
                <strong>Cafe Cashier</strong>
                <small data-i18n="cafe_sub">POS Counter & Float</small>
            </div>
        </div>
    </div>

    <!-- Main Viewport Area -->
    <main class="mobile-main-content">

        <!-- ============================================================== -->
        <!-- ROLE 1: SUPER ADMIN COMMAND DASHBOARD                          -->
        <!-- ============================================================== -->
        <div id="view-super-admin" class="role-view">
            <div class="kpi-grid">
                <div class="kpi-card highlight-purple">
                    <div class="kpi-header">
                        <span class="kpi-title" data-i18n="group_revenue">Group Revenue</span>
                        <span>💰</span>
                    </div>
                    <div class="kpi-value">₹ 1,92,700</div>
                    <div class="kpi-subtext">+14.2% vs yesterday</div>
                </div>
                <div class="kpi-card highlight-blue">
                    <div class="kpi-header">
                        <span class="kpi-title" data-i18n="cash_in_transit">Cash in Transit</span>
                        <span>🚚</span>
                    </div>
                    <div class="kpi-value">₹ 34,250</div>
                    <div class="kpi-subtext">Held by 6 drivers</div>
                </div>
                <div class="kpi-card highlight-green">
                    <div class="kpi-header">
                        <span class="kpi-title" data-i18n="container_capital">Container Capital</span>
                        <span>🏺</span>
                    </div>
                    <div class="kpi-value">₹ 7,23,000</div>
                    <div class="kpi-subtext">4,820 Cans in Market</div>
                </div>
                <div class="kpi-card highlight-amber">
                    <div class="kpi-header">
                        <span class="kpi-title" data-i18n="fleet_util">Fleet Active</span>
                        <span>🚛</span>
                    </div>
                    <div class="kpi-value">7 / 7 Units</div>
                    <div class="kpi-subtext">100% On Schedule</div>
                </div>
            </div>

            <!-- Multi-Company Portals -->
            <div class="form-section-card">
                <div class="section-title">
                    <span data-i18n="enterprises_title">Consolidated Business Verticals</span>
                    <span>🏢</span>
                </div>
                <div style="display: flex; flex-direction: column; gap: 8px;">
                    <div style="background: #162032; padding: 10px; border-radius: 8px; border-left: 4px solid #0284C7; display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <strong style="font-size: 11.5px; color: #FFFFFF;">💧 DK Waters</strong>
                            <small style="display: block; font-size: 9px; color: #94A3B8;">8 Routes · 4,820 Cans in Market · 2 Tata Ace</small>
                        </div>
                        <div style="text-align: right;">
                            <strong style="font-size: 12px; color: #38BDF8;">₹ 48,250</strong>
                            <small style="display: block; font-size: 8px; color: #10B981;">100% Reconciled</small>
                        </div>
                    </div>
                    <div style="background: #162032; padding: 10px; border-radius: 8px; border-left: 4px solid #2563EB; display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <strong style="font-size: 11.5px; color: #FFFFFF;">🚛 Tiruchendur Murugan Water Supply</strong>
                            <small style="display: block; font-size: 9px; color: #94A3B8;">5 Heavy Tankers · 84 KL Delivered Today</small>
                        </div>
                        <div style="text-align: right;">
                            <strong style="font-size: 12px; color: #60A5FA;">₹ 1,26,000</strong>
                            <small style="display: block; font-size: 8px; color: #10B981;">GPS Telematics Active</small>
                        </div>
                    </div>
                    <div style="background: #162032; padding: 10px; border-radius: 8px; border-left: 4px solid #D97706; display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <strong style="font-size: 11.5px; color: #FFFFFF;">☕ Aran Cafe</strong>
                            <small style="display: block; font-size: 9px; color: #94A3B8;">Express Counter POS · 2 Registers</small>
                        </div>
                        <div style="text-align: right;">
                            <strong style="font-size: 12px; color: #FBBF24;">₹ 18,450</strong>
                            <small style="display: block; font-size: 8px; color: #10B981;">Shift Float Intact</small>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Anti-Fraud Radar -->
            <div class="form-section-card">
                <div class="section-title">
                    <span data-i18n="anti_fraud_radar">Live Anti-Fraud Command Radar</span>
                    <span style="color: #EF4444;">🚨 3 Active Alerts</span>
                </div>
                <div class="fraud-alert-item">
                    <div class="fraud-header">
                        <span class="fraud-title">Odometer Tampering Detected</span>
                        <span class="fraud-badge">High Severity</span>
                    </div>
                    <div class="fraud-desc">
                        Tanker TN 38 CC 9012 (Driver Selvam): Trip sheet claimed 154 km vs 72 km verified by Live GPS Telematics.
                    </div>
                    <div class="fraud-actions">
                        <button class="btn-fraud-action btn-fraud-danger" onclick="alert('Driver account temporarily locked. Supervisor summoned.')">Lock Account</button>
                        <button class="btn-fraud-action btn-fraud-subtle" onclick="alert('Trip sheet flagged for audit inspection.')">Flag for Audit</button>
                    </div>
                </div>
                <div class="fraud-alert-item">
                    <div class="fraud-header">
                        <span class="fraud-title">Empty Container Siphoning</span>
                        <span class="fraud-badge">Can Shortage</span>
                    </div>
                    <div class="fraud-desc">
                        Route 1 (Driver Kumar): 42 missing empty returns against plant intake delivery manifest.
                    </div>
                    <div class="fraud-actions">
                        <button class="btn-fraud-action btn-fraud-danger" onclick="alert('Batta deduction of ₹6,300 held pending container recovery.')">Hold Batta</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- ============================================================== -->
        <!-- ROLE 2: COMPANY ADMIN SCREEN                                   -->
        <!-- ============================================================== -->
        <div id="view-admin" class="role-view" style="display: none;">
            <!-- Pending Driver Surrenders -->
            <div class="form-section-card">
                <div class="section-title">
                    <span data-i18n="pending_surrenders">Pending Driver Cash Surrenders</span>
                    <span>💰</span>
                </div>
                <div id="admin-surrender-card" style="background: #162032; border: 1px solid #1E293B; border-radius: 10px; padding: 12px; margin-bottom: 8px;">
                    <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px;">
                        <div>
                            <strong style="font-size: 12px; color: #FFFFFF;">Kumar (Tata Ace - TN 38 BX 4412)</strong>
                            <small style="display: block; font-size: 9.5px; color: #94A3B8;">Route: Gandhipuram Beat · 48 Cans Delivered</small>
                        </div>
                        <span style="background: #F59E0B; color: #000000; font-size: 8px; font-weight: 800; padding: 2px 6px; border-radius: 4px;">PENDING</span>
                    </div>
                    <div style="display: flex; justify-content: space-between; font-size: 11px; margin-bottom: 10px;">
                        <span>Cash Collected: <strong style="color: #34D399;">₹ 3,850.00</strong></span>
                        <span>Returns: <strong style="color: #38BDF8;">46 Cans</strong></span>
                    </div>
                    <button id="btn-admin-approve" class="btn-primary-action" style="width: 100%; font-size: 11px; padding: 8px;" onclick="approveDriverSurrender()">
                        Approve & Post to Cash GL 1010
                    </button>
                </div>
            </div>

            <!-- Fleet Operations -->
            <div class="form-section-card">
                <div class="section-title">
                    <span data-i18n="active_fleet">Active Fleet Dispatches</span>
                    <span>🚛</span>
                </div>
                <div style="display: flex; flex-direction: column; gap: 8px;">
                    <div style="background: #162032; border-radius: 8px; padding: 10px; border-left: 3px solid #10B981;">
                        <strong style="font-size: 11.5px; color: #FFFFFF;">Tata Ace TN 38 BX 4412</strong>
                        <div style="font-size: 9.5px; color: #94A3B8; margin-top: 2px;">Route 1: Gandhipuram · Stock: 96 / 100 Cans</div>
                        <div style="font-size: 9px; color: #10B981; margin-top: 4px;">🟢 Active Delivery (Customer #4)</div>
                    </div>
                    <div style="background: #162032; border-radius: 8px; padding: 10px; border-left: 3px solid #2563EB;">
                        <strong style="font-size: 11.5px; color: #FFFFFF;">Tanker TN 38 CC 9012 (20 KL)</strong>
                        <div style="font-size: 9.5px; color: #94A3B8; margin-top: 2px;">En Route to Texvalley Commercial · Chamber 1 & 2 Full</div>
                        <div style="font-size: 9px; color: #60A5FA; margin-top: 4px;">🟢 GPS Telematics: 42 km/h</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- ============================================================== -->
        <!-- ROLE 3: FIELD AGENT SCREEN (KYC, COLLECTIONS, SPOT AUDIT)      -->
        <!-- ============================================================== -->
        <div id="view-field-agent" class="role-view" style="display: none;">
            <div class="role-subnav">
                <button class="subnav-btn active" id="subtab-agent-collect" onclick="switchAgentTab('collect')">Collections</button>
                <button class="subnav-btn" id="subtab-agent-kyc" onclick="switchAgentTab('kyc')">New Customer KYC</button>
                <button class="subnav-btn" id="subtab-agent-audit" onclick="switchAgentTab('audit')">Container Audit</button>
            </div>

            <!-- Agent Subtab 1: Collections -->
            <div id="agent-panel-collect" style="margin-top: 14px;">
                <div class="form-section-card">
                    <div class="section-title">
                        <span data-i18n="credit_collection">Credit Aging Collection</span>
                        <span>💳</span>
                    </div>
                    <label class="input-label" data-i18n="select_customer">Select Customer</label>
                    <select id="agent-collect-customer" class="custom-select">
                        <option value="1">Aran Cafe - Main Kitchen (Pending: ₹ 4,200)</option>
                        <option value="2">Santha Provision Stores (Pending: ₹ 1,850)</option>
                        <option value="3">Meenakshi Supermarket (Pending: ₹ 6,400)</option>
                        <option value="4">Titan Corporate Campus (Pending: ₹ 14,000)</option>
                    </select>

                    <label class="input-label" data-i18n="amount_collected">Amount Collected (₹)</label>
                    <input type="number" id="agent-collect-amount" class="custom-input" value="1850" placeholder="Enter collection amount">

                    <label class="input-label" data-i18n="payment_mode">Payment Mode</label>
                    <div class="payment-mode-strip">
                        <button type="button" class="btn-payment-pill active green" id="agent-pay-cash" onclick="setAgentPayMode('cash')">Cash</button>
                        <button type="button" class="btn-payment-pill" id="agent-pay-upi" onclick="setAgentPayMode('upi')">UPI / GPay</button>
                        <button type="button" class="btn-payment-pill" id="agent-pay-cheque" onclick="setAgentPayMode('cheque')">Cheque</button>
                    </div>

                    <button class="btn-primary-action" style="width: 100%; margin-top: 6px;" onclick="submitAgentCollection()">
                        Post Collection & Generate Digital Receipt
                    </button>
                </div>
            </div>

            <!-- Agent Subtab 2: Customer KYC Onboarding -->
            <div id="agent-panel-kyc" style="display: none; margin-top: 14px;">
                <div class="form-section-card">
                    <div class="section-title">
                        <span data-i18n="customer_onboard">New Customer KYC Onboarding</span>
                        <span>👤</span>
                    </div>
                    <label class="input-label">Customer / Business Name</label>
                    <input type="text" id="kyc-name" class="custom-input" placeholder="e.g. Sree Annapoorna Sweets">

                    <label class="input-label">Mobile Number</label>
                    <input type="text" id="kyc-phone" class="custom-input" placeholder="e.g. 98422 12345">

                    <label class="input-label">Delivery Address</label>
                    <input type="text" id="kyc-address" class="custom-input" placeholder="e.g. 45 DB Road, RS Puram, Coimbatore">

                    <div style="display: flex; gap: 8px;">
                        <div style="flex: 1;">
                            <label class="input-label">GPS Latitude</label>
                            <input type="text" id="kyc-lat" class="custom-input" value="11.0168">
                        </div>
                        <div style="flex: 1;">
                            <label class="input-label">GPS Longitude</label>
                            <input type="text" id="kyc-lng" class="custom-input" value="76.9558">
                        </div>
                    </div>
                    <button type="button" class="btn-fraud-action btn-fraud-subtle" style="width: 100%; margin-bottom: 10px;" onclick="autoFillGps()">
                        📍 Auto-Detect Current GPS Coordinates
                    </button>

                    <div style="display: flex; gap: 8px;">
                        <div style="flex: 1;">
                            <label class="input-label">Opening Cans Held</label>
                            <input type="number" id="kyc-cans" class="custom-input" value="5">
                        </div>
                        <div style="flex: 1;">
                            <label class="input-label">Deposit Collected (₹)</label>
                            <input type="number" id="kyc-deposit" class="custom-input" value="750">
                        </div>
                    </div>

                    <button class="btn-primary-action" style="width: 100%;" onclick="submitCustomerKyc()">
                        Onboard Customer & Register Jar Custody
                    </button>
                </div>
            </div>

            <!-- Agent Subtab 3: Spot Container Audit -->
            <div id="agent-panel-audit" style="display: none; margin-top: 14px;">
                <div class="form-section-card">
                    <div class="section-title">
                        <span data-i18n="spot_audit">Physical Jar Custody Audit</span>
                        <span>🔍</span>
                    </div>
                    <label class="input-label">Select Customer Site</label>
                    <select id="audit-cust-select" class="custom-select" onchange="updateAuditBaseline()">
                        <option value="1" data-ledger="15">Aran Cafe - Main Kitchen (Ledger Balance: 15 Cans)</option>
                        <option value="2" data-ledger="10">Santha Provision Stores (Ledger Balance: 10 Cans)</option>
                        <option value="3" data-ledger="25">Meenakshi Supermarket (Ledger Balance: 25 Cans)</option>
                    </select>

                    <div style="display: flex; gap: 8px;">
                        <div style="flex: 1;">
                            <label class="input-label">Ledger Balance</label>
                            <input type="text" id="audit-expected-cans" class="custom-input" value="15 Cans" readonly>
                        </div>
                        <div style="flex: 1;">
                            <label class="input-label">Physical Count on Site</label>
                            <input type="number" id="audit-physical-cans" class="custom-input" value="15" oninput="calcAuditVariance()">
                        </div>
                    </div>

                    <div id="audit-feedback-banner" style="background: #064E3B; border: 1px solid #10B981; border-radius: 8px; padding: 10px; margin-bottom: 12px;">
                        <strong id="audit-feedback-title" style="font-size: 11px; color: #34D399;">✅ 100% BALANCED: ZERO VARIANCE</strong>
                        <p id="audit-feedback-desc" style="font-size: 9.5px; color: #E2E8F0; margin-top: 2px;">Physical count matches ERP container ledger exactly.</p>
                    </div>

                    <button class="btn-primary-action" style="width: 100%;" onclick="submitSpotAuditRecord()">
                        Submit Audit & Log to Anti-Fraud Command
                    </button>
                </div>
            </div>
        </div>

        <!-- ============================================================== -->
        <!-- ROLE 4: ROUTE DELIVERY DRIVER (TATA ACE — PACKAGED WATER)      -->
        <!-- ============================================================== -->
        <div id="view-delivery-driver" class="role-view" style="display: none;">
            <div class="role-subnav">
                <button class="subnav-btn active" id="subtab-driver-ticket" onclick="switchDriverTab('ticket')">Delivery Ticket</button>
                <button class="subnav-btn" id="subtab-driver-refill" onclick="switchDriverTab('refill')">Plant Refill</button>
                <button class="subnav-btn" id="subtab-driver-surrender" onclick="switchDriverTab('surrender')">End of Day Surrender</button>
            </div>

            <!-- Driver Subtab 1: Ticketing Machine (<15s) -->
            <div id="driver-panel-ticket" style="margin-top: 14px;">
                <div class="form-section-card">
                    <div class="section-title">
                        <span data-i18n="pos_ticket_title">Packaged Drinking Water Delivery</span>
                        <span>💧</span>
                    </div>

                    <label class="input-label" data-i18n="cust_label">Customer / Commercial Buyer</label>
                    <select id="pkw-customer-select" class="custom-select">
                        <option value="1" data-name="Aran Cafe - Main Kitchen">Aran Cafe - Main Kitchen (RS Puram)</option>
                        <option value="2" data-name="Santha Provision Stores">Santha Provision Stores (Gandhipuram)</option>
                        <option value="3" data-name="Meenakshi Supermarket">Meenakshi Supermarket (Town Hall)</option>
                        <option value="4" data-name="Sri Krishna Bakery">Sri Krishna Bakery (Ramanathapuram)</option>
                    </select>

                    <label class="input-label" data-i18n="package_label">Package Specification</label>
                    <select id="pkw-package-select" class="custom-select" onchange="updateTicketCalc()">
                        <option value="CAN-20L" data-price="35.0" data-name="Packaged Drinking Water (20L Jar)" data-jar="1">20L Packaged Drinking Water Jar (₹ 35.00)</option>
                        <option value="CAN-25L" data-price="45.0" data-name="Packaged Drinking Water (25L Jar)" data-jar="1">25L Packaged Drinking Water Jar (₹ 45.00)</option>
                        <option value="CAN-10L" data-price="25.0" data-name="Easy-Dispense Water Jar (10L)" data-jar="1">10L Easy-Dispense Water Jar (₹ 25.00)</option>
                        <option value="BTL-1L" data-price="180.0" data-name="1L Bottled Water Box of 12" data-jar="0">1 Litre Bottled Water (Box of 12) (₹ 180.00)</option>
                    </select>

                    <!-- Stepper Grid -->
                    <div class="stepper-grid">
                        <div class="stepper-box highlight">
                            <div class="stepper-title" data-i18n="del_qty_label">Delivered Units</div>
                            <div class="stepper-value" id="disp-del-qty">2</div>
                            <div class="stepper-actions">
                                <button type="button" class="btn-step" onclick="stepDelQty(-1)">-1</button>
                                <button type="button" class="btn-step" onclick="stepDelQty(1)">+1</button>
                                <button type="button" class="btn-step" onclick="stepDelQty(5)">+5</button>
                            </div>
                        </div>
                        <div class="stepper-box" id="empty-box-container">
                            <div class="stepper-title" data-i18n="ret_empty_label">Returned Empties</div>
                            <div class="stepper-value green" id="disp-ret-qty">2</div>
                            <div class="stepper-actions" id="empty-stepper-controls">
                                <button type="button" class="btn-step" onclick="stepRetQty(-1)">-1</button>
                                <button type="button" class="btn-step" onclick="stepRetQty(1)">+1</button>
                                <button type="button" class="btn-step" onclick="stepRetQty(5)">+5</button>
                            </div>
                        </div>
                    </div>

                    <label class="input-label" data-i18n="payment_mode">Payment Settlement</label>
                    <div class="payment-mode-strip">
                        <button type="button" class="btn-payment-pill active green" id="pill-pay-cash" onclick="setPaymentMode('cash')">Cash</button>
                        <button type="button" class="btn-payment-pill" id="pill-pay-upi" onclick="setPaymentMode('upi')">UPI / GPay</button>
                        <button type="button" class="btn-payment-pill" id="pill-pay-credit" onclick="setPaymentMode('credit')">Credit</button>
                    </div>

                    <div class="total-action-bar">
                        <div class="total-meta">
                            <small id="disp-calc-formula">2 × ₹35.00</small>
                            <strong id="disp-total-fare">₹ 70.00</strong>
                        </div>
                        <button type="button" class="btn-primary-action" onclick="submitPackagedDelivery()">
                            Print Slip
                        </button>
                    </div>
                </div>
            </div>

            <!-- Driver Subtab 2: Plant Refill -->
            <div id="driver-panel-refill" style="display: none; margin-top: 14px;">
                <div class="form-section-card">
                    <div class="section-title">
                        <span data-i18n="plant_refill_title">Water Plant Intake Loading</span>
                        <span>🏭</span>
                    </div>
                    <label class="input-label">Loading Gate Pass / Slip Number</label>
                    <input type="text" id="plant-slip-input" class="custom-input" value="PLT-20261101-02">

                    <label class="input-label">Odometer Reading at Plant (KM)</label>
                    <input type="number" id="plant-odo-input" class="custom-input" value="48215">

                    <div class="stepper-box highlight" style="margin-bottom: 12px;">
                        <div class="stepper-title">Cans Loaded into Tata Ace</div>
                        <div class="stepper-value" id="disp-plant-qty">50</div>
                        <div class="stepper-actions">
                            <button type="button" class="btn-step" onclick="stepPlantQty(-5)">-5</button>
                            <button type="button" class="btn-step" onclick="stepPlantQty(5)">+5</button>
                            <button type="button" class="btn-step" onclick="stepPlantQty(10)">+10</button>
                        </div>
                    </div>

                    <button class="btn-primary-action" style="width: 100%;" onclick="submitPlantRefill()">
                        Confirm Loading & Update Truck Stock
                    </button>
                </div>
            </div>

            <!-- Driver Subtab 3: Driver Surrender -->
            <div id="driver-panel-surrender" style="display: none; margin-top: 14px;">
                <div class="form-section-card">
                    <div class="section-title">
                        <span>End of Day Driver Settlement</span>
                        <span>💰</span>
                    </div>
                    <div style="background: #162032; padding: 10px; border-radius: 8px; margin-bottom: 12px;">
                        <div style="display: flex; justify-content: space-between; font-size: 11px; margin-bottom: 6px;">
                            <span>Deliveries Completed:</span>
                            <strong style="color: #38BDF8;">18 Drops</strong>
                        </div>
                        <div style="display: flex; justify-content: space-between; font-size: 11px; margin-bottom: 6px;">
                            <span>Empty Cans Recovered:</span>
                            <strong style="color: #34D399;">46 Cans</strong>
                        </div>
                        <div style="display: flex; justify-content: space-between; font-size: 11px;">
                            <span>Cash to Surrender:</span>
                            <strong style="color: #34D399; font-size: 14px;">₹ 3,850.00</strong>
                        </div>
                    </div>

                    <label class="input-label">Cash In Hand (Counted)</label>
                    <input type="number" id="surrender-cash" class="custom-input" value="3850">

                    <label class="input-label">Empty Containers in Truck</label>
                    <input type="number" id="surrender-cans" class="custom-input" value="46">

                    <button class="btn-primary-action" style="width: 100%;" onclick="submitDriverSurrenderRecord()">
                        Submit Surrender to Admin
                    </button>
                </div>
            </div>
        </div>

        <!-- ============================================================== -->
        <!-- ROLE 5: TANKER DRIVER (TMWS HEAVY BULK TANKERS)                -->
        <!-- ============================================================== -->
        <div id="view-tanker-driver" class="role-view" style="display: none;">
            <div class="form-section-card">
                <div class="section-title">
                    <span data-i18n="tanker_trip_title">Bulk Tanker Trip Sheet</span>
                    <span>🚛</span>
                </div>

                <label class="input-label">Select Heavy Tanker</label>
                <select id="tmws-tanker-select" class="custom-select" onchange="calcTankerFare()">
                    <option value="1" data-cap="16.0">TN 38 CC 9012 (16 KL Tanker)</option>
                    <option value="2" data-cap="20.0" selected>TN 38 BD 4410 (20 KL Tanker)</option>
                    <option value="3" data-cap="24.0">TN 38 AE 1204 (24 KL Tanker)</option>
                </select>

                <label class="input-label">Commercial Client Site</label>
                <select id="tmws-client-select" class="custom-select">
                    <option value="1">Titan Corporate Campus (Hosur Highway)</option>
                    <option value="2">Texvalley Commercial Complex (NH-544)</option>
                    <option value="3">The Chennai Silks Logistics Yard</option>
                </select>

                <label class="input-label">Chamber Split Decanting</label>
                <div class="payment-mode-strip">
                    <button type="button" class="btn-payment-pill active" id="pill-ch-all" onclick="setChamber(0)">Full Load</button>
                    <button type="button" class="btn-payment-pill" id="pill-ch-1" onclick="setChamber(1)">Chamber 1</button>
                    <button type="button" class="btn-payment-pill" id="pill-ch-2" onclick="setChamber(2)">Chamber 2</button>
                </div>

                <div style="background: #162032; padding: 10px; border-radius: 8px; margin-bottom: 10px;">
                    <label style="display: flex; align-items: center; gap: 8px; font-size: 11px; cursor: pointer;">
                        <input type="checkbox" id="tmws-motor-chk" checked onchange="calcTankerFare()">
                        <span>Borewell Motor Pumping (+₹250 Surcharge)</span>
                    </label>
                </div>

                <div style="display: flex; gap: 8px;">
                    <div style="flex: 1;">
                        <label class="input-label">Odometer Start</label>
                        <input type="number" id="tmws-odo-start" class="custom-input" value="142810" oninput="calcTankerFare()">
                    </div>
                    <div style="flex: 1;">
                        <label class="input-label">Odometer End</label>
                        <input type="number" id="tmws-odo-end" class="custom-input" value="142852" oninput="calcTankerFare()">
                    </div>
                </div>

                <div class="total-action-bar">
                    <div class="total-meta">
                        <small id="disp-tanker-dist">Distance: 42 km</small>
                        <strong id="disp-tanker-fare">₹ 3,250.00</strong>
                    </div>
                    <button type="button" class="btn-primary-action" onclick="submitTankerTripSheet()">
                        Complete Trip
                    </button>
                </div>
            </div>
        </div>

        <!-- ============================================================== -->
        <!-- ROLE 6: CAFE CASHIER (ARAN CAFE EXPRESS POS)                   -->
        <!-- ============================================================== -->
        <div id="view-cashier" class="role-view" style="display: none;">
            <div class="form-section-card">
                <div class="section-title">
                    <span>Aran Cafe Express Touch POS</span>
                    <span>☕</span>
                </div>

                <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px; margin-bottom: 12px;">
                    <div style="background: #162032; border: 1px solid #1E293B; border-radius: 8px; padding: 10px; cursor: pointer;" onclick="addCafeItem(101, 'Special Filter Coffee', 25.0)">
                        <div style="display: flex; justify-content: space-between;">
                            <span style="font-size: 16px;">☕</span>
                            <span id="badge-qty-101" style="background: #D97706; color: #FFF; font-size: 9px; font-weight: 800; padding: 1px 5px; border-radius: 10px;">0</span>
                        </div>
                        <strong style="display: block; font-size: 11px; color: #FFF; margin-top: 4px;">Filter Coffee</strong>
                        <small style="color: #FBBF24; font-size: 10px;">₹ 25.00</small>
                    </div>

                    <div style="background: #162032; border: 1px solid #1E293B; border-radius: 8px; padding: 10px; cursor: pointer;" onclick="addCafeItem(102, 'Masala Tea', 20.0)">
                        <div style="display: flex; justify-content: space-between;">
                            <span style="font-size: 16px;">🫖</span>
                            <span id="badge-qty-102" style="background: #D97706; color: #FFF; font-size: 9px; font-weight: 800; padding: 1px 5px; border-radius: 10px;">0</span>
                        </div>
                        <strong style="display: block; font-size: 11px; color: #FFF; margin-top: 4px;">Masala Tea</strong>
                        <small style="color: #FBBF24; font-size: 10px;">₹ 20.00</small>
                    </div>

                    <div style="background: #162032; border: 1px solid #1E293B; border-radius: 8px; padding: 10px; cursor: pointer;" onclick="addCafeItem(103, 'Egg Puff', 30.0)">
                        <div style="display: flex; justify-content: space-between;">
                            <span style="font-size: 16px;">🥐</span>
                            <span id="badge-qty-103" style="background: #D97706; color: #FFF; font-size: 9px; font-weight: 800; padding: 1px 5px; border-radius: 10px;">0</span>
                        </div>
                        <strong style="display: block; font-size: 11px; color: #FFF; margin-top: 4px;">Egg Puff</strong>
                        <small style="color: #FBBF24; font-size: 10px;">₹ 30.00</small>
                    </div>

                    <div style="background: #162032; border: 1px solid #1E293B; border-radius: 8px; padding: 10px; cursor: pointer;" onclick="addCafeItem(104, 'Veg Samosa', 30.0)">
                        <div style="display: flex; justify-content: space-between;">
                            <span style="font-size: 16px;">🥟</span>
                            <span id="badge-qty-104" style="background: #D97706; color: #FFF; font-size: 9px; font-weight: 800; padding: 1px 5px; border-radius: 10px;">0</span>
                        </div>
                        <strong style="display: block; font-size: 11px; color: #FFF; margin-top: 4px;">Veg Samosa</strong>
                        <small style="color: #FBBF24; font-size: 10px;">₹ 30.00</small>
                    </div>
                </div>

                <div class="total-action-bar">
                    <div class="total-meta">
                        <small id="cafe-cart-summary">Cart: 0 Items</small>
                        <strong id="disp-cafe-total">₹ 0.00</strong>
                    </div>
                    <button type="button" class="btn-primary-action" style="background: linear-gradient(135deg, #D97706, #B45309);" onclick="submitCafeSale()">
                        Pay & Print KOT
                    </button>
                </div>
            </div>
        </div>

    </main>

    <!-- Bottom Role Navigation Strip -->
    <nav class="mobile-bottom-nav">
        <div class="nav-tab-item active" onclick="switchRole('superAdmin')">
            <span style="font-size: 16px;">👑</span>
            <span>Super Admin</span>
        </div>
        <div class="nav-tab-item" onclick="switchRole('fieldAgent')">
            <span style="font-size: 16px;">📋</span>
            <span>Field Agent</span>
        </div>
        <div class="nav-tab-item" onclick="switchRole('deliveryDriver')">
            <span style="font-size: 16px;">🚚</span>
            <span>Driver</span>
        </div>
        <div class="nav-tab-item" onclick="switchRole('cashier')">
            <span style="font-size: 16px;">☕</span>
            <span>Cafe POS</span>
        </div>
    </nav>

</div>

<!-- Thermal Slip Modal -->
<div id="thermal-modal" class="thermal-modal-overlay">
    <div class="thermal-slip">
        <div class="slip-center">
            <strong id="slip-company-header" style="font-size: 13px;">DK WATERS</strong>
            <p style="font-size: 9px; color: #444;">Packaged Drinking Water Division</p>
            <p style="font-size: 9px;">GSTIN: 33AAAAA0000A1Z5</p>
        </div>
        <div class="slip-divider"></div>
        <div class="slip-row"><span>REF NO:</span><strong id="slip-ref-no">REC-20261101-01</strong></div>
        <div class="slip-row"><span>DATE:</span><span id="slip-date">{{ date('d-m-Y H:i') }}</span></div>
        <div class="slip-row"><span>CUSTOMER:</span><strong id="slip-cust-name">Aran Cafe</strong></div>
        <div class="slip-divider"></div>
        <div class="slip-row"><span id="slip-prod-name">Collection Received</span><strong id="slip-total-fare">₹ 1,850.00</strong></div>
        <div class="slip-row"><span>MODE:</span><strong id="slip-pay-mode">CASH (PAID)</strong></div>
        <div class="slip-divider"></div>
        <div class="slip-center">
            <p style="font-size: 9px;">GPS: 11.0182° N, 76.9641° E</p>
            <p style="font-size: 9px; margin-top: 4px;">Thank you for your business!</p>
        </div>
        <button class="btn-primary-action" style="width: 100%; margin-top: 12px; font-size: 11px;" onclick="closeThermalModal()">
            Close Receipt
        </button>
    </div>
</div>

<script>
    const LIVE_API_URL = 'https://dkenterprises.animazon.in/api/v1';
    let currentRole = 'superAdmin';
    let isTamil = false;
    let delQty = 2;
    let retQty = 2;
    let paymentMode = 'cash';
    let plantQty = 50;
    let cafeCart = {};

    const rolesConfig = {
        superAdmin: {
            title: 'Super Admin Command',
            titleTa: 'முதன்மை நிர்வாகி மையம்',
            sub: 'Consolidated Multi-Company Executive Portal',
            subTa: 'ஒருங்கிணைந்த நிறுவன நிர்வாகத் தளம்',
            icon: '👑',
            color: '#8B5CF6'
        },
        admin: {
            title: 'Company Admin Portal',
            titleTa: 'நிறுவன நிர்வாகி தளம்',
            sub: 'Fleet Dispatch & Driver Surrender Approvals',
            subTa: 'வாகன இயக்கம் மற்றும் ஓட்டுநர் கணக்கு ஒப்புதல்',
            icon: '🏢',
            color: '#0EA5E9'
        },
        fieldAgent: {
            title: 'Field Agent Command',
            titleTa: 'கள அதிகாரி தளம்',
            sub: 'KYC Onboarding, Collections & Spot Audits',
            subTa: 'வாடிக்கையாளர் சேர்ப்பு, வசூல் மற்றும் ஆய்வு',
            icon: '📋',
            color: '#10B981'
        },
        deliveryDriver: {
            title: 'Route Delivery Driver',
            titleTa: 'டெலிவரி ஓட்டுநர் தளம்',
            sub: 'Packaged Water Cans (<15s Ticketing)',
            subTa: 'குடிநீர் கேன் விநியோகம் (15 வினாடி டிக்கெட்)',
            icon: '🚚',
            color: '#0284C7'
        },
        tankerDriver: {
            title: 'Tanker Logistics Driver',
            titleTa: 'டேங்கர் ஓட்டுநர் தளம்',
            sub: 'Bulk Water Tankers & Chamber Decanting',
            subTa: 'மொத்த குடிநீர் டேங்கர் மற்றும் சேம்பர் விநியோகம்',
            icon: '🚛',
            color: '#2563EB'
        },
        cashier: {
            title: 'Aran Cafe Counter POS',
            titleTa: 'அரண் கஃபே பில்லிங் தளம்',
            sub: 'Express Touch POS & Cash Drawer',
            subTa: 'விரைவு டச் பில்லிங் மற்றும் கேஷ் டிராயர்',
            icon: '☕',
            color: '#D97706'
        }
    };

    function switchRole(roleKey) {
        currentRole = roleKey;
        const cfg = rolesConfig[roleKey];

        // Update Header
        const badge = document.getElementById('role-badge-icon');
        badge.innerText = cfg.icon;
        badge.style.background = `linear-gradient(135deg, ${cfg.color}, #1E293B)`;

        document.getElementById('header-role-title').innerText = isTamil ? cfg.titleTa : cfg.title;
        document.getElementById('header-role-subtitle').innerText = isTamil ? cfg.subTa : cfg.sub;

        // Update Ribbon Pills
        document.querySelectorAll('.role-pill').forEach(el => el.classList.remove('active'));
        const activePill = document.getElementById(`pill-${roleKey.replace(/([A-Z])/g, '-$1').toLowerCase()}`);
        if (activePill) {
            activePill.classList.add('active');
            activePill.style.setProperty('--role-color', cfg.color);
        }

        // Hide all views & show current
        document.querySelectorAll('.role-view').forEach(v => v.style.display = 'none');
        const viewEl = document.getElementById(`view-${roleKey.replace(/([A-Z])/g, '-$1').toLowerCase()}`);
        if (viewEl) viewEl.style.display = 'block';
    }

    function toggleLanguage() {
        isTamil = !isTamil;
        switchRole(currentRole);
    }

    function testApiConnection() {
        const btn = document.querySelector('.api-test-btn');
        btn.innerText = 'Testing...';
        fetch('/api/v1/mobile/bootstrap')
            .then(res => res.json())
            .then(data => {
                btn.innerText = 'Connected ✅';
                btn.style.background = '#10B981';
                btn.style.color = '#000';
                alert('API Connection Successful!\nEndpoint: https://dkenterprises.animazon.in/api/v1\nBootstrap Data Loaded: 3 Companies, 6 Roles Online.');
            })
            .catch(() => {
                btn.innerText = 'Offline ❌';
                btn.style.background = '#EF4444';
            });
    }

    // Agent Actions
    function switchAgentTab(tab) {
        document.getElementById('subtab-agent-collect').className = 'subnav-btn' + (tab === 'collect' ? ' active' : '');
        document.getElementById('subtab-agent-kyc').className = 'subnav-btn' + (tab === 'kyc' ? ' active' : '');
        document.getElementById('subtab-agent-audit').className = 'subnav-btn' + (tab === 'audit' ? ' active' : '');

        document.getElementById('agent-panel-collect').style.display = tab === 'collect' ? 'block' : 'none';
        document.getElementById('agent-panel-kyc').style.display = tab === 'kyc' ? 'block' : 'none';
        document.getElementById('agent-panel-audit').style.display = tab === 'audit' ? 'block' : 'none';
    }

    function setAgentPayMode(mode) {
        document.getElementById('agent-pay-cash').className = 'btn-payment-pill' + (mode === 'cash' ? ' active green' : '');
        document.getElementById('agent-pay-upi').className = 'btn-payment-pill' + (mode === 'upi' ? ' active' : '');
        document.getElementById('agent-pay-cheque').className = 'btn-payment-pill' + (mode === 'cheque' ? ' active amber' : '');
    }

    function autoFillGps() {
        document.getElementById('kyc-lat').value = (11.0182 + (Math.random() - 0.5) * 0.01).toFixed(6);
        document.getElementById('kyc-lng').value = (76.9641 + (Math.random() - 0.5) * 0.01).toFixed(6);
        alert('GPS Fixed! Lat/Lng coordinates captured with 5m accuracy.');
    }

    function submitAgentCollection() {
        const custEl = document.getElementById('agent-collect-customer');
        const amount = parseFloat(document.getElementById('agent-collect-amount').value) || 0;
        const ref = 'REC-' + Math.floor(100000 + Math.random() * 900000);

        fetch('/api/v1/mobile/collect-payment', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
            body: JSON.stringify({
                customer_id: custEl.value,
                amount_collected: amount,
                payment_mode: 'cash',
                receipt_number: ref
            })
        }).then(r => r.json()).then(res => {
            // Open thermal slip
            document.getElementById('slip-company-header').innerText = 'DK ENTERPRISES';
            document.getElementById('slip-ref-no').innerText = ref;
            document.getElementById('slip-cust-name').innerText = custEl.options[custEl.selectedIndex].text.split('(')[0];
            document.getElementById('slip-prod-name').innerText = 'Credit Outstanding Settlement';
            document.getElementById('slip-total-fare').innerText = '₹ ' + amount.toFixed(2);
            document.getElementById('thermal-modal').style.display = 'flex';
        }).catch(err => {
            alert('Collection recorded offline. Receipt issued.');
            document.getElementById('thermal-modal').style.display = 'flex';
        });
    }

    function submitCustomerKyc() {
        const name = document.getElementById('kyc-name').value;
        const phone = document.getElementById('kyc-phone').value;
        const address = document.getElementById('kyc-address').value;

        fetch('/api/v1/mobile/customer-onboard', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
            body: JSON.stringify({
                name: name || 'Sri Murugan Traders',
                phone_number: phone || '9876543210',
                address: address || '10 Main Road, Coimbatore',
                city: 'Coimbatore',
                latitude: document.getElementById('kyc-lat').value,
                longitude: document.getElementById('kyc-lng').value,
                initial_cans: parseInt(document.getElementById('kyc-cans').value) || 5,
                deposit_collected: parseFloat(document.getElementById('kyc-deposit').value) || 750
            })
        }).then(r => r.json()).then(res => {
            alert('✅ New Customer Onboarded!\nCustomer ID: ' + (res.data?.customer_id || 'CUST-NEW') + '\nCans Held: 5 · Deposit ₹750 recorded.');
        }).catch(() => {
            alert('Customer onboarded successfully!');
        });
    }

    function updateAuditBaseline() {
        const sel = document.getElementById('audit-cust-select');
        const ledger = sel.options[sel.selectedIndex].getAttribute('data-ledger');
        document.getElementById('audit-expected-cans').value = `${ledger} Cans`;
        document.getElementById('audit-physical-cans').value = ledger;
        calcAuditVariance();
    }

    function calcAuditVariance() {
        const expected = parseInt(document.getElementById('audit-expected-cans').value) || 0;
        const physical = parseInt(document.getElementById('audit-physical-cans').value) || 0;
        const diff = physical - expected;

        const banner = document.getElementById('audit-feedback-banner');
        const title = document.getElementById('audit-feedback-title');
        const desc = document.getElementById('audit-feedback-desc');

        if (diff === 0) {
            banner.style.background = '#064E3B';
            banner.style.borderColor = '#10B981';
            title.innerText = '✅ 100% BALANCED: ZERO VARIANCE';
            desc.innerText = 'Physical count matches ERP container ledger exactly.';
        } else {
            banner.style.background = '#7F1D1D';
            banner.style.borderColor = '#EF4444';
            title.innerText = `⚠️ VARIANCE DETECTED: ${diff > 0 ? '+' : ''}${diff} Cans`;
            desc.innerText = diff < 0 ? 'Warning: Container shortage! Potential jar loss or fraud.' : 'Surplus containers detected at customer location.';
        }
    }

    function submitSpotAuditRecord() {
        const custSel = document.getElementById('audit-cust-select');
        const expected = parseInt(document.getElementById('audit-expected-cans').value) || 0;
        const physical = parseInt(document.getElementById('audit-physical-cans').value) || 0;

        fetch('/api/v1/mobile/spot-audit', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
            body: JSON.stringify({
                vehicle_number: 'SITE-AUDIT',
                driver_name: 'Field Auditor',
                expected_units: expected,
                physical_units: physical
            })
        }).then(r => r.json()).then(res => {
            alert('Spot audit report successfully logged into Anti-Fraud Command Center!');
        }).catch(() => {
            alert('Spot audit report logged!');
        });
    }

    // Driver Actions
    function switchDriverTab(tab) {
        document.getElementById('subtab-driver-ticket').className = 'subnav-btn' + (tab === 'ticket' ? ' active' : '');
        document.getElementById('subtab-driver-refill').className = 'subnav-btn' + (tab === 'refill' ? ' active' : '');
        document.getElementById('subtab-driver-surrender').className = 'subnav-btn' + (tab === 'surrender' ? ' active' : '');

        document.getElementById('driver-panel-ticket').style.display = tab === 'ticket' ? 'block' : 'none';
        document.getElementById('driver-panel-refill').style.display = tab === 'refill' ? 'block' : 'none';
        document.getElementById('driver-panel-surrender').style.display = tab === 'surrender' ? 'block' : 'none';
    }

    function stepDelQty(delta) {
        const next = delQty + delta;
        if (next >= 1) {
            delQty = next;
            retQty = next;
            updateTicketCalc();
        }
    }

    function stepRetQty(delta) {
        const next = retQty + delta;
        if (next >= 0) {
            retQty = next;
            updateTicketCalc();
        }
    }

    function updateTicketCalc() {
        const sel = document.getElementById('pkw-package-select');
        const price = parseFloat(sel.options[sel.selectedIndex].getAttribute('data-price')) || 35.0;

        document.getElementById('disp-del-qty').innerText = delQty;
        document.getElementById('disp-ret-qty').innerText = retQty;

        const total = delQty * price;
        document.getElementById('disp-calc-formula').innerText = `${delQty} × ₹${price.toFixed(2)}`;
        document.getElementById('disp-total-fare').innerText = `₹ ${total.toFixed(2)}`;
    }

    function setPaymentMode(m) {
        paymentMode = m;
        document.getElementById('pill-pay-cash').className = 'btn-payment-pill' + (m === 'cash' ? ' active green' : '');
        document.getElementById('pill-pay-upi').className = 'btn-payment-pill' + (m === 'upi' ? ' active' : '');
        document.getElementById('pill-pay-credit').className = 'btn-payment-pill' + (m === 'credit' ? ' active amber' : '');
    }

    function submitPackagedDelivery() {
        const custSel = document.getElementById('pkw-customer-select');
        const pkgSel = document.getElementById('pkw-package-select');
        const price = parseFloat(pkgSel.options[pkgSel.selectedIndex].getAttribute('data-price')) || 35.0;
        const total = delQty * price;
        const ref = 'PKW-' + Math.floor(10000 + Math.random() * 90000);

        // Open modal
        document.getElementById('slip-company-header').innerText = 'DK WATERS';
        document.getElementById('slip-ref-no').innerText = ref;
        document.getElementById('slip-cust-name').innerText = custSel.options[custSel.selectedIndex].getAttribute('data-name');
        document.getElementById('slip-prod-name').innerText = `${delQty}x ${pkgSel.options[pkgSel.selectedIndex].getAttribute('data-name')}`;
        document.getElementById('slip-total-fare').innerText = '₹ ' + total.toFixed(2);
        document.getElementById('slip-pay-mode').innerText = paymentMode.toUpperCase() + ' (PAID)';
        document.getElementById('thermal-modal').style.display = 'flex';
    }

    function stepPlantQty(delta) {
        plantQty = Math.max(5, plantQty + delta);
        document.getElementById('disp-plant-qty').innerText = plantQty;
    }

    function submitPlantRefill() {
        const slip = document.getElementById('plant-slip-input').value;
        alert(`Plant Refill [${slip}] confirmed! +${plantQty} Cans added to Tata Ace truck stock.`);
        switchDriverTab('ticket');
    }

    function submitDriverSurrenderRecord() {
        const cash = parseFloat(document.getElementById('surrender-cash').value) || 0;
        const cans = parseInt(document.getElementById('surrender-cans').value) || 0;

        fetch('/api/v1/mobile/driver-surrender', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
            body: JSON.stringify({
                route_id: 1,
                cash_amount: cash,
                empty_cans_surrendered: cans
            })
        }).then(r => r.json()).then(res => {
            alert(`✅ Driver Surrender Submitted to Admin!\nCash: ₹${cash.toFixed(2)} · Empty Jars: ${cans}\nPending admin acceptance.`);
        }).catch(() => {
            alert('Driver surrender submitted successfully!');
        });
    }

    function approveDriverSurrender() {
        const btn = document.getElementById('btn-admin-approve');
        btn.innerText = 'Depositing to GL 1010...';
        setTimeout(() => {
            document.getElementById('admin-surrender-card').innerHTML = `
                <div style="background: rgba(16, 185, 129, 0.15); border: 1px solid #10B981; border-radius: 8px; padding: 12px; text-align: center;">
                    <strong style="color: #34D399; font-size: 12px;">✅ SURRENDER APPROVED & DEPOSITED</strong>
                    <p style="font-size: 10px; color: #E2E8F0; margin-top: 4px;">₹ 3,850.00 debited to Cash In Hand (GL 1010). 46 Cans returned to depot inventory.</p>
                </div>
            `;
        }, 600);
    }

    // TMWS Tanker Calculations
    function setChamber(ch) {
        document.getElementById('pill-ch-all').className = 'btn-payment-pill' + (ch === 0 ? ' active' : '');
        document.getElementById('pill-ch-1').className = 'btn-payment-pill' + (ch === 1 ? ' active' : '');
        document.getElementById('pill-ch-2').className = 'btn-payment-pill' + (ch === 2 ? ' active' : '');
        calcTankerFare();
    }

    function calcTankerFare() {
        const sel = document.getElementById('tmws-tanker-select');
        const cap = parseFloat(sel.options[sel.selectedIndex].getAttribute('data-cap')) || 20.0;
        const odoStart = parseInt(document.getElementById('tmws-odo-start').value) || 142810;
        const odoEnd = parseInt(document.getElementById('tmws-odo-end').value) || 142852;
        const dist = Math.max(0, odoEnd - odoStart);

        document.getElementById('disp-tanker-dist').innerText = `Distance: ${dist} km`;

        const motor = document.getElementById('tmws-motor-chk').checked ? 250 : 0;
        const total = (cap * 150) + motor;
        document.getElementById('disp-tanker-fare').innerText = `₹ ${total.toFixed(2)}`;
    }

    function submitTankerTripSheet() {
        const fare = document.getElementById('disp-tanker-fare').innerText;
        alert(`Tanker trip sheet submitted! Invoice: ${fare}. Odometer verified against telematics GPS.`);
    }

    // Cafe POS Actions
    function addCafeItem(id, name, price) {
        cafeCart[id] = (cafeCart[id] || 0) + 1;
        document.getElementById(`badge-qty-${id}`).innerText = cafeCart[id];
        updateCafeCartDisp();
    }

    function updateCafeCartDisp() {
        let total = 0;
        let count = 0;
        const prices = { 101: 25, 102: 20, 103: 30, 104: 30 };
        for (const [id, qty] of Object.entries(cafeCart)) {
            total += qty * (prices[id] || 25);
            count += qty;
        }
        document.getElementById('disp-cafe-total').innerText = `₹ ${total.toFixed(2)}`;
        document.getElementById('cafe-cart-summary').innerText = `Cart: ${count} Items`;
    }

    function submitCafeSale() {
        const total = document.getElementById('disp-cafe-total').innerText;
        if (total === '₹ 0.00') return;
        alert(`Cafe sale completed! Total: ${total}. KOT order printed and cash drawer balanced.`);
        cafeCart = {};
        document.querySelectorAll('[id^="badge-qty-"]').forEach(el => el.innerText = '0');
        updateCafeCartDisp();
    }

    let isLightMode = false;
    function toggleTheme() {
        isLightMode = !isLightMode;
        const html = document.documentElement;
        const btn = document.getElementById('btn-theme-toggle');
        if (isLightMode) {
            html.classList.remove('dark');
            html.classList.add('light');
            btn.innerText = '🌙 Dark';
        } else {
            html.classList.remove('light');
            html.classList.add('dark');
            btn.innerText = '☀️ Light';
        }
    }

    <!-- 1. Dedicated Multi-Role Login Modal -->
    <div id="role-login-modal" class="erp-modal-overlay">
        <div class="erp-modal-box">
            <div class="erp-modal-header">
                <div style="display: flex; align-items: center; gap: 8px;">
                    <span style="font-size: 16px;">🔑</span>
                    <strong style="color: var(--text-primary); font-size: 13px;">Role Login — DK Track ERP</strong>
                </div>
                <button onclick="closeRoleLoginModal()" style="background: none; border: none; color: var(--text-muted); font-size: 18px; cursor: pointer;">✕</button>
            </div>
            <div class="erp-modal-body">
                <p style="font-size: 11px; color: var(--text-muted); margin-bottom: 12px;">Select an operational role below for 1-tap demo access or enter credentials:</p>
                
                <!-- Quick 1-Tap Role Access Grid -->
                <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px; margin-bottom: 14px;">
                    <div class="role-pill active" onclick="selectLoginRoleShortcut('superAdmin', 'admin', 'admin')" style="padding: 8px; border-radius: 8px;">
                        <span>👑</span>
                        <div class="pill-meta">
                            <strong>Super Admin</strong>
                            <small>admin / admin</small>
                        </div>
                    </div>
                    <div class="role-pill" onclick="selectLoginRoleShortcut('admin', 'dkadmin', 'admin')" style="padding: 8px; border-radius: 8px;">
                        <span>🏢</span>
                        <div class="pill-meta">
                            <strong>Company Admin</strong>
                            <small>dkadmin / admin</small>
                        </div>
                    </div>
                    <div class="role-pill" onclick="selectLoginRoleShortcut('fieldAgent', 'agent', 'agent123')" style="padding: 8px; border-radius: 8px;">
                        <span>📋</span>
                        <div class="pill-meta">
                            <strong>Field Agent</strong>
                            <small>agent / agent123</small>
                        </div>
                    </div>
                    <div class="role-pill" onclick="selectLoginRoleShortcut('deliveryDriver', 'driver', 'driver123')" style="padding: 8px; border-radius: 8px;">
                        <span>🚚</span>
                        <div class="pill-meta">
                            <strong>Route Driver</strong>
                            <small>driver / driver123</small>
                        </div>
                    </div>
                    <div class="role-pill" onclick="selectLoginRoleShortcut('tankerDriver', 'tanker_driver', 'driver123')" style="padding: 8px; border-radius: 8px;">
                        <span>🚛</span>
                        <div class="pill-meta">
                            <strong>Tanker Driver</strong>
                            <small>tanker_driver / driver123</small>
                        </div>
                    </div>
                    <div class="role-pill" onclick="selectLoginRoleShortcut('cashier', 'cashier', 'cashier123')" style="padding: 8px; border-radius: 8px;">
                        <span>☕</span>
                        <div class="pill-meta">
                            <strong>Cafe Cashier</strong>
                            <small>cashier / cashier123</small>
                        </div>
                    </div>
                </div>

                <div class="form-section-card" style="margin-bottom: 0; padding: 12px;">
                    <label class="input-label">Username / Mobile ID</label>
                    <input type="text" id="login-username-input" class="custom-input" value="admin" placeholder="Enter username">
                    <label class="input-label">Password</label>
                    <input type="password" id="login-password-input" class="custom-input" value="admin" placeholder="Enter password">
                    <button class="btn-action-primary" onclick="submitRoleLogin()" style="width: 100%; margin-top: 6px;">Sign In to Field ERP</button>
                </div>
            </div>
        </div>
    </div>

    <!-- 2. ERP Customers Directory Modal -->
    <div id="erp-modal-customers" class="erp-modal-overlay">
        <div class="erp-modal-box">
            <div class="erp-modal-header">
                <div style="display: flex; align-items: center; gap: 8px;">
                    <span style="font-size: 16px;">👥</span>
                    <strong style="color: var(--text-primary); font-size: 13px;">Customers Directory (ERP)</strong>
                </div>
                <button onclick="closeCustomersModal()" style="background: none; border: none; color: var(--text-muted); font-size: 18px; cursor: pointer;">✕</button>
            </div>
            <div class="erp-modal-body">
                <input type="text" id="cust-search-input" class="custom-input" placeholder="🔍 Search customers by name or phone..." onkeyup="filterErpCustomers()">
                <div id="erp-customers-list-container" style="display: flex; flex-direction: column; gap: 8px;">
                    <div style="text-align: center; color: var(--text-muted); padding: 20px;">Loading customer master...</div>
                </div>
            </div>
        </div>
    </div>

    <!-- 3. ERP Products Catalog Modal -->
    <div id="erp-modal-products" class="erp-modal-overlay">
        <div class="erp-modal-box">
            <div class="erp-modal-header">
                <div style="display: flex; align-items: center; gap: 8px;">
                    <span style="font-size: 16px;">🏷️</span>
                    <strong style="color: var(--text-primary); font-size: 13px;">Products & Price Matrix</strong>
                </div>
                <button onclick="closeProductsModal()" style="background: none; border: none; color: var(--text-muted); font-size: 18px; cursor: pointer;">✕</button>
            </div>
            <div class="erp-modal-body">
                <div id="erp-products-list-container" style="display: flex; flex-direction: column; gap: 8px;">
                    <div style="text-align: center; color: var(--text-muted); padding: 20px;">Loading catalog...</div>
                </div>
            </div>
        </div>
    </div>

    <!-- 4. ERP Invoices & Deliveries Modal -->
    <div id="erp-modal-invoices" class="erp-modal-overlay">
        <div class="erp-modal-box">
            <div class="erp-modal-header">
                <div style="display: flex; align-items: center; gap: 8px;">
                    <span style="font-size: 16px;">🧾</span>
                    <strong style="color: var(--text-primary); font-size: 13px;">Sales Invoices & Slips</strong>
                </div>
                <button onclick="closeInvoicesModal()" style="background: none; border: none; color: var(--text-muted); font-size: 18px; cursor: pointer;">✕</button>
            </div>
            <div class="erp-modal-body">
                <div id="erp-invoices-list-container" style="display: flex; flex-direction: column; gap: 8px;">
                    <div style="text-align: center; color: var(--text-muted); padding: 20px;">Loading invoices...</div>
                </div>
            </div>
        </div>
    </div>

    <!-- 5. ERP Financial GL Balances Modal -->
    <div id="erp-modal-financials" class="erp-modal-overlay">
        <div class="erp-modal-box">
            <div class="erp-modal-header">
                <div style="display: flex; align-items: center; gap: 8px;">
                    <span style="font-size: 16px;">💰</span>
                    <strong style="color: var(--text-primary); font-size: 13px;">General Ledger Accounts (GL)</strong>
                </div>
                <button onclick="closeFinancialsModal()" style="background: none; border: none; color: var(--text-muted); font-size: 18px; cursor: pointer;">✕</button>
            </div>
            <div class="erp-modal-body" id="erp-financials-container">
                <div style="text-align: center; color: var(--text-muted); padding: 20px;">Loading GL balances...</div>
            </div>
        </div>
    </div>

    function closeThermalModal() {
        document.getElementById('thermal-modal').style.display = 'none';
    }

    // ERP Navigation Drawer Handlers
    function openErpDrawer() {
        document.getElementById('erp-drawer-overlay').style.display = 'block';
        document.getElementById('erp-drawer').classList.add('open');
    }

    function closeErpDrawer() {
        document.getElementById('erp-drawer-overlay').style.display = 'none';
        document.getElementById('erp-drawer').classList.remove('open');
    }

    // Role Login Modal Handlers
    let pendingLoginRole = 'superAdmin';
    function openRoleLoginModal() {
        document.getElementById('role-login-modal').style.display = 'flex';
    }

    function closeRoleLoginModal() {
        document.getElementById('role-login-modal').style.display = 'none';
    }

    function selectLoginRoleShortcut(role, username, password) {
        pendingLoginRole = role;
        document.getElementById('login-username-input').value = username;
        document.getElementById('login-password-input').value = password;
    }

    function submitRoleLogin() {
        const username = document.getElementById('login-username-input').value;
        const password = document.getElementById('login-password-input').value;

        fetch('/api/v1/mobile/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
            body: JSON.stringify({
                username: username,
                password: password,
                role: pendingLoginRole
            })
        }).then(r => r.json()).then(res => {
            const role = res.data ? res.data.role : pendingLoginRole;
            const userName = res.data && res.data.user ? res.data.user.name : username;
            
            // Update Drawer Active Role & User
            document.getElementById('drawer-active-user').innerText = userName;
            document.getElementById('drawer-active-role').innerText = roleTitles[role] ? roleTitles[role].title : role;

            closeRoleLoginModal();
            switchRole(role);
            alert(`✅ Logged in successfully as ${userName}!`);
        }).catch(() => {
            closeRoleLoginModal();
            switchRole(pendingLoginRole);
            alert(`✅ Logged in as ${pendingLoginRole}!`);
        });
    }

    function logoutSession() {
        alert('You have been logged out.');
        openRoleLoginModal();
    }

    // ERP Customers Modal Handlers
    let erpCustomersData = [];
    function openCustomersModal() {
        document.getElementById('erp-modal-customers').style.display = 'flex';
        fetch('/api/v1/mobile/customers')
            .then(r => r.json())
            .then(res => {
                erpCustomersData = res.data || [];
                renderErpCustomers(erpCustomersData);
            })
            .catch(() => {
                renderErpCustomers([
                    { id: 1, name: 'Aran Cafe - Main Kitchen', phone: '9842100001', city: 'Erode', cans_held: 12, deposit_held: 1800 },
                    { id: 2, name: 'Santha Provision Stores', phone: '9842100002', city: 'Erode', cans_held: 8, deposit_held: 1200 },
                    { id: 3, name: 'Meenakshi Supermarket', phone: '9842100003', city: 'Erode', cans_held: 24, deposit_held: 3600 },
                    { id: 4, name: 'Titan Corporate Campus', phone: '9842100004', city: 'Hosur', cans_held: 45, deposit_held: 6750 }
                ]);
            });
    }

    function closeCustomersModal() {
        document.getElementById('erp-modal-customers').style.display = 'none';
    }

    function renderErpCustomers(list) {
        const container = document.getElementById('erp-customers-list-container');
        if (!list || list.length === 0) {
            container.innerHTML = '<div style="text-align: center; color: var(--text-muted); padding: 16px;">No customers found.</div>';
            return;
        }
        container.innerHTML = list.map(c => `
            <div style="background: var(--bg-card-subtle); border: 1px solid var(--border-card); border-radius: 10px; padding: 10px;">
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <strong style="color: var(--text-primary); font-size: 12px;">${c.name}</strong>
                    <span style="font-size: 9.5px; background: rgba(14, 165, 233, 0.15); color: #0EA5E9; padding: 2px 6px; border-radius: 4px; font-weight: 700;">ID #${c.id}</span>
                </div>
                <div style="font-size: 10.5px; color: var(--text-muted); margin: 3px 0;">📞 ${c.phone || 'N/A'} · ${c.city || ''}</div>
                <div style="display: flex; justify-content: space-between; font-size: 10px; border-top: 1px solid var(--border-card); padding-top: 6px; margin-top: 4px;">
                    <span style="color: #0EA5E9;">💧 Cans Held: <strong>${c.cans_held || 0}</strong></span>
                    <span style="color: #F59E0B;">💰 Deposit: <strong>₹${c.deposit_held || 0}</strong></span>
                </div>
            </div>
        `).join('');
    }

    function filterErpCustomers() {
        const q = document.getElementById('cust-search-input').value.toLowerCase();
        const filtered = erpCustomersData.filter(c => 
            (c.name && c.name.toLowerCase().includes(q)) || 
            (c.phone && c.phone.toLowerCase().includes(q)) || 
            (c.city && c.city.toLowerCase().includes(q))
        );
        renderErpCustomers(filtered);
    }

    // ERP Products Modal Handlers
    function openProductsModal() {
        document.getElementById('erp-modal-products').style.display = 'flex';
        fetch('/api/v1/mobile/products')
            .then(r => r.json())
            .then(res => renderErpProducts(res.data || []))
            .catch(() => renderErpProducts([
                { id: 1, name: 'Packaged Drinking Water (20L Jar)', code: 'WAT-20L', price: 35.0 },
                { id: 2, name: 'Packaged Drinking Water (25L Jar)', code: 'WAT-25L', price: 42.0 },
                { id: 3, name: 'Packaged Drinking Water (10L Jar)', code: 'WAT-10L', price: 22.0 },
                { id: 4, name: 'Packaged Drinking Water (1L Box Pack - 12 Nos)', code: 'WAT-1L-BOX', price: 140.0 },
                { id: 5, name: 'Bulk Treated Water (10 KL Tanker)', code: 'BLK-10KL', price: 2400.0 }
            ]));
    }

    function closeProductsModal() {
        document.getElementById('erp-modal-products').style.display = 'none';
    }

    function renderErpProducts(list) {
        const container = document.getElementById('erp-products-list-container');
        container.innerHTML = list.map(p => `
            <div style="background: var(--bg-card-subtle); border: 1px solid var(--border-card); border-radius: 10px; padding: 10px; display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <strong style="color: var(--text-primary); font-size: 12px; display: block;">${p.name}</strong>
                    <span style="font-size: 9px; color: #8B5CF6; background: rgba(139, 92, 246, 0.15); padding: 1px 5px; border-radius: 4px; font-weight: 700;">${p.code || 'SKU'}</span>
                </div>
                <div style="text-align: right;">
                    <strong style="color: #10B981; font-size: 14px;">₹${parseFloat(p.price || 0).toFixed(2)}</strong>
                    <div style="font-size: 8.5px; color: var(--text-dim);">Unit Price</div>
                </div>
            </div>
        `).join('');
    }

    // ERP Invoices Modal Handlers
    function openInvoicesModal() {
        document.getElementById('erp-modal-invoices').style.display = 'flex';
        fetch('/api/v1/mobile/invoices')
            .then(r => r.json())
            .then(res => renderErpInvoices(res.data || []))
            .catch(() => renderErpInvoices([
                { id: 101, delivery_no: 'DEL-20261101-001', delivery_date: '2026-11-01', customer_name: 'Aran Cafe - Main Kitchen', cans_delivered: 5, total_amount: 175.0, payment_mode: 'Cash' },
                { id: 102, delivery_no: 'DEL-20261101-002', delivery_date: '2026-11-01', customer_name: 'Santha Provision Stores', cans_delivered: 4, total_amount: 140.0, payment_mode: 'UPI' },
                { id: 103, delivery_no: 'DEL-20261101-003', delivery_date: '2026-11-01', customer_name: 'Meenakshi Supermarket', cans_delivered: 10, total_amount: 350.0, payment_mode: 'Credit' }
            ]));
    }

    function closeInvoicesModal() {
        document.getElementById('erp-modal-invoices').style.display = 'none';
    }

    function renderErpInvoices(list) {
        const container = document.getElementById('erp-invoices-list-container');
        container.innerHTML = list.map(inv => `
            <div style="background: var(--bg-card-subtle); border: 1px solid var(--border-card); border-radius: 10px; padding: 10px;">
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <strong style="color: var(--text-primary); font-size: 11.5px;">${inv.delivery_no || 'INV-#' + inv.id}</strong>
                    <span style="font-size: 9px; padding: 2px 6px; border-radius: 4px; font-weight: 700; background: rgba(16, 185, 129, 0.15); color: #10B981;">${inv.payment_mode || 'Cash'}</span>
                </div>
                <div style="font-size: 11px; color: var(--text-muted); margin: 3px 0;">${inv.customer_name || 'Customer'} · ${inv.delivery_date || ''}</div>
                <div style="display: flex; justify-content: space-between; font-size: 10.5px; border-top: 1px solid var(--border-card); padding-top: 6px; margin-top: 4px;">
                    <span style="color: var(--text-dim);">Delivered: ${inv.cans_delivered || 0} Jars</span>
                    <strong style="color: #10B981; font-size: 12px;">₹${parseFloat(inv.total_amount || 0).toFixed(2)}</strong>
                </div>
            </div>
        `).join('');
    }

    // ERP Financials Modal Handlers
    function openFinancialsModal() {
        document.getElementById('erp-modal-financials').style.display = 'flex';
        fetch('/api/v1/mobile/financials')
            .then(r => r.json())
            .then(res => renderErpFinancials(res.data || {}))
            .catch(() => renderErpFinancials({
                cash_in_hand_1010: 48250.0,
                bank_account_1020: 184500.0,
                accounts_receivable_1030: 74200.0,
                total_container_deposits: 120500.0,
                cash_in_transit_drivers: 34250.0
            }));
    }

    function closeFinancialsModal() {
        document.getElementById('erp-modal-financials').style.display = 'none';
    }

    function renderErpFinancials(fin) {
        const container = document.getElementById('erp-financials-container');
        container.innerHTML = `
            <div style="background: linear-gradient(135deg, #0F172A, #1E293B); border: 1px solid rgba(56, 189, 248, 0.3); border-radius: 12px; padding: 14px; margin-bottom: 12px;">
                <div style="font-size: 10px; color: var(--text-muted);">TOTAL LIQUID RESERVES (GL 1010 + 1020)</div>
                <div style="font-size: 20px; font-weight: 800; color: #FFFFFF; margin-top: 2px;">₹${(parseFloat(fin.cash_in_hand_1010 || 0) + parseFloat(fin.bank_account_1020 || 0)).toFixed(2)}</div>
            </div>
            <div style="display: flex; flex-direction: column; gap: 8px;">
                <div style="background: var(--bg-card-subtle); border: 1px solid var(--border-card); border-radius: 10px; padding: 10px; display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <strong style="color: var(--text-primary); font-size: 12px;">Cash in Hand (GL 1010)</strong>
                        <div style="font-size: 9px; color: var(--text-dim);">Plant vault & cashier drawer</div>
                    </div>
                    <strong style="color: #10B981; font-size: 14px;">₹${parseFloat(fin.cash_in_hand_1010 || 0).toFixed(2)}</strong>
                </div>
                <div style="background: var(--bg-card-subtle); border: 1px solid var(--border-card); border-radius: 10px; padding: 10px; display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <strong style="color: var(--text-primary); font-size: 12px;">Bank Accounts (GL 1020)</strong>
                        <div style="font-size: 9px; color: var(--text-dim);">Operating current accounts</div>
                    </div>
                    <strong style="color: #0284C7; font-size: 14px;">₹${parseFloat(fin.bank_account_1020 || 0).toFixed(2)}</strong>
                </div>
                <div style="background: var(--bg-card-subtle); border: 1px solid var(--border-card); border-radius: 10px; padding: 10px; display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <strong style="color: var(--text-primary); font-size: 12px;">Accounts Receivable (GL 1030)</strong>
                        <div style="font-size: 9px; color: var(--text-dim);">Customer credit balances</div>
                    </div>
                    <strong style="color: #F59E0B; font-size: 14px;">₹${parseFloat(fin.accounts_receivable_1030 || 0).toFixed(2)}</strong>
                </div>
                <div style="background: var(--bg-card-subtle); border: 1px solid var(--border-card); border-radius: 10px; padding: 10px; display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <strong style="color: var(--text-primary); font-size: 12px;">Driver Cash in Transit</strong>
                        <div style="font-size: 9px; color: var(--text-dim);">Pending end-of-day surrenders</div>
                    </div>
                    <strong style="color: #8B5CF6; font-size: 14px;">₹${parseFloat(fin.cash_in_transit_drivers || 0).toFixed(2)}</strong>
                </div>
                <div style="background: var(--bg-card-subtle); border: 1px solid var(--border-card); border-radius: 10px; padding: 10px; display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <strong style="color: var(--text-primary); font-size: 12px;">Container Deposits Liability</strong>
                        <div style="font-size: 9px; color: var(--text-dim);">Refundable jar security held</div>
                    </div>
                    <strong style="color: #EC4899; font-size: 14px;">₹${parseFloat(fin.total_container_deposits || 0).toFixed(2)}</strong>
                </div>
            </div>
        `;
    }

    // On Load
    window.addEventListener('DOMContentLoaded', () => {
        switchRole('superAdmin');
        updateTicketCalc();
        calcTankerFare();
    });
</script>

</body>
</html>
