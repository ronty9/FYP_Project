// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';

class AppColors {
  static const Color skyMist = Color.fromARGB(255, 255, 255, 255);
  static const Color arctic = Color(0xFFCCE7FF);
  static const Color aqua = Color(0xFF59B6F3);
  static const Color cobalt = Color(0xFF2F6FD6);
  static const Color deepSea = Color(0xFF0D2B8F);
  static const Color midnight = Color(0xFF020A52);
  static const Color pageBackground = Color(0xFFF8F9FD);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.aqua,
      brightness: Brightness.light,
      surface: AppColors.skyMist,
    );

    final colorScheme = baseScheme.copyWith(
      primary: AppColors.cobalt,
      onPrimary: Colors.white,
      primaryContainer: AppColors.deepSea,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.aqua,
      onSecondary: AppColors.midnight,
      secondaryContainer: AppColors.arctic,
      onSecondaryContainer: AppColors.midnight,
      tertiary: AppColors.deepSea,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.cobalt,
      onTertiaryContainer: Colors.white,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: AppColors.skyMist,
      onSurface: AppColors.midnight,
      surfaceTint: AppColors.aqua,
      outline: const Color(0xFF7EA9D8),
      outlineVariant: const Color(0xFFBCD7F2),
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: AppColors.midnight,
      onInverseSurface: AppColors.arctic,
      inversePrimary: AppColors.aqua,
    );

    final baseTextTheme = Typography.blackMountainView.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.pageBackground,
      canvasColor: AppColors.pageBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.pageBackground,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: baseTextTheme,
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.secondaryContainer,
        labelStyle: baseTextTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.4),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
