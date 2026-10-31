@extends('backend.layout.main')
@section('content')

<div class="container-fluid py-4">
    <!-- Header -->
    <div class="row align-items-center mb-4">
        <div class="col-md-7">
            <h3 class="font-weight-bold text-dark m-0">
                <i class="dripicons-store text-warning mr-2"></i> Bakery &amp; Cafe Store Operations
            </h3>
            <p class="text-muted small m-0 mt-1">Daily ingredient procurement, evening counter cash drawer closing, daily finance loan instalments &amp; helper wages.</p>
        </div>
        <div class="col-md-5 text-right">
            <button type="button" class="btn btn-warning btn-sm mr-2 shadow-sm text-dark font-weight-bold" data-toggle="modal" data-target="#dailyClosingModal">
                <i class="dripicons-lock"></i> Reconcile Evening Cash Drawer
            </button>
            <button type="button" class="btn btn-primary btn-sm shadow-sm" data-toggle="modal" data-target="#addPurchaseModal">
                <i class="dripicons-plus"></i> + Log Ingredient Expense
            </button>
        </div>
    </div>

    <!-- Daily Drawer Reconciler Summary -->
    <div class="row mb-4">
        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white">
                <span class="small text-muted font-weight-bold">OPENING CASH BALANCE</span>
                <h3 class="font-weight-bold text-dark m-0 mt-2">₹1,500.00</h3>
                <small class="text-muted">Morning drawer float</small>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white">
                <span class="small text-muted font-weight-bold">TOTAL STORE SALES (TODAY)</span>
                <h3 class="font-weight-bold text-success m-0 mt-2">₹16,420.00</h3>
                <small class="text-success">Cash: ₹11.2K &bull; GPay: ₹5.2K</small>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white">
                <span class="small text-muted font-weight-bold">STORE CASH DISBURSEMENTS</span>
                <h3 class="font-weight-bold text-danger m-0 mt-2">₹5,211.60</h3>
                <small class="text-danger">Ingredients, Paati wage &amp; Finance</small>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white">
                <span class="small text-muted font-weight-bold">NET CASH SURRENDER TO OWNER</span>
                <h3 class="font-weight-bold text-primary m-0 mt-2">₹7,500.00</h3>
                <small class="text-primary font-weight-bold">&check; Evening Safe Handover</small>
            </div>
        </div>
    </div>

    <!-- Itemized Daily Ingredient Purchases & Drawer Payouts -->
    <div class="card border-0 shadow-sm rounded bg-white mb-4">
        <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center py-3">
            <h5 class="font-weight-bold m-0 text-dark">
                <i class="dripicons-basket text-warning mr-2"></i> Daily Ingredients &amp; Drawer Payouts
            </h5>
            <span class="badge badge-warning text-dark font-weight-bold px-3 py-2">Total Disbursements: ₹5,211.60</span>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0 text-nowrap">
                    <thead class="thead-light">
                        <tr>
                            <th>#</th>
                            <th>Expense Item</th>
                            <th>Quantity / Details</th>
                            <th>Category</th>
                            <th>Amount (₹)</th>
                            <th>Paid Via</th>
                            <th>Vendor / Payee</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>1</td>
                            <td><strong>Fresh Milk (Cow / Buffalo)</strong></td>
                            <td>45 Litres</td>
                            <td><span class="badge badge-info">Dairy / Raw Material</span></td>
                            <td><strong>₹2,250.00</strong></td>
                            <td><span class="badge badge-light border">Cash Safe Drawer</span></td>
                            <td>Local Dairy Society</td>
                            <td><span class="badge badge-success">&check; Paid</span></td>
                        </tr>
                        <tr>
                            <td>2</td>
                            <td><strong>Tomatoes &amp; Veggies</strong></td>
                            <td>8 kg ripe country tomatoes</td>
                            <td><span class="badge badge-info">Produce / Vegetables</span></td>
                            <td><strong>₹320.00</strong></td>
                            <td><span class="badge badge-light border">Cash Safe Drawer</span></td>
                            <td>Gandhi Market Mandi</td>
                            <td><span class="badge badge-success">&check; Paid</span></td>
                        </tr>
                        <tr>
                            <td>3</td>
                            <td><strong>Tea Dust &amp; Coffee Powder</strong></td>
                            <td>3 kg premium dust blend</td>
                            <td><span class="badge badge-info">Beverage Stock</span></td>
                            <td><strong>₹780.00</strong></td>
                            <td><span class="badge badge-light border">GPay (Kavin)</span></td>
                            <td>Nilgiri Tea Merchant</td>
                            <td><span class="badge badge-success">&check; Paid</span></td>
                        </tr>
                        <tr>
                            <td>4</td>
                            <td><strong>Daily Finance Instalment</strong></td>
                            <td>Daily loan repayment instalment</td>
                            <td><span class="badge badge-warning text-dark">Finance / Loan</span></td>
                            <td><strong>₹1,000.00</strong></td>
                            <td><span class="badge badge-light border">Cash Safe Drawer</span></td>
                            <td>Finance Agent</td>
                            <td><span class="badge badge-success">&check; Paid</span></td>
                        </tr>
                        <tr>
                            <td>5</td>
                            <td><strong>Paati Wages (Store Helper)</strong></td>
                            <td>Daily washing, cleaning &amp; kitchen assistance</td>
                            <td><span class="badge badge-secondary">Wages / Labour</span></td>
                            <td><strong>₹350.00</strong></td>
                            <td><span class="badge badge-light border">Cash Safe Drawer</span></td>
                            <td>Store Helper (Paati)</td>
                            <td><span class="badge badge-success">&check; Paid</span></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<!-- Modal: Reconcile Evening Cash Drawer -->
