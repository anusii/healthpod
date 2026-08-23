/// The result the Analyser Pod shares back after an analysis.
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
import 'dart:typed_data';

/// One set of averages: the three measurements, any of which may be absent.

class AnalyserAverages {
  const AnalyserAverages({this.systolic, this.diastolic, this.heartRate});

  /// Reads the `{systolic, diastolic, heart_rate}` shape the analyser writes.

  factory AnalyserAverages.fromJson(Map<String, dynamic>? json) {
    double? value(String key) {
      final raw = json?[key];
      return raw is num ? raw.toDouble() : null;
    }

    return AnalyserAverages(
      systolic: value('systolic'),
      diastolic: value('diastolic'),
      heartRate: value('heart_rate'),
    );
  }

  final double? systolic;
  final double? diastolic;
  final double? heartRate;

  /// Whether anything at all was measured.

  bool get isEmpty =>
      systolic == null && diastolic == null && heartRate == null;
}

/// The analysis of one Pod's blood pressure, as shared back by the Analyser.
///
/// The document also carries the chart the analyser drew, as base64-encoded
/// PNG, so the numbers and the picture arrive together in a single read.

class AnalyserResult {
  const AnalyserResult({
    required this.generatedAt,
    required this.own,
    required this.everyone,
    required this.observationCount,
    required this.podCount,
    this.filesRead = 0,
    this.filesSkipped = 0,
    this.chart,
  });

  /// Parses the result document, tolerating a missing chart.
  ///
  /// Throws [FormatException] when the document is not an analyser result,
  /// which guards against reading some other shared file by mistake.

  factory AnalyserResult.fromJson(Map<String, dynamic> json) {
    if (json['kind'] != 'pod-average') {
      throw const FormatException('not an analyser result document');
    }

    final pod = json['pod'] as Map<String, dynamic>?;
    final cohort = json['cohort'] as Map<String, dynamic>?;

    final generated = DateTime.tryParse('${json['generated_at']}');
    if (generated == null) {
      throw const FormatException('the result has no usable timestamp');
    }

    return AnalyserResult(
      generatedAt: generated.toUtc(),
      own: AnalyserAverages.fromJson(
        json['average'] as Map<String, dynamic>?,
      ),
      everyone: AnalyserAverages.fromJson(
        cohort?['average_of_averages'] as Map<String, dynamic>?,
      ),
      observationCount: (pod?['observation_count'] as num?)?.toInt() ?? 0,
      podCount: (cohort?['pod_count'] as num?)?.toInt() ?? 0,
      filesRead: (pod?['files_read'] as num?)?.toInt() ?? 0,
      filesSkipped: (pod?['files_skipped'] as num?)?.toInt() ?? 0,
      chart: _decodeChart(json['chart']),
    );
  }

  /// When the analyser produced this result, in UTC.

  final DateTime generatedAt;

  /// This Pod's own averages.

  final AnalyserAverages own;

  /// The average of every contributing Pod's average.

  final AnalyserAverages everyone;

  /// How many readings the analyser used.

  final int observationCount;

  /// How many Pods contributed to the cohort figure.

  final int podCount;

  /// How many of this Pod's shared files the analyser managed to read.

  final int filesRead;

  /// How many it found but could not read, usually for want of a key.

  final int filesSkipped;

  /// How many shared files the analyser had in view when it computed this.
  ///
  /// Every file it discovered was either read or skipped, so the total says
  /// how much of the Pod the result covers. A run triggered by somebody
  /// else's share can complete before this Pod's newest readings have
  /// finished being granted; such a result is genuinely new, and genuinely
  /// incomplete, and this is how the two are told apart.

  int get sourcesSeen => filesRead + filesSkipped;

  /// The chart as PNG bytes, when the analyser produced one.

  final Uint8List? chart;

  /// Whether this result is a different one from [previous].
  ///
  /// [previous] is the timestamp of the result that was already published
  /// before a new analysis was asked for; null when there was none. Comparing
  /// timestamps for difference rather than order means the answer does not
  /// depend on this device's clock agreeing with the server's.

  bool isFresherThan(DateTime? previous) =>
      previous == null || generatedAt != previous;

  static Uint8List? _decodeChart(Object? chart) {
    if (chart is! Map<String, dynamic>) return null;
    if (chart['format'] != 'png' || chart['encoding'] != 'base64') return null;

    final data = chart['data'];
    if (data is! String || data.isEmpty) return null;

    try {
      return base64Decode(data);
    } on FormatException {
      // A truncated or corrupted image is not worth failing the whole result
      // for; the numbers are still useful on their own.

      return null;
    }
  }
}
