/// Service for handling health resource-related actions and content.
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:healthpod/dialogs/markdown_alert.dart';

/// Service class for handling health resource-related actions and content.
///
/// Provides methods for displaying health information, opening external links,
/// and showing health-related tools and calculators.

class ResourceService {
  /// Opens an external URL in the default browser.
  ///
  /// Parameters:
  /// * [context] - The build context
  /// * [url] - The URL to open
  ///
  /// Shows an error message if the URL cannot be opened.
  
  static Future<void> openExternalLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showError(context, 'Could not open $url');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Error opening link: $e');
      }
    }
  }

  /// Shows health information in a markdown-formatted dialog.
  ///
  /// Parameters:
  /// * [context] - The build context
  /// * [topic] - The health topic to display information about
  ///
  /// Available topics:
  /// * 'blood-pressure' - Blood pressure guide with classifications
  /// * 'vaccination' - Vaccination information and schedules
  
  static void showHealthInfo(BuildContext context, String topic) {
    String content;
    String title;

    switch (topic) {
      case 'blood-pressure':
        title = 'Blood Pressure Guide';
        // Content sourced from AHA and Health Direct guidelines.

        content = '''

# Understanding Blood Pressure

Blood pressure is measured using two numbers:
* **Systolic pressure** (top number)
* **Diastolic pressure** (bottom number)

## BP Classifications (AHA)

| Classification | Systolic (mmHg) | Diastolic (mmHg) |
|---------------|-----------------|------------------|
| Normal        | Less than 120   | Less than 80     |
| Elevated      | 120-129         | Less than 80     |
| Stage 1 High  | 130-139         | 80-89           |
| Stage 2 High  | 140 or higher   | 90 or higher    |
| Crisis        | Over 180        | Over 120        |

> **Note:** If your readings are in the Crisis range, seek immediate medical care.

## Tips for Management

* 🔍 Regular monitoring
* 🥗 Maintain a healthy diet (low sodium, rich in fruits and vegetables)
* 🏃‍♂️ Regular exercise (at least 150 minutes per week)
* 🧘‍♂️ Stress management
* 💊 Take medications as prescribed

## Learn More
* [American Heart Association - Understanding Blood Pressure](https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings)
* [Health Direct - Blood Pressure](https://www.healthdirect.gov.au/blood-pressure)

''';
        break;

      case 'vaccination':
        title = 'Vaccination Information';
        // Content sourced from WHO and Australian Immunisation Handbook
        content = '''

# Importance of Vaccinations

Vaccinations are a crucial part of preventive healthcare that helps protect both you and your community from serious diseases.

## Key Points

* 📋 Keep your vaccination records up to date
* ⏰ Follow recommended vaccination schedules
* 👨‍⚕️ Consult with your healthcare provider
* 📱 Stay informed about booster requirements

## Common Adult Vaccines

### Annual Vaccines
* 🦠 Influenza (Flu) - Recommended annually for everyone 6 months and older

### Regular Interval Vaccines
* 💉 Tetanus-diphtheria (Td/Tdap) - Every 10 years
* 🦠 COVID-19 - As recommended by health authorities

### Age-Based Recommendations
* Shingles (Zoster) - Recommended for adults 50 years and older
* Pneumococcal - Recommended for adults 65 years and older
* Others based on risk factors and medical conditions

> **Remember:** Always consult your healthcare provider about which vaccines are right for you.

## Learn More
* [Australian Immunisation Handbook](https://immunisationhandbook.health.gov.au/)
* [WHO - Vaccines and Immunization](https://www.who.int/health-topics/vaccines-and-immunization)

''';
        break;

      default:
        title = 'Health Information';
        content = '''

# Health Information

Information not available for this topic.

For reliable health information, please visit:
* [Health Direct Australia](https://www.healthdirect.gov.au/)
* [World Health Organization](https://www.who.int/)

''';
    }

    markdownAlert(context, content, title);
  }

  /// Shows a health calculator dialog.
  ///
  /// Parameters:
  /// * [context] - The build context
  /// * [type] - The type of calculator to show
  ///
  /// Currently shows a placeholder with links to external calculators
  /// while implementation is in progress.
  static void showCalculator(BuildContext context, String type) {
    markdownAlert(
      context,
      '''

# Health Calculator

Calculator functionality coming soon!

We are working on implementing various evidence-based health calculators including:
* BMI Calculator (WHO standards)
* Ideal Weight Calculator
* Daily Calorie Calculator
* Heart Disease Risk Calculator

Learn more about health measurements and calculations:
* [Health Direct - BMI Calculator](https://www.healthdirect.gov.au/bmi-calculator)
* [Heart Foundation - Heart Age Calculator](https://www.heartfoundation.org.au/heart-age-calculator)

''',
      'Health Calculator',
    );
  }

  /// Shows a health tracker dialog.
  ///
  /// Parameters:
  /// * [context] - The build context
  /// * [type] - The type of tracker to show
  ///
  /// Currently shows a placeholder with information about upcoming
  /// tracking features and links to external resources.
  static void showTracker(BuildContext context, String type) {
    markdownAlert(
      context,
      '''

# Health Tracker

Tracking functionality coming soon!

We are working on implementing various health tracking features based on clinical guidelines:
* Goal Setting with SMART principles
* Progress Tracking with visual analytics
* Health Metrics Dashboard
* Medication and Appointment Reminders

Learn more about health tracking:
* [Health Direct - Health and Wellbeing](https://www.healthdirect.gov.au/health-and-wellbeing)
* [Better Health Channel - Goal Setting](https://www.betterhealth.vic.gov.au/health/healthyliving/goal-setting)

''',
      'Health Tracker',
    );
  }

  /// Shows an error message using a snackbar.
  ///
  /// Parameters:
  /// * [context] - The build context
  /// * [message] - The error message to display
  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
} 