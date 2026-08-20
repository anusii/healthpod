"""Reading and writing the small turtle documents solidpod puts on a Pod.

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

# Parsing goes through rdflib, which is strict and handles the several turtle
# dialects the Community Solid Server emits. Writing is done by hand so that the
# documents are byte-for-byte in the shape solidpod's own (rather more forgiving)
# parser expects to read back.

from __future__ import annotations

from typing import Any

from rdflib import Graph, URIRef

from . import pod_paths as paths


def parse(text: str, *, base: str | None = None) -> Graph:
    """Parse a turtle document, tolerating the absence of a base IRI."""

    graph = Graph()
    graph.parse(data=text, format='turtle', publicID=base)
    return graph


def triple_map(text: str, *, base: str | None = None) -> dict[str, dict[str, Any]]:
    """Flatten a turtle document into `{subject: {predicate: value}}`.

    Mirrors solidpod's `turtleToTripleMap()`: a predicate with one object maps
    to that object, a predicate with several maps to the list of objects.
    """

    graph = parse(text, base=base)
    flattened: dict[str, dict[str, Any]] = {}
    for subject, predicate, obj in graph:
        by_predicate = flattened.setdefault(str(subject), {})
        key = str(predicate)
        if key in by_predicate:
            existing = by_predicate[key]
            if isinstance(existing, list):
                existing.append(str(obj))
            else:
                by_predicate[key] = [existing, str(obj)]
        else:
            by_predicate[key] = str(obj)
    return flattened


def single(value: Any) -> str | None:
    """The lone value of a predicate, or None when it is absent."""

    if value is None:
        return None
    if isinstance(value, list):
        return value[0] if value else None
    return str(value)


def contained_resources(text: str, container_url: str) -> list[str]:
    """The resource URLs listed by an LDP container document."""

    graph = parse(text, base=container_url)
    contains = URIRef(paths.LDP_NS + 'contains')
    return sorted(str(obj) for obj in graph.objects(
        URIRef(container_url), contains))


def escape_literal(value: str) -> str:
    """Escape a string for use inside a turtle or SPARQL double-quoted literal."""

    return (
        value.replace('\\', '\\\\')
        .replace('"', '\\"')
        .replace('\n', '\\n')
        .replace('\r', '\\r')
    )


# ---------------------------------------------------------------------------
# Document writers
# ---------------------------------------------------------------------------


def encrypted_document(
    *, file_url: str, resource_path: str, iv_b64: str, enc_data_b64: str,
) -> str:
    """The encrypted-resource wrapper written by solidpod's `getEncTTLStr()`."""

    return (
        f'@prefix solidTerms: <{paths.APPS_TERMS}> .\n'
        f'<{file_url}>\n'
        f'    solidTerms:path "{escape_literal(resource_path)}";\n'
        f'    solidTerms:iv "{escape_literal(iv_b64)}";\n'
        f'    solidTerms:encData "{escape_literal(enc_data_b64)}".\n'
    )


def acl_document(
    *,
    resource_url: str,
    owner_web_id: str,
    reader_web_ids: list[str],
    is_file: bool = True,
) -> str:
    """A Web Access Control document granting the owner full control.

    Each WebID in [reader_web_ids] is granted Read. The resource is referenced
    relatively (its file name, or `./` for a container) exactly as solidpod's
    `genAclTurtle()` does, so the document resolves against the ACL URL.
    """

    target = './' if not is_file else resource_url.rstrip('/').split('/')[-1]
    lines = [
        f'@prefix acl: <{paths.ACL_NS}> .',
        f'@prefix foaf: <{paths.FOAF}> .',
        '',
        '<#owner>',
        '    a acl:Authorization;',
        f'    acl:accessTo <{target}>;',
    ]
    if not is_file:
        lines.append(f'    acl:default <{target}>;')
    lines += [
        f'    acl:agent <{owner_web_id}>;',
        '    acl:mode acl:Read, acl:Write, acl:Control.',
        '',
    ]

    for index, web_id in enumerate(reader_web_ids):
        lines += [
            f'<#reader{index}>',
            '    a acl:Authorization;',
            f'    acl:accessTo <{target}>;',
        ]
        if not is_file:
            lines.append(f'    acl:default <{target}>;')
        lines += [
            f'    acl:agent <{web_id}>;',
            '    acl:mode acl:Read.',
            '',
        ]

    return '\n'.join(lines)


