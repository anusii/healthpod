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

  group('Where a cancellation is left', () {
    const alice = 'https://solid.dev.empwr.au/alice/profile/card#me';

    test('is the Analyser Pod folder solidpod leaves publicly writable', () {
      // Nothing else in the Analyser Pod is reachable by an app that has not
      // been granted anything, which is why this is the folder used.

      final url = Analyser.cancelUrl(BPAnalyserResultService.podId(alice));

      expect(url, startsWith(Analyser.podRoot));
      expect(url, contains(Analyser.sharedPathFragment));
    });

    test('is named after the Pod asking, so two requests cannot collide', () {
      const bob = 'https://solid.dev.empwr.au/bob/profile/card#me';

      final forAlice =
          Analyser.cancelUrl(BPAnalyserResultService.podId(alice));
      final forBob = Analyser.cancelUrl(BPAnalyserResultService.podId(bob));

      expect(forAlice, endsWith('cancel-solid.dev.empwr.au-alice.json'));
      expect(forAlice, isNot(forBob));
    });

    test('is the exact address the analyser reads', () {
      // The two sides build this independently, in different languages. The
      // Python half is pinned to the same string by
      // `analyser/bp_analyser/tests/test_control.py`, so a change to either
      // that is not matched in the other fails here.

      const me = 'https://solid.dev.empwr.au/intony/profile/card#me';

      expect(
        Analyser.cancelUrl(BPAnalyserResultService.podId(me)),
        'https://solid.dev.empwr.au/Analyser/healthpod/shared/'
        'cancel-solid.dev.empwr.au-intony.json',
      );
    });

    test('sits beside the results the analyser publishes', () {
      // Both are derived from the same WebID, so a mismatch here would mean
      // the app cancelling under one name and collecting under another.

      final resultBase =
          BPAnalyserResultService.resultUrl(alice).split('/healthpod/').first;

      expect(
        Analyser.cancelUrl(BPAnalyserResultService.podId(alice)),
        startsWith(resultBase),
      );
    });
  });

  group('The request the analyser reads', () {
    const alice = 'https://solid.dev.empwr.au/alice/profile/card#me';
    final at = DateTime.utc(2026, 8, 29, 4, 11, 52);

    test('names the kind the analyser looks for', () {
      // The analyser ignores anything in the folder that is not this.

      expect(
        BPAnalyserCancelService.request(alice, at)['kind'],
        'cancel-request',
      );
    });

    test('carries the WebID it came from', () {
      // Checked against the Pods that have shared data, so a request from
      // somebody who has contributed nothing is ignored.

      expect(BPAnalyserCancelService.request(alice, at)['web_id'], alice);
    });

    test('is timestamped in UTC so it can go stale', () {
      // The folder is publicly writable, so a request nobody collected must
      // not stop an unrelated run hours later.

      final stamp = BPAnalyserCancelService.request(alice, at)['requested_at']
          as String;

      expect(DateTime.parse(stamp).isUtc, isTrue);
      expect(DateTime.parse(stamp), at);
    });

    test('states the schema the analyser expects', () {
      expect(BPAnalyserCancelService.request(alice, at)['schema_version'], 1);
    });

    test('is timestamped in UTC even when the device is not', () {
      final local = DateTime(2026, 8, 29, 14, 11, 52);
      final stamp =
          BPAnalyserCancelService.request(alice, local)['requested_at']
              as String;

      expect(DateTime.parse(stamp), local.toUtc());
    });
  });

  group('The outcome of a cancellation', () {
    test('counts as stopped only when the analyser collected the request', () {
      // What the user is asking is whether the server stopped, so leaving the
      // request somewhere it can be found must not be reported as success.

      expect(const AnalyserCancel(CancelOutcome.stopped).stopped, isTrue);
    });

    test('a request nobody collected is a failure, not a success', () {
      // The usual reason is that the analyser is not running, in which case
      // the analysis it was asked to stop is not running either — but this
      // cannot tell that from an analyser that simply never heard.

      expect(
        const AnalyserCancel(CancelOutcome.notCollected).stopped,
        isFalse,
      );
    });

    test('a request that could not be written is a failure', () {
      expect(
        const AnalyserCancel(CancelOutcome.undelivered).stopped,
        isFalse,
      );
      expect(
        const AnalyserCancel(CancelOutcome.notLoggedIn).stopped,
        isFalse,
      );
    });

    test('every outcome but one is a failure', () {
      // A new outcome added later defaults to being reported as a failure,
      // which is the safe direction: never claim the server stopped.

      final succeeded =
          CancelOutcome.values.where((o) => AnalyserCancel(o).stopped);

      expect(succeeded, [CancelOutcome.stopped]);
    });
  });
}
