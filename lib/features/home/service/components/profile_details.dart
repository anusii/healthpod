/// Integrated profile details card widget.
//
// Time-stamp: <Thursday 2025-05-08 12:15:21 +1000 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/features/home/service/components/profile/profile_data_manager.dart';
import 'package:healthpod/features/home/service/components/profile/profile_edit_dialog.dart';
import 'package:healthpod/features/home/service/components/profile/profile_photo_manager.dart';
import 'package:healthpod/features/home/service/components/profile/profile_ui_components.dart';
import 'package:healthpod/theme/card_style.dart';

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

  late final Map<TextEditingController, String> _controllers;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingPhoto = true;
  final bool _isUploadingPhoto = false;
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
    _controllers = {
      TextEditingController(): 'name',
      TextEditingController(): 'address',
      TextEditingController(): 'bestContactPhone',
      TextEditingController(): 'bestContactEmail',
      TextEditingController(): 'emergencyName',
      TextEditingController(): 'emergencyPhone',
      TextEditingController(): 'alternativeContactNumber',
      TextEditingController(): 'email',
      TextEditingController(): 'dateOfBirth',
      TextEditingController(): 'gender',
    };
  }

  /// Load profile data from the pod and update state.

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = await ProfileDataManager.loadProfileData(context);
      _profileData = profileData;

      setState(() {
        // Populate controllers with profile data or defaults.

        _controllers.forEach((controller, fieldName) {
          String value = profileData[fieldName] ?? '';
          if (fieldName == 'name' && value.isEmpty) {
            value = ProfileDataManager.getDefaultName();
          }
          controller.text = value;
        });
        _isLoading = false;
      });
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
      final photoProvider = await ProfilePhotoManager.loadProfilePhoto(context);
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
    // Get the name controller.

    final nameController = _controllers.keys.firstWhere(
      (controller) => _controllers[controller] == 'name',
    );

    // Validate only the name field.

    if (nameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Name is required')));
      }
      return;
    }

    // Skip if no changes detected.

    if (!ProfileDataManager.hasDataChanged(_controllers, _profileData)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No changes detected')));
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare data for saving.

      final updatedData = <String, dynamic>{};
      _controllers.forEach((controller, fieldName) {
        updatedData[fieldName] = controller.text.trim();
      });

      // Save using ProfileDataManager.

      final result = await ProfileDataManager.saveProfileData(
        updatedData,
        context,
      );

      if (result != SolidFunctionCallStatus.success) {
        throw Exception('Failed to save profile data: $result');
      }

      // Update local data and notify parent.

      _profileData = updatedData;
      widget.onDataChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String userFriendlyMessage = 'Error updating profile';

        // Provide more specific error messages for common issues.

        if (e.toString().contains('pathSeparator')) {
          userFriendlyMessage =
              'Profile save failed due to platform compatibility issue. Please try again.';
        } else if (e.toString().contains('not logged in')) {
          userFriendlyMessage = 'Please log in to save your profile';
        } else if (e.toString().contains('network')) {
          userFriendlyMessage =
              'Network error while saving profile. Check your connection and try again.';
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

  @override
  void dispose() {
    // Clean up all controllers to prevent memory leaks.

    for (var controller in _controllers.keys) {
      controller.dispose();
    }
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
    // Prepare current data for the dialog.

    final currentData = <String, String>{};
    _controllers.forEach((controller, fieldName) {
      currentData[fieldName] = controller.text;
    });

    // Show the edit dialog.

    final updatedData = await ProfileEditDialog.show(context, currentData);

    // If user saved changes, update controllers and save data.

    if (updatedData != null) {
      setState(() {
        _controllers.forEach((controller, fieldName) {
          controller.text = updatedData[fieldName] ?? '';
        });
      });

      await _saveProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the name controller for display purposes.

    final nameController = _controllers.keys.firstWhere(
      (controller) => _controllers[controller] == 'name',
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(16.0),
      decoration: getHomeCardDecoration(context),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title and edit button row.
              ProfileUIComponents.buildTitleRow(
                context,
                widget.showEditButton,
                _isLoading,
                _isSaving,
                _showEditDialog,
              ),

              const SizedBox(height: 12),

              // Avatar and Name Section
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ProfileUIComponents.buildProfileHeader(
                  context,
                  _profilePhoto,
                  nameController.text,
                  _isLoadingPhoto,
                  _isUploadingPhoto,
                  () => _showPhotoOptionsDialog(),
                ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Personal Identification Details section.
              if (_isLoading)
                ...ProfileUIComponents.buildLoadingRows(context)
              else
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: _buildDataRows(),
                  ),
                ),
            ],
          ),

          // Loading/saving overlay.
          if (_isLoading || _isSaving)
            ProfileUIComponents.buildLoadingOverlay(
              context,
              _isLoading,
              _isSaving,
            ),
        ],
      ),
    );
  }

  /// Builds data rows for all profile fields.

  List<Widget> _buildDataRows() {
    final fieldLabels = {
      'address': 'Address:',
      'bestContactPhone': 'Phone:',
      'emergencyName': 'Emergency Name:',
      'emergencyPhone': 'Emergency Phone:',
      'alternativeContactNumber': 'Alternative:',
      'email': 'Email:',
      'dateOfBirth': 'Date of Birth:',
      'gender': 'Gender:',
    };

    final rows = <Widget>[];
    for (final entry in _controllers.entries) {
      final controller = entry.key;
      final fieldName = entry.value;
      final label = fieldLabels[fieldName];
      if (label != null) {
        rows.add(
          ProfileUIComponents.buildDataRow(context, label, controller.text),
        );
        rows.add(const SizedBox(height: 6));
      }
    }

    // Remove the last SizedBox.
    if (rows.isNotEmpty) {
      rows.removeLast();
    }

    return rows;
  }

  /// Shows photo options dialog using ProfilePhotoManager.

  Future<void> _showPhotoOptionsDialog() async {
    final nameController = _controllers.keys.firstWhere(
      (controller) => _controllers[controller] == 'name',
    );

    await ProfilePhotoManager.showPhotoOptionsDialog(
      context,
      _profilePhoto,
      nameController.text,
      (photo) {
        setState(() {
          _profilePhoto = photo;
        });
      },
      widget.onDataChanged,
      _isLoading,
      _isSaving,
      _isLoadingPhoto,
      _isUploadingPhoto,
    );
  }
}
