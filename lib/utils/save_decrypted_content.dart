/// Save decrypted content.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU
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
/// Authors: Ashley Tang

library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:healthpod/utils/is_text_file.dart';

/// Renders decrypted content as the bytes to write for [fileName].
///
/// The counterpart to [saveDecryptedContent] for callers that hand the bytes
/// to a save dialogue which does the writing itself. Formats as JSON where
/// the content parses as JSON, and otherwise falls back to binary or text
/// based on the file type, exactly as [saveDecryptedContent] does.

Uint8List decryptedContentBytes(String decryptedContent, String fileName) {
  try {
    final jsonData = jsonDecode(decryptedContent);

    return utf8.encode(const JsonEncoder.withIndent('  ').convert(jsonData));
  } catch (jsonError) {
    debugPrint('JSON parsing failed: $jsonError');

    if (isTextFile(fileName)) return utf8.encode(decryptedContent);

    // For binary files, try base64 decode.

    try {
      return base64Decode(decryptedContent);
    } catch (base64Error) {
      debugPrint('Base64 decode failed: $base64Error');

      return utf8.encode(decryptedContent);
    }
  }
}

/// Saves decrypted content to a file, handling different file formats appropriately.
///
/// Attempts to save as JSON if possible, falls back to binary or text based on file type.

Future<void> saveDecryptedContent(
  String decryptedContent,
  String saveFilePath,
) async {
  final file = File(saveFilePath);

  // Ensure the parent directory exists.

  await file.parent.create(recursive: true);

  try {
    // Try to parse and save as formatted JSON first.

    try {
      final jsonData = jsonDecode(decryptedContent);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData),
      );
      return;
    } catch (jsonError) {
      debugPrint('JSON parsing failed: $jsonError');
      debugPrint('Raw decrypted content: $decryptedContent');

      // If not JSON, handle as binary or text.

      if (isTextFile(saveFilePath)) {
        await file.writeAsString(decryptedContent);
      } else {
        // For binary files, try base64 decode.

        try {
          final bytes = base64Decode(decryptedContent);
          await file.writeAsBytes(bytes);
        } catch (base64Error) {
          debugPrint('Base64 decode failed: $base64Error');
          await file.writeAsString(decryptedContent);
        }
      }
    }
  } catch (e) {
    throw Exception('Failed to save file: ${e.toString()}');
  }
}
