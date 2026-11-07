import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/module_tile.dart';

class ModuleLauncherScreen extends ConsumerStatefulWidget {
  const ModuleLauncherScreen({super.key});

  @override
  ConsumerState<ModuleLauncherScreen> createState() => _ModuleLauncherScreenState();
}

class _ModuleLauncherScreenState extends ConsumerState<ModuleLauncherScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final industry = authState.activeCompany?.industry ?? '';

    // List of all ERP modules grouped by category
    final allCategories = <_ModuleCategory>[
      _ModuleCategory(
        title: 'Sales & Commercial',
        modules: [
          _Module(
            title: 'Sales Invoices',
            description: 'B2B/B2C billing, tax invoice & payment history',
            icon: Icons.receipt_long_rounded,
            route: '/sales',
            color: AppColors.primary,
          ),
          _Module(
            title: 'Quotations',
            description: 'Commercial quotes & price estimates',
            icon: Icons.request_quote_rounded,
            route: '/sales',
            color: AppColors.info,
          ),
          _Module(
            title: 'Customer Payments',
            description: 'Receipt allocation against outstanding dues',
            icon: Icons.payments_rounded,
            route: '/accounting/collect',
            color: AppColors.success,
          ),
        ],
      ),
      _ModuleCategory(
        title: 'Procurement & Purchases',
        modules: [
          _Module(
            title: 'Purchase Bills',
            description: 'Inward vendor bills & payable dues',
            icon: Icons.shopping_bag_rounded,
            route: '/purchases',
            color: const Color(0xFF0284C7),
          ),
          _Module(
            title: 'Supplier Payments',
            description: 'Disbursements from cash/bank accounts',
            icon: Icons.outbox_rounded,
            route: '/purchases',
            color: AppColors.warning,
          ),
        ],
      ),
      _ModuleCategory(
        title: 'Inventory & Godowns',
        modules: [
          _Module(
            title: 'Stock Valuation',
            description: 'Real-time stock valuation by warehouse',
            icon: Icons.inventory_2_rounded,
            route: '/inventory',
            color: AppColors.success,
          ),
          _Module(
            title: 'Physical Stock Count',
            description: 'Barcode scanning and godown variance audits',
            icon: Icons.qr_code_scanner_rounded,
            route: '/inventory/stock-count',
            color: const Color(0xFF64748B),
          ),
        ],
      ),
      _ModuleCategory(
        title: 'Customers & Suppliers (Parties)',
        modules: [
          _Module(
            title: 'Customers 360',
            description: 'Customer list, credit balance, can deposits & KYC',
            icon: Icons.people_alt_rounded,
            route: '/customers',
            color: AppColors.primary,
          ),
          _Module(
            title: 'Suppliers Directory',
            description: 'Vendor contacts, GSTIN & payable statements',
            icon: Icons.storefront_rounded,
            route: '/suppliers',
            color: const Color(0xFF0369A1),
          ),
        ],
      ),
      _ModuleCategory(
        title: 'Accounting & Cash Books',
        modules: [
          _Module(
            title: 'Day Book & Cash Book',
            description: 'Cash-in-hand (1010) & Bank (1020) ledger movements',
            icon: Icons.menu_book_rounded,
            route: '/accounting/books',
            color: AppColors.brandNavy,
          ),
          _Module(
            title: 'Quick Expense Voucher',
            description: 'Instant receipt capture with camera & GPS stamp',
            icon: Icons.attach_money_rounded,
            route: '/expenses/new',
            color: AppColors.danger,
          ),
        ],
      ),
      _ModuleCategory(
        title: 'Vertical Operations',
        modules: [
          if (industry == 'packaged_water' || industry.isEmpty) ...[
            _Module(
              title: 'Can Sales POS Ticket',
              description: 'Fast 15-second driver sales & return tickets',
              icon: Icons.water_drop_rounded,
              route: '/operations/can-sales',
              color: const Color(0xFF0284C7),
            ),
            _Module(
              title: 'Plant Refill Manifest',
              description: 'Factory empty load & full refill batches',
              icon: Icons.factory_rounded,
              route: '/operations/plant-refill',
              color: const Color(0xFF0369A1),
            ),
            _Module(
              title: 'Spot Empty Can Audit',
              description: 'Customer jar count vs ledger balance audit',
              icon: Icons.fact_check_rounded,
              route: '/operations/spot-audit',
              color: AppColors.warning,
            ),
            _Module(
              title: 'Driver Cash Surrender',
              description: 'End-of-day route settlement with admin cashier',
              icon: Icons.price_check_rounded,
              route: '/operations/driver-surrender',
              color: AppColors.success,
            ),
          ],
          if (industry == 'bulk_water' || industry.isEmpty)
            _Module(
              title: 'Tanker Trip Sheet',
              description: 'Dispatches, km odometers, motor pumping & waiting surcharges',
              icon: Icons.local_shipping_rounded,
              route: '/operations/tanker-trip',
              color: const Color(0xFF0369A1),
            ),
          if (industry == 'cafe_bakery' || industry.isEmpty)
            _Module(
              title: 'Bakery & Cafe POS',
              description: 'Touch terminal billing & cash drawer closing',
              icon: Icons.restaurant_rounded,
              route: '/operations/cafe-pos',
              color: const Color(0xFFD97706),
            ),
        ],
      ),
      _ModuleCategory(
        title: 'HRM & Attendance',
        modules: [
          _Module(
            title: 'Geofenced Attendance',
            description: 'Facial selfie & GPS check-in / check-out',
            icon: Icons.fingerprint_rounded,
            route: '/hrm/attendance',
            color: AppColors.info,
          ),
        ],
      ),
      _ModuleCategory(
        title: 'Analytics & Reports',
        modules: [
          _Module(
            title: 'Financial & Sales Reports',
            description: 'Sales summaries, stock aging & customer ledgers',
            icon: Icons.bar_chart_rounded,
            route: '/reports',
            color: AppColors.brandPurple,
          ),
        ],
      ),
    ];

    // Filter categories & modules by search query
    final filteredCategories = allCategories
        .map((cat) {
          final matchingModules = cat.modules.where((m) {
            if (_searchQuery.isEmpty) return true;
            return m.title.toLowerCase().contains(_searchQuery) ||
                m.description.toLowerCase().contains(_searchQuery);
          }).toList();
          return _ModuleCategory(title: cat.title, modules: matchingModules);
        })
        .where((cat) => cat.modules.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Modules'),
      ),
      body: Column(
        children: [
          // Search Field Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(bottom: BorderSide(color: borderCol, width: 1)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search modules, workflows, reports...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // Categories List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (ctx, catIndex) {
                final cat = filteredCategories[catIndex];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.title,
                      style: AppTypography.section.copyWith(color: textCol, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cat.modules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, modIndex) {
                        final mod = cat.modules[modIndex];

                        return ModuleTile(
                          title: mod.title,
                          description: mod.description,
                          icon: mod.icon,
                          color: mod.color,
                          onTap: () => context.push(mod.route),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCategory {
  final String title;
  final List<_Module> modules;

  const _ModuleCategory({
    required this.title,
    required this.modules,
  });
}

class _Module {
  final String title;
  final String description;
  final IconData icon;
  final String route;
  final Color color;

  const _Module({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    required this.color,
  });
}

