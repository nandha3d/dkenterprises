import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class FieldAgentScreen extends StatefulWidget {
  final bool isTamil;
  final CompanyVertical vertical;

  const FieldAgentScreen({
    super.key,
    required this.isTamil,
    required this.vertical,
  });

  @override
  State<FieldAgentScreen> createState() => _FieldAgentScreenState();
}

class _FieldAgentScreenState extends State<FieldAgentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  // Form Controllers for Customer KYC
  final _kycFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cansHeldController = TextEditingController(text: '5');
  final _depositPerCanController = TextEditingController(text: '150');
  String _customerType = 'Commercial (Shop / Office)';

  // Form Controllers for Collection
  final _collectionFormKey = GlobalKey<FormState>();
  int _selectedCustomerId = 1;
  String _selectedCustomerName = 'Santha Provision Stores';
  double _customerOutstanding = 2800.0;
  final _amountCollectedController = TextEditingController();
  final _refController = TextEditingController();
  String _paymentMode = 'Cash';

  bool _isSubmitting = false;

  final List<CustomerItem> _demoCustomers = [
    CustomerItem(id: 1, name: 'Santha Provision Stores', phone: '9842101234', address: '12 North Car St, Town', emptyHeld: 15, depositHeld: 2250),
    CustomerItem(id: 2, name: 'Meenakshi Supermarket', phone: '9842105678', address: '45 Bypass Road, Madurai', emptyHeld: 25, depositHeld: 3750),
    CustomerItem(id: 3, name: 'Texvalley Commercial Complex', phone: '9842109988', address: 'NH-544 Industrial Corridor', emptyHeld: 0, depositHeld: 0),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cansHeldController.dispose();
    _depositPerCanController.dispose();
    _amountCollectedController.dispose();
    _refController.dispose();
    super.dispose();
  }

  void _onboardCustomer() async {
    if (!_kycFormKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final t = widget.isTamil;

    final cans = int.tryParse(_cansHeldController.text) ?? 0;
    final depPerCan = double.tryParse(_depositPerCanController.text) ?? 150.0;
    final totalDep = cans * depPerCan;

    final record = CustomerOnboardRecord(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: 'Madurai',
      companyId: widget.vertical == CompanyVertical.tmws ? 2 : 3,
      customerType: _customerType,
      initialCansHeld: cans,
      depositPerCan: depPerCan,
      totalDeposit: totalDep,
      latitude: 9.9252,
      longitude: 78.1198,
    );

    final res = await _apiService.onboardCustomer(record);

    setState(() => _isSubmitting = false);

    if (mounted) {
      _nameController.clear();
      _phoneController.clear();
      _addressController.clear();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF161F30),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(t ? 'வாடிக்கையாளர் பதிவு முடிந்தது' : 'Customer Onboarded', style: const TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Code: ${res['customer_code'] ?? 'CUST-NEW'}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),
              Text(
                t
                    ? 'தொடக்க கேன் இருப்பு: $cans கேன்கள்\nவசூலான டெபாசிட்: ₹ ${totalDep.toStringAsFixed(2)}\nஜி.பி.எஸ் இடம்: 9.9252° N, 78.1198° E'
                    : 'Initial Cans Issued: $cans Cans\nDeposit Balance: ₹ ${totalDep.toStringAsFixed(2)}\nGPS Pin: 9.9252° N, 78.1198° E',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _submitCollection() async {
    if (!_collectionFormKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCollectedController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isSubmitting = true);
    final t = widget.isTamil;
    final receiptNo = 'REC-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${(1000 + DateTime.now().millisecond)}';

    final record = PaymentCollectionRecord(
      receiptNumber: receiptNo,
      customerId: _selectedCustomerId,
      customerName: _selectedCustomerName,
      outstandingAmount: _customerOutstanding,
      amountCollected: amount,
      paymentMode: _paymentMode,
      transactionRef: _refController.text.trim(),
      collectionDate: DateTime.now(),
      collectedBy: 'Field Agent',
    );

    await _apiService.collectPayment(record);

    setState(() {
      _isSubmitting = false;
      _customerOutstanding -= amount;
    });

    if (mounted) {
      _amountCollectedController.clear();
      _refController.clear();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF161F30),
          title: Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(t ? 'ரசீது உருவாக்கப்பட்டது' : 'Electronic Receipt Issued', style: const TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(receiptNo, style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Customer: $_selectedCustomerName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text('Amount Collected: ₹ ${amount.toStringAsFixed(2)} ($_paymentMode)', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              Text('Remaining Balance: ₹ ${_customerOutstanding.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t ? 'ப்ளூடூத் பிரிண்டருக்கு ரசீது அனுப்பப்பட்டது' : 'Thermal receipt sent to field mobile printer')),
                );
              },
              icon: const Icon(Icons.print, size: 16),
              label: Text(t ? 'ரசீது அச்சிடு' : 'Print Thermal Slip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;

    return Column(
      children: [
        // Role Header Banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_ind, color: Color(0xFF34D399), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          t ? 'கள விற்பனை & வசூல் அலுவலர்' : 'Field Sales & Collections',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('FIELD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t ? 'புதிய வாடிக்கையாளர் பதிவு, நிலுவைத் தொகை வசூல் & நேரடி ஆய்வு' : 'Customer KYC, credit collection, receipting & container audits',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF10B981),
            indicatorWeight: 3,
            labelColor: const Color(0xFF10B981),
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: [
              Tab(
                icon: const Icon(Icons.currency_rupee, size: 18),
                text: t ? 'வசூல் ரசீது' : 'Collections',
              ),
              Tab(
                icon: const Icon(Icons.person_add_alt, size: 18),
                text: t ? 'புதிய KYC' : 'New Client KYC',
              ),
              Tab(
                icon: const Icon(Icons.inventory_2, size: 18),
                text: t ? 'கேன் தணிக்கை' : 'Jar Audit',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Credit Collection & Instant Receipt
              _buildCollectionTab(t),

              // Tab 2: Customer Onboarding KYC
              _buildKycTab(t),

              // Tab 3: Container Physical Audit
              _buildAuditTab(t),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionTab(bool t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _collectionFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outstanding Client Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161F30),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t ? 'வாடிக்கையாளரைத் தேர்வு செய்' : 'Select Customer Account', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _selectedCustomerId,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _demoCustomers.map((c) {
                      return DropdownMenuItem<int>(
                        value: c.id,
                        child: Text('${c.name} (${c.phone})', style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        final found = _demoCustomers.firstWhere((c) => c.id == id);
                        setState(() {
                          _selectedCustomerId = id;
                          _selectedCustomerName = found.name;
                          _customerOutstanding = id == 1 ? 2800.0 : (id == 2 ? 4500.0 : 12000.0);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t ? 'தற்போதைய நிலுவைத் தொகை' : 'Outstanding Receivables', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('₹ ${_customerOutstanding.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('OVERDUE 30+ DAYS', style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount to collect
            Text(t ? 'வசூலிக்கும் தொகை (₹)' : 'Collection Amount (₹)', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountCollectedController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111827),
                prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF10B981)),
                hintText: 'Enter amount to collect',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981))),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter collection amount';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Payment Mode
            Text(t ? 'பணம் செலுத்தும் முறை' : 'Payment Mode', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildModeChoice('Cash', Icons.money, const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildModeChoice('UPI / GPay', Icons.qr_code, const Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                _buildModeChoice('Cheque', Icons.article, const Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 14),

            // Ref No
            Text(t ? 'பரிவர்த்தனை குறிப்பு எண் / காசோலை எண்' : 'Transaction Ref / UTR / Cheque No', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _refController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111827),
                hintText: 'e.g. UPI-99882211 or CHQ-445501',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitCollection,
                icon: const Icon(Icons.receipt, color: Colors.white),
                label: Text(
                  t ? 'ரசீது உருவாக்கு & கணக்கில் வரவு வை' : 'Issue Receipt & Credit Account',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycTab(bool t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _kycFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t ? 'வாடிக்கையாளர் / நிறுவன பெயர்' : 'Customer / Business Name', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111827),
                hintText: 'e.g. Sri Krishna Sweets & Bakery',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: 14),

            Text(t ? 'தொலைபேசி எண் (வாட்ஸ்அப் ரசீதுக்கு)' : 'Mobile Phone (For WhatsApp Receipts)', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111827),
                prefixText: '+91 ',
                prefixStyle: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                hintText: '10-digit mobile number',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
              ),
              validator: (v) => v == null || v.length < 10 ? 'Enter valid 10-digit mobile number' : null,
            ),
            const SizedBox(height: 14),

            Text(t ? 'வணிக வகை' : 'Customer Category', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _customerType,
              dropdownColor: const Color(0xFF0F172A),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111827),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
              ),
              items: [
                'Commercial (Shop / Office)',
                'Residential (Apartment / Villa)',
                'Bulk Corporate (Hospital / College)',
                'Event / Function Bulk Supply',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _customerType = v!),
            ),
            const SizedBox(height: 14),

            Text(t ? 'முழு முகவரி' : 'Full Delivery Address', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111827),
                hintText: 'Door No, Street Name, Landmark',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter address' : null,
            ),
            const SizedBox(height: 14),

            // Container Custody Setup
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t ? 'தொடக்க ஜார் இருப்பு' : 'Opening Jars Held', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _cansHeldController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF111827),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t ? 'டெபாசிட் / கேன் (₹)' : 'Deposit / Jar (₹)', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _depositPerCanController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF111827),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _onboardCustomer,
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: Text(
                  t ? 'வாடிக்கையாளரை உடனடியாக பதிவு செய்' : 'Register Customer & Save GPS Pin',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTab(bool t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161F30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t ? 'நேரடி கேன் இருப்பு தணிக்கை' : 'On-Site Container Custody Audit',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    const Icon(Icons.qr_code_scanner, color: Color(0xFF38BDF8), size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t
                      ? 'வாடிக்கையாளர் இடத்தில் உள்ள உண்மையான காலி ஜார்களை கணக்கிட்டு, லெட்ஜர் முரண்பாடுகளை பதிவு செய்க.'
                      : 'Physically count empty and full jars at client location to prevent container loss and unrecorded swaps.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _demoCustomers.length,
            itemBuilder: (context, index) {
              final c = _demoCustomers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.water_drop, color: Color(0xFF38BDF8), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                          Text('System Custody Balance: ${c.emptyHeld} Cans', style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t ? 'கேன் இருப்பு சரிபார்க்கப்பட்டது: ${c.name}' : 'Audit verified: ${c.name}')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: Text(t ? 'சரிபார்' : 'Audit', style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeChoice(String title, IconData icon, Color color) {
    final isSelected = _paymentMode == title;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMode = title),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : const Color(0xFF334155)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.white60, size: 18),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
