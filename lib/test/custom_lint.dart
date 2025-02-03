/// Custom lint test file.
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

/// Test file demonstrating the custom lint rule for print statements.
///
/// This file intentionally contains a print statement that should trigger
/// the custom lint warning, serving as a verification that the lint rule
/// is working as expected.

/// Entry point of the application.
///
/// This main function serves as the starting point and calls the test function
/// that contains a print statement we expect to be flagged by our custom lint.

void main() {
  customLintTest();
}

/// Test function containing a print statement that should trigger the lint warning.
///
/// This function deliberately uses a print statement to verify that our custom
/// lint rule correctly identifies and flags such usage. When analysing this file,
/// the custom lint rule should generate a warning for the print statement below.
///
/// Expected lint warning:
/// - Location: The print statement in this function
/// - Message: "Avoid using print statements in production code."

void customLintTest() {
  // This print statement should trigger our custom lint warning.
  // Note: uncomment the line below to trigger the lint warning.

  // print('Hello world! We expect this to be flagged by the custom lint.');
}
