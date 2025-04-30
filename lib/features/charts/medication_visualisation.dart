/// Medication visualisation widget.
///
// Time-stamp: <Tuesday 2025-04-29 15:30:00 +1000 Graham Williams>
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

import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

import 'package:healthpod/constants/medication_survey.dart';
import 'package:healthpod/features/charts/utils/normalise_frequency.dart';
import 'package:healthpod/features/charts/utils/parse_date_safely.dart';
import 'package:healthpod/features/medication/data.dart';
import 'package:healthpod/features/visualise/stat_item.dart';

/// A widget for visualizing medication data.
///
/// This widget provides:
/// * Timeline of medications with start dates
/// * Visualisation of active medications over time
/// * Summary statistics including total count and frequency breakdown

class MedicationVisualisation extends StatefulWidget {
  const MedicationVisualisation({super.key});

  @override
  State<MedicationVisualisation> createState() => _MedicationVisualisationState();
}

class _MedicationVisualisationState extends State<MedicationVisualisation> {
  List<Map<String, dynamic>> _surveyData = [];
  bool _isLoading = true;
  String? _error;
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    // Catch any error that might come from date parsing.

    FlutterError.onError = (details) {
      if (details.exception is FormatException && 
          details.exception.toString().contains('Invalid date format null')) {
        debugPrint('Caught date format error: ${details.exception}');
        // Don't propagate this specific error.

        return;
      }
      // For all other errors, let Flutter handle them normally.

      FlutterError.presentError(details);
    };
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First, try to load data from the medication directory in the pod.

      final medicationData = await MedicationData.fetchAllMedicationData(context);
      
      // Validate each record and fix issues.
      
      final List<Map<String, dynamic>> validData = [];
      
      for (final record in medicationData) {
        try {
          // Ensure responses exists.

          if (!record.containsKey('responses')) {
            debugPrint('Skipping record without responses: $record');
            continue;
          }
          
          // Create a validated copy of the record to avoid modifying the original.
          
          final validatedRecord = <String, dynamic>{
            'timestamp': record['timestamp'] ?? DateTime.now().toIso8601String(),
            'responses': <String, dynamic>{},
          };
          
          final responses = record['responses'] as Map<String, dynamic>?;
          if (responses == null) {
            debugPrint('Skipping record with null responses: $record');
            continue;
          }
          
          // Copy responses with validation.

          validatedRecord['responses'][MedicationSurveyConstants.fieldName] = 
              responses[MedicationSurveyConstants.fieldName] ?? 'Unknown medication';
              
          validatedRecord['responses'][MedicationSurveyConstants.fieldDosage] = 
              responses[MedicationSurveyConstants.fieldDosage] ?? '';
              
          validatedRecord['responses'][MedicationSurveyConstants.fieldFrequency] = 
              responses[MedicationSurveyConstants.fieldFrequency] ?? '';
          
          // Special handling for date fields.

          String? startDateStr = responses[MedicationSurveyConstants.fieldStartDate] as String?;
          if (startDateStr == null || startDateStr.isEmpty) {
            // If no start date, use record timestamp.

            try {
              final timestamp = DateTime.parse(record['timestamp'].toString());
              startDateStr = DateFormat('yyyy-MM-dd').format(timestamp);
            } catch (e) {
              debugPrint('Error using timestamp as fallback date: $e');
              startDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
            }
          }
          validatedRecord['responses'][MedicationSurveyConstants.fieldStartDate] = startDateStr;
          
          validatedRecord['responses'][MedicationSurveyConstants.fieldNotes] = 
              responses[MedicationSurveyConstants.fieldNotes] ?? '';
          
          // Add the validated record.

          validData.add(validatedRecord);
          
        } catch (e) {
          debugPrint('Error validating medication record: $e');
          // Skip invalid records.

        }
      }
      
