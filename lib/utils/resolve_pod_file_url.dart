/// Utility function for resolving a Pod path to a full resource URL.
//
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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

import 'package:solidpod/solidpod.dart' show filenameToResourceUrl;

/// Resolves a Pod path to the full resource URL that solidpod requires.
///
/// [deleteFile] and the other solidpod resource calls parse their argument as
/// a URI, so a relative path such as `healthpod/data/blood_pressure/x.enc.ttl`
/// fails with "No host specified in URI". Anything that is not already a URL
/// is therefore resolved against the logged in user's Pod first.
///
/// A path may be given relative to the Pod root (`healthpod/data/...`) or
/// relative to the app's data directory (`blood_pressure/...`); both resolve
/// to the same URL. A value that is already a URL is returned unchanged, so
/// this is safe to apply to a path of unknown provenance.
///
/// Example:
/// ```dart
/// final url = await resolvePodFileUrl('healthpod/data/blood_pressure/x.ttl');
/// // Returns: 'https://pod.example/user/healthpod/data/blood_pressure/x.ttl'
/// await deleteFile(fileUrl: url);
/// ```

Future<String> resolvePodFileUrl(String filePath) async =>
    filenameToResourceUrl(fileName: filePath);
