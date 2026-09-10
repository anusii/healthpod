"""The gRPC interface an app calls to start an analysis.

Copyright (C) 2026, Software Innovation Institute, ANU.

Licensed under the GNU General Public License, Version 3 (the "License").

License: https://opensource.org/license/gpl-3-0.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see https://opensource.org/license/gpl-3-0.

Authors: Tony Chen
"""

# This is the whole of the trigger, and it replaced a watcher.
#
# The watcher polled the Analyser Pod's `shared/shared-keys.ttl` every thirty
# seconds and ran a cycle whenever its entity tag changed. Correct, and slow
# in three separate ways: the user waited up to a poll for the analysis to
# begin, the cycle then computed and published for every contributing Pod
# rather than for the one who asked, and a cancellation had to travel the same
# road backwards — a marker file in the Pod, collected on the next poll.
#
# Now the app calls Analyse when the user taps the button. The analysis starts
# in that handler, and the reply is the finished result. Nothing polls, and
# cancelling is a second call on the same connection.
#
# Two things the handler owes the caller, and neither is obvious:
#
#   - analyses are serialised. One `SolidClient` and one set of unlocked Pod
#     keys are shared by every call, and running two cycles through them at
#     once is not something this code has any business promising. A second
#     Analyse waits for the first, and can be cancelled while it waits.
#
#   - the answer is always an AnalyseReply, never a gRPC error, for anything
#     the caller could act on: no data shared, cancelled, the analysis failed.
#     An error status is reserved for the call being wrong — a missing WebID,
#     a bad token — because that is the only case where the app has nothing to
#     show a user.

from __future__ import annotations

import logging
import signal
import threading
import time
from concurrent import futures
from dataclasses import dataclass, field
from types import FrameType

import grpc

from . import analyser_pb2 as pb
from . import analyser_pb2_grpc as pb_grpc
from . import store
from .config import Config, ConfigError
from .keys import KeyStoreError
from .service import AnalyserService, CycleCancelled
from .solid_client import SolidError

log = logging.getLogger(__name__)

# How long a shutdown waits for the analysis in hand to reach a checkpoint
# before the process goes anyway. A cycle checks between steps, and the
# longest step is reading one Pod.

GRACE_SECONDS = 30.0


@dataclass
class _Run:
    """One analysis, queued or in progress.

    The `cancelled` reason is set by a Cancel call and read by the cycle at
    its next checkpoint. A plain attribute rather than an Event because the
    reason travels with it, and because the cycle only ever reads it from the
    thread that is running the cycle.

    There is no identifier here. A run is named by the cycle that runs it, and
    a run cancelled before its cycle began has no name — which is the honest
    answer to give, rather than an identifier for a run that never happened.
    """

    web_id: str
    started_at: float = field(default_factory=time.monotonic)
    cancelled: str | None = None

    # Set once the run has the analysis lock and is actually working, which is
    # what tells a Cancel call whether it stopped a run or emptied a queue.

    active: bool = False


