/// Home screen for the health data app.
///
// Time-stamp: <Monday 2025-08-25 10:52:34 +1000 Graham Williams>
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/charts/tab.dart';
import 'package:healthpod/features/file/service/providers/file_service_provider.dart';
import 'package:healthpod/features/resources/tab.dart';
import 'package:healthpod/features/table/tab.dart';
import 'package:healthpod/features/update/tab.dart';
import 'package:healthpod/providers/tab_state.dart';
import 'package:healthpod/settings/dialog.dart';
import 'package:healthpod/utils/fetch_web_id.dart';
import 'package:healthpod/utils/handle_logout.dart';
import 'package:healthpod/utils/initialise_feature_folders.dart';
import 'package:healthpod/utils/is_logged_in.dart';
import 'package:healthpod/widgets/home_page.dart';

/// The home screen for the HealthPod app.
///
/// This screen serves as the main entry point for the HealthPod application,
/// providing users with a dashboard of features, a footer with user-specific
/// information, and options to log out or view information about the app.

// Global function to build basic menu items.

List<SolidMenuItem> _buildBasicHealthPodMenu() => [
      SolidMenuItem(
        title: 'Home',
        icon: Icons.home,
        tooltip: '''

    **Home:** Tap here to view your HealthPod overview and dashboard.

    ''',
        child: HomePage(
          onNavigateToProfile: () {},
        ),
      ),
      SolidMenuItem(
        title: 'View',
        icon: Icons.show_chart,
        tooltip: '''

    **View:** Tap here to visualise your health data that is stored in your
      pod. Your **blood pressure** observations will show trends over time and
      other health metrics. Your **vaccinations** will be shown as a timeline.

    ''',
        child: const ChartTab(),
      ),
      SolidMenuItem(
        title: 'Entry',
        icon: Icons.assignment,
        tooltip: '''

    **Add:** Tap here to directly enter new data. This could be new observations
    of your **Blood Pressure** (systolic, diastolic, heart rate) or a new
    **Vaccination**. To upload new data from a *CSV* file vist the **Files**
    tab.

    ''',
        child: const SurveyTab(),
      ),
      SolidMenuItem(
        title: 'Data',
        icon: Icons.table_chart,
        tooltip: '''

    **Data:** Tap here to view, modify, add, or remove your saved health data
      through a tabular form. All of your health data from your pod is
      accessible here.

    ''',
        child: const TableTab(),
      ),
      SolidMenuItem(
        title: 'Files',
        icon: Icons.folder,
        tooltip: '''

    **Files:** Tap here to access file management features.  Here you can load
    your health data from any local *CSV* files you may have created into your
    Health Pod.

    The **Files** tab allows you to **browse** your pod storage, **upload**
    files to your pod, **download** files from your pod to you local device, and
    to **delete** files from your pod storage.

    ''',
        child: const _FileManagementContent(),
      ),
      SolidMenuItem(
        title: 'Support',
        icon: Icons.library_books,
        tooltip: '''

    **Support:** Tap here to access a comprehensive collection of health
    resources including:

    - Health information and guides

    - External trusted resources

    - Useful health calculators and tools

    ''',
        child: const ResourcesTab(),
      ),
    ];

class HealthPodHome extends ConsumerStatefulWidget {
  const HealthPodHome({super.key});

  @override
  HealthPodHomeState createState() => HealthPodHomeState();
}

