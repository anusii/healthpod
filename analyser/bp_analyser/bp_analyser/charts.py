"""Optional PNG charts of the analysis, for the front end to display.

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

# Charts are a convenience, not a requirement: if matplotlib is not installed
# the analyser logs the fact once and carries on, and the JSON results are
# unaffected. Each chart keeps to one unit per axis (millimetres of mercury on
# the pressure charts, beats per minute on the pulse chart) and labels every bar
# directly, so the figures stay readable in print and for colour-blind readers.

from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import Any

log = logging.getLogger(__name__)

# Categorical colours, validated for colour-vision deficiency against a light
# surface. Slot order is fixed: systolic, diastolic, then the comparison series.

_SERIES_1 = '#2a78d6'
_SERIES_2 = '#eb6834'
_SERIES_3 = '#1baf7a'
_INK = '#1a1a19'
_MUTED = '#6b6a63'
_GRID = '#e4e3de'
_SURFACE = '#fcfcfb'

# A hair of surface between adjacent bars, so a pair reads as two marks.

_GAP = 0.012

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


def _figure(width: float = 7.0, height: float = 4.0):
    """A figure and axes with the recessive styling used by every chart."""

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


def _label_bars(axes, bars, places: int = 0) -> None:
    """Print each bar's value above it, in ink rather than the series colour."""

    for bar in bars:
        height = bar.get_height()
        if height is None:
            continue
        axes.annotate(
            f'{height:.{places}f}',
            xy=(bar.get_x() + bar.get_width() / 2, height),
            xytext=(0, 3),
            textcoords='offset points',
            ha='center', va='bottom',
            fontsize=9, color=_INK,
        )


def _headroom(axes, values: list[float]) -> None:
    """Leave room above the tallest bar for its label and the legend."""

    tallest = max(values) if values else 0.0
    if tallest > 0:
        axes.set_ylim(0, tallest * 1.18)


def _legend(axes) -> None:
    """Place the legend above the plot, where it cannot cover a bar."""

    legend = axes.legend(
        frameon=False, fontsize=9, ncol=2,
        loc='lower right', bbox_to_anchor=(1.0, 1.0))
    for text in legend.get_texts():
        text.set_color(_INK)


def _save(figure, path: Path) -> Path:
    import matplotlib.pyplot as plt

    path.parent.mkdir(parents=True, exist_ok=True)
    figure.tight_layout()
    figure.savefig(path, facecolor=_SURFACE)
    plt.close(figure)
    return path


def render_pod_chart(
    pod: dict[str, Any], cohort: dict[str, Any], path: Path,
) -> Path | None:
    """One Pod's averages beside the cohort average of averages."""

    if not available():
        return None

    measures = pod.get('measures') or {}
    cohort_averages = cohort.get('average_of_averages') or {}

    labels, mine, theirs = [], [], []
    for key, label in (('systolic', 'Systolic'), ('diastolic', 'Diastolic')):
        measure = measures.get(key)
        if not measure:
            continue
        labels.append(label)
        mine.append(float(measure['average']))
        theirs.append(float(cohort_averages.get(key) or 0.0))

    if not labels:
        return None

    figure, axes = _figure(width=6.0, height=3.8)
    positions = range(len(labels))
    width = 0.3
    bars_mine = axes.bar(
        [p - width / 2 - _GAP for p in positions], mine, width,
        label='This Pod', color=_SERIES_1)
    bars_theirs = axes.bar(
        [p + width / 2 + _GAP for p in positions], theirs, width,
        label='Cohort average', color=_SERIES_3)

    _label_bars(axes, bars_mine)
    _label_bars(axes, bars_theirs)
    _headroom(axes, mine + theirs)
    axes.set_xticks(list(positions))
    axes.set_xticklabels(labels)
    axes.set_ylabel('mm Hg', color=_MUTED, fontsize=9)
    axes.set_title(
        f'Blood pressure average over {pod.get("observation_count", 0)} reading(s)',
        color=_INK, fontsize=11, loc='left', pad=24)
    _legend(axes)

    return _save(figure, path)


def render_cohort_chart(
    pods: list[dict[str, Any]], cohort: dict[str, Any], path: Path,
) -> Path | None:
    """Every contributing Pod's average, with the cohort figure marked."""

    if not available():
        return None

    included = [pod for pod in pods if pod.get('included_in_cohort')]
    if not included:
        return None

    labels = [pod['pod_id'] for pod in included]
    systolic = [
        float((pod['measures'].get('systolic') or {}).get('average') or 0.0)
        for pod in included
    ]
    diastolic = [
        float((pod['measures'].get('diastolic') or {}).get('average') or 0.0)
        for pod in included
    ]

    figure, axes = _figure(width=max(6.0, 1.6 * len(labels)), height=4.2)
    positions = range(len(labels))
    width = 0.3
    bars_systolic = axes.bar(
        [p - width / 2 - _GAP for p in positions], systolic, width,
        label='Systolic', color=_SERIES_1)
    bars_diastolic = axes.bar(
        [p + width / 2 + _GAP for p in positions], diastolic, width,
        label='Diastolic', color=_SERIES_2)

    _label_bars(axes, bars_systolic)
    _label_bars(axes, bars_diastolic)
    _headroom(axes, systolic + diastolic)

    averages = cohort.get('average_of_averages') or {}
    for key, colour in (('systolic', _SERIES_1), ('diastolic', _SERIES_2)):
        value = averages.get(key)
        if value:
            axes.axhline(
                float(value), color=colour, linewidth=2, linestyle='--',
                alpha=0.5)

    axes.set_xticks(list(positions))
    axes.set_xticklabels(labels, rotation=20, ha='right', fontsize=8)
    axes.set_ylabel('mm Hg', color=_MUTED, fontsize=9)
    axes.set_title(
        'Average per Pod, dashed lines show the cohort average of averages',
        color=_INK, fontsize=11, loc='left', pad=24)
    _legend(axes)

    return _save(figure, path)
