#!/usr/bin/env python3
"""Render the store screenshots at iPad size.

Same design, same captions, same code — aso_design_compositor with its canvas
swapped, which is what tool/play_v2_screenshots.py already does for Google
Play. Three things have to move with the canvas:

  * W/H — 2064x2752, the 13-inch iPad's own resolution, which is one of the
    sizes App Store Connect accepts for that class.
  * The type. Every size in the compositor is an absolute number tuned for a
    1290-wide canvas; on a 2064-wide one the headline reads as a caption.
    They scale by the width ratio.
  * The bezel and the corner radii, for the same reason.

The device drawing needs no other help: it derives its width from the
screenshot's own aspect, so a 4:3 tablet shot produces a tablet-shaped frame
without being told.

Raw shots come from a capture run against an iPad simulator, into
aso/screenshots_v2_raw_ipad/ — the phone set must not be overwritten.

    python3 tool/ipad_screenshots.py soccer
    python3 tool/ipad_screenshots.py soccer en-US
"""
import sys
from pathlib import Path

import aso_design_compositor as C

IPAD_W, IPAD_H = 2064, 2752
SCALE = IPAD_W / C.W                      # 1.6

REPO = Path(__file__).resolve().parent.parent
RAW = REPO / "aso" / "screenshots_v2_raw_ipad"
OUT = REPO / "fastlane" / "screenshots_ipad"


def retune():
    """Point the compositor at the tablet canvas and scale what is absolute."""
    C.V2RAW = RAW
    C.W, C.H = IPAD_W, IPAD_H

    # ── type ─────────────────────────────────────────────────────────────
    src_headline = C.draw_headline

    def draw_headline(img, locale, white_word, green_words, subtitle):
        fit = C._fit_font

        def scaled(table, loc, text, max_w, start, tracking, lo=70):
            return fit(table, loc, text, max_w,
                       int(start * SCALE), tracking, int(lo * SCALE))

        C._fit_font = scaled
        try:
            src_headline(img, locale, white_word, green_words, subtitle)
        finally:
            C._fit_font = fit

    C.draw_headline = draw_headline

    # ── the badge pill ───────────────────────────────────────────────────
    src_font = C.font
    C.font = lambda idx, size: src_font(idx, int(size * SCALE))
    src_badge = C.draw_badge

    def draw_badge(img, glyph_img, label):
        return src_badge(img, glyph_img, label)

    C.draw_badge = draw_badge


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    sport = args[0]
    retune()
    caps = C.load_captions()
    locales = args[1:] or list(caps.get(sport, {}))
    total = 0
    for loc in locales:
        if not (RAW / sport / loc).is_dir():
            print(f"⚠️  没有 iPad 原图: {sport}/{loc}")
            continue
        total += C.render_sport_locale(caps, sport, loc, OUT)
    print(f"\n{total} 张 → {OUT / sport}")


if __name__ == "__main__":
    main()
