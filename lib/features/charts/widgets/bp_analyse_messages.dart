/// What the analyse button says, and how it says it.
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

import 'package:flutter/material.dart';

import 'package:healthpod/constants/analyser.dart';
import 'package:healthpod/features/bp/analyser/analyser_client.dart';
import 'package:healthpod/features/bp/analyser/result_service.dart';

// Apart from the button because it is a different kind of reading. What is
// here is prose — the tooltips, and the sentence each way a round trip can
// fail turns into — and it is worth being able to read the wording through in
// one go, and to change it without going anywhere near the state machine that
// decides when it is shown.
//
// The phase comes with it. It is what most of the wording is chosen by, and
// leaving it behind in the button would mean handing this file something it
// could not name.

/// What the analysis is doing at the moment, which decides what the button
/// shows and what it says.

enum AnalysePhase {
  /// Nothing in progress; the button is live.

  idle,

  /// Asking the Analyser whether it is up, before anything is shared.
  ///
  /// Milliseconds on a working deployment, and the reason it happens before
  /// the sharing rather than after: granting a dozen permissions and then
  /// finding nothing is listening is the worst way round to learn it.

  checking,

  /// Granting the Analyser access to each reading, one at a time.

  sharing,

  /// The Analyser is running the analysis, inside the call that started it.

  analysing,

  /// Revoking the Analyser's access to each observation, one at a time.

  revoking,

  /// The user has asked to stop, and the Analyser is being told so.

  cancelling,
}

/// How a message reads: as a plain note, or as an outcome worth colouring.
///
/// Only the two ends of a cancellation are coloured. Everything else the
/// button says is a remark in passing, and a wall of coloured snack bars
/// would leave the two that matter no louder than the rest.

enum AnalyseTone {
  /// An aside. Takes the theme's own snack bar colour.

  plain,

  /// Something the user asked for has happened.

  success,

  /// Something the user asked for has not happened.

  failure,
}

/// What the button offers while nothing is in progress.

String get analyseIdleTooltip => '''

      **Analyse**

      Send your blood pressure observations to the ${Analyser.displayName} Pod
      and get back a chart of your observations marked with your own averages
      and the averages across everyone who has contributed.

      * The ${Analyser.displayName} is granted **read** access only, one
        observation at a time, and never gains access to anything else in your
        Pod.

      * Observations you record afterwards are **not** included automatically —
        analyse again to bring them in.

      * Every analysis is kept in your own Pod. **Past Analyses**, in the
        dialogue this opens, lists them and reopens or deletes any of them.

      * You can revoke access at any time with **Revoke Permissions** in
        the dialogue this opens, or from the file browser.

    ''';

/// What the button says while it is busy.
///
/// The phase describes the work; the note after it is added only while
/// [cancellable], so revoking — which is not an analysis — does not offer to
/// cancel one.
///
/// [completed] and [total] are the observations dealt with and the
/// observations there are, and are read only by the phases that count them.

String analyseBusyTooltip({
  required AnalysePhase phase,
  required int completed,
  required int total,
  required bool cancellable,
}) {
  final work = switch (phase) {
    AnalysePhase.cancelling => '''

      **Stopping**

      Waiting for the ${Analyser.displayName} to confirm it has stopped.

    ''',
    AnalysePhase.checking => '''

      **Checking the ${Analyser.displayName}**

      Making sure it is running before anything is shared with it.

    ''',
    AnalysePhase.sharing => '''

      **Sharing your observations**

      $completed of $total sent to the ${Analyser.displayName}.

    ''',
    AnalysePhase.revoking => '''

      **Revoking access**

      $completed of $total observations checked.

    ''',
    _ => '''

      **Analysing**

      The ${Analyser.displayName} is working, and will answer when it is done.

    ''',
  };

  if (!cancellable) return work;

  return '''$work
      Press to **cancel**. The ${Analyser.displayName} is asked to stop, and
      observations already shared stay shared — revoke them from the dialogue
      or the file browser if you would rather they did not.

    ''';
}

/// Explains an analysis that produced nothing, in terms the user can act on.

String analysisFailureMessage(AnalyserRun run, int shared) {
  if (run.message != null) return run.message!;

  return switch (run.status) {
    AnalyseStatus.ANALYSE_STATUS_NO_DATA =>
      'The ${Analyser.displayName} could not read any of the $shared '
          'observations that were shared with it.',
    AnalyseStatus.ANALYSE_STATUS_CANCELLED => 'The analysis was stopped.',
    _ => 'The ${Analyser.displayName} could not finish the analysis. '
        'Please try again in a moment.',
  };
}

/// Explains a published analysis that could not be read.
///
/// The analysis itself worked — the Analyser said so — so everything here
/// is about the result not arriving in a state this app can open, and each
/// case names something different to do about it.

String fetchFailureMessage(AnalyserFetch fetch) {
  if (fetch.staleKey) {
    return 'The ${Analyser.displayName} published a result, but this app is '
        'holding an out-of-date key for it. Restart the app and analyse '
        'again.';
  }

  return 'The ${Analyser.displayName} finished the analysis, but its result '
      'could not be read from your Pod yet. Please try again in a moment.';
}

/// Shows a message, coloured by what it is reporting.
///
/// A failure stays up twice as long: it usually names something the user
/// has to go and do, and a message that has to be read is worth more time
/// than one that only confirms.

void reportAnalyseMessage(
  BuildContext context,
  String message, {
  AnalyseTone tone = AnalyseTone.plain,
}) {
  final theme = Theme.of(context);
  final failed = tone == AnalyseTone.failure;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: switch (tone) {
        AnalyseTone.success => Colors.green,
        AnalyseTone.failure => theme.colorScheme.error,
        AnalyseTone.plain => null,
      },
      duration: Duration(seconds: failed ? 8 : 4),
    ),
  );
}
