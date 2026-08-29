/// The dialogue asked before blood pressure data leaves the Pod.
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

import 'package:healthpod/constants/analyser.dart';
import 'package:healthpod/features/bp/analyser/model.dart';

/// What the user chose in the confirmation dialogue.

enum AnalyseChoice {
  /// Leave everything as it is.

  cancel,

  /// Share the observations and run the analysis.

  analyse,

  /// Revoke the Analyser's access to every observation, without analysing.

  revoke,

  /// Show the analysis already kept in the Pod, without analysing.

  showLast,
}

/// Asks before any data leaves the Pod, and returns what the user chose.
///
/// [anyShared] and [saved] are started by the caller before the dialogue
/// opens, so neither Pod read holds it up: each one only decides whether its
/// button is live. [saved] is also how the caller shows the analysis without
/// reading it a second time, which is why the dialogue takes the future
/// rather than reading it itself.

Future<AnalyseChoice> showAnalyseDialog(
  BuildContext context, {
  required int observationCount,
  required Future<bool> anyShared,
  required Future<AnalyserResult?> saved,
}) async {
  final choice = await showDialog<AnalyseChoice>(
    context: context,
    builder: (context) => BPAnalyseDialog(
      observationCount: observationCount,
      anyShared: anyShared,
      saved: saved,
    ),
  );

  return choice ?? AnalyseChoice.cancel;
}

/// The dialogue itself, kept separate so it can be shown and tested on its
/// own.
///
/// It is also where access is given back: granting and revoking belong
/// together, so the user never has to hunt through the file browser to undo
/// a share.

class BPAnalyseDialog extends StatelessWidget {
  const BPAnalyseDialog({
    super.key,
    required this.observationCount,
    required this.anyShared,
    required this.saved,
  });

  /// How many observations would be shared.

  final int observationCount;

  /// Whether the Analyser already holds access to any of them.

  final Future<bool> anyShared;

  /// The analysis kept in the Pod, when there is one.

  final Future<AnalyserResult?> saved;

  @override
  Widget build(BuildContext context) {
    final plural = observationCount == 1 ? '' : 's';

    return AlertDialog(
      // Four paragraphs and a WebID do not fit a short window; without this
      // the dialogue overflows rather than scrolling.

      scrollable: true,
      title: const Text('Analyse your blood pressure'),
      content: SizedBox(
        width: Analyser.dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grant access to your $observationCount observation$plural. '
              'These will be shared with the ${Analyser.displayName} pod and '
              'used in aggregate to develop a population average that is '
              'shared with you and other users.',
            ),
            const SizedBox(height: 12),
            const Text(
              'It works out your averages and the averages across everyone '
              'who has contributed, and returns to your Pod a chart. Nobody '
              'else sees your individual observations.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Revoke Permissions takes that access away again: the '
              '${Analyser.displayName} can no longer read any of your '
              'observations, and analysing later will ask you to grant '
              'access afresh. Charts the ${Analyser.displayName} has '
              'already sent you are kept, along with any saved on this '
              'device.',
            ),
            const SizedBox(height: 12),
            SelectableText(
              Analyser.webId,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(AnalyseChoice.cancel),
          child: const Text('Cancel'),
        ),
        _lastAnalysisAction(),
        _revokeAction(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(AnalyseChoice.analyse),
          child: const Text('Analyse'),
        ),
      ],
    );
  }

  /// The analysis already in the Pod, offered once it has been read.

  Widget _lastAnalysisAction() => FutureBuilder<AnalyserResult?>(
        future: saved,
        builder: (context, snapshot) {
          final ready = snapshot.connectionState == ConnectionState.done;
          final hasSaved = snapshot.data != null;

          return MarkdownTooltip(
            message: !ready
                ? _readingSavedTooltip
                : hasSaved
                    ? _lastAnalysisTooltip
                    : _noSavedAnalysisTooltip,
            child: TextButton(
              onPressed: hasSaved
                  ? () => Navigator.of(context).pop(AnalyseChoice.showLast)
                  : null,
              child: const Text('Last Analysis'),
            ),
          );
        },
      );

  /// Revoking asks again on its own, and only closes this dialogue once the
  /// user has said yes to that second question. It is only offered once the
  /// Analyser is known to hold access to revoke.

  Widget _revokeAction() => FutureBuilder<bool>(
        future: anyShared,
        builder: (context, snapshot) {
          final checking = snapshot.connectionState != ConnectionState.done;
          final canRevoke = snapshot.data ?? false;

          return MarkdownTooltip(
            message: checking
                ? _checkingTooltip
                : canRevoke
                    ? _revokeTooltip
                    : _nothingSharedTooltip,
            child: TextButton(
              onPressed: canRevoke
                  ? () async {
                      if (!await _confirmRevoke(context)) return;
                      if (!context.mounted) return;
                      Navigator.of(context).pop(AnalyseChoice.revoke);
                    }
                  : null,
              child: const Text('Revoke Permissions'),
            ),
          );
        },
      );

  /// Asks again before access is taken away, since the next analysis will
  /// have to share everything afresh.

  Future<bool> _confirmRevoke(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Revoke permissions'),
        content: const SizedBox(
          width: Analyser.dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revoke ${Analyser.displayName} access to all of your blood '
                'pressure observations?',
              ),
              SizedBox(height: 12),
              Text(
                'The ${Analyser.displayName} will no longer be able to read '
                'any of them, and analysing again will ask you to grant '
                'access afresh. Charts it has already sent you are kept, '
                'along with any saved on this device.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  String get _lastAnalysisTooltip => '''

      **Last Analysis**

      Show the analysis kept in your Pod, with its chart and figures, as it
      was when the ${Analyser.displayName} returned it. Nothing is shared and
      no new analysis is run.

    ''';

  String get _readingSavedTooltip => '''

      **Last Analysis**

      Reading the analysis kept in your Pod.

    ''';

  String get _noSavedAnalysisTooltip => '''

      **No saved analysis**

      Your Pod does not hold an analysis yet. Run one and it will be kept
      there for next time.

    ''';

  String get _revokeTooltip => '''

      **Revoke Permissions**

      Take the ${Analyser.displayName}'s access back. It will no longer be
      able to read any of your observations, and analysing later will ask you
      to grant access afresh.

    ''';

  String get _checkingTooltip => '''

      **Revoke Permissions**

      Checking whether the ${Analyser.displayName} holds access to any of your
      observations.

    ''';

  String get _nothingSharedTooltip => '''

      **Nothing to revoke**

      The ${Analyser.displayName} does not hold access to any of your
      observations, so there is nothing to take back.

    ''';
}