      if (mounted) {
        setState(() {
          // If we have medication data, use it.

          if (validData.isNotEmpty) {
            _surveyData = validData;
            debugPrint('Loaded ${validData.length} medication records from pod');
          } else {
            // Otherwise use sample data.

            _surveyData = _getSampleData();
            debugPrint('No valid medication data found in pod, using sample data');
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error in _loadData: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading medication data: $e';
          _isLoading = false;
          // Use sample data as fallback.

          _surveyData = _getSampleData();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  /// Provides sample data to use when server data is unavailable.  

  List<Map<String, dynamic>> _getSampleData() {
    return [
      {
        'timestamp': DateTime(2025, 3, 15).toIso8601String(),
        'responses': {
          MedicationSurveyConstants.fieldName: 'Lisinopril',
          MedicationSurveyConstants.fieldDosage: '10mg',
          MedicationSurveyConstants.fieldFrequency: 'Once daily',
          MedicationSurveyConstants.fieldStartDate: '2025-01-15',
          MedicationSurveyConstants.fieldNotes: 'Take in the morning',
        },
      },
      {
        'timestamp': DateTime(2025, 3, 10).toIso8601String(),
        'responses': {
          MedicationSurveyConstants.fieldName: 'Metformin',
          MedicationSurveyConstants.fieldDosage: '500mg',
          MedicationSurveyConstants.fieldFrequency: 'Twice daily',
          MedicationSurveyConstants.fieldStartDate: '2024-12-01',
          MedicationSurveyConstants.fieldNotes: 'Take with food',
        },
      },
      {
        'timestamp': DateTime(2025, 2, 28).toIso8601String(),
        'responses': {
          MedicationSurveyConstants.fieldName: 'Atorvastatin',
          MedicationSurveyConstants.fieldDosage: '20mg',
          MedicationSurveyConstants.fieldFrequency: 'Once daily',
          MedicationSurveyConstants.fieldStartDate: '2024-11-15',
          MedicationSurveyConstants.fieldNotes: 'Take at bedtime',
        },
      },
      {
        'timestamp': DateTime(2025, 2, 15).toIso8601String(),
        'responses': {
          MedicationSurveyConstants.fieldName: 'Aspirin',
          MedicationSurveyConstants.fieldDosage: '81mg',
          MedicationSurveyConstants.fieldFrequency: 'Once daily',
          MedicationSurveyConstants.fieldStartDate: '2024-10-10',
          MedicationSurveyConstants.fieldNotes: 'Low-dose therapy',
        },
      },
    ];
  }

  /// Builds a list of statistical summary widgets.
  
  List<Widget> _buildStatItems() {
    if (_surveyData.isEmpty) {
      return [
        const StatItem(
          label: 'Medications',
          value: 'No data available',
        ),
      ];
    }

    // Count medications by frequency.

    Map<String, int> frequencyCount = {};
    for (var entry in _surveyData) {
      try {
        final responses = entry['responses'];
        if (responses == null) continue;
        
        // Get frequency and normalize it for better grouping.

        String frequency = responses[MedicationSurveyConstants.fieldFrequency] as String? ?? 'Unknown';
        
        // Normalise frequency for better grouping (e.g. "Once daily" and "once a day" should count as the same).

        frequency = normaliseFrequency(frequency);
        
        frequencyCount[frequency] = (frequencyCount[frequency] ?? 0) + 1;
      } catch (e) {
        debugPrint('Error processing medication entry in stats: $e');
        // Skip this entry.

      }
    }

    // Get the most common frequency.

    String mostCommonFrequency = 'None';
    int highestCount = 0;
    frequencyCount.forEach((frequency, count) {
      if (count > highestCount) {
        highestCount = count;
        mostCommonFrequency = frequency;
      }
    });

    return [
      StatItem(
        label: 'Total Medications',
        value: '${_surveyData.length}',
      ),
      Container(
        height: 40,
        width: 1,
        color: theme.dividerColor,
      ),
      StatItem(
        label: 'Most Common Frequency',
        value: mostCommonFrequency,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _surveyData.isEmpty) {
      return Center(
        child: Text(_error!),
      );
    }

    // Sort medications by start date, most recent first.

    final sortedData = [..._surveyData];
    
    try {
      sortedData.sort((a, b) {
        try {
          // Get date strings, handle both formats.

          final aDateStr = a['responses'][MedicationSurveyConstants.fieldStartDate] as String?;
          final bDateStr = b['responses'][MedicationSurveyConstants.fieldStartDate] as String?;
          
          // Parse dates safely.

          final DateTime aDate = parseDateSafely(aDateStr) ?? DateTime(1900);
          final DateTime bDate = parseDateSafely(bDateStr) ?? DateTime(1900);
          
          return bDate.compareTo(aDate);
        } catch (e) {
          // If there's an error parsing dates, maintain original order.

          debugPrint('Error sorting medication data: $e');
          return 0;
        }
      });
    } catch (e) {
      debugPrint('Error sorting medication data: $e');
      // Continue with unsorted data if sorting fails.

    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics section.

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildStatItems(),
              ),
            ),

            const Divider(height: 32),

            // Medication Timeline.

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildMedicationTimeline(sortedData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationTimeline(List<Map<String, dynamic>> sortedData) {
    if (sortedData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No medication data available'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedData.length,
      itemBuilder: (context, index) {
        try {
          final data = sortedData[index];
          final responses = data['responses'];
          if (responses == null) {
            // Skip invalid entries.

            return const SizedBox.shrink();
          }

          // Extract data with null safety.

          final name = responses[MedicationSurveyConstants.fieldName] as String? ?? 'Unknown medication';
          final dosage = responses[MedicationSurveyConstants.fieldDosage] as String? ?? '';
          final rawFrequency = responses[MedicationSurveyConstants.fieldFrequency] as String? ?? '';
          final frequency = normaliseFrequency(rawFrequency);
          
          // Parse date with error handling.

          DateTime? startDate;
          try {
            final dateStr = responses[MedicationSurveyConstants.fieldStartDate] as String?;
            startDate = parseDateSafely(dateStr);
          } catch (e) {
            debugPrint('Error parsing date in timeline: $e');
          }
          
          final notes = responses[MedicationSurveyConstants.fieldNotes] as String? ?? '';

          // Format the date or use a placeholder.

          final formattedDate = startDate != null 
              ? DateFormat('MMM d, yyyy').format(startDate)
              : 'Unknown date';

          return TimelineTile(
            alignment: TimelineAlign.manual,
            lineXY: 0.1,
            isFirst: index == 0,
            isLast: index == sortedData.length - 1,
            indicatorStyle: IndicatorStyle(
              width: 15,
              color: theme.primaryColor,
            ),
            beforeLineStyle: LineStyle(
              color: theme.primaryColor,
              thickness: 2,
            ),
            endChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 0, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (dosage.isNotEmpty || frequency.isNotEmpty)
                    Text(
                      [if (dosage.isNotEmpty) dosage, if (frequency.isNotEmpty) frequency]
                          .join(', '),
                      style: theme.textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Started: $formattedDate',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Notes: $notes',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            startChild: Center(
              child: Text(
                startDate != null
                    ? DateFormat('MMM\nyyyy').format(startDate)
                    : 'Unknown\ndate',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          );
        } catch (e) {
          debugPrint('Error building timeline item: $e');
          return const SizedBox.shrink();
        }
      },
    );
  }
} 