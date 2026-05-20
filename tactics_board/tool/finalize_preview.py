#!/usr/bin/env python3
"""
finalize_preview.py — post-process a raw simulator screen recording into
an App Store-ready preview video for one SKU × locale.

Steps:
1. Trim leading/trailing silence (first few frames may be black during
   simulator boot; last frames may have post-test idle).
2. Overlay 6 captioned text bands at scripted timings (Angle A storyline).
3. Resize to 1320×2868 portrait (Apple 6.9" App Preview spec) preserving aspect.
4. Encode H.264 with +faststart for streaming.

Usage:
    python3 tool/finalize_preview.py --raw /tmp/preview_soccer_raw.mov \\
        --out aso/previews/soccer/en-US/preview_v3.mov
"""
import argparse
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageStat

# Caption display windows (start, end) in seconds into the FINAL video
# (after trim). Each caption stays visible until the next one starts; the
# timings match the integration-test scene pacing. The text for each window
# is pulled per-locale from preview_captions.json.
CAPTION_TIMINGS = [
    (0.0,  3.0),
    (3.0,  7.3),
    (7.3,  14.5),
    (14.5, 20.0),
    (20.0, 24.5),
    (24.5, 29.0),
]

CAPTIONS_JSON = Path(__file__).resolve().parent / "preview_captions.json"


def load_captions(locale):
    """Return [(start, end, text), …] for `locale` from preview_captions.json.
    Falls back to en-US for any locale not present in the file."""
    data = json.loads(CAPTIONS_JSON.read_text(encoding="utf-8"))
    texts = data.get(locale) or data["en-US"]
    if len(texts) != len(CAPTION_TIMINGS):
        raise ValueError(
            f"preview_captions.json[{locale}] has {len(texts)} captions, "
            f"expected {len(CAPTION_TIMINGS)}")
    return [(s, e, t) for (s, e), t in zip(CAPTION_TIMINGS, texts)]


# Apple 6.9" App Preview portrait spec: 1320×2868 (iPhone 17 Pro Max native).
# Matches the simulator recordVideo output exactly, so no letter-boxing.
OUT_W, OUT_H = 1320, 2868

# Caption band on top, white text on translucent dark.
BAND_H = 360
FONT_SIZE = 96

# Latin / fallback bold fonts — cover en/es/fr/id/ms/vi. (path, ttc-index).
FONT_CANDIDATES_LATIN = [
    ("/System/Library/Fonts/HelveticaNeue.ttc", 7),   # index 7 = Bold
    ("/System/Library/Fonts/Helvetica.ttc", 1),
    ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 0),
]
# Locales whose scripts need a CJK / Thai font (first available wins).
LOCALE_FONTS = {
    "zh-Hant": [("/System/Library/Fonts/STHeiti Medium.ttc", 0)],   # Heiti TC
    "zh-Hans": [("/System/Library/Fonts/STHeiti Medium.ttc", 1)],   # Heiti SC
    "ja":      [("/System/Library/Fonts/Hiragino Sans GB.ttc", 2)],  # W6
    "ko":      [("/System/Library/Fonts/AppleSDGothicNeo.ttc", 6)],  # Bold
    "th":      [("/System/Library/Fonts/Supplemental/Thonburi.ttc", 1)],  # Bold
}
# Scripts written without spaces — wrap by character instead of by word.
CHAR_WRAP_LOCALES = {"ja", "zh-Hans", "zh-Hant"}

# Locales whose script needs complex-text shaping (Thai vowel / tone-mark
# stacking) that Pillow cannot do without libraqm. The bundled Pillow has no
# raqm, so these caption bands are rendered by the CoreText helper
# tool/shape_text instead, which shapes every script correctly.
SWIFT_RENDER_LOCALES = {"th"}
_SHAPE_TEXT_SRC = Path(__file__).resolve().parent / "shape_text.swift"
_SHAPE_TEXT_BIN = Path(__file__).resolve().parent / "shape_text"


def load_font(size, locale):
    """Best available bold font for the locale's script."""
    for path, idx in LOCALE_FONTS.get(locale, []) + FONT_CANDIDATES_LATIN:
        try:
            return ImageFont.truetype(path, size, index=idx)
        except Exception:
            continue
    return ImageFont.load_default()


def probe(raw):
    """Return (duration_sec, width, height) of the raw recording."""
    out = subprocess.run(
        ["ffprobe", "-v", "error",
         "-show_entries", "format=duration:stream=width,height",
         "-of", "json", str(raw)],
        capture_output=True, text=True, check=True).stdout
    j = json.loads(out)
    dur = float(j["format"]["duration"])
    w = int(j["streams"][0]["width"])
    h = int(j["streams"][0]["height"])
    return dur, w, h


