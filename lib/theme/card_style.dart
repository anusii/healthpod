/// Card styling utilities for home components.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:healthpod/theme/app_colors.dart';

/// Returns a BoxDecoration with a consistent soft card styling for home components
/// with lighter borders and subtle shadows
BoxDecoration getHomeCardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  
  return BoxDecoration(
    color: theme.cardTheme.color,
    border: Border.all(
      color: theme.brightness == Brightness.light 
          ? AppColors.cardBorder
          : AppColors.cardBorderDark,
      width: 0.5, // Thinner border
    ),
    borderRadius: BorderRadius.circular(6.0), // Slightly rounded corners
    boxShadow: [
      BoxShadow(
        color: theme.colorScheme.shadow.withOpacity(0.15), // More transparent shadow
        spreadRadius: 1, // Reduced spread
        blurRadius: 3, // Slightly reduced blur
        offset: const Offset(0, 1),
      ),
    ],
  );
}