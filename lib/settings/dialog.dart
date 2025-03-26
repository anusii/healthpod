/// Settings dialog/popup for the health data app.
///
// Time-stamp: <Wednesday 2025-03-26 09:54:58 +1100 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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
import 'package:healthpod/utils/constrained_dialog.dart';
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

    // Set default values if no settings are found in shared preferences.

    ref.read(serverURLProvider.notifier).state =
        prefs.getString('server_url') ?? 'https://pods.dev.solidcommunity.au';
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

    // Add reset function to handle clearing only server URL.

    void resetSettings() async {
      // Clear SharedPreferences.

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('server_url');
      // leave username, password and secret key here for now.

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
              // 80% of screen height.

              height: size.height * 0.8,
              constraints: BoxConstraints(
                // Maximum height in logical pixels.

                maxHeight: 600,
                // Minimum height in logical pixels.

                minHeight: 300,
              ),
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

                        **Server URL:** Enter the URL of your Solid Pod server
                        here. The server is where you have registered for a Pod
                        and can be any server supporting the Solid protocol. An
                        available demo server is
                        [https://pods.solidcommunity.au](https://pods.solidcommunity.au),
                        but any Solid server will do.  The default is
                        **currently** our development server
                        [https://pods.dev.solidcommunity.au](https://pods.dev.solidcommunity.au)

                        ''',
                      ),
                      const SizedBox(height: 16),
                      SettingField(
                        label: 'Username',
                        hint: 'Enter username',
                        provider: usernameProvider,
                        tooltip: '''

                        **Username:** This is your Solid Pod username that is
                        added to the **Server URL** to construct your WebID for
                        logging in to your Pod on the selected server. The
                        default is empty.

                        ''',
                      ),
                      const SizedBox(height: 16),
                      SettingField(
                        label: 'Password',
                        hint: 'Enter password',
                        provider: passwordProvider,
                        isPassword: true,
                        tooltip: '''

                        **Password:** This is the password you supplied when
                        creating your Solid Pod on a Solid server. Generally we
                        recommend that you do not store your password in this
                        field as it will be stored on this device as it could be
                        compromised any spy app that is installed on your
                        device. However, if you are comfortable that there is no
                        such spyware on your device then storing your password
                        is a conveinence. The default is empty.

                        ''',
                      ),
                      const SizedBox(height: 16),
                      SettingField(
                        label: 'Secret Key',
                        hint: 'Enter secret key',
                        provider: secretKeyProvider,
                        isPassword: true,
                        tooltip: '''

                        **Secret Key:** In addition to securing access to your
                        Pod on a remote server (through your username and
                        password that this app need not be aware of) we have
                        added encryption of your data on the server. This
                        protects your data from any disclosure on the remote
                        server. The secret encryption key should only be known
                        to you and as a conveince can be saved locally on your
                        device through this field. The default is empty.

                        ''',
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () async {
                          // Show confirmation dialog before resetting.

                          await showConstrainedConfirmationDialog(
                            context: context,
                            title: 'Reset Settings',
                            message:
                                'Are you sure you want to reset all settings to their defaults?',
                            confirmText: 'Reset',
                            confirmColor: Colors.red,
                            maxHeight: 100,
                            onConfirm: resetSettings,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                        ),
                        child: const Text(
                          'Reset Settings',
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
