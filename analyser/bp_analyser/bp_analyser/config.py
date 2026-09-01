"""Configuration for the blood pressure analyser.

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

# Everything the analyser needs to know lives in one YAML file (see
# `config.example.yaml`), including the address of the Analyser Pod itself. Any
# secret can instead be supplied through the environment, which is what the
# systemd unit does so that credentials never sit in a world-readable file:
#
#     HEALTHPOD_ANALYSER_SECURITY_KEY   the Analyser Pod's security key
#     HEALTHPOD_ANALYSER_CLIENT_ID      client credentials issued by the server
#     HEALTHPOD_ANALYSER_CLIENT_SECRET
#     HEALTHPOD_ANALYSER_API_TOKEN      token guarding the refresh endpoint

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml

from . import pod_paths as paths

ENV_SECURITY_KEY = 'HEALTHPOD_ANALYSER_SECURITY_KEY'
ENV_CLIENT_ID = 'HEALTHPOD_ANALYSER_CLIENT_ID'
ENV_CLIENT_SECRET = 'HEALTHPOD_ANALYSER_CLIENT_SECRET'
ENV_API_TOKEN = 'HEALTHPOD_ANALYSER_API_TOKEN'


class ConfigError(Exception):
    """Raised when the configuration file is missing or incoherent."""


@dataclass
class AnalyserConfig:
    """Identity and credentials of the Analyser Pod."""

    web_id: str
    app_dir_name: str = 'healthpod'
    server_url: str = ''
    security_key: str = ''
    client_id: str = ''
    client_secret: str = ''
    request_timeout: float = 30.0

    def __post_init__(self) -> None:
        if not self.web_id:
            raise ConfigError('analyser.web_id must be set')
        if not self.server_url:
            self.server_url = paths.server_of(self.web_id)
        self.server_url = self.server_url.rstrip('/')

    @property
    def pod_root(self) -> str:
        """The Analyser Pod root URL, with a trailing slash."""

        return paths.pod_root(self.web_id)


@dataclass
class DataConfig:
    """Which shared resources count as blood pressure data."""

    # A shared resource is analysed when its Pod-relative path contains any of
    # these fragments. The default matches HealthPod's blood pressure folder.

    path_fragments: list[str] = field(
        default_factory=lambda: ['/data/blood_pressure/'])

    # Field names inside the JSON written by HealthPod's survey.

    systolic_field: str = 'systolic'
    diastolic_field: str = 'diastolic'
    heart_rate_field: str = 'heart_rate'
    timestamp_field: str = 'timestamp'
    responses_field: str = 'responses'

    # Sanity bounds; readings outside these are ignored as data entry errors.

    systolic_range: tuple[float, float] = (40.0, 300.0)
    diastolic_range: tuple[float, float] = (20.0, 200.0)
    heart_rate_range: tuple[float, float] = (20.0, 250.0)


@dataclass
class AnalysisConfig:
    """How the averages are computed."""

    # Pods contributing fewer readings than this are reported but excluded
    # from the cohort average, so a single reading cannot skew it.

    minimum_observations: int = 1

    # Only consider readings from the last N days; null means all history.

    window_days: int | None = None

    decimal_places: int = 1


@dataclass
class SharingConfig:
    """How results are written back to the contributing Pods."""

    enabled: bool = True

    # Container inside the Analyser Pod's data directory holding the results.

    results_dir: str = 'analyser'

    # Whether each Pod also receives the cohort average of averages.

    share_cohort_average: bool = True

    # Whether a line is appended to each recipient's permission log, which is
    # what makes the result appear in HealthPod's "shared with me" list.

    write_permission_log: bool = True

    encrypt_results: bool = True


@dataclass
class WatchConfig:
    """How the service watches for new shares."""

    poll_seconds: int = 30

    # Zero (or less) switches the periodic run off, so the analysis happens
    # only when a Pod has shared something.

    full_rescan_seconds: int = 0
    run_on_start: bool = True
    error_backoff_seconds: int = 120

    # A user cancels an analysis by leaving a marker in the Analyser Pod's
    # `shared/` container, which is the one place an app can write to without
    # being granted anything first. Reading it costs one request, so a cycle
    # looks no more often than this.

    cancel_poll_seconds: float = 3.0

    # How long a cancellation stays honourable. The container is publicly
    # writable, so a marker nobody collected must not sit there waiting to
    # stop an unrelated run hours later. Zero switches the Pod channel off,
    # leaving only `POST /api/cancel`.

    cancel_max_age_seconds: int = 600


@dataclass
class OutputConfig:
    """Where local state, results and charts are written."""

    state_dir: Path = Path('var/state')
    results_dir: Path = Path('var/results')
    charts_dir: Path = Path('var/charts')
    render_charts: bool = True
    keep_runs: int = 50


@dataclass
class ApiConfig:
    """The read-only HTTP interface reserved for the front end."""

    enabled: bool = False
    host: str = '127.0.0.1'
    port: int = 8088
    cors_origins: list[str] = field(default_factory=list)

    # When set, `POST /api/refresh` requires `Authorization: Bearer <token>`.

    token: str = ''


@dataclass
class LoggingConfig:
    """Logging destination and verbosity."""

    level: str = 'INFO'
    file: Path | None = None


@dataclass
class Config:
    """The whole configuration, as loaded from one YAML file."""

    analyser: AnalyserConfig
    data: DataConfig = field(default_factory=DataConfig)
    analysis: AnalysisConfig = field(default_factory=AnalysisConfig)
    sharing: SharingConfig = field(default_factory=SharingConfig)
    watch: WatchConfig = field(default_factory=WatchConfig)
    output: OutputConfig = field(default_factory=OutputConfig)
    api: ApiConfig = field(default_factory=ApiConfig)
    logging: LoggingConfig = field(default_factory=LoggingConfig)
    source_path: Path | None = None

    # Non-fatal problems noticed while loading, reported by the caller once
    # logging is set up. Loose permissions on a file holding secrets is the
    # one that matters in practice.

    warnings: list[str] = field(default_factory=list)

    def require_credentials(self) -> None:
        """Fail early, and with a useful message, when a secret is missing."""

        missing = []
        if not self.analyser.client_id:
            missing.append(f'analyser.credentials.client_id (${ENV_CLIENT_ID})')
        if not self.analyser.client_secret:
            missing.append(
                f'analyser.credentials.client_secret (${ENV_CLIENT_SECRET})')
        if not self.analyser.security_key:
            missing.append(f'analyser.security_key (${ENV_SECURITY_KEY})')
        if missing:
            raise ConfigError(
                'missing credentials: ' + ', '.join(missing)
                + '. See README.md, section "Preparing the Analyser Pod".')


def _resolve(base: Path, value: Any, default: Path) -> Path:
    """Resolve a configured directory against the config file's own folder."""

    path = Path(value).expanduser() if value else default
    return path if path.is_absolute() else (base / path).resolve()


