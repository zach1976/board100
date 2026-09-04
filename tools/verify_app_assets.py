#!/usr/bin/env python3
"""Check every app's committed icon and splash against its own artwork.

This is the check that would have caught the hub shipping footvolley's icon:
before 2026-09 the native icons were regenerated on every build from whatever
`assets/icon/app_icon.png` happened to be at the time, so what sat in the repo
was nobody's identity in particular. Now each app owns its artwork and its
generated natives are committed — which is only safe if they actually agree.

For every app in tools/sports.tsv it verifies:

  1. assets/icon/app_icon.png and splash_logo.png exist;
  2. the committed iOS / Android / macOS icons are that source, resized;
  3. the committed iOS / Android splash images are that splash source;
  4. no two apps share the same artwork (a copy-paste mixing up two sports
     is otherwise invisible — both apps look "fine" on their own);
  5. the splash source's shape suits the fill mode the app asks for. A
     near-square image with ios_content_mode: scaleAspectFill gets most of
     itself cropped away on a phone — footvolley shipped like that.

    python3 tools/verify_app_assets.py            # all apps
    python3 tools/verify_app_assets.py soccer     # one app
"""
import sys
from pathlib import Path

from PIL import Image, ImageChops

from apps import APPS, KEYS, app_dir, icon_source, splash_source

# Mean per-pixel difference (0-255) at 64x64 that still counts as "same image".
# Rescaling and PNG quantisation move a few levels; different artwork moves
# tens of levels — measured spread on this repo is <2 vs >60.
TOLERANCE = 6.0

# (label, path relative to the app dir, source kind)
ICON_TARGETS = [
    ("ios icon", "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"),
    ("android icon", "android/app/src/main/res/mipmap-xxxhdpi/launcher_icon.png"),
    ("macos icon", "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png"),
]
SPLASH_TARGETS = [
    ("ios splash", "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png"),
    ("android splash", "android/app/src/main/res/drawable-xxhdpi/splash.png"),
]


def signature(path: Path) -> Image.Image:
    return Image.open(path).convert("RGB").resize((64, 64))


def difference(a: Path, b: Path) -> float:
    diff = ImageChops.difference(signature(a), signature(b)).convert("L")
    pixels = list(diff.getdata())
    return sum(pixels) / len(pixels)


def splash_shape_problem(key: str) -> str | None:
    """A wide/square splash under a fill mode loses most of its content."""
    pubspec = (app_dir(key) / "pubspec.yaml").read_text(encoding="utf-8")
    fills = "ios_content_mode: scaleAspectFill" in pubspec
    w, h = Image.open(splash_source(key)).size
    aspect = w / h
    # Phones are ~0.46 wide:tall. Anything squarer than 0.7 has nothing to
    # spare once it is scaled to cover the screen.
    if fills and aspect > 0.7:
        return (f"splash art is {w}x{h} (aspect {aspect:.2f}) but the app asks "
                f"for scaleAspectFill — most of it will be cropped")
    return None


def check(key: str) -> list[str]:
    problems = []
    root = app_dir(key)
    for label, source in (("icon", icon_source(key)), ("splash", splash_source(key))):
        if not source.exists():
            problems.append(f"missing {label} source {source.relative_to(root.parent)}")
    if problems:
        return problems

    for label, rel in ICON_TARGETS:
        target = root / rel
        if not target.exists():
            problems.append(f"{label}: not committed ({rel})")
            continue
        d = difference(target, icon_source(key))
        if d > TOLERANCE:
            problems.append(f"{label}: differs from this app's app_icon.png (diff {d:.1f})")

    for label, rel in SPLASH_TARGETS:
        target = root / rel
        if not target.exists():
            problems.append(f"{label}: not committed ({rel})")
            continue
        d = difference(target, splash_source(key))
        if d > TOLERANCE:
            problems.append(f"{label}: differs from this app's splash_logo.png (diff {d:.1f})")

    shape = splash_shape_problem(key)
    if shape:
        problems.append(shape)
    return problems


def main(argv: list[str]) -> int:
    keys = argv or KEYS
    unknown = [k for k in keys if k not in APPS]
    if unknown:
        sys.exit(f"unknown app(s): {', '.join(unknown)}")

    print(f"Checking icon + splash for {len(keys)} app(s)\n")
    print(f"{'app':16}{'dir':20}status")
    print("-" * 78)
    failures = []
    for key in keys:
        problems = check(key)
        status = "OK" if not problems else "; ".join(problems)
        print(f"{key:16}{APPS[key]['dir']:20}{status}")
        failures += [f"{key}: {p}" for p in problems]

    # Two apps sharing artwork means one of them is wearing the other's face.
    print()
    seen = {}
    for key in keys:
        src = icon_source(key)
        if not src.exists():
            continue
        for other, other_src in seen.items():
            if difference(src, other_src) <= TOLERANCE:
                failures.append(f"{key}: shares its icon artwork with {other}")
                print(f"⚠️  {key} and {other} have the same icon")
        seen[key] = src

    if failures:
        print(f"\n❌ {len(failures)} problem(s):")
        for f in failures:
            print(f"   - {f}")
        return 1
    print(f"✅ {len(keys)} apps: icon and splash match their own artwork, all distinct")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
