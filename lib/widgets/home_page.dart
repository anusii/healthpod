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

import 'package:healthpod/features/home/service/components/components.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onNavigateToProfile;

  const HomePage({
    super.key,
    required this.onNavigateToProfile,
  });

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
              const AvatarName(),
              const SizedBox(height: 16),
              const NextAppointment(),
              const SizedBox(height: 16),
              const ManagePlan(),
              const SizedBox(height: 16),
              PersonalDetails(
                showEditButton: true,
                onEditPressed: onNavigateToProfile,
              ),
              const SizedBox(height: 16),
              const NumberAppointments(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(int index) {
    final List<Widget> gridItems = [
      Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          AvatarName(),
          SizedBox(height: 10),
          NumberAppointments(),
          SizedBox(height: 10),
          ManagePlan(),
        ],
      ),
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [NextAppointment()],
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PersonalDetails(
            showEditButton: true,
            onEditPressed: onNavigateToProfile,
          ),
        ],
      ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400, minHeight: 220),
      child: gridItems[index],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, double maxWidth) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: maxWidth < 1200 ? 2 : 3,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                mainAxisExtent: 370,
              ),
              itemCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => _buildGridItem(index),
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
