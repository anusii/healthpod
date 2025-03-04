/// Secret key dialog for encryption/decryption operations.
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

/// A dialog that prompts the user for their secret key when needed for encryption/decryption.
/// Includes an option to save the key locally for future use.

class SecretKeyDialog extends ConsumerStatefulWidget {
  /// The operation being performed that requires the secret key
  final String operation;

  /// Optional callback to execute after the key is provided
  final Function(String key)? onKeyProvided;

  const SecretKeyDialog({
    super.key,
    required this.operation,
    this.onKeyProvided,
  });

  /// Static method to show the dialog and return the entered key
  static Future<String?> show(
    BuildContext context, {
    required String operation,
    Function(String key)? onKeyProvided,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SecretKeyDialog(
          operation: operation,
          onKeyProvided: onKeyProvided,
        );
      },
    );
  }

  @override
  SecretKeyDialogState createState() => SecretKeyDialogState();
}

class SecretKeyDialogState extends ConsumerState<SecretKeyDialog> {
  final TextEditingController _keyController = TextEditingController();
  bool _obscureText = true;
  bool _rememberKey = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkForSavedKey();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  /// Check if a key is already saved in settings
  Future<void> _checkForSavedKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('secret_key');

    if (savedKey != null && savedKey.isNotEmpty) {
      // If key is already saved, use it and close the dialog
      if (widget.onKeyProvided != null) {
        widget.onKeyProvided!(savedKey);
      }
      if (mounted) {
        Navigator.of(context).pop(savedKey);
      }
    }
  }

  /// Save the key to SharedPreferences and the provider
  Future<void> _saveKey(String key) async {
    if (_rememberKey && key.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('secret_key', key);

        // Save to provider
        ref.read(secretKeyProvider.notifier).state = key;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save key: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Secret Key Required for ${widget.operation}'),
      content: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please enter your secret key to continue:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _keyController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Secret Key',
                      hintText: 'Enter your secret key',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberKey,
                        onChanged: (value) {
                          setState(() {
                            _rememberKey = value ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Remember this key on this device',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  if (_rememberKey)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'The key will be stored on this device only. Anyone with access to this device may be able to decrypt your data.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  final key = _keyController.text;
                  if (key.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a secret key'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Save key if remember is checked
                  await _saveKey(key);

                  // Call the callback if provided
                  if (widget.onKeyProvided != null) {
                    widget.onKeyProvided!(key);
                  }

                  // Close the dialog and return the key
                  Navigator.of(context).pop(key);
                },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
