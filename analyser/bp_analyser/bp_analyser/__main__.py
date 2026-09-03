"""Command line for the blood pressure analyser.

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

# python3 -m bp_analyser --config config.yaml check      verify the set-up
# python3 -m bp_analyser --config config.yaml run-once   one analysis cycle
# python3 -m bp_analyser --config config.yaml watch      run continuously
# python3 -m bp_analyser --config config.yaml serve      the front-end API
# python3 -m bp_analyser --config config.yaml cancel     stop the run in hand
# python3 -m bp_analyser --config config.yaml show-config

from __future__ import annotations

import argparse
import json
import logging
import sys
from pathlib import Path

from . import charts, control, discovery, logs
from .config import Config, ConfigError, default_config_path, load
from .keys import KeyStoreError
from .service import AnalyserService
from .solid_client import SolidError
from .store import ResultStore

log = logging.getLogger('bp_analyser')


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog='bp_analyser',
        description='Average the blood pressure data Pods have shared with '
                    'the Analyser Pod, and share the results back.')
    parser.add_argument(
        '--config', '-c', default=None,
        help='path to the configuration file (default: ./config.yaml)')
    parser.add_argument(
        '--verbose', '-v', action='store_true', help='log at debug level')

    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser(
        'check', help='verify credentials, keys and what has been shared')
    commands.add_parser('run-once', help='run one analysis cycle and exit')
    commands.add_parser('watch', help='run cycles continuously')
    commands.add_parser('serve', help='serve the read-only front-end API')
    commands.add_parser(
        'cancel', help='ask a running watcher to abandon the current cycle')
    commands.add_parser(
        'show-config', help='print the effective configuration')
    return parser


def _load(args: argparse.Namespace) -> Config:
    path = Path(args.config) if args.config else default_config_path()
    config = load(path)
    logs.configure(config, verbose=args.verbose)
    for warning in config.warnings:
        log.warning(warning)
    return config


def _command_check(config: Config) -> int:
    """Walk through every prerequisite and report on each in turn."""

    for line in (
        f'Configuration:      {config.source_path}',
        f'Analyser WebID:     {config.analyser.web_id}',
        f'Server:             {config.analyser.server_url}',
        f'Application folder: {config.analyser.app_dir_name}',
    ):
        print(line, flush=True)

    config.require_credentials()
    service = AnalyserService(config)
    try:
        client, keys = service.connect()
        print('Login:              ok (client credentials, DPoP bound)')
        print(f'Pod unlocked:       ok (key derivation version '
              f'{keys.kdf_version})')

        shared = keys.shared_resources()
        print(f'Shared with us:     {len(shared)} resource(s)')
        for item in shared[:20]:
            kind = 'folder' if item.is_container else 'file'
            modes = ','.join(item.access_modes) or 'read'
            print(f'  - [{kind}] {item.resource_url} ({modes})')
        if len(shared) > 20:
            print(f'  ... and {len(shared) - 20} more')

        datasets = discovery.discover(client, shared, config)
        print(f'Contributing Pods:  {len(datasets)}')
        for dataset in datasets:
            print(f'  - {dataset.slug}: {dataset.resource_count} file(s)')

        cancels = control.CancelInbox(client, config)
        print(f'Cancel container:   '
              f'{cancels.container_url if cancels.enabled else "disabled"}')

        print(f'Charts:             '
              f'{"available" if charts.available() else "matplotlib not installed"}')
        store = ResultStore(config)
        print(f'Results directory:  {store.results_dir}')
        return 0
    finally:
        service.close()


def _command_run_once(config: Config) -> int:
    service = AnalyserService(config)

    # A marker left behind by a process that was killed mid-cycle would
    # otherwise stop this run before it began. The Pod holds its own markers,
    # which need a connection to clear, so that is done inside the try.

    service.store.clear_cancel()
    try:
        service.clear_pod_cancellations()
        outcome = service.run_cycle()
    finally:
        service.close()
    print(f'Run {outcome.document["run_id"]}: '
          f'{outcome.pod_count} Pod(s), '
          f'{outcome.observation_count} reading(s), '
          f'{outcome.shared_count} result(s) shared')
    print(f'Results written to {outcome.results_path}')
    return 0


def _command_watch(config: Config) -> int:
    service = AnalyserService(config)
    service.watch()
    return 0


def _command_serve(config: Config) -> int:
    try:
        import uvicorn
    except ImportError:
        print('uvicorn is not installed; run: pip install -r requirements.txt',
              file=sys.stderr)
        return 2

    from .api import create_app

    log.info('serving the front-end API on http://%s:%s',
             config.api.host, config.api.port)
    uvicorn.run(
        create_app(config),
        host=config.api.host,
        port=config.api.port,
        log_level='info',
    )
    return 0


def _command_cancel(config: Config) -> int:
    """Leave a cancellation marker for a watcher in another process.

    The same mechanism `POST /api/cancel` uses, for an operator who has a
    shell on the machine but no API. Reports what was running when the marker
    was written; whether that run then stops is the watcher's business, and it
    happens at its next checkpoint.
    """

    store = ResultStore(config)
    active = store.read_active_run()
    store.request_cancel('cli')

    if active:
        print(f'Cancellation requested; run {active.get("run_id")} '
              f'started at {active.get("started_at")} will stop at its next '
              f'checkpoint.')
    else:
        print('Cancellation requested; nothing is running, so any pending '
              'refresh will be withdrawn instead.')
    return 0


def _command_show_config(config: Config) -> int:
    redacted = {
        'analyser': {
            'web_id': config.analyser.web_id,
            'server_url': config.analyser.server_url,
            'app_dir_name': config.analyser.app_dir_name,
            'security_key': '(set)' if config.analyser.security_key else '(missing)',
            'client_id': '(set)' if config.analyser.client_id else '(missing)',
            'client_secret': (
                '(set)' if config.analyser.client_secret else '(missing)'),
        },
        'data': {'path_fragments': config.data.path_fragments},
        'analysis': {
            'minimum_observations': config.analysis.minimum_observations,
            'window_days': config.analysis.window_days,
        },
        'sharing': {
            'enabled': config.sharing.enabled,
            'results_dir': config.sharing.results_dir,
            'share_cohort_average': config.sharing.share_cohort_average,
            'encrypt_results': config.sharing.encrypt_results,
        },
        'watch': {
            'poll_seconds': config.watch.poll_seconds,
            'full_rescan_seconds': config.watch.full_rescan_seconds,
            'cancel_poll_seconds': config.watch.cancel_poll_seconds,
            'cancel_max_age_seconds': config.watch.cancel_max_age_seconds,
        },
        'output': {
            'state_dir': str(config.output.state_dir),
            'results_dir': str(config.output.results_dir),
            'charts_dir': str(config.output.charts_dir),
            'render_charts': config.output.render_charts,
        },
        'api': {
            'enabled': config.api.enabled,
            'host': config.api.host,
            'port': config.api.port,
            'token': '(set)' if config.api.token else '(none)',
        },
    }
    print(json.dumps(redacted, indent=2))
    return 0


def main(argv: list[str] | None = None) -> int:
    """Entry point; returns the process exit status."""

    args = _parser().parse_args(argv)

    try:
        config = _load(args)
    except ConfigError as exc:
        print(f'Configuration error: {exc}', file=sys.stderr)
        return 2

    handlers = {
        'check': _command_check,
        'run-once': _command_run_once,
        'watch': _command_watch,
        'serve': _command_serve,
        'cancel': _command_cancel,
        'show-config': _command_show_config,
    }

    try:
        return handlers[args.command](config)
    except ConfigError as exc:
        print(f'Configuration error: {exc}', file=sys.stderr)
        return 2
    except KeyStoreError as exc:
        print(f'Key error: {exc}', file=sys.stderr)
        return 3
    except SolidError as exc:
        print(f'Solid server error: {exc}', file=sys.stderr)
        return 4
    except KeyboardInterrupt:
        return 130


if __name__ == '__main__':
    sys.exit(main())
