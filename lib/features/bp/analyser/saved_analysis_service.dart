/// Keeps the latest blood pressure analysis in the user's own Pod.
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

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:solidpod/solidpod.dart'
    show
        ResourceContentType,
        ResourceStatus,
        checkResourceStatus,
        createResource,
        getDirUrl,
        readPod,
        writePod;

import 'package:healthpod/features/bp/analyser/model.dart';
import 'package:healthpod/utils/get_feature_path.dart';

/// The analysis the Analyser last returned, kept in the user's own Pod.
///
/// The Analyser publishes each result in its own Pod and shares it back, but
/// that copy is replaced by the next run and is out of the user's hands. A
/// copy here is theirs: encrypted like everything else in the Pod, available
/// on any device they log in from, and readable without the Analyser being
/// reachable at all.
///
/// Only the most recent analysis is kept — each run replaces the one before
/// it — and the document stored is the analyser's own, so reading it back
/// goes through the same [AnalyserResult.fromJson] as reading it live.
///
/// It sits in its own folder rather than among the observations: everything
/// in the blood pressure folder is offered to the Analyser when sharing, and
/// an analysis is not an observation.

class BPAnalysisStore {
  /// The folder holding the analysis, under `healthpod/data`.

  static const String folder = 'analysis';

  /// The one analysis kept.

  static const String fileName = 'bp-analysis.json.enc.ttl';

  /// Where the analysis sits, relative to the Pod's data folder.

  static const String path = '$folder/$fileName';

  /// Where the analysis sits in the Pod, as the user would find it in the
  /// file browser.

  static String get podPath => getFeaturePath(folder, fileName);

  /// Saves [document], the result document as the analyser wrote it.
  ///
  /// Returns whether it was saved. A failure here is worth reporting but not
  /// worth failing the analysis over: the result is already on screen.

  static Future<bool> save(Map<String, dynamic> document) async {
    try {
      await _ensureFolder();
      await writePod(
        path,
        jsonEncode(document),
        encrypted: true,
        overwrite: true,
      );

      return true;
    } catch (e) {
      debugPrint('Could not save the analysis to the Pod: $e');

      return false;
    }
  }

  /// The analysis kept in the Pod, or null when there is none to read.
  ///
  /// Nothing saved yet, a document from an older format, and a Pod that
  /// cannot be reached all come back the same way: there is nothing to show.

  static Future<AnalyserResult?> load() async {
    try {
      final content = await readPod(path);
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return null;

      return AnalyserResult.fromJson(decoded);
    } catch (e) {
      debugPrint('Could not read the saved analysis: $e');

      return null;
    }
  }

  /// Creates the analysis folder if the Pod does not have it yet.

  static Future<void> _ensureFolder() async {
    final url = await getDirUrl(getFeaturePath(folder));
    final status = await checkResourceStatus(url, isFile: false);
    if (status == ResourceStatus.exist) return;

    await createResource(
      url,
      isFile: false,
      contentType: ResourceContentType.directory,
      replaceIfExist: false,
    );
  }
}
