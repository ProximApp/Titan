#!/usr/bin/env bash
# Copies a flavor's favicon and PWA icons into the places web/index.html and
# web/manifest.json reference them from.
#
#   tool/web_icons.sh <flavor>          # alpha | prod | dev | emlyon
#   tool/web_icons.sh --from config.json
#
# The icons are kept per flavor under web/<Flavor>/, but the shell references
# them at the root — `favicon.png` and `icons/*` — and neither of those exists in
# the repository. Without this step `flutter build web` produces a page with no
# favicon and a manifest whose every icon is missing, which costs more than it
# looks: nginx's SPA fallback answers those URLs with index.html and a 200, so
# the browser gets HTML where it asked for a PNG and retries, and Chrome refuses
# to treat the app as installable when the manifest icons do not load.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ "${1:-}" = "--from" ]; then
  [ -f "${2:-}" ] || { echo "no such config file: ${2:-}" >&2; exit 1; }
  flavor=$(jq -r '.FLAVOR // empty' "$2")
  [ -n "$flavor" ] || { echo "no \"FLAVOR\" key in $2" >&2; exit 1; }
else
  flavor="${1:-}"
  [ -n "$flavor" ] || { echo "usage: $0 <flavor> | --from <config.json>" >&2; exit 1; }
fi

# web/Alpha, web/Prod, web/Dev — but web/emlyon, which is why this matches
# case-insensitively rather than just capitalising.
dir=$(find web -maxdepth 1 -type d -iname "$flavor" | head -1)
[ -n "$dir" ] || { echo "no web icon directory for flavor '$flavor'" >&2; exit 1; }

mkdir -p web/icons
cp -f "$dir/favicon.png" web/favicon.png
cp -f "$dir"/icons/* web/icons/

# We want to use the release index.html before compiling a release version
cp web/index.release.html web/index.html

# Every icon the manifest promises has to be on disk, or the app is silently not
# installable. Cheaper to fail here than to find out from a user.
missing=0
for src in $(jq -r '.icons[].src' web/manifest.json); do
  [ -f "web/$src" ] || { echo "manifest.json references missing web/$src" >&2; missing=1; }
done
[ -f web/favicon.png ] || { echo "web/favicon.png missing" >&2; missing=1; }
[ "$missing" -eq 0 ] || exit 1

echo "web icons set from $dir"
