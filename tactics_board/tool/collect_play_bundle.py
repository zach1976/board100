#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Collect each app's Google Play upload artifacts into one folder per app.

For every app it gathers, flat into build/play_bundles/<sport>/:
  - icon.png, featureGraphic.png            (from fastlane/play/<sport>/.../en-US/images/)
  - screenshot_1.png … screenshot_N.png     (the phoneScreenshots, renamed)
  - <sport>-<version>.aab                    (from build/aab_play/, if built)

Re-runnable: clears and rebuilds each target folder. Apps without a built AAB
get the images only (a note is printed).

Usage:
  python3 tool/collect_play_bundle.py            # all apps with Play metadata
  python3 tool/collect_play_bundle.py tactics_board tennis
"""
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAY = os.path.join(ROOT, "fastlane", "play")
AAB_DIR = os.path.join(ROOT, "build", "aab_play")
OUT = os.path.join(ROOT, "build", "play_bundles")


def collect(sport):
    imgdir = os.path.join(PLAY, sport, "metadata", "android", "en-US", "images")
    if not os.path.isdir(imgdir):
        print(f"  ✗ {sport}: no Play images, skipped")
        return
    dest = os.path.join(OUT, sport)
    if os.path.isdir(dest):
        shutil.rmtree(dest)
    os.makedirs(dest)

    n_img = 0
    for fname in ("icon.png", "featureGraphic.png"):
        src = os.path.join(imgdir, fname)
        if os.path.exists(src):
            shutil.copy2(src, os.path.join(dest, fname))
            n_img += 1
    ssdir = os.path.join(imgdir, "phoneScreenshots")
    if os.path.isdir(ssdir):
        for i, fn in enumerate(sorted(f for f in os.listdir(ssdir) if f.endswith(".png")), 1):
            shutil.copy2(os.path.join(ssdir, fn), os.path.join(dest, f"screenshot_{i}.png"))
            n_img += 1

    aabs = [f for f in os.listdir(AAB_DIR)] if os.path.isdir(AAB_DIR) else []
    aab = next((f for f in aabs if f.startswith(f"{sport}-") and f.endswith(".aab")), None)
    if aab:
        shutil.copy2(os.path.join(AAB_DIR, aab), os.path.join(dest, aab))
        print(f"  ✓ {sport}: {n_img} images + {aab}")
    else:
        print(f"  ✓ {sport}: {n_img} images  (no AAB yet — run build_sport_android.sh {sport})")


def main():
    args = sys.argv[1:]
    sports = args or sorted(
        d for d in os.listdir(PLAY)
        if os.path.isdir(os.path.join(PLAY, d)) and not d.endswith(".md")
    )
    os.makedirs(OUT, exist_ok=True)
    print(f"Collecting into {OUT}\n")
    for s in sports:
        collect(s)
    print(f"\nDone → {OUT}")


if __name__ == "__main__":
    main()
