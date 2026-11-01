import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text(t ? 'விற்பனை ரசீதுகள் (இன்வாய்ஸ்)' : 'Sales Invoices & Slips'),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInvoices,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _invoices.length,
                itemBuilder: (ctx, idx) {
                  final inv = _invoices[idx];
                  final total = (inv['total_amount'] ?? 0.0).toDouble();
                  final mode = inv['payment_mode'] ?? 'Cash';
                  final cansDelivered = inv['cans_delivered'] ?? 0;
                  final cansCollected = inv['empty_cans_collected'] ?? 0;

                  Color modeColor = const Color(0xFF10B981);
                  if (mode == 'UPI') modeColor = const Color(0xFF8B5CF6);
                  if (mode == 'Credit') modeColor = const Color(0xFFF59E0B);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_long, size: 16, color: Color(0xFF0284C7)),
                                const SizedBox(width: 6),
                                Text(
                                  inv['delivery_no'] ?? 'INV-#${inv['id']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text(context),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: modeColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: modeColor.withOpacity(0.4)),
                              ),
                              child: Text(
                                mode,
                                style: TextStyle(
                                  color: modeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          inv['customer_name'] ?? 'Customer',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(context),
                          ),
                        ),
                        Text(
                          '${inv['delivery_date'] ?? ''} • 20L Water Jars',
                          style: TextStyle(fontSize: 11, color: AppColors.textDim(context)),
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  t ? 'விநியோகம்: ' : 'Delivered: ',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
                                ),
                                Text(
                                  '$cansDelivered',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  t ? 'திரும்பியது: ' : 'Returned: ',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
                                ),
                                Text(
                                  '$cansCollected',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                            Text(
                              '₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
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
    );
  }
}
