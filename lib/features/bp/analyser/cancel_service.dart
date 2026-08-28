/// Telling the Analyser Pod to abandon the analysis in progress.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU
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
/// Authors: Tony Chen

library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:http/http.dart' as http;

import 'package:healthpod/constants/analyser.dart';

/// How a request to stop the analysis was received.

enum CancelOutcome {
  /// The analyser took the request. Whether a cycle was actually running is
  /// carried separately, in [AnalyserCancel.wasRunning].

  accepted,

  /// No analyser API address is configured, so there was nobody to tell.

  notConfigured,

  /// The analyser could not be reached, or refused the request.

  unreachable,
}

/// What came back from asking the analyser to stop.

class AnalyserCancel {
  const AnalyserCancel(this.outcome, {this.wasRunning = false, this.message});

  /// How the request was received.

  final CancelOutcome outcome;

  /// Whether a cycle was in progress when the request arrived.
  ///
  /// False also when the analyser was idle, which is the ordinary case for a
  /// cancellation made in the seconds after sharing: the watcher polls its
  /// sharing inbox, so the run this user set off may not have begun. The
  /// analyser withdraws it either way.

  final bool wasRunning;

  /// Why the request could not be delivered, when it could not be.

  final String? message;

  /// Whether the analyser has the request.

  bool get delivered => outcome == CancelOutcome.accepted;
}

/// Asks the analyser to stop the analysis it is running for this app.
///
/// The readings reach the analyser through the Pod, and Solid has no notion
/// of withdrawing work already under way, so this goes to the analyser's own
/// control API instead — the same interface that serves the front end its
/// figures. The service records the request and acts on it at the next point
/// in its cycle where stopping is safe; nothing is interrupted mid-write.
///
/// The call is deliberately forgiving. That API is optional, and is bound to
/// the loopback address by default, so an app on another machine will often
/// find nothing there. Cancelling still does what the user asked of the app
/// — it stops waiting — and this only adds the part that stops the server.

class BPAnalyserCancelService {
  /// How long to wait for the analyser to answer.
  ///
  /// Short on purpose: the user has already pressed cancel, and must not then
  /// sit through a second wait to find out whether it worked.

  static const Duration timeout = Duration(seconds: 5);

  /// Asks the analyser to abandon the run in progress.

  static Future<AnalyserCancel> cancel() async {
    if (!Analyser.apiConfigured) {
      return const AnalyserCancel(
        CancelOutcome.notConfigured,
        message: 'No analyser address is configured, so the analysis was only '
            'stopped in this app.',
      );
    }

    try {
      final response = await http.post(
        Uri.parse(Analyser.cancelUrl),
        headers: {
          if (Analyser.apiToken.isNotEmpty)
            'Authorization': 'Bearer ${Analyser.apiToken}',
        },
      ).timeout(timeout);

      if (response.statusCode != 200) {
        return AnalyserCancel(
          CancelOutcome.unreachable,
          message: 'The ${Analyser.displayName} refused the request '
              '(${response.statusCode}).',
        );
      }

      // `active` describes the cycle that was running, and is null when the
      // analyser was idle. A body that cannot be read is not worth failing
      // over: the analyser answered, so it has the request.

      var wasRunning = false;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          wasRunning = decoded['active'] != null;
        }
      } catch (e) {
        debugPrint('Could not read the cancellation response: $e');
      }

      return AnalyserCancel(CancelOutcome.accepted, wasRunning: wasRunning);
    } catch (e) {
      debugPrint('Could not reach the ${Analyser.displayName} to cancel: $e');

      return const AnalyserCancel(
        CancelOutcome.unreachable,
        message: 'Could not reach the ${Analyser.displayName} to stop it, so '
            'the analysis was only stopped in this app.',
      );
    }
  }
}
