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
import 'package:healthpod/features/bp/analyser/cancel_service.dart';
import 'package:healthpod/features/bp/analyser/result_dialog.dart';
import 'package:healthpod/features/bp/analyser/result_service.dart';
import 'package:healthpod/features/bp/analyser/share_service.dart';

/// What the analysis is doing at the moment, which decides what the button
/// shows and what it says.

enum _Phase {
  /// Nothing in progress; the button is live.

  idle,

  /// Granting the Analyser access to each reading, one at a time.

  sharing,

  /// Waiting for the Analyser to return the result it has computed.

  analysing,

  /// The user has asked to stop, and the Analyser is being told so.

  cancelling,
}

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
  _Phase _phase = _Phase.idle;
  int _completed = 0;
  int _total = 0;

  /// Set the moment the user asks to stop. The steps of the round trip check
  /// it and return quietly rather than carrying on with work nobody wants.

  bool _cancelRequested = false;

  /// Whether the pointer is over the progress ring, which is what turns it
  /// into a cancel button.

  bool _hovering = false;

  /// The request to the Analyser, while it is in flight.
  ///
  /// The round trip awaits it on its way out, so the button comes back to
  /// life once both halves have finished rather than as soon as the quicker
  /// of them does. Coming back early would let a second run start while the
  /// first was still inside a slow grant, and the two would then compete.

  Future<AnalyserCancel>? _cancelInFlight;

  bool get _busy => _phase != _Phase.idle;

  /// Whether the user can still stop what is happening. Once the request has
  /// gone to the Analyser there is nothing further to ask for.

  bool get _cancellable =>
      _phase == _Phase.sharing || _phase == _Phase.analysing;

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
    final outcome = await (_cancelInFlight ??
        Future.value(const AnalyserCancel(CancelOutcome.accepted)));
    if (!mounted) return;

    setState(() {
      _phase = _Phase.idle;
      _cancelRequested = false;
      _hovering = false;
      _completed = 0;
      _total = 0;
      _cancelInFlight = null;
    });

    if (outcome.delivered) {
      _report(
        outcome.wasRunning
            ? 'The ${Analyser.displayName} has been asked to stop the '
                'analysis it was running.'
            : 'Analysis cancelled.',
      );

      return;
    }

    // Not being able to reach the Analyser is not an error the user caused,
    // and the thing they asked for — an end to the waiting — has happened.
    // Say what did not, without dressing it as a failure.

    _report(outcome.message ?? 'Analysis cancelled.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: MarkdownTooltip(
        message: _busy ? _busyTooltip : _idleTooltip,
        child: _busy ? _progress(theme) : _button(theme),
      ),
    );
  }

  String get _idleTooltip => '''

      **Analyse**

      Send your blood pressure readings to the ${Analyser.displayName} Pod and
      get back a chart of your readings marked with your own averages and the
      averages across everyone who has contributed.

      * The ${Analyser.displayName} is granted **read** access only, one
        reading at a time, and never gains access to anything else in your Pod.

      * Readings you record afterwards are **not** included automatically —
        analyse again to bring them in.

      * You can withdraw access at any time from the file browser.

    ''';

  String get _busyTooltip {
    if (_phase == _Phase.cancelling) {
      return '''

      **Stopping**

      Asking the ${Analyser.displayName} to abandon the analysis.

    ''';
    }

    final work = _phase == _Phase.sharing
        ? '''

      **Sharing your readings**

      $_completed of $_total sent to the ${Analyser.displayName}.

    '''
        : '''

      **Analysing**

      Waiting for the ${Analyser.displayName} to return your chart. This
      usually takes under a minute.

    ''';

    return '''$work
      Press to **cancel**. The ${Analyser.displayName} is asked to stop, and
      readings already shared stay shared — withdraw them from the file
      browser if you would rather they did not.

    ''';
  }

  /// The button in its resting state.

  Widget _button(ThemeData theme) => IconButton(
        icon: Icon(Icons.analytics_outlined, color: theme.colorScheme.primary),
        onPressed: _runAnalysis,
      );

  /// The progress ring shown while the analysis runs, which doubles as the
  /// cancel button.
  ///
  /// Sharing has a known number of steps and so shows real progress; the wait
  /// that follows does not. Pointing at the ring puts a cross inside it and
  /// colours it as an action, which is the only change: the ring stays, so
  /// what is being cancelled remains visible while the pointer is over it.
  ///
  /// The ring is pressable whether or not it is hovered, because a touch
  /// screen never reports a hover. Cancelling loses nothing that cannot be
  /// had again by analysing a second time, so an accidental press is a
  /// nuisance rather than a loss.

  Widget _progress(ThemeData theme) {
    final active = _cancellable && _hovering;
    final colour = active ? theme.colorScheme.error : theme.disabledColor;

    return MouseRegion(
      cursor: _cancellable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: IconButton(
        onPressed: _cancellable ? _requestCancel : null,
        icon: SizedBox(
          width: 20,
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                value: _phase == _Phase.sharing && _total > 0
                    ? _completed / _total
                    : null,
                color: colour,
              ),
              if (active) Icon(Icons.close, size: 12, color: colour),
            ],
          ),
        ),
      ),
    );
  }

  /// Stops waiting, and asks the Analyser to stop working.
  ///
  /// The two are separate: the app gives up at its next step, while the
  /// Analyser is told over its own interface and acts on it at the next point
  /// in its cycle where stopping is safe. The Analyser may also not be
  /// reachable at all, which leaves it to finish a run whose result nobody is
  /// now waiting for.
  ///
  /// Only the asking happens here. The round trip is the one that knows when
  /// it has actually stopped, so it awaits this and puts the button back —
  /// see [_finishCancelled].

  void _requestCancel() {
    if (!_cancellable) return;

    setState(() {
      _cancelRequested = true;
      _phase = _Phase.cancelling;
      _cancelInFlight = BPAnalyserCancelService.cancel();
    });
  }

  /// The whole round trip: confirm, share, wait, show.

  Future<void> _runAnalysis() async {
    if (_busy) return;

    final webId = await getWebId();
    if (!mounted) return;

    if (webId == null || webId.isEmpty) {
      _report(
        'Please log in to your Pod before running an analysis.',
        isError: true,
      );

      return;
    }

    final List<String> files;
    try {
      files = await BPAnalyserShareService.listShareableFiles();
    } catch (e) {
      if (!mounted) return;
      _report('Could not read your blood pressure folder: $e', isError: true);

      return;
    }

    if (!mounted) return;

    if (files.isEmpty) {
      _report('There are no blood pressure readings to analyse yet.');

      return;
    }

    if (!await _confirm(files.length) || !mounted) return;

    // From here the button is a progress ring until the chart is on screen,
    // or until the user points at the ring and cancels.

    setState(() {
      _phase = _Phase.sharing;
      _cancelRequested = false;
      _completed = 0;
      _total = files.length;
    });

    // Note what the analyser has already published for this Pod, so the
    // result of this run can be told apart from it without relying on the
    // two machines' clocks agreeing.

    final previous = await BPAnalyserResultService.lastResultTime(webId);
    if (await _abandoned() || !mounted) return;

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
      setState(() => _phase = _Phase.idle);
      _report(
        shared.message ?? 'None of the readings could be shared.',
        isError: true,
      );

      return;
    }

    if (shared.isPartial) {
      _report(
        'Shared ${shared.shared} of ${shared.total} readings; the analysis '
        'covers the ones that were shared.',
      );
    }

    setState(() => _phase = _Phase.analysing);

    final outcome = await BPAnalyserResultService.waitForResult(
      webId: webId,
      previous: previous,
      // Only accept a result that had every shared reading in view. Another
      // Pod's share can set a run going that finishes before these readings
      // are all granted, and that result would be new but incomplete.
      minimumSources: shared.shared,
      isCancelled: () => _cancelRequested,
    );

    if (await _abandoned() || !mounted) return;

    final result = outcome.result;
    if (result == null) {
      setState(() => _phase = _Phase.idle);
      _report(_waitFailureMessage(outcome, shared.shared), isError: true);

      return;
    }

    // Keep a copy on this device, then hand the chart to the user. Saving is
    // a convenience: a failure there must not hide the result.

    final savedPath = await BPAnalyserResultService.saveChart(result);
    if (await _abandoned() || !mounted) return;

    setState(() => _phase = _Phase.idle);

    await showAnalyserResultDialog(
      context,
      result: result,
      savedPath: savedPath,
    );
  }

  /// Explains why the wait produced nothing, in terms the user can act on.

  String _waitFailureMessage(AnalyserWait outcome, int shared) {
    if (outcome.staleKey) {
      return 'The ${Analyser.displayName} sent a result, but this app is '
          'holding an out-of-date key for it. Restart the app and analyse '
          'again.';
    }

    final covered = outcome.bestCoverage;
    if (covered != null) {
      return 'The ${Analyser.displayName} has answered, but that analysis '
          'covered $covered of your $shared readings — it was already running '
          'when you shared. Analyse again in a moment to include them all.';
    }

    return 'Your readings were shared, but the ${Analyser.displayName} has '
        'not sent a result back yet. Please try again in a moment.';
  }

  /// Asks before any data leaves the Pod.

  Future<bool> _confirm(int readingCount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analyse your blood pressure'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grant ${Analyser.displayName} read access to $readingCount '
              'reading${readingCount == 1 ? '' : 's'} so it can analyse them?',
            ),
            const SizedBox(height: 12),
            const Text(
              'It works out your averages and the averages across everyone '
              'who has contributed, and returns a chart. Nobody else sees '
              'your individual readings.',
            ),
            const SizedBox(height: 12),
            SelectableText(
              Analyser.webId,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Analyse'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  /// Shows a message, in the error colour when something went wrong.

  void _report(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.colorScheme.error : null,
        duration: Duration(seconds: isError ? 8 : 4),
      ),
    );
  }
}
