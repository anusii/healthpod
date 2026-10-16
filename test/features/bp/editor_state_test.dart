/// Tests for adding and editing readings in the blood pressure editor.
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
import 'package:healthpod/features/table/bp_editor/state.dart';

/// Stands in for the Pod service, recording what would have been written.

class _RecordingService {
  final saved = <BPObservation>[];

  Future<void> saveObservationToPod({
    required BuildContext context,
    required BPObservation observation,
    required bool isNew,
    required BPObservation? oldObservation,
  }) async {
    saved.add(observation);
  }
}

BPObservation _reading(int day) => BPObservation(
      timestamp: DateTime(2026, 10, day),
      systolic: 110,
      diastolic: 70,
      heartRate: 65,
      notes: '',
    );

Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return context;
}

void _type(BPEditorState state, String sys, String dia, String hr) {
  state.systolicController!.text = sys;
  state.diastolicController!.text = dia;
  state.heartRateController!.text = hr;
}

void main() {
  testWidgets('a new reading is saved with the values typed', (tester) async {
    final context = await _context(tester);
    final state = BPEditorState()..observations = [_reading(1)];
    final service = _RecordingService();

    state.addNewObservation();
    _type(state, '120', '80', '60');
    await state.saveObservation(context, service, 0);

    final saved = service.saved.single;
    expect([saved.systolic, saved.diastolic, saved.heartRate], [120, 80, 60]);
    expect(state.isNewObservation, isFalse);
  });

  testWidgets('a timestamp picked before typing is kept', (tester) async {
    final context = await _context(tester);
    final state = BPEditorState()..observations = [_reading(1)];
    final service = _RecordingService();
    final picked = DateTime(2026, 10, 5, 8, 30);

    state.addNewObservation();
    state.updateTimestamp(picked);
    _type(state, '120', '80', '60');
    await state.saveObservation(context, service, 0);

    expect(service.saved.single.timestamp, picked);
  });

  test('pressing Add twice leaves a single new row', () {
    final state = BPEditorState()..observations = [_reading(1)];

    state.addNewObservation();
    state.addNewObservation();

    expect(state.observations, hasLength(2));
    expect(state.savedObservationCount, 1);
  });

  test('editing another reading drops the blank new row', () {
    final first = _reading(1);
    final second = _reading(2);
    final state = BPEditorState()..observations = [second, first];

    state.addNewObservation();
    state.enterEditMode(2);

    expect(state.observations, [second, first]);
    expect(state.editingIndex, 1);
    expect(state.currentEdit, first);
    expect(state.savedObservationCount, 2);
  });

  test('a fresh load no longer counts a new row as unsaved', () {
    final state = BPEditorState()..observations = [_reading(1)];

    state.addNewObservation();
    state.resetEditing();
    state.observations = [_reading(2), _reading(1)];

    expect(state.savedObservationCount, 2);
    expect(state.editingIndex, isNull);
  });
}
