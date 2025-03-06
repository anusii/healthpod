/// Widget shows the address link and it can launch Google Maps.
//
// Time-stamp: <Friday 2025-02-21 08:30:05 +1100 Graham Williams>
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
/// Authors: Zheyuan Xu

library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:healthpod/dialogs/alert.dart';

/// The widget creates a [TextSpan] with an underline and blue color styling
/// that, when tapped, attempts to launch Google Maps with the provided address.
/// The address is formatted into a Google Maps URL and opened in an external
/// application. If the URL fails to launch, a dialog will inform the user.

TextSpan addressLink(String clinicAddress, BuildContext context,
    {double fontSize = 16}) {
  // Make clinicAddress understandable to Google Map.

  String matchAddress = '';

  if (clinicAddress.contains('Gurriny Yealamucka') ||
      clinicAddress.contains('Visiting Services Gurriny Yealamucka')) {
    matchAddress = '1 Bukki Rd, Yarrabah QLD 4871';
  } else if (clinicAddress.contains('Workshop Street')) {
    matchAddress = '177 Workshop Rd, Yarrabah QLD 4871';
  }
  // Convert spaces to '+' to create a URL-friendly version of the address.

  final String mapUrl = matchAddress.isNotEmpty
      ? 'https://www.google.com/maps/place/${matchAddress.replaceAll(' ', '+')}/'
      : 'https://www.google.com/maps/place/${clinicAddress.replaceAll(' ', '+')}/';

  return clinicAddress.isEmpty || clinicAddress == 'N/A'
      ? TextSpan(
          text: clinicAddress,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.black,
          ),
        )
      : TextSpan(
          text: clinicAddress,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              try {
                await launchUrl(
                  Uri.parse(mapUrl),
                  mode: LaunchMode.externalApplication,
                );
              } catch (e) {
                // Handle failure to launch the URL, potentially with a logging framework or UI feedback.

                if (context.mounted) {
                  alert(context, 'Warning!', 'Cannot launch google map!');
                }
              }
            },
        );
}
