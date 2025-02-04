/// Import order lint test file.
///
// Time-stamp: <Thursday 2025-01-30 08:36:00 +1100 Graham Williams>
///
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

// These imports are intentionally out of order to test the lint rule.
// The lint rule should flag this file due to incorrect import ordering.

// Note: uncomment the imports below to trigger the lint warning.

// import 'package:flutter/material.dart';  // Flutter import.
// import 'dart:async';  // Dart SDK import should come first.
// import 'package:healthpod/features/file/browser.dart';  // Project import should come last.
// import 'package:path/path.dart';  // External package import.
// import 'package:healthpod/features/bp/exporter.dart';  // Project import out of alphabetical order.
// import 'dart:io';  // Dart SDK import.
// import 'package:flutter/services.dart';  // Flutter import.

void main() {
  // This function is left intentionally empty.
  // The lint rule should flag this file due to incorrect import ordering.
  // Note: uncomment the imports above to trigger the lint warning.
}
