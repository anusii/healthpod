import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthpod/providers/settings.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  SettingsDialogState createState() => SettingsDialogState();
}

class SettingsDialogState extends ConsumerState<SettingsDialog> {
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved settings
    ref.read(serverURLProvider.notifier).state =
        prefs.getString('serverURL') ?? '';
    ref.read(usernameProvider.notifier).state =
        prefs.getString('username') ?? '';
    ref.read(passwordProvider.notifier).state =
        prefs.getString('password') ?? '';
    ref.read(secretKeyProvider.notifier).state =
        prefs.getString('secretKey') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

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
                    color: Colors.black.withOpacity(0.3),
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
                      _buildSettingField(
                        'Server URL',
                        serverURLProvider,
                        'Enter server URL',
                      ),
                      _buildSettingField(
                        'Username',
                        usernameProvider,
                        'Enter username',
                      ),
                      _buildSettingField(
                        'Password',
                        passwordProvider,
                        'Enter password',
                        isPassword: true,
                      ),
                      _buildSettingField(
                        'Secret Key',
                        secretKeyProvider,
                        'Enter secret key',
                        isPassword: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          // Save all settings
                          await prefs.setString(
                              'serverURL', ref.read(serverURLProvider));
                          await prefs.setString(
                              'username', ref.read(usernameProvider));
                          await prefs.setString(
                              'password', ref.read(passwordProvider));
                          await prefs.setString(
                              'secretKey', ref.read(secretKeyProvider));
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Save Settings'),
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
                tooltip: 'Cancel',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingField(
    String label,
    StateProvider<String> provider,
    String hint, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: TextEditingController(text: ref.watch(provider)),
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) {
          ref.read(provider.notifier).state = value;
        },
      ),
    );
  }
}
