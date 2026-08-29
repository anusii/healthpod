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
import 'package:healthpod/features/bp/analyser/result_dialog.dart';
import 'package:healthpod/features/bp/analyser/result_service.dart';
import 'package:healthpod/features/bp/analyser/saved_analysis_dialog.dart';
import 'package:healthpod/features/bp/analyser/saved_analysis_service.dart';
import 'package:healthpod/features/bp/analyser/share_service.dart';
import 'package:healthpod/features/charts/widgets/bp_analyse_dialog.dart';

/// What the analysis is doing at the moment, which decides what the button
/// shows and what it says.

enum _Phase {
  /// Nothing in progress; the button is live.

  idle,

  /// Granting the Analyser access to each reading, one at a time.

  sharing,

  /// Waiting for the Analyser to return the result it has computed.

  analysing,

  /// Revoking the Analyser's access to each reading, one at a time.

  revoking,
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

class BPAnalyseButton extends StatefulWidget {
  const BPAnalyseButton({super.key});

  @override
  State<BPAnalyseButton> createState() => _BPAnalyseButtonState();
}

class _BPAnalyseButtonState extends State<BPAnalyseButton> {
  _Phase _phase = _Phase.idle;
  int _completed = 0;
  int _total = 0;

  bool get _busy => _phase != _Phase.idle;

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

  String get _busyTooltip => switch (_phase) {
        _Phase.sharing => '''

      **Sharing your observations**

      $_completed of $_total sent to the ${Analyser.displayName}.

    ''',
        _Phase.revoking => '''

      **Revoking access**

      $_completed of $_total observations checked.

    ''',
        _ => '''

      **Analysing**

      Waiting for the ${Analyser.displayName} to return your chart. This
      usually takes under a minute.

    ''',
      };

  /// The button in its resting state.

  Widget _button(ThemeData theme) => IconButton(
        icon: Icon(Icons.analytics_outlined, color: theme.colorScheme.primary),
        onPressed: _runAnalysis,
      );

  /// The disabled button while the analysis runs. Sharing has a known number
  /// of steps and so shows real progress; the wait that follows does not.

  Widget _progress(ThemeData theme) => IconButton(
        onPressed: null,
        icon: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: _phase != _Phase.analysing && _total > 0
                ? _completed / _total
                : null,
            color: theme.disabledColor,
          ),
        ),
      );

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

    // From here the button stays disabled until the chart is on screen.

    setState(() {
      _phase = _Phase.sharing;
      _completed = 0;
      _total = files.length;
    });

    // Note what the analyser has already published for this Pod, so the
    // result of this run can be told apart from it without relying on the
    // two machines' clocks agreeing.

    final previous = await BPAnalyserResultService.lastResultTime(webId);
    if (!mounted) return;

    final shared = await BPAnalyserShareService.shareAll(
      context,
      onProgress: (completed, total) {
        if (!mounted) return;
        setState(() {
          _completed = completed;
          _total = total;
        });
      },
    );

    if (!mounted) return;

    if (shared.failure != null || shared.shared == 0) {
      setState(() => _phase = _Phase.idle);
      _report(
        shared.message ?? 'None of the observations could be shared.',
        isError: true,
      );

      return;
    }

    if (shared.isPartial) {
      _report(
        'Shared ${shared.shared} of ${shared.total} observations; the '
        'analysis covers the ones that were shared.',
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
    );

    if (!mounted) return;

    final result = outcome.result;
    if (result == null) {
      setState(() => _phase = _Phase.idle);
      _report(_waitFailureMessage(outcome, shared.shared), isError: true);

      return;
    }

    // Keep it in the Pod, then hand the chart to the user. Saving is a
    // convenience: a failure there must not hide the result.

    final document = outcome.document;
    final savedAt = document == null
        ? null
        : await BPAnalysisStore.save(document, result.generatedAt);
    if (!mounted) return;

    setState(() => _phase = _Phase.idle);

    await showAnalyserResultDialog(
      context,
      result: result,
      savedAt: savedAt,
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
          'covered $covered of your $shared observations — it was already '
          'running when you shared. Analyse again in a moment to include them '
          'all.';
    }

    return 'Your observations were shared, but the ${Analyser.displayName} '
        'has not sent a result back yet. Please try again in a moment.';
  }

  /// Revokes the Analyser's access to every reading and says what happened.

  Future<void> _runRevoke() async {
    setState(() {
      _phase = _Phase.revoking;
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

    setState(() => _phase = _Phase.idle);

    if (result.failure != null) {
      _report(
        result.message ?? 'Access could not be revoked.',
        isError: true,
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
      isError: true,
    );
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
