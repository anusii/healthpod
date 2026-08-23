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

from bp_analyser import charts, crypto, pod_paths as paths, turtle
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
        self.containers_created: list[str] = []
        self.private_urls: set[str] = set()

    # -- Reading -----------------------------------------------------------

    def get_text(self, url: str, *, accept: str = 'text/turtle') -> str:
        from bp_analyser.solid_client import ForbiddenError, NotFoundError

        if self._is_private(url):
            raise ForbiddenError(f'read {url}: access denied', 403)
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

    # URLs the Analyser may neither read nor write, as a Pod's own containers
    # normally are. The server answers 403: the resource is there, but not for
    # us.

    def _is_private(self, url: str) -> bool:
        return url in self.private_urls

    def exists(self, url: str) -> bool:
        # A private resource still exists; the server just will not show it.
        if self._is_private(url):
            return True
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
        from bp_analyser.solid_client import ForbiddenError

        if self._is_private(url):
            raise ForbiddenError(f'write {url}: access denied', 403)
        self.resources[url] = content

    def ensure_container(self, url: str) -> None:
        from bp_analyser.solid_client import ForbiddenError

        self.containers_created.append(url)
        # Walking up a path in somebody else's Pod runs into containers that
        # are theirs alone; the real client cannot create those.
        if self._is_private(url):
            raise ForbiddenError(f'create {url}: access denied', 403)

    def patch_sparql(self, url: str, query: str) -> None:
        """Apply the DELETE DATA and INSERT DATA blocks of a SPARQL update."""

        from bp_analyser.solid_client import NotFoundError

        self.patched.append((url, query))
        if url not in self.resources:
            # A real server will not patch a resource that is not there.
            raise NotFoundError(f'patch {url}: not found', 404)

        graph = turtle.parse(self.resources[url])
        prefixes = '\n'.join(
            f'@prefix {declaration} .'
            for declaration in self._prefix_declarations(query)
        )

        for keyword, apply in (('DELETE DATA', graph.remove),
                               ('INSERT DATA', graph.add)):
            for block in self._blocks(query, keyword):
                # The final full stop is optional inside a SPARQL data block
                # but required by the turtle parser used here.
                body = block.strip()
                if not body.endswith('.'):
                    body += ' .'
                patch = turtle.parse(f'{prefixes}\n{body}')
                for triple in patch:
                    apply(triple)

        self.resources[url] = graph.serialize(format='turtle')

    @staticmethod
    def _prefix_declarations(query: str) -> list[str]:
        declarations = []
        for chunk in query.split('PREFIX ')[1:]:
            head = chunk.split('DELETE')[0].split('INSERT')[0].strip()
            if head:
                declarations.append(head)
        return declarations

    @staticmethod
    def _blocks(query: str, keyword: str) -> list[str]:
        """The braced bodies following each occurrence of [keyword]."""

        blocks = []
        position = query.find(keyword)
        while position != -1:
            start = query.index('{', position)
            depth, index = 0, start
            while index < len(query):
                if query[index] == '{':
                    depth += 1
                elif query[index] == '}':
                    depth -= 1
                    if depth == 0:
                        break
                index += 1
            blocks.append(query[start + 1:index])
            position = query.find(keyword, index)
        return blocks

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


class PipelineHarness(unittest.TestCase):
    """An Analyser Pod, two contributors and a service wired to them.

    Holds no tests of its own: the cases below share this set-up.
    """

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


class PipelineTests(PipelineHarness):
    """One full cycle: read, average, publish, share."""

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

class ChartDeliveryTests(PipelineHarness):
    """The chart travels inside the result the Pod receives."""

    def setUp(self) -> None:
        super().setUp()
        self.config.output.render_charts = True

    def test_result_carries_a_png_of_the_pods_own_readings(self) -> None:
        if not charts.available():
            self.skipTest('matplotlib is not installed')

        document = self.service.run_cycle().document
        published = {
            entry['pod_id']: entry
            for entry in document['sharing']['published']
            if entry['kind'] == 'pod-average'
        }

        payload = self._open_as_recipient(
            self.alice, published['server-alice']['resource_url'])
        chart = payload['chart']
        self.assertEqual(chart['format'], 'png')
        self.assertEqual(chart['encoding'], 'base64')

        image = base64.b64decode(chart['data'])
        # The PNG signature, so this is an image rather than an error page.
        self.assertEqual(image[:8], b'\x89PNG\r\n\x1a\n')
        self.assertGreater(len(image), 1000)

    def test_a_chart_file_is_kept_for_the_operator(self) -> None:
        if not charts.available():
            self.skipTest('matplotlib is not installed')

        document = self.service.run_cycle().document
        self.assertIn('server-alice', document['charts']['pods'])
        self.assertTrue(
            self.service.store.chart_path('server-alice').is_file())

    def test_there_is_no_separate_cohort_chart(self) -> None:
        document = self.service.run_cycle().document
        self.assertNotIn('cohort', document['charts'])


