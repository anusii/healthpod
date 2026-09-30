/// Tests for the bounded-concurrency helper used on the POD request paths.
//
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

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:healthpod/utils/map_with_concurrency.dart';

void main() {
  group('mapWithConcurrency', () {
    test('returns results in the order of the input, not of completion',
        () async {
      // Later items finish first, so an implementation that appended results
      // as they arrived would come back reversed.

      final results = await mapWithConcurrency<int, int>(
        [1, 2, 3, 4, 5],
        (n) async {
          await Future<void>.delayed(Duration(milliseconds: (6 - n) * 10));
          return n * 10;
        },
        concurrency: 5,
      );

      expect(results, [10, 20, 30, 40, 50]);
    });

    test('keeps at most the requested number of calls in flight', () async {
      var inFlight = 0;
      var peak = 0;
      final gates = <Completer<void>>[];

      final done = mapWithConcurrency<int, int>(
        List<int>.generate(10, (i) => i),
        (n) async {
          inFlight++;
          peak = inFlight > peak ? inFlight : peak;

          final gate = Completer<void>();
          gates.add(gate);
          await gate.future;

          inFlight--;
          return n;
        },
        concurrency: 3,
      );

      // Let the first batch start, then release the gates one at a time so a
      // new call can only begin as an earlier one finishes.

      while (gates.length < 10) {
        await Future<void>.delayed(Duration.zero);
        if (gates.every((g) => g.isCompleted)) break;
        gates.firstWhere((g) => !g.isCompleted).complete();
      }

      for (final gate in gates.where((g) => !g.isCompleted)) {
        gate.complete();
      }

      expect(await done, List<int>.generate(10, (i) => i));
      expect(peak, 3);
    });

    test('handles an empty list without running anything', () async {
      var called = false;

      final results = await mapWithConcurrency<int, int>([], (n) async {
        called = true;
        return n;
      });

      expect(results, isEmpty);
      expect(called, isFalse);
    });

    test('runs fewer workers than the limit when there is less to do',
        () async {
      var peak = 0;
      var inFlight = 0;

      await mapWithConcurrency<int, int>(
        [1, 2],
        (n) async {
          inFlight++;
          peak = inFlight > peak ? inFlight : peak;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          inFlight--;
          return n;
        },
        concurrency: 10,
      );

      expect(peak, 2);
    });

    test('propagates an error from the action', () async {
      expect(
        mapWithConcurrency<int, int>([1, 2, 3], (n) async {
          if (n == 2) throw StateError('boom');
          return n;
        }),
        throwsStateError,
      );
    });
  });
}
