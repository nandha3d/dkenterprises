import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

class QuickExpenseScreen extends ConsumerStatefulWidget {
  final bool embedded;
  final bool? initialBatchMode;

  const QuickExpenseScreen({
    super.key,
    this.embedded = false,
    this.initialBatchMode,
  });

  @override
  ConsumerState<QuickExpenseScreen> createState() => _QuickExpenseScreenState();
}

class _BatchLedgerRow {
  DateTime date;
  String entryType; // 'OUT' | 'IN'
  String companyTag;
  String paymentAccount;
  final TextEditingController amountCtrl;
  final TextEditingController vehicleStaffCtrl;
  final TextEditingController billNoCtrl;
  final TextEditingController descriptionCtrl;

  _BatchLedgerRow({
    required this.date,
    this.entryType = 'OUT',
    this.companyTag = 'TM WATER SUPPLY',
    this.paymentAccount = 'GPAY - KAVIN AXIS',
    String amount = '',
    String vehicleStaff = '',
    String billNo = '',
    String description = '',
  })  : amountCtrl = TextEditingController(text: amount),
        vehicleStaffCtrl = TextEditingController(text: vehicleStaff),
        billNoCtrl = TextEditingController(text: billNo),
        descriptionCtrl = TextEditingController(text: description);

  double get amount => double.tryParse(amountCtrl.text.trim()) ?? 0.0;

  void dispose() {
    amountCtrl.dispose();
    vehicleStaffCtrl.dispose();
    billNoCtrl.dispose();
    descriptionCtrl.dispose();
  }
}

class _AccountSummaryItem {
  final String name;
  final double opening;
  final double current;

  const _AccountSummaryItem({
    required this.name,
    this.opening = 0.0,
    this.current = 0.0,
  });
}

class _QuickExpenseScreenState extends ConsumerState<QuickExpenseScreen> {
  static const List<String> _companyTags = [
    'TM WATER SUPPLY',
    'DRINKAA',
    'ARAN1',
    'ARAN2',
    'ARAN',
    'FAMILY',
    'COMMON',
  ];

  static const List<String> _paymentAccounts = [
    'GPAY - KAVIN AXIS',
    'CASH',
    'KAVIN KVB',
    'KAVIN CANARA',
    'SASI',
    'AXIS OD LOAN',
    'DEEKTEX',
  ];

  static const List<String> _defaultVehicleStaff = [
    'platina',
    'SURESH',
    'TN 47 M 4585',
    'RAJA',
  ];

  static const List<_AccountSummaryItem> _defaultAccounts = [
    _AccountSummaryItem(name: 'Kavin Axis'),
    _AccountSummaryItem(name: 'Sasi'),
    _AccountSummaryItem(name: 'Axis OD LOAN'),
    _AccountSummaryItem(name: 'DeekTex'),
    _AccountSummaryItem(name: 'Kavin KVB'),
    _AccountSummaryItem(name: 'Kavin Canara'),
    _AccountSummaryItem(name: 'CASH'),
  ];

  // Single Entry controllers
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _category = 'Fuel / Diesel';
  String _paymentMode = 'Cash';

  // Mode & Sheet Batch state
  late bool _isBatchMode;
  bool _isSubmitting = false;
  bool _isLoadingSummary = false;
  final List<_BatchLedgerRow> _rows = [];
  List<_AccountSummaryItem> _accountBalances = _defaultAccounts;
  List<String> _vehicleStaffSuggestions = List<String>.from(_defaultVehicleStaff);
  double _serverTotalIn = 0.0;
  double _serverTotalOut = 0.0;

  final List<String> _categories = [
    'Fuel / Diesel',
    'Food & Tea',
    'Toll / Parking',
    'Vehicle Maintenance',
    'Stationary & Printing',
    'Miscellaneous Expense',
  ];

  @override
  void initState() {
    super.initState();
    final isAdmin = ref.read(activeRippleRoleProvider) == RippleRole.admin;
    _isBatchMode = widget.initialBatchMode ?? isAdmin;
    _rows.add(
      _BatchLedgerRow(
        date: DateTime.now(),
        entryType: 'OUT',
        companyTag: _defaultCompanyTagFromContext(),
        paymentAccount: 'GPAY - KAVIN AXIS',
      ),
    );
    _fetchAccountsSummary();
  }

