#!/usr/bin/env bash
# Validates a config.json before it is handed to `--dart-define-from-file`.
#
#   tool/check_config.sh config.json
#
# Every key here is read through `String.fromEnvironment` in
# lib/tools/functions.dart, which is a *const* lookup: a missing one does not
# fail the build, it compiles to the empty string and throws a StateError the
# first time the app tries to use it. On the web that means shipping a bundle
# that dies on the login screen. The CI config comes from a repository variable
# that nobody can see the contents of, so checking it here is the only place the
# mistake is cheap.
set -euo pipefail

file="${1:-config.json}"
[ -f "$file" ] || { echo "::error::$file does not exist"; exit 1; }
jq empty "$file" 2>/dev/null || { echo "::error::$file is not valid JSON"; exit 1; }

fail=0
note() { echo "::error::$file: $1"; fail=1; }

for key in FLAVOR APP_NAME SCHOOL_NAME APP_ID_PREFIX BACKEND_HOST TITAN_URL; do
  value=$(jq -r --arg k "$key" '.[$k] // empty' "$file")
  [ -n "$value" ] || note "missing or empty \"$key\""
done

# getTitanHost() and getTitanURL() both reject a host without a trailing slash,
# at runtime, with a StateError.
for key in BACKEND_HOST TITAN_URL; do
  value=$(jq -r --arg k "$key" '.[$k] // empty' "$file")
  case "$value" in
    ""|*/) ;;
    *) note "\"$key\" must end with a slash" ;;
  esac
done

# `flutter build web` rejects --flavor, so this key is the only thing telling a
# web build which flavor it is; getAppFlavor() lower-cases it but the icon and
# Plausible lookups compare against these three exactly.
flavor=$(jq -r '.FLAVOR // empty' "$file")
case "$flavor" in
  ""|prod|alpha|dev) ;;
  *) note "\"flavor\" is \"$flavor\", expected one of prod, alpha, dev" ;;
esac

[ "$fail" -eq 0 ] || exit 1
echo "$file looks complete (flavor: $flavor)"
