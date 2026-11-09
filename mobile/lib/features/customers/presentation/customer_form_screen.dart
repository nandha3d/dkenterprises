import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/location_parser.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialCustomer;

  const CustomerFormScreen({
    super.key,
    this.initialCustomer,
  });

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _waNumberController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _whatsappLocationController;
  late final TextEditingController _initialCansController;
  late final TextEditingController _depositController;
  late final TextEditingController _openingBalanceController;
  late final TextEditingController _gstinController;

  bool _sameAsPhone = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  double? _parsedLat;
  double? _parsedLng;

  int _selectedRouteId = 1;
  final List<Map<String, dynamic>> _routes = [
    {'id': 1, 'name': 'Route 1 - Anna Nagar & Teppakulam (Tata Ace WA-101)'},
    {'id': 2, 'name': 'Route 2 - KK Nagar & Mattuthavani (Tata Ace WA-102)'},
    {'id': 3, 'name': 'Commercial Bulk Tanker Route (TMWS Tanker Fleet)'},
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialCustomer ?? {};
    _nameController = TextEditingController(text: init['name']?.toString() ?? '');
    _companyNameController = TextEditingController(text: init['company_name']?.toString() ?? '');
    _phoneController = TextEditingController(text: init['phone']?.toString() ?? init['phone_number']?.toString() ?? '');
    _waNumberController = TextEditingController(text: init['wa_number']?.toString() ?? _phoneController.text);
    _contactPersonController = TextEditingController(text: init['contact_person']?.toString() ?? '');
    _addressController = TextEditingController(text: init['address']?.toString() ?? '');
    _cityController = TextEditingController(text: init['city']?.toString() ?? 'Erode');
    _whatsappLocationController = TextEditingController();
    _initialCansController = TextEditingController(text: init['cans_held']?.toString() ?? '5');
    _depositController = TextEditingController(text: init['deposit_held']?.toString() ?? '750');
    _openingBalanceController = TextEditingController(text: init['opening_balance']?.toString() ?? '0.00');
    _gstinController = TextEditingController(text: init['tax_no']?.toString() ?? '');

    if (init['latitude'] != null && init['longitude'] != null) {
      _parsedLat = double.tryParse(init['latitude'].toString());
      _parsedLng = double.tryParse(init['longitude'].toString());
    }

    _phoneController.addListener(() {
      if (_sameAsPhone) {
        _waNumberController.text = _phoneController.text;
      }
    });

    _initialCansController.addListener(() {
      final cans = int.tryParse(_initialCansController.text) ?? 0;
      _depositController.text = (cans * 150).toString();
    });

    _whatsappLocationController.addListener(_parseWhatsAppLocation);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _waNumberController.dispose();
    _contactPersonController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _whatsappLocationController.dispose();
    _initialCansController.dispose();
    _depositController.dispose();
    _openingBalanceController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  void _parseWhatsAppLocation() {
    final text = _whatsappLocationController.text.trim();
    if (text.isEmpty) return;

    final coords = LocationParser.extractCoordinates(text);
    if (coords != null) {
      setState(() {
        _parsedLat = coords.latitude;
        _parsedLng = coords.longitude;
      });
    }
  }

  Future<void> _submitCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final activeCompany = ref.read(authNotifierProvider).activeCompany;

      final payload = {
        'name': _nameController.text.trim(),
        'company_name': _companyNameController.text.trim().isNotEmpty
            ? _companyNameController.text.trim()
            : _nameController.text.trim(),
        'contact_person': _contactPersonController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'wa_number': _waNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'company_id': activeCompany?.id ?? 3,
        'customer_group_id': 1,
        'route_id': _selectedRouteId,
        'latitude': _parsedLat,
        'longitude': _parsedLng,
        'whatsapp_location': _whatsappLocationController.text.trim(),
        'opening_cans_held': int.tryParse(_initialCansController.text.trim()) ?? 0,
        'deposit_held': double.tryParse(_depositController.text.trim()) ?? 0.0,
        'opening_balance': double.tryParse(_openingBalanceController.text.trim()) ?? 0.0,
        'tax_no': _gstinController.text.trim(),
      };

      final res = await apiClient.post(
        ApiEndpoints.customerOnboard,
        data: payload,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (!mounted) return;

      if (res.isSuccess) {
        final data = res.dataOrNull?['data'] ?? res.dataOrNull ?? {};
        final code = data['customer_code'] ?? 'CUST-${data['id'] ?? 'NEW'}';
        final name = data['name'] ?? _nameController.text.trim();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer $name ($code) onboarded successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppColors.brandEmerald,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = res.failureOrNull?.message ?? 'Failed to onboard customer.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1C2541) : Colors.white;
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textPrim = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSec = isDark ? Colors.white70 : const Color(0xFF64748B);
    final activeCompany = ref.watch(authNotifierProvider).activeCompany;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        title: Text(
          'Onboard New Customer',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandEmerald.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brandEmerald.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business, size: 12, color: AppColors.brandEmerald),
                const SizedBox(width: 4),
                Text(
                  activeCompany?.code ?? 'ERP',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.brandEmerald),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandDanger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brandDanger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.brandDanger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(color: AppColors.brandDanger, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Section 1: Customer Identity & Shop Details
            _buildSectionHeader('1. Customer & Shop Identity', Icons.storefront_rounded, AppColors.brandSky),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer / Shop Name *',
                      hintText: 'e.g. Sri Murugan Hotel',
                      prefixIcon: Icon(Icons.person_rounded, size: 20),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter customer name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _companyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business / Enterprise Legal Name',
                      hintText: 'e.g. Murugan Hospitality Pvt Ltd',
                      prefixIcon: Icon(Icons.business_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            hintText: '10-digit mobile',
                            prefixIcon: Icon(Icons.phone_rounded, size: 20),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Phone required';
                            if (val.trim().length < 8) return 'Invalid phone';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _contactPersonController,
                          decoration: const InputDecoration(
                            labelText: 'Contact Person',
                            hintText: 'Manager / Owner',
                            prefixIcon: Icon(Icons.badge_rounded, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _sameAsPhone = !_sameAsPhone;
                        if (_sameAsPhone) {
                          _waNumberController.text = _phoneController.text;
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _sameAsPhone,
                              onChanged: (val) {
                                setState(() {
                                  _sameAsPhone = val ?? true;
                                  if (_sameAsPhone) {
                                    _waNumberController.text = _phoneController.text;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'WhatsApp Number is same as Phone',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textSec),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!_sameAsPhone) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _waNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp Number *',
                        prefixIcon: Icon(Icons.chat_rounded, color: AppColors.brandEmerald, size: 20),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Section 2: Address & WhatsApp GPS Capture
            _buildSectionHeader('2. Delivery Address & GPS Location', Icons.location_on_rounded, AppColors.brandEmerald),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Street Address & Landmark *',
                      hintText: 'e.g. 14, Perundurai Road (Opp. New Bus Stand)',
                      prefixIcon: Icon(Icons.signpost_rounded, size: 20),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter address' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City / Taluk *',
                            prefixIcon: Icon(Icons.location_city_rounded, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _gstinController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'GSTIN (Optional)',
                            hintText: '33AAAAA0000A1Z5',
                            prefixIcon: Icon(Icons.receipt_long_rounded, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // WhatsApp GPS Link Capture
                  Text(
                    'Instant WhatsApp Location Capture',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: textPrim),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Paste WhatsApp customer shared Google Maps link or location text:',
                    style: GoogleFonts.inter(fontSize: 11, color: textSec),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _whatsappLocationController,
                    decoration: InputDecoration(
                      hintText: 'e.g. https://maps.google.com/?q=11.341,77.717',
                      prefixIcon: const Icon(Icons.share_location_rounded, color: AppColors.brandEmerald, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste_rounded, size: 20),
                        tooltip: 'Parse Link',
                        onPressed: _parseWhatsAppLocation,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // GPS Coordinates Preview
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _parsedLat != null ? AppColors.brandEmerald.withOpacity(0.08) : Colors.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _parsedLat != null ? AppColors.brandEmerald.withOpacity(0.3) : Colors.amber.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _parsedLat != null ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          size: 16,
                          color: _parsedLat != null ? AppColors.brandEmerald : Colors.amber.shade800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _parsedLat != null
                                ? 'GPS Coordinates Locked: $_parsedLat, $_parsedLng'
                                : 'No GPS Coordinates Set (Paste WhatsApp Link Above)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _parsedLat != null ? AppColors.brandEmerald : Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Section 3: Route Beat & 20L Water Can Inventory
            _buildSectionHeader('3. Route Beat & Water Inventory', Icons.water_drop_rounded, AppColors.brandAmber),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    value: _selectedRouteId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Delivery Route Beat *',
                      prefixIcon: Icon(Icons.alt_route_rounded, size: 20),
                    ),
                    items: _routes.map((r) {
                      return DropdownMenuItem<int>(
                        value: r['id'] as int,
                        child: Text(
                          r['name'] as String,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRouteId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _initialCansController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Initial Cans Held',
                            hintText: 'e.g. 5',
                            prefixIcon: Icon(Icons.water_drop, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _depositController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Security Deposit (₹)',
                            hintText: 'e.g. 750',
                            prefixIcon: Icon(Icons.currency_rupee, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _openingBalanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Opening Balance Due (₹)',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.account_balance_wallet_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Icon(Icons.person_add_alt_1_rounded, size: 20),
                label: Text(
                  _isSubmitting ? 'Registering Customer...' : 'Save & Onboard Customer',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandSky,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: _isSubmitting ? null : _submitCustomer,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}
