<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>DK Track — Field Driver Mobile Portal</title>
    <link rel="stylesheet" href="<?php echo versioned_asset('vendor/bootstrap/css/bootstrap.min.css') ?>">
    <link rel="stylesheet" href="<?php echo versioned_asset('vendor/dripicons/webfont.css') ?>">
    <style>
        body {
            background-color: #0f172a;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            margin: 0;
            padding: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .mobile-device {
            width: 390px;
            height: 780px;
            background: #ffffff;
            border-radius: 40px;
            box-shadow: 0 25px 60px rgba(0,0,0,0.5), 0 0 0 12px #1e293b;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            position: relative;
        }
        .notch {
            width: 140px;
            height: 24px;
            background: #1e293b;
            border-bottom-left-radius: 16px;
            border-bottom-right-radius: 16px;
            margin: 0 auto;
            position: absolute;
            top: 0;
            left: 50%;
            transform: translateX(-50%);
            z-index: 99;
        }
        .mobile-header {
            background: #0284c7;
            color: #ffffff;
            padding: 34px 16px 12px 16px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .mobile-body {
            flex: 1;
            overflow-y: auto;
            padding: 16px;
            background: #f8fafc;
        }
        .customer-card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 14px;
            margin-bottom: 12px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
    </style>
</head>
<body>

<div class="mobile-device">
    <div class="notch"></div>
    <div class="mobile-header">
        <div>
            <div style="font-size: 0.75rem; opacity: 0.9;">Driver: Vignesh (Tata Ace)</div>
            <strong style="font-size: 1rem;">DK Waters &bull; Packaged Water Delivery</strong>
        </div>
        <span class="badge badge-success px-2 py-1">&bull; GPS Active</span>
    </div>

    <div class="mobile-body">
        <!-- Route Progress -->
        <div class="bg-white p-3 rounded-lg border mb-3 shadow-sm">
            <div class="d-flex justify-content-between align-items-center mb-1">
                <small class="text-muted font-weight-bold">TODAY'S ROUTE PROGRESS</small>
                <span class="badge badge-primary">Stop 14 of 16</span>
            </div>
            <div class="progress" style="height: 8px;">
                <div class="progress-bar bg-success" style="width: 87.5%;"></div>
            </div>
            <div class="d-flex justify-content-between small text-muted mt-2">
                <span>Loaded: 70 Units</span>
                <span>Delivered: 58</span>
                <span>Empties: 54</span>
            </div>
        </div>

        <!-- Target Customer Drop -->
        <div class="customer-card border-primary">
            <div class="d-flex justify-content-between align-items-center">
                <span class="badge badge-warning text-dark font-weight-bold">NEXT STOP #14</span>
                <span class="text-success small font-weight-bold">&check; Geo-Lock Pinned</span>
            </div>
            <h5 class="font-weight-bold text-dark mt-2 mb-1">Aran Cafe - 1</h5>
            <small class="text-muted d-block mb-3">Race Course Road &bull; 98421 55601</small>

            <div class="form-row mb-2">
                <div class="col-6">
                    <label class="small font-weight-bold mb-1">Delivered (Units)</label>
                    <input type="number" class="form-control font-weight-bold text-primary" value="15" id="dropCount">
                </div>
                <div class="col-6">
                    <label class="small font-weight-bold mb-1">Empties Returned</label>
                    <input type="number" class="form-control font-weight-bold text-success" value="15" id="emptyCount">
                </div>
            </div>

            <div class="form-row mb-3">
                <div class="col-6">
                    <label class="small font-weight-bold mb-1">Rate / Unit</label>
                    <input type="text" class="form-control" value="₹20.00" readonly>
                </div>
                <div class="col-6">
                    <label class="small font-weight-bold mb-1">Cash Collected</label>
                    <input type="number" class="form-control font-weight-bold text-success" value="300" id="cashAmt">
                </div>
            </div>

            <div class="alert alert-light border small py-2 mb-3">
                <i class="dripicons-location text-success mr-1"></i> Phone GPS: <code>11.018221, 76.964119</code><br>
                <span class="text-success font-weight-bold">&check; Inside Shop Radius (14m away)</span>
            </div>

            <button class="btn btn-success btn-block font-weight-bold py-2" onclick="confirmDrop()">
                <i class="dripicons-checkmark mr-1"></i> Confirm Drop &amp; Issue Receipt
            </button>
        </div>
    </div>
</div>

<script>
function confirmDrop() {
    alert("Drop Confirmed!\n- 15 Units Delivered\n- 15 Empty Containers Received\n- ₹300 Cash Collected\n- GPS Coordinates Verified!\nLedger and customer balance updated in real-time.");
}
</script>

</body>
</html>
