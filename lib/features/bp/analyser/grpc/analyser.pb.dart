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

import 'analyser.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'analyser.pbenum.dart';

class AnalyseRequest extends $pb.GeneratedMessage {
  factory AnalyseRequest({
    $core.String? webId,
    $core.int? sharedFileCount,
    $core.String? requestedAt,
  }) {
    final result = create();
    if (webId != null) result.webId = webId;
    if (sharedFileCount != null) result.sharedFileCount = sharedFileCount;
    if (requestedAt != null) result.requestedAt = requestedAt;
    return result;
  }

  AnalyseRequest._();

  factory AnalyseRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AnalyseRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AnalyseRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'healthpod.analyser.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'webId')
    ..aI(2, _omitFieldNames ? '' : 'sharedFileCount')
    ..aOS(3, _omitFieldNames ? '' : 'requestedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnalyseRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnalyseRequest copyWith(void Function(AnalyseRequest) updates) =>
      super.copyWith((message) => updates(message as AnalyseRequest))
          as AnalyseRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AnalyseRequest create() => AnalyseRequest._();
  @$core.override
  AnalyseRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AnalyseRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AnalyseRequest>(create);
  static AnalyseRequest? _defaultInstance;

  /// The Pod asking, as its WebID. The analysis reads every Pod that has
  /// shared data — the cohort figures need them all — but the chart and the
  /// published result are this Pod's.
  @$pb.TagNumber(1)
  $core.String get webId => $_getSZ(0);
  @$pb.TagNumber(1)
  set webId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWebId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWebId() => $_clearField(1);

  /// How many readings the caller granted access to just before calling.
  ///
  /// The analyser reports back how many it actually had in view, so an app can
  /// say `covered 9 of your 12 readings` when a grant has not yet propagated.
  /// Zero means the caller is not counting.
  @$pb.TagNumber(2)
  $core.int get sharedFileCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set sharedFileCount($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSharedFileCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearSharedFileCount() => $_clearField(2);

  /// When the app asked, as ISO 8601 in UTC. For the log only: the analyser
  /// times its own work.
  @$pb.TagNumber(3)
  $core.String get requestedAt => $_getSZ(2);
  @$pb.TagNumber(3)
  set requestedAt($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRequestedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearRequestedAt() => $_clearField(3);
}

class AnalyseReply extends $pb.GeneratedMessage {
  factory AnalyseReply({
    AnalyseStatus? status,
    $core.String? runId,
    $core.String? message,
    $core.String? resultUrl,
    $core.String? generatedAt,
    $core.int? podCount,
    $core.int? observationCount,
    $core.int? filesRead,
    $core.int? filesSkipped,
    $core.bool? published,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (runId != null) result.runId = runId;
    if (message != null) result.message = message;
    if (resultUrl != null) result.resultUrl = resultUrl;
    if (generatedAt != null) result.generatedAt = generatedAt;
    if (podCount != null) result.podCount = podCount;
    if (observationCount != null) result.observationCount = observationCount;
    if (filesRead != null) result.filesRead = filesRead;
    if (filesSkipped != null) result.filesSkipped = filesSkipped;
    if (published != null) result.published = published;
    return result;
  }

  AnalyseReply._();

  factory AnalyseReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AnalyseReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AnalyseReply',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'healthpod.analyser.v1'),
      createEmptyInstance: create)
    ..aE<AnalyseStatus>(1, _omitFieldNames ? '' : 'status',
        enumValues: AnalyseStatus.values)
    ..aOS(2, _omitFieldNames ? '' : 'runId')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..aOS(4, _omitFieldNames ? '' : 'resultUrl')
    ..aOS(5, _omitFieldNames ? '' : 'generatedAt')
    ..aI(6, _omitFieldNames ? '' : 'podCount')
    ..aI(7, _omitFieldNames ? '' : 'observationCount')
    ..aI(8, _omitFieldNames ? '' : 'filesRead')
    ..aI(9, _omitFieldNames ? '' : 'filesSkipped')
    ..aOB(10, _omitFieldNames ? '' : 'published')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnalyseReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnalyseReply copyWith(void Function(AnalyseReply) updates) =>
      super.copyWith((message) => updates(message as AnalyseReply))
          as AnalyseReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AnalyseReply create() => AnalyseReply._();
  @$core.override
  AnalyseReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AnalyseReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AnalyseReply>(create);
  static AnalyseReply? _defaultInstance;

  @$pb.TagNumber(1)
  AnalyseStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(AnalyseStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  /// The run that produced this, matching the run identifiers in the
  /// analyser's own result store.
  @$pb.TagNumber(2)
  $core.String get runId => $_getSZ(1);
  @$pb.TagNumber(2)
  set runId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRunId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRunId() => $_clearField(2);

  /// One line fit to show a user. Empty when there is nothing to add to
  /// `status`.
  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);

  /// Where the result was published in the Analyser Pod. The app can work this
  /// address out for itself, and does; carrying it means a change to the
  /// layout does not have to be made in two languages at once.
  @$pb.TagNumber(4)
  $core.String get resultUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set resultUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasResultUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearResultUrl() => $_clearField(4);

  /// When the analyser produced the result, as ISO 8601 in UTC. The app checks
  /// this against what was published before it called, so a result left by an
  /// earlier run is not mistaken for this one.
  @$pb.TagNumber(5)
  $core.String get generatedAt => $_getSZ(4);
  @$pb.TagNumber(5)
  set generatedAt($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGeneratedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearGeneratedAt() => $_clearField(5);

  /// How many Pods contributed to the cohort figures.
  @$pb.TagNumber(6)
  $core.int get podCount => $_getIZ(5);
  @$pb.TagNumber(6)
  set podCount($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPodCount() => $_has(5);
  @$pb.TagNumber(6)
  void clearPodCount() => $_clearField(6);

  /// How many of the caller's readings went into its own averages.
  @$pb.TagNumber(7)
  $core.int get observationCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set observationCount($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasObservationCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearObservationCount() => $_clearField(7);

  /// How many of the caller's shared files the analyser read, and how many it
  /// found but could not. Their sum is what the analyser had in view, which is
  /// what `shared_file_count` is compared against.
  @$pb.TagNumber(8)
  $core.int get filesRead => $_getIZ(7);
  @$pb.TagNumber(8)
  set filesRead($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFilesRead() => $_has(7);
  @$pb.TagNumber(8)
  void clearFilesRead() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get filesSkipped => $_getIZ(8);
  @$pb.TagNumber(9)
  set filesSkipped($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasFilesSkipped() => $_has(8);
  @$pb.TagNumber(9)
  void clearFilesSkipped() => $_clearField(9);

  /// Whether the result reached the caller's Pod. False with a COMPLETED
  /// status means the analysis worked but the hand-over of the key did not, so
  /// the app can fetch the result but not read it — worth saying plainly
  /// rather than leaving as a decryption failure.
  @$pb.TagNumber(10)
  $core.bool get published => $_getBF(9);
  @$pb.TagNumber(10)
  set published($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPublished() => $_has(9);
  @$pb.TagNumber(10)
  void clearPublished() => $_clearField(10);
}

class CancelRequest extends $pb.GeneratedMessage {
  factory CancelRequest({
    $core.String? webId,
    $core.String? requestedAt,
  }) {
    final result = create();
    if (webId != null) result.webId = webId;
    if (requestedAt != null) result.requestedAt = requestedAt;
    return result;
  }

  CancelRequest._();

  factory CancelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CancelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'healthpod.analyser.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'webId')
    ..aOS(2, _omitFieldNames ? '' : 'requestedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelRequest copyWith(void Function(CancelRequest) updates) =>
      super.copyWith((message) => updates(message as CancelRequest))
          as CancelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelRequest create() => CancelRequest._();
  @$core.override
  CancelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CancelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelRequest>(create);
  static CancelRequest? _defaultInstance;

  /// Whose analysis to stop. A run started by another Pod is not the caller's
  /// to abandon.
  @$pb.TagNumber(1)
  $core.String get webId => $_getSZ(0);
  @$pb.TagNumber(1)
  set webId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWebId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWebId() => $_clearField(1);

  /// When the app asked, as ISO 8601 in UTC. For the log only.
  @$pb.TagNumber(2)
  $core.String get requestedAt => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestedAt($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestedAt() => $_clearField(2);
}

class CancelReply extends $pb.GeneratedMessage {
  factory CancelReply({
    CancelStatus? status,
    $core.String? message,
    $core.String? runId,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (message != null) result.message = message;
    if (runId != null) result.runId = runId;
    return result;
  }

  CancelReply._();

  factory CancelReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CancelReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelReply',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'healthpod.analyser.v1'),
      createEmptyInstance: create)
    ..aE<CancelStatus>(1, _omitFieldNames ? '' : 'status',
        enumValues: CancelStatus.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'runId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelReply copyWith(void Function(CancelReply) updates) =>
      super.copyWith((message) => updates(message as CancelReply))
          as CancelReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelReply create() => CancelReply._();
  @$core.override
  CancelReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CancelReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelReply>(create);
  static CancelReply? _defaultInstance;

  @$pb.TagNumber(1)
  CancelStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(CancelStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  /// One line fit to show a user, when there is something to say.
  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  /// The run that was told to stop, when there was one.
  @$pb.TagNumber(3)
  $core.String get runId => $_getSZ(2);
  @$pb.TagNumber(3)
  set runId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRunId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRunId() => $_clearField(3);
}

class StatusRequest extends $pb.GeneratedMessage {
  factory StatusRequest() => create();

  StatusRequest._();

  factory StatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'healthpod.analyser.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusRequest copyWith(void Function(StatusRequest) updates) =>
      super.copyWith((message) => updates(message as StatusRequest))
          as StatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusRequest create() => StatusRequest._();
  @$core.override
  StatusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatusRequest>(create);
  static StatusRequest? _defaultInstance;
}

class StatusReply extends $pb.GeneratedMessage {
  factory StatusReply({
    $core.bool? ready,
    $core.String? analyserWebId,
    $core.int? activeRuns,
    $core.String? lastRunId,
    $core.String? lastRunAt,
    $core.String? message,
  }) {
    final result = create();
    if (ready != null) result.ready = ready;
    if (analyserWebId != null) result.analyserWebId = analyserWebId;
    if (activeRuns != null) result.activeRuns = activeRuns;
    if (lastRunId != null) result.lastRunId = lastRunId;
    if (lastRunAt != null) result.lastRunAt = lastRunAt;
    if (message != null) result.message = message;
    return result;
  }

  StatusReply._();

  factory StatusReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatusReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusReply',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'healthpod.analyser.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ready')
    ..aOS(2, _omitFieldNames ? '' : 'analyserWebId')
    ..aI(3, _omitFieldNames ? '' : 'activeRuns')
    ..aOS(4, _omitFieldNames ? '' : 'lastRunId')
    ..aOS(5, _omitFieldNames ? '' : 'lastRunAt')
    ..aOS(6, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusReply copyWith(void Function(StatusReply) updates) =>
      super.copyWith((message) => updates(message as StatusReply))
          as StatusReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusReply create() => StatusReply._();
  @$core.override
  StatusReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StatusReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatusReply>(create);
  static StatusReply? _defaultInstance;

  /// Whether the analyser can take an Analyse call. False while it is still
  /// starting up or cannot unlock its own Pod.
  @$pb.TagNumber(1)
  $core.bool get ready => $_getBF(0);
  @$pb.TagNumber(1)
  set ready($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReady() => $_has(0);
  @$pb.TagNumber(1)
  void clearReady() => $_clearField(1);

  /// Which Analyser Pod this service acts as, so an app can check it is
  /// talking to the analyser it shared with.
  @$pb.TagNumber(2)
  $core.String get analyserWebId => $_getSZ(1);
  @$pb.TagNumber(2)
  set analyserWebId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAnalyserWebId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAnalyserWebId() => $_clearField(2);

  /// How many analyses are in progress.
  @$pb.TagNumber(3)
  $core.int get activeRuns => $_getIZ(2);
  @$pb.TagNumber(3)
  set activeRuns($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasActiveRuns() => $_has(2);
  @$pb.TagNumber(3)
  void clearActiveRuns() => $_clearField(3);

  /// The most recent run, and when it finished, as ISO 8601 in UTC. Empty when
  /// the analyser has not run since it started.
  @$pb.TagNumber(4)
  $core.String get lastRunId => $_getSZ(3);
  @$pb.TagNumber(4)
  set lastRunId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLastRunId() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastRunId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get lastRunAt => $_getSZ(4);
  @$pb.TagNumber(5)
  set lastRunAt($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLastRunAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastRunAt() => $_clearField(5);

  /// Why the analyser is not ready, when it is not.
  @$pb.TagNumber(6)
  $core.String get message => $_getSZ(5);
  @$pb.TagNumber(6)
  set message($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMessage() => $_has(5);
  @$pb.TagNumber(6)
  void clearMessage() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
