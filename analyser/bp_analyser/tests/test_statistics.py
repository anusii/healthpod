"""Averaging: per Pod, then across the cohort.

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

import unittest
from datetime import datetime, timedelta, timezone

from bp_analyser import statistics
from bp_analyser.bp_data import Observation
from bp_analyser.config import AnalyserConfig, Config

WEB_ID = 'https://server/alice/profile/card#me'


def make_config(**analysis: object) -> Config:
    config = Config(analyser=AnalyserConfig(
        web_id='https://server/Analyser/profile/card#me'))
    for key, value in analysis.items():
        setattr(config.analysis, key, value)
    return config


def observation(systolic: float, diastolic: float,
                heart_rate: float | None = None,
                days_ago: int = 0) -> Observation:
    return Observation(
        timestamp=datetime.now(timezone.utc) - timedelta(days=days_ago),
        systolic=systolic,
        diastolic=diastolic,
        heart_rate=heart_rate,
        source_url='https://server/alice/healthpod/data/blood_pressure/x.ttl',
    )


def summarise(observations: list[Observation], config: Config) -> statistics.PodSummary:
    return statistics.summarise_pod(
        web_id=WEB_ID, pod_id='server-alice', pod_root='https://server/alice/',
        observations=observations, config=config)


class PodAverageTests(unittest.TestCase):
    """One Pod's readings."""

    def test_average_of_two_readings(self) -> None:
        summary = summarise(
            [observation(120, 80, 60), observation(130, 90, 70)],
            make_config())
        self.assertEqual(summary.observation_count, 2)
        self.assertAlmostEqual(summary.systolic.average, 125.0)
        self.assertAlmostEqual(summary.diastolic.average, 85.0)
        self.assertAlmostEqual(summary.heart_rate.average, 65.0)
        self.assertEqual(summary.systolic.minimum, 120)
        self.assertEqual(summary.systolic.maximum, 130)

    def test_missing_heart_rate_is_not_counted(self) -> None:
        summary = summarise(
            [observation(120, 80, 60), observation(130, 90, None)],
            make_config())
        self.assertEqual(summary.heart_rate.count, 1)
        self.assertAlmostEqual(summary.heart_rate.average, 60.0)

    def test_window_excludes_old_readings(self) -> None:
        summary = summarise(
            [observation(120, 80, days_ago=0), observation(200, 120, days_ago=90)],
            make_config(window_days=30))
        self.assertEqual(summary.observation_count, 1)
        self.assertAlmostEqual(summary.systolic.average, 120.0)
        self.assertTrue(summary.notes)

    def test_thin_pods_are_flagged_but_still_reported(self) -> None:
        summary = summarise([observation(120, 80)], make_config(
            minimum_observations=3))
        self.assertFalse(summary.included_in_cohort)
        self.assertEqual(summary.observation_count, 1)


class CohortTests(unittest.TestCase):
    """The average of averages, and its pooled companion."""

    def setUp(self) -> None:
        self.config = make_config()

    def _summary(self, pod_id: str, readings: list[tuple[float, float]]):
        return statistics.summarise_pod(
            web_id=f'https://server/{pod_id}/profile/card#me',
            pod_id=pod_id,
            pod_root=f'https://server/{pod_id}/',
            observations=[observation(s, d) for s, d in readings],
            config=self.config,
        )

    def test_every_pod_weighs_the_same(self) -> None:
        # One Pod with a single high reading, one with many low ones: the
        # average of averages sits midway, the pooled average does not.
        cohort = statistics.summarise_cohort([
            self._summary('a', [(160, 100)]),
            self._summary('b', [(120, 80)] * 9),
        ])
        self.assertAlmostEqual(cohort.average_of_averages['systolic'], 140.0)
        self.assertAlmostEqual(cohort.pooled_average['systolic'], 124.0)
        self.assertEqual(cohort.pod_count, 2)
        self.assertEqual(cohort.observation_count, 10)

    def test_excluded_pods_do_not_contribute(self) -> None:
        self.config.analysis.minimum_observations = 2
        cohort = statistics.summarise_cohort([
            self._summary('a', [(200, 120)]),
            self._summary('b', [(120, 80), (130, 85)]),
        ])
        self.assertEqual(cohort.included_pod_count, 1)
        self.assertAlmostEqual(cohort.average_of_averages['systolic'], 125.0)

    def test_empty_cohort_is_reported_as_empty(self) -> None:
        cohort = statistics.summarise_cohort([])
        self.assertEqual(cohort.pod_count, 0)
        self.assertIsNone(cohort.average_of_averages['systolic'])
        self.assertIsNone(cohort.pooled_average['systolic'])


if __name__ == '__main__':
    unittest.main()
