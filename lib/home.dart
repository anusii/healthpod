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

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidpod/solidpod.dart' show getAppNameVersion;
import 'package:solidui/solidui.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/charts/tab.dart';
import 'package:healthpod/features/file/service/providers/file_service_provider.dart';
import 'package:healthpod/features/resources/tab.dart';
import 'package:healthpod/features/table/tab.dart';
import 'package:healthpod/features/update/tab.dart';
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

// Define the menu items for SolidScaffold navigation.

List<SolidMenuItem> _buildHealthPodMenu() => [
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
  const _FileManagementContent();

  @override
  ConsumerState<_FileManagementContent> createState() =>
      _FileManagementContentState();
}

class _FileManagementContentState
    extends ConsumerState<_FileManagementContent> {
  final GlobalKey<SolidFileBrowserState> _browserKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Set up the refresh callback after the widget is built.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileServiceProvider.notifier).setRefreshCallback(() {
        _browserKey.currentState?.refreshFiles();
      });
      _navigateToFeatureFolder();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigateToFeatureFolder();
  }

  /// Navigates to the feature-specific folder.

  void _navigateToFeatureFolder() {
    final currentPath = ref.read(fileServiceProvider).currentPath ?? basePath;
    _browserKey.currentState?.navigateToPath(currentPath);
  }

  /// Creates upload callbacks based on current path.

  SolidFileUploadCallbacks _createUploadCallbacks(String currentPath) {
    // Determine which type of directory we're in.

    final isInBpDirectory = currentPath.contains('/bp');
    final isInVaccinationDirectory = currentPath.contains('/vaccination');
    final isInMedicationDirectory = currentPath.contains('/medication');
    final isInDiaryDirectory = currentPath.contains('/diary');
    final isInProfileDirectory = currentPath.contains('/profile');

    // Determine if we should show buttons.

    final showCsvButtons = isInBpDirectory ||
        isInVaccinationDirectory ||
        isInMedicationDirectory ||
        isInDiaryDirectory;
    final showProfileButtons = isInProfileDirectory;

    return SolidFileUploadCallbacks(
      onUpload: () => _handleFileUpload(),
      onImportCsv: showCsvButtons
          ? () => _handleCsvImport({
                'isVaccination': isInVaccinationDirectory,
                'isMedication': isInMedicationDirectory,
                'isDiary': isInDiaryDirectory,
                'isBloodPressure': isInBpDirectory,
              })
          : null,
      onExportCsv: showCsvButtons
          ? () => _handleCsvExport({
                'isVaccination': isInVaccinationDirectory,
                'isMedication': isInMedicationDirectory,
                'isDiary': isInDiaryDirectory,
                'isBloodPressure': isInBpDirectory,
              })
          : null,
      onImportProfile: showProfileButtons ? () => _handleProfileImport() : null,
      onExportProfile: showProfileButtons ? () => _handleProfileExport() : null,
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
        );
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        await _handlePreview();
      }
    }
  }

  /// Handles file preview.

  Future<void> _handlePreview() async {
    debugPrint('Preview file functionality');
  }

  /// Handles PDF to JSON conversion.

  void _handleConvertToJson() {
    debugPrint('Convert to JSON functionality');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileServiceProvider);
    final currentPath = state.currentPath ?? basePath;

    return SolidFile(
      basePath: basePath,
      currentPath: currentPath,
      browserKey: _browserKey,
      onBackPressed: () {
        const rootPath = basePath;
        if (state.currentPath != rootPath) {
          ref.read(fileServiceProvider.notifier).updateCurrentPath(rootPath);
          _browserKey.currentState?.navigateToPath(rootPath);
        }
      },
      onFileSelected: (fileName, filePath) {
        ref.read(fileServiceProvider.notifier)
          ..setDownloadFile(filePath)
          ..setFilePreview(fileName)
          ..setRemoteFileName(fileName);
      },
      onFileDownload: (fileName, filePath) async {
        ref.read(fileServiceProvider.notifier)
          ..setDownloadFile(filePath)
          ..setRemoteFileName(fileName)
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

        if (confirm == true) {
          // Delete functionality would be implemented here.

          debugPrint('Delete file: $filePath');
          _browserKey.currentState?.refreshFiles();
        }
      },
      onImportCsv: (fileName, filePath) {
        // Import CSV functionality would be implemented here.

        debugPrint('Import CSV: $fileName at $filePath');
      },
      onDirectoryChanged: (path) {
        ref.read(fileServiceProvider.notifier).updateCurrentPath(path);
      },
      uploadCallbacks: _createUploadCallbacks(currentPath),
      uploadState: SolidFileUploadState(
        uploadInProgress: state.uploadInProgress,
        importInProgress: state.importInProgress,
        exportInProgress: state.exportInProgress,
        uploadedFilePath: state.uploadFile,
        uploadDone: state.uploadDone,
      ),
    );
  }
}
