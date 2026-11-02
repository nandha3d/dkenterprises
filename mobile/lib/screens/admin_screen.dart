import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class AdminScreen extends StatefulWidget {
  final bool isTamil;
  final CompanyVertical vertical;

  const AdminScreen({
    super.key,
    required this.isTamil,
    required this.vertical,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  Map<String, dynamic> _financialData = {};
  List<Map<String, dynamic>> _routes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _apiService.fetchRoleDashboard('admin'),
      _apiService.fetchFinancials(),
      _apiService.fetchRoutes(),
    ]);

    if (mounted) {
      setState(() {
        _dashboardData = results[0];
        _financialData = results[1];
        if (results[2]['routes'] is List) {
          _routes = List<Map<String, dynamic>>.from(results[2]['routes']);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _approveSettlement(Map<String, dynamic> route) async {
    final t = widget.isTamil;
    final record = DriverSurrenderRecord(
      surrenderCode: 'SURR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      routeId: route['id'] ?? 1,
      routeName: route['name'] ?? 'Route Beat',
      driverName: route['driver_name'] ?? 'Route Driver',
      totalLoaded: 80,
      totalDelivered: 75,
      emptyReturned: 70,
      totalCashCollected: 2625.0,
      cashSurrendered: 2625.0,
      variance: 0.0,
      surrenderTime: DateTime.now(),
    );

    await _apiService.submitDriverSurrender(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t
                ? 'டிரைவர் ரொக்க ஒப்படைப்பு சரிபார்க்கப்பட்டு GL 1010-ல் வரவு வைக்கப்பட்டது: ₹2,625'
                : 'Settlement verified & posted to Main Cash GL 1010: ₹2,625',
          ),
          backgroundColor: AppColors.brandEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final v = widget.vertical;

    final dkWaters = _dashboardData['dk_waters'] as Map<String, dynamic>? ?? {};
    final activeRoutes = dkWaters['active_routes'] ?? _routes.length;
    final cit = (_financialData['cash_in_transit_drivers'] ?? 0.0).toDouble();

    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.brandPurple))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.brandPurple,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Profile Header Card
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 22,
                    tintColor: AppColors.brandPurple,
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.brandNavy, AppColors.brandPurple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brandPurple.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(v.icon, color: Colors.white, size: 24),
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
                                      t ? '${v.name(t)} - நிறுவன அட்மின்' : '${v.name(t)} Admin Command',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: AppColors.text(context),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPurple.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.brandPurple.withOpacity(0.4)),
                                    ),
                                    child: const Text(
                                      'ADMIN',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.brandPurple),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t ? 'ரூட் மற்றும் வாகன கட்டுப்பாட்டு மையம்' : 'Route Dispatch & Fleet Reconciliations',
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

                  // Operations Status KPIs
                  Text(
                    t ? 'இன்றைய நேரடி செயல்பாடுகள்' : 'Live Fleet Operations',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.3,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          borderRadius: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    t ? 'இயங்கும் ரூட்டுகள்' : 'Active Beats',
                                    style: TextStyle(fontSize: 11, color: AppColors.textMuted(context), fontWeight: FontWeight.w600),
                                  ),
                                  const Icon(Icons.alt_route, size: 16, color: AppColors.brandSky),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$activeRoutes Routes',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.brandSky),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t ? 'நேரடி டெலிவரி செயல்பாட்டில்' : 'Tata Ace Fleet Dispatched',
                                style: TextStyle(fontSize: 9.5, color: AppColors.textDim(context)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          borderRadius: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    t ? 'வழியில் உள்ள ரொக்கம்' : 'CIT In Transit',
                                    style: TextStyle(fontSize: 11, color: AppColors.textMuted(context), fontWeight: FontWeight.w600),
                                  ),
                                  const Icon(Icons.currency_exchange, size: 16, color: AppColors.brandAmber),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${cit.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.brandAmber),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t ? 'ஓட்டுநர்களிடம் உள்ள தொகை' : 'Pending Field Cash Settlement',
                                style: TextStyle(fontSize: 9.5, color: AppColors.textDim(context)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Route Settlement Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified, color: AppColors.brandEmerald, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            t ? 'டிரைவர் ரொக்கம் & கேன் ஒப்படைப்பு' : 'Driver Route Settlements',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.text(context),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          t ? 'நேரடி ERP' : 'Live Sync',
                          style: const TextStyle(
                            color: AppColors.brandPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_routes.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 18,
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.brandEmerald, size: 40),
                            const SizedBox(height: 10),
                            Text(
                              t
                                  ? 'அனைத்து டிரைவர் கணக்குகளும் சமரசம் செய்யப்பட்டு முடிந்தது!'
                                  : 'All driver shifts verified and reconciled with General Ledger!',
                              style: TextStyle(color: AppColors.text(context), fontSize: 13, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._routes.map((route) {
                      final routeName = route['route_name'] ?? route['name'] ?? 'Route Beat';
                      final vehicleNo = route['vehicle_number'] ?? 'Tata Ace TN-59-WA';
                      final driver = route['driver_name'] ?? 'Kumar (Driver)';

                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        borderRadius: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    routeName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text(context),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandSky.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    vehicleNo,
                                    style: const TextStyle(
                                      color: AppColors.brandSky,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${t ? "ஓட்டுநர்" : "Driver"}: $driver',
                              style: TextStyle(color: AppColors.textMuted(context), fontSize: 11),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.water_drop, size: 12, color: AppColors.brandSky),
                                    const SizedBox(width: 4),
                                    Text(
                                      '80 Jars',
                                      style: TextStyle(color: AppColors.textDim(context), fontSize: 11),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () => _approveSettlement(route),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandEmerald,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    t ? 'ஒப்புதல் அளி' : 'Verify & Settle',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
  }
}
