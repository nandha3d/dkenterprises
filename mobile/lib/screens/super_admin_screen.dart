import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SuperAdminScreen extends StatefulWidget {
  final bool isTamil;
  final ValueChanged<CompanyVertical> onSelectVertical;

  const SuperAdminScreen({
    super.key,
    required this.isTamil,
    required this.onSelectVertical,
  });

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  Map<String, dynamic> _financialData = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _apiService.fetchRoleDashboard('superAdmin'),
      _apiService.fetchFinancials(),
    ]);

    if (mounted) {
      setState(() {
        _dashboardData = results[0];
        _financialData = results[1];
        _isLoading = false;
      });
    }
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String sub,
    required Color color,
    required IconData icon,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      tintColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(color: color, blurRadius: 4, spreadRadius: 1),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.text(context),
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: 9.5,
              color: AppColors.textDim(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterprisePortalCard({
    required String title,
    required String subtitle,
    required Color color,
    required String badge,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      isInteractive: true,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      tintColor: color,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: color,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: color),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;

    // Live API Metrics
    final tmws = _dashboardData['tmws'] ?? {};
    final dkWaters = _dashboardData['dk_waters'] ?? {};
    final aranCafe = _dashboardData['aran_cafe'] ?? {};

    final tmwsRevenue = (tmws['revenue'] ?? 0.0).toDouble();
    final dkWatersRevenue = (dkWaters['revenue'] ?? 0.0).toDouble();
    final cafeRevenue = (aranCafe['pos_sales'] ?? 0.0).toDouble();
    final grossSales = tmwsRevenue + dkWatersRevenue + cafeRevenue;

    final cashInTransit = (_financialData['cash_in_transit_drivers'] ?? 0.0).toDouble();
    final totalKl = (tmws['total_kl'] ?? 0.0).toDouble();
    final totalJars = (dkWaters['cans_delivered'] ?? 0).toInt();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.brandPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Executive Title Glass Banner
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              tintColor: AppColors.roleSuperAdmin,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.roleSuperAdmin, AppColors.brandNavy],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.roleSuperAdmin.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              t ? 'குரூப் சூப்பர் அட்மின்' : 'Group Super Admin',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppColors.text(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.roleSuperAdmin.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'EXECUTIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.roleSuperAdmin,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          t ? 'நேரடி API தரவு · 3 நிறுவனங்கள்' : 'Live Cloud API · 3 Consolidated Enterprises',
                          style: TextStyle(
                            color: AppColors.textMuted(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Live Group Financials Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t ? 'ஒருங்கிணைந்த நிதி நிலை (API)' : 'Consolidated Group Financials (Live API)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.text(context),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: t ? 'மொத்த வருவாய்' : 'Gross Group Sales',
                    value: '₹ ${grossSales.toStringAsFixed(2)}',
                    sub: t ? '3 நிறுவனங்கள்' : 'Across 3 Entities',
                    color: AppColors.brandEmerald,
                    icon: Icons.currency_rupee,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: t ? 'டிரைவர் பணம்' : 'Cash in Transit',
                    value: '₹ ${cashInTransit.toStringAsFixed(2)}',
                    sub: t ? 'ஒப்படைக்க வேண்டியது' : 'Field Surrenders',
                    color: AppColors.brandAmber,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: t ? 'பல்க் வாட்டர்' : 'Bulk Water Decanted',
                    value: '${totalKl.toStringAsFixed(1)} KL',
                    sub: t ? 'ஹெவி டேங்கர் ட்ரிப்' : 'Tanker Logistics',
                    color: AppColors.roleTankerDriver,
                    icon: Icons.fire_truck,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: t ? 'குடிநீர் ஜார்கள்' : 'Packaged Water Cans',
                    value: '$totalJars Cans',
                    sub: t ? 'விநியோகம் முடிந்தது' : 'Delivered by Ace Fleet',
                    color: AppColors.roleDeliveryDriver,
                    icon: Icons.water_drop,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Enterprise Portals Section
            Text(
              t ? 'நிறுவன நேரடி நுழைவு (Enterprises)' : 'Enterprise Portals & Operations',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 10),

            _buildEnterprisePortalCard(
              title: 'Tiruchendur Murugan Water Supply (TMWS)',
              subtitle: t ? 'பல்க் வாட்டர் டேங்கர் & ஃப்ளீட் விநியோகம்' : 'Commercial Bulk Water Tankers & Heavy Lorries',
              color: AppColors.roleTankerDriver,
              badge: 'BULK WATER',
              icon: Icons.fire_truck,
              onTap: () => widget.onSelectVertical(CompanyVertical.tmws),
            ),
            _buildEnterprisePortalCard(
              title: 'DK Waters — Packaged Drinking Water',
              subtitle: t ? 'டாடா ஏஸ் பீட் ரூட்டுகள் & கேன் மேலாண்மை' : 'Tata Ace Beat Routes & Container Return Custody',
              color: AppColors.roleDeliveryDriver,
              badge: 'PACKAGED WATER',
              icon: Icons.water_drop,
              onTap: () => widget.onSelectVertical(CompanyVertical.dkWaters),
            ),
            _buildEnterprisePortalCard(
              title: 'Aran Cafe & Bakery Express',
              subtitle: t ? 'டச் POS கவுண்டர் & டிராயர் சமநிலை' : 'Express Touch POS Counter & Shift Cash Drawer',
              color: AppColors.roleCashier,
              badge: 'CAFE & POS',
              icon: Icons.local_cafe,
              onTap: () => widget.onSelectVertical(CompanyVertical.aranCafe),
            ),

            const SizedBox(height: 20),

            // Anti-Fraud Live Status Glass Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              tintColor: AppColors.brandDanger,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.brandDanger.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield, color: AppColors.brandDanger, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t ? 'நேரடி மோசடி தடுப்பு ரேடார்' : 'Anti-Fraud Real-Time Radar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text(context),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandEmerald.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ACTIVE 24/7',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t
                        ? 'ஓடோமீட்டர் முரண்பாடு, கேன் கடத்தல் மற்றும் பணப்பெட்டி பற்றாக்குறை தானாக கண்காணிக்கப்படுகிறது.'
                        : 'GPS odometer variance, missing container siphoning, and drawer cash float discrepancies are actively monitored.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
