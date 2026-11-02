import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class InvoicesScreen extends StatefulWidget {
  final bool isTamil;

  const InvoicesScreen({super.key, required this.isTamil});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final data = await _apiService.fetchInvoices();
    if (mounted) {
      setState(() {
        _invoices = data;
        _isLoading = false;
      });
    }
  }

  void _showInvoiceDetails(Map<String, dynamic> inv) {
    final t = widget.isTamil;
    final total = (inv['total_amount'] ?? 0.0).toDouble();
    final mode = inv['payment_mode'] ?? 'Cash';
    final cansDelivered = inv['cans_delivered'] ?? 0;
    final cansCollected = inv['empty_cans_collected'] ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassCard(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt, color: AppColors.brandPurple, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      inv['delivery_no'] ?? 'INV-#${inv['id']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text(context),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${t ? "வாடிக்கையாளர்" : "Customer"}: ${inv['customer_name'] ?? "Unknown"}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${t ? "தேதி" : "Date"}: ${inv['delivery_date'] ?? DateTime.now().toString().substring(0, 10)}',
              style: TextStyle(fontSize: 12, color: AppColors.textDim(context)),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t ? 'வழங்கப்பட்ட கேன்கள்' : 'Cans Delivered', style: TextStyle(color: AppColors.textMuted(context))),
                Text('$cansDelivered', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandSky)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t ? 'பெறப்பட்ட காலிகள்' : 'Empties Collected', style: TextStyle(color: AppColors.textMuted(context))),
                Text('$cansCollected', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandAmber)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t ? 'பணம் செலுத்தும் முறை' : 'Payment Mode', style: TextStyle(color: AppColors.textMuted(context))),
                Text(mode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandPurple)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t ? 'மொத்த தொகை' : 'Grand Total',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text(context)),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.brandEmerald),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
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
              child: const Icon(Icons.receipt_long, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              t ? 'விற்பனை ரசீதுகள்' : 'Sales Invoices & Slips',
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
            onPressed: _loadInvoices,
          ),
        ],
      ),
      body: Column(
        children: [
          // Metrics summary banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
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
                          ? 'ரசீதுகள்: ${_invoices.length} பதிவுகள்'
                          : 'Recent Invoices: ${_invoices.length} Slips',
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
                    t ? 'நேரடி ரசீதுகள்' : 'LIVE DISPATCH SLIPS',
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
          ),

          // Invoices List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.brandPurple),
                  )
                : _invoices.isEmpty
                    ? Center(
                        child: GlassCard(
                          padding: const EdgeInsets.all(24),
                          borderRadius: 24,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: AppColors.textDim(context),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                t ? 'ரசீதுகள் இன்னும் பதிவாகவில்லை' : 'No invoices generated yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t ? 'டிக்கெட் இயந்திரத்தில் விநியோகங்களை பதிவு செய்யவும்' : 'Issue delivery tickets to view live slips here',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textDim(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInvoices,
                        color: AppColors.brandPurple,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: _invoices.length,
                          itemBuilder: (ctx, idx) {
                            final inv = _invoices[idx];
                            final total = (inv['total_amount'] ?? 0.0).toDouble();
                            final mode = inv['payment_mode'] ?? 'Cash';
                            final cansDelivered = inv['cans_delivered'] ?? 0;
                            final cansCollected = inv['empty_cans_collected'] ?? 0;

                            Color modeColor = AppColors.brandEmerald;
                            if (mode == 'UPI') modeColor = AppColors.brandPurple;
                            if (mode == 'Credit') modeColor = AppColors.brandAmber;

                            return GlassCard(
                              isInteractive: true,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              borderRadius: 16,
                              onTap: () => _showInvoiceDetails(inv),
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
                                              color: AppColors.brandNavy.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.receipt, size: 16, color: AppColors.brandPurple),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            inv['delivery_no'] ?? 'INV-#${inv['id']}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.text(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: modeColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: modeColor.withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          mode,
                                          style: TextStyle(
                                            color: modeColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    inv['customer_name'] ?? 'Unknown Customer',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text(context),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 1,
                                    color: AppColors.border(context).withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.water_drop, size: 12, color: AppColors.brandSky),
                                          const SizedBox(width: 4),
                                          Text(
                                            '+$cansDelivered / -$cansCollected',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textMuted(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '₹${total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.brandEmerald,
                                        ),
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
