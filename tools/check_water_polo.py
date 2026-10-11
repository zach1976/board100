#!/usr/bin/env python3
"""Water polo rules the generic audit cannot know, checked on the shipped JSON.

    python3 tools/check_water_polo.py      # exit 1 and a list on any failure

1. Two-metre rule: at no step is an attacker who does not have the ball
   inside the opponents' 2 m line while the ball is further out than he is.
2. Every shot ends in the goal mouth: a ball leg that ends near the goal
   with nobody holding it must stop past the goal line, between the posts.
3. Nobody follows his shot: the man who releases a shot does not swim on
   the same beat (that is how shooters used to end up on the keeper).

Positions are converted to metres from the attacked goal line with the same
court rect the generator uses (402x730 display frame, 20 x 30 m pool).
"""
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from drills.engine import (CANVAS_H, CANVAS_W, DISPLAY_H, DISPLAY_W,  # noqa: E402
                           court_rect)

POOL_W, POOL_L = 20.0, 30.0
MOUTH_X = (8.5, 11.5)


def to_m(pt):
    left, top, w, h = court_rect("waterPolo")
    sx, sy = DISPLAY_W / CANVAS_W, DISPLAY_H / CANVAS_H
    return ((pt[0] - left * sx) / (w * sx) * POOL_W,
            (pt[1] - top * sy) / (h * sy) * POOL_L)


def at(p, step):
    pos = p["position"]
    for dest, ph in zip(p.get("moves", []), p.get("movePhases", [])):
        if ph < step:
            pos = dest
    return pos


def holder_at(ball, step):
    who = ball.get("holder")
    for h, ph in zip(ball.get("moveHolders") or [], ball.get("movePhases", [])):
        if ph < step:
            who = h
    return who


def check(drill) -> list[str]:
    errs = []
    b = drill["board"]
    people = [p for p in b["players"]
              if p.get("sportType") is None and not p.get("markerShape")]
    balls = [p for p in b["players"] if p.get("sportType") is not None]
    if not balls:
        return errs
    ball = balls[0]
    steps = 1 + max([ph + 1 for p in b["players"] for ph in p.get("movePhases", [])],
                    default=0)
    # 1. two-metre rule, home side attacking the top goal
    for k in range(steps):
        bx, by = to_m(at(ball, k))
        if by < 0:
            continue           # the ball is in the goal: the play is over
        holder = holder_at(ball, k)
        for p in people:
            if p["team"] != 0 or p.get("role") == "GK" or p["id"] == holder:
                continue
            x, y = to_m(at(p, k))
            if y < 2.0 and by > y + 0.05:
                errs.append(f"step {k}: {p['label'] or p['id']} is {y:.1f} m "
                            f"from the goal line, ahead of the ball at {by:.1f} m")
    # 2/3. shots
    prev_holder = ball.get("holder")
    for i, (mv, ph) in enumerate(zip(ball["moves"], ball["movePhases"])):
        held = (ball.get("moveHolders") or [None] * len(ball["moves"]))[i]
        x, y = to_m(mv)
        if held is None and y < 2.6:
            if not (MOUTH_X[0] < x < MOUTH_X[1] and -0.7 < y < 0.0):
                errs.append(f"shot on beat {ph + 1} ends at ({x:.1f}, {y:.1f}) m, "
                            f"not inside the goal mouth")
            shooter = next((p for p in people if p["id"] == prev_holder), None)
            if shooter is not None:
                a, c = to_m(at(shooter, ph)), to_m(at(shooter, ph + 1))
                if ((a[0] - c[0]) ** 2 + (a[1] - c[1]) ** 2) ** 0.5 > 0.5:
                    errs.append(f"{shooter['label']} swims after his own shot "
                                f"on beat {ph + 1}")
        if held is not None:
            prev_holder = held
    return errs


def main() -> int:
    data = json.loads((REPO / "tactics_board/assets/drills/waterPolo.json")
                      .read_text(encoding="utf-8"))
    bad = 0
    for d in data["drills"]:
        for e in check(d):
            print(f"✗ {d['id']}: {e}")
            bad += 1
    print(f"{len(data['drills'])} water polo drills checked, {bad} problem(s)")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
