/// Integrated profile details card widget.
//
// Time-stamp: <Thursday 2025-05-08 12:15:21 +1000 Graham Williams>
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
/// Authors: Ashley Tang

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/appointment.dart';
import 'package:healthpod/theme/card_style.dart';

import 'package:healthpod/utils/fetch_profile_data.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';
import 'package:healthpod/utils/is_logged_in.dart';
import 'package:healthpod/utils/profile_photo_handler.dart';

/// A widget that combines user avatar and name with personal identification details.
/// This integrated component displays all user profile information in a single card.
///
/// Includes functionality for viewing and editing user profile data, which is
/// persisted in the user's Solid Pod with encryption.

class ProfileDetails extends StatefulWidget {
  /// Whether the widget is in editing mode.

  final bool isEditing;

  /// Whether to show the edit button.

  final bool showEditButton;

  /// Callback when edit button is pressed.

  final VoidCallback onEditPressed;

  /// Callback when data is changed and saved.

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
  // Controllers for the editable fields.

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _bestContactPhoneController;
  late TextEditingController _bestContactEmailController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _alternativeContactNumberController;
  late TextEditingController _emailController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _genderController;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingPhoto = true;
  bool _isUploadingPhoto = false;
  ImageProvider? _profilePhoto;

  // Holds full profile data.

  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfileData();
    _loadProfilePhoto();
  }

  /// Initialise all text controllers.

  void _initializeControllers() {
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _bestContactPhoneController = TextEditingController();
    _bestContactEmailController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _alternativeContactNumberController = TextEditingController();
    _emailController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _genderController = TextEditingController();
  }

  /// Load profile data from the pod and update state.

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First check if user is logged in.

      final loggedIn = await isLoggedIn();

      if (loggedIn) {
        if (!mounted) return;
        // Fetch profile data using utility function.

        final profileData = await fetchProfileData(context);
        _profileData = profileData;

        setState(() {
          // Populate controllers with profile data or defaults.

          _nameController.text = profileData['name'] ?? userName;
          _addressController.text = profileData['address'] ?? '';
          _bestContactPhoneController.text =
              profileData['bestContactPhone'] ?? '';
          _bestContactEmailController.text =
              profileData['bestContactEmail'] ?? '';
          _emergencyNameController.text = profileData['emergencyName'] ?? '';
          _emergencyPhoneController.text = profileData['emergencyPhone'] ?? '';
          _alternativeContactNumberController.text =
              profileData['alternativeContactNumber'] ?? '';
          _emailController.text = profileData['email'] ?? '';
          _dateOfBirthController.text = profileData['dateOfBirth'] ?? '';
          _genderController.text = profileData['gender'] ?? '';
          _isLoading = false;
        });
      } else {
        // User not logged in, just use default values.

        setState(() {
          _nameController.text = userName;
          _addressController.text = '';
          _bestContactPhoneController.text = '';
          _bestContactEmailController.text = '';
          _emergencyNameController.text = '';
          _emergencyPhoneController.text = '';
          _alternativeContactNumberController.text = '';
          _emailController.text = '';
          _dateOfBirthController.text = '';
          _genderController.text = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load profile photo from pod.

  Future<void> _loadProfilePhoto() async {
    setState(() {
      _isLoadingPhoto = true;
    });

    try {
      final photoProvider = await ProfilePhotoHandler.getProfilePhoto(context);
      setState(() {
        _profilePhoto = photoProvider;
        _isLoadingPhoto = false;
      });
    } catch (e) {
      setState(() {
        _profilePhoto = null;
        _isLoadingPhoto = false;
      });
    }
  }

  /// Save profile data to the pod.

  Future<void> _saveProfileData() async {
    // Validate only the name field.

    if (_nameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name is required')),
        );
      }
      return;
    }

    // Skip if no changes detected.

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
      // Prepare data for saving.

      final updatedData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'bestContactPhone': _bestContactPhoneController.text.trim(),
        'bestContactEmail': _bestContactEmailController.text.trim(),
        'emergencyName': _emergencyNameController.text.trim(),
        'emergencyPhone': _emergencyPhoneController.text.trim(),
        'alternativeContactNumber':
            _alternativeContactNumberController.text.trim(),
        'email': _emailController.text.trim(),
        'dateOfBirth': _dateOfBirthController.text.trim(),
        'gender': _genderController.text.trim(),
      };

      // Clean up existing files before saving new ones.

      await _deleteExistingProfileFiles();

      // Save the data using the uploadJsonToPod utility.

      final result = await _saveProfileDataUsingUploadUtil(updatedData);

      if (result != SolidFunctionCallStatus.success) {
        throw Exception('Failed to save profile data: $result');
      }

      // Update local data and notify parent.

      _profileData = updatedData;
      widget.onDataChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        String userFriendlyMessage = 'Error updating profile';
        
        // Provide more specific error messages for common issues
        if (e.toString().contains('pathSeparator')) {
          userFriendlyMessage = 'Profile save failed due to platform compatibility issue. Please try again.';
        } else if (e.toString().contains('not logged in')) {
          userFriendlyMessage = 'Please log in to save your profile';
        } else if (e.toString().contains('network')) {
          userFriendlyMessage = 'Network error while saving profile. Check your connection and try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _saveProfileData(),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Save profile data using direct writePod call to avoid file system operations
  /// that don't work on web platforms.

  Future<SolidFunctionCallStatus> _saveProfileDataUsingUploadUtil(
      Map<String, dynamic> updatedData) async {
    try {
      // Create JSON data structure matching other successful implementations.

      final profileData = {
        'timestamp': DateTime.now().toIso8601String(),
        'responses': updatedData,
      };

      // Create filename with timestamp.

      final timestamp = formatTimestampForFilename(DateTime.now());
      final filename = 'profile_$timestamp.json.enc.ttl';

      // Use direct writePod call with relative path to match read operations.
      // Note: fetchProfileData uses full path for reading, so we need consistency.

      final result = await writePod(
        'profile/$filename',
        json.encode(profileData),
        context,
        const Text('Saving profile data'),
        encrypted: true,
      );

      return result;
    } on Exception catch (e) {
      debugPrint('Exception saving profile: $e');
      return SolidFunctionCallStatus.fail;
    } catch (e) {
      debugPrint('Unexpected error saving profile: $e');
      return SolidFunctionCallStatus.fail;
    }
  }

  /// Check if any profile data has been changed compared to stored data.

  bool _hasDataChanged() {
    return _nameController.text.trim() != (_profileData['name'] ?? '') ||
        _addressController.text.trim() != (_profileData['address'] ?? '') ||
        _bestContactPhoneController.text.trim() !=
            (_profileData['bestContactPhone'] ?? '') ||
        _bestContactEmailController.text.trim() !=
            (_profileData['bestContactEmail'] ?? '') ||
        _emergencyNameController.text.trim() !=
            (_profileData['emergencyName'] ?? '') ||
        _emergencyPhoneController.text.trim() !=
            (_profileData['emergencyPhone'] ?? '') ||
        _alternativeContactNumberController.text.trim() !=
            (_profileData['alternativeContactNumber'] ?? '') ||
        _emailController.text.trim() != (_profileData['email'] ?? '') ||
        _dateOfBirthController.text.trim() !=
            (_profileData['dateOfBirth'] ?? '') ||
        _genderController.text.trim() != (_profileData['gender'] ?? '');
  }

  /// Delete existing profile files to prevent duplication.
  ///
  /// This helps maintain a clean pod structure with only the latest profile data.

  Future<void> _deleteExistingProfileFiles() async {
    try {
      // Use full path for directory operations (SolidPod web bug workaround).

      final dirUrl = await getDirUrl('healthpod/data/profile');

      final resources = await getResourcesInContainer(dirUrl);

      // Find all profile files with the expected extension.

      final profileFiles = resources.files
          .where((file) =>
              file.startsWith('profile_') && file.endsWith('.json.enc.ttl'))
          .toList();

      if (profileFiles.isEmpty) {
        return;
      }

      // Sort to find the most recent file.

      profileFiles.sort((a, b) => b.compareTo(a));

      // Delete all profile files to create a clean slate.

      for (final file in profileFiles) {
        final filePath = 'profile/$file';
        await deleteFile(filePath);
      }
    } catch (e) {
      //debugPrint('Error cleaning up profile files: $e');
    }
  }

  @override
  void dispose() {
    // Clean up all controllers to prevent memory leaks.

    _nameController.dispose();
    _addressController.dispose();
    _bestContactPhoneController.dispose();
    _bestContactEmailController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _alternativeContactNumberController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProfileDetails oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Save data when exiting edit mode.

    if (oldWidget.isEditing && !widget.isEditing) {
      _saveProfileData();
    }

    // Reload photo if widget is updated.

    if (oldWidget != widget) {
      _loadProfilePhoto();
    }
  }

  /// Show dialog for editing profile details.

  Future<void> _showEditDialog() async {
    // Create temporary controllers for dialog fields.

    final tempNameController =
        TextEditingController(text: _nameController.text);
    final tempAddressController =
        TextEditingController(text: _addressController.text);
    final tempBestContactPhoneController =
        TextEditingController(text: _bestContactPhoneController.text);
    final tempBestContactEmailController =
        TextEditingController(text: _bestContactEmailController.text);
    final tempEmergencyNameController =
        TextEditingController(text: _emergencyNameController.text);
    final tempEmergencyPhoneController =
        TextEditingController(text: _emergencyPhoneController.text);
    final tempAlternativeContactNumberController =
        TextEditingController(text: _alternativeContactNumberController.text);
    final tempEmailController =
        TextEditingController(text: _emailController.text);
    final tempDateOfBirthController =
        TextEditingController(text: _dateOfBirthController.text);
    final tempGenderController =
        TextEditingController(text: _genderController.text);

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
                  const Text('Name'),
                  TextFormField(
                    controller: tempNameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
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
                  const Text('Emergency Name'),
                  TextFormField(
                    controller: tempEmergencyNameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      controller: tempEmergencyPhoneController,
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
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            // Show date picker for selecting date of birth.

                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _parseDateOrDefault(
                                  tempDateOfBirthController.text),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              tempDateOfBirthController.text =
                                  _formatDate(picked);
                            }
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: tempDateOfBirthController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              keyboardType: TextInputType.datetime,
                            ),
                          ),
                        ),
                      ),
                      if (tempDateOfBirthController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            tempDateOfBirthController.clear();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Gender'),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: tempGenderController.text.isEmpty
                              ? null
                              : tempGenderController.text,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: null, child: Text('Select gender')),
                            DropdownMenuItem(
                                value: 'Male', child: Text('Male')),
                            DropdownMenuItem(
                                value: 'Female', child: Text('Female')),
                            DropdownMenuItem(
                                value: 'Non-binary', child: Text('Non-binary')),
                            DropdownMenuItem(
                                value: 'Prefer not to say',
                                child: Text('Prefer not to say')),
                          ],
                          onChanged: (value) {
                            tempGenderController.text = value ?? '';
                          },
                        ),
                      ),
                      if (tempGenderController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            tempGenderController.clear();
                          },
                        ),
                    ],
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

    // If user confirmed, update main controllers and save data.

    if (result == true) {
      setState(() {
        _nameController.text = tempNameController.text;
        _addressController.text = tempAddressController.text;
        _bestContactPhoneController.text = tempBestContactPhoneController.text;
        _bestContactEmailController.text = tempBestContactEmailController.text;
        _emergencyNameController.text = tempEmergencyNameController.text;
        _emergencyPhoneController.text = tempEmergencyPhoneController.text;
        _alternativeContactNumberController.text =
            tempAlternativeContactNumberController.text;
        _emailController.text = tempEmailController.text;
        _dateOfBirthController.text = tempDateOfBirthController.text;
        _genderController.text = tempGenderController.text;
      });

      await _saveProfileData();
    }

    // Clean up temporary controllers.

    tempNameController.dispose();
    tempAddressController.dispose();
    tempBestContactPhoneController.dispose();
    tempBestContactEmailController.dispose();
    tempEmergencyNameController.dispose();
    tempEmergencyPhoneController.dispose();
    tempAlternativeContactNumberController.dispose();
    tempEmailController.dispose();
    tempDateOfBirthController.dispose();
    tempGenderController.dispose();
  }

  /// Parse a date string into DateTime or return a default date.

  DateTime _parseDateOrDefault(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (e) {
      //debugPrint('Error parsing date: $e');
    }
    // Return a default date (30 years ago)
    return DateTime.now().subtract(const Duration(days: 365 * 30));
  }

  /// Format a DateTime as YYYY-MM-DD.

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Validate email format - optional field.

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  /// Validate phone number format - optional field.

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;

    // Clean the input by removing spaces, dashes and parentheses.

    final cleanedValue = value.replaceAll(RegExp(r'[\s\-()]'), '');
    final australianPhoneRegex = RegExp(r'^(\+61|0)[0-9]{9,10}$');
    final internationalPhoneRegex = RegExp(r'^\+[0-9]{10,14}$');

    if (!australianPhoneRegex.hasMatch(cleanedValue) &&
        !internationalPhoneRegex.hasMatch(cleanedValue)) {
      return 'Enter a valid phone number (e.g. +61 4 1234 5678 or 04 1234 5678)';
    }
    return null;
  }

  /// Show dialog for selecting profile photo options.

  Future<void> _showPhotoOptionsDialog() async {
    if (_isLoading || _isSaving || _isLoadingPhoto || _isUploadingPhoto) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profile Photo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display current photo or avatar.

                SizedBox(
                  height: 100,
                  width: 100,
                  child: ProfilePhotoHandler.buildProfileAvatar(
                    context: context,
                    photo: _profilePhoto,
                    name: _nameController.text,
                    radius: 50,
                  ),
                ),
                const SizedBox(height: 20),
                // Photo action buttons.

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _handlePhotoUpload();
                      },
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Upload New'),
                    ),
                    if (_profilePhoto != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _handlePhotoDelete();
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Remove'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor:
                              Theme.of(context).colorScheme.onError,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Handle photo upload process.

  Future<void> _handlePhotoUpload() async {
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final imageFile = await ProfilePhotoHandler.pickProfilePhoto();

      if (imageFile != null && mounted) {
        final success = await ProfilePhotoHandler.uploadProfilePhoto(
          imageFile,
          context,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Cleanup old photos.

          await ProfilePhotoHandler.cleanupOldProfilePhotos(context);

          // Reload the photo.

          await _loadProfilePhoto();

          // Notify parent of data change.

          widget.onDataChanged();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  /// Handle photo deletion.

  Future<void> _handlePhotoDelete() async {
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      if (mounted) {
        final success = await ProfilePhotoHandler.deleteProfilePhoto(context);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo removed'),
              backgroundColor: Colors.green,
            ),
          );

          // Reset the photo.

          setState(() {
            _profilePhoto = null;
          });

          // Notify parent of data change.

          widget.onDataChanged();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const int notificationCount = 2;

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 400,
      ),
      padding: const EdgeInsets.all(16.0),
      decoration: getHomeCardDecoration(context),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title and edit button row.

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
                    // User avatar with lock icon.

                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Profile photo with loading indicator or initials.

                        ProfilePhotoHandler.buildProfileAvatar(
                          context: context,
                          photo: _profilePhoto,
                          name: _nameController.text,
                          radius: 24,
                          isLoading: _isLoadingPhoto || _isUploadingPhoto,
                          onTap: _showPhotoOptionsDialog,
                        ),

                        // Security lock indicator.
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

                        // Edit photo indicator.

                        if (!_isLoadingPhoto && !_isUploadingPhoto)
                          Positioned(
                            top: -2,
                            left: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: theme.colorScheme.primary,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Display user name.

                    Expanded(
                      child: Text(
                        _nameController.text,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Notification bell with notification count badge.

                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications,
                          size: 28,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        // Notification counter badge.

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

              // Personal Identification Details section.

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
                      _buildDataRow('Phone:', _bestContactPhoneController.text),
                      const SizedBox(height: 6),
                      _buildDataRow(
                          'Emergency Name:', _emergencyNameController.text),
                      const SizedBox(height: 6),
                      _buildDataRow(
                          'Emergency Phone:', _emergencyPhoneController.text),
                      const SizedBox(height: 6),
                      _buildDataRow('Alternative:',
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
          // Loading/saving overlay.

          if (_isLoading || _isSaving)
            Positioned.fill(
              child: Container(
                color: theme.cardTheme.color?.withValues(alpha: 0.7),
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

  /// Create placeholder loading rows during data fetch.

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

  /// Build a single data row with label and value.

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