class KeyDeliveryTests(PipelineHarness):
    """Handing the resource key to the recipient, the part that must not fail
    quietly: a Pod that has the result but not its key can fetch a document it
    cannot read, which looks like a fault in the app."""

    def _entry(self, pod: FakePod, resource_url: str) -> dict:
        """What the recipient's sharing inbox holds for one shared resource."""

        shared_url = paths.shared_key_url(pod.web_id, APP)
        subject = paths.APPS_RES_ID + crypto.unique_resource_id(
            resource_url, pod.web_id)

        return turtle.triple_map(
            self.client.resources[shared_url], base=shared_url)[subject]

    def _delivered_key(self, pod: FakePod, resource_url: str) -> bytes:
        """The resource key currently sitting in the recipient's inbox."""

        entry = self._entry(pod, resource_url)
        sealed = turtle.single(entry[paths.APPS_DATA + 'sharedKey'])

        return base64.b64decode(crypto.rsa_decrypt(pod.private_key, sealed))

    def _decrypt_resource(self, resource_url: str, key: bytes) -> str:
        """Open a published resource with a key held by the reader."""

        fields = turtle.triple_map(
            self.client.resources[resource_url], base=resource_url,
        )[resource_url]

        return crypto.aes_ctr_decrypt(
            turtle.single(fields[paths.APPS_TERMS + 'encData']),
            key,
            base64.b64decode(turtle.single(fields[paths.APPS_TERMS + 'iv'])),
        )

    def _pod_average_url(self, document: dict, pod_id: str) -> str:
        return next(
            entry['resource_url']
            for entry in document['sharing']['published']
            if entry['pod_id'] == pod_id
        )

    def test_a_second_run_replaces_the_key_rather_than_adding_one(self) -> None:
        # solidpod reads one value per predicate and fails on a list, so an
        # accumulated second value locks the recipient out of every result.

        first = self.service.run_cycle().document
        second = self.service.run_cycle().document
        self.assertEqual(
            self._pod_average_url(first, 'server-alice'),
            self._pod_average_url(second, 'server-alice'),
        )

        entry = self._entry(
            self.alice, self._pod_average_url(second, 'server-alice'))
        for predicate in ('sharedKey', 'path', 'accessList'):
            value = entry[paths.APPS_DATA + predicate]
            self.assertIsInstance(
                value, str, f'{predicate} accumulated more than one value')

    def test_the_key_from_the_latest_run_opens_the_latest_result(self) -> None:
        self.service.run_cycle()
        document = self.service.run_cycle().document

        payload = self._open_as_recipient(
            self.alice, self._pod_average_url(document, 'server-alice'))
        self.assertEqual(payload['generated_at'], document['generated_at'])

    def test_the_key_of_a_resource_does_not_change_between_runs(self) -> None:
        # A reader caches the key it was handed and only asks for another when
        # it holds none, so rotating the key silently breaks every reader.

        first = self.service.run_cycle().document
        url = self._pod_average_url(first, 'server-alice')
        key_after_first = self._delivered_key(self.alice, url)

        self.service.run_cycle()
        self.assertEqual(self._delivered_key(self.alice, url),
                         key_after_first)

    def test_a_cached_key_still_opens_a_later_result(self) -> None:
        # The app's position exactly: it holds the key from an earlier run and
        # reads content written by a later one.

        first = self.service.run_cycle().document
        url = self._pod_average_url(first, 'server-alice')
        cached = self._delivered_key(self.alice, url)

        second = self.service.run_cycle().document
        payload = json.loads(self._decrypt_resource(url, cached))

        self.assertEqual(payload['generated_at'], second['generated_at'])

    def test_a_private_container_on_the_way_does_not_stop_delivery(self) -> None:
        # The recipient's application folder is theirs alone; only the sharing
        # inbox inside it is open to others. Walking the path would fail.

        # Alice has never received a shared key, so her inbox does not exist
        # yet and has to be created inside a folder that is closed to us.
        self.client.private_urls.add(f'{SERVER}/alice/healthpod/')
        self.assertNotIn(
            paths.shared_key_url(self.alice.web_id, APP),
            self.client.resources,
        )

        document = self.service.run_cycle().document

        entry = next(
            item for item in document['sharing']['published']
            if item['pod_id'] == 'server-alice'
        )
        self.assertEqual(entry['failures'], {})
        self.assertEqual(entry['recipients'], [self.alice.web_id])

    def test_a_key_that_does_not_arrive_is_reported(self) -> None:
        # A server that accepts the write without storing it would otherwise
        # leave the app waiting for a result it can never open.

        shared_url = paths.shared_key_url(self.alice.web_id, APP)
        real_patch = self.client.patch_sparql
        real_put = self.client.put_text

        def swallow_patch(url: str, query: str) -> None:
            if url == shared_url:
                return
            real_patch(url, query)

        def swallow_put(url: str, content: str, **kwargs: object) -> None:
            if url == shared_url:
                return
            real_put(url, content, **kwargs)  # type: ignore[arg-type]

        self.client.patch_sparql = swallow_patch  # type: ignore[method-assign]
        self.client.put_text = swallow_put  # type: ignore[method-assign]

        document = self.service.run_cycle().document

        entry = next(
            item for item in document['sharing']['published']
            if item['pod_id'] == 'server-alice'
        )
        self.assertIn(self.alice.web_id, entry['failures'])
        self.assertTrue(
            any('did not receive the key' in warning
                for warning in document['warnings']),
            document['warnings'],
        )


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
