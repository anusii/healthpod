"""Local persistence: run state, result documents and chart files.

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

# The results are written to disk as plain JSON before anything is shared, so an
# operator can inspect exactly what the analyser computed, and so the HTTP API
# can serve the latest figures without touching the Solid server. The layout is
#
#     var/state/state.json        what has been seen, when the last run happened
#     var/state/refresh.trigger   touch this to ask the watcher for a run
#     var/state/cancel.trigger    touch this to ask the watcher to abandon one
#     var/state/active.json       the run in progress, absent when idle
#     var/results/latest.json     the most recent run
#     var/results/run-<id>.json   the run history, pruned to `output.keep_runs`
#     var/charts/<pod-id>.png     per-Pod charts, cohort.png for the cohort
#
# `results/latest.json` is the contract the front end reads; its shape is
# described in README.md under "The results document".

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .config import Config

log = logging.getLogger(__name__)

SCHEMA_VERSION = 1

_STATE_FILE = 'state.json'
_TRIGGER_FILE = 'refresh.trigger'
_CANCEL_FILE = 'cancel.trigger'
_ACTIVE_FILE = 'active.json'
_LATEST_FILE = 'latest.json'


def utc_now() -> datetime:
    """The current time, in UTC, as everything recorded here is."""

    return datetime.now(timezone.utc)


def run_id(moment: datetime | None = None) -> str:
    """A sortable identifier for one analysis run."""

    return (moment or utc_now()).strftime('%Y%m%dT%H%M%SZ')


class ResultStore:
    """Reads and writes everything the analyser keeps on local disk."""

    def __init__(self, config: Config) -> None:
        self._config = config
        self.state_dir = Path(config.output.state_dir)
        self.results_dir = Path(config.output.results_dir)
        self.charts_dir = Path(config.output.charts_dir)

    def ensure_directories(self) -> None:
        """Create the state, results and chart directories."""

        for directory in (self.state_dir, self.results_dir, self.charts_dir):
            directory.mkdir(parents=True, exist_ok=True)

    # -- Watch state -------------------------------------------------------

    @property
    def state_path(self) -> Path:
        """Where the watcher's bookkeeping lives."""

        return self.state_dir / _STATE_FILE

    def read_state(self) -> dict[str, Any]:
        """The saved watch state, or an empty state on first run."""

        if not self.state_path.is_file():
            return {'shared_key_etag': None, 'share_ids': [], 'last_run': None}
        try:
            with self.state_path.open('r', encoding='utf-8') as handle:
                return json.load(handle)
        except (OSError, json.JSONDecodeError) as exc:
            log.warning('ignoring unreadable state file %s: %s',
                        self.state_path, exc)
            return {'shared_key_etag': None, 'share_ids': [], 'last_run': None}

    def write_state(self, state: dict[str, Any]) -> None:
        """Persist the watch state atomically."""

        self.ensure_directories()
        _write_json(self.state_path, state)

    # -- Refresh trigger ---------------------------------------------------

    @property
    def trigger_path(self) -> Path:
        """The file the API touches to ask for an out-of-band run."""

        return self.state_dir / _TRIGGER_FILE

    def request_refresh(self, reason: str = 'api') -> None:
        """Ask the watcher to run a cycle at its next poll."""

        self.ensure_directories()
        _write_json(
            self.trigger_path,
            {'requested_at': utc_now().isoformat(), 'reason': reason})

    def consume_refresh(self) -> str | None:
        """Take a pending refresh request, if there is one."""

        if not self.trigger_path.is_file():
            return None
        try:
            with self.trigger_path.open('r', encoding='utf-8') as handle:
                payload = json.load(handle)
            reason = str(payload.get('reason', 'unknown'))
        except (OSError, json.JSONDecodeError):
            reason = 'unknown'
        self.trigger_path.unlink(missing_ok=True)
        return reason

    # -- Cancellation ------------------------------------------------------

    # A cancellation is a marker file rather than a signal, for the same
    # reason a refresh is: the API process holds no reference to the watcher
    # and may not even share a machine with it. The watcher reads the marker
    # at the safe points in a cycle and abandons the work in hand.

    @property
    def cancel_path(self) -> Path:
        """The file the API touches to ask for the current run to stop."""

        return self.state_dir / _CANCEL_FILE

    def request_cancel(self, reason: str = 'api') -> None:
        """Ask the watcher to abandon the run in hand."""

        self.ensure_directories()
        _write_json(
            self.cancel_path,
            {'requested_at': utc_now().isoformat(), 'reason': reason})

    def cancel_requested(self) -> bool:
        """Whether a cancellation is waiting to be acted on.

        Only asks whether the marker is there; the cycle calls this often, and
        the answer must not consume the request that a later check also needs.
        """

        return self.cancel_path.is_file()

    def consume_cancel(self) -> str | None:
        """Take a pending cancellation, if there is one."""

        if not self.cancel_path.is_file():
            return None
        try:
            with self.cancel_path.open('r', encoding='utf-8') as handle:
                payload = json.load(handle)
            reason = str(payload.get('reason', 'unknown'))
        except (OSError, json.JSONDecodeError):
            reason = 'unknown'
        self.cancel_path.unlink(missing_ok=True)
        return reason

    def clear_cancel(self) -> None:
        """Drop any pending cancellation without acting on it.

        Called before a cycle begins, so a request that arrived while nothing
        was running cannot reach forward and stop the next run instead.
        """

        self.cancel_path.unlink(missing_ok=True)

    # -- The run in progress -----------------------------------------------

    @property
    def active_path(self) -> Path:
        """Where the run in progress announces itself."""

        return self.state_dir / _ACTIVE_FILE

    def mark_run_started(self, identifier: str) -> None:
        """Record that a cycle has begun, so the API can say so."""

        self.ensure_directories()
        _write_json(
            self.active_path,
            {'run_id': identifier, 'started_at': utc_now().isoformat()})

    def mark_run_finished(self) -> None:
        """Record that no cycle is in progress."""

        self.active_path.unlink(missing_ok=True)

    def read_active_run(self) -> dict[str, Any] | None:
        """The run in progress, or None when the analyser is idle.

        The marker is left behind if the process is killed mid-cycle, so a
        caller that cares about liveness should treat a stale entry as a
        report of the last run attempted rather than as proof of activity.
        """

        if not self.active_path.is_file():
            return None
        try:
            with self.active_path.open('r', encoding='utf-8') as handle:
                return json.load(handle)
        except (OSError, json.JSONDecodeError) as exc:
            log.warning('ignoring unreadable active-run file %s: %s',
                        self.active_path, exc)
            return None

    # -- Results -----------------------------------------------------------

    @property
    def latest_path(self) -> Path:
        """The results document the front end reads."""

        return self.results_dir / _LATEST_FILE

    def write_results(self, document: dict[str, Any]) -> Path:
        """Write one run, refresh `latest.json` and prune the history."""

        self.ensure_directories()
        identifier = document.get('run_id') or run_id()
        run_path = self.results_dir / f'run-{identifier}.json'
        _write_json(run_path, document)
        _write_json(self.latest_path, document)
        self._prune()
        return run_path

    def read_latest(self) -> dict[str, Any] | None:
        """The most recent results document, or None before the first run."""

        if not self.latest_path.is_file():
            return None
        with self.latest_path.open('r', encoding='utf-8') as handle:
            return json.load(handle)

    def list_runs(self) -> list[str]:
        """The identifiers of the stored runs, newest first."""

        return sorted(
            (path.stem[len('run-'):] for path in
             self.results_dir.glob('run-*.json')),
            reverse=True,
        )

    def read_run(self, identifier: str) -> dict[str, Any] | None:
        """One stored run by identifier."""

        path = self.results_dir / f'run-{identifier}.json'
        if not path.is_file():
            return None
        with path.open('r', encoding='utf-8') as handle:
            return json.load(handle)

    def chart_path(self, name: str) -> Path:
        """Where a chart with the given name is written."""

        return self.charts_dir / f'{name}.png'

    def _prune(self) -> None:
        keep = max(1, self._config.output.keep_runs)
        runs = sorted(self.results_dir.glob('run-*.json'), reverse=True)
        for stale in runs[keep:]:
            try:
                stale.unlink()
            except OSError as exc:
                log.warning('could not remove old run %s: %s', stale, exc)


def _write_json(path: Path, payload: Any) -> None:
    """Write JSON via a temporary file so a reader never sees a partial one."""

    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + '.tmp')
    with temporary.open('w', encoding='utf-8') as handle:
        json.dump(payload, handle, indent=2, sort_keys=False)
        handle.write('\n')
    temporary.replace(path)
