import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF3CB91A); // Logo Green
  static const Color primaryDark = Color(0xFF2E8F13); // Darker Green
  static const Color primaryLight = Color(0xFF6DD24C); // Lighter Green
  static const Color secondaryColor = Color(0xFF3D3D3D); // Logo Dark Charcoal
  static const Color secondaryLight = Color(0xFF6B6B6B); // Lighter Charcoal
  static const Color backgroundColor = Color(0xFFF8FAFC); // Soft Off-White
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFDC2626);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  static const Color maleColor = Color(0xFF2563EB);
  static const Color femaleColor = Color(0xFFDB2777);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light( // ignore: prefer_const_constructors
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: secondaryColor,
        secondaryContainer: secondaryLight,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
        labelStyle: const TextStyle(color: secondaryColor),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: secondaryColor),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
      ),
    );
  }
}
