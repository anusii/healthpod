/// A widget to demonstrate the upload, download, and delete large files.
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
/// Authors: Dawei Chen, Ashley Tang

library;

import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/features/bp/exporter.dart';
import 'package:healthpod/features/bp/importer.dart';
import 'package:healthpod/features/file/browser.dart';
import 'package:healthpod/utils/is_text_file.dart';
import 'package:healthpod/utils/save_decrypted_content.dart';
import 'package:healthpod/utils/show_alert.dart';

/// File service.
///
/// Demonstrates the process of uploading, downloading, and deleting files.
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

  // uploadFile holds a String (file path) on mobile/desktop or Uint8List on web.

  dynamic uploadFile;
  // For web, we store the picked file name.

  String? uploadFileName;
  String? downloadFile;
  String? remoteFileName = 'remoteFileName';
  String? cleanFileName = 'remoteFileName';
  String? remoteFileUrl;
  String? filePreview;

  /// We store the current path separately from the FileBrowser's path.
  /// This helps us track the current directory context for file operations.

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
    return currentPath!.endsWith('/blood_pressure') ||
        currentPath!.contains('/blood_pressure/') ||
        currentPath == 'healthpod/data/blood_pressure';
  }

  /// Handles file upload by reading its contents and encrypting it for upload.

  Future<void> handleUpload() async {
    if (uploadFile == null) return;

    try {
      setState(() {
        uploadInProgress = true;
        uploadDone = false;
      });

      String fileContent;
      String fileName;

      if (kIsWeb) {
        // On web, uploadFile is a Uint8List and the file name is stored in uploadFileName.

        Uint8List fileBytes = uploadFile as Uint8List;
        fileName = uploadFileName ?? "upload.pdf";
        // For binary files on web, encode the bytes to base64.

        fileContent = base64Encode(fileBytes);
      } else {
        // On mobile/desktop, uploadFile is a file path.

        final filePath = uploadFile as String;
        fileName = path.basename(filePath);
        final file = File(filePath);
        // Call isTextFile() only on mobile/desktop where filePath is a String.

        if (isTextFile(filePath)) {
          fileContent = await file.readAsString();
        } else {
          final bytes = await file.readAsBytes();
          fileContent = base64Encode(bytes);
        }
      }

      // Sanitize the file name and append the encryption extension.

      String sanitizedFileName = fileName
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
          .replaceAll(RegExp(r'\.enc\.ttl$'), '');
      remoteFileName = '$sanitizedFileName.enc.ttl';
      cleanFileName = sanitizedFileName;

      // Extract the subdirectory path by removing the 'healthpod/data' prefix.

      String? subPath = currentPath?.replaceFirst('healthpod/data', '').trim();
      String uploadPath = (subPath == null || subPath.isEmpty)
          ? remoteFileName!
          : '${subPath.startsWith("/") ? subPath.substring(1) : subPath}/$remoteFileName';

      debugPrint('Upload path: $uploadPath');

      if (!mounted) return;

      // Upload the file with encryption.

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
        // Refresh the file browser after a successful upload.

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

  Future<void> handleDownload() async {
    if (downloadFile == null || remoteFileName == null) return;

    try {
      setState(() {
        downloadInProgress = true;
        downloadDone = false;
      });

      final baseDir = 'healthpod/data';
      final relativePath = currentPath == baseDir
          ? '$baseDir/$remoteFileName'
          : '$currentPath/$remoteFileName';

      debugPrint('Attempting to download from path: $relativePath');

      if (!mounted) return;

      await getKeyFromUserIfRequired(
        context,
        const Text('Please enter your security key to download the file'),
      );

      if (!mounted) return;

      final fileContent = await readPod(
        relativePath,
        context,
        const Text('Downloading'),
      );

      if (!mounted) return;

      if (fileContent == SolidFunctionCallStatus.fail ||
          fileContent == SolidFunctionCallStatus.notLoggedIn) {
        throw Exception(
            'Download failed - please check your connection and permissions');
      }

      final saveFileName = downloadFile!.replaceAll(RegExp(r'\.enc\.ttl$'), '');
      await saveDecryptedContent(fileContent, saveFileName);

      if (!mounted) return;
      setState(() {
        downloadDone = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAlert(context, e.toString().replaceAll('Exception: ', ''));
      debugPrint('Download error: $e');
    } finally {
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
      String content;
      if (kIsWeb) {
        // On web, use the stored file name to determine if it's a text file.

        if (uploadFileName != null && isTextFile(uploadFileName!)) {
          // Decode the bytes as UTF-8.

          content = utf8.decode(uploadFile as Uint8List);
          content = content.length > 500
              ? '${content.substring(0, 500)}...'
              : content;
        } else {
          final bytes = uploadFile as Uint8List;
          content =
              'Binary file\nSize: ${(bytes.length / 1024).toStringAsFixed(2)} KB\nType: ${path.extension(uploadFileName ?? "")}';
        }
      } else {
        final filePath = uploadFile as String;
        final file = File(filePath);
        if (isTextFile(filePath)) {
          content = await file.readAsString();
          content = content.length > 500
              ? '${content.substring(0, 500)}...'
              : content;
        } else {
          final bytes = await file.readAsBytes();
          content =
              'Binary file\nSize: ${(bytes.length / 1024).toStringAsFixed(2)} KB\nType: ${path.extension(filePath)}';
        }
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

      final basePath = currentPath == null
          ? remoteFileName!
          : '$currentPath/$remoteFileName';

      if (!mounted) return;

      bool mainFileDeleted = false;
      try {
        await deleteFile(basePath);
        mainFileDeleted = true;
        debugPrint('Successfully deleted main file: $basePath');
      } catch (e) {
        debugPrint('Error deleting main file: $e');
        if (!e.toString().contains('404') &&
            !e.toString().contains('NotFoundHttpError')) {
          rethrow;
        }
      }

      if (!mounted) return;

      if (mainFileDeleted) {
        try {
          await deleteFile('$basePath.acl');
          debugPrint('Successfully deleted ACL file');
        } catch (e) {
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

        _browserKey.currentState?.refreshFiles();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        deleteDone = false;
      });

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

  Future<void> handleCsvImport(String filePath, String dirPath) async {
    if (importInProgress) return;

    try {
      setState(() {
        importInProgress = true;
      });

      final success =
          await BPImporter.importFromCsv(filePath, dirPath, context);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Blood pressure data imported and converted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _browserKey.currentState?.refreshFiles();
      }
    } catch (e) {
      if (!mounted) return;
      showAlert(
          context, 'Failed to import Blood pressure data: ${e.toString()}');
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
              const Expanded(
                child: Text(
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
              setState(() {
                cleanFileName = fileName;
                remoteFileName = fileName;
                currentPath = path;
              });
            },
            onFileDownload: (fileName, path) async {
              setState(() {
                cleanFileName = fileName;
                remoteFileName = fileName;
                currentPath = path;
              });
              String cleanedFileName =
                  fileName.replaceAll(RegExp(r'\.enc\.ttl$'), '');
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
                remoteFileName = fileName;
                currentPath = path;
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

  /// Builds and returns the upload panel widget.

  Widget _buildUploadPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPreviewCard(),
          const SizedBox(height: 16),
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
                  Expanded(
                    child: Text(
                      kIsWeb
                          ? (uploadFileName ?? "unknown file")
                          : path.basename(uploadFile!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (uploadDone)
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (uploadInProgress ||
                          downloadInProgress ||
                          deleteInProgress)
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.any,
                          );
                          if (result != null) {
                            setState(() {
                              if (kIsWeb) {
                                uploadFile = result.files.single.bytes;
                                uploadFileName = result.files.single.name;
                              } else {
                                uploadFile = result.files.single.path;
                              }
                              uploadDone = false;
                            });
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
              if (isInBpDirectory) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['csv'],
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          if (file.path != null) {
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
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final String? outputFile =
                            await FilePicker.platform.saveFile(
                          dialogTitle: 'Save Blood pressure data as CSV:',
                          fileName: 'blood_pressure_data.csv',
                        );
                        if (outputFile != null) {
                          if (!mounted) return;
                          final success = await BPExporter.exportToCsv(
                            outputFile,
                            currentPath ?? 'healthpod/data',
                            context,
                          );
                          if (!mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Blood pressure data exported successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            showAlert(context,
                                'Failed to export Blood pressure data');
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Management'),
        backgroundColor: titleBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }
}
