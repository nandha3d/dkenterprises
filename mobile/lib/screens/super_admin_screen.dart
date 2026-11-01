import 'package:flutter/material.dart';
import '../models/models.dart';

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
  final List<FraudAlertItem> _fraudAlerts = [
    FraudAlertItem(
      id: 'ALT-101',
      title: 'Odometer Tampering Spike',
      companyName: 'Tiruchendur Murugan Water Supply',
      severity: 'High',
      description: 'Tanker TN-58-BW-4001 logged 68 KM trip for 32 KM geofence route. Potential fuel skimming detected.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    FraudAlertItem(
      id: 'ALT-102',
      title: 'Missing Container Variance',
      companyName: 'DK Waters',
      severity: 'Medium',
      description: 'Driver surrendered 24 empty jars against 36 delivered jars without credit slip or deposit on Route 1.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
    ),
    FraudAlertItem(
      id: 'ALT-103',
      title: 'Cash Drawer Variance',
      companyName: 'Aran Cafe',
      severity: 'Low',
      description: 'Shift 1 closed with ₹ 45 shortage against registered POS receipt sales.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive Title & Role Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Color(0xFFA78BFA), size: 32),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('EXECUTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t ? 'டி.கே. எண்டர்பிரைசஸ் ஒருங்கிணைந்த தலைமை தணிக்கை' : 'DK Enterprises Consolidated Multi-Vertical Command',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Consolidated Multi-Enterprise Financial Grid
          Text(
            t ? 'ஒருங்கிணைந்த நிதி நிலை (இன்று)' : 'Consolidated Group Financials (Today)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: t ? 'மொத்த வருவாய்' : 'Gross Group Sales',
                  value: '₹ 1,48,650',
                  sub: t ? '3 நிறுவனங்கள்' : 'Across 3 Entities',
                  color: const Color(0xFF10B981),
                  icon: Icons.currency_rupee,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: t ? 'கையிலுள்ள ரொக்கம்' : 'Cash in Transit',
                  value: '₹ 42,800',
                  sub: t ? 'டிரைவர் & கேஷியர்' : 'Drivers & Counters',
                  color: const Color(0xFFF59E0B),
                  icon: Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: t ? 'பல்க் வாட்டர் விநியோகம்' : 'Bulk Water Decanted',
                  value: '84.0 KL',
                  sub: t ? '6 ஹெவி டேங்கர் ட்ரிப்' : '6 Heavy Tanker Trips',
                  color: const Color(0xFF2563EB),
                  icon: Icons.fire_truck,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: t ? 'குடிநீர் ஜார்கள்' : 'Packaged Jars Out',
                  value: '420 Jars',
                  sub: t ? 'டாடா ஏஸ் ரூட்டுகள்' : 'Tata Ace Beat Routes',
                  color: const Color(0xFF0284C7),
                  icon: Icons.water_drop,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Fast Vertical Jump Cards
          Text(
            t ? 'நிறுவன நேரடி நுழைவு' : 'Enterprise Portals & Operations',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          _buildEnterprisePortalCard(
            title: 'Tiruchendur Murugan Water Supply (TMWS)',
            subtitle: t ? 'பல்க் வாட்டர் டேங்கர் & ஃப்ளீட் விநியோகம்' : 'Commercial Bulk Water Tankers & Heavy Lorries',
            color: const Color(0xFF2563EB),
            badge: 'BULK WATER',
            icon: Icons.fire_truck,
            onTap: () => widget.onSelectVertical(CompanyVertical.tmws),
          ),
          const SizedBox(height: 10),
          _buildEnterprisePortalCard(
            title: 'DK Waters (DKWATERS)',
            subtitle: t ? 'பாக்கேஜ் செய்யப்பட்ட குடிநீர் விநியோகம் (டாடா ஏஸ்)' : 'Packaged Drinking Water Distribution (Tata Ace Fleet)',
            color: const Color(0xFF0284C7),
            badge: 'PACKAGED WATER',
            icon: Icons.water_drop,
            onTap: () => widget.onSelectVertical(CompanyVertical.dkWaters),
          ),
          const SizedBox(height: 10),
          _buildEnterprisePortalCard(
            title: 'Aran Cafe (ARANCAFE)',
            subtitle: t ? 'பேக்கரி & விரைவு பில்லிங் கவுண்டர்' : 'Bakery & Express Counter POS Operations',
            color: const Color(0xFFD97706),
            badge: 'CAFE POS',
            icon: Icons.local_cafe,
            onTap: () => widget.onSelectVertical(CompanyVertical.aranCafe),
          ),
          const SizedBox(height: 24),

          // Anti-Fraud & Risk Radar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 6),
                  Text(
                    t ? 'மோசடி & முரண்பாடு ரேடார்' : 'Anti-Fraud & Risk Radar',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                ),
                child: Text(
                  '${_fraudAlerts.length} ${t ? "எச்சரிக்கைகள்" : "Active Alerts"}',
                  style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _fraudAlerts.length,
            itemBuilder: (context, index) {
              final a = _fraudAlerts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161F30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: a.severity == 'High' ? const Color(0xFFEF4444).withOpacity(0.4) : const Color(0xFF334155),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          a.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: a.severity == 'High' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            a.severity.toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(a.companyName, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(a.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t ? 'தணிக்கை அதிகாரிக்கு எச்சரிக்கை அனுப்பப்பட்டது' : 'Auditor dispatched for physical spot inspection')),
                            );
                          },
                          child: Text(t ? 'தணிக்கை செய்' : 'Order Spot Audit', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
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
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
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
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color.withOpacity(0.5)),
                        ),
                        child: Text(badge, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
