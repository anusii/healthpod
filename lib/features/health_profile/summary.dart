/// The health profile summary: current measurements and what they calculate.
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

import 'package:healthpod/features/health_profile/model.dart';
import 'package:healthpod/features/health_profile/service.dart';
import 'package:healthpod/features/health_profile/widgets/advice_links.dart';
import 'package:healthpod/features/health_profile/widgets/profile_cards.dart';
import 'package:healthpod/utils/fetch_profile_data.dart';

/// Shows where your measurements stand today.
///
/// Each measurement is shown with the date it was last updated, alongside the
/// body mass index and waist to hip ratio calculated from them, and links to
/// published advice on how to read those two.

class HealthProfileSummary extends StatefulWidget {
  const HealthProfileSummary({super.key});

  @override
  State<HealthProfileSummary> createState() => _HealthProfileSummaryState();
}

class _HealthProfileSummaryState extends State<HealthProfileSummary> {
  Map<String, DatedValue> _latest = {};
  String? _dateOfBirth;
  String? _gender;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads the measurements from the pod, and the date of birth and gender
  /// from the personal profile.

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries = await HealthProfileService.fetchAll();
      if (!mounted) return;

      final profile = await fetchProfileData(context);
      if (!mounted) return;

      setState(() {
        _latest = HealthProfileService.latestValues(entries);
        _dateOfBirth = profile['dateOfBirth']?.toString();
        _gender = profile['gender']?.toString();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.surface,
        title: MarkdownTooltip(
          message: '''

            **Health Profile:** Your body measurements, each kept with the date
            you recorded it.

            Weight, height, waist and hip are entered from the **Add** tab and
            every entry is kept in your pod, so you can see how they have
            changed under the **Data** tab. Your body mass index and waist to
            hip ratio are calculated from the most recent of each.

          ''',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Health Profile',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        actions: [
          MarkdownTooltip(
            message: '''

              **Refresh:** Re-read your measurements from your pod, picking up
              anything recorded since this screen was opened.

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_error != null) _buildError(),
          if (_latest.isEmpty && _error == null) _buildEmpty(),
          HealthProfileCards(
            latest: _latest,
            today: DateTime.now(),
            dateOfBirth: _dateOfBirth,
            gender: _gender,
          ),
          const SizedBox(height: 24),
          const HealthProfileAdviceLinks(),
        ],
      ),
    );
  }

  /// Says what is missing, without hiding the empty cards that show which
  /// measurements are yet to be recorded.

  Widget _buildEmpty() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        'No measurements recorded yet. Add your weight, height, waist and '
        'hip from the Add tab.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildError() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        'Could not read your health profile: $_error',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
