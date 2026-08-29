/// Keeps the blood pressure analyses in the user's own Pod.
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
        deleteFile,
        getDirUrl,
        getResourcesInContainer,
        readPod,
        writePod;

import 'package:healthpod/features/bp/analyser/model.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';
import 'package:healthpod/utils/get_feature_path.dart';
import 'package:healthpod/utils/resolve_pod_file_url.dart';

/// The analyses the Analyser has returned, kept in the user's own Pod.
///
/// The Analyser publishes each result in its own Pod and shares it back, but
/// that copy is replaced by the next run and is out of the user's hands. The
/// copies here are theirs: encrypted like everything else in the Pod,
/// available on any device they log in from, and readable without the
/// Analyser being reachable at all.
///
/// Every analysis is kept, one file per run, named for when the analyser
/// produced it. The document stored is the analyser's own, so reading one
/// back goes through the same [AnalyserResult.fromJson] as reading it live.
///
/// They sit in their own folder rather than among the observations:
/// everything in the blood pressure folder is offered to the Analyser when
/// sharing, and an analysis is not an observation.

class BPAnalysisStore {
  /// The folder holding the analyses, under `healthpod/data`.

  static const String folder = 'analysis';

  /// What every analysis file is called, either side of its timestamp.

  static const String filePrefix = 'bp-analysis-';
  static const String fileSuffix = '.json.enc.ttl';

  /// The name an analysis produced at [generatedAt] is kept under.
  ///
  /// The timestamp is local, so the name matches the time shown against it.

  static String fileNameFor(DateTime generatedAt) => '$filePrefix'
      '${formatTimestampForFilename(generatedAt.toLocal())}'
      '$fileSuffix';

  /// When the analysis in [fileName] was produced, or null when the name is
  /// not one of ours.

  static DateTime? timestampOf(String fileName) {
    if (!fileName.startsWith(filePrefix) || !fileName.endsWith(fileSuffix)) {
      return null;
    }

    final stamp = fileName.substring(
      filePrefix.length,
      fileName.length - fileSuffix.length,
    );

    // The name is ISO 8601 with the time's colons written as hyphens, since
    // a colon is no good in a filename. Putting them back gives something
    // DateTime can read.

    final parts = stamp.split('T');
    if (parts.length != 2) return null;

    return DateTime.tryParse('${parts[0]}T${parts[1].replaceAll('-', ':')}');
  }

  /// Where [fileName] sits in the Pod, as the user would find it in the file
  /// browser.

  static String podPath(String fileName) => getFeaturePath(folder, fileName);

  /// Saves [document], the result document as the analyser wrote it, under
  /// the name for [generatedAt], and returns where it was put.
  ///
  /// Returns null when it could not be saved. A failure here is worth
  /// reporting but not worth failing the analysis over: the result is
  /// already on screen.

  static Future<String?> save(
    Map<String, dynamic> document,
    DateTime generatedAt,
  ) async {
    final fileName = fileNameFor(generatedAt);

    try {
      await _ensureFolder();
      await writePod(
        '$folder/$fileName',
        jsonEncode(document),
        encrypted: true,
        overwrite: true,
      );

      return podPath(fileName);
    } catch (e) {
      debugPrint('Could not save the analysis to the Pod: $e');

      return null;
    }
  }

  /// The analyses kept in the Pod, newest first.
  ///
  /// A Pod with no analysis folder yet, and one that cannot be reached, both
  /// come back the same way: nothing to show.

  static Future<List<String>> list() async {
    try {
      final url = await getDirUrl(getFeaturePath(folder));
      final resources = await getResourcesInContainer(url);

      final files = [
        for (final file in resources.files)
          if (timestampOf(file) != null) file,
      ];

      // Newest first: the one the user most likely wants is at the top.

      files.sort((a, b) => timestampOf(b)!.compareTo(timestampOf(a)!));

      return files;
    } catch (e) {
      debugPrint('Could not list the saved analyses: $e');

      return [];
    }
  }

  /// The analysis kept in [fileName], or null when it cannot be read.

  static Future<AnalyserResult?> load(String fileName) async {
    try {
      final content = await readPod('$folder/$fileName');
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return null;

      return AnalyserResult.fromJson(decoded);
    } catch (e) {
      debugPrint('Could not read the saved analysis $fileName: $e');

      return null;
    }
  }

  /// Removes [fileName] from the Pod.
  ///
  /// A file the server reports as missing counts as deleted: on the web a
  /// delete can succeed and still raise a not-found error.

  static Future<bool> delete(String fileName) async {
    try {
      await deleteFile(fileUrl: await resolvePodFileUrl(podPath(fileName)));

      return true;
    } catch (e) {
      final message = '$e';
      if (message.contains('404') ||
          message.contains('NotFoundHttpError') ||
          message.contains('not found')) {
        return true;
      }

      debugPrint('Could not delete the analysis $fileName: $e');

      return false;
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
