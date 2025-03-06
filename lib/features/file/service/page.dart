/// A file service widget for managing file operations in the POD.
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

import 'package:flutter/material.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/features/file/browser/page.dart';
import 'package:healthpod/features/file/service/components/operation_status.dart';
import 'package:healthpod/features/file/service/components/upload_panel.dart';
import 'package:healthpod/features/file/service/operations/service_operations.dart';

/// A widget for managing file operations in the POD.
///
/// This widget provides:
/// - File upload with preview and encryption
/// - File download with decryption
/// - File deletion with ACL cleanup
/// - CSV import/export functionality
/// - File browser integration
///
/// The widget adapts its layout based on screen size:
/// - Desktop: Side-by-side panels
/// - Mobile: Stacked panels with expandable sections

class FileService extends StatefulWidget {
  const FileService({super.key});

  @override
  State<FileService> createState() => _FileServiceState();
}

/// State class for the [FileService] widget.
///
/// Manages:
/// - File operation states (upload, download, delete)
/// - Current directory path
/// - File selection and preview
/// - Operation progress tracking

class _FileServiceState extends State<FileService> {
  /// Key to access the file browser state.
  final _browserKey = GlobalKey<FileBrowserState>();

  /// Currently selected file for upload.
  String? uploadFile;

  /// Currently selected file for download.
  String? downloadFile;

  /// Remote file name for operations.
  String? remoteFileName;

  /// Clean file name without extensions.
  String? cleanFileName;

  /// Current directory path.
  String? currentPath = 'healthpod/data';

  /// Operation states.
  bool uploadInProgress = false;
  bool downloadInProgress = false;
  bool deleteInProgress = false;
  bool importInProgress = false;
  bool uploadDone = false;
  bool downloadDone = false;
  bool deleteDone = false;
  bool showPreview = false;

  /// Handles file upload by reading its contents and encrypting it for upload.
  Future<void> handleUpload() async {
    if (uploadFile == null || currentPath == null) return;

    try {
      setState(() {
        uploadInProgress = true;
        uploadDone = false;
      });

      final (success, fileName) = await ServiceOperations.uploadFile(
        filePath: uploadFile!,
        currentPath: currentPath!,
        context: context,
      );

      if (!mounted) return;

      setState(() {
        uploadDone = success;
        if (success) {
          remoteFileName = fileName;
          cleanFileName = fileName.replaceAll(RegExp(r'\.enc\.ttl$'), '');
        }
      });

      if (success) {
        _browserKey.currentState?.refreshFiles();
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        setState(() => uploadInProgress = false);
      }
    }
  }

  /// Handles file download by reading and decrypting the file.
  Future<void> handleDownload() async {
    if (downloadFile == null || currentPath == null) return;

    try {
      setState(() {
        downloadInProgress = true;
        downloadDone = false;
      });

      final success = await ServiceOperations.downloadFile(
        fileName: downloadFile!,
        currentPath: currentPath!,
        context: context,
      );

      if (!mounted) return;

      setState(() => downloadDone = success);
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        setState(() => downloadInProgress = false);
      }
    }
  }

  /// Handles file deletion by removing both the main file and its ACL file.
  Future<void> handleDelete() async {
    if (remoteFileName == null || currentPath == null) return;

    try {
      setState(() {
        deleteInProgress = true;
        deleteDone = false;
      });

      final success = await ServiceOperations.deletePodFile(
        fileName: remoteFileName!,
        currentPath: currentPath!,
        context: context,
      );

      if (!mounted) return;

      setState(() => deleteDone = success);

      if (success) {
        _browserKey.currentState?.refreshFiles();
      }
    } catch (e) {
      debugPrint('Delete error: $e');
      if (mounted) {
        setState(() => deleteInProgress = false);
      }
    }
  }

  /// Handles file preview before upload to display its content or basic info.
  Future<void> handlePreview() async {
    if (uploadFile == null) return;

    try {
      setState(() => showPreview = true);
    } catch (e) {
      debugPrint('Preview error: $e');
      if (mounted) {
        setState(() => showPreview = false);
      }
    }
  }

  /// Handles CSV file import by reading and processing the file.
  Future<void> handleCsvImport(String filePath) async {
    try {
      setState(() => importInProgress = true);

      final success = await ServiceOperations.importCsv(
        filePath: filePath,
        currentPath: currentPath ?? 'healthpod/data',
        context: context,
      );

      if (!mounted) return;

      if (success) {
        _browserKey.currentState?.refreshFiles();
      }
    } catch (e) {
      debugPrint('CSV import error: $e');
      if (mounted) {
        setState(() => importInProgress = false);
      }
    }
  }

  /// Builds the desktop layout with side-by-side panels.
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel: Upload and operations.
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Upload panel.
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
                      child: UploadPanel(
                        uploadFile: uploadFile,
                        uploadInProgress: uploadInProgress,
                        uploadDone: uploadDone,
                        onFileSelected: (file) {
                          setState(() => uploadFile = file);
                        },
                        onUpload: handleUpload,
                        onPreview: handlePreview,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right panel: File browser.
        Expanded(
          flex: 2,
          child: _buildFileBrowserPanel(),
        ),
      ],
    );
  }

  /// Builds the mobile layout with stacked panels.
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Upload panel.
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
                child: UploadPanel(
                  uploadFile: uploadFile,
                  uploadInProgress: uploadInProgress,
                  uploadDone: uploadDone,
                  onFileSelected: (file) {
                    setState(() => uploadFile = file);
                  },
                  onUpload: handleUpload,
                  onPreview: handlePreview,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // File browser.
        Expanded(
          child: _buildFileBrowserPanel(),
        ),
      ],
    );
  }

  /// Builds the file browser panel.
  Widget _buildFileBrowserPanel() {
    return Card(
      elevation: 4,
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
          // Header with operation status.
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
                OperationStatus(
                  uploadInProgress: uploadInProgress,
                  downloadInProgress: downloadInProgress,
                  deleteInProgress: deleteInProgress,
                  importInProgress: importInProgress,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // File browser content.
          Expanded(
            child: FileBrowser(
              browserKey: _browserKey,
              onFileSelected: (name, path) {
                setState(() {
                  cleanFileName = name;
                  remoteFileName = name;
                  currentPath = path;
                });
              },
              onFileDownload: (name, path) async {
                setState(() {
                  cleanFileName = name;
                  remoteFileName = name;
                  currentPath = path;
                });
                await handleDownload();
              },
              onFileDelete: (name, path) async {
                setState(() {
                  cleanFileName = name;
                  remoteFileName = name;
                  currentPath = path;
                });
                await handleDelete();
              },
              onDirectoryChanged: (newPath) {
                setState(() {
                  currentPath = newPath;
                });
              },
              onImportCsv: (filePath, _) => handleCsvImport(filePath),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine layout based on screen width.
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
