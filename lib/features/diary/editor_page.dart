import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthpod/features/diary/models/appointment.dart';
import 'package:healthpod/features/diary/service.dart';

class AppointmentEditorPage extends StatefulWidget {
  const AppointmentEditorPage({super.key});

  @override
  State<AppointmentEditorPage> createState() => _AppointmentEditorPageState();
}

class _AppointmentEditorPageState extends State<AppointmentEditorPage> {
  List<Appointment> _appointments = [];
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
    final appointments = await DiaryService.loadAppointments(context);

    if (mounted) {
      setState(() {
        _appointments = appointments;
        _appointments.sort(
            (a, b) => b.date.compareTo(a.date)); // Sort by date descending
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content:
            Text('Are you sure you want to delete "${appointment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await DiaryService.deleteAppointment(context, appointment);
      if (success && mounted) {
        _loadAppointments();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _appointments.map((appointment) {
                    return DataRow(
                      cells: [
                        DataCell(Text(DateFormat('dd MMM, yyyy')
                            .format(appointment.date))),
                        DataCell(Text(
                            DateFormat('hh:mm a').format(appointment.date))),
                        DataCell(Text(appointment.title)),
                        DataCell(Text(appointment.description)),
                        DataCell(
                            Text(appointment.isPast ? 'Past' : 'Upcoming')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteAppointment(appointment),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}
