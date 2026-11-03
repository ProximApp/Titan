#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not on PATH" >&2
  exit 2
fi

ARGS=(
  --coverage
  --flavor prod
  --dart-define=flavor=prod
  --dart-define=APP_ID_PREFIX=test
  --dart-define=APP_NAME=MyEMApp
  --dart-define=BACKEND_HOST=https://myemapp.com/
  --dart-define=TITAN_URL=https://myemapp.com/
  --dart-define=SCHOOL_NAME=
)

echo "Starting full suite coverage run with:" >&2
printf '  %q\n' "${ARGS[@]}" >&2

flutter test "${ARGS[@]}"
