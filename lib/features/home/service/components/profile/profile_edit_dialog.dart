/// Edit dialog for profile details.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/features/home/service/components/profile/profile_form_validators.dart';

/// Shows an edit dialog for profile details.

class ProfileEditDialog {
  /// Shows the edit dialog and returns true if user saved changes.

  static Future<Map<String, String>?> show(
    BuildContext context,
    Map<String, String> currentData,
  ) async {
    // Create temporary controllers for dialog fields.

    final tempControllers = <String, TextEditingController>{
      'name': TextEditingController(text: currentData['name']),
      'address': TextEditingController(text: currentData['address']),
      'bestContactPhone':
          TextEditingController(text: currentData['bestContactPhone']),
      'bestContactEmail':
          TextEditingController(text: currentData['bestContactEmail']),
      'emergencyName':
          TextEditingController(text: currentData['emergencyName']),
      'emergencyPhone':
          TextEditingController(text: currentData['emergencyPhone']),
      'alternativeContactNumber':
          TextEditingController(text: currentData['alternativeContactNumber']),
      'email': TextEditingController(text: currentData['email']),
      'dateOfBirth': TextEditingController(text: currentData['dateOfBirth']),
      'gender': TextEditingController(text: currentData['gender']),
    };

    final formKey = GlobalKey<FormState>();

    // Show dialog with edit form.

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile Details'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameField(tempControllers['name']!),
                  const SizedBox(height: 12),
                  _buildAddressField(tempControllers['address']!),
                  const SizedBox(height: 12),
                  _buildPhoneField(tempControllers['bestContactPhone']!),
                  const SizedBox(height: 12),
                  _buildEmergencyNameField(tempControllers['emergencyName']!),
                  const SizedBox(height: 12),
                  _buildEmergencyPhoneField(tempControllers['emergencyPhone']!),
                  const SizedBox(height: 12),
                  _buildAlternativePhoneField(
                    tempControllers['alternativeContactNumber']!,
                  ),
                  const SizedBox(height: 12),
                  _buildEmailField(tempControllers['email']!),
                  const SizedBox(height: 12),
                  _buildDateOfBirthField(
                    context,
                    tempControllers['dateOfBirth']!,
                  ),
                  const SizedBox(height: 12),
                  _buildGenderField(tempControllers['gender']!),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    // If user confirmed, return the updated data.

    if (result == true) {
      final updatedData = <String, String>{};
      for (final entry in tempControllers.entries) {
        updatedData[entry.key] = entry.value.text;
      }

      // Clean up temporary controllers.

      for (var controller in tempControllers.values) {
        controller.dispose();
      }

      return updatedData;
    }

    // Clean up temporary controllers.

    for (var controller in tempControllers.values) {
      controller.dispose();
    }

    return null;
  }

  /// Builds the name field.

  static Widget _buildNameField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Name'),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Builds the address field.

  static Widget _buildAddressField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Address'),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    );
  }

  /// Builds the phone field with tooltip.

  static Widget _buildPhoneField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phone'),
        MarkdownTooltip(
          message: '''

**Valid Phone Number Formats:**

- **Australian Mobile:** +61 4XX XXX XXX or 04XX XXX XXX
- **Australian Landline:** +61 X XXXX XXXX or 0X XXXX XXXX
- **International:** +[country code] followed by number

Spaces, dashes and parentheses are allowed.

''',
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              hintText: 'e.g. +61 4 1234 5678 or 04 1234 5678',
              suffixIcon: Icon(Icons.info_outline),
            ),
            validator: ProfileFormValidators.validatePhone,
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }

  /// Builds the emergency name field.

  static Widget _buildEmergencyNameField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Emergency Name'),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    );
  }

  /// Builds the emergency phone field with tooltip.

  static Widget _buildEmergencyPhoneField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Emergency Phone'),
        MarkdownTooltip(
          message: '''

**Valid Phone Number Formats:**

- **Australian Mobile:** +61 4XX XXX XXX or 04XX XXX XXX
- **Australian Landline:** +61 X XXXX XXXX or 0X XXXX XXXX
- **International:** +[country code] followed by number

Spaces, dashes and parentheses are allowed.

''',
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              hintText: 'e.g. +61 4 1234 5678 or 04 1234 5678',
              suffixIcon: Icon(Icons.info_outline),
            ),
            validator: ProfileFormValidators.validatePhone,
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }

  /// Builds the alternative phone field with tooltip.

  static Widget _buildAlternativePhoneField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alternative Phone'),
        MarkdownTooltip(
          message: '''

**Valid Phone Number Formats:**

- **Australian Mobile:** +61 4XX XXX XXX or 04XX XXX XXX
- **Australian Landline:** +61 X XXXX XXXX or 0X XXXX XXXX
- **International:** +[country code] followed by number

Spaces, dashes and parentheses are allowed.

''',
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              hintText: 'e.g. +61 4 1234 5678 or 04 1234 5678',
              suffixIcon: Icon(Icons.info_outline),
            ),
            validator: ProfileFormValidators.validatePhone,
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }

  /// Builds the email field.

  static Widget _buildEmailField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Email'),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          validator: ProfileFormValidators.validateEmail,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  /// Builds the date of birth field with date picker.

  static Widget _buildDateOfBirthField(
    BuildContext context,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date of Birth'),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  // Show date picker for selecting date of birth.

                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: ProfileFormValidators.parseDateOrDefault(
                      controller.text,
                    ),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    controller.text = ProfileFormValidators.formatDate(picked);
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                },
              ),
          ],
        ),
      ],
    );
  }

  /// Builds the gender field with dropdown.

  static Widget _buildGenderField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gender'),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: controller.text.isEmpty ? null : controller.text,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('Select gender'),
                  ),
                  DropdownMenuItem(
                    value: 'Male',
                    child: Text('Male'),
                  ),
                  DropdownMenuItem(
                    value: 'Female',
                    child: Text('Female'),
                  ),
                  DropdownMenuItem(
                    value: 'Non-binary',
                    child: Text('Non-binary'),
                  ),
                  DropdownMenuItem(
                    value: 'Prefer not to say',
                    child: Text('Prefer not to say'),
                  ),
                ],
                onChanged: (value) {
                  controller.text = value ?? '';
                },
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                },
              ),
          ],
        ),
      ],
    );
  }
}
