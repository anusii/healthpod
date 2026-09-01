/// Tests for the shared row action buttons.
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

import 'package:healthpod/theme/app_colors.dart';
import 'package:healthpod/theme/app_theme.dart';
import 'package:healthpod/widgets/action_buttons.dart';

/// Pumps [button] within the app's own theme.

Future<void> pumpButton(WidgetTester tester, Widget button) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

/// The colour the pumped button is filled with.

Color? fillOf(WidgetTester tester) {
  final button = tester.widget<IconButton>(find.byType(IconButton));

  return button.style?.backgroundColor?.resolve(<WidgetState>{});
}

/// The colour of the pumped button's icon.

Color? iconColourOf(WidgetTester tester) {
  final button = tester.widget<IconButton>(find.byType(IconButton));

  return button.style?.foregroundColor?.resolve(<WidgetState>{});
}

void main() {
  group('Every action button', () {
    testWidgets('is filled solid, with a white icon', (tester) async {
      await pumpButton(tester, EditButton(onPressed: () {}));

      expect(fillOf(tester), isNotNull);
      expect(iconColourOf(tester), Colors.white);
    });

    testWidgets('runs its action when tapped', (tester) async {
      var tapped = false;

      await pumpButton(tester, DeleteButton(onPressed: () => tapped = true));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('The colour says what the action does', () {
    testWidgets('editing is the app blue', (tester) async {
      await pumpButton(tester, EditButton(onPressed: () {}));

      expect(fillOf(tester), AppColors.primary);
    });

    testWidgets('deleting is red', (tester) async {
      await pumpButton(tester, DeleteButton(onPressed: () {}));

      expect(fillOf(tester), AppColors.error);
    });

    testWidgets('saving is green', (tester) async {
      await pumpButton(tester, SaveButton(onPressed: () {}));

      expect(fillOf(tester), AppColors.success);
    });

    testWidgets('backing out is grey', (tester) async {
      await pumpButton(tester, CancelButton(onPressed: () {}));

      expect(fillOf(tester), AppColors.navUnselected);
    });
  });

  group('Tooltips', () {
    testWidgets('name the record acted on', (tester) async {
      await pumpButton(
        tester,
        DeleteButton(record: 'reading', onPressed: () {}),
      );

      expect(
        tester.widget<IconButton>(find.byType(IconButton)).tooltip,
        'Delete this reading from your pod',
      );
    });

    testWidgets('give way to a tooltip the caller provides', (tester) async {
      await pumpButton(
        tester,
        DeleteButton(showTooltip: false, onPressed: () {}),
      );

      expect(
        tester.widget<IconButton>(find.byType(IconButton)).tooltip,
        isNull,
      );
    });
  });
}
