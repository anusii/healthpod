"""Check the crypto against vectors produced by solidpod's own Dart libraries.

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

# The vectors below were generated with `package:cryptography` (Argon2id, HKDF),
# `package:encrypter_plus` (AES, RSA) and `package:basic_utils` (RSA key
# encoding) — the exact libraries solidpod depends on. If any of these tests
# fail, the analyser can no longer read what HealthPod writes, so treat a
# failure as a compatibility break rather than a test to be adjusted.

from __future__ import annotations

import base64
import unittest

from bp_analyser import crypto

SECURITY_KEY = 'analyser-test-key'
SALT_B64 = 'AAcOFRwjKjE4P0ZNVFtiaQ=='
MASTER_KEY_B64 = 'AXviUZ7ZLcJnlxnstbM4JdN2jjzS1H4xIYAWWR/+Ks4='
VERIFICATION_KEY = 'RR14Fk23AAsd+th1zbI5qPV0XaWbjJWyZAdlMMmIs04='
IV_B64 = 'AAECAwQFBgcICQoLDA0ODw=='
IND_KEY_B64 = 'c29saWRwb2QtdGVzdC1pbmRpdmlkdWFsLWtleS0xMjM='

PLAINTEXT = (
    '{"timestamp":"2026-08-19T09:15:00.000",'
    '"responses":{"systolic":118,"diastolic":76,"heart_rate":64,"notes":""}}'
)

# AES-SIC (counter mode) with PKCS7 padding, as `encryptData()` produces.

AES_CTR_B64 = (
    '94FG6VZKUFwKJI0fCwsY1O7UlaennUwi5tYvOQ4Rs5tAjboShFPVWbzoSuRGiU'
    'w1RYGMO7IzTnyYQFlLA5dE3QxUCi0X42+3z3iWTG/ckDHCn5ik+cjzPaKZpC9x'
    'dXIqPiAah7oxaFO8sVUWIucQ2A=='
)

# AES-CBC, as `encryptPrivateKey()` produces.

AES_CBC_B64 = (
    '2xHJtaHqEpxeOpDJ6qsrNbM8ppvas8MFtdATph/LfCGcZqwcT4TOJn5kkqb1hR'
    '7PJzi1nATphYSY01T3cvFLFHIGB7EIH4Tooa1E4YPp9tU3wY9H//xH/M/eCUAt'
    'OtO2Yqhat86N14okmrKGO8Qkxg=='
)

# The individual key sealed with the master key, as `ind-keys.ttl` holds it.

SEALED_IND_KEY_B64 = (
    'vNYTifVsGJsqJkyxfZ3kYDpfDyGwFPJsrhwshXg8kxmHkIUSeEA5M5mf3BfYZ4'
    'eb'
)


class KeyDerivationTests(unittest.TestCase):
    """The security key must stretch to exactly the same master key."""

    def test_version_two_derivation(self) -> None:
        master_key, verification = crypto.derive_keys_v2(
            SECURITY_KEY, base64.b64decode(SALT_B64))
        self.assertEqual(base64.b64encode(master_key).decode(), MASTER_KEY_B64)
        self.assertEqual(verification, VERIFICATION_KEY)

    def test_legacy_derivation_is_utf8_hex(self) -> None:
        master_key, verification = crypto.derive_keys_v1(SECURITY_KEY)
        self.assertEqual(len(master_key), 32)
        self.assertEqual(len(verification), 32)
        self.assertTrue(all(chr(byte) in '0123456789abcdef' for byte in master_key))

    def test_verification_comparison(self) -> None:
        self.assertTrue(crypto.verification_matches('abc', 'abc'))
        self.assertFalse(crypto.verification_matches('abc', 'abd'))
        self.assertFalse(crypto.verification_matches('abc', 'ab'))


class SymmetricTests(unittest.TestCase):
    """Resource content and key wrappers must round trip with Dart."""

    def setUp(self) -> None:
        self.iv = base64.b64decode(IV_B64)
        self.master_key = base64.b64decode(MASTER_KEY_B64)
        self.ind_key = base64.b64decode(IND_KEY_B64)

    def test_counter_mode_decrypt(self) -> None:
        self.assertEqual(
            crypto.aes_ctr_decrypt(AES_CTR_B64, self.ind_key, self.iv),
            PLAINTEXT)

    def test_counter_mode_encrypt(self) -> None:
        self.assertEqual(
            crypto.aes_ctr_encrypt(PLAINTEXT, self.ind_key, self.iv),
            AES_CTR_B64)

    def test_cbc_decrypt(self) -> None:
        self.assertEqual(
            crypto.aes_cbc_decrypt(AES_CBC_B64, self.master_key, self.iv),
            PLAINTEXT)

    def test_cbc_encrypt(self) -> None:
        self.assertEqual(
            crypto.aes_cbc_encrypt(PLAINTEXT, self.master_key, self.iv),
            AES_CBC_B64)

    def test_sealed_individual_key(self) -> None:
        self.assertEqual(
            crypto.aes_ctr_decrypt(
                SEALED_IND_KEY_B64, self.master_key, self.iv),
            IND_KEY_B64)

    def test_wrong_key_is_reported(self) -> None:
        with self.assertRaises(crypto.DecryptionError):
            crypto.aes_cbc_decrypt(AES_CBC_B64, crypto.random_key(), self.iv)


class RsaTests(unittest.TestCase):
    """Sharing seals short strings with PKCS#1 v1.5, as encrypter_plus does."""

    def test_round_trip(self) -> None:
        from cryptography.hazmat.primitives.asymmetric import rsa

        private = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        public = private.public_key()
        sealed = crypto.rsa_encrypt(public, IND_KEY_B64)
        self.assertEqual(crypto.rsa_decrypt(private, sealed), IND_KEY_B64)

    def test_public_key_body_without_armour(self) -> None:
        from cryptography.hazmat.primitives import serialization
        from cryptography.hazmat.primitives.asymmetric import rsa

        private = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        pem = private.public_key().public_bytes(
            serialization.Encoding.PEM,
            serialization.PublicFormat.PKCS1).decode()
        body = ''.join(
            line for line in pem.splitlines() if not line.startswith('-----'))

        loaded = crypto.load_public_key(body)
        self.assertEqual(
            loaded.public_numbers(), private.public_key().public_numbers())


class ShareIdentifierTests(unittest.TestCase):
    """The share identifier must match `getUniqueIdResUrl()`."""

    def test_identifier_is_sha256_of_url_and_recipient(self) -> None:
        import hashlib

        url = 'https://server/alice/healthpod/data/blood_pressure/a.json.enc.ttl'
        recipient = 'https://server/Analyser/profile/card#me'
        self.assertEqual(
            crypto.unique_resource_id(url, recipient),
            hashlib.sha256((url + recipient).encode()).hexdigest())


if __name__ == '__main__':
    unittest.main()
