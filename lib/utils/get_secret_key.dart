/// Utility function to get the secret key for encryption/decryption.
///
// Time-stamp: <Friday 2025-02-21 16:58:42 +1100 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
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
/// Authors: Kevin Wang

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:healthpod/providers/settings.dart';
import 'package:healthpod/widgets/secret_key_dialog.dart';

/// Gets the secret key for encryption/decryption operations.
///
/// This function first checks if the key is already saved in the provider or SharedPreferences.
/// If not found, it shows a dialog to prompt the user for the key, with an option to save it.
///
/// Parameters:
/// - context: The BuildContext for showing the dialog
/// - ref: The WidgetRef for accessing providers
/// - operation: A description of the operation requiring the key (e.g., "Encryption", "Decryption")
///
/// Returns:
/// - A Future that resolves to the secret key, or null if the user cancels

Future<String?> getSecretKey(
  BuildContext context,
  WidgetRef ref, {
  required String operation,
}) async {
  // First check if the key is already in the provider
  String? key = ref.read(secretKeyProvider);

  // If not in provider, check SharedPreferences
  if (key == null || key.isEmpty) {
    final prefs = await SharedPreferences.getInstance();
    key = prefs.getString('secret_key');
  }

  // If still not found, show the dialog to get the key
  if (key == null || key.isEmpty) {
    return SecretKeyDialog.show(
      context,
      operation: operation,
    );
  }

  // Key was found, return it
  return key;
}

/// Clears the saved secret key from both the provider and SharedPreferences.
///
/// This can be used when the user wants to remove their saved key for security reasons.

Future<void> clearSavedSecretKey(WidgetRef ref) async {
  // Clear from provider
  ref.read(secretKeyProvider.notifier).state = '';

  // Clear from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('secret_key');
}
