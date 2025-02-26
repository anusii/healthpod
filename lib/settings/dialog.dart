/// Settings dialog/popup for the health data app.
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
import 'package:healthpod/widgets/setting_field.dart';

/// Settings dialog that allows users to configure server connection and authentication details.

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  SettingsDialogState createState() => SettingsDialogState();
}

/// Manages the state and UI for the settings dialog.

class SettingsDialogState extends ConsumerState<SettingsDialog> {
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Loads previously saved settings from local storage.

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    ref.read(serverURLProvider.notifier).state =
        prefs.getString('server_url') ?? '';
    ref.read(usernameProvider.notifier).state =
        prefs.getString('username') ?? '';
    ref.read(passwordProvider.notifier).state =
        prefs.getString('password') ?? '';
    ref.read(secretKeyProvider.notifier).state =
        prefs.getString('secret_key') ?? '';
  }

  // Builds the settings dialog UI with a white container and drop shadow.

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    // Add reset function to handle clearing all settings.

    void resetSettings() async {
      // Clear SharedPreferences.

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('server_url');
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.remove('secret_key');

      // Reset all providers to default values.

      ref.invalidate(serverURLProvider);
      ref.invalidate(usernameProvider);
      ref.invalidate(passwordProvider);
      ref.invalidate(secretKeyProvider);
    }

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Stack(
          children: [
            Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(77),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      SettingField(
                        label: 'Server URL',
                        hint: 'Enter server URL',
                        provider: serverURLProvider,
                        tooltip: '''

                        **Server URL Setting**
                        Enter the URL of your Solid Pod server.

                        ''',
                      ),
                      const SizedBox(height: 16),
                      SettingField(
                        label: 'Username',
                        hint: 'Enter username',
                        provider: usernameProvider,
                        tooltip: '''

                        **Username Setting**
                        Enter your Solid Pod username.

                        ''',
                      ),
                      const SizedBox(height: 16),
                      SettingField(
                        label: 'Password',
                        hint: 'Enter password',
                        provider: passwordProvider,
                        isPassword: true,
                        tooltip: '''

                        **Password Setting**
                        Enter your Solid Pod password.

                        ''',
                      ),
                      const SizedBox(height: 16),
                      SettingField(
                        label: 'Secret Key',
                        hint: 'Enter secret key',
                        provider: secretKeyProvider,
                        isPassword: true,
                        tooltip: '''

                        **Secret Key Setting**
                        Enter your encryption secret key.

                        ''',
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          // Show confirmation dialog before resetting
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Reset Settings'),
                                content: const Text(
                                    'Are you sure you want to reset all settings to default?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      resetSettings();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      'Reset',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                        ),
                        child: const Text(
                          'Reset to Default',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
