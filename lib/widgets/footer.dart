/// Footer widget to display server information, login status, and security key status.
//
// Time-stamp: <Tuesday 2025-01-14 21:20:03 +1100 Graham Williams>
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
import 'package:healthpod/features/file/security_key/manager.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:healthpod/utils/create_solid_login.dart';
import 'package:healthpod/utils/create_interactive_text.dart';
import 'package:healthpod/utils/handle_logout.dart';

/// Footer widget to display server information, login status, and security key
/// status.

class Footer extends StatelessWidget {
  final String? webId;
  final bool isKeySaved;

  const Footer({
    super.key,
    required this.webId,
    required this.isKeySaved,
  });

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Widget _buildTextRow(String label, String value, {Color? valueColor}) {
    return Text(
      '$label: $value',
      style: TextStyle(fontSize: 14, color: valueColor ?? Colors.black),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget buildServerInteractiveText(String serverUri, BuildContext context) {
    return createInteractiveText(
      context: context,
      text: serverUri,
      onTap: () => _launchUrl(serverUri),
      style: TextStyle(fontSize: 14, color: Colors.blue),
    );
  }

  Widget buildLoginStatusInteractiveText(
      String loginStatus, BuildContext context) {
    return createInteractiveText(
      context: context,
      text: 'Login Status: ${webId == null ? "Not Logged In" : "Logged In"}',
      onTap: () {
        if (webId != null) {
          handleLogout(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => createSolidLogin(context)),
          );
        }
      },
      style: TextStyle(
        fontSize: 14,
        color: webId == null ? Colors.red : Colors.green,
      ),
    );
  }

    Widget buildSecurityKeyStatusInteractiveText(
      String securityKeyStatus, BuildContext context) {
    return MarkdownTooltip(
      message: '''

      **Security Key Manager:** Tap here to manage your security key settings.

      - View your current security key status

      - Save a new security key
      
      - Remove an existing security key
      
      Your security key is essential for encrypting and protecting your health data.
      
      ''',
      child: createInteractiveText(
      context: context,
      text: securityKeyStatus,
      onTap: () => showDialog(
        context: context,
        barrierColor: Colors.black12, // Makes the background more transparent
        builder: (BuildContext context) => const SecurityKeyManager(),
      ),
      style: TextStyle(
        fontSize: 14,
          color: isKeySaved ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildNarrowLayout(String serverUri, String loginStatus,
      Color loginStatusColor, String securityKeyStatus, BuildContext context) {
    return Container(
      color: Colors.grey[200],
      height: 90.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildServerInteractiveText(serverUri, context),
            const SizedBox(height: 2),
            buildLoginStatusInteractiveText(loginStatus, context),
            const SizedBox(height: 2),
            buildSecurityKeyStatusInteractiveText(securityKeyStatus, context),
          ],
        ),
      ),
    );
  }

  Widget _buildMediumLayout(String serverUri, String loginStatus,
      Color loginStatusColor, String securityKeyStatus, BuildContext context) {
    return Container(
      color: Colors.grey[200],
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildServerInteractiveText(serverUri, context),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildLoginStatusInteractiveText(loginStatus, context),
                  const SizedBox(width: 16),
                  buildSecurityKeyStatusInteractiveText(
                      securityKeyStatus, context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(String serverUri, String loginStatus,
      Color loginStatusColor, String securityKeyStatus, BuildContext context) {
    return Container(
      color: Colors.grey[200],
      height: 50.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: buildServerInteractiveText(serverUri, context),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildLoginStatusInteractiveText(loginStatus, context),
              const SizedBox(width: 16),
              buildSecurityKeyStatusInteractiveText(securityKeyStatus, context),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 20250114 gjw Ensure we retain the final '/' for the serverUri else we get
    // a link to the 'Not logged in' page. With the final '/' we get to the
    // publicly visible page of the user's Pod. Thus strip the final `profile`
    // not eh final `/profile`.

    final serverUrl = webId?.split('profile')[0] ?? 'Not connected';

    final loginStatus = webId == null ? "Not Logged In" : "Logged In";
    final loginStatusColor = webId == null ? Colors.red : Colors.green;
    final securityKeyStatus =
        isKeySaved ? "Security Key: Saved" : "Security Key: Not Saved";

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          return _buildNarrowLayout(
            serverUrl,
            loginStatus,
            loginStatusColor,
            securityKeyStatus,
            context,
          );
        } else if (constraints.maxWidth < 600) {
          return _buildMediumLayout(
            serverUrl,
            loginStatus,
            loginStatusColor,
            securityKeyStatus,
            context,
          );
        } else {
          return _buildWideLayout(
            serverUrl,
            loginStatus,
            loginStatusColor,
            securityKeyStatus,
            context,
          );
        }
      },
    );
  }
}
