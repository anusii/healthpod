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

from __future__ import annotations

import logging
import signal
import time
from dataclasses import dataclass
from types import FrameType
from typing import Any

from . import bp_data, charts, discovery, statistics, store
from .config import Config, ConfigError
from .keys import KeyStoreError, PodKeys
from .publisher import Publisher
from .solid_client import SolidClient, SolidError
from .store import ResultStore

log = logging.getLogger(__name__)


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
        self._stopping = False

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

    @property
    def store(self) -> ResultStore:
        """The local result store this service writes to."""

        return self._store

    # -- One cycle ---------------------------------------------------------

    def run_cycle(self) -> CycleOutcome:
        """Read, analyse, record and share. Returns the results document."""

        client, keys = self.connect()
        started = store.utc_now()
        identifier = store.run_id(started)

        shared = keys.shared_resources()
        key_index = discovery.key_index(shared)
        datasets = discovery.discover(client, shared, self._config)

        places = self._config.analysis.decimal_places
        summaries = []
        warnings: list[str] = []

        for dataset in datasets:
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
            'charts': {'cohort': None, 'pods': {}},
            'sharing': {'enabled': self._config.sharing.enabled, 'published': []},
            'warnings': warnings,
        }

        self._render_charts(document)
        if self._config.sharing.enabled:
            self._share_results(document, summaries, cohort)

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

    def _render_charts(self, document: dict[str, Any]) -> None:
        if not self._config.output.render_charts:
            return

        # Must happen before matplotlib is imported, which `available()` does.
        charts.set_cache_dir(self._store.charts_dir / '.mplconfig')
        if not charts.available():
            return

        cohort = document['cohort']
        cohort_path = charts.render_cohort_chart(
            document['pods'], cohort, self._store.chart_path('cohort'))
        if cohort_path is not None:
            document['charts']['cohort'] = cohort_path.name

        for pod in document['pods']:
            path = charts.render_pod_chart(
                pod, cohort, self._store.chart_path(pod['pod_id']))
            if path is not None:
                document['charts']['pods'][pod['pod_id']] = path.name

    # -- Sharing -----------------------------------------------------------

    def _share_results(
        self,
        document: dict[str, Any],
        summaries: list[statistics.PodSummary],
        cohort: statistics.CohortSummary,
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
        rescan = max(poll, self._config.watch.full_rescan_seconds)
        last_full_run = 0.0
        pending = self._config.watch.run_on_start

        log.info('watching %s every %ss (full rescan every %ss)',
                 self._config.analyser.web_id, poll, rescan)

        while not self._stopping:
            reason = None
            try:
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

                if reason is None and time.monotonic() - last_full_run >= rescan:
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
