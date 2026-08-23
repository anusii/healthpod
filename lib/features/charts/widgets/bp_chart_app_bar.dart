/// App bar component for blood pressure chart with educational tooltips.
///
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/features/charts/widgets/bp_analyse_button.dart';
import 'package:healthpod/utils/url_launcher_util.dart';

/// App bar widget with educational tooltips about blood pressure.

class BPChartAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BPChartAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Row(
        children: [
          // Main title with basic BP explanation.
          MarkdownTooltip(
            message: '''

              **Blood Pressure:** A vital measurement of cardiovascular health.
              It shows how strongly your blood pushes against artery walls.

              Blood pressure is measured in millimeters of mercury (mmHg) and recorded as two numbers: systolic/diastolic.

              * **Systolic**: Upper number - Pressure when heart contracts

              * **Diastolic**: Lower number - Pressure when heart relaxes

            ''',
            child: Row(
              children: [
                const Text(
                  'Blood Pressure Trends',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.surface,
      actions: [
        // MarkdownTooltip explaining BP Classification ranges.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: MarkdownTooltip(
            message: '''

              **BP Classifications (AHA)**

              * **Normal Blood Pressure:** <120/<80 mmHg

              * **Elevated Blood Pressure:** 120-129/<80 mmHg

              * **Stage 1 High Blood Pressure (Hypertension):** 130-139/80-89 mmHg

              * **Stage 2 Hypertension:** ≥140/≥90 mmHg

              * **Hypertensive Crisis:** >180/>120 mmHg (Seek medical attention)

              * **Low Blood Pressure (Hypotension):** <90/<60 mmHg

            ''',
            child: Icon(
              Icons.monitor_heart_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
        ),

        // MarkdownTooltip for additional BP information.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: MarkdownTooltip(
            message: '''

              **BP Health Information**

              * Blood pressure can vary throughout the day due to activity, stress, or other factors.

              * A single high reading doesn't necessarily mean you have hypertension.

              * Consistent high readings should be discussed with your healthcare professional.

              * Ideal blood pressure ranges vary depending on age, health conditions, and individual circumstances.

              * Consult your doctor for personalised advice.

              * Healthy lifestyle helps maintain normal blood pressure:
                  - Regular exercise
                  - Balanced diet
                  - Stress management
                  - Limited sodium & alcohol

            ''',
            child: Icon(
              Icons.health_and_safety_outlined,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ),

        // Analyse: share the readings with the Analyser Pod and show the
        // chart it returns, marked with this user's averages and everyone's.
        const BPAnalyseButton(),

        // AHA Link Button.
        Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 8.0),
          child: MarkdownTooltip(
            message: '''

            **American Heart Association**

            Click to visit [AHA's website](https://www.heart.org) for expert guidance on heart health and blood pressure management.

            ''',
            child: IconButton(
              icon: Icon(Icons.open_in_new, color: theme.colorScheme.error),
              onPressed: () => UrlLauncherUtil.launchAHA(context),
            ),
          ),
        ),
      ],
    );
  }
}
