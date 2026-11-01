import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class TicketMachineScreen extends StatefulWidget {
  final bool isTamil;

  const TicketMachineScreen({super.key, required this.isTamil});

  @override
  State<TicketMachineScreen> createState() => _TicketMachineScreenState();
}

class _TicketMachineScreenState extends State<TicketMachineScreen> {
  final ApiService _apiService = ApiService();

  // Package products available (open and dynamic)
  final List<WaterPackageItem> _packages = const [
    WaterPackageItem(code: 'CAN-20L', nameEn: '20L Drinking Jar', nameTa: '20L குடிநீர் ஜார்', unitPrice: 35.0, isJar: true),
    WaterPackageItem(code: 'CAN-25L', nameEn: '25L Commercial Jar', nameTa: '25L வணிக ஜார்', unitPrice: 45.0, isJar: true),
    WaterPackageItem(code: 'CAN-10L', nameEn: '10L Compact Dispenser', nameTa: '10L நடுத்தர ஜார்', unitPrice: 25.0, isJar: true),
    WaterPackageItem(code: 'BTL-1L', nameEn: '1L Bottled Pack (12 Pcs)', nameTa: '1L பாட்டில் பாக் (12 шт)', unitPrice: 180.0, isJar: false),
    WaterPackageItem(code: 'BTL-2L', nameEn: '2L Bottled Pack (9 Pcs)', nameTa: '2L பாட்டில் பாக் (9 шт)', unitPrice: 180.0, isJar: false),
    WaterPackageItem(code: 'BTL-500ML', nameEn: '500ML Mini Pack (24 Pcs)', nameTa: '500ML மினி பாக் (24 шт)', unitPrice: 240.0, isJar: false),
  ];

  late WaterPackageItem _selectedPackage;

  // Customers on Beat Route
  final List<CustomerItem> _customers = [
    CustomerItem(id: 1, name: 'அரண் கஃபே - மெயின் கிச்சன் (Aran Cafe)', phone: '9842100010', address: '12 Gandhiji Road, Erode', emptyHeld: 24),
    CustomerItem(id: 2, name: 'பாலாஜி கஃபே (Balaji Cafe)', phone: '9842100011', address: '54 Brough Road, Erode', emptyHeld: 15),
    CustomerItem(id: 3, name: 'ப்ளாக் பெக்கோ டீ (Black Pekoe Tea)', phone: '9842100012', address: '88 Perundurai Road, Erode', emptyHeld: 32),
    CustomerItem(id: 4, name: 'ஒன் கப் டீ (One Cup Tea)', phone: '9842100013', address: '19 Park Road, Erode', emptyHeld: 8),
    CustomerItem(id: 5, name: 'சூர்யா டெக்ஸ் (Surya Tex)', phone: '9842100014', address: '102 Nethaji Road, Erode', emptyHeld: 40),
  ];

  late CustomerItem _selectedCustomer;

  int _deliveredQty = 10;
  int _emptyReturnedQty = 10;
  String _paymentMode = 'cash'; // 'cash', 'upi', 'credit'
  bool _isSubmitting = false;
  Map<String, dynamic>? _lastReceipt;

  // Live truck stock (packaged units)
  int _truckStock = 96;

  @override
  void initState() {
    super.initState();
    _selectedPackage = _packages[0];
    _selectedCustomer = _customers[0];
  }

  void _stepDelivered(int delta) {
    setState(() {
      final next = _deliveredQty + delta;
      if (next >= 1) {
        _deliveredQty = next;
        // Auto-match empty returns if it was identical
        if (_emptyReturnedQty == _deliveredQty - delta && _selectedPackage.isJar) {
          _emptyReturnedQty = next;
        }
      }
    });
  }

  void _stepEmpty(int delta) {
    if (!_selectedPackage.isJar) return;
    setState(() {
      final next = _emptyReturnedQty + delta;
      if (next >= 0) _emptyReturnedQty = next;
    });
  }

