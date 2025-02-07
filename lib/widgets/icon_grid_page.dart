/// Icon grid page.
//
// Time-stamp: <Monday 2025-01-27 16:22:20 +1100 Graham Williams>
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/dialogs/alert.dart';
import 'package:healthpod/dialogs/show_coming_soon.dart';
import 'package:healthpod/features/bp/editor.dart';
import 'package:healthpod/features/bp/survey.dart';
import 'package:healthpod/features/file/service.dart';
import 'package:healthpod/utils/fetch_and_navigate_to_visualisation.dart';

class IconGridPage extends StatelessWidget {
  // TODO 20250113 gjw MOVE TO constants/features.dart
  final List<IconData> features = [
    Icons.home,
    Icons.calendar_today,
    Icons.folder,
    Icons.vaccines,
    Icons.quiz,
    Icons.show_chart,
    Icons.table_chart,
    Icons.approval,
    Icons.lightbulb,
    Icons.local_hospital,
    Icons.health_and_safety,
    Icons.medical_information,
    Icons.medical_services,
    Icons.medication,
    Icons.medication_liquid,
  ];

  IconGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 10.0, // Space between icons horizontally
          runSpacing: 10.0, // Space between icons vertically
          children: features.map((icon) {
            final iconContainer = Container(
              width: 80.0, // Fixed width for each icon container
              height: 80.0, // Fixed height for each icon container
              decoration: BoxDecoration(
                // TODO 20250113 gjw MOVE TO constants/features.dart
                color: {
                  Icons.calendar_today,
                  Icons.folder,
                  Icons.vaccines,
                  Icons.quiz,
                  Icons.show_chart,
                  Icons.table_chart,
                }.contains(icon)
                    ? Colors.blue
                    : Colors.grey,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 50.0,
              ),
            );

            final gestureDetector = GestureDetector(
              onTap: () async {
                // TODO 20250113 gjw MOVE INTO constants/features.dart AND USE map() HERE
                switch (icon) {
                  case Icons.calendar_today:
                    alert(
                      context,
                      '''

                      Here you will be able to access and manage your
                      appointments. You can enter historic information, update
                      when you recieve a new appointment, and download
                      appointments from other sources.

                      ''',
                      'Comming Soon - Appointment',
                    );
                    break;
                  case Icons.folder:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FileService()),
                    );
                    break;
                  case Icons.vaccines:
                    alert(
                      context,
                      '''

                    Here you will be able to access and manage your record of
                    vaccinations. You can enter historic information, update
                    when you recieve a vaccination, and download from governemnt
                    records of your vaccinations.

                    ''',
                      'Comming Soon - Vaccines',
                    );
                    break;
                  case Icons.quiz:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BPSurvey()),
                    );
                    break;
                  case Icons.show_chart:
                    await fetchAndNavigateToVisualisation(context);
                    break;
                  case Icons.table_chart:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BPEditor(),
                      ),
                    );
                    break;
                  default:
                    showComingSoon(context); // For other features.
                }
              },
              child: iconContainer,
            );

            // Add tooltips for the folder features.

            return switch (icon) {
              // TODO 20250113 gjw MOVE INTO constants/features AND USE map() HERE
              Icons.calendar_today => MarkdownTooltip(
                  message: '''

                  **Appointment:** Here you will be able to access and manage
                  your appointments. You can enter historic information, update
                  when you recieve a new appointment, and download appointments
                  from other sources. This will be a record of all your
                  interactions with the health system.

                  ''',
                  child: gestureDetector,
                ),
              Icons.folder => MarkdownTooltip(
                  message: '''

                **File Management:** Tap here to access file management features.
                This allows you to:

                - Browse your POD storage

                - Upload files to your POD

                - Download files from your POD

                - Delete files from your POD

                ''',
                  child: gestureDetector,
                ),
              Icons.lightbulb => MarkdownTooltip(
                  message: 'Placeholder',
                  child: gestureDetector,
                ),
              Icons.vaccines => MarkdownTooltip(
                  message: '''

                  **Record of Vaccinations:** Tap here to access and manage your
                  record of vaccinations. You can enter historic information,
                  update when you recieve a vaccination, and download from
                  governemnt records of your vaccinations.

                  ''',
                  child: gestureDetector,
                ),
              Icons.quiz => MarkdownTooltip(
                  message: '''

                  **Health Survey:** Tap here to start the Health Survey.
                  This allows you to answer important health-related questions,
                  track your responses, and share them securely with your healthcare
                  provider if needed.

                  ''',
                  child: gestureDetector,
                ),
              Icons.show_chart => MarkdownTooltip(
                  message: '''

                  **Data Visualisation:** Tap here to access interactive data
                  visualisation tools. You can:

                  - View health trends over time

                  - Analyse patterns in your health data

                  - Generate comprehensive health reports

                  - Track progress towards health goals

                  ''',
                  child: gestureDetector,
                ),
              Icons.table_chart => MarkdownTooltip(
                  message: '''

                  **Blood Pressure Data Editor:** Edit your blood pressure readings:

                  - View all readings

                  - Add new readings

                  - Edit existing data

                  - Delete observations

                  ''',
                  child: gestureDetector,
                ),
              _ => gestureDetector,
            };
          }).toList(),
        ),
      ),
    );
  }
}
