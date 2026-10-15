/// Tests for the blood pressure editor page when a save goes wrong.
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
/// Authors: Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/features/bp/obs/service.dart';
import 'package:healthpod/features/table/bp_editor/page.dart';

/// A Pod held in memory, whose next save can be made to fail.

class _FakeService extends BPEditorService {
  _FakeService(this.pod);

  final List<BPObservation> pod;

  /// How many saves still to fail.

  int failures = 0;

  /// Whether a failing save still lands in the Pod, as when the server
  /// writes the file but the reply is lost.

  bool writesBeforeFailing = false;

  @override
  Future<List<BPObservation>> loadData(BuildContext context) async => [...pod];

  @override
  Future<void> saveObservationToPod({
    required BuildContext context,
    required BPObservation observation,
    required bool isNew,
    required BPObservation? oldObservation,
  }) async {
    if (failures > 0) {
      failures--;
      if (writesBeforeFailing) pod.add(observation);
      throw Exception('server unavailable');
    }
    pod.add(observation);
  }
}

List<BPObservation> _readings(int count) => [
      for (var i = 0; i < count; i++)
        BPObservation(
          timestamp: DateTime(2026, 9, i + 1),
          systolic: 110,
          diastolic: 70,
          heartRate: 65,
          notes: '',
        ),
    ];

Future<void> _addReading(WidgetTester tester) async {
  await tester.tap(find.text('Add New Reading'));
  await tester.pumpAndSettle();

  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), '120');
  await tester.enterText(fields.at(1), '80');
  await tester.enterText(fields.at(2), '60');
  await tester.pump();

  await tester.tap(find.byIcon(Icons.save));
  await tester.pumpAndSettle();
}

Future<void> _pumpPage(WidgetTester tester, _FakeService service) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: BPEditorPage(service: service)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a saved reading is counted', (tester) async {
    final service = _FakeService(_readings(10));
    await _pumpPage(tester, service);

    await _addReading(tester);

    expect(service.pod, hasLength(11));
    expect(find.text('11 observations'), findsOneWidget);
  });

  testWidgets(
      'a save that failed but reached the Pod leaves the list and count '
      'in step with the Pod', (tester) async {
    final service = _FakeService(_readings(10))
      ..failures = 1
      ..writesBeforeFailing = true;
    await _pumpPage(tester, service);

    await _addReading(tester);

    expect(service.pod, hasLength(11));
    expect(find.text('11 observations'), findsOneWidget);

    // Nothing is left in edit mode over a reading that was never opened.

    expect(find.byIcon(Icons.save), findsNothing);
  });

  testWidgets(
      'a save that failed outright can be added again without replacing '
      'another reading', (tester) async {
    final service = _FakeService(_readings(10))..failures = 1;
    await _pumpPage(tester, service);

    await _addReading(tester);
    expect(find.text('10 observations'), findsOneWidget);
    expect(find.byIcon(Icons.save), findsNothing);

    await _addReading(tester);

    expect(service.pod, hasLength(11));
    expect(find.text('11 observations'), findsOneWidget);
  });
}
