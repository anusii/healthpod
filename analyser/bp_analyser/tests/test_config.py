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


class GrpcConfigTests(unittest.TestCase):
    """The interface the app calls, which is now the whole of the trigger."""

    def _load(self, body: str) -> object:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'config.yaml'
            path.write_text(body)
            return config_module.load(path)

    def test_it_listens_on_every_interface_by_default(self) -> None:
        # The caller is an app on somebody's laptop, so unlike the read-only
        # HTTP API this cannot default to the loopback address.

        loaded = self._load(WITHOUT_SECRETS)
        self.assertEqual(loaded.grpc.host, '0.0.0.0')
        self.assertEqual(loaded.grpc.port, 50051)
        self.assertEqual(loaded.grpc.address, '0.0.0.0:50051')

    def test_the_address_can_be_narrowed(self) -> None:
        loaded = self._load(
            WITHOUT_SECRETS + '\ngrpc:\n  host: 127.0.0.1\n  port: 50100\n')
        self.assertEqual(loaded.grpc.address, '127.0.0.1:50100')

    def test_there_is_no_shared_secret_by_default(self) -> None:
        self.assertEqual(self._load(WITHOUT_SECRETS).grpc.token, '')

    def test_the_environment_beats_the_file_for_the_secret(self) -> None:
        # Same rule as the other secrets: the systemd unit keeps them out of
        # the deployment directory.

        body = WITHOUT_SECRETS + "\ngrpc:\n  token: from-the-file\n"
        os.environ[config_module.ENV_GRPC_TOKEN] = 'from-the-environment'
        try:
            self.assertEqual(
                self._load(body).grpc.token, 'from-the-environment')
        finally:
            del os.environ[config_module.ENV_GRPC_TOKEN]

    def test_a_secret_in_the_file_is_warned_about_when_readable(self) -> None:
        # The gRPC token replaced the API token in this check, and losing it
        # would mean a world-readable config.yaml passing without comment.

        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'config.yaml'
            path.write_text(WITHOUT_SECRETS + "\ngrpc:\n  token: hunter2\n")
            path.chmod(0o644)
            loaded = config_module.load(path)
        self.assertTrue(
            any('grpc.token' in warning for warning in loaded.warnings))

    def test_there_is_no_tls_by_default(self) -> None:
        loaded = self._load(WITHOUT_SECRETS)
        self.assertFalse(loaded.grpc.tls_enabled)

    def test_both_halves_of_a_certificate_are_needed(self) -> None:
        # A deployment that meant to serve TLS and quietly served plaintext is
        # the failure worth refusing to start on.

        with self.assertRaises(config_module.ConfigError):
            self._load(WITHOUT_SECRETS + '\ngrpc:\n  tls_cert_file: a.pem\n')

    def test_certificate_paths_resolve_against_the_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'config.yaml'
            path.write_text(
                WITHOUT_SECRETS
                + '\ngrpc:\n  tls_cert_file: tls/cert.pem\n'
                  '  tls_key_file: tls/key.pem\n')
            loaded = config_module.load(path)
        self.assertTrue(loaded.grpc.tls_enabled)
        self.assertEqual(
            loaded.grpc.tls_cert_file,
            Path(directory).resolve() / 'tls/cert.pem')

    def test_the_analysis_has_a_deadline(self) -> None:
        # Without one a cycle stuck on an unresponsive server would hold the
        # analysis lock against everybody else.

        self.assertEqual(
            self._load(WITHOUT_SECRETS).grpc.analysis_timeout_seconds, 300)

    def test_the_worker_pool_never_drops_below_two(self) -> None:
        # One worker would queue a Cancel behind the analysis it is meant to
        # stop, which is the one thing this pool exists to prevent.

        loaded = self._load(WITHOUT_SECRETS + '\ngrpc:\n  max_workers: 1\n')
        self.assertEqual(loaded.grpc.max_workers, 2)


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
