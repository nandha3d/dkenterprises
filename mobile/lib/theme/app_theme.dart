import 'package:flutter/material.dart';

class AppColors {
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color scaffold(BuildContext context) {
    return isDark(context) ? const Color(0xFF0B0F17) : const Color(0xFFF8FAFC);
  }

  static Color card(BuildContext context) {
    return isDark(context) ? const Color(0xFF111827) : Colors.white;
  }

  static Color cardSubtle(BuildContext context) {
    return isDark(context) ? const Color(0xFF162032) : const Color(0xFFF1F5F9);
  }

  static Color border(BuildContext context) {
    return isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  }

  static Color borderFocus(BuildContext context) {
    return isDark(context) ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
  }

  static Color text(BuildContext context) {
    return isDark(context) ? Colors.white : const Color(0xFF0F172A);
  }

  static Color textMuted(BuildContext context) {
    return isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  }

  static Color textDim(BuildContext context) {
    return isDark(context) ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  }

  static Color inputFill(BuildContext context) {
    return isDark(context) ? const Color(0xFF0B0F17) : const Color(0xFFF8FAFC);
  }

  static Color appBarBg(BuildContext context) {
    return isDark(context) ? const Color(0xFF0F172A) : Colors.white;
  }

  static Color bottomNavBg(BuildContext context) {
    return isDark(context) ? const Color(0xFF0F172A) : Colors.white;
  }
}

class AppTheme {
  static ThemeData getDarkTheme(Color primaryColor) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0F17),
      cardColor: const Color(0xFF111827),
      dividerColor: const Color(0xFF1E293B),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFF64748B),
      ),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: const Color(0xFF10B981),
        surface: const Color(0xFF111827),
        error: const Color(0xFFEF4444),
      ),
      fontFamily: 'Roboto',
    );
  }

  static ThemeData getLightTheme(Color primaryColor) {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE2E8F0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0.5,
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
      fontFamily: 'Roboto',
    );
  }
}
