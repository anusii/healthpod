"""The analysis cycle, run when an app asks for one.

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
#   4. write the results locally (and render the caller's chart);
#   5. share the caller's own average back to it, with the cohort figure.
#
# A cycle runs when an app asks for one over gRPC, and only then. Nothing here
# watches, polls, or wakes on a timer: `grpc_server.py` calls `run_cycle()`
# inside the handler for an Analyse call and answers with what it produced.
#
# The caller names itself, and that changes two of the five steps. Every Pod
# that has shared data is still read, because the cohort figures are the
# average of every contributor's average; but the chart is drawn for the
# caller alone and the result is published to the caller alone. A run
# therefore costs one chart and one publication rather than one of each per
# contributing Pod, which is most of why an analysis now takes seconds.
#
# A cycle can be abandoned part way through. The request arrives as a Cancel
# call on the same gRPC connection, and reaches the cycle as the `cancelled`
# callback passed to `run_cycle()` — an in-memory flag, read at the points
# between steps where stopping is safe. Nothing is killed mid-write, so an
# abandoned run leaves the stored results exactly as the previous run left
# them.

from __future__ import annotations

import logging
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime
from typing import Any

from . import bp_data, charts, discovery, statistics, store
from .config import Config
from .keys import PodKeys
from .publisher import Publisher
from .solid_client import SolidClient, SolidError
from .store import ResultStore

log = logging.getLogger(__name__)


class CycleCancelled(Exception):
    """Raised inside a cycle when a cancellation has been requested.

    Carries the point the cycle had reached, which is what the log and the
    stored state report; the caller decides whether that is worth complaining
    about, and for a cancellation it is not.
    """

    def __init__(
        self, stage: str, reason: str = 'grpc', identifier: str = '',
    ) -> None:
        super().__init__(f'cancelled during {stage} ({reason})')
        self.stage = stage
        self.reason = reason

        # The run that was abandoned, so the reply and the log line name the
        # same thing a completed run would. Minted inside `run_cycle`, which
        # is the only place that knows it.

        self.run_id = identifier


@dataclass
class CycleOutcome:
    """What one analysis cycle produced."""

    document: dict[str, Any]
    results_path: str
    pod_count: int
    observation_count: int
    shared_count: int

    # What the caller of an Analyse call is owed: their own figures, and
    # whether the result reached their Pod. All None for a run with no focus
    # Pod, which is what `run-once` on the command line does.

    focus: dict[str, Any] | None = None
    result_url: str | None = None
    published: bool = False

    @property
    def run_id(self) -> str:
        """The identifier of the run that produced this."""

        return str(self.document.get('run_id', ''))

    @property
    def generated_at(self) -> str:
        """When the analyser produced it, as ISO 8601 in UTC."""

        return str(self.document.get('generated_at', ''))

    @property
    def focus_observation_count(self) -> int:
        """How many of the caller's readings went into their averages."""

        return int((self.focus or {}).get('observation_count', 0) or 0)

    @property
    def focus_files_read(self) -> int:
        """How many of the caller's shared files were read."""

        return int((self.focus or {}).get('files_read', 0) or 0)

    @property
    def focus_files_skipped(self) -> int:
        """How many were found but could not be read."""

        return int((self.focus or {}).get('files_skipped', 0) or 0)


