/// Pathology report model class.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
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

/// Represents a pathology report file.

class PathologyReport {
  /// The display name of the report file (without .enc.ttl suffix).

  final String fileName;

  /// The date associated with this report.

  final DateTime date;

  /// The full path to the file in the POD storage.

  final String filePath;

  PathologyReport({
    required this.fileName,
    required this.date,
    required this.filePath,
  });
}

/// Represents a single test result within a pathology report.

class PathologyTest {
  /// Report name/identifier.

  final String reportName;

  /// Date when the test was requested.

  final DateTime? requestedDate;

  /// Time when the sample was collected.

  final DateTime? collectedTime;

  /// Time when the sample was received by the lab.

  final DateTime? receivedTime;

  /// Date when the report was uploaded.

  final DateTime? reportUploadDate;

  /// Name of the test.

  final String testName;

  /// Test result value.

  final String result;

  /// Units of measurement.

  final String units;

  /// Reference interval/normal range.

  final String referenceInterval;

  /// Additional comments or notes.

  final String comment;

  PathologyTest({
    required this.reportName,
    this.requestedDate,
    this.collectedTime,
    this.receivedTime,
    this.reportUploadDate,
    required this.testName,
    required this.result,
    this.units = '',
    this.referenceInterval = '',
    this.comment = '',
  });

  /// Creates a PathologyTest from JSON data.

  factory PathologyTest.fromJson(
    Map<String, dynamic> json,
    String reportName,
  ) {
    return PathologyTest(
      reportName: reportName,
      requestedDate: json['requested_date'] != null
          ? DateTime.tryParse(json['requested_date'])
          : null,
      collectedTime: json['collected_time'] != null
          ? DateTime.tryParse(json['collected_time'])
          : null,
      receivedTime: json['received_time'] != null
          ? DateTime.tryParse(json['received_time'])
          : null,
      reportUploadDate: json['report_upload_date'] != null
          ? DateTime.tryParse(json['report_upload_date'])
          : null,
      testName: json['test_name'] ?? '',
      result: json['result']?.toString() ?? '',
      units: json['units'] ?? '',
      referenceInterval: json['reference_interval'] ?? '',
      comment: json['comment'] ?? '',
    );
  }

  /// Converts the PathologyTest to JSON format.

  Map<String, dynamic> toJson() {
    return {
      'report_name': reportName,
      'requested_date': requestedDate?.toIso8601String(),
      'collected_time': collectedTime?.toIso8601String(),
      'received_time': receivedTime?.toIso8601String(),
      'report_upload_date': reportUploadDate?.toIso8601String(),
      'test_name': testName,
      'result': result,
      'units': units,
      'reference_interval': referenceInterval,
      'comment': comment,
    };
  }
}

/// Represents a report with its associated tests.

class ReportData {
  /// The display name of the report file.

  final String fileName;

  /// The date associated with this report.

  final DateTime date;

  /// The list of test results for this report.

  final List<PathologyTest> tests;

  ReportData({
    required this.fileName,
    required this.date,
    required this.tests,
  });
}
