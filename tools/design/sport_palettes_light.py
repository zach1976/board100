#!/usr/bin/env python3
"""Light colour system V3.0 of the fifteen tactics-board apps (2026-10-15).

The brand colours are the approved V3.0 values and are never altered here.
What the script derives — and audits with the WCAG 2.1 relative-luminance
formula, sRGB-linearised, never rounded up — are the semantic tokens that
make a light theme usable:

  accentText            primary's hue, darkened in OKLCH to ≥ 4.5:1 on all
                        three light grounds (white, app background, elevated)
  primaryStroke         the same to ≥ 3:1 — selection rings, active tabs
  primarySoftBackground primary at 14 % over white, with accentText ≥ 4.5 on it
  secondaryAccentText   ≥ 4.5:1, as accentText
  secondaryAccentStroke ≥ 3:1 — thin lines and icon strokes
  secondaryAccentSoftBackground  secondary at 18 % over white

Outputs:
  tools/design/sport_palettes_light.json
  tactics_board/lib/ui/sport_palettes.g.dart   (the app's only colour table)
  build/sport_palette_light.html + reports/浅色配色系统_V3_2026-10-15.html
  build/contrast_audit_v3.md   + reports/对比度审计_V3_2026-10-15.md
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from sport_palettes import oklch_of, hexof  # noqa: E402

REPO = Path(__file__).resolve().parents[2]

# ── exact WCAG 2.1 contrast ────────────────────────────────────────────────
def _lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def lum(hx):
    r, g, b = (int(hx[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return 0.2126 * _lin(r) + 0.7152 * _lin(g) + 0.0722 * _lin(b)


def cr(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def floor2(x):
    """Reported value: truncated, never rounded up into a pass."""
    return math.floor(x * 100) / 100


def mix(fg, bg, a):
    f = [int(fg[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(bg[i:i + 2], 16) for i in (1, 3, 5)]
    return '#%02X%02X%02X' % tuple(round(x * a + y * (1 - a)) for x, y in zip(f, b))


# ── the approved foundation and palettes ───────────────────────────────────
SHARED = {
    'pageBackground': '#F3F0E8', 'appBackground': '#F6F4EE',
    'surface': '#FFFFFF', 'elevatedSurface': '#EEF3F8',
    'secondarySurface': '#F7F9FC', 'border': '#D8E0E8',
    'textPrimary': '#16212E', 'textSecondary': '#5F6B7A', 'textTertiary': '#607083',
    'success': '#22A06B', 'warning': '#D99A1A', 'error': '#D64545',
    'info': '#2F80ED', 'disabled': '#C8D0D9', 'focus': '#1F6FEB',
}
GROUNDS = (SHARED['surface'], SHARED['appBackground'], SHARED['elevatedSurface'])
INK = SHARED['textPrimary']

# key, 中文, English, primary, secondary, approved button fg, rationale
SPORTS = [
    ('volleyball', '排球', 'Volleyball', '#2D6CDF', '#7DB7FF', '#FFFFFF',
     '国际赛事 Taraflex 场地的竞技蓝，配同系浅蓝。'),
    ('soccer', '足球', 'Soccer', '#257D42', '#8BCF67', '#FFFFFF',
     '加深的职业草皮绿，与羽毛球的青绿拉开。'),
    ('basketball', '篮球', 'Basketball', '#F28B2D', '#FFB566', '#16212E',
     '篮球橙配木地板的暖杏色，室内球馆的暖调。'),
    ('fieldHockey', '曲棍球', 'Field Hockey', '#087EB5', '#E3C86C', '#FFFFFF',
     '偏青的中蓝人造草，配比赛用球黄；与乒乓球的靛蓝分开。'),
    ('tennis', '网球', 'Tennis', '#C7D93B', '#6E95DD', '#16212E',
     '网球的荧光黄绿配硬地蓝，球与场。'),
    ('rugby', '橄榄球', 'Rugby', '#B98056', '#6FA570', '#16212E',
     '球皮革的棕褐配草场绿，对抗运动的厚重。'),
    ('badminton', '羽毛球', 'Badminton', '#087E78', '#D8B688', '#FFFFFF',
     '冷调青绿的场地垫，配软木球托的茶色。'),
    ('tableTennis', '乒乓球', 'Table Tennis', '#4354A3', '#E15C56', '#FFFFFF',
     '偏靛的深蓝球台，配赛场红地板。'),
    ('pickleball', '匹克球', 'Pickleball', '#26C2BF', '#D7C96E', '#16212E',
     '球场蓝绿交界的青绿，配洞洞球黄。'),
    ('baseball', '棒球', 'Baseball', '#C83A48', '#C98E57', '#FFFFFF',
     '加深的缝线红，白字可读；配内野红土。'),
    ('handball', '手球', 'Handball', '#6B82DE', '#E59B55', '#16212E',
     '室内场地的钴蓝，配六米球门区橙。'),
    ('waterPolo', '水球', 'Water Polo', '#59C3E8', '#5E8FC8', '#16212E',
     '明亮的泳池水色，配深水区蓝。'),
    ('sepakTakraw', '藤球', 'Sepak Takraw', '#D7B250', '#67A56C', '#16212E',
     '藤编球的金色，配东南亚场馆绿。'),
    ('beachTennis', '沙滩网球', 'Beach Tennis', '#E1C79B', '#CFA087', '#16212E',
     '赛场细沙配珊瑚，最柔和的一套。'),
    ('footvolley', '足排球', 'Footvolley', '#A64E29', '#39B9C8', '#FFFFFF',
     '海滩赛场的陶土色，配海水青；与网球的黄绿分开。'),
]


def darken_to(hx, need, grounds=GROUNDS):
    """Same hue, lower OKLCH lightness, until hx reaches [need] on every
    ground. Chroma is held (and only trimmed by the gamut). If the hue is
    gone before it passes, fall back to the shared ink."""
    def ok(c):
        return min(cr(c, g) for g in grounds) >= need
    if ok(hx):
        return hx
    L, C, h = oklch_of(hx)
    while L > 0.18:
        L -= 0.004
        cand = hexof(L, C, h)
        if ok(cand):
            return cand
    return INK


def build():
    pals = []
    for key, zh, en, pa, sa, fg, why in SPORTS:
        soft = mix(pa, '#FFFFFF', 0.14)
        at = darken_to(pa, 4.5, GROUNDS + (soft,))
        pals.append({
            'sportId': key, 'nameZh': zh, 'nameEn': en,
            'background': SHARED['appBackground'], 'surface': SHARED['surface'],
            'elevatedSurface': SHARED['elevatedSurface'],
            'primaryAccent': pa, 'secondaryAccent': sa,
            'primaryButtonForeground': fg,
            'accentText': at,
            'primaryStroke': darken_to(pa, 3.0),
            'primarySoftBackground': soft,
            'secondaryAccentText': darken_to(sa, 4.5),
            'secondaryAccentStroke': darken_to(sa, 3.0),
            'secondaryAccentSoftBackground': mix(sa, '#FFFFFF', 0.18),
            'rationale': why,
        })
    return pals


def audit(pals):
    fails = []
    W, A, E = GROUNDS
    hdr = ('| 运动 | 主色/白 | 主色/深字 | 按钮文字 | accentText/白 | /应用底 | /浮层 | 副色/白 | secondaryText | secondaryStroke | primaryStroke |\n'
           '|---|---|---|---|---|---|---|---|---|---|---|\n')
    rows = []
    for p in pals:
        btn = cr(p['primaryButtonForeground'], p['primaryAccent'])
        at = [cr(p['accentText'], g) for g in GROUNDS]
        st = min(cr(p['secondaryAccentText'], g) for g in GROUNDS)
        ss = min(cr(p['secondaryAccentStroke'], g) for g in GROUNDS)
        ps = min(cr(p['primaryStroke'], g) for g in GROUNDS)
        soft_ok = cr(p['accentText'], p['primarySoftBackground'])
        ssoft = cr(INK, p['secondaryAccentSoftBackground'])
        for name, v, need in (('button', btn, 4.5), ('accentText', min(at), 4.5),
                              ('accentText on soft', soft_ok, 4.5),
                              ('ink on secondary soft', ssoft, 4.5),
                              ('secondaryText', st, 4.5), ('secondaryStroke', ss, 3.0),
                              ('primaryStroke', ps, 3.0)):
            if v < need:
                fails.append(f"{p['sportId']} {name} {v:.3f} < {need}")
        f = floor2
        rows.append(f"| {p['nameZh']} | {f(cr(p['primaryAccent'], W))} | {f(cr(p['primaryAccent'], INK))} | "
                    f"{f(btn)} ({p['primaryButtonForeground']}) | {f(at[0])} | {f(at[1])} | {f(at[2])} | "
                    f"{f(cr(p['secondaryAccent'], W))} | {f(st)} | {f(ss)} | {f(ps)} |")
    shared_rows = []
    for k in ('textPrimary', 'textSecondary', 'textTertiary', 'success', 'warning', 'error', 'info', 'focus'):
        vals = [floor2(cr(SHARED[k], g)) for g in GROUNDS + (SHARED['pageBackground'],)]
        shared_rows.append(f'| {k} {SHARED[k]} | ' + ' | '.join(map(str, vals)) + ' |')
    md = ('# 对比度审计 V3.0\n\n按 WCAG 2.1 相对亮度公式（含 sRGB 线性化）计算，数值截断到两位小数，'
          '不向上取整。正文和按钮文字要求 4.5，描边和图标要求 3.0。\n\n'
          '「accentText/白、/应用底、/浮层」分别是对 #FFFFFF、#F6F4EE、#EEF3F8；'
          'secondaryText、secondaryStroke、primaryStroke 取三种底色里最低的一个。\n\n' + hdr + '\n'.join(rows) +
          '\n\n## 共用色\n\n| 令牌 | 白 | 应用底 | 浮层 | 页面画布 |\n|---|---|---|---|---|\n' + '\n'.join(shared_rows) +
          '\n\n规则：textTertiary 在页面画布 #F3F0E8 上低于 4.5，只能放在白、应用底或浮层上。'
          '功能色 success / warning / info 在浅底上不足 4.5，只用于图标、色块和徽章底色，'
          '对应的文字一律用 textPrimary。\n')
    return md, fails


def dart(pals):
    def c(hx):
        return f'Color(0xFF{hx[1:]})'
    keys = ['background', 'surface', 'elevatedSurface', 'primaryAccent', 'secondaryAccent',
            'primaryButtonForeground', 'accentText', 'primaryStroke', 'primarySoftBackground',
            'secondaryAccentText', 'secondaryAccentStroke', 'secondaryAccentSoftBackground']
    rows = []
    for p in pals:
        body = '\n'.join(f'    {k}: {c(p[k])},' for k in keys)
        rows.append(f'  SportType.{p["sportId"]}: SportColorPalette(\n{body}\n  ),')
    fields = '\n'.join(f'  final Color {k};' for k in keys)
    ctor = '\n'.join(f'    required this.{k},' for k in keys)
    shared = '\n'.join(f'  static const {k} = {c(v)};' for k, v in SHARED.items())
    return f"""// GENERATED by tools/design/sport_palettes_light.py — do not edit by hand.
