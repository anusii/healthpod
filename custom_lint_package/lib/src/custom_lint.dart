/// Custom lint widget.
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

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:custom_lint_package/src/print_statement_visitor.dart';

/// A custom lint rule that detects and reports usage of print statements in Dart code.
///
/// This lint rule is designed to help maintain code quality by flagging instances
/// where developers might accidentally leave debug print statements in production code.
/// It integrates with the Dart analyzer to provide warnings during static analysis.
///
/// Can use this package as a template for defining other custom lint rules
/// e.g. sorting imports, enforcing naming conventions, etc.

class CustomLint extends DartLintRule {
  /// Creates a new instance of [MyCustomLint].
  ///
  /// Initialises the lint rule with a predefined error code that specifies
  /// the nature of the lint violation.

  const CustomLint() : super(code: _code);

  /// The lint code definition that specifies the lint rule's properties.
  ///
  /// This includes the rule's name and the message that will be displayed
  /// when a violation is found.

  static const LintCode _code = LintCode(
    name: 'my_custom_lint',
    problemMessage: 'Avoid using print statements in production code.',
  );

  /// Getter to access the lint code from other parts of the application.

  static LintCode get lintCode => _code;

  /// Executes the lint rule on the provided code.
  ///
  /// This method is called by the analyzer for each Dart file being analyzed.
  /// It retrieves the resolved AST and passes it to a [PrintStatementVisitor]
  /// which does the actual work of finding print statements.
  ///
  /// [resolver] Provides access to the resolved AST
  /// [reporter] Used to report lint violations
  /// [context] Provides additional context for the analysis

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) {
    resolver.getResolvedUnitResult().then((ResolvedUnitResult result) {
      result.unit.visitChildren(PrintStatementVisitor(reporter));
    });
  }
}
