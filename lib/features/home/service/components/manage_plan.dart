/// Management Plan card widget.
//
// Time-stamp: <Tuesday 2025-04-22 13:57:20 +1000 Graham Williams>
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
/// Authors: Zheyuan Xu

library;

import 'package:flutter/material.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/features/resources/service/resource_service.dart';
import 'package:healthpod/theme/card_style.dart';
import 'package:healthpod/utils/fetch_health_plan_data.dart';
import 'package:healthpod/utils/save_health_plan_data.dart';

/// A widget to display and edit a health management plan.
///
/// This widget displays a card with the current health management plan items
/// and provides functionality to edit, add, or remove items from the plan.

class ManagePlan extends StatefulWidget {
  const ManagePlan({super.key});

  @override
  State<ManagePlan> createState() => _ManagePlanState();
}

class _ManagePlanState extends State<ManagePlan> {
  // Plan data
  String title = 'My Health Management Plan';
  List<String> planItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthPlanData();
  }

  /// Loads the health plan data from the pod.

  Future<void> _loadHealthPlanData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final healthPlanData = await fetchHealthPlanData(context);

      // Check if the returned data has planItems list.

      final List<String> loadedPlanItems =
          (healthPlanData['planItems'] as List?)?.cast<String>() ?? [];

      setState(() {
        title =
            healthPlanData['title'] as String? ?? 'My Health Management Plan';
        planItems =
            loadedPlanItems; // Use the loaded items, which might be empty
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading health plan: $e');

      // Use empty list on error.

      setState(() {
        title = 'My Health Management Plan';
        planItems = [];
        isLoading = false;
      });
    }
  }

  /// Saves the current health plan to the pod.

  Future<void> _saveHealthPlanData() async {
    try {
      final result = await saveHealthPlanData(
        context: context,
        title: title,
        planItems: planItems,
      );

      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health plan saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving health plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving health plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Opens a dialog to edit the health management plan.

  void _editPlan() {
    // Create controllers for existing plan items.

    List<TextEditingController> controllers =
        planItems.map((item) => TextEditingController(text: item)).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Health Management Plan'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Plan Items',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        itemCount: controllers.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final item = controllers.removeAt(oldIndex);
                            controllers.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          return MarkdownTooltip(
                            key: ValueKey(index),
                            message: '**Drag** to reorder this item',
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: TextField(
                                  controller: controllers[index],
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Enter plan item (markdown supported)',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  maxLines: null,
                                ),
                                trailing: MarkdownTooltip(
                                  message: '**Delete** this item',
                                  child: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      setState(() {
                                        controllers.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            controllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Update the plan items
                    final newPlanItems = controllers
                        .map((controller) => controller.text)
                        .where((text) => text.isNotEmpty)
                        .toList();

                    // Update the parent widget state
                    setState(() {
                      planItems = newPlanItems;
                    });

                    this.setState(() {
                      planItems = newPlanItems;
                    });

                    // Save to POD
                    await _saveHealthPlanData();

                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(16.0),
      decoration: getHomeCardDecoration(context),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    MarkdownTooltip(
                      message: '**Edit** health management plan',
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _editPlan,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (planItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                        'No health plan items added yet. Click edit to add items.'),
                  )
                else
                  ...planItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(
                              child: MarkdownBody(
                                data: item,
                                selectable: true,
                                onTapLink: (text, href, title) {
                                  if (href != null) {
                                    ResourceService.openExternalLink(
                                        context, href);
                                  }
                                },
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(fontSize: 14),
                                  strong: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  em: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                  blockquote: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context).colorScheme.tertiary
                                        : Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  blockquoteDecoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.6)
                                        : Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer
                                            .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border(
                                      left: BorderSide(
                                        width: 4,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ),
                                  blockquotePadding: const EdgeInsets.only(
                                      left: 12, top: 4, bottom: 4, right: 4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
    );
  }
}
