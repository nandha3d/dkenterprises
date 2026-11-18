@extends('backend.layout.main')

@section('content')
@php
    $posProducts = $bootstrap['products'] ?? [];
    $posCategories = $bootstrap['categories'] ?? [];
    $posTables = $bootstrap['tables'] ?? [];
    $posCustomers = $bootstrap['customers'] ?? [];
    $posWarehouses = $bootstrap['warehouses'] ?? [];
    $activeShift = $bootstrap['active_shift'] ?? null;
    $heldCount = (int) ($bootstrap['held_orders_count'] ?? 0);
    $activeWarehouseId = $bootstrap['active_warehouse_id'] ?? ($warehouses->first()->id ?? 1);
    $defaultCustomerId = $bootstrap['default_customer_id'] ?? ($posCustomers[0]['id'] ?? 1);
    $posPriceTiers = [];
    foreach (($bootstrap['price_tiers'] ?? []) as $tKey => $tVal) {
        if (is_array($tVal) && isset($tVal['code'])) {
            $posPriceTiers[$tVal['code']] = (float) ($tVal['multiplier'] ?? 1.0);
        } elseif (is_string($tKey) && is_numeric($tVal)) {
            $posPriceTiers[$tKey] = (float) $tVal;
        }
    }
    if (empty($posPriceTiers)) {
        $posPriceTiers = [
            'Retail MRP' => 1.0,
            'Wholesale' => 0.88,
            'Staff Rate' => 0.60,
            'Online Aggregator' => 1.15,
        ];
    }
@endphp

@push('css')
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@500;600;700;800&display=swap" rel="stylesheet">
@endpush

<style>
    :root {
        --cafe-canvas: #FBF4EA;
        --cafe-surface: #FFFFFF;
        --cafe-surface-tonal: #F3E9DC;
        --cafe-ink: #2B1B14;
        --cafe-muted: #6E5D53;
        --cafe-primary: #C2542D;
        --cafe-action: #F4A62A;
        --cafe-mint: #1FA971;
        --cafe-coral: #E8505B;
        --cafe-hairline: #E6D8C8;
    }

    .stitch-pos-shell {
        font-family: 'Manrope', -apple-system, BlinkMacSystemFont, sans-serif;
        background: var(--cafe-canvas);
        color: var(--cafe-ink);
        min-height: calc(100vh - 64px);
        padding: 16px;
    }

    .stitch-pos-grid {
        display: grid;
        grid-template-columns: minmax(0, 1.7fr) minmax(340px, 1fr);
        gap: 16px;
        align-items: start;
    }

    @media (max-width: 991px) {
        .stitch-pos-grid {
            grid-template-columns: 1fr;
        }
    }

    .stitch-card {
        background: var(--cafe-surface);
        border-radius: 20px;
        border: 1px solid var(--cafe-hairline);
        box-shadow: 0 4px 16px rgba(43, 27, 20, 0.04);
    }

    .stitch-header-bar {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        padding: 14px 18px;
        margin-bottom: 14px;
    }

    .stitch-badge-mint {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 5px 12px;
        border-radius: 999px;
        background: rgba(31, 169, 113, 0.12);
        color: var(--cafe-mint);
        font-size: 12px;
        font-weight: 700;
    }

    .stitch-badge-honey {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 5px 12px;
        border-radius: 999px;
        background: rgba(244, 166, 42, 0.18);
        color: #9A5B00;
        font-size: 12px;
        font-weight: 700;
    }

    .stitch-segmented {
        display: flex;
        background: var(--cafe-surface-tonal);
        padding: 4px;
        border-radius: 999px;
        gap: 4px;
    }

    .stitch-seg-btn {
        flex: 1;
        border: none;
        background: transparent;
        color: var(--cafe-muted);
        font-weight: 700;
        font-size: 13px;
        padding: 8px 14px;
        border-radius: 999px;
        cursor: pointer;
        transition: all 0.16s ease;
    }

    .stitch-seg-btn.active {
        background: var(--cafe-primary);
        color: #FFFFFF;
        box-shadow: 0 2px 8px rgba(194, 84, 45, 0.25);
    }

    .stitch-cat-strip {
        display: flex;
        gap: 8px;
        overflow-x: auto;
        padding-bottom: 6px;
        scrollbar-width: none;
    }
    .stitch-cat-strip::-webkit-scrollbar { display: none; }

    .stitch-cat-pill {
        border: 1px solid var(--cafe-hairline);
        background: var(--cafe-surface);
        color: var(--cafe-ink);
        padding: 8px 16px;
        border-radius: 999px;
        font-size: 13px;
        font-weight: 700;
        white-space: nowrap;
        cursor: pointer;
        transition: all 0.15s ease;
    }

    .stitch-cat-pill.active {
        background: var(--cafe-primary);
        color: #FFFFFF;
        border-color: var(--cafe-primary);
    }

    .stitch-rush-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(210px, 1fr));
        gap: 10px;
    }

    .stitch-rush-card {
        background: linear-gradient(135deg, #FFFDF9 0%, #FBF1E3 100%);
        border: 1.5px solid rgba(194, 84, 45, 0.22);
        border-radius: 16px;
        padding: 12px 14px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 10px;
        cursor: pointer;
        transition: transform 0.12s ease, border-color 0.12s ease;
    }
    .stitch-rush-card:hover {
        transform: translateY(-1px);
        border-color: var(--cafe-primary);
    }

    .stitch-menu-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(175px, 1fr));
        gap: 12px;
        max-height: calc(100vh - 330px);
        overflow-y: auto;
        padding-right: 4px;
    }

    .stitch-product-card {
        background: var(--cafe-surface);
        border: 1.5px solid var(--cafe-hairline);
        border-radius: 18px;
        padding: 14px;
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        min-height: 142px;
        cursor: pointer;
        transition: all 0.14s ease;
        position: relative;
    }

    .stitch-product-card:hover {
        border-color: var(--cafe-primary);
        box-shadow: 0 6px 16px rgba(194, 84, 45, 0.08);
    }

    .stitch-product-card.in-cart {
        border-color: var(--cafe-primary);
        border-width: 2px;
        background: #FFFDFB;
    }

    .stitch-product-card.sold-out {
        opacity: 0.58;
        background: #F5EFE8;
    }

    .stitch-stepper {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        background: var(--cafe-surface-tonal);
        border-radius: 999px;
        padding: 3px 6px;
    }

    .stitch-step-btn {
        width: 26px;
        height: 26px;
        border-radius: 50%;
        border: none;
        background: var(--cafe-surface);
        color: var(--cafe-primary);
        font-weight: 800;
        font-size: 15px;
        line-height: 1;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        justify-content: center;
    }

    .stitch-step-btn.plus {
        background: var(--cafe-primary);
        color: #FFFFFF;
    }

    .stitch-cart-panel {
        position: sticky;
        top: 16px;
        display: flex;
        flex-direction: column;
        max-height: calc(100vh - 96px);
    }

    .stitch-cart-items {
        flex: 1;
        overflow-y: auto;
        max-height: 340px;
        padding: 12px 16px;
    }

    .stitch-cart-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 10px;
        padding: 10px 0;
        border-bottom: 1px dashed var(--cafe-hairline);
    }

    .stitch-pay-btn {
        background: var(--cafe-action);
        color: var(--cafe-ink);
        border: none;
        border-radius: 999px;
        height: 52px;
        font-weight: 800;
        font-size: 16px;
        width: 100%;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
        box-shadow: 0 6px 18px rgba(244, 166, 42, 0.32);
        transition: transform 0.12s ease;
    }
    .stitch-pay-btn:active {
        transform: scale(0.99);
    }
    .stitch-pay-btn:disabled {
        opacity: 0.55;
        cursor: not-allowed;
    }
</style>

