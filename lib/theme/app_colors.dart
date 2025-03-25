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

  /// Warm gold - slightly desaturated.
  static const secondary = Color(0xFFD4A76A);

  /// Fresh teal - replaces dark green for a more modern look.
  static const tertiary = Color(0xFF20B2AA);

  /// Semantic Colours.
  /// Emerald green for success.
  static const success = Color(0xFF2ECC71);

  /// Crimson for errors.
  static const error = Color(0xFFE74C3C);

  /// Warm orange for warnings.
  static const warning = Color(0xFFE67E22);

  /// Azure blue for info.
  static const info = Color(0xFF3498DB);

  /// Warm neutral palette - more refined gradients.
  static const background = Color(0xFFF8F5F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF5EBE0);

  /// Text Colours - improved contrast.
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF404040);
  static const textTertiary = Color(0xFF666666);

  /// Navigation Colours.
  static const navSelected = primary;
  static const navUnselected = Color(0xFF8C8C8C);

  /// Additional Colours.
  static const lightGreen = Color(0xFF7CB342);
  static const iconDefault = Colors.white;

  /// Card Colours - more subtle.
  static const cardBackground = Color(0xFFFAF6F0);
  static const cardBorder = Color(0xFFE8E0D8);
}