class HealthPodHomeState extends ConsumerState<HealthPodHome> {
  String? _webId;
  bool _isKeySaved = false;
  String _appVersion = '';
  int _selectedMenuIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _initialiseFooterData(context);
    _initialiseData(context);
  }

  /// Loads the app name and version from package_info_plus.

  Future<void> _loadAppInfo() async {
    final appInfo = await getAppNameVersion();
    if (mounted) {
      setState(() {
        _appVersion = appInfo.version;
      });
    }
  }

  /// Initialises all required data including footer data and feature folders.

  Future<void> _initialiseData(BuildContext context) async {
    // First initialise footer data.

    await _initialiseFooterData(context);

    // Then initialise feature folders if user is logged in.
    // _webId will only be non-null if the user is actively logged in
    // thanks to our updated fetchWebId function

    if (_webId != null) {
      setState(() {});

      // Check security key once for the entire session.

      if (context.mounted) {
        await SolidSecurityKeyCentralManager.instance.ensureSecurityKey(
          context,
          const Text('Security verification is required to access your data'),
        );
      }

      if (context.mounted) {
        await initialiseFeatureFolders(
          context: context,
          onProgress: (inProgress) {
            if (mounted) {
              setState(() {});
            }
          },
          onComplete: () {
            // Feature folders initialized
          },
        );
      }
    }
  }

  /// Initialises the footer data by fetching the Web ID and encryption key status.

  Future<void> _initialiseFooterData(context) async {
    // Check if user is logged in with valid session
    final loggedIn = await isLoggedIn();
    final webId = loggedIn ? await fetchWebId() : null;

    // Only fetch key status if webId is not null (user is logged in)
    // This prevents the login prompt for users who clicked CONTINUE.

    bool isKeySaved = false;
    if (webId != null && context.mounted) {
      // Let the central key manager check for security key status.
      // This prevents multiple prompts across the app.

      isKeySaved =
          await SolidSecurityKeyCentralManager.instance.ensureSecurityKey(
        context,
        const Text('Security verification is required for Health Pod'),
      );
    }

    setState(() {
      _webId = webId;
      _isKeySaved = isKeySaved;
    });
  }

  /// Updates the key saved status in the state and triggers a rebuild.
  ///
  /// This method is passed as a callback to child widgets to notify the home screen
  /// when the encryption key status changes.

  void _updateKeyStatus(bool status) {
    setState(() {
      _isKeySaved = status;
    });
  }

  /// Sets the selected menu index and triggers a rebuild.

  void setSelectedMenuIndex(int index) {
    setState(() {
      _selectedMenuIndex = index;
    });
  }

  /// Handles menu selection in the SolidScaffold.

  void _onMenuSelected(int index) {
    setSelectedMenuIndex(index);
  }

  /// Handles successful CSV import.

  void _onImportSuccess(String importType) {
    if (mounted) {
      // Show a success message.

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${importType.replaceAll('_', ' ').toUpperCase()} data imported '
            'successfully',
          ),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Builds the menu items for SolidScaffold navigation with callbacks.

  List<SolidMenuItem> _buildHealthPodMenu() {
    final basicMenu = _buildBasicHealthPodMenu();

    // Find the Files menu item and replace it with one that has the callback.

    return basicMenu.map((item) {
      if (item.title == 'Files') {
        return SolidMenuItem(
          title: item.title,
          icon: item.icon,
          tooltip: item.tooltip,
          child: _FileManagementContent(
            onImportSuccess: _onImportSuccess,
          ),
        );
      }
      return item;
    }).toList();
  }

  /// Extracts the server URL from a WebID.

  String _extractServerFromWebId(String webId) {
    try {
      final uri = Uri.parse(webId);
      return '${uri.scheme}://${uri.host}'
          '${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
    } catch (e) {
      final parts = webId.split('/');
      if (parts.length >= 3) {
        return '${parts[0]}//${parts[2]}';
      }
      return webId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SolidScaffold(
      menu: _buildHealthPodMenu(),
      selectedIndex: _selectedMenuIndex,
      onMenuSelected: _onMenuSelected,
      appBar: SolidAppBarConfig(
        title: 'HealthPod',
        actions: [
          SolidAppBarAction(
            icon: Icons.settings,
            tooltip: '''

            **Settings:** Tap here to view and manage your HealthPod account
              settings.

            ''',
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const SettingsDialog(),
            ),
          ),
          SolidAppBarAction(
            icon: Icons.logout,
            tooltip: '''

            **Logout:** Tap here to securely log out of your HealthPod account.
            This will clear your current session and return you to the login
            screen.

            ''',
            onPressed: () => handleLogout(context),
          ),
        ],
        overflowItems: [],
      ),
      themeToggle: SolidThemeToggleConfig(),
      statusBar: SolidStatusBarConfig(
        serverInfo: _webId != null
            ? SolidServerInfo(
                serverUri: _extractServerFromWebId(_webId!),
                tooltip: '''

**Server:** This is your Solid Pod server where your health data is stored
securely.

Tap to visit your server in the browser.

''',
              )
            : null,
        loginStatus: SolidLoginStatus(
          webId: _webId,
          onTap: () => handleLogout(context),
        ),
        securityKeyStatus: SolidSecurityKeyStatus(
          isKeySaved: _isKeySaved,
          onKeyStatusChanged: _updateKeyStatus,
        ),
      ),
      aboutConfig: SolidAboutConfig(
        applicationName: 'HealthPod',
        applicationVersion: _appVersion,
        applicationIcon: Image.asset(
          'assets/images/app_logo.png',
          width: 100,
          height: 100,
        ),
        applicationLegalese: '© 2025 Software Innovation Institute ANU',
        text: '''

**A Health and Medical Record Manager.**

HealthPod is an app for managing your health data and medical records, keeping
all data stored in your personal online dataset (Pod). Medical documents as well
as a health diary can be maintained.

The app is written in Flutter and the open source code is available from
[github](https://github.com/gjwgit/healthpod). You can try it out online at the
[AU Solid Community](https://healthpod.solidcommunity.au).

The images for the app were generated by ChatGPT.

*Authors: Graham Williams, Ashley Tang, Kevin Wang, Zheyuan Xu.*

*Contributors: .*

**Web ID:** ${_webId ?? 'Web ID is not available and need to login first.'}

''',
        tooltip: '''

        **About:** Tap here to view information about the HealthPod app.
        This includes a list of contributers and the extensive list of
        open-source packages that the HealthPod app is built on and their
        licenses.

        ''',
      ),
    );
  }
}

