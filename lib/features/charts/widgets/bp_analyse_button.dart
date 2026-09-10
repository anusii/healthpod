/// Chart action that runs an analysis of the blood pressure readings.
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

import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:solidpod/solidpod.dart' show getWebId;

import 'package:healthpod/constants/analyser.dart';
import 'package:healthpod/features/bp/analyser/analyser_client.dart';
import 'package:healthpod/features/bp/analyser/result_dialog.dart';
import 'package:healthpod/features/bp/analyser/result_service.dart';
import 'package:healthpod/features/bp/analyser/saved_analysis_dialog.dart';
import 'package:healthpod/features/bp/analyser/saved_analysis_service.dart';
import 'package:healthpod/features/bp/analyser/share_service.dart';
import 'package:healthpod/features/charts/widgets/bp_analyse_dialog.dart';
import 'package:healthpod/features/charts/widgets/bp_analyse_messages.dart';

/// What a progress ring should show, or null for one that simply turns.
///
/// Sharing and revoking both know how many observations there are and so can
/// report real progress, but only once one has actually been dealt with: a
/// determinate ring at zero draws no arc at all, which made the button look
/// as though it had vanished for the first moments of every run. Until there
/// is something to report the ring turns instead.
///
/// [stepped] is whether the work in hand counts its steps. Waiting for the
/// analyser does not, and neither does waiting for it to stop.

@visibleForTesting
double? analyseRingValue({
  required bool stepped,
  required int completed,
  required int total,
}) =>
    stepped && completed > 0 && total > 0 ? completed / total : null;

/// Runs an analysis of the user's blood pressure and shows the result.
///
/// One press covers the whole round trip: share the readings with the
/// Analyser Pod, wait for it to compute this user's averages and the averages
/// across everybody who has contributed, then show the chart it draws.
///
/// The button is disabled for the whole of that round trip, so a second press
/// cannot start a competing run, and comes back to life when the chart
/// appears.
///
/// The round trip can be abandoned. While it runs the button is a progress
/// ring; pointing at the ring turns it into a cancel button, which stops the
/// app waiting and asks the Analyser to abandon the run at its end. Readings
/// already shared stay shared — withdrawing them is a separate decision, made
/// in the file browser.

class BPAnalyseButton extends StatefulWidget {
  const BPAnalyseButton({super.key});

  @override
  State<BPAnalyseButton> createState() => _BPAnalyseButtonState();
}

class _BPAnalyseButtonState extends State<BPAnalyseButton> {
  AnalysePhase _phase = AnalysePhase.idle;
  int _completed = 0;
  int _total = 0;

  /// Set the moment the user asks to stop. The steps of the round trip check
  /// it and return quietly rather than carrying on with work nobody wants.

  bool _cancelRequested = false;

  /// Whether the pointer is over the control, which is what turns the
  /// progress ring into a cancel button.
  ///
  /// Written only by the MouseRegion in [build], which outlives every phase
  /// change, so it stays in step with where the pointer actually is.

  bool _hovering = false;

  /// The request to the Analyser, while it is in flight.
  ///
  /// The round trip awaits it on its way out, so the button comes back to
  /// life once both halves have finished rather than as soon as the quicker
  /// of them does. Coming back early would let a second run start while the
  /// first was still inside a slow grant, and the two would then compete.

  Future<AnalyserCancel>? _cancelInFlight;

  bool get _busy => _phase != AnalysePhase.idle;

  /// Whether the user can still stop what is happening. Once the request has
  /// gone to the Analyser there is nothing further to ask for.

  bool get _cancellable =>
      _phase == AnalysePhase.sharing || _phase == AnalysePhase.analysing;

  /// The connection to the Analyser, open for the length of one round trip.
  ///
  /// Held here rather than inside the round trip because cancelling comes
  /// from a separate gesture and needs the same connection: it sends a second
  /// call on it while the first is still in flight.

  BPAnalyserClient? _client;

  /// The Pod running the analysis, for as long as one is running.
  ///
  /// A cancellation names the Pod whose analysis to stop, and it comes from a
  /// gesture rather than from inside the round trip, so it cannot go and look
  /// this up: the answer has to be waiting for it.

  String? _webId;

  /// Whether the user has asked for the round trip to stop.

  bool get _stopped => _cancelRequested;

  /// Whether the round trip should give up here, tidying up if it should.
  ///
  /// Called after every step. Nothing between one of these and the step
  /// before it can be interrupted: Dart hands control back only at an await,
  /// so the answer holds for the rest of the step.
  ///
  /// True for a widget that has gone away as well, which is why callers read
  /// `if (await _abandoned() || !mounted) return;` — the second half is for
  /// `use_build_context_synchronously`, which cannot see the check through a
  /// call, rather than for a case this misses.

