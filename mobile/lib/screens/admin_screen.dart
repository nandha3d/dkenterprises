import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

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

  final List<DriverSurrenderRecord> _pendingSettlements = [
    DriverSurrenderRecord(
      surrenderCode: 'SURR-20261101-081',
      routeId: 1,
      routeName: 'Town North Beat (Tata Ace TN-59-WA-1011)',
      driverName: 'Murugan (Driver #1)',
      totalLoaded: 80,
      totalDelivered: 74,
      emptyReturned: 70,
      totalCashCollected: 2590.0,
      cashSurrendered: 2590.0,
      variance: 0.0,
      surrenderTime: DateTime.now().subtract(const Duration(minutes: 40)),
    ),
    DriverSurrenderRecord(
      surrenderCode: 'SURR-20261101-082',
      routeId: 2,
      routeName: 'Highway Industrial Estate (Tata Ace TN-59-WA-2022)',
      driverName: 'Senthil (Driver #2)',
      totalLoaded: 100,
      totalDelivered: 96,
      emptyReturned: 91,
      totalCashCollected: 3360.0,
      cashSurrendered: 3310.0,
      variance: -50.0, // Rs 50 shortage
      surrenderTime: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
  ];

  void _approveSettlement(DriverSurrenderRecord record) async {
    final t = widget.isTamil;
    await _apiService.submitDriverSurrender(record);

    setState(() {
      _pendingSettlements.removeWhere((r) => r.surrenderCode == record.surrenderCode);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t
                ? 'டிரைவர் கணக்கு சரிபார்க்கப்பட்டு பொது ரொக்க கணக்கில் சேர்க்கப்பட்டது: ₹ ${record.cashSurrendered}'
                : 'Driver settlement accepted and credited to Main Cash GL 1010: ₹ ${record.cashSurrendered}',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final v = widget.vertical;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [v.primaryColor.withOpacity(0.3), const Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: v.primaryColor.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: v.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(v.icon, color: v.primaryColor, size: 30),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: v.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t ? 'ரூட் மற்றும் வாகன கட்டுப்பாட்டு மையம்' : 'Route Dispatch, Fleet Settlement & Operations Control',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Operational Status KPI
          Text(
            t ? 'இன்றைய செயல்பாட்டு நிலை' : 'Today\'s Dispatch & Field Operations',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildKpiBox(
                  title: t ? 'இயங்கும் வாகனங்கள்' : 'Active Fleet Vehicles',
                  val: v == CompanyVertical.tmws ? '3 Tankers' : '2 Tata Ace Trucks',
                  sub: t ? 'அனைத்தும் ஜி.பி.எஸ் இணைப்பில்' : '100% Live GPS Telematics',
                  color: const Color(0xFF10B981),
                  icon: Icons.directions_car,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiBox(
                  title: t ? 'நிலுவை ஒப்புதல்கள்' : 'Pending Approvals',
                  val: '${_pendingSettlements.length} Settlements',
                  sub: t ? 'காசோலை & ரொக்கம்' : 'Driver Surrenders',
                  color: _pendingSettlements.isEmpty ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  icon: Icons.assignment_turned_in,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pending Driver Surrender Settlements
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.currency_exchange, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    t ? 'டிரைவர் ரொக்கம் & கேன் ஒப்படைப்பு ஒப்புதல்' : 'Driver Cash & Return Empty Approvals',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
              if (_pendingSettlements.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_pendingSettlements.length} ${t ? "நிலுவை" : "Pending"}',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_pendingSettlements.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 40),
                  const SizedBox(height: 10),
                  Text(
                    t ? 'அனைத்து டிரைவர் கணக்குகளும் சமரசம் செய்யப்பட்டு முடிந்தது!' : 'All driver daily cash settlements verified & reconciled!',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingSettlements.length,
              itemBuilder: (context, index) {
                final s = _pendingSettlements[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: s.variance < 0 ? const Color(0xFFEF4444).withOpacity(0.5) : const Color(0xFF334155),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              s.routeName,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            s.surrenderCode,
                            style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Driver: ${s.driverName}',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const Divider(color: Color(0xFF334155), height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat(t ? 'ஏற்றப்பட்டது' : 'Loaded', '${s.totalLoaded} Cans'),
                          _buildMiniStat(t ? 'விநியோகம்' : 'Delivered', '${s.totalDelivered} Cans'),
                          _buildMiniStat(t ? 'காலி கேன்' : 'Returned', '${s.emptyReturned} Cans'),
                          _buildMiniStat(
                            t ? 'வசூலான ரொக்கம்' : 'Cash Collected',
                            '₹ ${s.cashSurrendered.toStringAsFixed(0)}',
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                      if (s.variance < 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEF4444)),
                              const SizedBox(width: 4),
                              Text(
                                t ? 'ரொக்கக் குறைவு: ₹ ${s.variance.abs().toStringAsFixed(0)} (விளக்கம் கேட்கப்பட்டது)' : 'Cash Shortage: ₹ ${s.variance.abs().toStringAsFixed(0)} (Explanation Required)',
                                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t ? 'ஸ்பாட் தணிக்கை குழு அனுப்பப்பட்டது' : 'Spot audit inspection ordered for truck')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF59E0B),
                              side: const BorderSide(color: Color(0xFFF59E0B)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            child: Text(t ? 'ஸ்பாட் தணிக்கை' : 'Spot Audit', style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _approveSettlement(s),
                            icon: const Icon(Icons.check, size: 16),
                            label: Text(t ? 'சரிபார்த்து ஏற்றுக்கொள்' : 'Approve & Deposit', style: const TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildKpiBox({
    required String title,
    required String val,
    required String sub,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
