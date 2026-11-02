import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'tanker_trip_sheet_screen.dart';
import 'spot_audit_screen.dart';
import 'fleet_gps_screen.dart';

class TmwsVerticalScreen extends StatefulWidget {
  final bool isTamil;

  const TmwsVerticalScreen({super.key, required this.isTamil});

  @override
  State<TmwsVerticalScreen> createState() => _TmwsVerticalScreenState();
}

class _TmwsVerticalScreenState extends State<TmwsVerticalScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _fleet = [];
  List<Map<String, dynamic>> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _apiService.fetchRoleDashboard('tankerDriver'),
      _apiService.fetchRoutes(),
      _apiService.fetchTankerTrips(),
    ]);

    if (mounted) {
      setState(() {
        _dashboardData = results[0] as Map<String, dynamic>;
        final routesData = results[1] as Map<String, dynamic>;
        if (routesData['tankers'] is List) {
          _fleet = List<Map<String, dynamic>>.from(routesData['tankers'] as List);
        }
        _trips = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final tmws = _dashboardData['tmws'] ?? {};
    final totalKl = (tmws['total_kl'] ?? 90.0).toDouble();
    final revenue = (tmws['revenue'] ?? 15600.0).toDouble();
    final tripsCount = (tmws['trips_today'] ?? 4).toInt();
    final tankersCount = _fleet.isNotEmpty ? _fleet.length : 3;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text(
          t ? 'திருச்செந்தூர் முருகன் வாட்டர் சப்ளை' : 'TMWS Bulk Logistics',
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.roleTankerDriver))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Banner
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 20,
                      tintColor: AppColors.roleTankerDriver,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.roleTankerDriver, AppColors.brandNavy],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.roleTankerDriver.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.fire_truck, color: Colors.white, size: 28),
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
                                        'Tiruchendur Murugan Water Supply',
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
                                        color: AppColors.roleTankerDriver.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'TMWS',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.roleTankerDriver,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  t ? 'வணிக பல்க் டேங்கர் கப்பற்படை (10KL - 40KL)' : 'Commercial Bulk Fleet & Decanting Operations',
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
                            tintColor: AppColors.roleTankerDriver,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${totalKl.toStringAsFixed(1)} KL',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.roleTankerDriver,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t ? 'இறக்கப்பட்ட நீர்' : 'Water Decanted',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text(context)),
                                ),
                                Text(
                                  t ? 'இன்றைய விநியோகம்' : 'Today\'s Supply',
                                  style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textDim(context)),
                                ),
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
                                  '₹ ${revenue.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brandEmerald,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t ? 'பல்க் வருவாய்' : 'Bulk Revenue',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text(context)),
                                ),
                                Text(
                                  '$tripsCount ${t ? "ட்ரிப்புகள் முடிந்தது" : "Completed Trips"}',
                                  style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textDim(context)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // LIVE GPS TANKER TRACKING RADAR CARD
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 18,
                      tintColor: AppColors.brandEmerald,
                      borderColor: AppColors.brandEmerald.withOpacity(0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandEmerald.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.share_location, color: AppColors.brandEmerald, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    t ? 'நேரடி GPS டேங்கர் ரேடார்' : 'Live Tanker GPS Fleet Tracking',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.text(context)),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.brandEmerald.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '3 ONLINE',
                                  style: GoogleFonts.inter(color: AppColors.brandEmerald, fontSize: 9, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            t
                                ? 'TN-58-BW-2001 (டெக்ச்வேலி மாலில் இறக்குகிறது)\nTN-58-BW-4001 (NH-544 சாலையில் 48 km/h வேகத்தில்)\nTN-58-BW-1001 (போர்வெல் ஆலைக்கு திரும்புகிறது)'
                                : '• TN-58-BW-2001: Decanting at Texvalley Mall (0 km/h · 420 L/min)\n• TN-58-BW-4001: En Route NH-544 to Chennai Silks (48 km/h)\n• TN-58-BW-1001: Returning empty to Borewell Hub (39 km/h)',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted(context), height: 1.45),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.radar, size: 16),
                              label: Text(
                                t ? 'முழு ரேடார் வரைபடத்தை திறக்க' : 'Open Live GPS Radar Map',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandEmerald,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => FleetGpsScreen(isTamil: t, initialMode: FleetViewMode.tankers),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(t ? 'புதிய ட்ரிப் பதிவு' : 'New Trip Sheet', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.roleTankerDriver,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => TankerTripSheetScreen(isTamil: t),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.verified_user, size: 16),
                          label: Text(t ? 'ஆய்வு' : 'Spot Audit', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text(context),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            side: BorderSide(color: AppColors.border(context)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => SpotAuditScreen(isTamil: t),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Active Fleet Section
                    Text(
                      t ? 'செயலில் உள்ள டேங்கர் கப்பற்படை ($tankersCount வாகனங்கள்)' : 'Active Commercial Tanker Fleet ($tankersCount Vehicles)',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text(context)),
                    ),
                    const SizedBox(height: 10),

                    ..._fleet.map((tanker) {
                      final number = tanker['vehicle_number'] ?? tanker['number'] ?? 'Tanker';
                      final kl = (tanker['capacity_kl'] ?? 20.0).toDouble();
                      final driver = tanker['driver_name'] ?? tanker['driver'] ?? 'Operator';
                      final phone = tanker['driver_phone'] ?? '9842100000';

                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        borderRadius: 14,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.roleTankerDriver.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.local_shipping, color: AppColors.roleTankerDriver, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        number,
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.text(context)),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.brandEmerald.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: GoogleFonts.inter(color: AppColors.brandEmerald, fontSize: 8.5, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${kl.toStringAsFixed(0)} KL Tanker · $driver ($phone)',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted(context)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Recent Trips Section
                    Text(
                      t ? 'சமீபத்திய டேங்கர் ட்ரிப் பதிவுகள் (Live API)' : 'Recent Tanker Trip Sheets (Live API)',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text(context)),
                    ),
                    const SizedBox(height: 10),

                    ..._trips.map((trip) {
                      final tripNo = trip['trip_number'] ?? 'TMWS-TRIP';
                      final customer = trip['customer_name'] ?? 'Site';
                      final rate = (trip['rate'] ?? 3500.0).toDouble();
                      final kl = (trip['capacity_kl'] ?? 20.0).toDouble();
                      final diesel = (trip['diesel'] ?? 850.0).toDouble();
                      final time = trip['time'] ?? 'Today';

                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        borderRadius: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tripNo,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.roleTankerDriver),
                                ),
                                Text(
                                  '₹ ${rate.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.brandEmerald),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              customer,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.text(context)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('${kl.toStringAsFixed(0)} KL Decanted', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textDim(context))),
                                const SizedBox(width: 10),
                                Text('•', style: TextStyle(color: AppColors.textDim(context))),
                                const SizedBox(width: 10),
                                Text('Diesel: ₹${diesel.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textDim(context))),
                                const Spacer(),
                                Text(time, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDim(context))),
                              ],
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
