import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/network/api_endpoints.dart';
import '../core/providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_typography.dart';
import '../core/ui/gps_map_interactive_sheets.dart';
import '../core/utils/location_parser.dart';
import '../features/operations/presentation/capture_location_dialog.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  final bool? isTamil;
  final bool embedded;

  const CustomersScreen({super.key, this.isTamil, this.embedded = false});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get(
        ApiEndpoints.customers,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (!mounted) return;

      if (res.isSuccess) {
        final raw = res.dataOrNull?['data'] ?? res.dataOrNull;
        final list = raw is List ? raw : [];
        final parsed = list.map((item) {
          return item is Map<String, dynamic>
              ? item
              : (item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{});
        }).toList();

        setState(() {
          _customers = parsed;
          _applyFilter(_searchQuery);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.failureOrNull?.message ?? 'Failed to load customers directory.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredCustomers = List.from(_customers);
    } else {
      final q = query.toLowerCase();
      _filteredCustomers = _customers.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final companyName = (c['company_name'] ?? '').toString().toLowerCase();
        final phone = (c['phone'] ?? c['phone_number'] ?? '').toString().toLowerCase();
        final city = (c['city'] ?? '').toString().toLowerCase();
        final address = (c['address'] ?? '').toString().toLowerCase();
        return name.contains(q) || companyName.contains(q) || phone.contains(q) || city.contains(q) || address.contains(q);
      }).toList();
    }
  }

  void _callCustomer(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyPhone(String phone) {
    if (phone.isEmpty) return;
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Phone number copied: $phone', style: AppTypography.body),
        backgroundColor: AppColors.brandSky,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double _num(dynamic raw) => double.tryParse(raw?.toString() ?? '0') ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil ?? (ref.watch(localeProvider).languageCode == 'ta');
    final skin = RippleSkin.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inrExact = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: skin.canvas,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: skin.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.people_alt_rounded, color: skin.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t ? 'வாடிக்கையாளர் பட்டியல்' : 'Customers Directory',
                    style: AppTypography.section.copyWith(color: skin.ink),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Open Customer & Due GPS Map',
                  icon: Icon(Icons.map_rounded, color: skin.primary, size: 21),
                  onPressed: () => context.push('/fleet-gps'),
                ),
                IconButton(
                  tooltip: t ? 'புதுப்பி' : 'Refresh',
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: _loadCustomers,
                ),
                IconButton(
                  tooltip: t ? 'புதிய வாடிக்கையாளர்' : 'Add Customer',
                  icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.success, size: 22),
                  onPressed: () async {
                    final result = await context.push<bool>('/customers/new');
                    if (result == true) {
                      _loadCustomers();
                    }
                  },
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: skin.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded, size: 18),
        label: Text(
          t ? '+ புதிய வாடிக்கையாளர்' : 'Add Customer',
          style: AppTypography.label.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        onPressed: () async {
          final result = await context.push<bool>('/customers/new');
          if (result == true) {
            _loadCustomers();
          }
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: skin.surface,
                    borderRadius: BorderRadius.circular(skin.inputRadius),
                    border: Border.all(color: skin.hairline),
                  ),
                  child: TextField(
                    style: AppTypography.body.copyWith(color: skin.ink, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: t
                          ? 'பெயர், தொலைபேசி அல்லது ஊர் தேடுக...'
                          : 'Search by customer, shop, phone, city...',
                      hintStyle: AppTypography.caption.copyWith(color: skin.muted),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: skin.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => setState(() => _applyFilter('')),
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _applyFilter(val)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t
                              ? 'மொத்தம்: ${_filteredCustomers.length} வாடிக்கையாளர்கள்'
                              : '${_filteredCustomers.length} Active Accounts',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: skin.muted,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.push('/fleet-gps'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: skin.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: skin.primary.withValues(alpha: 0.28)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_outlined, size: 14, color: skin.primary),
                            const SizedBox(width: 5),
                            Text(
                              'Live Due Map',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w800,
                                color: skin.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: AppTypography.body.copyWith(color: AppColors.danger)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadCustomers, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _filteredCustomers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_off_rounded, size: 48, color: skin.muted.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  t ? 'வாடிக்கையாளர் கிடைக்கவில்லை' : 'No customers found',
                                  style: AppTypography.section.copyWith(color: skin.ink),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap "+ Add Customer" below to onboard the first customer.',
                                  style: AppTypography.caption.copyWith(color: skin.muted),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCustomers,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
                              itemCount: _filteredCustomers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, idx) {
                                final c = _filteredCustomers[idx];
                                final name = c['name']?.toString() ?? 'Customer';
                                final companyName = c['company_name']?.toString() ?? '';
                                final phone = c['phone']?.toString() ?? c['phone_number']?.toString() ?? '';
                                final address = c['address']?.toString() ?? '';
                                final city = c['city']?.toString() ?? '';
                                final gstin = c['tax_no']?.toString() ?? '';
                                final cansHeld = c['cans_held'] ?? 0;
                                final depositHeld = _num(c['deposit_held']);
                                final totalPaid = _num(c['total_paid']);
                                final dueAmount = _num(c['due_amount']);
                                final overdueAmount = _num(c['overdue_amount']);
                                final lat = double.tryParse(c['latitude']?.toString() ?? '');
                                final lng = double.tryParse(c['longitude']?.toString() ?? '');
                                final hasGps = lat != null && lng != null && (lat.abs() > 0.0001 || lng.abs() > 0.0001);
                                final customerId = c['id'] is int ? c['id'] as int : int.tryParse(c['id']?.toString() ?? '') ?? 0;

                                final statusColor = overdueAmount > 0.01
                                    ? AppColors.danger
                                    : (dueAmount > 0.01 ? AppColors.warning : AppColors.success);
                                final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'C';
                                final isPackaged = ref.read(authNotifierProvider).activeCompany?.industry != 'bulk_water';

                                return Material(
                                  color: skin.surface,
                                  borderRadius: BorderRadius.circular(skin.cardRadius),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(skin.cardRadius),
                                    onTap: () => showCustomerFullDetailsSheet(
                                      context,
                                      ref: ref,
                                      customer: c,
                                      isPackagedWater: isPackaged,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(skin.cardRadius),
                                        border: Border.all(
                                          color: overdueAmount > 0.01
                                              ? AppColors.danger.withValues(alpha: 0.32)
                                              : skin.hairline,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              initial,
                                              style: AppTypography.section.copyWith(
                                                color: statusColor,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 11),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: AppTypography.bodyMedium.copyWith(color: skin.ink),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (companyName.isNotEmpty && companyName != name)
                                                  Text(
                                                    companyName,
                                                    style: AppTypography.caption.copyWith(color: skin.muted),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (hasGps ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  hasGps ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                                                  size: 12,
                                                  color: hasGps ? AppColors.success : AppColors.warning,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  hasGps ? 'GPS Set' : 'No GPS',
                                                  style: AppTypography.caption.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: hasGps ? AppColors.success : AppColors.warning,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (address.isNotEmpty || city.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 14, color: skin.primary),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                [address, city].where((s) => s.isNotEmpty).join(', '),
                                                style: AppTypography.caption.copyWith(color: skin.muted),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: skin.surface2,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: skin.hairline),
                                        ),
                                        child: Wrap(
                                          spacing: 12,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              'Paid ${inrExact.format(totalPaid)}',
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              overdueAmount > 0.01
                                                  ? 'Overdue ${inrExact.format(dueAmount)}'
                                                  : 'Due ${inrExact.format(dueAmount)}',
                                              style: AppTypography.caption.copyWith(
                                                color: dueAmount > 0.01 ? statusColor : skin.muted,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            if ((cansHeld as num?)?.toInt() != 0 || depositHeld > 0)
                                              Text(
                                                '$cansHeld Jars · Dep ${inrExact.format(depositHeld)}',
                                                style: AppTypography.caption.copyWith(
                                                  color: skin.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            if (gstin.isNotEmpty)
                                              Text(
                                                'GST: $gstin',
                                                style: AppTypography.caption.copyWith(color: skin.muted),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (phone.isNotEmpty) ...[
                                            InkWell(
                                              onTap: () => _callCustomer(phone),
                                              onLongPress: () => _copyPhone(phone),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: AppColors.success.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.phone_rounded, size: 13, color: AppColors.success),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      phone,
                                                      style: AppTypography.caption.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.success,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          const Spacer(),
                                          if (hasGps)
                                            IconButton(
                                              tooltip: 'Navigate with Google Maps',
                                              icon: const Icon(Icons.navigation_rounded, size: 19, color: AppColors.success),
                                              onPressed: () => LocationParser.launchNavigation(lat, lng),
                                            ),
                                          IconButton(
                                            tooltip: 'Set / Update GPS Pin',
                                            icon: Icon(Icons.add_location_alt_rounded, size: 19, color: skin.primary),
                                            onPressed: () {
                                              CaptureLocationDialog.show(
                                                context,
                                                customerId: customerId,
                                                customerName: name,
                                                onLocationUpdated: _loadCustomers,
                                              );
                                            },
                                          ),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(8),
                                            onTap: () => showCustomerFullDetailsSheet(
                                              context,
                                              ref: ref,
                                              customer: c,
                                              isPackagedWater: isPackaged,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: skin.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.history_edu_rounded, size: 13, color: skin.primary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'History',
                                                    style: AppTypography.caption.copyWith(
                                                      fontWeight: FontWeight.w700,
                                                      color: skin.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
