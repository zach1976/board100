#!/usr/bin/env python3
"""List every drill sentence that has no text in a locale yet.

The generator stops at the first missing translation (narrate._localized
raises), which is right for a build and slow for filling gaps: fix one,
run again, find the next. This runs every sport's build with misses
recorded instead, and prints them all at once, keyed by the English
sentence exactly as tools/drills/i18n/*.json wants it.

    python3 tools/drills/i18n_missing.py --locale de-DE
    python3 tools/drills/i18n_missing.py --locale nl-NL --sport volleyball
    python3 tools/drills/i18n_missing.py --locale de-DE --json   # stub to fill

Exit status 1 when anything is missing.
"""
import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from drills import CATALOGUE, narrate  # noqa: E402
from drills.engine import build  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--locale", required=True, help="e.g. de-DE")
    ap.add_argument("--sport", default="", help="comma list; default all")
    ap.add_argument("--json", action="store_true",
                    help="print a {english: {locale: \"\"}} stub instead")
    args = ap.parse_args()
    only = {x for x in args.sport.split(",") if x}

    found: dict[str, dict[str, set]] = {}  # english -> {sport: {what}}
    for sport, lib in CATALOGUE.items():
        if only and sport not in only:
            continue
        narrate._COLLECT = {}
        try:
            build(sport, lib)
        finally:
            got = narrate._COLLECT.get(args.locale, {})
            narrate._COLLECT = None
        for en, whats in got.items():
            found.setdefault(en, {}).setdefault(sport, set()).update(whats)

    if args.json:
        print(json.dumps({en: {args.locale: ""} for en in sorted(found)},
                         ensure_ascii=False, indent=2))
    else:
        for en in sorted(found):
            where = "; ".join(f"{s}: {', '.join(sorted(w))}"
                              for s, w in sorted(found[en].items()))
            print(f"[{where}] {en}")
        print(f"{len(found)} sentence(s) missing {args.locale}", file=sys.stderr)
    return 1 if found else 0


if __name__ == "__main__":
    raise SystemExit(main())
