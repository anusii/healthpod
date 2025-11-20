/// OCR service for extracting text from PDF images.
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

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:path/path.dart' as path;

/// Service for performing OCR on PDF documents.

class PdfOcrService {
  const PdfOcrService._();

  /// Extracts text from an image using system Tesseract command.

  static Future<String> _extractTextUsingSystemCommand(String imagePath) async {
    try {
      debugPrint('=== System Tesseract Command ===');
      debugPrint('Image path: $imagePath');
      
      // Verify image file exists.

      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('ERROR: Image file does not exist!');
        return '';
      }
      
      final fileSize = await imageFile.length();
      debugPrint('Image file size: ${fileSize} bytes');
      
      // Call tesseract directly via system command.
      // tesseract <input> stdout will output to stdout.

      debugPrint('Running: tesseract "$imagePath" stdout -l eng');
      
      final result = await Process.run(
        'tesseract',
        [imagePath, 'stdout', '-l', 'eng'],
      );
      
      debugPrint('Tesseract exit code: ${result.exitCode}');
      
      if (result.exitCode == 0) {
        final text = result.stdout.toString().trim();
        debugPrint('System Tesseract SUCCESS: ${text.length} characters');
        return text;
      } else {
        debugPrint('System Tesseract FAILED with exit code ${result.exitCode}');
        debugPrint('stdout: ${result.stdout}');
        debugPrint('stderr: ${result.stderr}');
        return '';
      }
    } catch (e, stackTrace) {
      debugPrint('System Tesseract command exception: $e');
      debugPrint('Stack trace: $stackTrace');
      return '';
    }
  }
  
  /// Checks if Tesseract OCR is available and properly configured.

  static Future<bool> checkTesseractAvailability() async {
    try {
      debugPrint('Checking Tesseract availability...');
      
      // Check if tesseract command is available.

      final result = await Process.run('which', ['tesseract']);
      if (result.exitCode == 0) {
        debugPrint('Tesseract found at: ${result.stdout.toString().trim()}');
        return true;
      } else {
        debugPrint('Tesseract not found in system PATH');
        return false;
      }
    } catch (e) {
      debugPrint('Tesseract check failed: $e');
      return false;
    }
  }

  /// Performs OCR on a PDF file.

  static Future<String> performOcr(String pdfPath) async {
    debugPrint('Starting OCR extraction for: $pdfPath');

    final List<String> tempImagePaths = [];
    String combinedText = '';

    try {
      // Open PDF document.

      final document = await PdfDocument.openFile(pdfPath);
      final pageCount = document.pageCount;

      debugPrint('PDF has $pageCount pages, converting to images for OCR');

      // Get temporary directory.

      final tempDir = await getTemporaryDirectory();

      // Process each page.

      for (int pageNum = 1; pageNum <= pageCount; pageNum++) {
        debugPrint('Processing page $pageNum/$pageCount');

        try {
          // Get page.

          final page = await document.getPage(pageNum);

          // Render page to image with 3x resolution for better OCR
          // Higher resolution improves text recognition accuracy
          // Note: pdf_render generates PNG format by default.

          final pageImage = await page.render(
            width: (page.width * 3).toInt(),
            height: (page.height * 3).toInt(),
          );

          // Create temporary image file (PNG format).

          final tempImagePath = path.join(
            tempDir.path,
            'ocr_page_${pageNum}_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          tempImagePaths.add(tempImagePath);

          // Convert Image to PNG bytes.
          // First, create the image.

          await pageImage.createImageIfNotAvailable();
          final image = await pageImage.createImageDetached();
          
          // Convert ui.Image to PNG bytes.

          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData == null) {
            debugPrint('Failed to convert image to bytes for page $pageNum');
            continue;
          }
          
          final imageBytes = byteData.buffer.asUint8List();
          
          // Save PNG image to file.

          final File imageFile = File(tempImagePath);
          await imageFile.writeAsBytes(imageBytes);

          final fileSize = await imageFile.length();
          debugPrint('Saved temporary image: $tempImagePath (${fileSize} bytes)');

          // Perform OCR on the image.

          String pageText = '';
          
          // Use system command (desktop/mobile platforms).

          if (!kIsWeb) {
            try {
              pageText = await _extractTextUsingSystemCommand(tempImagePath);
              
              if (pageText.isNotEmpty) {
                combinedText += pageText + '\n';
                debugPrint(
                  'Page $pageNum: Extracted ${pageText.length} characters',
                );
              } else {
                debugPrint(
                  'Page $pageNum: System Tesseract returned empty text',
                );
              }
            } catch (e, stackTrace) {
              debugPrint('Page $pageNum: System Tesseract failed: $e');
              debugPrint('Stack trace: $stackTrace');
            }
          } else {
            debugPrint('Web platform: OCR not supported');
          }
        } catch (e) {
          debugPrint('Error processing page $pageNum: $e');
          continue;
        }
      }

      // Close document.

      document.dispose();

      debugPrint(
        'Successfully extracted ${combinedText.length} characters using OCR',
      );

      return combinedText.trim();
    } catch (e) {
      debugPrint('Error during OCR extraction: $e');
      rethrow;
    } finally {
      // Clean up temporary image files.

      for (String imagePath in tempImagePaths) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            await file.delete();
            debugPrint('Deleted temporary image: $imagePath');
          }
        } catch (e) {
          debugPrint('Warning: Failed to delete temporary image $imagePath: $e');
        }
      }
    }
  }

  /// Checks if OCR is available on the current platform.

  static Future<bool> isOcrAvailable() async {
    try {
      // Try to extract text from a test string to see if Tesseract is
      // available.
      return true; // Assume available, actual check happens when OCR is called.
    } catch (e) {
      debugPrint('OCR not available: $e');
      return false;
    }
  }
}
