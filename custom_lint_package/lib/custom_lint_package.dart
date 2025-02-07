/// Custom lint package plugin.
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

import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:custom_lint_package/src/custom_lint.dart';
import 'package:custom_lint_package/src/import_order_lint.dart';

/// Private plugin class that implements the custom lint plugin functionality.
///
/// This class extends [PluginBase] to create a custom lint plugin that can be
/// loaded by the Dart analyzer. It provides the list of lint rules that should
/// be applied during static code analysis.

class _MyPlugin extends PluginBase {
  /// Returns the list of lint rules to be executed by the analyzer.
  ///
  /// This method is called by the analyzer to obtain the list of lint rules
  /// that should be applied during code analysis. It instantiates and returns
  /// all custom lint rules defined in this package.
  ///
  /// Parameters:
  ///   - [configs]: Configuration options for the lint rules, which can be
  ///     used to customize rule behavior based on analyzer settings.
  ///
  /// Returns:
  ///   A list of [LintRule] instances that will be executed during analysis.

  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [
      CustomLint(), // Lint for enforcing print statement usage. Acts as template.
      ImportOrderLint(), // Lint for enforcing import order.
    ];
  }
}

/// Factory function that creates an instance of the custom lint plugin.
///
/// This function is required by the custom_lint package and is automatically
/// called when the analyzer loads the plugin. It must be named 'createPlugin'
/// and return a [PluginBase] instance.
///
/// Returns:
///   A new instance of the custom lint plugin.

PluginBase createPlugin() => _MyPlugin();
