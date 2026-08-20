"""Averages per Pod, and the average of those averages across the cohort.

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

# Two cohort figures are computed and they answer different questions:
#
#   * the average of averages weights every Pod equally, so one enthusiastic
#     user taking six readings a day cannot dominate the cohort. This is the
#     figure shared back to the Pods;
#   * the pooled average weights every reading equally, and is reported
#     alongside it for context.
#
# Nothing in a Pod's own summary leaves that Pod, and nothing in the cohort
# summary identifies an individual: only counts and aggregates are shared.

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from statistics import mean, pstdev
from typing import Any

from .bp_data import Observation
from .config import Config


@dataclass
class Measure:
    """A single averaged measurement."""

    average: float
    minimum: float
    maximum: float
    count: int
    standard_deviation: float = 0.0

    def rounded(self, places: int) -> dict[str, Any]:
        """A JSON-friendly form, rounded for presentation."""

        return {
            'average': round(self.average, places),
            'minimum': round(self.minimum, places),
            'maximum': round(self.maximum, places),
            'standard_deviation': round(self.standard_deviation, places),
            'count': self.count,
        }


@dataclass
class PodSummary:
    """The analysis of one Pod's blood pressure data."""

    web_id: str
    pod_id: str
    pod_root: str
    observation_count: int
    systolic: Measure | None
    diastolic: Measure | None
    heart_rate: Measure | None
    first_observation: datetime | None
    last_observation: datetime | None
    files_read: int = 0
    files_skipped: int = 0
    included_in_cohort: bool = True
    notes: list[str] = field(default_factory=list)

    def to_dict(self, places: int) -> dict[str, Any]:
        """The per-Pod section of the results document."""

        return {
            'pod_id': self.pod_id,
            'web_id': self.web_id,
            'pod_root': self.pod_root,
            'observation_count': self.observation_count,
            'files_read': self.files_read,
            'files_skipped': self.files_skipped,
            'included_in_cohort': self.included_in_cohort,
            'first_observation': _iso(self.first_observation),
            'last_observation': _iso(self.last_observation),
            'measures': {
                'systolic': self.systolic.rounded(places) if self.systolic else None,
                'diastolic': (
                    self.diastolic.rounded(places) if self.diastolic else None),
                'heart_rate': (
                    self.heart_rate.rounded(places) if self.heart_rate else None),
            },
            'notes': list(self.notes),
        }


@dataclass
class CohortSummary:
    """The analysis across every contributing Pod."""

    pod_count: int
    included_pod_count: int
    observation_count: int
    average_of_averages: dict[str, float | None]
    pooled_average: dict[str, float | None]
    spread_of_averages: dict[str, float | None]

    def to_dict(self, places: int) -> dict[str, Any]:
        """The cohort section of the results document."""

        def rounded(values: dict[str, float | None]) -> dict[str, float | None]:
            return {
                key: (round(value, places) if value is not None else None)
                for key, value in values.items()
            }

        return {
            'pod_count': self.pod_count,
            'included_pod_count': self.included_pod_count,
            'observation_count': self.observation_count,
            'average_of_averages': rounded(self.average_of_averages),
            'pooled_average': rounded(self.pooled_average),
            'spread_of_averages': rounded(self.spread_of_averages),
        }


def _iso(value: datetime | None) -> str | None:
    return value.isoformat() if value else None


def _measure(values: list[float]) -> Measure | None:
    if not values:
        return None
    return Measure(
        average=mean(values),
        minimum=min(values),
        maximum=max(values),
        count=len(values),
        standard_deviation=pstdev(values) if len(values) > 1 else 0.0,
    )


def within_window(
    observations: list[Observation], config: Config,
) -> list[Observation]:
    """Drop readings older than the configured window."""

    window = config.analysis.window_days
    if not window:
        return observations
    cutoff = datetime.now(timezone.utc) - timedelta(days=window)
    return [
        item for item in observations
        if item.timestamp is None or item.timestamp >= cutoff
    ]


def summarise_pod(
    *,
    web_id: str,
    pod_id: str,
    pod_root: str,
    observations: list[Observation],
    config: Config,
    files_read: int = 0,
    files_skipped: int = 0,
) -> PodSummary:
    """Average one Pod's readings."""

    kept = within_window(observations, config)
    notes: list[str] = []
    if len(kept) != len(observations):
        notes.append(
            f'{len(observations) - len(kept)} reading(s) fell outside the '
            f'{config.analysis.window_days}-day window')

    timestamps = [item.timestamp for item in kept if item.timestamp]
    heart_rates = [
        item.heart_rate for item in kept if item.heart_rate is not None]

    included = len(kept) >= max(1, config.analysis.minimum_observations)
    if not included:
        notes.append(
            f'excluded from the cohort average: fewer than '
            f'{config.analysis.minimum_observations} reading(s)')

    return PodSummary(
        web_id=web_id,
        pod_id=pod_id,
        pod_root=pod_root,
        observation_count=len(kept),
        systolic=_measure([item.systolic for item in kept]),
        diastolic=_measure([item.diastolic for item in kept]),
        heart_rate=_measure(heart_rates),
        first_observation=min(timestamps) if timestamps else None,
        last_observation=max(timestamps) if timestamps else None,
        files_read=files_read,
        files_skipped=files_skipped,
        included_in_cohort=included,
        notes=notes,
    )


def summarise_cohort(summaries: list[PodSummary]) -> CohortSummary:
    """Combine the per-Pod averages into the cohort figures."""

    included = [item for item in summaries if item.included_in_cohort]

    def averages_of(attribute: str) -> list[float]:
        return [
            getattr(item, attribute).average
            for item in included
            if getattr(item, attribute) is not None
        ]

    def pooled(attribute: str) -> float | None:
        total = 0.0
        count = 0
        for item in included:
            measure = getattr(item, attribute)
            if measure is None:
                continue
            total += measure.average * measure.count
            count += measure.count
        return total / count if count else None

    def average_or_none(values: list[float]) -> float | None:
        return mean(values) if values else None

    def spread_or_none(values: list[float]) -> float | None:
        return pstdev(values) if len(values) > 1 else (0.0 if values else None)

    attributes = ('systolic', 'diastolic', 'heart_rate')
    return CohortSummary(
        pod_count=len(summaries),
        included_pod_count=len(included),
        observation_count=sum(item.observation_count for item in included),
        average_of_averages={
            name: average_or_none(averages_of(name)) for name in attributes},
        pooled_average={name: pooled(name) for name in attributes},
        spread_of_averages={
            name: spread_or_none(averages_of(name)) for name in attributes},
    )


def measure_dict(summary: PodSummary, places: int) -> dict[str, Any]:
    """The compact per-Pod averages shared back to that Pod."""

    return {
        name: (
            round(getattr(summary, name).average, places)
            if getattr(summary, name) is not None else None)
        for name in ('systolic', 'diastolic', 'heart_rate')
    }
