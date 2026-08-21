#!/usr/bin/env python3
"""Produces the Latin-subset, hint-stripped fonts in assets/google_fonts/.

    pip install 'fonttools[woff]' brotli
    python3 tool/subset_font.py <source.ttf> <assets/google_fonts/Out-Style.ttf> \
        [--instance wght=400,wdth=100]

Google serves these families as full Unicode files with hinting, which is two
to ten times the size the app needs: this is a French-language app, the glyphs
outside Latin are never drawn, and the web renderer ignores TrueType hinting
entirely. Subsetting is what takes Lato-Regular from 165 KB to 46 KB (23 KB once
brotli'd) and it is the reason bundling the fonts beats letting google_fonts
fetch them from fonts.gstatic.com at runtime.

The recipe was previously undocumented, so re-cutting a font — or adding a
weight — meant guessing at the flags and quietly shipping a file two or three
times larger than its neighbours.
"""

import subprocess
import sys
from pathlib import Path

# Exactly the range Google Fonts calls "latin", which is what its own CSS asks
# for and therefore what the app rendered before the fonts were bundled. It
# already covers every accented character French needs, including the Œ ligature
# at U+0152.
LATIN = (
    "U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,"
    "U+0304,U+0308,U+0329,U+2000-206F,U+2074,U+20AC,U+2122,U+2191,U+2193,"
    "U+2212,U+2215,U+FEFF,U+FFFD"
)

# `gasp` is kept because it is what tells a rasteriser to smooth rather than
# hint; `fpgm`, `prep` and `cvt ` are the hinting programs themselves and are
# dead weight in a browser.
DROP_TABLES = "fpgm,prep,cvt,gvar,avar,STAT,fvar,HVAR,VVAR,MVAR"


def main(argv: list[str]) -> int:
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2

    source, output = Path(argv[1]), Path(argv[2])
    instance = None
    if "--instance" in argv:
        instance = argv[argv.index("--instance") + 1]

    if not source.exists():
        print(f"no such font: {source}", file=sys.stderr)
        return 1

    # A variable font has to be pinned to one point on its axes first, otherwise
    # the subsetter keeps every master and the file stays enormous.
    staged = source
    if instance:
        staged = output.with_suffix(".instance.ttf")
        run(
            [
                sys.executable, "-m", "fontTools.varLib.instancer",
                str(source), *instance.split(","), "-o", str(staged),
            ]
        )

    run(
        [
            sys.executable, "-m", "fontTools.subset", str(staged),
            f"--unicodes={LATIN}",
            f"--drop-tables+={DROP_TABLES}",
            "--layout-features=*",
            "--no-hinting",
            "--desubroutinize",
            "--name-IDs=*",
            f"--output-file={output}",
        ]
    )

    if staged != source:
        staged.unlink()

    print(f"{source.name}: {size(source)} -> {output.name}: {size(output)}")
    return 0


def run(cmd: list[str]) -> None:
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(result.stderr, file=sys.stderr)
        raise SystemExit(result.returncode)


def size(path: Path) -> str:
    return f"{path.stat().st_size / 1024:.1f} KB"


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
