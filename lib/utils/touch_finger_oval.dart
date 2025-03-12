/// Touch finger oval widget showing message.
//
// Time-stamp: <Friday 2025-02-21 08:30:05 +1100 Graham Williams>
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

Widget touchFingerOval(String messageText) {
  return ClipOval(
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: null,
        child: Tooltip(
          message: messageText,
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
          margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          textStyle: plotTextStyleTooltip,
          showDuration: Duration(seconds: messageText.length > 200 ? 8 : 4),
          child: Icon(Icons.touch_app, color: Colors.green, size: 28),
        ),
      ),
    ),
  );
}

/// Text style for plot tooltip.

const plotTextStyleTooltip = TextStyle(
  fontWeight: FontWeight.normal,
  fontSize: 12,
  color: Colors.white,
  height: 1.1,
);
