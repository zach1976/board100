#!/usr/bin/env python3
"""Every player's facing at every beat of every drill, by the board's rule.

Mirrors boardHeading() in player_icon_widget.dart — a player faces their
next action: the target of a pass they are about to make, the ball if it is
coming to them, down a run they are about to start, else the ball. Reports,
per drill, what the rule could not decide and where it makes a player spin
on the spot: a turn of 135° or more at a beat in which they neither moved
nor touched the ball is a stance the rule chose badly, and those are the
boards to look at first.

    python3 tools/facing_audit.py            → tools/facing_audit.json + summary
"""
import json, math, glob, os, sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / 'tools'))
# Board files are in 1000x1500 board units; the app measures "at the feet"
# in screen points after rescaling the board to the phone. The engine has
# the conversion, so the audit borrows it rather than guessing at it — a
# 34pt radius applied in board units flagged 612 drills as passing to grass.
from drills.engine import _screen_gap, FEET_PT, NET_RALLY_SPORTS, BALL_ALONE_OK
HOLD = FEET_PT * 1.4
NAMES = ['N','NE','E','SE','S','SW','W','NW']

def chain_end(p, step):
    x, y = p['position']
    for m, ph in zip(p['moves'], p['movePhases']):
        if ph < step: x, y = m
    return (x, y)

def dist(a, b): return _screen_gap(a, b)

def direction(a, b):
    dx, dy = b[0]-a[0], b[1]-a[1]
    return None if math.hypot(dx, dy) < 1e-3 else math.atan2(dx, -dy)

def ball_pos(all_, ball, step):
    if not ball['moves'] and ball.get('attachedTo'):
        for x in all_:
            if x['id'] == ball['attachedTo']: return chain_end(x, step)
    return chain_end(ball, step)

def heading(all_, p, step):
    run_phase = run = None
    for i, (m, ph) in enumerate(zip(p['moves'], p['movePhases'])):
        if ph >= step:
            run_phase = ph
            frm = p['position'] if i == 0 else p['moves'][i-1]
            run = direction(frm, m); break
    ball = next((x for x in all_ if x['sportType'] is not None and x['markerShape'] == 0), None)
    if ball is None: return run, 'run' if run is not None else None
    me = chain_end(p, step); bnow = ball_pos(all_, ball, step)
    leg_phase = leg_to = None
    for m, ph in zip(ball['moves'], ball['movePhases']):
        if ph >= step: leg_phase, leg_to = ph, m; break
    if leg_phase is not None and (run_phase is None or leg_phase <= run_phase):
        if dist(me, bnow) < HOLD:
            d = direction(me, leg_to)
            if d is not None: return d, 'pass'
        if dist(chain_end(p, leg_phase + 1), leg_to) < HOLD:
            d = direction(me, bnow)
            if d is not None: return d, 'receive'
    if run is not None: return run, 'run'
    d = direction(me, bnow)
    return (d, 'watch') if d is not None else (None, None)

def snap(h): return round(h / (math.pi/4)) % 8

def leg_problems(all_, people):
    """A pass nobody is making, or nobody is taking. The rule can only turn
    a passer toward his target if it can tell who has the ball, and it
    can only turn a receiver toward the ball if somebody stands where it
    lands. Either gap leaves a player facing the wrong way on the board,
    and it is a defect in the drill, not in the rule."""
    ball = next((x for x in all_ if x['sportType'] is not None and x['markerShape'] == 0), None)
    if ball is None: return []
    out = []
    for m, ph in zip(ball['moves'], ball['movePhases']):
        start = ball_pos(all_, ball, ph)
        passer = [p for p in people if dist(chain_end(p, ph), start) < HOLD]
        taker = [p for p in people if dist(chain_end(p, ph + 1), m) < HOLD]
        # Neither is a facing defect. A ball that starts at nobody's feet is
        # served in from off the board (a coach's toss, a hit from the box);
        # a ball that lands on nobody is aimed at a spot — a shot at the
        # hoop, a serve into the far court, a cross into the box. The rule
        # still turns the striker toward the target and everyone else toward
        # the ball. They are listed so the reader knows why a beat has no
        # passer or no receiver, not counted against the drill.
        if not passer: out.append(('comes from off the board', ph))
        if not taker: out.append(('aimed at a spot, not a player', ph))
    return out


def audit_drill(dr, sport):
    board = dr['board']; all_ = board['players']
    people = [p for p in all_ if p['markerShape'] == 0 and p['sportType'] is None]
    phases = [ph for p in all_ for ph in p['movePhases']]
    steps = (max(phases) + 1) if phases else 0
    rows = []; spins = []; no_cue0 = 0
    legs = leg_problems(all_, people)
    # Over a net the ball lands on the table or the court, not at anyone's
    # feet — every rally would flag. A drill the engine already lists as
    # "ball alone on purpose" (a cross, a serve in flight) is not a defect
    # either. Those stay in the table but are not counted against the drill.
    expected = sport in NET_RALLY_SPORTS or dr['id'] in BALL_ALONE_OK
    for p in people:
        prev = None
        seq = []
        for step in range(steps + 1):
            h, why = heading(all_, p, step)
            if h is None:
                if step == 0: no_cue0 += 1
                seq.append(None); continue
            cell = snap(h); seq.append(cell)
            if prev is not None:
                turn = min((cell - prev) % 8, (prev - cell) % 8)
                moved = chain_end(p, step) != chain_end(p, step - 1)
                if turn >= 3 and not moved and why == 'watch':
                    spins.append((p['label'] or p['id'], step, NAMES[prev], NAMES[cell]))
            prev = cell
        rows.append((p['label'] or p['id'], [NAMES[c] if c is not None else '-' for c in seq]))
    return dict(id=dr['id'], steps=steps, players=len(people), no_cue0=no_cue0,
                spins=spins, legs=legs, expected=expected, rows=rows,
                name=dr.get('name', {}).get('en', dr['id']))

def main():
    out = {}
    for f in sorted(glob.glob(str(REPO / 'tactics_board/assets/drills/*.json'))):
        sport = Path(f).stem
        if sport == 'index': continue
        out[sport] = [audit_drill(dr, sport) for dr in json.load(open(f))['drills']]
    (REPO / 'tools/facing_audit.json').write_text(json.dumps(out, ensure_ascii=False, indent=1))
    drills = sum(len(v) for v in out.values()); players = sum(d['players'] for v in out.values() for d in v)
    nocue = sum(d['no_cue0'] for v in out.values() for d in v)
    spinning = [(s, d) for s, v in out.items() for d in v if d['spins']]
    from collections import Counter
    kinds = Counter(k for v in out.values() for d in v for k, _ in d['legs'])
    print(f'{drills} drills, {players} players; no cue at beat 0: {nocue}; '
          f'drills where somebody turns 135°+ on the spot to follow the ball: {len(spinning)}')
    print('  legs with no passer or no receiver (by design, listed not counted):', dict(kinds))
    for s, d in sorted(spinning, key=lambda x: -len(x[1]['spins']))[:10]:
        print(f'  {s}/{d["id"]}: ' + '; '.join(f'{l} beat {st} {a}→{b}' for l, st, a, b in d['spins'][:4]))

if __name__ == '__main__':
    main()
