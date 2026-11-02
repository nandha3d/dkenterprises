import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

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
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        glCode,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: AppColors.textDim(context)),
                ),
              ],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
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

    final cash1010 = (_finData['cash_in_hand_1010'] ?? 0.0).toDouble();
    final bank1020 = (_finData['bank_account_1020'] ?? 0.0).toDouble();
    final ar1030 = (_finData['accounts_receivable_1030'] ?? 0.0).toDouble();
    final deposits = (_finData['total_container_deposits'] ?? 0.0).toDouble();
    final cit = (_finData['cash_in_transit_drivers'] ?? 0.0).toDouble();
    final todayCol = (_finData['today_collections'] ?? 0.0).toDouble();

    final totalAssets = cash1010 + bank1020 + ar1030 + cit;

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
              child: const Icon(Icons.account_balance, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              t ? 'நிதி & பொது லெட்ஜர் (GL)' : 'Financials & General Ledger',
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
            onPressed: _loadFinancials,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandPurple),
            )
          : RefreshIndicator(
              onRefresh: _loadFinancials,
              color: AppColors.brandPurple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Liquid & Working Capital Card
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 22,
                      tintColor: AppColors.brandPurple,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t ? 'மொத்த நடைமுறை மூலதனம் (Liquid Assets)' : 'Working Capital & Liquid Assets',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted(context),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.brandEmerald.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ERP AUDITED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brandEmerald,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '₹${totalAssets.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: AppColors.text(context),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                    ? 'இன்றைய நேரடி வசூல்: ₹${todayCol.toStringAsFixed(2)}'
                                    : 'Today\'s Total Inflow: ₹${todayCol.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandEmerald,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t ? 'பொது லெட்ஜர் கணக்குகள் (GL Matrix)' : 'General Ledger Accounts Matrix',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: AppColors.text(context),
                          ),
                        ),
                        Text(
                          t ? 'நேரடி ERP இருப்பு' : 'Live Sync',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDim(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // GL 1010 - Main Cash in Hand
                    _buildGlCard(
                      title: t ? 'பிரதான ரொக்கம்' : 'Cash in Hand',
                      glCode: 'GL 1010',
                      amount: cash1010,
                      icon: Icons.payments,
                      color: AppColors.brandEmerald,
                      subtitle: t ? 'ஆலை அலுவலக பாதுகாப்பு பெட்டகத்தில் உள்ளது' : 'Plant Office Vault Balance',
                    ),

                    // GL 1020 - Bank Account
                    _buildGlCard(
                      title: t ? 'வங்கி கணக்கு' : 'Operating Bank Account',
                      glCode: 'GL 1020',
                      amount: bank1020,
                      icon: Icons.account_balance,
                      color: AppColors.brandPurple,
                      subtitle: t ? 'HDFC நடப்பு கணக்கு' : 'Current Account (HDFC/ICICI)',
                    ),

                    // GL 1030 - Accounts Receivable
                    _buildGlCard(
                      title: t ? 'சந்தை வரவு நிலுவை (AR)' : 'Accounts Receivable (AR)',
                      glCode: 'GL 1030',
                      amount: ar1030,
                      icon: Icons.assignment_late,
                      color: AppColors.brandAmber,
                      subtitle: t ? 'வாடிக்கையாளர் கடன் நிலுவை' : 'Customer Credit Ledger Outstanding',
                    ),

                    // CIT 1015 - Cash in Transit (Route Drivers)
                    _buildGlCard(
                      title: t ? 'பயண வழியில் உள்ள ரொக்கம்' : 'Cash in Transit (CIT)',
                      glCode: 'CIT 1015',
                      amount: cit,
                      icon: Icons.local_shipping,
                      color: AppColors.brandSky,
                      subtitle: t ? 'டாடா ஏஸ் ஓட்டுநர்களிடம் உள்ள தொகை' : 'Held by Route Delivery Drivers',
                    ),

                    // GL 2050 - Container Security Deposit
                    _buildGlCard(
                      title: t ? 'கேன் முன்பணம் (பாதுகாப்பு வைப்பு)' : 'Jar Security Deposits',
                      glCode: 'GL 2050',
                      amount: deposits,
                      icon: Icons.lock,
                      color: const Color(0xFF6366F1),
                      subtitle: t ? 'வாடிக்கையாளர்களிடம் பெறப்பட்ட பாதுகாப்பு வைப்பு' : 'Refundable Custody Liability',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
