/// Diary tab for the health data app.
///
// Time-stamp: <Wednesday 2025-03-26 10:26:49 +1100 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
/// Authors: Kevin Wang

// ignore_for_file: use_build_context_synchronously
// This is a workaround for the use_build_context_synchronously lint.
// Kevin cannot figure out how to fix this.

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'models/appointment.dart';
import 'service.dart';
import 'widgets/appointment_dialog.dart';
import 'widgets/appointment_list.dart';
import 'widgets/month_year_selector.dart';

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

  // True while appointments are being loaded from the Pod.
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Default to no day selected so the whole month is listed; tapping a day
    // filters to that day, tapping it again clears back to the month.
    _selectedDay = null;
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final appointments = await DiaryService.loadAppointments();
    if (!mounted) return;
    setState(() {
      _appointments.clear();
      _appointments.addAll(appointments);
      _updateEvents();
      _loading = false;
    });
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

  // All appointments in the focused month, sorted by date.
  List<Appointment> _getAppointmentsForMonth() {
    final list = _appointments
        .where(
          (a) =>
              a.date.year == _focusedDay.year &&
              a.date.month == _focusedDay.month,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      // Toggle: tapping the already-selected day clears the filter so the
      // whole month is listed again.
      if (_selectedDay != null && isSameDay(_selectedDay, selectedDay)) {
        _selectedDay = null;
      } else {
        _selectedDay = selectedDay;
      }
      _focusedDay = focusedDay;
    });
  }

  void _addAppointment() {
    showDialog(
      context: context,
      builder: (dialogContext) => AppointmentDialog(
        onSave: (title, description, date) async {
          final appointment = Appointment(
            date: date,
            title: title,
            description: description,
            isPast: date.isBefore(DateTime.now()),
          );

          final success = await DiaryService.saveAppointment(
            dialogContext,
            appointment,
          );
          if (success && mounted) {
            setState(() {
              _appointments.add(appointment);
              _updateEvents();
            });
          }
          if (mounted) {
            Navigator.pop(dialogContext);
          }
        },
      ),
    );
  }

  void _editAppointment(Appointment original) {
    showDialog(
      context: context,
      builder: (dialogContext) => AppointmentDialog(
        initial: original,
        onSave: (title, description, date) async {
          final updated = Appointment(
            id: original.id,
            date: date,
            title: title,
            description: description,
            isPast: date.isBefore(DateTime.now()),
          );

          // Delete the original first (matched by its stable id), then save
          // the updated version under the same id. Keep the dialog open while
          // saving so its context stays valid for the Pod call.
          await DiaryService.deleteAppointment(original);
          final saved = await DiaryService.saveAppointment(
            dialogContext,
            updated,
          );

          if (mounted) Navigator.pop(dialogContext);
          if (mounted) setState(() => _loading = true);

          // Reload from the Pod so the list reflects the saved state.
          if (saved) {
            await _loadAppointments();
          } else if (mounted) {
            setState(() => _loading = false);
          }
        },
      ),
    );
  }

  void _deleteAppointment(Appointment appointment) {
    if (!appointment.isPast) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete Appointment'),
          content: Text(
            'Are you sure you want to delete "${appointment.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (mounted) setState(() => _loading = true);
                final success = await DiaryService.deleteAppointment(
                  appointment,
                );
                // Reload from the Pod so the list matches what was actually
                // deleted (more reliable than removing by object identity).
                if (success) {
                  await _loadAppointments();
                } else if (mounted) {
                  setState(() => _loading = false);
                }
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Add month and year selector.
          MonthYearSelector(
            focusedDay: _focusedDay,
            onMonthChanged: (m) => setState(() {
              _focusedDay = DateTime(_focusedDay.year, m, _focusedDay.day);
            }),
            onYearChanged: (y) => setState(() {
              _focusedDay = DateTime(y, _focusedDay.month, _focusedDay.day);
            }),
            onToday: _goToToday,
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: TableCalendar<Appointment>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                rowHeight: 38,
                daysOfWeekHeight: 20,
                headerVisible: false,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getAppointmentsForDay,
                onDaySelected: _onDaySelected,
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarStyle: const CalendarStyle(
                  markersMaxCount: 3,
                  markerSize: 6,
                  cellMargin: EdgeInsets.all(4),
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
            child: AppointmentList(
              loading: _loading,
              filtering: _selectedDay != null,
              monthName: DateFormat('MMMM').format(_focusedDay),
              selectedDay: _selectedDay,
              items: _selectedDay != null
                  ? _getAppointmentsForDay(_selectedDay!)
                  : _getAppointmentsForMonth(),
              onShowMonth: () => setState(() => _selectedDay = null),
              onDelete: _deleteAppointment,
              onEdit: _editAppointment,
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

  // The list below the calendar. Shows a busy indicator while loading; then,
  // when a day is selected, only that day's appointments; otherwise every
  // appointment in the focused month.
}
