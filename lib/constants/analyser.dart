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

  /// Folder inside the Analyser Pod that any app can write to.
  ///
  /// A Pod laid out by solidpod grants public read and write on `<app>/shared/`
  /// so that other agents can deliver sealed keys into it without being
  /// granted anything first. That makes it the one place this app can leave a
  /// message for the analyser, which is how an analysis is cancelled: the
  /// analyser's own HTTP interface binds to the server's loopback address, so
  /// there is no route to it from here.

  static const String sharedPathFragment = '/healthpod/shared/';

  /// The Analyser Pod root, without a trailing slash.

  static String get podRoot => webId.replaceAll('/profile/card#me', '');

  /// Where the Pod identified by [slug] leaves a request to stop.
  ///
  /// One file per requester, so two people cancelling at once do not overwrite
  /// each other. [slug] is the WebID reduced to a file-safe label, the same
  /// form solidpod uses.

  static String cancelUrl(String slug) =>
      '$podRoot${sharedPathFragment}cancel-$slug.json';

  /// Width of the Analyser's text dialogues.
  ///
  /// A dialogue left to size itself stretches to the window, and prose that
  /// runs the full width of a desktop window is tiring to read. This holds a
  /// line to roughly 80 characters at the body text size.

  static const double dialogWidth = 560;
}
