/// A utility function to repeatedly execute a condition until it succeeds or times out.
//
// Time-stamp: <Sunday 2025-01-26 08:55:54 +1100 Graham Williams>
//
/// Copyright (C) 2023-2024, Togaware Pty Ltd
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

import 'dart:async';

/// Repeatedly attempts to execute a condition until it succeeds or times out.
///
/// This utility function implements a polling mechanism that:
/// - Executes the provided condition function at regular intervals
/// - Continues until the condition succeeds or timeout is reached
/// - Returns the condition's result if successful
/// - Throws TimeoutException if the timeout period is exceeded

Future<T> waitFor<T>(
  Future<T> Function() condition, {
  Duration timeout = const Duration(seconds: 10),
  Duration interval = const Duration(milliseconds: 500),
}) async {
  // Calculate when the waiting should end.

  final endTime = DateTime.now().add(timeout);

  // Keep trying until timeout.

  while (true) {
    try {
      // Attempt to execute the condition.

      return await condition();
    } catch (e) {
      // Check if we've exceeded the timeout period.

      if (DateTime.now().isAfter(endTime)) {
        throw TimeoutException(
          '⏳ Condition not met within timeout period',
        );
      }
      // Wait for specified interval before next attempt.

      await Future.delayed(interval);
    }
  }
}
