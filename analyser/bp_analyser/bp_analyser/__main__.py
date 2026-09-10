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

# python3 -m bp_analyser --config config.yaml check       verify the set-up
# python3 -m bp_analyser --config config.yaml run-once    one analysis cycle
# python3 -m bp_analyser --config config.yaml grpc        serve the app
# python3 -m bp_analyser --config config.yaml serve       the front-end API
# python3 -m bp_analyser --config config.yaml analyse WEBID   as the app does
# python3 -m bp_analyser --config config.yaml cancel WEBID    stop that run
# python3 -m bp_analyser --config config.yaml status      ask a running server
# python3 -m bp_analyser --config config.yaml show-config
#
# `grpc` is the mode systemd runs: the analyser waits for an app to ask for an
# analysis and does nothing until one does. `analyse`, `cancel` and `status`
# are clients of that server rather than of the Pod, so they answer only while
# it is running — which is the point of them.

from __future__ import annotations

import argparse
import json
import logging
import sys
from pathlib import Path

import grpc

from . import analyser_pb2 as pb
from . import charts, discovery, grpc_client, logs
from .config import Config, ConfigError, default_config_path, load
from .grpc_server import serve as serve_grpc
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
    commands.add_parser(
        'run-once',
        help='run one analysis cycle for every contributing Pod and exit')
    commands.add_parser(
        'grpc', help='serve the gRPC interface the app calls')
    commands.add_parser('serve', help='serve the read-only front-end API')

    analyse = commands.add_parser(
        'analyse',
        help='ask a running gRPC server for an analysis, as the app does')
    analyse.add_argument('web_id', help="the calling Pod's WebID")
    analyse.add_argument(
        '--timeout', type=float, default=None,
        help='seconds to wait for the analysis '
             '(default: grpc.analysis_timeout_seconds)')

    cancel = commands.add_parser(
        'cancel', help='ask it to abandon the analysis running for a Pod')
    cancel.add_argument('web_id', help="the Pod whose analysis to stop")

    commands.add_parser(
        'status', help='ask a running gRPC server what it is doing')
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

        print(f'gRPC interface:     {config.grpc.address}'
              f'{" (TLS)" if config.grpc.tls_enabled else ""}'
              f'{", token required" if config.grpc.token else ""}')

        print(f'Charts:             '
              f'{"available" if charts.available() else "matplotlib not installed"}')
        store = ResultStore(config)
        print(f'Results directory:  {store.results_dir}')
        return 0
    finally:
        service.close()


def _command_run_once(config: Config) -> int:
    """One cycle for every contributing Pod, with nobody waiting on it.

    Kept for an operator who wants a recompute without an app: no caller means
    no focus Pod, so every contributor gets a chart and a result, which is
    what the analyser used to do on every cycle. Nothing can cancel this one —
    a cancellation is a call to a running gRPC server, and this is not one.
    """

    service = AnalyserService(config)
    try:
        outcome = service.run_cycle()
    finally:
        service.close()
    print(f'Run {outcome.document["run_id"]}: '
          f'{outcome.pod_count} Pod(s), '
          f'{outcome.observation_count} reading(s), '
          f'{outcome.shared_count} result(s) shared')
    print(f'Results written to {outcome.results_path}')
    return 0


def _command_grpc(config: Config) -> int:
    """Serve the interface the app calls, and analyse when it asks."""

    return serve_grpc(config)


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


def _command_analyse(config: Config, web_id: str, timeout: float | None) -> int:
    """Make the call the app makes, and print what came back.

    The most useful thing in the box when somebody reports that an analysis is
    slow or empty: it exercises the whole path — the gRPC call, the Pod reads,
    the chart, the publication — as the app does, and prints the reply the app
    would have acted on.
    """

    address = grpc_client.target(config)
    wait = timeout or float(config.grpc.analysis_timeout_seconds)

    try:
        with grpc_client.channel(config) as stub:
            reply = stub.analyse(web_id, timeout=wait)
    except grpc.RpcError as error:
        print(grpc_client.unreachable(error, address), file=sys.stderr)
        return 4

    print(f'Status:             {pb.AnalyseStatus.Name(reply.status)}')
    if reply.run_id:
        print(f'Run:                {reply.run_id}')
    if reply.generated_at:
        print(f'Generated at:       {reply.generated_at}')
    if reply.status == pb.ANALYSE_STATUS_COMPLETED:
        print(f'Observations:       {reply.observation_count}')
        print(f'Files read:         {reply.files_read} '
              f'({reply.files_skipped} skipped)')
        print(f'Contributing Pods:  {reply.pod_count}')
        print(f'Published:          '
              f'{"yes" if reply.published else "no"}')
        print(f'Result:             {reply.result_url or "(not published)"}')
    if reply.message:
        print(f'Message:            {reply.message}')

    return 0 if reply.status == pb.ANALYSE_STATUS_COMPLETED else 1


def _command_cancel(config: Config, web_id: str) -> int:
    """Ask a running server to abandon the analysis for one Pod.

    The same call the app's cancel button makes. It is answered out of memory,
    so the reply says whether there was anything to stop; the run itself ends
    at its next checkpoint, typically within a second.
    """

    address = grpc_client.target(config)

    try:
        with grpc_client.channel(config) as stub:
            reply = stub.cancel(web_id)
    except grpc.RpcError as error:
        print(grpc_client.unreachable(error, address), file=sys.stderr)
        return 4

    if reply.status == pb.CANCEL_STATUS_STOPPED:
        print(f'Run {reply.run_id} has been told to stop; it will do so at '
              f'its next checkpoint.')
    else:
        print(reply.message
              or f'Nothing was running for {web_id}.')
    return 0


def _command_status(config: Config) -> int:
    """Ask a running server what it is doing."""

    address = grpc_client.target(config)

    try:
        with grpc_client.channel(config) as stub:
            reply = stub.status()
    except grpc.RpcError as error:
        print(grpc_client.unreachable(error, address), file=sys.stderr)
        return 4

    print(f'Analyser:           {reply.analyser_web_id}')
    print(f'Address:            {address}')
    print(f'Ready:              {"yes" if reply.ready else "no"}')
    if reply.message:
        print(f'Why not:            {reply.message}')
    print(f'Analyses in hand:   {reply.active_runs}')
    print(f'Last run:           {reply.last_run_id or "(none yet)"}'
          f'{" at " + reply.last_run_at if reply.last_run_at else ""}')
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
        'grpc': {
            'host': config.grpc.host,
            'port': config.grpc.port,
            'max_workers': config.grpc.max_workers,
            'analysis_timeout_seconds': config.grpc.analysis_timeout_seconds,
            'token': '(set)' if config.grpc.token else '(none)',
            'tls_cert_file': (
                str(config.grpc.tls_cert_file)
                if config.grpc.tls_cert_file else None),
            'tls_key_file': (
                str(config.grpc.tls_key_file)
                if config.grpc.tls_key_file else None),
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

    def dispatch() -> int:
        match args.command:
            case 'check':
                return _command_check(config)
            case 'run-once':
                return _command_run_once(config)
            case 'grpc':
                return _command_grpc(config)
            case 'serve':
                return _command_serve(config)
            case 'analyse':
                return _command_analyse(config, args.web_id, args.timeout)
            case 'cancel':
                return _command_cancel(config, args.web_id)
            case 'status':
                return _command_status(config)
            case _:
                return _command_show_config(config)

    try:
        return dispatch()
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
