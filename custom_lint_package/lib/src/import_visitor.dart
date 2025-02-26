/// Import visitor for enforcing import order lint rule.
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

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart' as custom_lint;

/// A specialised AST visitor that analyses and validates import directive ordering.
///
/// This visitor implements the logic for checking if imports in a Dart file follow
/// the specified ordering convention:
/// 1. Dart SDK imports (dart:*)
/// 2. Flutter imports (package:flutter/*)
/// 3. External package imports (other package:*)
/// 4. Project imports (package:healthpod/*)
///
/// The visitor reports a single, comprehensive error message per file when imports
/// are not properly ordered, including specific details about incorrect placements
/// and the expected ordering.
///
/// Example of a properly ordered file:
/// ```dart
/// import 'dart:async';
/// import 'dart:io';
///
/// import 'package:flutter/material.dart';
/// import 'package:flutter/widgets.dart';
///
/// import 'package:http/http.dart';
/// import 'package:path/path.dart';
///
/// import 'package:healthpod/models/user.dart';
/// import 'package:healthpod/utils/constants.dart';
/// ```

class ImportVisitor extends RecursiveAstVisitor<void> {
  /// The error reporter used to report lint violations.

  final ErrorReporter reporter;

  /// Creates a new instance of [ImportVisitor].
  ///
  /// Requires an [ErrorReporter] to report lint violations.

  ImportVisitor(this.reporter);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // Extract import directives from the compilation unit.

    final directives = node.directives;
    final imports = directives.whereType<ImportDirective>().toList();

    // Skip analysis if there are no imports.

    if (imports.isEmpty) return;

    _checkImportOrder(imports, reporter);
  }

  /// Analyses import ordering and reports violations.
  ///
  /// This method compares the current import order against the expected order
  /// and generates a detailed error message when violations are found.
  ///
  /// The error message includes:
  /// - Specific import statements that are out of order
  /// - Where each import should be placed
  /// - The complete expected ordering of all imports

  void _checkImportOrder(
      List<ImportDirective> imports, ErrorReporter reporter) {
    // Extract string values from import directives.

    List<String> importStrings =
        imports.map((imp) => imp.uri.stringValue ?? "").toList();

    // Generate properly sorted import list.

    List<String> sortedImports = _sortImports(importStrings);

    // Collect any ordering violations.

    List<String> errors = [];
    for (int i = 0; i < importStrings.length; i++) {
      // Skip if the import is already at the correct position.

      if (sortedImports[i] == importStrings[i]) continue;

      // Determine the correct before/after position for the import.

      String before = i > 0 ? sortedImports[i - 1] : "start of imports";
      String after = i < sortedImports.length - 1
          ? sortedImports[i + 1]
          : "end of imports";

      // If misplaced import is already in the expected "before" position, simplify the message.

      if (importStrings[i] == before) {
        errors.add('❌ Incorrect import position: "${importStrings[i]}"\n'
            '   🔼 Expected position: Before "$after".');
      }
      // If misplaced import is already in the expected "after" position, simplify the message.

      else if (importStrings[i] == after) {
        errors.add('❌ Incorrect import position: "${importStrings[i]}"\n'
            '   🔼 Expected position: After "$before".');
      }
      //  Default case: Show full "After X, Before Y" message.

      else {
        errors.add('❌ Incorrect import position: "${importStrings[i]}"\n'
            '   🔼 Expected position: After "$before", before "$after".');
      }
    }

    // Exit if no violations were found.

    if (errors.isEmpty) return;

    // Format the expected order with proper grouping.

    String formattedExpectedOrder = _formatExpectedOrder(sortedImports);

    // Construct comprehensive error message.

    String detailedMessage = '🚨 Incorrect import order in file.\n'
        '${errors.join("\n")}\n\n'
        '✅ Expected order:\n$formattedExpectedOrder';

    // Create lint code with detailed message.

    final dynamicCode = custom_lint.LintCode(
      name: 'ordered_imports',
      problemMessage: detailedMessage,
      errorSeverity: ErrorSeverity.INFO,
    );

    // Report the error at the location of the first import.

    reporter.atOffset(
      offset: imports.first.offset,
      length: imports.first.length,
      errorCode: dynamicCode,
    );
  }

  /// Sorts imports according to the modified ordering convention.
  ///
  /// Groups imports into categories and sorts each category alphabetically:
  /// 1. Dart SDK imports
  /// 2. Flutter package imports
  /// 3. External package imports
  /// 4. Project-specific imports
  /// 5. Relative imports

  List<String> _sortImports(List<String> imports) {
    // Categorise imports.

    List<String> dartImports = [];
    List<String> flutterImports = [];
    List<String> externalImports = [];
    List<String> relativeImports = [];
    List<String> projectImports = [];

    for (var import in imports) {
      if (import.startsWith("dart:")) {
        dartImports.add(import);
      } else if (import.startsWith("package:flutter/")) {
        flutterImports.add(import);
      } else if (import.startsWith("package:healthpod/")) {
        projectImports.add(import);
      } else if (import.startsWith("package:")) {
        externalImports.add(import);
      } else {
        // This captures relative imports that don't start with "package:"
        relativeImports.add(import);
      }
    }

    // Sort each category alphabetically.

    dartImports.sort();
    flutterImports.sort();
    externalImports.sort();
    relativeImports.sort();
    projectImports.sort();

    // Combine sorted categories in the correct order.

    return [
      ...dartImports,
      ...flutterImports,
      ...externalImports,
      ...projectImports,
      ...relativeImports,
    ];
  }

  /// Formats the list of imports with visual separation between categories.
  ///
  /// Adds blank lines between different import categories for better readability.

  String _formatExpectedOrder(List<String> imports) {
    List<String> formattedImports = [];
    String lastCategory = "";

    for (var import in imports) {
      String category = _getImportCategory(import);

      // Add spacing between different categories
      if (category != lastCategory && formattedImports.isNotEmpty) {
        formattedImports.add("");
      }

      formattedImports.add("  $import");
      lastCategory = category;
    }

    return formattedImports.join("\n");
  }

  /// Determines the category of an import based on its path.
  ///
  /// Categories are:
  /// - "dart" for Dart SDK imports
  /// - "flutter" for Flutter package imports
  /// - "project" for project-specific imports
  /// - "external" for all other package imports
  /// - "relative" for relative path imports

  String _getImportCategory(String importPath) {
    if (importPath.startsWith("dart:")) return "dart";
    if (importPath.startsWith("package:flutter/")) return "flutter";
    if (importPath.startsWith("package:healthpod/")) return "project";
    if (importPath.startsWith("package:")) return "external";
    return "relative";
  }
}