class _Runs:
    """The analyses this server has in hand, and who may cancel them."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._runs: list[_Run] = []

    def begin(self, web_id: str) -> _Run:
        """Register a run, before it has waited for anything."""

        run = _Run(web_id=web_id)
        with self._lock:
            self._runs.append(run)
        return run

    def finish(self, run: _Run) -> None:
        """Forget a run that has ended, however it ended."""

        with self._lock:
            if run in self._runs:
                self._runs.remove(run)

    def cancel(self, web_id: str, reason: str) -> list[_Run]:
        """Mark every run for [web_id], and say which they were.

        A Pod cancels its own analysis and no one else's. That falls out of
        the design rather than being enforced on top of it: the request names
        a WebID and only runs for that WebID are looked at, so the worst a
        misdirected request achieves is nothing.
        """

        with self._lock:
            marked = [run for run in self._runs if run.web_id == web_id]
            for run in marked:
                run.cancelled = reason
        return marked

    @property
    def count(self) -> int:
        """How many analyses are queued or running."""

        with self._lock:
            return len(self._runs)


class AnalyserServicer(pb_grpc.AnalyserServicer):
    """Serves Analyse, Cancel and Status for one Analyser Pod."""

    def __init__(
        self, config: Config, service: AnalyserService | None = None,
    ) -> None:
        self._config = config

        # Injectable so the tests can hand in a service wired to their own
        # in-memory Pod server. Production passes nothing.

        self._service = service or AnalyserService(config)
        self._runs = _Runs()

        # Held for the length of one cycle. See the note at the top of the
        # file: the Solid connection and the unlocked keys are shared.

        self._analysis = threading.Lock()

        # Why the analyser is not ready, when it is not. Set by a failed
        # connection attempt and cleared by a successful one, so Status can
        # tell an app what is wrong without trying to connect itself.

        self._not_ready: str | None = 'the analyser has not connected yet'

    # -- Analyse -----------------------------------------------------------

    def Analyse(  # noqa: N802 - the name is the generated one.
        self,
        request: pb.AnalyseRequest,
        context: grpc.ServicerContext,
    ) -> pb.AnalyseReply:
        """Run an analysis for the calling Pod and answer with the result."""

        web_id = (request.web_id or '').strip()
        if not web_id:
            context.abort(
                grpc.StatusCode.INVALID_ARGUMENT,
                'web_id is required: the analysis is for a particular Pod')

        run = self._runs.begin(web_id)
        log.info('analyse requested by %s (%d reading(s) shared)',
                 web_id, request.shared_file_count)
        try:
            return self._analyse(run, context)
        finally:
            self._runs.finish(run)

    def _analyse(
        self,
        run: _Run,
        context: grpc.ServicerContext,
    ) -> pb.AnalyseReply:
        """Wait for a turn, then run one cycle."""

        # Waiting for a turn is cancellable, which matters more than it looks:
        # a user who taps cancel while queued behind somebody else's analysis
        # should not have to wait for that analysis to finish first.

        if not self._acquire(run, context):
            if run.cancelled:
                return pb.AnalyseReply(
                    status=pb.ANALYSE_STATUS_CANCELLED,
                    message='The analysis was cancelled before it started.',
                )
            return pb.AnalyseReply(
                status=pb.ANALYSE_STATUS_FAILED,
                message='The analyser is busy and did not get to this '
                        'analysis in time. Please try again in a moment.',
            )

        try:
            run.active = True
            deadline = (
                run.started_at + self._config.grpc.analysis_timeout_seconds)

            def cancelled() -> str | None:
                """Why the cycle should stop, or None to carry on.

                Three ways in. The Cancel call is the one that matters and the
                only one an app can rely on. A client that has walked away is
                noticed when gRPC happens to tell us, which it does not
                promise for a unary call part way through its handler, so that
                is a saving rather than a mechanism. The deadline is the
                backstop: without it a cycle stuck on an unresponsive server
                would hold the lock against everybody else.
                """

                if run.cancelled:
                    return run.cancelled
                if not context.is_active():
                    return 'the caller stopped waiting'
                if time.monotonic() > deadline:
                    return 'the analysis took too long'
                return None

            outcome = self._service.run_cycle(
                focus_web_id=run.web_id, cancelled=cancelled)

        except CycleCancelled as exc:
            log.info('run %s cancelled: %s', exc.run_id, exc)
            self._record('last_cancelled', {
                'run_id': exc.run_id,
                'web_id': run.web_id,
                'at': store.utc_now().isoformat(),
                'reason': exc.reason,
                'stage': exc.stage,
            })
            return pb.AnalyseReply(
                status=pb.ANALYSE_STATUS_CANCELLED,
                run_id=exc.run_id,
                message='The analysis was stopped.',
            )

        except ConfigError as exc:
            # Not transient, and not the caller's fault either. Said plainly
            # in the reply, because the alternative is an app that reports a
            # slow analyser for a deployment that is simply not finished.

            log.error('the analysis for %s cannot proceed: %s',
                      run.web_id, exc)
            self._not_ready = str(exc)
            return pb.AnalyseReply(
                status=pb.ANALYSE_STATUS_FAILED,
                message='The analyser is not configured; the operator has '
                        'been told in the log.',
            )

        except KeyStoreError as exc:
            # Usually the Analyser Pod has never been opened in HealthPod, or
            # the configured security key is wrong. Both resolve, and neither
            # is worth retrying inside this call.

            log.error('cannot unlock the Analyser Pod for %s: %s',
                      run.web_id, exc)
            self._not_ready = str(exc)
            self._service.close()
            return pb.AnalyseReply(
                status=pb.ANALYSE_STATUS_FAILED,
                message='The analyser cannot unlock its own Pod, so it '
                        'cannot read what you shared.',
            )

        except SolidError as exc:
            # A server restart, an expired token, a Pod that revoked access
            # mid-run. Drop the connection so the next call logs in afresh:
            # a stale token is the commonest cause of a hard failure here.

            log.error('the analysis for %s failed: %s', run.web_id, exc)
            self._service.close()
            return pb.AnalyseReply(
                status=pb.ANALYSE_STATUS_FAILED,
                message=f'The analyser could not reach the Solid server: '
                        f'{exc}',
            )

        except Exception as exc:  # noqa: BLE001 - the server must not die.
            log.exception('the analysis for %s failed: %s', run.web_id, exc)
            self._service.close()
            return pb.AnalyseReply(
                status=pb.ANALYSE_STATUS_FAILED,
                message='The analysis failed; the operator has been told in '
                        'the log.',
            )

        finally:
            run.active = False
            self._analysis.release()

        self._not_ready = None
        self._record('last_run', {
            'run_id': outcome.run_id,
            'web_id': run.web_id,
            'at': outcome.generated_at,
            'pod_count': outcome.pod_count,
            'observation_count': outcome.observation_count,
        })

        if outcome.focus is None:
            return pb.AnalyseReply(
                status=pb.ANALYSE_STATUS_NO_DATA,
                run_id=outcome.run_id,
                generated_at=outcome.generated_at,
                pod_count=outcome.pod_count,
                message='The analyser found none of your blood pressure '
                        'observations. Share them and analyse again.',
            )

        return pb.AnalyseReply(
            status=pb.ANALYSE_STATUS_COMPLETED,
            run_id=outcome.run_id,
            result_url=outcome.result_url or '',
            generated_at=outcome.generated_at,
            pod_count=outcome.pod_count,
            observation_count=outcome.focus_observation_count,
            files_read=outcome.focus_files_read,
            files_skipped=outcome.focus_files_skipped,
            published=outcome.published,
            message='' if outcome.published else
                    'The analysis is done, but the key for it did not reach '
                    'your Pod, so the result cannot be read yet.',
        )

    def _acquire(self, run: _Run, context: grpc.ServicerContext) -> bool:
        """Wait for the analysis lock, giving up if the run is cancelled.

        Returns whether the lock is held. Polls in short slices rather than
        blocking outright, which is what makes the wait cancellable at all;
        the alternative is a condition variable that every cancellation would
        have to know to notify.
        """

        deadline = run.started_at + self._config.grpc.analysis_timeout_seconds
        while True:
            if self._analysis.acquire(timeout=0.2):
                # Cancelled while queued, and the queue has now reached it.
                # Hand the turn straight back rather than analysing something
                # nobody is waiting for.

                if run.cancelled:
                    self._analysis.release()
                    return False
                return True

            if run.cancelled or not context.is_active():
                return False
            if time.monotonic() > deadline:
                return False

    # -- Cancel ------------------------------------------------------------

    def Cancel(  # noqa: N802 - the name is the generated one.
        self,
        request: pb.CancelRequest,
        context: grpc.ServicerContext,
    ) -> pb.CancelReply:
        """Abandon the analysis running for the calling Pod."""

        web_id = (request.web_id or '').strip()
        if not web_id:
            context.abort(
                grpc.StatusCode.INVALID_ARGUMENT,
                'web_id is required: only your own analysis can be stopped')

        marked = self._runs.cancel(web_id, f'requested by {web_id}')
        if not marked:
            # Nothing running, and nothing is remembered for later: a request
            # that reached forward into the next analysis would stop a run
            # nobody had asked to stop, which is the fault the marker files in
            # the Pod had and the reason they had to be collected on every
            # poll whether a cycle was running or not.

            log.info('cancel from %s: nothing running', web_id)
            return pb.CancelReply(
                status=pb.CANCEL_STATUS_NOTHING_RUNNING,
                message='There was no analysis running for your Pod.',
            )

        log.info('cancel from %s: %d run(s) told to stop', web_id, len(marked))
        return pb.CancelReply(
            status=pb.CANCEL_STATUS_STOPPED,
            message='' if marked[0].active else
                    'The analysis was stopped before it started.',
        )

    # -- Status ------------------------------------------------------------

    def Status(  # noqa: N802 - the name is the generated one.
        self,
        request: pb.StatusRequest,
        context: grpc.ServicerContext,
    ) -> pb.StatusReply:
        """Whether the analyser is up, and what it is doing.

        Reads local state only. An app calls this before offering to analyse,
        and a check that had to log in to a Solid server would be neither
        cheap nor a fair test of anything the app is about to do.
        """

        state = self._service.store.read_state()
        last = state.get('last_run') or {}
        return pb.StatusReply(
            ready=self._not_ready is None,
            analyser_web_id=self._config.analyser.web_id,
            active_runs=self._runs.count,
            last_run_id=str(last.get('run_id', '') or ''),
            last_run_at=str(last.get('at', '') or ''),
            message=self._not_ready or '',
        )

    # -- Start-up and shutdown ---------------------------------------------

    def warm_up(self) -> None:
        """Log in and unlock the Pod before the first call arrives.

        Worth doing: the login and the key derivation together are a second or
        two, and paying them at start-up rather than inside the first Analyse
        is the difference between a service that feels immediate and one that
        is slow exactly once. A failure is not fatal — the Pod may not be
        initialised yet, and that resolves — so it is recorded for Status and
        retried by the first call.
        """

        try:
            self._service.connect()
            self._not_ready = None
            log.info('ready')
        except (ConfigError, KeyStoreError, SolidError) as exc:
            self._not_ready = str(exc)
            log.error('not ready: %s', exc)
            log.error('run "./run.sh check" to diagnose; the first Analyse '
                      'call will try again')

    def close(self) -> None:
        """Drop the Solid connection."""

        self._service.close()

    def _record(self, key: str, value: dict[str, object]) -> None:
        """Note something in the stored state, without ever failing for it."""

        try:
            state = self._service.store.read_state()
            state[key] = value
            self._service.store.write_state(state)
        except OSError as exc:
            log.warning('could not record %s: %s', key, exc)


class _TokenInterceptor(grpc.ServerInterceptor):
    """Rejects a call that does not carry the configured shared secret.

    Installed only when `grpc.token` is set. An interceptor rather than a
    check in each handler so that a method added later is guarded by default
    rather than by remembering.
    """

    def __init__(self, token: str) -> None:
        self._expected = f'Bearer {token}'
        self._deny = grpc.unary_unary_rpc_method_handler(
            lambda request, context: context.abort(
                grpc.StatusCode.UNAUTHENTICATED, 'invalid token'))

    def intercept_service(self, continuation, handler_call_details):
        metadata = dict(handler_call_details.invocation_metadata or ())
        if metadata.get('authorization') != self._expected:
            return self._deny
        return continuation(handler_call_details)


def build_server(config: Config) -> tuple[grpc.Server, AnalyserServicer]:
    """Build the gRPC server for [config], without starting it."""

    servicer = AnalyserServicer(config)
    interceptors: list[grpc.ServerInterceptor] = []
    if config.grpc.token:
        interceptors.append(_TokenInterceptor(config.grpc.token))

    server = grpc.server(
        futures.ThreadPoolExecutor(max_workers=config.grpc.max_workers),
        interceptors=interceptors,
    )
    pb_grpc.add_AnalyserServicer_to_server(servicer, server)

    if config.grpc.tls_enabled:
        assert config.grpc.tls_cert_file and config.grpc.tls_key_file
        credentials = grpc.ssl_server_credentials([(
            config.grpc.tls_key_file.read_bytes(),
            config.grpc.tls_cert_file.read_bytes(),
        )])
        server.add_secure_port(config.grpc.address, credentials)
    else:
        server.add_insecure_port(config.grpc.address)

    return server, servicer


def serve(config: Config) -> int:
    """Run the gRPC server until the process is asked to stop.

    Returns the process exit status. The credentials are checked first, so a
    deployment missing a secret says so once and exits rather than accepting
    calls it cannot serve.
    """

    config.require_credentials()

    server, servicer = build_server(config)
    servicer.warm_up()
    server.start()

    log.info('serving gRPC on %s (%s%s)',
             config.grpc.address,
             'TLS' if config.grpc.tls_enabled else 'plaintext',
             ', token required' if config.grpc.token else '')

    stopping = threading.Event()

    def handler(signum: int, frame: FrameType | None) -> None:
        log.info('received signal %s, finishing the analysis in hand', signum)
        stopping.set()

    for name in (signal.SIGINT, signal.SIGTERM):
        try:
            signal.signal(name, handler)
        except ValueError:
            # Not the main thread; whoever built us owns the shutdown.
            pass

    stopping.wait()

    # `stop` refuses new calls at once and gives the ones in flight the grace
    # period to finish. A cycle checks for cancellation between steps, so an
    # analysis part way through ends at its next checkpoint rather than being
    # cut off mid-write.

    server.stop(GRACE_SECONDS).wait()
    servicer.close()
    log.info('stopped')
    return 0
