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

# A `.venv` that came with the copy belongs to whoever built it, not to this
# host: its interpreter is a symlink to a path that does not exist here, and
# its site-packages hold binary wheels for another platform. `python3 -m venv`
# will not heal that — it skips creating `bin/python3` when something is
# already linked there, then fails trying to run it — so a venv whose
# interpreter does not work is removed rather than reused.
#
# Testing it by running it also catches the cases worth catching that have
# nothing to do with copying: a venv built against a Python that has since
# been upgraded out from under it, or one left half-written by a killed run.

if [ -e .venv ] && ! ./.venv/bin/python -c '' 2>/dev/null; then
  echo "==> Discarding an unusable .venv (built elsewhere, or broken)"
  rm -rf .venv
fi

if [ -d .venv ]; then
  echo "==> Reusing the virtual environment in $here/.venv"
else
  echo "==> Creating the virtual environment in $here/.venv"
  "$python" -m venv .venv
fi

echo "==> Installing dependencies"
./.venv/bin/pip install --upgrade pip >/dev/null
./.venv/bin/pip install -r requirements.txt

# ReadWritePaths= in the systemd units points at var/, and systemd sets up its
# mount namespace before the process starts: the directory has to exist by
# then, or the service fails with a namespace error rather than a useful one.

echo "==> Creating the runtime directories"
mkdir -p var/state var/results var/charts

# Bytecode compiled by another interpreter, or on another platform, is ignored
# rather than trusted — but it is dead weight in a deployment, and clearing it
# makes `find . -name '*.pyc'` a useful question again.

find . -name __pycache__ -type d -prune -exec rm -rf {} + 2>/dev/null || true
find . -name '.DS_Store' -delete 2>/dev/null || true

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
echo
echo "Changing bp_analyser/analyser.proto, the contract with the app, needs"
echo "one more package that nothing at run time uses:"
echo "    ./.venv/bin/pip install grpcio-tools   # then ./proto.sh"
