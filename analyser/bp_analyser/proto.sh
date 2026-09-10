#!/usr/bin/env bash
#
# Regenerate the gRPC bindings from bp_analyser/analyser.proto.
#
#   ./proto.sh          both languages
#   ./proto.sh python   the analyser's stubs only
#   ./proto.sh dart     the app's stubs only
#
# The proto file is the contract between the app and the analyser, and the
# only place it is written down. Both sets of bindings are generated from it
# and committed, so neither side needs a protobuf compiler to build — only
# whoever changes the contract does.
#
# Python lands beside the proto file, inside the package, because that is what
# makes the import in `analyser_pb2_grpc.py` a package-relative one:
# generating from the project root with `-I .` puts `bp_analyser.analyser_pb2`
# in the generated file rather than a bare `analyser_pb2`, which would only
# resolve if the package directory happened to be on the path.
#
# Dart lands in the app, beside the service that uses it.
#
# What each half needs, and only to run this:
#
#   pip install grpcio-tools            # inside the project's .venv
#   dart pub global activate protoc_plugin
#   protoc                              # apt install protobuf-compiler, or brew

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"

proto='bp_analyser/analyser.proto'

# The app's copy of this repository, four levels up: bp_analyser is inside
# healthpod/analyser/.

dart_out='../../lib/features/bp/analyser/grpc'

what="${1:-both}"

generate_python() {
  local python='.venv/bin/python'
  if [ ! -x "$python" ]; then
    python='python3'
  fi

  if ! "$python" -c 'import grpc_tools' 2>/dev/null; then
    echo "grpcio-tools is not installed. Run:" >&2
    echo "  ./.venv/bin/pip install grpcio-tools" >&2
    exit 1
  fi

  # --pyi_out gives the type checkers something to read; the runtime does not
  # need it, and neither does anything in this project, but a generated module
  # with no signatures anywhere is a poor thing to have to read.

  "$python" -m grpc_tools.protoc \
    -I . \
    --python_out=. \
    --pyi_out=. \
    --grpc_python_out=. \
    "$proto"

  echo "Python:  bp_analyser/analyser_pb2.py, analyser_pb2_grpc.py"
}

generate_dart() {
  if ! command -v protoc >/dev/null; then
    echo 'protoc is not installed (apt install protobuf-compiler).' >&2
    exit 1
  fi

  if ! command -v protoc-gen-dart >/dev/null; then
    echo 'The Dart plugin is not on the path. Run:' >&2
    echo '  dart pub global activate protoc_plugin' >&2
    echo 'and make sure ~/.pub-cache/bin is on $PATH.' >&2
    exit 1
  fi

  if [ ! -d "$dart_out" ]; then
    mkdir -p "$dart_out"
  fi

  # -I is the package directory rather than the project root, so the generated
  # Dart imports each other by bare file name and sit in one flat folder.

  protoc -I bp_analyser --dart_out="grpc:$dart_out" analyser.proto

  # The plugin also writes analyser.pbjson.dart, the proto descriptors as
  # base64. Nothing in the app reads them — the messages in analyser.pb.dart
  # carry their own field information, and only code that reflects over the
  # schema at runtime, which this app does not, needs the descriptors. Left in
  # place it is a file no import reaches, which is exactly what `make dcm`
  # reports, so it goes as soon as it arrives.

  rm -f "$dart_out/analyser.pbjson.dart"

  echo "Dart:    $dart_out/analyser.pb.dart, analyser.pbenum.dart, analyser.pbgrpc.dart"
}

case "$what" in
  python) generate_python ;;
  dart) generate_dart ;;
  both)
    generate_python
    generate_dart
    ;;
  *)
    echo "Usage: ./proto.sh [python|dart|both]" >&2
    exit 2
    ;;
esac
