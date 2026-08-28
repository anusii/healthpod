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
        grantPermission,
        permStr,
        readPermission,
        revokePermission;
import 'package:solidui/solidui.dart' show getKeyFromUserIfRequired;

import 'package:healthpod/constants/analyser.dart';
import 'package:healthpod/utils/get_feature_path.dart';

/// Why a share or revoke attempt could not even begin.

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

/// The outcome of revoking the Analyser's access to every reading.

class AnalyserRevokeResult {
  const AnalyserRevokeResult({
    required this.revoked,
    required this.shared,
    this.failure,
    this.message,
    this.failedFiles = const [],
  });

  /// How many readings had the Analyser's access revoked successfully.

  final int revoked;

  /// How many readings the Analyser held access to when the run began.

  final int shared;

  /// Set when the revoke could not be carried out at all.

  final ShareFailure? failure;

  /// A message suitable for showing to the user.

  final String? message;

  /// Readings whose access could not be revoked, if any.

  final List<String> failedFiles;

  /// Whether the Analyser held no access to revoke in the first place.

  bool get hadNothingShared => failure == null && shared == 0;

  /// Whether every share the Analyser held was revoked.

  bool get isCompleteSuccess =>
      failure == null && shared > 0 && revoked == shared;

  /// Whether some shares were revoked and others were not.

  bool get isPartial => failure == null && revoked > 0 && revoked < shared;
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
///
/// [revokeAll] is the counterpart: it revokes the Analyser's access to
/// every reading it still holds, reading each reading's ACL to find out what
/// was actually granted rather than assuming a previous share succeeded.

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

  /// The permissions the Analyser currently holds over [filePath], or null
  /// when it holds none.
  ///
  /// A reading that has never been shared has no ACL file of its own, and
  /// reading its permissions throws. That is not an error worth surfacing:
  /// there is simply nothing to revoke, so it is reported the same way as
  /// an ACL that names no Analyser.

  static Future<List<dynamic>?> _analyserPermissions(String filePath) async {
    try {
      final permissions = await readPermission(
        fileName: filePath,
        isFile: true,
      );

      final entry = permissions[Analyser.webId];
      if (entry == null) return null;

      final granted = (entry as Map)[permStr] as List?;
      return (granted == null || granted.isEmpty) ? null : granted;
    } catch (e) {
      debugPrint('Could not read the permissions on $filePath: $e');
      return null;
    }
  }

  /// Revokes the Analyser Pod's access to every blood pressure reading.
  ///
  /// Each reading is revoked individually, mirroring [shareAll]: the shares
  /// were granted one resource at a time, so they have to come back the same
  /// way. Revoking also removes the Analyser's copy of each reading's key
  /// from its Pod, so the readings it was shown are no longer readable there.
  ///
  /// Results the Analyser has already shared back are left alone: they belong
  /// to the Analyser's Pod, not the user's, and hold no individual readings.
  ///
  /// [onProgress] is called after each reading is examined with the number
  /// examined and the total, so the caller can show progress on a long run.
  /// Progress counts every reading in the folder, not just the shared ones,
  /// because whether a reading is shared is only known once its ACL is read.

  static Future<AnalyserRevokeResult> revokeAll({
    void Function(int examined, int total)? onProgress,
  }) async {
    try {
      final ownerWebId = await getWebId();
      if (ownerWebId == null || ownerWebId.isEmpty) {
        return const AnalyserRevokeResult(
          revoked: 0,
          shared: 0,
          failure: ShareFailure.notLoggedIn,
          message: 'Please log in to your Pod before revoking access.',
        );
      }

      final files = await listShareableFiles();
      if (files.isEmpty) {
        return const AnalyserRevokeResult(revoked: 0, shared: 0);
      }

      var examined = 0;
      var shared = 0;
      var revoked = 0;
      final failed = <String>[];

      for (final file in files) {
        final filePath = '$feature/$file';
        final granted = await _analyserPermissions(filePath);

        if (granted != null) {
          shared++;

          try {
            // Revoke exactly what the ACL says was granted, so the entry
            // written to the permission logs records the access that was
            // really revoked.

            final status = await revokePermission(
              fileName: filePath,
              permissionList: granted,
              recipientIndOrGroupWebId: Analyser.webId,
              ownerWebId: ownerWebId,
              granterWebId: ownerWebId,
              recipientType: RecipientType.individual,
            );

            if (status == SolidFunctionCallStatus.success) {
              revoked++;
            } else {
              failed.add(file);
              debugPrint(
                'Could not revoke the Analyser\'s access to $file: $status',
              );
            }
          } catch (e) {
            // One stubborn reading must not stop the rest coming back.

            failed.add(file);
            debugPrint(
              'Error revoking the Analyser\'s access to $file: $e',
            );
          }
        }

        examined++;
        onProgress?.call(examined, files.length);
      }

      return AnalyserRevokeResult(
        revoked: revoked,
        shared: shared,
        failedFiles: failed,
      );
    } catch (e) {
      debugPrint('Error revoking the Analyser\'s access: $e');
      return AnalyserRevokeResult(
        revoked: 0,
        shared: 0,
        failure: ShareFailure.error,
        message: 'Could not revoke access: $e',
      );
    }
  }
}
