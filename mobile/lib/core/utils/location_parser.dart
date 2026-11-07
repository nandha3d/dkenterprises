import 'package:url_launcher/url_launcher.dart';

class LocationCoordinates {
  final double latitude;
  final double longitude;

  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => '$latitude, $longitude';
}

class LocationParser {
  /// Extracts latitude and longitude from raw text, WhatsApp share text, or Google Maps URLs.
  static LocationCoordinates? extractCoordinates(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final text = Uri.decodeFull(input.trim());

    // Pattern 1: URL with q=lat,lng or query=lat,lng or loc:lat,lng
    final queryRegex = RegExp(
      r'(?:[?&](?:q|query|loc)=|loc:)\s*(-?\d{1,2}(?:\.\d+)?)\s*,\s*(-?\d{1,3}(?:\.\d+)?)',
      caseSensitive: false,
    );
    final match1 = queryRegex.firstMatch(text);
    if (match1 != null) {
      final lat = double.tryParse(match1.group(1)!);
      final lng = double.tryParse(match1.group(2)!);
      if (lat != null && lng != null) {
        return LocationCoordinates(latitude: lat, longitude: lng);
      }
    }

    // Pattern 2: Google Maps @lat,lng,zoom or /place/lat,lng
    final placeRegex = RegExp(
      r'(?:@|place\/)\s*(-?\d{1,2}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)',
      caseSensitive: false,
    );
    final match2 = placeRegex.firstMatch(text);
    if (match2 != null) {
      final lat = double.tryParse(match2.group(1)!);
      final lng = double.tryParse(match2.group(2)!);
      if (lat != null && lng != null) {
        return LocationCoordinates(latitude: lat, longitude: lng);
      }
    }

    // Pattern 3: Raw coordinates "11.0845, 77.2941" or "11.0845 77.2941"
    final rawRegex = RegExp(
      r'(-?\d{1,2}\.\d{3,})\s*(?:,|\s+)\s*(-?\d{1,3}\.\d{3,})',
    );
    final match3 = rawRegex.firstMatch(text);
    if (match3 != null) {
      final lat = double.tryParse(match3.group(1)!);
      final lng = double.tryParse(match3.group(2)!);
      if (lat != null && lng != null) {
        return LocationCoordinates(latitude: lat, longitude: lng);
      }
    }

    return null;
  }

  /// Builds Google Maps Turn-by-Turn navigation URL
  static String getNavigationUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
  }

  /// Launches Google Maps Navigation in native app or external browser
  static Future<bool> launchNavigation(double latitude, double longitude) async {
    final urlString = getNavigationUrl(latitude, longitude);
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
