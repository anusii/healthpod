/// HealthPod - Collect and analyse health data preserving privacy using PODs.
///
// Time-stamp: <Wednesday 2025-07-23 16:34:25 +1000 Graham Williams>
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
/// Authors: Graham Williams, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:healthpod/utils/is_desktop.dart';
import 'package:healthpod/utils/security_key/central_key_manager.dart';

import 'healthpod.dart';

/// Main entry point for the [HealthPod] application.

void main() async {
  // This is the main entry point for the app. The [async] is required because
  // we asynchronously [await] the window manager below. Often, `main()` will
  // include only [runApp].

  // Globally remove [debugPrint] messages.

  // debugPrint = (String? message, {int? wrapWidth}) {
  //   null;
  // };

  // Ensure Flutter bindings are initialized for async operations

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize CentralKeyManager to handle all user security key requests.

  CentralKeyManager.instance;

  if (isDesktop(PlatformWrapper())) {
    // Support [windowManager] options for the desktop. We do this here before
    // running the app. If there is no [windowManager] options we probably don't
    // need this whole section.

    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      // Set various desktop window options here.

      // Setting [alwaysOnTop] here will ensure the app starts on top of other
      // apps on the desktop so that it is visible (otherwise, with GNOME on
      // Ubuntu the app is often lost below other windows on startup).
      // We later turn it off as we don't want to force it always on top.

      alwaysOnTop: true,

      // The [title] is used for the window manager's window title.

      title: 'HealthPod - Private Solid Pod for Health Data',
    );

    // Once the window manager is ready we reconfigure it a little.

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setAlwaysOnTop(false);
    });
  }

  // The runApp() function takes the given Widget and makes it the root of the
  // widget tree.

  runApp(const ProviderScope(child: HealthPod()));
}
