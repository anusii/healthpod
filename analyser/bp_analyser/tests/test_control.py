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

# The container these markers live in is publicly writable -- that is what
# makes the channel work at all -- so what the analyser refuses to act on
# matters as much as what it acts on. The Solid server is replaced by a
# dictionary here; `solid_client` is exercised against a real one elsewhere.

from __future__ import annotations

import json
import unittest
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone

from bp_analyser import control
from bp_analyser.solid_client import NotFoundError, SolidError

ANALYSER = 'https://server/Analyser/profile/card#me'
ALICE = 'https://server/alice/profile/card#me'
STRANGER = 'https://server/mallory/profile/card#me'
CONTAINER = 'https://server/Analyser/healthpod/shared/'


@dataclass
class _Watch:
    cancel_poll_seconds: float = 3.0
    cancel_max_age_seconds: int = 600


@dataclass
class _Analyser:
    web_id: str = ANALYSER
    app_dir_name: str = 'healthpod'


@dataclass
class _Config:
    analyser: _Analyser = field(default_factory=_Analyser)
    watch: _Watch = field(default_factory=_Watch)


class _FakePod:
    """Just enough of `SolidClient` for the inbox: list, read and delete."""

    def __init__(self, resources: dict[str, str] | None = None) -> None:
        self.resources = dict(resources or {})
        self.deleted: list[str] = []
        self.list_error: Exception | None = None

    def list_container(self, url: str) -> list[str]:
        if self.list_error is not None:
            raise self.list_error
        return sorted(self.resources)

    def get_text_or_none(self, url: str, *, accept: str = '') -> str | None:
        return self.resources.get(url)

    def delete(self, url: str) -> bool:
        self.deleted.append(url)
        return self.resources.pop(url, None) is not None


def _marker(web_id: str = ALICE, *, age: timedelta = timedelta(seconds=5),
            kind: str = 'cancel-request') -> str:
    moment = datetime.now(timezone.utc) - age
    return json.dumps({
        'schema_version': control.SCHEMA_VERSION,
        'kind': kind,
        'web_id': web_id,
        # The app writes a trailing Z, which `datetime.fromisoformat` rejected
        # before Python 3.11.
        'requested_at': moment.isoformat().replace('+00:00', 'Z'),
    })


def _url(slug: str) -> str:
    return f'{CONTAINER}cancel-{slug}.json'