  Future<bool> _abandoned() async {
    if (!mounted) return true;
    if (!_stopped) return false;
    await _finishCancelled();

    return true;
  }

  /// Returns the button to its resting state once the cancellation is done,
  /// and says what became of it.

  Future<void> _finishCancelled() async {
    // Null only if the round trip decided to stop without anybody pressing
    // cancel, which nothing currently does. There is then no request to
    // report on, and inventing an outcome would mean claiming something
    // about a server that was never asked anything.

    final outcome = await _cancelInFlight;
    if (!mounted) return;

    // `_hovering` is left alone: the MouseRegion owns it, and the pointer may
    // well still be sitting on the button. Clearing it here would leave the
    // two disagreeing until the pointer wandered off and came back.

    setState(() {
      _phase = AnalysePhase.idle;
      _cancelRequested = false;
      _completed = 0;
      _total = 0;
      _cancelInFlight = null;
    });

    if (outcome == null) {
      _report('Analysis cancelled.');

      return;
    }

    if (outcome.stopped) {
      _report(
        'The ${Analyser.displayName} has stopped the analysis.',
        tone: AnalyseTone.success,
      );

      return;
    }

    // The app stopped waiting either way, so the user is not stuck. What
    // failed is the half they cannot see, and saying so plainly is the point
    // of colouring this: the analysis may still be running on the server.

    _report(
      outcome.message ??
          'Could not confirm that the ${Analyser.displayName} stopped.',
      tone: AnalyseTone.failure,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),

      // Above the tooltip rather than inside it. Flutter's Tooltip wraps its
      // child in a RawTooltip only while the tooltip is showing, so the whole
      // subtree below it is thrown away and rebuilt each time one appears or
      // fades. A MouseRegion down there is a fresh render object every time,
      // and a pointer that has not moved since sends it no enter event — so
      // the cross showed up only when something else generated a pointer
      // event, such as pressing the button. Up here the region is built once
      // and keeps its hover state.

      child: MouseRegion(
        onEnter: (_) => _setHovering(true),
        onExit: (_) => _setHovering(false),
        child: MarkdownTooltip(
          message: _busy
              ? analyseBusyTooltip(
                  phase: _phase,
                  completed: _completed,
                  total: _total,
                  cancellable: _cancellable,
                )
              : analyseIdleTooltip,
          child: _busy ? _progress(theme) : _button(theme),
        ),
      ),
    );
  }

  /// Records whether the pointer is over the control, rebuilding only on a
  /// change: enter and exit can both arrive repeatedly as the tooltip comes
  /// and goes underneath.

  void _setHovering(bool hovering) {
    if (_hovering == hovering) return;
    setState(() => _hovering = hovering);
  }

  /// The button in its resting state.

  Widget _button(ThemeData theme) => IconButton(
        icon: Icon(Icons.analytics_outlined, color: theme.colorScheme.primary),
        onPressed: _runAnalysis,
      );

  /// The progress ring shown while the button is busy, which doubles as the
  /// cancel button.
  ///
  /// Sharing and revoking both work through a known number of observations
  /// and so show real progress; the wait for the analyser does not. Pointing
  /// at the ring puts a cross inside it and colours it as an action, which is
  /// the only change: the ring stays, so what is being cancelled remains
  /// visible while the pointer is over it.
  ///
  /// The ring is pressable whether or not it is hovered, because a touch
  /// screen never reports a hover. Cancelling loses nothing that cannot be
  /// had again by analysing a second time, so an accidental press is a
  /// nuisance rather than a loss. Revoking is not an analysis and cannot be
  /// called off, so the ring is inert for the whole of it.

  Widget _progress(ThemeData theme) {
    final active = _cancellable && _hovering;
    final colour = active ? theme.colorScheme.error : theme.disabledColor;

    final value = analyseRingValue(
      stepped:
          _phase == AnalysePhase.sharing || _phase == AnalysePhase.revoking,
      completed: _completed,
      total: _total,
    );

    return IconButton(
      onPressed: _cancellable ? _requestCancel : null,
      icon: SizedBox(
        width: 20,
        height: 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              value: value,
              color: colour,

              // The track keeps the control a complete circle whatever the
              // arc is doing, so there is always something to aim at.

              backgroundColor: colour.withValues(alpha: 0.25),
            ),
            if (active) Icon(Icons.close, size: 12, color: colour),
          ],
        ),
      ),
    );
  }

  /// Stops waiting, and asks the Analyser to stop working.
  ///
  /// Three things happen, and they are separate on purpose:
  ///
  ///   * `_cancelRequested` stops the round trip at its next step, which is
  ///     what frees the app during the sharing;
  ///
  ///   * `abandon()` drops the analysis call, which is what frees it during
  ///     the analysis — a call that would otherwise sit there until the
  ///     Analyser finished the work nobody now wants;
  ///
  ///   * `cancel()` tells the Analyser to stop, which is the half the user is
  ///     actually asking about. It is a fresh call on the same connection,
  ///     answered out of the Analyser's memory, so it comes back in
  ///     milliseconds whether or not there was anything to stop.
  ///
  /// Only the asking happens here. The round trip is the one that knows when
  /// it has actually stopped, so it awaits the reply and puts the button back
  /// — see [_finishCancelled].

  void _requestCancel() {
    if (!_cancellable) return;

    final client = _client;
    final webId = _webId;

    setState(() {
      _cancelRequested = true;
      _phase = AnalysePhase.cancelling;
      _cancelInFlight =
          client == null || webId == null ? null : client.cancel(webId: webId);
    });

    // After the request rather than before it: dropping the analysis call
    // first would let the round trip run on and close the connection this
    // needs. Nothing is awaited between the two, so the order is the whole of
    // the guarantee.

    client?.abandon();
  }

  /// The whole round trip: confirm, check, share, analyse, show.

  Future<void> _runAnalysis() async {
    if (_busy) return;

    final webId = await getWebId();
    if (!mounted) return;

    if (webId == null || webId.isEmpty) {
      _report(
        'Please log in to your Pod before running an analysis.',
        tone: AnalyseTone.failure,
      );

      return;
    }

    final List<String> files;
    try {
      files = await BPAnalyserShareService.listShareableFiles();
    } catch (e) {
      if (!mounted) return;
      _report(
        'Could not read your blood pressure folder: $e',
        tone: AnalyseTone.failure,
      );

      return;
    }

    if (!mounted) return;

    if (files.isEmpty) {
      _report('There are no blood pressure observations to analyse yet.');

      return;
    }

    // Both reads start before the dialogue opens, so neither holds it up:
    // one decides whether Revoke Permissions is live, the other whether
    // Past Analyses is, and the listing it reads is the one shown.

    final anyShared = BPAnalyserShareService.isAnyShared(files);
    final saved = BPAnalysisStore.list();

    final choice = await showAnalyseDialog(
      context,
      observationCount: files.length,
      anyShared: anyShared,
      saved: saved,
    );

    if (!mounted || choice == AnalyseChoice.cancel) return;

    if (choice == AnalyseChoice.revoke) {
      await _runRevoke();

      return;
    }

    if (choice == AnalyseChoice.showSaved) {
      final analyses = await saved;
      if (!mounted) return;

      await showSavedAnalysesDialog(context, analyses: analyses);

      return;
    }

    // From here the button is a progress ring until the chart is on screen,
    // or until the user points at the ring and cancels.

    final client = BPAnalyserClient.connect();

    setState(() {
      _phase = AnalysePhase.checking;
      _cancelRequested = false;
      _completed = 0;
      _total = files.length;
      _client = client;
      _webId = webId;
    });

    try {
      await _analyse(webId: webId, client: client, observations: files.length);
    } finally {
      // The connection outlives nothing: closing it here covers the ordinary
      // path, every early return above it, and a cancellation, which awaits
      // its own reply on the way through `_finishCancelled` before arriving.

      await client.close();
      if (mounted) {
        setState(() {
          _client = null;
          _webId = null;
        });
      }
    }
  }

  /// Check, share, analyse, show — the part that has the Analyser in hand.
  ///
  /// Split from [_runAnalysis] so that the connection is opened and closed in
  /// one place, around everything that could use it, however this returns.

  Future<void> _analyse({
    required String webId,
    required BPAnalyserClient client,
    required int observations,
  }) async {
    // Before anything is shared, because sharing is the expensive and
    // irreversible half of the round trip. This costs a few milliseconds when
    // the Analyser is up, and saves granting a dozen permissions for an
    // analysis that was never going to happen when it is not.

    final status = await client.status();
    if (await _abandoned() || !mounted) return;

    if (!status.available) {
      setState(() => _phase = AnalysePhase.idle);
      _report(
        status.message ??
            'The ${Analyser.displayName} is not ready, so no analysis was '
                'started. Please try again in a moment.',
        tone: AnalyseTone.failure,
      );

      return;
    }

    // Pointed at one Analyser and sharing with another is a
    // misconfiguration that would otherwise show up as an analysis that
    // never finds any data, which is a much harder thing to read.

    if (status.analyserWebId.isNotEmpty &&
        status.analyserWebId != Analyser.webId) {
      setState(() => _phase = AnalysePhase.idle);
      _report(
        'This app shares with ${Analyser.webId}, but the service it called '
        'acts for ${status.analyserWebId}.',
        tone: AnalyseTone.failure,
      );

      return;
    }

    setState(() {
      _phase = AnalysePhase.sharing;
      _total = observations;
    });

    final shared = await BPAnalyserShareService.shareAll(
      context,
      isCancelled: () => _cancelRequested,
      onProgress: (completed, total) {
        if (!mounted) return;
        setState(() {
          _completed = completed;
          _total = total;
        });
      },
    );

    if (await _abandoned() || !mounted) return;

    if (shared.failure != null || shared.shared == 0) {
      setState(() => _phase = AnalysePhase.idle);
      _report(
        shared.message ?? 'None of the observations could be shared.',
        tone: AnalyseTone.failure,
      );

      return;
    }

    if (shared.isPartial) {
      _report(
        'Shared ${shared.shared} of ${shared.total} observations; the '
        'analysis covers the ones that were shared.',
      );
    }

    setState(() => _phase = AnalysePhase.analysing);

    // One call, and it answers when the analysis is done. Telling the
    // Analyser how many readings went out lets it say how many it had in
    // view, which is what [_analysisFailureMessage] reports on when the two
    // do not agree.

    final run = await client.analyse(
      webId: webId,
      sharedFileCount: shared.shared,
    );

    if (await _abandoned() || !mounted) return;

    if (!run.succeeded) {
      setState(() => _phase = AnalysePhase.idle);
      _report(
        analysisFailureMessage(run, shared.shared),
        tone: AnalyseTone.failure,
      );

      return;
    }

    // The Analyser has published the result and said when it made it, so this
    // is one read of a known address rather than a search for something new.

    final fetch = await BPAnalyserResultService.readResult(
      webId: webId,
      expected: run.generatedAt,
      isCancelled: () => _cancelRequested,
    );

    if (await _abandoned() || !mounted) return;

    final result = fetch.result;
    if (result == null) {
      setState(() => _phase = AnalysePhase.idle);
      _report(fetchFailureMessage(fetch), tone: AnalyseTone.failure);

      return;
    }

    if (run.sourcesSeen < shared.shared) {
      // The analysis is this run's — the timestamp matched — but it was
      // reading while the last grants were still landing. Shown alongside the
      // result rather than instead of it: the figures are sound as far as they
      // go, and the user can bring the rest in by analysing again.

      _report(
        'That analysis covered ${run.sourcesSeen} of your ${shared.shared} '
        'observations. Analyse again in a moment to include them all.',
      );
    }

    // Keep it in the Pod, then hand the chart to the user. Saving is a
    // convenience: a failure there must not hide the result.

    final document = fetch.document;
    final savedAt = document == null
        ? null
        : await BPAnalysisStore.save(document, result.generatedAt);
    if (await _abandoned() || !mounted) return;

    setState(() => _phase = AnalysePhase.idle);

    await showAnalyserResultDialog(
      context,
      result: result,
      savedAt: savedAt,
    );
  }

  /// Revokes the Analyser's access to every reading and says what happened.

  Future<void> _runRevoke() async {
    setState(() {
      _phase = AnalysePhase.revoking;
      _completed = 0;
      _total = 0;
    });

    final result = await BPAnalyserShareService.revokeAll(
      onProgress: (examined, total) {
        if (!mounted) return;
        setState(() {
          _completed = examined;
          _total = total;
        });
      },
    );

    if (!mounted) return;

    setState(() => _phase = AnalysePhase.idle);

    if (result.failure != null) {
      _report(
        result.message ?? 'Access could not be revoked.',
        tone: AnalyseTone.failure,
      );

      return;
    }

    if (result.hadNothingShared) {
      _report(
        'The ${Analyser.displayName} does not have access to any of your '
        'blood pressure observations.',
      );

      return;
    }

    if (result.isCompleteSuccess) {
      _report(
        'Revoked ${Analyser.displayName} access to ${result.revoked} '
        'observation${result.revoked == 1 ? '' : 's'}.',
      );

      return;
    }

    _report(
      'Revoked access to ${result.revoked} of ${result.shared} '
      'observations; the rest could not be changed. Please try again in a '
      'moment.',
      tone: AnalyseTone.failure,
    );
  }

  /// Shows a message about the analysis. See [reportAnalyseMessage], which
  /// is where the wording of every one of them lives as well.

  void _report(String message, {AnalyseTone tone = AnalyseTone.plain}) =>
      reportAnalyseMessage(context, message, tone: tone);
}
