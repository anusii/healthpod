/// The recorded history of the health profile measurements.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/dialogs/confirm_delete.dart';
import 'package:healthpod/features/health_profile/model.dart';
import 'package:healthpod/features/health_profile/service.dart';
import 'package:healthpod/features/health_profile/widgets/history_table.dart';
import 'package:healthpod/utils/show_delete_result.dart';

/// Every set of measurements recorded, most recent first.
///
/// New measurements are entered from the **Add** tab. Here they can be
/// reviewed and a mistaken entry removed.

class HealthProfileHistoryPage extends StatefulWidget {
  const HealthProfileHistoryPage({super.key});

  @override
  State<HealthProfileHistoryPage> createState() =>
      _HealthProfileHistoryPageState();
}

class _HealthProfileHistoryPageState extends State<HealthProfileHistoryPage> {
  List<HealthProfileEntry> _entries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries = await HealthProfileService.fetchAll();
      if (!mounted) return;

      setState(() {
        // Most recent first, which is the order these are reviewed in.

        _entries = entries.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  /// Confirms and then removes one record from the pod.

  Future<void> _delete(HealthProfileEntry entry) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete measurements',
      message: 'Remove this record from your pod? The measurements it holds '
          'cannot be recovered.',
    );

    if (!confirmed || !mounted) return;

    try {
      final deleted = await HealthProfileService.delete(entry);

      if (!mounted) return;

      if (deleted) {
        showDeleteSuccess(context, 'Measurements deleted successfully.');
      } else {
        showDeleteFailure(
          context,
          'The record could not be found on your pod.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      showDeleteFailure(context, 'Error deleting measurements: $e');
    } finally {
      // Always reload so that the table reflects what is now on the pod.

      if (mounted) await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const MarkdownTooltip(
          message: '''

            **Health Profile history:** Every set of measurements you have
            recorded, most recent first.

            Each row is one entry, holding only the measurements entered at
            that time. Record new measurements from the **Add** tab; delete a
            row here if it was entered in error.

          ''',
          child: Text(
            'Health Profile History',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        actions: [
          MarkdownTooltip(
            message: '''

              **Refresh:** Re-read the recorded measurements from your pod.

            ''',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _load,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Could not read your health profile: $_error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No measurements recorded yet.\n\n'
            'Record your weight, height, waist and hip from the Add tab.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return HealthProfileHistoryTable(entries: _entries, onDelete: _delete);
  }
}
