/// Creates a SolidLogin widget with consistent configuration.
//
// Time-stamp: <Tuesday 2025-01-14 09:29:45 +1100 Graham Williams>
//
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/home.dart';

/// Creates a SolidLogin widget with consistent configuration.

Widget createSolidLogin(BuildContext context) {
  return const SolidLogin(
    // If the app has functionality that does not require access to Pod
    // data then [required] can be `false`. If the user connects to their
    // Pod then their session information will be saved to save having to
    // log in everytime. The login token and the security key are (optionally)
    // cached so that the login information is not required every time.
    //
    // In this demo app we allow the CONTINUE button so as to demonstrate
    // the use of [SolidLoginPopup] during the app session. If we want to
    // save the data to the Pod or view data from the Pod, then if the
    // user did not log in during startup we can call [SolidLoginPopup] to
    // establish the connection at that time.

    required: false,
    title: 'HEALTH POD',
    appDirectory: 'healthpod',
    webID: 'https://pods.dev.solidcommunity.au', // Set default server to dev.
    image: AssetImage('assets/images/healthpod_image.png'),
    logo: AssetImage('assets/images/healthpod_icon.png'),
    link: 'https://github.com/anusii/healthpod/blob/main/README.md',
    child: HealthPodHome(),
  );
}
