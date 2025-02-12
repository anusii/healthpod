import 'package:flutter/material.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to HealthPod',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your personal health data management system',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Use the navigation rail on the left to access different features:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownTooltip(
                  message: '''
                  **Appointment:** Here you will be able to access and manage
                  your appointments. You can enter historic information, update
                  when you recieve a new appointment, and download appointments
                  from other sources. This will be a record of all your
                  interactions with the health system.
                  ''',
                  child: Text(
                    '• Appointments',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                MarkdownTooltip(
                  message: '''
                **File Management:** Tap here to access file management features.
                This allows you to:

                - Browse your POD storage
                - Upload files to your POD
                - Download files from your POD
                - Delete files from your POD
                ''',
                  child: Text(
                    '• Files',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                MarkdownTooltip(
                  message: '''
                  **Record of Vaccinations:** Tap here to access and manage your
                  record of vaccinations. You can enter historic information,
                  update when you recieve a vaccination, and download from
                  governemnt records of your vaccinations.
                  ''',
                  child: Text(
                    '• Vaccinations',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                MarkdownTooltip(
                  message: '''
                  **Health Survey:** Tap here to start the Health Survey.
                  This allows you to answer important health-related questions,
                  track your responses, and share them securely with your healthcare
                  provider if needed.
                  ''',
                  child: Text(
                    '• Survey',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                MarkdownTooltip(
                  message: '''
                  **Data Visualisation:** Tap here to access interactive data
                  visualisation tools. You can:

                  - View health trends over time
                  - Analyse patterns in your health data
                  - Generate comprehensive health reports
                  - Track progress towards health goals
                  ''',
                  child: Text(
                    '• Visualisation',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                MarkdownTooltip(
                  message: '''
                  **Blood Pressure Data Editor:** Edit your blood pressure readings:

                  - View all readings
                  - Add new readings
                  - Edit existing data
                  - Delete observations
                  ''',
                  child: Text(
                    '• BP Editor',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