class CancelInboxTests(unittest.TestCase):
    def setUp(self) -> None:
        self.config = _Config()

    def _inbox(self, resources: dict[str, str] | None = None):
        pod = _FakePod(resources)
        return pod, control.CancelInbox(pod, self.config)

    # -- Where it looks ----------------------------------------------------

    def test_looks_in_the_publicly_writable_container(self) -> None:
        _, inbox = self._inbox()
        self.assertEqual(inbox.container_url, CONTAINER)

    def test_the_app_and_the_analyser_agree_on_the_name(self) -> None:
        self.assertEqual(
            control.cancel_url(ANALYSER, 'healthpod', 'server-alice'),
            _url('server-alice'))

    def test_the_deployed_address_is_the_one_the_app_writes(self) -> None:
        """Pinned on both sides; the app half is in `cancel_test.dart`.

        The two are built independently, in different languages, so a change
        to either that is not matched in the other fails here.
        """

        self.assertEqual(
            control.cancel_url(
                'https://solid.dev.empwr.au/Analyser/profile/card#me',
                'healthpod',
                'solid.dev.empwr.au-intony'),
            'https://solid.dev.empwr.au/Analyser/healthpod/shared/'
            'cancel-solid.dev.empwr.au-intony.json')

    # -- What it acts on ---------------------------------------------------

    def test_acts_on_a_recent_request_from_a_contributor(self) -> None:
        pod, inbox = self._inbox({_url('server-alice'): _marker()})

        request = inbox.poll({ALICE})

        self.assertIsNotNone(request)
        self.assertEqual(request.web_id, ALICE)
        self.assertIn(ALICE, request.reason)

    def test_a_request_is_acted_on_once(self) -> None:
        """Left behind, it would stop the next run as well.

        Removing it is also how the app is told the analyser stopped: it
        watches the file it wrote and reports success when it goes. Collecting
        a request without removing it would have the app report success for
        analyses that carried on.
        """

        pod, inbox = self._inbox({_url('server-alice'): _marker()})

        self.assertIsNotNone(inbox.poll({ALICE}))
        self.assertEqual(pod.deleted, [_url('server-alice')])
        self.assertIsNone(inbox.poll({ALICE}))

    def test_ignores_a_request_from_a_pod_that_shared_nothing(self) -> None:
        """The container is public, so the name on it is all there is."""

        pod, inbox = self._inbox({_url('server-mallory'): _marker(STRANGER)})

        self.assertIsNone(inbox.poll({ALICE}))

        # Still cleared, so it cannot accumulate.

        self.assertEqual(pod.deleted, [_url('server-mallory')])

    def test_ignores_a_stale_request(self) -> None:
        """One nobody collected must not stop an unrelated run hours later."""

        pod, inbox = self._inbox(
            {_url('server-alice'): _marker(age=timedelta(hours=2))})

        self.assertIsNone(inbox.poll({ALICE}))
        self.assertEqual(pod.deleted, [_url('server-alice')])

    def test_ignores_a_request_dated_far_in_the_future(self) -> None:
        """Otherwise it would never go stale."""

        pod, inbox = self._inbox(
            {_url('server-alice'): _marker(age=-timedelta(days=1))})

        self.assertIsNone(inbox.poll({ALICE}))

    def test_allows_a_clock_a_little_ahead(self) -> None:
        pod, inbox = self._inbox(
            {_url('server-alice'): _marker(age=-timedelta(seconds=20))})

        self.assertIsNotNone(inbox.poll({ALICE}))

    def test_ignores_a_request_without_a_timestamp(self) -> None:
        body = json.dumps({'kind': 'cancel-request', 'web_id': ALICE})
        pod, inbox = self._inbox({_url('server-alice'): body})

        self.assertIsNone(inbox.poll({ALICE}))

    def test_ignores_a_request_naming_no_pod(self) -> None:
        body = json.dumps({'kind': 'cancel-request', 'requested_at': 'now'})
        pod, inbox = self._inbox({_url('server-alice'): body})

        self.assertIsNone(inbox.poll({ALICE}))

    def test_ignores_something_that_is_not_a_request(self) -> None:
        pod, inbox = self._inbox(
            {_url('server-alice'): _marker(kind='greeting')})

        self.assertIsNone(inbox.poll({ALICE}))

    def test_ignores_unreadable_content(self) -> None:
        pod, inbox = self._inbox({_url('server-alice'): '{not json'})

        self.assertIsNone(inbox.poll({ALICE}))

    # -- What it leaves alone ----------------------------------------------

    def test_never_touches_the_shared_keys_file(self) -> None:
        """Deleting it would cut the analyser off from every contributor."""

        keys = f'{CONTAINER}shared-keys.ttl'
        pod, inbox = self._inbox({keys: '<a> <b> <c> .'})

        self.assertIsNone(inbox.poll({ALICE}))
        self.assertEqual(pod.deleted, [])
        self.assertIn(keys, pod.resources)

    def test_clearing_leaves_everything_but_the_markers(self) -> None:
        keys = f'{CONTAINER}shared-keys.ttl'
        pod, inbox = self._inbox({
            keys: '<a> <b> <c> .',
            _url('server-alice'): _marker(),
        })

        inbox.clear()

        self.assertEqual(pod.deleted, [_url('server-alice')])
        self.assertIn(keys, pod.resources)

    # -- When the Pod misbehaves -------------------------------------------

    def test_an_absent_container_is_not_an_error(self) -> None:
        """Before anything has been shared there is no container at all."""

        pod, inbox = self._inbox()
        pod.list_error = NotFoundError('no such container', 404)

        self.assertIsNone(inbox.poll({ALICE}))

    def test_a_failure_to_read_does_not_become_a_failed_analysis(self) -> None:
        pod, inbox = self._inbox()
        pod.list_error = SolidError('server on fire', 500)

        self.assertIsNone(inbox.poll({ALICE}))

    # -- Switching the channel off -----------------------------------------

    def test_a_zero_maximum_age_switches_the_channel_off(self) -> None:
        self.config.watch.cancel_max_age_seconds = 0
        pod, inbox = self._inbox({_url('server-alice'): _marker()})

        self.assertFalse(inbox.enabled)
        self.assertIsNone(inbox.poll({ALICE}))
        self.assertEqual(pod.deleted, [])

    # -- Several at once ---------------------------------------------------

    def test_who_may_cancel_can_be_worked_out_lazily(self) -> None:
        """An idle watcher must not read the shared-keys file every poll."""

        pod, inbox = self._inbox()
        calls = []

        def contributors() -> set[str]:
            calls.append(1)
            return {ALICE}

        self.assertIsNone(inbox.poll(contributors))
        self.assertEqual(calls, [], 'nothing found, so nobody was asked')

        pod.resources[_url('server-alice')] = _marker()
        self.assertIsNotNone(inbox.poll(contributors))
        self.assertEqual(calls, [1])

    def test_the_contributor_set_is_worked_out_once_per_pass(self) -> None:
        pod, inbox = self._inbox({
            _url('server-alice'): _marker(ALICE),
            _url('server-mallory'): _marker(STRANGER),
        })
        calls = []

        def contributors() -> set[str]:
            calls.append(1)
            return {ALICE}

        inbox.poll(contributors)

        self.assertEqual(calls, [1])

    def test_clears_every_marker_in_one_pass(self) -> None:
        """A second request must not survive to stop the following run."""

        pod, inbox = self._inbox({
            _url('server-alice'): _marker(ALICE),
            _url('server-mallory'): _marker(STRANGER),
        })

        request = inbox.poll({ALICE})

        self.assertEqual(request.web_id, ALICE)
        self.assertEqual(len(pod.deleted), 2)
        self.assertEqual(pod.resources, {})


if __name__ == '__main__':
    unittest.main()
