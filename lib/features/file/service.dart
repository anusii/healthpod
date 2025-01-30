/// A widget to demonstrate the upload, download, and delete large files.
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
/// Authors: Dawei Chen, Ashley Tang

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:healthpod/utils/process_bp_json_to_csv.dart';
import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/features/file/browser.dart';
import 'package:healthpod/utils/is_text_file.dart';
import 'package:healthpod/utils/process_bp_csv_to_json.dart';
import 'package:healthpod/utils/save_decrypted_content.dart';
import 'package:healthpod/utils/show_alert.dart';

/// File service.
///
/// Demonstrates process of uploading, downloading, and deleting files.
/// It supports both text and binary file formats, providing features like encryption
/// during upload, previewing files before uploading, and file management.

class FileService extends StatefulWidget {
  const FileService({super.key});

  @override
  State<FileService> createState() => _FileServiceState();
}

class _FileServiceState extends State<FileService> {
  // File state variables that manage the selected file, its name and its preview.

  final _browserKey = GlobalKey<FileBrowserState>();

  String? uploadFile;
  String? downloadFile;
  String? remoteFileName = 'remoteFileName';
  String? cleanFileName = 'remoteFileName';
  String? remoteFileUrl;
  String? filePreview;

  /// We store the current path separately from the FileBrowser's path.
  /// This helps us track the current directory context for file operations
  /// without relying on accessing the FileBrowser's state.

  String? currentPath =
      'healthpod/data'; // Initialise with the default root path.

  // Boolean flags to track status of various file operations.

  bool uploadInProgress = false;
  bool downloadInProgress = false;
  bool deleteInProgress = false;
  bool importInProgress = false; // CSV import state tracking.
  bool uploadDone = false;
  bool downloadDone = false;
  bool deleteDone = false;
  bool showPreview = false;

  // UI Constants for layout spacing.

  final smallGapH = const SizedBox(width: 10);
  final smallGapV = const SizedBox(height: 10);
  final largeGapV = const SizedBox(height: 50);

  // Helper method to check if we're in the bp/ directory.

  bool get isInBpDirectory {
    return currentPath!.endsWith('/bp') ||
        currentPath!.contains('/bp/') ||
        currentPath == 'healthpod/data/bp';
  }

  /// Handles file upload by reading its contents and encrypting it for upload.

  Future<void> handleUpload() async {
    if (uploadFile == null) return;

    try {
      setState(() {
        uploadInProgress = true;
        uploadDone = false;
      });

      final file = File(uploadFile!);
      String fileContent;

      // For text files, we directly read the content.
      // For binary files, we encode them into base64 format.

      if (isTextFile(uploadFile!)) {
        fileContent = await file.readAsString();
      } else {
        final bytes = await file.readAsBytes();
        fileContent = base64Encode(bytes);
      }

      // Sanitise file name and append encryption extension.

      String sanitizedFileName = path
          .basename(uploadFile!)
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
          .replaceAll(RegExp(r'\.enc\.ttl$'), '');

      remoteFileName =
          '$sanitizedFileName.enc.ttl'; // Add `.enc.ttl` extension for new upload file.
      cleanFileName = sanitizedFileName;

      // Extract the subdirectory path by removing `healthpod/data/` prefix.
      // This is because `healthpod/data` is the root directory for all files.

      String? subPath = currentPath?.replaceFirst('healthpod/data', '').trim();

      // If we have a subdirectory (not in root), include it in the path.

      String uploadPath = subPath == null || subPath.isEmpty
          ? remoteFileName!
          : '${subPath.startsWith("/") ? subPath.substring(1) : subPath}/$remoteFileName';

      debugPrint('Upload path: $uploadPath');

      if (!mounted) return;

      // Upload file with encryption.

      final result = await writePod(
        uploadPath,
        fileContent,
        context,
        const Text('Upload'),
        encrypted: true,
      );

      if (!mounted) return;

      setState(() {
        uploadDone = result == SolidFunctionCallStatus.success;
      });

      if (result == SolidFunctionCallStatus.success) {
        // Refresh the file browser after successful upload.

        _browserKey.currentState?.refreshFiles();
      } else if (mounted) {
        showAlert(context,
            'Upload failed - please check your connection and permissions.');
      }
    } catch (e) {
      if (!mounted) return;
      showAlert(context, 'Upload error: ${e.toString()}');
      debugPrint('Upload error: $e');
    } finally {
      if (mounted) {
        setState(() {
          uploadInProgress = false;
        });
      }
    }
  }

