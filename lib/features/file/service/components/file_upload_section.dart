/// File upload section component for the file service feature.
///
// Time-stamp: <Friday 2025-02-14 08:40:39 +1100 Graham Williams>
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
/// Authors: Ashley Tang

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:healthpod/features/file/service/providers/file_service_provider.dart';
import 'package:healthpod/utils/is_text_file.dart';

/// A widget that handles file upload functionality and preview.
///
/// This component provides UI elements for selecting and uploading files,
/// including a file picker button and upload status indicators.

class FileUploadSection extends ConsumerStatefulWidget {
  const FileUploadSection({super.key});

  @override
  ConsumerState<FileUploadSection> createState() => _FileUploadSectionState();
}

class _FileUploadSectionState extends ConsumerState<FileUploadSection> {
  String? filePreview;
  bool showPreview = false;

  /// Handles file preview before upload to display its content or basic info.

  Future<void> handlePreview(String filePath) async {
    try {
      final file = File(filePath);
      String content;

      if (isTextFile(filePath)) {
        // For text files, show the first 500 characters.

        content = await file.readAsString();
        content =
            content.length > 500 ? '${content.substring(0, 500)}...' : content;
      } else {
        // For binary files, show their size and type.

        final bytes = await file.readAsBytes();
        content =
            'Binary file\nSize: ${(bytes.length / 1024).toStringAsFixed(2)} KB\nType: ${path.extension(filePath)}';
      }

      setState(() {
        filePreview = content;
        showPreview = true;
      });
    } catch (e) {
      debugPrint('Preview error: $e');
    }
  }

  /// Builds a preview card UI to show content or info of selected file.

