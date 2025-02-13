/// Fetch and navigate to visualisation.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
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
import 'package:healthpod/features/bp/combined_visualisation.dart';
import 'package:healthpod/features/survey/data.dart';

/// Helper function to fetch and handle survey data.
Future<void> fetchAndNavigateToVisualisation(BuildContext context) async {
  // Show loading indicator.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  try {
    // Fetch survey data.
    final surveyData = await SurveyData.fetchAllSurveyData(context);

    // Close loading indicator.
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Instead of returning data, navigate to visualization page
    if (surveyData.isNotEmpty && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BPCombinedVisualisation(),
        ),
      );
    }
  } catch (e) {
    // Close loading indicator and show error.
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading survey data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
