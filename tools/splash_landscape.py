#!/usr/bin/env python3
"""A landscape launch image for every shell, so the subject survives the turn.

The launch screen is the portrait splash, aspect-filled. Turned sideways a
phone shows the middle 39–61% of it and an iPad the middle 32–68%, and the
ball — the whole point of the picture — sits at 62%. It was simply not on
screen. iOS picks a launch image by size class, so each shell gets a second
one: a wide band of the same picture, centred on the subject, used when the
height is compact (a phone on its side) or the width is regular (an iPad,
either way up — an iPad upright crops the band's sides and keeps the ball,
which beats cropping the ball).

    python3 tools/splash_landscape.py            # all 16 shells
    python3 tools/splash_landscape.py soccer     # one

A shell that has a real landscape picture at assets/icon/splash_logo_landscape.png
uses that instead of the baked band. tools/gen_sport_shell.sh runs this after
flutter_native_splash, so a regenerated shell keeps it.
"""
import json
import pathlib
import sys

from PIL import Image

REPO = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from apps import APPS, app_dir  # noqa: E402

# Where the subject sits in the portrait splash, as a fraction of its height.
# Measured on the soccer ball (0.62) and the same for every sport: the
# prompt that made them put the ball in the lower middle.
SUBJECT_Y = 0.62
# The band's shape: a phone on its side. Wider than any iPad, so an iPad
# crops the sides and nothing else.
BAND = 2.17


def band_from(portrait: Image.Image) -> Image.Image:
    w, h = portrait.size
    bh = round(w / BAND)
    top = round(SUBJECT_Y * h - bh / 2)
    top = max(0, min(h - bh, top))
    return portrait.crop((0, top, w, top + bh))


def install(key: str, app_dir: pathlib.Path) -> str:
    icon = app_dir / "assets" / "icon"
    real = icon / "splash_logo_landscape.png"
    src = Image.open(real if real.exists() else icon / "splash_logo.png").convert("RGB")
    land = src if real.exists() else band_from(src)
    imageset = app_dir / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    if not imageset.is_dir():
        return f"{key}: no LaunchImage.imageset, skipped"
    # The full picture at 3x and it shrunk for the other two: actool stores
    # every entry separately, and the first soccer build carried nine copies
    # of the full 1844-wide file — 16MB of a 17.8MB catalog — for screens
    # that would have scaled it down anyway.
    for scale in (1, 2, 3):
        w = round(land.width * scale / 3)
        img = land if scale == 3 else land.resize(
            (w, round(land.height * w / land.width)), Image.LANCZOS)
        img.save(imageset / f"LaunchImage-landscape@{scale}x.png", optimize=True)
    contents = json.loads((imageset / "Contents.json").read_text())
    kept = [i for i in contents["images"]
            if not str(i.get("filename", "")).startswith("LaunchImage-landscape")]
    # Three trait sets, not two: a Max-sized phone on its side is BOTH
    # compact in height and regular in width, and with only those two entries
    # actool calls the pair ambiguous. The explicit (regular, compact) entry is
    # the most specific match there and ends the argument.
    for scale in (1, 2, 3):
        for trait in ({"height-class": "compact"}, {"width-class": "regular"},
                      {"width-class": "regular", "height-class": "compact"}):
            kept.append({"filename": f"LaunchImage-landscape@{scale}x.png",
                         "idiom": "universal", "scale": f"{scale}x", **trait})
    contents["images"] = kept
    (imageset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    return f"{key}: {'own art' if real.exists() else 'baked band'} {land.size}"


def main() -> int:
    keys = sys.argv[1:] or list(APPS)
    for key in keys:
        print(install(key, pathlib.Path(app_dir(key))))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
