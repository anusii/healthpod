/// Custom logger for integration testing.
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

import 'dart:io';

/// Custom logger for integration testing.
///
/// Features:
/// - Multiple log levels (DEBUG, INFO, WARNING, ERROR)
/// - Console output with timestamps
/// - Optional file logging

class Logger {
  // Enable/disable all logging output.

  static const bool enableLogging = true;

  // Enable/disable writing logs to file.

  static const bool logToFile = false;

  // File to write logs to when logToFile is enabled.

  static final File logFile = File('test_logs.txt');

  /// Internal logging method used by public logging methods.
  ///
  /// Formats the message with timestamp and level, then outputs to
  /// console and optionally to file if enabled.

  static void _log(String message, String level) {
    // Early return if logging is disabled.

    if (!enableLogging) return;

    // Add timestamp and log level to message.

    final formattedMessage = '[$level]: $message';

    // Output formatted message to console.
    // ignore_for_file: avoid_print

    // Append to log file if file logging is enabled.

    if (logToFile) {
      try {
        logFile.writeAsStringSync('$formattedMessage\n', mode: FileMode.append);
      } catch (e) {
        // Log file write errors to console since we can't write them to file.

        stdout.writeln('Failed to write to log file: $e');
      }
    }
  }

  /// Log a debug message.

  static void debug(String message) => _log(message, 'DEBUG');

  /// Log an info message.

  static void info(String message) => _log(message, 'INFO');

  /// Log a warning message.

  static void warn(String message) => _log(message, 'WARNING');

  /// Log an error message with optional error object and stack trace.
  ///
  /// If error object is provided, it will be included in the message.
  /// If stack trace is provided, it will be appended after the error.

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    final fullMessage = error != null
        ? '$message\nError: $error${stackTrace != null ? '\nStack trace:\n$stackTrace' : ''}'
        : message;
    _log(fullMessage, 'ERROR');
  }
}
