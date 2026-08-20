"""The Analyser Pod's keys, and the keys other Pods have shared with it.

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

# `PodKeys` is the analyser's view of the solidpod key files:
#
#   * `encryption/enc-keys.ttl` unlocks the Pod. The security key is stretched
#     into the master key, checked against the verification value stored there,
#     and used to open the RSA private key.
#   * `shared/shared-keys.ttl` is the inbox for sharing. Every time a Pod grants
#     the Analyser access to an encrypted resource, an entry lands here holding
#     the resource URL, the permissions and the resource key, each sealed with
#     the Analyser's public key. Reading this file is therefore how the analyser
#     learns that a new Pod has shared its blood pressure data.
#   * `encryption/ind-keys.ttl` records the keys of resources the Analyser itself
#     has written, so that results can be re-read and re-shared later.

from __future__ import annotations

import base64
import logging
from dataclasses import dataclass

from cryptography.hazmat.primitives.asymmetric.rsa import (
    RSAPrivateKey,
    RSAPublicKey,
)

from . import crypto, pod_paths as paths, turtle
from .config import Config
from .solid_client import NotFoundError, SolidClient

log = logging.getLogger(__name__)


class KeyStoreError(Exception):
    """Raised when a key file is missing, malformed or cannot be unlocked."""


@dataclass
class SharedResource:
    """One entry from the shared-keys file: a resource another Pod shared."""

    unique_id: str
    resource_url: str
    access_modes: list[str]
    key: bytes

    # The raw, still-sealed values, needed to delete the entry again.

    sealed_path: str
    sealed_access: str
    sealed_key: str

    @property
    def is_container(self) -> bool:
        """Whether a whole folder was shared rather than a single file."""

        return self.resource_url.endswith('/')


def _predicate(name: str, namespace: str = paths.APPS_TERMS) -> str:
    return namespace + name


class PodKeys:
    """Key material for the Analyser Pod, loaded lazily and then cached."""

    def __init__(self, client: SolidClient, config: Config) -> None:
        self._client = client
        self._config = config
        self._web_id = config.analyser.web_id
        self._app = config.analyser.app_dir_name

        self._master_key: bytes | None = None
        self._private_key: RSAPrivateKey | None = None
        self._kdf_version: int | None = None
        self._public_keys: dict[str, RSAPublicKey] = {}

    # -- Unlocking ---------------------------------------------------------

    @property
    def kdf_version(self) -> int | None:
        """Which key-derivation scheme the Analyser Pod uses (1 or 2)."""

        return self._kdf_version

    def unlock(self) -> None:
        """Derive the master key and open the RSA private key.

        Raises [KeyStoreError] with an actionable message when the security key is
        wrong, which is by far the most common misconfiguration.
        """

        if self._private_key is not None:
            return

        url = paths.enc_key_url(self._web_id, self._app)
        try:
            document = self._client.get_text(url)
        except NotFoundError as exc:
            raise KeyStoreError(
                f'{url} does not exist. The Analyser Pod has not been '
                'initialised by HealthPod yet; see README.md, section '
                '"Preparing the Analyser Pod".') from exc

        record = turtle.triple_map(document, base=url).get(url)
        if record is None:
            raise KeyStoreError(f'{url} is not a solidpod key file')

        verification = turtle.single(record.get(_predicate('encKey')))
        sealed_private = turtle.single(record.get(_predicate('prvKey')))
        iv_b64 = turtle.single(record.get(_predicate('iv')))
        salt_b64 = turtle.single(record.get(_predicate('salt')))
        version = turtle.single(record.get(_predicate('keyVersion')))

        if not verification or not sealed_private or not iv_b64:
            raise KeyStoreError(f'{url} is missing one of encKey, prvKey or iv')

        security_key = self._config.analyser.security_key
        if salt_b64:
            master_key, derived = crypto.derive_keys_v2(
                security_key, base64.b64decode(salt_b64))
            self._kdf_version = int(version) if version else 2
        else:
            master_key, derived = crypto.derive_keys_v1(security_key)
            self._kdf_version = 1

        if not crypto.verification_matches(verification, derived):
            raise KeyStoreError(
                'the configured security key does not match the one the '
                'Analyser Pod was initialised with (verification failed)')

        self._master_key = master_key
        pem = crypto.aes_cbc_decrypt(
            sealed_private, master_key, base64.b64decode(iv_b64))
        self._private_key = crypto.load_private_key(pem)
        log.info('unlocked the Analyser Pod (key derivation version %s)',
                 self._kdf_version)

    @property
    def master_key(self) -> bytes:
        """The AES master key; unlocks the Pod's own individual keys."""

        self.unlock()
        assert self._master_key is not None
        return self._master_key

    @property
    def private_key(self) -> RSAPrivateKey:
        """The RSA private key; opens everything shared with this Pod."""

        self.unlock()
        assert self._private_key is not None
        return self._private_key

    # -- Keys shared with the Analyser -------------------------------------

    def shared_key_etag(self) -> str | None:
        """A cheap change marker for the shared-keys file."""

        return self._client.etag(paths.shared_key_url(self._web_id, self._app))

    def shared_resources(self) -> list[SharedResource]:
        """Every resource another Pod has shared with the Analyser.

        Entries that cannot be opened are logged and skipped: a Pod may have
        shared with a different key pair before the Analyser Pod was re-keyed,
        and one bad entry must not stop the analysis.
        """

        url = paths.shared_key_url(self._web_id, self._app)
        document = self._client.get_text_or_none(url)
        if document is None:
            log.info('no shared-keys file yet at %s; nothing has been shared',
                     url)
            return []

        shared: list[SharedResource] = []
        for subject, record in turtle.triple_map(document, base=url).items():
            sealed_key = turtle.single(
                record.get(_predicate('sharedKey', paths.APPS_DATA)))
            sealed_path = turtle.single(
                record.get(_predicate('path', paths.APPS_DATA)))
            sealed_access = turtle.single(
                record.get(_predicate('accessList', paths.APPS_DATA)))
            if not (sealed_key and sealed_path):
                continue

            try:
                resource_url = crypto.rsa_decrypt(self.private_key, sealed_path)
                key_b64 = crypto.rsa_decrypt(self.private_key, sealed_key)
                access = (
                    crypto.rsa_decrypt(self.private_key, sealed_access)
                    if sealed_access else '')
            except crypto.DecryptionError as exc:
                log.warning('skipping share %s: %s', subject, exc)
                continue

            shared.append(SharedResource(
                unique_id=subject.rsplit('#', 1)[-1],
                resource_url=resource_url,
                access_modes=[
                    mode.strip().lower() for mode in access.split(',') if mode.strip()],
                key=base64.b64decode(key_b64),
                sealed_path=sealed_path,
                sealed_access=sealed_access or '',
                sealed_key=sealed_key,
            ))

        log.info('%d resource(s) are shared with the Analyser', len(shared))
        return shared

    # -- The Analyser's own individual keys --------------------------------

    def _read_individual_keys(self) -> tuple[str, dict[str, dict[str, str]]]:
        """The raw records of `ind-keys.ttl`, keyed by resource URL."""

        url = paths.ind_key_url(self._web_id, self._app)
        document = self._client.get_text_or_none(url)
        records: dict[str, dict[str, str]] = {}
        if document is None:
            return url, records

        for subject, record in turtle.triple_map(document, base=url).items():
            session_key = turtle.single(record.get(_predicate('sessionKey')))
            iv_b64 = turtle.single(record.get(_predicate('iv')))
            path = turtle.single(record.get(_predicate('path')))
            if session_key and iv_b64 and path:
                records[subject] = {
                    'path': path, 'iv': iv_b64, 'sessionKey': session_key}
        return url, records

    def individual_key(self, resource_url: str) -> bytes | None:
        """The key of a resource the Analyser owns, or None if it has none."""

        _, records = self._read_individual_keys()
        record = records.get(resource_url)
        if record is None:
            return None
        return base64.b64decode(crypto.aes_ctr_decrypt(
            record['sessionKey'],
            self.master_key,
            base64.b64decode(record['iv']),
        ))

    def add_individual_key(self, resource_url: str, key: bytes) -> None:
        """Record the key of a resource the Analyser has just written.

        solidpod rewrites the whole file rather than patching it, because some
        CSS versions accept a SPARQL PATCH without persisting it; we do the
        same, merging into whatever is already there.
        """

        url, records = self._read_individual_keys()
        iv = crypto.random_iv()
        records[resource_url] = {
            'path': paths.resource_path_in_pod(resource_url, self._web_id),
            'iv': base64.b64encode(iv).decode('ascii'),
            'sessionKey': crypto.aes_ctr_encrypt(
                base64.b64encode(key).decode('ascii'), self.master_key, iv),
        }
        self._client.put_text(url, turtle.individual_keys_document(url, records))

    # -- Other Pods' public keys -------------------------------------------

    def public_key_of(self, web_id: str) -> RSAPublicKey:
        """Fetch (and cache) the RSA public key of another Pod."""

        cached = self._public_keys.get(web_id)
        if cached is not None:
            return cached

        url = paths.pub_key_url(web_id, self._app)
        try:
            document = self._client.get_text(url)
        except NotFoundError as exc:
            raise KeyStoreError(
                f'{web_id} has no public key at {url}; that Pod has not been '
                f'initialised for the "{self._app}" application') from exc

        record = turtle.triple_map(document, base=url).get(url)
        body = turtle.single(record.get(_predicate('pubKey'))) if record else None
        if not body:
            raise KeyStoreError(f'{url} does not contain a public key')

        public_key = crypto.load_public_key(body)
        self._public_keys[web_id] = public_key
        return public_key
