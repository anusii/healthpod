"""Turning the shared-keys inbox into a per-Pod list of files to read.

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

# A Pod owner may share a single blood pressure reading, a selection of them, or
# the whole `healthpod/data/blood_pressure` folder. All three arrive as entries
# in the Analyser's shared-keys file, so this module normalises them into one
# shape: for each contributing Pod, the list of resource URLs to read, plus an
# index of every key the Analyser holds so the reader can unlock them.

from __future__ import annotations

import logging
from dataclasses import dataclass, field

from . import pod_paths as paths
from .config import Config
from .keys import SharedResource
from .solid_client import ForbiddenError, NotFoundError, SolidClient

log = logging.getLogger(__name__)

# Extensions the reader knows how to interpret.

_READABLE_SUFFIXES = ('.enc.ttl', '.json', '.csv')


@dataclass
class PodDataset:
    """Everything one contributing Pod has shared with the Analyser."""

    web_id: str
    pod_root: str
    slug: str
    file_urls: list[str] = field(default_factory=list)
    container_urls: list[str] = field(default_factory=list)

    @property
    def resource_count(self) -> int:
        """How many individual files were found for this Pod."""

        return len(self.file_urls)


def _matches(resource_url: str, config: Config) -> bool:
    """Whether a shared resource looks like blood pressure data."""

    fragments = config.data.path_fragments
    if not fragments:
        return True
    return any(fragment in resource_url for fragment in fragments)


def key_index(shared: list[SharedResource]) -> dict[str, bytes]:
    """Map every shared resource URL (file or folder) to its key."""

    return {item.resource_url: item.key for item in shared}


def discover(
    client: SolidClient, shared: list[SharedResource], config: Config,
) -> list[PodDataset]:
    """Group the shared resources into one dataset per contributing Pod."""

    app = config.analyser.app_dir_name
    datasets: dict[str, PodDataset] = {}

    def dataset_for(resource_url: str) -> PodDataset:
        root = paths.owner_pod_root(resource_url, app)
        existing = datasets.get(root)
        if existing is None:
            web_id = paths.web_id_of(root)
            existing = PodDataset(
                web_id=web_id, pod_root=root, slug=paths.pod_slug(web_id))
            datasets[root] = existing
        return existing

    for item in shared:
        if not _matches(item.resource_url, config):
            log.debug('ignoring shared resource outside the data path: %s',
                      item.resource_url)
            continue

        # Do not analyse anything the Analyser shared back to a Pod.
        if item.resource_url.startswith(config.analyser.pod_root):
            continue

        dataset = dataset_for(item.resource_url)

        if not item.is_container:
            if item.resource_url not in dataset.file_urls:
                dataset.file_urls.append(item.resource_url)
            continue

        dataset.container_urls.append(item.resource_url)
        try:
            members = client.list_container(item.resource_url)
        except (NotFoundError, ForbiddenError) as exc:
            log.warning('cannot list shared folder %s: %s',
                        item.resource_url, exc)
            continue

        for member in members:
            if member.endswith('/') or member.endswith('.acl'):
                continue
            if not member.endswith(_READABLE_SUFFIXES):
                continue
            if member not in dataset.file_urls:
                dataset.file_urls.append(member)

    for dataset in datasets.values():
        dataset.file_urls.sort()

    result = sorted(datasets.values(), key=lambda item: item.web_id)
    log.info('%d Pod(s) have shared data, %d file(s) in total',
             len(result), sum(item.resource_count for item in result))
    return result
