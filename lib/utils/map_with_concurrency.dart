/// Run an asynchronous action over a list with a bounded number in flight.
//
// Time-stamp: <Sunday 2026-09-14 10:00:00 +1000>
//
/// Copyright (C) 2026, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Tony Chen

library;

/// How many POD requests to keep in flight at once.
///
/// Each health record is a separate file on the POD, so loading or saving a
/// year of readings is hundreds of independent requests. Issuing them one
/// after another means the app waits a full network round trip per record,
/// which is what makes a remote POD server feel so much slower than a nearby
/// one. Overlapping a handful of requests hides most of that latency.
///
/// Six matches the per-host connection limit browsers impose, so the web build
/// gains nothing from a larger value and servers are not hammered.

const int podRequestConcurrency = 6;

/// Apply [action] to every element of [items], with at most [concurrency]
/// invocations running at the same time.
///
/// Results come back in the order of [items], regardless of the order in which
/// they complete. If [action] throws, the error propagates once the calls
/// already in flight have settled; handle per-item failures inside [action] if
/// the batch should carry on without them.

Future<List<R>> mapWithConcurrency<T, R>(
  List<T> items,
  Future<R> Function(T item) action, {
  int concurrency = podRequestConcurrency,
}) async {
  assert(concurrency > 0);

  if (items.isEmpty) return <R>[];

  final results = List<R?>.filled(items.length, null);
  var next = 0;

  Future<void> worker() async {
    while (true) {
      final index = next++;
      if (index >= items.length) return;
      results[index] = await action(items[index]);
    }
  }

  final workerCount = concurrency < items.length ? concurrency : items.length;

  await Future.wait(<Future<void>>[
    for (var i = 0; i < workerCount; i++) worker(),
  ]);

  return results.cast<R>();
}
