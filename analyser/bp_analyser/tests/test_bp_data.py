"""Choosing the key that opens a shared reading.

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

# HealthPod used to encrypt every reading with a key of its own and share the
# readings one by one. It now encrypts them with their folder's key and shares
# the folder, and it moves older readings over when it next shares. A reading
# moved that way can still have its old key in the Analyser's shared keys, so
# the key the document names has to win.

from __future__ import annotations

import json
import unittest
from types import SimpleNamespace

from bp_analyser import bp_data, crypto, pod_paths as paths

from tests.test_pipeline import APP, SERVER, encrypted_resource, reading

FOLDER = f'{SERVER}/bob/{APP}/data/blood_pressure/'
FILE = f'{FOLDER}bp_2026-08-20.json.enc.ttl'
INHERIT_PATH = f'{APP}/data/blood_pressure/'
CONFIG = SimpleNamespace(analyser=SimpleNamespace(app_dir_name=APP))
PAYLOAD = reading('2026-08-20T09:00:00.000', 140, 95, 80)


class DecryptDocumentTests(unittest.TestCase):

    def test_folder_key_opens_a_reading_that_inherits_it(self) -> None:
        folder_key = crypto.random_key()
        text = encrypted_resource(FILE, PAYLOAD, folder_key,
                                  inherit_from=INHERIT_PATH)

        plaintext = bp_data.decrypt_document(
            text, FILE, {FOLDER: folder_key}, CONFIG)

        self.assertEqual(json.loads(plaintext), PAYLOAD)

    def test_named_folder_key_wins_over_a_stale_file_key(self) -> None:
        folder_key = crypto.random_key()
        stale_key = crypto.random_key()
        text = encrypted_resource(FILE, PAYLOAD, folder_key,
                                  inherit_from=INHERIT_PATH)

        plaintext = bp_data.decrypt_document(
            text, FILE, {FILE: stale_key, FOLDER: folder_key}, CONFIG)

        self.assertEqual(json.loads(plaintext), PAYLOAD)

    def test_a_reading_with_its_own_key_still_opens(self) -> None:
        file_key = crypto.random_key()
        text = encrypted_resource(FILE, PAYLOAD, file_key)

        plaintext = bp_data.decrypt_document(
            text, FILE, {FILE: file_key}, CONFIG)

        self.assertEqual(json.loads(plaintext), PAYLOAD)

    def test_no_shared_key_is_reported(self) -> None:
        text = encrypted_resource(FILE, PAYLOAD, crypto.random_key(),
                                  inherit_from=INHERIT_PATH)

        with self.assertRaises(crypto.DecryptionError):
            bp_data.decrypt_document(text, FILE, {}, CONFIG)

    def test_folder_is_the_one_the_service_derives(self) -> None:
        self.assertEqual(
            FOLDER,
            paths.data_url(f'{SERVER}/bob/profile/card#me', APP,
                           'blood_pressure') + '/',
        )


if __name__ == '__main__':
    unittest.main()
