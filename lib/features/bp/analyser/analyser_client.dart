/// Asking the analyser for an analysis, and asking it to stop.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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

// The analyser used to be asked for nothing at all. Readings were shared with
// its Pod, and a service on the server noticed at its next poll — up to half a
// minute later — read every contributing Pod, published a result to each of
// them, and the app watched its own Pod until one appeared that looked new
// enough to be its own. Cancelling went the same way round: a small JSON file
// written into the one folder the Analyser Pod leaves publicly writable, and
// the app then watched for it to disappear, which took anything up to forty
// seconds to answer and often could not answer at all.
//
// Now the app asks. Sharing has not changed — that is what gives the analyser
// the keys, and it is still the app granting read access one reading at a time
// — but the moment that is done, this makes one call and the analysis runs
// inside it. The reply is the finished analysis: what it computed, and where
// in the Analyser Pod the result was published for this Pod to read.
//
// Three calls, and what each is for:
//
//   * `status()` before sharing, because sharing is the expensive and
//     irreversible half. Granting a dozen permissions and then finding the
//     analyser is not running is the worst way round to learn it.
//
//   * `analyse()` after sharing, awaited for as long as the analysis takes.
//
//   * `cancel()` while `analyse()` is in flight, from another user gesture.
//     Two separate things happen: `abandon()` drops the call so the app stops
//     waiting at once, and `cancel()` tells the analyser to stop working. The
//     second is the one the user is really asking about, and it is why this
//     does not simply cancel the call and walk away.
//
// One client per analysis, closed when it ends. The channel is a socket and a
// handshake, which is nothing beside an analysis, and a client that lives no
// longer than the run it serves cannot leak one.

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

import 'package:grpc/service_api.dart'
    show CallOptions, ClientChannel, ResponseFuture;

import 'package:healthpod/constants/analyser.dart';
import 'package:healthpod/features/bp/analyser/channel.dart';
import 'package:healthpod/features/bp/analyser/grpc/analyser.pbgrpc.dart';

// The two status enums are part of what this hands back, so they are part of
// its surface: a caller reading `AnalyserRun.status` should not have to reach
// past this into the generated bindings to name what it finds there.

export 'package:healthpod/features/bp/analyser/grpc/analyser.pbgrpc.dart'
    show AnalyseStatus, CancelStatus;

/// How a request to the analyser ended, for any of the three calls.

enum AnalyserCallOutcome {
  /// The analyser answered, and the answer is in hand.

  answered,

  /// Nothing is listening. Almost always the analyser is not running.

  unreachable,

  /// The analyser refused the call: the wrong shared secret, or none.

  refused,

  /// The call was abandoned from this end, by [BPAnalyserClient.abandon].

  abandoned,

  /// Anything else — a broken connection, a reply that made no sense.

  failed,
}

/// What became of an analysis asked for over gRPC.

class AnalyserRun {
  const AnalyserRun({
    required this.outcome,
    this.status = AnalyseStatus.ANALYSE_STATUS_UNSPECIFIED,
    this.runId = '',
    this.resultUrl = '',
    this.generatedAt,
    this.observationCount = 0,
    this.podCount = 0,
    this.filesRead = 0,
    this.filesSkipped = 0,
    this.published = false,
    this.message,
  });

  /// Whether the analyser answered at all, and if not, why.

  final AnalyserCallOutcome outcome;

  /// What the analyser made of the request, when it answered.

  final AnalyseStatus status;

  /// The run that produced this, matching the analyser's own log.

  final String runId;

  /// Where the result was published in the Analyser Pod.
  ///
  /// The app can work this address out for itself, and does — see
  /// `BPAnalyserResultService.resultUrl` — so this is a cross-check rather
  /// than the source of truth. A mismatch means the two halves disagree about
  /// the layout, which is worth knowing in a log.

  final String resultUrl;

  /// When the analyser produced the result, in UTC.
  ///
  /// The app reads the published result and checks this against what it finds,
  /// which is how it knows it is looking at this run's answer rather than an
  /// earlier one that has not been overwritten yet.

  final DateTime? generatedAt;

  /// How many of this Pod's readings went into its averages.

  final int observationCount;

  /// How many Pods contributed to the cohort figures.

  final int podCount;

  /// How many of this Pod's shared files the analyser read, and how many it
  /// found but could not.

  final int filesRead;
  final int filesSkipped;

  /// Whether the result reached this Pod.
  ///
  /// False with a completed analysis means the figures exist but the key for
  /// them did not arrive, so the result can be fetched and not read. Worth
  /// saying plainly rather than letting it surface as a decryption failure.

  final bool published;

  /// What the analyser said, when it said anything.

  final String? message;

  /// Whether there is a published result to go and read.

  bool get succeeded =>
      outcome == AnalyserCallOutcome.answered &&
      status == AnalyseStatus.ANALYSE_STATUS_COMPLETED;

  /// Whether the analyser stopped because it was asked to.

