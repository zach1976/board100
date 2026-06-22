#!/usr/bin/env python3
"""
aso_design_compositor.py — render the v2 "PLAN EVERY RALLY" App Store screenshots.

Composites, per (sport, locale, shot):
  - per-sport navy court-line background (drawn, not photographic)
  - a drawn titanium iPhone frame wrapping the captured app screenshot
  - "TACTICS BOARD" pill badge with the sport glyph
  - two-line headline (white word + accent-green line, dashes flanking line 2)
  - a one-line subtitle

Output canvas: 1290 x 2796 (App Store iPhone 6.7" required size).

Standalone sample (no captions table yet):
    python3 tool/aso_design_compositor.py --sample
"""

import argparse
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

REPO = Path(__file__).resolve().parent.parent
RAW = REPO / "fastlane" / "screenshots"
V2RAW = REPO / "aso" / "screenshots_v2_raw"
GLYPHS = REPO / "aso" / "glyphs"
CAPTIONS = REPO / "aso" / "captions_v2.json"
OUTBASE = REPO / "fastlane" / "screenshots"


def load_glyph(sport):
    p = GLYPHS / f"{sport}.png"
    return Image.open(p).convert("RGBA") if p.exists() else None

W, H = 1290, 2796

# ── palette ──────────────────────────────────────────────────────────────────
NAVY_TOP    = (9, 16, 38)
NAVY_MID    = (20, 36, 72)
NAVY_BOT    = (6, 11, 28)
GLOW        = (38, 64, 116)
ACCENT      = (159, 230, 63)      # lime green
WHITE       = (255, 255, 255)
SUBTITLE    = (188, 197, 214)
LINE        = (255, 255, 255)     # court lines (drawn at low alpha)

# ── fonts ────────────────────────────────────────────────────────────────────
HELV = "/System/Library/Fonts/HelveticaNeue.ttc"
EMOJI = "/System/Library/Fonts/Apple Color Emoji.ttc"
HIRA = "/System/Library/Fonts/Hiragino Sans GB.ttc"
HEITI = "/System/Library/Fonts/STHeiti Medium.ttc"
GOTHIC = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
THON = "/System/Library/Fonts/ThonburiUI.ttc"

def font(idx, size):
    return ImageFont.truetype(HELV, size, index=idx)

# HelveticaNeue.ttc indices: 4=Cond Bold, 9=Cond Black, 1=Bold, 10=Medium, 7=Light

# (path, ttc-index) per locale for the big headline + body subtitle.
HEADLINE_FONT = {
    "default":  (HELV, 9),     # Condensed Black
    "zh-Hans":  (HIRA, 2),     # Hiragino Sans GB W6
    "zh-Hant":  (HEITI, 0),    # Heiti TC Medium
    "ja":       (HIRA, 2),
    "ko":       (GOTHIC, 6),   # Apple SD Gothic Neo Bold
    "th":       (THON, 0),
}
BODY_FONT = {
    "default":  (HELV, 10),    # Medium
    "zh-Hans":  (HIRA, 0),
    "zh-Hant":  (HEITI, 0),
    "ja":       (HIRA, 0),
    "ko":       (GOTHIC, 2),   # Medium
    "th":       (THON, 0),
}
LATIN_LOCALES = {"en-US", "es-ES", "fr-FR", "id", "ms", "vi"}

def _font(table, locale, size):
    path, idx = table.get(locale, table["default"])
    return ImageFont.truetype(path, size, index=idx)

def headline_font(locale, size): return _font(HEADLINE_FONT, locale, size)
def body_font(locale, size):     return _font(BODY_FONT, locale, size)
def maybe_upper(locale, s):      return s.upper() if locale in LATIN_LOCALES else s


# ── background ───────────────────────────────────────────────────────────────
def vgrad(w, h, stops):
    """stops: list of (pos0..1, (r,g,b)). vertical gradient."""
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        # find segment
        for i in range(len(stops) - 1):
            p0, c0 = stops[i]
            p1, c1 = stops[i + 1]
            if p0 <= t <= p1:
                f = (t - p0) / (p1 - p0) if p1 > p0 else 0
                c = tuple(int(c0[k] + (c1[k] - c0[k]) * f) for k in range(3))
                break
        else:
            c = stops[-1][1]
        for x in range(w):
            px[x, y] = c
    return img


def radial_glow(w, h, cx, cy, radius, color, max_alpha):
    g = Image.new("L", (w, h), 0)
    gp = g.load()
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            d = math.hypot(x - cx, y - cy) / radius
            a = max(0, int(max_alpha * (1 - d))) if d < 1 else 0
            gp[x, y] = a
            if x + 1 < w: gp[x + 1, y] = a
            if y + 1 < h:
                gp[x, y + 1] = a
                if x + 1 < w: gp[x + 1, y + 1] = a
    g = g.filter(ImageFilter.GaussianBlur(40))
    layer = Image.new("RGB", (w, h), color)
    return layer, g


