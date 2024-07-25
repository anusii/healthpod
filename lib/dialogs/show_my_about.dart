/// An About dialog for the app.
///
// Time-stamp: <Thursday 2024-07-25 20:20:09 +1000 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
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
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:solidpod/solidpod.dart';

Future<void> showMyAbout(BuildContext context, {String? webId}) async {
  final appInfo = await getAppNameVersion();

  if (context.mounted) {
    showAboutDialog(
      context: context,
      applicationLegalese: '© 2024 Software Innovation Institute ANU',
      applicationIcon: Image.asset(
        'assets/images/healthpod_logo.png',
        width: 100,
        height: 100,
      ),
      applicationName: appInfo.name,
      applicationVersion: appInfo.version,
      children: [
        SizedBox(
          // Limit the width of the about dialog box.

          width: 300,

          child: Column(
            children: [
              const MarkdownBody(
                selectable: true,
                data: '''
**A Health and Medical Record Manager.**

HealthPod is an app for managing your health data and medical records, keeping
all data stored in your personal online dataset (Pod). Medical documents as well
as a health diary can be maintained.

The app is written in Flutter and the open source code
is available from github at https://github.com/gjwgit/healthpod.
You can try it out online at https://healthpod.solidcommunity.au.

The images for the app were generated by ChatGPT.

*Authors: Graham Williams.*

*Contributors: .*

''',
              ),
              const SizedBox(
                height: 10,
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: SelectableText.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Web ID: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: webId ??
                            'Web ID is not available and need to login first.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
