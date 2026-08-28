/// Address of the Analyser Pod that health data can be shared with.
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

/// The Analyser Pod: a service Pod that averages the blood pressure data
/// shared with it and shares the results back.
///
/// The analyser itself is a Python service watching this Pod's sharing inbox;
/// see `analyser/bp_analyser/README.md` in this repository. When a user shares
/// readings with the WebID below, the service reads them, computes that user's
/// average and the average across every contributing Pod, and shares both back
/// to the user's own Pod.

class Analyser {
  /// The WebID users share their data with.

  static const String webId =
      'https://solid.dev.empwr.au/Analyser/profile/card#me';

  /// Name shown in the interface, in place of the raw WebID.

  static const String displayName = 'Analyser';

  /// Folder inside the Analyser Pod holding the results it publishes.
  ///
  /// A resource shared back by the analyser has a URL containing this
  /// fragment, which is how results are told apart from anything else that
  /// has been shared with the user.

  static const String resultsPathFragment = '/healthpod/data/analyser/';

  /// File name of the summary the analyser shares with each contributing Pod.

  static const String podAverageFileName = 'bp-average.json.enc.ttl';

  /// File name of the cohort summary shared with every contributing Pod.

  static const String cohortAverageFileName = 'bp-cohort-average.json.enc.ttl';

  /// Where the analyser's control API answers, without a trailing slash.
  ///
  /// The analysis itself travels through the Pod, so the app needs this only
  /// to tell the analyser to stop: there is nothing in the Solid model that
  /// withdraws work already in hand. The service binds to the loopback
  /// address unless it is deliberately moved (`api.host` in its
  /// `config.yaml`), so the default suits an analyser running alongside the
  /// app; a deployment elsewhere overrides it at build time with
  ///
  ///     flutter run --dart-define=HEALTHPOD_ANALYSER_API=https://host:8088
  ///
  /// Setting it to the empty string switches the call off, and cancelling
  /// then only stops this app waiting — see [apiConfigured].

  static const String apiBaseUrl = String.fromEnvironment(
    'HEALTHPOD_ANALYSER_API',
    defaultValue: 'http://localhost:8088',
  );

  /// Token for the analyser's guarded endpoints, when it requires one.
  ///
  /// Matches `api.token` in the analyser's configuration. Empty by default,
  /// which is right for a loopback API; a shared one should be given a token
  /// through `--dart-define=HEALTHPOD_ANALYSER_API_TOKEN=...`.

  static const String apiToken = String.fromEnvironment(
    'HEALTHPOD_ANALYSER_API_TOKEN',
  );

  /// Whether an analyser API address is configured at all.

  static bool get apiConfigured => apiBaseUrl.isNotEmpty;

  /// Endpoint that asks the analyser to abandon the run in progress.

  static String get cancelUrl => '$apiBaseUrl/api/cancel';
}
