/// Tests for the Analyse button and the cancel it turns into.
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

// Two faults these cover, both of which reached the user:
//
//   - the hover region sat inside the tooltip, whose child subtree Flutter
//     rebuilds whenever the tooltip appears or fades. The rebuilt region
//     received no enter event from a pointer that had not moved, so the
//     cross showed up only when something else generated a pointer event;
//   - the progress ring was determinate from the first frame, and an arc of
//     zero draws nothing, so the button appeared to vanish when pressed.

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:healthpod/features/charts/widgets/bp_analyse_button.dart';

/// The button, with room around it to park a pointer clear of the control.

Widget harness() => const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: Center(child: BPAnalyseButton()),
          ),
        ),
      ),
    );

/// The hover region the button relies on, which must outlive the tooltip.

MouseRegion hoverRegion(WidgetTester tester) => tester.widget<MouseRegion>(
      find
          .ancestor(
            of: find.byType(Tooltip),
            matching: find.byType(MouseRegion),
          )
          .first,
    );

void main() {
  testWidgets('the hover region sits outside the tooltip', (tester) async {
    // Inside it, the region is rebuilt every time the tooltip shows or hides
    // and loses track of a pointer that has not moved since.

    await tester.pumpWidget(harness());

    final region = find.ancestor(
      of: find.byType(Tooltip),
      matching: find.byType(MouseRegion),
    );

    expect(region, findsWidgets);
    expect(hoverRegion(tester).onEnter, isNotNull);
    expect(hoverRegion(tester).onExit, isNotNull);
  });

  testWidgets('the hover region survives a rebuild of the tooltip',
      (tester) async {
    // The same render object before and after, so hover state carries over.

    await tester.pumpWidget(harness());
    final before = tester.renderObject(
      find
          .ancestor(
            of: find.byType(Tooltip),
            matching: find.byType(MouseRegion),
          )
          .first,
    );

    await tester.pumpWidget(harness());
    await tester.pump();

    final after = tester.renderObject(
      find
          .ancestor(
            of: find.byType(Tooltip),
            matching: find.byType(MouseRegion),
          )
          .first,
    );

    expect(identical(before, after), isTrue);
  });

  group('The progress ring', () {
    test('turns rather than sitting at zero when nothing has gone out yet', () {
      // A determinate ring at zero draws no arc, so the button looked as
      // though it had vanished the moment it was pressed.

      expect(
        analyseRingValue(stepped: true, completed: 0, total: 12),
        isNull,
      );
    });

    test('reports real progress once a reading has gone out', () {
      expect(analyseRingValue(stepped: true, completed: 3, total: 12), 0.25);
      expect(analyseRingValue(stepped: true, completed: 12, total: 12), 1.0);
    });

    test('turns while waiting for the analyser, which reports no steps', () {
      expect(
        analyseRingValue(stepped: false, completed: 12, total: 12),
        isNull,
      );
    });

    test('reports progress while revoking, which counts its steps too', () {
      expect(analyseRingValue(stepped: true, completed: 6, total: 12), 0.5);
    });

    test('turns rather than dividing by a total nobody has counted', () {
      expect(analyseRingValue(stepped: true, completed: 0, total: 0), isNull);
    });
  });

  testWidgets('the resting button offers the analyse action', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('hovering the resting button does not offer a cancel',
      (tester) async {
    // There is nothing to cancel until an analysis is running.

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await tester.pumpWidget(harness());
    await pointer.addPointer(
      location: tester.getCenter(find.byType(BPAnalyseButton)),
    );
    addTearDown(pointer.removePointer);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsNothing);
  });
}
