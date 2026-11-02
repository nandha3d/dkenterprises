import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'ticket_machine_screen.dart';
import 'plant_refill_screen.dart';
import 'customers_screen.dart';
import 'invoices_screen.dart';

class DkWatersVerticalScreen extends StatefulWidget {
  final bool isTamil;

  const DkWatersVerticalScreen({super.key, required this.isTamil});

  @override
  State<DkWatersVerticalScreen> createState() => _DkWatersVerticalScreenState();
}

class _DkWatersVerticalScreenState extends State<DkWatersVerticalScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _apiService.fetchRoleDashboard('deliveryDriver'),
      _apiService.fetchRoutes(),
      _apiService.fetchInvoices(),
    ]);

    if (mounted) {
      setState(() {
        _dashboardData = results[0] as Map<String, dynamic>;
        final routesData = results[1] as Map<String, dynamic>;
        if (routesData['routes'] is List) {
          _routes = List<Map<String, dynamic>>.from(routesData['routes'] as List);
        }
        _invoices = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final dkWaters = _dashboardData['dk_waters'] ?? {};
    final cansDelivered = (dkWaters['cans_delivered'] ?? 145).toInt();
    final cansInMarket = (dkWaters['cans_in_market'] ?? 442).toInt();
    final depositsHeld = (dkWaters['deposits_held'] ?? 66300.0).toDouble();
    final revenue = (dkWaters['revenue'] ?? 5075.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text(
          t ? 'டிகே வாட்டர்ஸ் — பேக்கேஜ்டு குடிநீர்' : 'DK Waters Distribution',
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.roleDeliveryDriver))
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
                      tintColor: AppColors.roleDeliveryDriver,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.roleDeliveryDriver, AppColors.brandNavy],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.roleDeliveryDriver.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.water_drop, color: Colors.white, size: 28),
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
                                        'DK Waters — Packaged Water',
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
                                        color: AppColors.roleDeliveryDriver.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '20L JARS',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.roleDeliveryDriver,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  t ? 'டாடா ஏஸ் பீட் ரூட்டுகள் & கேன் மேலாண்மை' : 'Tata Ace Beat Routes & Container Return Custody',
                                  style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textDim(context)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Operational KPI Grid (4 Cards)
                    Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            borderRadius: 16,
                            tintColor: AppColors.roleDeliveryDriver,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$cansDelivered Cans',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.roleDeliveryDriver,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t ? 'விநியோகம் முடிந்தது' : 'Delivered Today',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text(context)),
                                ),
                                Text('₹${revenue.toStringAsFixed(0)} ${t ? "வருவாய்" : "Sales"}', style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textDim(context))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            borderRadius: 16,
                            tintColor: AppColors.brandAmber,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$cansInMarket Cans',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brandAmber,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t ? 'சந்தையில் உள்ள கேன்கள்' : 'Cans in Market',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text(context)),
                                ),
                                Text('₹${depositsHeld.toStringAsFixed(0)} ${t ? "வைப்புத்தொகை" : "Deposits"}', style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textDim(context))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.point_of_sale, size: 18),
                            label: Text(t ? 'டெலிவரி டிக்கெட்' : 'Delivery Ticket', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.roleDeliveryDriver,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => Scaffold(
                                    appBar: AppBar(title: Text(t ? 'குடிநீர் டெலிவரி டிக்கெட்' : 'Delivery Ticket Machine')),
                                    body: TicketMachineScreen(isTamil: t),
                                  ),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.factory, size: 18),
                            label: Text(t ? 'ஆலை லோடிங்' : 'Plant Refill', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text(context),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: AppColors.border(context)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => Scaffold(
                                    appBar: AppBar(title: Text(t ? 'ஆலை லோடிங் நுழைவு' : 'Plant Refill Intake')),
                                    body: PlantRefillScreen(isTamil: t),
                                  ),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.people, size: 16),
                            label: Text(t ? 'வாடிக்கையாளர் ஜார் லெட்ஜர்' : 'Customer Cans', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11.5)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text(context),
                              side: BorderSide(color: AppColors.border(context)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => CustomersScreen(isTamil: t))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.receipt_long, size: 16),
                            label: Text(t ? 'டெலிவரி ரசீதுகள்' : 'Delivery Slips', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11.5)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text(context),
                              side: BorderSide(color: AppColors.border(context)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => InvoicesScreen(isTamil: t))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Active Beat Routes Section
                    Text(
                      t ? 'செயலில் உள்ள பீட் ரூட்டுகள்' : 'Active Tata Ace Beat Routes',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text(context)),
                    ),
                    const SizedBox(height: 10),

                    ..._routes.map((route) {
                      final name = route['route_name'] ?? 'Route';
                      final vehicle = route['vehicle_no'] ?? 'Tata Ace';
                      final driver = route['driver_name'] ?? 'Driver';
                      final avg = route['daily_avg_cans'] ?? 96;

                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        borderRadius: 14,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.roleDeliveryDriver.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.alt_route, color: AppColors.roleDeliveryDriver, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.text(context)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.brandEmerald.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'ON ROUTE',
                                          style: GoogleFonts.inter(color: AppColors.brandEmerald, fontSize: 8.5, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$vehicle · $driver · Avg: $avg Cans/Day',
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

                    // Recent Deliveries Section
                    Text(
                      t ? 'சமீபத்திய டெலிவரி ரசீதுகள் (Live API)' : 'Recent Delivery Slips (Live API)',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text(context)),
                    ),
                    const SizedBox(height: 10),

                    ..._invoices.map((inv) {
                      final slip = inv['delivery_no'] ?? 'DKW-DEL';
                      final customer = inv['customer_name'] ?? 'Customer';
                      final amount = (inv['total_amount'] ?? 0.0).toDouble();
                      final delivered = inv['cans_delivered'] ?? 0;
                      final empty = inv['empty_cans_collected'] ?? 0;
                      final mode = inv['payment_mode'] ?? 'Cash';

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
                                  slip,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.roleDeliveryDriver),
                                ),
                                Text(
                                  '₹ ${amount.toStringAsFixed(2)}',
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
                                Text('$delivered Cans Delivered', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textDim(context))),
                                const SizedBox(width: 8),
                                Text('•', style: TextStyle(color: AppColors.textDim(context))),
                                const SizedBox(width: 8),
                                Text('$empty Empties Returned', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textDim(context))),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.roleDeliveryDriver.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    mode,
                                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.roleDeliveryDriver),
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
            ),
    );
  }
}
