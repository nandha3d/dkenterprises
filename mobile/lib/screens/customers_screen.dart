import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class CustomersScreen extends StatefulWidget {
  final bool isTamil;

  const CustomersScreen({super.key, required this.isTamil});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final data = await _apiService.fetchCustomers();
    if (mounted) {
      setState(() {
        _customers = data;
        _applyFilter(_searchQuery);
        _isLoading = false;
      });
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
        final phone = (c['phone'] ?? '').toString().toLowerCase();
        final city = (c['city'] ?? '').toString().toLowerCase();
        final address = (c['address'] ?? '').toString().toLowerCase();
        return name.contains(q) || phone.contains(q) || city.contains(q) || address.contains(q);
      }).toList();
    }
  }

  void _copyPhoneNumber(String phone) {
    if (phone.isEmpty) return;
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isTamil ? 'தொலைபேசி எண் நகலெடுக்கப்பட்டது: $phone' : 'Phone number copied: $phone',
        ),
        backgroundColor: AppColors.brandPurple,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brandPurple, AppColors.brandNavy],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.people_alt, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              t ? 'வாடிக்கையாளர் பட்டியல்' : 'Customers Directory',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text(context),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.appBarBg(context),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: t ? 'புதுப்பி' : 'Refresh',
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Metrics Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Frosted Glass Search Bar
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  borderRadius: 14,
                  blurSigma: 12,
                  child: TextField(
                    style: TextStyle(color: AppColors.text(context), fontSize: 13),
                    decoration: InputDecoration(
                      hintText: t
                          ? 'பெயர், தொலைபேசி அல்லது ஊர் தேடுக...'
                          : 'Search customer by name, phone, city...',
                      hintStyle: TextStyle(color: AppColors.textDim(context), fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.brandPurple),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
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
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brandPurple.withOpacity(isDark ? 0.25 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.brandPurple.withOpacity(0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        t ? 'நேரடி ERP தரவு' : 'LIVE API SYNC',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandPurple,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Customers List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.brandPurple),
                  )
                : _filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GlassCard(
                              padding: const EdgeInsets.all(24),
                              borderRadius: 24,
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.person_off_outlined,
                                    size: 48,
                                    color: AppColors.textDim(context),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    t ? 'வாடிக்கையாளர் கிடைக்கவில்லை' : 'No customers found',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t ? 'தேடலை மாற்றவும் அல்லது புதுப்பிக்கவும்' : 'Try adjusting your search criteria',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textDim(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCustomers,
                        color: AppColors.brandPurple,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (ctx, idx) {
                            final c = _filteredCustomers[idx];
                            final cansHeld = c['cans_held'] ?? 0;
                            final deposit = (c['deposit_held'] ?? 0.0).toDouble();
                            final phone = (c['phone'] ?? '').toString();

                            return GlassCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              borderRadius: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Customer Icon Avatar
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [AppColors.brandNavy, AppColors.brandPurple],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.brandPurple.withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.person, color: Colors.white, size: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Name & Phone
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c['name'] ?? 'Unknown Customer',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.text(context),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.phone, size: 12, color: AppColors.textMuted(context)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  phone.isNotEmpty ? phone : (t ? 'எண் இல்லை' : 'No Phone'),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted(context),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (c['city'] != null && c['city'].toString().isNotEmpty) ...[
                                                  Text(' • ', style: TextStyle(color: AppColors.textDim(context))),
                                                  Text(
                                                    c['city'].toString(),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.textDim(context),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ID Pill & Phone Quick Copy
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.brandEmerald.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '#${c['id']}',
                                              style: const TextStyle(
                                                color: AppColors.brandEmerald,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          if (phone.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            InkWell(
                                              onTap: () => _copyPhoneNumber(phone),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Padding(
                                                padding: const EdgeInsets.all(2),
                                                child: Icon(
                                                  Icons.copy,
                                                  size: 14,
                                                  color: AppColors.brandPurple.withOpacity(0.8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),

                                  if (c['address'] != null && c['address'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 12, color: AppColors.textDim(context)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            c['address'].toString(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textDim(context),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 12),
                                  Container(
                                    height: 1,
                                    color: AppColors.border(context).withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 10),

                                  // Inventory Metrics: Cans Held & Deposit Held
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Cans Held
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppColors.brandSky.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.water_drop, size: 12, color: AppColors.brandSky),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            t ? 'கையில் உள்ள கேன்கள்: ' : 'Cans Held: ',
                                            style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
                                          ),
                                          Text(
                                            '$cansHeld',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.brandSky,
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Security Deposit
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppColors.brandAmber.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.account_balance_wallet, size: 12, color: AppColors.brandAmber),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            t ? 'முன்பணம்: ' : 'Deposit: ',
                                            style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
                                          ),
                                          Text(
                                            '₹${deposit.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.brandAmber,
                                            ),
                                          ),
                                        ],
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
