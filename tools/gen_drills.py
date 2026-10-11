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
    ap.add_argument("--only", default="",
                    help="comma list of sports to (re)write; the index is left alone")
    args = ap.parse_args()
    only = {x for x in args.only.split(",") if x}

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    failed = False
    # How many drills each sport ships. The hub's sport picker shows the
    # number on every card, and the only other way to know it is to parse
    # fifteen libraries (13MB) on a page that has to open instantly.
    counts = ({} if only else
              {sport: len(build(sport, CATALOGUE[sport])["drills"]) for sport in CATALOGUE})
    index_path = OUT_DIR / "index.json"
    index_payload = json.dumps(counts, indent=2, sort_keys=True) + "\n"
    if only:
        pass
    elif args.check:
        if (index_path.read_text(encoding="utf-8") if index_path.exists() else "") != index_payload:
            print(f"✗ {index_path.relative_to(REPO)} is stale — run tools/gen_drills.py")
            failed = True
    else:
        index_path.write_text(index_payload, encoding="utf-8")
    for sport in CATALOGUE:
        if only and sport not in only:
            continue
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
