/// A widget to view private key data in a Solid Pod.
///
// Time-stamp: <Monday 2025-04-14 13:21:20 +1000 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
///
/// This program is free software: you can redistribute it and/or modify it under
/// the terms of the GNU General Public License as published by the Free Software
/// Foundation, either version 3 of the License, or (at your option) any later
/// version.
///
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Anushka Vidanage, Graham Williams, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:healthpod/utils/get_enc_key_content.dart';

/// A widget to show the user all the encryption keys stored in their Solid Pod.

class ViewKeys extends StatefulWidget {
  /// Constructor for the widget.

  const ViewKeys({
    required this.keyInfo,
    required this.title,
    super.key,
  });

  /// Data of the key file.

  final String keyInfo;

  // Title of the page.

  final String title;

  @override
  State<ViewKeys> createState() => _ViewKeysState();
}

class _ViewKeysState extends State<ViewKeys> {
  /// Scaffold key for managing widget state.

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // The main screen layout with an app bar and a data table.

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: loadedScreen(widget.keyInfo));
  }

  @override
  void initState() {
    super.initState();
  }

  /// A widget to display the loaded encryption key data in a table.

  Widget loadedScreen(String keyData) {
    final encFileData = getEncKeyContent(keyData);

    // Map the data into rows for the DataTable.

    final dataRows = encFileData.entries.map((entry) {
      return DataRow(cells: [
        DataCell(Text(
          entry.key as String,
          style: const TextStyle(
            fontSize: 12,
          ),
        )),
        DataCell(SizedBox(
            width: 600,
            child: Text(
              entry.value[1] as String,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
              ),
            ))),
      ]);
    }).toList();

    // Display the table of encryption key data.

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DataTable(
                columnSpacing: 30.0,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Parameter',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Value',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                rows: dataRows),
          ],
        ),
      ),
    );
  }
}
