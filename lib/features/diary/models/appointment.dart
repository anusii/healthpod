/// A model class representing a medical appointment.
///
/// This class contains information about an appointment including its date,
/// title, description, and whether it's in the past or future.
class Appointment {
  /// The date and time of the appointment.
  final DateTime date;

  /// The title or name of the appointment.
  final String title;

  /// A detailed description of the appointment.
  final String description;

  /// Whether the appointment is in the past.
  final bool isPast;

  /// Creates a new [Appointment] instance.
  ///
  /// [date] is the date and time of the appointment.
  /// [title] is the title or name of the appointment.
  /// [description] is a detailed description of the appointment.
  /// [isPast] indicates whether the appointment is in the past.
  Appointment({
    required this.date,
    required this.title,
    required this.description,
    required this.isPast,
  });
}
