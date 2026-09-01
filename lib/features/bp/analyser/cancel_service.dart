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
import 'package:solidpod/solidpod.dart' show getTokensForResource, getWebId;

import 'package:healthpod/constants/analyser.dart';
import 'package:healthpod/features/bp/analyser/result_service.dart';

/// How a request to stop the analysis ended.

enum CancelOutcome {
  /// The analyser took the request, and so has stopped.
  ///
  /// It removes a request as it collects it, and it only collects one at a
  /// point where it is about to act on it, so the request disappearing is
  /// the analyser saying it has stopped.

  stopped,

  /// The request was left in the Analyser Pod but was still sitting there
  /// when this gave up watching.
  ///
  /// Almost always means the analyser is not running. It will collect the
  /// request whenever it next starts, and refuse it once it has gone stale.

  notCollected,

  /// The user is not logged in, so there is no Pod to write from and no
  /// WebID to sign the request with.

  notLoggedIn,

  /// The request could not be written to the Analyser Pod at all.

  undelivered,
}

/// What came of asking the analyser to stop.

class AnalyserCancel {
  const AnalyserCancel(this.outcome, {this.message});

  /// How the request ended.

  final CancelOutcome outcome;

  /// What went wrong, when something did.

  final String? message;

  /// Whether the analyser stopped.
  ///
  /// True only for [CancelOutcome.stopped]: leaving the request somewhere the
  /// analyser can find it is not the same as it having acted on one, and the
  /// difference is exactly what the user is asking about.

  bool get stopped => outcome == CancelOutcome.stopped;
}

/// Asks the analyser to stop the analysis it is running for this user.
///
/// The analyser has an HTTP interface, but it binds to the server's loopback
/// address, so an app on somebody's laptop has no route to it. What the app
/// does have is the Pod: solidpod grants public read and write on a Pod's
/// `<app>/shared/` container precisely so other agents can deliver sealed
/// keys into it, and the same door takes a message. So a cancellation is a
/// small JSON file written into the Analyser Pod:
///
///     <analyser>/healthpod/shared/cancel-<pod-id>.json
///
/// The analyser reads that container between the steps of its cycle and
/// abandons the run. One file per requester, named after the Pod asking, so
/// two people cancelling at once do not overwrite each other's request.
///
/// The request carries the WebID it came from, and the analyser ignores one
/// naming a Pod that has shared nothing with it. That is a narrowing rather
/// than a guarantee — the container is publicly writable, which is what makes
/// this work at all — so requests also go stale, and the analyser drops one
/// older than `watch.cancel_max_age_seconds`.
///
/// Writing the request is not the same as the analyser acting on it, and it is
/// the second that the user is asking about. The analyser removes a request as
/// it collects it, so this watches the file it wrote and reports success when
/// that disappears. An analyser that is not running leaves it sitting there,
/// and the answer is an honest failure rather than a cheerful message about a
/// service that never heard.

class BPAnalyserCancelService {
  /// The version of the request document the analyser expects.

  static const int schemaVersion = 1;

  /// How long to wait for the write before giving up.

  static const Duration timeout = Duration(seconds: 8);

  /// How long to watch for the analyser to collect the request.
  ///
  /// An analyser part way through a cycle looks between its steps, every
  /// `watch.cancel_poll_seconds` (three by default), so the usual answer
  /// arrives in a few seconds. An idle one looks once per `watch.poll_seconds`
  /// (thirty), which is the case this has to outlast — hence a window rather
  /// wider than the common answer needs.

  static const Duration confirmTimeout = Duration(seconds: 40);

  /// How often to look while waiting for that.

  static const Duration confirmInterval = Duration(seconds: 1);

  /// The request document the analyser reads.

  static Map<String, dynamic> request(String webId, DateTime at) => {
        'schema_version': schemaVersion,
        'kind': 'cancel-request',
        'web_id': webId,
        'requested_at': at.toUtc().toIso8601String(),
      };

