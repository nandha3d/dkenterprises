import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Primitives from Web App (zolo-tokens.css)
  static const Color brandPurple = Color(0xFF7D287E); // --zp-700
  static const Color brandNavy = Color(0xFF021840);   // --zn-900
  static const Color brandDeepNavy = Color(0xFF010F2A); // --zn-950
  static const Color brandSky = Color(0xFF0EA5E9);
  static const Color brandCyan = Color(0xFF38BDF8);
  static const Color brandEmerald = Color(0xFF10B981);
  static const Color brandAmber = Color(0xFFF59E0B);
  static const Color brandDanger = Color(0xFFEF4444);

  // Role Color Accents
  static const Color roleSuperAdmin = Color(0xFF8B5CF6);
  static const Color roleAdmin = Color(0xFF0EA5E9);
  static const Color roleFieldAgent = Color(0xFF10B981);
  static const Color roleDeliveryDriver = Color(0xFF0284C7);
  static const Color roleTankerDriver = Color(0xFF2563EB);
  static const Color roleCashier = Color(0xFFD97706);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color scaffold(BuildContext context) {
    return isDark(context) ? const Color(0xFF060A14) : const Color(0xFFF8FAFC);
  }

  static Color card(BuildContext context) {
    return isDark(context) ? const Color(0xFF101726) : Colors.white;
  }

  static Color cardSubtle(BuildContext context) {
    return isDark(context) ? const Color(0xFF162032) : const Color(0xFFF1F5F9);
  }

  static Color border(BuildContext context) {
    return isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  }

  static Color borderFocus(BuildContext context) {
    return isDark(context) ? const Color(0xFF38BDF8) : brandPurple;
  }

  static Color text(BuildContext context) {
    return isDark(context) ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  }

  static Color textMuted(BuildContext context) {
    return isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  }

  static Color textDim(BuildContext context) {
    return isDark(context) ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  }

  static Color inputFill(BuildContext context) {
    return isDark(context) ? const Color(0x1AFFFFFF) : const Color(0xFFF1F5F9);
  }

  static Color appBarBg(BuildContext context) {
    return isDark(context) ? const Color(0xFF0B0F17).withOpacity(0.85) : Colors.white.withOpacity(0.92);
  }

  static Color bottomNavBg(BuildContext context) {
    return isDark(context) ? const Color(0xFF0B0F17).withOpacity(0.90) : Colors.white.withOpacity(0.92);
  }
}

class AppTheme {
  static ThemeData getDarkTheme(Color primaryColor) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF060A14),
      cardColor: const Color(0xFF101726),
      dividerColor: const Color(0xFF1E293B),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0B0F17),
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFF64748B),
      ),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: const Color(0xFF10B981),
        surface: const Color(0xFF101726),
        error: const Color(0xFFEF4444),
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(ThemeData.dark().primaryTextTheme),
    );
  }

  static ThemeData getLightTheme(Color primaryColor) {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE2E8F0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFF64748B),
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: const Color(0xFF059669),
        surface: Colors.white,
        error: const Color(0xFFDC2626),
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(ThemeData.light().primaryTextTheme),
    );
  }
}