  bool get cancelled =>
      outcome == AnalyserCallOutcome.abandoned ||
      status == AnalyseStatus.ANALYSE_STATUS_CANCELLED;

  /// How many shared files the analyser had in view.
  ///
  /// Every file it found was either read or skipped, so their sum says how
  /// much of the Pod the result covers. Compared against the number of
  /// readings the app shared, it is what tells a complete analysis from one
  /// that ran before the last grant had landed.

  int get sourcesSeen => filesRead + filesSkipped;
}

/// What became of a request to stop.

class AnalyserCancel {
  const AnalyserCancel({
    required this.outcome,
    this.status = CancelStatus.CANCEL_STATUS_UNSPECIFIED,
    this.message,
  });

  final AnalyserCallOutcome outcome;
  final CancelStatus status;
  final String? message;

  /// Whether the analyser has stopped, or had nothing to stop.
  ///
  /// Both count: what the user is asking is whether an analysis is still
  /// running on the server, and in neither case is one. A request that never
  /// arrived is a different matter and is not this.

  bool get stopped =>
      outcome == AnalyserCallOutcome.answered &&
      (status == CancelStatus.CANCEL_STATUS_STOPPED ||
          status == CancelStatus.CANCEL_STATUS_NOTHING_RUNNING);
}

/// Whether the analyser is up, and what it is doing.

class AnalyserStatus {
  const AnalyserStatus({
    required this.outcome,
    this.ready = false,
    this.analyserWebId = '',
    this.activeRuns = 0,
    this.message,
  });

  final AnalyserCallOutcome outcome;

  /// Whether it can take an analysis. False while it is starting up, or when
  /// it cannot unlock its own Pod.

  final bool ready;

  /// Which Analyser Pod it acts as. Checked against [Analyser.webId], so an
  /// app pointed at one analyser and sharing with another finds out before it
  /// grants anything.

  final String analyserWebId;

  /// How many analyses it has in hand. A non-zero count means this one waits.

  final int activeRuns;

  final String? message;

  /// Whether it answered and is ready to work.

  bool get available => outcome == AnalyserCallOutcome.answered && ready;
}

/// The analyser, as this app talks to it.
///
/// Built for one analysis and closed after it. [close] must be called, which
/// the caller does in a `finally`: an unclosed channel keeps a socket open for
/// the life of the app.

class BPAnalyserClient {
  BPAnalyserClient._(this._channel) : _stub = AnalyserClient(_channel);

  /// Opens a channel to the analyser named in [Analyser].

  factory BPAnalyserClient.connect() => BPAnalyserClient.to(
        host: Analyser.grpcHost,
        port: Analyser.grpcPort,
        secure: Analyser.grpcSecure,
      );

  /// Opens a channel to an analyser at a given address.
  ///
  /// For the tests, which stand a real gRPC server up on a loopback port and
  /// drive this against it. Everything else uses [BPAnalyserClient.connect],
  /// which is this with the configured address filled in.

  @visibleForTesting
  factory BPAnalyserClient.to({
    required String host,
    required int port,
    bool secure = false,
  }) =>
      BPAnalyserClient._(
        createAnalyserChannel(host: host, port: port, secure: secure),
      );

  /// How long to allow for one analysis.
  ///
  /// The analyser has its own deadline — `grpc.analysis_timeout_seconds`,
  /// five minutes by default — and answers when it passes. This is the
  /// backstop for the analyser going away mid-call, so it sits beyond that:
  /// giving up first would leave the app reporting a timeout for an analysis
  /// that was about to answer.

  static const Duration analysisTimeout = Duration(minutes: 6);

  /// How long to allow for the two calls answered out of memory.

  static const Duration controlTimeout = Duration(seconds: 10);

  final ClientChannel _channel;
  final AnalyserClient _stub;

  /// The analysis while it is in flight, so [abandon] can drop it.

  ResponseFuture<AnalyseReply>? _inFlight;

  /// The shared secret, on every call, or nothing when none is configured.

  CallOptions _options(Duration timeout) => CallOptions(
        timeout: timeout,
        metadata: Analyser.grpcToken.isEmpty
            ? const {}
            : {'authorization': 'Bearer ${Analyser.grpcToken}'},
      );

  /// Asks whether the analyser is up, before anything is shared with it.

  Future<AnalyserStatus> status() async {
    try {
      final reply = await _stub.status(
        StatusRequest(),
        options: _options(controlTimeout),
      );

      return AnalyserStatus(
        outcome: AnalyserCallOutcome.answered,
        ready: reply.ready,
        analyserWebId: reply.analyserWebId,
        activeRuns: reply.activeRuns,
        message: reply.message.isEmpty ? null : reply.message,
      );
    } catch (e) {
      final outcome = classify(e);
      debugPrint('Could not reach the analyser at $_address: $e');

      return AnalyserStatus(outcome: outcome, message: _explain(outcome));
    }
  }

