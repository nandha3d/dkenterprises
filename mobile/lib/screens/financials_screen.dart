import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class FinancialsScreen extends StatefulWidget {
  final bool isTamil;

  const FinancialsScreen({super.key, required this.isTamil});

  @override
  State<FinancialsScreen> createState() => _FinancialsScreenState();
}

class _FinancialsScreenState extends State<FinancialsScreen> {
  final _apiService = ApiService();
  Map<String, dynamic> _finData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinancials();
  }

  Future<void> _loadFinancials() async {
    setState(() => _isLoading = true);
    final data = await _apiService.fetchFinancials();
    if (mounted) {
      setState(() {
        _finData = data;
        _isLoading = false;
      });
    }
  }

  Widget _buildGlCard({
    required String title,
    required String glCode,
    required double amount,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        glCode,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: AppColors.textDim(context)),
                ),
              ],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final cash1010 = (_finData['cash_in_hand_1010'] ?? 48250.0).toDouble();
    final bank1020 = (_finData['bank_account_1020'] ?? 184500.0).toDouble();
    final ar1030 = (_finData['accounts_receivable_1030'] ?? 74200.0).toDouble();
    final deposits = (_finData['total_container_deposits'] ?? 120500.0).toDouble();
    final inTransit = (_finData['cash_in_transit_drivers'] ?? 34250.0).toDouble();
    final todayColl = (_finData['today_collections'] ?? 18450.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text(t ? 'நிதி கணக்குகள் (GL லெட்ஜர்)' : 'Financials & Accounts (GL)'),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFinancials,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFinancials,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  // Total Cash & Bank Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t ? 'மொத்த திரவ இருப்பு (Cash + Bank)' : 'Total Liquid Reserves',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${(cash1010 + bank1020).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t ? 'இன்றைய வசூல்: ₹${todayColl.toStringAsFixed(0)}' : 'Today Collections: ₹${todayColl.toStringAsFixed(0)}',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'இரட்டைப்பதிவு GL',
                              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    t ? 'பொது லெட்ஜர் கணக்குகள் (Chart of Accounts):' : 'General Ledger Accounts:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildGlCard(
                    title: t ? 'ரொக்க இருப்பு' : 'Cash in Hand',
                    glCode: 'GL 1010',
                    amount: cash1010,
                    icon: Icons.payments,
                    color: const Color(0xFF10B981),
                    subtitle: t ? 'ஆலை & அலுவலக பணப்பெட்டி' : 'Plant vault & office drawer',
                  ),

                  _buildGlCard(
                    title: t ? 'வங்கி கணக்கு' : 'Bank Accounts',
                    glCode: 'GL 1020',
                    amount: bank1020,
                    icon: Icons.account_balance,
                    color: const Color(0xFF0284C7),
                    subtitle: t ? 'HDFC & SBI நடப்பு கணக்குகள்' : 'Current operating accounts',
                  ),

                  _buildGlCard(
                    title: t ? 'வாடிக்கையாளர் பாக்கி (AR)' : 'Accounts Receivable',
                    glCode: 'GL 1030',
                    amount: ar1030,
                    icon: Icons.assignment_late,
                    color: const Color(0xFFF59E0B),
                    subtitle: t ? 'கார்ப்பரேட் கடன் வாடிக்கையாளர்கள்' : 'Customer outstanding credit balance',
                  ),

                  _buildGlCard(
                    title: t ? 'டிரைவர் கையில் உள்ள பணம்' : 'Cash in Transit',
                    glCode: 'CIT 1015',
                    amount: inTransit,
                    icon: Icons.local_shipping,
                    color: const Color(0xFF8B5CF6),
                    subtitle: t ? 'மாலை ஒப்படைக்க வேண்டிய தொகை' : 'Pending end-of-day driver surrenders',
                  ),

                  _buildGlCard(
                    title: t ? 'கேன் முன்பணப் பொறுப்பு' : 'Container Deposits Liability',
                    glCode: 'GL 2050',
                    amount: deposits,
                    icon: Icons.inventory,
                    color: const Color(0xFFEC4899),
                    subtitle: t ? 'வாடிக்கையாளர் பாதுகாப்பு முன்பணம்' : 'Customer refundable deposit holding',
                  ),
                ],
              ),
            ),
    );
  }
}
