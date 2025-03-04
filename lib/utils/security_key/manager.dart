/// Security key manager.
///
// Time-stamp: <Friday 2024-06-28 13:35:54 +1000 Graham Williams>
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solidpod/solidpod.dart'
    show
        AppInfo,
        KeyManager,
        SolidFunctionCallStatus,
        changeKeyPopup,
        deleteFile,
        getEncKeyPath,
        getWebId,
        readPod;

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/home.dart';
import 'package:healthpod/providers/settings.dart';
import 'package:healthpod/utils/fetch_key_saved_status.dart';
import 'package:healthpod/utils/get_secret_key.dart';
import 'package:healthpod/utils/security_key/view_keys.dart';

/// Security Key Manager.
///
/// This class represents a dialog interface for managing local security keys.
/// It provides features like showing the current securtiy key, changing the key,
/// and forgetting the key locally altogether.

/// Main widget for managing security keys.

class SecurityKeyManager extends ConsumerStatefulWidget {
  // Callback to notify parent widget when key status changes.

  final Function(bool) onKeyStatusChanged;

  const SecurityKeyManager({
    super.key,
    required this.onKeyStatusChanged,
  });

  @override
  SecurityKeyManagerState createState() => SecurityKeyManagerState();
}

/// State class that powers `SecurityKeyManager` widget.
/// It encapsulates all logic and UI rendering for the dialog.

