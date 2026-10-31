import 'package:flutter/material.dart';

class TicketMachineScreen extends StatefulWidget {
  final bool isTamil;

  const TicketMachineScreen({super.key, required this.isTamil});

  @override
  State<TicketMachineScreen> createState() => _TicketMachineScreenState();
}

class _TicketMachineScreenState extends State<TicketMachineScreen> {
  String _selectedShop = 'அரண் கஃபே - 1 (Aran Cafe - 1)';
  int _deliveredCans = 14;
  int _emptyReturned = 14;
  final int _ratePerCan = 20;
  String _paymentMode = 'cash'; // 'cash', 'upi', 'credit'
  bool _showSuccessAlert = false;

  final List<String> _shops = [
    'அரண் கஃபே - 1 (Aran Cafe - 1)',
    'அரண் கஃபே - 2 (Aran Cafe - 2)',
    'பாலாஜி கஃபே (Balaji Cafe)',
    'ப்ளாக் பெக்கோ டீ (Black Pekoe Tea)',
    'ஒன் கப் டீ (One Cup Tea)',
    'சூர்யா டெக்ஸ் (Surya Tex - 1)',
    'சாந்தா கம்பெனி (Santha Company)',
  ];

  void _submitDelivery() {
    setState(() {
      _showSuccessAlert = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSuccessAlert = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _deliveredCans * _ratePerCan;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Stock Status Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 16, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 8),
                    Text(
                      widget.isTamil ? 'வண்டியில் உள்ள கேன்:' : 'Stock on Truck:',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const Text(
                  '25 Cans',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Success Notification Banner
          if (_showSuccessAlert)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF065F46),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.isTamil
                          ? 'டெலிவரி வெற்றிகரமாக பதிவானது! (GPS: 11.0182, 76.9641)'
                          : 'Delivery recorded with GPS fix (11.0182, 76.9641)',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // 1. Shop Selector Dropdown
          Text(
            widget.isTamil ? 'வாடிக்கையாளர் / கடை தேர்வு:' : 'Select Customer / Shop:',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedShop,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                items: _shops.map((shop) {
                  return DropdownMenuItem(
                    value: shop,
                    child: Text(shop, style: const TextStyle(fontSize: 14, color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedShop = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2. High-Speed Steppers: Cans Delivered & Empty Collected
          Row(
            children: [
              // Cans Delivered
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.isTamil ? 'லோடு கேன்' : 'Delivered Cans',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_deliveredCans',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_deliveredCans > 1) setState(() => _deliveredCans--);
                            },
                            icon: const Icon(Icons.remove_circle, color: Color(0xFFEF4444), size: 28),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _deliveredCans++),
                            icon: const Icon(Icons.add_circle, color: Color(0xFF10B981), size: 28),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Empty Returned
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.isTamil ? 'காலி கேன்' : 'Empty Returned',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_emptyReturned',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_emptyReturned > 0) setState(() => _emptyReturned--);
                            },
                            icon: const Icon(Icons.remove_circle, color: Color(0xFFEF4444), size: 28),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _emptyReturned++),
                            icon: const Icon(Icons.add_circle, color: Color(0xFF10B981), size: 28),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3. Payment Mode Buttons (Large touch targets)
          Text(
            widget.isTamil ? 'பணம் வசூல் முறை:' : 'Payment Mode:',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _paymentMode = 'cash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _paymentMode == 'cash' ? const Color(0xFF059669) : const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    widget.isTamil ? 'பணம் (Cash)' : 'Cash',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _paymentMode = 'upi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _paymentMode == 'upi' ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    widget.isTamil ? 'ஜிபே (UPI)' : 'UPI',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _paymentMode = 'credit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _paymentMode == 'credit' ? const Color(0xFFD97706) : const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    widget.isTamil ? 'கடன் (Credit)' : 'Credit',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Total Calculation Pill
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isTamil ? 'மொத்த தொகை (Total):' : 'Total Billing Amount:',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                ),
                Text(
                  '₹$totalAmount',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Giant Submit Button (<15s completion)
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _submitDelivery,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check, size: 24, color: Colors.white),
              label: Text(
                widget.isTamil ? 'டெலிவரி உறுதிசெய் (<15s)' : 'CONFIRM DELIVERY (<15s)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
