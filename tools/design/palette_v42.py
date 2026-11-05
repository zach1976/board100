#!/usr/bin/env python3
"""Colour system V4.2 — Stage One: validation and preview only (2026-10-15).

The V4.2 brief's values, recomputed from scratch: WCAG 2.1 contrast (sRGB
linearised; reported to three decimals, truncated, never rounded up),
OKLab ΔE for every brand pair and brand–semantic pair, nearest neighbours,
derived accessible tokens, button fills, annotations against real courts.
No production file is touched.

    build/v42/palette_v42.json   build/v42/report.md
    build/v42/board.html         build/v42/icons.html
    (copies in reports/配色V4.2_*)
"""
from __future__ import annotations

import itertools
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from palette_v41 import cr, dE, mix, COURTS, ANNOTATIONS  # noqa: E402
from sport_palettes import oklch_of, hexof  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / 'build/v42'

SHARED = {
    'pageBackground': '#F3F0E8', 'appBackground': '#F6F4EE', 'surface': '#FFFFFF',
    'elevatedSurface': '#EEF3F8', 'secondarySurface': '#F7F9FC',
    'textPrimary': '#16212E', 'textSecondary': '#394657', 'textTertiary': '#586577',
    'decorativeBorder': '#D8E0E8', 'inputBorder': '#728091', 'disabledSurface': '#C8D0D9',
}
SEMANTIC = {'success': '#10663A', 'warning': '#7A5E00', 'error': '#BB234A',
            'information': '#0D4A8E', 'focus': '#4D295C'}
GROUNDS = {'#FFFFFF': 'white', '#F6F4EE': 'app', '#EEF3F8': 'elevated', '#F3F0E8': 'page'}
INK = SHARED['textPrimary']
P = None  # 'primary' marker in the fill column

# id, 中文, English, primary, secondary, button fill (None = primary), fg
APPS = [
    ('volleyball', '排球', 'Volleyball', '#2C50CC', '#7DB7FF', P, '#FFFFFF'),
    ('soccer', '足球', 'Soccer', '#268435', '#8BCF67', '#217F30', '#FFFFFF'),
    ('basketball', '篮球', 'Basketball', '#DB631E', '#FFB566', '#E56D28', '#16212E'),
    ('fieldHockey', '曲棍球', 'Field Hockey', '#076CA5', '#E3C86C', P, '#FFFFFF'),
    ('tennis', '网球', 'Tennis', '#C7D93B', '#6E95DD', P, '#16212E'),
    ('rugby', '橄榄球', 'Rugby', '#B27F6F', '#6FA570', '#B78474', '#16212E'),
    ('badminton', '羽毛球', 'Badminton', '#087D77', '#D8B688', '#077C76', '#FFFFFF'),
    ('tableTennis', '乒乓球', 'Table Tennis', '#604595', '#E15C56', P, '#FFFFFF'),
    ('pickleball', '匹克球', 'Pickleball', '#1F9E84', '#D7C96E', '#23A288', '#16212E'),
    ('baseball', '棒球', 'Baseball', '#883C66', '#C98E57', P, '#FFFFFF'),
    ('handball', '手球', 'Handball', '#8081C8', '#E59B55', '#8889D0', '#16212E'),
    ('waterPolo', '水球', 'Water Polo', '#218EB6', '#5E8FC8', '#176A90', '#FFFFFF'),
    ('sepakTakraw', '藤球', 'Sepak Takraw', '#A38B23', '#67A56C', '#A78F27', '#16212E'),
    ('beachTennis', '沙滩网球', 'Beach Tennis', '#E1C79B', '#CFA087', P, '#16212E'),
    ('footvolley', '足排球', 'Footvolley', '#AA5026', '#39B9C8', P, '#FFFFFF'),
    ('hub', '战术板合集', 'Sports Tactics Hub', '#365058', '#B49A6A', P, '#FFFFFF'),
]

TEXT_MIN, TEXT_SAFE, UI_MIN, UI_SAFE = 4.5, 5.0, 3.0, 3.5
BRAND_GAP, SEM_GAP, HUB_FOCUS_GAP, IDEAL_GAP = 0.10, 0.10, 0.12, 0.12


