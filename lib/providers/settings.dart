/// Providers for the settings popup.
///
// Time-stamp: <Saturday 2025-10-25 06:03:53 +1100 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Kevin Wang

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provides state management for application settings using Riverpod.

// Initialise settings from SharedPreferences.

Future<String> _initSetting(String key, String defaultValue) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key) ?? defaultValue;
}

// Provider to initialise settings.

final settingsInitializerProvider = FutureProvider<void>((ref) async {
  final serverUrl = await _initSetting(
    'server_url',
    'https://pods.solidcommunity.au',
  );
  final email = await _initSetting('email', 'test@anu.edu.au');
  final password = await _initSetting('password', 'SuperSecure123');
  final secretKey = await _initSetting('secret_key', 'YourSecretKey123');

  ref.read(serverURLProvider.notifier).setState(serverUrl);
  ref.read(emailProvider.notifier).setState(email);
  ref.read(passwordProvider.notifier).setState(password);
  ref.read(secretKeyProvider.notifier).setState(secretKey);
});

/// Base class for string notifiers that provides setState functionality.

abstract class StringSettingNotifier extends Notifier<String> {
  void setState(String value) {
    state = value;
  }
}

/// Notifier for server URL state management.

class ServerURLNotifier extends StringSettingNotifier {
  @override
  String build() => 'https://pods.solidcommunity.au';
}

/// Notifier for email state management.

class EmailNotifier extends StringSettingNotifier {
  @override
  String build() => '';
}

/// Notifier for password state management.

class PasswordNotifier extends StringSettingNotifier {
  @override
  String build() => '';
}

/// Notifier for secret key state management.

class SecretKeyNotifier extends StringSettingNotifier {
  @override
  String build() => '';
}

/// Notifier for auto-dispose boolean state with family support.
/// In Riverpod 3.0, family notifiers use constructor parameters for the arg.

class PasswordVisibilityNotifier extends Notifier<bool> {
  PasswordVisibilityNotifier(this.fieldId);
  final String fieldId;

  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void setState(bool value) {
    state = value;
  }
}

// Default server URL for the Solid Pod server.

final serverURLProvider = NotifierProvider<ServerURLNotifier, String>(
  ServerURLNotifier.new,
);

// Stores the user's Solid Pod email.

final emailProvider = NotifierProvider<EmailNotifier, String>(
  EmailNotifier.new,
);

// Stores the user's Solid Pod password.

final passwordProvider = NotifierProvider<PasswordNotifier, String>(
  PasswordNotifier.new,
);

// Stores the encryption secret key for secure data handling.

final secretKeyProvider = NotifierProvider<SecretKeyNotifier, String>(
  SecretKeyNotifier.new,
);

// Controls password visibility for password fields in the UI.
// Uses a family provider to manage visibility state for different fields.

final isPasswordVisibleProvider = NotifierProvider.autoDispose
    .family<PasswordVisibilityNotifier, bool, String>(
  PasswordVisibilityNotifier.new,
);
