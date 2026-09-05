#!/usr/bin/env python3
"""Draw every shipped drill so a person can actually look at them.

Structural tests prove a drill loads; they cannot prove that "Corner far
post" looks like a corner or that a rondo is a ring. That takes eyes, and
575 boards need them in rows: this renders each sport's library to contact
sheets (PNG, 20 boards each) plus one browsable HTML page.

    python3 tools/render_drills.py            # -> build/drill_review/
"""
import json
import math
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from drills.engine import COURT  # noqa: E402  (court aspect per sport)

REPO = pathlib.Path(__file__).resolve().parent.parent
SRC = REPO / "tactics_board" / "assets" / "drills"
OUT = REPO / "build" / "drill_review"

W, H = 240, 360                 # one board tile (canvas is 1000x1500)
PAD = 26                        # room for the title above each tile
COLS, ROWS = 5, 4               # boards per sheet

HOME, AWAY, NEUTRAL = (64, 156, 255), (255, 99, 99), (200, 200, 80)
PITCH = (34, 90, 52)
LINE = (255, 255, 255, 90)


def sx(x): return x * W / 1000.0
def sy(y): return y * H / 1500.0


def court_box(sport):
    aspect, sw, sh = COURT[sport]
    if 1000 / 1500 > aspect:
        ch = 1500 * sh; cw = ch * aspect
    else:
        cw = 1000 * sw; ch = cw / aspect
    return (1000 - cw) / 2, (1500 - ch) / 2, cw, ch


def draw_board(d, sport, tile):
    g = ImageDraw.Draw(tile, "RGBA")
    g.rectangle([0, 0, W, H], fill=PITCH)
    left, top, cw, ch = court_box(sport)
    box = [sx(left), sy(top), sx(left + cw), sy(top + ch)]
    g.rectangle(box, outline=LINE, width=1)
    g.line([box[0], (box[1] + box[3]) / 2, box[2], (box[1] + box[3]) / 2],
           fill=LINE, width=1)

    players = d["board"]["players"]
    # movement paths first, so bodies draw over them
    for p in players:
        prev = p["position"]
        for i, mv in enumerate(p["moves"]):
            g.line([sx(prev[0]), sy(prev[1]), sx(mv[0]), sy(mv[1])],
                   fill=(255, 255, 255, 140), width=1)
            prev = mv
        if p["moves"]:
            mx, my = p["moves"][-1]
            g.ellipse([sx(mx) - 2, sy(my) - 2, sx(mx) + 2, sy(my) + 2],
                      outline=(255, 255, 255, 160))

    for p in players:
        x, y = sx(p["position"][0]), sy(p["position"][1])
        if p.get("sportType") is not None:          # the ball
            g.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(255, 255, 255))
            continue
        if p["markerShape"] != 0:                    # cones, zones, goals
            g.rectangle([x - 3, y - 3, x + 3, y + 3],
                        outline=NEUTRAL, width=1)
            continue
        color = HOME if p["team"] == 0 else AWAY if p["team"] == 1 else NEUTRAL
        r = 6
        g.ellipse([x - r, y - r, x + r, y + r], fill=color)
        label = (p["label"] or "")[:3]
        if label:
            g.text((x, y), label, fill=(0, 0, 0), anchor="mm")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    font = ImageFont.load_default()
    index = ["<html><meta charset='utf-8'><body style='background:#111;"
             "color:#eee;font-family:sans-serif'><h1>Drill review</h1>"]
    for f in sorted(SRC.glob("*.json")):
        sport = f.stem
        drills = json.loads(f.read_text())["drills"]
        sheets = math.ceil(len(drills) / (COLS * ROWS))
        index.append(f"<h2>{sport} — {len(drills)}</h2>")
        for s in range(sheets):
            chunk = drills[s * COLS * ROWS:(s + 1) * COLS * ROWS]
            sheet = Image.new("RGB", (COLS * (W + 8) + 8,
                                      ROWS * (H + PAD + 8) + 8), (17, 17, 17))
            g = ImageDraw.Draw(sheet)
            for i, d in enumerate(chunk):
                cx = 8 + (i % COLS) * (W + 8)
                cy = 8 + (i // COLS) * (H + PAD + 8)
                tile = Image.new("RGB", (W, H))
                draw_board(d, sport, tile)
                sheet.paste(tile, (cx, cy + PAD))
                title = f"{d['id']}  ·  {d['name']['en'][:34]}"
                g.text((cx, cy + 6), title, font=font, fill=(230, 230, 230))
            name = f"{sport}_{s + 1:02d}.png"
            sheet.save(OUT / name)
            index.append(f"<img src='{name}' style='max-width:100%'><br>")
        print(f"{sport}: {sheets} sheet(s)")
    (OUT / "index.html").write_text("\n".join(index) + "</body></html>")
    print(f"\n→ {OUT}/index.html")


if __name__ == "__main__":
    main()
