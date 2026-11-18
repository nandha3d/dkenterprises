import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

class _RegularVendor {
  final int? id;
  final String name;
  final String category;
  final String preferredPaymentMode;
  final String? phone;

  const _RegularVendor({
    this.id,
    required this.name,
    required this.category,
    this.preferredPaymentMode = 'Cash',
    this.phone,
  });
}

class QuickPurchaseScreen extends ConsumerStatefulWidget {
  const QuickPurchaseScreen({super.key});

  @override
  ConsumerState<QuickPurchaseScreen> createState() => _QuickPurchaseScreenState();
}

class _QuickPurchaseScreenState extends ConsumerState<QuickPurchaseScreen> {
  static const List<String> _companyBranches = [
    'ARAN1',
    'ARAN2',
    'TMWS',
    'DRINKAA',
    'COMMON',
  ];

  static const List<String> _categories = [
    'Milk',
    'Groceries',
    'Ice Cream',
    'Flour',
    'Fruits',
    'Vegetables',
    'Commercial LPG',
    'Fleet Maintenance',
    'Bakery & Packaging',
    'General Purchase',
  ];

  static const List<String> _gpayAccounts = [
    'GPAY - KAVIN AXIS',
    'KAVIN KVB',
    'KAVIN CANARA',
    'SASI',
    'AXIS OD LOAN',
    'DEEKTEX',
  ];

  static const List<_RegularVendor> _defaultVendors = [
    _RegularVendor(name: 'Amirtha Milk', category: 'Milk', preferredPaymentMode: 'Cash'),
    _RegularVendor(name: 'Local Milk Vendor 2', category: 'Milk', preferredPaymentMode: 'Cash'),
    _RegularVendor(name: 'Sri Murugan Groceries', category: 'Groceries', preferredPaymentMode: 'GPay'),
    _RegularVendor(name: 'Ice Cream Distributor', category: 'Ice Cream', preferredPaymentMode: 'GPay'),
    _RegularVendor(name: 'Maida & Bakery Flour Mill', category: 'Flour', preferredPaymentMode: 'Credit'),
    _RegularVendor(name: 'Pazhamudir Cholai Fruits', category: 'Fruits', preferredPaymentMode: 'Cash'),
    _RegularVendor(name: 'Onion & Vegetable Wholesale', category: 'Vegetables', preferredPaymentMode: 'Cash'),
    _RegularVendor(name: 'Chendhur Gas Agency', category: 'Commercial LPG', preferredPaymentMode: 'GPay'),
    _RegularVendor(name: 'Prabu Auto Spares', category: 'Fleet Maintenance', preferredPaymentMode: 'GPay'),
    _RegularVendor(name: 'Satha Workshop - Sakthi Auto', category: 'Fleet Maintenance', preferredPaymentMode: 'Cash'),
  ];

  final _billNoController = TextEditingController();
  final _itemDescController = TextEditingController();
  final _amountController = TextEditingController();

