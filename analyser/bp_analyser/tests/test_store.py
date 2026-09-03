"""The markers the store keeps: refresh, cancellation and the run in progress.

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

# These markers are how the API talks to the watcher: one process writes a
# file, the other finds it. Nothing here needs a Solid server or the crypto
# dependencies, so the store is exercised on its own.

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


class StoreMarkerTests(unittest.TestCase):
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

    # -- Cancellation ------------------------------------------------------

    def test_no_cancellation_by_default(self) -> None:
        self.assertFalse(self.store.cancel_requested())
        self.assertIsNone(self.store.consume_cancel())

    def test_asking_does_not_consume_the_request(self) -> None:
        """A cycle checks many times; only acting on it takes the request."""

        self.store.request_cancel('api')
        self.assertTrue(self.store.cancel_requested())
        self.assertTrue(self.store.cancel_requested())
        self.assertEqual(self.store.consume_cancel(), 'api')
        self.assertFalse(self.store.cancel_requested())

    def test_the_reason_survives_the_round_trip(self) -> None:
        self.store.request_cancel('cli')
        self.assertEqual(self.store.consume_cancel(), 'cli')

    def test_an_unreadable_marker_still_cancels(self) -> None:
        """A truncated write must not leave a request that cannot be taken."""

        self.store.cancel_path.write_text('{not json', encoding='utf-8')
        self.assertTrue(self.store.cancel_requested())
        self.assertEqual(self.store.consume_cancel(), 'unknown')
        self.assertFalse(self.store.cancel_path.exists())

    def test_clearing_drops_the_request_without_acting_on_it(self) -> None:
        self.store.request_cancel('api')
        self.store.clear_cancel()
        self.assertFalse(self.store.cancel_requested())

    # -- The run in progress -----------------------------------------------

    def test_the_active_marker_follows_the_run(self) -> None:
        self.assertIsNone(self.store.read_active_run())
        self.store.mark_run_started('20260829T101500Z')
        active = self.store.read_active_run()
        self.assertIsNotNone(active)
        self.assertEqual(active['run_id'], '20260829T101500Z')
        self.assertIn('started_at', active)
        self.store.mark_run_finished()
        self.assertIsNone(self.store.read_active_run())

    def test_finishing_twice_is_harmless(self) -> None:
        """`run_cycle` clears the marker in a `finally`; it may already be gone."""

        self.store.mark_run_started('20260829T101500Z')
        self.store.mark_run_finished()
        self.store.mark_run_finished()
        self.assertIsNone(self.store.read_active_run())

    def test_an_unreadable_active_marker_reads_as_idle(self) -> None:
        self.store.active_path.write_text('{not json', encoding='utf-8')
        self.assertIsNone(self.store.read_active_run())

    # -- Refresh -----------------------------------------------------------

    def test_refresh_is_taken_once(self) -> None:
        self.store.request_refresh('api')
        self.assertEqual(self.store.consume_refresh(), 'api')
        self.assertIsNone(self.store.consume_refresh())


if __name__ == '__main__':
    unittest.main()
