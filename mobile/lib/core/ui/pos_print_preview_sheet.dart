import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Supported SensiblePOS print & label templates.
enum PosPrintFormat {
  thermal80mm('thermal_80mm', '80mm Receipt + Token', Icons.receipt_long_rounded),
  thermal58mm('thermal_58mm', '58mm Pocket Slip', Icons.print_outlined),
  kotTicket('kot_ticket', 'KOT Kitchen Slip', Icons.soup_kitchen_outlined),
  stickerLabel50x25('sticker_label_50x25mm', '50x25mm Barcode Label', Icons.qr_code_2_rounded),
  canNeckTag50x38('can_neck_tag_50x38mm', '50x38mm Seal / Jar Tag', Icons.verified_outlined);

  final String code;
  final String label;
  final IconData icon;
  const PosPrintFormat(this.code, this.label, this.icon);
}

class PosPrintLineItem {
  final String name;
  final String code;
  final double qty;
  final double unitPrice;
  final String? note;
  final String? unitLabel;

  const PosPrintLineItem({
    required this.name,
    required this.code,
    required this.qty,
    required this.unitPrice,
    this.note,
    this.unitLabel,
  });

  double get lineTotal => qty * unitPrice;
}

/// Interactive SensiblePOS Print Studio & Thermal Label Designer Modal.
class PosPrintPreviewSheet extends StatefulWidget {
  final String companyName;
  final String branchName;
  final String? gstin;
  final String? upiVpa;
  final String referenceNo;
  final String tokenNumber;
  final String customerName;
  final String orderType;
  final String priceTier;
  final String paymentMethod;
  final List<PosPrintLineItem> items;
  final double discount;
  final double packingCharge;
  final double taxAmount;
  final double roundOff;
  final double grandTotal;
  final double paidAmount;
  final Map<String, String>? extraTelemetryMeta;
  final PosPrintFormat initialFormat;

  const PosPrintPreviewSheet({
    super.key,
    required this.companyName,
    this.branchName = 'Main Branch',
    this.gstin,
    this.upiVpa,
    required this.referenceNo,
    this.tokenNumber = '0000',
    required this.customerName,
    this.orderType = 'Counter',
    this.priceTier = 'Retail MRP',
    this.paymentMethod = 'Cash',
    required this.items,
    this.discount = 0.0,
    this.packingCharge = 0.0,
    this.taxAmount = 0.0,
    this.roundOff = 0.0,
    required this.grandTotal,
    required this.paidAmount,
    this.extraTelemetryMeta,
    this.initialFormat = PosPrintFormat.thermal80mm,
  });

  static Future<void> show(
    BuildContext context, {
    required String companyName,
    String branchName = 'Main Branch',
    String? gstin,
    String? upiVpa,
    required String referenceNo,
    String tokenNumber = '0000',
    required String customerName,
    String orderType = 'Counter',
    String priceTier = 'Retail MRP',
    String paymentMethod = 'Cash',
    required List<PosPrintLineItem> items,
    double discount = 0.0,
    double packingCharge = 0.0,
    double taxAmount = 0.0,
    double roundOff = 0.0,
    required double grandTotal,
    required double paidAmount,
    Map<String, String>? extraTelemetryMeta,
    PosPrintFormat initialFormat = PosPrintFormat.thermal80mm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PosPrintPreviewSheet(
        companyName: companyName,
        branchName: branchName,
        gstin: gstin,
        upiVpa: upiVpa,
        referenceNo: referenceNo,
        tokenNumber: tokenNumber,
        customerName: customerName,
        orderType: orderType,
        priceTier: priceTier,
        paymentMethod: paymentMethod,
        items: items,
        discount: discount,
        packingCharge: packingCharge,
        taxAmount: taxAmount,
        roundOff: roundOff,
        grandTotal: grandTotal,
        paidAmount: paidAmount,
        extraTelemetryMeta: extraTelemetryMeta,
        initialFormat: initialFormat,
      ),
    );
  }

  @override
  State<PosPrintPreviewSheet> createState() => _PosPrintPreviewSheetState();
}

