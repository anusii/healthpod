/// Body measurement calculations for the health profile.
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

/// Values derived from the recorded measurements.
///
/// Every calculation returns null when the measurements it needs have not
/// been recorded, so a partly filled profile shows what it can and says
/// nothing about the rest.

class HealthMeasures {
  const HealthMeasures._();

  /// Waist to hip ratios at or above which the World Health Organization
  /// reports a substantially increased risk of metabolic complications.

  static const double whrThresholdMale = 0.90;
  static const double whrThresholdFemale = 0.85;

  /// Body mass index in kg/m², from a weight in kg and a height in cm.

  static double? bmi({double? weightKg, double? heightCm}) {
    if (weightKg == null || heightCm == null || heightCm <= 0) return null;
    final metres = heightCm / 100;
    return weightKg / (metres * metres);
  }

  /// The World Health Organization weight category for a body mass index.

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Waist to hip ratio, from a waist and hip measured in the same units.

  static double? waistHipRatio({double? waist, double? hip}) {
    if (waist == null || hip == null || hip <= 0) return null;
    return waist / hip;
  }

  /// The ratio at which risk rises for [gender], or null if it is not one the
  /// World Health Organization gives a threshold for.

  static double? whrThreshold(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return whrThresholdMale;
      case 'female':
        return whrThresholdFemale;
      default:
        return null;
    }
  }

  /// How a waist to hip [ratio] reads against the threshold for [gender].
  ///
  /// Returns null when no gender is recorded in the profile, in which case
  /// both thresholds are worth showing rather than guessing at one.

  static String? waistHipCategory(double ratio, String? gender) {
    final threshold = whrThreshold(gender);
    if (threshold == null) return null;
    return ratio >= threshold ? 'Increased risk' : 'Lower risk';
  }

  /// Age in whole years at [asAt], from a 'yyyy-MM-dd' date of birth.

  static int? ageInYears(String? dateOfBirth, DateTime asAt) {
    if (dateOfBirth == null || dateOfBirth.isEmpty) return null;
    final born = DateTime.tryParse(dateOfBirth);
    if (born == null) return null;

    // Take a year off until the birthday has come around this year.

    var years = asAt.year - born.year;
    final hadBirthday = asAt.month > born.month ||
        (asAt.month == born.month && asAt.day >= born.day);
    if (!hadBirthday) years--;

    return years < 0 ? null : years;
  }
}
