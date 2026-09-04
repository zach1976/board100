#!/usr/bin/env python3
"""Turn a generated image into an app's splash source at the exact canvas.

Image models hand back 1024x1536, 1024x1792, 2:3, 9:16 — never 853x1844. This
centre-crops to the shipped aspect and resizes, so what lands in the repo is
the same shape as the other fifteen apps and `scaleAspectFill` has nothing to
throw away.

    python3 tools/make_splash.py ~/Downloads/render.png footvolley
    python3 tools/make_splash.py render.png footvolley --dry-run
    python3 tools/make_splash.py render.png footvolley --anchor 0.35

--anchor moves the crop window vertically (0 = keep the top, 1 = keep the
bottom, default 0.5). Useful when the model puts the hero low and a centred
crop would cut the light source off.
"""
import argparse
import sys

from PIL import Image

from apps import APPS, splash_source

WIDTH, HEIGHT = 853, 1844          # what the shipped 15 use
ASPECT = WIDTH / HEIGHT


def fit(img: Image.Image, anchor: float) -> Image.Image:
    w, h = img.size
    if w / h > ASPECT:                       # too wide: trim the sides
        new_w = round(h * ASPECT)
        left = round((w - new_w) / 2)
        box = (left, 0, left + new_w, h)
    else:                                    # too tall: trim top/bottom
        new_h = round(w / ASPECT)
        top = round((h - new_h) * anchor)
        box = (0, top, w, top + new_h)
    return img.crop(box).resize((WIDTH, HEIGHT), Image.LANCZOS)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("image", help="the generated file")
    ap.add_argument("app", help="app key from tools/sports.tsv, e.g. footvolley")
    ap.add_argument("--anchor", type=float, default=0.5,
                    help="vertical crop anchor, 0=top .. 1=bottom (default 0.5)")
    ap.add_argument("--dry-run", action="store_true",
                    help="write /tmp/<app>_splash_preview.png instead of the repo")
    args = ap.parse_args()

    if args.app not in APPS:
        sys.exit(f"unknown app '{args.app}' — keys: {', '.join(APPS)}")
    if not 0.0 <= args.anchor <= 1.0:
        sys.exit("--anchor must be between 0 and 1")

    src = Image.open(args.image).convert("RGB")
    out = fit(src, args.anchor)
    dest = (f"/tmp/{args.app}_splash_preview.png" if args.dry_run
            else str(splash_source(args.app)))
    out.save(dest)

    kept = "sides trimmed" if src.width / src.height > ASPECT else "top/bottom trimmed"
    print(f"{args.image}  {src.width}x{src.height} ({src.width/src.height:.3f})")
    print(f"  -> {dest}  {WIDTH}x{HEIGHT} ({ASPECT:.3f}), {kept}")
    if not args.dry_run:
        print(f"\nNext:  cd {APPS[args.app]['dir']} && dart run flutter_native_splash:create")
        print(f"       python3 tools/verify_app_assets.py {args.app}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
