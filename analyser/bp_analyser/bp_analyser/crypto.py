"""Cryptography compatible with solidpod's on-Pod key and file formats.

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

# Every primitive here mirrors what the Dart `solidpod` package does, so that a
# resource written by HealthPod can be decrypted by this script and a resource
# written by this script can be decrypted by HealthPod. The Dart side of each
# primitive is named in the docstrings.
#
# Summary of the scheme (solidpod `key_helper.dart`):
#
#   * The security key is stretched into a 256-bit master key. Version 2 runs
#     Argon2id once (salted) and HKDF-expands the result into the master key and
#     a verification value; version 1 (legacy) is `sha256(securityKey)` truncated
#     to 32 hex characters, taken as UTF-8 bytes.
#   * The Pod holds an RSA key pair. The private key PEM is sealed with the
#     master key using AES-CBC and stored in `encryption/enc-keys.ttl`.
#   * Every encrypted resource has its own random AES-256 "individual key". The
#     resource itself is AES-SIC (counter mode, with PKCS7 padding, which is what
#     `encrypter_plus` applies by default) and wrapped in a small turtle
#     document. The individual key is sealed with the master key and recorded in
#     `encryption/ind-keys.ttl`.
#   * To share a resource the granter seals its individual key with the
#     recipient's RSA public key (PKCS#1 v1.5) and drops it into the recipient's
#     `shared/shared-keys.ttl`.

from __future__ import annotations

import base64
import hashlib
import hmac
import os

from argon2.low_level import Type as Argon2Type, hash_secret_raw
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding as asym_padding
from cryptography.hazmat.primitives.asymmetric.rsa import (
    RSAPrivateKey,
    RSAPublicKey,
)
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

# The Argon2id parameters are fixed by solidpod's `deriveKeys()`; changing any
# of them yields a different master key and every resource becomes unreadable.

_ARGON2_PARALLELISM = 4
_ARGON2_MEMORY_KIB = 10000
_ARGON2_ITERATIONS = 1
_ARGON2_HASH_LENGTH = 32

_HKDF_MASTER_INFO = b'solidpod/v2/master-key'
_HKDF_VERIFY_INFO = b'solidpod/v2/verification'

# Length of an AES block, which is also the length of an initialisation vector.

BLOCK_SIZE = 16

# Length of the AES key used for the master key and every individual key.

KEY_SIZE = 32


class DecryptionError(Exception):
    """Raised when content cannot be decrypted with the key supplied."""


# ---------------------------------------------------------------------------
# Key derivation
# ---------------------------------------------------------------------------


def derive_keys_v2(security_key: str, salt: bytes) -> tuple[bytes, str]:
    """Derive the (master key, verification value) pair, scheme version 2.

    Mirrors `deriveKeys()` in solidpod: a single Argon2id run produces a master
    secret which is then HKDF-expanded into two domain-separated outputs. The
    verification value is returned base64-encoded, as it is stored on the Pod.
    """

    master_secret = hash_secret_raw(
        secret=security_key.encode('utf-8'),
        salt=salt,
        time_cost=_ARGON2_ITERATIONS,
        memory_cost=_ARGON2_MEMORY_KIB,
        parallelism=_ARGON2_PARALLELISM,
        hash_len=_ARGON2_HASH_LENGTH,
        type=Argon2Type.ID,
    )

    def expand(info: bytes) -> bytes:
        return HKDF(
            algorithm=hashes.SHA256(), length=32, salt=salt, info=info,
        ).derive(master_secret)

    master_key = expand(_HKDF_MASTER_INFO)
    verification = base64.b64encode(expand(_HKDF_VERIFY_INFO)).decode('ascii')
    return master_key, verification


def derive_keys_v1(security_key: str) -> tuple[bytes, str]:
    """Derive the (master key, verification value) pair, legacy version 1.

    Mirrors `genLegacyMasterKey()` and `genLegacyVerificationKey()`: the hex
    digest truncated to 32 characters, used as UTF-8 bytes rather than decoded.
    """

    digest = hashlib.sha256(security_key.encode('utf-8')).hexdigest()[:32]
    verification = hashlib.sha224(
        security_key.encode('utf-8')).hexdigest()[:32]
    return digest.encode('utf-8'), verification


def verification_matches(expected: str, actual: str) -> bool:
    """Compare two verification values without leaking a matching prefix."""

    return hmac.compare_digest(expected.encode('utf-8'), actual.encode('utf-8'))


# ---------------------------------------------------------------------------
# Symmetric encryption
# ---------------------------------------------------------------------------


def _pkcs7_pad(data: bytes) -> bytes:
    pad = BLOCK_SIZE - (len(data) % BLOCK_SIZE)
    return data + bytes([pad]) * pad


def _pkcs7_unpad(data: bytes, *, strict: bool) -> bytes:
    """Remove PKCS7 padding.

    `encrypter_plus` pads even in counter mode, so well-formed content always
    carries padding. Content produced by an older or hand-rolled writer may
    not, hence the tolerant path used when [strict] is false.
    """

    if not data:
        return data
    pad = data[-1]
    valid = (
        1 <= pad <= BLOCK_SIZE
        and len(data) >= pad
        and data[-pad:] == bytes([pad]) * pad
    )
    if valid:
        return data[:-pad]
    if strict:
        raise DecryptionError('content is not correctly PKCS7-padded')
    return data


def aes_ctr_encrypt(plaintext: str, key: bytes, iv: bytes) -> str:
    """Encrypt with AES-SIC + PKCS7 and return base64, as `encryptData()` does.

    Counter mode in PointyCastle ("SIC") treats the whole 16-byte IV as a
    big-endian counter, which is exactly what `modes.CTR` does here.
    """

    encryptor = Cipher(algorithms.AES(key), modes.CTR(iv)).encryptor()
    sealed = encryptor.update(_pkcs7_pad(plaintext.encode('utf-8')))
    sealed += encryptor.finalize()
    return base64.b64encode(sealed).decode('ascii')


def aes_ctr_decrypt(encoded: str, key: bytes, iv: bytes) -> str:
    """Decrypt base64 AES-SIC content written by `encryptData()`."""

    try:
        raw = base64.b64decode(encoded)
    except Exception as exc:  # noqa: BLE001 - surfaced as a decryption failure.
        raise DecryptionError(f'content is not valid base64: {exc}') from exc

    decryptor = Cipher(algorithms.AES(key), modes.CTR(iv)).decryptor()
    opened = decryptor.update(raw) + decryptor.finalize()
    opened = _pkcs7_unpad(opened, strict=False)
    try:
        return opened.decode('utf-8')
    except UnicodeDecodeError as exc:
        raise DecryptionError(
            'decrypted content is not UTF-8; the key is probably wrong'
        ) from exc


def aes_cbc_encrypt(plaintext: str, key: bytes, iv: bytes) -> str:
    """Encrypt with AES-CBC + PKCS7, as `encryptPrivateKey()` does."""

    encryptor = Cipher(algorithms.AES(key), modes.CBC(iv)).encryptor()
    sealed = encryptor.update(_pkcs7_pad(plaintext.encode('utf-8')))
    sealed += encryptor.finalize()
    return base64.b64encode(sealed).decode('ascii')


def aes_cbc_decrypt(encoded: str, key: bytes, iv: bytes) -> str:
    """Decrypt base64 AES-CBC content written by `encryptPrivateKey()`."""

    try:
        raw = base64.b64decode(encoded)
    except Exception as exc:  # noqa: BLE001 - surfaced as a decryption failure.
        raise DecryptionError(f'content is not valid base64: {exc}') from exc

    if not raw or len(raw) % BLOCK_SIZE:
        raise DecryptionError('ciphertext length is not a multiple of 16')

    decryptor = Cipher(algorithms.AES(key), modes.CBC(iv)).decryptor()
    opened = decryptor.update(raw) + decryptor.finalize()
    try:
        return _pkcs7_unpad(opened, strict=True).decode('utf-8')
    except UnicodeDecodeError as exc:
        raise DecryptionError(
            'decrypted content is not UTF-8; the security key is wrong'
        ) from exc


def random_key() -> bytes:
    """A fresh AES-256 individual key, as `genRandIndividualKey()` returns."""

    return os.urandom(KEY_SIZE)


def random_iv() -> bytes:
    """A fresh initialisation vector, as `genRandIV()` returns."""

    return os.urandom(BLOCK_SIZE)


# ---------------------------------------------------------------------------
# RSA key handling
# ---------------------------------------------------------------------------


def load_private_key(pem: str) -> RSAPrivateKey:
    """Load the Pod's RSA private key from the PEM stored in enc-keys.ttl."""

    key = serialization.load_pem_private_key(
        pem.strip().encode('ascii'), password=None)
    if not isinstance(key, RSAPrivateKey):
        raise DecryptionError('the stored private key is not an RSA key')
    return key


