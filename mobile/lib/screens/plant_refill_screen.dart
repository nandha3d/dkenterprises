import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class PlantRefillScreen extends StatefulWidget {
  final bool isTamil;

  const PlantRefillScreen({super.key, required this.isTamil});

  @override
  State<PlantRefillScreen> createState() => _PlantRefillScreenState();
}

class _PlantRefillScreenState extends State<PlantRefillScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _slipController = TextEditingController(text: 'RO-2026-9941');
  final TextEditingController _odometerController = TextEditingController(text: '54210');

  int _loadSequence = 2; // Load 2
  int _cansLoaded = 84;
  final String _plantName = 'Main RO Water Treatment Plant (Erode)';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _loadsToday = [
    {'sequence': 1, 'time': '07:30 AM', 'cans': 72, 'slip': 'RO-2026-9912'},
  ];

  void _stepLoaded(int delta) {
    setState(() {
      final next = _cansLoaded + delta;
      if (next >= 5) _cansLoaded = next;
    });
  }

  Future<void> _submitRefill() async {
    setState(() => _isSubmitting = true);

    final record = PlantRefillRecord(
      loadSequence: _loadSequence,
      plantName: _plantName,
      cansLoaded: _cansLoaded,
      ratePerCan: 8.00,
      slipNumber: _slipController.text,
      odometerKm: int.tryParse(_odometerController.text) ?? 54210,
      timestamp: DateTime.now(),
    );

    await _apiService.submitPlantRefill(record, 1);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _loadsToday.add({
          'sequence': _loadSequence,
          'time': DateTime.now().toLocal().toString().substring(11, 16),
          'cans': _cansLoaded,
          'slip': _slipController.text,
        });
        _loadSequence++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTamil
                ? 'ஆலை கேன் ஏற்றுதல் பதிவானது! வண்டியில் +$_cansLoaded கேன்கள் சேர்க்கப்பட்டன.'
                : 'Plant refill logged! +$_cansLoaded jars added to truck stock.',
          ),
          backgroundColor: AppColors.brandEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final totalShiftCans = _loadsToday.fold<int>(0, (sum, item) => sum + (item['cans'] as int));

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plant Header Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              tintColor: AppColors.brandPurple,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.brandNavy, AppColors.brandPurple],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.factory, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t ? 'ஆலை கேன் லோடிங் & கேட் பாஸ்' : 'RO Plant Intake & Gate Pass',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _plantName,
                          style: TextStyle(fontSize: 11, color: AppColors.textDim(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stepper Load Count Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              child: Column(
                children: [
                  Text(
                    t ? 'ஏற்றப்பட்ட கேன்கள் எண்ணிக்கை (Load $_loadSequence)' : 'Jars Loaded Intake (Load $_loadSequence)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted(context)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle, size: 36, color: AppColors.brandDanger),
                        onPressed: () => _stepLoaded(-5),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '$_cansLoaded',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandSky,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 36, color: AppColors.brandEmerald),
                        onPressed: () => _stepLoaded(5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t ? '20 லிட்டர் குடிநீர் கேன்கள்' : '20L Standard Jars',
                    style: TextStyle(fontSize: 11, color: AppColors.textDim(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Slip & Odometer Inputs Card
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 20,
              child: Column(
                children: [
                  TextFormField(
                    controller: _slipController,
                    style: TextStyle(color: AppColors.text(context), fontSize: 13),
                    decoration: InputDecoration(
                      labelText: t ? 'ஆலை ரசீது எண் (RO Slip #)' : 'Plant Slip Number',
                      labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 12),
                      prefixIcon: const Icon(Icons.receipt, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _odometerController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: AppColors.text(context), fontSize: 13),
                    decoration: InputDecoration(
                      labelText: t ? 'வாகன ஓடோமீட்டர் ரீடிங் (KM)' : 'Vehicle Odometer (KM)',
                      labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 12),
                      prefixIcon: const Icon(Icons.speed, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRefill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              t ? 'ஏற்றுதலை உறுதி செய்து பதிவிடு' : 'Confirm & Log Plant Intake',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Loads Today History
            Text(
              t ? 'இன்றைய ஏற்றுதல் வரலாறு (மொத்தம்: $totalShiftCans)' : 'Loads Logged Today (Total: $totalShiftCans Jars)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text(context)),
            ),
            const SizedBox(height: 10),
            ..._loadsToday.map((load) {
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                borderRadius: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.brandSky.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'L${load['sequence']}',
                            style: const TextStyle(color: AppColors.brandSky, fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${load['slip']}',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.text(context)),
                            ),
                            Text(
                              '${load['time']}',
                              style: TextStyle(fontSize: 10, color: AppColors.textDim(context)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '+${load['cans']} Jars',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.brandEmerald),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
