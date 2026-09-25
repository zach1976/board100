#!/usr/bin/env python3
"""Where the board turns a player badly — read from what the app itself says.

tool/facing_dump.dart runs the real boardHeading() over every drill and
writes tools/facing_headings.json: per beat, where each player stands, where
the ball is and which way the rule turns them, all in the screen points the
phone draws in. This judges those numbers. Nothing here re-implements the
rule, because a Python copy of it was wrong at every 22.5° boundary — the
board file's units are not scaled evenly onto the phone.

What it looks for, per player per beat:

  back-to-ball   standing still, not holding the ball, and turned more than
                 100° away from it. This is the C defect: a winger whose
                 check-away run is two beats off used to face up the pitch
                 from the first frame while the ball was still at the other
                 end. Running away from the ball is not this — that is a
                 player making a run, and it is listed separately.
  spin           a turn of 135° or more at a beat in which they did not
                 move: the rule changed its mind about what they are doing.
  no cue         the board says nothing about them at all and the token
                 falls back to the team's default facing.

    python3 tools/facing_audit.py            → tools/facing_audit.json + summary
"""
import json, math, sys
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / 'tools/facing_headings.json'
# The reach the board calls "this is his ball": the generator places a
# carried ball 24 screen points from its holder.
HOLD = 24.0 * 1.4
NAMES = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']
BACK = math.radians(100)
SPIN = math.radians(135)


def cell(h):
    return NAMES[round(h / (math.pi / 4)) % 8]


def gap(a, b):
    """The smaller angle between two headings, always 0..pi."""
    d = abs(a - b) % (2 * math.pi)
    return min(d, 2 * math.pi - d)


def toward(at, b):
    """The heading that looks from a player at the ball."""
    return None if b is None else math.atan2(b[0] - at[0], -(b[1] - at[1]))


def doing(p, dr, st):
    """What the rule has this player doing at beat st, read back off the
    numbers: the board hands out a heading, not a reason, and the reason is
    what tells a 180° turn to follow a ball from a 180° turn for no reason."""
    h, at, b = p['h'][st], p['at'][st], dr['ball'][st]
    if h is None:
        return 'no cue'
    tb = toward(at, b)
    if tb is None:
        return 'no ball'
    holding = math.hypot(b[0] - at[0], b[1] - at[1]) < HOLD
    if gap(h, tb) < math.radians(25):
        return 'has the ball' if holding else 'watching the ball'
    return 'playing it away' if holding else 'facing their run'


def why_spin(p, dr, st):
    """Why a standing player turned right round between two beats."""
    b, bp, at = dr['ball'][st], dr['ball'][st - 1], p['at'][st]
    if b is not None and bp is not None:
        a1, a2 = toward(at, bp), toward(at, b)
        if a1 is not None and a2 is not None and gap(a1, a2) >= math.radians(100):
            return 'the ball went past them'
    was, now = doing(p, dr, st - 1), doing(p, dr, st)
    if was == now == 'playing it away':
        return 'they are playing the ball the other way'
    return f'{was} → {now}'


def audit_drill(dr):
    steps, ball = dr['steps'], dr['ball']
    back, spins, runs_away, nocue = [], [], 0, 0
    rows = []
    for p in dr['players']:
        seq = []
        for s in range(steps + 1):
            h = p['h'][s]
            seq.append(cell(h) if h is not None else '-')
            if h is None:
                nocue += 1
                continue
            here = p['at'][s]
            moved = s > 0 and p['at'][s - 1] != here
            moves_next = s < steps and p['at'][s + 1] != here
            if s > 0 and p['h'][s - 1] is not None and not moved:
                if gap(h, p['h'][s - 1]) >= SPIN:
                    spins.append([p['label'], s, cell(p['h'][s - 1]), cell(h),
                                  why_spin(p, dr, s)])
            b = ball[s]
            if b is None:
                continue
            d = math.hypot(b[0] - here[0], b[1] - here[1])
            if d < HOLD:
                continue  # his ball: he is passing it, not ignoring it
            to_ball = math.atan2(b[0] - here[0], -(b[1] - here[1]))
            if gap(h, to_ball) > BACK:
                if moves_next:
                    runs_away += 1  # making a run: away from the ball on purpose
                else:
                    back.append([p['label'], s, cell(h), cell(to_ball), round(d)])
        rows.append([p['label'], seq])
    return dict(id=dr['id'], name=dr['name'], steps=steps,
                players=len(dr['players']), back=back, spins=spins,
                runs_away=runs_away, nocue=nocue, rows=rows)


def main():
    if not SRC.exists():
        sys.exit('no tools/facing_headings.json — run:\n'
                 '  cd tactics_board && flutter test tool/facing_dump.dart')
    data = json.loads(SRC.read_text())
    out = {s: [audit_drill(d) for d in v] for s, v in data.items()}
    (REPO / 'tools/facing_audit.json').write_text(
        json.dumps(out, ensure_ascii=False, indent=1))

    drills = sum(len(v) for v in out.values())
    people = sum(d['players'] for v in out.values() for d in v)
    beats = sum(d['players'] * (d['steps'] + 1) for v in out.values() for d in v)
    bad = [(s, d) for s, v in out.items() for d in v if d['back']]
    spun = [(s, d) for s, v in out.items() for d in v if d['spins']]
    print(f'{drills} drills, {people} players, {beats} player-beats')
    print(f'  back to the ball while standing still: '
          f'{sum(len(d["back"]) for _, d in bad)} beats in {len(bad)} drills')
    print(f'  running away from the ball (by design): '
          f'{sum(d["runs_away"] for v in out.values() for d in v)}')
    print(f'  turns of 135°+ on the spot: '
          f'{sum(len(d["spins"]) for _, d in spun)} in {len(spun)} drills')
    print(f'  no cue at all: {sum(d["nocue"] for v in out.values() for d in v)}')
    by_sport = Counter(s for s, d in bad for _ in d['back'])
    if by_sport:
        print('  worst sports:', dict(by_sport.most_common(6)))
    for s, d in sorted(bad, key=lambda x: -len(x[1]['back']))[:12]:
        w = '; '.join(f'{l} beat {st} faces {a}, ball {b} ({g}pt)'
                      for l, st, a, b, g in d['back'][:3])
        print(f'  {s}/{d["id"]}: {w}')
    why = Counter(w for v in out.values() for d in v for *_, w in d['spins'])
    print('  why they turn:')
    for k, n in why.most_common():
        print(f'    {n:4}  {k}')


if __name__ == '__main__':
    main()
