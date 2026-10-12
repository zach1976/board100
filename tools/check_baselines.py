#!/usr/bin/env python3
"""Net sports: who stands behind a baseline is DRAWN behind it, and on the board.

    python3 tools/check_baselines.py [sport ...]      # all five by default
    python3 tools/check_baselines.py --pack F.json    # one pack file

Judged on every person as DRAWN, not on his point: the app draws a person
upright and centred on his point (FIGURE_PT, 26 x 52 pt on the phone; a
board's figureScale and his own scale shrink it), so his feet are half a
figure below the point and his head half a figure above it. A far-side man
whose point is a hair behind the baseline has his feet on it, or in the
court. At every step:

1. The whole figure is on the canvas.
2. A far-side man whose point is behind the far baseline has his feet
   behind it too. (Near side, the feet are below the point: behind.)
3. The serve, in the sports served from behind the baseline (tennis, beach
   tennis, pickleball; volleyball's server only — reception happens inside
   the court), on the boards that open with one (SERVE_DRILLS; every
   pickleball board, as tools/check_pickleball.py): the server, the ball's
   first holder when his point starts behind a baseline, has his feet
   behind it until he strikes the serve; the receiver, whoever the first
   ball leg goes to, until it arrives. A feed from behind the baseline to
   a pair at the net is not a serve.
4. Badminton is served from inside the service court: on the boards that
   open with a serve, the server and the receiver have their feet in their
   service courts — behind their short service lines — when it is struck.
5. Badminton is played, coached and fed from inside the court: every
   figure on the board — players, feeders, a coach or referee marker — has
   his feet inside the court lines (the outer doubles lines) at every step.
   Rules 2 and 3 are about standing BEHIND a baseline, which badminton
   never asks for: its court is not redrawn.

Positions are measured on the 402x730 phone board against the court the
board was generated for: a board carrying its sport's COURT_REDRAW key is on
the current court (engine.COURT), one without it on the old one.
"""
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from drills.engine import (COURT, COURT_REDRAW, DISPLAY_H, DISPLAY_W,  # noqa: E402
                           FIGURE_PT, MARKER, SPORT_INDEX)

SPORTS = ["tennis", "beachTennis", "volleyball", "badminton", "pickleball"]
# Rule 3: whose serve is struck, and received, from behind the baseline.
SERVE_RULE = {"tennis": ("server", "receiver"),
              "beachTennis": ("server", "receiver"),
              "pickleball": ("server", "receiver"),
              "volleyball": ("server",)}
# The boards that open with a serve, by id.
SERVE_DRILLS = {"tennis": re.compile(r"serve|return|_game_"),
                "beachTennis": re.compile(r"serve|return|_game_"),
                "volleyball": re.compile(r"serve|receive|_game_"),
                "pickleball": re.compile(r""),
                "badminton": re.compile(r"serve")}
SHORT_LINE = 1.98 / 13.4                  # badminton: short service line off the net
MARGIN = 1.0                              # pt of clear air the rules ask for


def court_pt(sport, board) -> tuple[float, float, float, float]:
    """The court rect (left, top, width, height) in the board's own points."""
    aspect, scale_w, scale_h = COURT[sport]
    redraw = COURT_REDRAW.get(sport)
    if redraw and board.get(redraw[0]) != redraw[1]:
        scale_w = scale_h = redraw[2]
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


