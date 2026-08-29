/// Tests for the shared confirmation and reporting of a deletion.
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

import 'package:healthpod/dialogs/confirm_delete.dart';
import 'package:healthpod/utils/show_delete_result.dart';

/// Pumps a button that runs [onPressed] with a usable context.

Future<void> pumpAction(
  WidgetTester tester,
  void Function(BuildContext context) onPressed,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => onPressed(context),
            child: const Text('Delete'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
  await tester.pumpAndSettle();
}

/// The background colour of the snackbar currently shown.

Color? snackBarColour(WidgetTester tester) =>
    tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor;

void main() {
  group('Confirming a deletion', () {
    testWidgets('asks before anything is removed', (tester) async {
      await pumpAction(
        tester,
        (context) => confirmDelete(
          context,
          title: 'Delete reading',
          message: 'Remove this reading from your pod?',
        ),
      );

      expect(find.text('Delete reading'), findsOneWidget);
      expect(find.text('Remove this reading from your pod?'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Delete'), findsOneWidget);
    });

    testWidgets('goes ahead only when the user agrees', (tester) async {
      bool? answer;

      await pumpAction(
        tester,
        (context) => confirmDelete(
          context,
          title: 'Delete reading',
          message: 'Remove this reading from your pod?',
        ).then((confirmed) => answer = confirmed),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(answer, isTrue);
    });

    testWidgets('cancelling leaves the record alone', (tester) async {
      bool? answer;

      await pumpAction(
        tester,
        (context) => confirmDelete(
          context,
          title: 'Delete reading',
          message: 'Remove this reading from your pod?',
        ).then((confirmed) => answer = confirmed),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(answer, isFalse);
    });
  });

  group('Reporting the outcome', () {
    testWidgets('a delete that worked is reported in green', (tester) async {
      await pumpAction(
        tester,
        (context) => showDeleteSuccess(context, 'Reading deleted.'),
      );

      expect(find.text('Reading deleted.'), findsOneWidget);
      expect(snackBarColour(tester), Colors.green);
    });

    testWidgets('a delete that failed is reported in red', (tester) async {
      await pumpAction(
        tester,
        (context) => showDeleteFailure(context, 'Error deleting reading.'),
      );

      expect(find.text('Error deleting reading.'), findsOneWidget);
      expect(snackBarColour(tester), Colors.red);
    });
  });
}
