"""Cancellation requests left in the Analyser Pod by a contributing app.

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

# A user who presses cancel is running an app on their own machine, and the
# analyser is a service on the server with no address of its own: `api.host`
# is the loopback interface unless somebody deliberately moves it. So the
# request travels the one way round that always works — through the Pod.
#
# A Pod laid out by solidpod grants public read and write on
# `<app>/shared/`, so that any agent can deliver a sealed key there without
# being granted anything first. That is the container an app can reach, and
# so it is where a cancellation is left:
#
#     <analyser-pod>/healthpod/shared/cancel-<pod-slug>.json
#
#     {"schema_version": 1, "kind": "cancel-request",
#      "web_id": "https://server/alice/profile/card#me",
#      "requested_at": "2026-08-29T04:11:52.117Z"}
#
# The analyser reads the container between the steps of a cycle, acts on the
# first request it can honour, and removes every marker it looks at — a
# request is acted on once.
#
# That container being publicly writable is the whole reason this works, and
# also its weakness: anyone who can reach the Pod can leave a marker. Two
# things narrow it, neither of which closes it:
#
#   - a request naming a WebID that has shared nothing is ignored, so a
#     stranger has to know a contributor's WebID to be a nuisance;
#   - a request goes stale after `watch.cancel_max_age_seconds`, so one left
#     lying about cannot stop an unrelated run hours later.
#
# A deployment that would rather not accept this sets `cancel_max_age_seconds`
# to zero, which switches the channel off and leaves `POST /api/cancel` as the
# only way in.

from __future__ import annotations

import json
import logging
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime, timezone

from . import pod_paths as paths
from .config import Config
from .solid_client import ForbiddenError, NotFoundError, SolidClient, SolidError

log = logging.getLogger(__name__)

SCHEMA_VERSION = 1

# Marker names the analyser recognises. The `shared/` container also holds
# `shared-keys.ttl`, which this must never touch.

CANCEL_PREFIX = 'cancel-'
CANCEL_SUFFIX = '.json'


def cancel_url(analyser_web_id: str, app_dir_name: str, slug: str) -> str:
    """Where the Pod identified by [slug] leaves a cancellation."""

    return paths.app_url(
        analyser_web_id, app_dir_name, paths.SHARED_DIR,
        f'{CANCEL_PREFIX}{slug}{CANCEL_SUFFIX}')


@dataclass
class CancelRequest:
    """One cancellation the analyser has decided to act on."""

    url: str
    web_id: str
    requested_at: datetime | None

    @property
    def reason(self) -> str:
        """How this reads in a log line and in the watch state."""

        return f'pod request from {self.web_id}'


def _parse_time(value: object) -> datetime | None:
    """An ISO 8601 timestamp, tolerating the trailing Z that Dart writes."""

    if not isinstance(value, str) or not value:
        return None
    text = value[:-1] + '+00:00' if value.endswith('Z') else value
    try:
        moment = datetime.fromisoformat(text)
    except ValueError:
        return None
    return moment if moment.tzinfo else moment.replace(tzinfo=timezone.utc)


class CancelInbox:
    """The cancellation markers waiting in the Analyser Pod."""

    def __init__(self, client: SolidClient, config: Config) -> None:
        self._client = client
        self._config = config

    @property
    def enabled(self) -> bool:
        """Whether the Pod channel is switched on at all."""

        return self._config.watch.cancel_max_age_seconds > 0

    @property
    def container_url(self) -> str:
        """The container an app can write a cancellation into.

        A container URL, so it carries the trailing slash the server needs to
        treat it as one rather than as a file of the same name.
        """

        return paths.app_url(
            self._config.analyser.web_id,
            self._config.analyser.app_dir_name,
            paths.SHARED_DIR,
        ).rstrip('/') + '/'

    def poll(
        self,
        allowed_web_ids: set[str] | Callable[[], set[str]],
    ) -> CancelRequest | None:
        """The first request worth acting on, or None.

        Every marker looked at is removed, honoured or not: leaving one behind
        would have it stop the next run as well.

        [allowed_web_ids] limits which Pods may cancel. Passing a callable
        defers working the set out until a marker has actually been found,
        which is what lets an idle watcher check this container without also
        reading the shared-keys file on every poll.

        Never raises. The Pod is not the analyser's to depend on mid-cycle, and
        a failure to read a cancellation must not become a failed analysis.
        """

        if not self.enabled:
            return None

        try:
            members = self._client.list_container(self.container_url)
        except (NotFoundError, ForbiddenError):
            # No shared container yet, or not ours to list. Either way there is
            # nothing to collect, and it is not worth a warning each time.
            return None
        except SolidError as exc:
            log.warning('could not read the cancellation container %s: %s',
                        self.container_url, exc)
            return None

        honoured: CancelRequest | None = None
        allowed: set[str] | None = None
        for url in members:
            name = url.rstrip('/').rsplit('/', 1)[-1]
            if not (name.startswith(CANCEL_PREFIX)
                    and name.endswith(CANCEL_SUFFIX)):
                continue

            request = self._read(url)
            self._discard(url)
            if request is None:
                continue

            if not self._is_fresh(request):
                log.info('ignoring a stale cancellation from %s (%s)',
                         request.web_id, request.requested_at)
                continue

            if allowed is None:
                allowed = (
                    allowed_web_ids() if callable(allowed_web_ids)
                    else allowed_web_ids)

            if request.web_id not in allowed:
                log.warning('ignoring a cancellation from %s, which has '
                            'shared nothing with the Analyser', request.web_id)
                continue

            # Keep going so the rest are cleared in the same pass, but the
            # first honourable request is the one reported.

            honoured = honoured or request

        return honoured

    def clear(self) -> None:
        """Discard every waiting cancellation without acting on it.

        Called on the way into a cycle started from the command line, where a
        marker left by an earlier process would otherwise stop a run nobody
        asked to stop.
        """

        if not self.enabled:
            return
        try:
            members = self._client.list_container(self.container_url)
        except SolidError:
            return
        for url in members:
            name = url.rstrip('/').rsplit('/', 1)[-1]
            if name.startswith(CANCEL_PREFIX) and name.endswith(CANCEL_SUFFIX):
                self._discard(url)

    # -- One marker --------------------------------------------------------

    def _read(self, url: str) -> CancelRequest | None:
        """Parse one marker, or None when it is not one we understand."""

        try:
            body = self._client.get_text_or_none(url, accept='application/json')
        except SolidError as exc:
            log.warning('could not read the cancellation at %s: %s', url, exc)
            return None
        if body is None:
            return None

        try:
            payload = json.loads(body)
        except json.JSONDecodeError:
            log.warning('ignoring an unreadable cancellation at %s', url)
            return None

        if not isinstance(payload, dict):
            return None
        if payload.get('kind') != 'cancel-request':
            log.warning('ignoring %s: not a cancellation request', url)
            return None

        web_id = payload.get('web_id')
        if not isinstance(web_id, str) or not web_id:
            log.warning('ignoring a cancellation at %s naming no WebID', url)
            return None

        return CancelRequest(
            url=url,
            web_id=web_id,
            requested_at=_parse_time(payload.get('requested_at')),
        )

    def _is_fresh(self, request: CancelRequest) -> bool:
        """Whether the request is recent enough to act on.

        A marker without a readable timestamp is treated as stale: the app
        always writes one, so its absence means the marker was not written by
        an app this analyser knows.
        """

        if request.requested_at is None:
            return False
        age = (datetime.now(timezone.utc) - request.requested_at).total_seconds()

        # A clock a little ahead of the server's is ordinary; a marker dated
        # far in the future is not, and would otherwise never go stale.

        if age < -self._config.watch.cancel_max_age_seconds:
            return False
        return age <= self._config.watch.cancel_max_age_seconds

    def _discard(self, url: str) -> None:
        """Remove a marker, complaining only once if it will not go."""

        try:
            self._client.delete(url)
        except SolidError as exc:
            log.warning('could not remove the cancellation at %s: %s',
                        url, exc)
