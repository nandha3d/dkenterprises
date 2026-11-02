import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

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
  final String _customerType = 'Commercial (Shop / Office)';

  // Form Controllers for Collection
  final _collectionFormKey = GlobalKey<FormState>();
  Map<String, dynamic>? _selectedCustomer;
  final _amountCollectedController = TextEditingController();
  final _refController = TextEditingController();
  String _paymentMode = 'Cash';

  bool _isSubmitting = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final data = await _apiService.fetchCustomers();
    if (mounted) {
      setState(() {
        _customers = data;
        if (_customers.isNotEmpty) {
          _selectedCustomer = _customers.first;
        }
        _isLoading = false;
      });
    }
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

  Future<void> _onboardCustomer() async {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t
                ? 'புதிய வாடிக்கையாளர் [${res['customer_code'] ?? 'CUST-OK'}] பதிவு செய்யப்பட்டு கிளவுடில் சேமிக்கப்பட்டது!'
                : 'Customer registered & synced to Cloud ERP: ${res['customer_code'] ?? 'OK'}',
          ),
          backgroundColor: AppColors.brandEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadCustomers();
    }
  }

  Future<void> _submitCollection() async {
    if (!_collectionFormKey.currentState!.validate() || _selectedCustomer == null) return;

    setState(() => _isSubmitting = true);
    final t = widget.isTamil;
    final amount = double.tryParse(_amountCollectedController.text) ?? 0.0;

    final receiptNo = 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final record = PaymentCollectionRecord(
      customerId: _selectedCustomer!['id'],
      customerName: _selectedCustomer!['name'] ?? '',
      receiptNumber: receiptNo,
      outstandingAmount: 2500.0,
      amountCollected: amount,
      paymentMode: _paymentMode,
      transactionRef: _refController.text.isEmpty ? 'CASH-SETTLE' : _refController.text,
      collectionDate: DateTime.now(),
    );

    await _apiService.collectPayment(record);

    setState(() => _isSubmitting = false);

    if (mounted) {
      _amountCollectedController.clear();
      _refController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t
                ? 'ரசீது $receiptNo: ₹$amount வசூலிக்கப்பட்டு GL 1010-ல் பதிவு செய்யப்பட்டது!'
                : 'Receipt $receiptNo: ₹$amount credited to GL 1010!',
          ),
          backgroundColor: AppColors.brandEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          // Frosted Glass Tab Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: GlassCard(
              padding: const EdgeInsets.all(4),
              borderRadius: 14,
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandPurple, AppColors.brandNavy],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted(context),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                tabs: [
                  Tab(text: t ? 'KYC வாடிக்கையாளர்' : 'KYC Onboarding'),
                  Tab(text: t ? 'கடன் வசூல்' : 'Credit Collection'),
                  Tab(text: t ? 'கேன் இருப்பு' : 'Jars Ledger'),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: KYC Customer Onboarding
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 20,
                    child: Form(
                      key: _kycFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.brandEmerald.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.person_add, color: AppColors.brandEmerald, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t ? 'புதிய வாடிக்கையாளர் இணைப்பு (KYC)' : 'New Customer Registration',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.text(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Customer Name
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(color: AppColors.text(context), fontSize: 13),
                            decoration: InputDecoration(
                              labelText: t ? 'கடை / வாடிக்கையாளர் பெயர்' : 'Shop / Customer Name',
                              labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 12),
                              prefixIcon: const Icon(Icons.storefront, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) => v!.isEmpty ? (t ? 'பெயர் தேவை' : 'Name required') : null,
                          ),
                          const SizedBox(height: 12),

                          // Phone Number
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: AppColors.text(context), fontSize: 13),
                            decoration: InputDecoration(
                              labelText: t ? 'தொலைபேசி எண் (WhatsApp)' : 'Mobile Number',
                              labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 12),
                              prefixIcon: const Icon(Icons.phone, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) => v!.isEmpty ? (t ? 'எண் தேவை' : 'Phone required') : null,
                          ),
                          const SizedBox(height: 12),

                          // Address
                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            style: TextStyle(color: AppColors.text(context), fontSize: 13),
                            decoration: InputDecoration(
                              labelText: t ? 'முழு முகவரி & லேண்ட்மார்க்' : 'Delivery Address & Landmark',
                              labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 12),
                              prefixIcon: const Icon(Icons.location_on, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) => v!.isEmpty ? (t ? 'முகவரி தேவை' : 'Address required') : null,
                          ),
                          const SizedBox(height: 12),

                          // Initial Cans & Deposit
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cansHeldController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: AppColors.text(context), fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: t ? 'துவக்க கேன்கள்' : 'Initial Cans Held',
                                    labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 11),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _depositPerCanController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: AppColors.text(context), fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: t ? 'முன்பணம்/கேன் (₹)' : 'Deposit/Can (₹)',
                                    labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 11),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Submit Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _onboardCustomer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      t ? 'பதிவு செய்து ஆன்லைனில் சேமி' : 'Register Customer & Save KYC',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // TAB 2: Credit Collection
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 20,
                    child: Form(
                      key: _collectionFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.brandPurple.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.payments, color: AppColors.brandPurple, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t ? 'கடன் வசூல் ரசீது (GL 1030 -> 1010)' : 'Customer Credit Payment Collection',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.text(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Select Customer Dropdown
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedCustomer,
                            style: TextStyle(color: AppColors.text(context), fontSize: 13),
                            decoration: InputDecoration(
                              labelText: t ? 'வாடிக்கையாளரைத் தேர்வு செய்' : 'Select Customer',
                              labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 12),
                              prefixIcon: const Icon(Icons.person, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _customers.map((c) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: c,
                                child: Text(c['name'] ?? 'Customer'),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedCustomer = val),
                          ),
                          const SizedBox(height: 14),

                          // Amount to Collect
                          TextFormField(
                            controller: _amountCollectedController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppColors.text(context), fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: t ? 'வசூலித்த தொகை (₹)' : 'Amount Collected (₹)',
                              labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 12),
                              prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) => v!.isEmpty ? (t ? 'தொகை தேவை' : 'Amount required') : null,
                          ),
                          const SizedBox(height: 14),

                          // Payment Mode Segmented Pills
                          Row(
                            children: ['Cash', 'UPI', 'Cheque'].map((mode) {
                              final isSelected = _paymentMode == mode;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text(mode),
                                    selected: isSelected,
                                    selectedColor: AppColors.brandPurple,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textMuted(context),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                    onSelected: (val) => setState(() => _paymentMode = mode),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitCollection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandEmerald,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      t ? 'ரசீது உருவாக்கி வரவு வை' : 'Issue Receipt & Credit Ledger',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // TAB 3: Jars Ledger
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.brandPurple))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _customers.length,
                        itemBuilder: (ctx, idx) {
                          final c = _customers[idx];
                          final cans = c['cans_held'] ?? 0;
                          final dep = (c['deposit_held'] ?? 0.0).toDouble();

                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            borderRadius: 16,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandSky.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.water_drop, color: AppColors.brandSky, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['name'] ?? 'Customer',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: AppColors.text(context),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${c['phone'] ?? ''} • ${c['city'] ?? ''}',
                                        style: TextStyle(color: AppColors.textMuted(context), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$cans Cans',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: AppColors.brandSky,
                                      ),
                                    ),
                                    Text(
                                      '₹${dep.toStringAsFixed(0)} Dep',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.brandAmber,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
