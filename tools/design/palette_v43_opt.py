#!/usr/bin/env python3
"""V4.3 optimiser: the fewest, smallest colour changes that give V4.2 real
visual margins (2026-10-15). Stage One only — writes build/v43/solution.json.

Every movable token has a window that keeps it authentic (OKLCH hue,
lightness, chroma) and must stay usable: a brand colour must take a 5:1
button label (on itself or on a fill within 0.05 of it); a semantic text
colour must read at 5:1 on all four light grounds. Simulated annealing then
minimises  changes + distance moved  subject to the brief's minimums, with
the critical pairs pushed towards 0.14.
"""
from __future__ import annotations

import itertools
import json
import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from palette_v41 import cr, dE  # noqa: E402
from sport_palettes import oklch_of, hexof, to_oklab  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
GROUNDS = ['#FFFFFF', '#F6F4EE', '#EEF3F8', '#F3F0E8']
INK = '#16212E'

V42 = {  # id: (primary, secondary, fill or None, fg)
    'volleyball': ('#2C50CC', '#7DB7FF', None, '#FFFFFF'),
    'soccer': ('#268435', '#8BCF67', '#217F30', '#FFFFFF'),
    'basketball': ('#DB631E', '#FFB566', '#E56D28', '#16212E'),
    'fieldHockey': ('#076CA5', '#E3C86C', None, '#FFFFFF'),
    'tennis': ('#C7D93B', '#6E95DD', None, '#16212E'),
    'rugby': ('#B27F6F', '#6FA570', '#B78474', '#16212E'),
    'badminton': ('#087D77', '#D8B688', '#077C76', '#FFFFFF'),
    'tableTennis': ('#604595', '#E15C56', None, '#FFFFFF'),
    'pickleball': ('#1F9E84', '#D7C96E', '#23A288', '#16212E'),
    'baseball': ('#883C66', '#C98E57', None, '#FFFFFF'),
    'handball': ('#8081C8', '#E59B55', '#8889D0', '#16212E'),
    'waterPolo': ('#218EB6', '#5E8FC8', '#176A90', '#FFFFFF'),
    'sepakTakraw': ('#A38B23', '#67A56C', '#A78F27', '#16212E'),
    'beachTennis': ('#E1C79B', '#CFA087', None, '#16212E'),
    'footvolley': ('#AA5026', '#39B9C8', None, '#FFFFFF'),
    'hub': ('#365058', '#B49A6A', None, '#FFFFFF'),
}
SEM42 = {'success': '#10663A', 'information': '#0D4A8E', 'error': '#BB234A',
         'focus': '#4D295C', 'warningIcon': '#D99816', 'warningText': '#795000'}

# Authentic windows: (hue lo, hue hi, L lo, L hi, C lo, C hi). None = fixed.
BRAND_WIN = {
    'volleyball': (255, 270, .44, .56, .15, .21),
    'soccer': (135, 152, .45, .60, .12, .17),
    'basketball': (40, 56, .58, .70, .14, .19),
    'fieldHockey': (232, 252, .44, .56, .10, .15),
    'tennis': None,
    'rugby': (36, 58, .46, .64, .07, .11),
    'badminton': (166, 195, .45, .58, .08, .12),
    'tableTennis': (285, 305, .40, .52, .11, .15),
    'pickleball': (168, 200, .58, .72, .09, .13),
    'baseball': (338, 360, .42, .52, .10, .13),
    'handball': (268, 292, .58, .70, .09, .13),
    'waterPolo': (208, 232, .60, .74, .10, .14),
    'sepakTakraw': (78, 96, .66, .76, .10, .14),
    'beachTennis': None,
    'footvolley': (34, 50, .48, .58, .11, .15),
    'hub': (195, 250, .36, .48, .02, .05),
}
SEM_WIN = {
    'success': (145, 162, .34, .50, .08, .12, 'text'),
    'information': (244, 266, .32, .46, .10, .15, 'text'),
    'error': (4, 26, .44, .56, .15, .20, 'text'),
    'focus': (305, 332, .28, .42, .08, .12, 'ui'),
    'warningIcon': (68, 86, .70, .80, .13, .17, 'none'),
    'warningText': (62, 86, .38, .50, .08, .11, 'text'),
}
CRITICAL = {frozenset(p) for p in [('fieldHockey', 'waterPolo'), ('badminton', 'pickleball'),
                                    ('soccer', 'badminton'), ('basketball', 'rugby'),
                                    ('rugby', 'sepakTakraw')]}
MIN, PREF, HUB_FOCUS = 0.12, 0.14, 0.14


def better_fg(c):
    return max(('#FFFFFF', INK), key=lambda f: cr(f, c))


def button_for(c):
    """(fill, fg) reaching 5:1, with the fill within 0.05 of c; or None."""
    fg = better_fg(c)
    if cr(fg, c) >= 5.0:
        return c, fg
    L, C, h = oklch_of(c)
    step = -0.003 if fg == '#FFFFFF' else 0.003
    fill = c
    for _ in range(60):
        L += step
        fill = hexof(L, C, h)
        if cr(fg, fill) >= 5.0:
            return (fill, fg) if dE(fill, c) <= 0.05 else None
    return None


def grid(win):
    hlo, hhi, llo, lhi, clo, chi = win[:6]
    out = set()
    for h in range(int(hlo), int(hhi) + 1, 2):
        for i in range(int(round((lhi - llo) / 0.01)) + 1):
            L = llo + i * 0.01
            for k in range(4):
                C = clo + (chi - clo) * k / 3
                out.add(hexof(L, C, h % 360))
    return sorted(out)


