#!/usr/bin/env python3
"""The light theme of the fifteen tactics-board apps (2026-10-15).

The values are the brief's, as given. What this script adds is what a light
theme needs and the brief leaves open: for each accent, the ink that reads on
it (dark or white), and a text variant — the same hue darkened in OKLCH just
enough to reach 4.5:1 on white — for links, selected labels and icons, since
several brand accents (tennis, beach tennis, footvolley...) are fills, not
text colours, on a white card. It also measures how close the accents are.

    tools/design/sport_palettes_light.json
    build/sport_palette_light.html  (and a copy in reports/)
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from sport_palettes import contrast, de, oklch_of, hexof  # noqa: E402

REPO = Path(__file__).resolve().parents[2]

SHARED = {
    'pageBackground': '#F3F0E8', 'appBackground': '#F6F4EE',
    'surface': '#FFFFFF', 'elevatedSurface': '#EEF3F8',
    'secondarySurface': '#F7F9FC', 'border': '#D8E0E8',
    'textPrimary': '#16212E', 'textSecondary': '#5F6B7A', 'textTertiary': '#8A97A6',
    'success': '#22A06B', 'warning': '#D99A1A', 'error': '#D64545',
    'info': '#2F80ED', 'disabled': '#C8D0D9', 'focus': '#1F6FEB',
}

# key, 中文, English, primary, secondary, court reference, rationale
SPORTS = [
    ('volleyball', '排球', 'Volleyball', '#2D6CDF', '#7DB7FF', '#4B86D9',
     '主色取国际赛事 Taraflex 场地的竞技蓝，副色是同色系的浅蓝，一深一浅，冷静专业。'),
    ('soccer', '足球', 'Soccer', '#2E9E44', '#8BCF67', '#4C9B52',
     '主色是职业草皮的正绿，副色是新草的浅绿，像修剪过的条纹草坪。'),
    ('basketball', '篮球', 'Basketball', '#F28B2D', '#FFB566', '#C88A4A',
     '主色是篮球的橙，副色是木地板反光的暖杏色，整套都是室内球馆的暖调。'),
    ('fieldHockey', '曲棍球', 'Field Hockey', '#1F8AE0', '#E3C86C', '#4F8FD8',
     '主色是蓝色人造草，副色是比赛用球的黄，蓝场上最醒目的那个点。'),
    ('tennis', '网球', 'Tennis', '#C7D93B', '#6E95DD', '#4D77C4',
     '主色是网球的荧光黄绿，副色是硬地球场的蓝，球与场组成网球最典型的画面。'),
    ('rugby', '橄榄球', 'Rugby', '#B98056', '#6FA570', '#5A8F54',
     '主色是橄榄球皮革的棕褐，副色是草场绿，体现对抗型运动的厚重。'),
    ('badminton', '羽毛球', 'Badminton', '#37A866', '#D8B688', '#4E9E63',
     '主色是比赛场地垫的绿，副色是软木球托的浅茶色，室内、轻盈。'),
    ('tableTennis', '乒乓球', 'Table Tennis', '#2F86D9', '#E15C56', '#2E79C7',
     '主色是球台蓝，副色是赛场红地板，蓝台红地是乒乓赛场的标准配色。'),
    ('pickleball', '匹克球', 'Pickleball', '#26C2BF', '#D7C96E', '#4F8EC8',
     '主色是球场蓝绿交界的青绿，副色是洞洞球的黄。'),
    ('baseball', '棒球', 'Baseball', '#E2555B', '#C98E57', '#B97B4E',
     '主色是棒球缝线的红，副色是内野红土的赭色，经典棒球画面。'),
    ('handball', '手球', 'Handball', '#6B82DE', '#E59B55', '#C9915A',
     '主色是室内场地的钴蓝，副色是六米球门区的橙。'),
    ('waterPolo', '水球', 'Water Polo', '#59C3E8', '#5E8FC8', '#49A8D8',
     '主色是泳池明亮的水色，副色是深水区的蓝，整套都是水。'),
    ('sepakTakraw', '藤球', 'Sepak Takraw', '#D7B250', '#67A56C', '#C49D57',
     '主色是藤编球的金色藤条，副色是东南亚场馆的绿色场地。'),
    ('beachTennis', '沙滩网球', 'Beach Tennis', '#E1C79B', '#CFA087', '#D9C29D',
     '主色是赛场细沙，副色是沙滩赛事的珊瑚色，最柔和的一套。'),
    ('footvolley', '足排球', 'Footvolley', '#E1C83C', '#39B9C8', '#D6C18E',
     '主色是里约海滩的巴西黄，副色是大西洋的海水青。'),
]

INK = SHARED['textPrimary']


def text_variant(hx, on='#FFFFFF', need=4.5):
    """The accent's hue, darkened in OKLCH until it reads on [on]."""
    if contrast(hx, on) >= need:
        return hx
    L, C, h = oklch_of(hx)
    while L > 0.2:
        L -= 0.005
        cand = hexof(L, C, h)
        if contrast(cand, on) >= need:
            return cand
    return INK


