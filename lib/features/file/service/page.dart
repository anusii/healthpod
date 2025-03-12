/// The file service page that provides file management functionality.
///
/// This page includes features for uploading, downloading, and managing files
/// in the user's POD storage.
///
/// Authors: Ashley Tang

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/features/file/service/components/components.dart';

/// The file service page that provides file management functionality.
///
/// This page includes features for uploading, downloading, and managing files
/// in the user's POD storage.
class FileService extends ConsumerWidget {
  const FileService({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Management'),
        backgroundColor: titleBackgroundColor,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: FileServiceWidget(),
      ),
    );
  }
}
