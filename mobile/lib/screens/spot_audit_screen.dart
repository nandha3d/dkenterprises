import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SpotAuditScreen extends StatefulWidget {
  final bool isTamil;
  final UserRole? activeRole;

  const SpotAuditScreen({super.key, required this.isTamil, this.activeRole});

  @override
  State<SpotAuditScreen> createState() => _SpotAuditScreenState();
}

class _SpotAuditScreenState extends State<SpotAuditScreen> {
  final ApiService _apiService = ApiService();
  String _auditTarget = 'packaged'; // 'packaged', 'tanker', 'cafe'

  final _vehicleController = TextEditingController(text: 'Tata Ace TN-58-WA-101');
  final _driverController = TextEditingController(text: 'Kumar (Driver)');
  final _unitsObservedController = TextEditingController(text: '25');
  final _cashObservedController = TextEditingController(text: '1810');
  final _notesController = TextEditingController();

  final int _expectedUnits = 25;
  final double _expectedCash = 1810.0;

  bool _isSubmitting = false;

  bool get _canSwitchTarget {
    if (widget.activeRole == UserRole.deliveryDriver ||
        widget.activeRole == UserRole.fieldAgent ||
        widget.activeRole == UserRole.tankerDriver ||
        widget.activeRole == UserRole.cashier) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    if (widget.activeRole == UserRole.deliveryDriver || widget.activeRole == UserRole.fieldAgent) {
      _auditTarget = 'packaged';
      _vehicleController.text = 'Tata Ace TN-58-WA-101';
      _driverController.text = 'Kumar (Driver)';
    } else if (widget.activeRole == UserRole.tankerDriver) {
      _auditTarget = 'tanker';
      _vehicleController.text = 'Tanker TN-58-BW-2001';
      _driverController.text = 'Murugan S. (Driver)';
    } else if (widget.activeRole == UserRole.cashier) {
      _auditTarget = 'cafe';
      _vehicleController.text = 'POS Register #01';
      _driverController.text = 'Cashier Desk';
    }
  }

