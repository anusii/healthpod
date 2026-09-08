// This is a generated file - do not edit.
//
// Generated from analyser.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class AnalyseStatus extends $pb.ProtobufEnum {
  /// Never sent. Present because proto3 requires a zero value, and reading it
  /// means the reply came from a version that knows something this one does
  /// not.
  static const AnalyseStatus ANALYSE_STATUS_UNSPECIFIED =
      AnalyseStatus._(0, _omitEnumNames ? '' : 'ANALYSE_STATUS_UNSPECIFIED');

  /// The analysis ran and the result was published to the caller's Pod.
  static const AnalyseStatus ANALYSE_STATUS_COMPLETED =
      AnalyseStatus._(1, _omitEnumNames ? '' : 'ANALYSE_STATUS_COMPLETED');

  /// Abandoned part way through, because Cancel arrived.
  static const AnalyseStatus ANALYSE_STATUS_CANCELLED =
      AnalyseStatus._(2, _omitEnumNames ? '' : 'ANALYSE_STATUS_CANCELLED');

  /// Nothing to analyse: the caller has shared no readings the analyser can
  /// read. Not a failure — the usual cause is a share that has not been made.
  static const AnalyseStatus ANALYSE_STATUS_NO_DATA =
      AnalyseStatus._(3, _omitEnumNames ? '' : 'ANALYSE_STATUS_NO_DATA');

  /// The analyser tried and could not finish. `message` says why.
  static const AnalyseStatus ANALYSE_STATUS_FAILED =
      AnalyseStatus._(4, _omitEnumNames ? '' : 'ANALYSE_STATUS_FAILED');

  static const $core.List<AnalyseStatus> values = <AnalyseStatus>[
    ANALYSE_STATUS_UNSPECIFIED,
    ANALYSE_STATUS_COMPLETED,
    ANALYSE_STATUS_CANCELLED,
    ANALYSE_STATUS_NO_DATA,
    ANALYSE_STATUS_FAILED,
  ];

  static final $core.List<AnalyseStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static AnalyseStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AnalyseStatus._(super.value, super.name);
}

class CancelStatus extends $pb.ProtobufEnum {
  /// Never sent; see ANALYSE_STATUS_UNSPECIFIED.
  static const CancelStatus CANCEL_STATUS_UNSPECIFIED =
      CancelStatus._(0, _omitEnumNames ? '' : 'CANCEL_STATUS_UNSPECIFIED');

  /// A run for this Pod was in progress and has been told to stop.
  static const CancelStatus CANCEL_STATUS_STOPPED =
      CancelStatus._(1, _omitEnumNames ? '' : 'CANCEL_STATUS_STOPPED');

  /// Nothing was running for this Pod, so there was nothing to stop. The
  /// request is not held against a later run: an analysis nobody has asked for
  /// yet cannot have been cancelled.
  static const CancelStatus CANCEL_STATUS_NOTHING_RUNNING =
      CancelStatus._(2, _omitEnumNames ? '' : 'CANCEL_STATUS_NOTHING_RUNNING');

  /// The request was not acted on. `message` says why.
  static const CancelStatus CANCEL_STATUS_REFUSED =
      CancelStatus._(3, _omitEnumNames ? '' : 'CANCEL_STATUS_REFUSED');

  static const $core.List<CancelStatus> values = <CancelStatus>[
    CANCEL_STATUS_UNSPECIFIED,
    CANCEL_STATUS_STOPPED,
    CANCEL_STATUS_NOTHING_RUNNING,
    CANCEL_STATUS_REFUSED,
  ];

  static final $core.List<CancelStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static CancelStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CancelStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
