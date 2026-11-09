import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/network/api_endpoints.dart';
import '../core/providers.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/location_parser.dart';
import '../features/operations/presentation/capture_location_dialog.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  final bool? isTamil;

  const CustomersScreen({super.key, this.isTamil});

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
        content: Text('Phone number copied: $phone', style: GoogleFonts.inter()),
        backgroundColor: AppColors.brandSky,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil ?? (ref.watch(localeProvider).languageCode == 'ta');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1C2541) : Colors.white;
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textPrim = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSec = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.brandSky.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.people_alt_rounded, color: AppColors.brandSky, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              t ? 'வாடிக்கையாளர் பட்டியல்' : 'Customers Directory',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: t ? 'புதுப்பி' : 'Refresh',
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _loadCustomers,
          ),
          IconButton(
            tooltip: t ? 'புதிய வாடிக்கையாளர்' : 'Add Customer',
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.brandEmerald, size: 22),
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
        backgroundColor: AppColors.brandSky,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded, size: 18),
        label: Text(
          t ? '+ புதிய வாடிக்கையாளர்' : '+ Add Customer',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
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
          // Search & Summary Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol),
                  ),
                  child: TextField(
                    style: GoogleFonts.inter(color: textPrim, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: t
                          ? 'பெயர், தொலைபேசி அல்லது ஊர் தேடுக...'
                          : 'Search by customer, shop, phone, city...',
                      hintStyle: GoogleFonts.inter(color: textSec, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.brandSky),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => setState(() => _applyFilter('')),
                            )
                          : null,
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _applyFilter(val)),
                  ),
                ),
                const SizedBox(height: 10),

                // Live Sync Status Ribbon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.brandEmerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t
                              ? 'மொத்தம்: ${_filteredCustomers.length} வாடிக்கையாளர்கள்'
                              : 'Total: ${_filteredCustomers.length} Active Records',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textSec,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brandSky.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.brandSky.withOpacity(0.3)),
                      ),
                      child: Text(
                        t ? 'நேரடி ERP தரவு' : 'LIVE ERP SYNC',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandSky,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Customer Directory List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 40, color: AppColors.brandDanger),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: GoogleFonts.inter(color: AppColors.brandDanger)),
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
                                Icon(Icons.person_off_rounded, size: 48, color: textSec.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  t ? 'வாடிக்கையாளர் கிடைக்கவில்லை' : 'No customers found',
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: textPrim),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap "+ Add Customer" below to onboard the first customer.',
                                  style: GoogleFonts.inter(fontSize: 12, color: textSec),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCustomers,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                              itemCount: _filteredCustomers.length,
                              separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                              itemBuilder: (ctx, idx) {
                                final c = _filteredCustomers[idx];
                                final name = c['name']?.toString() ?? 'Customer';
                                final companyName = c['company_name']?.toString() ?? '';
                                final phone = c['phone']?.toString() ?? c['phone_number']?.toString() ?? '';
                                final address = c['address']?.toString() ?? '';
                                final city = c['city']?.toString() ?? '';
                                final cansHeld = c['cans_held'] ?? 0;
                                final depositHeld = (c['deposit_held'] as num?)?.toDouble() ?? 0.0;
                                final lat = double.tryParse(c['latitude']?.toString() ?? '');
                                final lng = double.tryParse(c['longitude']?.toString() ?? '');
                                final hasGps = lat != null && lng != null && (lat != 0 || lng != 0);
                                final customerId = c['id'] is int ? c['id'] as int : int.tryParse(c['id']?.toString() ?? '') ?? 0;

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderCol),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Customer Identity Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: textPrim,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (companyName.isNotEmpty && companyName != name)
                                                  Text(
                                                    companyName,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: textSec,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: hasGps
                                                  ? AppColors.brandEmerald.withOpacity(0.12)
                                                  : Colors.amber.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: hasGps
                                                    ? AppColors.brandEmerald.withOpacity(0.4)
                                                    : Colors.amber.withOpacity(0.4),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  hasGps ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                                                  size: 12,
                                                  color: hasGps ? AppColors.brandEmerald : Colors.amber.shade800,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  hasGps ? 'GPS Pin Set' : 'No GPS',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: hasGps ? AppColors.brandEmerald : Colors.amber.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      // Address & City
                                      if (address.isNotEmpty || city.isNotEmpty)
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.brandSky),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                [address, city].where((s) => s.isNotEmpty).join(', '),
                                                style: GoogleFonts.inter(fontSize: 11, color: textSec),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),

                                      const SizedBox(height: 8),

                                      // Jars Held & Security Deposit Strip
                                      if (cansHeld > 0 || depositHeld > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.brandSky.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.water_drop_rounded, size: 14, color: AppColors.brandSky),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$cansHeld 20L Jars Held',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.brandSky,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                'Deposit: ₹${depositHeld.toStringAsFixed(0)}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.brandEmerald,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      const SizedBox(height: 10),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),

                                      // 1-Tap Action Bar
                                      Row(
                                        children: [
                                          // Phone Call
                                          if (phone.isNotEmpty) ...[
                                            InkWell(
                                              onTap: () => _callCustomer(phone),
                                              onLongPress: () => _copyPhone(phone),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: AppColors.brandEmerald.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.phone_rounded, size: 13, color: AppColors.brandEmerald),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      phone,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.brandEmerald,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],

                                          const Spacer(),

                                          // Turn-by-Turn GPS Navigation
                                          if (hasGps)
                                            IconButton(
                                              tooltip: 'Navigate with Google Maps',
                                              icon: const Icon(Icons.navigation_rounded, size: 18, color: AppColors.brandEmerald),
                                              onPressed: () => LocationParser.launchNavigation(lat, lng),
                                            ),

                                          // WhatsApp Location Link Capture Modal
                                          IconButton(
                                            tooltip: 'Capture WhatsApp GPS',
                                            icon: const Icon(Icons.share_location_rounded, size: 18, color: AppColors.brandSky),
                                            onPressed: () {
                                              CaptureLocationDialog.show(
                                                context,
                                                customerId: customerId,
                                                customerName: name,
                                                onLocationUpdated: _loadCustomers,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
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
