/// Tests for the blood pressure line chart.
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

library;

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:healthpod/features/charts/widgets/bp_line_chart.dart';

/// Builds [count] observations, two on each day, starting 2025-09-01.

List<Map<String, dynamic>> observations(int count) => List.generate(
      count,
      (i) => {
        'timestamp': DateTime(2025, 9, 1 + i ~/ 2, 8 + (i % 2) * 6, 30)
            .toIso8601String(),
        'responses': {
          'systolic': 120 + i % 40,
          'diastolic': 80 + i % 20,
          'heart_rate': 70,
          'notes': '',
        },
      },
    );

Widget wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(height: 400, child: child)),
    );

/// The chart's scroll position, which reports how much is off screen.

ScrollPosition scrollPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable)).position;

void main() {
  testWidgets('labels each observation, using times within a day', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(BPLineChart(surveyData: observations(4))));

    // The first observation of a day carries the date, the later ones their
    // time, so same-day observations are distinguishable.

    expect(find.text('1 Sep \'25'), findsOneWidget);
    expect(find.text('2 Sep'), findsOneWidget);
    expect(find.text('14:30'), findsNWidgets(2));

    // Four observations fit the window, so there is nothing to scroll.

    expect(scrollPosition(tester).maxScrollExtent, 0);
  });

  testWidgets('scrolls to reach observations beyond the window', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(BPLineChart(surveyData: observations(30))));
    await tester.pumpAndSettle();

    // With more observations than fit, the view opens on the most recent one
    // and the first is off to the left.

    final windowWidth = tester.getSize(find.byType(BPLineChart)).width;
    expect(scrollPosition(tester).maxScrollExtent, greaterThan(0));
    expect(tester.getTopLeft(find.text('15 Sep')).dx, lessThan(windowWidth));
    expect(tester.getTopLeft(find.text('1 Sep \'25')).dx, lessThan(0));

    // Scrolling back reaches the earliest observation.

    await tester.drag(find.byType(Scrollable), const Offset(3000, 0));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('1 Sep \'25')).dx,
      greaterThanOrEqualTo(0),
    );
  });
}
