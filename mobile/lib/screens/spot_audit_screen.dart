import 'package:flutter/material.dart';

class SpotAuditScreen extends StatefulWidget {
  final bool isTamil;

  const SpotAuditScreen({super.key, required this.isTamil});

  @override
  State<SpotAuditScreen> createState() => _SpotAuditScreenState();
}

class _SpotAuditScreenState extends State<SpotAuditScreen> {
  String _auditTarget = 'packaged'; // 'packaged' (DK Waters), 'tanker' (TMWS), 'cafe' (Aran Cafe)

  final _unitsObservedController = TextEditingController(text: '25');
  final _cashObservedController = TextEditingController(text: '1810');
  bool _auditDone = false;

  final int _expectedUnits = 25;
  final double _expectedCash = 1810.0;

  void _runAudit() {
    setState(() => _auditDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final observedUnits = int.tryParse(_unitsObservedController.text) ?? 0;
    final observedCash = double.tryParse(_cashObservedController.text) ?? 0.0;
    final unitDiff = observedUnits - _expectedUnits;
    final cashDiff = observedCash - _expectedCash;
    final isClean = (unitDiff == 0 && cashDiff == 0.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD97706)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: Color(0xFFFBBF24), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isTamil ? 'திடீர் களத் தணிக்கை (ஸ்பாட் ஆடிட்)' : 'Surprise Field Spot Audit',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      Text(
                        widget.isTamil
                            ? 'நேரடி ஸ்டாக் மற்றும் ஓட்டுனர் ரொக்கம் சரிபார்ப்பு'
                            : 'Physical manifest vs driver cash verification & anti-fraud audit',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Audit Target Selector (Packaged Water / Bulk Tanker / Cafe)
          Text(
            widget.isTamil ? 'தணிக்கை செய்யப்படும் பிரிவு (Vehicle Type):' : 'Select Target for Audit:',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTargetPill('packaged', widget.isTamil ? 'குடிநீர் வேன் (Tata Ace)' : 'Packaged Water Van', const Color(0xFF0284C7)),
              const SizedBox(width: 8),
              _buildTargetPill('tanker', widget.isTamil ? 'வாட்டர் டேங்கர்' : 'Bulk Tanker', const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              _buildTargetPill('cafe', widget.isTamil ? 'கஃபே கவுண்டர்' : 'Cafe Counter', const Color(0xFFD97706)),
            ],
          ),
          const SizedBox(height: 18),

          // Expected vs Physical Counts Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _auditTarget == 'packaged'
                          ? 'Tata Ace (TN 38 BX 4412) · Raja'
                          : (_auditTarget == 'tanker' ? 'Tanker (TN 34 AF 4954) · Suresh' : 'Aran Cafe Counter 1 · Barista'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        widget.isTamil ? 'கணினி இருப்பு' : 'System Manifest',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF1E293B)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.isTamil ? 'இருக்க வேண்டிய இருப்பு:' : 'Expected Units on Vehicle:', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    Text('$_expectedUnits Units', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.isTamil ? 'இருக்க வேண்டிய ரொக்கம்:' : 'Expected Driver Cash (₹):', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    Text('₹ ${_expectedCash.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF34D399))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Physical Observed Inputs
          Text(
            widget.isTamil ? 'நேரில் எண்ணப்பட்ட இருப்பு எண்ணிக்கை:' : 'Physical Units Counted by Supervisor:',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _unitsObservedController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            widget.isTamil ? 'ஓட்டுனரிடம் உள்ள நேரடி ரொக்கம் (Cash ₹):' : 'Physical Cash in Hand (₹):',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _cashObservedController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _runAudit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.isTamil ? 'தணிக்கை முடிவை சரிபார் (EVALUATE VARIANCE)' : 'EVALUATE VARIANCE',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Audit Results Card
          if (_auditDone)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isClean ? const Color(0xFF065F46) : const Color(0xFF7F1D1D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isClean ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isClean ? Icons.check_circle : Icons.warning_amber_rounded, color: isClean ? const Color(0xFF34D399) : const Color(0xFFFCA5A5), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isClean
                              ? (widget.isTamil ? 'தணிக்கை சரியானது (100% BALANCED)' : 'AUDIT PASSED: ZERO VARIANCE')
                              : (widget.isTamil ? 'எச்சரிக்கை: கணக்கில் வித்தியாசம் உள்ளது!' : 'ALERT: VARIANCE DETECTED! FRAUD SUSPECTED'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.isTamil ? 'இருப்பு வித்தியாசம்:' : 'Stock Unit Variance:', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        unitDiff == 0 ? '0 Units' : (unitDiff > 0 ? '+$unitDiff Surplus' : '$unitDiff Missing'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.isTamil ? 'ரொக்க வித்தியாசம்:' : 'Cash Variance:', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        cashDiff == 0 ? '₹ 0.00' : (cashDiff > 0 ? '+₹ ${cashDiff.toStringAsFixed(2)} Surplus' : '₹ ${cashDiff.toStringAsFixed(2)} Shortage'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTargetPill(String target, String label, Color color) {
    final isSelected = _auditTarget == target;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _auditTarget = target;
          _auditDone = false;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? color : const Color(0xFF334155)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}
