/// A tab that displays organized health resources and information.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:healthpod/features/file/resources/card.dart';
import 'package:healthpod/features/file/resources/service/resource_service.dart';

/// A tab widget that displays health resources organised by category.

class ResourcesTab extends StatelessWidget {
  /// Creates a resources tab.

  const ResourcesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Resources',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),
            // Health Information section.

            _buildSection(
              context,
              title: 'Health Information',
              icon: Icons.medical_information,
              cards: [
                ResourceCard(
                  title: 'Blood Pressure Guide',
                  description:
                      'Understanding blood pressure readings and management',
                  icon: Icons.favorite,
                  onTap: () => ResourceService.showHealthInfo(
                    context,
                    'blood-pressure',
                  ),
                ),
                ResourceCard(
                  title: 'Vaccination Information',
                  description: 'Latest guidelines and schedules',
                  icon: Icons.vaccines,
                  onTap: () => ResourceService.showHealthInfo(
                    context,
                    'vaccination',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // External Resources section.

            _buildSection(
              context,
              title: 'External Resources',
              icon: Icons.link,
              cards: [
                ResourceCard(
                  title: 'WHO Health Topics',
                  description: 'World Health Organization resources',
                  icon: Icons.public,
                  isExternalLink: true,
                  onTap: () => ResourceService.openExternalLink(
                    context,
                    'https://www.who.int/health-topics',
                  ),
                ),
                ResourceCard(
                  title: 'Health Direct',
                  description: 'Australian health information and advice',
                  icon: Icons.local_hospital,
                  isExternalLink: true,
                  onTap: () => ResourceService.openExternalLink(
                    context,
                    'https://www.healthdirect.gov.au',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Tools & Calculators section.

            _buildSection(
              context,
              title: 'Tools & Calculators',
              icon: Icons.calculate,
              cards: [
                ResourceCard(
                  title: 'BMI Calculator',
                  description: 'Calculate and track your Body Mass Index',
                  icon: Icons.monitor_weight,
                  onTap: () => ResourceService.showCalculator(
                    context,
                    'bmi',
                  ),
                ),
                ResourceCard(
                  title: 'Health Goal Tracker',
                  description: 'Set and monitor your health goals',
                  icon: Icons.track_changes,
                  onTap: () => ResourceService.showTracker(
                    context,
                    'health-goals',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section of resource cards with a title and icon.
  ///
  /// Parameters:
  /// * [context] - The build context
  /// * [title] - The section title
  /// * [icon] - The icon to display next to the title
  /// * [cards] - List of [ResourceCard]s to display in this section

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<ResourceCard> cards,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with icon.

        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.headlineMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Wrap cards in a responsive grid.

        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards,
        ),
      ],
    );
  }
}
