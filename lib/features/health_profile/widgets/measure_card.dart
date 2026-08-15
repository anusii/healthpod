/// A card showing one health profile measurement.
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

/// A card showing one measurement, its unit, and when it was last updated.
///
/// A measurement that has not been recorded shows a dash rather than being
/// left out, so it is clear what the profile is still missing.

class MeasureCard extends StatelessWidget {
  const MeasureCard({
    super.key,
    required this.label,
    required this.value,
    required this.tooltip,
    this.unit,
    this.detail,
  });

  /// The name of the measurement.

  final String label;

  /// The measurement itself, or null when nothing has been recorded.

  final String? value;

  /// What the measurement is and how to read it.

  final String tooltip;

  /// The unit the measurement is in.

  final String? unit;

  /// The line beneath the value - when it was updated, or how it reads.

  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recorded = value != null;

    return MarkdownTooltip(
      message: tooltip,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 190,

          // A fixed height so the cards line up in rows however long the
          // value and its detail line run.

          height: 132,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              // A long value with its unit is scaled down rather than
              // clipped, so a card never loses the number it is there for.

              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value ?? '—',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: recorded
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (recorded && unit != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail ?? 'Not recorded',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