def load_public_key(body: str) -> RSAPublicKey:
    """Load a Pod's RSA public key from the body held in public-key.ttl.

    solidpod strips the PEM armour before storing the key (`trimPubKeyStr()`),
    and the underlying generator has emitted both PKCS#1 and SubjectPublicKeyInfo
    encodings over time, so all four combinations are attempted.
    """

    body = ''.join(body.split())
    candidates = []
    if 'BEGIN' in body:
        candidates.append(body)
    else:
        for label in ('RSA PUBLIC KEY', 'PUBLIC KEY'):
            wrapped = '\n'.join(
                [f'-----BEGIN {label}-----']
                + [body[i:i + 64] for i in range(0, len(body), 64)]
                + [f'-----END {label}-----', '']
            )
            candidates.append(wrapped)

    for candidate in candidates:
        try:
            key = serialization.load_pem_public_key(candidate.encode('ascii'))
        except Exception:  # noqa: BLE001 - try the next encoding.
            continue
        if isinstance(key, RSAPublicKey):
            return key

    try:
        key = serialization.load_der_public_key(base64.b64decode(body))
    except Exception as exc:  # noqa: BLE001
        raise DecryptionError(f'unreadable RSA public key: {exc}') from exc
    if not isinstance(key, RSAPublicKey):
        raise DecryptionError('the stored public key is not an RSA key')
    return key


def rsa_encrypt(public_key: RSAPublicKey, plaintext: str) -> str:
    """Seal a short string for a recipient Pod and return base64.

    `encrypter_plus` defaults to PKCS#1 v1.5, which is what solidpod uses when
    it copies a shared key into a recipient's Pod.
    """

    sealed = public_key.encrypt(
        plaintext.encode('utf-8'), asym_padding.PKCS1v15())
    return base64.b64encode(sealed).decode('ascii')


def rsa_decrypt(private_key: RSAPrivateKey, encoded: str) -> str:
    """Open a value sealed for this Pod with [rsa_encrypt]."""

    try:
        opened = private_key.decrypt(
            base64.b64decode(encoded), asym_padding.PKCS1v15())
    except Exception as exc:  # noqa: BLE001 - surfaced as a decryption failure.
        raise DecryptionError(
            f'could not open a value sealed with our public key: {exc}'
        ) from exc
    return opened.decode('utf-8')


def unique_resource_id(resource_url: str, recipient_web_id: str) -> str:
    """The share identifier, as `getUniqueIdResUrl()` computes it."""

    return hashlib.sha256(
        (resource_url + recipient_web_id).encode('utf-8')).hexdigest()