// Light colour system V3.0: the approved brand colours of the fifteen
// sports and the semantic tokens derived from them, audited to WCAG 2.1 AA.
import 'package:flutter/material.dart';

import '../models/sport_type.dart';

/// One sport's colours. The brand pair (primaryAccent, secondaryAccent) is
/// for fills and identity only; text and thin strokes take the derived
/// tokens, which pass 4.5:1 (text) or 3:1 (strokes) on every light ground.
class SportColorPalette {{
  const SportColorPalette({{
{ctor}
  }});

{fields}
}}

const Map<SportType, SportColorPalette> kSportColors = {{
{chr(10).join(rows)}
}};

/// Shared by all fifteen apps. Never per sport.
class LightTokens {{
{shared}
}}
"""


def html(pals):
    S = SHARED
    def sw(hx, lab):
        return f'<div class="sw"><i style="background:{hx}"></i><b>{lab}</b><code>{hx}</code></div>'
    cards = []
    for i, p in enumerate(pals, 1):
        cards.append(f"""<article class="card">
<header><span class="no">{i:02d}</span><div><h3>{p['nameZh']}</h3><code class="en">{p['sportId']}</code></div></header>
<div class="sws">{sw(p['background'],'Background')}{sw(p['surface'],'Surface')}{sw(p['elevatedSurface'],'Elevated')}{sw(p['primaryAccent'],'Primary')}{sw(p['secondaryAccent'],'Secondary')}</div>
<div class="demo"><span class="btn" style="background:{p['primaryAccent']};color:{p['primaryButtonForeground']}">打开战术板</span>
<span class="txt" style="color:{p['accentText']}">全部训练 →</span></div>
<div class="sem"><span><i style="background:{p['accentText']}"></i>accentText {p['accentText']}</span><span><i style="background:{p['secondaryAccentText']}"></i>2nd text {p['secondaryAccentText']}</span></div>
<p>{p['rationale']}</p></article>""")
    return f"""<!doctype html><html lang="zh"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>浅色配色系统 V3</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
