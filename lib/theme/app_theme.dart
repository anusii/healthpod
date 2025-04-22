/// Theme configuration for the application.
//
// Time-stamp: <Friday 2025-02-21 08:30:05 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Defines the theme configuration for the application.
/// Provides both light and dark theme variants.

class AppTheme {
  /// Light theme configuration.

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.iconDefault,
        secondary: AppColors.secondary,
        onSecondary: AppColors.iconDefault,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.cardBorder,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.25,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          letterSpacing: 0.15,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          letterSpacing: 0.25,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
      iconTheme: IconThemeData(
        color: AppColors.navUnselected,
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.primary,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardBackground,
        elevation: 2,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Dark theme configuration.

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primaryDark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryDark,
        onPrimary: AppColors.iconDefaultDark,
        secondary: AppColors.secondaryDark,
        onSecondary: AppColors.iconDefaultDark,
        tertiary: AppColors.tertiaryDark,
        error: AppColors.errorDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerHighest: AppColors.surfaceVariantDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        outline: AppColors.cardBorderDark,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.25,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 16,
          letterSpacing: 0.15,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 14,
          letterSpacing: 0.25,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
      iconTheme: IconThemeData(
        color: AppColors.navUnselectedDark,
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.primaryDark,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardBackgroundDark,
        elevation: 1,
        shadowColor: AppColors.textPrimaryDark.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.cardBorderDark,
            width: 1,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.cardBorderDark,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.inputBackgroundDark,
        filled: true,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.inputBorderDark),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.inputBorderDark),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryDark),
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: TextStyle(color: AppColors.textPrimaryDark),
        hintStyle: TextStyle(color: AppColors.textSecondaryDark),
        prefixStyle: TextStyle(color: AppColors.textPrimaryDark),
        suffixStyle: TextStyle(color: AppColors.textPrimaryDark),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.tooltipBackgroundDark,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: AppColors.tooltipTextDark,
          fontSize: 14,
        ),
      ),
    );
  }
}
