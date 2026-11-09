import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SpotAuditScreen extends ConsumerStatefulWidget {
  const SpotAuditScreen({super.key});

  @override
  ConsumerState<SpotAuditScreen> createState() => _SpotAuditScreenState();
}

class _SpotAuditScreenState extends ConsumerState<SpotAuditScreen> {
  final _customerController = TextEditingController();
  int _systemRecordedJars = 0;
  int _physicalCountedJars = 0;
  final _remarksController = TextEditingController();
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    final client = ref.read(apiClientProvider);
    final res = await client.get(
      ApiEndpoints.customers,
      fromJson: (data) {
        final list = data is Map && data['data'] is List
            ? data['data'] as List
            : (data is List ? data : []);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      },
    );
    if (mounted && res.isSuccess && (res.dataOrNull?.isNotEmpty ?? false)) {
      setState(() {
        _customers = res.dataOrNull ?? [];
        final first = _customers.first;
        _customerController.text = first['name']?.toString() ?? '';
        _systemRecordedJars = (first['total_cans_held'] as num?)?.toInt() ?? 0;
        _physicalCountedJars = _systemRecordedJars;
      });
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  int get _difference => _physicalCountedJars - _systemRecordedJars;

  Future<void> _submitAudit() async {
    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final payload = {
      'customer_id': 1,
      'customer_name': _customerController.text.trim(),
      'system_jars': _systemRecordedJars,
      'physical_jars': _physicalCountedJars,
      'difference': _difference,
      'remarks': _remarksController.text.trim(),
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final idempotencyKey = const Uuid().v4();

    final result = await client.post(
      ApiEndpoints.spotAudit,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spot audit submitted and verified with company database!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.spotAudit,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audit record saved offline in Outbox!'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spot Empty Can Audit'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer Location', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customerController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.storefront_rounded, size: 20),
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
                  Text(
                    'Jar Balance Verification',
                    style: AppTypography.section.copyWith(fontSize: 16, color: textCol),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('System Ledger Jar Balance', style: AppTypography.body),
                      Text('$_systemRecordedJars Jars', style: AppTypography.section.copyWith(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Physically Counted Jars', style: AppTypography.body),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: _physicalCountedJars > 0 ? () => setState(() => _physicalCountedJars--) : null,
                            icon: const Icon(Icons.remove_rounded, size: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '$_physicalCountedJars',
                              style: AppTypography.title.copyWith(fontSize: 20),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => setState(() => _physicalCountedJars++),
                            icon: const Icon(Icons.add_rounded, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Variance Difference', style: AppTypography.section.copyWith(fontSize: 16, color: textCol)),
                      Text(
                        _difference == 0 ? 'Exact Match (0)' : '$_difference Jars',
                        style: AppTypography.title.copyWith(
                          fontSize: 18,
                          color: _difference == 0
                              ? AppColors.success
                              : _difference < 0
                                  ? AppColors.danger
                                  : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  if (_difference < 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Shortage detected: ${_difference.abs()} jars missing from customer premises.',
                              style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  Text('Supervisor Remarks', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      hintText: 'Customer confirmed breakage / bottle replacement note',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitAudit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Confirm & Record Spot Audit'),
          ),
        ],
      ),
    );
  }
}

