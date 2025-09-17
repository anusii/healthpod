/// Widget for displaying appointment information.
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
/// Authors: Zheyuan Xu, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:healthpod/features/diary/models/appointment.dart';

/// Widget that displays appointment details in a consistent format.

class AppointmentInfoDisplay extends StatelessWidget {
  const AppointmentInfoDisplay({
    super.key,
    required this.appointment,
    required this.subtitle,
  });

  final Appointment appointment;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          'Date:',
          'Monday, ${DateFormat('d MMMM').format(appointment.date)}',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Time:',
          DateFormat('h:mm a').format(appointment.date),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Description:', appointment.description),
      ],
    );
  }

  /// Helper method to build consistent information rows.
  ///
  /// Creates a row with a label and value, maintaining consistent styling
  /// and layout across the display.

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
