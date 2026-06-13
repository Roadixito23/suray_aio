import 'package:flutter/material.dart';

abstract final class AppColors {
  // Burdeo (Burgundy) – Primary: acciones principales, FAB, botones
  static const Color burdeo = Color(0xFF6D1427);
  static const Color burdeoLight = Color(0xFFB24C63);
  static const Color burdeoContainer = Color(0xFFFFDADB);
  static const Color onBurdeoContainer = Color(0xFF40030D);

  // Azul Marino (Navy Blue) – Secondary: AppBar, estructura, navegación
  static const Color azulMarino = Color(0xFF1A3A6B);
  static const Color azulMarinoLight = Color(0xFF4560A0);
  static const Color azulMarinoContainer = Color(0xFFD5E3FF);
  static const Color onAzulMarinoContainer = Color(0xFF001A45);

  // Hunter Green – Tertiary: valores positivos, stock, totales
  static const Color hunterGreen = Color(0xFF355E3B);
  static const Color hunterGreenLight = Color(0xFF5C8764);
  static const Color hunterGreenContainer = Color(0xFFB6F2BE);
  static const Color onHunterGreenContainer = Color(0xFF002108);
}

abstract final class AppTheme {
  static ThemeData get theme {
    const cs = ColorScheme(
      brightness: Brightness.light,
      // Primary: Burdeo
      primary: AppColors.burdeo,
      onPrimary: Colors.white,
      primaryContainer: AppColors.burdeoContainer,
      onPrimaryContainer: AppColors.onBurdeoContainer,
      // Secondary: Azul Marino
      secondary: AppColors.azulMarino,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.azulMarinoContainer,
      onSecondaryContainer: AppColors.onAzulMarinoContainer,
      // Tertiary: Hunter Green
      tertiary: AppColors.hunterGreen,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.hunterGreenContainer,
      onTertiaryContainer: AppColors.onHunterGreenContainer,
      // Error
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      // Surfaces (tono neutro cálido)
      surface: Color(0xFFFFF8F7),
      onSurface: Color(0xFF201A1B),
      surfaceContainerHighest: Color(0xFFEDE0E1),
      surfaceContainerHigh: Color(0xFFF4E8E8),
      surfaceContainer: Color(0xFFF5EEED),
      surfaceContainerLow: Color(0xFFFCF3F3),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFF534346),
      outline: Color(0xFF857376),
      outlineVariant: Color(0xFFD8C2C4),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF352F30),
      onInverseSurface: Color(0xFFFBEEEE),
      inversePrimary: AppColors.burdeoLight,
    );

    return ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.azulMarino,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.burdeo,
        foregroundColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.burdeo,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Color(0x4D6D1427),
          disabledForegroundColor: Colors.white54,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.burdeo,
          side: const BorderSide(color: AppColors.burdeo),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.burdeo),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xBBFFFFFF),
        indicatorColor: Colors.white,
        dividerColor: Colors.transparent,
      ),
      chipTheme: const ChipThemeData(
        selectedColor: AppColors.burdeoContainer,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.burdeo,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.burdeo : null,
        ),
      ),
    );
  }
}
