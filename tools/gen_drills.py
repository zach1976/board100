#!/usr/bin/env python3
"""Build the shipped drill library from the specs in this file.

Why a generator: a drill is a board — players, cones, a ball, and a movement
path per player with a phase number so the play unfolds in order. Hand-writing
that JSON is unreadable and unmaintainable; hand-placing it in the app and
exporting is slow and can't be diffed. Here one drill is ~10 lines of intent
and the coordinates stay reviewable.

Positions are in a nominal 1000x1500 portrait canvas (attacking upward: the
opponent goal is at y=0). The app rescales a loaded board to whatever canvas
it is on, so these numbers are proportions, not pixels.

    python3 tools/gen_drills.py            # writes tactics_board/assets/drills/
    python3 tools/gen_drills.py --check    # verify the checked-in output matches
"""
import argparse
import json
from pathlib import Path

from drills import CATALOGUE
from drills.engine import build

REPO = Path(__file__).resolve().parent.parent
OUT_DIR = REPO / "tactics_board" / "assets" / "drills"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true",
                    help="fail if the checked-in assets differ from this file")
    args = ap.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    failed = False
    for sport in CATALOGUE:
        payload = json.dumps(build(sport, CATALOGUE[sport]), ensure_ascii=False, indent=2) + "\n"
        path = OUT_DIR / f"{sport}.json"
        if args.check:
            current = path.read_text(encoding="utf-8") if path.exists() else ""
            if current != payload:
                print(f"✗ {path.relative_to(REPO)} is stale — run tools/gen_drills.py")
                failed = True
            else:
                print(f"✓ {path.relative_to(REPO)}")
        else:
            path.write_text(payload, encoding="utf-8")
            n = len(json.loads(payload)["drills"])
            print(f"{path.relative_to(REPO)}: {n} drills")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
