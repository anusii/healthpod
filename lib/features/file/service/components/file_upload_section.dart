/// File upload section component for the file service feature.
///
// Time-stamp: <Thursday 2025-04-17 10:02:42 +1000 Graham Williams>
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
import 'package:healthpod/features/profile/importer.dart';
import 'package:healthpod/providers/profile_provider.dart';
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
                  icon: MarkdownTooltip(
                    message: '''

                    **Close Preview:** Tap here to close the file preview panel.

                    ''',
                    child: const Icon(Icons.close, size: 20),
                  ),
                  onPressed: () => setState(() => showPreview = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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

  /// Builds a CSV format information card for each supported directory.

  Widget _buildFormatCard(bool isInBpDirectory, bool isInVaccinationDirectory,
      bool isInProfileDirectory, bool isInMedicationDirectory) {
    if (!isInBpDirectory &&
        !isInVaccinationDirectory &&
        !isInProfileDirectory &&
        !isInMedicationDirectory) {
      return const SizedBox.shrink();
    }

    String title = '';
    List<String> requiredFields = [];
    List<String> optionalFields = [];
    bool isJson = false;

    if (isInBpDirectory) {
      title = 'Blood Pressure CSV Format';
      requiredFields = ['timestamp', 'systolic', 'diastolic', 'heart_rate'];
      optionalFields = ['notes'];
    } else if (isInVaccinationDirectory) {
      title = 'Vaccination CSV Format';
      requiredFields = ['timestamp', 'name', 'type'];
      optionalFields = ['location', 'notes', 'batch_number'];
    } else if (isInMedicationDirectory) {
      title = 'Medication CSV Format';
      requiredFields = [
        'timestamp',
        'name',
        'dosage',
        'frequency',
        'start_date'
      ];
      optionalFields = ['notes'];
    } else if (isInProfileDirectory) {
      title = 'Profile JSON Format';
      requiredFields = [
        'name',
        'address',
        'bestContactPhone',
        'alternativeContactNumber',
        'email',
        'dateOfBirth',
        'gender'
      ];
      isJson = true;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withAlpha(10),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Required Fields:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text('• ${requiredFields.join("\n• ")}'),
            const SizedBox(height: 8),
            if (optionalFields.isNotEmpty) ...[
              Text(
                'Optional Fields:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text('• ${optionalFields.join("\n• ")}'),
              const SizedBox(height: 8),
            ],
            Text(
              isJson
                  ? 'Note: The JSON file must contain these required fields with valid values.'
                  : 'Note: The first row should contain these column headers. All values should be in the correct format.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle profile JSON import.

  Future<void> handleProfileImport() async {
    try {
      // Show loading indicator.

      setState(() {
        ref.read(fileServiceProvider.notifier).updateImportInProgress(true);
      });

      // Open file picker for JSON files.

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          // Show preview.

          if (!mounted) return;
          await handlePreview(file.path!);

          // Import profile data.

          if (!mounted) return;
          await ProfileImporter.importJson(
            file.path!,
            'profile',
            context,
            onSuccess: () {
              // Only refresh if still mounted.

              if (!mounted) return;

              // Show success message first before any navigation or refresh.

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Profile data imported successfully'),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              );

              // Wrap in a microtask to ensure UI operations complete first.

              Future.microtask(() {
                if (!mounted) return;

                // Refresh profile data after import.

                ref.read(profileProvider.notifier).refreshProfileData(context);

                // Refresh file browser.

                ref.read(fileServiceProvider.notifier).refreshBrowser();
              });
            },
          );

          // No need for additional success message as it's handled in onSuccess.
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          ref.read(fileServiceProvider.notifier).updateImportInProgress(false);
        });
      }
    }
  }

  Future<void> convertPDFToJsonUpload(File file) async {
    try {
      // Show loading dialog while processing.

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Read PDF file.

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final PdfDocument pdf = PdfDocument(inputBytes: bytes);

      // Extract text from all pages.

      String text = '';
      for (var i = 0; i < pdf.pages.count; i++) {
        text += PdfTextExtractor(pdf).extractText(startPageIndex: i);
      }

      // Structure the data to match kt_pathology.json format.

      final List<String> lines = text.split('\n');

      // Close loading dialog.

      if (!mounted) return;
      Navigator.pop(context);

      // Extract final structured data.

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

      // Parse the extracted text.

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        // Extract timestamp.

        if (line.contains('Collected:')) {
          final dateTime = line.split('Collected:')[1].trim();
          final parts = dateTime.split(' ');
          if (parts.length == 2) {
            final date = parts[0].split('/');
            if (date.length == 3) {
              final year = date[2];
              final month = date[1].padLeft(2, '0');
              final day = date[0].padLeft(2, '0');
              final time = parts[1];
              finalJson['timestamp'] = '$year-$month-$day $time';
            }
          }
        }

        // Extract clinical note.

        if (line.contains('Clinical Notes:')) {
          finalJson['clinical_note'] = line.split('Clinical Notes:')[1].trim();
        }

        // Extract referrer.

        if (line.startsWith('Dr ')) {
          finalJson['referrer'] = line;
        }

        // Extract clinic address.

        if (line.contains('Medical Centre')) {
          finalJson['clinic'] = line;
        }

        // Extract pathologist.

        if (line.contains('Pathologist:')) {
          finalJson['pathologist'] = line.split('Pathologist:')[1].trim();
        }

        // Extract test results.

        if (line.contains('Sodium')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['sodium'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('Potassium')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['potassium'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('Chloride')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['chloride'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('Bicarbonate')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['bicarbonate'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('Anion Gap')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['anion_gap'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('Urea')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['urea'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('Creatinine')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['creatinine'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('eGFR')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['egfr'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('Total Protein')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['total_protien'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('Globulin')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['globulin'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('Albumin')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['albumin'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('Bilirubin Total')) {
          final nextLine = lines[lines.indexOf(line) + 1].trim();
          finalJson['bilirubin_total'] = double.tryParse(nextLine) ?? 0.0;
        } else if (line.contains('Alk. Phosphatase')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['alk_phosphatase'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('Gamma GT')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['gamma_gt'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('ALT')) {
          final parts =
              line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) {
            finalJson['alt'] = double.tryParse(parts[1]) ?? 0.0;
          }
        } else if (line.contains('AST')) {
          final nextLine = lines[lines.indexOf(line) + 1].trim();
          finalJson['ast'] = double.tryParse(nextLine) ?? 0.0;
        }
      }
      // Create a temporary file for the final JSON.

      final tempDir = await Directory.systemTemp.createTemp();
      if (!mounted) return;

      // Create a file with a name based on the original PDF.

      final jsonFile = File(
          '${tempDir.path}/${path.basenameWithoutExtension(file.path)}_final.json');
      await jsonFile
          .writeAsString(const JsonEncoder.withIndent('  ').convert(finalJson));

      // Upload both files to POD.

      if (!mounted) return;

      // First upload the PDF.

      ref.read(fileServiceProvider.notifier).setUploadFile(file.path);
      await ref.read(fileServiceProvider.notifier).handleUpload(context);
      if (!mounted) return;

      // Then upload the JSON.

      ref.read(fileServiceProvider.notifier).setUploadFile(jsonFile.path);
      await ref.read(fileServiceProvider.notifier).handleUpload(context);
      if (!mounted) return;

      // Clean up temporary file.

      await jsonFile.delete();
      await tempDir.delete();

      // Show success message.

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF and JSON files uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileServiceProvider);
    final isInBpDirectory =
        state.currentPath?.contains('blood_pressure') ?? false;
    final isInVaccinationDirectory =
        state.currentPath?.contains('vaccination') ?? false;
    final isInProfileDirectory =
        state.currentPath?.contains('profile') ?? false;
    final isInMedicationDirectory =
        state.currentPath?.contains('medication') ?? false;
    final showCsvButtons =
        isInBpDirectory || isInVaccinationDirectory || isInMedicationDirectory;
    final showProfileImportButton = isInProfileDirectory;

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
                              if (file.extension?.toLowerCase() == 'pdf') {
                                await convertPDFToJsonUpload(File(file.path!));
                              } else {
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

            // Show Profile Import button in Profile directory
            if (showProfileImportButton) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.importInProgress
                      ? null
                      : () => handleProfileImport(),
                  icon: const Icon(Icons.person),
                  label: const Text('Import Profile'),
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
              // Export Profile button.

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.exportInProgress
                      ? null
                      : () => ref
                          .read(fileServiceProvider.notifier)
                          .handleProfileExport(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Export Profile'),
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

            // Show CSV import/export buttons in BP or Vaccination directory.

            if (showCsvButtons) ...[
              const SizedBox(width: 8),
              Expanded(
                child: MarkdownTooltip(
                  message: '''

                  **Import CSV:** Tap here to import data from a CSV file:

                  - Select a CSV file from your device;

                  - The data will be processed and added to your health records;

                  - Please ensure the CSV follows the required format.


                  ''',
                  child: ElevatedButton.icon(
                    onPressed: state.importInProgress
                        ? null
                        : () => ref
                            .read(fileServiceProvider.notifier)
                            .handleCsvImport(
                              context,
                              isVaccination: isInVaccinationDirectory,
                              isMedication: isInMedicationDirectory,
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
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MarkdownTooltip(
                  message: '''

                  **Export CSV:** Tap here to export your health data to a CSV
                  file:

                  - Export your vaccination or blood pressure records

                  - The data will be saved in a standard CSV format

                  - You can use this file for backup or analysis

                  - The export process is quick and efficient

                  ''',
                  child: ElevatedButton.icon(
                    onPressed: state.exportInProgress
                        ? null
                        : () => ref
                            .read(fileServiceProvider.notifier)
                            .handleCsvExport(
                              context,
                              isVaccination: isInVaccinationDirectory,
                              isMedication: isInMedicationDirectory,
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
              ),
            ],
          ],
        ),

        // Display CSV format information card.

        _buildFormatCard(isInBpDirectory, isInVaccinationDirectory,
            isInProfileDirectory, isInMedicationDirectory),

        const SizedBox(height: 12),
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
                        await handlePreview(file.path!);
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

            **Convert to JSON**: Tap here to convert the PDF file to JSON format and upload both files.
            This will extract text from the PDF, structure it as JSON data, and upload both files to your POD.

            ''',
            child: TextButton.icon(
              onPressed: state.uploadInProgress
                  ? null
                  : () => convertPDFToJsonUpload(File(state.uploadFile!)),
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
