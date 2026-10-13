/// Observation folders whose files share the folder's key and ACL.
//
// Time-stamp: <Tuesday 2026-10-13 10:00:00 +1100>
//
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

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:solidpod/solidpod.dart'
    show
        KeyManager,
        SolidFunctionCallStatus,
        agentStr,
        deleteFile,
        getDirUrl,
        getFileUrl,
        getRecipientType,
        permStr,
        readPermission,
        readPod,
        revokePermission,
        setInheritKeyDir,
        writePod;

import 'package:healthpod/utils/get_feature_path.dart';

/// Feature folders, under `healthpod/data`, holding observations.
///
/// An observation written into one of these folders is encrypted with the
/// folder's key rather than a key of its own, and gets no ACL of its own, so
/// the Pod server falls back to the folder's ACL. Sharing the folder then
/// shares every observation in it, present and future, with two edits — the
/// folder's ACL and the recipient's `shared-keys.ttl` — instead of two per
/// observation.

const Set<String> observationFolders = {'blood_pressure'};

/// The observation folder whose key encrypts [filePath], or null when
/// [filePath] (relative to `healthpod/data`) is not inside one.

String? observationKeyFolder(String filePath) {
  final path = filePath.startsWith('/') ? filePath.substring(1) : filePath;
  final slash = path.indexOf('/');
  if (slash <= 0) return null;

  final folder = path.substring(0, slash);
  return observationFolders.contains(folder) ? folder : null;
}

/// Writes an encrypted health record to [filePath], relative to
/// `healthpod/data`.
///
/// Inside an observation folder the record inherits the folder's key and ACL;
/// anywhere else it is written as before, with a key and an ACL of its own.

Future<void> writeHealthRecord(
  String filePath,
  String content, {
  bool overwrite = false,
}) async {
  final folder = observationKeyFolder(filePath);

  await writePod(
    filePath,
    content,
    encrypted: true,
    overwrite: overwrite,
    inheritKeyFrom: folder,
    createAcl: folder == null,
  );
}

/// Makes sure the observation folder [feature] has a key of its own.
///
/// writePod() creates the key on first use, but it checks and adds it without
/// a lock, so several writes started together on a folder without a key would
/// each create one and all but the last would encrypt with a key that is then
/// lost. Writers that overlap call this first. Sharing calls it too: granting
/// access to a folder that has no key hands the recipient nothing to decrypt
/// with.

Future<void> ensureObservationFolderKey(String feature) async {
  final dirUrl = await getDirUrl(getFeaturePath(feature));
  if (await KeyManager.hasIndividualKey(dirUrl)) return;

  await setInheritKeyDir(dirUrl, createAcl: false);
}

/// Whether [file] in the observation folder [feature] still has a key of its
/// own, which marks an observation written before observations inherited
/// their folder's key.
///
/// The individual keys are held in memory once loaded, so this costs no
/// request per file.

Future<bool> hasOwnObservationKey(String feature, String file) async =>
    KeyManager.hasIndividualKey(
      await getFileUrl(getFeaturePath(feature, file)),
    );

/// Converts an observation written with its own key and ACL to one that
/// inherits both from its folder.
///
/// In order, so that a failure part way through never loses the observation:
///
/// 1. Revoke every recipient's access to it. This removes their copy of its
///    key and, for a public share, re-encrypts the file in place, so what is
///    read next is the encrypted original rather than plaintext.
/// 2. Read it, and write it back over itself under the folder's key.
/// 3. Delete its own ACL, so the folder's ACL applies to it.
/// 4. Drop its own key, which no longer decrypts anything.
///
/// The folder must already have a key; see [ensureObservationFolderKey].
/// Throws when the observation cannot be read or rewritten.

Future<void> adoptObservationFolderKey({
  required String feature,
  required String file,
  required String ownerWebId,
}) async {
  final filePath = '$feature/$file';
  final podPath = getFeaturePath(feature, file);

  await _revokeAllRecipients(filePath, ownerWebId);

  final content = await readPod(filePath);

  // Older solidpod releases reported a failed read as a status string rather
  // than throwing. Writing that back would replace the observation with it.

  if (content == SolidFunctionCallStatus.fail.toString() ||
      content == SolidFunctionCallStatus.notLoggedIn.toString()) {
    throw Exception('Could not read $filePath: $content');
  }

  await writeHealthRecord(filePath, content, overwrite: true);

  final fileUrl = await getFileUrl(podPath);
  try {
    // isKey asks deleteFile() for the bare delete: an ACL has no key or
    // shares of its own to clear away first.

    await deleteFile(fileUrl: '$fileUrl.acl', isKey: true);
  } catch (e) {
    // An observation that never had an ACL has nothing to delete.

    debugPrint('No ACL to delete for $filePath: $e');
  }

  await KeyManager.removeIndividualKey(resourcePath: podPath);
}

/// Revokes the access of everyone but [ownerWebId] to the file at
/// [filePath], relative to `healthpod/data`.
///
/// A file that was never shared has no ACL of its own, and reading its
/// permissions throws; there is then nothing to revoke.

Future<void> _revokeAllRecipients(String filePath, String ownerWebId) async {
  final Map<dynamic, dynamic> permissions;
  try {
    permissions = await readPermission(fileName: filePath, isFile: true);
  } catch (e) {
    return;
  }

  for (final entry in permissions.entries) {
    final recipient = entry.key.toString();
    if (recipient == ownerWebId) continue;

    final record = entry.value as Map;
    final recipientType = getRecipientType(
      record[agentStr] as String,
      recipient,
    );

    await revokePermission(
      fileName: filePath,
      permissionList: record[permStr] as List,
      recipientIndOrGroupWebId: recipient,
      ownerWebId: ownerWebId,
      granterWebId: ownerWebId,
      recipientType: recipientType,
    );
  }
}
