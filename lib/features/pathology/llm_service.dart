/// LLM-based pathology analysis service.
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

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Service for communicating with the PDF Analysis LLM server.

class PathologyLLMService {
  /// Base URL of the PDF analysis server.

  final String baseUrl;

  /// Request timeout duration.

  final Duration timeout;

  PathologyLLMService({
    this.baseUrl = 'http://localhost:8000',
    this.timeout = const Duration(seconds: 900), // 900 seconds (15 minutes)
  });

  /// Analyses a PDF file using the LLM server.
  ///
  /// Returns structured pathology data as a Map.

  Future<Map<String, dynamic>> analysePdf(File pdfFile) async {
    final uri = Uri.parse('$baseUrl/analyse/pdf');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('file', pdfFile.path),
    );

    try {
      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Server returned error: ${response.statusCode}\n${response.body}',
        );
      }
    } on SocketException {
      throw Exception(
        'Network error: Cannot connect to server at $baseUrl. '
        'Please ensure the server is running.',
      );
    } on http.ClientException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to analyse PDF: $e');
    }
  }

  /// Analyses pre-extracted text using the LLM server.
  ///
  /// Returns structured pathology data as a Map.

  Future<Map<String, dynamic>> analyseText(
    String text,
    String reportName,
  ) async {
    final uri = Uri.parse('$baseUrl/analyse/text');

    final body = json.encode({
      'text': text,
      'report_name': reportName,
    });

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Server returned error: ${response.statusCode}\n${response.body}',
        );
      }
    } on SocketException {
      throw Exception(
        'Network error: Cannot connect to server at $baseUrl. '
        'Please ensure the server is running.',
      );
    } on http.ClientException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to analyse text: $e');
    }
  }

  /// Checks if the LLM server is available.

  Future<bool> checkConnection() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(
            const Duration(seconds: 5),
          );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Gets the server health status with detailed information.

  Future<Map<String, dynamic>?> getHealthStatus() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
