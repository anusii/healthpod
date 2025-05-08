/// Home Page Widget
//
// Time-stamp: <Friday 2025-02-21 08:30:05 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Kevin Wang, Zheyuan Xu

library;

import 'package:flutter/material.dart';

import 'package:healthpod/features/home/service/components/appointment_card.dart';
import 'package:healthpod/features/home/service/components/components.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onNavigateToProfile;

  const HomePage({
    super.key,
    required this.onNavigateToProfile,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Key to force rebuild of the PersonalDetails widget.

  final GlobalKey _personalDetailsKey = GlobalKey();

  // Force rebuild of the PersonalDetails widget.

  void _refreshPersonalDetails() {
    setState(() {
      // Updating the key will force a rebuild.

      _personalDetailsKey.currentState?.setState(() {});
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Your Personal Health Data Management System',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              const ManagePlan(),
              const SizedBox(height: 16),
              const AppointmentCard(),
              const SizedBox(height: 16),
              ProfileDetails(
                key: _personalDetailsKey,
                showEditButton: true,
                onEditPressed: () {},
                onDataChanged: _refreshPersonalDetails,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(int index) {
    final List<Widget> gridItems = [
      const ManagePlan(),
      const AppointmentCard(),
      ProfileDetails(
        key: _personalDetailsKey,
        showEditButton: true,
        onEditPressed: () {},
        onDataChanged: _refreshPersonalDetails,
      ),
    ];

    // Return the widget directly without any constraints to preserve natural sizing.
    return gridItems[index];
  }

  Widget _buildDesktopLayout(BuildContext context, double maxWidth) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            // Replace GridView with a more flexible layout that respects natural heights.

            if (maxWidth < 1200)
              // Two column layout.

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First column.
                  Expanded(
                    child: Column(
                      children: [
                        _buildGridItem(0),
                        const SizedBox(height: 24),
                        _buildGridItem(1),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Second column - Profile Details.

                  Expanded(
                    child: _buildGridItem(2),
                  ),
                ],
              )
            else
              // Three column layout.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First column.

                  Expanded(
                    child: _buildGridItem(0),
                  ),
                  const SizedBox(width: 24),
                  // Second column.

                  Expanded(
                    child: _buildGridItem(1),
                  ),
                  const SizedBox(width: 24),
                  // Third column - Profile Details.

                  Expanded(
                    child: _buildGridItem(2),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth < 800
              ? _buildMobileLayout(context)
              : _buildDesktopLayout(context, constraints.maxWidth);
        },
      ),
    );
  }
}