<div class="stitch-pos-shell">
    <!-- Top Header Strip (Stitch C-02 Chai & Crema) -->
    <div class="stitch-card stitch-header-bar">
        <div class="d-flex align-items-center" style="gap: 12px;">
            <div style="width:44px;height:44px;border-radius:14px;background:var(--cafe-primary);color:#fff;display:flex;align-items:center;justify-content:center;font-weight:800;font-size:18px;">
                <i class="fa fa-coffee"></i>
            </div>
            <div>
                <div class="d-flex align-items-center" style="gap: 8px;">
                    <h4 style="margin:0;font-weight:800;font-size:19px;color:var(--cafe-ink);">Counter POS Terminal</h4>
                    <span class="stitch-badge-mint">
                        <i class="fa fa-check-circle"></i> Live ERP Connected
                    </span>
                </div>
                <div style="font-size:12px;color:var(--cafe-muted);font-weight:600;margin-top:2px;">
                    {{ $companyName }} &bull;
                    <span id="pos-shift-badge">
                        @if($activeShift)
                            Shift #{{ $activeShift['id'] }} Open (Float ₹{{ number_format((float)($activeShift['cash_in_hand'] ?? 0), 0) }})
                        @else
                            No Open Drawer Shift
                        @endif
                    </span>
                    &bull; <span id="pos-held-badge">{{ $heldCount }} Held</span>
                </div>
            </div>
        </div>

        <div class="d-flex align-items-center flex-wrap" style="gap: 8px;">
            <button type="button" class="btn btn-sm" style="background:var(--cafe-surface-tonal);color:var(--cafe-ink);border-radius:999px;font-weight:700;padding:7px 14px;" onclick="openPrintStudioModal('80mm')">
                <i class="fa fa-qrcode"></i> Print &amp; Label Studio
            </button>
            <button type="button" class="btn btn-sm" style="background:var(--cafe-surface-tonal);color:var(--cafe-ink);border-radius:999px;font-weight:700;padding:7px 14px;" onclick="openShiftModal()">
                <i class="fa fa-calculator"></i>
                <span id="btn-shift-label">{{ $activeShift ? 'Shift / X-Z Drawer' : 'Open Drawer Shift' }}</span>
            </button>
            <button type="button" class="btn btn-sm" style="background:var(--cafe-surface-tonal);color:var(--cafe-ink);border-radius:999px;font-weight:700;padding:7px 14px;" onclick="loadHeldOrdersModal()">
                <i class="fa fa-pause-circle"></i> Held &amp; Recent Bills
            </button>
            <a href="{{ route('cafe.index') }}" class="btn btn-sm" style="background:var(--cafe-ink);color:#fff;border-radius:999px;font-weight:700;padding:7px 14px;">
                <i class="fa fa-columns"></i> Kitchen &amp; Ops Hub
            </a>
        </div>
    </div>

    <!-- Tablet / Desktop 2-Pane Split Layout -->
    <div class="stitch-pos-grid">
        <!-- LEFT PANE: Order Controls, Rush Hour Strip & Menu Catalog -->
        <div class="d-flex flex-column" style="gap: 12px;">
            <!-- Order Type + Customer + Table + Search Bar -->
            <div class="stitch-card" style="padding: 14px;">
                <div class="row align-items-center" style="row-gap: 10px;">
                    <div class="col-lg-5 col-md-12">
                        <div class="stitch-segmented" id="order-type-group">
                            <button type="button" class="stitch-seg-btn active" data-type="dine_in" onclick="setOrderType('dine_in', this)">Dine-In</button>
                            <button type="button" class="stitch-seg-btn" data-type="takeaway" onclick="setOrderType('takeaway', this)">Takeaway</button>
                            <button type="button" class="stitch-seg-btn" data-type="delivery" onclick="setOrderType('delivery', this)">Delivery</button>
                        </div>
                    </div>
                    <div class="col-lg-3 col-md-6">
                        <select id="pos-customer-select" class="form-control" style="border-radius:12px;border-color:var(--cafe-hairline);font-weight:600;font-size:13px;height:40px;" onchange="recalculateTotals()">
                            @forelse($posCustomers as $cust)
                                <option value="{{ $cust['id'] }}"
                                    data-credit-limit="{{ (float)($cust['credit_limit'] ?? 0) }}"
                                    data-due-amount="{{ (float)($cust['due_amount'] ?? 0) }}"
                                    {{ $cust['id'] == $defaultCustomerId ? 'selected' : '' }}>
                                    &#128100; {{ $cust['name'] }}
                                </option>
                            @empty
                                <option value="1" data-credit-limit="0" data-due-amount="0">&#128100; Walk-in Customer</option>
                            @endforelse
                        </select>
                    </div>
                    <div class="col-lg-4 col-md-6">
                        <select id="pos-table-select" class="form-control" style="border-radius:12px;border-color:var(--cafe-hairline);font-weight:600;font-size:13px;height:40px;">
                            <option value="">&#127869; Counter / No Table</option>
                            @foreach($posTables as $tbl)
                                <option value="{{ $tbl['id'] }}">
                                    {{ $tbl['name'] }} ({{ $tbl['floor'] ?? 'Main Hall' }} &bull; {{ $tbl['is_occupied'] ? 'Occupied' : $tbl['seats'].' seats' }})
                                </option>
                            @endforeach
                        </select>
                    </div>
                </div>

                <!-- Rate Slab Selector + Fast Bill vs KOT First (SensiblePOS Parity) -->
                <div class="d-flex align-items-center justify-content-between flex-wrap mt-2 pt-2" style="gap: 8px; border-top: 1px dashed var(--cafe-hairline);">
                    <div class="d-flex align-items-center flex-wrap" id="price-tier-group" style="gap: 6px;">
                        <span style="font-size:11px;font-weight:800;color:var(--cafe-muted);letter-spacing:0.04em;">RATE SLAB:</span>
                        @foreach($posPriceTiers as $tierName => $tierMult)
                            <button type="button"
                                class="stitch-cat-pill {{ $tierName === 'Retail MRP' ? 'active' : '' }}"
                                style="padding:4px 12px;font-size:12px;"
                                data-tier="{{ $tierName }}"
                                onclick="setPriceTier('{{ $tierName }}', this)">
                                {{ $tierName }}
                            </button>
                        @endforeach
                    </div>
                    <button type="button" id="btn-billing-mode" class="btn btn-sm" style="background:var(--cafe-surface-tonal);border:1px solid var(--cafe-hairline);border-radius:999px;font-weight:800;font-size:12px;padding:4px 12px;color:var(--cafe-ink);" onclick="toggleKotFirstMode()">
                        <i class="fa fa-bolt" id="billing-mode-icon"></i> <span id="billing-mode-label">Mode: Fast Bill</span>
                    </button>
                </div>

                <!-- Search + Barcode + Warehouse -->
                <div class="row mt-2" style="row-gap: 8px;">
                    <div class="col-md-8">
                        <div class="input-group">
                            <div class="input-group-prepend">
                                <span class="input-group-text" style="background:var(--cafe-surface-tonal);border-color:var(--cafe-hairline);border-radius:12px 0 0 12px;">
                                    <i class="fa fa-search" style="color:var(--cafe-primary);"></i>
                                </span>
                            </div>
                            <input type="text" id="pos-search-input" class="form-control" placeholder="Search menu items, SKU code, or scan barcode + Enter..." style="border-color:var(--cafe-hairline);border-radius:0 12px 12px 0;font-weight:600;height:40px;" oninput="renderCatalog()" onkeydown="handleSearchEnter(event)">
                        </div>
                    </div>
                    <div class="col-md-4">
                        <select id="pos-warehouse-select" class="form-control" style="border-radius:12px;border-color:var(--cafe-hairline);font-weight:600;font-size:13px;height:40px;">
                            @foreach($warehouses as $wh)
                                <option value="{{ $wh->id }}" {{ $wh->id == $activeWarehouseId ? 'selected' : '' }}>
                                    &#127970; {{ $wh->name }}
                                </option>
                            @endforeach
                        </select>
                    </div>
                </div>
            </div>

            <!-- Category Filter Pills -->
            <div class="stitch-cat-strip" id="pos-category-strip">
                <button type="button" class="stitch-cat-pill active" data-cat="all" onclick="selectCategory('all', this)">
                    All Menu ({{ count($posProducts) }})
                </button>
                @foreach($posCategories as $cat)
                    <button type="button" class="stitch-cat-pill" data-cat="{{ $cat['id'] }}" onclick="selectCategory('{{ $cat['id'] }}', this)">
                        {{ $cat['name'] }}
                    </button>
                @endforeach
            </div>

            <!-- Rush Hour Super-Fast Strip (Stitch C-02) -->
            <div class="stitch-card" style="padding: 12px 14px;" id="rush-hour-section">
                <div class="d-flex align-items-center justify-content-between mb-2">
                    <div class="d-flex align-items-center" style="gap: 6px;">
                        <span style="color:var(--cafe-primary);font-size:16px;">&#9889;</span>
                        <span style="font-weight:800;font-size:14px;color:var(--cafe-ink);">Rush Hour Super-Fast</span>
                    </div>
                    <span class="stitch-badge-honey">Top Sellers &bull; 1-Tap Add</span>
                </div>
                <div class="stitch-rush-grid" id="rush-hour-grid"></div>
            </div>

            <!-- Responsive Menu Grid -->
            <div class="stitch-menu-grid" id="pos-menu-grid"></div>
        </div>

        <!-- RIGHT PANE: Persistent Live Order Ticket & Multi-Tender Checkout -->
        <div class="stitch-card stitch-cart-panel">
            <!-- Cart Header -->
            <div style="padding: 16px; border-bottom: 1px solid var(--cafe-hairline);" class="d-flex align-items-center justify-content-between">
                <div>
                    <div class="d-flex align-items-center" style="gap: 8px;">
                        <h5 style="margin:0;font-weight:800;font-size:17px;color:var(--cafe-ink);">Current Order Ticket</h5>
                        <span id="cart-count-pill" class="stitch-badge-honey">0 items</span>
                    </div>
                    <small id="cart-context-subtitle" style="color:var(--cafe-muted);font-weight:600;">Dine-In &bull; Counter</small>
                </div>
                <button type="button" class="btn btn-sm btn-outline-danger" style="border-radius:999px;font-weight:700;" onclick="clearPosCart()">
                    <i class="fa fa-trash"></i> Clear
                </button>
            </div>

            <!-- Cart Line Items -->
            <div class="stitch-cart-items" id="pos-cart-items">
                <div class="text-center py-5" style="color:var(--cafe-muted);">
                    <i class="fa fa-shopping-basket fa-2x mb-2" style="opacity:0.4;"></i>
                    <div style="font-weight:700;">Tap any menu item on the left to build bill</div>
                    <small>Supports Dine-in KOT, Hold Bill &amp; Split Tender</small>
                </div>
            </div>

            <!-- Totals, Discount & Payment Controls -->
            <div style="padding: 16px; background: var(--cafe-surface-tonal); border-radius: 0 0 20px 20px;">
                <div id="cart-credit-banner" style="display:none;padding:6px 10px;border-radius:10px;font-size:11px;font-weight:800;margin-bottom:8px;border:1px solid var(--cafe-hairline);"></div>
                <div class="d-flex justify-content-between mb-1" style="font-size:13px;font-weight:600;color:var(--cafe-muted);">
                    <span>Subtotal (<span id="cart-tier-label">Retail MRP</span>)</span>
                    <span id="cart-subtotal">₹0.00</span>
                </div>
                <div class="d-flex justify-content-between align-items-center mb-1" style="font-size:13px;font-weight:600;color:var(--cafe-muted);">
                    <span>Order Discount (₹)</span>
                    <input type="number" id="cart-discount-input" value="0" min="0" step="1"
                        style="width:86px;text-align:right;border:1px solid var(--cafe-hairline);border-radius:8px;padding:2px 8px;font-weight:700;background:#fff;"
                        oninput="recalculateTotals()">
                </div>
                <div class="d-flex justify-content-between align-items-center mb-1" style="font-size:13px;font-weight:600;color:var(--cafe-muted);">
                    <span>Packing / Parcel (₹)</span>
                    <input type="number" id="cart-packing-input" value="0" min="0" step="1"
                        style="width:86px;text-align:right;border:1px solid var(--cafe-hairline);border-radius:8px;padding:2px 8px;font-weight:700;background:#fff;"
                        oninput="recalculateTotals()">
                </div>
                <div class="d-flex justify-content-between align-items-center mb-1" style="font-size:13px;font-weight:600;color:var(--cafe-muted);">
                    <label class="mb-0 d-flex align-items-center" style="gap:6px;cursor:pointer;">
                        <input type="checkbox" id="cart-roundoff-toggle" onchange="recalculateTotals()">
                        <span>Auto Round-Off</span>
                    </label>
                    <span id="cart-roundoff-display">₹0.00</span>
                </div>
                <div class="d-flex justify-content-between mb-2" style="font-size:13px;font-weight:600;color:var(--cafe-muted);">
                    <span>Tax (GST Included/Excl)</span>
                    <span id="cart-tax">₹0.00</span>
                </div>
                <div class="d-flex justify-content-between align-items-baseline pt-2 mb-3" style="border-top: 1.5px solid var(--cafe-hairline);">
                    <span style="font-weight:800;font-size:15px;color:var(--cafe-ink);">Grand Total</span>
                    <span id="cart-grand-total" style="font-weight:800;font-size:26px;color:var(--cafe-primary);">₹0.00</span>
                </div>

                <!-- Payment Method Selector -->
                <div class="mb-2">
                    <label style="font-size:11px;font-weight:800;text-transform:uppercase;color:var(--cafe-muted);letter-spacing:0.04em;margin-bottom:4px;">Tender Mode</label>
                    <div class="stitch-segmented" id="payment-method-group">
                        <button type="button" class="stitch-seg-btn active" data-method="Cash" onclick="setPaymentMethod('Cash', this)">Cash</button>
                        <button type="button" class="stitch-seg-btn" data-method="UPI" onclick="setPaymentMethod('UPI', this)">UPI</button>
                        <button type="button" class="stitch-seg-btn" data-method="Card" onclick="setPaymentMethod('Card', this)">Card</button>
                        <button type="button" class="stitch-seg-btn" data-method="Credit" onclick="setPaymentMethod('Credit', this)">Credit</button>
                    </div>
                </div>

                <!-- Hold / Send KOT / Print Capsule -->
                <div class="d-flex mb-2" style="gap: 8px;">
                    <button type="button" id="btn-hold-order" class="btn btn-sm flex-fill" style="background:#fff;border:1px solid var(--cafe-hairline);border-radius:999px;font-weight:700;padding:8px 10px;color:var(--cafe-ink);" onclick="submitPosOrder(true)">
                        <i class="fa fa-pause"></i> <span id="btn-hold-label">Hold / Send KOT</span>
                    </button>
                    <button type="button" id="btn-print-last" class="btn btn-sm flex-fill" style="background:#fff;border:1px solid var(--cafe-hairline);border-radius:999px;font-weight:700;padding:8px 10px;color:var(--cafe-ink);" onclick="openPrintStudioModal('80mm')">
                        <i class="fa fa-print"></i> Print / Labels
                    </button>
                </div>

                <!-- Primary Checkout CTA -->
                <button type="button" id="btn-complete-pay" class="stitch-pay-btn" onclick="submitPosOrder(false)" disabled>
                    <i class="fa fa-check-circle"></i>
                    <span id="btn-pay-label">Pay &amp; Post to ERP (₹0.00)</span>
                </button>
            </div>
        </div>
    </div>
