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

FONT_CANDIDATES = [
    "/System/Library/Fonts/HelveticaNeue.ttc",
    "/System/Library/Fonts/Helvetica.ttc",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/System/Library/Fonts/Geneva.ttf",
]


def load_font(size: int) -> ImageFont.ImageFont:
    """Best-effort bold sans-serif lookup. Falls back to Pillow default."""
    for p in FONT_CANDIDATES:
        if Path(p).exists():
            try:
                # .ttc files need an index; HelveticaNeue.ttc index 7 = Bold on macOS.
                return ImageFont.truetype(p, size=size, index=7 if p.endswith(".ttc") else 0)
            except Exception:
                try:
                    return ImageFont.truetype(p, size=size)
                except Exception:
                    continue
    return ImageFont.load_default()


def parse_captions(md_path: Path) -> dict[str, list[str]]:
    """
    Parse SCREENSHOT_CAPTIONS.md → {sku: [c1, c2, ..., c6]}.
    The file has '## <sku>' headers followed by a 6-row table.
    """
    text = md_path.read_text(encoding="utf-8")
    out: dict[str, list[str]] = {}
    current_sku: str | None = None
    for line in text.splitlines():
        h = re.match(r"^##\s+([A-Za-z_]+)\b", line)
        if h:
            tok = h.group(1).strip()
            # Skip non-SKU section headers like "Localization plan" or "Universal".
            if tok in {"tactics_board", "soccer", "basketball", "volleyball", "badminton",
                       "tennis", "tableTennis", "pickleball", "baseball", "handball",
                       "rugby", "fieldHockey", "waterPolo", "sepakTakraw", "beachTennis",
                       "footvolley"}:
                current_sku = tok
                out[current_sku] = []
            else:
                current_sku = None
            continue
        if current_sku is None:
            continue
        row = re.match(r"^\|\s*(\d+)\s*\|\s*(.+?)\s*\|\s*$", line)
        if row:
            idx = int(row.group(1))
            cap = row.group(2).strip()
            # idx is 1-6; append in order. We rely on the table being in order.
            if 1 <= idx <= 6:
                out[current_sku].append(cap)
    # Sanity: every SKU should have exactly 6 captions.
    for sku, caps in out.items():
        if len(caps) != 6:
            print(f"⚠️  {sku}: parsed {len(caps)} captions (expected 6)", file=sys.stderr)
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


def compose(src_png: Path, caption: str, out_png: Path) -> None:
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
        font = load_font(size)
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

    captions = parse_captions(CAPTIONS_MD)
    if not captions:
        print("❌ no captions parsed from", CAPTIONS_MD, file=sys.stderr)
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
            print(f"⚠️  {sku} not in captions; skip"); skipped += 1; continue
        for idx, cap in enumerate(captions[sku], start=1):
            src = find_source(sku, args.locale, idx)
            if src is None:
                print(f"⚠️  {sku}/{args.locale}/s{idx} raw missing; skip")
                missing += 1
                continue
            out_path = out_root / sku / args.locale / f"s{idx}_captioned.png" if not args.in_place else src
            compose(src, cap, out_path)
            print(f"  ✓ {sku}/{args.locale}/s{idx}: {cap[:50]}{'…' if len(cap) > 50 else ''}")
            done += 1

    print(f"\ndone: {done} composed, {missing} raw missing, {skipped} skus skipped")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
