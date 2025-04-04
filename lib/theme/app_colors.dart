/// Core colour palette for the application.
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

/// Core colour palette for the application.
/// These colours are used throughout the app via the theme system.

class AppColors {
  /// Brand Colours.
  /// Rich navy blue - more vibrant primary.

  static const primary = Color(0xFF0A4D8C);
  static const primaryDark = Color(0xFF2196F3);

  /// Warm gold - slightly desaturated.

  static const secondary = Color(0xFFD4A76A);
  static const secondaryDark = Color(0xFFFFB74D);

  /// Fresh teal - replaces dark green for a more modern look.

  static const tertiary = Color(0xFF20B2AA);
  static const tertiaryDark = Color(0xFF4DB6AC);

  /// Semantic Colours.
  /// Emerald green for success.

  static const success = Color(0xFF2ECC71);
  static const successDark = Color(0xFF66BB6A);

  /// Crimson for errors.

  static const error = Color(0xFFE74C3C);
  static const errorDark = Color(0xFFEF5350);

  /// Warm orange for warnings.

  static const warning = Color(0xFFE67E22);
  static const warningDark = Color(0xFFFFB74D);

  /// Azure blue for info.

  static const info = Color(0xFF3498DB);
  static const infoDark = Color(0xFF64B5F6);

  /// Warm neutral palette - more refined gradients.

  static const background = Color(0xFFFAF6F0);
  static const backgroundDark = Color(0xFF121212);

  static const surface = Color(0xFFFFFBF7);
  static const surfaceDark = Color(0xFF1D1D1D);

  static const surfaceVariant = Color(0xFFF7E8D8);
  static const surfaceVariantDark = Color(0xFF2A2A2A);

  /// Text Colours - improved contrast.

  static const textPrimary = Color(0xFF1A1A1A);
  static const textPrimaryDark = Color(0xFFFFFFFF);

  static const textSecondary = Color(0xFF404040);
  static const textSecondaryDark = Color(0xFFE0E0E0);

  static const textTertiary = Color(0xFF666666);
  static const textTertiaryDark = Color(0xFFBDBDBD);

  /// Navigation Colours.

  static const navSelected = primary;
  static const navSelectedDark = primaryDark;
  static const navUnselected = Color(0xFF8C8C8C);
  static const navUnselectedDark = Color(0xFF9E9E9E);

  /// Additional Colours.

  static const lightGreen = Color(0xFF7CB342);
  static const iconDefault = Colors.white;
  static const iconDefaultDark = Colors.white;

  /// Card Colours - more subtle.

  static const cardBackground = Color(0xFFFAF6F0);
  static const cardBackgroundDark = Color(0xFF252525);

  static const cardBorder = Color(0xFFE8E0D8);
  static const cardBorderDark = Color(0xFF404040);

  /// Input field colors.

  static const inputBackground = Color(0xFFFFFFFF);
  static const inputBackgroundDark = Color(0xFF1E1E1E);

  static const inputBorder = Color(0xFFE0E0E0);
  static const inputBorderDark = Color(0xFF505050);

  /// Tooltip colors.

  static const tooltipBackground = Color(0xFF2A2A2A);
  static const tooltipBackgroundDark = Color(0xFF424242);
  static const tooltipText = Color(0xFFFFFFFF);
  static const tooltipTextDark = Color(0xFFFFFFFF);
}