  /// Runs an analysis for [webId] and waits for it to finish.
  ///
  /// [sharedFileCount] is how many readings were just granted, which the
  /// analyser logs and reports back against so the app can tell a complete
  /// analysis from one that ran before the last grant landed.
  ///
  /// Does not throw. Every way this can fail is something the user is owed a
  /// sentence about, and an exception would leave the caller writing that
  /// sentence in two places.

  Future<AnalyserRun> analyse({
    required String webId,
    required int sharedFileCount,
  }) async {
    final call = _stub.analyse(
      AnalyseRequest(
        webId: webId,
        sharedFileCount: sharedFileCount,
        requestedAt: DateTime.now().toUtc().toIso8601String(),
      ),
      options: _options(analysisTimeout),
    );
    _inFlight = call;

    try {
      final reply = await call;

      return AnalyserRun(
        outcome: AnalyserCallOutcome.answered,
        status: reply.status,
        runId: reply.runId,
        resultUrl: reply.resultUrl,
        generatedAt: DateTime.tryParse(reply.generatedAt)?.toUtc(),
        observationCount: reply.observationCount,
        podCount: reply.podCount,
        filesRead: reply.filesRead,
        filesSkipped: reply.filesSkipped,
        published: reply.published,
        message: reply.message.isEmpty ? null : reply.message,
      );
    } catch (e) {
      final outcome = classify(e);
      debugPrint('The analysis at $_address failed: $e');

      return AnalyserRun(outcome: outcome, message: _explain(outcome));
    } finally {
      _inFlight = null;
    }
  }

  /// Drops the analysis in flight, so the app stops waiting at once.
  ///
  /// This is half of cancelling and the lesser half: it frees the app and says
  /// nothing to the analyser, which carries on. [cancel] is the other half.

  void abandon() {
    final call = _inFlight;
    if (call == null) return;
    _inFlight = null;
    call.cancel();
  }

  /// Asks the analyser to abandon the analysis it is running for [webId].
  ///
  /// Answered out of memory by the process doing the work, so this comes back
  /// in milliseconds whether or not there was anything to stop. The run itself
  /// ends at its next checkpoint, which is between two steps of the cycle
  /// rather than in the middle of one — nothing is left half written.

  Future<AnalyserCancel> cancel({required String webId}) async {
    try {
      final reply = await _stub.cancel(
        CancelRequest(
          webId: webId,
          requestedAt: DateTime.now().toUtc().toIso8601String(),
        ),
        options: _options(controlTimeout),
      );

      return AnalyserCancel(
        outcome: AnalyserCallOutcome.answered,
        status: reply.status,
        message: reply.message.isEmpty ? null : reply.message,
      );
    } catch (e) {
      final outcome = classify(e);
      debugPrint('Could not ask the analyser at $_address to stop: $e');

      return AnalyserCancel(
        outcome: outcome,
        message: 'Could not ask the ${Analyser.displayName} to stop, so the '
            'analysis was only stopped in this app.',
      );
    }
  }

  /// Closes the channel. Safe to call more than once.

  Future<void> close() async {
    // `shutdown` waits for calls in flight, and an abandoned analysis is not
    // one worth waiting for; `terminate` ends them. A caller that wants a
    // reply has already awaited it by the time it gets here.

    try {
      await _channel.terminate();
    } catch (e) {
      debugPrint('Could not close the channel to $_address: $e');
    }
  }

  String get _address => '${Analyser.grpcHost}:${Analyser.grpcPort}';

  /// Sorts a failure into the handful of cases worth telling apart.
  ///
  /// Visible for testing because it is the fragile part of this file: what it
  /// matches on is text, and a wrong answer here turns "the analyser is not
  /// running" into "the request failed", which sends the user looking in the
  /// wrong place.
  ///
  /// Matched on the status name rather than the class, so this compiles the
  /// same against the native channel and the grpc-web one: they raise
  /// different types for the same conditions.

  @visibleForTesting
  static AnalyserCallOutcome classify(Object error) {
    final text = '$error';

    if (text.contains('UNAVAILABLE') ||
        text.contains('Connection refused') ||
        text.contains('SocketException') ||
        text.contains('Failed host lookup')) {
      return AnalyserCallOutcome.unreachable;
    }
    if (text.contains('UNAUTHENTICATED') ||
        text.contains('PERMISSION_DENIED')) {
      return AnalyserCallOutcome.refused;
    }
    if (text.contains('CANCELLED')) return AnalyserCallOutcome.abandoned;

    return AnalyserCallOutcome.failed;
  }

  /// One sentence for the user, for a call that did not get an answer.

  static String? _explain(AnalyserCallOutcome outcome) => switch (outcome) {
        AnalyserCallOutcome.unreachable =>
          'The ${Analyser.displayName} is not answering, so no analysis was '
              'started. It may not be running.',
        AnalyserCallOutcome.refused =>
          'The ${Analyser.displayName} would not accept the request from this '
              'app.',
        AnalyserCallOutcome.failed =>
          'The request to the ${Analyser.displayName} failed.',
        _ => null,
      };
}
