import 'package:flutter/material.dart';
import 'package:healthpod/utils/fetch_key_saved_status.dart';

/// A reusable function to handle survey submissions with options to save locally and/or to POD.
///
/// Parameters:
/// - context: BuildContext for showing dialogs and navigation
/// - responses: Map of survey responses
/// - saveLocally: Function to handle local saving
/// - saveToPod: Function to handle POD saving
/// - title: Custom title for the save dialog (optional)
/// - navigateBack: Boolean to determine if the screen should navigate back after saving (optional)
Future<void> handleSurveySubmit({
  required BuildContext context,
  required Map<String, dynamic> responses,
  required Future<void> Function(BuildContext, Map<String, dynamic>)
      saveLocally,
  required Future<void> Function(BuildContext, Map<String, dynamic>) saveToPod,
  String title = 'Save Survey Results',
  bool navigateBack = false,
}) async {
  if (!context.mounted) return;

  final isKeySaved = await fetchKeySavedStatus(context);

  if (!context.mounted) return;

  final saveChoice = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose how to save your results:'),
            if (!isKeySaved) ...[
              const SizedBox(height: 12),
              const Text(
                'Note: POD saving requires setting up your security key first.',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('local'),
            child: const Text('Save Locally'),
          ),
          TextButton(
            onPressed:
                isKeySaved ? () => Navigator.of(context).pop('pod') : null,
            child: Text(
              'Save to POD',
              style: TextStyle(
                color: isKeySaved ? null : Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed:
                isKeySaved ? () => Navigator.of(context).pop('both') : null,
            child: Text(
              'Save Both Places',
              style: TextStyle(
                color: isKeySaved ? null : Colors.grey,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (saveChoice == null) return;

  if (!context.mounted) return;

  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saving survey results...'),
        duration: Duration(seconds: 2),
      ),
    );

    if (saveChoice == 'local' || saveChoice == 'both') {
      await saveLocally(context, responses);
    }

    if (!context.mounted) return;

    if (saveChoice == 'pod' || saveChoice == 'both') {
      await saveToPod(context, responses);
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Survey submitted and saved successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    if (navigateBack) {
      await Future.delayed(const Duration(seconds: 1));
      if (!context.mounted) return;
      Navigator.of(context).pop();
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error saving survey: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
