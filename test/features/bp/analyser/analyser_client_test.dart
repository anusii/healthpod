/// Tests for asking the analyser to analyse, and asking it to stop.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Tony Chen

library;

// A real gRPC server, on a loopback port the operating system picks, serving
// the same generated bindings the analyser serves. That is worth the setup:
// the interesting parts of the client are what it does when a call does not
// come back the ordinary way — the analyser is not running, the request is
// refused, the user cancels part way through — and none of those can be
// exercised by mocking the stub, which is where they would be papered over.
//
// The analyser's own half is covered by
// `analyser/bp_analyser/tests/test_pipeline.py`, which drives the real
// handlers against an in-memory Pod server.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart' as grpc;

import 'package:healthpod/features/bp/analyser/analyser_client.dart';
import 'package:healthpod/features/bp/analyser/grpc/analyser.pbgrpc.dart';

const alice = 'https://solid.dev.empwr.au/alice/profile/card#me';
const analyserWebId = 'https://solid.dev.empwr.au/Analyser/profile/card#me';

/// An analyser that answers however the test in hand needs it to.

class FakeAnalyser extends AnalyserServiceBase {
  FakeAnalyser({
    this.ready = true,
    this.webId = analyserWebId,
    this.reply,
    this.holdAnalysis = false,
  });

  /// What Status says.

  bool ready;
  String webId;

  /// What Analyse answers with, when it answers at all.

  AnalyseReply? reply;

  /// Whether Analyse waits to be released rather than answering.
  ///
  /// For the cancellation tests: the client has to have a call genuinely in
  /// flight for there to be anything to abandon.

  bool holdAnalysis;

  final held = Completer<void>();

  /// Every request the server saw, so a test can check what went out as well
  /// as what came back.

  final analyseRequests = <AnalyseRequest>[];
  final cancelRequests = <CancelRequest>[];

  @override
  Future<AnalyseReply> analyse(
    grpc.ServiceCall call,
    AnalyseRequest request,
  ) async {
    analyseRequests.add(request);
    if (holdAnalysis) await held.future;

    return reply ??
        AnalyseReply(
          status: AnalyseStatus.ANALYSE_STATUS_COMPLETED,
          runId: '20260908T101500Z',
          resultUrl: 'https://solid.dev.empwr.au/Analyser/healthpod/data/'
              'analyser/solid.dev.empwr.au-alice/bp-average.json.enc.ttl',
          generatedAt: '2026-09-08T10:15:00+00:00',
          podCount: 3,
          observationCount: 12,
          filesRead: 12,
          published: true,
        );
  }

  @override
  Future<CancelReply> cancel(
    grpc.ServiceCall call,
    CancelRequest request,
  ) async {
    cancelRequests.add(request);
    if (!held.isCompleted) held.complete();

    return CancelReply(status: CancelStatus.CANCEL_STATUS_STOPPED);
  }

  @override
  Future<StatusReply> status(
    grpc.ServiceCall call,
    StatusRequest request,
  ) async =>
      StatusReply(
        ready: ready,
        analyserWebId: webId,
        message: ready ? '' : 'the analyser has not connected yet',
      );
}

