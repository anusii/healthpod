/// Collecting the analysis the Analyser Pod shares back.
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
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:solidpod/solidpod.dart' show readExternalPod;

import 'package:healthpod/constants/analyser.dart';
import 'package:healthpod/features/bp/analyser/model.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';

/// How a wait for the analysis ended.
///
/// Exactly one of these applies: a result arrived that was both new and
/// complete; nothing arrived in time; something arrived that could not be
/// decrypted; or what arrived covered only part of what was shared.

class AnalyserWait {
  const AnalyserWait({this.result, this.staleKey = false, this.bestCoverage});

  /// The analysis, when one arrived that passed every check.

  final AnalyserResult? result;

  /// Whether the content could be fetched but not decrypted, which means the
  /// key held here no longer matches and waiting will not help.

  final bool staleKey;

  /// The most readings any new-but-incomplete result covered, if there was
  /// one. Null when nothing new arrived at all.

  final int? bestCoverage;

  /// Whether the wait produced a usable analysis.

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

class BPAnalyserResultService {
  /// How long to keep waiting for a result before giving up.
  ///
  /// The analyser polls its sharing inbox every 30 seconds by default, and a
  /// cycle takes a few seconds more, so a minute and a half leaves room for a
  /// slow server without leaving the user staring at a spinner.

  static const Duration defaultTimeout = Duration(seconds: 90);

  /// How long to wait between attempts to read the result.

  static const Duration pollInterval = Duration(seconds: 3);

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

    final base = Analyser.webId.replaceAll('/profile/card#me', '');

    return '$base${Analyser.resultsPathFragment}'
        '${podId(webId)}/${Analyser.podAverageFileName}';
  }

  /// When the analyser last published a result for [webId], if it ever has.
  ///
  /// Read before asking for a new analysis, so the wait that follows can tell
  /// the new result from the one already there.

  static Future<DateTime?> lastResultTime(String webId) async {
    final attempt = await _tryRead(resultUrl(webId));

    return attempt.result?.generatedAt;
  }

  /// Waits for a result the analyser has not published before, then returns it.
  ///
  /// [previous] is the timestamp from [lastResultTime], taken before the
  /// readings were shared; a document still carrying it belongs to the earlier
  /// run and is ignored. Comparing against that baseline rather than against
  /// the current time keeps the check correct even when this device's clock
  /// and the server's disagree, which they routinely do by a few seconds and
  /// occasionally by much more.
  ///
  /// Waits for a result that is both new and complete, then returns it.
  ///
  /// [previous] is the timestamp from [lastResultTime], taken before the
  /// readings were shared; a document still carrying it belongs to the
  /// earlier run. [minimumSources] is how many readings were shared, and a
  /// result that saw fewer is set aside: a run triggered by another Pod's
  /// share can finish after this one started and before these readings were
  /// all granted, which makes it new but incomplete.

  static Future<AnalyserWait> waitForResult({
    required String webId,
    DateTime? previous,
    int minimumSources = 0,
    Duration timeout = defaultTimeout,
    Duration interval = pollInterval,
    void Function(Duration elapsed)? onWaiting,
  }) async {
    final url = resultUrl(webId);
    final startedAt = DateTime.now();
    final deadline = startedAt.add(timeout);
    var staleKey = false;
    int? bestCoverage;

    while (DateTime.now().isBefore(deadline)) {
      final attempt = await _tryRead(url);
      final result = attempt.result;
      staleKey = attempt.staleKey;

      if (result != null && result.isFresherThan(previous)) {
        if (result.sourcesSeen >= minimumSources) {
          return AnalyserWait(result: result);
        }

        bestCoverage = result.sourcesSeen;
      }

      onWaiting?.call(DateTime.now().difference(startedAt));
      await Future<void>.delayed(interval);
    }

    return AnalyserWait(staleKey: staleKey, bestCoverage: bestCoverage);
  }

  /// Reads the result once, reporting why it could not be used.

  static Future<({AnalyserResult? result, bool staleKey})> _tryRead(
    String url,
  ) async {
    try {
      final content = await readExternalPod(url);
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return (result: null, staleKey: false);
      }

      return (result: AnalyserResult.fromJson(decoded), staleKey: false);
    } catch (e) {
      // Not there yet, not shared yet, or not readable yet: all expected
      // while waiting, and worth a line in the log but nothing more. A
      // decryption failure is different — it means the content was fetched
      // and opened with the wrong key — so it is reported to the caller.

      debugPrint('Waiting for the analysis at $url: $e');

      return (result: null, staleKey: isDecryptionFailure(e));
    }
  }

  /// Whether an error means the content was decrypted with the wrong key.
  ///
  /// solidpod hands the ciphertext to PointyCastle, which reports a wrong key
  /// as a padding fault rather than as anything more specific.

  static bool isDecryptionFailure(Object error) =>
      error is ArgumentError || '$error'.contains('pad block');

  /// Writes the chart to a file on this device and returns its path.
  ///
  /// Returns null on the web, where there is no local filesystem to write to,
  /// and when saving fails for any other reason: the chart is still shown, so
  /// a failed save is a missing convenience rather than a failed analysis.

  static Future<String?> saveChart(AnalyserResult result) async {
    final chart = result.chart;
    if (chart == null || kIsWeb) return null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory('${directory.path}/healthpod/analysis');
      await folder.create(recursive: true);

      final name =
          'bp-analysis-${formatTimestampForFilename(result.generatedAt)}.png';
      final file = File('${folder.path}/$name');
      await file.writeAsBytes(chart);

      return file.path;
    } catch (e) {
      debugPrint('Could not save the chart locally: $e');

      return null;
    }
  }
}
