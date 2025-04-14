/// Common utilities for working on RDF data.
///
// Time-stamp: <Monday 2025-04-14 13:19:30 +1000 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Dawei Chen, Graham Williams

library;

import 'package:rdflib/rdflib.dart';

/// Parses enc-key file information and extracts content into a map.
///
/// This function processes the provided file information, which is expected to be
/// in Turtle (Terse RDF Triple Language) format. It uses a graph-based approach
/// to parse the Turtle data and extract key attributes and their values.

Map<dynamic, dynamic> getEncKeyContent(String fileInfo) {
  final g = Graph();
  g.parseTurtle(fileInfo);
  final fileContentMap = {};
  final fileContentList = [];
  for (final t in g.triples) {
    final predicate = t.pre.value as String;
    if (predicate.contains('#')) {
      final subject = t.sub.value;
      final attributeName = predicate.split('#')[1];
      final attrVal = t.obj.value.toString();
      if (attributeName != 'type') {
        fileContentList.add([subject, attributeName, attrVal]);
      }
      fileContentMap[attributeName] = [subject, attrVal];
    }
  }

  return fileContentMap;
}
