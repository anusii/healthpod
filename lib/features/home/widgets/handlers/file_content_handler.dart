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
import 'package:path_provider/path_provider.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/file/service/providers/file_service_provider.dart';
import 'package:healthpod/features/pathology/llm_service.dart';

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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No file uploaded for conversion'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Show loading dialog.

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Processing PDF...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }

      final pdfFile = File(state.uploadFile!);
      final fileName = path.basename(pdfFile.path);

      // Send PDF to Python server for analysis.

      final llmService = PathologyLLMService(
        baseUrl: 'http://localhost:8000',
        timeout: const Duration(seconds: 900), // 15 minutes.
      );

      final jsonData = await llmService.analysePdf(pdfFile);

      // Close loading dialog.

      if (context.mounted) {
        Navigator.pop(context);
      }

      // Create JSON file.

      final jsonFileName = fileName.replaceAll('.pdf', '.json');
      final tempDir = await getTemporaryDirectory();
      final jsonFile = File('${tempDir.path}/$jsonFileName');
      await jsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData),
      );

      // Upload PDF file.

      if (context.mounted) {
        ref.read(fileServiceProvider.notifier).setUploadFile(pdfFile.path);
        await ref.read(fileServiceProvider.notifier).handleUpload(context);
      }

      // Upload JSON file.

      if (context.mounted) {
        ref.read(fileServiceProvider.notifier).setUploadFile(jsonFile.path);
        await ref.read(fileServiceProvider.notifier).handleUpload(context);
      }

      // Clean up temp file.

      if (await jsonFile.exists()) {
        await jsonFile.delete();
      }

      // Show success message.

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF analysed and files uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open.

      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message.

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
