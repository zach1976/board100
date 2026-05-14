#!/usr/bin/env python3
"""
aso_caption_overlay.py — bake EN captions into existing App Store screenshots.

Reads captions from aso/SCREENSHOT_CAPTIONS.md (16 SKU × 6 shots = 96 EN strings)
and overlays them on the raw localized PNGs in aso/screenshots_localized/<sku>/en-US/.

Output canvas: 1290 × 2796 (App Store iPhone 6.7" required size).
Layout:        top 720px  = #0D0D1A bg + caption text (white bold)
               bottom 2076px = source screenshot scaled to fit, centered.

Usage:
    # one-off (one SKU):
    python3 tool/aso_caption_overlay.py --sku soccer --locale en-US --out aso/screenshots_captioned

    # full batch:
    python3 tool/aso_caption_overlay.py --all --out aso/screenshots_captioned

    # in-place (overwrites screenshots_localized/<sku>/<locale>/<n>.png):
    python3 tool/aso_caption_overlay.py --all --in-place
"""

import argparse
import re
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parent.parent
CAPTIONS_MD = REPO_ROOT / "aso" / "SCREENSHOT_CAPTIONS.md"
SRC_DIR = REPO_ROOT / "aso" / "screenshots_localized"

CANVAS_W, CANVAS_H = 1290, 2796
CAPTION_BAND_H = 720
BG_HEX = (0x0D, 0x0D, 0x1A, 255)
TEXT_HEX = (255, 255, 255, 255)
ACCENT_HEX = (0xFF, 0xD6, 0x00, 255)

# Filename suffix for each shot index (matches integration_test/appstore_screenshots.dart).
# tactics_board uses different s1 name; others use s1_empty / s2_formation / ...
SHOT_SUFFIX = {
    1: ["s1_sport_selection", "s1_empty"],
    2: ["s2_formation"],
    3: ["s3_drawing"],
    4: ["s4_moves"],
    5: ["s5_timeline"],
    6: ["s6_playback"],
}

# Latin / fallback fonts (no CJK glyphs).
FONT_CANDIDATES_LATIN = [
    ("/System/Library/Fonts/HelveticaNeue.ttc", 7),  # index 7 = Bold on macOS
    ("/System/Library/Fonts/Helvetica.ttc", 0),
    ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 0),
]

# Per-locale font preferences (first hit wins). Each entry is (path, ttc-index).
LOCALE_FONTS = {
    "zh-Hans": [("/System/Library/Fonts/Hiragino Sans GB.ttc", 1),
                ("/System/Library/Fonts/STHeiti Medium.ttc", 0)],
    "zh-Hant": [("/System/Library/Fonts/Hiragino Sans GB.ttc", 1),
                ("/System/Library/Fonts/STHeiti Medium.ttc", 0)],
    "ja":      [("/System/Library/Fonts/Hiragino Sans GB.ttc", 1),
                ("/System/Library/Fonts/AppleSDGothicNeo.ttc", 2)],
    "ko":      [("/System/Library/Fonts/AppleSDGothicNeo.ttc", 2)],
    "th":      [("/System/Library/Fonts/ThonburiUI.ttc", 1),
                ("/System/Library/Fonts/Thonburi.ttc", 1)],
}


def load_font(size: int, locale: str = "en-US") -> ImageFont.ImageFont:
    """Locale-aware bold sans-serif lookup. Falls back to Helvetica then Pillow default."""
    candidates = LOCALE_FONTS.get(locale, []) + FONT_CANDIDATES_LATIN
    for path, idx in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size=size, index=idx)
            except Exception:
                try:
                    return ImageFont.truetype(path, size=size)
                except Exception:
                    continue
    return ImageFont.load_default()


SKU_NAMES = {"tactics_board", "soccer", "basketball", "volleyball", "badminton",
             "tennis", "tableTennis", "pickleball", "baseball", "handball",
             "rugby", "fieldHockey", "waterPolo", "sepakTakraw", "beachTennis",
             "footvolley"}


def parse_captions(md_path: Path) -> dict[tuple[str, str], list[str]]:
    """
    Parse SCREENSHOT_CAPTIONS.md → {(locale, sku): [c1, ..., c6]}.

    Format:
      `# Locale: <code>`  switches the current locale namespace (default en-US).
      `## <sku>`          starts a new SKU section.
      6-row markdown table with `| N | caption |` rows provides the captions.
    """
    text = md_path.read_text(encoding="utf-8")
    out: dict[tuple[str, str], list[str]] = {}
    locale = "en-US"
    sku: str | None = None
    for line in text.splitlines():
        loc_h = re.match(r"^#\s+Locale:\s*([\w-]+)\s*$", line)
        if loc_h:
            locale = loc_h.group(1).strip()
            sku = None
            continue
        sku_h = re.match(r"^##\s+([A-Za-z_]+)\b", line)
        if sku_h:
            tok = sku_h.group(1).strip()
            if tok in SKU_NAMES:
                sku = tok
                out.setdefault((locale, sku), [])
            else:
                sku = None
            continue
        if sku is None:
            continue
        row = re.match(r"^\|\s*(\d+)\s*\|\s*(.+?)\s*\|\s*$", line)
        if row:
            idx = int(row.group(1))
            cap = row.group(2).strip()
            if 1 <= idx <= 6:
                out[(locale, sku)].append(cap)
    for (loc, s), caps in out.items():
        if len(caps) != 6:
            print(f"⚠️  [{loc}][{s}] parsed {len(caps)} captions (expected 6)", file=sys.stderr)
    return out


