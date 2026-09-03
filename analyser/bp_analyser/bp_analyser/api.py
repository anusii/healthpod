"""The read-only HTTP interface reserved for the front end.

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

# The analyser does its work whether or not this interface runs; the API only
# serves what the last cycle already wrote to disk, so it can be exposed to a
# front end without giving it any access to the Solid server or the Pod keys.
#
#     GET  /health                      liveness, and when the last run happened
#     GET  /api/summary                 the whole latest results document
#     GET  /api/cohort                  the cohort figures only
#     GET  /api/pods                    one entry per contributing Pod
#     GET  /api/pods/{pod_id}           one Pod's averages
#     GET  /api/pods/{pod_id}/chart.png that Pod's chart
#     GET  /api/runs                    identifiers of the stored runs
#     GET  /api/runs/{run_id}           one stored run
#     POST /api/refresh                 ask the watcher for a run (token guarded)
#     POST /api/cancel                  ask it to abandon one (token guarded)
#     GET  /api/status                  whether a run is in progress
#
# Adding a new view means adding a route here and a field to the results
# document; nothing else in the analyser needs to change.
#
# Neither of the POST routes does any work itself: each leaves a marker file
# in the state directory for the watching process to find. That is what lets
# the API run without credentials of its own, and it is why a cancellation is
# acted on at the watcher's next checkpoint rather than instantly.

from __future__ import annotations

import logging
from typing import Any

from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from .config import Config
from .store import ResultStore, utc_now

log = logging.getLogger(__name__)


def create_app(config: Config) -> FastAPI:
    """Build the FastAPI application for [config]."""

    store = ResultStore(config)
    app = FastAPI(
        title='HealthPod blood pressure analyser',
        summary='Cohort blood pressure averages computed from Solid Pods.',
        version='1.0.0',
    )

    if config.api.cors_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=config.api.cors_origins,
            allow_methods=['GET', 'POST'],
            allow_headers=['*'],
        )

    def latest() -> dict[str, Any]:
        document = store.read_latest()
        if document is None:
            raise HTTPException(
                status_code=503,
                detail='no analysis has been run yet')
        return document

    def require_token(authorization: str) -> None:
        """Reject a write request that does not carry `api.token`.

        Does nothing when no token is configured, which is the default and is
        safe only because the API binds to the loopback address unless it is
        deliberately moved.
        """

        if not config.api.token:
            return
        if authorization != f'Bearer {config.api.token}':
            raise HTTPException(status_code=401, detail='invalid token')

    def find_pod(document: dict[str, Any], pod_id: str) -> dict[str, Any]:
        for pod in document.get('pods', []):
            if pod.get('pod_id') == pod_id:
                return pod
        raise HTTPException(status_code=404, detail=f'unknown Pod: {pod_id}')

    @app.get('/health')
    def health() -> dict[str, Any]:
        """Liveness, plus a summary of the most recent run."""

        state = store.read_state()
        document = store.read_latest()
        return {
            'status': 'ok',
            'time': utc_now().isoformat(),
            'analyser_web_id': config.analyser.web_id,
            'last_run': state.get('last_run'),
            'last_cancelled': state.get('last_cancelled'),
            'running': store.read_active_run(),
            'has_results': document is not None,
        }

    @app.get('/api/summary')
    def summary() -> dict[str, Any]:
        """The complete results document from the latest run."""

        return latest()

    @app.get('/api/cohort')
    def cohort() -> dict[str, Any]:
        """The cohort average of averages and its companions."""

        document = latest()
        return {
            'run_id': document.get('run_id'),
            'generated_at': document.get('generated_at'),
            'cohort': document.get('cohort'),
        }

    @app.get('/api/pods')
    def pods() -> dict[str, Any]:
        """Every contributing Pod, with its averages."""

        document = latest()
        return {
            'run_id': document.get('run_id'),
            'generated_at': document.get('generated_at'),
            'pods': document.get('pods', []),
        }

    @app.get('/api/pods/{pod_id}')
    def pod(pod_id: str) -> dict[str, Any]:
        """One Pod's averages, alongside the cohort figures."""

        document = latest()
        return {
            'run_id': document.get('run_id'),
            'generated_at': document.get('generated_at'),
            'pod': find_pod(document, pod_id),
            'cohort': document.get('cohort'),
        }

    @app.get('/api/pods/{pod_id}/chart.png')
    def pod_chart(pod_id: str) -> FileResponse:
        """That Pod's readings over time, with the reference averages.

        The same image reaches the Pod itself inside the shared result, so
        this endpoint is for an operator or a front end that would rather
        fetch it directly than read it out of the Pod.
        """

        document = latest()
        find_pod(document, pod_id)
        path = store.chart_path(pod_id)
        if not path.is_file():
            raise HTTPException(
                status_code=404,
                detail='no chart for this Pod; is matplotlib installed and '
                       'output.render_charts enabled?')
        return FileResponse(path, media_type='image/png')

    @app.get('/api/runs')
    def runs() -> dict[str, Any]:
        """The identifiers of the stored runs, newest first."""

        return {'runs': store.list_runs()}

    @app.get('/api/runs/{run_id}')
    def run(run_id: str) -> dict[str, Any]:
        """One stored run in full."""

        document = store.read_run(run_id)
        if document is None:
            raise HTTPException(status_code=404, detail=f'unknown run: {run_id}')
        return document

    @app.post('/api/refresh')
    def refresh(authorization: str = Header(default='')) -> dict[str, Any]:
        """Ask the watcher to run a cycle at its next poll.

        Guarded by `api.token` when one is configured. The request only leaves
        a marker file behind; the watching process does the work, so the API
        never needs credentials of its own.
        """

        require_token(authorization)
        store.request_refresh('api')
        return {'status': 'accepted', 'requested_at': utc_now().isoformat()}

    @app.get('/api/status')
    def status() -> dict[str, Any]:
        """Whether a cycle is running, and what happened to the last one.

        The front end reads this to decide whether a cancellation would land
        on anything. `running` is the run marker the watcher writes, so it is
        also left behind by a process killed mid-cycle; treat a long-standing
        entry as the last run attempted rather than as one still going.
        """

        state = store.read_state()
        return {
            'time': utc_now().isoformat(),
            'running': store.read_active_run(),
            'cancel_pending': store.cancel_requested(),
            'last_run': state.get('last_run'),
            'last_cancelled': state.get('last_cancelled'),
        }

    @app.post('/api/cancel')
    def cancel(authorization: str = Header(default='')) -> dict[str, Any]:
        """Ask the watcher to abandon the run in progress.

        Guarded by `api.token` in the same way as `/api/refresh`, and works
        the same way: a marker file is left behind and the watcher acts on it
        at its next checkpoint, which is between two steps of the cycle
        rather than in the middle of one. A request that arrives while
        nothing is running withdraws any pending refresh instead, so pressing
        cancel just after pressing analyse does not simply defer the run.

        Answering `accepted` means the request was recorded, not that a cycle
        was stopped; `active` says whether one was in progress when it was.
        """

        require_token(authorization)
        active = store.read_active_run()
        store.request_cancel('api')
        log.info('cancellation requested via the API (running: %s)',
                 active.get('run_id') if active else 'nothing')
        return {
            'status': 'accepted',
            'requested_at': utc_now().isoformat(),
            'active': active,
        }

    return app
