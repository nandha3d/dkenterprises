import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class TicketMachineScreen extends StatefulWidget {
  final bool isTamil;

  const TicketMachineScreen({super.key, required this.isTamil});

  @override
  State<TicketMachineScreen> createState() => _TicketMachineScreenState();
}

class _TicketMachineScreenState extends State<TicketMachineScreen> {
  final ApiService _apiService = ApiService();

  List<WaterPackageItem> _packages = [];
  List<CustomerItem> _customers = [];
  WaterPackageItem? _selectedPackage;
  CustomerItem? _selectedCustomer;

  bool _isLoading = true;
  int _deliveredQty = 10;
  int _emptyReturnedQty = 10;
  String _paymentMode = 'cash'; // 'cash', 'upi', 'credit'
  bool _isSubmitting = false;
  Map<String, dynamic>? _lastReceipt;

  int _truckStock = 96;

  @override
  void initState() {
    super.initState();
    _loadApiData();
  }

  Future<void> _loadApiData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _apiService.fetchCustomers(),
      _apiService.fetchProducts(),
    ]);

    final rawCusts = results[0];
    final rawProds = results[1];

    final customers = rawCusts.map((c) => CustomerItem(
      id: c['id'] ?? 0,
      name: c['name'] ?? 'Customer',
      phone: c['phone'] ?? '',
      address: c['address'] ?? '',
      emptyHeld: c['cans_held'] ?? 0,
    )).toList();

    final packages = rawProds.map((p) {
      final name = p['name'] ?? 'Packaged Water';
      final price = (p['price'] ?? 35.0).toDouble();
      final code = p['code'] ?? 'WAT-20L';
      final isJar = !code.toString().contains('BTL');
      return WaterPackageItem(
        code: code,
        nameEn: name,
        nameTa: name,
        unitPrice: price,
        isJar: isJar,
      );
    }).toList();

    if (mounted) {
      setState(() {
        _customers = customers.isNotEmpty
            ? customers
            : [CustomerItem(id: 1, name: 'Default Customer', phone: '9842100000', address: 'Town Route', emptyHeld: 10)];
        _packages = packages.isNotEmpty
            ? packages
            : [const WaterPackageItem(code: 'CAN-20L', nameEn: '20L Drinking Jar', nameTa: '20L குடிநீர் ஜார்', unitPrice: 35.0, isJar: true)];
        _selectedCustomer = _customers.first;
        _selectedPackage = _packages.first;
        _isLoading = false;
      });
    }
  }

  void _stepDelivered(int delta) {
    setState(() {
      final next = _deliveredQty + delta;
      if (next >= 1) {
        _deliveredQty = next;
      }
    });
  }

  void _stepEmpty(int delta) {
    setState(() {
      final next = _emptyReturnedQty + delta;
      if (next >= 0) {
        _emptyReturnedQty = next;
      }
    });
  }

  double get _totalFare {
    if (_selectedPackage == null) return 0.0;
    return _deliveredQty * _selectedPackage!.unitPrice;
  }

  Future<void> _submitDelivery() async {
    if (_selectedCustomer == null || _selectedPackage == null) return;

    setState(() => _isSubmitting = true);

    final record = WaterCanDeliveryRecord(
      deliveryNumber: 'DEL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      routeId: 1,
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      cansDelivered: _deliveredQty,
      emptyCansCollected: _emptyReturnedQty,
      canRate: _selectedPackage!.unitPrice,
      totalAmount: _totalFare,
      paymentMode: _paymentMode,
      deliveryTime: DateTime.now(),
      balanceCansHeld: _selectedCustomer!.emptyHeld + (_deliveredQty - _emptyReturnedQty),
    );

    final res = await _apiService.submitCanDelivery(record);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _truckStock = (_truckStock - _deliveredQty).clamp(0, 999);
        _lastReceipt = {
          'delivery_no': record.deliveryNumber,
          'customer': _selectedCustomer!.name,
          'package': _selectedPackage!.name(widget.isTamil),
          'qty': _deliveredQty,
          'empty': _emptyReturnedQty,
          'rate': _selectedPackage!.unitPrice,
          'total': _totalFare,
          'mode': _paymentMode.toUpperCase(),
          'timestamp': DateTime.now().toLocal().toString().substring(0, 16),
          'offline': res['offline_queued'] == true,
        };
      });

      _showReceiptSheet();
    }
  }

  void _showReceiptSheet() {
    if (_lastReceipt == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppColors.brandEmerald, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      widget.isTamil ? 'மின்னணு ரசீது' : 'Delivery Electronic Slip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text(context),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.isDark(context) ? Colors.black38 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'DK WATERS — PACKAGED DRINKING WATER',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: AppColors.text(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Slip No: ${_lastReceipt!['delivery_no']}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                      Text('${_lastReceipt!['mode']}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandEmerald)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Customer: ${_lastReceipt!['customer']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('Package: ${_lastReceipt!['package']} x ${_lastReceipt!['qty']}', style: const TextStyle(fontSize: 11)),
                  Text('Empty Jars Collected: ${_lastReceipt!['empty']}', style: const TextStyle(fontSize: 11, color: AppColors.brandSky)),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL AMOUNT:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      Text('₹ ${_lastReceipt!['total'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.brandEmerald)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roleDeliveryDriver,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                widget.isTamil ? 'முடிந்தது (அடுத்த வாடிக்கையாளர்)' : 'Done (Next Customer)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final canPop = Navigator.canPop(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.scaffold(context),
        body: const Center(child: CircularProgressIndicator(color: AppColors.roleDeliveryDriver)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: canPop
          ? AppBar(
              title: Text(
                t ? 'குடிநீர் விநியோக டிக்கெட்' : 'Water Delivery Ticketing',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            )
          : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Truck Stock Glass Card
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 16,
              tintColor: AppColors.roleDeliveryDriver,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.roleDeliveryDriver.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_shipping, color: AppColors.roleDeliveryDriver, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t ? 'டாடா ஏஸ் லாரி இருப்பு' : 'Truck Stock (Tata Ace)',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted(context), fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$_truckStock Jars Loaded',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.text(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandEmerald.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('LIVE ROUTE', style: TextStyle(color: AppColors.brandEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Customer Selection Glass Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t ? 'வாடிக்கையாளர் (பீட் ரூட்)' : 'Customer (Beat Route)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text(context)),
                      ),
                      Text(
                        '${_customers.length} On Route',
                        style: TextStyle(fontSize: 10, color: AppColors.textDim(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CustomerItem>(
                          isExpanded: true,
                          value: _selectedCustomer,
                          dropdownColor: AppColors.card(context),
                          items: _customers.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                '${c.name} (${c.emptyHeld} Cans)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCustomer = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Package Selection Glass Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t ? 'குடிநீர் தயாரிப்பு (பேக்கேஜ்)' : 'Package Product',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text(context)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _packages.map((pkg) {
                      final isSel = _selectedPackage?.code == pkg.code;
                      return InkWell(
                        onTap: () => setState(() => _selectedPackage = pkg),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.roleDeliveryDriver.withOpacity(0.18)
                                : AppColors.card(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? AppColors.roleDeliveryDriver : AppColors.border(context),
                              width: isSel ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            '${pkg.name(t)} · ₹${pkg.unitPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel ? AppColors.roleDeliveryDriver : AppColors.text(context),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Quantities Delivered & Returned Glass Cards
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 18,
                  tintColor: AppColors.roleDeliveryDriver,
                  child: Column(
                    children: [
                      Text(
                        t ? 'விநியோகம் (Cans)' : 'Delivered Qty',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted(context)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_deliveredQty',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.roleDeliveryDriver),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _stepDelivered(-1),
                            color: AppColors.text(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _stepDelivered(1),
                            color: AppColors.roleDeliveryDriver,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 18,
                  tintColor: AppColors.brandEmerald,
                  child: Column(
                    children: [
                      Text(
                        t ? 'திரும்பியது (Empty)' : 'Empty Returned',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted(context)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_emptyReturnedQty',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.brandEmerald),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _stepEmpty(-1),
                            color: AppColors.text(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _stepEmpty(1),
                            color: AppColors.brandEmerald,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Payment Mode Selector Glass Card
          GlassCard(
            padding: const EdgeInsets.all(14),
            borderRadius: 18,
            child: Row(
              children: [
                _buildPayPill('cash', t ? 'ரொக்கம்' : 'Cash', Icons.payments, AppColors.brandEmerald),
                const SizedBox(width: 8),
                _buildPayPill('upi', 'UPI QR', Icons.qr_code, AppColors.roleSuperAdmin),
                const SizedBox(width: 8),
                _buildPayPill('credit', t ? 'கடன்' : 'Credit', Icons.credit_score, AppColors.brandAmber),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Submit Delivery Glass Action Button
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.roleDeliveryDriver, AppColors.brandNavy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.roleDeliveryDriver.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isSubmitting ? null : _submitDelivery,
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              t ? 'விநியோகம் உறுதிசெய் · ₹ ${_totalFare.toStringAsFixed(0)}' : 'Issue Ticket · ₹ ${_totalFare.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

  Widget _buildPayPill(String mode, String label, IconData icon, Color color) {
    final isSel = _paymentMode == mode;
    return Expanded(
      child: GlassCard(
        isInteractive: true,
        padding: const EdgeInsets.symmetric(vertical: 10),
        borderRadius: 12,
        tintColor: isSel ? color : null,
        borderColor: isSel ? color : null,
        borderWidth: isSel ? 1.8 : 1.0,
        onTap: () => setState(() => _paymentMode = mode),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSel ? color : AppColors.textMuted(context)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                color: isSel ? color : AppColors.text(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