</div>

<!-- Line Modifier & Fractional Qty Modal -->
<div class="modal fade" id="lineModifierModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-md" role="document">
        <div class="modal-content" style="border-radius:20px;">
            <div class="modal-header">
                <h5 class="modal-title" style="font-weight:800;" id="modifier-modal-title">Edit Item Line</h5>
                <button type="button" class="close" data-dismiss="modal"><span>&times;</span></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="mod-product-id">
                <div class="mb-2">
                    <label style="font-size:11px;font-weight:800;color:var(--cafe-muted);">FRACTIONAL / QUICK QTY</label>
                    <div class="d-flex flex-wrap" style="gap:6px;">
                        @foreach([0.25, 0.50, 1.00, 1.50, 2.00, 5.00] as $fq)
                            <button type="button" class="btn btn-sm btn-outline-secondary" style="border-radius:999px;font-weight:700;" onclick="document.getElementById('mod-qty').value='{{ $fq }}'">{{ $fq }}x</button>
                        @endforeach
                    </div>
                </div>
                <div class="row mb-2">
                    <div class="col-6">
                        <label style="font-size:12px;font-weight:700;">Quantity</label>
                        <input type="number" step="0.05" min="0" id="mod-qty" class="form-control">
                    </div>
                    <div class="col-6">
                        <label style="font-size:12px;font-weight:700;">Unit Price (₹)</label>
                        <input type="number" step="0.50" min="0" id="mod-price" class="form-control">
                    </div>
                </div>
                <div class="mb-2">
                    <label style="font-size:11px;font-weight:800;color:var(--cafe-muted);">KITCHEN MODIFIER PRESETS</label>
                    <div class="d-flex flex-wrap" style="gap:6px;">
                        @foreach(['No Sugar', 'Less Sugar', 'Extra Strong', 'Extra Hot', 'Parcel Pack', 'Spicy', 'No Onion', 'Jain'] as $tag)
                            <button type="button" class="btn btn-sm btn-light" style="border-radius:999px;border:1px solid var(--cafe-hairline);font-size:12px;font-weight:700;" onclick="toggleModifierTag('{{ $tag }}')">{{ $tag }}</button>
                        @endforeach
                    </div>
                </div>
                <div class="form-group mb-0">
                    <label style="font-size:12px;font-weight:700;">Custom Kitchen Note</label>
                    <input type="text" id="mod-note" class="form-control" placeholder="e.g. Less oil, separate chutney">
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-outline-danger" onclick="applyLineModifiers(true)">Remove</button>
                <button type="button" class="btn btn-primary" style="background:var(--cafe-primary);border-color:var(--cafe-primary);font-weight:800;" onclick="applyLineModifiers(false)">Apply Changes</button>
            </div>
        </div>
    </div>
