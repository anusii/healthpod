// This is a generated file - do not edit.
//
// Generated from analyser.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'analyser.pb.dart' as $0;

export 'analyser.pb.dart';

@$pb.GrpcServiceName('healthpod.analyser.v1.Analyser')
class AnalyserClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  AnalyserClient(super.channel, {super.options, super.interceptors});

  /// Analyse the caller's readings now, and answer when the result has been
  /// published back to the caller's Pod.
  ///
  /// Long-running by design: the reply says what happened, so the app needs no
  /// second call and no polling. A client that stops waiting should cancel the
  /// call and send Cancel, which are different things — see CancelRequest.
  $grpc.ResponseFuture<$0.AnalyseReply> analyse(
    $0.AnalyseRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$analyse, request, options: options);
  }

  /// Abandon the analysis running for the caller.
  ///
  /// Answers immediately, whether or not there was anything to stop. The run
  /// itself stops at its next checkpoint, which is typically within a second.
  $grpc.ResponseFuture<$0.CancelReply> cancel(
    $0.CancelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancel, request, options: options);
  }

  /// Whether the analyser is up, and what it is doing.
  ///
  /// Cheap and unauthenticated: it reads no Pod and holds up no analysis, so
  /// an app can call it before offering to analyse at all.
  $grpc.ResponseFuture<$0.StatusReply> status(
    $0.StatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$status, request, options: options);
  }

  // method descriptors

  static final _$analyse =
      $grpc.ClientMethod<$0.AnalyseRequest, $0.AnalyseReply>(
          '/healthpod.analyser.v1.Analyser/Analyse',
          ($0.AnalyseRequest value) => value.writeToBuffer(),
          $0.AnalyseReply.fromBuffer);
  static final _$cancel = $grpc.ClientMethod<$0.CancelRequest, $0.CancelReply>(
      '/healthpod.analyser.v1.Analyser/Cancel',
      ($0.CancelRequest value) => value.writeToBuffer(),
      $0.CancelReply.fromBuffer);
  static final _$status = $grpc.ClientMethod<$0.StatusRequest, $0.StatusReply>(
      '/healthpod.analyser.v1.Analyser/Status',
      ($0.StatusRequest value) => value.writeToBuffer(),
      $0.StatusReply.fromBuffer);
}

@$pb.GrpcServiceName('healthpod.analyser.v1.Analyser')
abstract class AnalyserServiceBase extends $grpc.Service {
  $core.String get $name => 'healthpod.analyser.v1.Analyser';

  AnalyserServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.AnalyseRequest, $0.AnalyseReply>(
        'Analyse',
        analyse_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AnalyseRequest.fromBuffer(value),
        ($0.AnalyseReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CancelRequest, $0.CancelReply>(
        'Cancel',
        cancel_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CancelRequest.fromBuffer(value),
        ($0.CancelReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StatusRequest, $0.StatusReply>(
        'Status',
        status_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StatusRequest.fromBuffer(value),
        ($0.StatusReply value) => value.writeToBuffer()));
  }

  $async.Future<$0.AnalyseReply> analyse_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AnalyseRequest> $request) async {
    return analyse($call, await $request);
  }

  $async.Future<$0.AnalyseReply> analyse(
      $grpc.ServiceCall call, $0.AnalyseRequest request);

  $async.Future<$0.CancelReply> cancel_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.CancelRequest> $request) async {
    return cancel($call, await $request);
  }

  $async.Future<$0.CancelReply> cancel(
      $grpc.ServiceCall call, $0.CancelRequest request);

  $async.Future<$0.StatusReply> status_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.StatusRequest> $request) async {
    return status($call, await $request);
  }

  $async.Future<$0.StatusReply> status(
      $grpc.ServiceCall call, $0.StatusRequest request);
}