def build():
    out = []
    for key, zh, en, pa, sa, court, why in SPORTS:
        on = INK if contrast(INK, pa) >= contrast('#FFFFFF', pa) else '#FFFFFF'
        out.append({
            'sportId': key, 'nameZh': zh, 'nameEn': en,
            'background': SHARED['appBackground'], 'surface': SHARED['surface'],
            'elevatedSurface': SHARED['elevatedSurface'],
            'primaryAccent': pa, 'secondaryAccent': sa,
            'onPrimaryAccent': on,
            'primaryAccentText': text_variant(pa),
            'secondaryAccentText': text_variant(sa),
            'courtReference': court, 'rationale': why,
        })
    return out


def report(pals):
    rows = []
    for p in pals:
        rows.append((p['sportId'], p['primaryAccent'],
                     contrast(p['primaryAccent'], '#FFFFFF'),
                     contrast(p['onPrimaryAccent'], p['primaryAccent']),
                     p['onPrimaryAccent'], p['primaryAccentText'],
                     contrast(p['secondaryAccent'], '#FFFFFF')))
    print(f"{'sport':12} {'primary':8} {'on white':>8} {'label':>6} ink     text-variant  {'2nd on white':>12}")
    for r in rows:
        print(f'{r[0]:12} {r[1]} {r[2]:8.2f} {r[3]:6.2f} {r[4]} {r[5]}  {r[6]:12.2f}')
    pairs = sorted((de(a['primaryAccent'], b['primaryAccent']), a['sportId'], b['sportId'])
                   for i, a in enumerate(pals) for b in pals[i + 1:])
    print('closest primaries (ΔE_ok):')
    for d, a, b in pairs[:6]:
        print(f'   {a:12} {b:12} {d:.3f}')
    for k in ('textPrimary', 'textSecondary', 'textTertiary'):
        print(f"{k:14} on white {contrast(SHARED[k], '#FFFFFF'):.2f}  on elevated {contrast(SHARED[k], SHARED['elevatedSurface']):.2f}")
    return pairs


