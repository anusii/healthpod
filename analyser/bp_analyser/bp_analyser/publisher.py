"""Writing results into the Analyser Pod and sharing them back.

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

# Sharing follows exactly the protocol solidpod's `grantPermission()` implements,
# so a result published here shows up in HealthPod like any other shared file:
#
#   1. the result is encrypted with a fresh individual key and written into the
#      Analyser Pod, and that key is recorded in the Analyser's `ind-keys.ttl`;
#   2. an ACL grants the recipient Pod read access to the result;
#   3. the individual key, the resource URL and the permission list are sealed
#      with the recipient's RSA public key and inserted into the recipient's
#      `shared/shared-keys.ttl`;
#   4. a line is appended to the recipient's permission log, which is what the
#      app reads to list the resources shared with its user.
#
# Steps 3 and 4 write into somebody else's Pod. That is by design: a Pod set up
# by solidpod grants public write on `<app>/shared/` and public append on the
# permission log precisely so that other agents can hand over shared keys.

from __future__ import annotations

import base64
import json
import logging
from dataclasses import dataclass, field
from datetime import datetime

from . import crypto, pod_paths as paths, turtle
from .config import Config
from .keys import PodKeys
from .solid_client import SolidClient, SolidError

log = logging.getLogger(__name__)

# The permissions the recipient is granted over a published result.

_ACCESS_MODES = ['read']


@dataclass
class PublishResult:
    """The outcome of publishing one result document."""

    resource_url: str
    recipients: list[str] = field(default_factory=list)
    failures: dict[str, str] = field(default_factory=dict)

    @property
    def shared_with(self) -> int:
        """How many recipients received the key successfully."""

        return len(self.recipients)


class Publisher:
    """Publishes analysis results from the Analyser Pod to contributing Pods."""

    def __init__(self, client: SolidClient, keys: PodKeys, config: Config) -> None:
        self._client = client
        self._keys = keys
        self._config = config
        self._web_id = config.analyser.web_id
        self._app = config.analyser.app_dir_name
        self._log_sequence = 0

    # -- Publishing --------------------------------------------------------

    def publish(
        self,
        *,
        payload: dict,
        relative_path: str,
        recipients: list[str],
    ) -> PublishResult:
        """Write [payload] into the Analyser Pod and share it with [recipients].

        [relative_path] is relative to the Analyser's application data
        directory, for example `analyser/alice/bp-average.json`.
        """

        encrypt = self._config.sharing.encrypt_results
        suffix = '.enc.ttl' if encrypt else ''
        resource_url = paths.data_url(
            self._web_id, self._app, relative_path + suffix)
        container_url = resource_url.rsplit('/', 1)[0] + '/'
        body = json.dumps(payload, indent=2, sort_keys=False)

        self._client.ensure_container(container_url)

        if encrypt:
            key = crypto.random_key()
            iv = crypto.random_iv()
            document = turtle.encrypted_document(
                file_url=resource_url,
                resource_path=paths.resource_path_in_pod(
                    resource_url, self._web_id),
                iv_b64=base64.b64encode(iv).decode('ascii'),
                enc_data_b64=crypto.aes_ctr_encrypt(body, key, iv),
            )
            self._client.put_text(resource_url, document)
            self._keys.add_individual_key(resource_url, key)
        else:
            key = b''
            self._client.put_text(
                resource_url, body, content_type='application/json')

        self._client.put_text(
            f'{resource_url}.acl',
            turtle.acl_document(
                resource_url=resource_url,
                owner_web_id=self._web_id,
                reader_web_ids=recipients,
            ),
        )

        result = PublishResult(resource_url=resource_url)
        for recipient in recipients:
            try:
                if encrypt:
                    self._share_key(recipient, resource_url, key)
                if self._config.sharing.write_permission_log:
                    self._log_grant(recipient, resource_url)
            except Exception as exc:  # noqa: BLE001 - one failed
                # recipient must not stop the others.
                result.failures[recipient] = str(exc)
                log.warning('could not share %s with %s: %s',
                            resource_url, recipient, exc)
                continue
            result.recipients.append(recipient)

        log.info('published %s and shared it with %d of %d Pod(s)',
                 resource_url, result.shared_with, len(recipients))
        return result

    # -- Handing over the key ----------------------------------------------

    def _share_key(self, recipient: str, resource_url: str, key: bytes) -> None:
        """Seal the resource key for [recipient] and put it in their Pod."""

        public_key = self._keys.public_key_of(recipient)
        sealed_key = crypto.rsa_encrypt(
            public_key, base64.b64encode(key).decode('ascii'))
        sealed_path = crypto.rsa_encrypt(public_key, resource_url)
        sealed_access = crypto.rsa_encrypt(public_key, ','.join(_ACCESS_MODES))
        unique_id = crypto.unique_resource_id(resource_url, recipient)

        shared_url = paths.shared_key_url(recipient, self._app)
        if self._client.exists(shared_url):
            self._client.patch_sparql(
                shared_url,
                turtle.shared_key_insert_query(
                    unique_id, sealed_path, sealed_access, sealed_key),
            )
        else:
            self._client.ensure_container(shared_url.rsplit('/', 1)[0] + '/')
            self._client.put_text(
                shared_url,
                turtle.shared_keys_document(
                    shared_url, unique_id, sealed_path, sealed_access,
                    sealed_key),
            )

    # -- Permission log ----------------------------------------------------

    def _log_grant(self, recipient: str, resource_url: str) -> None:
        """Append a grant to the recipient's and the Analyser's own log."""

        now = datetime.now()
        self._log_sequence = (self._log_sequence + 1) % 1000
        entry_id = (
            now.strftime('%Y%m%dT%H%M%S')
            + f'{now.microsecond // 1000:03d}{self._log_sequence:03d}')
        record = ';'.join([
            now.strftime('%Y%m%dT%H%M%S'),
            resource_url,
            self._web_id,      # owner of the result
            'grant',
            self._web_id,      # granter
            recipient,
            ','.join(_ACCESS_MODES),
        ])
        query = turtle.permission_log_insert_query(entry_id, record)

        for web_id in (recipient, self._web_id):
            log_url = paths.perm_log_url(web_id, self._app)
            try:
                if not self._client.exists(log_url):
                    self._client.ensure_container(
                        log_url.rsplit('/', 1)[0] + '/')
                    self._client.put_text(
                        log_url, turtle.permission_log_document(log_url))
                self._client.patch_sparql(log_url, query)
            except SolidError as exc:
                # A missing or read-only log must not fail the share itself;
                # the recipient can still open the resource by its URL.
                log.warning('could not append to the permission log %s: %s',
                            log_url, exc)
