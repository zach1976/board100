#!/usr/bin/env python3
"""SUPERSEDED — the dark colour system of 2026-10-15 morning. The app now
uses the light system in sport_palettes_light.py; this is kept for the
record and writes only its JSON and review page.

The colour system of the fifteen tactics-board apps (2026-10-15).

One source of truth. Everything is specified in OKLCH — perceptual
lightness, chroma, hue — so that "equally dark" and "equally strong" are
measurable instead of eyeballed, then converted to sRGB hex. The script
checks the system (equal surface lightness, accent hierarchy, distinctness
of primaries, WCAG contrast) and writes:

    tools/design/sport_palettes.json              the palettes + shared tokens
    tactics_board/lib/ui/sport_palettes.g.dart    the same, for the app
    build/sport_palette_review.html               the visual comparison

    python3 tools/design/sport_palettes.py          # check + write
    python3 tools/design/sport_palettes.py --check  # check only
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]

# ── colour maths ───────────────────────────────────────────────────────────

def oklch_to_srgb(L, C, h):
    a, b = C * math.cos(math.radians(h)), C * math.sin(math.radians(h))
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3
    r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    bb = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    return r, g, bb


def in_gamut(rgb):
    return all(-1e-4 <= c <= 1 + 1e-4 for c in rgb)


def fit(L, C, h):
    """Reduce chroma until the colour is displayable (keeps L and h)."""
    while C > 0 and not in_gamut(oklch_to_srgb(L, C, h)):
        C -= 0.002
    return L, max(C, 0), h


def enc(c):
    c = min(max(c, 0), 1)
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def hexof(L, C, h):
    r, g, b = oklch_to_srgb(*fit(L, C, h))
    return '#%02X%02X%02X' % tuple(round(enc(x) * 255) for x in (r, g, b))


def rgb01(hx):
    return [int(hx[i:i + 2], 16) / 255 for i in (1, 3, 5)]


def lum(hx):
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(c) for c in rgb01(hx))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def to_oklab(hx):
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(c) for c in rgb01(hx))
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_, m_, s_ = (x ** (1 / 3) for x in (l, m, s))
    return (0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
            1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
            0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_)


def de(a, b):
    return math.dist(to_oklab(a), to_oklab(b))


def oklch_of(hx):
    L, a, b = to_oklab(hx)
    return L, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360

# ── the foundation ─────────────────────────────────────────────────────────
# Cool, near-neutral, identical lightness for every sport. Each sport may
# lean its surfaces a few degrees towards its own hue, never more than a
# whisper of chroma: the family reads as one product side by side.
SURFACE_L = (0.175, 0.225, 0.285)      # background, surface, elevated
SURFACE_C = (0.012, 0.014, 0.016)
FAMILY_HUE = 255                        # slate: cool, not navy


def surface_hue(accent_h):
    """Lean the slate at most 25° towards the sport's own hue."""
    d = ((accent_h - FAMILY_HUE + 180) % 360) - 180
    return (FAMILY_HUE + max(-25, min(25, d * 0.35))) % 360

