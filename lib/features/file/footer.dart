/// Footer widget to display server information, login status, and security key status.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
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

/// Footer widget to display server information, login status, and security key status.

class FooterWidget extends StatelessWidget {
  final String? webId;
  final bool isKeySaved;

  const FooterWidget({
    super.key,
    required this.webId,
    required this.isKeySaved,
  });

  @override
  Widget build(BuildContext context) {
    final serverUri = webId?.split('/profile')[0] ?? 'Not connected';

    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Server: $serverUri',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'Login Status: ${webId == null ? "Not Logged In" : "Logged In"}',
            style: TextStyle(
              fontSize: 14,
              color: webId == null ? Colors.red : Colors.green,
            ),
          ),
          Text(
            'Security Key: ${isKeySaved ? "Saved" : "Not Saved"}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}