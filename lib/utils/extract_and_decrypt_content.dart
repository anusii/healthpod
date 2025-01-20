/// Extract and decrypt content.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';
import 'package:solidpod/solidpod.dart';
import 'package:encrypt/encrypt.dart';

/// Extracts and decrypts content from a TTL file.
///
/// Takes the raw TTL content string and returns the decrypted file content.
/// Throws an exception if required fields are missing or parsing fails.

Future<String> extractAndDecryptContent(String ttlContent) async {
  // Extract resource URL using a specific pattern.

  final urlPattern = RegExp(r'<(https://[^>]+\.json\.enc\.ttl)>');
  final urlMatch = urlPattern.firstMatch(ttlContent);

  // Extract IV and encrypted data.

  final ivMatch = RegExp(r'solidTerms:iv\s+"([^"]+)"').firstMatch(ttlContent);
  final encDataMatch =
      RegExp(r'solidTerms:encData\s+"([^"]+)"').firstMatch(ttlContent);

  if (ivMatch == null || encDataMatch == null || urlMatch == null) {
    throw Exception('Could not parse TTL content. Missing required fields.');
  }

  // Extract the values and clean them up.

  String ivString = ivMatch.group(1)!.replaceAll(r'^^xsd:string', '').trim();
  String encryptedData =
      encDataMatch.group(1)!.replaceAll(r'^^xsd:string', '').trim();
  String resourceUrl = urlMatch.group(1)!.trim();

  debugPrint('Found IV: $ivString');
  debugPrint('Found URL: $resourceUrl');
  debugPrint(
      'Found encrypted data (first 50 chars): ${encryptedData.substring(0, 50)}...');

  // Get the individual key for the file.

  final indKey = await KeyManager.getIndividualKey(resourceUrl);

  // Create IV object from base64 string.

  final iv = IV.fromBase64(ivString);

  // Decrypt the data.

  return decryptData(encryptedData, indKey, iv);
}
