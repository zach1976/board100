#!/usr/bin/env python3
"""
make_preview_video.py — build an App Store preview video for one SKU × locale.

Re-composes the 6 captioned frames with a polished gradient backdrop + soft
device shadow (instead of the flat #0D0D1A used by aso_caption_overlay.py),
then ffmpegs them into a 21.5-second 1290×2796 H.264 .mov with crossfade
transitions.

Output: aso/previews/<sku>/<locale>/preview_v<N>.mov
"""
import argparse, re, subprocess, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO_ROOT = Path(__file__).resolve().parent.parent
CAPTIONS_MD = REPO_ROOT / "aso" / "SCREENSHOT_CAPTIONS.md"
RAW_DIR = REPO_ROOT / "aso" / "screenshots_localized"

CANVAS_W, CANVAS_H = 1290, 2796
CAPTION_BAND_H = 720
GRADIENT_TOP = (10, 10, 24, 255)        # #0A0A18 — slightly deeper navy at top
GRADIENT_BOTTOM = (31, 26, 53, 255)     # #1F1A35 — subtle purple lift at bottom
TEXT_HEX = (255, 255, 255, 255)
ACCENT_HEX = (0xFF, 0xD6, 0x00, 255)
SHADOW_HEX = (0, 0, 0, 110)             # device shadow opacity

ACCENT_RE = re.compile(r"<a>(.+?)</a>")

SHOT_SUFFIX = {
    1: ["s1_sport_selection", "s1_empty"],
    2: ["s2_formation"],
    3: ["s3_drawing"],
    4: ["s4_moves"],
    5: ["s5_timeline"],
    6: ["s6_playback"],
}

LOCALE_FONTS = {
    "zh-Hans": [("/System/Library/Fonts/Hiragino Sans GB.ttc", 1)],
    "zh-Hant": [("/System/Library/Fonts/Hiragino Sans GB.ttc", 1)],
    "ja":      [("/System/Library/Fonts/Hiragino Sans GB.ttc", 1),
                ("/System/Library/Fonts/AppleSDGothicNeo.ttc", 2)],
    "ko":      [("/System/Library/Fonts/AppleSDGothicNeo.ttc", 2)],
    "th":      [("/System/Library/Fonts/ThonburiUI.ttc", 1),
                ("/System/Library/Fonts/Thonburi.ttc", 1)],
}
FALLBACK = [("/System/Library/Fonts/HelveticaNeue.ttc", 7),
            ("/System/Library/Fonts/Helvetica.ttc", 0)]


def load_font(size, locale):
    for path, idx in LOCALE_FONTS.get(locale, []) + FALLBACK:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size=size, index=idx)
            except Exception:
                pass
    return ImageFont.load_default()


def gradient_bg(w, h):
    """Vertical gradient via 1×h column resized to w×h."""
    col = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / max(h - 1, 1)
        r = int(GRADIENT_TOP[0] + (GRADIENT_BOTTOM[0] - GRADIENT_TOP[0]) * t)
        g = int(GRADIENT_TOP[1] + (GRADIENT_BOTTOM[1] - GRADIENT_TOP[1]) * t)
        b = int(GRADIENT_TOP[2] + (GRADIENT_BOTTOM[2] - GRADIENT_TOP[2]) * t)
        col.putpixel((0, y), (r, g, b))
    return col.resize((w, h), Image.NEAREST).convert("RGBA")


def round_corners(im, radius=48):
    w, h = im.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([(0, 0), (w - 1, h - 1)], radius=radius, fill=255)
    out = im.copy() if im.mode == "RGBA" else im.convert("RGBA")
    out.putalpha(mask)
    return out