</div>

<!-- 5-Format Multi-Printer & Label Studio Modal (Section 4 Parity) -->
<div class="modal fade" id="printStudioModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content" style="border-radius:20px;">
            <div class="modal-header">
                <div>
                    <h5 class="modal-title mb-0" style="font-weight:800;">Thermal Receipt &amp; Label Studio</h5>
                    <small class="text-muted" id="print-studio-ref">Ready to print current bill or label batch</small>
                </div>
                <button type="button" class="close" data-dismiss="modal"><span>&times;</span></button>
            </div>
            <div class="modal-body">
                <div class="d-flex flex-wrap mb-3" style="gap:6px;" id="print-format-pills">
                    <button type="button" class="stitch-cat-pill active" data-fmt="80mm" onclick="selectPrintFormat('80mm', this)">80mm Bill + Token</button>
                    <button type="button" class="stitch-cat-pill" data-fmt="58mm" onclick="selectPrintFormat('58mm', this)">58mm Compact</button>
                    <button type="button" class="stitch-cat-pill" data-fmt="kot" onclick="selectPrintFormat('kot', this)">Kitchen KOT</button>
                    <button type="button" class="stitch-cat-pill" data-fmt="sticker_50x25" onclick="selectPrintFormat('sticker_50x25', this)">50x25mm Barcode Sticker</button>
                    <button type="button" class="stitch-cat-pill" data-fmt="neck_tag_50x38" onclick="selectPrintFormat('neck_tag_50x38', this)">20L Can Neck Tag</button>
                </div>

                <div class="row">
                    <div class="col-md-7 mb-2">
                        <div id="print-preview-paper" style="background:#FFFDF8;border:1.5px dashed #CBBBA8;border-radius:14px;padding:16px;font-family:'Courier New',monospace;color:#1A1512;max-height:420px;overflow:auto;"></div>
                    </div>
                    <div class="col-md-5 mb-2">
                        <div style="background:var(--cafe-surface-tonal);border-radius:14px;padding:12px;">
                            <div style="font-size:11px;font-weight:800;color:var(--cafe-muted);margin-bottom:6px;">PRINTER DISPATCH &amp; TSPL2 STREAM</div>
                            <div id="tspl-stream-box" style="font-family:monospace;font-size:11px;background:#1F1A17;color:#D8F3DC;padding:10px;border-radius:10px;min-height:180px;max-height:260px;overflow:auto;white-space:pre-wrap;"></div>
                            <div class="d-flex mt-2" style="gap:6px;">
                                <button type="button" class="btn btn-sm btn-outline-dark flex-fill" onclick="copyPrintStream()">Copy TSPL2 / ESC</button>
                                <button type="button" class="btn btn-sm btn-primary flex-fill" style="background:var(--cafe-action);border-color:var(--cafe-action);color:#2B1B14;font-weight:800;" onclick="executeThermalPrint()">Print Now</button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Held & Recent Orders Modal -->
<div class="modal fade" id="heldOrdersModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content" style="border-radius:20px;">
            <div class="modal-header">
                <h5 class="modal-title" style="font-weight:800;">Held KOTs &amp; Recent POS Bills</h5>
                <button type="button" class="close" data-dismiss="modal"><span>&times;</span></button>
            </div>
            <div class="modal-body" id="held-orders-modal-body">
                <p class="text-muted">Loading ERP orders...</p>
            </div>
        </div>
    </div>
</div>

