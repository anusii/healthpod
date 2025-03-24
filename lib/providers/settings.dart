/// Providers for the settings popup.
///
// Time-stamp: <Friday 2025-02-21 16:58:42 +1100 Graham Williams>
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

// Provides state management for application settings using Riverpod.

// Initialize settings from SharedPreferences
Future<String> _initSetting(String key, String defaultValue) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key) ?? defaultValue;
}

// Provider to initialize settings
final settingsInitializerProvider = FutureProvider<void>((ref) async {
  final serverUrl =
      await _initSetting('server_url', 'https://pods.dev.solidcommunity.au');
  final username = await _initSetting('username', 'test@anu.edu.au');
  final password = await _initSetting('password', 'SuperSecure123');
  final secretKey = await _initSetting('secret_key', 'YourSecretKey123');

  ref.read(serverURLProvider.notifier).state = serverUrl;
  ref.read(usernameProvider.notifier).state = username;
  ref.read(passwordProvider.notifier).state = password;
  ref.read(secretKeyProvider.notifier).state = secretKey;
});

// Default server URL for the Solid Pod server.
final serverURLProvider =
    StateProvider<String>((ref) => 'https://pods.dev.solidcommunity.au');

// Stores the user's Solid Pod username.
final usernameProvider = StateProvider<String>((ref) => '');

// Stores the user's Solid Pod password.
final passwordProvider = StateProvider<String>((ref) => '');

// Stores the encryption secret key for secure data handling.
final secretKeyProvider = StateProvider<String>((ref) => '');

// Controls password visibility for password fields in the UI.
// Uses a family provider to manage visibility state for different fields.
final isPasswordVisibleProvider =
    StateProvider.autoDispose.family<bool, String>((ref, id) => false);
