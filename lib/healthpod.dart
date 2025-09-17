/// HealthPod - Collect and analyse health data preserving privacy using PODs.
///
// Time-stamp: <Wednesday 2025-07-23 16:30:10 +1000 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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
import 'package:solidui/solidui.dart';

import 'package:healthpod/providers/settings.dart';
import 'package:healthpod/theme/app_theme.dart';
import 'package:healthpod/utils/create_solid_login.dart';

/// The root widget for the [HealthPod] app.
///
/// The widget essentially orchestrates the building of other
/// widgets. Generically we set up to build a Home widget containing the
/// App. For SolidPod we wrap the Home widget within [SolidLogin] to start with
/// a login screen, though this is optional.

class HealthPod extends ConsumerStatefulWidget {
  const HealthPod({super.key});

  @override
  ConsumerState<HealthPod> createState() => _HealthPodState();
}

class _HealthPodState extends ConsumerState<HealthPod> {
  Widget? _loginWidget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _loginWidget = createSolidLogin(context);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialise settings.

    ref.watch(settingsInitializerProvider);

    return SolidThemeApp(
      title: 'Solid Health Pod',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: SelectionArea(
        child: _loginWidget ?? createSolidLogin(context),
      ),
    );
  }
}
