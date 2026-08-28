"""Pod URL and path arithmetic, mirroring solidpod's `pod_paths.dart`.

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

# A Solid Pod laid out by solidpod looks like this, where `<app>` is the
# application directory name (`healthpod` for HealthPod):
#
#     https://server/<pod>/profile/card#me        the WebID
#     https://server/<pod>/<app>/data/            application data
#     https://server/<pod>/<app>/encryption/enc-keys.ttl
#     https://server/<pod>/<app>/encryption/ind-keys.ttl
#     https://server/<pod>/<app>/sharing/public-key.ttl
#     https://server/<pod>/<app>/shared/shared-keys.ttl
#     https://server/<pod>/<app>/logs/permissions-log.ttl
#
# The last three are the ones that make cross-Pod sharing work: a granter reads
# the recipient's public key, writes the sealed resource key into the recipient's
# `shared-keys.ttl`, and appends a line to the recipient's permission log.

from __future__ import annotations

from urllib.parse import urlsplit

# The profile document suffix every solidpod WebID ends with.

PROFILE_CARD = 'profile/card#me'

# Resource names inside the application directory.

ENC_KEY_FILE = 'enc-keys.ttl'
IND_KEY_FILE = 'ind-keys.ttl'
PUB_KEY_FILE = 'public-key.ttl'
SHARED_KEY_FILE = 'shared-keys.ttl'
PERM_LOG_FILE = 'permissions-log.ttl'

# Sub-directories inside the application directory.

DATA_DIR = 'data'
SHARING_DIR = 'sharing'
SHARED_DIR = 'shared'
ENC_DIR = 'encryption'
LOGS_DIR = 'logs'

# Predicate namespaces used by solidpod, from `schema.dart`.

APPS_TERMS = 'https://solidcommunity.au/predicates/terms#'
APPS_DATA = 'https://solidcommunity.au/predicates/data#'
APPS_RES_ID = 'https://solidcommunity.au/predicates/resourceid#'
APPS_LOG_ID = 'https://solidcommunity.au/predicates/logid#'
DC_TERMS = 'http://purl.org/dc/terms/'
FOAF = 'http://xmlns.com/foaf/0.1/'
ACL_NS = 'http://www.w3.org/ns/auth/acl#'
LDP_NS = 'http://www.w3.org/ns/ldp#'


def pod_root(web_id: str) -> str:
    """The Pod root URL (with a trailing slash) for [web_id]."""

    if PROFILE_CARD in web_id:
        return web_id.split(PROFILE_CARD)[0]
    # Fall back to stripping the profile document, whatever it is called.
    base = web_id.split('#')[0]
    return base.rsplit('/', 2)[0] + '/'


def web_id_of(pod_root_url: str) -> str:
    """The WebID of the Pod rooted at [pod_root_url]."""

    return pod_root_url.rstrip('/') + '/' + PROFILE_CARD


def pod_slug(web_id: str) -> str:
    """A filesystem- and URL-safe identifier for a Pod.

    Matches solidpod's `getUniqueStrWebId()`, so the same Pod carries the same
    label here as it does in the Flutter apps: `server-host-podname`.
    """

    slug = web_id
    for scheme in ('https://', 'http://'):
        if slug.startswith(scheme):
            slug = slug[len(scheme):]
    slug = slug.replace('/' + PROFILE_CARD, '').replace(PROFILE_CARD, '')
    return slug.strip('/').replace('/', '-')


def server_of(web_id: str) -> str:
    """The origin (scheme and authority) hosting [web_id]."""

    parts = urlsplit(web_id)
    return f'{parts.scheme}://{parts.netloc}'


def app_url(web_id: str, app_dir_name: str, *segments: str) -> str:
    """Build a URL under the application directory of [web_id]'s Pod."""

    tail = '/'.join(segment.strip('/') for segment in segments if segment)
    base = f'{pod_root(web_id)}{app_dir_name}'
    return f'{base}/{tail}' if tail else f'{base}/'


def enc_key_url(web_id: str, app_dir_name: str) -> str:
    """URL of the file holding the verification and private keys."""

    return app_url(web_id, app_dir_name, ENC_DIR, ENC_KEY_FILE)


def ind_key_url(web_id: str, app_dir_name: str) -> str:
    """URL of the file holding this Pod's own individual resource keys."""

    return app_url(web_id, app_dir_name, ENC_DIR, IND_KEY_FILE)


def pub_key_url(web_id: str, app_dir_name: str) -> str:
    """URL of the publicly readable RSA public key of a Pod."""

    return app_url(web_id, app_dir_name, SHARING_DIR, PUB_KEY_FILE)


def shared_key_url(web_id: str, app_dir_name: str) -> str:
    """URL of the file where other Pods drop keys shared with this Pod."""

    return app_url(web_id, app_dir_name, SHARED_DIR, SHARED_KEY_FILE)


def perm_log_url(web_id: str, app_dir_name: str) -> str:
    """URL of the permission log of a Pod."""

    return app_url(web_id, app_dir_name, LOGS_DIR, PERM_LOG_FILE)


def data_url(web_id: str, app_dir_name: str, *segments: str) -> str:
    """URL of a resource under the application data directory."""

    return app_url(web_id, app_dir_name, DATA_DIR, *segments)


def owner_pod_root(resource_url: str, app_dir_name: str) -> str:
    """The Pod root that owns [resource_url].

    The application directory is the marker: everything to its left is the Pod.
    Falls back to the first path segment for resources stored outside the
    application directory, which is how a Pod hosted at the server root or with
    a non-standard layout still resolves to something sensible.
    """

    marker = f'/{app_dir_name}/'
    if marker in resource_url:
        return resource_url.split(marker)[0] + '/'

    parts = urlsplit(resource_url)
    segments = [s for s in parts.path.split('/') if s]
    if not segments:
        return f'{parts.scheme}://{parts.netloc}/'
    return f'{parts.scheme}://{parts.netloc}/{segments[0]}/'


def resource_path_in_pod(resource_url: str, web_id: str) -> str:
    """The Pod-relative path of [resource_url], as stored in the key files."""

    root = pod_root(web_id)
    if resource_url.startswith(root):
        return resource_url[len(root):]
    return urlsplit(resource_url).path.lstrip('/')


def is_container(url: str) -> bool:
    """Whether [url] denotes an LDP container rather than a file."""

    return url.endswith('/')