def t3(x):
    return f'{math.floor(x * 1000) / 1000:.3f}'


def grade(v, need, safe):
    return 'FAIL' if v < need else ('BORDERLINE' if v < safe else 'PASS')


def worst(hx, grounds):
    return min(cr(hx, g) for g in grounds)


def darken_to(hx, need, grounds):
    if worst(hx, grounds) >= need:
        return hx
    L, C, h = oklch_of(hx)
    while L > 0.15:
        L -= 0.003
        c = hexof(L, C, h)
        if worst(c, grounds) >= need:
            return c
    return INK


def derive(a):
    key, zh, en, pa, sa, fill, fg = a
    g = list(GROUNDS)
    soft = mix(pa, '#FFFFFF', 0.12)
    return {
        'id': key, 'zh': zh, 'en': en,
        'background': SHARED['appBackground'], 'surface': SHARED['surface'],
        'elevatedSurface': SHARED['elevatedSurface'],
        'primaryAccent': pa, 'secondaryAccent': sa,
        'primaryButtonFill': fill or pa, 'primaryButtonForeground': fg,
        'accentText': darken_to(pa, TEXT_SAFE, g + [soft]),
        'selectedStroke': darken_to(pa, UI_SAFE, g + [soft]),
        'secondaryAccentText': darken_to(sa, TEXT_SAFE, g),
        'secondaryAccentStroke': darken_to(sa, UI_SAFE, g),
        'accentSoftBackground': soft,
    }


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    pals = [derive(a) for a in APPS]
    by = {p['id']: p for p in pals}
    md, W = [], None
    W = md.append
    fails, borders = [], []

    def rec(label, v, need, safe):
        g = grade(v, need, safe)
        if g == 'FAIL':
            fails.append(f'{label} {t3(v)}')
        elif g == 'BORDERLINE':
            borders.append(f'{label} {t3(v)}')
        return f'{t3(v)} {g}'

    W('# 配色 V4.2 第一阶段：验证报告\n')
    W('所有数值由脚本重新计算：WCAG 2.1 相对亮度（含 sRGB 线性化），保留三位小数并截断，不向上取整。'
      '文字 ≥4.500 达标、<5.000 记 BORDERLINE；非文字 ≥3.000 达标、<3.500 记 BORDERLINE。'
      '派生色对四种底色（#FFFFFF、#F6F4EE、#EEF3F8、#F3F0E8）和该运动的浅色选中底都取最差值。\n')

    # 1. shared + semantic
    W('## 1. 共用色与语义色\n')
    W('| 令牌 | 白 | 应用底 | 浮层 | 页面画布 | 最差 | 判定 |')
    W('|---|---|---|---|---|---|---|')
    def srow(name, hx, need, safe):
        vals = [cr(hx, g) for g in GROUNDS]
        W(f'| {name} {hx} | ' + ' | '.join(t3(v) for v in vals) +
          f' | {t3(min(vals))} | {rec(name, min(vals), need, safe).split()[1]} |')
    for k in ('textPrimary', 'textSecondary', 'textTertiary'):
        srow(k, SHARED[k], TEXT_MIN, TEXT_SAFE)
    srow('inputBorder', SHARED['inputBorder'], UI_MIN, UI_SAFE)
    for k, v in SEMANTIC.items():
        srow(f'{k}（作文字）', v, TEXT_MIN, TEXT_SAFE)
    hier = dE(SHARED['textSecondary'], SHARED['textTertiary'])
    W(f"\n文字层级：textSecondary 与 textTertiary 色差 ΔE_OK = {hier:.3f}，"
      f"白底对比度 {t3(cr(SHARED['textSecondary'], '#FFFFFF'))} 对 {t3(cr(SHARED['textTertiary'], '#FFFFFF'))}。")

    # 2. per-app contrast
    W('\n## 2. 各 app 对比度\n')
    W('| App | 按钮文字/按钮填充 | 按钮填充与品牌色色差 | accentText | selectedStroke | 2nd text | 2nd stroke | 浅色选中底上的 accentText |')
    W('|---|---|---|---|---|---|---|---|')
    for p in pals:
        g = list(GROUNDS)
        btn = cr(p['primaryButtonForeground'], p['primaryButtonFill'])
        cells = [
            rec(f"{p['zh']} 按钮文字", btn, TEXT_MIN, TEXT_SAFE),
            f"{dE(p['primaryButtonFill'], p['primaryAccent']):.3f}",
            rec(f"{p['zh']} accentText", worst(p['accentText'], g), TEXT_MIN, TEXT_SAFE),
            rec(f"{p['zh']} selectedStroke", min(worst(p['selectedStroke'], g), cr(p['selectedStroke'], p['accentSoftBackground'])), UI_MIN, UI_SAFE),
            rec(f"{p['zh']} secondaryAccentText", worst(p['secondaryAccentText'], g), TEXT_MIN, TEXT_SAFE),
            rec(f"{p['zh']} secondaryAccentStroke", worst(p['secondaryAccentStroke'], g), UI_MIN, UI_SAFE),
            rec(f"{p['zh']} accentText on soft", cr(p['accentText'], p['accentSoftBackground']), TEXT_MIN, TEXT_SAFE),
        ]
        W(f"| {p['zh']} | " + ' | '.join(cells) + ' |')
    W('\n参考值（不判定）：主色对白底、对深色字。')
    W('\n| App | 主色 | 主色/白 | 主色/深字 |\n|---|---|---|---|')
    for p in pals:
        W(f"| {p['zh']} | {p['primaryAccent']} | {t3(cr(p['primaryAccent'], '#FFFFFF'))} | {t3(cr(p['primaryAccent'], INK))} |")

    # 3. OKLab
    ids = [p['id'] for p in pals]
    W('\n## 3. OKLab 色差矩阵\n')
    W('| | ' + ' | '.join(by[i]['zh'] for i in ids) + ' |')
    W('|---|' + '---|' * len(ids))
    for a in ids:
        cells = []
        for b in ids:
            if a == b:
                cells.append('—'); continue
            d = dE(by[a]['primaryAccent'], by[b]['primaryAccent'])
            cells.append(f'**{d:.3f}**' if d < BRAND_GAP else (f'_{d:.3f}_' if d < IDEAL_GAP else f'{d:.3f}'))
        W(f"| {by[a]['zh']} | " + ' | '.join(cells) + ' |')
    W(f'\n粗体：低于 {BRAND_GAP}（不达标）；斜体：{BRAND_GAP}–{IDEAL_GAP}（达标但未到理想值）。')

    brand_hits, sem_hits, near_rows = [], [], []
    for a, b in itertools.combinations(ids, 2):
        d = dE(by[a]['primaryAccent'], by[b]['primaryAccent'])
        if d < BRAND_GAP:
            brand_hits.append((d, a, b))
    W('\n## 4. 最近邻\n')
    W('| App | 最近的 app | 色差 | 最近的语义色 | 色差 | 判定 |')
    W('|---|---|---|---|---|---|')
    for p in pals:
        nb = min((dE(p['primaryAccent'], q['primaryAccent']), q['zh']) for q in pals if q is not p)
        sems = {k: dE(p['primaryAccent'], v) for k, v in SEMANTIC.items()}
        ns = min(sems.items(), key=lambda kv: kv[1])
        for k, v in sems.items():
            need = HUB_FOCUS_GAP if (p['id'] == 'hub' and k == 'focus') else SEM_GAP
            if v < need:
                sem_hits.append((v, p['id'], k, need))
        flag = 'PASS'
        if nb[0] < BRAND_GAP or ns[1] < SEM_GAP or (p['id'] == 'hub' and sems['focus'] < HUB_FOCUS_GAP):
            flag = 'FAIL'
        elif nb[0] < IDEAL_GAP:
            flag = 'REVIEW'
        W(f"| {p['zh']} | {nb[1]} | {nb[0]:.3f} | {ns[0]} | {ns[1]:.3f} | {flag} |")
    W(f"\n合集版对焦点色：{dE(by['hub']['primaryAccent'], SEMANTIC['focus']):.3f}（要求 ≥ {HUB_FOCUS_GAP}）。")

    W('\n## 5. 品牌色与语义色\n')
    W('| App | ' + ' | '.join(SEMANTIC) + ' |')
    W('|---|' + '---|' * len(SEMANTIC))
    for p in pals:
        W(f"| {p['zh']} | " + ' | '.join(
            (f'**{dE(p["primaryAccent"], v):.3f}**' if dE(p["primaryAccent"], v) < SEM_GAP else f'{dE(p["primaryAccent"], v):.3f}')
            for v in SEMANTIC.values()) + ' |')

    # 6. annotations
    W('\n## 6. 战术标注与真实球场\n')
    W('线条在 app 里带 28–40% 黑色描边，球员是带白边的人形；下表是标注色本身对球场的对比度，仅作参考。\n')
    W('| 球场 | ' + ' | '.join(ANNOTATIONS) + ' |')
    W('|---|' + '---|' * len(ANNOTATIONS))
    for k, court in COURTS.items():
        W(f"| {by[k]['zh']} {court} | " + ' | '.join(t3(cr(c, court)) for c in ANNOTATIONS.values()) + ' |')

    # 7. corrections
    W('\n## 7. 不达标项与修正建议\n')
    corrections = {}
    if not brand_hits and not sem_hits:
        W('品牌色之间、品牌色与语义色之间没有低于要求的组合。')
    for d, a, b in sorted(brand_hits):
        W(f"- 品牌色 {by[a]['zh']} {by[a]['primaryAccent']} / {by[b]['zh']} {by[b]['primaryAccent']}：{d:.3f} < {BRAND_GAP}")
    for v, a, k, need in sorted(sem_hits):
        W(f"- {by[a]['zh']} {by[a]['primaryAccent']} / 语义色 {k} {SEMANTIC[k]}：{v:.3f} < {need}")
    W('\n### 失败项\n')
    W('\n'.join(f'- {x}' for x in fails) or '无。')
    W('\n### 临界项\n')
    W('\n'.join(f'- {x}' for x in borders) or '无。')
    review = sorted((dE(by[a]['primaryAccent'], by[b]['primaryAccent']), a, b)
                    for a, b in itertools.combinations(ids, 2)
                    if BRAND_GAP <= dE(by[a]['primaryAccent'], by[b]['primaryAccent']) < IDEAL_GAP)
    W('\n### 达标但未到理想值 0.12 的品牌色组合（需要看图标）\n')
    W('\n'.join(f"- {by[a]['zh']} / {by[b]['zh']}：{d:.3f}" for d, a, b in review) or '无。')

    summary = {'apps': len(pals), 'wcagFailures': len(fails), 'borderline': len(borders),
               'brandCollisions': len(brand_hits), 'semanticCollisions': len(sem_hits),
               'belowIdealPairs': len(review)}
    W('\n## 8. 汇总\n')
    for k, v in summary.items():
        W(f'- {k}: {v}')

    (OUT / 'report.md').write_text('\n'.join(md) + '\n')
    (OUT / 'palette_v42.json').write_text(json.dumps(
        {'version': '4.2-candidate', 'shared': SHARED, 'semantic': SEMANTIC,
         'annotations': ANNOTATIONS, 'apps': pals, 'summary': summary},
        ensure_ascii=False, indent=2) + '\n')
    (OUT / 'board.html').write_text(board(pals, by))
    (OUT / 'icons.html').write_text(icons(pals))
    for src, dst in (('report.md', '配色V4.2_验证报告_2026-10-15.md'),
                     ('board.html', '配色V4.2_对照板_2026-10-15.html'),
                     ('icons.html', '配色V4.2_图标对比_2026-10-15.html'),
                     ('palette_v42.json', '配色V4.2_候选配置_2026-10-15.json')):
        (REPO / 'reports' / dst).write_text((OUT / src).read_text())
    print(json.dumps(summary, ensure_ascii=False))
    print('fails', fails)
    print('borderline', borders)
    print('brand', [(round(d, 3), a, b) for d, a, b in brand_hits])
    print('semantic', [(round(v, 3), a, k) for v, a, k, _ in sem_hits])
    print('below ideal', [(round(d, 3), a, b) for d, a, b in review])


