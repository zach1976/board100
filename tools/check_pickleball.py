#!/usr/bin/env python3
"""Pickleball rules the generic audit cannot know, checked on the shipped JSON.

    python3 tools/check_pickleball.py [pack.json]   # exit 1 and a list on any failure

Judged on every person as DRAWN, not on his point: the app draws a person
upright and centred on his point (FIGURE_PT, 26 x 52 pt on the phone; a
tight board's figureScale shrinks it), so his feet are half a figure below
the point and his head half a figure above it. At every step:

1. Nobody is drawn in a kitchen. Near side: his head is below the near
   kitchen line. Far side: his feet are above the far one. (Someone wholly
   outside a sideline — the Ernie, around the post — is not in it.)
2. The server and the receiver of a serve stand with their feet behind
   their own baseline, from the set-up until the return is struck. The
   server is the ball's first holder when his point starts behind a
   baseline (a rally fed from inside the court is not a serve); the
   receiver is whoever the first ball leg goes to.
3. The whole figure is on the canvas.

Positions are measured on the 402x730 phone board against the court the
board was generated for: "pbCourt": 2 is the current court (engine.COURT),
a board without it was drawn on the old 0.88 court.
"""
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from drills.engine import COURT, DISPLAY_H, DISPLAY_W, FIGURE_PT  # noqa: E402

COURT_W, COURT_L = 6.1, 13.41
KITCHEN_FAR = 0.5 - 2.13 / COURT_L        # fraction of the court, from the top
KITCHEN_NEAR = 0.5 + 2.13 / COURT_L
LEGACY_SCALE = 0.88                       # the court before "pbCourt": 2
MARGIN = 1.0                              # pt of clear air the rules ask for


def court_pt(board) -> tuple[float, float, float, float]:
    """The court rect (left, top, width, height) in the board's own points."""
    aspect, scale_w, scale_h = COURT["pickleball"]
    if board.get("pbCourt") != 2:
        scale_w = scale_h = LEGACY_SCALE
    w = board.get("canvasWidth", DISPLAY_W)
    h = board.get("canvasHeight", DISPLAY_H)
    if w / h > aspect:
        ch = h * scale_h
        cw = ch * aspect
    else:
        cw = w * scale_w
        ch = cw / aspect
    return (w - cw) / 2, (h - ch) / 2, cw, ch


def at(p, step):
    pos = p["position"]
    for dest, ph in zip(p.get("moves", []), p.get("movePhases", [])):
        if ph < step:
            pos = dest
    return pos


def check(drill) -> list[str]:
    errs = []
    b = drill["board"]
    if b.get("viewWindow"):
        errs.append("has a view window: figure size under a zoom is not checked")
    w, h = b.get("canvasWidth", DISPLAY_W), b.get("canvasHeight", DISPLAY_H)
    left, top, cw, ch = court_pt(b)
    k_far, k_near = top + KITCHEN_FAR * ch, top + KITCHEN_NEAR * ch
    s_board = b.get("figureScale", 1.0)
    people = [p for p in b["players"]
              if p.get("sportType") is None and not p.get("markerShape")]
    balls = [p for p in b["players"] if p.get("sportType") is not None]
    steps = 1 + max([ph + 1 for p in b["players"] for ph in p.get("movePhases", [])],
                    default=0)

    def box(p, k):
        s = s_board * p.get("scale", 1.0)
        fw, fh = FIGURE_PT[0] * s, FIGURE_PT[1] * s
        x, y = at(p, k)
        return x - fw / 2, y - fh / 2, x + fw / 2, y + fh / 2

    def name(p):
        return p.get("label") or p["id"]

    # 1 and 3, everyone, every step
    for k in range(steps):
        for p in people:
            x0, y0, x1, y1 = box(p, k)
            if x0 < 0 or y0 < 0 or x1 > w or y1 > h:
                errs.append(f"step {k}: {name(p)} is drawn off the canvas "
                            f"({x0:.0f},{y0:.0f})-({x1:.0f},{y1:.0f})")
            if x1 <= left or x0 >= left + cw:
                continue                     # wholly outside a sideline
            if y1 > k_far - MARGIN and y0 < k_near + MARGIN:
                errs.append(f"step {k}: {name(p)} is drawn in the kitchen "
                            f"(figure y {y0:.0f}..{y1:.0f}, kitchen "
                            f"{k_far:.0f}..{k_near:.0f})")
    # 2. the serve
    if balls:
        ball = balls[0]
        by_id = {p["id"]: p for p in people}
        server = by_id.get(ball.get("holder"))
        legs = list(zip(ball.get("moveHolders") or [], ball.get("movePhases", [])))
        if server is not None and legs:
            sy = (at(server, 0)[1] - top) / ch
            if sy > 1.0 or sy < 0.0:
                receiver = by_id.get(legs[0][0])
                last = legs[0][1] + 1        # the step the serve arrives
                for role, p in (("server", server), ("receiver", receiver)):
                    if p is None:
                        continue
                    near = (at(p, 0)[1] - top) / ch > 0.5
                    for k in range(last + 1):
                        _, _, _, feet = box(p, k)
                        if near and feet < top + ch + MARGIN:
                            errs.append(f"step {k}: {role} {name(p)} has his feet "
                                        f"{top + ch - feet:.0f} pt inside his baseline")
                        if not near and feet > top - MARGIN:
                            errs.append(f"step {k}: {role} {name(p)} has his feet "
                                        f"{feet - top:.0f} pt inside his baseline")
    return errs


def main() -> int:
    path = (Path(sys.argv[1]) if len(sys.argv) > 1
            else REPO / "tactics_board/assets/drills/pickleball.json")
    data = json.loads(path.read_text(encoding="utf-8"))
    bad = 0
    for d in data["drills"]:
        for e in check(d):
            print(f"✗ {d['id']}: {e}")
            bad += 1
    print(f"{len(data['drills'])} pickleball drills checked, {bad} problem(s)")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