void main() {
  group('Talking to an analyser that is there', () {
    late FakeAnalyser analyser;
    late grpc.Server server;
    late BPAnalyserClient client;

    setUp(() async {
      analyser = FakeAnalyser();
      server = grpc.Server.create(services: [analyser]);
      await server.serve(address: '127.0.0.1', port: 0);
      client = BPAnalyserClient.to(host: '127.0.0.1', port: server.port!);
    });

    tearDown(() async {
      await client.close();
      await server.shutdown();
    });

    test('an analysis comes back with what the analyser computed', () async {
      final run = await client.analyse(webId: alice, sharedFileCount: 12);

      expect(run.outcome, AnalyserCallOutcome.answered);
      expect(run.succeeded, isTrue);
      expect(run.observationCount, 12);
      expect(run.podCount, 3);
      expect(run.filesRead, 12);
      expect(run.published, isTrue);
      expect(run.runId, '20260908T101500Z');
    });

    test('the analysis carries the timestamp the result must match', () async {
      // The app reads the published result and checks this against what it
      // finds, which is how it knows it has this run's answer rather than an
      // earlier one still sitting at the address.

      final run = await client.analyse(webId: alice, sharedFileCount: 12);

      expect(run.generatedAt, DateTime.utc(2026, 9, 8, 10, 15));
      expect(run.generatedAt!.isUtc, isTrue);
    });

    test('the request names the Pod asking', () async {
      // The whole point of the change: the analyser analyses for a caller
      // rather than for everybody who has ever shared.

      await client.analyse(webId: alice, sharedFileCount: 12);

      expect(analyser.analyseRequests.single.webId, alice);
    });

    test('the request says how many readings went out', () async {
      // Compared against what the analyser reports it had in view, which is
      // how a complete analysis is told from one that ran before the last
      // grant landed.

      await client.analyse(webId: alice, sharedFileCount: 9);

      expect(analyser.analyseRequests.single.sharedFileCount, 9);
    });

    test('the request is timestamped in UTC', () async {
      await client.analyse(webId: alice, sharedFileCount: 1);

      final stamp = analyser.analyseRequests.single.requestedAt;
      expect(DateTime.parse(stamp).isUtc, isTrue);
    });

    test('how much the analyser saw is read off the reply', () async {
      analyser.reply = AnalyseReply(
        status: AnalyseStatus.ANALYSE_STATUS_COMPLETED,
        filesRead: 9,
        filesSkipped: 1,
        published: true,
      );

      final run = await client.analyse(webId: alice, sharedFileCount: 12);

      expect(run.sourcesSeen, 10);
    });

    test('a published result that could not be handed over is flagged',
        () async {
      // The figures exist and cannot be read, which from the app's side would
      // otherwise surface as a decryption failure.

      analyser.reply = AnalyseReply(
        status: AnalyseStatus.ANALYSE_STATUS_COMPLETED,
        published: false,
        message: 'the key did not reach your Pod',
      );

      final run = await client.analyse(webId: alice, sharedFileCount: 12);

      expect(run.succeeded, isTrue);
      expect(run.published, isFalse);
      expect(run.message, 'the key did not reach your Pod');
    });

    test('a caller who shared nothing is told, not failed', () async {
      analyser.reply =
          AnalyseReply(status: AnalyseStatus.ANALYSE_STATUS_NO_DATA);

      final run = await client.analyse(webId: alice, sharedFileCount: 0);

      expect(run.outcome, AnalyserCallOutcome.answered);
      expect(run.succeeded, isFalse);
      expect(run.status, AnalyseStatus.ANALYSE_STATUS_NO_DATA);
    });

    test('the status says which Analyser Pod the service acts for', () async {
      // Checked against the Pod the app shares with, so being pointed at one
      // analyser and sharing with another is caught before anything is
      // granted rather than showing up as an analysis that finds no data.

      final status = await client.status();

      expect(status.available, isTrue);
      expect(status.analyserWebId, analyserWebId);
    });

    test('an analyser that is not ready says so and why', () async {
      analyser.ready = false;

      final status = await client.status();

      expect(status.outcome, AnalyserCallOutcome.answered);
      expect(status.available, isFalse);
      expect(status.message, isNotNull);
    });

    test('a cancellation names the Pod whose analysis to stop', () async {
      final outcome = await client.cancel(webId: alice);

      expect(outcome.stopped, isTrue);
      expect(analyser.cancelRequests.single.webId, alice);
    });
  });

  group('Cancelling an analysis in flight', () {
    late FakeAnalyser analyser;
    late grpc.Server server;
    late BPAnalyserClient client;

    setUp(() async {
      analyser = FakeAnalyser(holdAnalysis: true);
      server = grpc.Server.create(services: [analyser]);
      await server.serve(address: '127.0.0.1', port: 0);
      client = BPAnalyserClient.to(host: '127.0.0.1', port: server.port!);
    });

    tearDown(() async {
      await client.close();
      await server.shutdown();
    });

    test('abandoning the call frees the app without waiting for the analysis',
        () async {
      // The analyser here never answers of its own accord, so this returning
      // at all is the test: the app is not held by an analysis nobody wants.

      final analysis = client.analyse(webId: alice, sharedFileCount: 12);
      await pumpEventQueue();

      client.abandon();
      final run = await analysis;

      expect(run.cancelled, isTrue);
      expect(run.outcome, AnalyserCallOutcome.abandoned);
      expect(run.succeeded, isFalse);
    });

    test('the analyser is told as well, on the same connection', () async {
      // Abandoning the call says nothing to the analyser, which would carry
      // on working. Both halves happen, and this is the one the user is
      // actually asking about.

      final analysis = client.analyse(webId: alice, sharedFileCount: 12);
      await pumpEventQueue();

      final outcome = await client.cancel(webId: alice);
      client.abandon();
      await analysis;

      expect(outcome.stopped, isTrue);
      expect(analyser.cancelRequests.single.webId, alice);
    });

    test('abandoning nothing is harmless', () {
      // The button can reach this with no analysis in flight, between the
      // reply arriving and the phase changing.

      expect(client.abandon, returnsNormally);
    });
  });

  group('Talking to an analyser that is not there', () {
    test('a call to a dead port reports it as unreachable', () async {
      // Almost always means the analyser is not running, which is a different
      // thing to say to the user than "the request failed".

      final server = grpc.Server.create(services: [FakeAnalyser()]);
      await server.serve(address: '127.0.0.1', port: 0);
      final port = server.port!;
      await server.shutdown();

      final client = BPAnalyserClient.to(host: '127.0.0.1', port: port);
      final status = await client.status();
      await client.close();

      expect(status.outcome, AnalyserCallOutcome.unreachable);
      expect(status.available, isFalse);
      expect(status.message, contains('not answering'));
    });

    test('nothing was started, and the message says so', () async {
      final server = grpc.Server.create(services: [FakeAnalyser()]);
      await server.serve(address: '127.0.0.1', port: 0);
      final port = server.port!;
      await server.shutdown();

      final client = BPAnalyserClient.to(host: '127.0.0.1', port: port);
      final run = await client.analyse(webId: alice, sharedFileCount: 12);
      await client.close();

      expect(run.outcome, AnalyserCallOutcome.unreachable);
      expect(run.message, contains('no analysis was started'));
    });
  });

  group('Sorting out what went wrong', () {
    // Matched on text, because the native channel and the grpc-web one raise
    // different types for the same conditions. That makes it the fragile part
    // of the client, and worth pinning.

    test('an unavailable service is unreachable', () {
      expect(
        BPAnalyserClient.classify(
          const grpc.GrpcError.unavailable('Connection refused'),
        ),
        AnalyserCallOutcome.unreachable,
      );
    });

    test('a host that does not resolve is unreachable', () {
      expect(
        BPAnalyserClient.classify(
          const SocketExceptionStandIn('Failed host lookup: nowhere'),
        ),
        AnalyserCallOutcome.unreachable,
      );
    });

    test('a rejected token is a refusal, not a failure', () {
      // Nothing the user can do about it, and nothing a retry will fix, so
      // this must not read as a transient error.

      expect(
        BPAnalyserClient.classify(
          const grpc.GrpcError.unauthenticated('no token'),
        ),
        AnalyserCallOutcome.refused,
      );
    });

    test('a cancelled call is not an error at all', () {
      expect(
        BPAnalyserClient.classify(const grpc.GrpcError.cancelled()),
        AnalyserCallOutcome.abandoned,
      );
    });

    test('anything else is a plain failure', () {
      expect(
        BPAnalyserClient.classify(const grpc.GrpcError.internal('went wrong')),
        AnalyserCallOutcome.failed,
      );
    });
  });

  group('What a cancellation counts as', () {
    test('a stopped analysis is stopped', () {
      expect(
        const AnalyserCancel(
          outcome: AnalyserCallOutcome.answered,
          status: CancelStatus.CANCEL_STATUS_STOPPED,
        ).stopped,
        isTrue,
      );
    });

    test('nothing to stop counts as stopped too', () {
      // What the user is asking is whether an analysis is still running on
      // the server. In neither case is one.

      expect(
        const AnalyserCancel(
          outcome: AnalyserCallOutcome.answered,
          status: CancelStatus.CANCEL_STATUS_NOTHING_RUNNING,
        ).stopped,
        isTrue,
      );
    });

    test('a request that never arrived is not stopped', () {
      // The app stops waiting either way, so the user is not stuck; what
      // failed is the half they cannot see, and claiming otherwise would be
      // claiming something about a server that was never reached.

      expect(
        const AnalyserCancel(outcome: AnalyserCallOutcome.unreachable).stopped,
        isFalse,
      );
    });

    test('a refusal is not stopped', () {
      expect(
        const AnalyserCancel(outcome: AnalyserCallOutcome.refused).stopped,
        isFalse,
      );
    });

    test('every outcome but an answer is a failure', () {
      // A new outcome added later defaults to being reported as a failure,
      // which is the safe direction: never claim the analyser stopped.

      final stopped = AnalyserCallOutcome.values.where(
        (outcome) => AnalyserCancel(
          outcome: outcome,
          status: CancelStatus.CANCEL_STATUS_STOPPED,
        ).stopped,
      );

      expect(stopped, [AnalyserCallOutcome.answered]);
    });
  });
}

/// A stand-in for the socket failure the native channel raises.
///
/// `SocketException` comes from `dart:io`, which this test would then have to
/// import to build one; the classifier reads the text, so the text is all
/// that needs to be right.

class SocketExceptionStandIn implements Exception {
  const SocketExceptionStandIn(this.message);

  final String message;

  @override
  String toString() => 'SocketException: $message';
}
