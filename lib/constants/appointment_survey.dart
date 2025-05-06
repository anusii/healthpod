import 'package:healthpod/features/survey/question.dart';
import 'package:healthpod/constants/health_data_type.dart';

/// Constants for the appointment survey form.
class AppointmentSurveyConstants {
  /// Field names used in the survey.
  static const String fieldDate = 'date';
  static const String fieldTitle = 'title';
  static const String fieldDescription = 'description';

  /// Questions displayed in the survey.
  static const String date = 'When is your appointment?';
  static const String title = 'What is the appointment for?';
  static const String description = 'Any additional details?';

  /// The list of questions used in the appointment survey.
  static final List<HealthSurveyQuestion> questions = [
    HealthSurveyQuestion(
      question: date,
      fieldName: fieldDate,
      type: HealthDataType.datetime,
      isRequired: true,
      allowFutureDate: true,
      showTime: true,
    ),
    HealthSurveyQuestion(
      question: title,
      fieldName: fieldTitle,
      type: HealthDataType.text,
      isRequired: true,
    ),
    HealthSurveyQuestion(
      question: description,
      fieldName: fieldDescription,
      type: HealthDataType.text,
      isRequired: false,
    ),
  ];
}
