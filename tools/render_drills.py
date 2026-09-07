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


# The lines a drill can be illegal against. Without them the sheet cannot
# show that a hockey shot was taken outside the D, a takraw serve from
# outside the circle or a badminton serve from in front of the short
# service line — every one of which shipped, unseen, through a picture
# review done on a plain rectangle.
#
# Each entry is a list of marks in court-relative coordinates (0..1 across
# and down the playing surface, y=0 being the end the home team attacks):
#   ("hline", y)                     full-width line
#   ("hline", y, x0, x1)             partial-width line
#   ("vline", x)                     full-height line
#   ("arc", cx, cy, r_x)             circle, radius as a fraction of width
#   ("box", x0, y0, x1, y1)          rectangle
MARKINGS = {
    # 91.4 x 55 m. Shooting circle 14.63 m radius off the backline; the
    # 23 m lines; the goal.
    "fieldHockey": [("arc", 0.5, 0.0, 0.266), ("arc", 0.5, 1.0, 0.266),
                    ("hline", 0.2516), ("hline", 0.7484),
                    ("box", 0.4667, 0.0, 0.5333, 0.012)],
    # 40 x 20 m. 6 m goal area, 7 m mark, 9 m free-throw line.
    "handball": [("arc", 0.5, 0.0, 0.30), ("arc", 0.5, 1.0, 0.30),
                 ("arc", 0.5, 0.0, 0.45), ("arc", 0.5, 1.0, 0.45),
                 ("box", 0.425, 0.0, 0.575, 0.0125)],
    # 13.4 x 6.1 m. Short service lines 1.98 m either side of the net,
    # doubles long service line 0.76 m in from the back, centre line.
    "badminton": [("hline", 0.3522), ("hline", 0.6478),
                  ("hline", 0.0567), ("hline", 0.9433),
                  ("vline", 0.5)],
    # 23.77 x 10.97 m singles/doubles. Service lines 6.4 m from the net,
    # singles sidelines 1.37 m in, centre service line.
    "tennis": [("hline", 0.3308), ("hline", 0.6692),
               ("vline", 0.125), ("vline", 0.875),
               ("vline", 0.5, )],
    # 13.41 x 6.10 m. Non-volley zone 2.13 m either side of the net.
    "pickleball": [("hline", 0.3411), ("hline", 0.6589), ("vline", 0.5)],
    # 13.4 x 6.1 m. Service circle r=0.3 m at 2.45 m from the back line,
    # quarter circles r=0.9 m in the corners at the centre line.
    "sepakTakraw": [("arc", 0.5, 0.8172, 0.0492), ("arc", 0.5, 0.1828, 0.0492),
                    ("arc", 0.0, 0.5, 0.1475), ("arc", 1.0, 0.5, 0.1475)],
    # 18 x 9 m. Attack lines 3 m either side of the net.
    "volleyball": [("hline", 0.3333), ("hline", 0.6667)],
    # 25 x 20 m. 2 m and 5 m lines.
    "waterPolo": [("hline", 0.08), ("hline", 0.92),
                  ("hline", 0.20), ("hline", 0.80),
                  ("box", 0.425, 0.0, 0.575, 0.01)],
    # 28 x 15 m. Free-throw lane and line, three-point arc.
    "basketball": [("box", 0.34, 0.0, 0.66, 0.2071),
                   ("box", 0.34, 0.7929, 0.66, 1.0),
                   ("arc", 0.5, 0.0499, 0.475), ("arc", 0.5, 0.9501, 0.475)],
    # Beach tennis and footvolley: the net is the only line that matters,
    # and the halfway line already draws it.
}


def draw_markings(g, sport, left, top, cw, ch):
    """The sport's own lines, so an illegal position is visible."""
    def px(x): return sx(left + x * cw)
    def py(y): return sy(top + y * ch)
    for mark in MARKINGS.get(sport, ()):
        kind = mark[0]
        if kind == "hline":
            x0, x1 = (mark[2], mark[3]) if len(mark) > 3 else (0.0, 1.0)
            g.line([px(x0), py(mark[1]), px(x1), py(mark[1])], fill=LINE, width=1)
        elif kind == "vline":
            g.line([px(mark[1]), py(0), px(mark[1]), py(1)], fill=LINE, width=1)
        elif kind == "arc":
            _, cx, cy, r = mark
            rx, ry = r * cw, r * cw          # a circle on the pitch, not the tile
            g.ellipse([px(cx) - sx(rx), py(cy) - sy(ry),
                       px(cx) + sx(rx), py(cy) + sy(ry)], outline=LINE, width=1)
        elif kind == "box":
            _, x0, y0, x1, y1 = mark
            g.rectangle([px(x0), py(y0), px(x1), py(y1)], outline=LINE, width=1)


def draw_board(d, sport, tile):
    g = ImageDraw.Draw(tile, "RGBA")
    g.rectangle([0, 0, W, H], fill=PITCH)
    left, top, cw, ch = court_box(sport)
    box = [sx(left), sy(top), sx(left + cw), sy(top + ch)]
    g.rectangle(box, outline=LINE, width=1)
    g.line([box[0], (box[1] + box[3]) / 2, box[2], (box[1] + box[3]) / 2],
           fill=LINE, width=1)
    draw_markings(g, sport, left, top, cw, ch)

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
