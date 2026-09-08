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
/// The analyser itself is a Python service beside the Solid server; see
/// `analyser/bp_analyser/README.md` in this repository. Two addresses matter
/// here, and they are separate on purpose:
///
///   * [webId] is the Pod. Readings are shared with it, and the results are
///     published from it. This is the only part of the arrangement the Solid
///     server knows about.
///
///   * [grpcHost] and [grpcPort] are the service. An analysis is asked for
///     over gRPC, which is what makes it start at once instead of at the
///     service's next poll of its own Pod, and what makes cancelling one
///     immediate rather than a message left in a folder.
///
/// So sharing still goes through the Pod — that is how the analyser gets the
/// keys to read anything — and only the asking goes direct.

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

  /// The Analyser Pod root, without a trailing slash.

  static String get podRoot => webId.replaceAll('/profile/card#me', '');

  /// Where the analyser service listens for an app to ask for an analysis.
  ///
  /// The same host as the Solid server in the deployment this is set for,
  /// which is the usual arrangement rather than a requirement: the service
  /// talks to the server over HTTPS like any other client, so it can sit
  /// anywhere the app can reach.

  static const String grpcHost = 'solid.dev.empwr.au';

  /// The port that service listens on. `grpc.port` in its configuration.

  static const int grpcPort = 50051;

  /// Whether that port is served over TLS.
  ///
  /// False for the proof of concept, matching an analyser configured without
  /// `grpc.tls_cert_file`. A WebID is the only thing this app puts on the
  /// wire, and that is enough to want encrypted on anything but a private
  /// network — so a deployment that serves TLS sets this too, and the two must
  /// agree or the channel will not open.

  static const bool grpcSecure = false;

  /// The shared secret the analyser requires, when it requires one.
  ///
  /// Matches `grpc.token` in its configuration; empty means the analyser is
  /// accepting calls from anyone who can reach the port. A secret compiled
  /// into an app is not a secret from whoever holds the app, so this keeps
  /// passers-by out rather than a determined user: it is the port's front
  /// door, not its lock. What it protects is modest — an analysis only ever
  /// publishes to the Pod that shared the data, so the worst a stranger gets
  /// is the analyser doing work nobody wanted.

  static const String grpcToken = 'hunter2';

  /// Width of the Analyser's text dialogues.
  ///
  /// A dialogue left to size itself stretches to the window, and prose that
  /// runs the full width of a desktop window is tiring to read. This holds a
  /// line to roughly 80 characters at the body text size.

  static const double dialogWidth = 560;
}
