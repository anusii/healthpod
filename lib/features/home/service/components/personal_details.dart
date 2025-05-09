/// Personal details card widget.
//
// Time-stamp: <Friday 2025-02-21 08:30:05 +1100 Graham Williams>
//
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
/// Authors: Zheyuan Xu

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/construct_pod_path.dart';
import 'package:healthpod/utils/fetch_profile_data.dart';
import 'package:healthpod/utils/upload_json_to_pod.dart';

/// A widget that displays and allows editing of personal identification information.

class PersonalDetails extends StatefulWidget {
  final bool isEditing;
  final bool showEditButton;
  final VoidCallback onEditPressed;
  final VoidCallback onDataChanged;

  const PersonalDetails({
    super.key,
    this.isEditing = false,
    this.showEditButton = true,
    required this.onEditPressed,
    required this.onDataChanged,
  });

  @override
  State<PersonalDetails> createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  late TextEditingController _addressController;
  late TextEditingController _bestContactPhoneController;
  late TextEditingController _alternativeContactNumberController;
  late TextEditingController _emailController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _genderController;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfileData();
  }

  void _initializeControllers() {
    _addressController = TextEditingController();
    _bestContactPhoneController = TextEditingController();
    _alternativeContactNumberController = TextEditingController();
    _emailController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _genderController = TextEditingController();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = await fetchProfileData(context);
      _profileData = profileData;

      setState(() {
        _addressController.text = profileData['address'] ?? '';
        _bestContactPhoneController.text =
            profileData['bestContactPhone'] ?? '';
        _alternativeContactNumberController.text =
            profileData['alternativeContactNumber'] ?? '';
        _emailController.text = profileData['email'] ?? '';
        _dateOfBirthController.text = profileData['dateOfBirth'] ?? '';
        _genderController.text = profileData['gender'] ?? '';
      });
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if any data has actually changed.

    if (!_hasDataChanged()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes detected')),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedData = {
        'name': _profileData['name'] ?? '',
        'address': _addressController.text.trim(),
        'bestContactPhone': _bestContactPhoneController.text.trim(),
        'alternativeContactNumber':
            _alternativeContactNumberController.text.trim(),
        'email': _emailController.text.trim(),
        'dateOfBirth': _dateOfBirthController.text.trim(),
        'gender': _genderController.text.trim(),
      };

      // Clean up existing profile files before saving a new one.

      await _deleteExistingProfileFiles();

      // Try to use the uploadJsonToPod method which is known to work with other components.

      final result = await _saveProfileDataUsingUploadUtil(updatedData);

      if (result != SolidFunctionCallStatus.success) {
        throw Exception('Failed to save profile data: $result');
      }

      // Update local profile data.

      _profileData = updatedData;
      widget.onDataChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Saves the profile data using the uploadJsonToPod utility which handles file creation
  /// and proper encryption consistently.

  Future<SolidFunctionCallStatus> _saveProfileDataUsingUploadUtil(
      Map<String, dynamic> updatedData) async {
    debugPrint('Saving profile using uploadJsonToPod utility...');

    try {
      // Create a structure for uploadJsonToPod that matches what saveResponseToPod expects
      // The profile data should be passed as the 'responses' parameter, not wrapped in 'data'

      // Use uploadJsonToPod which is used by other components successfully.
      final result = await uploadJsonToPod(
        data: {
          'timestamp': DateTime.now().toIso8601String(),
          'responses':
              updatedData, // This matches the expected structure in fetchProfileData
        },
        targetPath: 'profile',
        fileNamePrefix: 'profile',
        context: context,
        onSuccess: () {
          debugPrint('Successfully uploaded profile data');
        },
      );

      // Double-check by logging the directory contents after saving.

      if (result == SolidFunctionCallStatus.success) {
        try {
          final dirUrl = await getDirUrl(constructPodPath('profile', ''));
          final resources = await getResourcesInContainer(dirUrl);
          debugPrint(
              'After save - Files in profile directory: ${resources.files}');
        } catch (e) {
          debugPrint('Error checking directory after save: $e');
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error saving profile: $e');
      return SolidFunctionCallStatus.fail;
    }
  }

  /// Check if any data has changed compared to the original profile data.

  bool _hasDataChanged() {
    return _addressController.text.trim() != (_profileData['address'] ?? '') ||
        _bestContactPhoneController.text.trim() !=
            (_profileData['bestContactPhone'] ?? '') ||
        _alternativeContactNumberController.text.trim() !=
            (_profileData['alternativeContactNumber'] ?? '') ||
        _emailController.text.trim() != (_profileData['email'] ?? '') ||
        _dateOfBirthController.text.trim() !=
            (_profileData['dateOfBirth'] ?? '') ||
        _genderController.text.trim() != (_profileData['gender'] ?? '');
  }

  /// Deletes existing profile files before saving a new one to prevent duplication.
  /// Keeps track of the most recent file (if any) for persistence purposes.

  Future<void> _deleteExistingProfileFiles() async {
    try {
      // Get all files in the profile directory.
      // Note: constructPodPath already includes basePath.

      final dirUrl = await getDirUrl(constructPodPath('profile', ''));
      debugPrint(
          'Looking for profile files to delete in: ${constructPodPath('profile', '')}');

      final resources = await getResourcesInContainer(dirUrl);
      debugPrint('Files in profile directory: ${resources.files}');

      // Find all profile files.

      final profileFiles = resources.files
          .where((file) =>
              file.startsWith('profile_') && file.endsWith('.json.enc.ttl'))
          .toList();

      if (profileFiles.isEmpty) {
        debugPrint('No existing profile files to clean up');
        return;
      }

      // Sort to find the most recent one (we'll keep the metadata from this).

      profileFiles.sort((a, b) => b.compareTo(a));

      // Delete all profile files - we'll create a new one with the current data.

      int deletedCount = 0;
      for (final file in profileFiles) {
        try {
          final filePath = constructPodPath('profile', file);
          debugPrint('Deleting profile file: $filePath');
          await deleteFile(filePath);
          deletedCount++;
        } catch (e) {
          debugPrint('Error deleting profile file $file: $e');
        }
      }

      debugPrint('Successfully deleted $deletedCount profile files');
    } catch (e) {
      debugPrint('Error cleaning up profile files: $e');
      // Don't rethrow - we want to continue with saving even if cleanup fails.
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _bestContactPhoneController.dispose();
    _alternativeContactNumberController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PersonalDetails oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If we're exiting edit mode, save the data.

    if (oldWidget.isEditing && !widget.isEditing) {
      _saveProfileData();
    }
  }

  // Show edit dialog for editing personal details.

  Future<void> _showEditDialog() async {
    // Create temporary controllers with current values.

    final tempAddressController =
        TextEditingController(text: _addressController.text);
    final tempBestContactPhoneController =
        TextEditingController(text: _bestContactPhoneController.text);
    final tempAlternativeContactNumberController =
        TextEditingController(text: _alternativeContactNumberController.text);
    final tempEmailController =
        TextEditingController(text: _emailController.text);
    final tempDateOfBirthController =
        TextEditingController(text: _dateOfBirthController.text);
    final tempGenderController =
        TextEditingController(text: _genderController.text);

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Personal Details'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Address'),
                  TextFormField(
                    controller: tempAddressController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    validator: _validateRequired,
                  ),
                  const SizedBox(height: 12),
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
                      controller: tempBestContactPhoneController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        hintText: 'e.g. +61 4 1234 5678 or 04 1234 5678',
                        suffixIcon: Icon(Icons.info_outline),
                      ),
                      validator: _validatePhone,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      controller: tempAlternativeContactNumberController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        hintText: 'e.g. +61 4 1234 5678 or 04 1234 5678',
                        suffixIcon: Icon(Icons.info_outline),
                      ),
                      validator: _validatePhone,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Email'),
                  TextFormField(
                    controller: tempEmailController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  const Text('Date of Birth'),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _parseDateOrDefault(tempDateOfBirthController.text),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        tempDateOfBirthController.text = _formatDate(picked);
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: tempDateOfBirthController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: _validateRequired,
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Gender'),
                  DropdownButtonFormField<String>(
                    value: tempGenderController.text.isEmpty
                        ? null
                        : tempGenderController.text,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(
                          value: 'Non-binary', child: Text('Non-binary')),
                      DropdownMenuItem(
                          value: 'Prefer not to say',
                          child: Text('Prefer not to say')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        tempGenderController.text = value;
                      }
                    },
                    validator: _validateRequired,
                  ),
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

    // If user confirmed saving, update the main controllers and save data.

    if (result == true) {
      setState(() {
        _addressController.text = tempAddressController.text;
        _bestContactPhoneController.text = tempBestContactPhoneController.text;
        _alternativeContactNumberController.text =
            tempAlternativeContactNumberController.text;
        _emailController.text = tempEmailController.text;
        _dateOfBirthController.text = tempDateOfBirthController.text;
        _genderController.text = tempGenderController.text;
      });

      await _saveProfileData();
    }

    // Dispose temporary controllers after they are no longer needed.

    tempAddressController.dispose();
    tempBestContactPhoneController.dispose();
    tempAlternativeContactNumberController.dispose();
    tempEmailController.dispose();
    tempDateOfBirthController.dispose();
    tempGenderController.dispose();
  }

  /// Parse a date string or return a default date.

  DateTime _parseDateOrDefault(String dateStr) {
    try {
      // Try to parse the date in format YYYY-MM-DD.
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    // Return a default date (30 years ago).

    return DateTime.now().subtract(const Duration(days: 365 * 30));
  }

  /// Format a date as YYYY-MM-DD.

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Validate an email address.

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null; // Make email optional
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  /// Validate a phone number.

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null; // Make phone optional

    // Clean the input by removing spaces, dashes, and parentheses.

    final cleanedValue = value.replaceAll(RegExp(r'[\s\-()]'), '');

    // Australian mobile: +61 4XX XXX XXX or 04XX XXX XXX.
    // Australian landline: +61 X XXXX XXXX or 0X XXXX XXXX.
    // Allow international format with + prefix.

    final australianPhoneRegex = RegExp(r'^(\+61|0)[0-9]{9,10}$');

    // Also allow international numbers with country code.

    final internationalPhoneRegex = RegExp(r'^\+[0-9]{10,14}$');

    if (!australianPhoneRegex.hasMatch(cleanedValue) &&
        !internationalPhoneRegex.hasMatch(cleanedValue)) {
      return 'Enter a valid phone number (e.g. +61 4 1234 5678 or 04 1234 5678)';
    }
    return null;
  }

  /// Validate a required field.

  String? _validateRequired(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 400,
        minHeight: 300,
      ),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            spreadRadius: 3,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Personal Identification Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.showEditButton)
                    MarkdownTooltip(
                      message: '**Edit** personal details',
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed:
                            _isLoading || _isSaving ? null : _showEditDialog,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                ..._buildLoadingRows()
              else
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataRow('Address:', _addressController.text),
                      const SizedBox(height: 8),
                      _buildDataRow('Phone:', _bestContactPhoneController.text),
                      const SizedBox(height: 8),
                      _buildDataRow('Alternative Phone:',
                          _alternativeContactNumberController.text),
                      const SizedBox(height: 8),
                      _buildDataRow('Email:', _emailController.text),
                      const SizedBox(height: 8),
                      _buildDataRow(
                          'Date of Birth:', _dateOfBirthController.text),
                      const SizedBox(height: 8),
                      _buildDataRow('Gender:', _genderController.text),
                    ],
                  ),
                ),
            ],
          ),
          if (_isLoading || _isSaving)
            Positioned.fill(
              child: Container(
                color:
                    Theme.of(context).cardTheme.color?.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(_isLoading
                          ? 'Loading profile data...'
                          : 'Saving profile data...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildLoadingRows() {
    return List.generate(
      6,
      (index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Container(
                height: 14,
                width: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build a data row for display mode.

  Widget _buildDataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              color: value.isEmpty
                  ? Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
