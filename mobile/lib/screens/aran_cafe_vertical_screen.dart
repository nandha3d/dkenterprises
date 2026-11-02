import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'cafe_pos_screen.dart';
import 'products_screen.dart';
import 'spot_audit_screen.dart';

class AranCafeVerticalScreen extends StatefulWidget {
  final bool isTamil;

  const AranCafeVerticalScreen({super.key, required this.isTamil});

  @override
  State<AranCafeVerticalScreen> createState() => _AranCafeVerticalScreenState();
}

class _AranCafeVerticalScreenState extends State<AranCafeVerticalScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _menuProducts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _apiService.fetchRoleDashboard('cashier'),
      _apiService.fetchProducts(),
    ]);

    if (mounted) {
      setState(() {
        _dashboardData = results[0] as Map<String, dynamic>;
        _menuProducts = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final aran = _dashboardData['aran_cafe'] ?? {};
    final sales = (aran['pos_sales'] ?? 18450.0).toDouble();
    final openDrawers = aran['open_drawers'] ?? 1;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text(
          t ? 'அரண் கஃபே & பேக்கரி எக்ஸ்பிரஸ்' : 'Aran Cafe POS Operations',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.roleCashier))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Banner
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 20,
                      tintColor: AppColors.roleCashier,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.roleCashier, AppColors.brandNavy],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.roleCashier.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.local_cafe, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Aran Cafe & Bakery Express',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: AppColors.text(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.roleCashier.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'TOUCH POS',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.roleCashier,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  t ? 'விரைவு டச் POS & ஷிப்ட் கேஷ் டிராயர்' : 'Express Touch Billing & Till Balancing',
                                  style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textDim(context)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Operational KPI Grid
                    Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            borderRadius: 16,
                            tintColor: AppColors.roleCashier,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹ ${sales.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.roleCashier,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t ? 'இன்றைய POS விற்பனை' : 'Today\'s POS Sales',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text(context)),
                                ),
                                Text(t ? '38 ஆர்டர்கள் முடிந்தது' : '38 Orders Cleared', style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textDim(context))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            borderRadius: 16,
                            tintColor: AppColors.brandEmerald,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$openDrawers Active',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brandEmerald,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t ? 'கேஷ் டிராயர் நிலை' : 'Drawer Status',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text(context)),
                                ),
                                Text('Float: ₹5,000.00', style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textDim(context))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Launch Touch POS Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.point_of_sale, size: 20),
                        label: Text(
                          t ? 'விரைவு டச் POS பில்லிங் திறக்க' : 'Launch Express Touch POS Counter',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.roleCashier,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => Scaffold(
                                appBar: AppBar(title: Text(t ? 'விரைவு டச் POS' : 'Express Touch POS Counter')),
                                body: CafePosScreen(isTamil: t),
                              ),
                            ),
                          ).then((_) => _loadData());
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.restaurant_menu, size: 16),
                            label: Text(t ? 'உணவு பட்டியல் & விலை' : 'Menu Catalog', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text(context),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              side: BorderSide(color: AppColors.border(context)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => ProductsScreen(isTamil: t))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.price_check, size: 16),
                            label: Text(t ? 'டிராயர் தணிக்கை' : 'Float Audit', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text(context),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              side: BorderSide(color: AppColors.border(context)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => SpotAuditScreen(isTamil: t))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Top Menu Items Grid
                    Text(
                      t ? 'பிரபலமான மெனு & விலைப்பட்டியல்' : 'Top Counter Items & Price Matrix',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text(context)),
                    ),
                    const SizedBox(height: 10),

                    ..._menuProducts.map((p) {
                      final name = p['name'] ?? 'Product';
                      final price = (p['price'] ?? 0.0).toDouble();
                      final code = p['code'] ?? 'SKU';
                      final cat = p['category'] ?? 'Cafe';

                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        borderRadius: 12,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.roleCashier.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.bakery_dining, color: AppColors.roleCashier, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.text(context)),
                                  ),
                                  Text('$code · $cat', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDim(context))),
                                ],
                              ),
                            ),
                            Text(
                              '₹ ${price.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.brandEmerald),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}
