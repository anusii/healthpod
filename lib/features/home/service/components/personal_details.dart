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

/// A widget that displays detailed personal identification information clearly and concisely.
///
/// This widget allows users to verify and update their personal details easily.

class PersonalDetails extends StatefulWidget {
  const PersonalDetails({super.key});

  @override
  State<PersonalDetails> createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  final String address = '14 Example Street, Yarrabah QLD';
  final String bestContactPhone = '0400 123 456';
  final String alternativeContactNumber = '(07) 3333 3333';
  final String email = 'riley-breugel@yarrabah.net';
  final String dateOfBirth = '1970-07-24';
  final String gender = 'Female';

  bool? identifyAsIndigenous = false;

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
      child: LayoutBuilder(
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
                  const Text(
                    'Personal Identification Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLabeledRow('Address:', address),
                  const SizedBox(height: 8),
                  _buildLabeledRow('Best Contact Phone:', bestContactPhone),
                  const SizedBox(height: 8),
                  _buildLabeledRow(
                      'Alternative Contact Number:', alternativeContactNumber),
                  const SizedBox(height: 8),
                  _buildLabeledRow('Email:', email),
                  const SizedBox(height: 8),
                  _buildLabeledRow('Date of Birth:', dateOfBirth),
                  const SizedBox(height: 8),
                  _buildLabeledRow('Gender:', gender),
                  const SizedBox(height: 12),
                  const Text(
                    'Identify as Aboriginal and/or Torres Strait Islander:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: identifyAsIndigenous,
                          onChanged: (bool? newValue) {
                            setState(() {
                              identifyAsIndigenous = newValue;
                            });
                          },
                        ),
                        const Text('Yes'),
                        const SizedBox(width: 16),
                        Radio<bool>(
                          value: false,
                          groupValue: identifyAsIndigenous,
                          onChanged: (bool? newValue) {
                            setState(() {
                              identifyAsIndigenous = newValue;
                            });
                          },
                        ),
                        const Text('No'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Helper method to build a row with a bold label and regular text.
  Widget _buildLabeledRow(String label, String value) {
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
          child: Text(
            value,
            style: const TextStyle(
              height: 1.2,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
