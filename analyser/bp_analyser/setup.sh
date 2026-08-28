#!/usr/bin/env bash
#
# Create the virtual environment for the HealthPod blood pressure analyser.
#
# Run from the project root: it creates .venv and config.yaml beside the
# `bp_analyser` package. A second analyser dropped alongside this project
# under analyser/ keeps its own environment, configuration and service unit.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"

python="${PYTHON:-python3}"

# A copy made over SFTP, or unpacked from an archive that does not carry
# permissions, arrives without the execute bit. Restore it here so ./run.sh
# works afterwards; failure is not fatal (the file may belong to someone else,
# and `bash run.sh` works regardless).

chmod +x run.sh setup.sh 2>/dev/null || \
  echo "Note: could not set the execute bit; invoke the scripts as 'bash run.sh'."

echo "==> Creating the virtual environment in $here/.venv"
"$python" -m venv .venv

echo "==> Installing dependencies"
./.venv/bin/pip install --upgrade pip >/dev/null
./.venv/bin/pip install -r requirements.txt

# ReadWritePaths= in the systemd units points at var/, and systemd sets up its
# mount namespace before the process starts: the directory has to exist by
# then, or the service fails with a namespace error rather than a useful one.

echo "==> Creating the runtime directories"
mkdir -p var/state var/results var/charts

if [ ! -f config.yaml ]; then
  echo "==> Creating config.yaml from the example"
  cp config.example.yaml config.yaml
  chmod 600 config.yaml
  echo "    Edit config.yaml: the Analyser WebID, the security key and the"
  echo "    client credentials are all required before the first run."
fi

echo
echo "Done. Verify the set-up with:"
echo "    ./run.sh check"