# ── the fifteen sports ─────────────────────────────────────────────────────
# (key, 中文, primary (L, C, h, name), secondary (L, C, h, name), rationale)
# Primary accents sit in one lightness band (0.70–0.80) so no app shouts
# louder than another; secondaries are lower in chroma or lightness so the
# primary always leads.
SPORTS = [
    ('volleyball', '排球',
     (0.76, 0.165, 62, 'FIVB 球场橙'), (0.62, 0.13, 252, 'Taraflex 场外蓝'),
     '主色取 FIVB 比赛场地的橙色，副色是场外自由区的 Taraflex 蓝，两者就是一块国际排球场。'
     '与篮球同属暖橙，但排球偏黄、更亮，副色是冷蓝；篮球偏红、副色是木地板色。'),
    ('soccer', '足球',
     (0.74, 0.165, 145, '草皮绿'), (0.88, 0.035, 120, '白线粉笔色'),
     '主色是职业草皮的正绿，副色是场地白线那种略暖的粉笔白，克制、不抢主色。'
     '与羽毛球区分：足球绿偏黄、更鲜；羽毛球是偏青的球场垫绿。'),
    ('basketball', '篮球',
     (0.70, 0.170, 45, '篮球橙'), (0.74, 0.085, 70, '枫木地板'),
     '主色是篮球本身的橙红，副色是枫木地板的蜂蜜色，同一暖色家族里一主一辅。'
     '比排球橙更红、更深，副色是暖木色而非冷蓝。'),
    ('fieldHockey', '曲棍球',
     (0.76, 0.125, 236, '蓝色人造草'), (0.84, 0.110, 92, '比赛用球黄'),
     '主色是国际赛事蓝色人造草，副色是曲棍球常用的黄色比赛用球，蓝场上最醒目的那个点。'
     '与乒乓球区分：曲棍球是偏青的天蓝、更亮；乒乓球是更深的群青。'),
    ('tennis', '网球',
     (0.89, 0.185, 120, '荧光球黄'), (0.64, 0.130, 262, '硬地蓝'),
     '主色是网球本身的荧光黄绿，这是网球最无歧义的颜色；副色是大满贯硬地球场的蓝。'
     '与匹克球区分：匹克球以青绿球场为主色、黄球为辅；网球反过来，以荧光球为主、蓝场为辅，且黄更偏绿。'),
    ('rugby', '橄榄球',
     (0.72, 0.090, 60, '比赛用球皮革'), (0.62, 0.085, 155, '深草场绿'),
     '主色取橄榄球的皮革棕褐，副色是更深、更沉的草场绿，体现对抗型运动的厚重。'
     '与足球区分：足球以鲜绿为主色，橄榄球以皮革色为主、绿色只做辅助且更深。'),
    ('badminton', '羽毛球',
     (0.67, 0.120, 170, '比赛场地垫绿'), (0.80, 0.075, 72, '软木球托'),
     '主色是 BWF 比赛场地垫的青绿，副色是羽毛球软木球托的浅茶色。'
     '与足球区分：色相偏青约 25°、明度更低，像室内场地垫而不是草皮；副色是暖茶色而非白线。与匹克球区分：更绿、更深。'),
    ('tableTennis', '乒乓球',
     (0.60, 0.165, 252, 'ITTF 球台蓝'), (0.62, 0.150, 25, '赛场深红地板'),
     '主色是 ITTF 比赛球台的深蓝，副色是国际赛场常见的深红地板，蓝台红地是乒乓赛场的标准画面。'
     '与曲棍球区分：明度低一大截的深蓝，副色是红而非黄。'),
    ('pickleball', '匹克球',
     (0.75, 0.120, 194, '球场青绿'), (0.86, 0.110, 98, '洞洞球黄'),
     '主色是匹克球场蓝绿相接的青绿，副色是洞洞球的亮黄。'
     '与网球区分：主色是青绿球场而非荧光球；副色黄更暖，不带荧光绿。与水球区分：更深、更偏绿。'),
    ('baseball', '棒球',
     (0.63, 0.180, 22, '缝线红'), (0.68, 0.100, 55, '内野红土'),
     '主色是棒球缝线的红，副色是内野红土的赭色，经典棒球画面。'
     '与篮球区分：更深的绯红而非橙。与错误色错开：错误色更亮、偏粉，只用于提示，棒球红只做品牌。'),
    ('handball', '手球',
     (0.64, 0.160, 272, '室内场地钴蓝'), (0.72, 0.130, 50, '六米区橙'),
     '主色是室内手球场偏紫的钴蓝，副色是六米球门区的橙。'
     '与排球区分：排球以橙为主、蓝为辅，手球反过来。与乒乓球、曲棍球区分：色相更偏紫，三种蓝在明度和色相上都拉开。'),
    ('waterPolo', '水球',
     (0.83, 0.105, 212, '泳池水色'), (0.60, 0.100, 250, '深水区蓝'),
     '主色是比赛泳池明亮的青蓝水色，副色是深水区的蓝，整套都是水。'
     '与曲棍球、匹克球区分：明度最高、最浅的一种青，像水面反光；副色不用黄，避免和匹克球、曲棍球撞。'),
    ('sepakTakraw', '藤球',
     (0.79, 0.115, 88, '藤编金'), (0.64, 0.100, 150, '东南亚场馆绿'),
     '主色是藤编球的金色藤条，副色是东南亚藤球场馆常见的绿色场地。'
     '与排球区分：主色偏黄绿的藤色而非橙，副色是绿而非蓝。与沙滩网球、足排球区分：比沙色饱和，比巴西黄沉稳。'),
    ('beachTennis', '沙滩网球',
     (0.86, 0.068, 72, '细沙色'), (0.72, 0.066, 38, '日落珊瑚'),
     '主色是赛场细沙，低彩度、高明度；副色是沙滩赛事常用的珊瑚橙。'
     '与足排球区分：沙滩网球主色更淡更暖，副色是珊瑚；足排球主色更黄更浓，副色是海水青。'),
    ('footvolley', '足排球',
     (0.86, 0.170, 98, '巴西黄'), (0.72, 0.115, 200, '大西洋海水青'),
     '足排球起源于里约海滩，主色取巴西黄，副色是大西洋的海水青。'
     '与沙滩网球区分：彩度高一倍、色相偏黄，副色是冷色海水。与藤球区分：更亮更纯的黄，副色是海水青而非场馆绿。与网球区分：黄更暖、更饱和，副色是青而非硬地蓝。'),
]