def _frame_at(raw, t, workdir):
    out = workdir / f"trim_probe_{t:06.2f}.png"
    if not out.exists():
        subprocess.run(
            ["ffmpeg", "-y", "-ss", f"{t}", "-i", str(raw),
             "-frames:v", "1", "-q:v", "3", str(out)],
            capture_output=True, check=True)
    return out


def _looks_like_home_screen(png_path):
    """Heuristic: icon-grid in upper half + near-zero pitch-green ratio.
    Mirrors the predicate in test_preview_video.py so the two stay aligned."""
    im = Image.open(png_path).convert("RGBA")
    pixels = list(im.getdata())
    green = sum(
        1 for r, g, b, *_ in pixels
        if g > 60 and g > r * 1.2 and g > b * 1.1 and g < 200
    ) / len(pixels)
    if green > 0.05:
        return False
    sample = im.crop((0, im.height // 8, im.width, im.height * 7 // 16)).resize((40, 40))
    var_sum = sum(ImageStat.Stat(sample).var[:3])
    return var_sum > 9000


def _is_content_frame(png_path):
    """True if the frame shows the actual board UI — not the iOS home
    screen, the app's launch/splash screen, or a black launch frame.

    The board is a playing field made of a few large flat colour regions
    (pitch + lines, or a two-tone court); the iOS Springboard and the app's
    splash (a multi-sport icon collage) scatter colour across many small
    regions. So the board's top-3 quantised colours cover most of the frame
    while the home screen / splash do not. Apple App Preview reviewers reject
    previews that open on a splash or black screen.

    Single-colour dominance is NOT enough: the table-tennis board is a
    two-tone blue whose largest colour (~0.48) matches the splash (~0.48).
    The top-3 cumulative share separates them cleanly.

    Measured: home screen top3≈0.20, app splash top3≈0.64, table-tennis
    board top3≈0.85, single-field courts (basketball…) top3≈0.90+."""
    from collections import Counter
    im = Image.open(png_path).convert("RGB")
    mean_sum = sum(ImageStat.Stat(im).mean[:3])
    if mean_sum < 60:
        return False              # near-black launch frame
    small = im.resize((64, 64))
    quant = [(r // 32, g // 32, b // 32) for r, g, b in small.getdata()]
    top3 = sum(n for _, n in Counter(quant).most_common(3)) / (64 * 64)
    return top3 > 0.75            # a few field colours fill the frame → board


def detect_app_window(raw, dur, workdir, coarse_step=1.0, fine_step=0.2):
    """Find [start, end] of the in-app footage in the raw recording.

    Walks forward at `coarse_step` until the first non-home frame, then
    refines backward at `fine_step` to get a tighter start. Mirrors from
    the tail for the end.
    """
    # Forward scan
    t = 0.0
    while t < dur and _looks_like_home_screen(_frame_at(raw, t, workdir)):
        t += coarse_step
    start = max(0.0, t)
    # Refine backwards
    refine_t = start - coarse_step
    while refine_t < start - 1e-3:
        if not _looks_like_home_screen(_frame_at(raw, refine_t, workdir)):
            start = max(0.0, refine_t)
            break
        refine_t += fine_step
    # Backward scan from tail
    t = dur - 0.1
    while t > start and _looks_like_home_screen(_frame_at(raw, t, workdir)):
        t -= coarse_step
    end = min(dur, t + coarse_step)
    # Refine forward
    refine_t = end - coarse_step + fine_step
    while refine_t < end:
        if _looks_like_home_screen(_frame_at(raw, refine_t, workdir)):
            end = max(start, refine_t - fine_step)
            break
        refine_t += fine_step
    return start, end


def _wrap_caption(draw, text, font, max_w, by_char):
    """Greedy-wrap into lines that each fit `max_w`. `by_char` wraps between
    characters (CJK, written without spaces); otherwise between word tokens."""
    if by_char:
        tokens, sep = list(text), ""
    else:
        tokens, sep = text.split(), " "
    lines, cur = [], ""
    for tok in tokens:
        trial = tok if not cur else cur + sep + tok
        if not cur or draw.textbbox((0, 0), trial, font=font)[2] <= max_w:
            cur = trial
        else:
            lines.append(cur)
            cur = tok
    if cur:
        lines.append(cur)
    return lines


def _ensure_shape_text():
    """Compile tool/shape_text.swift if the binary is missing or stale."""
    if (_SHAPE_TEXT_BIN.exists() and _SHAPE_TEXT_SRC.exists()
            and _SHAPE_TEXT_BIN.stat().st_mtime
            >= _SHAPE_TEXT_SRC.stat().st_mtime):
        return _SHAPE_TEXT_BIN
    r = subprocess.run(["swiftc", "-O", str(_SHAPE_TEXT_SRC),
                        "-o", str(_SHAPE_TEXT_BIN)],
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"swiftc failed building shape_text:\n{r.stderr}")
    return _SHAPE_TEXT_BIN


def _render_caption_pngs_swift(workdir, captions):
    """Render caption bands via the CoreText helper — for complex scripts
    (Thai) that Pillow cannot shape. Returns (start, end, png_path) tuples."""
    binary = _ensure_shape_text()
    out = []
    for i, (start, end, text) in enumerate(captions):
        p = workdir / f"caption_{i:02d}.png"
        subprocess.run([str(binary), str(p), str(OUT_W), str(BAND_H), text],
                       check=True, capture_output=True)
        out.append((start, end, p))
    return out


def render_caption_pngs(workdir, captions, locale):
    """Render each caption as a transparent PNG band.

    Complex-script locales (Thai) go through the CoreText helper; the rest
    are rendered with Pillow (ffmpeg `drawtext` is unavailable — the bundled
    ffmpeg lacks --enable-libfreetype). Returns (start, end, png_path) tuples.
    The font is picked for the locale's script; the text is shrunk and
    wrapped to fit the band in ≤2 lines.
    """
    if locale in SWIFT_RENDER_LOCALES:
        return _render_caption_pngs_swift(workdir, captions)
    by_char = locale in CHAR_WRAP_LOCALES
    max_w = OUT_W - 120
    out = []
    for i, (start, end, text) in enumerate(captions):
        img = Image.new("RGBA", (OUT_W, BAND_H), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        # Shrink the font until the caption wraps into at most 2 lines.
        size = FONT_SIZE
        font = load_font(size, locale)
        lines = _wrap_caption(d, text, font, max_w, by_char)
        while len(lines) > 2 and size > 40:
            size -= 6
            font = load_font(size, locale)
            lines = _wrap_caption(d, text, font, max_w, by_char)
        # Translucent dark rounded band.
        d.rounded_rectangle([(40, 30), (OUT_W - 40, BAND_H - 30)],
                            radius=24, fill=(13, 13, 26, 220))
        # Vertically centre the 1- or 2-line text block in the band.
        ascent, descent = font.getmetrics()
        line_h = ascent + descent + 12
        y = (BAND_H - line_h * len(lines)) // 2
        for line in lines:
            bb = d.textbbox((0, 0), line, font=font)
            d.text(((OUT_W - (bb[2] - bb[0])) // 2 - bb[0], y),
                   line, fill=(255, 255, 255, 255), font=font)
            y += line_h
        p = workdir / f"caption_{i:02d}.png"
        img.save(p, "PNG")
        out.append((start, end, p))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", required=True, help="raw simctl recordVideo .mov")
    ap.add_argument("--out", required=True, help="finalized preview .mov path")
    ap.add_argument("--trim-start", type=float, default=None,
                    help="seconds to skip from raw start "
                         "(default: auto-detect first non-home-screen frame)")
    ap.add_argument("--keep", type=float, default=None,
                    help="seconds of usable footage to keep "
                         "(default: auto = end-of-app minus start, capped at 29s)")
    ap.add_argument("--locale", default="en-US",
                    help="caption locale — a key in preview_captions.json")
    args = ap.parse_args()

    raw = Path(args.raw)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    if not raw.exists():
        print(f"❌ raw not found: {raw}", file=sys.stderr); return 1
    if not shutil.which("ffmpeg"):
        print("❌ ffmpeg not found", file=sys.stderr); return 1

    dur, w, h = probe(raw)
    print(f"raw: {w}×{h}, {dur:.1f}s")

    workdir = Path(tempfile.mkdtemp(prefix="preview_"))
    captions = render_caption_pngs(workdir, load_captions(args.locale),
                                   args.locale)
    print(f"rendered {len(captions)} {args.locale} caption PNGs in {workdir}")

    # Auto-detect app window in the raw recording. The simulator stays on
    # the iOS Springboard for ~30-45s while flutter test compiles & installs,
    # then again briefly after the test exits. We must trim those out.
    if args.trim_start is None or args.keep is None:
        print("scanning raw for app-launch boundary...")
        a_start, a_end = detect_app_window(raw, dur, workdir)
        # detect_app_window stops at the first non-home-screen frame, which
        # is the app's launch/splash screen — not the board. Fine-scan
        # forward to the first frame that shows the actual board UI, so the
        # preview never opens on the splash screen or a black launch frame.
        # Find the first frame whose following ~0.9s are ALL board content,
        # so the trim never starts on — or just before — a black transition
        # flash between the splash and the board.
        scan_t = a_start
        content_start = a_end
        while scan_t < a_end - 1.0:
            if all(_is_content_frame(_frame_at(raw, scan_t + dt, workdir))
                   for dt in (0.0, 0.2, 0.45, 0.7, 0.9)):
                content_start = scan_t
                break
            scan_t += 0.1
        # Safety net: if no board frame was found, fall back to the start of
        # the app window. Leaving content_start at a_end would make `keep`
        # compute to 0, and ffmpeg with `-t 0` plus the infinitely-looped
        # caption PNG inputs hangs forever instead of erroring out.
        if content_start >= a_end - 1.0:
            content_start = a_start
        # The board paints its canvas background a few frames before the
        # field itself, so the first ~0.1-0.4s of board footage can be a
        # dim placeholder that reads as a near-black opening frame. Advance
        # past any such frame so the preview never opens near-black.
        #
        # Reference brightness = the settled empty board. Sample a few
        # frames inside Scene 1 (the ~1.2s empty-board opening) and take the
        # brightest, so the reference is the fully-painted board — not a dim
        # fade-in frame and not the photo sheet that slides up afterwards.
        def _brightness(t):
            im = Image.open(_frame_at(raw, t, workdir)).convert("RGB")
            return sum(ImageStat.Stat(im).mean[:3])
        ref_b = max(_brightness(min(content_start + dt, a_end - 0.2))
                    for dt in (0.5, 0.7, 0.9))
        # Skip opening frames dimmer than the settled board, with an absolute
        # floor so a near-black frame can never survive as frame 1.
        floor = max(ref_b * 0.88, 120.0)
        while (content_start < a_end - 1.6
               and _brightness(content_start) < floor):
            content_start += 0.066
        usable = max(0.0, a_end - content_start - 0.4)  # 0.4s tail buffer
        if args.trim_start is None:
            args.trim_start = content_start
        if args.keep is None:
            args.keep = min(29.0, usable)
        print(f"  app window: [{a_start:.1f}s, {a_end:.1f}s], "
              f"board UI from {content_start:.2f}s "
              f"→ trim {args.trim_start:.2f}s, keep {args.keep:.2f}s")

    # Build the ffmpeg command:
    #   input 0: raw simulator recording
    #   inputs 1..N: caption PNGs
    #   filter graph:
    #     [0] trim → scale-to-fit OUT_W×OUT_H (letter-boxed) → fps=30 → [base]
    #     [base][cap_i] overlay caption_i at top during its time window
    cmd = ["ffmpeg", "-y", "-i", str(raw)]
    for (_, _, png) in captions:
        cmd += ["-loop", "1", "-i", str(png)]
    # Silent stereo audio track — App Store app previews are rejected with
    # MOV_RESAVE_STEREO unless the .mov carries a stereo audio track.
    cmd += ["-f", "lavfi",
            "-i", "anullsrc=channel_layout=stereo:sample_rate=44100"]
    audio_idx = 1 + len(captions)

    base = (
        f"[0:v]trim=start={args.trim_start}:duration={args.keep},"
        f"setpts=PTS-STARTPTS,"
        f"scale=w='if(gt(a,{OUT_W}/{OUT_H}),{OUT_W},-2)':"
        f"h='if(gt(a,{OUT_W}/{OUT_H}),-2,{OUT_H})',"
        f"pad={OUT_W}:{OUT_H}:(ow-iw)/2:(oh-ih)/2:color=0x0D0D1A,"
        f"setsar=1,fps=30[base]"
    )
    fc = [base]
    last = "[base]"
    for i, (start, end, _) in enumerate(captions):
        idx = i + 1
        tag = f"[v{idx}]"
        fc.append(
            f"{last}[{idx}:v]overlay=x=(W-w)/2:y=40:"
            f"enable='between(t,{start},{end})':"
            f"shortest=0{tag}"
        )
        last = tag
    cmd += ["-filter_complex", ";".join(fc),
            "-map", last,
            "-map", f"{audio_idx}:a",
            "-t", str(args.keep),  # cap output duration; caption PNGs would loop forever otherwise
            # Hardware H.264 (VideoToolbox) — ~5-10× faster than libx264, which
            # matters when finalizing 11 locales per sport. Apple's own encoder.
            "-c:v", "h264_videotoolbox", "-b:v", "10M", "-profile:v", "high",
            "-pix_fmt", "yuv420p",
            "-c:a", "aac", "-b:a", "128k",
            "-movflags", "+faststart",
            "-shortest",
            str(out)]
    print("ffmpeg: …", str(cmd[-1]))
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print("❌ ffmpeg failed", file=sys.stderr)
        print(r.stderr[-2000:], file=sys.stderr)
        return 1
    final_dur, final_w, final_h = probe(out)
    print(f"\n✓ {out}  {final_w}×{final_h}  {final_dur:.1f}s  "
          f"{out.stat().st_size/1024/1024:.1f} MB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