<div class="modal fade" id="dailyClosingModal" tabindex="-1" role="dialog" aria-labelledby="dailyClosingModalLabel" aria-hidden="true">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header bg-warning text-dark">
                <h5 class="modal-title font-weight-bold" id="dailyClosingModalLabel">
                    <i class="dripicons-lock mr-1"></i> Evening Cash Drawer Reconciliation
                </h5>
                <button type="button" class="close text-dark" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <form id="drawerClosingForm">
                    <div class="form-group">
                        <label class="font-weight-bold">Store Counter Manager</label>
                        <input type="text" class="form-control" value="Kavin Anna (Store In-Charge)" readonly>
                    </div>
                    <div class="form-row">
                        <div class="form-group col-md-6">
                            <label class="font-weight-bold">Opening Drawer Float (₹)</label>
                            <input type="number" class="form-control" value="1500" readonly>
                        </div>
                        <div class="form-group col-md-6">
                            <label class="font-weight-bold">Total Cash Sales (₹)</label>
                            <input type="number" class="form-control" value="11200">
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group col-md-6">
                            <label class="font-weight-bold">Total Cash Paid Out (₹)</label>
                            <input type="number" class="form-control text-danger font-weight-bold" value="5211.60" readonly>
                        </div>
                        <div class="form-group col-md-6">
                            <label class="font-weight-bold">Cash Handover to Owner (₹)</label>
                            <input type="number" class="form-control text-primary font-weight-bold" value="7500">
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="font-weight-bold">Closing Float Left in Register (₹)</label>
                        <input type="number" class="form-control" value="1500">
                    </div>
                    <div class="form-group">
                        <label class="font-weight-bold">Disbursement Notes</label>
                        <textarea class="form-control" rows="2">Paati ₹350 disbursed from drawer. Finance ₹1,000 handed to collection agent. All slips attached.</textarea>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-warning btn-sm font-weight-bold text-dark" onclick="alert('Evening Cash Drawer reconciled and closed successfully!'); $('#dailyClosingModal').modal('hide');">
                    <i class="dripicons-checkmark"></i> Confirm &amp; Close Register
                </button>
            </div>
        </div>
    </div>
</div>

@endsection
