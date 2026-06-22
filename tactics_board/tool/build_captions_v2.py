#!/usr/bin/env python3
"""Build aso/captions_v2.json — per-sport EN headlines for the v2 screenshots.

Each entry: sport -> locale -> [ [white, green, subtitle] x6 ].
This pass fills en-US only; translations are added later per locale.
"""
import json
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "aso" / "captions_v2.json"

# Shared shots 2,3,6 (same across all sports).
S2 = ["PLACE", "EVERY PLAYER", "Build formations with clear numbered markers"]
S3 = ["BUILD", "A TIMELINE", "Organize each move in a clear sequence"]
S6 = ["ANIMATE", "THE DRILL", "Play each step and visualize movement paths"]

DRAG = "Drag players and draw tactics in seconds"

# Per-sport: shot1, shot4, shot5 (the variable trio). 2/3/6 inherited.
SPORTS = {
    # ── net / racket sports ──
    "badminton":   [["PLAN","EVERY RALLY",DRAG], ["ADD","MATCH SETUPS","Singles, doubles, mixed and custom markers"], ["SHOW","SHOTS CLEARLY","Map routes, targets and rally patterns"]],
    "tableTennis": [["PLAN","EVERY RALLY",DRAG], ["ADD","MATCH SETUPS","Singles, doubles and custom markers"],        ["SHOW","SHOTS CLEARLY","Map serves, spins and rally patterns"]],
    "tennis":      [["PLAN","EVERY RALLY",DRAG], ["ADD","MATCH SETUPS","Singles, doubles and custom markers"],        ["SHOW","SHOTS CLEARLY","Map serves, returns and rally patterns"]],
    "pickleball":  [["PLAN","EVERY RALLY",DRAG], ["ADD","MATCH SETUPS","Singles, doubles and custom markers"],        ["SHOW","SHOTS CLEARLY","Map dinks, drives and rally patterns"]],
    "beachTennis": [["PLAN","EVERY RALLY",DRAG], ["ADD","MATCH SETUPS","Singles, doubles and custom markers"],        ["SHOW","SHOTS CLEARLY","Map serves, volleys and rally patterns"]],
    "sepakTakraw": [["PLAN","EVERY RALLY",DRAG], ["ADD","MATCH SETUPS","Regu, doubles and custom markers"],           ["SHOW","SHOTS CLEARLY","Map serves, spikes and rally patterns"]],
    "footvolley":  [["PLAN","EVERY RALLY",DRAG], ["ADD","MATCH SETUPS","Singles, doubles and custom markers"],        ["SHOW","SHOTS CLEARLY","Map serves, touches and rally patterns"]],
    "volleyball":  [["PLAN","EVERY RALLY",DRAG], ["ADD","ANY ROTATION","6v6, beach and custom markers"],              ["SHOW","ATTACKS CLEARLY","Map rotations, hits and coverage"]],

    # ── team / invasion sports ──
    "soccer":      [["PLAN","EVERY ATTACK",DRAG],["ADD","ANY FORMATION","11v11, futsal and custom markers"],          ["SHOW","RUNS CLEARLY","Map runs, passes and pressing"]],
    "basketball":  [["PLAN","EVERY PLAY",DRAG],  ["ADD","ANY LINEUP","5v5, half-court and custom markers"],           ["SHOW","PLAYS CLEARLY","Map cuts, screens and drives"]],
    "handball":    [["PLAN","EVERY ATTACK",DRAG],["ADD","ANY LINEUP","Full teams, subs and custom markers"],          ["SHOW","RUNS CLEARLY","Map runs, screens and fast breaks"]],
    "waterPolo":   [["PLAN","EVERY ATTACK",DRAG],["ADD","ANY LINEUP","Full teams, subs and custom markers"],          ["SHOW","PLAYS CLEARLY","Map swims, passes and man-up"]],
    "rugby":       [["PLAN","EVERY PHASE",DRAG], ["ADD","ANY LINEUP","Full teams, subs and custom markers"],          ["SHOW","RUNS CLEARLY","Map runs, rucks and phase play"]],
    "fieldHockey": [["PLAN","EVERY ATTACK",DRAG],["ADD","ANY LINEUP","Full teams, subs and custom markers"],          ["SHOW","RUNS CLEARLY","Map runs, passes and press"]],
    "baseball":    [["PLAN","EVERY PLAY",DRAG],  ["ADD","THE LINEUP","Batters, fielders and custom markers"],         ["SHOW","PLAYS CLEARLY","Map throws, runs and defensive shifts"]],

    # ── multi-sport flagship ──
    "tactics_board":[["PLAN","EVERY SPORT",DRAG],["ADD","ANY MATCHUP","Teams, balls and custom markers"],            ["SHOW","PLAYS CLEARLY","Map runs, routes and patterns"]],
}


def build():
    data = {}
    for sport, (s1, s4, s5) in SPORTS.items():
        shots = [s1, S2, S3, s4, s5, S6]
        data[sport] = {"en-US": shots}
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2))
    print(f"wrote {OUT}  ({len(data)} sports)")
    # review table
    print("\n# EN review table (white | green | subtitle)\n")
    for sport, d in data.items():
        print(f"## {sport}")
        for i, (w, g, sub) in enumerate(d["en-US"], 1):
            print(f"  {i}. {w} {g}  —  {sub}")
        print()


if __name__ == "__main__":
    build()