# ── shared functional and tactical tokens ─────────────────────────────────
TEXT_L = (0.96, 0.76, 0.62, 0.46)   # primary, secondary, tertiary, disabled

def shared():
    h, c = FAMILY_HUE, 0.012
    return {
        'textPrimary': hexof(TEXT_L[0], 0.006, h),
        'textSecondary': hexof(TEXT_L[1], c, h),
        'textTertiary': hexof(TEXT_L[2], c, h),
        'textDisabled': hexof(TEXT_L[3], c, h),
        'divider': hexof(0.34, 0.014, h),
        'borderStrong': hexof(0.46, 0.016, h),
        'focus': hexof(0.80, 0.12, 230),
        'disabledFill': hexof(0.26, 0.010, h),
        'success': hexof(0.74, 0.150, 150),
        'warning': hexof(0.82, 0.150, 80),
        'error': hexof(0.71, 0.165, 10),
        'info': hexof(0.74, 0.120, 235),
        # Tactical annotations: one set for every sport, chosen against the
        # playing surfaces, not against the app chrome.
        'teamA': '#4D8FE8',
        'teamB': '#E86452',
        'movementPath': hexof(0.82, 0.140, 70),
        'passPath': '#FFFFFF',
        'ballPath': hexof(0.90, 0.170, 105),
        'selectedPlayer': '#FFFFFF',
        'highlightZone': hexof(0.85, 0.120, 195),
        'selectionIndicator': hexof(0.80, 0.12, 230),
    }


def build():
    out = []
    for key, zh, p, s, why in SPORTS:
        sh = surface_hue(p[2])
        bg, sf, el = (hexof(L, C, sh) for L, C in zip(SURFACE_L, SURFACE_C))
        pa, sa = hexof(*p[:3]), hexof(*s[:3])
        # Foreground on a filled accent: dark ink when the accent is light.
        on = hexof(0.20, 0.03, p[2]) if contrast(pa, '#141414') >= contrast(pa, '#FFFFFF') else '#FFFFFF'
        out.append({
            'sportId': key, 'nameZh': zh,
            'background': bg, 'surface': sf, 'elevatedSurface': el,
            'primaryAccent': pa, 'secondaryAccent': sa, 'onPrimaryAccent': on,
            'primaryName': p[3], 'secondaryName': s[3], 'rationale': why,
        })
    return out


