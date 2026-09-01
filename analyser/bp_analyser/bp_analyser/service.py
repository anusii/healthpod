"""The analysis cycle, and the loop that watches for new shares.

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

# One cycle is:
#
#   1. read the Analyser's shared-keys file to see what has been shared;
#   2. read and decrypt each Pod's blood pressure readings;
#   3. average per Pod, then average those averages across the cohort;
#   4. write the results locally (and render charts);
#   5. share each Pod's own average back to it, together with the cohort figure.
#
# `watch()` repeats that whenever the shared-keys file changes — which is what
# happens the moment a new Pod grants the Analyser access — and, as a safety
# net, on a slower full rescan so a change missed by an unreliable entity tag or
# a share that arrives without one is still picked up.
#
# A cycle can be abandoned part way through. There are two ways to ask:
#
#   - `POST /api/cancel`, which leaves a marker file in the state directory,
#     for an operator or a front end that can reach the API;
#   - a marker left in the Analyser Pod's `shared/` container, which is how
#     the HealthPod app asks, because it has no route to an API bound to the
#     server's loopback interface. See `control.py`.
#
# Either way the cycle looks between steps, at the points where stopping is
# safe. Nothing is killed mid-write, so an abandoned run leaves the stored
# results exactly as the previous run left them.

from __future__ import annotations

import logging
import signal
import time
from dataclasses import dataclass
from datetime import datetime
from types import FrameType
from typing import Any

from . import bp_data, charts, control, discovery, statistics, store
from .config import Config, ConfigError
from .keys import KeyStoreError, PodKeys
from .publisher import Publisher
from .solid_client import SolidClient, SolidError
from .store import ResultStore

log = logging.getLogger(__name__)


class CycleCancelled(Exception):
    """Raised inside a cycle when a cancellation has been requested.

    Carries the point the cycle had reached, which is what the log and the
    watch state report; the caller decides whether that is worth complaining
    about, and for a cancellation it is not.
    """

    def __init__(self, stage: str, reason: str = 'api') -> None:
        super().__init__(f'cancelled during {stage} ({reason})')
        self.stage = stage
        self.reason = reason


@dataclass
class CycleOutcome:
    """What one analysis cycle produced."""

    document: dict[str, Any]
    results_path: str
    pod_count: int
    observation_count: int
    shared_count: int


class AnalyserService:
    """Owns the Solid connection and runs the analysis."""

    def __init__(self, config: Config) -> None:
        self._config = config
        self._store = ResultStore(config)
        self._client: SolidClient | None = None
        self._keys: PodKeys | None = None
        self._inbox: control.CancelInbox | None = None
        self._stopping = False

        # Who may cancel the cycle in hand, and when the Pod was last asked.
        # Both last only as long as the cycle that set them.

        self._cycle_web_ids: set[str] | None = None
        self._last_inbox_poll = 0.0

    # -- Connection --------------------------------------------------------

    def connect(self) -> tuple[SolidClient, PodKeys]:
        """Log in to the server and unlock the Analyser Pod, once."""

        if self._client is None:
            self._config.require_credentials()
            client = SolidClient(
                self._config.analyser.server_url,
                self._config.analyser.client_id,
                self._config.analyser.client_secret,
                timeout=self._config.analyser.request_timeout,
            )
            client.login()
            keys = PodKeys(client, self._config)
            keys.unlock()
            self._client = client
            self._keys = keys
            self._inbox = control.CancelInbox(client, self._config)
            log.info('connected to %s as %s',
                     self._config.analyser.server_url,
                     self._config.analyser.web_id)
        assert self._client is not None and self._keys is not None
        return self._client, self._keys

    def close(self) -> None:
        """Drop the connection; the next cycle will reconnect."""

        if self._client is not None:
            self._client.close()
        self._client = None
        self._keys = None
        self._inbox = None

    @property
    def store(self) -> ResultStore:
        """The local result store this service writes to."""

        return self._store

    # -- Cancellation ------------------------------------------------------

    def clear_pod_cancellations(self) -> None:
        """Discard cancellations waiting in the Pod without acting on them.

        For a run started from the command line, where a marker left by an
        earlier process would otherwise stop a run nobody asked to stop. The
        watcher does not need this: it collects markers as it goes.
        """

        self.connect()
        if self._inbox is not None:
            self._inbox.clear()

    def _contributors(self) -> set[str]:
        """The WebIDs that have shared something with the Analyser.

        Reads the shared-keys file, so it is worth calling only once there is
        a cancellation to check against.
        """

        _, keys = self.connect()
        return discovery.contributor_web_ids(
            keys.shared_resources(), self._config)

    def collect_pod_cancellation(self) -> control.CancelRequest | None:
        """Take a cancellation waiting in the Pod, when nothing is running.

        Costs one container listing per call, and works out who is allowed to
        cancel only if that listing turns something up. Collecting while idle
        is what stops a request going uncollected: left there, it would be
        picked up by the next run instead, and stop an analysis nobody asked
        to stop.
        """

        self.connect()
        if self._inbox is None or not self._inbox.enabled:
            return None
        return self._inbox.poll(self._contributors)

    def _check_cancelled(self, stage: str) -> None:
        """Abandon the cycle if a cancellation has been asked for.

        Called between steps rather than during one: a half-written result or
        a half-granted permission would be worse than a run that finishes.

        Looks at both channels. The local marker is a file, so it is read
        every time; the Pod costs a request, so it is read no more often than
        `watch.cancel_poll_seconds`.
        """

        if self._store.cancel_requested():
            reason = self._store.consume_cancel() or 'unknown'
            raise CycleCancelled(stage, reason)

        request = self._poll_inbox()
        if request is not None:
            raise CycleCancelled(stage, request.reason)

    def _poll_inbox(self) -> control.CancelRequest | None:
        """Read the Pod's cancellation container, at most so often.

        Stays shut until `_cycle_web_ids` is known. The container is publicly
        writable, so the WebID on a request is the only thing distinguishing a
        contributor from a passer-by, and there is nothing to check it against
        before the shared list has been read.
        """

        if self._inbox is None or not self._inbox.enabled:
            return None
        if self._cycle_web_ids is None:
            return None

        now = time.monotonic()
        if now - self._last_inbox_poll < self._config.watch.cancel_poll_seconds:
            return None
        self._last_inbox_poll = now

        return self._inbox.poll(self._cycle_web_ids)

    # -- One cycle ---------------------------------------------------------

    def run_cycle(self) -> CycleOutcome:
        """Read, analyse, record and share. Returns the results document.

        Raises `CycleCancelled` when a cancellation is requested while the
        cycle is running. Nothing has been written or shared at that point
        beyond whatever had already been published for earlier Pods, so the
        run simply leaves no trace of itself.

        Any cancellation left over from before is the caller's to clear:
        `watch()` takes one at the top of every pass, and `run-once` clears
        one on the way in, so a marker still here belongs to this run.
        """

        started = store.utc_now()
        identifier = store.run_id(started)

        # Marked before the login, which is slow enough to be worth cancelling
        # during and, on a cold start, is where a cycle most often waits.

        self._store.mark_run_started(identifier)

        # Cleared so the Pod channel stays shut until the shared list has
        # been read; see `_poll_inbox`.

        self._cycle_web_ids = None
        self._last_inbox_poll = 0.0
        try:
            client, keys = self.connect()
            self._check_cancelled('connecting')
            return self._run_cycle(client, keys, started, identifier)
        finally:
            self._cycle_web_ids = None
            self._store.mark_run_finished()

    def _run_cycle(
        self,
        client: SolidClient,
        keys: PodKeys,
        started: datetime,
        identifier: str,
    ) -> CycleOutcome:
        """The body of one cycle, with the run marker already in place."""

        shared = keys.shared_resources()
        key_index = discovery.key_index(shared)

        # From here a cancellation left in the Pod is honoured, but only from
        # a Pod that has actually shared something: the container it is left
        # in is publicly writable, so the name on the request is all there is
        # to go on.

        self._cycle_web_ids = discovery.contributor_web_ids(shared, self._config)

        datasets = discovery.discover(client, shared, self._config)
        self._check_cancelled('discovery')

        places = self._config.analysis.decimal_places
        summaries = []
        readings: dict[str, list] = {}
        warnings: list[str] = []

        for dataset in datasets:
            # Reading a Pod is the slow part of a cycle, so this is where a
            # cancellation most often lands.

            self._check_cancelled(f'reading {dataset.slug}')
            report = bp_data.read_pod(
                client, dataset.file_urls, key_index, self._config)
            summary = statistics.summarise_pod(
                web_id=dataset.web_id,
                pod_id=dataset.slug,
                pod_root=dataset.pod_root,
                observations=report.observations,
                config=self._config,
                files_read=report.files_read,
                files_skipped=report.files_skipped,
            )
            for file_url, reason in report.skipped_reasons.items():
                warnings.append(f'{file_url}: {reason}')
            summaries.append(summary)
            readings[summary.pod_id] = statistics.within_window(
                report.observations, self._config)
            log.info('%s: %d reading(s) from %d file(s)',
                     dataset.slug, summary.observation_count, report.files_read)

        cohort = statistics.summarise_cohort(summaries)

        document: dict[str, Any] = {
            'schema_version': store.SCHEMA_VERSION,
            'run_id': identifier,
            'generated_at': started.isoformat(),
            'analyser': {
                'web_id': self._config.analyser.web_id,
                'app_dir_name': self._config.analyser.app_dir_name,
                'server_url': self._config.analyser.server_url,
            },
            'analysis': {
                'minimum_observations': self._config.analysis.minimum_observations,
                'window_days': self._config.analysis.window_days,
            },
            'cohort': cohort.to_dict(places),
            'pods': [summary.to_dict(places) for summary in summaries],
            'charts': {'pods': {}},
            'sharing': {'enabled': self._config.sharing.enabled, 'published': []},
            'warnings': warnings,
        }

        self._check_cancelled('drawing the charts')
        chart_images = self._render_charts(document, readings)
        if self._config.sharing.enabled:
            self._check_cancelled('sharing the results')
            self._share_results(document, summaries, cohort, chart_images)

        results_path = self._store.write_results(document)
        log.info('run %s complete: %d Pod(s), %d reading(s)',
                 identifier, cohort.pod_count, cohort.observation_count)

        return CycleOutcome(
            document=document,
            results_path=str(results_path),
            pod_count=cohort.pod_count,
            observation_count=cohort.observation_count,
            shared_count=len(document['sharing']['published']),
        )

    # -- Charts ------------------------------------------------------------

    def _render_charts(
        self, document: dict[str, Any], readings: dict[str, list],
    ) -> dict[str, str]:
        """Draw one chart per Pod and return them base64-encoded, by Pod.

        The file under `var/charts/` is for the operator; the encoded copy
        travels inside the result the Pod receives, so the app gets the
        picture and the numbers in a single read.
        """

        images: dict[str, str] = {}
        if not self._config.output.render_charts:
            return images

        # Must happen before matplotlib is imported, which `available()` does.
        charts.set_cache_dir(self._store.charts_dir / '.mplconfig')
        if not charts.available():
            return images

        cohort = document['cohort']
        for pod in document['pods']:
            pod_id = pod['pod_id']
            path = charts.render_pod_chart(
                observations=readings.get(pod_id, []),
                pod=pod,
                cohort=cohort,
                path=self._store.chart_path(pod_id),
            )
            if path is None:
                continue
            document['charts']['pods'][pod_id] = path.name
            encoded = charts.encode(path)
            if encoded is not None:
                images[pod_id] = encoded

        return images

    # -- Sharing -----------------------------------------------------------

    def _share_results(
        self,
        document: dict[str, Any],
        summaries: list[statistics.PodSummary],
        cohort: statistics.CohortSummary,
        chart_images: dict[str, str],
    ) -> None:
        client, keys = self.connect()
        publisher = Publisher(client, keys, self._config)
        places = self._config.analysis.decimal_places
        results_dir = self._config.sharing.results_dir
        published = document['sharing']['published']

        # Each Pod receives its own average, plus the cohort figure for
        # context. No other Pod's readings or identity are included.

        for summary in summaries:
            if summary.observation_count == 0:
                continue

            # Publishing re-encrypts a key per recipient and writes to the
            # server, so check between Pods rather than part way through one.

            self._check_cancelled(f'sharing with {summary.pod_id}')
            payload = {
                'schema_version': store.SCHEMA_VERSION,
                'kind': 'pod-average',
                'generated_at': document['generated_at'],
                'analyser_web_id': self._config.analyser.web_id,
                'pod': summary.to_dict(places),
                'average': statistics.measure_dict(summary, places),
                'cohort': cohort.to_dict(places),
                'units': {
                    'systolic': 'mm Hg',
                    'diastolic': 'mm Hg',
                    'heart_rate': 'bpm',
                },
            }

            # The chart of this Pod's own readings, ready for the app to
            # decode and show. Absent when charts are switched off or
            # matplotlib is not installed, which the app must tolerate.

            image = chart_images.get(summary.pod_id)
            if image is not None:
                payload['chart'] = {
                    'format': 'png',
                    'encoding': 'base64',
                    'data': image,
                }

            try:
                outcome = publisher.publish(
                    payload=payload,
                    relative_path=f'{results_dir}/{summary.pod_id}/bp-average.json',
                    recipients=[summary.web_id],
                )
            except SolidError as exc:
                document['warnings'].append(
                    f'could not share the average with {summary.web_id}: {exc}')
                log.error('could not share the average with %s: %s',
                          summary.web_id, exc)
                continue
            published.append({
                'kind': 'pod-average',
                'pod_id': summary.pod_id,
                'resource_url': outcome.resource_url,
                'recipients': outcome.recipients,
                'failures': outcome.failures,
            })
            for recipient, reason in outcome.failures.items():
                # A Pod that did not receive its key can fetch the result but
                # not read it, which looks like an app fault from the outside.
                # Say so plainly, in the log and in the run document.

                document['warnings'].append(
                    f'{recipient} did not receive the key for '
                    f'{outcome.resource_url}: {reason}')
                log.error('%s did not receive the key for %s: %s',
                          recipient, outcome.resource_url, reason)

        # The cohort average of averages goes to every contributing Pod.

        if not self._config.sharing.share_cohort_average:
            return

        recipients = [
            summary.web_id for summary in summaries
            if summary.observation_count > 0
        ]
        if not recipients:
            return

        payload = {
            'schema_version': store.SCHEMA_VERSION,
            'kind': 'cohort-average',
            'generated_at': document['generated_at'],
            'analyser_web_id': self._config.analyser.web_id,
            'cohort': cohort.to_dict(places),
            'units': {
                'systolic': 'mm Hg',
                'diastolic': 'mm Hg',
                'heart_rate': 'bpm',
            },
        }
        try:
            outcome = publisher.publish(
                payload=payload,
                relative_path=f'{results_dir}/cohort/bp-cohort-average.json',
                recipients=recipients,
            )
        except SolidError as exc:
            document['warnings'].append(
                f'could not share the cohort average: {exc}')
            log.error('could not share the cohort average: %s', exc)
            return
        published.append({
            'kind': 'cohort-average',
            'pod_id': None,
            'resource_url': outcome.resource_url,
            'recipients': outcome.recipients,
            'failures': outcome.failures,
        })
        for recipient, reason in outcome.failures.items():
            document['warnings'].append(
                f'{recipient} did not receive the key for the cohort '
                f'average: {reason}')
            log.error('%s did not receive the cohort average key: %s',
                      recipient, reason)

    # -- Watching ----------------------------------------------------------

    def _share_fingerprint(self) -> tuple[str | None, list[str]]:
        """A cheap description of what is currently shared with the Analyser."""

        client, keys = self.connect()
        etag = keys.shared_key_etag()
        if etag is not None:
            return etag, []
        # No entity tag from the server: fall back to the set of share ids.
        return None, sorted(item.unique_id for item in keys.shared_resources())

    def watch(self) -> None:
        """Run cycles for as long as the process lives.

        A cycle is triggered by a change to the shared-keys file, by the
        periodic full rescan, or by a refresh request from the HTTP API.

        A cancellation stops the cycle in hand, whether it came through the
        API or through the Analyser Pod. Arriving while nothing is running, it
        instead withdraws whatever would have started the next one — a pending
        refresh, or the share that has just been noticed — because a user who
        cancels means "do not analyse", not "analyse a moment later".

        Transient failures — a server restart, an expired token, a Pod that
        revokes access mid-run — are logged and retried. A configuration
        problem is not transient, so it is raised: the process exits, the
        operator sees why, and systemd's `Restart=always` does not turn the
        mistake into a log flood.
        """

        # Check the credentials before announcing that we are watching, so a
        # missing secret is reported once, plainly, at startup.

        self._config.require_credentials()

        self._install_signal_handlers()
        state = self._store.read_state()
        poll = max(5, self._config.watch.poll_seconds)

        # A rescan interval of zero (or less) switches the periodic run off:
        # the analysis then happens only when something has actually been
        # shared, which is the usual arrangement.

        configured_rescan = self._config.watch.full_rescan_seconds
        rescan = max(poll, configured_rescan) if configured_rescan > 0 else 0
        last_full_run = 0.0
        pending = self._config.watch.run_on_start

        log.info(
            'watching %s every %ss (%s)',
            self._config.analyser.web_id,
            poll,
            f'full rescan every {rescan}s' if rescan
            else 'analysing only when something is shared',
        )

        while not self._stopping:
            reason = None
            try:
                cancelled = self._store.consume_cancel()
                if cancelled is None:
                    # The app's channel. Collected on every pass, running or
                    # not, so a request cannot sit in the Pod waiting to stop
                    # a later analysis that nobody asked to stop.

                    request = self.collect_pod_cancellation()
                    if request is not None:
                        cancelled = request.reason

                if cancelled:
                    # Nothing is running, so there is no cycle to stop. Drop
                    # the work that was queued instead, and take the current
                    # fingerprint as seen so the share that prompted it does
                    # not start a run on the very next poll.

                    log.info('cancelled before the run started (%s)', cancelled)
                    self._store.consume_refresh()
                    pending = False
                    etag, share_ids = self._share_fingerprint()
                    state['shared_key_etag'] = etag
                    state['share_ids'] = share_ids
                    state['last_cancelled'] = {
                        'at': store.utc_now().isoformat(),
                        'reason': cancelled,
                        'stage': 'before the run started',
                    }
                    self._store.write_state(state)
                    self._sleep(poll)
                    continue

                requested = self._store.consume_refresh()
                if requested:
                    reason = f'refresh requested ({requested})'

                if pending:
                    reason = reason or 'first run'

                if reason is None:
                    etag, share_ids = self._share_fingerprint()
                    if etag is not None and etag != state.get('shared_key_etag'):
                        reason = 'a Pod has shared something new'
                        state['shared_key_etag'] = etag
                    elif etag is None and share_ids != state.get('share_ids'):
                        reason = 'the set of shared resources has changed'
                        state['share_ids'] = share_ids

                if (reason is None and rescan
                        and time.monotonic() - last_full_run >= rescan):
                    reason = 'periodic rescan'

                if reason is not None:
                    log.info('running the analysis: %s', reason)
                    outcome = self.run_cycle()
                    pending = False
                    last_full_run = time.monotonic()
                    etag, share_ids = self._share_fingerprint()
                    state['shared_key_etag'] = etag
                    state['share_ids'] = share_ids
                    state['last_run'] = {
                        'run_id': outcome.document['run_id'],
                        'at': outcome.document['generated_at'],
                        'pod_count': outcome.pod_count,
                        'observation_count': outcome.observation_count,
                        'reason': reason,
                    }
                    self._store.write_state(state)

            except CycleCancelled as exc:
                # Asked for, so not a failure. The stored results are the ones
                # the previous run left; note what happened and carry on
                # watching, with the fingerprint taken as seen so the share
                # that prompted this run does not immediately start another.

                log.info('analysis cancelled: %s', exc)
                pending = False
                last_full_run = time.monotonic()
                try:
                    etag, share_ids = self._share_fingerprint()
                    state['shared_key_etag'] = etag
                    state['share_ids'] = share_ids
                except Exception:  # noqa: BLE001 - best effort bookkeeping.
                    log.debug('could not refresh the share fingerprint after '
                              'a cancellation', exc_info=True)
                state['last_cancelled'] = {
                    'at': store.utc_now().isoformat(),
                    'reason': exc.reason,
                    'stage': exc.stage,
                }
                self._store.write_state(state)
                self._sleep(poll)
                continue

            except ConfigError:
                # Not transient: retrying cannot fix a missing credential.
                raise

            except KeyStoreError as exc:
                # Either the security key is wrong, or the Analyser Pod has
                # not been initialised in HealthPod yet. The second case does
                # resolve on its own once somebody initialises it, so keep
                # going — but without a traceback, which says nothing useful.
                backoff = max(poll, self._config.watch.error_backoff_seconds)
                log.error('cannot unlock the Analyser Pod: %s', exc)
                log.error('retrying in %ss; run "./run.sh check" to diagnose',
                          backoff)
                self.close()
                self._sleep(backoff)
                continue

            except Exception as exc:  # noqa: BLE001 - the watcher must not die.
                backoff = max(poll, self._config.watch.error_backoff_seconds)
                log.exception('cycle failed, retrying in %ss: %s', backoff, exc)
                # Force a fresh login next time round: the most common cause
                # of a hard failure is an expired or revoked token.
                self.close()
                self._sleep(backoff)
                continue

            self._sleep(poll)

        log.info('watcher stopped')
        self.close()

    def stop(self) -> None:
        """Ask the watch loop to finish after the current cycle."""

        self._stopping = True

    def _sleep(self, seconds: float) -> None:
        """Sleep in short slices so a stop signal is acted on promptly."""

        deadline = time.monotonic() + seconds
        while not self._stopping and time.monotonic() < deadline:
            time.sleep(min(1.0, deadline - time.monotonic()))

    def _install_signal_handlers(self) -> None:
        def handler(signum: int, frame: FrameType | None) -> None:
            log.info('received signal %s, finishing up', signum)
            self.stop()

        for name in (signal.SIGINT, signal.SIGTERM):
            try:
                signal.signal(name, handler)
            except ValueError:
                # Not the main thread; the caller is responsible for stopping.
                pass