  List<_RegularVendor> _vendors = List<_RegularVendor>.from(_defaultVendors);
  _RegularVendor? _selectedVendor;
  String _companyBranch = 'ARAN1';
  String _category = 'Milk';
  DateTime _purchaseDate = DateTime.now();
  String _paymentMode = 'Cash'; // 'Cash' | 'GPay' | 'Credit'
  String _gpayAccount = 'GPAY - KAVIN AXIS';
  bool _isLoadingVendors = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _companyBranch = _defaultCompanyBranch();
    _selectedVendor = _vendors.first;
    _category = _selectedVendor!.category;
    _loadRegularVendors();
  }

  String _defaultCompanyBranch() {
    final authState = ref.read(authNotifierProvider);
    final branchCode = (authState.activeBranch?.code ?? '').trim().toUpperCase();
    if (_companyBranches.contains(branchCode)) return branchCode;
    final industry = (authState.activeCompany?.industry ?? '').toLowerCase();
    final compCode = (authState.activeCompany?.code ?? '').toUpperCase();
    if (industry == 'bulk_water' || compCode == 'TMWS') return 'TMWS';
    if (industry == 'packaged_water' || compCode.contains('DKW')) return 'DRINKAA';
    return 'ARAN1';
  }

  @override
  void dispose() {
    _billNoController.dispose();
    _itemDescController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadRegularVendors() async {
    setState(() => _isLoadingVendors = true);
    try {
      final res = await ref
          .read(apiClientProvider)
          .get<List<_RegularVendor>>(
            ApiEndpoints.purchasesRegularVendors,
            fromJson: (raw) {
              final list = raw is Map && raw['data'] is List
                  ? raw['data'] as List
                  : (raw is Map && raw['vendors'] is List
                      ? raw['vendors'] as List
                      : (raw is List ? raw : const []));
              return list
                  .whereType<Map>()
                  .map((v) {
                    final name = (v['name'] ?? v['company_name'] ?? '').toString().trim();
                    if (name.isEmpty) return null;
                    final rawCat = (v['default_category'] ?? v['category'] ?? 'General Purchase').toString().trim();
                    final cat = _categories.contains(rawCat) ? rawCat : 'General Purchase';
                    final rawPay = (v['preferred_payment_mode'] ?? 'Cash').toString();
                    final pay = ['Cash', 'GPay', 'Credit'].contains(rawPay) ? rawPay : 'Cash';
                    return _RegularVendor(
                      id: int.tryParse((v['id'] ?? '').toString()),
                      name: name,
                      category: cat,
                      preferredPaymentMode: pay,
                      phone: v['phone_number']?.toString() ?? v['phone']?.toString(),
                    );
                  })
                  .whereType<_RegularVendor>()
                  .toList();
            },
          )
          .timeout(const Duration(seconds: 6));

      if (!mounted) return;
      if (res.isSuccess && (res.dataOrNull?.isNotEmpty ?? false)) {
        final serverVendors = res.dataOrNull!;
        final seenNames = serverVendors.map((v) => v.name.toLowerCase()).toSet();
        final merged = [
          ...serverVendors,
          ..._defaultVendors.where((d) => !seenNames.contains(d.name.toLowerCase())),
        ];
        setState(() {
          _vendors = merged;
          _selectedVendor = merged.first;
          _category = _selectedVendor!.category;
          _isLoadingVendors = false;
        });
        return;
      }
    } catch (_) {
      // Offline / 404 graceful fallback to built-in regular vendors
    }
    if (mounted) {
      setState(() => _isLoadingVendors = false);
    }
  }

  void _selectVendor(_RegularVendor vendor) {
    setState(() {
      _selectedVendor = vendor;
      if (_categories.contains(vendor.category)) {
        _category = vendor.category;
      }
      if (['Cash', 'GPay', 'Credit'].contains(vendor.preferredPaymentMode)) {
        _paymentMode = vendor.preferredPaymentMode;
      }
    });
  }

  Future<void> _openNewVendorDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    var chosenCategory = _category;

    final created = await showDialog<_RegularVendor>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Regular / New Supplier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Supplier / Shop Name *',
                  hintText: 'e.g. Sri Murugan Dairy',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  hintText: '9876543210',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: chosenCategory,
                decoration: const InputDecoration(labelText: 'Default Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => chosenCategory = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.of(ctx).pop(
                  _RegularVendor(
                    name: name,
                    category: chosenCategory,
                    preferredPaymentMode: _paymentMode,
                    phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  ),
                );
              },
              child: const Text('Add & Select'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();

    if (created != null && mounted) {
      setState(() {
        _vendors = [created, ..._vendors];
        _selectedVendor = created;
        _category = created.category;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null && mounted) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _submitPurchase() async {
    final vendor = _selectedVendor;
    if (vendor == null || vendor.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add a supplier.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid purchase bill amount (> 0).'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);
    final idempotencyKey = const Uuid().v4();
    final dateIso = DateFormat('yyyy-MM-dd').format(_purchaseDate);
    final desc = _itemDescController.text.trim();
    final billNo = _billNoController.text.trim();

    final payload = <String, dynamic>{
      if (vendor.id != null) 'supplier_id': vendor.id,
      'supplier_name': vendor.name,
      if (vendor.phone != null && vendor.phone!.isNotEmpty) 'supplier_phone': vendor.phone,
      'is_new_vendor': vendor.id == null,
      'company_tag': _companyBranch,
      'category': _category,
      if (billNo.isNotEmpty) 'bill_no': billNo,
      'purchase_date': dateIso,
      'item_description': desc.isNotEmpty ? desc : '$_category supply from ${vendor.name}',
      'note': desc,
      'amount': amount,
      'total_amount': amount,
      'payment_mode': _paymentMode,
      'payment_status': _paymentMode == 'Credit' ? 'credit' : 'paid',
      'paid_amount': _paymentMode == 'Credit' ? 0.0 : amount,
      if (_paymentMode == 'GPay') 'payment_account': _gpayAccount,
      if (_paymentMode == 'Cash') 'payment_account': 'CASH',
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final res = await client.post(
      ApiEndpoints.purchasesQuick,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final statusCode = res.failureOrNull?.statusCode;
    if (res.isSuccess) {
      ref.read(dashboardRefreshSignalProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Purchase bill ₹${amount.toStringAsFixed(0)} for ${vendor.name} recorded ($_paymentMode)!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else if (statusCode == 422 || statusCode == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.message ?? 'Validation failed for purchase bill.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.purchasesQuick,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase bill queued offline in Outbox! Will sync automatically.'),
          backgroundColor: AppColors.warning,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedCol = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final skin = RippleSkin.of(context);
    final dateStr = DateFormat('dd.MM.yyyy').format(_purchaseDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Purchase Bill / Supplier'),
        actions: [
          IconButton(
            tooltip: 'Reload Suppliers',
            onPressed: _isLoadingVendors ? null : _loadRegularVendors,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          // 1. Company / Branch Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company / Branch', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _companyBranches.map((branch) {
                      return ChoiceChip(
                        selected: _companyBranch == branch,
                        label: Text(branch, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        onSelected: (_) => setState(() => _companyBranch = branch),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Regular Supplier Quick-Tap Chips + Dropdown + Inline New Vendor
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Regular Supplier', style: AppTypography.label.copyWith(color: textCol)),
                      ),
                      if (_isLoadingVendors)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      TextButton.icon(
                        onPressed: _openNewVendorDialog,
                        icon: const Icon(Icons.add_business_rounded, size: 16),
                        label: const Text('+ New Vendor', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _vendors.map((v) {
                        final selected = _selectedVendor?.name == v.name;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: selected,
                            label: Text(
                              v.name,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            onSelected: (_) => _selectVendor(v),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<_RegularVendor>(
                    value: _vendors.contains(_selectedVendor) ? _selectedVendor : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Selected Supplier',
                      prefixIcon: Icon(Icons.storefront_rounded, size: 20),
                    ),
                    items: _vendors
                        .map(
                          (v) => DropdownMenuItem<_RegularVendor>(
                            value: v,
                            child: Text('${v.name} (${v.category})', overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _selectVendor(v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _categories.contains(_category) ? _category : _categories.last,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Purchase Category',
                      prefixIcon: Icon(Icons.category_rounded, size: 20),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Bill No, Date, Item / Description & Amount
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _billNoController,
                          decoration: const InputDecoration(
                            labelText: 'Bill / Invoice No',
                            hintText: 'e.g. INV-402',
                            prefixIcon: Icon(Icons.receipt_outlined, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Bill Date',
                              prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                            ),
                            child: Text(
                              dateStr,
                              style: TextStyle(fontWeight: FontWeight.w700, color: textCol),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _itemDescController,
                    decoration: const InputDecoration(
                      labelText: 'Item / Description',
                      hintText: 'e.g. 20L Amirtha Milk + Curd / 50kg Onion',
                      prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.title.copyWith(fontSize: 24),
                    decoration: const InputDecoration(
                      labelText: 'Total Bill Amount (₹) *',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.currency_rupee_rounded, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Payment Mode (Cash | GPay w/ account | Credit / Pay Later)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Mode', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'Cash', label: Text('Cash', style: TextStyle(fontSize: 12))),
                        ButtonSegment(value: 'GPay', label: Text('GPay', style: TextStyle(fontSize: 12))),
                        ButtonSegment(value: 'Credit', label: Text('Credit / Pay Later', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {_paymentMode},
                      onSelectionChanged: (sel) => setState(() => _paymentMode = sel.first),
                    ),
                  ),
                  if (_paymentMode == 'GPay') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _gpayAccounts.contains(_gpayAccount) ? _gpayAccount : _gpayAccounts.first,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Paid From GPay / Bank Account',
                        prefixIcon: Icon(Icons.account_balance_rounded, size: 20),
                      ),
                      items: _gpayAccounts
                          .map((a) => DropdownMenuItem<String>(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _gpayAccount = val);
                      },
                    ),
                  ] else if (_paymentMode == 'Credit') ...[
                    const SizedBox(height: 10),
                    Text(
                      'Recorded under Supplier Payables (Credit) for later settlement.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mutedCol),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitPurchase,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: skin.primary,
              foregroundColor: Colors.white,
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: const Text(
              'Save Purchase Bill',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
