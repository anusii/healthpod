/// Tests for recording health profile measurements.
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

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:healthpod/features/charts/tab.dart';
import 'package:healthpod/features/health_profile/survey.dart';
import 'package:healthpod/features/table/tab.dart';
import 'package:healthpod/features/update/tab.dart';

void main() {
  testWidgets('asks for each measurement, none of them required', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: HealthProfileSurvey()));

    // The form numbers the questions it asks.

    expect(find.textContaining("What's your weight?"), findsOneWidget);
    expect(find.textContaining('How tall are you?'), findsOneWidget);
    expect(
      find.textContaining("What's your waist circumference?"),
      findsOneWidget,
    );
    expect(
      find.textContaining("What's your hip circumference?"),
      findsOneWidget,
    );
  });

  testWidgets('will not record an entry with nothing measured', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HealthProfileSurvey()));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    // Saving nothing would stamp today's date against measurements that have
    // not changed, so it is refused before the save dialog is reached.

    expect(find.text('Nothing to save'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'OK'));
    await tester.pumpAndSettle();

    // The shared form clears itself five seconds after a submission.

    await tester.pump(const Duration(seconds: 5));
  });

  test('sits between Appointments and Blood Pressure in every tab', () {
    const expected = [
      'Appointments',
      'Health Profile',
      'Blood Pressure',
      'Medications',
      'Vaccinations',
      'Pathology',
    ];

    // The View, Add and Data tabs share a selected index, so they have to
    // hold the same features in the same order.

    for (final panels in [chartPanels, surveyPanels, tablePanels]) {
      expect(panels.map((panel) => panel['title']).toList(), expected);
    }
  });
}
