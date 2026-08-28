"""Reading and decrypting blood pressure observations from a Pod.

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

# HealthPod writes one file per reading, encrypted, with this JSON inside:
#
#     {"timestamp": "2026-08-19T09:15:00.000",
#      "responses": {"systolic": 118, "diastolic": 76,
#                    "heart_rate": 64, "notes": ""}}
#
# The file itself is a small turtle document holding the initialisation vector
# and the ciphertext. This module unwraps that, and also accepts plain JSON and
# CSV so that data shared publicly (which solidpod stores unencrypted) or
# exported from the app can be analysed too.

from __future__ import annotations

import base64
import csv
import io
import json
import logging
from dataclasses import dataclass, field
from datetime import datetime, timezone

from . import crypto, pod_paths as paths, turtle
from .config import Config
from .solid_client import ForbiddenError, NotFoundError, SolidClient

log = logging.getLogger(__name__)


@dataclass
class Observation:
    """One blood pressure reading."""

    timestamp: datetime | None
    systolic: float
    diastolic: float
    heart_rate: float | None
    source_url: str


@dataclass
class ReadReport:
    """What happened while reading one Pod's shared files."""

    observations: list[Observation]
    files_read: int = 0
    files_skipped: int = 0
    skipped_reasons: dict[str, str] = field(default_factory=dict)


def _as_float(value: object) -> float | None:
    """Coerce a JSON or CSV cell to a number, or None when it is not one."""

    if value is None or isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return float(value)
    text = str(value).strip()
    if not text:
        return None
    try:
        return float(text)
    except ValueError:
        return None


def _parse_timestamp(value: object) -> datetime | None:
    """Parse the ISO 8601 timestamps HealthPod writes."""

    if not value:
        return None
    text = str(value).strip().replace('Z', '+00:00')
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        # HealthPod records local wall-clock time; treat it as UTC so that
        # readings from different Pods remain comparable.
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed


def _in_range(value: float, bounds: tuple[float, float]) -> bool:
    return bounds[0] <= value <= bounds[1]


def observation_from_mapping(
    payload: dict, source_url: str, config: Config,
) -> Observation | None:
    """Build an observation from one decoded JSON record.

    Accepts both the survey shape (measurements under `responses`) and a flat
    mapping, and rejects anything outside the configured sanity bounds.
    """

    data = config.data
    body = payload.get(data.responses_field)
    fields = body if isinstance(body, dict) else payload

    systolic = _as_float(fields.get(data.systolic_field))
    diastolic = _as_float(fields.get(data.diastolic_field))
    heart_rate = _as_float(fields.get(data.heart_rate_field))

    if systolic is None or diastolic is None:
        return None
    if not _in_range(systolic, data.systolic_range):
        return None
    if not _in_range(diastolic, data.diastolic_range):
        return None
    if heart_rate is not None and not _in_range(heart_rate, data.heart_rate_range):
        heart_rate = None

    return Observation(
        timestamp=_parse_timestamp(
            payload.get(data.timestamp_field) or fields.get(data.timestamp_field)),
        systolic=systolic,
        diastolic=diastolic,
        heart_rate=heart_rate,
        source_url=source_url,
    )


def _observations_from_json(
    text: str, source_url: str, config: Config,
) -> list[Observation]:
    """Read one reading, or a list of them, from a JSON document."""

    payload = json.loads(text)
    records = payload if isinstance(payload, list) else [payload]
    observations = []
    for record in records:
        if not isinstance(record, dict):
            continue
        observation = observation_from_mapping(record, source_url, config)
        if observation is not None:
            observations.append(observation)
    return observations


def _observations_from_csv(
    text: str, source_url: str, config: Config,
) -> list[Observation]:
    """Read readings from a CSV export, matching columns case-insensitively."""

    reader = csv.DictReader(io.StringIO(text))
    observations = []
    for row in reader:
        normalised = {
            (key or '').strip().lower().replace(' ', '_'): value
            for key, value in row.items()
        }
        observation = observation_from_mapping(normalised, source_url, config)
        if observation is not None:
            observations.append(observation)
    return observations


def decrypt_document(
    text: str,
    file_url: str,
    keys: dict[str, bytes],
    config: Config,
) -> str:
    """Return the plaintext of a solidpod-encrypted turtle document.

    Non-encrypted content is returned unchanged. Raises [crypto.DecryptionError]
    when the document is encrypted but no key for it has been shared.
    """

    stripped = text.lstrip()
    if not (stripped.startswith('@prefix') or stripped.startswith('<')):
        return text

    record = turtle.triple_map(text, base=file_url).get(file_url)
    if record is None:
        # Some servers rewrite the subject; fall back to the only subject that
        # carries an encData predicate.
        for candidate in turtle.triple_map(text, base=file_url).values():
            if paths.APPS_TERMS + 'encData' in candidate:
                record = candidate
                break
    if record is None:
        return text

    enc_data = turtle.single(record.get(paths.APPS_TERMS + 'encData'))
    iv_b64 = turtle.single(record.get(paths.APPS_TERMS + 'iv'))
    if not enc_data or not iv_b64:
        return text

    inherit_from = turtle.single(record.get(paths.APPS_TERMS + 'inheritKeyFrom'))
    key = keys.get(file_url)
    if key is None and inherit_from:
        # The file was encrypted with its folder's key, so the folder is what
        # the owner shared. Its URL is the Pod root plus the recorded path.
        pod_root = paths.owner_pod_root(file_url, config.analyser.app_dir_name)
        inherited_url = pod_root + inherit_from.lstrip('/')
        if not inherited_url.endswith('/'):
            inherited_url += '/'
        key = keys.get(inherited_url)
    if key is None:
        # A folder share where the files carry their own keys: try the folder.
        folder_url = file_url.rsplit('/', 1)[0] + '/'
        key = keys.get(folder_url)
    if key is None:
        raise crypto.DecryptionError(
            'no key has been shared for this resource')

    return crypto.aes_ctr_decrypt(enc_data, key, base64.b64decode(iv_b64))


def read_file(
    client: SolidClient,
    file_url: str,
    keys: dict[str, bytes],
    config: Config,
) -> list[Observation]:
    """Read and parse one shared file into observations."""

    accept = 'text/turtle' if file_url.endswith('.ttl') else '*/*'
    text = client.get_text(file_url, accept=accept)

    if file_url.endswith('.ttl'):
        text = decrypt_document(text, file_url, keys, config)

    if file_url.endswith('.csv') or text.lstrip().lower().startswith('timestamp,'):
        return _observations_from_csv(text, file_url, config)
    return _observations_from_json(text, file_url, config)


def read_pod(
    client: SolidClient,
    file_urls: list[str],
    keys: dict[str, bytes],
    config: Config,
) -> ReadReport:
    """Read every shared file of one Pod, tolerating individual failures."""

    report = ReadReport(observations=[])
    for file_url in file_urls:
        try:
            observations = read_file(client, file_url, keys, config)
        except (NotFoundError, ForbiddenError) as exc:
            report.files_skipped += 1
            report.skipped_reasons[file_url] = str(exc)
            log.warning('cannot read %s: %s', file_url, exc)
            continue
        except crypto.DecryptionError as exc:
            report.files_skipped += 1
            report.skipped_reasons[file_url] = str(exc)
            log.warning('cannot decrypt %s: %s', file_url, exc)
            continue
        except (ValueError, json.JSONDecodeError) as exc:
            report.files_skipped += 1
            report.skipped_reasons[file_url] = f'unreadable content: {exc}'
            log.warning('cannot parse %s: %s', file_url, exc)
            continue

        report.files_read += 1
        report.observations.extend(observations)

    return report
