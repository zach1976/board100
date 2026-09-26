#!/usr/bin/env python3
"""play_v2_screenshots.py — render the v2 "PLAN EVERY RALLY" design at Google
Play phone size and drop it into each sport's Play listing.

Reuses tool/aso_design_compositor.py unchanged: it only monkeypatches the
canvas size (W/H) so the same proportional layout renders at Play's 1440x2868
(<= 2:1 aspect; the App Store's 1290x2796 is taller than 2:1 and Play rejects
it). The phone screenshot itself is aspect-locked, so widening the canvas just
widens the navy margin — no distortion.

Usage:
    python3 tool/play_v2_screenshots.py basketball soccer volleyball badminton
    python3 tool/play_v2_screenshots.py --all     # every sport with Play dir
"""
import sys
import shutil
import tempfile
from pathlib import Path

import aso_design_compositor as C

# Google Play phone screenshot size (within the 2:1 max aspect ratio).
PLAY_W, PLAY_H = 1440, 2868

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO.parent / "tools"))
from apps import APPS, play_metadata_dir  # noqa: E402


def play_dir(sport):
    # Per-app since 2026-09: SoccerBoard/fastlane/play/..., not a folder per
    # sport under the core. tools/apps.py is the one place that mapping lives.
    return Path(play_metadata_dir(sport)) / "en-US" / "images" / "phoneScreenshots"


def render_one(sport, tmpbase):
    """Render the 6 en-US shots for one sport into the sport's Play listing."""
    caps = C.load_captions()
    dst = play_dir(sport)
    if not dst.exists():
        print(f"⚠️  no Play listing dir for {sport} ({dst}) — skipped")
        return False
    # How many is the caption list's answer, same as the compositor: soccer
    # is five since the scene order was reworked, the others still six.
    want = len(caps.get(sport, {}).get("en-US", []))
    n = C.render_sport_locale(caps, sport, "en-US", tmpbase)
    if n != want:
        print(f"⚠️  {sport}: rendered {n}/{want} — skipped (incomplete)")
        return False
    rendered = sorted((Path(tmpbase) / sport / "en-US").glob("*.png"))
    if len(rendered) != want:
        print(f"⚠️  {sport}: expected {want} output files, got {len(rendered)} — skipped")
        return False
    # A shorter set must not leave the old sixth shot behind.
    for stale in dst.glob("*.png"):
        stale.unlink()
    for i, src in enumerate(rendered, start=1):
        shutil.copyfile(src, dst / f"{i}.png")
    print(f"✅ {sport}: {want} Play screenshots → {dst}")
    return True


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit("usage: play_v2_screenshots.py <sport...> | --all")

    if args == ["--all"]:
        sports = sorted(k for k in APPS if play_dir(k).exists())
    else:
        sports = args

    # Switch the shared compositor onto the Play canvas.
    C.W, C.H = PLAY_W, PLAY_H

    ok = 0
    with tempfile.TemporaryDirectory() as tmp:
        for sport in sports:
            if render_one(sport, tmp):
                ok += 1
    print(f"\nDONE: {ok}/{len(sports)} sports updated at {PLAY_W}x{PLAY_H}")


if __name__ == "__main__":
    main()
