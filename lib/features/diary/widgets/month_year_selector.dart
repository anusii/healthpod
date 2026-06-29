/// Month and year selector bar for the appointments calendar.
///
/// Copyright (C) 2024-2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

/// A compact bar with month and year dropdowns plus a Today button. Reports
/// changes via callbacks so the parent owns the focused-day state.

class MonthYearSelector extends StatelessWidget {
  const MonthYearSelector({
    super.key,
    required this.focusedDay,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onToday,
  });

  final DateTime focusedDay;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Month dropdown.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withAlpha(51),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: focusedDay.month,
                  underline: const SizedBox(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  items: List.generate(12, (index) => index + 1)
                      .map(
                        (month) => DropdownMenuItem<int>(
                          value: month,
                          child: Text(
                            DateFormat(
                              'MMMM',
                            ).format(DateTime(focusedDay.year, month)),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (int? newMonth) {
                    if (newMonth != null) onMonthChanged(newMonth);
                  },
                ),
              ],
            ),
          ),
          // Year dropdown.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withAlpha(51),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: focusedDay.year,
                  underline: const SizedBox(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  items: List.generate(11, (index) => 2020 + index)
                      .map(
                        (year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text(
                            year.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (int? newYear) {
                    if (newYear != null) onYearChanged(newYear);
                  },
                ),
              ],
            ),
          ),
          // Today button.
          TextButton.icon(
            onPressed: onToday,
            icon: Icon(
              Icons.today,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: const Text('Today'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withAlpha(51),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