  Widget _buildPreviewCard() {
    if (!showPreview || filePreview == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withAlpha(10),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.preview,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => showPreview = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Close preview',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Text(
                filePreview!,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> handlePdfToJson(File file) async {
    // Store context before async operations.

    final currentContext = context;

    try {
      // Show loading dialog while processing.

      if (currentContext.mounted) {
        showDialog(
          context: currentContext,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Read PDF file.

      final bytes = await file.readAsBytes();
      final PdfDocument pdf = PdfDocument(inputBytes: bytes);

      // Extract text from all pages.

      String text = '';
      for (var i = 0; i < pdf.pages.count; i++) {
        text += PdfTextExtractor(pdf).extractText(startPageIndex: i);
      }

      // Structure the data to match kt_pathology.json format.

      final List<String> lines = text.split('\n');
      final Map<String, dynamic> jsonData = {
        'metadata': {
          'filename': file.path.split('/').last,
          'pageCount': pdf.pages.count,
          'processedDate': DateTime.now().toIso8601String(),
        },
        'content': {
          'rawText': text,
          'structuredLines': lines
              .map((line) => {
                    'text': line.trim(),
                    'length': line.length,
                  })
              .toList(),
        }
      };

      // Close loading dialog.

      if (currentContext.mounted) {
        Navigator.pop(currentContext);
      }

      // Save JSON file in integration_test/data folder.

      if (currentContext.mounted) {
        final jsonString = jsonEncode(jsonData);
        final jsonFileName = '${path.basenameWithoutExtension(file.path)}.json';
        final jsonFilePath =
            path.join('integration_test', 'data', jsonFileName);
        final jsonFile = File(jsonFilePath);

        // Create directory if it doesn't exist.

        await jsonFile.parent.create(recursive: true);
        await jsonFile.writeAsString(jsonString);

        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text('JSON file saved as $jsonFilePath'),
              action: SnackBarAction(
                label: 'View',
                onPressed: () => handleJsonPreview(jsonFilePath),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Handle errors and display error message.

      if (currentContext.mounted) {
        Navigator.pop(currentContext);
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Error converting PDF to JSON: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> handleJsonPreview(String filePath) async {
    final currentContext = context;
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      final formattedJson =
          const JsonEncoder.withIndent('  ').convert(jsonData);

      if (currentContext.mounted) {
        showDialog(
          context: currentContext,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.analytics),
                const SizedBox(width: 8),
                Text(path.basename(filePath)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 1000,
              child: SingleChildScrollView(
                child: SelectableText(
                  formattedJson,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (jsonData['content']?['structuredLines'] != null) {
                    final List<dynamic> lines =
                        jsonData['content']['structuredLines'];
                    final List<String> texts =
                        lines.map((line) => line['text'] as String).toList();
                    final extractedText = texts.join('\n');

                    showDialog(
                      context: currentContext,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.text_snippet),
                            SizedBox(width: 8),
                            Text('Extracted Text'),
                          ],
                        ),
                        content: SizedBox(
                          width: double.maxFinite,
                          height: 800,
                          child: SingleChildScrollView(
                            child: SelectableText(
                              extractedText,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              final Map<String, dynamic> finalJson = {
                                'timestamp': '',
                                'clinical_note': '',
                                'referrer': '',
                                'clinic': '',
                                'laboratory': '4Cyte Pathology',
                                'pathologist': '',
                                'sodium': 0.0,
                                'potassium': 0.0,
                                'chloride': 0.0,
                                'bicarbonate': 0.0,
                                'anion_gap': 0.0,
                                'urea': 0.0,
                                'creatinine': 0.0,
                                'egfr': 0.0,
                                'total_protien': 0.0,
                                'globulin': 0.0,
                                'albumin': 0.0,
                                'bilirubin_total': 0.0,
                                'alk_phosphatase': 0.0,
                                'gamma_gt': 0.0,
                                'alt': 0.0,
                                'ast': 0.0,
                              };

                              // Parse the extracted text
                              final lines = extractedText.split('\n');
                              for (var line in lines) {
                                line = line.trim();
                                if (line.isEmpty) continue;

                                // Extract timestamp
                                if (line.contains('Collected:')) {
                                  final dateTime =
                                      line.split('Collected:')[1].trim();
                                  final parts = dateTime.split(' ');
                                  if (parts.length == 2) {
                                    final date = parts[0].split('/');
                                    if (date.length == 3) {
                                      final year = date[2];
                                      final month = date[1].padLeft(2, '0');
                                      final day = date[0].padLeft(2, '0');
                                      final time = parts[1];
                                      finalJson['timestamp'] =
                                          '$year-$month-$day $time';
                                    }
                                  }
                                }

                                // Extract clinical note
                                if (line.contains('Clinical Notes:')) {
                                  finalJson['clinical_note'] =
                                      line.split('Clinical Notes:')[1].trim();
                                }

                                // Extract referrer
                                if (line.startsWith('Dr ')) {
                                  finalJson['referrer'] = line;
                                }

                                // Extract clinic address
                                if (line.contains('Medical Centre')) {
                                  finalJson['clinic'] = line;
                                }

                                // Extract pathologist
                                if (line.contains('Pathologist:')) {
                                  finalJson['pathologist'] =
                                      line.split('Pathologist:')[1].trim();
                                }

                                // Extract test results
                                if (line.contains('Sodium')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['sodium'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('Potassium')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['potassium'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('Chloride')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['chloride'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('Bicarbonate')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['bicarbonate'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('Anion Gap')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['anion_gap'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('Urea')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['urea'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('Creatinine')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['creatinine'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('eGFR')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['egfr'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('Total Protein')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['total_protien'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('Globulin')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['globulin'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('Albumin')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['albumin'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('Bilirubin Total')) {
                                  // Look for the value on the next line
                                  final nextLine =
                                      lines[lines.indexOf(line) + 1].trim();
                                  finalJson['bilirubin_total'] =
                                      double.tryParse(nextLine) ?? 0.0;
                                } else if (line.contains('Alk. Phosphatase')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['alk_phosphatase'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('Gamma GT')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['gamma_gt'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('ALT')) {
                                  final parts = line
                                      .split(RegExp(r'\s+'))
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                  if (parts.length >= 2) {
                                    finalJson['alt'] =
                                        double.tryParse(parts[1]) ?? 0.0;
                                  }
                                } else if (line.contains('AST')) {
                                  // Look for the value on the next line
                                  final nextLine =
                                      lines[lines.indexOf(line) + 1].trim();
                                  finalJson['ast'] =
                                      double.tryParse(nextLine) ?? 0.0;
                                }
                              }

                              showDialog(
                                context: currentContext,
                                builder: (context) => AlertDialog(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.analytics),
                                      SizedBox(width: 8),
                                      Text('Final JSON'),
                                    ],
                                  ),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    height: 800,
                                    child: SingleChildScrollView(
                                      child: SelectableText(
                                        const JsonEncoder.withIndent('  ')
                                            .convert(finalJson),
                                        style: const TextStyle(
                                            fontFamily: 'monospace'),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () async {
                                        final result =
                                            await FilePicker.platform.saveFile(
                                          dialogTitle: 'Save Final JSON',
                                          fileName:
                                              '${path.basenameWithoutExtension(filePath)}_final.json',
                                        );
                                        if (result != null) {
                                          final file = File(result);
                                          await file.writeAsString(
                                            const JsonEncoder.withIndent('  ')
                                                .convert(finalJson),
                                          );
                                          if (currentContext.mounted) {
                                            ScaffoldMessenger.of(currentContext)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'JSON saved to ${file.path}'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text('Save Final JSON'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(currentContext),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Extract Final Info'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text('Extract Info'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(currentContext),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('JSON preview error: $e');
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Error reading JSON file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileServiceProvider);
    final isInBpDirectory =
        state.currentPath?.contains('blood_pressure') ?? false;
    final isInVaccinationDirectory =
        state.currentPath?.contains('vaccination') ?? false;
    final showCsvButtons = isInBpDirectory || isInVaccinationDirectory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title.

        const Text(
          'Upload Files',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Display preview card if enabled.

        _buildPreviewCard(),
        if (showPreview) const SizedBox(height: 16),

        // Show selected file info.

        if (state.uploadFile != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.file_present,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    path.basename(state.uploadFile!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (state.uploadDone)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
          ),
        if (state.uploadFile != null) const SizedBox(height: 16),

        // Upload and CSV buttons row.

        Row(
          children: [
            // Main upload button.

            Expanded(
              child: MarkdownTooltip(
                message: '''

                **Upload**: Tap here to upload a file to your Solid Health Pod.
                    
                ''',
                child: ElevatedButton.icon(
                  onPressed: state.uploadInProgress
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles();
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            if (file.path != null) {
                              ref
                                  .read(fileServiceProvider.notifier)
                                  .setUploadFile(file.path);
                              await handlePreview(file.path!);
                              if (!context.mounted) return;
                              await ref
                                  .read(fileServiceProvider.notifier)
                                  .handleUpload(context);
                            }
                          }
                        },
                  icon: Icon(Icons.file_upload,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                  label: const Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),

            // Show CSV import/export buttons in BP or Vaccination directory.

            if (showCsvButtons) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.importInProgress
                      ? null
                      : () => ref
                          .read(fileServiceProvider.notifier)
                          .handleCsvImport(
                            context,
                            isVaccination: isInVaccinationDirectory,
                          ),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Import CSV'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.exportInProgress
                      ? null
                      : () => ref
                          .read(fileServiceProvider.notifier)
                          .handleCsvExport(
                            context,
                            isVaccination: isInVaccinationDirectory,
                          ),
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        Theme.of(context).colorScheme.tertiaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onTertiaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(width: 8),
        MarkdownTooltip(
          message: '''

          **Visualize JSON**: Tap here to select and visualize a JSON file from your local machine.

          ''',
          child: TextButton.icon(
            onPressed: state.uploadInProgress
                ? null
                : () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final file = result.files.first;
                      if (file.path != null) {
                        await handleJsonPreview(file.path!);
                      }
                    }
                  },
            icon: const Icon(Icons.analytics),
            label: const Text('Visualize JSON'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        // Preview button.

        if (state.uploadFile != null) ...[
          const SizedBox(height: 12),
          MarkdownTooltip(
            message: '''

            **Preview File**: Tap here to preview the recently uploaded file.

            ''',
            child: TextButton.icon(
              onPressed: state.uploadInProgress
                  ? null
                  : () => handlePreview(state.uploadFile!),
              icon: const Icon(Icons.preview),
              label: const Text('Preview File'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MarkdownTooltip(
            message: '''

            **Convert to JSON**: Tap here to convert the PDF file to JSON format.
            This will extract text from the PDF and structure it as JSON data.

            ''',
            child: TextButton.icon(
              onPressed: state.uploadInProgress
                  ? null
                  : () => handlePdfToJson(File(state.uploadFile!)),
              icon: const Icon(Icons.code),
              label: const Text('Convert to JSON'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
