/// Plugin widget.
///
// Time-stamp: <Thursday 2025-01-30 08:36:00 +1100 Graham Williams>
///
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
/// Authors: Ashley Tang

library;

import 'custom_lint.dart';

import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Plugin class that registers the custom lint rules.
///
/// This class implements [PluginBase] and is responsible for providing
/// the list of lint rules that should be applied during analysis.

class MyPlugin extends PluginBase {
  /// Returns the list of lint rules to be applied during analysis.
  ///
  /// [configs] Contains configuration options for the lint rules.
  /// Returns a list containing an instance of [MyCustomLint].

  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [CustomLint()];
}

/// Factory function that creates an instance of the plugin.
///
/// This function is required by the custom_lint package and is used to
/// instantiate the plugin when the analyzer loads it.
///
/// Returns a new instance of [MyPlugin].

PluginBase createPlugin() => MyPlugin();
