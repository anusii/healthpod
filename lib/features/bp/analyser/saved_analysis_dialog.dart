/// Dialog listing the analyses kept in the user's Pod.
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
import 'package:healthpod/features/bp/analyser/result_dialog.dart';
import 'package:healthpod/features/bp/analyser/saved_analysis_service.dart';
import 'package:healthpod/utils/format_moment.dart';

/// Lists the analyses kept in the Pod, newest first.
///
/// [analyses] is the listing the caller already started, so the dialogue
/// opens without waiting on the Pod. It is only the first listing: deleting
/// one reads the folder again.

Future<void> showSavedAnalysesDialog(
  BuildContext context, {
  required List<String> analyses,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => SavedAnalysesDialog(analyses: analyses),
  );
}

/// The dialog itself, kept separate so it can be shown and tested on its own.

class SavedAnalysesDialog extends StatefulWidget {
  const SavedAnalysesDialog({super.key, required this.analyses});

  /// The analysis file names, newest first.

  final List<String> analyses;

  @override
  State<SavedAnalysesDialog> createState() => _SavedAnalysesDialogState();
}

class _SavedAnalysesDialogState extends State<SavedAnalysesDialog> {
  late List<String> _analyses = widget.analyses;

  /// The analysis being read or deleted, so its row can say so and a second
  /// tap cannot start the same work twice.

  String? _busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      scrollable: true,
      title: const Text('Past analyses'),
      content: SizedBox(
        width: Analyser.dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _analyses.isEmpty
                  ? 'Your Pod holds no analyses. Deleted ones are gone for '
                      'good, but analysing again makes a new one.'
                  : 'Every analysis the ${Analyser.displayName} has returned, '
                      'newest first. Open one to see its chart and figures.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            for (final fileName in _analyses) _row(fileName),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// One analysis: when it was made, and a way to be rid of it.

  Widget _row(String fileName) {
    final moment = BPAnalysisStore.timestampOf(fileName);
    final busy = _busy == fileName;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(moment == null ? fileName : formatMoment(moment)),
      onTap: busy ? null : () => _open(fileName),
      trailing: MarkdownTooltip(
        message: _deleteTooltip,
        child: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: busy ? null : () => _delete(fileName),
        ),
      ),
    );
  }

  String get _deleteTooltip => '''

      **Delete**

      Remove this analysis from your Pod. The chart and figures go with it,
      and there is no way back, though analysing again makes a new one.

    ''';

  /// Reads one analysis and shows it, leaving this list underneath so the
  /// next one is a tap away.

  Future<void> _open(String fileName) async {
    setState(() => _busy = fileName);

    final result = await BPAnalysisStore.load(fileName);

    if (!mounted) return;

    setState(() => _busy = null);

    if (result == null) {
      _report('That analysis could not be read from your Pod.');

      return;
    }

    await showAnalyserResultDialog(
      context,
      result: result,
      savedAt: BPAnalysisStore.podPath(fileName),
    );
  }

  /// Asks first, since a deleted analysis cannot be brought back.

  Future<void> _delete(String fileName) async {
    final moment = BPAnalysisStore.timestampOf(fileName);
    final label = moment == null ? fileName : formatMoment(moment);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Delete analysis'),
        content: SizedBox(
          width: Analyser.dialogWidth,
          child: Text(
            'Delete the analysis from $label? Its chart and figures go with '
            'it, and there is no way back. Your observations are untouched, '
            'so analysing again makes a new one.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = fileName);

    final deleted = await BPAnalysisStore.delete(fileName);
    final remaining = deleted ? await BPAnalysisStore.list() : _analyses;

    if (!mounted) return;

    setState(() {
      _busy = null;
      _analyses = remaining;
    });

    if (!deleted) _report('That analysis could not be deleted.');
  }

  /// Says what went wrong, over the top of this dialogue.

  void _report(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
