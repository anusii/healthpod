/// File service provider for the file service feature.
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/file/service/handlers/csv_handler.dart';
import 'package:healthpod/features/file/service/handlers/delete_handler.dart';
import 'package:healthpod/features/file/service/handlers/download_handler.dart';
import 'package:healthpod/features/file/service/handlers/profile_handler.dart';
import 'package:healthpod/features/file/service/handlers/upload_handler.dart';
import 'package:healthpod/features/file/service/models/file_state.dart';

/// A provider that manages the business logic for file operations.

class FileServiceNotifier extends StateNotifier<FileState> {
  final bool isVaccination;
  final bool isDiary;
  final bool isMedication;
  final bool isBloodPressure;

  FileServiceNotifier({
    required this.isVaccination,
    required this.isDiary,
    required this.isMedication,
    required this.isBloodPressure,
  }) : super(const FileState(currentPath: '$basePath/diary'));

  // Add callback for browser refresh.

  Function? _refreshCallback;

  // Method to set the refresh callback.

  void setRefreshCallback(Function callback) {
    _refreshCallback = callback;
  }

  // Method to call the refresh callback.

  void refreshBrowser() {
    _refreshCallback?.call();
  }

  /// Updates the current path and notifies listeners.

  void updateCurrentPath(String path) {
    state = state.copyWith(currentPath: path);
  }

  /// Updates import in progress state.

  void updateImportInProgress(bool inProgress) {
    state = state.copyWith(importInProgress: inProgress);
  }

  /// Handles file upload by reading its contents and encrypting it for upload.

  Future<void> handleUpload(BuildContext context) async {
    if (state.uploadFile == null) return;

    state = state.copyWith(uploadInProgress: true, uploadDone: false);

    final result = await FileUploadHandler.handleUpload(
      context,
      uploadFile: state.uploadFile!,
      currentPath: state.currentPath,
      refreshCallback: _refreshCallback,
    );

    state = state.copyWith(
      uploadDone: result.success,
      uploadInProgress: false,
      remoteFileName: result.remoteFileName,
      cleanFileName: result.cleanFileName,
    );
  }

  /// Handles the download and decryption of files from the POD.

  Future<void> handleDownload(BuildContext context) async {
    if (state.remoteFileName == null || state.currentPath == null) return;

    state = state.copyWith(downloadInProgress: true, downloadDone: false);

    final success = await FileDownloadHandler.handleDownload(
      context,
      remoteFileName: state.remoteFileName,
      currentPath: state.currentPath,
      cleanFileName: state.cleanFileName,
    );

    state = state.copyWith(downloadDone: success, downloadInProgress: false);
  }

  /// Updates the selected file for upload.

  void setUploadFile(String? file) {
    state = state.copyWith(uploadFile: file);
  }

  /// Updates the selected file for download.

  void setDownloadFile(String file) {
    state = state.copyWith(downloadFile: file);
  }

  /// Updates the file preview content.

  void setFilePreview(String preview) {
    state = state.copyWith(filePreview: preview);
  }

  /// Updates the remote file name.

  void setRemoteFileName(String fileName) {
    state = state.copyWith(
      remoteFileName: fileName,
      cleanFileName: fileName.replaceAll('.enc.ttl', ''),
    );
  }

  /// Handles file deletion from the POD.

  Future<void> handleDelete(BuildContext context) async {
    if (state.remoteFileName == null || state.currentPath == null) return;

    state = state.copyWith(deleteInProgress: true, deleteDone: false);

    final success = await FileDeleteHandler.handleDelete(
      context,
      remoteFileName: state.remoteFileName,
      currentPath: state.currentPath,
      refreshCallback: _refreshCallback,
    );

    state = state.copyWith(deleteDone: success, deleteInProgress: false);
  }

  /// Toggles the preview visibility.

  void togglePreview() {
    state = state.copyWith(showPreview: !state.showPreview);
  }

  /// Handles the import of BP, Vaccination, Medication or Diary data from CSV format.

  Future<void> handleCsvImport(
    BuildContext context, {
    bool isVaccination = false,
    bool isMedication = false,
    bool isDiary = false,
    bool isBloodPressure = false,
    Function(String importType)? onImportSuccess,
  }) async {
    state = state.copyWith(importInProgress: true);

    await CsvHandler.handleCsvImport(
      context,
      currentPath: state.currentPath,
      refreshCallback: _refreshCallback,
      isVaccination: isVaccination,
      isMedication: isMedication,
      isDiary: isDiary,
      isBloodPressure: isBloodPressure,
      onImportSuccess: onImportSuccess,
    );

    state = state.copyWith(importInProgress: false);
  }

  /// Handles the export of BP, Vaccination, Diary or Medication data to CSV format.

  Future<void> handleCsvExport(
    BuildContext context, {
    bool isVaccination = false,
    bool isDiary = false,
    bool isMedication = false,
  }) async {
    state = state.copyWith(exportInProgress: true);

    await CsvHandler.handleCsvExport(
      context,
      currentPath: state.currentPath,
      isVaccination: isVaccination,
      isDiary: isDiary,
      isMedication: isMedication,
    );

    state = state.copyWith(exportInProgress: false);
  }

  /// Handles the import of profile data from JSON format.

  Future<void> handleProfileImport(
    BuildContext context, {
    required WidgetRef ref,
  }) async {
    state = state.copyWith(importInProgress: true);

    await ProfileHandler.handleProfileImport(
      context,
      ref: ref,
      refreshCallback: refreshBrowser,
    );

    state = state.copyWith(importInProgress: false);
  }

  /// Handles the export of profile data to JSON format.

  Future<void> handleProfileExport(BuildContext context) async {
    state = state.copyWith(exportInProgress: true);

    await ProfileHandler.handleProfileExport(
      context,
      currentPath: state.currentPath,
    );

    state = state.copyWith(exportInProgress: false);
  }
}

/// The provider instance for file service operations.

final fileServiceProvider =
    StateNotifierProvider<FileServiceNotifier, FileState>((ref) {
  return FileServiceNotifier(
    isVaccination: false,
    isDiary: false,
    isMedication: false,
    isBloodPressure: false,
  );
});