def load(path: str | Path) -> Config:
    """Load and validate the configuration file at [path]."""

    config_path = Path(path).expanduser().resolve()
    if not config_path.is_file():
        raise ConfigError(f'configuration file not found: {config_path}')

    with config_path.open('r', encoding='utf-8') as handle:
        raw = yaml.safe_load(handle) or {}
    if not isinstance(raw, dict):
        raise ConfigError(f'{config_path} does not contain a YAML mapping')

    base = config_path.parent
    analyser_raw = dict(raw.get('analyser') or {})
    credentials = dict(analyser_raw.pop('credentials', None) or {})

    analyser = AnalyserConfig(
        web_id=str(analyser_raw.get('web_id', '')).strip(),
        app_dir_name=str(analyser_raw.get('app_dir_name', 'healthpod')).strip(),
        server_url=str(analyser_raw.get('server_url', '') or '').strip(),
        security_key=(
            os.environ.get(ENV_SECURITY_KEY)
            or str(analyser_raw.get('security_key', '') or '')),
        client_id=(
            os.environ.get(ENV_CLIENT_ID)
            or str(credentials.get('client_id', '') or '')),
        client_secret=(
            os.environ.get(ENV_CLIENT_SECRET)
            or str(credentials.get('client_secret', '') or '')),
        request_timeout=float(analyser_raw.get('request_timeout', 30.0)),
    )

    data_raw = raw.get('data') or {}
    data = DataConfig(
        path_fragments=list(
            data_raw.get('path_fragments') or ['/data/blood_pressure/']),
        systolic_field=str(data_raw.get('systolic_field', 'systolic')),
        diastolic_field=str(data_raw.get('diastolic_field', 'diastolic')),
        heart_rate_field=str(data_raw.get('heart_rate_field', 'heart_rate')),
        timestamp_field=str(data_raw.get('timestamp_field', 'timestamp')),
        responses_field=str(data_raw.get('responses_field', 'responses')),
    )
    for name in ('systolic', 'diastolic', 'heart_rate'):
        bounds = data_raw.get(f'{name}_range')
        if bounds:
            setattr(data, f'{name}_range', (float(bounds[0]), float(bounds[1])))

    analysis_raw = raw.get('analysis') or {}
    analysis = AnalysisConfig(
        minimum_observations=int(analysis_raw.get('minimum_observations', 1)),
        window_days=(
            int(analysis_raw['window_days'])
            if analysis_raw.get('window_days') else None),
        decimal_places=int(analysis_raw.get('decimal_places', 1)),
    )

    sharing_raw = raw.get('sharing') or {}
    sharing = SharingConfig(
        enabled=bool(sharing_raw.get('enabled', True)),
        results_dir=str(sharing_raw.get('results_dir', 'analyser')).strip('/'),
        share_cohort_average=bool(sharing_raw.get('share_cohort_average', True)),
        write_permission_log=bool(sharing_raw.get('write_permission_log', True)),
        encrypt_results=bool(sharing_raw.get('encrypt_results', True)),
    )

    watch_raw = raw.get('watch') or {}
    watch = WatchConfig(
        poll_seconds=int(watch_raw.get('poll_seconds', 30)),
        full_rescan_seconds=int(watch_raw.get('full_rescan_seconds') or 0),
        run_on_start=bool(watch_raw.get('run_on_start', True)),
        error_backoff_seconds=int(watch_raw.get('error_backoff_seconds', 120)),
        cancel_poll_seconds=float(watch_raw.get('cancel_poll_seconds', 3.0)),
        cancel_max_age_seconds=int(
            watch_raw.get('cancel_max_age_seconds', 600)),
    )

    output_raw = raw.get('output') or {}
    output = OutputConfig(
        state_dir=_resolve(base, output_raw.get('state_dir'), base / 'var/state'),
        results_dir=_resolve(
            base, output_raw.get('results_dir'), base / 'var/results'),
        charts_dir=_resolve(
            base, output_raw.get('charts_dir'), base / 'var/charts'),
        render_charts=bool(output_raw.get('render_charts', True)),
        keep_runs=int(output_raw.get('keep_runs', 50)),
    )

    api_raw = raw.get('api') or {}
    api = ApiConfig(
        enabled=bool(api_raw.get('enabled', False)),
        host=str(api_raw.get('host', '127.0.0.1')),
        port=int(api_raw.get('port', 8088)),
        cors_origins=list(api_raw.get('cors_origins') or []),
        token=os.environ.get(ENV_API_TOKEN) or str(api_raw.get('token', '') or ''),
    )

    logging_raw = raw.get('logging') or {}
    log_file = logging_raw.get('file')
    logs = LoggingConfig(
        level=str(logging_raw.get('level', 'INFO')).upper(),
        file=_resolve(base, log_file, base / 'var/analyser.log') if log_file else None,
    )

    config = Config(
        analyser=analyser,
        data=data,
        analysis=analysis,
        sharing=sharing,
        watch=watch,
        output=output,
        api=api,
        logging=logs,
        source_path=config_path,
    )
    config.warnings.extend(_permission_warnings(config_path, config))
    return config


