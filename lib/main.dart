/// Your health data in your POD.
//
// Time-stamp: <Tuesday 2025-01-07 14:10:07 +1100 Graham Williams>
//
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

import 'package:healthpod/utils/create_solid_login.dart';
import 'package:healthpod/utils/is_desktop.dart';

void main() async {
  // This is the main entry point for the app. The [async] is required because
  // we asynchronously [await] the window manager below. Often, `main()` will
  // simply include just [runApp].

  if (isDesktop(PlatformWrapper())) {
    // Suport [windowManager] options for the desktop. We do this here before
    // running the app. If there is no [windowManager] options we probably don't
    // need this whole section.

    // Ensure things are set up properly since we haven't yet initialised the
    // app with [runApp].

    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      // We can set various desktop window options here.

      // Setting [alwaysOnTop] here will ensure the app starts on top of other
      // apps on the desktop so that it is visible (otherwise, Ubuuntu with
      // GNOME it is often lost below other windows on startup which can be a
      // little disconcerting). We later turn it off as we don't want to force
      // it always on top.

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

  // Ready to run the app.

  runApp(
    const ProviderScope(
      child: HealthPod(),
    ),
  );
}

// The main widget could be in a separate file, but handy having it in main and
// the file is not too large. The widget essentially orchestrates the building
// of other widgets. Generically we set up to build a `Home()` widget containing
// the App. For SolidPod we wrap the `Home()` widget within the `SolidLogin()`
// widget so we start with a login screen, though this is optional.

class HealthPod extends StatelessWidget {
  const HealthPod({super.key});

  // This StatelessWidget is the root of our application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solid Health Pod',
      home: SelectionArea(
        // Wrap the whole app inside a SelectionArea to ensure we get selectable
        // text, for text that can be selected, as a default.

        child: createSolidLogin(context),
      ),
    );
  }
}
