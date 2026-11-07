import 'package:flutter_test/flutter_test.dart';
import 'package:dk_track_mobile/core/ui/amount_text.dart';

void main() {
  group('Indian Currency Amount Formatting', () {
    test('formats whole numbers with rupee symbol and Indian grouping', () {
      final formatted = AmountText.format(148500);
      expect(formatted, contains('1,48,500.00'));
      expect(formatted, contains('₹'));
    });

    test('formats decimal numbers with paise accurately', () {
      final formatted = AmountText.format(48250.75);
      expect(formatted, contains('48,250.75'));
    });

    test('formats zero properly', () {
      final formatted = AmountText.format(0);
      expect(formatted, contains('0.00'));
    });

    test('formats positive numbers with optional sign', () {
      final formatted = AmountText.format(500, showSign: true);
      expect(formatted.startsWith('+'), isTrue);
    });
  });
}

