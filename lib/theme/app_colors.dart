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
  /// darkBlue.

  static const primary = Color(0xFF07579A);

  /// anuGold.

  static const secondary = Color(0xFFBE830E);

  /// darkGreen
  static const tertiary = Color(0xFF40A351);

  /// Semantic Colours.
  /// Darker green for better contrast.

  static const success = Color(0xFF2D6A4F);

  /// Red for errors.
  static const error = Color(0xFFC72C41);

  /// Copper for warnings.

  static const warning = Color(0xFFBE4E0E);

  /// Darker blue for better contrast.

  static const info = Color(0xFF0A558C);

  /// Warm neutral palette.
  static const background = Color(0xFFF5F2EE);
  static const surface = Color(0xFFFAF7F2);
  static const surfaceVariant = Color(0xFFF0E4D7);

  /// Text Colours.

  static const textPrimary = Color(0xFF2C2C2C);
  static const textSecondary = Color(0xFF4A4A4A);
  static const textTertiary = Color(0xFF6B6B6B);

  /// Navigation Colours.

  static const navSelected = primary;
  static const navUnselected = Color(0xFF6B5E5E);

  /// Additional Colours.

  static const lightGreen = Color(0xFF4CAF50);
  static const iconDefault = Colors.white;

  /// Card Colours.

  static const cardBackground = Color(0xFFF0E4D7);
  static const cardBorder = Color(0xFFE6D5C5);
}