:root{{color-scheme:light}}
body{{margin:0;background:{S['pageBackground']};color:{S['textPrimary']};font-family:Inter,-apple-system,"PingFang SC",sans-serif;padding:44px 16px 60px}}
.wrap{{max-width:1500px;margin:0 auto}}.kicker{{font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:{S['textSecondary']};font-weight:600}}
h1{{font-size:30px;letter-spacing:-.02em;margin:8px 0 10px}}.lede{{color:{S['textSecondary']};font-size:14.5px;line-height:1.65;max-width:820px;margin:0}}
.grid{{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:16px;margin-top:32px}}
@media (max-width:1280px){{.grid{{grid-template-columns:repeat(3,minmax(0,1fr))}}}}
@media (max-width:820px){{.grid{{grid-template-columns:repeat(2,minmax(0,1fr))}}}}
@media (max-width:540px){{.grid{{grid-template-columns:1fr}}}}
.card{{background:{S['surface']};border:1px solid {S['border']};border-radius:18px;padding:18px;box-shadow:0 1px 2px rgba(22,33,46,.04),0 6px 20px rgba(22,33,46,.05);display:flex;flex-direction:column;gap:13px;min-height:330px}}
header{{display:flex;align-items:center;gap:10px}}.no{{font-size:11.5px;font-weight:600;color:{S['textTertiary']}}}
header h3{{margin:0;font-size:17px}}.en{{font-size:11.5px;color:{S['textTertiary']}}}
.sws{{display:grid;grid-template-columns:repeat(5,1fr);gap:6px}}.sw i{{display:block;height:44px;border-radius:10px;box-shadow:inset 0 0 0 1px {S['border']}}}
.sw b{{display:block;font-size:9.5px;font-weight:600;margin-top:6px;color:{S['textSecondary']}}}.sw code{{font-size:9.5px;color:{S['textTertiary']}}}
.demo{{background:{S['elevatedSurface']};border-radius:12px;padding:9px;display:flex;align-items:center;gap:8px}}
.btn{{font-weight:600;font-size:13px;border-radius:9px;padding:8px 12px}}.txt{{margin-left:auto;font-weight:600;font-size:13px}}
.sem{{display:flex;flex-direction:column;gap:4px;font-size:11px;color:{S['textSecondary']}}}.sem i{{display:inline-block;width:10px;height:10px;border-radius:3px;margin-right:6px;vertical-align:-1px}}
.card p{{margin:auto 0 0;font-size:12.5px;line-height:1.6;color:{S['textSecondary']}}}
</style></head><body><div class="wrap">
<div class="kicker">Tactics Board · Design System V3.0</div><h1>浅色配色系统 V3.0</h1>
<p class="lede">五个色块是批准的品牌色，原样展示。示例按钮用核准的文字色；右侧「全部训练」是 accentText——主色同色相加深到在白、应用底、浮层三种底色上都达到 4.5:1 的文字专用色。副色只做色块，要写字或画细线时用下方的 2nd text / stroke 变体。</p>
<div class="grid">{''.join(cards)}</div></div></body></html>"""


def main():
    pals = build()
    md, fails = audit(pals)
    if fails:
        print('FAIL:\n  ' + '\n  '.join(fails))
        sys.exit(1)
    print(md)
    (REPO / 'tools/design/sport_palettes_light.json').write_text(json.dumps(
        {'version': '3.0', 'shared': SHARED,
         'sports': [{k: v for k, v in p.items() if k != 'rationale'} for p in pals]},
        ensure_ascii=False, indent=2) + '\n')
    (REPO / 'tactics_board/lib/ui/sport_palettes.g.dart').write_text(dart(pals))
    page = html(pals)
    for p in ('build/sport_palette_light.html', 'reports/浅色配色系统_V3_2026-10-15.html'):
        (REPO / p).write_text(page)
    for p in ('build/contrast_audit_v3.md', 'reports/对比度审计_V3_2026-10-15.md'):
        (REPO / p).write_text(md)
    print('✓ all tokens pass; wrote json, dart, html, audit')


if __name__ == '__main__':
    main()
