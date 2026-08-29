/// Tests for the dialog presenting an analysis.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU
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
/// Authors: Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:healthpod/features/bp/analyser/model.dart';
import 'package:healthpod/features/bp/analyser/result_dialog.dart';
import 'package:healthpod/features/bp/analyser/saved_analysis_service.dart';

/// An analysis with figures but no chart, which needs no image decoding.

final AnalyserResult _result = AnalyserResult(
  generatedAt: DateTime.utc(2026, 8, 21, 9, 15),
  own: const AnalyserAverages(systolic: 125, diastolic: 82.5, heartRate: 67),
  everyone: const AnalyserAverages(
    systolic: 134.2,
    diastolic: 86.9,
    heartRate: 71.4,
  ),
  observationCount: 12,
  podCount: 3,
);

Future<void> _pump(WidgetTester tester, {required bool savedInPod}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnalyserResultDialog(result: _result, savedInPod: savedInPod),
        ),
      ),
    );

void main() {
  group('Where the analysis is kept', () {
    testWidgets('says where in the Pod it was saved', (tester) async {
      await _pump(tester, savedInPod: true);

      expect(
        find.textContaining('Kept in your Pod at ${BPAnalysisStore.podPath}'),
        findsOneWidget,
      );
    });

    testWidgets('says so when it could not be saved', (tester) async {
      await _pump(tester, savedInPod: false);

      expect(
        find.textContaining('could not be saved to your Pod'),
        findsOneWidget,
      );
      expect(find.textContaining('Kept in your Pod'), findsNothing);
    });

    testWidgets('compares the figures against everyone', (tester) async {
      await _pump(tester, savedInPod: true);

      const summary =
          'Your 12 observations, compared with 3 contributing Pods.';

      expect(find.text(summary), findsOneWidget);
      expect(find.text('125.0'), findsOneWidget);
      expect(find.text('134.2'), findsOneWidget);
    });
  });
}
