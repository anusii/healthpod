"""Logging set-up shared by the command line, the watcher and the API.

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

import logging
import sys
from logging.handlers import RotatingFileHandler

from .config import Config

_FORMAT = '%(asctime)s %(levelname)-7s %(name)s: %(message)s'
_DATE_FORMAT = '%Y-%m-%d %H:%M:%S'


def configure(config: Config, *, verbose: bool = False) -> None:
    """Send logging to stderr, and to a rotating file when one is configured.

    Under systemd the stderr stream is what lands in the journal, so a file is
    optional; when set it rotates at 5 MB and keeps five generations.
    """

    level = logging.DEBUG if verbose else getattr(
        logging, config.logging.level, logging.INFO)

    root = logging.getLogger()
    root.setLevel(level)
    for handler in list(root.handlers):
        root.removeHandler(handler)

    formatter = logging.Formatter(_FORMAT, _DATE_FORMAT)

    stream = logging.StreamHandler(sys.stderr)
    stream.setFormatter(formatter)
    root.addHandler(stream)

    if config.logging.file:
        config.logging.file.parent.mkdir(parents=True, exist_ok=True)
        rotating = RotatingFileHandler(
            config.logging.file, maxBytes=5 * 1024 * 1024, backupCount=5)
        rotating.setFormatter(formatter)
        root.addHandler(rotating)

    # httpx logs every request at INFO, which drowns out our own progress.
    logging.getLogger('httpx').setLevel(logging.WARNING)
