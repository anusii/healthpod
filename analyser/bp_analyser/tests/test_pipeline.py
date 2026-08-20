"""End-to-end test of one analysis cycle against an in-memory Pod server.

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

# The fake server below holds exactly the resources a real Community Solid Server
# would after two users had shared their blood pressure data with the Analyser:
#
#   * Alice shared two individual readings, each with its own key;
#   * Bob shared his whole blood pressure folder, whose readings inherit the
#     folder's key.
#
# The test then runs a full cycle and checks both halves of the contract: that
# the analyser reads and averages what was shared, and that what it publishes
# back can be opened by the recipient with their own private key.

from __future__ import annotations

import base64
import json
import tempfile
import unittest
from pathlib import Path

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

from bp_analyser import crypto, pod_paths as paths, turtle
from bp_analyser.config import AnalyserConfig, Config, ConfigError
from bp_analyser.keys import PodKeys
from bp_analyser.service import AnalyserService

SERVER = 'https://server'
ANALYSER_WEB_ID = f'{SERVER}/Analyser/profile/card#me'
APP = 'healthpod'


class FakePod:
    """One Pod's key material, as it would sit on the server."""

    def __init__(self, web_id: str, security_key: str = 'pod-key') -> None:
        self.web_id = web_id
        self.security_key = security_key
        self.salt = b'0123456789abcdef'
        self.master_key, self.verification = crypto.derive_keys_v2(
            security_key, self.salt)
        self.private_key = rsa.generate_private_key(
            public_exponent=65537, key_size=2048)
        self.public_key = self.private_key.public_key()

    @property
    def private_pem(self) -> str:
        return self.private_key.private_bytes(
            serialization.Encoding.PEM,
            serialization.PrivateFormat.TraditionalOpenSSL,
            serialization.NoEncryption(),
        ).decode()

    @property
    def public_body(self) -> str:
        pem = self.public_key.public_bytes(
            serialization.Encoding.PEM,
            serialization.PublicFormat.PKCS1).decode()
        return ''.join(
            line for line in pem.splitlines() if not line.startswith('-----'))


class FakeSolidClient:
    """A dictionary pretending to be a Solid server."""

    def __init__(self) -> None:
        self.resources: dict[str, str] = {}
        self.patched: list[tuple[str, str]] = []

    # -- Reading -----------------------------------------------------------

    def get_text(self, url: str, *, accept: str = 'text/turtle') -> str:
        from bp_analyser.solid_client import NotFoundError

        if url.endswith('/'):
            return self._container_document(url)
        if url not in self.resources:
            raise NotFoundError(f'read {url}: not found', 404)
        return self.resources[url]

    def get_text_or_none(self, url: str, *, accept: str = 'text/turtle') -> str | None:
        from bp_analyser.solid_client import NotFoundError

        try:
            return self.get_text(url, accept=accept)
        except NotFoundError:
            return None

    def exists(self, url: str) -> bool:
        if url.endswith('/'):
            return any(key.startswith(url) for key in self.resources)
        return url in self.resources

    def etag(self, url: str) -> str | None:
        content = self.resources.get(url)
        return None if content is None else str(hash(content))

    def list_container(self, url: str) -> list[str]:
        if not url.endswith('/'):
            url += '/'
        members = set()
        for key in self.resources:
            if not key.startswith(url) or key == url:
                continue
            remainder = key[len(url):]
            head = remainder.split('/')[0]
            members.add(url + head + ('/' if '/' in remainder else ''))
        return sorted(members)

    def _container_document(self, url: str) -> str:
        lines = [f'@prefix ldp: <{paths.LDP_NS}> .', f'<{url}>']
        members = self.list_container(url)
        if not members:
            return f'<{url}> a ldp:Container .\n'
        lines.append('    ldp:contains ' + ', '.join(
            f'<{member}>' for member in members) + ' .')
        return '\n'.join(lines) + '\n'

    # -- Writing -----------------------------------------------------------

    def put_text(self, url: str, content: str, *, content_type: str = 'text/turtle') -> None:
        self.resources[url] = content

    def ensure_container(self, url: str) -> None:
        return None

    def patch_sparql(self, url: str, query: str) -> None:
        """Apply an INSERT DATA query by merging its triples into the document."""

        self.patched.append((url, query))
        body = query[query.index('{') + 1:query.rindex('}')]
        prefixes = []
        for chunk in query.split('PREFIX ')[1:]:
            declaration = chunk.split('INSERT')[0].strip()
            if declaration:
                prefixes.append('@prefix ' + declaration.rstrip() + ' .')
        addition = '\n'.join(prefixes) + '\n' + body.strip()
        if not addition.rstrip().endswith('.'):
            addition += ' .'
        existing = self.resources.get(url, '')
        merged = turtle.parse(existing) if existing else turtle.parse('')
        merged.parse(data=addition, format='turtle')
        self.resources[url] = merged.serialize(format='turtle')

    def close(self) -> None:
        return None

    def login(self) -> None:
        return None


