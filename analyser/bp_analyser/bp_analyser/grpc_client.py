"""Calling the analyser's gRPC interface from the command line.

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

# An operator with a shell on the host has the same three calls the app has,
# and `run.sh analyse`, `run.sh cancel` and `run.sh status` are how they reach
# them. That matters more than it sounds: with the watcher gone there is no
# other way to ask a running analyser for anything, and being able to make the
# exact call the app makes is what turns "the app says it is slow" into an
# answer.
#
# The channel connects to the address the server is configured to listen on,
# through the loopback interface when that address is a wildcard — the point
# of these commands is to reach the analyser on this host.

from __future__ import annotations

import logging
from collections.abc import Iterator
from contextlib import contextmanager

import grpc

from . import analyser_pb2 as pb
from . import analyser_pb2_grpc as pb_grpc
from .config import Config

log = logging.getLogger(__name__)

# How long to wait for a Cancel or a Status. Both are answered out of memory,
# so anything slower than this means the server is not there.

CONTROL_TIMEOUT = 10.0


def target(config: Config) -> str:
    """The address to dial for a server listening on this host.

    `0.0.0.0` and `::` are addresses to listen on, not to connect to; a client
    on the same host wants the loopback interface.
    """

    host = config.grpc.host
    if host in ('0.0.0.0', '::', ''):
        host = '127.0.0.1'
    return f'{host}:{config.grpc.port}'


@contextmanager
def channel(config: Config) -> Iterator['_Stub']:
    """A stub for the configured analyser, closed on the way out.

    TLS is used when the server is serving it, verifying against the
    certificate the server presents — which for a self-signed certificate
    means pointing `grpc.tls_cert_file` at the certificate itself, as a
    deployment on one host naturally does.
    """

    address = target(config)
    metadata = (
        [('authorization', f'Bearer {config.grpc.token}')]
        if config.grpc.token else [])

    if config.grpc.tls_enabled:
        assert config.grpc.tls_cert_file is not None
        credentials = grpc.ssl_channel_credentials(
            root_certificates=config.grpc.tls_cert_file.read_bytes())
        connection = grpc.secure_channel(address, credentials)
    else:
        connection = grpc.insecure_channel(address)

    try:
        yield _Stub(pb_grpc.AnalyserStub(connection), metadata)
    finally:
        connection.close()


class _Stub:
    """The generated stub with the shared secret attached to every call."""

    def __init__(self, stub: pb_grpc.AnalyserStub, metadata: list) -> None:
        self._stub = stub
        self._metadata = metadata

    def analyse(self, web_id: str, timeout: float) -> pb.AnalyseReply:
        """Ask for an analysis on behalf of [web_id] and wait for it."""

        return self._stub.Analyse(
            pb.AnalyseRequest(web_id=web_id),
            timeout=timeout,
            metadata=self._metadata,
        )

    def cancel(self, web_id: str) -> pb.CancelReply:
        """Ask for the analysis running for [web_id] to stop."""

        return self._stub.Cancel(
            pb.CancelRequest(web_id=web_id),
            timeout=CONTROL_TIMEOUT,
            metadata=self._metadata,
        )

    def status(self) -> pb.StatusReply:
        """Ask what the analyser is doing."""

        return self._stub.Status(
            pb.StatusRequest(),
            timeout=CONTROL_TIMEOUT,
            metadata=self._metadata,
        )


def unreachable(error: grpc.RpcError, address: str) -> str:
    """One line explaining a failed call, in terms an operator can act on."""

    code = error.code() if isinstance(error, grpc.Call) else None

    if code == grpc.StatusCode.UNAVAILABLE:
        return (f'nothing is listening on {address}. Is the analyser running? '
                f'Try "systemctl status healthpod-analyser".')
    if code == grpc.StatusCode.UNAUTHENTICATED:
        return ('the analyser rejected the token. Check grpc.token, or '
                '$HEALTHPOD_ANALYSER_GRPC_TOKEN.')
    if code == grpc.StatusCode.DEADLINE_EXCEEDED:
        return f'{address} did not answer in time.'

    detail = error.details() if isinstance(error, grpc.Call) else str(error)
    return f'the call to {address} failed: {detail}'
