#!/usr/bin/env python3
"""Rugby law checks on the generated library (tactics_board/assets/drills/rugby.json).

    python3 tools/check_rugby_passes.py          # exit 1 on any failure
    python3 tools/check_rugby_passes.py other.json

Every board in the rugby library attacks UP the page (the try line being
attacked is the top one), whichever side has the ball. So:

1. No forward pass (Law 11). A pass is a ball leg that nobody carries and
   that ends with a team-mate of the man who had it. Its catch point must
   not be nearer the top of the page than its release point — measured on
   the ball as drawn AND on the two players' own spots (the ball is drawn a
   few metres off a man's feet, toward the passer, which can hide a forward
   pass in either direction).
2. A kick has a kicker: a leg that lands nowhere or with the other side
   starts from a ball somebody is holding.
3. A try is grounded: a ball that ends in the in-goal is carried there.

Run after `python3 tools/gen_drills.py --only rugby`.
"""
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LIB = REPO / "tactics_board" / "assets" / "drills" / "rugby.json"

FIELD_W, FIELD_H, IN_GOAL = 70.0, 144.0, 22.0
SCALE = 0.92
# A pass caught this far ahead of its release fails. Zero: flat is the limit.
TOLERANCE_M = 0.0


def _court(board):
    """(left, top, metres per unit) of the pitch on this board's canvas —
    the same fit lib/painters/rugby_court_painter.dart does."""
    w, h = board["canvasWidth"], board["canvasHeight"]
    ratio = FIELD_W / FIELD_H
    if w / h > ratio:
        ch = h * SCALE
        cw = ch * ratio
    else:
        cw = w * SCALE
        ch = cw / ratio
    return (w - cw) / 2, (h - ch) / 2, cw / FIELD_W


def _metres(board):
    left, top, s = _court(board)
    return lambda p: ((p[0] - left) / s, (p[1] - top) / s)


def _at(player, beat):
    """A player's spot once every move up to [beat] has run."""
    at = player["position"]
    for mv, ph in zip(player["moves"], player["movePhases"]):
        if ph <= beat:
            at = mv
    return at


# The place kick at goal is the one ball that flies into the in-goal alone.
KICK_AT_GOAL = {"rg_kick_at_goal"}
# Reach, in metres, within which a man standing over a loose ball is the
# one who plays it next (the 9 at the base of a ruck, the chaser on a kick).
REACH_M = 4.5


def _direction(people, team) -> float:
    """-1 if [team] attacks up the page (toward smaller y), +1 if down: a
    side attacks toward the other one. With nobody to face, up."""
    own = [p["position"][1] for p in people.values() if p["team"] == team]
    other = [p["position"][1] for p in people.values() if p["team"] != team]
    if not own or not other:
        return -1.0
    return -1.0 if sum(other) / len(other) <= sum(own) / len(own) else 1.0


def check_drill(drill) -> list[str]:
    board = drill["board"]
    m = _metres(board)
    people = {p["id"]: p for p in board["players"]
              if p.get("sportType") is None and p["markerShape"] == 0}
    out = []

    def over_the_ball(pt, beat):
        """Whoever stands within reach of a loose ball once [beat] has run."""
        bx, by = m(pt)
        best, who = REACH_M, None
        for p in people.values():
            px, py = m(_at(p, beat))
            d = ((px - bx) ** 2 + (py - by) ** 2) ** 0.5
            if d < best:
                best, who = d, p
        return who

    for ball in (p for p in board["players"] if p.get("sportType") is not None):
        prev = ball["position"]
        prev_h = ball.get("holder")
        prev_beat = -1
        legs = list(zip(ball["moves"], ball["movePhases"]))
        for i, (pt, beat) in enumerate(legs):
            h = ball["moveHolders"][i]
            c = ball["moveCarriers"][i]
            step = f"step {beat + 1}"
            passer = people.get(prev_h)
            if passer is None:
                # a loose ball is played by the man standing over it
                passer = (over_the_ball(prev, prev_beat)
                          or over_the_ball(prev, beat))
            catcher = people.get(h)
            is_pass = (c is None and passer is not None and catcher is not None
                       and catcher is not passer
                       and passer["team"] == catcher["team"])
            if is_pass:
                fwd = _direction(people, passer["team"])
                rel_y, cat_y = m(prev)[1], m(pt)[1]
                ahead = (cat_y - rel_y) * fwd
                if ahead > TOLERANCE_M:
                    out.append(f"{drill['id']} {step}: forward pass "
                               f"{passer['label']}->{catcher['label']}, ball "
                               f"caught {ahead:.1f} m ahead of release")
                p_y = m(_at(passer, prev_beat))[1]
                r_y = m(_at(catcher, beat))[1]
                ahead = (r_y - p_y) * fwd
                if ahead > TOLERANCE_M:
                    out.append(f"{drill['id']} {step}: forward pass "
                               f"{passer['label']}->{catcher['label']}, "
                               f"receiver {ahead:.1f} m ahead of the passer")
            if c is None and passer is None:
                out.append(f"{drill['id']} {step}: the ball is played on with "
                           f"nobody holding it or standing over it")
            last = i == len(legs) - 1
            if (m(pt)[1] < IN_GOAL and c is None
                    and drill["id"] not in KICK_AT_GOAL):
                out.append(f"{drill['id']} {step}: the ball goes into the "
                           f"in-goal with nobody carrying it — a try is "
                           f"grounded, not thrown")
            prev, prev_h, prev_beat = pt, h, beat
    return out


def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else LIB
    drills = json.loads(path.read_text(encoding="utf-8"))["drills"]
    bad = []
    for d in drills:
        if d["id"].startswith("rgfit_"):
            continue
        bad += check_drill(d)
    for line in bad:
        print("✗", line)
    print(f"{len(drills)} rugby drills checked, {len(bad)} failure(s)")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
