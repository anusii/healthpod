/// Central key manager to prevent multiple security key prompts.
//
// Time-stamp: <Thursday 2024-05-16 13:33:06 +1100 Ashley Tang>
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

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

/// Central manager for security key operations to prevent duplicate prompts.
///
/// This singleton keeps track of security key verification status and
/// ensures that the key is only requested once during app initialization.

class CentralKeyManager {
  // Singleton instance.

  static final CentralKeyManager _instance = CentralKeyManager._internal();

  // Factory constructor.

  factory CentralKeyManager() => _instance;

  // Private constructor.

  CentralKeyManager._internal();

  // Key verification status.

  bool _keyVerified = false;

  // Completer to track verification process.

  Completer<bool>? _verificationCompleter;

  // Get singleton instance.

  static CentralKeyManager get instance => _instance;

  /// Checks if security key is needed and initiates a single verification process.
  ///
  /// Returns true if key is verified (either now or previously), false otherwise.
  /// Ensures that only one prompt is shown even if called from multiple places.

  Future<bool> ensureSecurityKey(BuildContext context, Widget child) async {
    // If key is already verified, return immediately.

    if (_keyVerified) {
      //debugPrint('⚠️ Security key already verified, skipping prompt');
      return true;
    }

    // If verification is in progress, wait for it to complete.

    if (_verificationCompleter != null &&
        !_verificationCompleter!.isCompleted) {
      //debugPrint('⚠️ Security key verification already in progress, waiting...');
      // Wait for the existing verification to complete and return its result.

      return _verificationCompleter!.future;
    }

    // Start new verification process.

    _verificationCompleter = Completer<bool>();

    try {
      // Check if security key exists.

      final hasKey = await KeyManager.hasSecurityKey();

      if (hasKey) {
        //debugPrint('⚠️ Security key found, no prompt needed');
        _keyVerified = true;
        _verificationCompleter!.complete(true);
        return true;
      }

      // Get verification key.

      final verificationKey = await KeyManager.getVerificationKey();

      // If no verification key, no security key is needed.

      if (verificationKey.isEmpty) {
        //debugPrint('⚠️ No verification key found, no security key needed');
        _keyVerified = true;
        _verificationCompleter!.complete(true);
        return true;
      }

      // Show security key prompt once.

      if (!context.mounted) {
        _verificationCompleter!.complete(false);
        return false;
      }

      //debugPrint('⚠️ Showing security key prompt');

      // Attempt to get the key using the standard SolidPod function

      try {
        await getKeyFromUserIfRequired(context, child);
      } catch (e) {
        debugPrint('⚠️ Error showing key dialog: $e');
      }

      // Double-check if key was provided.

      final hasKeyNow = await KeyManager.hasSecurityKey();
      _keyVerified = hasKeyNow;

      _verificationCompleter!.complete(hasKeyNow);
      return hasKeyNow;
    } catch (e) {
      //debugPrint('⚠️ Error in security key verification: $e');
      _verificationCompleter?.complete(false);
      return false;
    } finally {
      // If the completer didn't complete for some reason, complete it now.

      if (_verificationCompleter != null &&
          !_verificationCompleter!.isCompleted) {
        _verificationCompleter!.complete(false);
      }
    }
  }

  /// Reset the key verification status.
  ///
  /// Should be called when logging out or when key needs re-verification.

  void reset() {
    _keyVerified = false;

    // Clear any in-progress verification.

    if (_verificationCompleter != null &&
        !_verificationCompleter!.isCompleted) {
      _verificationCompleter!.complete(false);
    }
    _verificationCompleter = null;

    //debugPrint('⚠️ Security key verification status reset');
  }
}
