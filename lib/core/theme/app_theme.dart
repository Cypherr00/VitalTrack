import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme( // Removed const here
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0.0, // Changed to 0.0
      ),
      cardTheme: CardThemeData(
        color: Colors.white, // No longer errors
        elevation: 3.0,      // Changed to 3.0
        shadowColor: AppColors.accent.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Added .0 just in case
        ),
      ),
    );
  }
}