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
#     GET  /api/status                  whether a run is in progress
#
# Adding a new view means adding a route here and a field to the results
# document; nothing else in the analyser needs to change.
#
# There is nothing here that writes. Starting an analysis and cancelling one
# are gRPC calls, answered by the process doing the work — see
# `grpc_server.py`. This once had `POST /api/refresh` and `POST /api/cancel`,
# which left marker files for a watcher to find on its next poll; with the
# watcher gone there is no watcher to find them, and the app has a faster and
# better authenticated road to the same two requests.

from __future__ import annotations

import logging
from typing import Any

from fastapi import FastAPI, HTTPException
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
            allow_methods=['GET'],
            allow_headers=['*'],
        )

    def latest() -> dict[str, Any]:
        document = store.read_latest()
        if document is None:
            raise HTTPException(
                status_code=503,
                detail='no analysis has been run yet')
        return document

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

    @app.get('/api/status')
    def status() -> dict[str, Any]:
        """Whether a cycle is running, and what happened to the last one.

        `running` is the marker the analysing process writes, so it is also
        left behind by a process killed mid-cycle; treat a long-standing entry
        as the last run attempted rather than as one still going. An app that
        wants a live answer asks the gRPC Status call, which is served from
        the memory of the process that would be doing the work.
        """

        state = store.read_state()
        return {
            'time': utc_now().isoformat(),
            'running': store.read_active_run(),
            'last_run': state.get('last_run'),
            'last_cancelled': state.get('last_cancelled'),
        }

    return app
