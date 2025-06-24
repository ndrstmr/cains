// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define the color palette
class AppColors {
  static const Color primary = Color(0xFF4CAF50); // Green 500
  static const Color secondary = Color(0xFFFFC107); // Amber 500
  static const Color tertiary = Color(0xFF2196F3); // Blue 500

  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color backgroundLight = Color(0xFFFFFFFF);

  static const Color surfaceDark = Color(0xFF212121);
  static const Color backgroundDark = Color(0xFF121212);

  static const Color error = Color(0xFFF44336); // Red 500

  // Add other colors as needed, e.g., onPrimary, onSecondary, etc.
  // For simplicity, Material 3'sColorScheme.fromSeed will generate these if not specified.
}

/// Provides the current theme mode (light/dark).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Contains the application's theme configurations.
class AppTheme {
  static ThemeData get lightTheme {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      error: AppColors.error,
      brightness: Brightness.light,
      // Avoid direct 'surface' and 'background' here if they cause issues with seed generation logic for M3
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: baseColorScheme.copyWith(
        // Override specific derived colors if necessary.
        // For Material 3, 'surface' and 'background' are often nuanced.
        // Let's use the defined surfaceLight for surface.
        surface: AppColors.surfaceLight, // The main "card" color
        // 'background' parameter removed from copyWith to avoid deprecation warning
      ),
      scaffoldBackgroundColor:
          AppColors.backgroundLight, // Explicitly set overall background
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      // Add other theme properties as needed
      // e.g., appBarTheme, buttonTheme, etc.
    );
  }

  static ThemeData get darkTheme {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary, // Or a different seed for dark if desired
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      error: AppColors.error,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: baseColorScheme.copyWith(
        surface: AppColors
            .surfaceDark, // Use defined surfaceDark for component surfaces
        // 'background' parameter removed from copyWith to avoid deprecation warning
      ),
      scaffoldBackgroundColor:
          AppColors.backgroundDark, // Explicitly set overall background
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      // Add other theme properties as needed
    );
  }
}
