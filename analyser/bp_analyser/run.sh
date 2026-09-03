#!/usr/bin/env bash
#
# Run the HealthPod blood pressure analyser from its virtual environment.
#
#   ./run.sh check       verify credentials, keys and what has been shared
#   ./run.sh run-once    one analysis cycle
#   ./run.sh watch       run continuously (the mode systemd uses)
#   ./run.sh serve       the read-only front-end API
#   ./run.sh cancel      ask a running watcher to abandon the current cycle
#   ./run.sh test        the offline test suite
#
# Everything runs from this directory, the project root: it holds the
# `bp_analyser` package, the configuration, the tests and the virtual
# environment, so the package resolves without any path juggling.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"

if [ ! -x .venv/bin/python ]; then
  echo "The virtual environment is missing. Run ./setup.sh first." >&2
  exit 1
fi

if [ "${1:-}" = 'test' ]; then
  shift
  exec ./.venv/bin/python -m unittest discover -s tests -t . "$@"
fi

config="${HEALTHPOD_ANALYSER_CONFIG:-$here/config.yaml}"

exec ./.venv/bin/python -m bp_analyser --config "$config" "$@"