  /// Leaves a request to stop in the Analyser Pod.

  static Future<AnalyserCancel> cancel() async {
    final webId = await getWebId();
    if (webId == null || webId.isEmpty) {
      return const AnalyserCancel(
        CancelOutcome.notLoggedIn,
        message: 'You are no longer logged in, so the analysis was only '
            'stopped in this app.',
      );
    }

    // Named after the requesting Pod, which is also how the analyser labels
    // the results it publishes, so the two line up in a directory listing.

    final url = Analyser.cancelUrl(BPAnalyserResultService.podId(webId));
    final body = jsonEncode(request(webId, DateTime.now()));

    try {
      // Written straight rather than through solidpod's own helpers: those
      // work within the user's Pod, and this file belongs to somebody else's.
      // The tokens are the same ones every other cross-Pod call uses.

      final tokens = await getTokensForResource(url, 'PUT');
      final response = await http
          .put(
            Uri.parse(url),
            headers: {
              'Accept': '*/*',
              'Authorization': 'DPoP ${tokens.accessToken}',
              'Content-Type': 'application/json',
              'DPoP': tokens.dPopToken,
              'Link': '<http://www.w3.org/ns/ldp#Resource>; rel="type"',
            },
            body: utf8.encode(body),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // The request is in place. Whether the analyser stops is a separate
        // question, and the one worth answering.

        if (await _collected(url)) {
          return const AnalyserCancel(CancelOutcome.stopped);
        }

        return const AnalyserCancel(
          CancelOutcome.notCollected,
          message: 'The request to stop is waiting in the '
              '${Analyser.displayName} Pod, but nothing has collected it. '
              'The ${Analyser.displayName} may not be running.',
        );
      }

      debugPrint('Could not leave a cancellation at $url: '
          'HTTP ${response.statusCode} ${response.body}');

      // 403 is the one worth naming: it means the Analyser Pod was not set up
      // by solidpod, or its shared folder has been locked down since, and no
      // amount of retrying will change that.

      if (response.statusCode == 403 || response.statusCode == 401) {
        return const AnalyserCancel(
          CancelOutcome.undelivered,
          message: 'The ${Analyser.displayName} Pod would not accept the '
              'request to stop, so the analysis was only stopped in this app.',
        );
      }

      return AnalyserCancel(
        CancelOutcome.undelivered,
        message: 'Could not ask the ${Analyser.displayName} to stop '
            '(${response.statusCode}), so the analysis was only stopped in '
            'this app.',
      );
    } catch (e) {
      debugPrint('Could not leave a cancellation at $url: $e');

      return const AnalyserCancel(
        CancelOutcome.undelivered,
        message: 'Could not reach the ${Analyser.displayName} to stop it, so '
            'the analysis was only stopped in this app.',
      );
    }
  }

  /// Watches until the analyser takes the request away, or time runs out.
  ///
  /// Returns whether it was collected. Waiting a beat before the first look
  /// costs nothing: the analyser cannot have collected a request in less time
  /// than it takes to write it.

  static Future<bool> _collected(String url) async {
    final deadline = DateTime.now().add(confirmTimeout);

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(confirmInterval);
      if (await _isGone(url) ?? false) return true;
    }

    return false;
  }

  /// Whether the request has been taken away, or null when that cannot be
  /// told — a network blip, or an answer that is neither 'there' nor 'gone'.
  ///
  /// Not knowing is treated as still waiting by the caller, so a run of bad
  /// answers ends in an honest failure rather than a false success.

  static Future<bool?> _isGone(String url) async {
    try {
      final tokens = await getTokensForResource(url, 'GET');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'DPoP ${tokens.accessToken}',
          'DPoP': tokens.dPopToken,
        },
      ).timeout(timeout);

      if (response.statusCode == 404) return true;
      if (response.statusCode >= 200 && response.statusCode < 300) return false;

      return null;
    } catch (e) {
      debugPrint('Could not check the cancellation at $url: $e');

      return null;
    }
  }
}
