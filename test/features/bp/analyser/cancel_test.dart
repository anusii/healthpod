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

// Cancelling still has two halves that fail independently — the app stops
// waiting, and the analyser is told to stop working — but both now travel the
// same gRPC connection, and `analyser_client_test.dart` drives them against a
// real server. What is left here is the part of the round trip that has to
// give up in the middle of its own work: the sharing, which happens before
// the analyser has been asked anything, and the read of the result, which
// happens after it has answered.
//
// The analyser's own side is covered by
// `analyser/bp_analyser/tests/test_pipeline.py`.

import 'package:flutter_test/flutter_test.dart';

import 'package:healthpod/features/bp/analyser/result_service.dart';
import 'package:healthpod/features/bp/analyser/share_service.dart';

void main() {
  group('Reading the result', () {
    test('stops at once when the user has already cancelled', () async {
      // Returns before the first read, so this needs no Pod and no clock.

      final fetch = await BPAnalyserResultService.readResult(
        webId: 'https://server/alice/profile/card#me',
        isCancelled: () => true,
      );

      expect(fetch.succeeded, isFalse);
      expect(fetch.result, isNull);
      expect(fetch.staleKey, isFalse);
    });

    test('reports nothing when there was nothing to report', () {
      const fetch = AnalyserFetch();

      expect(fetch.succeeded, isFalse);
      expect(fetch.staleKey, isFalse);
      expect(fetch.document, isNull);
    });

    test('a stale key is worth telling the user about on its own', () {
      // The analysis worked and the result cannot be opened, which is a
      // different thing to do about than a result that never arrived.

      const fetch = AnalyserFetch(staleKey: true);

      expect(fetch.succeeded, isFalse);
      expect(fetch.staleKey, isTrue);
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
}
