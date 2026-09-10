"""The run marker and the state the store keeps.

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

# The store once carried the requests as well — a file for a refresh, a file
# for a cancellation, written by one process and found by another on its next
# poll. Both are gRPC calls now, answered inside the process doing the work,
# so what is left here is the record: which run is in progress, and how the
# last one ended.
#
# Nothing here needs a Solid server or the crypto dependencies, so the store
# is exercised on its own.

from __future__ import annotations

import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

from bp_analyser.store import ResultStore


@dataclass
class _Output:
    """Just the fields of `config.output` that the store reads."""

    state_dir: Path
    results_dir: Path
    charts_dir: Path
    keep_runs: int = 3
    render_charts: bool = False


@dataclass
class _Config:
    """A stand-in for the configuration, holding only what the store uses."""

    output: _Output


class StoreTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        base = Path(self.temporary.name)
        self.store = ResultStore(_Config(_Output(
            state_dir=base / 'state',
            results_dir=base / 'results',
            charts_dir=base / 'charts',
        )))
        self.store.ensure_directories()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    # -- The run in progress -----------------------------------------------

    def test_the_active_marker_follows_the_run(self) -> None:
        self.assertIsNone(self.store.read_active_run())
        self.store.mark_run_started(
            '20260829T101500Z', 'https://server/alice/profile/card#me')
        active = self.store.read_active_run()
        self.assertIsNotNone(active)
        self.assertEqual(active['run_id'], '20260829T101500Z')
        self.assertEqual(
            active['web_id'], 'https://server/alice/profile/card#me')
        self.assertIn('started_at', active)
        self.store.mark_run_finished()
        self.assertIsNone(self.store.read_active_run())

    def test_a_run_with_no_caller_names_none(self) -> None:
        """`run-once` on the command line analyses for everybody."""

        self.store.mark_run_started('20260829T101500Z')
        self.assertEqual(self.store.read_active_run()['web_id'], '')

    def test_finishing_twice_is_harmless(self) -> None:
        """`run_cycle` clears the marker in a `finally`; it may already be gone."""

        self.store.mark_run_started('20260829T101500Z')
        self.store.mark_run_finished()
        self.store.mark_run_finished()
        self.assertIsNone(self.store.read_active_run())

    def test_an_unreadable_active_marker_reads_as_idle(self) -> None:
        self.store.active_path.write_text('{not json', encoding='utf-8')
        self.assertIsNone(self.store.read_active_run())

    # -- State -------------------------------------------------------------

    def test_the_state_reads_as_empty_before_the_first_run(self) -> None:
        """A Status call reads this before anything has ever run."""

        state = self.store.read_state()
        self.assertIsNone(state['last_run'])
        self.assertIsNone(state['last_cancelled'])

    def test_the_state_survives_a_round_trip(self) -> None:
        self.store.write_state({'last_run': {'run_id': '20260829T101500Z'}})
        self.assertEqual(
            self.store.read_state()['last_run']['run_id'],
            '20260829T101500Z')

    def test_an_unreadable_state_file_reads_as_empty(self) -> None:
        """A truncated write must not stop the analyser from starting."""

        self.store.state_path.write_text('{not json', encoding='utf-8')
        self.assertIsNone(self.store.read_state()['last_run'])

    def test_the_empty_state_cannot_be_edited_by_a_reader(self) -> None:
        """`read_state` hands back a copy; callers add keys to what they get."""

        first = self.store.read_state()
        first['last_run'] = {'run_id': 'x'}
        self.assertIsNone(self.store.read_state()['last_run'])


if __name__ == '__main__':
    unittest.main()
