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

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:solidpod/solidpod.dart'
    show
        KeyManager,
        SolidFunctionCallStatus,
        agentStr,
        deleteFile,
        getDirUrl,
        getFileUrl,
        getRecipientType,
        getResource,
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
/// The same applies to an observation encrypted with some other inherited
/// key, except that it is read before anything is revoked: only a file with
/// a key of its own can have been decrypted in place by a public share, and
/// one whose key turns out to be missing is then left exactly as it was.
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
  final hasOwnKey = await hasOwnObservationKey(feature, file);

  if (hasOwnKey) await _revokeAllRecipients(filePath, ownerWebId);

  final content = await readPod(filePath);

  // Older solidpod releases reported a failed read as a status string rather
  // than throwing. Writing that back would replace the observation with it.

  if (content == SolidFunctionCallStatus.fail.toString() ||
      content == SolidFunctionCallStatus.notLoggedIn.toString()) {
    throw Exception('Could not read $filePath: $content');
  }

  if (!hasOwnKey) await _revokeAllRecipients(filePath, ownerWebId);

  await writeHealthRecord(filePath, content, overwrite: true);

  await _deleteOwnAcl(feature, file);

  if (hasOwnKey) await KeyManager.removeIndividualKey(resourcePath: podPath);
}

/// Hands a plaintext observation over to its folder's ACL.
///
/// Its content needs no key, so nothing is rewritten: every recipient's
/// access is revoked and its own ACL, if it has one, is deleted, after which
/// whoever the folder is shared with can read it.

Future<void> releaseObservationAcl({
  required String feature,
  required String file,
  required String ownerWebId,
}) async {
  await _revokeAllRecipients('$feature/$file', ownerWebId);
  await _deleteOwnAcl(feature, file);
}

/// Deletes the ACL of [file] in [feature], if it has one.

Future<void> _deleteOwnAcl(String feature, String file) async {
  final fileUrl = await getFileUrl(getFeaturePath(feature, file));
  try {
    // isKey asks deleteFile() for the bare delete: an ACL has no key or
    // shares of its own to clear away first.

    await deleteFile(fileUrl: '$fileUrl.acl', isKey: true);
  } catch (e) {
    // An observation that never had an ACL has nothing to delete.

    debugPrint('No ACL to delete for $feature/$file: $e');
  }
}

/// How an observation without a key of its own is stored on the server.

enum ObservationStorage {
  /// Encrypted with its own folder's key: sharing the folder shares it.

  folderKey,

  /// Not encrypted at all. Readable through the folder's ACL, unless it has
  /// an ACL of its own.

  plaintext,

  /// Encrypted with the key of some other folder, which the document names.

  otherFolderKey,

  /// Encrypted, but naming no folder's key while having no key of its own
  /// either: the key it was encrypted with has been lost.

  keyLost,
}

/// The `inheritKeyFrom` value of a solidpod-encrypted document, prefixed or
/// written out in full by the server.

final RegExp _inheritKeyPattern = RegExp(r'inheritKeyFrom>?\s+"([^"]*)"');

/// The `encData` predicate every solidpod-encrypted document carries.

final RegExp _encDataPattern = RegExp(r'encData>?\s+"');

/// Classifies the stored content of an observation that has no key of its
/// own, along with the folder, relative to the Pod root and ending in a
/// slash, whose key it names.
///
/// A file without a key of its own is not necessarily on its folder's key: it
/// may be plaintext, or encrypted with a key that has since been lost. Only
/// the document itself says which, so this reads it as stored, without
/// decrypting anything. Pure so that it can be tested without a Pod.

({ObservationStorage storage, String? keyFolder}) classifyObservationContent(
  String content,
  String feature,
) {
  if (!_encDataPattern.hasMatch(content)) {
    return (storage: ObservationStorage.plaintext, keyFolder: null);
  }

  final match = _inheritKeyPattern.firstMatch(content);
  if (match == null) {
    return (storage: ObservationStorage.keyLost, keyFolder: null);
  }

  var named = match.group(1)!.trim();
  if (named.startsWith('/')) named = named.substring(1);
  if (!named.endsWith('/')) named = '$named/';

  return (
    storage: named == '${getFeaturePath(feature)}/'
        ? ObservationStorage.folderKey
        : ObservationStorage.otherFolderKey,
    keyFolder: named,
  );
}

/// Reads [file] in [feature] as stored and classifies it; see
/// [classifyObservationContent]. A file naming some other folder whose key
/// this Pod does not hold is reported as [ObservationStorage.keyLost], since
/// nothing here can decrypt it. Throws when the file cannot be fetched.

Future<ObservationStorage> inspectObservation(
  String feature,
  String file,
) async {
  final fileUrl = await getFileUrl(getFeaturePath(feature, file));
  final content = utf8.decode(await getResource(fileUrl));
  final (:storage, :keyFolder) = classifyObservationContent(content, feature);

  if (storage == ObservationStorage.otherFolderKey &&
      !await KeyManager.hasIndividualKey(await getDirUrl(keyFolder!))) {
    return ObservationStorage.keyLost;
  }

  return storage;
}

/// Remembers, on this device, which observations have been confirmed to be on
/// their folder's key, so each is read once rather than on every share.
///
/// The app only ever rewrites an observation under its folder's key, so a
/// confirmed file stays confirmed. A file changed by some other tool could
/// fall out of step; it would then show up as unreadable in the analysis
/// rather than as a reading that failed to share.

class ConfirmedObservations {
  ConfirmedObservations._(this._prefsKey, this._files);

  final String _prefsKey;
  final Set<String> _files;

  /// Loads the record for [feature] in the Pod of [webId].

  static Future<ConfirmedObservations> load(
    String webId,
    String feature,
  ) async {
    final prefsKey = 'healthpod.confirmedFolderKey.$webId.$feature';
    var files = <String>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      files = (prefs.getStringList(prefsKey) ?? const <String>[]).toSet();
    } catch (e) {
      debugPrint('Could not load the confirmed observations: $e');
    }

    return ConfirmedObservations._(prefsKey, files);
  }

  /// Whether [file] has been confirmed.

  bool contains(String file) => _files.contains(file);

  /// Marks [file] as confirmed.

  void add(String file) => _files.add(file);

  /// Saves the record, keeping only files still in [present] so that it does
  /// not grow with readings that have since been deleted.

  Future<void> save(Iterable<String> present) async {
    _files.retainAll(present.toSet());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _files.toList()..sort());
    } catch (e) {
      debugPrint('Could not save the confirmed observations: $e');
    }
  }
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
