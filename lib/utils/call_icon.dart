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

import 'package:permission_handler/permission_handler.dart';
import 'package:universal_io/io.dart' show Platform;
import 'package:ussd_phone_call_sms/ussd_phone_call_sms.dart';

import 'package:healthpod/utils/show_alert.dart';

/// A widget that displays a phone icon. On iOS, Android, and Linux the icon is interactive.
/// On Linux, we bypass permission checks because permission_handler does not support Linux.

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
    // Enable interactive behavior on mobile and Linux.

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

  Future<void> _showPermissionDialog(BuildContext context) async {
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
            "This app requires phone call permissions to make a call. Please enable it."),
        actions: <Widget>[
          ElevatedButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          ElevatedButton(
            child: const Text("Ok"),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result == true) {
      await Permission.phone.request();
    }
  }

  Future<void> _showManualPermissionSettingDialog() async {
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Permission Needed'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This app needs phone permission to make calls.'),
                Text('Please enable it in the app settings.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Settings'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (result == true) {
      await openAppSettings();
    }
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    // Capture the context synchronously.

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
              Navigator.of(dialogContext).pop(); // Close the dialog first.
              await _initiatePhoneCall(localContext);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _initiatePhoneCall(BuildContext context) async {
    // Capture the BuildContext synchronously.

    final localContext = context;
    if (!mounted) return;

    setState(() {
      _iconColor = Colors.red;
    });

    // If running on Linux, skip permission checks.

    if (Platform.isLinux) {
      try {
        await UssdPhoneCallSms().phoneCall(phoneNumber: widget.contactNumber);
      } catch (e) {
        if (!mounted) return;
        showAlert(localContext,
            'Fail to call ${widget.contactNumber}! Phone call may not be supported on Linux.');
      }
      if (!mounted) return;
      setState(() {
        _iconColor = Colors.deepPurple;
      });
      return;
    }

    // For iOS/Android, use permission_handler.

    final callStatus = await Permission.phone.status;
    if (!mounted) return;
    if (callStatus.isPermanentlyDenied) {
      await _showManualPermissionSettingDialog();
      if (!mounted) return;
    } else if (callStatus.isDenied) {
      await _showPermissionDialog(localContext);
      if (!mounted) return;
    } else {
      try {
        await UssdPhoneCallSms().phoneCall(phoneNumber: widget.contactNumber);
      } catch (e) {
        if (!mounted) return;
        showAlert(localContext,
            'Fail to call ${widget.contactNumber}! Please check app permission!');
      }
    }

    if (!mounted) return;
    
    setState(() {
      _iconColor = Colors.deepPurple;
    });
  }
}