def _permission_warnings(path: Path, config: Config) -> list[str]:
    """Warn when a configuration file holding secrets is widely readable.

    Secrets supplied through the environment are not the file's problem, so
    only secrets that actually came from the file are considered. The mode is
    checked rather than the ownership: whoever can read the file can read the
    security key, which unlocks every resource shared with the Analyser.
    """

    in_file = [
        name for name, value, variable in (
            ('analyser.security_key', config.analyser.security_key, ENV_SECURITY_KEY),
            ('analyser.credentials.client_id', config.analyser.client_id, ENV_CLIENT_ID),
            ('analyser.credentials.client_secret', config.analyser.client_secret,
             ENV_CLIENT_SECRET),
            ('api.token', config.api.token, ENV_API_TOKEN),
        )
        if value and not os.environ.get(variable)
    ]
    if not in_file:
        return []

    try:
        mode = path.stat().st_mode & 0o777
    except OSError:
        return []

    if not mode & 0o077:
        return []

    return [
        f'{path} holds secrets ({", ".join(in_file)}) and is readable by '
        f'other accounts (mode {mode:03o}). Run "chmod 600 {path.name}", or '
        f'better, move the secrets into the environment — see README.md, '
        f'section "Configuration".'
    ]


def default_config_path() -> Path:
    """Where the analyser looks for its configuration when none is given.

    `config.yaml` lives in the project root, one level above this package,
    beside `run.sh` and the tests.
    """

    from_env = os.environ.get('HEALTHPOD_ANALYSER_CONFIG')
    if from_env:
        return Path(from_env).expanduser()
    return Path(__file__).resolve().parent.parent / 'config.yaml'