HEAD = """<!doctype html><html lang="zh"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title}</title><link rel="preconnect" href="https://fonts.googleapis.com"><link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>:root{{color-scheme:light}}body{{margin:0;background:#F3F0E8;color:#16212E;font-family:Inter,-apple-system,"PingFang SC",sans-serif;padding:40px 16px 60px}}
.wrap{{max-width:1360px;margin:0 auto}}.kicker{{font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:#394657;font-weight:600}}
h1{{font-size:28px;margin:8px 0 10px}}.lede{{color:#394657;font-size:14px;line-height:1.65;max-width:920px;margin:0}}h2{{font-size:13px;letter-spacing:.12em;text-transform:uppercase;color:#394657;margin:40px 0 14px}}
"""


def board(pals, by):
    def sw(hx, lab):
        return f'<div class="sw"><i style="background:{hx}"></i><b>{lab}</b><code>{hx}</code></div>'
    cards = []
    g = list(GROUNDS)
    for i, p in enumerate(pals, 1):
        btn = cr(p['primaryButtonForeground'], p['primaryButtonFill'])
        at = worst(p['accentText'], g)
        ss = min(worst(p['selectedStroke'], g), cr(p['selectedStroke'], p['accentSoftBackground']))
        nb = min((dE(p['primaryAccent'], q['primaryAccent']), q['zh']) for q in pals if q is not p)
        ns = min((dE(p['primaryAccent'], v), k) for k, v in SEMANTIC.items())
        def badge(v, need, safe):
            gr = grade(v, need, safe)
            c = {'PASS': '#10663A', 'BORDERLINE': '#7A5E00', 'FAIL': '#BB234A'}[gr]
            return f'<em style="color:{c}">{t3(v)} {gr}</em>'
        nflag = '#10663A' if nb[0] >= IDEAL_GAP else ('#7A5E00' if nb[0] >= BRAND_GAP else '#BB234A')
        sflag = '#10663A' if ns[0] >= SEM_GAP else '#BB234A'
        fill_note = '' if p['primaryButtonFill'] == p['primaryAccent'] else f' · 填充 {p["primaryButtonFill"]}'
        cards.append(f"""<article class="card"><header><span class="no">{i:02d}</span><div><h3>{p['zh']}</h3><code class="en">{p['id']}</code></div></header>
<div class="sws">{sw(p['background'],'Background')}{sw(p['surface'],'Surface')}{sw(p['elevatedSurface'],'Elevated')}{sw(p['primaryAccent'],'Primary')}{sw(p['secondaryAccent'],'Secondary')}</div>
<div class="demo" style="background:{p['accentSoftBackground']}"><span class="btn" style="background:{p['primaryButtonFill']};color:{p['primaryButtonForeground']}">打开战术板</span><span class="sel" style="border-color:{p['selectedStroke']}">已选</span><span class="txt" style="color:{p['accentText']}">全部训练 →</span></div>
<dl><dt>按钮文字{fill_note}</dt><dd>{badge(btn, TEXT_MIN, TEXT_SAFE)}</dd>
<dt>品牌文字 {p['accentText']}</dt><dd>{badge(at, TEXT_MIN, TEXT_SAFE)}</dd>
<dt>选中描边 {p['selectedStroke']}</dt><dd>{badge(ss, UI_MIN, UI_SAFE)}</dd>
<dt>最近的 app</dt><dd><em style="color:{nflag}">{nb[1]} {nb[0]:.3f}</em></dd>
<dt>最近的语义色</dt><dd><em style="color:{sflag}">{ns[1]} {ns[0]:.3f}</em></dd></dl></article>""")
    return HEAD.format(title='配色 V4.2 对照板') + """
.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:16px;margin-top:26px}@media (max-width:1100px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}}@media (max-width:600px){.grid{grid-template-columns:1fr}}
.card{background:#fff;border:1px solid #D8E0E8;border-radius:18px;padding:16px;box-shadow:0 1px 2px rgba(22,33,46,.04),0 6px 18px rgba(22,33,46,.05);display:flex;flex-direction:column;gap:10px;height:400px;box-sizing:border-box}
header{display:flex;align-items:center;gap:10px}.no{font-size:11px;font-weight:600;color:#586577}header h3{margin:0;font-size:16px}.en{font-size:11px;color:#586577}
.sws{display:grid;grid-template-columns:repeat(5,1fr);gap:5px}.sw i{display:block;height:36px;border-radius:9px;box-shadow:inset 0 0 0 1px #D8E0E8}.sw b{display:block;font-size:9px;font-weight:600;margin-top:5px;color:#394657}.sw code{font-size:9px;color:#586577}
.demo{border-radius:11px;padding:8px;display:flex;align-items:center;gap:7px}.btn{font-weight:600;font-size:12.5px;border-radius:8px;padding:7px 10px}.sel{background:#fff;border:2px solid;border-radius:8px;padding:5px 9px;font-size:12px}.txt{margin-left:auto;font-weight:600;font-size:12.5px}
dl{display:grid;grid-template-columns:1fr auto;gap:4px 8px;margin:0;font-size:11.5px}dt{color:#394657}dd{margin:0;text-align:right}dd em{font-style:normal;font-weight:600;font-variant-numeric:tabular-nums}
</style></head><body><div class="wrap"><div class="kicker">Tactics Board · Colour System V4.2 · Stage One</div><h1>配色 V4.2 对照板（待批准）</h1>
<p class="lede">色块是 V4.2 规范原值。示例条的底色是该运动的浅色选中底（accentSoftBackground），按钮用规范指定的按钮填充色，「已选」框是选中描边，「全部训练」是品牌文字色。每张卡片下方是脚本重新算出的对比度和最近邻，保留三位小数，不向上取整。</p>
<div class="grid">""" + ''.join(cards) + '</div></div></body></html>'