def encrypted_resource(url: str, payload: dict, key: bytes,
                       inherit_from: str | None = None) -> str:
    """Write one reading the way HealthPod's `writePod()` would."""

    iv = crypto.random_iv()
    body = json.dumps(payload)
    document = (
        f'@prefix solidTerms: <{paths.APPS_TERMS}> .\n'
        f'<{url}>\n'
        f'    solidTerms:path "{url.split("/", 3)[-1]}";\n'
        f'    solidTerms:iv "{base64.b64encode(iv).decode()}";\n'
    )
    if inherit_from:
        document += f'    solidTerms:inheritKeyFrom "{inherit_from}";\n'
    document += (
        f'    solidTerms:encData "{crypto.aes_ctr_encrypt(body, key, iv)}".\n')
    return document


def reading(timestamp: str, systolic: float, diastolic: float,
            heart_rate: float) -> dict:
    return {
        'timestamp': timestamp,
        'responses': {
            'systolic': systolic,
            'diastolic': diastolic,
            'heart_rate': heart_rate,
            'notes': '',
        },
    }


class PipelineTests(unittest.TestCase):
    """One full cycle: read, average, publish, share."""

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        root = Path(self.temporary.name)

        self.analyser_pod = FakePod(ANALYSER_WEB_ID, 'analyser-key')
        self.alice = FakePod(f'{SERVER}/alice/profile/card#me', 'alice-key')
        self.bob = FakePod(f'{SERVER}/bob/profile/card#me', 'bob-key')

        self.client = FakeSolidClient()
        self._seed_analyser()
        self._seed_alice()
        self._seed_bob()

        self.config = Config(analyser=AnalyserConfig(
            web_id=ANALYSER_WEB_ID,
            app_dir_name=APP,
            server_url=SERVER,
            security_key='analyser-key',
            client_id='id',
            client_secret='secret',
        ))
        self.config.output.state_dir = root / 'state'
        self.config.output.results_dir = root / 'results'
        self.config.output.charts_dir = root / 'charts'
        self.config.output.render_charts = False

        self.service = AnalyserService(self.config)
        self.service._client = self.client  # noqa: SLF001 - test injection.
        self.service._keys = PodKeys(self.client, self.config)  # noqa: SLF001

    def tearDown(self) -> None:
        self.temporary.cleanup()

    # -- Seeding -----------------------------------------------------------

    def _seed_keys(self, pod: FakePod) -> None:
        iv = crypto.random_iv()
        enc_url = paths.enc_key_url(pod.web_id, APP)
        self.client.resources[enc_url] = (
            f'@prefix solidTerms: <{paths.APPS_TERMS}> .\n'
            f'<{enc_url}>\n'
            f'    solidTerms:encKey "{pod.verification}";\n'
            f'    solidTerms:iv "{base64.b64encode(iv).decode()}";\n'
            f'    solidTerms:salt "{base64.b64encode(pod.salt).decode()}";\n'
            f'    solidTerms:keyVersion "2";\n'
            f'    solidTerms:prvKey '
            f'"{crypto.aes_cbc_encrypt(pod.private_pem, pod.master_key, iv)}".\n'
        )
        pub_url = paths.pub_key_url(pod.web_id, APP)
        self.client.resources[pub_url] = (
            f'@prefix solidTerms: <{paths.APPS_TERMS}> .\n'
            f'<{pub_url}>\n'
            f'    solidTerms:pubKey "{pod.public_body}".\n'
        )

    def _share_with_analyser(self, resource_url: str, key: bytes) -> None:
        """Do what solidpod's `copySharedKey()` does on the recipient side."""

        shared_url = paths.shared_key_url(ANALYSER_WEB_ID, APP)
        unique_id = crypto.unique_resource_id(resource_url, ANALYSER_WEB_ID)
        public = self.analyser_pod.public_key
        entry = turtle.shared_keys_document(
            shared_url,
            unique_id,
            crypto.rsa_encrypt(public, resource_url),
            crypto.rsa_encrypt(public, 'read'),
            crypto.rsa_encrypt(public, base64.b64encode(key).decode()),
        )
        existing = self.client.resources.get(shared_url)
        if existing is None:
            self.client.resources[shared_url] = entry
        else:
            graph = turtle.parse(existing)
            graph.parse(data=entry, format='turtle')
            self.client.resources[shared_url] = graph.serialize(format='turtle')

    def _seed_analyser(self) -> None:
        self._seed_keys(self.analyser_pod)
        ind_url = paths.ind_key_url(ANALYSER_WEB_ID, APP)
        self.client.resources[ind_url] = turtle.individual_keys_document(
            ind_url, {})

    def _seed_alice(self) -> None:
        self._seed_keys(self.alice)
        folder = paths.data_url(self.alice.web_id, APP, 'blood_pressure') + '/'
        for index, (systolic, diastolic, pulse) in enumerate(
                [(120, 80, 60), (130, 90, 70)]):
            url = f'{folder}bp_2026-08-1{index}.json.enc.ttl'
            key = crypto.random_key()
            self.client.resources[url] = encrypted_resource(
                url,
                reading(f'2026-08-1{index}T09:00:00.000', systolic, diastolic, pulse),
                key,
            )
            self._share_with_analyser(url, key)

    def _seed_bob(self) -> None:
        self._seed_keys(self.bob)
        folder = paths.data_url(self.bob.web_id, APP, 'blood_pressure') + '/'
        folder_key = crypto.random_key()
        inherit_path = f'{APP}/data/blood_pressure/'
        for index, (systolic, diastolic, pulse) in enumerate(
                [(140, 95, 80), (150, 100, 90)]):
            url = f'{folder}bp_2026-08-2{index}.json.enc.ttl'
            self.client.resources[url] = encrypted_resource(
                url,
                reading(f'2026-08-2{index}T09:00:00.000', systolic, diastolic, pulse),
                folder_key,
                inherit_from=inherit_path,
            )
        self._share_with_analyser(folder, folder_key)

    # -- Tests -------------------------------------------------------------

    def test_cycle_averages_every_pod(self) -> None:
        outcome = self.service.run_cycle()
        document = outcome.document

        self.assertEqual(document['cohort']['pod_count'], 2)
        self.assertEqual(document['cohort']['observation_count'], 4)

        by_id = {pod['pod_id']: pod for pod in document['pods']}
        self.assertIn('server-alice', by_id)
        self.assertIn('server-bob', by_id)

        alice = by_id['server-alice']
        self.assertEqual(alice['observation_count'], 2)
        self.assertAlmostEqual(alice['measures']['systolic']['average'], 125.0)
        self.assertAlmostEqual(alice['measures']['diastolic']['average'], 85.0)

        bob = by_id['server-bob']
        self.assertEqual(bob['observation_count'], 2)
        self.assertAlmostEqual(bob['measures']['systolic']['average'], 145.0)

        # The cohort figure is the average of the two Pod averages.
        self.assertAlmostEqual(
            document['cohort']['average_of_averages']['systolic'], 135.0)
        self.assertEqual(document['warnings'], [])

    def test_results_are_written_locally(self) -> None:
        self.service.run_cycle()
        latest = self.service.store.read_latest()
        self.assertIsNotNone(latest)
        self.assertEqual(latest['schema_version'], 1)
        self.assertEqual(len(self.service.store.list_runs()), 1)

    def test_each_pod_receives_its_own_average(self) -> None:
        document = self.service.run_cycle().document
        published = {
            entry['pod_id']: entry for entry in document['sharing']['published']
        }
        self.assertIn('server-alice', published)
        self.assertEqual(
            published['server-alice']['recipients'], [self.alice.web_id])
        self.assertFalse(published['server-alice']['failures'])

        payload = self._open_as_recipient(
            self.alice, published['server-alice']['resource_url'])
        self.assertEqual(payload['kind'], 'pod-average')
        self.assertAlmostEqual(payload['average']['systolic'], 125.0)
        self.assertAlmostEqual(
            payload['cohort']['average_of_averages']['systolic'], 135.0)

    def test_cohort_average_goes_to_every_pod(self) -> None:
        document = self.service.run_cycle().document
        cohort_entries = [
            entry for entry in document['sharing']['published']
            if entry['kind'] == 'cohort-average'
        ]
        self.assertEqual(len(cohort_entries), 1)
        self.assertCountEqual(
            cohort_entries[0]['recipients'],
            [self.alice.web_id, self.bob.web_id])

        for pod in (self.alice, self.bob):
            payload = self._open_as_recipient(
                pod, cohort_entries[0]['resource_url'])
            self.assertEqual(payload['kind'], 'cohort-average')
            self.assertAlmostEqual(
                payload['cohort']['average_of_averages']['diastolic'], 91.2)

    def test_recipient_permission_log_records_the_grant(self) -> None:
        self.service.run_cycle()
        log_url = paths.perm_log_url(self.alice.web_id, APP)
        self.assertIn(log_url, self.client.resources)
        self.assertIn('grant', self.client.resources[log_url])
        self.assertIn(self.alice.web_id, self.client.resources[log_url])

    def test_analyser_results_are_not_re_analysed(self) -> None:
        # Publishing writes into the Analyser's own data folder; a second cycle
        # must not treat those as somebody's blood pressure readings.
        first = self.service.run_cycle().document
        second = self.service.run_cycle().document
        self.assertEqual(second['cohort']['pod_count'],
                         first['cohort']['pod_count'])

    # -- Helpers -----------------------------------------------------------

    def _open_as_recipient(self, pod: FakePod, resource_url: str) -> dict:
        """Open a published result the way HealthPod would, on the Pod side."""

        shared_url = paths.shared_key_url(pod.web_id, APP)
        document = self.client.resources[shared_url]
        unique_id = crypto.unique_resource_id(resource_url, pod.web_id)
        subject = paths.APPS_RES_ID + unique_id

        record = turtle.triple_map(document, base=shared_url)[subject]
        sealed_key = turtle.single(record[paths.APPS_DATA + 'sharedKey'])
        sealed_path = turtle.single(record[paths.APPS_DATA + 'path'])
        self.assertEqual(
            crypto.rsa_decrypt(pod.private_key, sealed_path), resource_url)

        key = base64.b64decode(crypto.rsa_decrypt(pod.private_key, sealed_key))
        content = self.client.resources[resource_url]
        fields = turtle.triple_map(content, base=resource_url)[resource_url]
        plaintext = crypto.aes_ctr_decrypt(
            turtle.single(fields[paths.APPS_TERMS + 'encData']),
            key,
            base64.b64decode(turtle.single(fields[paths.APPS_TERMS + 'iv'])),
        )
        return json.loads(plaintext)


class WatchGuardTests(unittest.TestCase):
    """The watcher must not loop on a problem that retrying cannot fix."""

    def test_watch_refuses_to_start_without_credentials(self) -> None:
        config = Config(analyser=AnalyserConfig(web_id=ANALYSER_WEB_ID))
        service = AnalyserService(config)
        with self.assertRaises(ConfigError):
            service.watch()

    def test_watch_reports_every_missing_secret_at_once(self) -> None:
        config = Config(analyser=AnalyserConfig(
            web_id=ANALYSER_WEB_ID, client_id='id', client_secret='secret'))
        service = AnalyserService(config)
        with self.assertRaises(ConfigError) as raised:
            service.watch()
        message = str(raised.exception)
        self.assertIn('security_key', message)
        self.assertNotIn('client_id', message)


if __name__ == '__main__':
    unittest.main()