  /// Handles the download and decryption of files from the POD.
  ///
  /// Originally, we expected readPod to automatically handle decryption, but we discovered
  /// that in some cases files remained encrypted and users would see raw TTL content when
  /// downloading. This method now explicitly handles decryption using helper functions to
  /// ensure files are always properly decrypted before saving.

  Future<void> handleDownload() async {
    if (downloadFile == null || remoteFileName == null) return;

    try {
      setState(() {
        downloadInProgress = true;
        downloadDone = false;
      });

      // Construct the relative path, being careful to handle nested directories correctly.
      // We use baseDir as the root directory for all file operations.

      final baseDir = 'healthpod/data';
      final relativePath = currentPath == baseDir
          ? '$baseDir/$remoteFileName' // We're at root, so just append the filename.
          : '$currentPath/$remoteFileName'; // We're in a subfolder, use the full path.

      debugPrint('Attempting to download from path: $relativePath');

      if (!mounted) return;

      // Security key is required for decryption. This ensures it's available
      // before we attempt to read the file.

      await getKeyFromUserIfRequired(
        context,
        const Text('Please enter your security key to download the file'),
      );

      if (!mounted) return;

      // Read the encrypted file content from the POD.
      // Note: At this stage, the content is still in TTL format containing
      // encrypted data, even though readPod may have attempted decryption.

      final fileContent = await readPod(
        relativePath,
        context,
        const Text('Downloading'),
      );

      if (!mounted) return;

      // Handle common error cases from readPod.

      if (fileContent == SolidFunctionCallStatus.fail ||
          fileContent == SolidFunctionCallStatus.notLoggedIn) {
        throw Exception(
            'Download failed - please check your connection and permissions');
      }

      /// We can directly use the decrypted fileContent from readPod.
      ///
      /// This is because we encrypted a JSON file upon upload using the utility function.
      /// And upon decrypting, we expect a JSON file instead of TTL content.

      final saveFileName = downloadFile!.replaceAll(
          RegExp(r'\.enc\.ttl$'), ''); // Use save path selected by user.
      await saveDecryptedContent(fileContent, saveFileName);

      if (!mounted) return;
      setState(() {
        downloadDone = true;
      });

      // Show a success message to give user feedback.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Provide user-friendly error messages by removing the 'Exception:' prefix.

      if (!mounted) return;
      showAlert(context, e.toString().replaceAll('Exception: ', ''));
      debugPrint('Download error: $e');
    } finally {
      // Always reset the download status, even if an error occurred.

      if (mounted) {
        setState(() {
          downloadInProgress = false;
        });
      }
    }
  }

  /// Handles file preview before upload to display its content or basic info.

