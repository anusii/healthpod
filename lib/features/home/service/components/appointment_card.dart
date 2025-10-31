/// Combined appointment card widget.
//
// Time-stamp: <Monday 2025-05-12 16:12:15 +1000 Graham Williams>
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
/// Authors: Zheyuan Xu, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/features/diary/models/appointment.dart';
import 'package:healthpod/features/diary/service.dart';
import 'package:healthpod/features/home/service/components/dialogs/appointment_management_dialog.dart';
import 'package:healthpod/features/home/service/components/widgets/appointment_info_display.dart';
import 'package:healthpod/features/home/service/components/widgets/transport_info_widget.dart';
import 'package:healthpod/theme/card_style.dart';

/// A widget that displays both next appointment details and appointment summary.
///
/// This component combines the functionality of showing the next appointment
/// details and the total number of upcoming appointments in a single card.

class AppointmentCard extends StatefulWidget {
  const AppointmentCard({super.key});

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  // Card title displayed at the top of the component.

  String title = 'Medical Appointments';

  // Subtitle shown when displaying next appointment details.

  String subtitle = 'Next Appointment Details';

  // Date and time of the next appointment.

  DateTime appointmentDate = DateTime(2023, 3, 13, 14, 30);

  // Location where the appointment will take place.

  String location = 'Gurriny Yealamucka';

  // Flag indicating if transport assistance is needed.

  bool needsTransport = true;

  // Phone number to call for transport assistance.

  String transportPhone = '(01) 2345 6789';

  // Additional note about transport service availability.

  String transportNote = '(only during office hours)';

  // Flag indicating if clinic bus service is available.

  bool useClinicBus = true;

  // List of all upcoming appointments with their details.

  List<Appointment> appointments = [];

  // Flag indicating if appointments are currently loading.

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    if (!mounted) return;
    final loadedAppointments = await DiaryService.loadAppointments(context);

    if (mounted) {
      setState(() {
        // Filter out past appointments and sort by date.

        appointments = loadedAppointments
            .where((appointment) => !appointment.isPast)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Opens a dialog to manage all appointments.

  void _manageAppointments() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppointmentManagementDialog(
          appointments: appointments,
          onAppointmentsUpdated: (updatedAppointments) {
            setState(() {
              appointments = updatedAppointments;
              if (appointments.isNotEmpty) {
                final nextAppointment = appointments.first;
                appointmentDate = nextAppointment.date;
                location = nextAppointment.description;
              }
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400, minHeight: 300),
      padding: const EdgeInsets.all(16.0),
      decoration: getHomeCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              MarkdownTooltip(
                message: '**Manage** your appointments',
                child: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _manageAppointments,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            appointments.isEmpty
                ? 'No current appointments recorded.'
                : appointments.length == 1
                    ? 'Only one appointment in the future'
                    : '${appointments.length} appointments scheduled',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (appointments.isNotEmpty) ...[
            AppointmentInfoDisplay(
              appointment: appointments.first,
              subtitle: subtitle,
            ),
            const SizedBox(height: 16),
            TransportInfoWidget(
              useClinicBus: useClinicBus,
              needsTransport: needsTransport,
              transportPhone: transportPhone,
              transportNote: transportNote,
            ),
          ],
        ],
      ),
    );
  }
}
