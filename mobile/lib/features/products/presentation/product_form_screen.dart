import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialProduct;

  const ProductFormScreen({super.key, this.initialProduct});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  bool _isLoadingMeta = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Metadata catalogs from API
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _taxes = [];
  List<Map<String, dynamic>> _warehouses = [];
  List<String> _types = ['standard', 'combo', 'digital', 'service'];
  List<String> _symbologies = ['C128', 'C39', 'UPCA', 'UPCE', 'EAN8', 'EAN13'];

  // Tab 1: General Form Controllers
  late TextEditingController _nameController;
  late TextEditingController _printNameController;
  late TextEditingController _codeController;
  late TextEditingController _tagsController;
  late TextEditingController _descriptionController;
  String _selectedType = 'standard';
  String _selectedSymbology = 'C128';
  String _selectedUsage = 'composite';
  int? _selectedCategoryId;
  int? _selectedBrandId;
  int? _selectedUnitId;

  // Tab 2: Pricing & Tax Controllers
  late TextEditingController _costController;
  late TextEditingController _profitMarginController;
  String _profitMarginType = 'percentage'; // percentage or fixed
  late TextEditingController _priceController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _dailyObjectiveController;
  int? _selectedTaxId;
  int _taxMethod = 1; // 1: Exclusive, 2: Inclusive
  bool _isPromotion = false;
  late TextEditingController _promoPriceController;
  DateTime? _promoStart;
  DateTime? _promoEnd;

  // Tab 3: Inventory & Warehouse Controllers
  late TextEditingController _initialStockController;
  int? _selectedWarehouseId;
  late TextEditingController _alertQtyController;
  bool _inStock = true;
  bool _trackInventory = true;
  bool _isBatch = false;
  bool _isImei = false;
  bool _isDiffPrice = false;

  // Tab 4: Variants
  bool _hasVariants = false;
  late TextEditingController _variantOptionController;
  late TextEditingController _variantValueController;
  List<String> _variantValues = [];

  // Tab 5: Verticals & Advanced
  late TextEditingController _waterDepositController;
  late TextEditingController _nominalCapacityController;
  late TextEditingController _kitchenStationController;
  String _menuType = 'standard';
  bool _isTopping = false;
  bool _featured = false;
  bool _isOnline = true;
  late TextEditingController _warrantyController;
  late TextEditingController _guaranteeController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    final p = widget.initialProduct ?? {};
    _nameController = TextEditingController(text: p['name']?.toString() ?? '');
    _printNameController = TextEditingController(text: p['print_name']?.toString() ?? p['name']?.toString() ?? '');
    _codeController = TextEditingController(text: p['code']?.toString() ?? '');
    _tagsController = TextEditingController(text: p['tags']?.toString() ?? '');
    _descriptionController = TextEditingController(text: p['product_details']?.toString() ?? '');

    _selectedType = p['type']?.toString() ?? 'standard';
    _selectedSymbology = p['barcode_symbology']?.toString() ?? 'C128';
    _selectedUsage = p['product_usage']?.toString() ?? 'composite';
    _selectedCategoryId = p['category_id'] as int?;
    _selectedBrandId = p['brand_id'] as int?;
    _selectedUnitId = p['unit_id'] as int?;

    _costController = TextEditingController(text: (p['cost'] ?? 0.0).toString());
    _profitMarginController = TextEditingController(text: (p['profit_margin'] ?? 20.0).toString());
    _profitMarginType = p['profit_margin_type']?.toString() ?? 'percentage';
    _priceController = TextEditingController(text: (p['price'] ?? 0.0).toString());
    _wholesalePriceController = TextEditingController(text: (p['wholesale_price'] ?? 0.0).toString());
    _dailyObjectiveController = TextEditingController(text: (p['daily_sale_objective'] ?? 0).toString());
    _selectedTaxId = p['tax_id'] as int?;
    _taxMethod = (p['tax_method'] as num?)?.toInt() ?? 1;
    _isPromotion = p['promotion'] == true || p['promotion'] == 1;
    _promoPriceController = TextEditingController(text: (p['promotion_price'] ?? 0.0).toString());

    _initialStockController = TextEditingController(text: (p['qty'] ?? 0.0).toString());
    _alertQtyController = TextEditingController(text: (p['alert_quantity'] ?? 5).toString());
    _inStock = p['in_stock'] != false && p['in_stock'] != 0;
    _trackInventory = p['track_inventory'] != false && p['track_inventory'] != 0;
    _isBatch = p['is_batch'] == true || p['is_batch'] == 1;
    _isImei = p['is_imei'] == true || p['is_imei'] == 1;
    _isDiffPrice = p['is_diffPrice'] == true || p['is_diffPrice'] == 1;

    _hasVariants = p['is_variant'] == true || p['is_variant'] == 1;
    _variantOptionController = TextEditingController(text: p['variant_option']?.toString() ?? 'Size');
    _variantValueController = TextEditingController();
    if (p['variant_value'] != null) {
      _variantValues = p['variant_value'].toString().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    _waterDepositController = TextEditingController(text: '150');
    _nominalCapacityController = TextEditingController(text: '20');
    _kitchenStationController = TextEditingController(text: p['kitchen_id']?.toString() ?? '');
    _menuType = p['menu_type']?.toString() ?? 'standard';
    _isTopping = p['is_addon'] == true || p['is_addon'] == 1;
    _featured = p['featured'] == true || p['featured'] == 1;
    _isOnline = p['is_online'] != false && p['is_online'] != 0;
    _warrantyController = TextEditingController(text: p['warranty']?.toString() ?? '');
    _guaranteeController = TextEditingController(text: p['guarantee']?.toString() ?? '');

    _fetchMetadata();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _printNameController.dispose();
    _codeController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _profitMarginController.dispose();
    _priceController.dispose();
    _wholesalePriceController.dispose();
    _dailyObjectiveController.dispose();
    _promoPriceController.dispose();
    _initialStockController.dispose();
    _alertQtyController.dispose();
    _variantOptionController.dispose();
    _variantValueController.dispose();
    _waterDepositController.dispose();
    _nominalCapacityController.dispose();
    _kitchenStationController.dispose();
    _warrantyController.dispose();
    _guaranteeController.dispose();
    super.dispose();
  }

  Future<void> _fetchMetadata() async {
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.get(
        ApiEndpoints.productMetadata,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (!mounted) return;

      if (res.isSuccess) {
        final d = res.dataOrNull!;
        final raw = d['data'] is Map ? d['data'] as Map : d;

        setState(() {
          _isLoadingMeta = false;
          _categories = (raw['categories'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _brands = (raw['brands'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _units = (raw['units'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _taxes = (raw['taxes'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _warehouses = (raw['warehouses'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

          if (_categories.isNotEmpty && _selectedCategoryId == null) {
            _selectedCategoryId = _categories.first['id'] as int?;
          }
          if (_units.isNotEmpty && _selectedUnitId == null) {
            _selectedUnitId = _units.first['id'] as int?;
          }
          if (_warehouses.isNotEmpty && _selectedWarehouseId == null) {
            _selectedWarehouseId = _warehouses.first['id'] as int?;
          }
        });
      } else {
        setState(() {
          _isLoadingMeta = false;
          _errorMessage = res.failureOrNull?.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMeta = false;
          _errorMessage = 'Could not load configuration catalogs.';
        });
      }
    }
  }

  void _recalculatePrice() {
    final cost = double.tryParse(_costController.text) ?? 0.0;
    final margin = double.tryParse(_profitMarginController.text) ?? 0.0;

    double price = cost;
    if (_profitMarginType == 'percentage') {
      price = cost + (cost * (margin / 100.0));
    } else {
      price = cost + margin;
    }

    _priceController.text = price.toStringAsFixed(2);
  }

  void _generateSku() {
    final prefix = _nameController.text.isNotEmpty
        ? _nameController.text.substring(0, _nameController.text.length >= 3 ? 3 : _nameController.text.length).toUpperCase()
        : 'PRD';
    final randomSuffix = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    setState(() {
      _codeController.text = '$prefix-$randomSuffix';
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the validation errors in the form.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final client = ref.read(apiClientProvider);

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'print_name': _printNameController.text.trim().isNotEmpty ? _printNameController.text.trim() : _nameController.text.trim(),
      'code': _codeController.text.trim(),
      'type': _selectedType,
      'barcode_symbology': _selectedSymbology,
      'product_usage': _selectedUsage,
      'category_id': _selectedCategoryId,
      'brand_id': _selectedBrandId,
      'unit_id': _selectedUnitId,
      'cost': double.tryParse(_costController.text) ?? 0.0,
      'profit_margin': double.tryParse(_profitMarginController.text) ?? 0.0,
      'profit_margin_type': _profitMarginType,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'wholesale_price': double.tryParse(_wholesalePriceController.text) ?? 0.0,
      'daily_sale_objective': int.tryParse(_dailyObjectiveController.text) ?? 0,
      'tax_id': _selectedTaxId,
      'tax_method': _taxMethod,
      'promotion': _isPromotion ? 1 : 0,
      'promotion_price': _isPromotion ? (double.tryParse(_promoPriceController.text) ?? 0.0) : null,
      'starting_date': _isPromotion && _promoStart != null ? DateFormat('yyyy-MM-dd').format(_promoStart!) : null,
      'last_date': _isPromotion && _promoEnd != null ? DateFormat('yyyy-MM-dd').format(_promoEnd!) : null,
      'alert_quantity': double.tryParse(_alertQtyController.text) ?? 5.0,
      'in_stock': _inStock ? 1 : 0,
      'track_inventory': _trackInventory ? 1 : 0,
      'is_batch': _isBatch ? 1 : 0,
      'is_imei': _isImei ? 1 : 0,
      'is_diffPrice': _isDiffPrice ? 1 : 0,
      'is_variant': _hasVariants ? 1 : 0,
      'variant_option': _hasVariants ? _variantOptionController.text.trim() : null,
      'variant_value': _hasVariants ? _variantValues.join(',') : null,
      'featured': _featured ? 1 : 0,
      'is_online': _isOnline ? 1 : 0,
      'is_addon': _isTopping ? 1 : 0,
      'menu_type': _menuType,
      'kitchen_id': int.tryParse(_kitchenStationController.text),
      'product_details': _descriptionController.text.trim(),
      'tags': _tagsController.text.trim(),
      'warranty': _warrantyController.text.trim(),
      'guarantee': _guaranteeController.text.trim(),
    };

    if (widget.initialProduct == null) {
      payload['initial_stock'] = double.tryParse(_initialStockController.text) ?? 0.0;
      payload['warehouse_id'] = _selectedWarehouseId;
    }

    try {
      final isEdit = widget.initialProduct != null;
      final id = widget.initialProduct?['id'];

      final res = isEdit
          ? await client.put(
              ApiEndpoints.productDetail(id as int),
              data: payload,
              fromJson: (data) => data as Map<String, dynamic>,
            )
          : await client.post(
              ApiEndpoints.productCatalog,
              data: payload,
              fromJson: (data) => data as Map<String, dynamic>,
            );

      if (!mounted) return;

      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Product updated successfully.' : 'Product created and cataloged.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failureOrNull?.message ?? 'Failed to save product.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error saving product configuration.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardCol = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final isEdit = widget.initialProduct != null;

    final authState = ref.watch(authNotifierProvider);
    final industry = authState.activeCompany?.industry ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product Details' : 'New Product Configuration'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.info_outline_rounded), text: 'General'),
            Tab(icon: Icon(Icons.payments_outlined), text: 'Pricing & Tax'),
            Tab(icon: Icon(Icons.warehouse_outlined), text: 'Stock & Godown'),
            Tab(icon: Icon(Icons.tune_rounded), text: 'Variants'),
            Tab(icon: Icon(Icons.star_outline_rounded), text: 'Verticals & Adv'),
          ],
        ),
      ),
      body: _isLoadingMeta
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _isLoadingMeta = true);
                            _fetchMetadata();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralTab(context, cardCol, borderCol, textCol),
                  _buildPricingTab(context, cardCol, borderCol, textCol),
                  _buildInventoryTab(context, cardCol, borderCol, textCol, isEdit),
                  _buildVariantsTab(context, cardCol, borderCol, textCol),
                  _buildVerticalsTab(context, cardCol, borderCol, textCol, industry),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardCol,
          border: Border(top: BorderSide(color: borderCol, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: borderCol),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(_isSaving ? 'Saving...' : (isEdit ? 'Save Changes' : 'Create Product')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: General Info
  Widget _buildGeneralTab(BuildContext context, Color cardCol, Color borderCol, Color textCol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCard(
            cardCol,
            borderCol,
            title: 'Primary Identification',
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name *', hintText: 'e.g. 20L Water Can, Croissant, Fabric Roll'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Product name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _printNameController,
                decoration: const InputDecoration(labelText: 'Print Name (Receipt/Bill)', hintText: 'Optional alias printed on POS vouchers'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(labelText: 'Product Code / SKU *', hintText: 'e.g. WTR-20L'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Product code is required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.auto_awesome),
                    tooltip: 'Auto Generate SKU',
                    onPressed: _generateSku,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            cardCol,
            borderCol,
            title: 'Classification & Standards',
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Product Type *'),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _selectedType = v ?? 'standard'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSymbology,
                decoration: const InputDecoration(labelText: 'Barcode Symbology *'),
                items: _symbologies.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _selectedSymbology = v ?? 'C128'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: _categories.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name']?.toString() ?? ''))).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedBrandId,
                decoration: const InputDecoration(labelText: 'Brand (Optional)'),
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('No Brand')),
                  ..._brands.map((b) => DropdownMenuItem(value: b['id'] as int, child: Text(b['name']?.toString() ?? ''))),
                ],
                onChanged: (v) => setState(() => _selectedBrandId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedUnitId,
                decoration: const InputDecoration(labelText: 'Base Unit *'),
                items: _units.map((u) => DropdownMenuItem(value: u['id'] as int, child: Text('${u['unit_name']} (${u['unit_code']})'))).toList(),
                onChanged: (v) => setState(() => _selectedUnitId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Tags / Keywords', hintText: 'comma-separated tags for fast search'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Product Details / Specification', hintText: 'Public or internal notes about this SKU'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 2: Pricing & Tax
  Widget _buildPricingTab(BuildContext context, Color cardCol, Color borderCol, Color textCol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCard(
            cardCol,
            borderCol,
            title: 'Cost & Margin Calculation',
            children: [
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Purchase / Production Cost (₹) *', prefixText: '₹ '),
                onChanged: (_) => _recalculatePrice(),
                validator: (val) => val == null || val.isEmpty ? 'Cost is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _profitMarginController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Profit Margin *'),
                      onChanged: (_) => _recalculatePrice(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _profitMarginType,
                      decoration: const InputDecoration(labelText: 'Margin Mode'),
                      items: const [
                        DropdownMenuItem(value: 'percentage', child: Text('% Percent')),
                        DropdownMenuItem(value: 'fixed', child: Text('₹ Fixed')),
                      ],
                      onChanged: (v) {
                        setState(() => _profitMarginType = v ?? 'percentage');
                        _recalculatePrice();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Retail Selling Price / MRP (₹) *',
                  prefixText: '₹ ',
                  helperText: 'Auto-computes from Cost + Margin or manually override',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Price is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _wholesalePriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Wholesale / Corporate Price (₹)', prefixText: '₹ '),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            cardCol,
            borderCol,
            title: 'Taxation & Fiscal Settings',
            children: [
              DropdownButtonFormField<int>(
                value: _selectedTaxId,
                decoration: const InputDecoration(labelText: 'Tax Rate'),
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('No Tax (0%)')),
                  ..._taxes.map((t) => DropdownMenuItem(value: t['id'] as int, child: Text('${t['name']} (${t['rate']}%)'))),
                ],
                onChanged: (v) => setState(() => _selectedTaxId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _taxMethod,
                decoration: const InputDecoration(labelText: 'Tax Calculation Method'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Exclusive (Tax added on top of Price)')),
                  DropdownMenuItem(value: 2, child: Text('Inclusive (Tax included inside Price)')),
                ],
                onChanged: (v) => setState(() => _taxMethod = v ?? 1),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dailyObjectiveController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Daily Sales Objective / Target (Units)', hintText: 'Target volume per day'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            cardCol,
            borderCol,
            title: 'Promotional Pricing',
            children: [
              SwitchListTile(
                title: const Text('Enable Promotional Price'),
                subtitle: const Text('Temporarily offer discounted rate for campaigns'),
                value: _isPromotion,
                onChanged: (v) => setState(() => _isPromotion = v),
              ),
              if (_isPromotion) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _promoPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Promotional Price (₹)', prefixText: '₹ '),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_promoStart == null ? 'Start Date' : DateFormat('dd MMM yyyy').format(_promoStart!)),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _promoStart ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (d != null) setState(() => _promoStart = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event, size: 16),
                        label: Text(_promoEnd == null ? 'End Date' : DateFormat('dd MMM yyyy').format(_promoEnd!)),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _promoEnd ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (d != null) setState(() => _promoEnd = d);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // TAB 3: Inventory & Warehouse
  Widget _buildInventoryTab(BuildContext context, Color cardCol, Color borderCol, Color textCol, bool isEdit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCard(
            cardCol,
            borderCol,
            title: 'Stock Balances & Thresholds',
            children: [
              if (!isEdit) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _initialStockController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Initial Opening Stock'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedWarehouseId,
                        decoration: const InputDecoration(labelText: 'Godown / Warehouse'),
                        items: _warehouses.map((w) => DropdownMenuItem(value: w['id'] as int, child: Text(w['name']?.toString() ?? ''))).toList(),
                        onChanged: (v) => setState(() => _selectedWarehouseId = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _alertQtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Minimum Alert Quantity',
                  helperText: 'Triggers low stock warnings on executive dashboard',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('In Stock Availability'),
                subtitle: const Text('Turn off if temporarily unavailable or seasonal'),
                value: _inStock,
                onChanged: (v) => setState(() => _inStock = v),
              ),
              SwitchListTile(
                title: const Text('Track Inventory Balances'),
                subtitle: const Text('Automatically deduct upon sale and add on purchase'),
                value: _trackInventory,
                onChanged: (v) => setState(() => _trackInventory = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            cardCol,
            borderCol,
            title: 'Tracking Features',
            children: [
              SwitchListTile(
                title: const Text('Batch & Expiry Tracking'),
                subtitle: const Text('Enables batch numbers, manufacturing & expiry dates'),
                value: _isBatch,
                onChanged: (v) => setState(() => _isBatch = v),
              ),
              SwitchListTile(
                title: const Text('IMEI / Serial Number Tracking'),
                subtitle: const Text('Enables tracking unique devices/equipment serial numbers'),
                value: _isImei,
                onChanged: (v) => setState(() => _isImei = v),
              ),
              SwitchListTile(
                title: const Text('Different Price by Warehouse'),
                subtitle: const Text('Maintain independent pricing matrices across godowns'),
                value: _isDiffPrice,
                onChanged: (v) => setState(() => _isDiffPrice = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 4: Variants
  Widget _buildVariantsTab(BuildContext context, Color cardCol, Color borderCol, Color textCol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCard(
            cardCol,
            borderCol,
            title: 'Variant Configurations',
            children: [
              SwitchListTile(
                title: const Text('This Product has Multiple Variants'),
                subtitle: const Text('e.g. Size, Color, Liters, Flavour'),
                value: _hasVariants,
                onChanged: (v) => setState(() => _hasVariants = v),
              ),
              if (_hasVariants) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _variantOptionController,
                  decoration: const InputDecoration(
                    labelText: 'Option Attribute Name',
                    hintText: 'e.g. Size, Volume, Weight',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _variantValueController,
                        decoration: const InputDecoration(
                          labelText: 'Add Value',
                          hintText: 'e.g. 20L, 500ml, 1KG, Large',
                        ),
                        onFieldSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            setState(() {
                              _variantValues.add(val.trim());
                              _variantValueController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_variantValueController.text.trim().isNotEmpty) {
                          setState(() {
                            _variantValues.add(_variantValueController.text.trim());
                            _variantValueController.clear();
                          });
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _variantValues.map((val) {
                    return Chip(
                      label: Text(val),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() => _variantValues.remove(val));
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // TAB 5: Verticals & Advanced
  Widget _buildVerticalsTab(BuildContext context, Color cardCol, Color borderCol, Color textCol, String industry) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCard(
            cardCol,
            borderCol,
            title: 'Water Logistics Specifics',
            children: [
              TextFormField(
                controller: _waterDepositController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '20L Jar / Can Deposit Amount (₹)',
                  prefixText: '₹ ',
                  helperText: 'Refundable security deposit charged on new customer KYC',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nominalCapacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal Volume Capacity (Liters)',
                  helperText: 'Used for bulk water tanker and bottle line balance',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            cardCol,
            borderCol,
            title: 'Bakery, Kitchen & Restaurant POS',
            children: [
              TextFormField(
                controller: _kitchenStationController,
                decoration: const InputDecoration(
                  labelText: 'Kitchen Display / Station ID',
                  hintText: 'e.g. Oven Station, Tea Counter, Packaging Unit',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _menuType,
                decoration: const InputDecoration(labelText: 'Menu Type'),
                items: const [
                  DropdownMenuItem(value: 'standard', child: Text('Regular Menu')),
                  DropdownMenuItem(value: 'breakfast', child: Text('Breakfast Only')),
                  DropdownMenuItem(value: 'evening', child: Text('Evening Snacks / Tea')),
                  DropdownMenuItem(value: 'special', child: Text('Weekend Special')),
                ],
                onChanged: (v) => setState(() => _menuType = v ?? 'standard'),
              ),
              SwitchListTile(
                title: const Text('Is Topping / Extra Item'),
                subtitle: const Text('Item can be attached as add-on to main bakery items'),
                value: _isTopping,
                onChanged: (v) => setState(() => _isTopping = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            cardCol,
            borderCol,
            title: 'Digital & Online Capabilities',
            children: [
              SwitchListTile(
                title: const Text('Featured Product'),
                subtitle: const Text('Prioritized at top of mobile POS and billing machines'),
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
              ),
              SwitchListTile(
                title: const Text('Available for Online POS / Delivery'),
                subtitle: const Text('Enables catalog inclusion for field drivers and web store'),
                value: _isOnline,
                onChanged: (v) => setState(() => _isOnline = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _warrantyController,
                      decoration: const InputDecoration(labelText: 'Warranty Period', hintText: 'e.g. 1 Year, 6 Months'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _guaranteeController,
                      decoration: const InputDecoration(labelText: 'Guarantee Period', hintText: 'e.g. 30 Days Replacement'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Color cardCol, Color borderCol, {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTypography.section.copyWith(fontSize: 14, color: AppColors.primary),
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}