  Future<void> handlePreview() async {
    if (uploadFile == null) return;

    try {
      final file = File(uploadFile!);
      String content;

      if (isTextFile(uploadFile!)) {
        // For text files, show the first 500 characters.

        content = await file.readAsString();
        content =
            content.length > 500 ? '${content.substring(0, 500)}...' : content;
      } else {
        // For binary files, show their size and type.

        final bytes = await file.readAsBytes();
        content =
            'Binary file\nSize: ${(bytes.length / 1024).toStringAsFixed(2)} KB\nType: ${path.extension(uploadFile!)}';
      }

      if (!mounted) return;
      setState(() {
        filePreview = content;
        showPreview = true;
      });
    } catch (e) {
      if (!mounted) return;
      showAlert(context, 'Failed to preview file: ${e.toString()}');
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

  /// Handles file deletion by removing both the main file and its ACL file.

  Future<void> handleDelete() async {
    if (remoteFileName == null) return;

    try {
      setState(() {
        deleteInProgress = true;
        deleteDone = false;
      });

      /// Path Construction
      ///
      /// We no longer prepend the data directory path (healthpod/data) here
      /// because currentPath from FileBrowser already includes this prefix.
      /// This prevents path duplication like `healthpod/data/healthpod/data/...`

      final basePath = currentPath == null
          ? remoteFileName!
          : '$currentPath/$remoteFileName';

      if (!mounted) return;

      // First try to delete the main file.

      bool mainFileDeleted = false;
      try {
        await deleteFile(basePath);
        mainFileDeleted = true;
        debugPrint('Successfully deleted main file: $basePath');
      } catch (e) {
        debugPrint('Error deleting main file: $e');
        // Only rethrow if it's not a 404 error.
        // 404 errors are expected in some cases (like when file is already deleted).

        if (!e.toString().contains('404') &&
            !e.toString().contains('NotFoundHttpError')) {
          rethrow;
        }
      }

      if (!mounted) return;

      // If main file deletion succeeded, try to delete the ACL file.
      // ACL files are auxiliary files that control access permissions.

      if (mainFileDeleted) {
        try {
          await deleteFile('$basePath.acl');
          debugPrint('Successfully deleted ACL file');
        } catch (e) {
          // ACL files are optional and may not exist.

          if (e.toString().contains('404') ||
              e.toString().contains('NotFoundHttpError')) {
            debugPrint('ACL file not found (safe to ignore)');
          } else {
            debugPrint('Error deleting ACL file: ${e.toString()}');
          }
        }

        if (!mounted) return;
        setState(() {
          deleteDone = true;
        });

        // Refresh the file browser to show updated contents.

        _browserKey.currentState?.refreshFiles();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        deleteDone = false;
      });

      // Provide user-friendly error messages.

      final message = e.toString().contains('404') ||
              e.toString().contains('NotFoundHttpError')
          ? 'File not found or already deleted'
          : 'Delete failed: ${e.toString()}';

      showAlert(context, message);
      debugPrint('Delete error: $e');
    } finally {
      if (mounted) {
        setState(() {
          deleteInProgress = false;
        });
      }
    }
  }

  /// Handles the import of BP CSV files and conversion to individual JSON files.
  ///
  /// Each row of the CSV is processed and stored as a separate encrypted JSON file in the POD.
  /// Files are named using the timestamp from the data.

  Future<void> handleCsvImport(String filePath, String dirPath) async {
    if (importInProgress) return;

    try {
      setState(() {
        importInProgress = true;
      });

      // Process CSV and create individual JSON files for each row.

      final success = await processBpCsvToJson(filePath, dirPath, context);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('BP data imported and converted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the file browser to show the new files.

        _browserKey.currentState?.refreshFiles();
      }
    } catch (e) {
      if (!mounted) return;
      showAlert(context, 'Failed to import BP data: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          importInProgress = false;
        });
      }
    }
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel: File Browser.

