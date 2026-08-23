/// Sharing blood pressure readings with the Analyser Pod.
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

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart'
    show
        AccessMode,
        RecipientType,
        SolidFunctionCallStatus,
        getDirUrl,
        getResourcesInContainer,
        getWebId,
        grantPermission;
import 'package:solidui/solidui.dart' show getKeyFromUserIfRequired;

import 'package:healthpod/constants/analyser.dart';
import 'package:healthpod/utils/get_feature_path.dart';

/// Why a share attempt could not even begin.

enum ShareFailure {
  /// The user is not logged in to a Pod.

  notLoggedIn,

  /// There are no readings in the Pod to share.

  noData,

  /// The Analyser Pod has not been set up with the HealthPod folder
  /// structure, so it cannot be given a key.

  analyserNotInitialised,

  /// Anything else, with the message carried alongside.

  error,
}

/// The outcome of sharing every reading with the Analyser.

class AnalyserShareResult {
  const AnalyserShareResult({
    required this.shared,
    required this.total,
    this.failure,
    this.message,
    this.failedFiles = const [],
  });

  /// How many readings were shared successfully.

  final int shared;

  /// How many readings were attempted.

  final int total;

  /// Set when the share could not be carried out at all.

  final ShareFailure? failure;

  /// A message suitable for showing to the user.

  final String? message;

  /// Readings that could not be shared, if any.

  final List<String> failedFiles;

  /// Whether every reading was shared.

  bool get isCompleteSuccess => failure == null && total > 0 && shared == total;

  /// Whether some readings were shared and others were not.

  bool get isPartial => failure == null && shared > 0 && shared < total;
}

/// Grants the Analyser Pod read access to the user's blood pressure readings.
///
/// HealthPod encrypts each reading with its own key, so sharing the folder
/// alone would hand over a key that unlocks nothing. Each reading is therefore
/// granted individually, which is also what the sharing dialogue does when a
/// user selects several files by hand.
///
/// Readings recorded after this runs are not shared automatically: they are
/// new resources with new keys, and the user has to share again. That is a
/// property of the Solid sharing model rather than a limitation here, and the
/// interface says so before asking the user to confirm.

class BPAnalyserShareService {
  /// The feature folder holding the readings, under `healthpod/data`.

  static const String feature = 'blood_pressure';

  /// Extensions worth offering to the analyser. Everything else in the folder
  /// (notably `.acl` files) is skipped.

  static const List<String> _shareableSuffixes = ['.enc.ttl', '.json'];

  /// Whether a resource in the blood pressure folder is a reading to share.

  static bool isShareable(String fileName) =>
      _shareableSuffixes.any(fileName.endsWith);

  /// The permissions the Analyser is granted: read, and nothing more.
  ///
  /// `grantPermission()` declares this as a list of dynamic, but internally
  /// casts each entry to a String before passing it to `getAccessMode()`, so
  /// the mode name is what has to be sent rather than the enum value itself.
  /// Taking the name from the enum keeps it in step with solidpod, which is
  /// also what solidui's sharing form does.

  static final List<String> permissions = [AccessMode.read.mode];

  /// Lists the readings that would be shared, without sharing anything.
  ///
  /// Used to tell the user how many readings are involved before they commit.

  static Future<List<String>> listShareableFiles() async {
    final dirUrl = await getDirUrl(getFeaturePath(feature));
    final resources = await getResourcesInContainer(dirUrl);

    return [
      for (final file in resources.files)
        if (isShareable(file)) file,
    ];
  }

  /// Shares every reading with the Analyser Pod.
  ///
  /// [onProgress] is called after each reading with the number completed and
  /// the total, so the caller can show progress on a long run.

  static Future<AnalyserShareResult> shareAll(
    BuildContext context, {
    void Function(int completed, int total)? onProgress,
  }) async {
    try {
      final ownerWebId = await getWebId();
      if (ownerWebId == null || ownerWebId.isEmpty) {
        return const AnalyserShareResult(
          shared: 0,
          total: 0,
          failure: ShareFailure.notLoggedIn,
          message: 'Please log in to your Pod before sharing.',
        );
      }

      final files = await listShareableFiles();
      if (files.isEmpty) {
        return const AnalyserShareResult(
          shared: 0,
          total: 0,
          failure: ShareFailure.noData,
          message: 'There are no blood pressure readings to share yet.',
        );
      }

      // Granting access re-encrypts the resource key for the recipient, which
      // needs the security key. Prompt for it once, before the loop.

      if (!context.mounted) {
        return const AnalyserShareResult(shared: 0, total: 0);
      }
      await getKeyFromUserIfRequired(
        context,
        const Text(
          'Please enter your security key to share your blood pressure data',
        ),
      );

      var shared = 0;
      final failed = <String>[];
      var analyserNotInitialised = false;

      for (final file in files) {
        final status = await grantPermission(
          fileName: '$feature/$file',
          permissionList: permissions,
          recipientType: RecipientType.individual,
          recipientWebIdList: [Analyser.webId],
          ownerWebId: ownerWebId,
          granterWebId: ownerWebId,
        );

        switch (status) {
          case SolidFunctionCallStatus.success:
            shared++;
          case SolidFunctionCallStatus.notInitialised:
            // The recipient Pod lacks the key structure; every other reading
            // would fail the same way, so stop here rather than grinding
            // through the whole folder.

            analyserNotInitialised = true;
          default:
            failed.add(file);
            debugPrint('Could not share $file with the Analyser: $status');
        }

        if (analyserNotInitialised) break;

        onProgress?.call(shared + failed.length, files.length);
      }

      if (analyserNotInitialised) {
        return AnalyserShareResult(
          shared: shared,
          total: files.length,
          failure: ShareFailure.analyserNotInitialised,
          message:
              'The ${Analyser.displayName} Pod is not set up to receive data '
              'yet. Please ask the administrator to initialise it.',
        );
      }

      return AnalyserShareResult(
        shared: shared,
        total: files.length,
        failedFiles: failed,
      );
    } catch (e) {
      debugPrint('Error sharing blood pressure data with the Analyser: $e');
      return AnalyserShareResult(
        shared: 0,
        total: 0,
        failure: ShareFailure.error,
        message: 'Could not share the data: $e',
      );
    }
  }
}
