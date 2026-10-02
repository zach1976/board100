#!/usr/bin/env python3
"""Compose one app's store screenshots and put them where the uploader reads.

The compositor writes to tactics_board/fastlane/screenshots/<sport>/<locale>/,
which nothing uploads from: release_app.py's `shots` step reads each shell's
own fastlane/screenshots/<locale>/ through tools/apps.py. That gap is why a
documented `--all` rerun refreshed nothing. This script runs both compositors
and copies the phone set across, so "composed" and "about to be uploaded"
cannot drift apart again.

    python3 tools/make_store_shots.py soccer           # one app
    python3 tools/make_store_shots.py all              # all 16
    python3 tools/make_store_shots.py all --phone      # skip the iPad set

The iPad set needs no copy — release_app.py's `ipad` step already reads
tactics_board/fastlane/screenshots_ipad/<key>/.
"""
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
CORE = REPO / "tactics_board"
sys.path.insert(0, str(REPO / "tools"))
from apps import APPS, screenshots_dir  # noqa: E402

PHONE_OUT = CORE / "fastlane" / "screenshots"
IPAD_OUT = CORE / "fastlane" / "screenshots_ipad"
RAW = CORE / "aso" / "screenshots_v2_raw"
RAW_IPAD = CORE / "aso" / "screenshots_v2_raw_ipad"


def locales_with_raw(key: str, root: Path) -> list:
    # The hub has no raws of its own — the compositor builds its set out of
    # FLAGSHIP_SPORTS, so ask one of those which locales exist.
    probe = "soccer" if key == "tactics_board" else key
    d = root / probe
    return sorted(p.name for p in d.iterdir() if p.is_dir()) if d.is_dir() else []


def run(cmd: list) -> bool:
    r = subprocess.run(cmd, cwd=CORE, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"   ✗ {' '.join(cmd[-3:])}\n{r.stdout[-600:]}{r.stderr[-600:]}")
    return r.returncode == 0


def do_app(key: str, phone: bool, ipad: bool) -> None:
    print(f"══ {key}")
    if phone:
        locs = locales_with_raw(key, RAW)
        for loc in locs:
            run(["python3", "tool/aso_design_compositor.py",
                 "--sport", key, "--locale", loc])
        n = 0
        for loc in locs:
            src = PHONE_OUT / key / loc
            if not src.is_dir():
                continue
            dst = screenshots_dir(key) / loc
            dst.mkdir(parents=True, exist_ok=True)
            # Replace this app's set wholesale: a release that drops a scene
            # must not leave the old one behind for the uploader to find.
            for old in dst.glob(f"[0-9][0-9]_{key}_s*.png"):
                old.unlink()
            for f in sorted(src.glob("*.png")):
                if f.name.startswith("ipad"):
                    continue
                shutil.copy2(f, dst / f.name)
                n += 1
        print(f"   phone: {n} → {screenshots_dir(key)}")
    if ipad:
        if not (RAW_IPAD / ("soccer" if key == "tactics_board" else key)).is_dir():
            print("   ipad:  no raws, skipped")
            return
        run(["python3", "tool/ipad_screenshots.py", key])
        n = sum(1 for _ in (IPAD_OUT / key).rglob("*.png")) if (IPAD_OUT / key).is_dir() else 0
        print(f"   ipad:  {n} → {IPAD_OUT / key}")


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = {a for a in sys.argv[1:] if a.startswith("--")}
    if not args:
        sys.exit(__doc__)
    phone = "--ipad" not in flags
    ipad = "--phone" not in flags
    keys = list(APPS) if args[0] == "all" else args
    for key in keys:
        if key not in APPS:
            print(f"✗ unknown app {key!r}")
            return 1
        do_app(key, phone, ipad)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