        Expanded(
          flex: 2,
          child: Card(
            elevation: 4, // Increased elevation for better depth
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // More rounded corners
              side: BorderSide(
                color: Theme.of(context).dividerColor.withAlpha(10),
                width: 1,
              ),
            ),
            child: _buildFileBrowserPanel(),
          ),
        ),
        const SizedBox(width: 16),
        // Right panel: Upload.

        Expanded(
          flex: 1,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withAlpha(10),
                width: 1,
              ),
            ),
            child: _buildUploadPanel(),
          ),
        ),
      ],
    );
  }

  /// Builds the mobile layout for the file service.

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Top panel: Upload section.

        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withAlpha(10),
              width: 1,
            ),
          ),
          child: ExpansionTile(
            title: const Text(
              'Upload New File',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildUploadPanel(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Bottom panel: File Browser.

        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withAlpha(10),
                width: 1,
              ),
            ),
            child: _buildFileBrowserPanel(),
          ),
        ),
      ],
    );
  }

  /// Builds the file browser panel for desktop layout.

  Widget _buildFileBrowserPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.folder_open),
              const SizedBox(width: 8),
              Expanded(
                child: const Text(
                  'Your Files',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (uploadInProgress ||
                  downloadInProgress ||
                  deleteInProgress ||
                  importInProgress) ...[
                const SizedBox(width: 16),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  uploadInProgress
                      ? 'Uploading...'
                      : downloadInProgress
                          ? 'Downloading...'
                          : importInProgress
                              ? 'Importing...'
                              : 'Deleting...',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FileBrowser(
            key: _browserKey,
            browserKey: _browserKey,
            onFileSelected: (fileName, path) {
              // Store both the file information and the current path.
              // This ensures we maintain correct context for file operations.

              setState(() {
                cleanFileName = fileName;
                remoteFileName =
                    fileName; // fileName already has existing `.enc.ttl` extension.
                currentPath = path;
              });
            },
            onFileDownload: (fileName, path) async {
              setState(() {
                cleanFileName = fileName;
                remoteFileName =
                    fileName; // fileName already has existing `.enc.ttl` extension.
                currentPath = path;
              });

              // Remove encryption extensions before showing save dialog.

              String cleanedFileName =
                  fileName.replaceAll(RegExp(r'\.enc\.ttl$'), '');

              // Let user choose where to save the file.

              String? outputFile = await FilePicker.platform.saveFile(
                dialogTitle: 'Save file as:',
                fileName: cleanedFileName,
              );

              if (outputFile != null) {
                setState(() {
                  downloadFile = outputFile;
                });
                await handleDownload();
              }
            },
            onFileDelete: (fileName, path) async {
              setState(() {
                cleanFileName = fileName;
                remoteFileName =
                    fileName; // fileName already has existing `.enc.ttl` extension.
                currentPath = path; // Maintain path context for deletion.
              });
              await handleDelete();
            },
            onDirectoryChanged: (newPath) {
              setState(() {
                currentPath = newPath;
              });
            },
            onImportCsv: handleCsvImport,
          ),
        ),
      ],
    );
  }

  /// Builds and returns the upload panel widget which contains
  /// file upload functionality and CSV import options.
  ///
  /// This panel appears on the right side in desktop layout
  /// and as an expandable section in mobile layout.

  Widget _buildUploadPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display preview card if a file is selected and preview is enabled.

          _buildPreviewCard(),
          const SizedBox(height: 16),

          // Show selected file info container when a file is chosen.

          if (uploadFile != null)
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
                  // Display filename with overflow protection.

                  Expanded(
                    child: Text(
                      path.basename(uploadFile!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Show success checkmark when upload completes.

                  if (uploadDone)
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                ],
              ),
            ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Main upload button - handles both file selection and upload.

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (uploadInProgress ||
                          downloadInProgress ||
                          deleteInProgress)
                      ? null // Disable button during any ongoing operation.
                      : () async {
                          // Open file picker and trigger upload if file is selected.

                          final result = await FilePicker.platform.pickFiles();
                          if (result != null) {
                            setState(() {
                              uploadFile = result.files.single.path!;
                              uploadDone = false;
                            });
                            // Immediately trigger upload after file selection.

                            await handleUpload();
                          }
                        },
                  icon: const Icon(Icons.file_upload),
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

              // Show CSV import and export buttons only when in blood pressure directory.

              if (isInBpDirectory) ...[
                const SizedBox(width: 8),
                // Import CSV Button.

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // Open file picker configured for CSV files only.

                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['csv'],
                        );

                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          if (file.path != null) {
                            // Process and import CSV data.

                            handleCsvImport(
                                file.path!, currentPath ?? 'healthpod/data');
                          }
                        }
                      } catch (e) {
                        debugPrint('Error picking CSV file: $e');
                      }
                    },
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
                // Export CSV Button.

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final String? outputFile =
                            await FilePicker.platform.saveFile(
                          dialogTitle: 'Save BP data as CSV:',
                          fileName: 'bp_data.csv',
                        );

                        if (outputFile != null) {
                          if (!mounted) return;

                          // Export JSON files in bp/ to a single CSV file.

                          final success = await processBpJsonToCsv(
                            outputFile,
                            currentPath ?? 'healthpod/data',
                            context,
                          );

                          if (!mounted) return;

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('BP data exported successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            showAlert(context, 'Failed to export BP data');
                          }
                        }
                      } catch (e) {
                        if (!mounted) return;
                        showAlert(context, 'Export error: ${e.toString()}');
                        debugPrint('Export error: $e');
                      }
                    },
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
          const SizedBox(height: 12),

          // Preview button - enabled only when a file is selected and no operation is in progress.

          TextButton.icon(
            onPressed: (uploadFile == null ||
                    uploadInProgress ||
                    downloadInProgress ||
                    deleteInProgress)
                ? null
                : handlePreview,
            icon: const Icon(Icons.preview),
            label: const Text('Preview File'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the main UI layout for the file service.

  @override
  Widget build(BuildContext context) {
    // Get screen width to determine layout.

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Home',
        ),
        title: const Text(
          'File Management',
        ),
        backgroundColor: titleBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }
}