def check(pals, tok):
    problems, lines = [], []
    # 1. equal lightness of each surface level
    for i, k in enumerate(('background', 'surface', 'elevatedSurface')):
        Ls = [oklch_of(p[k])[0] for p in pals]
        spread = max(Ls) - min(Ls)
        lines.append(f'{k:16} L {min(Ls):.3f}–{max(Ls):.3f}  spread {spread:.4f}')
        if spread > 0.006:
            problems.append(f'{k} lightness spread {spread:.4f}')
    # 2. hierarchy and contrast per sport
    for p in pals:
        pa, sa, bg, sf, el = (p[k] for k in ('primaryAccent', 'secondaryAccent', 'background', 'surface', 'elevatedSurface'))
        c_bg = contrast(pa, bg); c_el = contrast(pa, el); c_on = contrast(p['onPrimaryAccent'], pa)
        c_s = contrast(sa, bg)
        lines.append(f"{p['sportId']:12} P {pa} bg {c_bg:4.1f} el {c_el:4.1f} on {c_on:4.1f} | S {sa} bg {c_s:4.1f}")
        if c_bg < 4.5: problems.append(f"{p['sportId']} primary on background {c_bg:.2f} < 4.5")
        if c_el < 3.0: problems.append(f"{p['sportId']} primary on elevated {c_el:.2f} < 3")
        if c_on < 4.5: problems.append(f"{p['sportId']} text on primary {c_on:.2f} < 4.5")
        if c_s < 3.0: problems.append(f"{p['sportId']} secondary on background {c_s:.2f} < 3")
        Lp, Cp, _ = oklch_of(pa); Ls_, Cs, _ = oklch_of(sa)
        # Primary leads. A chromatic secondary carries less chroma than the
        # primary; a near-neutral one (chalk, cork) is quiet by nature.
        if Cs >= 0.05 and Cs > Cp + 0.002:
            problems.append(f"{p['sportId']} secondary chroma {Cs:.3f} > primary {Cp:.3f}")
    # 3. text tokens
    for k in ('textPrimary', 'textSecondary', 'textTertiary'):
        worst = min(contrast(tok[k], p['elevatedSurface']) for p in pals)
        need = 4.5 if k != 'textTertiary' else 3.0
        lines.append(f'{k:14} worst on elevated {worst:.2f} (need {need})')
        if worst < need: problems.append(f'{k} {worst:.2f} on elevated')
    # 4. distinctness of primaries (the App Store row)
    pairs = []
    for i in range(len(pals)):
        for j in range(i + 1, len(pals)):
            a, b = pals[i], pals[j]
            d1 = de(a['primaryAccent'], b['primaryAccent'])
            d2 = de(a['secondaryAccent'], b['secondaryAccent'])
            pairs.append((d1, d2, a['sportId'], b['sportId']))
    pairs.sort()
    lines.append('closest primaries (ΔE_ok primary / secondary):')
    for d1, d2, a, b in pairs[:8]:
        lines.append(f'   {a:12} {b:12} {d1:.3f} / {d2:.3f}')
        # Two sports may share a primary family only if the pair as a whole
        # (primary + secondary) is clearly different.
        if d1 < 0.045 or (d1 < 0.08 and d2 < 0.10):
            problems.append(f'{a} vs {b} too close ({d1:.3f}/{d2:.3f})')
    # 5. functional colours stay away from brand reds
    for p in pals:
        if de(p['primaryAccent'], tok['error']) < 0.06:
            problems.append(f"{p['sportId']} primary too close to error")
    return problems, lines


def dart(pals, tok):
    def c(hx):
        return f'Color(0xFF{hx[1:]})'
    rows = []
    for p in pals:
        rows.append(f"""  SportType.{p['sportId']}: SportColors(
    background: {c(p['background'])},
    surface: {c(p['surface'])},
    elevatedSurface: {c(p['elevatedSurface'])},
    primaryAccent: {c(p['primaryAccent'])},
    secondaryAccent: {c(p['secondaryAccent'])},
    onPrimaryAccent: {c(p['onPrimaryAccent'])},
  ),""")
    toks = '\n'.join(f'  static const {k} = {c(v)};' for k, v in tok.items())
    return f"""// GENERATED by tools/design/sport_palettes.py — do not edit by hand.
// The fifteen sports' colours and the tokens they share. Change the
// OKLCH values in the script and run it again.
import 'package:flutter/material.dart';

import '../models/sport_type.dart';

class SportColors {{
  const SportColors({{
    required this.background,
    required this.surface,
    required this.elevatedSurface,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.onPrimaryAccent,
  }});

  final Color background;
  final Color surface;
  final Color elevatedSurface;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color onPrimaryAccent;
}}

const Map<SportType, SportColors> kSportColors = {{
{chr(10).join(rows)}
}};

/// Shared by all fifteen apps: text, borders, states, and the tactical
/// annotations drawn on the board. Never per sport.
class FamilyTokens {{
{toks}
}}
"""