def icons(pals):
    sizes = [(180, 'App Store 产品页 180'), (120, '主屏幕 @2x 120'), (60, '主屏幕 60'), (40, '搜索/设置 40')]
    rows = []
    for px, label in sizes:
        tiles = ''.join(
            f'<div class="t"><i style="width:{px}px;height:{px}px;border-radius:{px*0.2237:.1f}px;'
            f'background:linear-gradient(145deg,{p["primaryAccent"]} 0 64%,{p["secondaryAccent"]} 64%)">'
            f'<span style="font-size:{px*0.36:.0f}px;color:{p["primaryButtonForeground"]}">{p["zh"][0]}</span></i>'
            f'{"<small>"+p["zh"]+"</small>" if px >= 60 else ""}</div>' for p in pals)
        rows.append(f'<h2>{label}</h2><div class="row">{tiles}</div>')
    groups = [('排球', '曲棍球', '水球', '手球', '乒乓球', '战术板合集'), ('足球', '羽毛球', '匹克球'),
              ('篮球', '橄榄球', '藤球', '足排球'), ('乒乓球', '棒球')]
    by = {p['zh']: p for p in pals}
    gh = ''.join('<div class="grp">' + ''.join(
        f'<div class="t"><i style="width:60px;height:60px;border-radius:13.4px;background:{by[z]["primaryAccent"]}"></i><small>{z}</small></div>'
        for z in g) + '</div>' for g in groups)
    return HEAD.format(title='配色 V4.2 图标对比') + """
.row{display:flex;flex-wrap:wrap;gap:14px;align-items:flex-end}.t{display:flex;flex-direction:column;align-items:center;gap:6px}.t i{display:flex;align-items:center;justify-content:center;box-shadow:0 1px 3px rgba(0,0,0,.18)}.t span{font-weight:700}.t small{font-size:11px;color:#394657}
.grp{display:inline-flex;gap:12px;background:#fff;border:1px solid #D8E0E8;border-radius:16px;padding:14px 16px;margin:0 12px 12px 0}
</style></head><body><div class="wrap"><div class="kicker">Tactics Board · Colour System V4.2 · Stage One</div><h1>图标尺寸对比</h1>
<p class="lede">这些不是 app 的真实图标（真实图标是写实插画），而是用主色和副色做的色块示意，用来检查在常见图标尺寸下，只靠颜色能不能区分 16 个 app。字是运动名的首字，颜色用按钮文字色。</p>
""" + ''.join(rows) + '<h2>易混组并排（60pt，纯主色）</h2>' + gh + '</div></body></html>'


if __name__ == '__main__':
    main()
