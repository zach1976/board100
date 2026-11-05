#!/usr/bin/env python3
"""Colour system V4.1 — Stage One: proposal and validation only (2026-10-15).

Takes the V4.1 brief's exact values for sixteen apps (fifteen sports and the
Hub), derives the accessible semantic tokens, and audits everything:
WCAG 2.1 contrast (sRGB-linearised, truncated never rounded up), PASS /
BORDERLINE / FAIL against the brief's internal targets, OKLab distances
between every pair and against the semantic colours, tactical annotations
against each sport's real court, and — for every high-risk collision —
candidate replacements with their measured effect. It changes no production
file. Outputs:

    build/v41/palette_v41.json
    build/v41/board.html           the 4×4 comparison board
    build/v41/report.md            all the reports, corrections, checklist
    (copies in reports/配色V4.1_*)
"""
from __future__ import annotations

import itertools
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from sport_palettes import oklch_of, hexof, to_oklab  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / 'build/v41'

# ── maths ──────────────────────────────────────────────────────────────────
def _lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def lum(hx):
    r, g, b = (int(hx[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return 0.2126 * _lin(r) + 0.7152 * _lin(g) + 0.0722 * _lin(b)


def cr(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def f2(x):
    return f'{math.floor(x * 100) / 100:.2f}'


def dE(a, b):
    return math.dist(to_oklab(a), to_oklab(b))


def mix(fg, bg, a):
    f = [int(fg[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(bg[i:i + 2], 16) for i in (1, 3, 5)]
    return '#%02X%02X%02X' % tuple(round(x * a + y * (1 - a)) for x, y in zip(f, b))


# ── the brief ──────────────────────────────────────────────────────────────
SHARED = {
    'pageBackground': '#F3F0E8', 'appBackground': '#F6F4EE', 'surface': '#FFFFFF',
    'elevatedSurface': '#EEF3F8', 'secondarySurface': '#F7F9FC',
    'textPrimary': '#16212E', 'textSecondary': '#526071', 'textTertiary': '#586577',
    'decorativeBorder': '#D8E0E8', 'inputBorder': '#778494', 'disabledSurface': '#C8D0D9',
}
SEMANTIC = {'success': '#147D50', 'warning': '#8B5900', 'error': '#B83240',
            'information': '#155E9E', 'focus': '#4A345C'}
GROUNDS = {'white': '#FFFFFF', 'app': '#F6F4EE', 'elevated': '#EEF3F8', 'page': '#F3F0E8'}
INK = SHARED['textPrimary']

# key, 中文, English, primary, secondary, candidate button fg
APPS = [
    ('volleyball', '排球', 'Volleyball', '#2852B5', '#7DB7FF', '#FFFFFF'),
    ('soccer', '足球', 'Soccer', '#257D42', '#8BCF67', '#FFFFFF'),
    ('basketball', '篮球', 'Basketball', '#D06B25', '#FFB566', '#16212E'),
    ('fieldHockey', '曲棍球', 'Field Hockey', '#0873A4', '#E3C86C', '#FFFFFF'),
    ('tennis', '网球', 'Tennis', '#C7D93B', '#6E95DD', '#16212E'),
    ('rugby', '橄榄球', 'Rugby', '#B98056', '#6FA570', '#16212E'),
    ('badminton', '羽毛球', 'Badminton', '#087E78', '#D8B688', '#FFFFFF'),
    ('tableTennis', '乒乓球', 'Table Tennis', '#594695', '#E15C56', '#FFFFFF'),
    ('pickleball', '匹克球', 'Pickleball', '#159C85', '#D7C96E', '#16212E'),
    ('baseball', '棒球', 'Baseball', '#883C66', '#C98E57', '#FFFFFF'),
    ('handball', '手球', 'Handball', '#7385C3', '#E59B55', '#16212E'),
    ('waterPolo', '水球', 'Water Polo', '#227AA7', '#5E8FC8', '#FFFFFF'),
    ('sepakTakraw', '藤球', 'Sepak Takraw', '#AC862C', '#67A56C', '#16212E'),
    ('beachTennis', '沙滩网球', 'Beach Tennis', '#E1C79B', '#CFA087', '#16212E'),
    ('footvolley', '足排球', 'Footvolley', '#A64E29', '#39B9C8', '#FFFFFF'),
    ('hub', '战术板合集', 'Sports Tactics Hub', '#344D63', '#B49A6A', '#FFFFFF'),
]

# Real court surfaces (SportType.courtSurfaces.first in the app) and the
# app's tactical annotation colours, which are shared by every sport.
COURTS = {'volleyball': '#F57F17', 'soccer': '#2D8A2D', 'basketball': '#D9A867',
          'fieldHockey': '#1976D2', 'tennis': '#2A65A5', 'rugby': '#2E7D32',
          'badminton': '#2E7D4F', 'tableTennis': '#1D4F91', 'pickleball': '#1769B4',
          'baseball': '#2E7D32', 'handball': '#1565C0', 'waterPolo': '#0277BD',
          'sepakTakraw': '#1565C0', 'beachTennis': '#EAC478', 'footvolley': '#E5B880'}
ANNOTATIONS = {'teamA': '#4D8FE8', 'teamB': '#E86452', 'selectedPlayer': '#FFFFFF',
               'movementLine': '#E3A348', 'passLine': '#35C7C2', 'ballPath': '#FFFFFF',
               'highlightZone': '#FFFFFF', 'selectionOutline': '#FFFFFF'}
EDGE = '#000000'   # lines are stroked with a 28–40 % black edge in the painter

TEXT_MIN, TEXT_SAFE = 4.5, 5.0
UI_MIN, UI_SAFE = 3.0, 3.5


def grade(v, need, safe):
    if v < need:
        return 'FAIL'
    return 'BORDERLINE' if v < safe else 'PASS'


def darken_to(hx, need, grounds):
    def ok(c):
        return min(cr(c, g) for g in grounds) >= need
    if ok(hx):
        return hx
    L, C, h = oklch_of(hx)
    while L > 0.15:
        L -= 0.004
        c = hexof(L, C, h)
        if ok(c):
            return c
    return INK


def derive(app):
    key, zh, en, pa, sa, fg = app
    g = list(GROUNDS.values())
    soft = mix(pa, '#FFFFFF', 0.12)
    return {
        'id': key, 'zh': zh, 'en': en,
        'background': SHARED['appBackground'], 'surface': SHARED['surface'],
        'elevatedSurface': SHARED['elevatedSurface'],
        'primaryAccent': pa, 'secondaryAccent': sa,
        'primaryButtonForeground': fg,
        # Derived to the internal targets, not the bare minimums.
        'accentText': darken_to(pa, TEXT_SAFE, g + [soft]),
        'selectedStroke': darken_to(pa, UI_SAFE, g),
        'secondaryAccentText': darken_to(sa, TEXT_SAFE, g),
        'secondaryAccentStroke': darken_to(sa, UI_SAFE, g),
        'accentSoftBackground': soft,
    }


def audit(p):
    rows = []
    def add(name, v, need, safe):
        rows.append((name, v, grade(v, need, safe)))
    # Reference only: a primary is read against one of these, never both —
    # the button foreground row is the test that counts.
    rows.append(('primary vs white', cr(p['primaryAccent'], '#FFFFFF'), 'INFO'))
    rows.append(('primary vs dark text', cr(p['primaryAccent'], INK), 'INFO'))
    add('button text', cr(p['primaryButtonForeground'], p['primaryAccent']), TEXT_MIN, TEXT_SAFE)
    for k in ('accentText', 'secondaryAccentText'):
        add(k, min(cr(p[k], g) for g in GROUNDS.values()), TEXT_MIN, TEXT_SAFE)
    add('accentText on soft bg', cr(p['accentText'], p['accentSoftBackground']), TEXT_MIN, TEXT_SAFE)
    for k in ('selectedStroke', 'secondaryAccentStroke'):
        add(k, min(cr(p[k], g) for g in GROUNDS.values()), UI_MIN, UI_SAFE)
    return rows


def better_fg(pa):
    """The foreground that reads best on pa."""
    return max(('#FFFFFF', INK), key=lambda f: cr(f, pa))


# ── candidates for a collision ─────────────────────────────────────────────
def candidates(hx, others, keep_fg, n=2, sem=(), hue_span=30, sport_gap=0.10, sem_gap=0.08):
    """Colours in the same family (hue ±hue_span°, lightness ±0.15, chroma
    ×0.75–1.25) that clear every other app by ≥ sport_gap and every
    semantic colour by ≥ sem_gap, with a ≥ 5:1 button label. Ranked by how
    little they move, so the sport keeps its identity."""
    L, C, h = oklch_of(hx)
    found = []
    for dh in range(-hue_span, hue_span + 1, 3):
        for dl in (-0.15, -0.12, -0.09, -0.06, -0.03, 0, 0.03, 0.06, 0.09, 0.12):
          for k in (0.75, 0.9, 1.0, 1.1, 1.25):
            cand = hexof(L + dl, C * k, (h + dh) % 360)
            if cand == hx:
                continue
            m = min(dE(cand, o) for o in others)
            ms = min((dE(cand, o) for o in sem), default=9)
            fg = better_fg(cand)
            if m >= sport_gap and ms >= sem_gap and cr(fg, cand) >= TEXT_SAFE:
                found.append((dE(cand, hx), cand, min(m, ms), fg))
    found.sort()
    out, seen = [], []
    for move, cand, m, fg in found:
        if all(dE(cand, s) > 0.03 for s in seen):
            out.append((cand, move, m, fg))
            seen.append(cand)
        if len(out) == n:
            break
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    pals = [derive(a) for a in APPS]
    by = {p['id']: p for p in pals}
    md = []
    W = md.append

    # 1. WCAG report
    W('# 配色 V4.1 第一阶段：验证报告\n')
    W('计算方法：WCAG 2.1 相对亮度（含 sRGB 线性化），比值截断到两位小数，不向上取整。'
      '判定：文字 ≥4.5 为达标、<5.0 记为 BORDERLINE；非文字 ≥3.0 达标、<3.5 记为 BORDERLINE。'
      '测试底色：#FFFFFF、#F6F4EE、#EEF3F8、#F3F0E8，派生色取四者中最差的一个。\n')
    W('## 1. 各 app 对比度\n')
    W('| App | 主色/白 | 主色/深字 | 按钮文字 | accentText | accentText/浅色底 | selectedStroke | 2nd text | 2nd stroke |')
    W('|---|---|---|---|---|---|---|---|---|')
    fails, borders = [], []
    for p in pals:
        r = audit(p)
        cells = []
        for name, v, gr in r:
            cells.append(f'{f2(v)} {gr}')
            if gr == 'FAIL':
                fails.append(f"{p['zh']} · {name} {f2(v)}")
            elif gr == 'BORDERLINE':
                borders.append(f"{p['zh']} · {name} {f2(v)}")
        order = [0, 1, 2, 3, 5, 6, 4, 7]
        W(f"| {p['zh']} | " + ' | '.join(cells[i] for i in order) + ' |')

    W('\n## 2. 共用色与语义色\n')
    W('| 令牌 | 白 | 应用底 | 浮层 | 页面画布 | 要求 |')
    W('|---|---|---|---|---|---|')
    def shared_row(name, hx, need, safe, label):
        vals = [cr(hx, g) for g in GROUNDS.values()]
        gr = grade(min(vals), need, safe)
        W(f'| {name} {hx} | ' + ' | '.join(f2(v) for v in vals) + f' | {label} {gr} |')
        if gr == 'FAIL':
            fails.append(f'{name} {f2(min(vals))}')
        elif gr == 'BORDERLINE':
            borders.append(f'{name} {f2(min(vals))}')
    for k in ('textPrimary', 'textSecondary', 'textTertiary'):
        shared_row(k, SHARED[k], TEXT_MIN, TEXT_SAFE, '文字 4.5')
    shared_row('inputBorder', SHARED['inputBorder'], UI_MIN, UI_SAFE, '非文字 3.0')
    for k, v in SEMANTIC.items():
        shared_row(k, v, TEXT_MIN, TEXT_SAFE, '作文字 4.5')
    sec_ter = cr(SHARED['textSecondary'], '#FFFFFF') / cr(SHARED['textTertiary'], '#FFFFFF')
    W(f"\n文字层级：textSecondary 与 textTertiary 在白底上的对比度之比为 {sec_ter:.2f}，"
      f"两者色差 ΔE_OK = {dE(SHARED['textSecondary'], SHARED['textTertiary']):.3f}。")

    # 3. OKLab matrix
    W('\n## 3. OKLab 色差矩阵（主色两两之间）\n')
    ids = [p['id'] for p in pals]
    W('| | ' + ' | '.join(by[i]['zh'] for i in ids) + ' |')
    W('|---|' + '---|' * len(ids))
    for a in ids:
        cells = []
        for b in ids:
            if a == b:
                cells.append('—')
                continue
            d = dE(by[a]['primaryAccent'], by[b]['primaryAccent'])
            cells.append(f'**{d:.3f}**' if d < 0.08 else (f'_{d:.3f}_' if d < 0.12 else f'{d:.3f}'))
        W(f"| {by[a]['zh']} | " + ' | '.join(cells) + ' |')
    W('\n粗体：低于 0.08，高风险；斜体：0.08–0.12，需要人工看。')

    pairs = sorted((dE(by[a]['primaryAccent'], by[b]['primaryAccent']), a, b)
                   for a, b in itertools.combinations(ids, 2))
    high = [(d, a, b) for d, a, b in pairs if d < 0.08]
    review = [(d, a, b) for d, a, b in pairs if 0.08 <= d < 0.12]

    # 4. brand vs semantic
    W('\n## 4. 品牌色与语义色冲突\n')
    W('| App | ' + ' | '.join(SEMANTIC) + ' |')
    W('|---|' + '---|' * len(SEMANTIC))
    sem_high = []
    for p in pals:
        cells = []
        for k, v in SEMANTIC.items():
            d = dE(p['primaryAccent'], v)
            if d < 0.08:
                sem_high.append((d, p['id'], k))
            cells.append(f'**{d:.3f}**' if d < 0.08 else (f'_{d:.3f}_' if d < 0.12 else f'{d:.3f}'))
        W(f"| {p['zh']} | " + ' | '.join(cells) + ' |')

    # 5. tactical annotations against real courts
    W('\n## 5. 战术标注与真实球场\n')
    W('每条线在 app 里都带 28–40% 的黑色描边，所以一条线是否可见看「线色对球场」与「黑边对球场」两者中较高的一个；'
      '球员是带白边的人形，不是色块。下表列出线色本身对球场的对比度，低于 3.0 的依赖描边。\n')
    W('| 球场 | ' + ' | '.join(ANNOTATIONS) + ' |')
    W('|---|' + '---|' * len(ANNOTATIONS))
    weak = []
    for k, court in COURTS.items():
        cells = []
        for n, c in ANNOTATIONS.items():
            v = cr(c, court)
            if v < 3.0 and n in ('movementLine', 'passLine', 'teamA', 'teamB'):
                weak.append(f"{by[k]['zh']}球场 {court} 上的 {n} {f2(v)}")
            cells.append(f2(v) if v >= 3 else f'**{f2(v)}**')
        W(f"| {by[k]['zh']} {court} | " + ' | '.join(cells) + ' |')

    # 6. corrections
    W('\n## 6. 需要处理的问题与候选替换色\n')
    W('让步的一方按判断指定：曲棍球与水球让水球（水球是 V4.1 新改的），橄榄球与篮球、藤球让橄榄球，'
      '足球与羽毛球让羽毛球，与语义色冲突的让运动。候选色在原色色相 ±30°、明度 ±0.15、彩度 ±25% 内搜索，'
      '要求离其他 app 主色 ≥ 0.10、离语义色 ≥ 0.08，按钮文字 ≥ 5:1，按移动最小排序。'
      '没有你的确认，原色保持不变。\n')
    all_colors = {p['id']: p['primaryAccent'] for p in pals}
    proposals = {}
    # Which one moves: for sport–semantic, the sport; for sport–sport, the
    # one with more collisions, then the later in the brief's list.
    load = {}
    for d, a, b in high:
        load[a] = load.get(a, 0) + 1
        load[b] = load.get(b, 0) + 1
    for d, a, k in sem_high:
        load[a] = load.get(a, 0) + 1
    movers = []
    for d, a, b in high:
        movers.append(b if load.get(b, 0) >= load.get(a, 0) else a)
    for d, a, k in sem_high:
        movers.append(a)
    # Who gives way, by judgement rather than count: the sport whose V4.1
    # change caused the collision, or whose identity tolerates a shift.
    MOVE = {('fieldHockey', 'waterPolo'): 'waterPolo',
            ('rugby', 'sepakTakraw'): 'rugby', ('basketball', 'rugby'): 'rugby',
            ('soccer', 'badminton'): 'badminton'}
    movers = []
    for d, a, b in high:
        movers.append(MOVE.get((a, b)) or MOVE.get((b, a)) or b)
    for d, a, k in sem_high:
        movers.append(a)
    for m in dict.fromkeys(movers):
        if m == 'hub':
            continue
        others = [v for k, v in all_colors.items() if k != m]
        proposals[m] = candidates(all_colors[m], others, by[m]['primaryButtonForeground'],
                                  sem=list(SEMANTIC.values()))
    if not high and not sem_high:
        W('没有高风险碰撞。')
    for d, a, b in high:
        W(f"- **{by[a]['zh']} {by[a]['primaryAccent']} 与 {by[b]['zh']} {by[b]['primaryAccent']}**：色差 {d:.3f}，高风险。")
    for d, a, k in sem_high:
        W(f"- **{by[a]['zh']} {by[a]['primaryAccent']} 与语义色 {k} {SEMANTIC[k]}**：色差 {d:.3f}，高风险。")
    for m, cands in proposals.items():
        p = by[m]
        W(f"\n**{p['zh']}（现 {p['primaryAccent']}）的候选：**\n")
        if not cands:
            W('在搜索范围内找不到同时满足条件的颜色，需要换思路（例如换色相家族）。')
        for cand, move, mind, fg in cands:
            W(f'- `{cand}`：离原色 {move:.3f}；与其他所有颜色最近 {mind:.3f}；'
              f'按钮文字用 {fg} 为 {f2(cr(fg, cand))}；白底 {f2(cr(cand, "#FFFFFF"))}。')
    # Hub vs blue sports
    hub = by['hub']['primaryAccent']
    near_hub = sorted((dE(hub, p['primaryAccent']), p['zh']) for p in pals if p['id'] != 'hub')[:4]
    W(f"\n**合集版 {hub}** 与最近的几个运动：" + '，'.join(f'{z} {d:.3f}' for d, z in near_hub) +
      f"；与焦点色 {SEMANTIC['focus']} {dE(hub, SEMANTIC['focus']):.3f}。")
    hub_others = [p['primaryAccent'] for p in pals if p['id'] != 'hub'] + list(SEMANTIC.values())
    hub_alts = candidates(hub, [p['primaryAccent'] for p in pals if p['id'] != 'hub'], '#FFFFFF',
                          sem=list(SEMANTIC.values()), hue_span=45, sem_gap=0.12)
    if near_hub[0][0] < 0.12 or dE(hub, SEMANTIC['focus']) < 0.12:
        W('合集版需要人工看，两个备选：')
        for cand, move, mind, fg in hub_alts:
            W(f'- `{cand}`：离原色 {move:.3f}；与其他所有颜色最近 {mind:.3f}；白字 {f2(cr(fg, cand))}。')

    # button foreground corrections
    W('\n## 7. 按钮文字色核对\n')
    for p in pals:
        fg = p['primaryButtonForeground']
        v = cr(fg, p['primaryAccent'])
        best = better_fg(p['primaryAccent'])
        flag = grade(v, TEXT_MIN, TEXT_SAFE)
        note = '' if best == fg or cr(best, p['primaryAccent']) - v < 0.5 else f'；改用 {best} 可到 {f2(cr(best, p["primaryAccent"]))}'
        if v < TEXT_SAFE:
            L, C, h = oklch_of(p['primaryAccent'])
            step = 0.004 if fg != '#FFFFFF' else -0.004
            fill = p['primaryAccent']
            while cr(fg, fill) < TEXT_SAFE and 0.1 < L < 0.98:
                L += step
                fill = hexof(L, C, h)
            note += f'；专用按钮填充色 `{fill}` 可到 {f2(cr(fg, fill))}（与品牌色色差 {dE(fill, p["primaryAccent"]):.3f}）'
        W(f"- {p['zh']}：{fg} 在 {p['primaryAccent']} 上 {f2(v)} {flag}{note}")

    # 8. summary lists
    W('\n## 8. 失败项\n')
    W('\n'.join(f'- {x}' for x in fails) if fails else '无。')
    W('\n## 9. 临界项（达标但低于内部目标）\n')
    W('\n'.join(f'- {x}' for x in borders) if borders else '无。')
    W('\n## 10. 需要人工看的组合（0.08–0.12）\n')
    W('\n'.join(f"- {by[a]['zh']} {by[a]['primaryAccent']} / {by[b]['zh']} {by[b]['primaryAccent']}：{d:.3f}"
                for d, a, b in review) or '无。')
    W('\n## 11. 球场上偏弱的标注（依赖黑色描边）\n')
    W('\n'.join(f'- {x}' for x in weak) or '无。')

    summary = {
        'apps': len(pals), 'failures': len(fails), 'borderline': len(borders),
        'highRiskSportPairs': len(high), 'highRiskSemantic': len(sem_high),
        'reviewPairs': len(review),
    }
    W('\n## 12. 批准清单\n')
    for item in ('15 个运动和合集版的主色、副色是否接受（或选用候选色）',
                 '高风险碰撞的替换色', '语义色是否接受（尤其是作为文字时的对比度）',
                 '派生色（accentText、selectedStroke 等）是否接受', '是否进入第二阶段接入 app'):
        W(f'- [ ] {item}')

    (OUT / 'report.md').write_text('\n'.join(md) + '\n')
    (OUT / 'palette_v41.json').write_text(json.dumps(
        {'version': '4.1-proposal', 'shared': SHARED, 'semantic': SEMANTIC,
         'annotations': ANNOTATIONS, 'apps': pals, 'summary': summary,
         'proposals': {k: [c[0] for c in v] for k, v in proposals.items()},
         'hubAlternatives': [c[0] for c in hub_alts]}, ensure_ascii=False, indent=2) + '\n')
    (OUT / 'board.html').write_text(board(pals, fails, borders, proposals, hub_alts))
    for src, dst in (('report.md', 'reports/配色V4.1_验证报告_2026-10-15.md'),
                     ('board.html', 'reports/配色V4.1_对照板_2026-10-15.html')):
        (REPO / dst).write_text((OUT / src).read_text())
    print(json.dumps(summary, ensure_ascii=False))
    print('proposals', {k: [c[0] for c in v] for k, v in proposals.items()}, 'hub alts', [c[0] for c in hub_alts])


def board(pals, fails, borders, proposals, hub_alts):
    S = SHARED
    def sw(hx, lab):
        return f'<div class="sw"><i style="background:{hx}"></i><b>{lab}</b><code>{hx}</code></div>'
    cards = []
    for i, p in enumerate(pals, 1):
        r = audit(p)
        worst = 'FAIL' if any(g == 'FAIL' for *_, g in r) else ('BORDERLINE' if any(g == 'BORDERLINE' for *_, g in r) else 'PASS')
        badge = {'PASS': '#147D50', 'BORDERLINE': '#8B5900', 'FAIL': '#B83240'}[worst]
        alt = ''
        if p['id'] in proposals and proposals[p['id']]:
            alt = '<div class="alt">候选 ' + ' '.join(f'<span style="background:{c[0]}"></span><code>{c[0]}</code>' for c in proposals[p['id']]) + '</div>'
        if p['id'] == 'hub' and hub_alts:
            alt = '<div class="alt">备选 ' + ' '.join(f'<span style="background:{c[0]}"></span><code>{c[0]}</code>' for c in hub_alts) + '</div>'
        cards.append(f"""<article class="card">
<header><span class="no">{i:02d}</span><div><h3>{p['zh']}</h3><code class="en">{p['id']}</code></div>
<span class="st" style="color:{badge};border-color:{badge}">对比度 {worst}</span></header>
<div class="sws">{sw(p['background'],'Background')}{sw(p['surface'],'Surface')}{sw(p['elevatedSurface'],'Elevated')}{sw(p['primaryAccent'],'Primary')}{sw(p['secondaryAccent'],'Secondary')}</div>
<div class="demo"><span class="btn" style="background:{p['primaryAccent']};color:{p['primaryButtonForeground']}">打开战术板</span>
<span class="sel" style="border-color:{p['selectedStroke']}">已选</span>
<span class="txt" style="color:{p['accentText']}">全部训练 →</span></div>
<div class="sem"><span><i style="background:{p['accentText']}"></i>accentText {p['accentText']}</span><span><i style="background:{p['selectedStroke']}"></i>selectedStroke {p['selectedStroke']}</span></div>
{alt}</article>""")
    icons = ''.join(f'<div class="ic"><i style="background:linear-gradient(135deg,{p["primaryAccent"]} 0 62%,{p["secondaryAccent"]} 62%)"></i><small>{p["zh"]}</small></div>' for p in pals)
    sem = ''.join(f'<span class="chip" style="color:{v};border-color:{v}">● {k} {v}</span>' for k, v in SEMANTIC.items())
    return f"""<!doctype html><html lang="zh"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>配色 V4.1 提案</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
:root{{color-scheme:light}}body{{margin:0;background:{S['pageBackground']};color:{S['textPrimary']};font-family:Inter,-apple-system,"PingFang SC",sans-serif;padding:40px 16px 60px}}
.wrap{{max-width:1360px;margin:0 auto}}.kicker{{font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:{S['textSecondary']};font-weight:600}}
h1{{font-size:28px;margin:8px 0 10px}}.lede{{color:{S['textSecondary']};font-size:14px;line-height:1.65;max-width:900px;margin:0}}
h2{{font-size:13px;letter-spacing:.12em;text-transform:uppercase;color:{S['textSecondary']};margin:40px 0 14px}}
.grid{{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:16px;margin-top:26px}}
@media (max-width:1100px){{.grid{{grid-template-columns:repeat(2,minmax(0,1fr))}}}}@media (max-width:600px){{.grid{{grid-template-columns:1fr}}}}
.card{{background:#fff;border:1px solid {S['decorativeBorder']};border-radius:18px;padding:16px;box-shadow:0 1px 2px rgba(22,33,46,.04),0 6px 18px rgba(22,33,46,.05);display:flex;flex-direction:column;gap:11px;height:310px;box-sizing:border-box}}
header{{display:flex;align-items:center;gap:10px}}.no{{font-size:11px;font-weight:600;color:{S['textTertiary']}}}header h3{{margin:0;font-size:16px}}.en{{font-size:11px;color:{S['textTertiary']}}}
.st{{margin-left:auto;font-size:10.5px;font-weight:700;border:1.5px solid;border-radius:999px;padding:2px 8px}}
.sws{{display:grid;grid-template-columns:repeat(5,1fr);gap:5px}}.sw i{{display:block;height:38px;border-radius:9px;box-shadow:inset 0 0 0 1px {S['decorativeBorder']}}}
.sw b{{display:block;font-size:9px;font-weight:600;margin-top:5px;color:{S['textSecondary']}}}.sw code{{font-size:9px;color:{S['textTertiary']}}}
.demo{{background:{S['elevatedSurface']};border-radius:11px;padding:8px;display:flex;align-items:center;gap:7px}}
.btn{{font-weight:600;font-size:12.5px;border-radius:8px;padding:7px 10px}}.sel{{background:#fff;border:2px solid;border-radius:8px;padding:5px 9px;font-size:12px}}.txt{{margin-left:auto;font-weight:600;font-size:12.5px}}
.sem{{display:flex;flex-direction:column;gap:3px;font-size:10.5px;color:{S['textSecondary']}}}.sem i{{display:inline-block;width:9px;height:9px;border-radius:3px;margin-right:5px}}
.alt{{margin-top:auto;font-size:10.5px;color:{S['textSecondary']};display:flex;align-items:center;gap:5px;flex-wrap:wrap}}.alt span{{width:14px;height:14px;border-radius:4px;display:inline-block}}
.icons{{display:grid;grid-template-columns:repeat(16,minmax(0,1fr));gap:10px}}@media (max-width:1100px){{.icons{{grid-template-columns:repeat(8,1fr)}}}}
.ic{{text-align:center}}.ic i{{display:block;width:60px;height:60px;border-radius:14px;margin:0 auto 5px;box-shadow:0 1px 3px rgba(0,0,0,.15)}}.ic small{{font-size:10.5px;color:{S['textSecondary']}}}
.chips{{display:flex;gap:8px;flex-wrap:wrap}}.chip{{background:#fff;border:1.5px solid;border-radius:999px;padding:4px 10px;font-size:12px;font-weight:600}}
</style></head><body><div class="wrap">
<div class="kicker">Tactics Board · Colour System V4.1 · Stage One proposal</div><h1>配色 V4.1 提案（待批准）</h1>
<p class="lede">16 个 app 的色值完全按 V4.1 规范，未做任何改动。每张卡片右上角是该 app 最差一项的判定；有高风险碰撞的卡片底部列出候选替换色，仅供选择，没有采用。完整数值见同目录的验证报告。</p>
<div class="grid">{''.join(cards)}</div>
<h2>App Store 图标尺寸下并排（60pt）</h2><div class="icons">{icons}</div>
<h2>语义色</h2><div class="chips">{sem}</div>
</div></body></html>"""


if __name__ == '__main__':
    main()
