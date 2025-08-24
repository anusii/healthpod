/// Setup for medication feature.
///
// Time-stamp: <Tuesday 2025-04-29 10:15:00 +1000 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/create_feature_folder.dart';

/// Sets up medication feature folders and files in the POD.
///
/// This function:
/// - Creates a medication directory in the POD if it doesn't exist
/// - Creates initial configuration files needed for the feature
///
/// Returns a [Future<SolidFunctionCallStatus>] indicating setup success or failure.

Future<SolidFunctionCallStatus> setupMedicationFeature(
  BuildContext context,
) async {
  // Return early if widget is no longer mounted.

  if (!context.mounted) return SolidFunctionCallStatus.fail;

  return await createFeatureFolder(
    featureName: 'medication',
    context: context,
    createInitFile: true,
    onProgressChange: (_) {},
    onSuccess: () {},
  );
}
