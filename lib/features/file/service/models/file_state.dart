/// A model class to manage the state of file operations in the file service.
///
/// This class encapsulates all the state variables that were previously scattered
/// throughout the FileService widget, providing a more organized and maintainable
/// way to manage file operation states.

library;

class FileState {
  /// The currently selected file for upload.

  String? uploadFile;

  /// The currently selected file for download.

  String? downloadFile;

  /// The name of the file on the remote server.

  String? remoteFileName;

  /// The clean name of the file (without encryption extension).

  String? cleanFileName;

  /// The URL of the remote file.

  String? remoteFileUrl;

  /// The preview content of the selected file.

  String? filePreview;

  /// The current directory path.

  String? currentPath;

  /// Operation status flags.

  bool uploadInProgress = false;
  bool downloadInProgress = false;
  bool deleteInProgress = false;
  bool importInProgress = false;
  bool exportInProgress = false;
  bool uploadDone = false;
  bool downloadDone = false;
  bool deleteDone = false;
  bool showPreview = false;

  /// Creates a new [FileState] with default values.

  FileState({
    this.uploadFile,
    this.downloadFile,
    this.remoteFileName = 'remoteFileName',
    this.cleanFileName = 'remoteFileName',
    this.remoteFileUrl,
    this.filePreview,
    this.currentPath = 'healthpod/data',
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

  /// Creates a copy of this [FileState] with the given fields replaced with new values.

  FileState copyWith({
    String? uploadFile,
    String? downloadFile,
    String? remoteFileName,
    String? cleanFileName,
    String? remoteFileUrl,
    String? filePreview,
    String? currentPath,
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
      uploadFile: uploadFile ?? this.uploadFile,
      downloadFile: downloadFile ?? this.downloadFile,
      remoteFileName: remoteFileName ?? this.remoteFileName,
      cleanFileName: cleanFileName ?? this.cleanFileName,
      remoteFileUrl: remoteFileUrl ?? this.remoteFileUrl,
      filePreview: filePreview ?? this.filePreview,
      currentPath: currentPath ?? this.currentPath,
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

  /// Checks if the current path is in the blood pressure directory.

  bool get isInBpDirectory {
    return currentPath!.endsWith('/blood_pressure') ||
        currentPath!.contains('/blood_pressure/') ||
        currentPath == 'healthpod/data/blood_pressure';
  }
}