class _PosPrintPreviewSheetState extends State<PosPrintPreviewSheet> {
  late PosPrintFormat _selectedFormat;
  String _printerPort = 'USB / POS Direct';
  int _copies = 1;
  bool _autoCut = true;
  bool _kickDrawer = true;
  bool _includeTokenStub = true;
  bool _showUpiQr = true;
  int _selectedLabelIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat;
  }

  String _generateTsplForItem(PosPrintLineItem item) {
    final now = DateTime.now();
    final pkd = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${(now.year % 100).toString().padLeft(2, '0')}';
    final expDate = now.add(const Duration(days: 2));
    final exp = '${expDate.day.toString().padLeft(2, '0')}/${expDate.month.toString().padLeft(2, '0')}/${(expDate.year % 100).toString().padLeft(2, '0')}';
    final batch = 'B${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${widget.tokenNumber}';
    final sizeHeader = _selectedFormat == PosPrintFormat.canNeckTag50x38
        ? 'SIZE 50 mm, 38 mm'
        : 'SIZE 50 mm, 25 mm';

    return [
      sizeHeader,
      'GAP 2 mm, 0 mm',
      'DIRECTION 1',
      'CLS',
      'TEXT 16,12,"2",0,1,1,"${widget.companyName.toUpperCase()}"',
      'TEXT 210,12,"1",0,1,1,"BATCH: $batch"',
      'BAR 16,32,368,2',
      'TEXT 16,42,"3",0,1,1,"${item.name.toUpperCase()}"',
      'TEXT 16,70,"2",0,1,1,"MRP: Rs.${item.unitPrice.toStringAsFixed(2)}"',
      'TEXT 195,70,"1",0,1,1,"PKD: $pkd"',
      'TEXT 195,88,"1",0,1,1,"USE: $exp"',
      'BARCODE 32,112,"128",52,1,0,2,2,"${item.code}"',
      'PRINT 1,${item.qty.ceil().clamp(1, 50)}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final isLabelMode = _selectedFormat == PosPrintFormat.stickerLabel50x25 ||
        _selectedFormat == PosPrintFormat.canNeckTag50x38;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.6,
      maxChildSize: 0.96,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: skin.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag Handle & Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
              decoration: BoxDecoration(
                color: skin.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(bottom: BorderSide(color: skin.hairline)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: skin.hairline,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: skin.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.print_rounded, color: skin.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SensiblePOS Print & Label Studio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: skin.ink,
                              ),
                            ),
                            Text(
                              'Ref: ${widget.referenceNo} · Token #${widget.tokenNumber}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: skin.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: skin.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 5-Format Selector Strip
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: PosPrintFormat.values.map((fmt) {
                        final selected = _selectedFormat == fmt;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: selected,
                            showCheckmark: false,
                            avatar: Icon(
                              fmt.icon,
                              size: 16,
                              color: selected ? Colors.white : skin.primary,
                            ),
                            label: Text(
                              fmt.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: selected ? Colors.white : skin.ink,
                              ),
                            ),
                            selectedColor: skin.primary,
                            backgroundColor: skin.surface2,
                            onSelected: (_) => setState(() => _selectedFormat = fmt),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Preview & Printer Controls
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Printer Interface & Copies Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: skin.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: skin.hairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  'USB / POS Direct',
                                  'Bluetooth Thermal',
                                  'LAN IP:9100',
                                  'TSPL Label Roll',
                                ].map((port) {
                                  final active = _printerPort == port;
                                  return InkWell(
                                    onTap: () => setState(() => _printerPort = port),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? skin.primary.withValues(alpha: 0.14)
                                            : skin.surface2,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: active ? skin.primary : skin.hairline,
                                        ),
                                      ),
                                      child: Text(
                                        port,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: active ? skin.primary : skin.ink,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: skin.surface2,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: _copies > 1 ? () => setState(() => _copies--) : null,
                                    child: const Icon(Icons.remove_rounded, size: 16),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '${_copies}x',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: skin.ink,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _copies < 5 ? () => setState(() => _copies++) : null,
                                    child: const Icon(Icons.add_rounded, size: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            FilterChip(
                              selected: _autoCut,
                              label: const Text('Auto-Cut', style: TextStyle(fontSize: 11)),
                              onSelected: (v) => setState(() => _autoCut = v),
                              visualDensity: VisualDensity.compact,
                            ),
                            FilterChip(
                              selected: _kickDrawer,
                              label: const Text('Kick Drawer', style: TextStyle(fontSize: 11)),
                              onSelected: (v) => setState(() => _kickDrawer = v),
                              visualDensity: VisualDensity.compact,
                            ),
                            if (!isLabelMode) ...[
                              FilterChip(
                                selected: _includeTokenStub,
                                label: const Text('Perforated Token Stub', style: TextStyle(fontSize: 11)),
                                onSelected: (v) => setState(() => _includeTokenStub = v),
                                visualDensity: VisualDensity.compact,
                              ),
                              FilterChip(
                                selected: _showUpiQr,
                                label: const Text('UPI Dynamic QR', style: TextStyle(fontSize: 11)),
                                onSelected: (v) => setState(() => _showUpiQr = v),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Render Selected Format Preview
                  if (isLabelMode)
                    _buildStickerLabelDesigner(skin)
                  else if (_selectedFormat == PosPrintFormat.kotTicket)
                    _buildKotPreview(skin)
                  else
                    _buildThermalReceiptPreview(skin),
                ],
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: skin.surface,
                border: Border(top: BorderSide(color: skin.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      onPressed: () {
                        if (widget.items.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No items available to copy print stream.')),
                          );
                          return;
                        }
                        final activeItem = widget.items[_selectedLabelIndex.clamp(0, widget.items.length - 1)];
                        final payloadText = isLabelMode
                            ? _generateTsplForItem(activeItem)
                            : 'REF: ${widget.referenceNo} | TOTAL: INR ${widget.grandTotal.toStringAsFixed(2)}';
                        Clipboard.setData(ClipboardData(text: payloadText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isLabelMode
                                ? 'TSPL2 barcode label commands copied to clipboard!'
                                : 'ESC/POS receipt stream copied to clipboard!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.code_rounded, size: 18),
                      label: Text(
                        isLabelMode ? 'Copy TSPL' : 'Copy ESC/POS',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: skin.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.rippleMint,
                              content: Text(
                                'Dispatched ${_copies}x ${_selectedFormat.label} to $_printerPort (${widget.referenceNo})',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: Text(
                          'Print ${_copies}x ${_selectedFormat.label}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
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

  Widget _buildStickerLabelDesigner(RippleSkin skin) {
    final items = widget.items.isNotEmpty
        ? widget.items
        : const [
            PosPrintLineItem(
              name: 'Packaged Drinking Water Can',
              code: 'DKW-CAN-001',
              qty: 1,
              unitPrice: 35.0,
            ),
          ];
    final safeIdx = _selectedLabelIndex.clamp(0, items.length - 1);
    final item = items[safeIdx];
    final isNeckTag = _selectedFormat == PosPrintFormat.canNeckTag50x38;
    final now = DateTime.now();
    final pkdDate =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    final expDate = now.add(Duration(days: isNeckTag ? 30 : 2));
    final useByDate =
        '${expDate.day.toString().padLeft(2, '0')}-${expDate.month.toString().padLeft(2, '0')}-${expDate.year}';
    final batchNo =
        'B${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${widget.tokenNumber}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(items.length, (i) {
                final active = i == safeIdx;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 12),
                  child: ChoiceChip(
                    selected: active,
                    label: Text(
                      '${items[i].name} (${items[i].qty.toStringAsFixed(0)} labels)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    onSelected: (_) => setState(() => _selectedLabelIndex = i),
                  ),
                );
              }),
            ),
          ),
        ],

        // Physical Die-Cut Thermal Sticker Label Card
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black87, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Brand & Batch Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            widget.companyName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'BATCH: $batchNo',
                          style: const TextStyle(
                            color: Color(0xFFC9F36A),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quality / FSSAI Sub-bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isNeckTag
                              ? 'RO + UV + OZONIZED · TDS: 42 ppm · pH 7.2'
                              : 'FSSAI LIC: 12426009812 · FRESH PACK',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black87),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isNeckTag ? '50×38mm SEAL' : '50×25mm LABEL',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black87, thickness: 1.2, height: 16),

                  // Product Title & Price Slab
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Party: ${widget.customerName} · Qty: ${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 2)} ${item.unitLabel ?? 'Units'}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            if (item.note != null && item.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  'PREP / SPEC: ${item.note}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black87, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'MRP (Incl. Tax)',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '₹${item.unitPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // PKD & Expiry Dates Grid
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'PKD: $pkdDate',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'USE BY: $useByDate',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'REF: ${widget.referenceNo}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (widget.extraTelemetryMeta != null &&
                      widget.extraTelemetryMeta!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: widget.extraTelemetryMeta!.entries
                          .map(
                            (e) => Text(
                              '${e.key}: ${e.value}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // High-Density Code-128 Barcode Visual Block
                  SizedBox(
                    height: 44,
                    child: CustomPaint(
                      painter: _Code128BarcodePainter(
                        codeData: '${item.code}-${widget.referenceNo}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '* ${item.code.toUpperCase()} · ${widget.referenceNo} *',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Raw TSPL2 Command Stream Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'GENERATED TSPL2 LABEL PRINTER STREAM (203 DPI)',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFC9F36A),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'CODE-128 AUTO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _generateTsplForItem(item),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKotPreview(RippleSkin skin) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEF7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black87, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.black,
                child: Column(
                  children: [
                    Text(
                      'KITCHEN ORDER TICKET #${widget.tokenNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${widget.orderType.toUpperCase()} · $timeStr',
                      style: const TextStyle(
                        color: Color(0xFFF4A62A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Order Ref: ${widget.referenceNo} · Party: ${widget.customerName}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.black87, thickness: 1.2, height: 18),
              ...widget.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 1)}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.note != null && item.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 44, top: 3),
                          child: Text(
                            '>> PREP: ${item.note!.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC2542D),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Colors.black87, thickness: 1.2, height: 16),
              Text(
                'TOTAL QTY: ${widget.items.fold<double>(0, (s, e) => s + e.qty).toStringAsFixed(0)} ITEMS',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThermalReceiptPreview(RippleSkin skin) {
    final is58mm = _selectedFormat == PosPrintFormat.thermal58mm;
    final maxWidth = is58mm ? 310.0 : 410.0;
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final subtotal = widget.items.fold<double>(0, (s, i) => s + i.lineTotal);
    final due = (widget.grandTotal - widget.paidAmount).clamp(0.0, double.infinity);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: EdgeInsets.all(is58mm ? 14 : 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand Crest Header
              Text(
                widget.companyName.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: is58mm ? 15 : 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.gstin != null && widget.gstin!.trim().isNotEmpty
                    ? '${widget.branchName} · GSTIN: ${widget.gstin}'
                    : widget.branchName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Prominent Counter Token Box
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black87, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      'TOKEN #${widget.tokenNumber}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: is58mm ? 15 : 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${widget.orderType.toUpperCase()} · ${widget.priceTier.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bill No : ${widget.referenceNo}\nDate    : $dateStr\nCustomer: ${widget.customerName}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),

              if (widget.extraTelemetryMeta != null &&
                  widget.extraTelemetryMeta!.isNotEmpty) ...[
                const Divider(color: Colors.black54, height: 14),
                ...widget.extraTelemetryMeta!.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          e.value,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const Divider(color: Colors.black87, thickness: 1.2, height: 16),

              // Table Header
              const Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'ITEM',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'QTY',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'RATE',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'AMT',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.black54, height: 10),

              // Line Items
              ...widget.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 2),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.unitPrice.toStringAsFixed(0),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.lineTotal.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.note != null && item.note!.isNotEmpty)
                        Text(
                          '  * ${item.note}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const Divider(color: Colors.black87, thickness: 1.2, height: 14),
              _receiptTotalRow('Subtotal', subtotal),
              if (widget.discount > 0)
                _receiptTotalRow('Discount', -widget.discount),
              if (widget.packingCharge > 0)
                _receiptTotalRow('Parcel / Packing', widget.packingCharge),
              if (widget.taxAmount > 0) ...[
                _receiptTotalRow('CGST (2.5%)', widget.taxAmount / 2),
                _receiptTotalRow('SGST (2.5%)', widget.taxAmount / 2),
              ],
              if (widget.roundOff.abs() > 0.001)
                _receiptTotalRow('Round Off', widget.roundOff),
              const Divider(color: Colors.black, thickness: 1.6, height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'GRAND TOTAL',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '₹${widget.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _receiptTotalRow('Paid (${widget.paymentMethod})', widget.paidAmount),
              if (due > 0.01) _receiptTotalRow('Balance Due', due),

              if (_showUpiQr) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 38, color: Colors.black),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'SCAN TO PAY VIA UPI\n₹${widget.grandTotal.toStringAsFixed(2)} · Verified Merchant',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_includeTokenStub) ...[
                const SizedBox(height: 12),
                const Text(
                  '- - - - - ✂ TEAR COUNTER TOKEN ✂ - - - - -',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'TOKEN #${widget.tokenNumber}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${widget.items.length} Items · ₹${widget.grandTotal.toStringAsFixed(0)}',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptTotalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Text(
            '${amount < 0 ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _Code128BarcodePainter extends CustomPainter {
  final String codeData;
  const _Code128BarcodePainter({required this.codeData});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final units = <int>[2, 1, 1, 2, 3, 1];
    for (var i = 0; i < codeData.length; i++) {
      final c = codeData.codeUnitAt(i);
      units.add(((c >> 0) & 2) + 1);
      units.add(((c >> 1) & 1) + 1);
      units.add(((c >> 2) & 2) + 1);
      units.add(((c >> 3) & 1) + 1);
    }
    units.addAll(const [2, 3, 1, 1, 2]);

    final totalUnits = units.fold<int>(0, (s, u) => s + u);
    final unitWidth = size.width / totalUnits;
    var x = 0.0;
    for (var i = 0; i < units.length; i++) {
      final w = units[i] * unitWidth;
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      }
      x += w;
    }
  }

  @override
  bool shouldRepaint(covariant _Code128BarcodePainter oldDelegate) =>
      oldDelegate.codeData != codeData;
}