def check(sport, drill) -> list[str]:
    errs = []
    b = drill["board"]
    if b.get("viewWindow"):
        errs.append("has a view window: figure size under a zoom is not checked")
    w, h = b.get("canvasWidth", DISPLAY_W), b.get("canvasHeight", DISPLAY_H)
    left, top, cw, ch = court_pt(sport, b)
    net = top + ch / 2
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

    # 1 and 2, everyone, every step
    for k in range(steps):
        for p in people:
            x0, y0, x1, y1 = box(p, k)
            if x0 < 0 or y0 < 0 or x1 > w or y1 > h:
                errs.append(f"step {k}: {name(p)} is drawn off the canvas "
                            f"({x0:.0f},{y0:.0f})-({x1:.0f},{y1:.0f})")
            y = at(p, k)[1]
            if y < top and y1 > top - MARGIN:
                errs.append(f"step {k}: {name(p)} stands behind the far baseline "
                            f"with his feet {y1 - top:+.1f} pt from it")
    # 3. the serve
    roles = SERVE_RULE.get(sport, ())
    if not SERVE_DRILLS.get(sport, re.compile(r"^$")).search(drill["id"]):
        roles = ()
    if balls and roles:
        ball = balls[0]
        by_id = {p["id"]: p for p in people}
        server = by_id.get(ball.get("holder"))
        legs = list(zip(ball.get("moveHolders") or [], ball.get("movePhases", [])))
        if server is not None and legs:
            sy = (at(server, 0)[1] - top) / ch
            if sy > 1.0 or sy < 0.0:
                struck = legs[0][1]          # the step the serve is struck
                for role, p, last in (("server", server, struck),
                                      ("receiver", by_id.get(legs[0][0]), struck + 1)):
                    if p is None or role not in roles:
                        continue
                    near = at(p, 0)[1] > net
                    for k in range(last + 1):
                        _, _, _, feet = box(p, k)
                        if near and feet < top + ch + MARGIN:
                            errs.append(f"step {k}: {role} {name(p)} has his feet "
                                        f"{top + ch - feet:.1f} pt inside his baseline")
                        if not near and feet > top - MARGIN:
                            errs.append(f"step {k}: {role} {name(p)} has his feet "
                                        f"{feet - top:.1f} pt inside his baseline")
    # 4. the badminton serve
    if (sport == "badminton" and balls and balls[0].get("movePhases")
            and SERVE_DRILLS["badminton"].search(drill["id"])):
        ball = balls[0]
        by_id = {p["id"]: p for p in people}
        server = by_id.get(ball.get("holder"))
        legs = list(zip(ball.get("moveHolders") or [], ball.get("movePhases", [])))
        receiver = by_id.get(legs[0][0]) if legs else None
        # A shuttle written at a spot, not in a hand, is served by whoever
        # stands over it.
        if server is None and people:
            bx, by = ball["position"]
            server = min(people, key=lambda p: (at(p, 0)[0] - bx) ** 2
                         + (at(p, 0)[1] - by) ** 2)
        # The receiver is who the shuttle goes to, or who stands nearest
        # where it lands on the other side.
        if receiver is None and server is not None:
            land = ball["moves"][0]
            other = [p for p in people
                     if (at(p, 0)[1] > net) != (at(server, 0)[1] > net)]
            if other:
                receiver = min(other, key=lambda p: (at(p, 0)[0] - land[0]) ** 2
                               + (at(p, 0)[1] - land[1]) ** 2)
        struck = ball["movePhases"][0]
        for role, p in (("server", server), ("receiver", receiver)):
            if p is None:
                continue
            near = at(p, 0)[1] > net
            line = net + SHORT_LINE * ch if near else net - SHORT_LINE * ch
            _, _, _, feet = box(p, struck)
            if near and feet < line + MARGIN:
                errs.append(f"step {struck}: {role} {name(p)} has his feet "
                            f"{line - feet:.1f} pt over his short service line")
            if not near and feet > line - MARGIN:
                errs.append(f"step {struck}: {role} {name(p)} has his feet "
                            f"{feet - line:.1f} pt over his short service line")
    # 5. badminton: everybody inside the court
    if sport == "badminton":
        figures = people + [p for p in b["players"]
                            if p.get("sportType") is None
                            and p.get("markerShape") in (MARKER["coach"],
                                                         MARKER["referee"])]
        for k in range(steps):
            for p in figures:
                x0, _, x1, feet = box(p, k)
                x = (x0 + x1) / 2
                if (x < left - MARGIN or x > left + cw + MARGIN
                        or feet < top - MARGIN or feet > top + ch + MARGIN):
                    errs.append(f"step {k}: {name(p)} has his feet outside "
                                f"the court")
    return errs


def check_pack(sport, path) -> int:
    data = json.loads(path.read_text(encoding="utf-8"))
    bad = 0
    for d in data["drills"]:
        for e in check(sport, d):
            print(f"✗ {sport} {d['id']}: {e}")
            bad += 1
    print(f"{len(data['drills'])} {sport} drills checked, {bad} problem(s)")
    return bad


def main() -> int:
    args = sys.argv[1:]
    bad = 0
    if args[:1] == ["--pack"]:
        path = Path(args[1])
        sport = json.loads(path.read_text(encoding="utf-8"))["sport"]
        bad += check_pack(sport, path)
    else:
        for sport in args or SPORTS:
            assert sport in SPORT_INDEX, sport
            bad += check_pack(sport, REPO / f"tactics_board/assets/drills/{sport}.json")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
