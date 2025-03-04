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

library;

import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:universal_io/io.dart' show Platform;
import 'package:ussd_phone_call_sms/ussd_phone_call_sms.dart';

import 'package:healthpod/utils/show_alert.dart';

/// A widget that displays a phone icon which is interactive on iOS and Android platforms.
///
/// This widget provides a phone call functionality by tapping on the icon for mobile platforms.
/// On non-mobile platforms, it simply displays an icon without interaction capabilities.
///
/// When tapped, the widget attempts to initiate a phone call to the provided [contactNumber].
/// If the phone call cannot be initiated (e.g., due to permission issues or an invalid number),
/// it displays a popup dialog with a warning message.

class CallIcon extends StatefulWidget {
  /// The contact number to call.

  final String contactNumber;

  /// Constructor for the CallIcon widget.

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
    return (Platform.isIOS || Platform.isAndroid)
        ? GestureDetector(
            child: Icon(Icons.phone, color: _iconColor),
            onTap: () async {
              await _showConfirmationDialog(context);
            },
          )
        : Icon(Icons.phone, color: Colors.black);
  }

  /// Displays a dialog prompting the user to grant phone call permissions.
  ///
  /// This dialog is triggered when an attempt to make a phone call detects
  /// that the necessary permissions have not been granted. The dialog offers
  /// two options to the user: 'Cancel' and 'Ok'. Selecting 'Ok' will prompt
  /// the user directly to grant the required permissions.

  Future<void> _showPermissionDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Permission Required"),
        content: Text(
            "This app requires phone call permissions to make a call. Please enable it."),
        actions: <Widget>[
          ElevatedButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text("Ok"),
            onPressed: () async {
              await Permission.phone.request();

              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  /// Displays a dialog instructing the user to manually enable phone permissions.
  ///
  /// This method is triggered when the phone permission has been permanently denied and
  /// cannot be requested directly via the app. The dialog provides a clear message to the user
  /// about the necessity of the phone permission for making calls and directs them to open
  /// the app settings to enable the permission manually.

  Future<void> _showManualPermissionSettingDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Needed'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This app needs phone permission to make calls.'),
                Text('Please enable it in the app settings.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Settings'),
              onPressed: () async {
                await openAppSettings(); // This will open the app settings page
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a confirmation dialog before initiating the phone call.

  Future<void> _showConfirmationDialog(
    BuildContext context,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Call"),
        content: Text("Are you sure you want to call the clinic?"),
        actions: <Widget>[
          ElevatedButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text("Yes"),
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog first.

              await _initiatePhoneCall(context);
            },
          ),
        ],
      ),
    );
  }

  /// Initiates the phone call process, including checking permissions.

  Future<void> _initiatePhoneCall(BuildContext context) async {
    setState(() {
      _iconColor = Colors.red;
    });

    var callStatus = await Permission.phone.status;
    if (callStatus.isPermanentlyDenied) {
      await _showManualPermissionSettingDialog();
    } else if (callStatus.isDenied) {
      await _showPermissionDialog(context);
    } else {
      try {
        await UssdPhoneCallSms().phoneCall(phoneNumber: widget.contactNumber);
      } catch (e) {
        showAlert(context,
            'Fail to call ${widget.contactNumber}! Please check app permission!');
      }
    }

    setState(() {
      _iconColor = Colors.deepPurple;
    });
  }
}