def wrap_caption(draw: ImageDraw.ImageDraw, text: str, font, max_w: int) -> list[str]:
    """Word-wrap so each line fits within max_w pixels."""
    words = text.split()
    lines, cur = [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        bbox = draw.textbbox((0, 0), trial, font=font)
        if bbox[2] - bbox[0] <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def compose(src_png: Path, caption: str, out_png: Path, locale: str = "en-US") -> None:
    """Compose final 1290×2796 captioned screenshot."""
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), BG_HEX)

    # Lower band: scale source to fit (1290 × 2076), preserve aspect.
    src = Image.open(src_png).convert("RGBA")
    panel_w, panel_h = CANVAS_W, CANVAS_H - CAPTION_BAND_H
    sw, sh = src.size
    scale = min(panel_w / sw, panel_h / sh)
    new_w, new_h = int(sw * scale), int(sh * scale)
    src_scaled = src.resize((new_w, new_h), Image.LANCZOS)
    off_x = (panel_w - new_w) // 2
    off_y = CAPTION_BAND_H + (panel_h - new_h) // 2
    canvas.paste(src_scaled, (off_x, off_y), src_scaled)

    # Upper band: caption text, word-wrapped, centered.
    draw = ImageDraw.Draw(canvas)
    # Try a few font sizes; shrink until ≤2 lines fit.
    font = None
    lines: list[str] = []
    for size in (92, 84, 76, 68, 60):
        font = load_font(size, locale)
        lines = wrap_caption(draw, caption, font, CANVAS_W - 160)
        if len(lines) <= 2:
            break
    # Render lines centered vertically in the band.
    line_h = (font.getbbox("Ay")[3] - font.getbbox("Ay")[1]) + 16
    total_h = line_h * len(lines)
    y = (CAPTION_BAND_H - total_h) // 2
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        w = bbox[2] - bbox[0]
        x = (CANVAS_W - w) // 2
        draw.text((x, y), line, fill=TEXT_HEX, font=font)
        y += line_h

    out_png.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out_png, format="PNG", optimize=True)


def find_source(sku: str, locale: str, shot_idx: int) -> Path | None:
    """Locate the raw PNG for (sku, locale, shot_idx). Returns None if missing."""
    base = SRC_DIR / sku / locale
    for suffix in SHOT_SUFFIX[shot_idx]:
        candidate = base / f"{suffix}.png"
        if candidate.exists():
            return candidate
    return None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--sku", help="Single SKU to process (e.g., soccer)")
    ap.add_argument("--locale", default="en-US", help="Locale (default en-US)")
    ap.add_argument("--all", action="store_true", help="Process all 16 SKUs")
    ap.add_argument("--out", default=str(REPO_ROOT / "aso" / "screenshots_captioned"),
                    help="Output dir root (default aso/screenshots_captioned)")
    ap.add_argument("--in-place", action="store_true",
                    help="Overwrite screenshots_localized/<sku>/<locale>/*.png in place")
    args = ap.parse_args()

    all_captions = parse_captions(CAPTIONS_MD)
    if not all_captions:
        print("❌ no captions parsed from", CAPTIONS_MD, file=sys.stderr)
        return 1

    # Subset captions to the chosen locale.
    locale = args.locale
    captions = {sku: caps for (loc, sku), caps in all_captions.items() if loc == locale}
    if not captions:
        print(f"❌ no captions for locale '{locale}' in {CAPTIONS_MD.name}", file=sys.stderr)
        print(f"   available locales: {sorted({loc for (loc, _) in all_captions})}", file=sys.stderr)
        return 1

    if args.all:
        skus = list(captions.keys())
    elif args.sku:
        skus = [args.sku]
    else:
        ap.print_help()
        return 1

    out_root = SRC_DIR if args.in_place else Path(args.out)
    done = skipped = missing = 0
    for sku in skus:
        if sku not in captions:
            print(f"⚠️  {sku} not in captions[{locale}]; skip"); skipped += 1; continue
        for idx, cap in enumerate(captions[sku], start=1):
            src = find_source(sku, locale, idx)
            if src is None:
                print(f"⚠️  {sku}/{locale}/s{idx} raw missing; skip")
                missing += 1
                continue
            out_path = out_root / sku / locale / f"s{idx}_captioned.png" if not args.in_place else src
            compose(src, cap, out_path, locale)
            print(f"  ✓ {sku}/{locale}/s{idx}: {cap[:50]}{'…' if len(cap) > 50 else ''}")
            done += 1

    print(f"\ndone: {done} composed, {missing} raw missing, {skipped} skus skipped")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