def device_shadow(w, h, radius=48, blur=40, spread=18):
    """Build a soft shadow alpha image sized for a wxh device."""
    pad = blur * 2
    shadow = Image.new("RGBA", (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle([(pad - spread, pad - spread // 2),
                          (pad + w + spread, pad + h + spread)],
                         radius=radius + spread, fill=SHADOW_HEX)
    return shadow.filter(ImageFilter.GaussianBlur(blur))


def parse_segments(text):
    out, pos = [], 0
    for m in ACCENT_RE.finditer(text):
        if m.start() > pos:
            out.append((text[pos:m.start()], False))
        out.append((m.group(1), True))
        pos = m.end()
    if pos < len(text):
        out.append((text[pos:], False))
    return out or [(text, False)]


def parse_captions(md_path, locale, sku):
    """Pull the 6 captions for (locale, sku) from SCREENSHOT_CAPTIONS.md."""
    text = md_path.read_text(encoding="utf-8")
    caps, cur_loc, cur_sku = [], "en-US", None
    for line in text.splitlines():
        m = re.match(r"^#\s+Locale:\s*([\w-]+)\s*$", line)
        if m:
            cur_loc = m.group(1).strip(); cur_sku = None; continue
        m = re.match(r"^##\s+([A-Za-z_]+)\b", line)
        if m:
            cur_sku = m.group(1).strip(); continue
        if cur_loc == locale and cur_sku == sku:
            r = re.match(r"^\|\s*(\d+)\s*\|\s*(.+?)\s*\|\s*$", line)
            if r and 1 <= int(r.group(1)) <= 6:
                caps.append(r.group(2).strip())
    return caps


def compose_frame(src_png, caption, locale):
    canvas = gradient_bg(CANVAS_W, CANVAS_H)

    src = Image.open(src_png).convert("RGBA")
    panel_w, panel_h = CANVAS_W, CANVAS_H - CAPTION_BAND_H
    sw, sh = src.size
    scale = min(panel_w / sw, panel_h / sh)
    new_w, new_h = int(sw * scale), int(sh * scale)
    src_scaled = src.resize((new_w, new_h), Image.LANCZOS)
    src_rounded = round_corners(src_scaled, radius=48)
    off_x = (panel_w - new_w) // 2
    off_y = CAPTION_BAND_H + (panel_h - new_h) // 2

    # Soft shadow under the device
    shadow = device_shadow(new_w, new_h, radius=48, blur=40, spread=18)
    shadow_off_x = off_x - 80
    shadow_off_y = off_y - 80 + 24      # nudge shadow down for "light from above"
    canvas.alpha_composite(shadow, (shadow_off_x, shadow_off_y))

    # Device
    canvas.alpha_composite(src_rounded, (off_x, off_y))

    # Caption
    draw = ImageDraw.Draw(canvas)
    segs = parse_segments(caption)
    plain = "".join(s for s, _ in segs)
    font = None; lines = []
    for size in (92, 84, 76, 68, 60):
        font = load_font(size, locale)
        bbox = draw.textbbox((0, 0), plain, font=font)
        if bbox[2] - bbox[0] <= CANVAS_W - 160:
            lines = [plain]; break
        # word wrap
        words = plain.split()
        if " " in plain:
            cur, lines = "", []
            for w in words:
                trial = (cur + " " + w).strip()
                if draw.textbbox((0, 0), trial, font=font)[2] <= CANVAS_W - 160:
                    cur = trial
                else:
                    if cur: lines.append(cur)
                    cur = w
            if cur: lines.append(cur)
        else:
            lines = [plain]
        if len(lines) <= 2: break

    line_h = (font.getbbox("Ay")[3] - font.getbbox("Ay")[1]) + 16
    total_h = line_h * len(lines)
    y = (CAPTION_BAND_H - total_h) // 2

    if len(lines) == 1 and any(is_a for _, is_a in segs):
        seg_w = [draw.textbbox((0, 0), s, font=font)[2] for s, _ in segs]
        total_w = sum(seg_w)
        x = (CANVAS_W - total_w) // 2
        for (seg, is_a), w in zip(segs, seg_w):
            draw.text((x, y), seg, fill=ACCENT_HEX if is_a else TEXT_HEX, font=font)
            x += w
    else:
        for line in lines:
            bb = draw.textbbox((0, 0), line, font=font)
            x = (CANVAS_W - (bb[2] - bb[0])) // 2
            draw.text((x, y), line, fill=TEXT_HEX, font=font)
            y += line_h

    return canvas.convert("RGB")


def find_raw(sku, locale, shot_idx):
    for suffix in SHOT_SUFFIX[shot_idx]:
        p = RAW_DIR / sku / locale / f"{suffix}.png"
        if p.exists():
            return p
    return None


def build_video(frames_dir, out_path, per_shot=4.0, crossfade=0.5):
    """ffmpeg-build the 21.5s preview from 6 PNG frames."""
    inputs = []
    for i in range(1, 7):
        inputs += ["-loop", "1", "-t", str(per_shot), "-i",
                   str(frames_dir / f"frame_{i:02d}.png")]
    fc = []
    for i in range(6):
        fc.append(f"[{i}:v]fps=30,scale={CANVAS_W}:{CANVAS_H},setsar=1[v{i}]")
    last = "v0"
    for i in range(1, 6):
        offset = i * per_shot - i * crossfade - (per_shot - per_shot) - crossfade
        # Cumulative offset = sum of previous (per_shot - crossfade) durations.
        offset = i * (per_shot - crossfade) - crossfade + crossfade  # simplifies to i*(per_shot-crossfade)
        offset = i * per_shot - i * crossfade - (crossfade) if i == 1 else \
                 i * (per_shot - crossfade) - crossfade
        # Simpler & correct: cumulative non-overlapped time before the i-th transition
        offset = i * per_shot - i * crossfade
        tag = f"x{i}"
        fc.append(f"[{last}][v{i}]xfade=transition=fade:duration={crossfade}:offset={offset}[{tag}]")
        last = tag
    cmd = ["ffmpeg", "-y", *inputs, "-filter_complex", ";".join(fc),
           "-map", f"[{last}]", "-c:v", "libx264", "-pix_fmt", "yuv420p",
           "-movflags", "+faststart", str(out_path)]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sku", default="soccer")
    ap.add_argument("--locale", default="en-US")
    ap.add_argument("--version", type=int, default=2)
    ap.add_argument("--per-shot", type=float, default=4.0)
    args = ap.parse_args()

    caps = parse_captions(CAPTIONS_MD, args.locale, args.sku)
    if len(caps) != 6:
        print(f"❌ expected 6 captions, got {len(caps)} for [{args.locale}][{args.sku}]", file=sys.stderr)
        return 1

    out_dir = REPO_ROOT / "aso" / "previews" / args.sku / args.locale
    frames_dir = out_dir / f"frames_v{args.version}"
    frames_dir.mkdir(parents=True, exist_ok=True)

    for i, cap in enumerate(caps, start=1):
        raw = find_raw(args.sku, args.locale, i)
        if raw is None:
            print(f"❌ raw missing for s{i}", file=sys.stderr); return 1
        frame = compose_frame(raw, cap, args.locale)
        out = frames_dir / f"frame_{i:02d}.png"
        frame.save(out, "PNG", optimize=True)
        print(f"  ✓ frame {i}: {cap[:55]}{'…' if len(cap) > 55 else ''}")

    out_video = out_dir / f"preview_v{args.version}.mov"
    build_video(frames_dir, out_video, per_shot=args.per_shot)
    print(f"\n→ {out_video}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
