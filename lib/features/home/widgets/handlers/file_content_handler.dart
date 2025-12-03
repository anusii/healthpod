/// File content handling operations for local and remote files.
///
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang, Tony Chen

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/file/service/providers/file_service_provider.dart';
import 'package:healthpod/features/home/widgets/pdf_processor.dart';

/// Handles file content operations including preview, visualisation, and PDF
/// conversion.

class FileContentHandler {
  final WidgetRef ref;
  final BuildContext context;
  final Function() onStateUpdate;

  const FileContentHandler({
    required this.ref,
    required this.context,
    required this.onStateUpdate,
  });

  /// Handles selecting and previewing local JSON files.

  Future<void> handleSelectLocalJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await _handlePreviewLocalFile(file.path!);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select JSON file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles previewing a local file by path.

  Future<void> _handlePreviewLocalFile(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();

      String displayContent;
      try {
        final jsonData = jsonDecode(content);
        displayContent = const JsonEncoder.withIndent('  ').convert(jsonData);
      } catch (e) {
        // If it's not valid JSON, just show the raw content.

        displayContent = content;
      }

      // Update the file preview state.

      ref.read(fileServiceProvider.notifier).setFilePreview(displayContent);

      // Always ensure preview is shown when content is loaded.

      final currentState = ref.read(fileServiceProvider);
      if (!currentState.showPreview) {
        ref.read(fileServiceProvider.notifier).togglePreview();
      } else {
        onStateUpdate(); // Force a widget rebuild
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Local JSON file loaded: ${path.basename(filePath)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load local file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles JSON visualisation from POD.

  Future<void> handleVisualiseJson() async {
    final state = ref.read(fileServiceProvider);

    if (state.remoteFileName == null || state.currentPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Construct the full file path by combining directory and filename.

    String filePath;
    final dirPath = state.downloadFile ?? state.currentPath;
    
    if (dirPath != null && dirPath.isNotEmpty) {
      filePath = [dirPath, state.remoteFileName].join('/');
    } else {
      // Fallback: use basePath if no directory path is available.

      filePath = [basePath, state.remoteFileName].join('/');
    }

    try {
      // Read the file content from POD.

      final webId = await getWebId();
      if (webId != null) {
        final fileUrl = webId.replaceAll('profile/card#me', filePath);
        final hasIndKey = await KeyManager.hasIndividualKey(fileUrl);
      }

      final fileContent = await readPod(
        filePath,
        pathType: PathType.relativeToPod,
      );

      if (fileContent == SolidFunctionCallStatus.fail.toString() ||
          fileContent == SolidFunctionCallStatus.notLoggedIn.toString()) {
        throw Exception('Failed to read file from POD');
      }

      // Try to parse and format the JSON content.

      String displayContent;
      try {
        final jsonData = jsonDecode(fileContent);
        // Pretty format the JSON with indentation.

        displayContent = const JsonEncoder.withIndent('  ').convert(jsonData);
      } catch (e) {
        // If it's not valid JSON, just show the raw content.

        displayContent = fileContent;
      }

      // Update the file preview state.

      ref.read(fileServiceProvider.notifier).setFilePreview(displayContent);

      // Always ensure preview is shown when content is loaded.

      final currentState = ref.read(fileServiceProvider);

      if (!currentState.showPreview) {
        ref.read(fileServiceProvider.notifier).togglePreview();
      } else {
        // Force a widget rebuild by calling setState on a parent widget.

        onStateUpdate();
      }
    } catch (e) {
      debugPrint('Failed to load JSON: ${e.toString()}');
    }
  }

  /// Handles file preview.

  Future<void> handlePreview() async {
    final state = ref.read(fileServiceProvider);

    if (state.remoteFileName == null || state.currentPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Construct the full file path.
    // The currentPath already contains the full path from pod root.

    final dirPath = state.currentPath ?? basePath;
    final filePath = [dirPath, state.remoteFileName].join('/');

    try {
      // Read the file content from POD.
      // Use PathType.relativeToPod since filePath already contains the full
      // path from pod root (e.g., "healthpod/data/pathology/file.enc.ttl").

      final fileContent = await readPod(
        filePath,
        pathType: PathType.relativeToPod,
      );

      if (fileContent == SolidFunctionCallStatus.fail.toString() ||
          fileContent == SolidFunctionCallStatus.notLoggedIn.toString()) {
        throw Exception('Failed to read file from POD');
      }

      // Display content (truncate if too long).

      String displayContent = fileContent.length > 1000
          ? '${fileContent.substring(0, 1000)}...\n\n[Content truncated]'
          : fileContent;

      // Update the file preview state.

      ref.read(fileServiceProvider.notifier).setFilePreview(displayContent);

      // Always ensure preview is shown when content is loaded.

      final currentState = ref.read(fileServiceProvider);
      if (!currentState.showPreview) {
        ref.read(fileServiceProvider.notifier).togglePreview();
      }
    } catch (e) {
      debugPrint('Failed to load file: ${e.toString()}');
    }
  }

  /// Handles PDF to JSON conversion.

  Future<void> handleConvertToJson() async {
    final state = ref.read(fileServiceProvider);
    if (state.uploadFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file uploaded for conversion'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await PdfProcessor.convertPDFToJsonUpload(
      File(state.uploadFile!),
      context,
      ref,
    );
  }
}
