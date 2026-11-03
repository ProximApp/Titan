#!/usr/bin/env bash
# Measures the coverage of ONE lib file without losing the suite-wide lcov.
#
#   tool/cov_file.sh lib/tickets/ui/pages/book_ticket_page.dart \
#                     test/tickets/integration/tickets_book_integration_test.dart
#
# A targeted `flutter test --coverage` OVERWRITES coverage/lcov.info with just
# the files that run touched, so measuring one file used to mean copying the
# suite-wide lcov aside by hand, restoring it afterwards, and getting the awk
# right every time. This script owns that dance: it backs the file up, runs the
# given tests, prints the target's covered/total (still excluding generated/
# and l10n/, like the suite-wide number), then restores the suite lcov.
#
# The restore is a trap, so it happens even when the tests fail or the run is
# interrupted — a broken measurement must never cost you the full-run lcov.
set -euo pipefail

target="${1:-}"
if [ -z "$target" ]; then
  echo "usage: tool/cov_file.sh <lib/...dart> <test/...dart> [more test files...]" >&2
  exit 2
fi
shift
if [ "$#" -lt 1 ]; then
  echo "tool/cov_file.sh: pass at least one test file" >&2
  exit 2
fi

backup="$(mktemp /tmp/lcov_suite_backup.XXXXXX)"
if [ -f coverage/lcov.info ]; then
  cp coverage/lcov.info "$backup"
else
  : > "$backup"
fi

restore() {
  cp "$backup" coverage/lcov.info
  rm -f "$backup"
}
trap restore EXIT

echo "== running $* =="
flutter test --no-pub --coverage "$@"

echo "== coverage for $target =="
awk -v target="$target" '
  /^SF:/ {
    f = substr($0, 4)
    # lcov writes either an absolute path or a repo-relative one; compare on
    # the tail of the target path so both spellings match.
    hit = (index(f, target) > 0)
    next
  }
  hit && /^DA:/ {
    split(substr($0, 4), a, ",")
    total++
    if (a[2] + 0 > 0) covered++
  }
  /^end_of_record/ {
    if (hit) {
      if (total > 0) {
        printf "%s\n  covered %d / %d executable lines = %.1f%%\n", target, covered, total, 100 * covered / total
      } else {
        printf "%s\n  NOT INSTRUMENTED (the tests never loaded it)\n", target
      }
      found = 1
    }
    hit = 0
    covered = 0
    total = 0
  }
  END {
    if (!found) printf "%s\n  NOT IN lcov.info (nothing under test imports it)\n", target
  }
' coverage/lcov.info
