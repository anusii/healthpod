/// Setting field for the settings popup.
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
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:healthpod/providers/settings.dart';

/// A reusable widget for displaying and editing settings with a label and tooltip.

class SettingField extends ConsumerWidget {
  final String label;
  final String hint;
  final StateProvider<String> provider;
  final bool isPassword;
  final String tooltip;

  const SettingField({
    super.key,
    required this.label,
    required this.hint,
    required this.provider,
    this.isPassword = false,
    required this.tooltip,
  });

  // Builds the setting field with a label and text input aligned horizontally.

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);

    // If value is empty, get the stored value from SharedPreferences.

    if (value.isEmpty) {
      SharedPreferences.getInstance().then((prefs) {
        final storedValue = prefs.getString(label) ?? '';
        if (storedValue.isNotEmpty) {
          ref.read(provider.notifier).state = storedValue;
        }
      });
    }

    // Use the label as a unique identifier for each field's visibility state.

    final showPassword = ref.watch(isPasswordVisibleProvider(label));

    // Persists the setting value to local storage.

    Future<void> saveSetting(String value) async {
      // Save to SharedPreferences.

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(label.toLowerCase().replaceAll(' ', '_'), value);
      // Save to provider.

      ref.read(provider.notifier).state = value;
    }

    // Creates a tooltip wrapper around the setting field for additional information.

    return MarkdownTooltip(
      message: tooltip,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Fixed-width container for consistent label alignment.

              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 16),
              // Expandable text field that fills remaining space.

              Expanded(
                child: TextField(
                  controller: TextEditingController(text: value)
                    ..selection = TextSelection.collapsed(offset: value.length),
                  obscureText: isPassword && !showPassword,
                  onChanged: (value) {
                    ref.read(provider.notifier).state = value;
                    saveSetting(value);
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: hint,
                    suffixIcon: isPassword
                        ? IconButton(
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              ref
                                  .read(
                                      isPasswordVisibleProvider(label).notifier)
                                  .state = !showPassword;
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
