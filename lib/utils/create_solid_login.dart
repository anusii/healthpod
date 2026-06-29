/// Create Solid Login Widget.
//
// Time-stamp: <Monday 2026-06-29 16:08:00 +1000 Graham Williams>
//
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

import 'package:healthpod/home.dart';

/// Solid POD Authentication Widget Creator.
///
/// Returns the standard [SolidLogin] widget, which authenticates against the
/// user's Solid server using an external browser. solidui handles server URL
/// and security-key entry as part of the login flow.

Widget createSolidLogin(BuildContext context) {
  return const SolidLogin(
    required: false,
    title: 'Health Pod\nManage and Query Health Docs',
    appDirectory: 'healthpod',
    image: AssetImage('assets/images/app_image.jpg'),
    logo: AssetImage('assets/images/app_icon.png'),
    link: 'https://github.com/anusii/healthpod/blob/main/README.md',
    clientId: 'https://anusii.github.io/healthpod/client-profile.jsonld',
    redirectUris: [
      'https://anusii.github.io/healthpod/redirect.html',
      'com.togaware.healthpod://redirect',
      'http://localhost:4400/redirect',
    ],
    child: HealthPodHome(),
  );
}