class SecurityKeyManagerState extends ConsumerState<SecurityKeyManager>
    with SingleTickerProviderStateMixin {
  // Tracks whether a background operation is in progress to manage UI feedback.

  bool _isLoading = false;

  // Indicates if a security key exists for the user.

  bool _hasExistingKey = false;

  // Controllers for input fields used in dialogs.

  final _keyController = TextEditingController();
  final _confirmKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // On initialisation, verify if a key is already saved.

    _checkKeyStatus();
  }

  /// Checks if a security key exists.
  ///
  /// Updates `_hasExistingKey` to reflect the current status.

  Future<void> _checkKeyStatus() async {
    final hasKey =
        await fetchKeySavedStatus(context, widget.onKeyStatusChanged);
    setState(() {
      _hasExistingKey = hasKey;
    });

    // Also check if the key is saved in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('secret_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      // Update the provider with the saved key
      ref.read(secretKeyProvider.notifier).state = savedKey;
    }
  }

  /// Defines consistent button styles.
  ///
  /// Ensures a uniform user interface across dialogs.

  ButtonStyle _getButtonStyle({bool isDestructive = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDestructive ? Colors.red : Colors.white,
      foregroundColor: isDestructive ? Colors.white : Colors.blue,
      side: BorderSide(
        color: isDestructive ? Colors.red : Colors.blue,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  }

  /// Returns decoration for input fields.
  ///
  /// Used to maintain a cohesive design across dialogs.

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  /// Handles the retrieval and display of security key information.
  ///
  /// If a key doesn't exist, an appropriate error dialog is shown.

  Future<void> _showPrivateData(String title, BuildContext context) async {
    if (!_hasExistingKey) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Notice'),
          content: const Text(
              'No security key found. Please set a security key first.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show loading indicator while retrieving key data.

    setState(() {
      _isLoading = true;
    });

    try {
      final filePath = await getEncKeyPath();
      if (!context.mounted) return;

      final fileContent = await readPod(
        filePath,
        context,
        SecurityKeyManager(onKeyStatusChanged: widget.onKeyStatusChanged),
      );
      if (!context.mounted) return;

      // If key retrieval is successful, navigate to key display screen.

      if (![SolidFunctionCallStatus.notLoggedIn, SolidFunctionCallStatus.fail]
          .contains(fileContent)) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewKeys(
              keyInfo: fileContent!,
              title: title,
            ),
          ),
        );
      }
    } on Exception catch (e) {
      debugPrint('Exception: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Prompts the user to input or change a security key.
  ///
  /// Handles both scenarios: setting a new key or updating an existing one.

  Future<void> _showKeyInputDialog(BuildContext context) async {
    _keyController.clear();
    _confirmKeyController.clear();

    if (_hasExistingKey) {
      try {
        await changeKeyPopup(
          context,
          HealthPodHome(),
        );
        widget.onKeyStatusChanged(true);
        await _checkKeyStatus();
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, e.toString());
        }
      } finally {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
      return;
    }

    // Display a dialog for entering a new key.

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Set Security Key',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _keyController,
              decoration: _getInputDecoration('Enter Security Key'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmKeyController,
              decoration: _getInputDecoration('Confirm Security Key'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: true, // Default to checked
                  onChanged: (value) {
                    // Always save to SharedPreferences
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            style: _getButtonStyle(),
            onPressed: () => _handleKeySubmission(context),
            child: const Text(
              'Set Key',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Submits and validates the entered security key.
  ///
  /// Ensures that both inputs match and triggers the key-saving process.

  Future<void> _handleKeySubmission(BuildContext context) async {
    final key = _keyController.text;
    final confirmKey = _confirmKeyController.text;

    if (key.isEmpty || confirmKey.isEmpty) {
      _showErrorSnackBar(context, 'Please enter both keys');
      return;
    }

    if (key != confirmKey) {
      _showErrorSnackBar(context, 'Keys do not match');
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Initialize the Pod keys
      await KeyManager.initPodKeys(key);

      // Save the key to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('secret_key', key);

      // Update the provider
      ref.read(secretKeyProvider.notifier).state = key;

      widget.onKeyStatusChanged(true);
      await _checkKeyStatus();

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Security key set successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Shows a snack bar with an error message.

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Retries app information for the title.

  Future<({String name, String? webId})> _getInfo() async =>
      (name: await AppInfo.name, webId: await getWebId());

  /// Builds the content of the dialog.
  ///
  /// The user is presented with options to view, change or forget the security key.

  Widget _buildDialogContent(BuildContext context, String title) {
    const smallGapV = SizedBox(height: 20.0);

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Introduction to the dialog's purpose.

            Container(
              color: titleBackgroundColor,
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              child: const Row(
                children: [
                  Text(
                    'Local Security Key Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // Interactive options for the user.

            Container(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 32.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasExistingKey
                                  ? Colors.white
                                  : Colors.grey[300],
                              foregroundColor: _hasExistingKey
                                  ? Colors.blue
                                  : Colors.grey[600],
                              side: BorderSide(
                                color: _hasExistingKey
                                    ? Colors.blue
                                    : Colors.grey[400]!,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _hasExistingKey
                                ? () async {
                                    await _showPrivateData(title, context);
                                  }
                                : null,
                            child: const Text('Show Security Key'),
                          ),
                        ),
                        smallGapV,
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              await _showKeyInputDialog(context);
                            },
                            child: Text(
                                _hasExistingKey ? 'Change Key' : 'Set Key'),
                          ),
                        ),
                        if (_hasExistingKey) ...[
                          smallGapV,
                          SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                final confirmed =
                                    await _showForgetKeyConfirmation(context);
                                if (!confirmed) return;

                                late String msg;
                                try {
                                  // Forget the key in KeyManager
                                  await KeyManager.forgetSecurityKey();

                                  // Delete the key file from the Pod
                                  final encKeyPath = await getEncKeyPath();
                                  await deleteFile(encKeyPath);

                                  // Clear the key from SharedPreferences
                                  await clearSavedSecretKey(ref);

                                  widget.onKeyStatusChanged(false);
                                  await _checkKeyStatus();
                                  msg =
                                      'Successfully forgot local security key.';
                                } on Exception catch (e) {
                                  msg =
                                      'Failed to forget local security key: $e';
                                }

                                if (context.mounted) {
                                  await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: const Text('Notice'),
                                      content: Text(msg),
                                      actions: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              child: const Text('Forget Security Key'),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before forgetting the security key.

  Future<bool> _showForgetKeyConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Confirm Delete',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to forget this security key?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              ElevatedButton(
                style: _getButtonStyle(isDestructive: true),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Builds the dialog widget.
  ///
  /// It uses a FutureBuilder to fetch app information and display the dialog content.

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: FutureBuilder<({String name, String? webId})>(
        future: _getInfo(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final appName = snapshot.data?.name;
            final title =
                'Security Key Management - ${appName!.isNotEmpty ? appName[0].toUpperCase() + appName.substring(1) : ""}';
            return _buildDialogContent(context, title);
          } else {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(24.0),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}
