/// Collecting the analysis the Analyser Pod publishes.
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

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart' show readExternalPod;

import 'package:healthpod/constants/analyser.dart';
import 'package:healthpod/features/bp/analyser/model.dart';

/// How a fetch of the published analysis ended.
///
/// Exactly one of these applies: the result arrived; something arrived that
/// could not be decrypted; or nothing readable arrived at all.

class AnalyserFetch {
  const AnalyserFetch({
    this.result,
    this.document,
    this.staleKey = false,
  });

  /// The analysis, when one was read and parsed.

  final AnalyserResult? result;

  /// The document [result] was parsed from, kept so it can be saved to the
  /// user's Pod in the form the analyser wrote it.

  final Map<String, dynamic>? document;

  /// Whether the content could be fetched but not decrypted, which means the
  /// key held here no longer matches the one the analyser used.

  final bool staleKey;

  /// Whether a usable analysis was read.

  bool get succeeded => result != null;
}

/// Reads the result the analyser publishes for this Pod.
///
/// The analyser writes each Pod's result to a predictable place in its own
/// Pod and grants that Pod read access, so the address can be worked out
/// rather than searched for:
///
///     <analyser>/healthpod/data/analyser/<pod-id>/bp-average.json.enc.ttl
///
/// where `<pod-id>` is the WebID reduced to a file-safe label, the same form
/// solidpod uses. Reading it goes through `readExternalPod()`, which finds the
/// key the analyser left in this Pod's sharing inbox and decrypts the content.
///
/// This used to poll: the app had no way of knowing when the analyser had
/// finished, so it read this address every three seconds for a minute and a
/// half, comparing timestamps against a baseline it had taken before sharing,
/// and gave up if nothing new appeared. The analyser now answers the call that
/// started it, so by the time anything here runs the result is published and
/// the answer already says when it was made. What is left is one read, and a
/// couple of retries for the seconds a server can take to make a fresh write
/// readable.

class BPAnalyserResultService {
  /// How many times to read before giving up.
  ///
  /// The result exists — the analyser said so — so a failure here is the
  /// server not serving it yet rather than the analysis not being done. Three
  /// attempts a second and a half apart covers that without turning a real
  /// failure into a long wait.

  static const int defaultAttempts = 3;

  /// How long to wait between attempts.

  static const Duration defaultRetryInterval = Duration(milliseconds: 1500);

  /// The label the analyser uses for a Pod, derived from its WebID.
  ///
  /// Mirrors solidpod's `getUniqueStrWebId()`: drop the scheme and the profile
  /// document, then replace the remaining separators. For
  /// `https://solid.dev.empwr.au/alice/profile/card#me` this gives
  /// `solid.dev.empwr.au-alice`.

  static String podId(String webId) {
    var label = webId;
    for (final scheme in const ['https://', 'http://']) {
      if (label.startsWith(scheme)) {
        label = label.substring(scheme.length);
      }
    }
    label = label.replaceAll('/profile/card#me', '');

    return label.split('/').where((part) => part.isNotEmpty).join('-');
  }

  /// The URL of the result the analyser publishes for [webId].

  static String resultUrl(String webId) {
    // The Analyser Pod root, without a trailing slash: the results fragment
    // carries its own leading one.

    return '${Analyser.podRoot}${Analyser.resultsPathFragment}'
        '${podId(webId)}/${Analyser.podAverageFileName}';
  }

  /// Reads the analysis the analyser has just published for [webId].
  ///
  /// [expected] is the timestamp the analyser reported when it answered. A
  /// document carrying a different one is the previous run's, still sitting at
  /// the address because the new write has not become visible yet, so it is
  /// set aside and the read tried again. Comparing against what the analyser
  /// said, rather than against the current time, keeps this correct however
  /// far apart this device's clock and the server's are — and they routinely
  /// differ by seconds.
  ///
  /// Passing null for [expected] accepts whatever is published, which is what
  /// the saved-analysis path wants: it is reading history, not a fresh run.
  ///
  /// [isCancelled] is consulted between attempts, so a user who gives up while
  /// a retry is pending gets the interface back without waiting it out.

  static Future<AnalyserFetch> readResult({
    required String webId,
    DateTime? expected,
    int attempts = defaultAttempts,
    Duration interval = defaultRetryInterval,
    bool Function()? isCancelled,
  }) async {
    final url = resultUrl(webId);
    var staleKey = false;

    for (var attempt = 1; attempt <= attempts; attempt++) {
      if (isCancelled?.call() ?? false) break;

      final fetch = await _tryRead(url);
      staleKey = fetch.staleKey;

      final result = fetch.result;
      if (result != null &&
          (expected == null || result.generatedAt == expected)) {
        return fetch;
      }

      if (attempt < attempts) await Future<void>.delayed(interval);
    }

    return AnalyserFetch(staleKey: staleKey);
  }

  /// Reads the result once, reporting why it could not be used.

  static Future<AnalyserFetch> _tryRead(String url) async {
    try {
      final content = await readExternalPod(url);
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return const AnalyserFetch();

      return AnalyserFetch(
        result: AnalyserResult.fromJson(decoded),
        document: decoded,
      );
    } catch (e) {
      // Not visible yet, or not readable yet: expected on the first attempt
      // after a fresh write, and worth a line in the log but nothing more. A
      // decryption failure is different — it means the content was fetched
      // and opened with the wrong key — so it is reported to the caller.

      debugPrint('Reading the analysis at $url: $e');

      return AnalyserFetch(staleKey: isDecryptionFailure(e));
    }
  }

  /// Whether an error means the content was decrypted with the wrong key.
  ///
  /// solidpod hands the ciphertext to PointyCastle, which reports a wrong key
  /// as a padding fault rather than as anything more specific.

  static bool isDecryptionFailure(Object error) =>
      error is ArgumentError || '$error'.contains('pad block');
}
