/// A widget for displaying file previews.
///
/// Time-stamp: <Friday 2025-02-14 08:40:39 +1100 Graham Williams>
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

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:healthpod/utils/is_text_file.dart';

/// A widget that displays a preview of a file's contents.
///
/// For text files, shows the first few lines of content.
/// For binary files, shows basic file information.
/// Handles large files gracefully with truncation.

class PreviewCard extends StatelessWidget {
  /// The path to the file to preview.
  final String filePath;

  const PreviewCard({
    super.key,
    required this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withAlpha(10),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File type indicator.
            Row(
              children: [
                Icon(
                  isTextFile(filePath)
                      ? Icons.description
                      : Icons.insert_drive_file,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isTextFile(filePath) ? 'Text File' : 'Binary File',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // File size.
            FutureBuilder<bool>(
              future: File(filePath).exists(),
              builder: (context, existsSnapshot) {
                if (!existsSnapshot.hasData || !existsSnapshot.data!) {
                  return const SizedBox.shrink();
                }

                return FutureBuilder<int>(
                  future: File(filePath).length(),
                  builder: (context, sizeSnapshot) {
                    if (!sizeSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final size = sizeSnapshot.data!;
                    return Text(
                      'Size: ${(size / 1024).toStringAsFixed(1)} KB',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),

            // Preview content for text files.
            if (isTextFile(filePath))
              FutureBuilder<String>(
                future: File(filePath).readAsString(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final content = snapshot.data!;
                  final preview = content.split('\n').take(5).join('\n');
                  final isTruncated = content.split('\n').length > 5;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isTruncated)
                        Text(
                          '... (truncated)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