  Future<void> _submitDelivery() async {
    setState(() => _isSubmitting = true);

    final total = _deliveredQty * _selectedPackage.unitPrice;
    final cashCollected = _paymentMode == 'cash' ? total : (_paymentMode == 'upi' ? total : 0.0);
    final deliveryNo = 'PKW-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final deliveryRecord = PackagedWaterDeliveryRecord(
      deliveryNumber: deliveryNo,
      routeId: 1,
      customerId: _selectedCustomer.id,
      customerName: _selectedCustomer.name,
      packageCode: _selectedPackage.code,
      quantityDelivered: _deliveredQty,
      emptyReturned: _selectedPackage.isJar ? _emptyReturnedQty : 0,
      unitPrice: _selectedPackage.unitPrice,
      totalAmount: total,
      cashCollected: cashCollected,
      paymentMode: _paymentMode,
      latitude: 11.018221,
      longitude: 76.964119,
      timestamp: DateTime.now(),
    );

    await _apiService.submitPackagedWaterDelivery(deliveryRecord);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _truckStock = (_truckStock - _deliveredQty).clamp(0, 999);
        _lastReceipt = {
          'delivery_no': deliveryNo,
          'customer': _selectedCustomer.name,
          'package': widget.isTamil ? _selectedPackage.nameTa : _selectedPackage.nameEn,
          'qty': _deliveredQty,
          'empty': _selectedPackage.isJar ? _emptyReturnedQty : 0,
          'rate': _selectedPackage.unitPrice,
          'total': total,
          'mode': _paymentMode.toUpperCase(),
          'time': DateTime.now().toLocal().toString().substring(11, 19),
          'lat': 11.0182,
          'lng': 76.9641,
        };
      });

      _showReceiptDialog();
    }
  }

  void _showReceiptDialog() {
    if (_lastReceipt == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.isTamil ? 'டெலிவரி சீட்டு' : 'Delivery Thermal Slip',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Column(
                  children: [
                    Text('DK WATERS — PACKAGED DRINKING WATER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF38BDF8))),
                    Text('TATA ACE BEAT ROUTE 1 · ERODE', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    Divider(color: Color(0xFF334155)),
                  ],
                ),
              ),
              Text('${widget.isTamil ? "ரசீது எண்" : "Slip No"}: ${_lastReceipt!['delivery_no']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text('${widget.isTamil ? "வாடிக்கையாளர்" : "Customer"}: ${_lastReceipt!['customer']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              Text('${widget.isTamil ? "பொருள்" : "Item"}: ${_lastReceipt!['package']}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.isTamil ? "டெலிவரி" : "Delivered"}: ${_lastReceipt!['qty']} шт', style: const TextStyle(color: Colors.white)),
                  Text('${widget.isTamil ? "காலி வரவு" : "Empty In"}: ${_lastReceipt!['empty']} шт', style: const TextStyle(color: Color(0xFF38BDF8))),
                ],
              ),
              const Divider(color: Color(0xFF334155)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.isTamil ? 'மொத்தத் தொகை:' : 'Grand Total:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('₹ ${_lastReceipt!['total']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF34D399))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.isTamil ? "முறை" : "Mode"}: ${_lastReceipt!['mode']}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  Text('${_lastReceipt!['time']} · GPS Fixed', style: const TextStyle(fontSize: 10, color: Color(0xFF10B981))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.print, size: 16, color: Color(0xFF38BDF8)),
            label: Text(widget.isTamil ? 'அச்சிடு / முடி' : 'Print / Done', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _deliveredQty * _selectedPackage.unitPrice;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Stock Status Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0284C7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping, size: 18, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isTamil ? 'வண்டியில் உள்ள இருப்பு:' : 'Stock on Tata Ace:',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        Text(
                          '$_truckStock Units (${_selectedPackage.code})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, size: 12, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 4),
                      Text(
                        widget.isTamil ? 'GPS இணைப்பில்' : 'GPS Active',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. Packaged Water Product Selector
          Text(
            widget.isTamil ? 'குடிநீர் தயாரிப்பு தேர்வு (Package):' : 'Select Packaged Drinking Water:',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<WaterPackageItem>(
                value: _selectedPackage,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                items: _packages.map((pkg) {
                  return DropdownMenuItem(
                    value: pkg,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isTamil ? pkg.nameTa : pkg.nameEn,
                          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '₹${pkg.unitPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPackage = val;
                      if (!val.isJar) _emptyReturnedQty = 0;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Customer Selector
          Text(
            widget.isTamil ? 'வாடிக்கையாளர் / கடை தேர்வு:' : 'Select Customer / Shop:',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CustomerItem>(
                value: _selectedCustomer,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                items: _customers.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c.name, style: const TextStyle(fontSize: 13, color: Colors.white), overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCustomer = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 3. High-Speed Steppers: Units Delivered & Empty Returned
          Row(
            children: [
              // Units Delivered
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.isTamil ? 'டெலிவரி எண்ணிக்கை' : 'Units Delivered',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_deliveredQty',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepBtn('-5', () => _stepDelivered(-5)),
                          const SizedBox(width: 4),
                          _buildStepBtn('-1', () => _stepDelivered(-1)),
                          const SizedBox(width: 4),
                          _buildStepBtn('+1', () => _stepDelivered(1)),
                          const SizedBox(width: 4),
                          _buildStepBtn('+5', () => _stepDelivered(5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Empty Returned (Only enabled if jar packaging)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _selectedPackage.isJar ? const Color(0xFF334155) : Colors.transparent),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.isTamil ? 'திரும்பிய காலி ஜார்' : 'Empty Jars In',
                        style: TextStyle(
                          fontSize: 11,
                          color: _selectedPackage.isJar ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedPackage.isJar ? '$_emptyReturnedQty' : '—',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _selectedPackage.isJar ? const Color(0xFF34D399) : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedPackage.isJar)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStepBtn('-5', () => _stepEmpty(-5)),
                            const SizedBox(width: 4),
                            _buildStepBtn('-1', () => _stepEmpty(-1)),
                            const SizedBox(width: 4),
                            _buildStepBtn('+1', () => _stepEmpty(1)),
                            const SizedBox(width: 4),
                            _buildStepBtn('+5', () => _stepEmpty(5)),
                          ],
                        )
                      else
                        Text(
                          widget.isTamil ? 'ஒருமுறை பயன்பாடு (Non-Return)' : 'Non-Returnable Pack',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Total Fare Highlight
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isTamil ? 'மொத்த பில் தொகை:' : 'Total Payable:',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      '$_deliveredQty × ₹${_selectedPackage.unitPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Text(
                  '₹ ${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 4. Payment Mode Segmented Pills
          Text(
            widget.isTamil ? 'பணம் செலுத்தும் முறை (Payment Mode):' : 'Payment Mode:',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPaymentPill('cash', widget.isTamil ? '💵 பணம் (CASH)' : '💵 CASH', const Color(0xFF059669)),
              const SizedBox(width: 8),
              _buildPaymentPill('upi', widget.isTamil ? '📱 UPI / GPAY' : '📱 GPAY/UPI', const Color(0xFF0284C7)),
              const SizedBox(width: 8),
              _buildPaymentPill('credit', widget.isTamil ? '⏳ கடன் (CREDIT)' : '⏳ CREDIT', const Color(0xFFD97706)),
            ],
          ),
          const SizedBox(height: 22),

          // 5. Rapid Submit Button (<15 Seconds Law)
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitDelivery,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
            ),
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.isTamil ? '✅ பதிவு செய் (CONFIRM DELIVERY <15s)' : '✅ CONFIRM DELIVERY (<15s)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBtn(String label, VoidCallback onTap) {
    return SizedBox(
      height: 28,
      width: 32,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildPaymentPill(String mode, String label, Color activeColor) {
    final isSelected = _paymentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? activeColor : const Color(0xFF334155)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}
