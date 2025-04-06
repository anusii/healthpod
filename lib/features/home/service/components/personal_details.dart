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

import 'package:healthpod/utils/fetch_profile_data.dart';
import 'package:healthpod/utils/save_response_pod.dart';

/// A widget that displays detailed personal identification information clearly and concisely.
///
/// This widget allows users to verify and update their personal details easily.

class PersonalDetails extends StatefulWidget {
  final bool isEditing;
  final bool showEditButton;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDataChanged;

  const PersonalDetails({
    super.key,
    this.isEditing = false,
    this.showEditButton = false,
    this.onEditPressed,
    this.onDataChanged,
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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialise with empty values, will update after fetching.

    _addressController = TextEditingController();
    _bestContactPhoneController = TextEditingController();
    _alternativeContactNumberController = TextEditingController();
    _emailController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _genderController = TextEditingController();

    _loadProfileData();
  }

  /// Loads profile data from POD and updates controllers.

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = await fetchProfileData(context);

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
      // Show error to user if needed.
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Saves updated profile data to POD.

  Future<void> _saveProfileData() async {
    if (!widget.isEditing) return;

    try {
      final updatedData = {
        'address': _addressController.text,
        'bestContactPhone': _bestContactPhoneController.text,
        'alternativeContactNumber': _alternativeContactNumberController.text,
        'email': _emailController.text,
        'dateOfBirth': _dateOfBirthController.text,
        'gender': _genderController.text,
        'identifyAsIndigenous': false,
      };

      await saveResponseToPod(
        context: context,
        responses: updatedData,
        podPath: '/profile',
        filePrefix: 'profile',
      );

      if (widget.onDataChanged != null) {
        widget.onDataChanged!();
      }

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
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.minHeight,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: Column(
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
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: widget.onEditPressed,
                                tooltip: 'Edit Profile',
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLabeledRow(
                          'Address:',
                          widget.isEditing
                              ? TextField(
                                  controller: _addressController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                )
                              : Text(_addressController.text),
                        ),
                        const SizedBox(height: 8),
                        _buildLabeledRow(
                          'Best Contact Phone:',
                          widget.isEditing
                              ? TextField(
                                  controller: _bestContactPhoneController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                )
                              : Text(_bestContactPhoneController.text),
                        ),
                        const SizedBox(height: 8),
                        _buildLabeledRow(
                          'Alternative Contact Number:',
                          widget.isEditing
                              ? TextField(
                                  controller:
                                      _alternativeContactNumberController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                )
                              : Text(_alternativeContactNumberController.text),
                        ),
                        const SizedBox(height: 8),
                        _buildLabeledRow(
                          'Email:',
                          widget.isEditing
                              ? TextField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                )
                              : Text(_emailController.text),
                        ),
                        const SizedBox(height: 8),
                        _buildLabeledRow(
                          'Date of Birth:',
                          widget.isEditing
                              ? TextField(
                                  controller: _dateOfBirthController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                )
                              : Text(_dateOfBirthController.text),
                        ),
                        const SizedBox(height: 8),
                        _buildLabeledRow(
                          'Gender:',
                          widget.isEditing
                              ? TextField(
                                  controller: _genderController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                )
                              : Text(_genderController.text),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Helper method to build a row with a bold label and regular text or input field.

  Widget _buildLabeledRow(String label, Widget value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
          child: value,
        ),
      ],
    );
  }
}
