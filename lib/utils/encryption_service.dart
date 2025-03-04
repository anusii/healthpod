/// Encryption service for handling data encryption and decryption.
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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidpod/solidpod.dart' show KeyManager;

import 'package:healthpod/utils/get_secret_key.dart';

/// A service for encrypting and decrypting data using the user's secret key.
///
/// This class demonstrates how to use the secret key dialog to prompt for a key
/// when needed for encryption or decryption operations.

class EncryptionService {
  /// Encrypts the given data using the user's secret key.
  ///
  /// If the key is not already saved, it will prompt the user with a dialog.
  /// The user can choose to save the key for future use.
  ///
  /// Returns the encrypted data, or null if encryption failed or was cancelled.

  static Future<String?> encryptData({
    required BuildContext context,
    required WidgetRef ref,
    required String data,
  }) async {
    try {
      // Get the secret key, showing a dialog if needed
      final secretKey = await getSecretKey(
        context,
        ref,
        operation: 'Encryption',
      );

      // If the user cancelled, return null
      if (secretKey == null || secretKey.isEmpty) {
        return null;
      }

      // Use the KeyManager from solidpod to encrypt the data
      // This is just an example - replace with your actual encryption logic
      // In a real implementation, you would use the appropriate method from KeyManager
      // For example, KeyManager.encryptData or similar
      await KeyManager.initPodKeys(secretKey);
      final encryptedData =
          base64Encode(utf8.encode(data)); // Placeholder encryption
      return encryptedData;
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Encryption failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Decrypts the given data using the user's secret key.
  ///
  /// If the key is not already saved, it will prompt the user with a dialog.
  /// The user can choose to save the key for future use.
  ///
  /// Returns the decrypted data, or null if decryption failed or was cancelled.

  static Future<String?> decryptData({
    required BuildContext context,
    required WidgetRef ref,
    required String encryptedData,
  }) async {
    try {
      // Get the secret key, showing a dialog if needed
      final secretKey = await getSecretKey(
        context,
        ref,
        operation: 'Decryption',
      );

      // If the user cancelled, return null
      if (secretKey == null || secretKey.isEmpty) {
        return null;
      }

      // Use the KeyManager from solidpod to decrypt the data
      // This is just an example - replace with your actual decryption logic
      // In a real implementation, you would use the appropriate method from KeyManager
      // For example, KeyManager.decryptData or similar
      await KeyManager.initPodKeys(secretKey);
      final decryptedData =
          utf8.decode(base64Decode(encryptedData)); // Placeholder decryption
      return decryptedData;
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Decryption failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Encrypts and saves data to a file in the Pod.
  ///
  /// This is an example of how to use the encryption service with Pod file operations.

  static Future<bool> encryptAndSaveToPod({
    required BuildContext context,
    required WidgetRef ref,
    required String data,
    required String filePath,
  }) async {
    try {
      // Encrypt the data
      final encryptedData = await encryptData(
        context: context,
        ref: ref,
        data: data,
      );

      if (encryptedData == null) {
        return false;
      }

      // Save the encrypted data to the Pod
      // This is just an example - replace with your actual Pod saving logic
      // await writePod(filePath, encryptedData, context, const Text('Saving'));

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save encrypted data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Loads and decrypts data from a file in the Pod.
  ///
  /// This is an example of how to use the encryption service with Pod file operations.

  static Future<String?> loadAndDecryptFromPod({
    required BuildContext context,
    required WidgetRef ref,
    required String filePath,
  }) async {
    try {
      // Load the encrypted data from the Pod
      // This is just an example - replace with your actual Pod loading logic
      // final encryptedData = await readPod(filePath, context, const Text('Loading'));

      // For this example, we'll just use a placeholder
      const encryptedData = "ENCRYPTED_DATA_PLACEHOLDER";

      if (encryptedData == null) {
        return null;
      }

      // Decrypt the data
      return await decryptData(
        context: context,
        ref: ref,
        encryptedData: encryptedData,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load encrypted data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}
