/// PDF viewer page for pathology reports.
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
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Widget for viewing PDF pathology reports.

class PathologyPdfViewer extends StatefulWidget {
  final String fileName;
  final String filePath;
  final bool showAppBar; // Whether to show the app bar with zoom controls.

  const PathologyPdfViewer({
    required this.fileName,
    required this.filePath,
    this.showAppBar = true,
    super.key,
  });

  @override
  State<PathologyPdfViewer> createState() => _PathologyPdfViewerState();
}

class _PathologyPdfViewerState extends State<PathologyPdfViewer> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _error;
  final PdfViewerController _pdfViewerController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  /// Loads and decrypts the PDF file from the POD.

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Read the encrypted file from POD.
      // If it's a .enc.ttl file, readPod will automatically decrypt it.

      final result = await readPod(
        widget.filePath,
        context,
        const Text('Loading PDF'),
      );

      if (result == SolidFunctionCallStatus.fail.toString() ||
          result == SolidFunctionCallStatus.notLoggedIn.toString()) {
        throw Exception('Failed to load PDF from POD');
      }

      // Convert result to bytes based on type.
      late Uint8List bytes;

      if (result is Uint8List) {
        final resultBytes = result as Uint8List;
        bytes = resultBytes;
      } else if (result is List<int>) {
        final resultList = result as List<int>;
        bytes = Uint8List.fromList(resultList);
      } else {
        // If it's a string, it might be base64 encoded.

        final resultString = result;
        try {
          bytes = base64Decode(resultString);
        } catch (e) {
          debugPrint('PDF VIEWER: Base64 decode failed: $e');
          // Try as raw bytes from string.
          bytes = Uint8List.fromList(resultString.codeUnits);
        }
      }

      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If showAppBar is false, return just the body.

    if (!widget.showAppBar) {
      return Column(
        children: [
          // Zoom controls bar.

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  tooltip: 'Zoom Out',
                  onPressed: () {
                    _pdfViewerController.zoomLevel =
                        _pdfViewerController.zoomLevel - 0.25;
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  tooltip: 'Zoom In',
                  onPressed: () {
                    _pdfViewerController.zoomLevel =
                        _pdfViewerController.zoomLevel + 0.25;
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      );
    }

    // Otherwise, return with full Scaffold including app bar.

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Zoom In',
            onPressed: () {
              _pdfViewerController.zoomLevel =
                  _pdfViewerController.zoomLevel + 0.25;
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Zoom Out',
            onPressed: () {
              _pdfViewerController.zoomLevel =
                  _pdfViewerController.zoomLevel - 0.25;
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading PDF...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load PDF',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPdf,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes == null) {
      return const Center(
        child: Text('No PDF data available'),
      );
    }

    // Use memory to load decrypted PDF.

    return SfPdfViewer.memory(
      _pdfBytes!,
      controller: _pdfViewerController,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      enableDoubleTapZooming: true,
      enableTextSelection: true,
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        if (mounted) {
          setState(() {
            _error = 'Failed to load PDF: ${details.description}';
            _isLoading = false;
          });
        }
      },
    );
  }
}
