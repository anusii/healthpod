/// Tests for the health profile calculations.
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

library;

import 'package:flutter_test/flutter_test.dart';

import 'package:healthpod/features/health_profile/measures.dart';

void main() {
  group('BMI', () {
    test('is weight over height squared, in metres', () {
      expect(
        HealthMeasures.bmi(weightKg: 80, heightCm: 180),
        closeTo(24.69, 0.01),
      );
    });

    test('is unknown until both weight and height are recorded', () {
      expect(HealthMeasures.bmi(weightKg: 80, heightCm: null), isNull);
      expect(HealthMeasures.bmi(weightKg: null, heightCm: 180), isNull);
      expect(HealthMeasures.bmi(weightKg: 80, heightCm: 0), isNull);
    });

    test('categories follow the WHO boundaries', () {
      expect(HealthMeasures.bmiCategory(18.4), 'Underweight');
      expect(HealthMeasures.bmiCategory(18.5), 'Healthy weight');
      expect(HealthMeasures.bmiCategory(24.9), 'Healthy weight');
      expect(HealthMeasures.bmiCategory(25), 'Overweight');
      expect(HealthMeasures.bmiCategory(29.9), 'Overweight');
      expect(HealthMeasures.bmiCategory(30), 'Obese');
    });
  });

  group('Waist to hip ratio', () {
    test('is waist over hip', () {
      expect(
        HealthMeasures.waistHipRatio(waist: 90, hip: 100),
        closeTo(0.90, 0.001),
      );
    });

    test('is unknown until both are recorded', () {
      expect(HealthMeasures.waistHipRatio(waist: 90, hip: null), isNull);
      expect(HealthMeasures.waistHipRatio(waist: null, hip: 100), isNull);
      expect(HealthMeasures.waistHipRatio(waist: 90, hip: 0), isNull);
    });

    test('reads against the threshold for the recorded gender', () {
      expect(HealthMeasures.waistHipCategory(0.89, 'Male'), 'Lower risk');
      expect(HealthMeasures.waistHipCategory(0.90, 'Male'), 'Increased risk');
      expect(HealthMeasures.waistHipCategory(0.84, 'Female'), 'Lower risk');
      expect(HealthMeasures.waistHipCategory(0.85, 'Female'), 'Increased risk');
    });

    test('says nothing without a gender to choose a threshold', () {
      expect(HealthMeasures.waistHipCategory(0.95, null), isNull);
      expect(HealthMeasures.waistHipCategory(0.95, 'Non-binary'), isNull);
      expect(
        HealthMeasures.waistHipCategory(0.95, 'Prefer not to say'),
        isNull,
      );
    });
  });

  group('Age', () {
    test('counts whole years since the date of birth', () {
      expect(
        HealthMeasures.ageInYears('1958-03-12', DateTime(2026, 8, 15)),
        68,
      );
    });

    test('waits for the birthday to come around', () {
      expect(
        HealthMeasures.ageInYears('1958-12-31', DateTime(2026, 12, 30)),
        67,
      );
      expect(
        HealthMeasures.ageInYears('1958-12-31', DateTime(2026, 12, 31)),
        68,
      );
    });

    test('is unknown without a usable date of birth', () {
      expect(HealthMeasures.ageInYears(null, DateTime(2026, 8, 15)), isNull);
      expect(HealthMeasures.ageInYears('', DateTime(2026, 8, 15)), isNull);
      expect(
        HealthMeasures.ageInYears('not a date', DateTime(2026, 8, 15)),
        isNull,
      );
    });
  });
}
