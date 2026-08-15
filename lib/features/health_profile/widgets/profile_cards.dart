/// The health profile measurements and the values calculated from them.
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

import 'package:intl/intl.dart';

import 'package:healthpod/constants/health_profile.dart';
import 'package:healthpod/features/health_profile/measures.dart';
import 'package:healthpod/features/health_profile/model.dart';
import 'package:healthpod/features/health_profile/widgets/measure_card.dart';
import 'package:healthpod/utils/format_measure.dart';

/// Lays out a card for each measurement, then for each calculated value.
///
/// The date of birth and gender come from the personal profile rather than
/// being recorded again here, so there is one of each on the pod.

class HealthProfileCards extends StatelessWidget {
  const HealthProfileCards({
    super.key,
    required this.latest,
    required this.today,
    this.dateOfBirth,
    this.gender,
  });

  /// The most recent value recorded for each measurement, with its date.

  final Map<String, DatedValue> latest;

  /// The day the age is calculated against.

  final DateTime today;

  /// Date of birth from the personal profile, as 'yyyy-MM-dd'.

  final String? dateOfBirth;

  /// Gender from the personal profile, which sets the waist to hip threshold.

  final String? gender;

  @override
  Widget build(BuildContext context) {
    final bmi = HealthMeasures.bmi(
      weightKg: latest[HealthProfileConstants.fieldWeight]?.value,
      heightCm: latest[HealthProfileConstants.fieldHeight]?.value,
    );
    final ratio = HealthMeasures.waistHipRatio(
      waist: latest[HealthProfileConstants.fieldWaist]?.value,
      hip: latest[HealthProfileConstants.fieldHip]?.value,
    );
    final age = HealthMeasures.ageInYears(dateOfBirth, today);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        ...HealthProfileConstants.units.keys.map(_measurementCard),
        MeasureCard(
          label: 'Age',
          value: age?.toString(),
          unit: 'years',
          detail: age == null ? 'No date of birth set' : 'From your profile',
          tooltip: '''

            **Age**

            Calculated from the date of birth held in your profile, which you
            can set from the **Home** screen. It is not recorded again here so
            there is only ever one date of birth in your pod.

          ''',
        ),
        MeasureCard(
          label: 'BMI',
          value: bmi == null ? null : formatMeasure(bmi),
          unit: 'kg/m²',
          detail: bmi == null
              ? 'Needs a weight and a height'
              : HealthMeasures.bmiCategory(bmi),
          tooltip: '''

            **Body Mass Index**

            Your weight in kilograms divided by the square of your height in
            metres. The World Health Organization reads it as underweight
            below 18.5, healthy from 18.5 to 24.9, overweight from 25 to 29.9,
            and obese at 30 and above.

            It takes no account of build, so a muscular frame can read high.
            Follow the links below for what it does and does not tell you.

          ''',
        ),
        MeasureCard(
          label: 'Waist/Hip',
          value: ratio?.toStringAsFixed(2),
          detail: _ratioDetail(ratio),
          tooltip: '''

            **Waist to hip ratio**

            Your waist measurement divided by your hip measurement, which
            describes where you carry weight rather than how much. The World
            Health Organization reports a substantially increased risk of
            metabolic complications at 0.90 and above for men, and 0.85 and
            above for women.

            Measure the waist at its narrowest, the hips at their widest, and
            keep the tape level and snug without compressing the skin.

          ''',
        ),
      ],
    );
  }

  /// A card for one recorded measurement, dated by when it was entered.

  Widget _measurementCard(String field) {
    final recorded = latest[field];

    return MeasureCard(
      label: HealthProfileConstants.labels[field]!,
      value: recorded == null ? null : formatMeasure(recorded.value),
      unit: HealthProfileConstants.units[field],
      detail: recorded == null
          ? null
          : 'Updated ${DateFormat('d MMM y').format(recorded.updated)}',
      tooltip: '''

        **${HealthProfileConstants.labels[field]}**

        Recorded in ${HealthProfileConstants.units[field]}, with the date you
        entered it. Add a new measurement from the **Add** tab and the earlier
        ones are kept in your pod as history.

      ''',
    );
  }

  /// How the ratio reads, or the thresholds when there is no gender to
  /// choose between them.

  String _ratioDetail(double? ratio) {
    if (ratio == null) return 'Needs a waist and a hip';

    return HealthMeasures.waistHipCategory(ratio, gender) ??
        'Thresholds 0.90 men, 0.85 women';
  }
}
