/// Links to advice on healthy BMI and waist to hip ratios.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
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
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/constants/health_profile.dart';
import 'package:healthpod/utils/url_launcher_util.dart';

/// Buttons opening published advice on what the calculated values mean.

class HealthProfileAdviceLinks extends StatelessWidget {
  const HealthProfileAdviceLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _link(
          context,
          label: 'Healthy BMI range',
          site: 'healthdirect',
          url: HealthProfileConstants.bmiAdviceUrl,
          tooltip: '''

            **Healthy BMI range**

            Opens healthdirect, the Australian government health service, on
            what body mass index measures, the healthy range for adults, and
            where it is a poor guide - athletes, older people, pregnancy, and
            children.

          ''',
        ),
        _link(
          context,
          label: 'BMI calculator',
          site: 'Heart Foundation',
          url: HealthProfileConstants.bmiCalculatorUrl,
          tooltip: '''

            **Heart Foundation BMI calculator**

            Opens the Heart Foundation calculator, which puts your body mass
            index alongside advice on heart health and what to do about a
            reading outside the healthy range.

          ''',
        ),
        _link(
          context,
          label: 'Waist/hip ratio',
          site: 'WHO',
          url: HealthProfileConstants.waistHipAdviceUrl,
          tooltip: '''

            **Waist to hip ratio**

            Opens the World Health Organization expert consultation that sets
            the widely used thresholds - 0.90 for men and 0.85 for women -
            above which the risk of metabolic complications rises.

          ''',
        ),
      ],
    );
  }

  /// One link button, described by its tooltip before it is followed.

  Widget _link(
    BuildContext context, {
    required String label,
    required String site,
    required String url,
    required String tooltip,
  }) {
    return MarkdownTooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.open_in_new, size: 16),
        label: Text(label),
        onPressed: () => UrlLauncherUtil.launchUrl(
          context: context,
          url: url,
          websiteName: site,
        ),
      ),
    );
  }
}
