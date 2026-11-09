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

    final user = authState.user;
    final role = (user?.role ?? '').toLowerCase();
    final username = (user?.username ?? user?.name ?? '').toLowerCase();

    final isTankerDriver = role == 'tankerdriver' || username == 'tanker_driver' || username == 'tanker';
    final isDeliveryDriver = role == 'deliverydriver' || role == 'driver' || username == 'driver';
    final isCashier = role == 'cashier' || username == 'cashier';
    final isFieldAgent = role == 'fieldagent' || role == 'agent' || username == 'agent';

    final allCategories = <_ModuleCategory>[];

    if (isTankerDriver) {
      allCategories.addAll([
        const _ModuleCategory(
          title: 'Bulk Tanker Operations',
          modules: [
            _Module(
              title: 'Tanker Trip Sheet',
              description: 'Dispatches, odometers, decanting & surcharges',
              icon: Icons.local_shipping_rounded,
              route: '/operations/tanker-trip',
              color: Color(0xFF0284C7),
            ),
            _Module(
              title: 'Diesel & Vehicle Expenses',
              description: 'Fuel slips, tanker repair & toll expenditure',
              icon: Icons.local_gas_station_rounded,
              route: '/expenses/new',
              color: AppColors.warning,
            ),
          ],
        ),
        const _ModuleCategory(
          title: 'Staff & Attendance',
          modules: [
            _Module(
              title: 'Geofenced Attendance',
              description: 'GPS check-in / check-out',
              icon: Icons.fingerprint_rounded,
              route: '/hrm/attendance',
              color: AppColors.info,
            ),
          ],
        ),
      ]);
    } else if (isDeliveryDriver) {
      allCategories.addAll([
        const _ModuleCategory(
          title: '20L Can Distribution Operations',
          modules: [
            _Module(
              title: 'Can Sales POS Ticket',
              description: 'Fast 15-second driver sales & return tickets',
              icon: Icons.water_drop_rounded,
              route: '/operations/can-sales',
              color: Color(0xFF059669),
            ),
            _Module(
              title: 'Spot Empty Can Audit',
              description: 'Inspect Tata Ace vehicle cans vs route manifest',
              icon: Icons.fact_check_rounded,
              route: '/operations/spot-audit',
              color: AppColors.warning,
            ),
            _Module(
              title: 'Driver Cash Surrender',
              description: 'End-of-day route settlement with cashier',
              icon: Icons.price_check_rounded,
              route: '/operations/driver-surrender',
              color: Color(0xFF0284C7),
            ),
            _Module(
              title: 'Route Fuel & Expenses',
              description: 'Daily diesel & van maintenance slips',
              icon: Icons.attach_money_rounded,
              route: '/expenses/new',
              color: AppColors.warning,
            ),
          ],
        ),
        const _ModuleCategory(
          title: 'Staff & Attendance',
          modules: [
            _Module(
              title: 'Geofenced Attendance',
              description: 'GPS check-in / check-out',
              icon: Icons.fingerprint_rounded,
              route: '/hrm/attendance',
              color: AppColors.info,
            ),
          ],
        ),
      ]);
    } else if (isCashier) {
      allCategories.addAll([
        const _ModuleCategory(
          title: 'Bakery & POS Operations',
          modules: [
            _Module(
              title: 'Bakery & Cafe POS',
              description: 'Touch terminal billing & kitchen orders',
              icon: Icons.restaurant_rounded,
              route: '/operations/cafe-pos',
              color: Color(0xFFD97706),
            ),
            _Module(
              title: 'Daily Cash Drawer Closing',
              description: 'Cash-in-hand (1010) register balance',
              icon: Icons.menu_book_rounded,
              route: '/accounting/books',
              color: AppColors.brandNavy,
            ),
            _Module(
              title: 'Customer Payment Collection',
              description: 'Collect outstanding party dues',
              icon: Icons.payments_rounded,
              route: '/accounting/collect',
              color: AppColors.success,
            ),
            _Module(
              title: 'Kitchen & Daily Expenses',
              description: 'Vegetables, milk & daily purchases',
              icon: Icons.attach_money_rounded,
              route: '/expenses/new',
              color: AppColors.danger,
            ),
          ],
        ),
        const _ModuleCategory(
          title: 'Staff & Attendance',
          modules: [
            _Module(
              title: 'Geofenced Attendance',
              description: 'GPS check-in / check-out',
              icon: Icons.fingerprint_rounded,
              route: '/hrm/attendance',
              color: AppColors.info,
            ),
          ],
        ),
      ]);
    } else if (isFieldAgent) {
      allCategories.addAll([
        const _ModuleCategory(
          title: 'Commercial Field Operations',
          modules: [
            _Module(
              title: 'Customer Dues & Collection',
              description: 'Receipt allocation against outstanding dues',
              icon: Icons.payments_rounded,
              route: '/accounting/collect',
              color: AppColors.success,
            ),
            _Module(
              title: 'Customer Directory & GPS Pins',
              description: 'Customer list, credit balance & location update',
              icon: Icons.people_alt_rounded,
              route: '/customers',
              color: AppColors.primary,
            ),
            _Module(
              title: 'Field Conveyance & Expenses',
              description: 'Instant receipt capture with camera & GPS',
              icon: Icons.attach_money_rounded,
              route: '/expenses/new',
              color: AppColors.warning,
            ),
          ],
        ),
        const _ModuleCategory(
          title: 'Staff & Attendance',
          modules: [
            _Module(
              title: 'Geofenced Attendance',
              description: 'GPS check-in / check-out',
              icon: Icons.fingerprint_rounded,
              route: '/hrm/attendance',
              color: AppColors.info,
            ),
          ],
        ),
      ]);
    } else {
      // Full ERP Suite for Admin / Super Admin
      allCategories.addAll([
        const _ModuleCategory(
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
        const _ModuleCategory(
          title: 'Procurement & Purchases',
          modules: [
            _Module(
              title: 'Purchase Bills',
              description: 'Inward vendor bills & payable dues',
              icon: Icons.shopping_bag_rounded,
              route: '/purchases',
              color: Color(0xFF0284C7),
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
        const _ModuleCategory(
          title: 'Inventory & Godowns',
          modules: [
            _Module(
              title: 'Product Catalog & Config',
              description: 'Item master, barcode symbology, pricing & vertical setup',
              icon: Icons.category_rounded,
              route: '/products',
              color: AppColors.primary,
            ),
            _Module(
              title: 'New Product Configuration',
              description: 'Tabbed master configuration for standard, combo & services',
              icon: Icons.add_box_rounded,
              route: '/products/new',
              color: AppColors.brandPurple,
            ),
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
              color: Color(0xFF64748B),
            ),
          ],
        ),
        const _ModuleCategory(
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
              color: Color(0xFF0369A1),
            ),
          ],
        ),
        const _ModuleCategory(
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
          title: switch (industry) {
            'cafe_bakery' => 'Bakery & Cafe Operations',
            'bulk_water' => 'Bulk Tanker Fleet Logistics',
            'packaged_water' => '20L Can Route Distribution',
            'textile' => 'Textile & Garment Operations',
            _ => 'Commercial Operations',
          },
          modules: [
            // 1. Cafe & Bakery Vertical (Aran Cafe)
            if (industry == 'cafe_bakery') ...[
              const _Module(
                title: 'Bakery & Cafe POS',
                description: 'Touch terminal billing & cash drawer closing',
                icon: Icons.restaurant_rounded,
                route: '/operations/cafe-pos',
                color: Color(0xFFD97706),
              ),
              const _Module(
                title: 'Kitchen & Recipe Inventory',
                description: 'Bakery ingredient stocks, flour & dairy audit',
                icon: Icons.inventory_2_rounded,
                route: '/inventory/stock-count',
                color: Color(0xFF059669),
              ),
              const _Module(
                title: 'Cafe Expenses & Purchases',
                description: 'Vegetables, milk, gas & daily operational bills',
                icon: Icons.receipt_long_rounded,
                route: '/expenses/new',
                color: AppColors.primary,
              ),
            ]
            // 2. Bulk Water Tankers Vertical (TMWS)
            else if (industry == 'bulk_water') ...[
              const _Module(
                title: 'Live Tanker GPS Fleet Radar',
                description: 'Radar tracking, decanting flow rate, dwell time & fuel',
                icon: Icons.share_location_rounded,
                route: '/fleet/gps?mode=bulk_water',
                color: Color(0xFF0369A1),
              ),
              const _Module(
                title: 'Tanker Trip Sheet',
                description: 'Dispatches, km odometers, motor pumping & waiting surcharges',
                icon: Icons.local_shipping_rounded,
                route: '/operations/tanker-trip',
                color: Color(0xFF0284C7),
              ),
              const _Module(
                title: 'Trip Payment Collection',
                description: 'Collect driver cash & corporate commercial dues',
                icon: Icons.payments_rounded,
                route: '/accounting/collect',
                color: AppColors.success,
              ),
              const _Module(
                title: 'Diesel & Vehicle Maintenance',
                description: 'Fuel slips, tanker repair & toll expenditure',
                icon: Icons.local_gas_station_rounded,
                route: '/expenses/new',
                color: AppColors.warning,
              ),
            ]
            // 3. 20L Can Route Distribution Vertical (DK Waters)
            else if (industry == 'packaged_water') ...[
              const _Module(
                title: 'Tata Ace Beat GPS Radar',
                description: 'Route beat perimeter, delivery stops & van jar balance',
                icon: Icons.share_location_rounded,
                route: '/fleet/gps?mode=packaged_water',
                color: Color(0xFF0284C7),
              ),
              const _Module(
                title: 'Can Sales POS Ticket',
                description: 'Fast 15-second driver sales & return tickets',
                icon: Icons.water_drop_rounded,
                route: '/operations/can-sales',
                color: Color(0xFF059669),
              ),
              const _Module(
                title: 'Spot Empty Can Audit',
                description: 'Inspect Tata Ace vehicle cans vs route manifest',
                icon: Icons.fact_check_rounded,
                route: '/operations/spot-audit',
                color: AppColors.warning,
              ),
              const _Module(
                title: 'Driver Cash Surrender',
                description: 'End-of-day route settlement with admin cashier',
                icon: Icons.price_check_rounded,
                route: '/operations/driver-surrender',
                color: Color(0xFF0284C7),
              ),
              const _Module(
                title: 'RO Plant Refill Manifest',
                description: 'Reverse Osmosis factory intake batch logs',
                icon: Icons.factory_rounded,
                route: '/operations/plant-refill',
                color: AppColors.primary,
              ),
            ]
            // 4. Textile & Garment Manufacturing Vertical (zoloERP Textiles)
            else if (industry == 'textile') ...[
              const _Module(
                title: 'Wholesale Tax Invoicing',
                description: 'Fabric & garment commercial invoice generation',
                icon: Icons.receipt_long_rounded,
                route: '/sales/new',
                color: Color(0xFF7C3AED),
              ),
              const _Module(
                title: 'Fabric Roll & Yarn Stock Audit',
                description: 'Physical meter roll and yarn weight audits',
                icon: Icons.inventory_2_rounded,
                route: '/inventory/stock-count',
                color: AppColors.primary,
              ),
              const _Module(
                title: 'Commercial Debtor Collection',
                description: 'Collect trade receivables against B2B invoices',
                icon: Icons.payments_rounded,
                route: '/accounting/collect',
                color: AppColors.success,
              ),
            ],
          ],
        ),
        const _ModuleCategory(
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
        const _ModuleCategory(
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
      ]);
    }

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

