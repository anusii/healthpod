/// File management content widget for the home screen.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidui/solidui.dart';

import 'package:healthpod/constants/file_type_configs.dart';
import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/file/service/providers/file_service_provider.dart';
import 'package:healthpod/features/home/widgets/handlers/file_content_handler.dart';
import 'package:healthpod/features/home/widgets/handlers/file_operation_handler.dart';
import 'package:healthpod/features/home/widgets/handlers/upload_callback_handler.dart';
import 'package:healthpod/features/home/widgets/navigation/tab_coordinator.dart';
import 'package:healthpod/providers/tab_state.dart';

/// File management content widget using SolidFile.

class FileManagementContent extends ConsumerStatefulWidget {
  /// Callback function to handle import success navigation.

  final Function(String importType)? onImportSuccess;

  /// Flag to track whether the user has ever actively selected a feature tab.

  final bool hasUserSelectedFeatureTab;

  const FileManagementContent({
    super.key,
    this.onImportSuccess,
    required this.hasUserSelectedFeatureTab,
  });

  @override
  ConsumerState<FileManagementContent> createState() =>
      _FileManagementContentState();
}

class _FileManagementContentState extends ConsumerState<FileManagementContent> {
  final GlobalKey<SolidFileBrowserState> _browserKey = GlobalKey();

  /// Flag to track whether the user has manually navigated to a different
  /// folder. If true, we won't override the user's choice with tab
  /// coordination.

  bool _userHasManuallyNavigated = false;

  /// Track the last tab index we coordinated with to avoid redundant
  /// navigation.

  int? _lastCoordinatedTabIndex;

  /// Tri-state flag tracking the Files page visibility history:
  ///   null  – the user has never visited Files yet
  ///   true  – Files is currently the active page
  ///   false – the user was on Files previously but has since navigated away

  bool? _wasFilesPageActive;

  @override
  void initState() {
    super.initState();
    // Set up the refresh callback after the widget is built.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileServiceProvider.notifier).setRefreshCallback(() {
        _browserKey.currentState?.refreshFiles();
      });

      // Always start at the data root.  Folder coordination when returning
      // to the Files page from another page is handled in build() via the
      // _wasFilesPageActive tri-state logic.

      ref.read(fileServiceProvider.notifier).updateCurrentPath(basePath);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileServiceProvider);

    // Create handler instances.

    final fileContentHandler = FileContentHandler(
      ref: ref,
      context: context,
      onStateUpdate: () => setState(() {}),
    );

    final uploadHandler = UploadCallbackHandler(
      ref: ref,
      context: context,
      onImportSuccess: (importType) => widget.onImportSuccess?.call(importType),
      onVisualiseJson: fileContentHandler.handleVisualiseJson,
      onSelectLocalJson: fileContentHandler.handleSelectLocalJson,
      onPreviewFile: fileContentHandler.handlePreview,
      onConvertToJson: fileContentHandler.handleConvertToJson,
    );

    final fileOperationHandler = FileOperationHandler(
      ref: ref,
      context: context,
      browserKey: _browserKey,
      onStateUpdate: () => setState(() {}),
    );

    final menuIndex = ref.watch(menuIndexProvider);
    const filesPageIndex = 4;
    final isFilesActive = (menuIndex == filesPageIndex);

    // When RETURNING to Files (was here before, left, now back), clear the
    // manual-navigation flag so that tab-based folder coordination re-engages.
    // On the very first visit (_wasFilesPageActive == null) we intentionally
    // skip this so the browser stays at the default root (healthpod/data).

    final isReturningToFiles = isFilesActive && _wasFilesPageActive == false;

    if (isReturningToFiles) {
      _userHasManuallyNavigated = false;
      _lastCoordinatedTabIndex = null;

      // Ensure the provider is at basePath so that if the SolidFileBrowser
      // is recreated, it receives initialPath = basePath and sets _homePath
      // correctly. The coordination below will then navigate to the tab’s
      // folder. This prevents Home/Up from using a subfolder as the root.

      ref.read(fileServiceProvider.notifier).updateCurrentPath(basePath);
    }

    // When SolidFileBrowser may be (re)created, pass basePath so _homePath is
    // correct: first visit (_wasFilesPageActive == null) or returning after
    // being disposed (_wasFilesPageActive == false).

    final browserMayBeRecreated = isFilesActive && _wasFilesPageActive != true;
    final pathForSolidFile =
        browserMayBeRecreated ? basePath : (state.currentPath ?? basePath);

    // Update the tri-state visibility tracker.

    if (isFilesActive) {
      _wasFilesPageActive = true;
    } else if (_wasFilesPageActive == true) {
      _wasFilesPageActive = false;
    }

    final currentTabState = ref.watch(tabStateProvider);

    // When the Files page is active, coordinate with the current tab so the
    // displayed folder matches View / Add / Data. Stay at root only when
    // selectedIndex is -1 (user has never opened a feature tab).

    if (isFilesActive &&
        !_userHasManuallyNavigated &&
        _lastCoordinatedTabIndex != currentTabState.selectedIndex) {
      // Update the last coordinated index.

      _lastCoordinatedTabIndex = currentTabState.selectedIndex;

      // Use a post-frame callback to trigger navigation after build completes.

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_userHasManuallyNavigated) {
          TabCoordinator.navigateToFeatureFolder(
            ref,
            _userHasManuallyNavigated,
            (targetPath) =>
                _browserKey.currentState?.navigateToPath(targetPath),
          );
        }
      });
    }

    return SolidFile(
      currentPath: pathForSolidFile,
      browserKey: _browserKey,
      autoConfig: true,
      fileTypeResolver: healthFileTypeResolver,
      folderNameOverrides: healthFolderNameOverrides,
      showBackButton: true,
      backButtonText: 'Back to Home Folder',
      onBackPressed: () {
        const rootPath = basePath;

        // Block tab coordination while the user is browsing at root level.
        // Coordination will be re-enabled automatically when the user leaves
        // the Files page and returns (handled by _wasFilesPageActive logic).

        _userHasManuallyNavigated = true;

        // Reset coordinated index to allow future tab coordination if needed.

        _lastCoordinatedTabIndex = null;

        ref.read(fileServiceProvider.notifier).updateCurrentPath(rootPath);
        _browserKey.currentState?.navigateToPath(rootPath);

        setState(() {});
      },
      onFileSelected: fileOperationHandler.handleFileSelected,
      onFileDownload: fileOperationHandler.handleFileDownload,
      onFileDelete: fileOperationHandler.handleFileDelete,
      onImportCsv: fileOperationHandler.handleImportCsv,
      onDirectoryChanged: (path) {
        fileOperationHandler.handleDirectoryChanged(
          path,
          () => TabCoordinator.getExpectedPathForCurrentTab(ref),
          (value) => _userHasManuallyNavigated = value,
          (value) => _lastCoordinatedTabIndex = value,
        );
      },
      onClosePreview: fileOperationHandler.handleClosePreview,
      uploadCallbacks: uploadHandler.createUploadCallbacks(pathForSolidFile),
      uploadState: SolidFileUploadState(
        uploadInProgress: state.uploadInProgress,
        importInProgress: state.importInProgress,
        exportInProgress: state.exportInProgress,
        uploadedFilePath: state.uploadFile,
        uploadDone: state.uploadDone,
        filePreview: state.filePreview,
        showPreview: state.showPreview,
      ),
    );
  }
}
