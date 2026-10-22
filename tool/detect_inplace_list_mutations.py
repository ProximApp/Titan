#!/usr/bin/env python3
"""The in-place list-mutation detector for lib/.

`test/shared/inplace_list_mutation_detector.dart` is the Dart port of THIS
file, and `test/tools/unit/inplace_list_mutations_test.dart` cross-checks the
two row for row — so any change here must be mirrored there and vice versa.
The Dart side exists so the ratchet can assert its own coverage without
shelling out to Python; this side exists so a silently-dead regex in the port
cannot drift unnoticed (a raw-string bug once took the findings from 21 to
115 with no error anywhere).

A finding is a bucket, a file, a line and the receiver expression. Anything
the detector cannot resolve to a copy, a class's own field, a notifier's API
or a platform object comes back as `review`, the only bucket the ratchet
treats as a finding.

Usage:
    python3 tool/detect_inplace_list_mutations.py          # review rows (exit 1
                                                          # when any exist)
    python3 tool/detect_inplace_list_mutations.py --all    # every bucket
    python3 tool/detect_inplace_list_mutations.py --count  # just the review count
    python3 tool/detect_inplace_list_mutations.py --dump   # "bucket id" rows,
                                                          # exit 0 — machine
                                                          # mode for the test
"""

import re
import sys
from pathlib import Path

# The repo root, resolved from this file so the dump is identical no matter
# which directory the tool is invoked from (the test compares it against the
# Dart port's cwd-relative `lib/...` ids).
ROOT = Path(__file__).resolve().parent.parent

# Every list/set method that mutates in place. `sort` is here so this tool
# supersedes tool/detect_inplace_sorts.py rather than sitting beside it.
MUTATORS = [
    "add",
    "addAll",
    "addFirst",
    "addLast",
    "clear",
    "fillRange",
    "insert",
    "insertAll",
    "remove",
    "removeAt",
    "removeFirst",
    "removeLast",
    "removeRange",
    "removeSingle",
    "removeWhere",
    "replaceRange",
    "retainWhere",
    "setAll",
    "setLength",
    "setRange",
    "shuffle",
    "sort",
]

# Longest first, so `removeAt` is never read as `remove`. (Same-length
# mutators never shadow each other, so the tie order cannot change results.)
ALT = "|".join(sorted(MUTATORS, key=lambda s: -len(s)))

# A receiver is a postfix expression: a base (identifier or literal) plus any
# number of `.field`, `.method(...)`, `?`, `!` and `[index]` steps. Matched
# FORWARDS on purpose: the original sort detector walked backwards over a
# loose character class, which ran straight through `=`, `>` and `+` and
# reported whole function bodies as receivers.
BASE = r"(?:[A-Za-z_$][\w$]*|\[[^\[\]]*\]|\{[^}]*\}|<[^>]*>\s*\[[^\]]*\])"
SEG = (
    r"(?:\s*[?!]?\s*\.\s*[A-Za-z_$][\w$]*"
    r"|\s*\.\s*[A-Za-z_$][\w$]*\s*\((?:[^()]|\([^()]*\))*\)"
    r"|\s*\[[^\[\]]*\])*"
)
RECEIVER = BASE + SEG

PLAIN = re.compile("(" + RECEIVER + r")\.(" + ALT + r")\s*\(")
# `..method(` — the extra dot is the cascade, so group 1 is the cascade
# TARGET, classified the same way a receiver is.
CASCADE = re.compile("(" + RECEIVER + r")\.\.(" + ALT + r")\s*\(")

# Receiver last-segments that are platform objects, not Dart collections.
CONTROL = {
    "controller",
    "prefs",
    "storage",
    "sink",
    "completer",
    "context",
    "cacher",
    "caches",
    "keys",
    "focusnode",
}

# `ListNotifierAPI`/`SingleNotifierAPI` expose methods whose names collide
# with the mutators. On a notifier receiver they are provider API.
PROVIDER_TAIL = re.compile(r"(notifier|provider|repository|repo)$", re.IGNORECASE)

