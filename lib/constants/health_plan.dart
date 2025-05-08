/// Health plan constants.
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

/// Default health plan data structure.

final Map<String, dynamic> defaultHealthPlanData = {
  'timestamp': DateTime.now().toIso8601String(),
  'data': {
    'title': 'My Health Management Plan',
    'planItems': [
      '**Important medication**: Take 2 tablets of Vitamin D3 daily',
      '*Blood pressure goal*: Keep below 120/80 mmHg',
      'Visit [HealthDirect](https://www.healthdirect.gov.au) for more information',
      '## Exercise Plan\n- Walk 30 minutes *daily*\n- Swim **twice** weekly',
      '> Remember to drink 2L of water daily!',
      'Monitor glucose levels at these times:\n1. Before breakfast\n2. 2 hours after lunch\n3. Before bed',
    ],
  }
};
