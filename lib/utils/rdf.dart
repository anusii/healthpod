/// Common utilities for working on RDF data.
///
// Time-stamp: <Wednesday 2024-07-10 09:49:30 +1000 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
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
/// Authors: Dawei Chen

// TODO 20240708 gjw CAN ANY OF THIS GO TO RDFLIB?

library;

import 'package:rdflib/rdflib.dart';

import 'package:solidpod/solidpod.dart' show getWebId;

// Namespace for keys

const String appTerms = 'https://solidcommunity.au/predicates/terms#';

/// Serialise key/value pairs [keyValuePairs] in TTL format where
/// Subject: Web ID
/// Predicate: Key
/// Object: Value

Future<String> genTTLStr(
  List<({String key, dynamic value})> keyValuePairs,
) async {
  assert(keyValuePairs.isNotEmpty);
  assert(
    {for (final p in keyValuePairs) p.key}.length == keyValuePairs.length,
  ); // No duplicate keys
  final webId = await getWebId();
  assert(webId != null);
  final g = Graph();
  final f = URIRef(webId!);
  final ns = Namespace(ns: appTerms);

  for (final p in keyValuePairs) {
    g.addTripleToGroups(f, ns.withAttr(p.key), p.value);
  }

  g.serialize(abbr: 'short');

  return g.serializedString;
}

/// Parse TTL string [ttlStr] and returns the key-value pairs from triples where
/// Subject: Web ID
/// Predicate: Key
/// Object: Value

// TODO 20240710 gjw COULD THIS USE rdflib::parseTTL

Future<List<({String key, dynamic value})>> parseTTLStr(String ttlStr) async {
  // TODO 20240710 gjw COMMENT THAT WE COULD DO WITH USING MORE asserts()

  assert(ttlStr.isNotEmpty);
  final g = Graph();
  g.parseTurtle(ttlStr);
  final keys = <String>{};
  final pairs = <({String key, dynamic value})>[];
  final webId = await getWebId();
  assert(webId != null);
  String extract(String str) => str.contains('#') ? str.split('#')[1] : str;
  for (final t in g.triples) {
    final sub = t.sub.value as String;
    if (sub == webId) {
      final pre = extract(t.pre.value as String);
      final obj = extract(t.obj.value as String);
      assert(!keys.contains(pre));
      keys.add(pre);
      pairs.add((key: pre, value: obj));
    }
  }
  return pairs;
}