# Types known NOT to be a collection. `DateTime.add(Duration)` is the
# important one: `DateTime.now().add(...)` is everywhere in this codebase.
NONLIST = re.compile(
    r"^DateTime\s*[.(]|\.now\(\)$|\.parse\(|^Duration|^String|^num$|^bool$"
)

# `state.sublist(0)`, `x.toList()`, `List.of(x)` — a copy made on the spot.
# `sublist` matters: it is this codebase's idiomatic "copy before I mutate".
COPY_TAIL = re.compile(
    r"(List|Set|Map)\s*[.<]"
    r"|\.(?:toList|toSet|sublist|from)\s*(?:<[^>]*>)?\s*\([^()]*\)"
    r"|\.cast<"
)

# `map.putIfAbsent(k, () => []).add(x)` — the receiver is a list the factory
# built on the spot. `[^;]*?` rather than `[^)]*` because the text to cross is
# `() => []`, which contains a closing paren of its own.
PUTIFABSENT = re.compile(r"putIfAbsent\([^;]*?=>\s*[\[<]")

# A declaration that builds a new collection right here.
TYPED = r"(?:final|const|var|late|static)?\s*[\w<>,\s?]*\??\s+"
FRESH_RHS = (
    r"(?:const\s+|final\s+|late\s+)?"
    r"(?:\[|\{|<[^>]*>\s*[\[{]|List\s*[.<]|Set\s*[.<]|Map\s*[.<]"
    r"|\w[\w.()\[\]]*\s*\.\s*(?:toList|toSet|sublist|split|cast)\s*(?:<[^>]*>)?\s*\([^()]*\)"
    r"|\w+\s*\.\s*(?:where|map|entries|keys|values)\b[^;]*\.(?:toList|toSet)\(\))"
)

# Patterns that splice a fragment in are built by CONCATENATION — the same
# discipline the Dart port needs, where a raw string would have compiled the
# fragment's name in literally and matched nothing.
DECL = re.compile(
    r"\b" + TYPED + r"(?P<name>[A-Za-z_$][\w$]*)\s*=\s*" + FRESH_RHS,
    re.MULTILINE,
)

# `List<X> foo = [];` split across two lines is the same declaration as a
# one-liner, so a bare reassignment to a literal makes the name fresh too.
REASSIGN = re.compile(
    r"^\s+(?P<name>[A-Za-z_$][\w$]*)\s*=\s*" + FRESH_RHS,
    re.MULTILINE,
)

# A class member: collection-typed, at exactly two spaces of indent. This repo
# formats at two spaces per level, so a two-space indent inside a top-level
# class is a field and a four-space one is a local.
FIELD = re.compile(
    r"^ {2}(?:static\s+|late\s+|final\s+|const\s+)*"
    r"(?:List|Set|Iterable|Map)<[^>]*>\??\s+(?P<name>[A-Za-z_$][\w$]*)\s*(?:=|;)"
)


def strip_noise(src):
    """Blank out comments and string bodies, preserving offsets and newlines.

    Without this a mutator name inside a doc comment, an l10n string or a URL
    is indistinguishable from a call — ledger #49's ratchet already learned
    that.
    """
    out = list(src)
    n = len(src)

    def blank(frm, to):
        for k in range(frm, min(to, n)):
            if out[k] != "\n":
                out[k] = " "

    i = 0
    while i < n:
        c = src[i]
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            j = src.find("\n", i)
            if j < 0:
                j = n
            blank(i, j)
            i = j
        elif c == "/" and i + 1 < n and src[i + 1] == "*":
            end = src.find("*/", i + 2)
            j = n if end < 0 else end + 2
            blank(i, j)
            i = j
        elif c in ("'", '"'):
            triple = src.startswith("'''", i) or src.startswith('"""', i)
            quote = src[i : i + 3] if triple else c
            j = i + len(quote)
            while j < n:
                if src[j] == "\\":
                    j += 2
                    continue
                if src.startswith(quote, j):
                    j += len(quote)
                    break
                j += 1
            blank(i, min(j, n))
            i = j
        else:
            i += 1
    return "".join(out)


