"""An authenticated HTTP client for a Community Solid Server.

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

# The Flutter libraries log in interactively through Solid-OIDC, which no daemon
# can do. A headless agent instead uses the client credentials the server issues
# for its account, exchanges them for a DPoP-bound access token, and signs every
# subsequent request with a proof of possession. The DPoP mechanics here match
# `solidpod/example/loadtest/solid_load_test.py`, which exercises the same server.

from __future__ import annotations

import base64
import hashlib
import json
import logging
import secrets
import time
from typing import Any
from urllib.parse import quote, urlsplit, urlunsplit

import httpx
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec, utils as asym_utils

from . import turtle

log = logging.getLogger(__name__)

# Content types used when writing to a Pod.

TURTLE = 'text/turtle'
SPARQL_UPDATE = 'application/sparql-update'

# Link headers telling the server whether to create a file or a container.

_FILE_LINK = '<http://www.w3.org/ns/ldp#Resource>; rel="type"'
_CONTAINER_LINK = '<http://www.w3.org/ns/ldp#BasicContainer>; rel="type"'


class SolidError(Exception):
    """Raised when the server refuses a request."""

    def __init__(self, message: str, status_code: int | None = None) -> None:
        super().__init__(message)
        self.status_code = status_code


class NotFoundError(SolidError):
    """Raised when a resource does not exist."""


class ForbiddenError(SolidError):
    """Raised when the Analyser is not allowed to touch a resource."""


def _b64url(data: bytes) -> str:
    """Base64url without padding, as JOSE requires."""

    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('ascii')


def _htu(url: str) -> str:
    """The `htu` claim: the request URL without query string or fragment."""

    parts = urlsplit(url)
    return urlunsplit((parts.scheme, parts.netloc, parts.path, '', ''))


class DpopKey:
    """The EC P-256 key pair that binds our access token to this process."""

    def __init__(self) -> None:
        self._key = ec.generate_private_key(ec.SECP256R1())
        numbers = self._key.public_key().public_numbers()
        self.jwk = {
            'kty': 'EC',
            'crv': 'P-256',
            'x': _b64url(numbers.x.to_bytes(32, 'big')),
            'y': _b64url(numbers.y.to_bytes(32, 'big')),
        }

    def proof(
        self,
        method: str,
        url: str,
        *,
        nonce: str | None = None,
        access_token: str | None = None,
    ) -> str:
        """Sign a single-use DPoP proof for one request."""

        header = {'typ': 'dpop+jwt', 'alg': 'ES256', 'jwk': self.jwk}
        payload: dict[str, Any] = {
            'htu': _htu(url),
            'htm': method.upper(),
            'jti': _b64url(secrets.token_bytes(16)),
            'iat': int(time.time()),
        }
        if nonce is not None:
            payload['nonce'] = nonce
        if access_token is not None:
            payload['ath'] = _b64url(
                hashlib.sha256(access_token.encode('ascii')).digest())

        signing_input = (
            _b64url(json.dumps(header, separators=(',', ':')).encode())
            + '.'
            + _b64url(json.dumps(payload, separators=(',', ':')).encode())
        )
        der = self._key.sign(
            signing_input.encode('ascii'), ec.ECDSA(hashes.SHA256()))
        r, s = asym_utils.decode_dss_signature(der)
        raw = r.to_bytes(32, 'big') + s.to_bytes(32, 'big')
        return signing_input + '.' + _b64url(raw)


class SolidClient:
    """A synchronous, token-refreshing client for one Solid server."""

    def __init__(
        self,
        server_url: str,
        client_id: str,
        client_secret: str,
        *,
        timeout: float = 30.0,
    ) -> None:
        self._server = server_url.rstrip('/')
        self._client_id = client_id
        self._client_secret = client_secret
        self._http = httpx.Client(timeout=timeout, follow_redirects=True)
        self._dpop = DpopKey()
        self._token: str | None = None
        self._token_expiry = 0.0
        self._nonce: str | None = None

    # -- Lifecycle ---------------------------------------------------------

    def close(self) -> None:
        """Release the underlying connection pool."""

        self._http.close()

    def __enter__(self) -> 'SolidClient':
        self.login()
        return self

    def __exit__(self, exc_type, exc, tb) -> bool:
        self.close()
        return False

    # -- Authentication ----------------------------------------------------

    def _token_endpoint(self) -> str:
        url = f'{self._server}/.well-known/openid-configuration'
        response = self._http.get(url, headers={'Accept': 'application/json'})
        if response.status_code != 200:
            raise SolidError(
                f'cannot read {url}: HTTP {response.status_code}',
                response.status_code)
        endpoint = response.json().get('token_endpoint')
        if not endpoint:
            raise SolidError('server metadata has no token_endpoint')
        return endpoint

    def login(self) -> None:
        """Exchange the client credentials for a DPoP-bound access token."""

        endpoint = self._token_endpoint()
        # CSS expects each half of the credential pair to be URL-encoded
        # before it is folded into the Basic authorisation header.
        basic = base64.b64encode(
            f'{quote(self._client_id)}:{quote(self._client_secret)}'.encode()
        ).decode()

        def attempt(nonce: str | None) -> httpx.Response:
            return self._http.post(
                endpoint,
                headers={
                    'Authorization': f'Basic {basic}',
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'DPoP': self._dpop.proof('POST', endpoint, nonce=nonce),
                },
                content='grant_type=client_credentials&scope=webid',
            )

        response = attempt(None)
        if response.status_code in (400, 401) and 'DPoP-Nonce' in response.headers:
            response = attempt(response.headers['DPoP-Nonce'])
        if response.status_code != 200:
            raise SolidError(
                f'login failed: HTTP {response.status_code}: '
                f'{response.text[:200]}', response.status_code)

        body = response.json()
        self._token = body['access_token']
        # Refresh a minute early so a long analysis cycle never runs into an
        # expiry part way through.
        self._token_expiry = time.time() + float(body.get('expires_in', 300)) - 60
        log.debug('obtained an access token, valid for %ss',
                  body.get('expires_in'))

    def _ensure_token(self) -> str:
        if self._token is None or time.time() >= self._token_expiry:
            self.login()
        assert self._token is not None
        return self._token

    # -- Requests ----------------------------------------------------------

    def request(
        self,
        method: str,
        url: str,
        *,
        content: bytes | None = None,
        content_type: str | None = None,
        headers: dict[str, str] | None = None,
    ) -> httpx.Response:
        """Issue a DPoP-authenticated request, handling nonces and expiry."""

        def attempt(nonce: str | None, token: str) -> httpx.Response:
            request_headers = {
                'Authorization': f'DPoP {token}',
                'DPoP': self._dpop.proof(
                    method, url, nonce=nonce, access_token=token),
            }
            if content_type is not None:
                request_headers['Content-Type'] = content_type
            if headers:
                request_headers.update(headers)
            return self._http.request(
                method, url, headers=request_headers, content=content)

        token = self._ensure_token()
        response = attempt(self._nonce, token)

        if response.status_code == 401 and 'DPoP-Nonce' in response.headers:
            self._nonce = response.headers['DPoP-Nonce']
            response = attempt(self._nonce, token)

        if response.status_code == 401:
            # The token itself has gone stale; get a new one and try once more.
            self.login()
            token = self._ensure_token()
            response = attempt(self._nonce, token)

        if 'DPoP-Nonce' in response.headers:
            self._nonce = response.headers['DPoP-Nonce']
        return response

    def _check(self, response: httpx.Response, what: str) -> httpx.Response:
        if response.status_code == 404:
            raise NotFoundError(f'{what}: not found', 404)
        if response.status_code in (401, 403):
            raise ForbiddenError(
                f'{what}: access denied (HTTP {response.status_code})',
                response.status_code)
        if not 200 <= response.status_code < 300:
            raise SolidError(
                f'{what}: HTTP {response.status_code}: {response.text[:200]}',
                response.status_code)
        return response

    # -- Reading -----------------------------------------------------------

    def get_text(self, url: str, *, accept: str = 'text/turtle') -> str:
        """Fetch a resource as text."""

        response = self.request('GET', url, headers={'Accept': accept})
        return self._check(response, f'read {url}').text

    def get_text_or_none(self, url: str, *, accept: str = 'text/turtle') -> str | None:
        """Fetch a resource, or return None when it does not exist."""

        try:
            return self.get_text(url, accept=accept)
        except NotFoundError:
            return None

    def exists(self, url: str) -> bool:
        """Whether a resource is there at all.

        A 403 counts as present: the server is saying the resource exists but
        is not ours to look at, which is the normal answer for another Pod's
        private containers. Treating it as absent would have us try to create
        a container that is already there, and fail.
        """

        response = self.request('HEAD', url)
        if response.status_code == 403:
            return True

        return 200 <= response.status_code < 300

    def etag(self, url: str) -> str | None:
        """The entity tag of a resource, used to spot changes cheaply."""

        response = self.request('HEAD', url)
        if response.status_code == 404:
            return None
        if not 200 <= response.status_code < 300:
            return None
        return response.headers.get('etag') or response.headers.get('last-modified')

    def list_container(self, url: str) -> list[str]:
        """The URLs of the resources directly inside a container."""

        if not url.endswith('/'):
            url += '/'
        body = self.get_text(url)
        return turtle.contained_resources(body, url)

    # -- Writing -----------------------------------------------------------

    def put_text(self, url: str, content: str, *, content_type: str = TURTLE) -> None:
        """Create or replace a file."""

        response = self.request(
            'PUT', url,
            content=content.encode('utf-8'),
            content_type=content_type,
            headers={'Link': _FILE_LINK},
        )
        self._check(response, f'write {url}')

    def patch_sparql(self, url: str, query: str) -> None:
        """Apply a SPARQL update, as solidpod's `updateFileByQuery()` does."""

        response = self.request(
            'PATCH', url,
            content=query.encode('utf-8'),
            content_type=SPARQL_UPDATE,
            headers={'Accept': '*/*'},
        )
        self._check(response, f'patch {url}')

    def ensure_container(self, url: str) -> None:
        """Create a container if it is absent, including its parents.

        The empwr server does not create intermediate containers implicitly,
        so each level is provisioned in turn.
        """

        if not url.endswith('/'):
            url += '/'
        parts = urlsplit(url)
        segments = [s for s in parts.path.split('/') if s]

        # Start below the Pod root: the Pod itself always exists.
        for depth in range(1, len(segments) + 1):
            candidate = (
                f'{parts.scheme}://{parts.netloc}/'
                + '/'.join(segments[:depth]) + '/')
            if self.exists(candidate):
                continue
            response = self.request(
                'PUT', candidate,
                content=b'',
                content_type=TURTLE,
                headers={'Link': _CONTAINER_LINK},
            )
            if response.status_code in (401, 403):
                # A parent we may not create is fine as long as it is there.
                if self.exists(candidate):
                    continue
            if not (200 <= response.status_code < 300
                    or response.status_code == 409):
                raise SolidError(
                    f'create container {candidate}: '
                    f'HTTP {response.status_code}: {response.text[:200]}',
                    response.status_code)
