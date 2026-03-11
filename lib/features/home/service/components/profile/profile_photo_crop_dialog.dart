/// Profile photo crop dialog with square aspect ratio.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU
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

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:crop_your_image/crop_your_image.dart';

/// Dialog for cropping a profile photo to a square region.

class ProfilePhotoCropDialog extends StatefulWidget {
  /// The image bytes to crop.

  final Uint8List imageBytes;

  /// Callback with the cropped image bytes (PNG format), or null if cancelled.

  final void Function(Uint8List? croppedBytes) onCropped;

  const ProfilePhotoCropDialog({
    super.key,
    required this.imageBytes,
    required this.onCropped,
  });

  /// Shows the crop dialog and returns the cropped image bytes when confirmed.

  static Future<Uint8List?> show(
    BuildContext context,
    Uint8List imageBytes,
  ) async {
    Uint8List? result;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProfilePhotoCropDialog(
          imageBytes: imageBytes,
          onCropped: (cropped) {
            result = cropped;
            Navigator.of(context).pop();
          },
        );
      },
    );
    return result;
  }

  @override
  State<ProfilePhotoCropDialog> createState() => _ProfilePhotoCropDialogState();
}

class _ProfilePhotoCropDialogState extends State<ProfilePhotoCropDialog> {
  final _cropController = CropController();
  bool _isCropping = false;

  void _onCrop() async {
    if (_isCropping) return;
    setState(() => _isCropping = true);
    _cropController.crop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crop Profile Photo'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Crop(
          image: widget.imageBytes,
          controller: _cropController,
          aspectRatio: 1.0,
          initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
            size: 0.8,
            aspectRatio: 1.0,
          ),
          interactive: true,
          onCropped: (result) {
            switch (result) {
              case CropSuccess(:final croppedImage):
                widget.onCropped(croppedImage);
              case CropFailure(:final cause):
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Crop failed: $cause'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                  widget.onCropped(null);
                }
            }
            if (mounted) {
              setState(() => _isCropping = false);
            }
          },
          progressIndicator: const Center(child: CircularProgressIndicator()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCropping ? null : () => widget.onCropped(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isCropping ? null : _onCrop,
          child: _isCropping
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crop & Save'),
        ),
      ],
    );
  }
}