def one_line(text):
    """Collapse a receiver to one line (the --dump one-row-per-line contract)."""
    return re.sub(r"\s+", " ", text).strip()


def tail_of(recv):
    parts = re.split(r"[.\[\]()<>]", recv)
    return parts[-1] if parts else ""


def declarations(src):
    fresh = set()
    fields = set()
    for m in REASSIGN.finditer(src):
        fresh.add(m.group("name"))
    for m in DECL.finditer(src):
        fresh.add(m.group("name"))
    for line in src.split("\n"):
        m = FIELD.search(line)
        if m:
            fields.add(m.group("name"))
    return fresh, fields


def classify(recv, fresh, fields):
    """Bucket a mutating call by what its receiver actually is."""
    recv = recv.strip()
    tail = tail_of(recv).strip()
    low = tail.lower()

    # `state` is the one name a file can never have made for itself: in a
    # Notifier it IS the provider's state, whatever the last line assigned to
    # it. `state = state.sublist(0)` makes a copy on the RIGHT of the
    # assignment and leaves `state` exactly as owned as it was. Getting this
    # backwards silences the single most dangerous receiver in the codebase.
    if low == "state":
        return "review"
    # A literal receiver is a fresh collection by construction.
    if recv.startswith(("[", "{", "<")):
        return "fresh"
    if COPY_TAIL.search(recv):
        return "fresh"
    if recv.endswith("]"):
        return "element"
    if low in CONTROL or low.endswith("controller"):
        return "control"
    if NONLIST.search(recv):
        return "nonlist"
    if PROVIDER_TAIL.search(low):
        return "api"
    if PUTIFABSENT.search(recv):
        return "fresh"
    # OWNED before FRESH so a notifier's own catalog is labelled as its own
    # rather than as a fresh list: both are "not a finding", but only one is
    # the right reason.
    if tail in fields:
        return "owned"
    if tail in fresh:
        return "fresh"
    return "review"


def find_inplace_list_mutations(root=ROOT / "lib"):
    """Scan `root` for in-place collection mutations.

    Returns (bucket, path, line, receiver) tuples sorted by path then line.
    """
    found = []
    files = sorted(p for p in root.rglob("*.dart") if p.is_file())
    for path in files:
        source = strip_noise(path.read_text(encoding="utf-8"))
        fresh, fields = declarations(source)
        rel = path.relative_to(ROOT).as_posix()
        for kind, rx in (("cascade", CASCADE), ("plain", PLAIN)):
            for m in rx.finditer(source):
                recv = m.group(1)
                method = m.group(2)
                bucket = classify(recv, fresh, fields)
                reported = f"{recv}..{method}" if kind == "cascade" else recv
                line = source.count("\n", 0, m.start()) + 1
                found.append((bucket, rel, line, one_line(reported)))
    found.sort(key=lambda t: (t[1], t[2]))
    return found


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    rows = find_inplace_list_mutations()
    review = [r for r in rows if r[0] == "review"]

    if "--dump" in argv:
        # "bucket id" — the exact two tokens the cross-check test parses.
        # Machine mode: always exit 0, the verdict belongs to the human modes.
        for bucket, rel, line, _ in rows:
            print(f"{bucket} {rel}:{line}")
        return 0

    if "--count" in argv:
        print(len(review))
        return 1 if review else 0

    for bucket, rel, line, recv in (rows if "--all" in argv else review):
        print(f"{bucket} {rel}:{line}  receiver={recv}")
    if "--all" in argv:
        print(f"{len(rows)} sites, {len(review)} review")
    return 1 if review else 0


if __name__ == "__main__":
    sys.exit(main())