  Future<void> _submitAudit() async {
    setState(() => _isSubmitting = true);

    final observedUnits = int.tryParse(_unitsObservedController.text) ?? 0;
    final observedCash = double.tryParse(_cashObservedController.text) ?? 0.0;
    final unitDiff = observedUnits - _expectedUnits;
    final cashDiff = observedCash - _expectedCash;
    final isFraud = unitDiff.abs() > 2 || cashDiff.abs() > 100;

    final audit = SpotAuditRecord(
      vehicleNumber: _vehicleController.text,
      driverName: _driverController.text,
      expectedUnits: _expectedUnits,
      physicalUnits: observedUnits,
      expectedCash: _expectedCash,
      physicalCash: observedCash,
      unitDifference: unitDiff,
      cashDifference: cashDiff,
      isFraudSuspected: isFraud,
      auditNotes: _notesController.text.isEmpty ? 'Regular spot check' : _notesController.text,
      auditTime: DateTime.now(),
    );

    await _apiService.submitSpotAudit(audit);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTamil
                ? 'களத் தணிக்கை கிளவுட் மோசடி தடுப்பு மையத்தில் சமர்ப்பிக்கப்பட்டது!'
                : 'Spot audit recorded and synced to Anti-Fraud Command!',
          ),
          backgroundColor: isFraud ? AppColors.brandDanger : AppColors.brandEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final observedUnits = int.tryParse(_unitsObservedController.text) ?? 0;
    final observedCash = double.tryParse(_cashObservedController.text) ?? 0.0;
    final unitDiff = observedUnits - _expectedUnits;
    final cashDiff = observedCash - _expectedCash;
    final isClean = (unitDiff == 0 && cashDiff == 0.0);
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: canPop
          ? AppBar(
              title: Text(
                t ? 'களத் தணிக்கை & மோசடி எதிர்ப்பு' : 'Spot Audit & Anti-Fraud',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
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
                    child: const Icon(Icons.security, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t ? 'திடீர் களத் தணிக்கை (ஸ்பாட் ஆடிட்)' : 'Anti-Theft Field Spot Audit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t
                              ? 'நேரடி ஸ்டாக் மற்றும் ஓட்டுனர் ரொக்கம் சரிபார்ப்பு'
                              : 'Physical manifest vs driver cash verification',
                          style: TextStyle(fontSize: 11, color: AppColors.textDim(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Target Selector Pills (Gated)
            if (_canSwitchTarget)
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(t ? 'குடிநீர் வேன்' : 'Water Van'),
                      selected: _auditTarget == 'packaged',
                      selectedColor: AppColors.brandPurple,
                      labelStyle: TextStyle(
                        color: _auditTarget == 'packaged' ? Colors.white : AppColors.textMuted(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                      onSelected: (v) => setState(() => _auditTarget = 'packaged'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(t ? 'டேங்கர்' : 'Bulk Tanker'),
                      selected: _auditTarget == 'tanker',
                      selectedColor: AppColors.brandPurple,
                      labelStyle: TextStyle(
                        color: _auditTarget == 'tanker' ? Colors.white : AppColors.textMuted(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                      onSelected: (v) => setState(() => _auditTarget = 'tanker'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(t ? 'கஃபே' : 'Cafe POS'),
                      selected: _auditTarget == 'cafe',
                      selectedColor: AppColors.brandPurple,
                      labelStyle: TextStyle(
                        color: _auditTarget == 'cafe' ? Colors.white : AppColors.textMuted(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                      onSelected: (v) => setState(() => _auditTarget = 'cafe'),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brandPurple.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _auditTarget == 'tanker'
                          ? Icons.fire_truck
                          : (_auditTarget == 'cafe' ? Icons.local_cafe : Icons.water_drop),
                      size: 16,
                      color: AppColors.brandPurple,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _auditTarget == 'tanker'
                          ? (t ? 'பல்க் டேங்கர் தணிக்கை' : 'TMWS Tanker Physical Check')
                          : (_auditTarget == 'cafe'
                              ? (t ? 'கஃபே ரொக்க தணிக்கை' : 'Aran Cafe Drawer Check')
                              : (t ? 'குடிநீர் கேன் நேரடி தணிக்கை' : 'DK Waters Can & Cash Check')),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text(context),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Audit Physical vs Expected Card
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t ? 'நேரடி ஆய்வு விவரங்கள்' : 'Audit Observations',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text(context)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _unitsObservedController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: AppColors.text(context), fontSize: 13),
                          decoration: InputDecoration(
                            labelText: t ? 'பார்த்த கேன்கள்' : 'Physical Units',
                            labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cashObservedController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: AppColors.text(context), fontSize: 13),
                          decoration: InputDecoration(
                            labelText: t ? 'பார்த்த ரொக்கம் (₹)' : 'Physical Cash (₹)',
                            labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notesController,
                    style: TextStyle(color: AppColors.text(context), fontSize: 13),
                    decoration: InputDecoration(
                      labelText: t ? 'ஆய்வுக் குறிப்புகள்' : 'Audit Notes & Observations',
                      labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 11),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Variance Result Badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isClean ? AppColors.brandEmerald.withOpacity(0.12) : AppColors.brandDanger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isClean ? AppColors.brandEmerald.withOpacity(0.3) : AppColors.brandDanger.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isClean ? Icons.check_circle : Icons.warning_amber_rounded,
                          color: isClean ? AppColors.brandEmerald : AppColors.brandDanger,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isClean
                                ? (t ? 'இருப்பு மற்றும் ரொக்கம் 100% சரியாக உள்ளது!' : 'Stock & cash 100% reconciled!')
                                : (t ? 'வித்தியாசம்: $unitDiff கேன்கள், ₹$cashDiff ரொக்கம்' : 'Variance: $unitDiff units, ₹$cashDiff cash'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isClean ? AppColors.brandEmerald : AppColors.brandDanger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAudit,
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
                              t ? 'தணிக்கை முடிவைச் சமர்ப்பி' : 'Submit Audit to Anti-Fraud Command',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
