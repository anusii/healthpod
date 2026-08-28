"""Loading the configuration, and the warnings it raises about secrets.

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

from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from bp_analyser import config as config_module

WITH_SECRETS = """
analyser:
  web_id: https://server/Analyser/profile/card#me
  security_key: super-secret
  credentials:
    client_id: an-id
    client_secret: a-secret
"""

WITHOUT_SECRETS = """
analyser:
  web_id: https://server/Analyser/profile/card#me
"""


class SecretPermissionTests(unittest.TestCase):
    """A configuration file holding secrets must not be widely readable."""

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.path = Path(self.temporary.name) / 'config.yaml'

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _load(self, body: str, mode: int, environment: dict[str, str] | None = None):
        self.path.write_text(body)
        self.path.chmod(mode)
        with mock.patch.dict(os.environ, environment or {}, clear=False):
            for name in (config_module.ENV_SECURITY_KEY,
                         config_module.ENV_CLIENT_ID,
                         config_module.ENV_CLIENT_SECRET):
                if not (environment or {}).get(name):
                    os.environ.pop(name, None)
            return config_module.load(self.path)

    def test_group_readable_file_with_secrets_warns(self) -> None:
        config = self._load(WITH_SECRETS, 0o644)
        self.assertEqual(len(config.warnings), 1)
        warning = config.warnings[0]
        self.assertIn('analyser.security_key', warning)
        self.assertIn('644', warning)
        # The warning must never quote the secret itself.
        self.assertNotIn('super-secret', warning)

    def test_owner_only_file_is_quiet(self) -> None:
        config = self._load(WITH_SECRETS, 0o600)
        self.assertEqual(config.warnings, [])

    def test_secrets_from_the_environment_are_not_the_files_problem(self) -> None:
        config = self._load(WITHOUT_SECRETS, 0o644, {
            config_module.ENV_SECURITY_KEY: 'key',
            config_module.ENV_CLIENT_ID: 'id',
            config_module.ENV_CLIENT_SECRET: 'secret',
        })
        self.assertEqual(config.warnings, [])
        self.assertEqual(config.analyser.security_key, 'key')

    def test_file_without_secrets_is_quiet(self) -> None:
        config = self._load(WITHOUT_SECRETS, 0o644)
        self.assertEqual(config.warnings, [])


class ChartCacheDirectoryTests(unittest.TestCase):
    """matplotlib must cache somewhere writable, not in a sandboxed home."""

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self._saved = os.environ.pop('MPLCONFIGDIR', None)

    def tearDown(self) -> None:
        os.environ.pop('MPLCONFIGDIR', None)
        if self._saved is not None:
            os.environ['MPLCONFIGDIR'] = self._saved
        self.temporary.cleanup()

    def test_directory_is_created_and_exported(self) -> None:
        from bp_analyser import charts

        target = self.root / 'charts' / '.mplconfig'
        charts.set_cache_dir(target)
        self.assertTrue(target.is_dir())
        self.assertEqual(os.environ['MPLCONFIGDIR'], str(target))

    def test_an_explicit_setting_wins(self) -> None:
        from bp_analyser import charts

        os.environ['MPLCONFIGDIR'] = '/somewhere/chosen'
        charts.set_cache_dir(self.root / 'ignored')
        self.assertEqual(os.environ['MPLCONFIGDIR'], '/somewhere/chosen')
        self.assertFalse((self.root / 'ignored').exists())

    def test_an_unwritable_target_is_not_fatal(self) -> None:
        from bp_analyser import charts

        blocked = self.root / 'blocked'
        blocked.mkdir()
        blocked.chmod(0o500)
        try:
            charts.set_cache_dir(blocked / 'nested' / '.mplconfig')
        finally:
            blocked.chmod(0o700)
        self.assertNotIn('MPLCONFIGDIR', os.environ)


class WatchDefaultTests(unittest.TestCase):
    """The analysis runs on a share, not on a timer."""

    def _load(self, body: str) -> object:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'config.yaml'
            path.write_text(body)
            return config_module.load(path)

    def test_polling_is_half_a_minute_by_default(self) -> None:
        self.assertEqual(self._load(WITHOUT_SECRETS).watch.poll_seconds, 30)

    def test_the_periodic_rescan_is_off_by_default(self) -> None:
        self.assertEqual(
            self._load(WITHOUT_SECRETS).watch.full_rescan_seconds, 0)

    def test_a_blank_rescan_interval_means_off(self) -> None:
        loaded = self._load(
            WITHOUT_SECRETS + '\nwatch:\n  full_rescan_seconds:\n')
        self.assertEqual(loaded.watch.full_rescan_seconds, 0)

    def test_a_rescan_interval_can_still_be_asked_for(self) -> None:
        loaded = self._load(
            WITHOUT_SECRETS + '\nwatch:\n  full_rescan_seconds: 900\n')
        self.assertEqual(loaded.watch.full_rescan_seconds, 900)


class LoadingTests(unittest.TestCase):
    """The basics of reading the file."""

    def test_missing_file_is_reported(self) -> None:
        with self.assertRaises(config_module.ConfigError):
            config_module.load('/nonexistent/config.yaml')

    def test_server_url_is_derived_from_the_web_id(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'config.yaml'
            path.write_text(WITHOUT_SECRETS)
            config = config_module.load(path)
        self.assertEqual(config.analyser.server_url, 'https://server')
        self.assertEqual(config.analyser.pod_root, 'https://server/Analyser/')

    def test_relative_output_paths_resolve_against_the_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'config.yaml'
            path.write_text(WITHOUT_SECRETS + '\noutput:\n  results_dir: out\n')
            config = config_module.load(path)
            self.assertEqual(
                config.output.results_dir, Path(directory).resolve() / 'out')


if __name__ == '__main__':
    unittest.main()
