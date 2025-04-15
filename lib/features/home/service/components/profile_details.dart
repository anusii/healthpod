/// Integrated profile details card widget.
//
// Time-stamp: <Sunday 2025-03-16 15:30:05 +1100>
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

import 'package:healthpod/constants/appointment.dart';
import 'package:healthpod/utils/construct_pod_path.dart';
import 'package:healthpod/utils/fetch_profile_data.dart';
import 'package:healthpod/utils/upload_json_to_pod.dart';

/// A widget that combines user avatar and name with personal identification details.
/// This integrated component displays all user profile information in a single card.

class ProfileDetails extends StatefulWidget {
  final bool isEditing;
  final bool showEditButton;
  final VoidCallback onEditPressed;
  final VoidCallback onDataChanged;

  const ProfileDetails({
    super.key,
    this.isEditing = false,
    this.showEditButton = true,
    required this.onEditPressed,
    required this.onDataChanged,
  });

  @override
  State<ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails> {
  late TextEditingController _nameController;
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
    _nameController = TextEditingController();
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
        _nameController.text = profileData['patientName'] ?? userName;
        _addressController.text = profileData['address'] ?? '';
        _bestContactPhoneController.text =
            profileData['bestContactPhone'] ?? '';
        _alternativeContactNumberController.text =
            profileData['alternativeContactNumber'] ?? '';
        _emailController.text = profileData['email'] ?? '';
        _dateOfBirthController.text = profileData['dateOfBirth'] ?? '';
        _genderController.text = profileData['gender'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      setState(() {
        _nameController.text = userName;
        _addressController.text = '';
        _bestContactPhoneController.text = '';
        _alternativeContactNumberController.text = '';
        _emailController.text = '';
        _dateOfBirthController.text = '';
        _genderController.text = '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) return;

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
        'patientName': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'bestContactPhone': _bestContactPhoneController.text.trim(),
        'alternativeContactNumber':
            _alternativeContactNumberController.text.trim(),
        'email': _emailController.text.trim(),
        'dateOfBirth': _dateOfBirthController.text.trim(),
        'gender': _genderController.text.trim(),
        'identifyAsIndigenous': _profileData['identifyAsIndigenous'] ?? false,
      };

      await _deleteExistingProfileFiles();

      final result = await _saveProfileDataUsingUploadUtil(updatedData);

      if (result != SolidFunctionCallStatus.success) {
        throw Exception('Failed to save profile data: $result');
      }

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

  Future<SolidFunctionCallStatus> _saveProfileDataUsingUploadUtil(
      Map<String, dynamic> updatedData) async {
    debugPrint('Saving profile using uploadJsonToPod utility...');

    try {
      final jsonData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': updatedData,
      };

      final result = await uploadJsonToPod(
        data: jsonData,
        targetPath: 'profile',
        fileNamePrefix: 'profile',
        context: context,
        onSuccess: () {
          debugPrint('Successfully uploaded profile data');
        },
      );

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

  bool _hasDataChanged() {
    return _nameController.text.trim() != (_profileData['patientName'] ?? '') ||
        _addressController.text.trim() != (_profileData['address'] ?? '') ||
        _bestContactPhoneController.text.trim() !=
            (_profileData['bestContactPhone'] ?? '') ||
        _alternativeContactNumberController.text.trim() !=
            (_profileData['alternativeContactNumber'] ?? '') ||
        _emailController.text.trim() != (_profileData['email'] ?? '') ||
        _dateOfBirthController.text.trim() !=
            (_profileData['dateOfBirth'] ?? '') ||
        _genderController.text.trim() != (_profileData['gender'] ?? '');
  }

  Future<void> _deleteExistingProfileFiles() async {
    try {
      final dirUrl = await getDirUrl(constructPodPath('profile', ''));
      debugPrint(
          'Looking for profile files to delete in: ${constructPodPath('profile', '')}');

      final resources = await getResourcesInContainer(dirUrl);
      debugPrint('Files in profile directory: ${resources.files}');

      final profileFiles = resources.files
          .where((file) =>
              file.startsWith('profile_') && file.endsWith('.json.enc.ttl'))
          .toList();

      if (profileFiles.isEmpty) {
        debugPrint('No existing profile files to clean up');
        return;
      }

      profileFiles.sort((a, b) => b.compareTo(a));

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
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _bestContactPhoneController.dispose();
    _alternativeContactNumberController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProfileDetails oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isEditing && !widget.isEditing) {
      _saveProfileData();
    }
  }

  Future<void> _showEditDialog() async {
    final tempNameController =
        TextEditingController(text: _nameController.text);
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
          title: const Text('Edit Profile Details'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Name'),
                  TextFormField(
                    controller: tempNameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    validator: _validateRequired,
                  ),
                  const SizedBox(height: 12),
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
                  const Text('Best Contact Phone'),
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
                  const Text('Alternative Contact Number'),
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

    if (result == true) {
      setState(() {
        _nameController.text = tempNameController.text;
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

    tempNameController.dispose();
    tempAddressController.dispose();
    tempBestContactPhoneController.dispose();
    tempAlternativeContactNumberController.dispose();
    tempEmailController.dispose();
    tempDateOfBirthController.dispose();
    tempGenderController.dispose();
  }

  DateTime _parseDateOrDefault(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return DateTime.now().subtract(const Duration(days: 365 * 30));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;

    final cleanedValue = value.replaceAll(RegExp(r'[\s\-()]'), '');
    final australianPhoneRegex = RegExp(r'^(\+61|0)[0-9]{9,10}$');
    final internationalPhoneRegex = RegExp(r'^\+[0-9]{10,14}$');

    if (!australianPhoneRegex.hasMatch(cleanedValue) &&
        !internationalPhoneRegex.hasMatch(cleanedValue)) {
      return 'Enter a valid phone number (e.g. +61 4 1234 5678 or 04 1234 5678)';
    }
    return null;
  }

  String? _validateRequired(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 400,
      ),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
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
                    'Profile Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.showEditButton)
                    MarkdownTooltip(
                      message: '''
                      
                      **Edit Profile Details**
                      
                      Click to modify your personal information:
                      
                      - Name
                      - Address
                      - Contact information
                      - Personal details
                      
                      Your data is securely stored in your personal pod.
                      
                      ''',
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed:
                            _isLoading || _isSaving ? null : _showEditDialog,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Avatar and Name Section
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    // User avatar with lock icon
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(
                              'assets/images/sample_avatar_image.png'),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock,
                              color: theme.colorScheme.onTertiary,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Display user name
                    Expanded(
                      child: Text(
                        _nameController.text,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Notification bell with notification count badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications,
                          size: 28,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        if (notificationCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$notificationCount',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onError,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Personal Identification Details
              if (_isLoading)
                ..._buildLoadingRows()
              else
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDataRow('Address:', _addressController.text),
                      const SizedBox(height: 6),
                      _buildDataRow('Best Contact Phone:',
                          _bestContactPhoneController.text),
                      const SizedBox(height: 6),
                      _buildDataRow('Alternative Contact Number:',
                          _alternativeContactNumberController.text),
                      const SizedBox(height: 6),
                      _buildDataRow('Email:', _emailController.text),
                      const SizedBox(height: 6),
                      _buildDataRow(
                          'Date of Birth:', _dateOfBirthController.text),
                      const SizedBox(height: 6),
                      _buildDataRow('Gender:', _genderController.text),
                    ],
                  ),
                ),
            ],
          ),
          if (_isLoading || _isSaving)
            Positioned.fill(
              child: Container(
                color: theme.cardTheme.color?.withOpacity(0.7),
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
                      .withOpacity(0.2),
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
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                      .withOpacity(0.5)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