class AnalyserService:
    """Owns the Solid connection and runs the analysis."""

    def __init__(self, config: Config) -> None:
        self._config = config
        self._store = ResultStore(config)
        self._client: SolidClient | None = None
        self._keys: PodKeys | None = None

        # Asked between the steps of the cycle in hand, and returning a reason
        # when the run should be abandoned. Set by `run_cycle` for the length
        # of one cycle; None means nothing can cancel this one.

        self._cancelled: Callable[[], str | None] | None = None

        # The identifier of the cycle in hand, so a cancellation can name it.

        self._run_id = ''

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

    # -- Cancellation ------------------------------------------------------

    # A cancellation used to travel out of band, because the app had no route
    # to the analyser: a marker file in the Analyser Pod's publicly writable
    # `shared/` container, collected on the next poll. It worked, and it was
    # slow — an idle analyser looked once every thirty seconds — and it let
    # anyone who could reach the Pod stop somebody else's analysis.
    #
    # A Cancel call arrives on the same connection the Analyse call went out
    # on, so it is in the same process, and the flag it sets is read at the
    # next checkpoint. Nothing to poll, nothing to write, and the request is
    # tied to the caller by construction.

    def _check_cancelled(self, stage: str) -> None:
        """Abandon the cycle if a cancellation has been asked for.

        Called between steps rather than during one: a half-written result or
        a half-granted permission would be worse than a run that finishes.
        """

        if self._cancelled is None:
            return
        reason = self._cancelled()
        if reason:
            raise CycleCancelled(stage, reason, self._run_id)

    # -- One cycle ---------------------------------------------------------

    def run_cycle(
        self,
        focus_web_id: str | None = None,
        cancelled: Callable[[], str | None] | None = None,
        identifier: str | None = None,
    ) -> CycleOutcome:
        """Read, analyse, record and share. Returns the results document.

        [focus_web_id] is the Pod that asked, when one did. Every contributing
        Pod is still read, because the cohort figures are the average of every
        contributor's average, but the chart is drawn and the result published
        for that Pod alone. Passing None analyses for everybody, which is what
        `run-once` on the command line does.

        [cancelled] is asked between the steps of the cycle and abandons it by
        returning a reason. `CycleCancelled` is then raised: nothing has been
        written or shared at that point, so the run leaves no trace of itself
        and the stored results stay as the previous run left them.

        [identifier] names the run, for a caller that wants to choose. Left
        unset it is derived from the moment the cycle starts, which is what
        keeps it in step with `generated_at` and unique between two runs that
        cannot overlap. A cancellation carries it back on `CycleCancelled`.
        """

        started = store.utc_now()
        identifier = identifier or store.run_id(started)

        # Marked before the login, which is slow enough to be worth cancelling
        # during and, on a cold start, is where a cycle most often waits.

        self._store.mark_run_started(identifier, focus_web_id or '')
        self._cancelled = cancelled
        self._run_id = identifier
        try:
            client, keys = self.connect()
            self._check_cancelled('connecting')
            return self._run_cycle(
                client, keys, started, identifier, focus_web_id)
        finally:
            self._cancelled = None
            self._run_id = ''
            self._store.mark_run_finished()

    def _run_cycle(
        self,
        client: SolidClient,
        keys: PodKeys,
        started: datetime,
        identifier: str,
        focus_web_id: str | None,
    ) -> CycleOutcome:
        """The body of one cycle, with the run marker already in place."""

        shared = keys.shared_resources()
        key_index = discovery.key_index(shared)

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

        # Whose chart is drawn and whose Pod is written to. Everything above
        # this line reads every contributor, because the cohort figure is the
        # average of their averages; everything below deals with the caller
        # alone, unless there is no caller and the run is for everybody.

        recipients = [
            summary for summary in summaries
            if focus_web_id is None or summary.web_id == focus_web_id
        ]

        if focus_web_id is not None and not recipients:
            # The caller has shared nothing the analyser can read. Worth
            # saying in the document as well as in the reply: an analysis that
            # found no data for the Pod that asked for it looks like a fault
            # from the app's side, and this is where the reason lives.

            warnings.append(
                f'{focus_web_id} asked for an analysis but has shared no '
                f'blood pressure data the Analyser can read')

        document: dict[str, Any] = {
            'schema_version': store.SCHEMA_VERSION,
            'run_id': identifier,
            'generated_at': started.isoformat(),
            'requested_by': focus_web_id,
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
        chart_images = self._render_charts(document, readings, recipients)

        result_url: str | None = None
        published = False
        if self._config.sharing.enabled and recipients:
            self._check_cancelled('sharing the results')
            result_url, published = self._share_results(
                document, recipients, cohort, chart_images, focus_web_id)

        results_path = self._store.write_results(document)
        log.info('run %s complete: %d Pod(s), %d reading(s)',
                 identifier, cohort.pod_count, cohort.observation_count)

        focus = next(
            (summary.to_dict(places) for summary in recipients
             if focus_web_id is not None and summary.web_id == focus_web_id),
            None,
        )

        return CycleOutcome(
            document=document,
            results_path=str(results_path),
            pod_count=cohort.pod_count,
            observation_count=cohort.observation_count,
            shared_count=len(document['sharing']['published']),
            focus=focus,
            result_url=result_url,
            published=published,
        )

    # -- Charts ------------------------------------------------------------

    def _render_charts(
        self,
        document: dict[str, Any],
        readings: dict[str, list],
        recipients: list[statistics.PodSummary],
    ) -> dict[str, str]:
        """Draw a chart for each of [recipients], base64-encoded, by Pod.

        The file under `var/charts/` is for the operator; the encoded copy
        travels inside the result the Pod receives, so the app gets the
        picture and the numbers in a single read.

        Only the Pods a result is going to are drawn. Rendering is the second
        slowest thing a cycle does after reading the Pods, and a chart nobody
        will be shown is the clearest waste in a run that somebody is sitting
        and waiting for.
        """

        images: dict[str, str] = {}
        if not self._config.output.render_charts:
            return images

        # Must happen before matplotlib is imported, which `available()` does.
        charts.set_cache_dir(self._store.charts_dir / '.mplconfig')
        if not charts.available():
            return images

        wanted = {summary.pod_id for summary in recipients}
        cohort = document['cohort']
        for pod in document['pods']:
            pod_id = pod['pod_id']
            if pod_id not in wanted:
                continue
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
        focus_web_id: str | None,
    ) -> tuple[str | None, bool]:
        """Publish each of [summaries] back to its own Pod.

        Returns where the result for [focus_web_id] was published and whether
        that Pod received the key for it, which is what the Analyse reply
        carries. Both are empty for a run with no focus Pod.
        """

        client, keys = self.connect()
        publisher = Publisher(client, keys, self._config)
        places = self._config.analysis.decimal_places
        results_dir = self._config.sharing.results_dir
        published = document['sharing']['published']
        focus_url: str | None = None
        focus_published = False

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
            if summary.web_id == focus_web_id:
                # A result the caller can fetch but not read is the one
                # failure worth naming in the reply: from the app's side it
                # looks like a decryption fault rather than a delivery one.

                focus_url = outcome.resource_url
                focus_published = summary.web_id not in outcome.failures
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
            return focus_url, focus_published

        recipients = [
            summary.web_id for summary in summaries
            if summary.observation_count > 0
        ]
        if not recipients:
            return focus_url, focus_published

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
            return focus_url, focus_published
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

        return focus_url, focus_published