def individual_keys_document(
    ind_key_url: str, records: dict[str, dict[str, str]],
) -> str:
    """The `ind-keys.ttl` document, as solidpod's `genIndKeyTTLStr()` writes it.

    [records] maps a resource URL to `{'path', 'iv', 'sessionKey'}`. solidpod
    rewrites this file wholesale rather than patching it, and so do we, which
    is why the caller must merge new records into the existing set first.
    """

    lines = [
        f'@prefix solidTerms: <{paths.APPS_TERMS}> .',
        f'@prefix terms: <{paths.DC_TERMS}> .',
        '',
        f'<{ind_key_url}>',
        '    terms:title "Individual Encryption Keys".',
        '',
    ]
    for resource_url, record in records.items():
        lines += [
            f'<{resource_url}>',
            f'    solidTerms:path "{escape_literal(record["path"])}";',
            f'    solidTerms:iv "{escape_literal(record["iv"])}";',
            f'    solidTerms:sessionKey "{escape_literal(record["sessionKey"])}".',
            '',
        ]
    return '\n'.join(lines)


def shared_keys_document(
    shared_key_url: str, unique_id: str, path: str, access: str, key: str,
) -> str:
    """A fresh `shared-keys.ttl` holding one entry.

    Used only when the recipient has no shared-keys file yet; otherwise the
    entry is inserted with SPARQL so that keys shared by other Pods survive.
    Mirrors the document `copySharedKey()` creates.
    """

    return (
        '@prefix : <#>.\n'
        f'@prefix foaf: <{paths.FOAF}>.\n'
        f'@prefix terms: <{paths.DC_TERMS}>.\n'
        f'@prefix resourceId: <{paths.APPS_RES_ID}>.\n'
        f'@prefix data: <{paths.APPS_DATA}>.\n'
        ':me\n'
        '    a foaf:PersonalProfileDocument;\n'
        '    terms:title "Shared Encryption Keys".\n'
        f'resourceId:{unique_id}\n'
        f'    data:path "{escape_literal(path)}";\n'
        f'    data:accessList "{escape_literal(access)}";\n'
        f'    data:sharedKey "{escape_literal(key)}".\n'
    )


def shared_key_insert_query(
    unique_id: str, path: str, access: str, key: str,
) -> str:
    """SPARQL to add one entry to an existing `shared-keys.ttl`."""

    return (
        f'PREFIX resourceId: <{paths.APPS_RES_ID}> '
        f'PREFIX data: <{paths.APPS_DATA}> '
        f'INSERT DATA {{resourceId:{unique_id} '
        f'data:path "{escape_literal(path)}"; '
        f'data:accessList "{escape_literal(access)}"; '
        f'data:sharedKey "{escape_literal(key)}".}};'
    )


def shared_key_delete_query(
    unique_id: str, path: str, access: str, key: str,
) -> str:
    """SPARQL to remove one entry from an existing `shared-keys.ttl`."""

    return (
        f'PREFIX resourceId: <{paths.APPS_RES_ID}> '
        f'PREFIX data: <{paths.APPS_DATA}> '
        f'DELETE DATA {{resourceId:{unique_id} '
        f'data:path "{escape_literal(path)}"; '
        f'data:accessList "{escape_literal(access)}"; '
        f'data:sharedKey "{escape_literal(key)}".}};'
    )


def permission_log_insert_query(entry_id: str, record: str) -> str:
    """SPARQL to append one line to a permission log, as `addPermLogLine()` does."""

    return (
        f'PREFIX logId: <{paths.APPS_LOG_ID}> '
        f'PREFIX data: <{paths.APPS_DATA}> '
        f'INSERT DATA {{logId:{entry_id} '
        f'data:log "<{escape_literal(record)}>"}};'
    )


def permission_log_document(log_url: str) -> str:
    """An empty permission log, as solidpod's `genPermLogTTLStr()` writes it."""

    return (
        f'@prefix terms: <{paths.DC_TERMS}> .\n'
        f'<{log_url}>\n'
        '    terms:title "Permissions Log".\n'
    )
