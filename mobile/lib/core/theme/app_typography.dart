import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Stitch "Ripple" Typography Scale using Manrope with Tabular Figures.
/// Strictly enforces min 12sp font size and crisp outdoor contrast.
abstract final class AppTypography {
  static const String fontSans = 'Manrope';
  static const String fontMono = 'JetBrains Mono';

  static TextTheme manropeTextTheme(TextTheme base) {
    return GoogleFonts.manropeTextTheme(base);
  }

  static const TextStyle display = TextStyle(
    fontFamily: fontSans,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 1.2,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontSans,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.35,
    height: 1.28,
  );

  static const TextStyle section = TextStyle(
    fontFamily: fontSans,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontSans,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontSans,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontSans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontSans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  /// Tabular font for currency totals, shift drawer counts, odometer readings, and quantities.
  static const TextStyle numberDisplay = TextStyle(
    fontFamily: fontSans,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.15,
  );

  static const TextStyle numberCard = TextStyle(
    fontFamily: fontSans,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.2,
  );

  static const TextStyle numberInline = TextStyle(
    fontFamily: fontSans,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.25,
  );
}