def html(pals, tok):
    cards = []
    for p in pals:
        sw = ''.join(
            f'<div class="sw"><i style="background:{p[k]}"></i><b>{lab}</b><code>{p[k]}</code></div>'
            for k, lab in (('background', '底色'), ('surface', '表面'), ('elevatedSurface', '浮层'),
                           ('primaryAccent', '主色'), ('secondaryAccent', '副色')))
        cards.append(f"""<div class="card" style="--bg:{p['background']};--sf:{p['surface']};--el:{p['elevatedSurface']};--pa:{p['primaryAccent']};--sa:{p['secondaryAccent']};--on:{p['onPrimaryAccent']}">
<div class="head"><span class="dot"></span><h3>{p['nameZh']}</h3><span class="id">{p['sportId']}</span></div>
<div class="sws">{sw}</div>
<div class="mock"><div class="btn">打开战术板</div><div class="ghost">新建</div><span class="tag">{p['primaryName']} · {p['secondaryName']}</span></div>
<p>{p['rationale']}</p></div>""")
    toks = ''.join(f'<div class="tk"><i style="background:{v}"></i><code>{k}</code><small>{v}</small></div>' for k, v in tok.items())
    t0 = tok
    return f"""<!doctype html><html lang="zh"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>战术板配色系统</title><style>
:root{{--page:#0A0D12;--ink:#E9EDF2;--muted:#8B95A3}}
body{{margin:0;background:var(--page);color:var(--ink);font-family:-apple-system,"PingFang SC",sans-serif;padding:28px 16px}}
h1{{font-size:24px;margin:0 0 6px}}h2{{font-size:17px;margin:36px 0 12px}}.sub{{color:var(--muted);font-size:14px;margin:0;max-width:900px;line-height:1.6}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(330px,1fr));gap:16px;margin-top:20px}}
.card{{background:var(--bg);border:1px solid {t0['divider']};border-radius:18px;padding:16px;display:flex;flex-direction:column;gap:12px}}
.head{{display:flex;align-items:center;gap:8px}}.head h3{{margin:0;font-size:17px;color:{t0['textPrimary']}}}.id{{margin-left:auto;font:12px ui-monospace,monospace;color:{t0['textTertiary']}}}
.dot{{width:12px;height:12px;border-radius:50%;background:var(--pa);box-shadow:0 0 0 3px var(--sa)}}
.sws{{display:grid;grid-template-columns:repeat(5,1fr);gap:6px}}.sw i{{display:block;height:46px;border-radius:9px;border:1px solid {t0['divider']}}}
.sw b{{display:block;font-size:11px;margin-top:5px;color:{t0['textSecondary']};font-weight:600}}.sw code{{font-size:10.5px;color:{t0['textTertiary']}}}
.mock{{background:var(--sf);border-radius:12px;padding:10px;display:flex;gap:8px;align-items:center;flex-wrap:wrap}}
.btn{{background:var(--pa);color:var(--on);border-radius:9px;padding:7px 12px;font-weight:700;font-size:13px}}.ghost{{background:var(--el);color:{t0['textPrimary']};border-radius:9px;padding:7px 12px;font-size:13px}}
.tag{{font-size:11px;color:var(--sa);margin-left:auto}}
.card p{{margin:0;font-size:12.5px;line-height:1.6;color:{t0['textSecondary']}}}
.toks{{display:grid;grid-template-columns:repeat(auto-fill,minmax(190px,1fr));gap:8px}}.tk{{display:flex;align-items:center;gap:8px;background:#121821;border-radius:10px;padding:8px}}.tk i{{width:22px;height:22px;border-radius:6px;border:1px solid #2a3340}}.tk code{{font-size:12px}}.tk small{{margin-left:auto;color:var(--muted);font-size:11px}}
</style></head><body>
<h1>战术板系列配色系统</h1>
<p class="sub">15 个运动共用同一套冷调近中性底色，三级表面在所有运动里感知明度完全一致（OKLCH L 0.175 / 0.225 / 0.285）。每个运动有一个主色和一个副色，主色统一在同一明度带内。功能色和战术标注色全系列共用，不随运动变化。</p>
<div class="grid">{''.join(cards)}</div>
<h2>全系列共用的设计令牌</h2><div class="toks">{toks}</div>
</body></html>"""


def main():
    pals = build()
    tok = shared()
    problems, lines = check(pals, tok)
    print('\n'.join(lines))
    if problems:
        print('\nPROBLEMS:'); print('\n'.join('  ' + p for p in problems))
        sys.exit(1)
    print('\n✓ all checks pass')
    if '--check' in sys.argv:
        return
    (REPO / 'tools/design/sport_palettes.json').write_text(json.dumps(
        {'sports': [{k: v for k, v in p.items() if k not in ('rationale',)} for p in pals],
         'shared': tok}, ensure_ascii=False, indent=2) + '\n')
    # Superseded 2026-10-15 by the light system (sport_palettes_light.py),
    # which owns tactics_board/lib/ui/sport_palettes.g.dart now.
    (REPO / 'build').mkdir(exist_ok=True)
    (REPO / 'build/sport_palette_review.html').write_text(html(pals, tok))
    print('wrote json, dart, html')


if __name__ == '__main__':
    main()
