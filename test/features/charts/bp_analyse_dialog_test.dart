/// Tests for the dialogue asked before blood pressure data leaves the Pod.
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

import 'package:healthpod/features/bp/analyser/saved_analysis_service.dart';
import 'package:healthpod/features/charts/widgets/bp_analyse_dialog.dart';

final String _analysis =
    BPAnalysisStore.fileNameFor(DateTime(2026, 8, 21, 9, 15));

Future<void> _pump(
  WidgetTester tester, {
  int observationCount = 12,
  bool anyShared = false,
  List<String> saved = const [],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BPAnalyseDialog(
          observationCount: observationCount,
          anyShared: Future<bool>.value(anyShared),
          saved: Future<List<String>>.value(saved),
        ),
      ),
    ),
  );

  // Both actions wait on a future before deciding whether they are live.

  await tester.pumpAndSettle();
}

/// Whether the action carrying [label] can be pressed.

bool _enabled(WidgetTester tester, String label) =>
    tester
        .widget<TextButton>(find.widgetWithText(TextButton, label))
        .onPressed !=
    null;

void main() {
  group('What the dialogue offers', () {
    testWidgets('counts the observations, pluralised', (tester) async {
      await _pump(tester);
      expect(
        find.textContaining('Grant access to your 12 observations.'),
        findsOneWidget,
      );

      await _pump(tester, observationCount: 1);
      expect(
        find.textContaining('Grant access to your 1 observation.'),
        findsOneWidget,
      );
    });

    testWidgets('offers Revoke only when something is shared', (tester) async {
      await _pump(tester);
      expect(_enabled(tester, 'Revoke Permissions'), isFalse);

      await _pump(tester, anyShared: true);
      expect(_enabled(tester, 'Revoke Permissions'), isTrue);
    });

    testWidgets('offers Past Analyses only when one is saved', (tester) async {
      await _pump(tester);
      expect(_enabled(tester, 'Past Analyses'), isFalse);

      await _pump(tester, saved: [_analysis]);
      expect(_enabled(tester, 'Past Analyses'), isTrue);
    });

    testWidgets('always offers Cancel and Analyse', (tester) async {
      await _pump(tester);

      expect(_enabled(tester, 'Cancel'), isTrue);
      expect(_enabled(tester, 'Analyse'), isTrue);
    });
  });
}