/// File management content widget using SolidFile.

class _FileManagementContent extends ConsumerStatefulWidget {
  /// Callback function to handle import success navigation.

  final Function(String importType)? onImportSuccess;

  const _FileManagementContent({
    this.onImportSuccess,
  });

  @override
  ConsumerState<_FileManagementContent> createState() =>
      _FileManagementContentState();
}

class _FileManagementContentState
    extends ConsumerState<_FileManagementContent> {
  final GlobalKey<SolidFileBrowserState> _browserKey = GlobalKey();

  /// Flag to track whether the user has manually navigated to a different
  /// folder. If true, we won't override the user's choice with tab
  /// coordination.

  bool _userHasManuallyNavigated = false;

  /// Track the last tab index we coordinated with to avoid redundant
  /// navigation.

  int? _lastCoordinatedTabIndex;

  @override
  void initState() {
    super.initState();
    // Set up the refresh callback after the widget is built.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileServiceProvider.notifier).setRefreshCallback(() {
        _browserKey.currentState?.refreshFiles();
      });

      // Initialise to home folder by default.

      Future(() {
        ref.read(fileServiceProvider.notifier).updateCurrentPath(basePath);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  /// Navigates to the feature-specific folder based on the current tab
  /// selection.

  void _navigateToFeatureFolder() {
    // If the user has manually navigated, don't override their choice.

    if (_userHasManuallyNavigated) {
      return;
    }

    // Read the selected tab index from the provider to coordinate with other
    // tabs.

    final selectedIndex = ref.read(tabStateProvider).selectedIndex;

    // Map the tab index to the corresponding directory name.
    // Index 0: Appointments → diary
    // Index 1: Blood Pressure → blood_pressure
    // Index 2: Medications → medication
    // Index 3: Vaccinations → vaccination

    String featureDir;
    switch (selectedIndex) {
      case 0:
        featureDir = 'diary'; // Appointments
        break;
      case 1:
        featureDir = 'blood_pressure'; // Blood Pressure
        break;
      case 2:
        featureDir = 'medication'; // Medications
        break;
      case 3:
        featureDir = 'vaccination'; // Vaccinations
        break;
      default:
        featureDir = ''; // Default to home
        break;
    }

    final targetPath =
        featureDir.isNotEmpty ? '$basePath/$featureDir' : basePath;
    final currentPath = ref.read(fileServiceProvider).currentPath ?? basePath;
    if (currentPath != targetPath) {
      ref.read(fileServiceProvider.notifier).updateCurrentPath(targetPath);
      _browserKey.currentState?.navigateToPath(targetPath);
    }
  }

  /// Gets the expected path for the current tab selection.

  String _getExpectedPathForCurrentTab() {
    final selectedIndex = ref.read(tabStateProvider).selectedIndex;

    String featureDir;
    switch (selectedIndex) {
      case 0:
        featureDir = 'diary'; // Appointments
        break;
      case 1:
        featureDir = 'blood_pressure'; // Blood Pressure
        break;
      case 2:
        featureDir = 'medication'; // Medications
        break;
      case 3:
        featureDir = 'vaccination'; // Vaccinations
        break;
      default:
        featureDir = ''; // Default to home
        break;
    }

    return featureDir.isNotEmpty ? '$basePath/$featureDir' : basePath;
  }

  /// Creates upload callbacks.

  SolidFileUploadCallbacks _createUploadCallbacks(String currentPath) {
    Map<String, bool> computeDirectoryFlags() {
      final livePath = ref.read(fileServiceProvider).currentPath ?? basePath;
      final isInBpDirectory = livePath.contains('/blood_pressure');
      final isInVaccinationDirectory = livePath.contains('/vaccination');
      final isInMedicationDirectory = livePath.contains('/medication');
      final isInDiaryDirectory = livePath.contains('/diary');

      return {
        'isVaccination': isInVaccinationDirectory,
        'isMedication': isInMedicationDirectory,
        'isDiary': isInDiaryDirectory,
        'isBloodPressure': isInBpDirectory,
      };
    }

    bool inProfileDirectory() {
      final livePath = ref.read(fileServiceProvider).currentPath ?? basePath;
      return livePath.contains('/profile');
    }

    return SolidFileUploadCallbacks(
      onUpload: () => _handleFileUpload(),
      onImportCsv: () => _handleCsvImport(computeDirectoryFlags()),
      onExportCsv: () => _handleCsvExport(computeDirectoryFlags()),
      onImportSuccess: _handleImportSuccess,
      onImportProfile: () {
        if (inProfileDirectory()) _handleProfileImport();
      },
      onExportProfile: () {
        if (inProfileDirectory()) _handleProfileExport();
      },
      onVisualiseJson: () => _handleVisualiseJson(),
      onPreviewFile: () => _handlePreview(),
      onConvertToJson: () => _handleConvertToJson(),
    );
  }

  /// Handles file upload.

  void _handleFileUpload() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null && mounted) {
        ref.read(fileServiceProvider.notifier).setUploadFile(file.path);
        await ref.read(fileServiceProvider.notifier).handleUpload(context);
      }
    }
  }

  /// Handles CSV import.

  void _handleCsvImport(Map<String, bool> directoryFlags) {
    ref.read(fileServiceProvider.notifier).handleCsvImport(
          context,
          isVaccination: directoryFlags['isVaccination'] ?? false,
          isMedication: directoryFlags['isMedication'] ?? false,
          isDiary: directoryFlags['isDiary'] ?? false,
          isBloodPressure: directoryFlags['isBloodPressure'] ?? false,
          onImportSuccess: _handleImportSuccess,
        );
  }

  /// Handles successful CSV import.

  void _handleImportSuccess(String importType) {
    // Call the parent callback if provided.

    widget.onImportSuccess?.call(importType);
  }

  /// Handles CSV export.

  void _handleCsvExport(Map<String, bool> directoryFlags) {
    ref.read(fileServiceProvider.notifier).handleCsvExport(
          context,
          isVaccination: directoryFlags['isVaccination'] ?? false,
          isDiary: directoryFlags['isDiary'] ?? false,
          isMedication: directoryFlags['isMedication'] ?? false,
        );
  }

  /// Handles Profile import.

  void _handleProfileImport() {
    debugPrint('Import Profile functionality');
  }

  /// Handles Profile export.

  void _handleProfileExport() {
    debugPrint('Export Profile functionality');
  }

  /// Handles JSON visualisation.

  void _handleVisualiseJson() async {
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
    if (state.downloadFile != null && state.downloadFile!.isNotEmpty) {
      filePath = '${state.downloadFile}/${state.remoteFileName}';
    } else {
      // Fallback to manual construction using currentPath.

      filePath = state.currentPath == basePath
          ? '$basePath/${state.remoteFileName}'
          : '${state.currentPath}/${state.remoteFileName}';
    }

    try {
      // Read the file content from POD.

      final fileContent = await readPod(
        filePath,
        context,
        const Text('Reading JSON file'),
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

        setState(() {});
      }
    } catch (e) {
      debugPrint('Failed to load JSON: ${e.toString()}');
    }
  }

  /// Handles file preview.

  Future<void> _handlePreview() async {
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

    final filePath = state.currentPath == basePath
        ? '$basePath/${state.remoteFileName}'
        : '${state.currentPath}/${state.remoteFileName}';

    try {
      // Read the file content from POD.

      final fileContent = await readPod(
        filePath,
        context,
        const Text('Reading file'),
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

  void _handleConvertToJson() {
    debugPrint('Convert to JSON functionality');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileServiceProvider);
    final currentPath = state.currentPath ?? basePath;

    // Watch the tab state and trigger navigation when it changes.

    final currentTabState = ref.watch(tabStateProvider);

    // Check if tab has changed and we need to coordinate navigation.

    if (!_userHasManuallyNavigated &&
        _lastCoordinatedTabIndex != currentTabState.selectedIndex) {
      // Update the last coordinated index.

      _lastCoordinatedTabIndex = currentTabState.selectedIndex;

      // Use a post-frame callback to trigger navigation after build completes.

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_userHasManuallyNavigated) {
          _navigateToFeatureFolder();
        }
      });
    }

    return SolidFile(
      basePath: basePath,
      currentPath: currentPath,
      browserKey: _browserKey,
      autoConfig: true,
      showBackButton: true,
      backButtonText: 'Back to Home Folder',
      onBackPressed: () {
        const rootPath = basePath;
        // Set manual navigation flag to prevent automatic coordination after
        // back press.

        _userHasManuallyNavigated = true;

        // Reset coordinated index to allow future tab coordination if needed.

        _lastCoordinatedTabIndex = null;
        ref.read(fileServiceProvider.notifier).updateCurrentPath(rootPath);
        _browserKey.currentState?.navigateToPath(rootPath);

        // Re-enable coordination after a short delay to allow tab coordination
        // again.

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _userHasManuallyNavigated = false;
          }
        });

        // Force refresh the widget to ensure immediate update.

        setState(() {});
      },
      onFileSelected: (fileName, filePath) {
        ref.read(fileServiceProvider.notifier)
          ..setDownloadFile(filePath)
          ..setFilePreview(fileName)
          ..setRemoteFileName(path.basename(fileName));
      },
      onFileDownload: (fileName, filePath) async {
        ref.read(fileServiceProvider.notifier)
          ..setDownloadFile(filePath)
          ..setRemoteFileName(path.basename(fileName))
          ..handleDownload(context);
      },
      onFileDelete: (fileName, filePath) async {
        // Show confirmation dialogue before deleting.

        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: Text(
                'Are you sure you want to delete "$fileName"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );

        if (!context.mounted) return;

        if (confirm == true) {
          String actualPath = '$filePath/$fileName';

          try {
            // Delete the main file first.

            await deleteFile(actualPath);

            // Try to delete the ACL file.

            try {
              await deleteFile('$actualPath.acl');
            } catch (e) {
              // ACL files are optional and may not exist.
            }

            // Show success message.

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('File deleted successfully'),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              );

              // Refresh the file browser.

              _browserKey.currentState?.refreshFiles();
            }
          } catch (e) {
            if (context.mounted) {
              final message = e.toString().contains('404') ||
                      e.toString().contains('NotFoundHttpError')
                  ? 'File not found or already deleted'
                  : 'Delete failed: ${e.toString()}';

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      onImportCsv: (fileName, filePath) {
        // Import CSV functionality would be implemented here.

        debugPrint('Import CSV: $fileName at $filePath');
      },
      onDirectoryChanged: (path) {
        final expectedPath = _getExpectedPathForCurrentTab();
        final isTabCoordinatedNavigation = (path == expectedPath);

        if (!isTabCoordinatedNavigation) {
          _userHasManuallyNavigated = true;
          _lastCoordinatedTabIndex = null;
        }

        ref.read(fileServiceProvider.notifier).updateCurrentPath(path);
      },
      onClosePreview: () {
        final currentState = ref.read(fileServiceProvider);
        if (currentState.showPreview) {
          ref.read(fileServiceProvider.notifier).togglePreview();
        }
      },
      uploadCallbacks: _createUploadCallbacks(currentPath),
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
