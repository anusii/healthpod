import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthpod/providers/settings.dart';
import 'package:healthpod/widgets/setting_field.dart';

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
    ref.read(serverURLProvider.notifier).state =
        prefs.getString('server_url') ?? '';
    ref.read(usernameProvider.notifier).state =
        prefs.getString('username') ?? '';
    ref.read(passwordProvider.notifier).state =
        prefs.getString('password') ?? '';
    ref.read(secretKeyProvider.notifier).state =
        prefs.getString('secret_key') ?? '';
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
