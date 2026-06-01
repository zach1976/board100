#!/usr/bin/env python3
"""Generate Google Play store graphics for the single-sport apps.

Outputs into fastlane/play/<sport>/metadata/android/en-US/images/:
  - icon.png             512x512   (Play app icon)
  - featureGraphic.png   1024x500  (Play feature graphic)
  - phoneScreenshots/1..6.png      (captioned screenshots padded to <=2:1)

Usage:
  python3 tool/gen_play_assets.py basketball
  python3 tool/gen_play_assets.py all
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON_DIR = os.path.join(ROOT, "assets", "icon")
SS_DIR = os.path.join(ROOT, "fastlane", "screenshots")
PLAY_DIR = os.path.join(ROOT, "fastlane", "play")

FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_REG = "/System/Library/Fonts/Supplemental/Arial.ttf"

# sport -> (display name, tagline)
SPORTS = {
    "basketball": ("Basketball Board", "Draw It. Run It. Score."),
    "soccer": ("Soccer Board", "Draw a Play. Watch It Run."),
    "volleyball": ("Volleyball Board", "Rotations, Demystified."),
    "badminton": ("Badminton Board", "Win Doubles Without Words."),
    "baseball": ("Baseball Board", "Set the Defense. Run the Bases."),
    "beachTennis": ("Beach Tennis Board", "Own the Sand."),
    "fieldHockey": ("Field Hockey Board", "Corners, Drilled."),
    "footvolley": ("Footvolley Board", "Sand. Skill. Strategy."),
    "handball": ("Handball Board", "Attack. Defend. Break."),
    "pickleball": ("Pickleball Board", "Master the Kitchen."),
    "rugby": ("Rugby Board", "Lineouts to Tries."),
    "sepakTakraw": ("Sepak Takraw Board", "Serve. Feed. Spike."),
    "tableTennis": ("Table Tennis Board", "Serve. Return. Attack."),
    "tennis": ("Tennis Board", "Plan Every Point."),
    "waterPolo": ("Water Polo Board", "Command the Pool."),
    "tactics_board": ("Tactics Board", "Every Sport. One Board."),
}

# The multi-sport hub has no per-sport asset; it uses the default source PNGs.
def _icon_src(sport):
    name = "app_icon.png" if sport == "tactics_board" else f"{sport}_icon.png"
    return os.path.join(ICON_DIR, name)


def _splash_src(sport):
    name = "splash_logo.png" if sport == "tactics_board" else f"{sport}_splash.png"
    return os.path.join(ICON_DIR, name)


def rounded(img, radius):
    """Apply rounded corners to an RGBA image."""
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.size[0] - 1, img.size[1] - 1], radius=radius, fill=255
    )
    out = img.copy()
    out.putalpha(mask)
    return out


def wrap(draw, text, font, max_w):
    """Greedy word-wrap to a pixel width."""
    words = text.split()
    lines, cur = [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        if draw.textlength(trial, font=font) <= max_w or not cur:
            cur = trial
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def gen_icon(sport, outdir):
    src = Image.open(_icon_src(sport)).convert("RGBA")
    src.resize((512, 512), Image.LANCZOS).save(os.path.join(outdir, "icon.png"))
    print(f"  icon.png            512x512")


def gen_feature(sport, name, tagline, outdir):
    W, H = 1024, 500

    # background: cover-fit the splash artwork, center crop
    splash = Image.open(_splash_src(sport)).convert("RGB")
    sw, sh = splash.size
    scale = max(W / sw, H / sh)
    splash = splash.resize((round(sw * scale), round(sh * scale)), Image.LANCZOS)
    ox = (splash.size[0] - W) // 2
    oy = (splash.size[1] - H) // 2
    bg = splash.crop((ox, oy, ox + W, oy + H))

    # darken for text contrast
    bg = Image.blend(bg, Image.new("RGB", (W, H), (8, 12, 22)), 0.55)
    canvas = bg.convert("RGBA")

    # icon with rounded corners + soft shadow
    isz = 284
    icon = (
        Image.open(_icon_src(sport))
        .convert("RGBA")
        .resize((isz, isz), Image.LANCZOS)
    )
    icon = rounded(icon, int(isz * 0.22))
    ix, iy = 76, (H - isz) // 2
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [ix, iy + 10, ix + isz, iy + isz + 10], radius=int(isz * 0.22), fill=(0, 0, 0, 170)
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(16)))
    canvas.alpha_composite(icon, (ix, iy))

    # text block
    draw = ImageDraw.Draw(canvas)
    tx = ix + isz + 58
    max_w = W - tx - 56

    f_name = ImageFont.truetype(FONT_BOLD, 78)
    f_tag = ImageFont.truetype(FONT_REG, 36)
    name_lines = wrap(draw, name, f_name, max_w)
    tag_lines = wrap(draw, tagline, f_tag, max_w)

    name_lh = 90
    tag_lh = 46
    block_h = len(name_lines) * name_lh + 20 + len(tag_lines) * tag_lh
    y = (H - block_h) // 2

    for ln in name_lines:
        draw.text((tx, y), ln, font=f_name, fill=(255, 255, 255, 255))
        y += name_lh
    # accent rule
    y += 4
    draw.rounded_rectangle([tx, y, tx + 70, y + 7], radius=3, fill=(255, 196, 64, 255))
    y += 22
    for ln in tag_lines:
        draw.text((tx, y), ln, font=f_tag, fill=(214, 220, 232, 255))
        y += tag_lh

    canvas.convert("RGB").save(os.path.join(outdir, "featureGraphic.png"))
    print(f"  featureGraphic.png  {W}x{H}")


def gen_screenshots(sport, outdir):
    srcdir = os.path.join(SS_DIR, sport, "en-US")
    ssdir = os.path.join(outdir, "phoneScreenshots")
    os.makedirs(ssdir, exist_ok=True)
    for old in os.listdir(ssdir):
        os.remove(os.path.join(ssdir, old))
    files = sorted(f for f in os.listdir(srcdir) if f.lower().endswith(".png"))
    for i, fn in enumerate(files, 1):
        im = Image.open(os.path.join(srcdir, fn)).convert("RGB")
        w, h = im.size
        # Play phone screenshot: longer side must be <= 2x the shorter side.
        # These raw screenshots are full-bleed, so pad the width by replicating
        # the edge columns outward — the court/toolbar colours extend seamlessly.
        if h > 2 * w:
            target_w = h // 2 + 6
            if (target_w - w) % 2:
                target_w += 1
            pad = (target_w - w) // 2
            canvas = Image.new("RGB", (target_w, h))
            canvas.paste(im.crop((0, 0, 1, h)).resize((pad, h), Image.NEAREST), (0, 0))
            canvas.paste(im, (pad, 0))
            canvas.paste(im.crop((w - 1, 0, w, h)).resize((pad, h), Image.NEAREST), (pad + w, 0))
            im = canvas
        im.save(os.path.join(ssdir, f"{i}.png"))
    print(f"  phoneScreenshots/   {len(files)} x {im.size[0]}x{im.size[1]}  (ratio {im.size[1]/im.size[0]:.3f})")


def run(sport):
    if sport not in SPORTS:
        print(f"unknown sport: {sport}")
        return
    name, tagline = SPORTS[sport]
    outdir = os.path.join(PLAY_DIR, sport, "metadata", "android", "en-US", "images")
    os.makedirs(outdir, exist_ok=True)
    print(f"{sport}:")
    gen_icon(sport, outdir)
    gen_feature(sport, name, tagline, outdir)
    gen_screenshots(sport, outdir)


if __name__ == "__main__":
    args = sys.argv[1:] or ["all"]
    sports = list(SPORTS) if args == ["all"] else args
    for s in sports:
        run(s)
