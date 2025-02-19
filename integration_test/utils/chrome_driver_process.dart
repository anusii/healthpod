/// ChromeDriver process management for WebDriver.
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
import 'dart:convert';
import 'dart:io';

import 'logger.dart';
import 'test_config.dart';

/// Manages ChromeDriver process lifecycle for WebDriver testing
///
/// Handles:
/// - Starting ChromeDriver on specified port
/// - Process monitoring and logging
/// - Graceful shutdown
/// - Platform-specific behavior (Windows vs other OS)
/// - Port availability checking
/// - Process cleanup

/// ChromeDriver process management for WebDriver with cross-platform support.
///
/// This class manages the lifecycle of a ChromeDriver process, which is required
/// for browser automation using WebDriver. It provides platform-specific handling
/// for Windows, Linux, and macOS environments.
///
/// Features:
/// * Automatic platform detection and configuration
/// * System and local ChromeDriver support
/// * Port availability checking
/// * Process monitoring and logging
/// * Graceful shutdown handling
/// * Executable permission management for Unix systems
///
/// Example usage:
/// ```dart
/// final driver = ChromeDriverProcess();
/// await driver.start();
/// // ... perform WebDriver operations ...
/// await driver.stop();
/// ```
///
/// Note: Requires ChromeDriver to be either:
/// - Available in system PATH (Linux/macOS)
/// - Located in the configured tools directory (Windows/Linux fallback)

class ChromeDriverProcess {
  // Internal reference to the ChromeDriver process.

  Process? _process;

  // Tracks the running state of ChromeDriver.

  bool _isRunning = false;

  /// Indicates whether the ChromeDriver process is currently running.

  bool get isRunning => _isRunning;

  /// Checks if a specific port is available for use on localhost.
  ///
  /// Returns true if the port is available, false otherwise.
  /// This helps prevent port conflicts when starting ChromeDriver.
  ///
  /// Parameters:
  /// - [port]: The port number to check

  Future<bool> _isPortAvailable(int port) async {
    try {
      final socket = await ServerSocket.bind('localhost', port, shared: true);
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Determines the appropriate ChromeDriver command for the current platform.
  ///
  /// This method implements the following strategy:
  /// 1. For Windows: Uses the configured path
  /// 2. For Linux: Tries system installation first, falls back to local
  /// 3. For macOS: Uses system installation
  ///
  /// Throws:
  /// - [UnsupportedError] if the platform is not supported

  String _getChromeDriverCommand() {
    if (Platform.isWindows) {
      return TestConfig.chromeDriverPath;
    } else if (Platform.isLinux) {
      // First try system-installed chromedriver.

      final result = Process.runSync('which', ['chromedriver']);
      if (result.exitCode == 0) {
        return 'chromedriver';
      }
      // Fallback to configured path if system installation not found.

      return TestConfig.chromeDriverPath;
    } else if (Platform.isMacOS) {
      // Uses system installation on macOS.

      return 'chromedriver';
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  /// Verifies that ChromeDriver exists at the specified path.
  ///
  /// Parameters:
  /// - [driverPath]: The path to check for ChromeDriver
  ///
  /// Throws:
  /// - [FileSystemException] if ChromeDriver is not found

  Future<void> _verifyDriverExists(String driverPath) async {
    if (Platform.isWindows ||
        (Platform.isLinux && driverPath != 'chromedriver')) {
      final file = File(driverPath);
      if (!await file.exists()) {
        throw FileSystemException('🚫 ChromeDriver not found', driverPath);
      }
    }
  }

  /// Configures platform-specific process options.
  ///
  /// On Linux systems, this ensures the ChromeDriver binary has
  /// executable permissions. Returns the appropriate ProcessStartMode
  /// for the current platform.

  Future<ProcessStartMode> _getProcessMode() async {
    if (Platform.isLinux) {
      // Ensure executable permissions on Linux.

      final driverPath = _getChromeDriverCommand();
      if (driverPath != 'chromedriver') {
        await Process.run('chmod', ['+x', driverPath]);
      }
      return ProcessStartMode.normal;
    }
    return ProcessStartMode.normal;
  }

  /// Starts the ChromeDriver process.
  ///
  /// This method:
  /// 1. Verifies ChromeDriver installation
  /// 2. Checks port availability
  /// 3. Configures platform-specific options
  /// 4. Launches ChromeDriver process
  /// 5. Sets up output logging
  ///
  /// Throws:
  /// - [FileSystemException] if ChromeDriver is not found
  /// - [StateError] if the port is already in use
  /// - Other exceptions that may occur during process startup

  Future<void> start() async {
    if (_isRunning) return;

    try {
      // Get and verify ChromeDriver command.

      final driverCommand = _getChromeDriverCommand();
      await _verifyDriverExists(driverCommand);

      // Verify port availability.

      if (!await _isPortAvailable(TestConfig.chromeDriverPort)) {
        throw StateError(
            '⚠️ Port ${TestConfig.chromeDriverPort} is already in use. Please close other instances.');
      }

      // Configure and start process.

      final processMode = await _getProcessMode();
      Logger.info('🚀 Starting ChromeDriver from: $driverCommand');

      _process = await Process.start(
        driverCommand,
        ['--port=${TestConfig.chromeDriverPort}'],
        mode: processMode,
      );

      // Configure process output logging.

      _process!.stdout.transform(utf8.decoder).listen((data) {
        Logger.info('📢 ChromeDriver stdout: $data');
      });

      _process!.stderr.transform(utf8.decoder).listen((data) {
        Logger.warn('⚠️ ChromeDriver stderr: $data');
      });

      // Allow time for initialisation.

      await Future.delayed(const Duration(seconds: 2));
      _isRunning = true;
      Logger.info('✅ ChromeDriver started successfully');
    } catch (e) {
      Logger.error('❌ Failed to start ChromeDriver: $e');
      await stop();
      rethrow;
    }
  }

  /// Stops the ChromeDriver process.
  ///
  /// Implements a graceful shutdown process:
  /// 1. Attempts SIGTERM for graceful shutdown
  /// 2. Waits for process to exit
  /// 3. Forces termination with SIGKILL if timeout occurs
  ///
  /// The timeout period is 5 seconds before forcing termination.

  Future<void> stop() async {
    if (_process != null) {
      Logger.info('🛑 Stopping ChromeDriver...');
      try {
        // Attempt graceful shutdown.

        _process!.kill(ProcessSignal.sigterm);

        // Wait with timeout for process to exit.

        await _process!.exitCode.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            Logger.warn(
                '⚠️ ChromeDriver graceful shutdown timed out, forcing termination');
            _process!.kill(ProcessSignal.sigkill);
            return -1;
          },
        );
      } catch (e) {
        Logger.error('❌ Error stopping ChromeDriver: $e');
      }
      _process = null;
    }
    _isRunning = false;
  }
}
