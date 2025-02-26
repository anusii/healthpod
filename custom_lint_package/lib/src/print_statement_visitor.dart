/// Print statement visitor widget.
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
import 'package:analyzer/error/listener.dart';

import 'package:custom_lint_package/src/custom_lint.dart';

/// A visitor that traverses the AST looking for print statements.
///
/// This class extends [RecursiveAstVisitor] to walk through all nodes in the AST
/// and identifies method invocations that correspond to print statements.

class PrintStatementVisitor extends RecursiveAstVisitor<void> {
  /// The error reporter used to report lint violations.

  final ErrorReporter reporter;

  /// Creates a new instance of [PrintStatementVisitor].
  ///
  /// [reporter] The error reporter that will be used to report found print statements.

  PrintStatementVisitor(this.reporter);

  /// Visits method invocation nodes in the AST.
  ///
  /// This method is called for each method invocation found in the code.
  /// It checks if the method being called is 'print' and reports it as a
  /// lint violation if found.
  ///
  /// [node] The method invocation node being visited.

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'print') {
      reporter.atOffset(
        offset: node.offset,
        length: node.length,
        errorCode: CustomLint.lintCode,
      );
    }
    super.visitMethodInvocation(node);
  }
}
