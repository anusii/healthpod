/// Diary tab for the health data app.
///
// Time-stamp: <Wednesday 2025-03-26 10:26:49 +1100 Graham Williams>
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
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'models/appointment.dart';
import 'widgets/appointment_dialog.dart';

class DiaryTab extends StatefulWidget {
  const DiaryTab({super.key});

  @override
  State<DiaryTab> createState() => _DiaryTabState();
}

class _DiaryTabState extends State<DiaryTab> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Appointment>> _events = {};
  final List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAppointments();
  }

  void _loadAppointments() {
    // TODO: Load appointments from storage
    // For now, add some sample appointments
    final now = DateTime.now();
    _appointments.addAll([
      Appointment(
        date: now.subtract(const Duration(days: 1)),
        title: 'Past Appointment',
        description: 'This is a past appointment',
        isPast: true,
      ),
      Appointment(
        date: now.add(const Duration(days: 1)),
        title: 'Future Appointment',
        description: 'This is a future appointment',
        isPast: false,
      ),
    ]);
    _updateEvents();
  }

  void _updateEvents() {
    _events = {};
    for (var appointment in _appointments) {
      final date = DateTime(
        appointment.date.year,
        appointment.date.month,
        appointment.date.day,
      );
      if (_events[date] == null) {
        _events[date] = [];
      }
      _events[date]!.add(appointment);
    }
  }

  List<Appointment> _getAppointmentsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
  }

  void _addAppointment() {
    showDialog(
      context: context,
      builder: (context) => AppointmentDialog(
        onSave: (title, description, date) {
          setState(() {
            _appointments.add(
              Appointment(
                date: date,
                title: title,
                description: description,
                isPast: date.isBefore(DateTime.now()),
              ),
            );
            _updateEvents();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteAppointment(Appointment appointment) {
    if (!appointment.isPast) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Appointment'),
          content:
              Text('Are you sure you want to delete "${appointment.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _appointments.remove(appointment);
                  _updateEvents();
                });
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: TableCalendar<Appointment>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getAppointmentsForDay,
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarStyle: const CalendarStyle(
                  markersMaxCount: 3,
                  markerSize: 8,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: events.first.isPast
                                ? Colors.grey
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _getAppointmentsForDay(_selectedDay!).length,
              itemBuilder: (context, index) {
                final appointment =
                    _getAppointmentsForDay(_selectedDay!)[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(appointment.title),
                    subtitle: Text(appointment.description),
                    trailing: !appointment.isPast
                        ? IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteAppointment(appointment),
                          )
                        : null,
                    onTap: () => _showAppointmentDetails(appointment),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAppointment,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appointment.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${DateFormat('MMM dd, yyyy').format(appointment.date)}',
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${DateFormat('hh:mm a').format(appointment.date)}',
            ),
            const SizedBox(height: 8),
            Text('Description: ${appointment.description}'),
            const SizedBox(height: 8),
            Text(
              'Status: ${appointment.isPast ? 'Past' : 'Upcoming'}',
              style: TextStyle(
                color: appointment.isPast ? Colors.grey : Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