<script>
    const POS_CSRF = '{{ csrf_token() }}';
    const POS_STORE_URL = '{{ route("cafe.orders.store") }}';
    const POS_ORDERS_URL = '{{ route("cafe.pos.orders") }}';
    const POS_SHIFT_OPEN_URL = '{{ route("cafe.pos.shifts.open") }}';
    const POS_PRINT_JOB_URL_TEMPLATE = '{{ route("cafe.pos.orders.print-job", ["id" => "__ID__"]) }}';
    const POS_PRICE_TIERS = @json($posPriceTiers);
    const POS_COMPANY_NAME = @json($companyName);
    const POS_UPI_VPA = @json($upiVpa ?? '');
    const POS_COMPANY_GSTIN = @json($companyGstin ?? '');

    let catalogProducts = @json($posProducts);
    if (!Array.isArray(catalogProducts) || catalogProducts.length === 0) {
        catalogProducts = @json($products).map(p => ({
            id: Number(p.id),
            name: p.name,
            code: p.code || '',
            price: Number(p.price || 0),
            category_id: p.category_id,
            stock_qty: Number(p.qty ?? 25),
            in_stock: Number(p.qty ?? 25) > 0,
            featured: Boolean(p.featured),
            type: p.type || 'standard',
            tax_rate: 0
        }));
    }

    let selectedCategory = 'all';
    let selectedOrderType = 'dine_in';
    let selectedPaymentMethod = 'Cash';
    let selectedPriceTier = 'Retail MRP';
    let kotFirstMode = false;
    let selectedPrintFormat = '80mm';
    let lastGeneratedPrintStream = '';
    let cart = [];
    let lastCompletedOrder = null;

    function formatINR(val) {
        return '₹' + Number(val || 0).toFixed(2);
    }

    function tierPrice(product) {
        const mult = Number(POS_PRICE_TIERS[selectedPriceTier] || 1.0);
        return Number((Number(product.price || 0) * mult).toFixed(2));
    }

    function formatQty(q) {
        const num = Number(q || 0);
        return Math.abs(num - Math.round(num)) < 0.001 ? String(Math.round(num)) : num.toFixed(2).replace(/0+$/, '').replace(/\.$/, '');
    }

    function setOrderType(type, btn) {
        selectedOrderType = type;
        document.querySelectorAll('#order-type-group .stitch-seg-btn').forEach(b => b.classList.remove('active'));
        if (btn) btn.classList.add('active');
        updateCartSubtitle();
    }

    function setPaymentMethod(method, btn) {
        selectedPaymentMethod = method;
        document.querySelectorAll('#payment-method-group .stitch-seg-btn').forEach(b => b.classList.remove('active'));
        if (btn) btn.classList.add('active');
        recalculateTotals();
    }

    function setPriceTier(tier, btn) {
        selectedPriceTier = tier;
        document.querySelectorAll('#price-tier-group .stitch-cat-pill').forEach(b => b.classList.remove('active'));
        if (btn) btn.classList.add('active');
        const tierLabel = document.getElementById('cart-tier-label');
        if (tierLabel) tierLabel.textContent = tier;
        cart = cart.map(item => ({
            ...item,
            unitPrice: tierPrice(item.product)
        }));
        renderCatalog();
        renderCart();
    }

    function toggleKotFirstMode() {
        kotFirstMode = !kotFirstMode;
        const label = document.getElementById('billing-mode-label');
        const holdLabel = document.getElementById('btn-hold-label');
        const btn = document.getElementById('btn-billing-mode');
        if (label) label.textContent = kotFirstMode ? 'Mode: KOT First' : 'Mode: Fast Bill';
        if (holdLabel) holdLabel.textContent = kotFirstMode ? 'Fire KOT First' : 'Hold / Send KOT';
        if (btn) {
            btn.style.background = kotFirstMode ? 'var(--cafe-primary)' : 'var(--cafe-surface-tonal)';
            btn.style.color = kotFirstMode ? '#fff' : 'var(--cafe-ink)';
        }
    }

    function handleSearchEnter(event) {
        if (event.key !== 'Enter') return;
        event.preventDefault();
        addByBarcodeOrQuery();
    }

    function addByBarcodeOrQuery() {
        const input = document.getElementById('pos-search-input');
        const q = (input?.value || '').trim().toLowerCase();
        if (!q) return;

        let match = catalogProducts.find(p => String(p.code || '').toLowerCase() === q);
        if (!match) {
            match = catalogProducts.find(p => String(p.name || '').toLowerCase() === q);
        }
        if (!match) {
            const matches = catalogProducts.filter(p =>
                (selectedCategory === 'all' || String(p.category_id) === selectedCategory) &&
                (String(p.name || '').toLowerCase().includes(q) || String(p.code || '').toLowerCase().includes(q))
            );
            if (matches.length === 1) match = matches[0];
        }
        if (match && match.in_stock !== false) {
            addToCart(match.id, 1);
            input.value = '';
            renderCatalog();
        }
    }

    function selectCategory(catId, btn) {
        selectedCategory = String(catId);
        document.querySelectorAll('#pos-category-strip .stitch-cat-pill').forEach(b => b.classList.remove('active'));
        if (btn) btn.classList.add('active');
        renderCatalog();
    }

    function updateCartSubtitle() {
        const typeLabel = selectedOrderType === 'dine_in' ? 'Dine-In' : (selectedOrderType === 'takeaway' ? 'Takeaway' : 'Delivery');
        const tableSelect = document.getElementById('pos-table-select');
        const tableText = tableSelect && tableSelect.value
            ? tableSelect.options[tableSelect.selectedIndex].text.split('(')[0].trim()
            : 'Counter';
        document.getElementById('cart-context-subtitle').textContent = `${typeLabel} • ${tableText}`;
    }

    function getCartQty(productId) {
        const found = cart.find(i => i.product.id === Number(productId));
        return found ? found.qty : 0;
    }

    function addToCart(productId, delta = 1) {
        const product = catalogProducts.find(p => Number(p.id) === Number(productId));
        if (!product) return;

        const existing = cart.find(i => i.product.id === Number(productId));
        if (existing) {
            existing.qty = Number((existing.qty + delta).toFixed(2));
            if (existing.qty <= 0.001) {
                cart = cart.filter(i => i.product.id !== Number(productId));
            }
        } else if (delta > 0) {
            cart.push({
                product,
                qty: Number(delta),
                unitPrice: tierPrice(product),
                note: ''
            });
        }
        renderCatalog();
        renderCart();
    }

    function openLineModifierModal(productId) {
        const item = cart.find(i => Number(i.product.id) === Number(productId));
        if (!item) return;
        document.getElementById('mod-product-id').value = item.product.id;
        document.getElementById('modifier-modal-title').textContent = `${item.product.name} • Modifiers`;
        document.getElementById('mod-qty').value = item.qty;
        document.getElementById('mod-price').value = Number(item.unitPrice ?? tierPrice(item.product)).toFixed(2);
        document.getElementById('mod-note').value = item.note || '';
        $('#lineModifierModal').modal('show');
    }

    function toggleModifierTag(tag) {
        const noteInput = document.getElementById('mod-note');
        const parts = (noteInput.value || '').split(',').map(s => s.trim()).filter(Boolean);
        const idx = parts.indexOf(tag);
        if (idx >= 0) parts.splice(idx, 1);
        else parts.push(tag);
        noteInput.value = parts.join(', ');
    }

    function applyLineModifiers(removeItem) {
        const productId = Number(document.getElementById('mod-product-id').value);
        const idx = cart.findIndex(i => Number(i.product.id) === productId);
        if (idx < 0) return;
        if (removeItem) {
            cart.splice(idx, 1);
        } else {
            const qty = Number(document.getElementById('mod-qty').value || 0);
            const price = Number(document.getElementById('mod-price').value || cart[idx].unitPrice);
            const note = (document.getElementById('mod-note').value || '').trim();
            if (qty <= 0.001) {
                cart.splice(idx, 1);
            } else {
                cart[idx].qty = Number(qty.toFixed(2));
                cart[idx].unitPrice = Number(price.toFixed(2));
                cart[idx].note = note;
            }
        }
        $('#lineModifierModal').modal('hide');
        renderCatalog();
        renderCart();
    }

    function clearPosCart() {
        cart = [];
        document.getElementById('cart-discount-input').value = 0;
        const packingInput = document.getElementById('cart-packing-input');
        if (packingInput) packingInput.value = 0;
        renderCatalog();
        renderCart();
    }

    function renderRushHour() {
        const rushContainer = document.getElementById('rush-hour-grid');
        if (!rushContainer) return;
        const featured = catalogProducts.filter(p => p.featured).slice(0, 4);
        const topList = featured.length > 0 ? featured : catalogProducts.slice(0, 4);

        if (topList.length === 0) {
            document.getElementById('rush-hour-section').style.display = 'none';
            return;
        }
        document.getElementById('rush-hour-section').style.display = 'block';
        rushContainer.innerHTML = topList.map(item => {
            const qty = getCartQty(item.id);
            const price = tierPrice(item);
            return `
                <div class="stitch-rush-card" onclick="addToCart(${item.id}, 1)">
                    <div style="min-width:0;">
                        <div style="font-weight:800;font-size:14px;color:var(--cafe-ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
                            ${item.name}
                        </div>
                        <div style="font-weight:800;font-size:13px;color:var(--cafe-primary);">
                            ₹${price.toFixed(0)}
                            ${qty > 0 ? `<span class="badge badge-pill" style="background:var(--cafe-primary);color:#fff;margin-left:4px;">${formatQty(qty)}x</span>` : ''}
                        </div>
                    </div>
                    <button type="button" class="stitch-step-btn plus" onclick="event.stopPropagation(); addToCart(${item.id}, 1)">+</button>
                </div>
            `;
        }).join('');
    }

    function renderCatalog() {
        renderRushHour();
        const query = (document.getElementById('pos-search-input')?.value || '').trim().toLowerCase();
        const grid = document.getElementById('pos-menu-grid');
        if (!grid) return;

        const filtered = catalogProducts.filter(p => {
            const matchesCat = selectedCategory === 'all' || String(p.category_id) === selectedCategory;
            const matchesQuery = !query ||
                String(p.name || '').toLowerCase().includes(query) ||
                String(p.code || '').toLowerCase().includes(query);
            return matchesCat && matchesQuery;
        });

        if (filtered.length === 0) {
            grid.innerHTML = `
                <div class="stitch-card p-4 text-center" style="grid-column: 1 / -1; color: var(--cafe-muted);">
                    No menu items match the current filter.
                </div>
            `;
            return;
        }

        grid.innerHTML = filtered.map(item => {
            const qty = getCartQty(item.id);
            const stock = Number(item.stock_qty ?? 0);
            const isSoldOut = item.in_stock === false;
            const price = tierPrice(item);
            return `
                <div class="stitch-product-card ${qty > 0 ? 'in-cart' : ''} ${isSoldOut ? 'sold-out' : ''}"
                     onclick="${isSoldOut ? '' : `addToCart(${item.id}, 1)`}">
                    <div class="d-flex justify-content-between align-items-center">
                        <span style="font-size:11px;font-weight:700;padding:2px 8px;border-radius:999px;background:var(--cafe-surface-tonal);color:var(--cafe-muted);">
                            ${isSoldOut ? '86 Sold Out' : (item.type === 'service' ? 'Fresh Prep' : `${stock.toFixed(0)} left`)}
                        </span>
                        <span style="font-size:11px;font-weight:700;color:var(--cafe-muted);">${item.code || ''}</span>
                    </div>
                    <div style="margin: 10px 0;">
                        <div style="font-weight:800;font-size:15px;color:var(--cafe-ink);line-height:1.25;">${item.name}</div>
                    </div>
                    <div class="d-flex justify-content-between align-items-center">
                        <span style="font-weight:800;font-size:17px;color:var(--cafe-primary);">₹${price.toFixed(0)}</span>
                        ${qty > 0 ? `
                            <div class="stitch-stepper" onclick="event.stopPropagation();">
                                <button type="button" class="stitch-step-btn" onclick="addToCart(${item.id}, -1)">-</button>
                                <span style="font-weight:800;font-size:13px;min-width:16px;text-align:center;">${formatQty(qty)}</span>
                                <button type="button" class="stitch-step-btn plus" onclick="addToCart(${item.id}, 1)">+</button>
                            </div>
                        ` : `
                            <button type="button" class="stitch-step-btn plus" onclick="event.stopPropagation(); addToCart(${item.id}, 1)">+</button>
                        `}
                    </div>
                </div>
            `;
        }).join('');
    }

    function getCustomerCreditStatus(addedCredit) {
        const sel = document.getElementById('pos-customer-select');
        const opt = sel && sel.selectedOptions ? sel.selectedOptions[0] : null;
        const limit = Number(opt?.dataset?.creditLimit || 0);
        const due = Number(opt?.dataset?.dueAmount || 0);
        const projected = due + Math.max(0, addedCredit || 0);
        const blocked = limit > 0 && addedCredit > 0.01 && projected > limit;
        const name = (opt?.textContent || 'Customer').replace(/^[^\w]+/, '').trim();
        return { limit, due, projected, blocked, shortfall: Math.max(0, projected - limit), name };
    }

    function recalculateTotals() {
        let subtotal = 0;
        let tax = 0;
        let count = 0;

        cart.forEach(item => {
            const unit = Number(item.unitPrice ?? tierPrice(item.product));
            const lineNet = unit * item.qty;
            const lineTax = lineNet * (Number(item.product.tax_rate || 0) / 100);
            subtotal += lineNet;
            tax += lineTax;
            count += item.qty;
        });

        const discount = Math.max(0, Number(document.getElementById('cart-discount-input')?.value || 0));
        const packing = Math.max(0, Number(document.getElementById('cart-packing-input')?.value || 0));
        const preRoundTotal = Math.max(0, subtotal + tax + packing - discount);
        const autoRound = Boolean(document.getElementById('cart-roundoff-toggle')?.checked);
        const roundOff = autoRound ? Number((Math.round(preRoundTotal) - preRoundTotal).toFixed(2)) : 0;
        const grandTotal = Math.max(0, preRoundTotal + roundOff);

        document.getElementById('cart-count-pill').textContent = `${formatQty(count)} item${count === 1 ? '' : 's'}`;
        document.getElementById('cart-subtotal').textContent = formatINR(subtotal);
        document.getElementById('cart-tax').textContent = formatINR(tax);
        const roundDisplay = document.getElementById('cart-roundoff-display');
        if (roundDisplay) roundDisplay.textContent = `${roundOff >= 0 ? '+' : ''}₹${roundOff.toFixed(2)}`;
        document.getElementById('cart-grand-total').textContent = formatINR(grandTotal);
        document.getElementById('btn-pay-label').textContent = `Pay & Post to ERP (${formatINR(grandTotal)})`;
        document.getElementById('btn-complete-pay').disabled = cart.length === 0;

        const creditInfo = getCustomerCreditStatus(selectedPaymentMethod === 'Credit' ? grandTotal : 0);
        const creditBanner = document.getElementById('cart-credit-banner');
        if (creditBanner) {
            if (creditInfo.limit > 0) {
                creditBanner.style.display = 'block';
                creditBanner.style.background = creditInfo.blocked ? '#FCE8E8' : '#FFFFFF';
                creditBanner.style.color = creditInfo.blocked ? '#C92A2A' : 'var(--cafe-muted)';
                creditBanner.style.borderColor = creditInfo.blocked ? '#E8505B' : 'var(--cafe-hairline)';
                creditBanner.textContent = creditInfo.blocked
                    ? `${creditInfo.name}: CREDIT LIMIT EXCEEDED (${formatINR(creditInfo.projected)} > Limit ${formatINR(creditInfo.limit)})`
                    : `${creditInfo.name}: Due ${formatINR(creditInfo.due)} / Limit ${formatINR(creditInfo.limit)}`;
            } else {
                creditBanner.style.display = 'none';
            }
        }

        return { subtotal, tax, discount, packing, roundOff, grandTotal, count };
    }

    function renderCart() {
        const container = document.getElementById('pos-cart-items');
        if (cart.length === 0) {
            container.innerHTML = `
                <div class="text-center py-5" style="color:var(--cafe-muted);">
                    <i class="fa fa-shopping-basket fa-2x mb-2" style="opacity:0.4;"></i>
                    <div style="font-weight:700;">Tap any menu item on the left to build bill</div>
                    <small>Supports Dine-in KOT, Hold Bill &amp; Split Tender</small>
                </div>
            `;
            recalculateTotals();
            return;
        }

        container.innerHTML = cart.map(item => {
            const unit = Number(item.unitPrice ?? tierPrice(item.product));
            const lineTotal = unit * item.qty;
            return `
                <div class="stitch-cart-row" style="cursor:pointer;" onclick="openLineModifierModal(${item.product.id})">
                    <div style="min-width:0;flex:1;">
                        <div style="font-weight:700;font-size:14px;color:var(--cafe-ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
                            ${item.product.name}
                        </div>
                        <small style="color:${item.note ? 'var(--cafe-primary)' : 'var(--cafe-muted)'};font-weight:600;">
                            ₹${unit.toFixed(2)} each${item.note ? ` • ${item.note}` : ' • Edit / Note'}
                        </small>
                    </div>
                    <div class="stitch-stepper" onclick="event.stopPropagation();">
                        <button type="button" class="stitch-step-btn" onclick="addToCart(${item.product.id}, -1)">-</button>
                        <span style="font-weight:800;font-size:13px;min-width:18px;text-align:center;" onclick="openLineModifierModal(${item.product.id})">${formatQty(item.qty)}</span>
                        <button type="button" class="stitch-step-btn plus" onclick="addToCart(${item.product.id}, 1)">+</button>
                    </div>
                    <div style="font-weight:800;font-size:14px;color:var(--cafe-ink);min-width:68px;text-align:right;">
                        ₹${lineTotal.toFixed(2)}
                    </div>
                </div>
            `;
        }).join('');

        recalculateTotals();
    }

    async function submitPosOrder(hold = false) {
        if (cart.length === 0) return;

        const totals = recalculateTotals();
        if (!hold && selectedPaymentMethod === 'Credit') {
            const creditInfo = getCustomerCreditStatus(totals.grandTotal);
            if (creditInfo.blocked) {
                alert(`Credit Limit Exceeded by ${formatINR(creditInfo.shortfall)} for ${creditInfo.name}. Collect Cash/UPI before posting.`);
                return;
            }
        }

        const warehouseId = Number(document.getElementById('pos-warehouse-select')?.value || {{ $activeWarehouseId }});
        const customerId = Number(document.getElementById('pos-customer-select')?.value || {{ $defaultCustomerId }});
        const tableVal = document.getElementById('pos-table-select')?.value;
        const tableId = tableVal ? Number(tableVal) : null;
        const lineNotes = {};
        cart.forEach(i => {
            if (i.note && i.note.trim()) {
                lineNotes[String(i.product.id)] = i.note.trim();
            }
        });

        const payload = {
            warehouse_id: warehouseId,
            customer_id: customerId,
            table_id: tableId,
            order_type: selectedOrderType,
            price_tier: selectedPriceTier,
            hold: Boolean(hold),
            order_discount: totals.discount,
            shipping_cost: totals.packing,
            round_off_amount: totals.roundOff,
            line_notes: lineNotes,
            sale_note: hold
                ? (kotFirstMode ? `KOT First Fire (${selectedPriceTier})` : `Held KOT from Web Counter POS (${selectedPriceTier})`)
                : `Web Counter POS (${selectedOrderType.toUpperCase()} · ${selectedPriceTier})`,
            items: cart.map(i => ({
                product_id: Number(i.product.id),
                qty: Number(i.qty),
                unit_price: Number(i.unitPrice ?? tierPrice(i.product)),
                discount: 0,
                tax_rate: Number(i.product.tax_rate || 0),
                note: i.note || ''
            })),
            payments: (hold || selectedPaymentMethod === 'Credit') ? [] : [
                {
                    method: selectedPaymentMethod,
                    amount: totals.grandTotal
                }
            ]
        };

        const payBtn = document.getElementById('btn-complete-pay');
        payBtn.disabled = true;
        document.getElementById('btn-pay-label').textContent = hold ? 'Holding KOT...' : 'Posting to ERP Ledger...';

        try {
            const response = await fetch(POS_STORE_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': POS_CSRF
                },
                body: JSON.stringify(payload)
            });
            const json = await response.json();
            if (!response.ok || json.success === false) {
                throw new Error(json.message || 'Failed to save POS order');
            }

            lastCompletedOrder = json.data;
            clearPosCart();
            alert(`${hold ? 'Order Held / Sent to KOT' : 'POS Bill Posted to ERP Ledger'}!\nReference: ${lastCompletedOrder.reference_no}\nTotal: ₹${Number(lastCompletedOrder.grand_total).toFixed(2)}`);
        } catch (err) {
            alert('POS Error: ' + err.message);
        } finally {
            payBtn.disabled = cart.length === 0;
            recalculateTotals();
        }
    }

    async function openShiftModal() {
        const cashFloat = prompt('Enter Opening Cash Drawer Float (₹):', '2500');
        if (cashFloat === null) return;
        const warehouseId = Number(document.getElementById('pos-warehouse-select')?.value || {{ $activeWarehouseId }});

        try {
            const res = await fetch(POS_SHIFT_OPEN_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': POS_CSRF
                },
                body: JSON.stringify({
                    warehouse_id: warehouseId,
                    cash_in_hand: Number(cashFloat || 0)
                })
            });
            const json = await res.json();
            if (json.data) {
                document.getElementById('pos-shift-badge').textContent =
                    `Shift #${json.data.id} Open (Float ₹${Number(json.data.cash_in_hand || 0).toFixed(0)})`;
            }
        } catch (e) {
            alert('Could not open shift: ' + e.message);
        }
    }

    async function loadHeldOrdersModal() {
        $('#heldOrdersModal').modal('show');
        const body = document.getElementById('held-orders-modal-body');
        body.innerHTML = '<p class="text-muted">Loading ERP POS orders...</p>';
        try {
            const res = await fetch(POS_ORDERS_URL, {
                headers: { 'Accept': 'application/json' }
            });
            const json = await res.json();
            const orders = json.data || [];
            if (orders.length === 0) {
                body.innerHTML = '<p class="text-muted mb-0">No recent POS bills found for this company.</p>';
                return;
            }
            body.innerHTML = `
                <div class="table-responsive">
                    <table class="table table-sm table-hover">
                        <thead>
                            <tr>
                                <th>Ref No</th>
                                <th>Customer</th>
                                <th>Table</th>
                                <th>Status</th>
                                <th>Total</th>
                                <th>Print</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${orders.map(o => `
                                <tr>
                                    <td><strong>${o.reference_no}</strong></td>
                                    <td>${o.customer_name || 'Walk-in'}</td>
                                    <td>${o.table_name || 'Counter'}</td>
                                    <td><span class="badge badge-${o.is_held ? 'warning' : 'success'}">${o.is_held ? 'Held / KOT' : 'Completed'}</span></td>
                                    <td><strong>₹${Number(o.grand_total || 0).toFixed(2)}</strong></td>
                                    <td><button type="button" class="btn btn-xs btn-outline-primary" onclick="lastCompletedOrder = ${JSON.stringify(o).replace(/"/g, '&quot;')}; $('#heldOrdersModal').modal('hide'); openPrintStudioModal('80mm');">Studio</button></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `;
        } catch (e) {
            body.innerHTML = `<p class="text-danger">${e.message}</p>`;
        }
    }

    function openPrintStudioModal(format = '80mm') {
        selectedPrintFormat = format;
        document.querySelectorAll('#print-format-pills .stitch-cat-pill').forEach(b => {
            b.classList.toggle('active', b.dataset.fmt === format);
        });
        renderPrintStudio();
        $('#printStudioModal').modal('show');
    }

    function selectPrintFormat(format, btn) {
        selectedPrintFormat = format;
        document.querySelectorAll('#print-format-pills .stitch-cat-pill').forEach(b => b.classList.remove('active'));
        if (btn) btn.classList.add('active');
        renderPrintStudio();
    }

    function buildPrintItemsContext() {
        if (cart.length > 0) {
            const totals = recalculateTotals();
            return {
                referenceNo: 'DRAFT-' + String(Date.now()).slice(-6),
                tokenNo: String((Date.now() % 899) + 100),
                customer: getCustomerCreditStatus(0).name || 'Walk-in Customer',
                tier: selectedPriceTier,
                subtotal: totals.subtotal,
                packing: totals.packing,
                discount: totals.discount,
                roundOff: totals.roundOff,
                grandTotal: totals.grandTotal,
                items: cart.map(c => ({
                    name: c.product.name,
                    code: c.product.code || `SKU-${c.product.id}`,
                    qty: Number(c.qty),
                    unitPrice: Number(c.unitPrice ?? tierPrice(c.product)),
                    note: c.note || ''
                }))
            };
        }
        if (lastCompletedOrder) {
            return {
                referenceNo: lastCompletedOrder.reference_no || `POS-${lastCompletedOrder.id}`,
                tokenNo: String(lastCompletedOrder.id || 0).padStart(4, '0'),
                customer: lastCompletedOrder.customer_name || 'Walk-in Customer',
                tier: lastCompletedOrder.price_tier || selectedPriceTier,
                subtotal: Number(lastCompletedOrder.grand_total || 0),
                packing: Number(lastCompletedOrder.shipping_cost || 0),
                discount: Number(lastCompletedOrder.order_discount || 0),
                roundOff: Number(lastCompletedOrder.round_off_amount || 0),
                grandTotal: Number(lastCompletedOrder.grand_total || 0),
                items: (lastCompletedOrder.items || []).map(i => ({
                    name: i.product_name,
                    code: i.product_code || `SKU-${i.product_id}`,
                    qty: Number(i.qty || 1),
                    unitPrice: Number(i.net_unit_price || i.unit_price || 0),
                    note: i.note || ''
                }))
            };
        }
        return {
            referenceNo: 'NO-ACTIVE-BILL',
            tokenNo: '0000',
            customer: 'Walk-in Customer',
            tier: selectedPriceTier,
            subtotal: 0,
            packing: 0,
            discount: 0,
            roundOff: 0,
            grandTotal: 0,
            items: []
        };
    }

    function renderPrintStudio() {
        const ctx = buildPrintItemsContext();
        document.getElementById('print-studio-ref').textContent = `${ctx.referenceNo} • Token #${ctx.tokenNo} • ${ctx.tier}`;
        const paper = document.getElementById('print-preview-paper');
        const tsplBox = document.getElementById('tspl-stream-box');
        if (!ctx.items.length) {
            paper.innerHTML = `<div style="text-align:center;padding:24px;color:#6E5D53;font-size:13px;">Cart is empty and no recent completed bill is loaded. Add items to cart to preview thermal receipt or label output.</div>`;
            tsplBox.textContent = '';
            lastGeneratedPrintStream = '';
            return;
        }
        const firstItem = ctx.items[0];
        const today = new Date();
        const pkd = today.toISOString().slice(0, 10);
        const expDate = new Date(today.getTime() + (selectedPrintFormat === 'neck_tag_50x38' ? 30 : 2) * 86400000).toISOString().slice(0, 10);
        const upiUri = POS_UPI_VPA
            ? `upi://pay?pa=${encodeURIComponent(POS_UPI_VPA)}&pn=${encodeURIComponent(POS_COMPANY_NAME)}&tn=${encodeURIComponent(ctx.referenceNo)}&am=${ctx.grandTotal.toFixed(2)}&cu=INR`
            : '';

        if (selectedPrintFormat === 'kot') {
            paper.innerHTML = `
                <div style="text-align:center;font-weight:800;font-size:15px;">*** KITCHEN ORDER TICKET ***</div>
                <div style="text-align:center;font-size:12px;">${POS_COMPANY_NAME} • TOKEN #${ctx.tokenNo}</div>
                <hr style="border-top:1px dashed #999;">
                <div style="font-size:12px;">ORDER: ${ctx.referenceNo} | ${selectedOrderType.toUpperCase()}</div>
                <div style="font-size:12px;margin-bottom:8px;">CUSTOMER: ${ctx.customer}</div>
                <hr style="border-top:1px dashed #999;">
                ${ctx.items.map(i => `
                    <div style="font-size:15px;font-weight:800;margin:6px 0;">[ ${formatQty(i.qty)}x ] ${i.name.toUpperCase()}</div>
                    ${i.note ? `<div style="font-size:12px;font-weight:700;color:#C2542D;margin-left:14px;">>> NOTE: ${i.note}</div>` : ''}
                `).join('')}
                <hr style="border-top:1px dashed #999;">
                <div style="text-align:center;font-size:11px;">TIME: ${today.toLocaleTimeString()}</div>
            `;
            lastGeneratedPrintStream = `ESC/POS KOT TICKET\nTOKEN #${ctx.tokenNo}\nORDER ${ctx.referenceNo}\n` +
                ctx.items.map(i => `${formatQty(i.qty)}x ${i.name}${i.note ? ' [' + i.note + ']' : ''}`).join('\n');
        } else if (selectedPrintFormat === 'sticker_50x25' || selectedPrintFormat === 'neck_tag_50x38') {
            const isNeck = selectedPrintFormat === 'neck_tag_50x38';
            paper.innerHTML = `
                <div style="border:2px solid #2B1B14;border-radius:10px;padding:12px;background:#fff;max-width:320px;margin:0 auto;">
                    <div class="d-flex justify-content-between" style="font-size:11px;font-weight:800;">
                        <span>${POS_COMPANY_NAME.toUpperCase()}</span>
                        <span>${isNeck ? 'BIS / RO + UV + OZONISED' : 'BATCH #' + ctx.tokenNo}</span>
                    </div>
                    <div style="font-size:16px;font-weight:800;margin:4px 0;">${firstItem.name}</div>
                    <div style="font-size:12px;">SKU: ${firstItem.code} &bull; MRP: <strong>₹${Number(firstItem.unitPrice).toFixed(2)}</strong></div>
                    <div style="margin:8px 0;padding:6px;background:#F3E9DC;border-radius:6px;text-align:center;font-weight:800;letter-spacing:3px;">
                        ||| || |||| | ||| ${firstItem.code} |||
                    </div>
                    <div class="d-flex justify-content-between" style="font-size:11px;font-weight:700;">
                        <span>PKD: ${pkd}</span>
                        <span>USE BY: ${expDate}</span>
                    </div>
                </div>
            `;
            const h = isNeck ? '38 mm' : '25 mm';
            lastGeneratedPrintStream = [
                `SIZE 50 mm, ${h}`,
                'GAP 2 mm, 0 mm',
                'CLS',
                `TEXT 16,14,"2",0,1,1,"${POS_COMPANY_NAME.slice(0, 22)}"`,
                `TEXT 16,42,"3",0,1,1,"${firstItem.name.slice(0, 20)}"`,
                `TEXT 16,74,"2",0,1,1,"MRP Rs.${Number(firstItem.unitPrice).toFixed(2)}  PKD:${pkd}"`,
                `BARCODE 16,102,"128",42,1,0,2,2,"${firstItem.code}"`,
                `TEXT 16,158,"1",0,1,1,"BATCH:${ctx.tokenNo} EXP:${expDate}"`,
                'PRINT 1,1'
            ].join('\n');
        } else {
            const width = selectedPrintFormat === '58mm' ? '260px' : '340px';
            paper.innerHTML = `
                <div style="max-width:${width};margin:0 auto;font-size:12px;">
                    <div style="text-align:center;font-weight:800;font-size:15px;">${POS_COMPANY_NAME}</div>
                    ${POS_COMPANY_GSTIN ? `<div style="text-align:center;font-size:11px;">GSTIN: ${POS_COMPANY_GSTIN}</div>` : ''}
                    <div style="text-align:center;">COUNTER TOKEN #${ctx.tokenNo}</div>
                    <hr style="border-top:1px dashed #999;">
                    <div>Bill: ${ctx.referenceNo} (${selectedOrderType.toUpperCase()})</div>
                    <div>Cust: ${ctx.customer} • Slab: ${ctx.tier}</div>
                    <hr style="border-top:1px dashed #999;">
                    ${ctx.items.map(i => `
                        <div class="d-flex justify-content-between">
                            <span>${formatQty(i.qty)}x ${i.name}</span>
                            <strong>₹${(i.qty * i.unitPrice).toFixed(2)}</strong>
                        </div>
                        ${i.note ? `<div style="font-size:10px;color:#6E5D53;">  [${i.note}]</div>` : ''}
                    `).join('')}
                    <hr style="border-top:1px dashed #999;">
                    ${ctx.packing > 0 ? `<div class="d-flex justify-content-between"><span>Packing Charge</span><span>₹${ctx.packing.toFixed(2)}</span></div>` : ''}
                    ${ctx.discount > 0 ? `<div class="d-flex justify-content-between"><span>Discount</span><span>-₹${ctx.discount.toFixed(2)}</span></div>` : ''}
                    ${ctx.roundOff !== 0 ? `<div class="d-flex justify-content-between"><span>Round Off</span><span>₹${ctx.roundOff.toFixed(2)}</span></div>` : ''}
                    <div class="d-flex justify-content-between" style="font-size:15px;font-weight:800;margin-top:4px;">
                        <span>GRAND TOTAL</span><span>₹${ctx.grandTotal.toFixed(2)}</span>
                    </div>
                    ${upiUri ? `<div style="text-align:center;font-size:10px;margin-top:8px;word-break:break-all;">UPI QR Payload: ${upiUri}</div>` : ''}
                </div>
            `;
            lastGeneratedPrintStream = `ESC/POS ${selectedPrintFormat.toUpperCase()}\n${POS_COMPANY_NAME}\nBILL: ${ctx.referenceNo}\nTOTAL: INR ${ctx.grandTotal.toFixed(2)}${upiUri ? `\nUPI: ${upiUri}` : ''}\nCUT_PAPER`;
        }
        tsplBox.textContent = lastGeneratedPrintStream;
    }

    function copyPrintStream() {
        if (!lastGeneratedPrintStream) return;
        navigator.clipboard?.writeText(lastGeneratedPrintStream);
        alert('Printer command stream copied to clipboard!');
    }

    async function executeThermalPrint() {
        if (lastCompletedOrder && lastCompletedOrder.id) {
            try {
                const url = POS_PRINT_JOB_URL_TEMPLATE.replace('__ID__', String(lastCompletedOrder.id));
                await fetch(url, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': POS_CSRF
                    },
                    body: JSON.stringify({ format: selectedPrintFormat })
                });
            } catch (_) {
                // Local browser print still succeeds
            }
        }
        window.print();
    }

    function printLastOrderReceipt() {
        openPrintStudioModal('80mm');
    }

    document.addEventListener('DOMContentLoaded', function () {
        document.getElementById('pos-table-select')?.addEventListener('change', updateCartSubtitle);
        renderCatalog();
        renderCart();
    });
</script>
@endsection
