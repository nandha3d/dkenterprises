import 'package:flutter/material.dart';

/// Centralized Industrial Design Colors for Zolo ERP Mobile.
/// Follows strict WCAG 2.1 AA / AAA contrast (>4.5:1 / >7:1 for field use).
abstract final class AppColors {
  // Brand & Action
  static const Color primary = Color(0xFF0369A1); // Deep Ocean Blue
  static const Color primaryDark = Color(0xFF38BDF8); // Sky Blue for dark canvas
  static const Color brandNavy = Color(0xFF021840);
  static const Color brandPurple = Color(0xFF7D287E);

  // Semantics
  static const Color success = Color(0xFF059669); // Emerald
  static const Color successDark = Color(0xFF10B981);
  static const Color danger = Color(0xFFDC2626); // Ruby
  static const Color dangerDark = Color(0xFFEF4444);
  static const Color warning = Color(0xFFD97706); // Amber
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0284C7);

  // Light Surfaces
  static const Color lightCanvas = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightDivider = Color(0xFFCBD5E1);

  // Dark Surfaces
  static const Color darkCanvas = Color(0xFF0B0F17);
  static const Color darkCard = Color(0xFF111827);
  static const Color darkBorder = Color(0xFF1F2937);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkDivider = Color(0xFF374151);

  // Chip backgrounds
  static const Color chipSuccessBgLight = Color(0xFFECFDF5);
  static const Color chipDangerBgLight = Color(0xFFFEF2F2);
  static const Color chipWarningBgLight = Color(0xFFFFFBEB);
  static const Color chipInfoBgLight = Color(0xFFF0F9FF);

  static const Color chipSuccessBgDark = Color(0xFF064E3B);
  static const Color chipDangerBgDark = Color(0xFF7F1D1D);
  static const Color chipWarningBgDark = Color(0xFF78350F);
  static const Color chipInfoBgDark = Color(0xFF082F49);
}

