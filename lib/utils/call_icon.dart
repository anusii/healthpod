/// Icon to call in mobile devices.
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

// ignore_for_file: use_build_context_synchronously

library;

import 'package:flutter/material.dart';

import 'package:universal_io/io.dart' show Platform;
import 'package:ussd_phone_call_sms/ussd_phone_call_sms.dart';

import 'package:healthpod/utils/show_alert.dart';

/// A widget that displays a phone icon. On iOS, Android, and Linux the icon is interactive.
/// (Permission checks have been removed for Linux since permission_handler does not work there.).

class CallIcon extends StatefulWidget {
  final String contactNumber;

  const CallIcon({
    super.key,
    required this.contactNumber,
  });

  @override
  State<CallIcon> createState() => _CallIconState();
}

class _CallIconState extends State<CallIcon> {
  Color _iconColor = Colors.deepPurple;

  @override
  Widget build(BuildContext context) {
    // Enable interactive behavior on iOS, Android, and Linux.

    if (Platform.isIOS || Platform.isAndroid || Platform.isLinux) {
      return GestureDetector(
        child: Icon(Icons.phone, color: _iconColor),
        onTap: () async {
          await _showConfirmationDialog(context);
        },
      );
    } else {
      return Icon(Icons.phone, color: Colors.black);
    }
  }

  /// Displays a confirmation dialog before initiating the phone call.
  
  Future<void> _showConfirmationDialog(BuildContext context) async {
    // Capture the current BuildContext synchronously.

    final localContext = context;
    showDialog(
      context: localContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirm Call"),
        content: const Text("Are you sure you want to call the clinic?"),
        actions: <Widget>[
          ElevatedButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ElevatedButton(
            child: const Text("Yes"),
            onPressed: () async {
              Navigator.of(dialogContext).pop(); 
              await _initiatePhoneCall(localContext);
            },
          ),
        ],
      ),
    );
  }

  /// Initiates the phone call process.
  
  Future<void> _initiatePhoneCall(BuildContext context) async {
    // Capture the BuildContext synchronously.

    final localContext = context;
    if (!mounted) return;

    setState(() {
      _iconColor = Colors.red;
    });

    // For iOS/Android/Linux, simply attempt the phone call.

    try {
      await UssdPhoneCallSms().phoneCall(phoneNumber: widget.contactNumber);
    } catch (e) {
      if (!mounted) return;

      showAlert(localContext,
          'Fail to call ${widget.contactNumber}! Please check app permission or platform support!');
    }

    if (!mounted) return;
    setState(() {
      _iconColor = Colors.deepPurple;
    });
  }
}
