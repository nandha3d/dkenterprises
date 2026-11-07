import 'package:flutter_test/flutter_test.dart';
import 'package:dk_track_mobile/core/utils/location_parser.dart';

void main() {
  group('LocationParser Tests', () {
    test('extracts coordinates from standard Google Maps URL', () {
      final coords = LocationParser.extractCoordinates('https://maps.google.com/?q=11.0845000,77.2941000');
      expect(coords, isNotNull);
      expect(coords!.latitude, 11.0845);
      expect(coords.longitude, 77.2941);
    });

    test('extracts coordinates from @lat,lng Google Maps URL', () {
      final coords = LocationParser.extractCoordinates('https://www.google.com/maps/@11.3324,77.7121,17z');
      expect(coords, isNotNull);
      expect(coords!.latitude, 11.3324);
      expect(coords.longitude, 77.7121);
    });

    test('extracts coordinates from WhatsApp shared text message', () {
      const text = 'Please deliver to this location: https://maps.google.com/?q=11.018221,76.964119 thank you';
      final coords = LocationParser.extractCoordinates(text);
      expect(coords, isNotNull);
      expect(coords!.latitude, 11.018221);
      expect(coords.longitude, 76.964119);
    });

    test('extracts coordinates from raw coordinates string', () {
      const text = 'Customer location: 11.0268, 76.9742';
      final coords = LocationParser.extractCoordinates(text);
      expect(coords, isNotNull);
      expect(coords!.latitude, 11.0268);
      expect(coords.longitude, 76.9742);
    });

    test('builds navigation URL correctly', () {
      final url = LocationParser.getNavigationUrl(11.0845, 77.2941);
      expect(url, 'https://www.google.com/maps/dir/?api=1&destination=11.0845,77.2941');
    });
  });
}