  String _defaultCompanyTagFromContext() {
    final activeCompany = ref.read(authNotifierProvider).activeCompany;
    final activeBranch = ref.read(authNotifierProvider).activeBranch;
    final branchCode = (activeBranch?.code ?? '').trim().toUpperCase();
    if (branchCode == 'ARAN1' || branchCode == 'ARAN2') {
      return branchCode;
    }
    final industry = (activeCompany?.industry ?? '').toLowerCase();
    final code = (activeCompany?.code ?? '').toUpperCase();
    if (industry == 'bulk_water' || code == 'TMWS') return 'TM WATER SUPPLY';
    if (industry == 'packaged_water' || code.contains('DKW')) return 'DRINKAA';
    if (industry == 'cafe_bakery' || code.contains('ARAN')) return 'ARAN1';
    return 'TM WATER SUPPLY';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchAccountsSummary() async {
    setState(() => _isLoadingSummary = true);
    try {
      final res = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>(
            ApiEndpoints.expensesAccountsSummary,
            fromJson: (data) => data is Map
                ? Map<String, dynamic>.from(data)
                : <String, dynamic>{},
          )
          .timeout(const Duration(seconds: 6));

      if (!mounted) return;
      if (res.isSuccess) {
        final raw = res.dataOrNull ?? const <String, dynamic>{};
        final payload = raw['data'] is Map
            ? Map<String, dynamic>.from(raw['data'] as Map)
            : raw;

        final rawAccounts = payload['accounts'];
        final parsedAccounts = <_AccountSummaryItem>[];
        if (rawAccounts is List) {
          for (final item in rawAccounts.whereType<Map>()) {
            final name = (item['name'] ?? item['account'] ?? '').toString().trim();
            if (name.isEmpty) continue;
            parsedAccounts.add(
              _AccountSummaryItem(
                name: name,
                opening: double.tryParse((item['opening'] ?? item['opening_balance'] ?? 0).toString()) ?? 0.0,
                current: double.tryParse((item['current'] ?? item['current_balance'] ?? item['balance'] ?? 0).toString()) ?? 0.0,
              ),
            );
          }
        }

        final rawTags = payload['vehicle_staff_tags'] ?? payload['staff_vehicle_tags'];
        final parsedTags = <String>{..._defaultVehicleStaff};
        if (rawTags is List) {
          for (final t in rawTags) {
            final s = t.toString().trim();
            if (s.isNotEmpty) parsedTags.add(s);
          }
        }

        setState(() {
          if (parsedAccounts.isNotEmpty) {
            _accountBalances = parsedAccounts;
          }
          _vehicleStaffSuggestions = parsedTags.toList();
          _serverTotalIn = double.tryParse((payload['total_in'] ?? 0).toString()) ?? 0.0;
          _serverTotalOut = double.tryParse((payload['total_out'] ?? 0).toString()) ?? 0.0;
          _isLoadingSummary = false;
        });
        return;
      }
    } catch (_) {
      // Graceful fallback to defaults when offline or 404
    }
    if (mounted) {
      setState(() => _isLoadingSummary = false);
    }
  }

  double get _batchTotalIn => _rows
      .where((r) => r.entryType == 'IN')
      .fold<double>(0.0, (sum, r) => sum + r.amount);

  double get _batchTotalOut => _rows
      .where((r) => r.entryType == 'OUT')
      .fold<double>(0.0, (sum, r) => sum + r.amount);

  void _addBatchRow() {
    final last = _rows.isNotEmpty ? _rows.last : null;
    setState(() {
      _rows.add(
        _BatchLedgerRow(
          date: last?.date ?? DateTime.now(),
          entryType: last?.entryType ?? 'OUT',
          companyTag: last?.companyTag ?? _defaultCompanyTagFromContext(),
          paymentAccount: last?.paymentAccount ?? 'GPAY - KAVIN AXIS',
        ),
      );
    });
  }

  void _removeBatchRow(int index) {
    if (_rows.length <= 1 || index < 0 || index >= _rows.length) return;
    setState(() {
      final removed = _rows.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _pickRowDate(int index) async {
    final current = _rows[index].date;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() => _rows[index].date = picked);
    }
  }

  Future<void> _submitSingleExpense() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid expense amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final payload = {
      'category': _category,
      'amount': amount,
      'payment_mode': _paymentMode,
      'note': _noteController.text.trim(),
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final idempotencyKey = const Uuid().v4();

    final result = await client.post(
      ApiEndpoints.expenses,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ref.read(dashboardRefreshSignalProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense recorded and debited from cash account!'),
          backgroundColor: AppColors.success,
        ),
      );
      if (widget.embedded) {
        _amountController.clear();
        _noteController.clear();
        setState(() => _isSubmitting = false);
      } else {
        Navigator.of(context).pop();
      }
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.expenses,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense queued offline in Outbox! Will sync automatically.'),
          backgroundColor: AppColors.warning,
        ),
      );
      if (widget.embedded) {
        _amountController.clear();
        _noteController.clear();
        setState(() => _isSubmitting = false);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _submitBatchRows() async {
    final validRows = <Map<String, dynamic>>[];
    for (var i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      if (r.amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Row #${i + 1}: Please enter an Amount greater than 0.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      final dateIso = DateFormat('yyyy-MM-dd').format(r.date);
      final desc = r.descriptionCtrl.text.trim();
      final vehStaff = r.vehicleStaffCtrl.text.trim();
      final billNo = r.billNoCtrl.text.trim();
      validRows.add({
        'entry_date': dateIso,
        'entry_type': r.entryType,
        'company_tag': r.companyTag,
        'payment_account': r.paymentAccount,
        'amount': r.amount,
        if (vehStaff.isNotEmpty) 'vehicle_or_staff_tag': vehStaff,
        if (billNo.isNotEmpty) 'bill_no': billNo,
        'category': r.entryType == 'IN' ? 'Cash Inflow' : 'Operational Expense',
        'description': desc,
        'note': desc,
      });
    }

    if (validRows.isEmpty) return;

    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);
    final idempotencyKey = const Uuid().v4();

    final payload = {
      'rows': validRows,
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final result = await client.post(
      ApiEndpoints.expensesBatch,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;

    final statusCode = result.failureOrNull?.statusCode;
    if (result.isSuccess) {
      ref.read(dashboardRefreshSignalProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Posted ${validRows.length} ledger rows to 2026 Accounts!'),
          backgroundColor: AppColors.success,
        ),
      );
      _resetBatchRowsAfterSubmit();
      await _fetchAccountsSummary();
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      if (!widget.embedded && mounted) {
        Navigator.of(context).pop();
      }
    } else if (statusCode == 422 || statusCode == 403) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failureOrNull?.message ?? 'Validation failed on batch ledger.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.expensesBatch,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${validRows.length} rows queued offline in Outbox! Will sync automatically.'),
          backgroundColor: AppColors.warning,
        ),
      );
      _resetBatchRowsAfterSubmit();
      setState(() => _isSubmitting = false);
      if (!widget.embedded) {
        Navigator.of(context).pop();
      }
    }
  }

  void _resetBatchRowsAfterSubmit() {
    final lastCompany = _rows.isNotEmpty ? _rows.last.companyTag : _defaultCompanyTagFromContext();
    final lastAccount = _rows.isNotEmpty ? _rows.last.paymentAccount : 'GPAY - KAVIN AXIS';
    for (final r in _rows) {
      r.dispose();
    }
    _rows
      ..clear()
      ..add(
        _BatchLedgerRow(
          date: DateTime.now(),
          entryType: 'OUT',
          companyTag: lastCompany,
          paymentAccount: lastAccount,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedCol = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final skin = RippleSkin.of(context);

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(_isBatchMode ? '2026 Accounts Sheet Batch' : 'Quick 20s Expense'),
              actions: [
                if (_isBatchMode)
                  IconButton(
                    tooltip: 'Refresh Account Balances',
                    onPressed: _isLoadingSummary ? null : _fetchAccountsSummary,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
              ],
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.receipt_long_rounded, size: 16),
                    label: Text('Single Entry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.table_chart_rounded, size: 16),
                    label: Text('Sheet Batch (2026 Accounts)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
                selected: {_isBatchMode},
                onSelectionChanged: (sel) {
                  setState(() => _isBatchMode = sel.first);
                },
              ),
            ),
          ),
          Expanded(
            child: _isBatchMode
                ? _buildBatchModeBody(textCol, mutedCol, borderCol, skin, isDark)
                : _buildSingleModeBody(textCol),
          ),
        ],
      ),
      bottomNavigationBar: _isBatchMode
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                border: Border(top: BorderSide(color: borderCol, width: 1)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_rows.length} ${_rows.length == 1 ? 'Row' : 'Rows'} Ready',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mutedCol),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 8,
                            children: [
                              Text(
                                'IN ₹${_batchTotalIn.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                              Text(
                                'OUT ₹${_batchTotalOut.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitBatchRows,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(168, 48),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text('Submit All (${_rows.length} Rows)'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSingleModeBody(Color textCol) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expense Amount (₹)', style: AppTypography.label.copyWith(color: textCol)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.title.copyWith(fontSize: 26),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.currency_rupee_rounded, size: 24),
                    hintText: '0.00',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expense Category', style: AppTypography.label.copyWith(color: textCol)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Payment Out From', style: AppTypography.label.copyWith(color: textCol)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Cash', label: Text('Cash Hand')),
                    ButtonSegment(value: 'UPI', label: Text('UPI App')),
                  ],
                  selected: {_paymentMode},
                  onSelectionChanged: (selected) {
                    setState(() => _paymentMode = selected.first);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Note / Remarks', style: AppTypography.label.copyWith(color: textCol)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 5L diesel for Tata Ace van',
                    prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitSingleExpense,
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : const Text('Record Expense Voucher'),
        ),
      ],
    );
  }

  Widget _buildBatchModeBody(
    Color textCol,
    Color mutedCol,
    Color borderCol,
    RippleSkin skin,
    bool isDark,
  ) {
    final totalInDisplay = _serverTotalIn + _batchTotalIn;
    final totalOutDisplay = _serverTotalOut + _batchTotalOut;
    final wide = MediaQuery.sizeOf(context).width >= 600;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // Account Balances Strip + Total IN / Total OUT
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, size: 16, color: skin.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '2026 Accounts Strip',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textCol),
                      ),
                    ),
                    if (_isLoadingSummary)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    const SizedBox(width: 6),
                    _summaryTotalPill('Total IN', totalInDisplay, AppColors.success),
                    const SizedBox(width: 6),
                    _summaryTotalPill('Total OUT', totalOutDisplay, AppColors.danger),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _accountBalances.map((acc) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderCol),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              acc.name,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: mutedCol),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${acc.current.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textCol),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Editable Batch Rows
        ...List.generate(_rows.length, (index) {
          final row = _rows[index];
          final isIn = row.entryType == 'IN';
          final dateLabel = DateFormat('dd.MM.yyyy').format(row.date);

          return Card(
            key: ValueKey('batch_row_$index'),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: skin.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'S.NO #${index + 1}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: skin.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() {
                          row.entryType = isIn ? 'OUT' : 'IN';
                        }),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isIn ? AppColors.success : AppColors.danger).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isIn ? AppColors.success : AppColors.danger,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                size: 13,
                                color: isIn ? AppColors.success : AppColors.danger,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                row.entryType,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isIn ? AppColors.success : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _pickRowDate(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderCol),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 12, color: mutedCol),
                              const SizedBox(width: 4),
                              Text(
                                dateLabel,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textCol),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_rows.length > 1)
                        IconButton(
                          tooltip: 'Remove Row',
                          onPressed: () => _removeBatchRow(index),
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Company & Payment Account Dropdowns
                  if (wide)
                    Row(
                      children: [
                        Expanded(child: _buildCompanyDropdown(row)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildAccountDropdown(row)),
                      ],
                    )
                  else ...[
                    _buildCompanyDropdown(row),
                    const SizedBox(height: 8),
                    _buildAccountDropdown(row),
                  ],
                  const SizedBox(height: 8),

                  // Amount & Bill No
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: row.amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Amount (₹)',
                            hintText: '0',
                            prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: row.billNoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Bill No',
                            hintText: 'WL9554',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Vehicle / Staff Tag + Suggestion Chips
                  TextFormField(
                    controller: row.vehicleStaffCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle / Staff',
                      hintText: 'e.g. platina, SURESH, TN 47 M 4585',
                      prefixIcon: Icon(Icons.badge_outlined, size: 18),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _vehicleStaffSuggestions.map((tag) {
                        final selected = row.vehicleStaffCtrl.text.trim().toLowerCase() == tag.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            selected: selected,
                            visualDensity: VisualDensity.compact,
                            label: Text(tag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            onSelected: (_) {
                              setState(() {
                                row.vehicleStaffCtrl.text = selected ? '' : tag;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  TextFormField(
                    controller: row.descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g. suresh went to amirtha / Chendhur gas agency',
                      prefixIcon: Icon(Icons.notes_rounded, size: 18),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // + Add Row Button
        OutlinedButton.icon(
          onPressed: _addBatchRow,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 46),
            side: BorderSide(color: skin.primary),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            '+ Add Row',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _summaryTotalPill(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label ₹${amount.toStringAsFixed(0)}',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _buildCompanyDropdown(_BatchLedgerRow row) {
    return DropdownButtonFormField<String>(
      value: _companyTags.contains(row.companyTag) ? row.companyTag : _companyTags.first,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Company',
        isDense: true,
        prefixIcon: Icon(Icons.business_rounded, size: 18),
      ),
      items: _companyTags
          .map((c) => DropdownMenuItem<String>(
                value: c,
                child: Text(c, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => row.companyTag = val);
      },
    );
  }

  Widget _buildAccountDropdown(_BatchLedgerRow row) {
    return DropdownButtonFormField<String>(
      value: _paymentAccounts.contains(row.paymentAccount) ? row.paymentAccount : _paymentAccounts.first,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Payment Account',
        isDense: true,
        prefixIcon: Icon(Icons.account_balance_rounded, size: 18),
      ),
      items: _paymentAccounts
          .map((a) => DropdownMenuItem<String>(
                value: a,
                child: Text(a, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => row.paymentAccount = val);
      },
    );
  }
}
