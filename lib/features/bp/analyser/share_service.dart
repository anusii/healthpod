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
        WebIdStatus,
        checkWebIdProfile,
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
import 'package:healthpod/utils/observation_folder_key.dart';

/// Why a share or revoke attempt could not even begin.

enum ShareFailure {
  /// The user is not logged in to a Pod.

  notLoggedIn,

  /// There are no readings in the Pod to share.

  noData,

  /// The Analyser Pod has not been set up with the HealthPod folder
  /// structure, so it cannot be given a key.

  analyserNotInitialised,

  /// The Analyser Pod did not answer, so whether it is set up is unknown.

  analyserUnreachable,

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
    this.cancelled = false,
  });

  /// How many readings the Analyser can now read through the shared folder.

  final int shared;

  /// How many readings were attempted.

  final int total;

  /// Set when the share could not be carried out at all.

  final ShareFailure? failure;

  /// A message suitable for showing to the user.

  final String? message;

  /// Older readings that could not be moved onto the folder's key, and so
  /// are not visible to the Analyser, if any.

  final List<String> failedFiles;

  /// Whether the user stopped the sharing part way through.
  ///
  /// The folder stays shared, and with it every reading already on the
  /// folder's key: withdrawing that is a separate decision, made with Revoke
  /// Permissions or in the file browser, and undoing it silently would be a
  /// surprise. [shared] says how many readings the Analyser can read.

  final bool cancelled;

  /// Whether every reading was shared.

  bool get isCompleteSuccess =>
      failure == null && !cancelled && total > 0 && shared == total;

  /// Whether some readings were shared and others were not.

  bool get isPartial =>
      failure == null && !cancelled && shared > 0 && shared < total;
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

  /// How many readings the Analyser can no longer read.

  final int revoked;

  /// How many readings the Analyser could read when the run began.

  final int shared;

  /// Set when the revoke could not be carried out at all.

  final ShareFailure? failure;

  /// A message suitable for showing to the user.

  final String? message;

  /// Resources whose access could not be revoked, if any: the folder, or an
  /// older reading shared on its own.

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
/// Readings are encrypted with the key of the blood pressure folder and have
/// no ACL of their own, so the Pod server applies the folder's ACL to them.
/// Sharing is therefore two edits however many readings there are: the
/// folder's ACL, and the folder's key in the Analyser's `shared-keys.ttl`.
/// Readings recorded afterwards are shared as well, for as long as the folder
/// is.
///
/// Readings written before this arrangement carry their own key and ACL, and
/// the folder's share does not reach them. [shareAll] moves each onto the
/// folder's key the first time it meets it; after that the reading behaves
/// like any other.
///
/// [revokeAll] is the counterpart: it revokes the Analyser's access to the
/// folder, and to any older reading that was shared on its own, reading each
/// ACL to find out what was actually granted rather than assuming a previous
/// share succeeded.

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

  /// The readings among [files] that still carry a key of their own.
  ///
  /// Answered from the individual keys solidpod already holds in memory, so
  /// it costs no request per reading.

  static Future<List<String>> _ownKeyFiles(List<String> files) async => [
        for (final file in files)
          if (await hasOwnObservationKey(feature, file)) file,
      ];

  /// Shares every reading with the Analyser Pod by sharing their folder.
  ///
  /// [onProgress] is called with the number of readings the Analyser can read
  /// and the total: once after the folder is shared, then after each older
  /// reading is moved onto the folder's key.
  ///
  /// [isCancelled] is consulted before the folder is shared and before each
  /// older reading is moved. A move already under way is left to finish: it
  /// rewrites the reading on the server, and abandoning it half done would be
  /// worse than letting one more reading through.

  static Future<AnalyserShareResult> shareAll(
    BuildContext context, {
    void Function(int completed, int total)? onProgress,
    bool Function()? isCancelled,
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
          message: 'There are no blood pressure observations to share yet.',
        );
      }

      // Granting access re-encrypts the folder's key for the recipient, and
      // moving older readings decrypts and re-encrypts them; both need the
      // security key. Prompt for it once, up front.

      if (!context.mounted) {
        return const AnalyserShareResult(shared: 0, total: 0);
      }
      await getKeyFromUserIfRequired(
        context,
        const Text(
          'Please enter your security key to share your blood pressure data',
        ),
      );

      if (isCancelled?.call() ?? false) {
        return AnalyserShareResult(
          shared: 0,
          total: files.length,
          cancelled: true,
        );
      }

      // The folder needs its key before it is shared: granting access to a
      // folder without one hands the Analyser nothing to decrypt with.

      await ensureObservationFolderKey(feature);

      final status = await grantPermission(
        fileName: feature,
        isFile: false,
        permissionList: permissions,
        recipientType: RecipientType.individual,
        recipientWebIdList: [Analyser.webId],
        ownerWebId: ownerWebId,
        granterWebId: ownerWebId,
      );

      if (status == SolidFunctionCallStatus.notInitialised) {
        // solidpod reports a Pod it could not look at as uninitialised, so
        // ask whether the Pod is answering at all before telling the user
        // that nobody has set it up.

        final reachable = await _analyserIsReachable();

        return AnalyserShareResult(
          shared: 0,
          total: files.length,
          failure: reachable
              ? ShareFailure.analyserNotInitialised
              : ShareFailure.analyserUnreachable,
          message: reachable
              ? 'The ${Analyser.displayName} Pod is not set up to receive '
                  'data yet. Please ask the administrator to initialise it.'
              : 'The ${Analyser.displayName} Pod could not be reached at '
                  '${Analyser.webId} — its server did not return a profile. '
                  'It may be down; please try again shortly.',
        );
      }

      if (status != SolidFunctionCallStatus.success) {
        debugPrint('Could not share $feature with the Analyser: $status');
        return AnalyserShareResult(
          shared: 0,
          total: files.length,
          failure: ShareFailure.error,
          message: 'Could not share your blood pressure folder with the '
              '${Analyser.displayName}. Please try again in a moment.',
        );
      }

      // Every reading already on the folder's key is shared now. The rest
      // were written with keys of their own and are moved one at a time.

      final ownKeyFiles = await _ownKeyFiles(files);
      var shared = files.length - ownKeyFiles.length;
      final failed = <String>[];
      var cancelled = false;

      onProgress?.call(shared, files.length);

      for (final file in ownKeyFiles) {
        if (isCancelled?.call() ?? false) {
          cancelled = true;
          break;
        }

        try {
          await adoptObservationFolderKey(
            feature: feature,
            file: file,
            ownerWebId: ownerWebId,
          );
          shared++;
        } catch (e) {
          // One stubborn reading must not stop the rest coming over.

          failed.add(file);
          debugPrint('Could not move $file onto the folder key: $e');
        }

        onProgress?.call(shared + failed.length, files.length);
      }

      return AnalyserShareResult(
        shared: shared,
        total: files.length,
        failedFiles: failed,
        cancelled: cancelled,
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

  /// Whether the Analyser Pod is answering for its own WebID.
  ///
  /// Its profile document is public, so this needs no permissions and says
  /// what a failed grant cannot: a Pod that is down, or refusing requests,
  /// looks exactly like a Pod nobody has set up.

  static Future<bool> _analyserIsReachable() async {
    try {
      return await checkWebIdProfile(Analyser.webId) == WebIdStatus.valid;
    } catch (e) {
      debugPrint('Could not reach the Analyser Pod: $e');

      return false;
    }
  }

  /// The permissions the Analyser holds in [permissions], or null when it
  /// holds none.

  static List<dynamic>? _analyserEntry(Map<dynamic, dynamic> permissions) {
    final entry = permissions[Analyser.webId];
    if (entry == null) return null;

    final granted = (entry as Map)[permStr] as List?;
    return (granted == null || granted.isEmpty) ? null : granted;
  }

  /// The permissions the Analyser currently holds over the reading at
  /// [filePath], or null when it holds none.
  ///
  /// A reading that has never been shared has no ACL file of its own, and
  /// reading its permissions throws. That is not an error worth surfacing:
  /// there is simply nothing to revoke, so it is reported the same way as
  /// an ACL that names no Analyser.

  static Future<List<dynamic>?> _analyserFilePermissions(
    String filePath,
  ) async {
    try {
      return _analyserEntry(
        await readPermission(fileName: filePath, isFile: true),
      );
    } catch (e) {
      debugPrint('Could not read the permissions on $filePath: $e');
      return null;
    }
  }

  /// The permissions the Analyser currently holds over the blood pressure
  /// folder, or null when it holds none.
  ///
  /// The ACL is named by its own URL: asked for a folder, readPermission()
  /// appends `/.acl` to a URL that already ends in a slash and reads a
  /// resource that does not exist.

  static Future<List<dynamic>?> _analyserFolderPermissions() async {
    try {
      final dirUrl = await getDirUrl(getFeaturePath(feature));
      return _analyserEntry(
        await readPermission(
          fileName: '$dirUrl.acl',
          isFile: false,
          isFileUrl: true,
        ),
      );
    } catch (e) {
      debugPrint('Could not read the permissions on $feature: $e');
      return null;
    }
  }

  /// Whether the Analyser currently holds access to the folder or to any of
  /// [files].
  ///
  /// Used to decide whether there is anything for Revoke Permissions to do.
  /// The folder is asked first, and on a Pod that has shared it that single
  /// ACL read is the answer. Only readings with keys of their own can have
  /// been shared on their own, so those are the only ACLs read after that.

  static Future<bool> isAnyShared(List<String> files) async {
    if (await _analyserFolderPermissions() != null) return true;

    for (final file in await _ownKeyFiles(files)) {
      if (await _analyserFilePermissions('$feature/$file') != null) {
        return true;
      }
    }

    return false;
  }

  /// Revokes the Analyser Pod's access to every blood pressure reading.
  ///
  /// The folder's share is revoked first, which takes back every reading on
  /// the folder's key and removes the Analyser's copy of that key. Older
  /// readings shared on their own, before they were moved onto the folder's
  /// key, are then revoked one by one.
  ///
  /// Results the Analyser has already shared back are left alone: they belong
  /// to the Analyser's Pod, not the user's, and hold no individual readings.
  ///
  /// [onProgress] is called with the number of readings examined and the
  /// total: once after the folder, covering every reading on its key, then
  /// after each older reading.

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
      final ownKeyFiles = await _ownKeyFiles(files);
      final folderFiles = files.length - ownKeyFiles.length;

      var shared = 0;
      var revoked = 0;
      final failed = <String>[];

      final folderGranted = await _analyserFolderPermissions();
      if (folderGranted != null) {
        shared += folderFiles;

        final status = await revokePermission(
          fileName: feature,
          isFile: false,
          permissionList: folderGranted,
          recipientIndOrGroupWebId: Analyser.webId,
          ownerWebId: ownerWebId,
          granterWebId: ownerWebId,
          recipientType: RecipientType.individual,
        );

        if (status != SolidFunctionCallStatus.success) {
          // Every reading on the folder's key stays readable, so this is
          // a failure rather than a partial success.

          debugPrint(
            'Could not revoke the Analyser\'s access to $feature: $status',
          );
          return AnalyserRevokeResult(
            revoked: 0,
            shared: shared,
            failure: ShareFailure.error,
            message: 'Could not revoke the ${Analyser.displayName}\'s access '
                'to your blood pressure folder. Please try again in a moment.',
          );
        }

        revoked += folderFiles;
      }

      var examined = folderFiles;
      onProgress?.call(examined, files.length);

      for (final file in ownKeyFiles) {
        final filePath = '$feature/$file';
        final granted = await _analyserFilePermissions(filePath);

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