def perspective_court(sport):
    """Draw a faint receding court on a transparent layer. Returns RGBA."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    vx, vy = W / 2, H * 0.30          # vanishing point
    base_y = H * 1.02                 # court near edge (below screen)
    half_bottom = W * 0.95
    a = 30                            # line alpha

    def lerp_pt(x_bottom):
        """point on a line from (x_bottom, base_y) toward vanishing point, at depth d."""
        return (x_bottom, base_y)

    # longitudinal (side) lines converging to VP
    for fx in (-0.95, -0.62, -0.30, 0.0, 0.30, 0.62, 0.95):
        bx = vx + half_bottom * fx
        d.line([(bx, base_y), (vx + (vx - vx) * 0, vy)], fill=(*LINE, a), width=3)
        d.line([(bx, base_y), (vx, vy)], fill=(*LINE, a), width=3)

    # transversal lines at increasing depth (closer together toward VP)
    for k in range(1, 9):
        t = k / 9.0
        # ease so lines bunch near VP
        tt = t ** 1.7
        y = base_y + (vy - base_y) * tt
        wfac = (1 - tt)
        x0 = vx - half_bottom * wfac
        x1 = vx + half_bottom * wfac
        d.line([(x0, y), (x1, y)], fill=(*LINE, int(a * (0.5 + 0.5 * wfac))), width=3)

    layer = layer.filter(ImageFilter.GaussianBlur(0.6))
    return layer


def glyph_watermark(glyph_img):
    """Large faint sport glyph, top-right, slightly rotated."""
    if glyph_img is None:
        return None
    g = glyph_img.copy()
    bbox = g.getbbox()
    if bbox:
        g = g.crop(bbox)
    g = g.resize((300, 300), Image.LANCZOS)
    g = g.rotate(-16, expand=True, resample=Image.BICUBIC)
    alpha = g.split()[3].point(lambda p: int(p * 0.42))
    g.putalpha(alpha)
    return g


def build_background(sport, glyph_img):
    bg = vgrad(W, H, [
        (0.0, NAVY_TOP), (0.32, NAVY_MID), (0.62, (14, 26, 54)), (1.0, NAVY_BOT)
    ])
    glow_layer, glow_mask = radial_glow(W, H, W * 0.5, H * 0.40, W * 0.85, GLOW, 90)
    bg = Image.composite(glow_layer, bg, glow_mask)
    bg = bg.convert("RGBA")
    bg.alpha_composite(perspective_court(sport))
    wm = glyph_watermark(glyph_img)
    if wm:
        bg.alpha_composite(wm, (W - wm.width + 20, 36))
    # subtle vignette
    vig = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vig)
    vd.rectangle([0, 0, W, H], fill=0)
    vig = Image.new("L", (W, H), 0)
    vp = vig.load()
    for y in range(0, H, 3):
        for x in range(0, W, 3):
            d = math.hypot((x - W/2)/(W/2), (y - H/2)/(H/2))
            v = max(0, int(110 * (d - 0.6))) if d > 0.6 else 0
            for dx in range(3):
                for dy in range(3):
                    if x+dx < W and y+dy < H:
                        vp[x+dx, y+dy] = min(255, v)
    vig = vig.filter(ImageFilter.GaussianBlur(30))
    black = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    bg = Image.composite(black, bg, vig)
    return bg


# ── phone frame ──────────────────────────────────────────────────────────────
def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0]-1, size[1]-1], radius=radius, fill=255)
    return m


def phone(screenshot_path, top_frac=0.255, bottom_frac=0.95):
    shot = Image.open(screenshot_path).convert("RGB")
    sw, sh = shot.size
    aspect = sw / sh

    phone_top = int(H * top_frac)
    phone_bot = int(H * bottom_frac)
    phone_h = phone_bot - phone_top
    bezel = 24
    screen_h = phone_h - 2 * bezel
    screen_w = int(screen_h * aspect)
    phone_w = screen_w + 2 * bezel
    px = (W - phone_w) // 2
    py = phone_top

    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    # drop shadow
    sh_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh_layer)
    sd.rounded_rectangle([px-6, py+14, px+phone_w+6, py+phone_h+24], radius=120, fill=(0, 0, 0, 150))
    sh_layer = sh_layer.filter(ImageFilter.GaussianBlur(28))
    layer.alpha_composite(sh_layer)

    # titanium frame: metallic vertical gradient
    frame = vgrad(phone_w, phone_h, [
        (0.0, (94, 100, 110)), (0.5, (52, 57, 66)), (1.0, (78, 84, 94))
    ]).convert("RGBA")
    fmask = rounded_mask((phone_w, phone_h), 118)
    layer.paste(frame, (px, py), fmask)

    # inner black gap then screen
    gap = 6
    inner = Image.new("RGBA", (phone_w - 2*gap, phone_h - 2*gap), (8, 8, 10, 255))
    layer.paste(inner, (px+gap, py+gap), rounded_mask(inner.size, 112))

    # screen
    scr = shot.resize((screen_w, screen_h), Image.LANCZOS)
    smask = rounded_mask((screen_w, screen_h), 96)
    layer.paste(scr, (px+bezel, py+bezel), smask)

    # dynamic island pill near top center of screen
    di = ImageDraw.Draw(layer)
    di_w, di_h = int(screen_w * 0.30), 38
    di_x = px + bezel + (screen_w - di_w)//2
    di_y = py + bezel + 26
    di.rounded_rectangle([di_x, di_y, di_x+di_w, di_y+di_h], radius=di_h//2, fill=(8,8,10,255))

    # side buttons
    bd = ImageDraw.Draw(layer)
    bcol = (40, 44, 52, 255)
    bd.rounded_rectangle([px-3, py+int(phone_h*0.20), px+2, py+int(phone_h*0.255)], radius=3, fill=bcol)
    bd.rounded_rectangle([px-3, py+int(phone_h*0.30), px+2, py+int(phone_h*0.40)], radius=3, fill=bcol)
    bd.rounded_rectangle([px-3, py+int(phone_h*0.41), px+2, py+int(phone_h*0.51)], radius=3, fill=bcol)
    bd.rounded_rectangle([px+phone_w-2, py+int(phone_h*0.27), px+phone_w+3, py+int(phone_h*0.40)], radius=3, fill=bcol)

    # reflection under phone
    refl = layer.crop((px, py+phone_h-int(phone_h*0.18), px+phone_w, py+phone_h)).transpose(Image.FLIP_TOP_BOTTOM)
    ra = refl.split()[3].point(lambda p: int(p * 0.22))
    refl.putalpha(ra)
    refl = refl.filter(ImageFilter.GaussianBlur(2))
    layer.alpha_composite(refl, (px, py+phone_h+8))

    return layer


# ── text ─────────────────────────────────────────────────────────────────────
def draw_text_center(d, cy, text, fnt, fill, tracking=0):
    if tracking == 0:
        w = d.textlength(text, font=fnt)
        bbox = fnt.getbbox(text)
        x = (W - w) / 2
        d.text((x, cy - (bbox[3]-bbox[1])/2 - bbox[1]), text, font=fnt, fill=fill)
        return w
    # letter-spaced
    widths = [d.textlength(ch, font=fnt) for ch in text]
    total = sum(widths) + tracking * (len(text) - 1)
    x = (W - total) / 2
    bbox = fnt.getbbox(text)
    yy = cy - (bbox[3]-bbox[1])/2 - bbox[1]
    for ch, w in zip(text, widths):
        d.text((x, yy), ch, font=fnt, fill=fill)
        x += w + tracking
    return total


def draw_badge(img, glyph_img, label):
    d = ImageDraw.Draw(img)
    bf = font(4, 40)                       # condensed bold
    tracking = 6
    # measure label
    widths = [d.textlength(c, font=bf) for c in label]
    text_w = sum(widths) + tracking * (len(label)-1)
    glyph_w = 52
    pad_x = 34
    pill_w = int(glyph_w + 14 + text_w + pad_x*2)
    pill_h = 84
    cy = int(H * 0.045)
    x0 = (W - pill_w)//2
    y0 = cy
    # pill
    pill = Image.new("RGBA", (pill_w, pill_h), (0,0,0,0))
    pd = ImageDraw.Draw(pill)
    pd.rounded_rectangle([0,0,pill_w-1,pill_h-1], radius=pill_h//2, fill=(11,20,42,210), outline=(*ACCENT,255), width=3)
    img.alpha_composite(pill, (x0, y0))
    # glyph icon
    if glyph_img is not None:
        g = glyph_img.copy()
        bb = g.getbbox()
        if bb: g = g.crop(bb)
        g = g.resize((glyph_w, glyph_w), Image.LANCZOS)
        img.alpha_composite(g, (x0+pad_x, y0+(pill_h-glyph_w)//2))
    # label
    d = ImageDraw.Draw(img)
    tx = x0 + pad_x + glyph_w + 14
    ty = y0 + (pill_h)//2
    bbox = bf.getbbox(label)
    yy = ty - (bbox[3]-bbox[1])/2 - bbox[1]
    for c, w in zip(label, widths):
        d.text((tx, yy), c, font=bf, fill=(*ACCENT,255))
        tx += w + tracking
    return y0 + pill_h


def _fit_font(table, locale, text, max_w, start, tracking, lo=70):
    """Largest font size whose text width <= max_w."""
    d = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    size = start
    while size > lo:
        f = _font(table, locale, size)
        w = d.textlength(text, font=f) + tracking * (len(text) - 1)
        if w <= max_w:
            return f
        size -= 4
    return _font(table, locale, lo)


def draw_headline(img, locale, white_word, green_words, subtitle):
    d = ImageDraw.Draw(img)
    tracking = 2 if locale in LATIN_LOCALES else 0
    max_w = W - 120
    l1 = maybe_upper(locale, white_word)
    l2 = maybe_upper(locale, green_words)
    hf = _fit_font(HEADLINE_FONT, locale, max(l1, l2, key=len), max_w, 158, tracking)

    cy1 = int(H * 0.118)
    draw_text_center(d, cy1, l1, hf, (*WHITE, 255), tracking=tracking)

    cy2 = int(H * 0.172)
    lw = draw_text_center(d, cy2, l2, hf, (*ACCENT, 255), tracking=tracking)
    # dashes flanking line 2 (only when they fit on the canvas)
    dash_len = 64
    gap = 38
    left_x1 = (W - lw) / 2 - gap
    if left_x1 - dash_len > 30:
        d.line([(left_x1 - dash_len, cy2), (left_x1, cy2)], fill=(*ACCENT, 255), width=8)
        right_x0 = (W + lw) / 2 + gap
        d.line([(right_x0, cy2), (right_x0 + dash_len, cy2)], fill=(*ACCENT, 255), width=8)

    cy3 = int(H * 0.222)
    sf = _fit_font(BODY_FONT, locale, subtitle, max_w, 42, 0, lo=26)
    draw_text_center(d, cy3, subtitle, sf, (*SUBTITLE, 255))


# ── compose one ──────────────────────────────────────────────────────────────
def compose(screenshot_path, out_path, sport, locale, label,
            white_word, green_words, subtitle):
    glyph_img = load_glyph(sport)
    img = build_background(sport, glyph_img)
    img.alpha_composite(phone(screenshot_path))
    draw_badge(img, glyph_img, label)
    draw_headline(img, locale, white_word, green_words, subtitle)
    img.convert("RGB").save(out_path, "PNG")


def load_captions():
    return json.loads(CAPTIONS.read_text())


# For the multi-sport flagship, each shot showcases a different sport.
FLAGSHIP_SPORTS = ["soccer", "basketball", "volleyball", "tennis", "badminton", "handball"]


def render_sport_locale(captions, sport, locale, outbase):
    """Render all 6 shots for one sport+locale. Returns count rendered."""
    shots = captions.get(sport, {}).get(locale) or captions.get(sport, {}).get("en-US")
    if not shots:
        print(f"⚠️  no captions for {sport}/{locale}")
        return 0
    out_dir = Path(outbase) / sport / locale
    out_dir.mkdir(parents=True, exist_ok=True)
    # clear stale iPhone screenshots so the dir holds exactly the new 6
    for old in out_dir.glob("*.png"):
        if not old.name.startswith("ipad"):
            old.unlink()
    flagship = sport == "tactics_board"
    n = 0
    for i in range(6):
        # flagship pulls each shot from a different sport for a multi-sport feel
        src_sport = FLAGSHIP_SPORTS[i] if flagship else sport
        src = V2RAW / src_sport / locale / f"s{i+1}.png"
        if not src.exists():
            print(f"⚠️  missing raw {src}")
            continue
        white, green, sub = shots[i]
        out = out_dir / f"{i+1:02d}_{sport}_s{i+1}.png"
        compose(src, out, src_sport, locale, "TACTICS BOARD", white, green, sub)
        n += 1
    print(f"✅ {sport}/{locale}: {n}/6")
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sample", action="store_true")
    ap.add_argument("--sport")
    ap.add_argument("--locale")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--out", default=str(OUTBASE))
    args = ap.parse_args()

    if args.sample:
        caps = load_captions()
        render_sport_locale(caps, "badminton", "en-US", REPO / "aso" / "sample_v2")
        return

    caps = load_captions()
    if args.all:
        total = 0
        for sport in caps:
            for locale in caps[sport]:
                total += render_sport_locale(caps, sport, locale, args.out)
        print(f"\nTOTAL: {total} screenshots")
    elif args.sport and args.locale:
        render_sport_locale(caps, args.sport, args.locale, args.out)
    else:
        ap.error("use --sample, --all, or --sport X --locale Y")


if __name__ == "__main__":
    main()