def candidates():
    cand = {}
    for k, (pa, *_rest) in V42.items():
        opts = [pa]
        if BRAND_WIN[k]:
            for c in grid(BRAND_WIN[k]):
                if c != pa and button_for(c):
                    opts.append(c)
        cand[k] = opts
    for k, w in SEM_WIN.items():
        opts = [SEM42[k]]
        for c in grid(w):
            if c == SEM42[k]:
                continue
            need = {'text': 5.0, 'ui': 3.5, 'none': 0}[w[6]]
            if min(cr(c, g) for g in GROUNDS) >= need:
                opts.append(c)
        cand[k] = opts
    return cand


BRANDS = list(V42)
SEMS = list(SEM42)
TOKENS = BRANDS + SEMS


def pair_rules():
    rules = []  # (a, b, hard_min, pref, weight_pref)
    for a, b in itertools.combinations(BRANDS, 2):
        crit = frozenset((a, b)) in CRITICAL
        rules.append((a, b, MIN, PREF, 60.0 if crit else 0.3))
    for a in BRANDS:
        for s in SEMS:
            hard = HUB_FOCUS if (a == 'hub' and s == 'focus') else MIN
            rules.append((a, s, hard, PREF, 0.3))
    for s, t in itertools.combinations(['success', 'information', 'error', 'focus', 'warningIcon'], 2):
        rules.append((s, t, MIN, PREF, 0.1))
    return rules


def solve(seed=1, iters=400000):
    rnd = random.Random(seed)
    cand = candidates()
    lab = {c: to_oklab(c) for opts in cand.values() for c in opts}
    orig = {k: cand[k][0] for k in TOKENS}
    rules = pair_rules()
    by_tok = {k: [] for k in TOKENS}
    for r in rules:
        by_tok[r[0]].append(r)
        by_tok[r[1]].append(r)

    def d(a, b):
        return math.dist(lab[a], lab[b])

    def rule_cost(r, cur):
        a, b, hard, pref, w = r
        x = d(cur[a], cur[b])
        c = 0.0
        if x < hard:
            c += 1000 * (hard - x) + 50
        if x < pref:
            c += w * (pref - x) * 10
        return c

    def tok_cost(k, cur):
        if cur[k] == orig[k]:
            return 0.0
        return 1.0 + 12 * d(cur[k], orig[k])

    cur = dict(orig)
    total = sum(rule_cost(r, cur) for r in rules) + sum(tok_cost(k, cur) for k in TOKENS)
    best, best_cost = dict(cur), total
    T0 = 5.0
    movable = [k for k in TOKENS if len(cand[k]) > 1]
    for i in range(iters):
        T = T0 * (1 - i / iters) + 0.01
        k = rnd.choice(movable)
        new = orig[k] if rnd.random() < 0.15 else rnd.choice(cand[k])
        if new == cur[k]:
            continue
        old = cur[k]
        before = sum(rule_cost(r, cur) for r in by_tok[k]) + tok_cost(k, cur)
        cur[k] = new
        after = sum(rule_cost(r, cur) for r in by_tok[k]) + tok_cost(k, cur)
        delta = after - before
        if delta <= 0 or rnd.random() < math.exp(-delta / T):
            total += delta
            if total < best_cost - 1e-9:
                best, best_cost = dict(cur), total
        else:
            cur[k] = old
    return best, best_cost


ORIG = {**{k: v[0] for k, v in V42.items()}, **SEM42}


def feasible(cur, rules):
    """Every hard minimum met, and every critical pair at the preferred 0.14."""
    for a, b, hard, pref, w in rules:
        x = dE(cur[a], cur[b])
        if x < hard:
            return False
        if frozenset((a, b)) in CRITICAL and x < PREF:
            return False
    return True


def polish(sol, cand, rules):
    """Undo what need not change, then pull each change back towards its
    original as far as the constraints allow. Deterministic."""
    cur = dict(sol)
    if not feasible(cur, rules):
        return None
    improved = True
    while improved:
        improved = False
        changed = sorted((k for k in TOKENS if cur[k] != ORIG[k]), key=lambda k: dE(cur[k], ORIG[k]))
        for k in changed:
            keep = cur[k]
            cur[k] = ORIG[k]
            if feasible(cur, rules):
                improved = True
            else:
                cur[k] = keep
        for k in [k for k in TOKENS if cur[k] != ORIG[k]]:
            keep = cur[k]
            for c in sorted(cand[k], key=lambda c: dE(c, ORIG[k])):
                if dE(c, ORIG[k]) >= dE(keep, ORIG[k]) - 1e-9:
                    break
                cur[k] = c
                if feasible(cur, rules):
                    improved = True
                    break
                cur[k] = keep
    return cur


def main():
    cand = candidates()
    rules = pair_rules()
    results = []
    for seed in range(1, 25):
        sol, cost = solve(seed)
        pol = polish(sol, cand, rules)
        if pol is None:
            print(f'seed {seed}: infeasible'); continue
        changed = {k: v for k, v in pol.items() if v != ORIG[k]}
        move = sum(dE(v, ORIG[k]) for k, v in changed.items())
        results.append((len(changed), move, seed, pol, changed))
        print(f'seed {seed}: {len(changed)} changes, total move {move:.3f}')
    results.sort(key=lambda r: (r[0], r[1]))
    n, cost, seed, sol, changed = results[0]
    out = REPO / 'build/v43'
    out.mkdir(parents=True, exist_ok=True)
    (out / 'solution.json').write_text(json.dumps({'seed': seed, 'cost': cost, 'tokens': sol, 'changed': changed}, indent=2) + '\n')
    print('best', seed, round(cost, 2), changed)


if __name__ == '__main__':
    main()
