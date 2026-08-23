"""The chart the analyser draws and sends back to each contributing Pod.

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

import base64
import logging
import os
from datetime import datetime
from pathlib import Path
from typing import Any

log = logging.getLogger(__name__)

# Categorical colours, validated for colour-vision deficiency against a light
# surface. One hue per measure, used for the readings and for both of that
# measure's reference lines.

_SYSTOLIC = '#2a78d6'
_DIASTOLIC = '#eb6834'
_HEART_RATE = '#1baf7a'
_INK = '#1a1a19'
_MUTED = '#6b6a63'
_GRID = '#e4e3de'
_SURFACE = '#fcfcfb'

# The measures drawn, in a fixed order: (key, label, colour).

_MEASURES = (
    ('systolic', 'Systolic', _SYSTOLIC),
    ('diastolic', 'Diastolic', _DIASTOLIC),
    ('heart_rate', 'Heart rate', _HEART_RATE),
)

_matplotlib_warned = False


def set_cache_dir(directory: Path) -> None:
    """Give matplotlib a writable cache directory, before it is imported.

    matplotlib caches its font list under `$HOME/.config/matplotlib`. A
    sandboxed service has a read-only home — the systemd units leave only
    `var/` writable — so it falls back to a fresh temporary directory on every
    start, which is slow and noisy. Pointing `MPLCONFIGDIR` inside `var/`
    fixes both. An explicit setting in the environment always wins.
    """

    if os.environ.get('MPLCONFIGDIR'):
        return
    try:
        directory.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        log.debug('cannot create the matplotlib cache directory: %s', exc)
        return
    os.environ['MPLCONFIGDIR'] = str(directory)


def available() -> bool:
    """Whether charts can be rendered in this environment."""

    try:
        import matplotlib  # noqa: F401
    except ImportError:
        global _matplotlib_warned
        if not _matplotlib_warned:
            log.info('matplotlib is not installed; charts will be skipped')
            _matplotlib_warned = True
        return False
    return True


def encode(path: Path) -> str | None:
    """Base64-encode a rendered chart so it can travel inside the results.

    The result document is shared with the Pod through the ordinary Solid
    sharing mechanism, which carries text. Embedding the image means the app
    receives the chart with the numbers, in one read, with no second channel
    to authenticate.
    """

    try:
        return base64.b64encode(path.read_bytes()).decode('ascii')
    except OSError as exc:
        log.warning('cannot read the rendered chart %s: %s', path, exc)
        return None


def _figure(width: float, height: float):
    """A figure and axes with the recessive styling the chart uses."""

    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt

    figure, axes = plt.subplots(figsize=(width, height), dpi=144)
    figure.patch.set_facecolor(_SURFACE)
    axes.set_facecolor(_SURFACE)
    axes.grid(axis='y', color=_GRID, linewidth=1)
    axes.set_axisbelow(True)
    for side in ('top', 'right'):
        axes.spines[side].set_visible(False)
    for side in ('left', 'bottom'):
        axes.spines[side].set_color(_GRID)
    axes.tick_params(colors=_MUTED, length=0, labelsize=9)
    return figure, axes


def _series(observations: list, key: str) -> tuple[list[datetime], list[float]]:
    """The (time, value) pairs for one measure, in chronological order."""

    points = []
    for index, item in enumerate(observations):
        value = getattr(item, key, None)
        if value is None:
            continue
        # A reading without a timestamp still counts; place it in sequence so
        # the line stays complete rather than silently losing points.
        moment = item.timestamp or datetime.fromtimestamp(index)
        points.append((moment, float(value)))

    points.sort(key=lambda pair: pair[0])
    return [pair[0] for pair in points], [pair[1] for pair in points]


def render_pod_chart(
    *,
    observations: list,
    pod: dict[str, Any],
    cohort: dict[str, Any],
    path: Path,
) -> Path | None:
    """Draw one Pod's readings with its own and the cohort's averages.

    [observations] are that Pod's readings, [pod] its section of the results
    document and [cohort] the cohort section. Returns the path written, or
    None when there is nothing to draw.
    """

    if not available() or not observations:
        return None

    import matplotlib.dates as mdates
    from matplotlib.lines import Line2D

    figure, axes = _figure(width=9.0, height=5.0)

    measures = pod.get('measures') or {}
    cohort_averages = cohort.get('average_of_averages') or {}

    drawn = False
    own_labels: list[tuple[float, str, str]] = []
    cohort_labels: list[tuple[float, str, str]] = []

    for key, label, colour in _MEASURES:
        times, values = _series(observations, key)
        if not values:
            continue
        drawn = True

        # The readings themselves: a thin line with a marker per reading, so a
        # single reading is still visible.
        axes.plot(
            times, values,
            color=colour, linewidth=2, marker='o', markersize=4,
            markerfacecolor=colour, markeredgecolor=_SURFACE,
            markeredgewidth=1, label=label, zorder=3,
        )

        own = (measures.get(key) or {}).get('average')
        if own is not None:
            axes.axhline(
                float(own), color=colour, linewidth=1.5, linestyle='--',
                alpha=0.75, zorder=2)
            own_labels.append((float(own), f'{float(own):.0f}', colour))

        everyone = cohort_averages.get(key)
        if everyone is not None:
            axes.axhline(
                float(everyone), color=colour, linewidth=1.5, linestyle=':',
                alpha=0.6, zorder=2)
            cohort_labels.append(
                (float(everyone), f'{float(everyone):.0f}', colour))

    if not drawn:
        import matplotlib.pyplot as plt
        plt.close(figure)
        return None

    # Label the reference lines at opposite edges: the Pod's own averages on
    # the right, everybody's on the left. Two values that sit close together
    # then cannot collide with each other.

    for value, text, colour in own_labels:
        axes.annotate(
            text, xy=(1.0, value), xycoords=('axes fraction', 'data'),
            xytext=(4, 0), textcoords='offset points',
            va='center', ha='left', fontsize=8, color=colour,
        )
    for value, text, colour in cohort_labels:
        axes.annotate(
            text, xy=(0.0, value), xycoords=('axes fraction', 'data'),
            xytext=(-4, 0), textcoords='offset points',
            va='center', ha='right', fontsize=8, color=colour,
        )

    axes.set_ylabel('mm Hg (pressure) · bpm (pulse)', color=_MUTED, fontsize=9)
    axes.xaxis.set_major_formatter(mdates.DateFormatter('%d %b'))
    figure.autofmt_xdate(rotation=20, ha='right')

    count = pod.get('observation_count', len(observations))
    axes.set_title(
        f'Blood pressure over {count} reading{"" if count == 1 else "s"}',
        color=_INK, fontsize=12, loc='left', pad=28,
    )

    # Identity comes from the three coloured series; the two dashed and dotted
    # entries explain what the reference lines mean without repeating a colour.

    style_handles = [
        Line2D([], [], color=_MUTED, linewidth=1.5, linestyle='--',
               label='Your average'),
        Line2D([], [], color=_MUTED, linewidth=1.5, linestyle=':',
               label="Everyone's average"),
    ]
    handles, labels = axes.get_legend_handles_labels()
    legend = axes.legend(
        handles=handles + style_handles,
        labels=labels + [handle.get_label() for handle in style_handles],
        frameon=False, fontsize=9, ncol=5,
        loc='lower right', bbox_to_anchor=(1.0, 1.0),
    )
    for text in legend.get_texts():
        text.set_color(_INK)

    return _save(figure, path)


def _save(figure, path: Path) -> Path:
    import matplotlib.pyplot as plt

    path.parent.mkdir(parents=True, exist_ok=True)
    figure.tight_layout()
    figure.savefig(path, facecolor=_SURFACE)
    plt.close(figure)
    return path
