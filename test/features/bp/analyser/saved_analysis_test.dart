/// Tests for the analyses kept in the user's own Pod.
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

import 'package:healthpod/features/bp/analyser/saved_analysis_dialog.dart';
import 'package:healthpod/features/bp/analyser/saved_analysis_service.dart';

void main() {
  group('What an analysis is called', () {
    test('names a file for when the analysis was made', () {
      expect(
        BPAnalysisStore.fileNameFor(DateTime(2026, 8, 21, 9, 15, 30)),
        'bp-analysis-2026-08-21T09-15-30.json.enc.ttl',
      );
    });

    test('reads the moment back out of the name', () {
      final moment = DateTime(2026, 8, 21, 9, 15, 30);

      expect(
        BPAnalysisStore.timestampOf(BPAnalysisStore.fileNameFor(moment)),
        moment,
      );
    });

    test('ignores anything that is not an analysis', () {
      for (final name in [
        'blood_pressure_2026-08-21T09-15-30.json.enc.ttl',
        'bp-analysis-not-a-date.json.enc.ttl',
        'bp-analysis-2026-08-21T09-15-30.png',
        'init.json',
      ]) {
        expect(BPAnalysisStore.timestampOf(name), isNull, reason: name);
      }
    });

    test('puts the analyses in the Pod, not among the observations', () {
      expect(
        BPAnalysisStore.podPath('bp-analysis-2026-08-21T09-15-30.json.enc.ttl'),
        'healthpod/data/analysis/bp-analysis-2026-08-21T09-15-30.json.enc.ttl',
      );
    });
  });

  group('The list of past analyses', () {
    final names = [
      BPAnalysisStore.fileNameFor(DateTime(2026, 8, 29, 9, 41)),
      BPAnalysisStore.fileNameFor(DateTime(2026, 8, 21, 9, 15)),
    ];

    Future<void> pump(WidgetTester tester, List<String> analyses) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: SavedAnalysesDialog(analyses: analyses)),
          ),
        );

    testWidgets('shows each one by when it was made', (tester) async {
      await pump(tester, names);

      expect(find.text('29 Aug 2026 at 9:41'), findsOneWidget);
      expect(find.text('21 Aug 2026 at 9:15'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('says so when the Pod holds none', (tester) async {
      await pump(tester, []);

      expect(find.textContaining('Your Pod holds no analyses'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });
  });
}
