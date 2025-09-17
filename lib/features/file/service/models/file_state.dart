/// File state model for the file service provider.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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
/// Authors: Ashley Tang, Tony Chen

library;

/// State class for file service operations.

class FileState {
  final String? currentPath;
  final String? uploadFile;
  final String? downloadFile;
  final String? remoteFileName;
  final String? cleanFileName;
  final String? filePreview;
  final bool uploadInProgress;
  final bool downloadInProgress;
  final bool deleteInProgress;
  final bool importInProgress;
  final bool exportInProgress;
  final bool uploadDone;
  final bool downloadDone;
  final bool deleteDone;
  final bool showPreview;

  const FileState({
    this.currentPath,
    this.uploadFile,
    this.downloadFile,
    this.remoteFileName,
    this.cleanFileName,
    this.filePreview,
    this.uploadInProgress = false,
    this.downloadInProgress = false,
    this.deleteInProgress = false,
    this.importInProgress = false,
    this.exportInProgress = false,
    this.uploadDone = false,
    this.downloadDone = false,
    this.deleteDone = false,
    this.showPreview = false,
  });

  /// Creates a copy of this state with the given fields replaced with new
  /// values.

  FileState copyWith({
    String? currentPath,
    String? uploadFile,
    String? downloadFile,
    String? remoteFileName,
    String? cleanFileName,
    String? filePreview,
    bool? uploadInProgress,
    bool? downloadInProgress,
    bool? deleteInProgress,
    bool? importInProgress,
    bool? exportInProgress,
    bool? uploadDone,
    bool? downloadDone,
    bool? deleteDone,
    bool? showPreview,
  }) {
    return FileState(
      currentPath: currentPath ?? this.currentPath,
      uploadFile: uploadFile ?? this.uploadFile,
      downloadFile: downloadFile ?? this.downloadFile,
      remoteFileName: remoteFileName ?? this.remoteFileName,
      cleanFileName: cleanFileName ?? this.cleanFileName,
      filePreview: filePreview ?? this.filePreview,
      uploadInProgress: uploadInProgress ?? this.uploadInProgress,
      downloadInProgress: downloadInProgress ?? this.downloadInProgress,
      deleteInProgress: deleteInProgress ?? this.deleteInProgress,
      importInProgress: importInProgress ?? this.importInProgress,
      exportInProgress: exportInProgress ?? this.exportInProgress,
      uploadDone: uploadDone ?? this.uploadDone,
      downloadDone: downloadDone ?? this.downloadDone,
      deleteDone: deleteDone ?? this.deleteDone,
      showPreview: showPreview ?? this.showPreview,
    );
  }
}
