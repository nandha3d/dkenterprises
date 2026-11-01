import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CustomersScreen extends StatefulWidget {
  final bool isTamil;

  const CustomersScreen({super.key, required this.isTamil});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final data = await _apiService.fetchCustomers();
    if (mounted) {
      setState(() {
        _customers = data;
        _filteredCustomers = data;
        _isLoading = false;
      });
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((c) {
          final name = (c['name'] ?? '').toString().toLowerCase();
          final phone = (c['phone'] ?? '').toString().toLowerCase();
          final city = (c['city'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || phone.contains(q) || city.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text(t ? 'வாடிக்கையாளர் பட்டியல் (ERP)' : 'Customers Directory (ERP)'),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: TextStyle(color: AppColors.text(context), fontSize: 13),
              decoration: InputDecoration(
                hintText: t ? 'பெயர், தொலைபேசி அல்லது ஊர் தேடுக...' : 'Search customer by name, phone, city...',
                hintStyle: TextStyle(color: AppColors.textDim(context), fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.card(context),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
              ),
              onChanged: _filterCustomers,
            ),
          ),

          // Total Count Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t ? 'பதிவான வாடிக்கையாளர்கள்: ${_filteredCustomers.length}' : 'Active Customers: ${_filteredCustomers.length}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted(context)),
                ),
                Text(
                  t ? 'நேரடி ERP தரவு' : 'Live ERP Data',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? Center(
                        child: Text(
                          t ? 'வாடிக்கையாளர் கிடைக்கவில்லை' : 'No customers found',
                          style: TextStyle(color: AppColors.textMuted(context)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCustomers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (ctx, idx) {
                            final c = _filteredCustomers[idx];
                            final cansHeld = c['cans_held'] ?? 0;
                            final deposit = (c['deposit_held'] ?? 0.0).toDouble();

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
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0284C7).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.person, color: Color(0xFF0284C7), size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c['name'] ?? 'Unknown',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.text(context),
                                              ),
                                            ),
                                            Text(
                                              '${c['phone'] ?? ''} • ${c['city'] ?? ''}',
                                              style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'ID #${c['id']}',
                                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (c['address'] != null && c['address'].toString().isNotEmpty)
                                    Text(
                                      c['address'],
                                      style: TextStyle(fontSize: 11, color: AppColors.textDim(context)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.water_drop, size: 14, color: Color(0xFF0284C7)),
                                          const SizedBox(width: 4),
                                          Text(
                                            t ? 'கையில் உள்ள கேன்கள்: ' : 'Cans Held: ',
                                            style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
                                          ),
                                          Text(
                                            '$cansHeld',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.account_balance_wallet, size: 14, color: Color(0xFFF59E0B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            t ? 'முன்பணம்: ' : 'Deposit: ',
                                            style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
                                          ),
                                          Text(
                                            '₹${deposit.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                          ),
                                        ],
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