def html(pals):
    S = SHARED
    def sw(hx, lab):
        return (f'<div class="sw"><i style="background:{hx}"></i><b>{lab}</b>'
                f'<code>{hx}</code></div>')
    cards = []
    for i, p in enumerate(pals, 1):
        cards.append(f"""<article class="card" style="--pa:{p['primaryAccent']};--sa:{p['secondaryAccent']};--on:{p['onPrimaryAccent']};--pt:{p['primaryAccentText']}">
<header><span class="no">{i:02d}</span><div><h3>{p['nameZh']}</h3><span class="en">{p['nameEn']} · <code>{p['sportId']}</code></span></div><span class="court" title="球场参考色" style="background:{p['courtReference']}"></span></header>
<div class="sws">{sw(p['background'],'Background')}{sw(p['surface'],'Surface')}{sw(p['elevatedSurface'],'Elevated')}{sw(p['primaryAccent'],'Primary')}{sw(p['secondaryAccent'],'Secondary')}</div>
<div class="demo"><span class="btn">打开战术板</span><span class="ghost">新建</span><span class="link">全部训练 →</span></div>
<p>{p['rationale']}</p></article>""")
    shared = ''.join(f'<div class="tk"><i style="background:{v}"></i><span>{k}</span><code>{v}</code></div>' for k, v in S.items())
    return f"""<!doctype html><html lang="zh"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>浅色配色系统</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
:root{{color-scheme:light}}
body{{margin:0;background:{S['pageBackground']};color:{S['textPrimary']};font-family:Inter,-apple-system,"PingFang SC",sans-serif;padding:48px 16px 64px}}
.wrap{{max-width:1240px;margin:0 auto}}
.kicker{{font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:{S['textSecondary']};font-weight:600}}
h1{{font-size:32px;letter-spacing:-.02em;margin:8px 0 10px}}.lede{{color:{S['textSecondary']};font-size:15px;line-height:1.65;max-width:760px;margin:0}}
h2{{font-size:13px;letter-spacing:.12em;text-transform:uppercase;color:{S['textSecondary']};margin:56px 0 16px;font-weight:600}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(360px,1fr));gap:20px;margin-top:36px}}
.card{{background:{S['surface']};border:1px solid {S['border']};border-radius:20px;padding:22px;box-shadow:0 1px 2px rgba(22,33,46,.04),0 8px 24px rgba(22,33,46,.05);display:flex;flex-direction:column;gap:16px}}
header{{display:flex;align-items:center;gap:12px}}.no{{font:600 12px Inter,sans-serif;color:{S['textTertiary']};width:22px}}
header h3{{margin:0;font-size:19px;letter-spacing:-.01em}}.en{{font-size:12.5px;color:{S['textSecondary']}}}.en code{{font-size:11.5px;color:{S['textTertiary']}}}
.court{{margin-left:auto;width:30px;height:30px;border-radius:9px;box-shadow:inset 0 0 0 1px rgba(22,33,46,.08)}}
.sws{{display:grid;grid-template-columns:repeat(5,1fr);gap:8px}}.sw i{{display:block;height:58px;border-radius:12px;box-shadow:inset 0 0 0 1px {S['border']}}}
.sw b{{display:block;font-size:10.5px;font-weight:600;margin-top:7px;color:{S['textSecondary']};letter-spacing:.02em}}.sw code{{font-size:10.5px;color:{S['textTertiary']}}}
.demo{{background:{S['elevatedSurface']};border-radius:14px;padding:10px;display:flex;align-items:center;gap:8px}}
.btn{{background:var(--pa);color:var(--on);font-weight:600;font-size:13px;border-radius:10px;padding:8px 14px}}
.ghost{{background:{S['surface']};border:1px solid {S['border']};font-size:13px;border-radius:10px;padding:7px 13px}}
.link{{margin-left:auto;color:var(--pt);font-weight:600;font-size:13px}}
.card p{{margin:0;font-size:13px;line-height:1.65;color:{S['textSecondary']}}}
.toks{{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:10px}}
.tk{{background:{S['surface']};border:1px solid {S['border']};border-radius:12px;padding:10px 12px;display:flex;align-items:center;gap:10px;font-size:13px}}
.tk i{{width:22px;height:22px;border-radius:7px;box-shadow:inset 0 0 0 1px rgba(22,33,46,.1)}}.tk code{{margin-left:auto;font-size:12px;color:{S['textTertiary']}}}
.note{{font-size:13px;color:{S['textSecondary']};line-height:1.65;max-width:820px}}
</style></head><body><div class="wrap">
<div class="kicker">Tactics Board · Design System</div>
<h1>浅色配色系统</h1>
<p class="lede">15 个运动共用同一套暖白底和白色卡片，只靠主色和副色区分运动。卡片右上角的小色块是该运动的球场参考色，它属于战术板画面，不是界面背景。示例按钮里的文字颜色和右侧链接颜色是按对比度自动选的：浅色主色上用深色文字，链接用同色相加深的变体。</p>
<div class="grid">{''.join(cards)}</div>
<h2>全系列共用</h2><div class="toks">{shared}</div>
</div></body></html>"""


def main():
    pals = build()
    report(pals)
    (REPO / 'tools/design/sport_palettes_light.json').write_text(json.dumps(
        {'shared': SHARED, 'sports': [{k: v for k, v in p.items() if k != 'rationale'} for p in pals]},
        ensure_ascii=False, indent=2) + '\n')
    page = html(pals)
    (REPO / 'build/sport_palette_light.html').write_text(page)
    (REPO / 'reports/浅色配色系统_2026-10-15.html').write_text(page)
    print('wrote json + html')


if __name__ == '__main__':
    main()
