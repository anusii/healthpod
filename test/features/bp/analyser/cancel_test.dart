/// Tests for abandoning an analysis part way through.
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

// Cancelling has two halves that fail independently: the app stops waiting,
// and the analyser is told to stop working. These cover the first half and
// the address the second half is sent to; the analyser's own side is covered
// by `analyser/bp_analyser/tests/test_store.py`.

import 'package:flutter_test/flutter_test.dart';

import 'package:healthpod/constants/analyser.dart';
import 'package:healthpod/features/bp/analyser/cancel_service.dart';
import 'package:healthpod/features/bp/analyser/result_service.dart';
import 'package:healthpod/features/bp/analyser/share_service.dart';

void main() {
  group('Waiting for the analysis', () {
    test('stops at once when the user has already cancelled', () async {
      // Returns before the first read, so this needs no Pod and no clock.

      final outcome = await BPAnalyserResultService.waitForResult(
        webId: 'https://server/alice/profile/card#me',
        isCancelled: () => true,
      );

      expect(outcome.cancelled, isTrue);
      expect(outcome.succeeded, isFalse);
      expect(outcome.result, isNull);
    });

    test('reports nothing else when it was cancelled', () {
      // The user knows what they did; a cancelled wait must not also claim a
      // stale key or a partial result, which would send them chasing a fault.

      const outcome = AnalyserWait(cancelled: true);

      expect(outcome.staleKey, isFalse);
      expect(outcome.bestCoverage, isNull);
    });

    test('is not cancelled by default', () {
      expect(const AnalyserWait().cancelled, isFalse);
    });
  });

  group('Sharing that was cancelled part way', () {
    test('counts as neither complete nor partial', () {
      // Both would prompt a message about the analysis that follows, and
      // there is no analysis to follow.

      const result = AnalyserShareResult(
        shared: 3,
        total: 10,
        cancelled: true,
      );

      expect(result.isCompleteSuccess, isFalse);
      expect(result.isPartial, isFalse);
    });

    test('still reports how many readings went out', () {
      // They stay shared: withdrawing them is a separate decision, made in
      // the file browser.

      const result = AnalyserShareResult(
        shared: 3,
        total: 10,
        cancelled: true,
      );

      expect(result.shared, 3);
    });

    test('leaves an uncancelled share judged as before', () {
      const complete = AnalyserShareResult(shared: 10, total: 10);
      const partial = AnalyserShareResult(shared: 3, total: 10);

      expect(complete.isCompleteSuccess, isTrue);
      expect(partial.isPartial, isTrue);
    });
  });

  group('The analyser control API', () {
    test('cancels at the path the analyser serves', () {
      expect(Analyser.cancelUrl, endsWith('/api/cancel'));
      expect(Analyser.cancelUrl, startsWith(Analyser.apiBaseUrl));
    });

    test('has an address configured by default', () {
      // Without one, cancelling could only ever stop the app waiting.

      expect(Analyser.apiConfigured, isTrue);
      expect(Analyser.apiBaseUrl, isNot(endsWith('/')));
    });

    test('carries no token unless one is given at build time', () {
      expect(Analyser.apiToken, isEmpty);
    });
  });

  group('The outcome of a cancellation', () {
    test('counts as delivered only when the analyser answered', () {
      expect(
        const AnalyserCancel(CancelOutcome.accepted).delivered,
        isTrue,
      );
      expect(
        const AnalyserCancel(CancelOutcome.unreachable).delivered,
        isFalse,
      );
      expect(
        const AnalyserCancel(CancelOutcome.notConfigured).delivered,
        isFalse,
      );
    });

    test('says nothing was running unless told so', () {
      expect(const AnalyserCancel(CancelOutcome.accepted).wasRunning, isFalse);
    });
  });
}
