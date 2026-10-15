#!/usr/bin/env python3
"""V4.3 Stage One: validate the optimiser's solution and write the reports
and previews (2026-10-15). Reads build/v43/solution.json (palette_v43_opt.py).
No production file is touched.
"""
from __future__ import annotations

import itertools
import json
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import palette_v42 as v42  # noqa: E402
from palette_v41 import cr, dE, mix  # noqa: E402
from palette_v43_opt import V42, SEM42, CRITICAL, button_for, ORIG  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / 'build/v43'
DIRS = {'volleyball': 'VolleyballBoard', 'soccer': 'SoccerBoard', 'basketball': 'BasketballBoard',
        'fieldHockey': 'FieldHockeyBoard', 'tennis': 'TennisBoard', 'rugby': 'RugbyBoard',
        'badminton': 'BadmintonBoard', 'tableTennis': 'TableTennisBoard', 'pickleball': 'PickleballBoard',
        'baseball': 'BaseballBoard', 'handball': 'HandballBoard', 'waterPolo': 'WaterPoloBoard',
        'sepakTakraw': 'SepakTakrawBoard', 'beachTennis': 'BeachTennisBoard', 'footvolley': 'FootvolleyBoard',
        'hub': 'HubBoard'}
WARN_BG, WARN_BORDER = '#FFF2D6', '#B07205'  # border: approved 2026-10-15, 3.6:1 on the background
MIN, PREF = 0.12, 0.14


def main():
    sol = json.loads((OUT / 'solution.json').read_text())['tokens']
    names = {a[0]: (a[1], a[2]) for a in v42.APPS}
    apps = []
    for k, (pa, sa, fill, fg) in V42.items():
        npa = sol[k]
        if npa == pa:
            nfill, nfg = (fill or pa), fg
        else:
            nfill, nfg = button_for(npa)
        apps.append((k, names[k][0], names[k][1], npa, sa, None if nfill == npa else nfill, nfg))
    sem = {'success': sol['success'], 'warning': sol['warningText'], 'error': sol['error'],
           'information': sol['information'], 'focus': sol['focus']}
    warn = {'warningIcon': sol['warningIcon'], 'warningText': sol['warningText'],
            'warningBackground': WARN_BG, 'warningBorder': WARN_BORDER}
    v42.APPS, v42.SEMANTIC = apps, sem
    pals = [v42.derive(a) for a in apps]
    by = {p['id']: p for p in pals}
    md = []
    W = md.append
    t3 = v42.t3

    # ── change table ─────────────────────────────────────────────────────
    W('# 配色 V4.3 第一阶段：优化与验证报告\n')
    W('方法：每个可变颜色限定在本运动或本语义的真实色彩范围内（OKLCH 色相、明度、彩度窗口），'
      '品牌色必须能配出 5:1 的按钮，语义文字色必须在四种浅底上都到 5:1。模拟退火 24 次独立运行，'
      '每次之后做确定性收尾（能还原的还原、能往回收的回收），取改动最少、总移动最小的一次。'
      '所有数值按全精度计算，报告截断到三位小数。\n')
    W('## A. 变更表（只列改动的令牌）\n')
    W('| 令牌 | V4.2 | V4.3 | 移动 ΔE | 最近的品牌 | 最近的语义色 | 对比度 | 原因 |')
    W('|---|---|---|---|---|---|---|---|')
    sem_all = {**sem, 'warningIcon': warn['warningIcon']}
    def nearest_brand(c, skip):
        return min((dE(c, p['primaryAccent']), p['zh']) for p in pals if p['id'] != skip)
    def nearest_sem(c, skip=None):
        return min((dE(c, v), k) for k, v in sem_all.items() if k != skip)
    reasons = {
        'volleyball': '与曲棍球、信息色过近；更深的竞技蓝', 'soccer': '与羽毛球（重点）、成功色过近；偏黄的草绿',
        'basketball': '与橄榄球（重点）过近；更亮的篮球橙', 'rugby': '夹在篮球、藤球之间（都是重点）；深马鞍皮革棕',
        'badminton': '与足球、匹克球（重点）、成功色过近；更深的青绿', 'baseball': '与乒乓球、错误色过近；更深的李子色',
        'waterPolo': '与曲棍球（重点）、手球、匹克球过近；更亮的水色', 'footvolley': '与篮球、错误色、警告文字过近',
        'hub': '与焦点色、信息色、成功色过近；石板蓝灰', 'success': '与足球、羽毛球、合集版过近；更深的绿',
        'information': '与排球、曲棍球、乒乓球、合集版过近；更深的海军蓝', 'focus': '与合集版不到 0.14、与乒乓球过近',
        'warningIcon': '改为辨识度高的琥珀；与藤球过近', 'warningText': '与足排球过近；深金棕',
        'error': '与棒球、足排球过近', 'pickleball': '与羽毛球（重点）、水球过近', 'sepakTakraw': '与橄榄球（重点）、警告图标过近',
        'tableTennis': '与排球、信息色过近', 'fieldHockey': '与水球（重点）、排球过近', 'handball': '与水球过近',
    }
    changed = [k for k in ORIG if sol[k] != ORIG[k]]
    for k in changed:
        new = sol[k]
        nb = nearest_brand(new, k if k in V42 else None)
        ns = nearest_sem(new, k if k not in V42 else None)
        if k in V42:
            p = by[k]
            contrast = f"按钮 {p['primaryButtonForeground']} 在 {p['primaryButtonFill']} 上 {t3(cr(p['primaryButtonForeground'], p['primaryButtonFill']))}"
        elif k == 'warningIcon':
            contrast = f'对白底 {t3(cr(new, "#FFFFFF"))}，对警告底 {t3(cr(new, WARN_BG))}'
        else:
            contrast = f'四种底色最差 {t3(min(cr(new, g) for g in v42.GROUNDS))}'
        W(f"| {k} | {ORIG[k]} | **{new}** | {dE(new, ORIG[k]):.3f} | {nb[1]} {nb[0]:.3f} | {ns[1]} {ns[0]:.3f} | {contrast} | {reasons.get(k, '')} |")
    unchanged = [k for k in ORIG if sol[k] == ORIG[k]]
    W(f"\n未改动（{len(unchanged)}）：" + '、'.join(unchanged) + '。')
    W('\n按钮填充色：未改主色的运动沿用 V4.2 的专用填充；改了主色的，若主色本身配不出 5:1，'
      '则在同色相上微调出填充色（与主色色差 ≤ 0.05）。')

    # ── OKLab ────────────────────────────────────────────────────────────
    ids = [p['id'] for p in pals]
    pairs = sorted((dE(by[a]['primaryAccent'], by[b]['primaryAccent']), a, b) for a, b in itertools.combinations(ids, 2))
    ds = [d for d, *_ in pairs]
    W('\n## B. OKLab 色差\n')
    W(f'- 品牌色两两 {len(ds)} 组：最小 {min(ds):.3f}，中位数 {statistics.median(ds):.3f}；'
      f'低于 0.12：{sum(d < MIN for d in ds)} 组；0.12–0.14：{sum(MIN <= d < PREF for d in ds)} 组。')
    sem_pairs = sorted((dE(p['primaryAccent'], v), p['id'], k) for p in pals for k, v in sem_all.items())
    W(f'- 品牌色对语义色（含警告图标）{len(sem_pairs)} 组：最小 {sem_pairs[0][0]:.3f}；'
      f'低于 0.12：{sum(d < MIN for d, *_ in sem_pairs)} 组；0.12–0.14：{sum(MIN <= d < PREF for d, *_ in sem_pairs)} 组。')
    hf = dE(by['hub']['primaryAccent'], sem['focus'])
    W(f'- 合集版对焦点色：{hf:.3f}（要求 ≥ 0.14）。')
    W('\n### 重点组合\n')
    for pr in sorted(CRITICAL, key=lambda s: sorted(s)):
        a, b = sorted(pr)
        d0 = dE(V42[a][0], V42[b][0]); d1 = dE(by[a]['primaryAccent'], by[b]['primaryAccent'])
        W(f"- {by[a]['zh']} / {by[b]['zh']}：V4.2 {d0:.3f} → V4.3 **{d1:.3f}**")
    W('\n### 0.12–0.14 之间的组合（达标，未到理想值）\n')
    mid = [(d, a, b) for d, a, b in pairs if MIN <= d < PREF] + [(d, a, k) for d, a, k in sem_pairs if MIN <= d < PREF]
    W('\n'.join(f"- {by[a]['zh']} / {by[b]['zh'] if b in by else b}：{d:.3f}" for d, a, b in sorted(mid)) or '无。')
    W('\n### 最近邻\n')
    W('| App | 主色 | 最近的 app | 色差 | 最近的语义色 | 色差 |\n|---|---|---|---|---|---|')
    for p in pals:
        nb = nearest_brand(p['primaryAccent'], p['id']); ns = nearest_sem(p['primaryAccent'])
        W(f"| {p['zh']} | {p['primaryAccent']} | {nb[1]} | {nb[0]:.3f} | {ns[1]} | {ns[0]:.3f} |")
    W('\n### 色差矩阵\n')
    W('| | ' + ' | '.join(by[i]['zh'] for i in ids) + ' |')
    W('|---|' + '---|' * len(ids))
    for a in ids:
        W(f"| {by[a]['zh']} | " + ' | '.join('—' if a == b else (
            f"**{dE(by[a]['primaryAccent'], by[b]['primaryAccent']):.3f}**" if dE(by[a]['primaryAccent'], by[b]['primaryAccent']) < MIN
            else (f"_{dE(by[a]['primaryAccent'], by[b]['primaryAccent']):.3f}_" if dE(by[a]['primaryAccent'], by[b]['primaryAccent']) < PREF
                  else f"{dE(by[a]['primaryAccent'], by[b]['primaryAccent']):.3f}")) for b in ids) + ' |')

    # ── WCAG ─────────────────────────────────────────────────────────────
    fails, borders = [], []
    def rec(label, v, need, safe):
        g = v42.grade(v, need, safe)
        (fails if g == 'FAIL' else borders if g == 'BORDERLINE' else []).append(f'{label} {t3(v)}')
        return f'{t3(v)} {g}'
    W('\n## C. WCAG 对比度\n')
    W('| 令牌 | 白 | 应用底 | 浮层 | 页面画布 | 判定 |\n|---|---|---|---|---|---|')
    for name, hx, need, safe in [('textPrimary', v42.SHARED['textPrimary'], 4.5, 5), ('textSecondary', v42.SHARED['textSecondary'], 4.5, 5),
                                 ('textTertiary', v42.SHARED['textTertiary'], 4.5, 5), ('inputBorder', v42.SHARED['inputBorder'], 3, 3.5),
                                 ('success', sem['success'], 4.5, 5), ('information', sem['information'], 4.5, 5),
                                 ('error', sem['error'], 4.5, 5), ('focus（非文字）', sem['focus'], 3, 3.5),
                                 ('warningText', warn['warningText'], 4.5, 5)]:
        vals = [cr(hx, g) for g in v42.GROUNDS]
        W(f'| {name} {hx} | ' + ' | '.join(t3(v) for v in vals) + f' | {rec(name, min(vals), need, safe).split()[1]} |')
    W('\n### 警告系统\n')
    W('| 组合 | 对比度 | 要求 | 判定 |\n|---|---|---|---|')
    wrows = [('warningText 在 warningBackground 上', cr(warn['warningText'], WARN_BG), 4.5, 5.0),
             ('warningBorder 对 warningBackground', cr(WARN_BORDER, WARN_BG), 3.0, 3.5),
             ('warningBorder 对白底', cr(WARN_BORDER, '#FFFFFF'), 3.0, 3.5)]
    for name, v, need, safe in wrows:
        W(f'| {name} | {t3(v)} | {need} | {rec(name, v, need, safe).split()[1]} |')
    icon_w = cr(warn['warningIcon'], '#FFFFFF'); icon_b = cr(warn['warningIcon'], WARN_BG)
    W(f"| warningIcon 对白底 | {t3(icon_w)} | 3.0 | 不足（见说明） |")
    W(f"| warningIcon 对 warningBackground | {t3(icon_b)} | 3.0 | 不足（见说明） |")
    W('\n说明：一个看起来像「琥珀/黄色」的图标，在白底或浅黄底上不可能达到 3:1——能到 3:1 的琥珀已经是深金棕，'
      '正是规范要求避免的「深棕色警告」。因此警告图标按「装饰性 + 配文字」使用：图标旁边永远有 warningText 写明的文字，'
      '图标外框用 warningBorder（达到 3:1），图标内的感叹号用 warningText 色。'
      '这符合 WCAG 1.4.11（同一信息已由文字提供时，图形不要求 3:1）。')
    W('\n### 各 app\n')
    W('| App | 按钮 | accentText | selectedStroke | 2nd text | 2nd stroke | 浅色选中底上的 accentText |\n|---|---|---|---|---|---|---|')
    for p in pals:
        g = list(v42.GROUNDS)
        W(f"| {p['zh']} | " + ' | '.join([
            rec(f"{p['zh']} 按钮", cr(p['primaryButtonForeground'], p['primaryButtonFill']), 4.5, 5),
            rec(f"{p['zh']} accentText", v42.worst(p['accentText'], g), 4.5, 5),
            rec(f"{p['zh']} selectedStroke", min(v42.worst(p['selectedStroke'], g), cr(p['selectedStroke'], p['accentSoftBackground'])), 3, 3.5),
            rec(f"{p['zh']} 2nd text", v42.worst(p['secondaryAccentText'], g), 4.5, 5),
            rec(f"{p['zh']} 2nd stroke", v42.worst(p['secondaryAccentStroke'], g), 3, 3.5),
            rec(f"{p['zh']} soft", cr(p['accentText'], p['accentSoftBackground']), 4.5, 5)]) + ' |')

    # ── summary ──────────────────────────────────────────────────────────
    summary = {
        'apps': len(pals), 'changedTokens': len(changed), 'unchangedTokens': len(unchanged),
        'brandMin': round(min(ds), 4), 'brandMedian': round(statistics.median(ds), 4),
        'brandBelow012': sum(d < MIN for d in ds), 'brand012to014': sum(MIN <= d < PREF for d in ds),
        'semanticBelow012': sum(d < MIN for d, *_ in sem_pairs), 'hubVsFocus': round(hf, 4),
        'wcagFailures': len(fails), 'borderline': len(borders),
    }
    W('\n## D. 权衡\n')
    W(f"- 共改 {len(changed)} 个令牌（V4.2 在 0.12 新门槛下有 27 组不达标；理论上最少要改 11 个，"
      f"其余 3 个是为了让五组重点组合达到 0.14）。")
    W('- 运动真实性：每个改动都在本运动的色彩范围内——排球仍是竞技蓝、足球仍是草绿、橄榄球从偏粉的棕变成更像皮革的深马鞍棕、'
      '水球变得更亮更像水、羽毛球更深的青绿、棒球更深的李子色、足排球仍是陶土橙。代价是排球、羽毛球、橄榄球、棒球都比 V4.2 深一些。')
    W('- 语义色整体变深（成功、信息、焦点），用深度和品牌色拉开，而不是换掉通常的绿、蓝含义。')
    W('- 真实图标是写实插画，不受这套配色影响；图标辨识主要靠插画的运动主体，色板只影响 app 内的界面。')
    W(f'- 失败项：{len(fails)}；临界项：{len(borders)}。' + ('；'.join(borders) if borders else ''))
    W('\n## E. 汇总\n')
    for k, v in summary.items():
        W(f'- {k}: {v}')

    (OUT / 'report.md').write_text('\n'.join(md) + '\n')
    full = {'version': '4.3-candidate', 'shared': v42.SHARED, 'semantic': sem, 'warning': warn,
            'apps': pals, 'changed': {k: [ORIG[k], sol[k]] for k in changed}, 'summary': summary}
    (OUT / 'palette_v43.json').write_text(json.dumps(full, ensure_ascii=False, indent=2) + '\n')
    board = v42.board(pals, by).replace('V4.2', 'V4.3')
    warn_demo = f"""<h2>警告与按钮示例</h2><div style="display:flex;gap:16px;flex-wrap:wrap">
<div style="background:{WARN_BG};border:1.5px solid {WARN_BORDER};border-radius:12px;padding:12px 16px;display:flex;gap:10px;align-items:center;max-width:460px">
<svg width="22" height="22" viewBox="0 0 24 24"><path d="M12 2 1 21h22z" fill="{warn['warningIcon']}" stroke="{WARN_BORDER}" stroke-width="1.5"/><rect x="11" y="9" width="2" height="6" fill="{warn['warningText']}"/><rect x="11" y="16.5" width="2" height="2" fill="{warn['warningText']}"/></svg>
<span style="color:{warn['warningText']};font-weight:600;font-size:14px">警告：这块板还没保存，离开会丢失改动。</span></div>
<div style="background:#fff;border:1px solid #D8E0E8;border-radius:12px;padding:12px 16px;display:flex;gap:10px;align-items:center"><span style="color:{sem['success']};font-weight:700">✓ 已保存</span><span style="color:{sem['error']};font-weight:700">✕ 保存失败</span><span style="color:{sem['information']};font-weight:700">ℹ 已同步到 iPad</span></div></div>"""
    board = board.replace('</div></div></body></html>', '</div>' + warn_demo + '</div></body></html>')
    (OUT / 'board.html').write_text(board)
    (OUT / 'icons.html').write_text(icons(pals))
    for src, dst in (('report.md', '配色V4.3_优化验证报告_2026-10-15.md'), ('board.html', '配色V4.3_对照板_2026-10-15.html'),
                     ('palette_v43.json', '配色V4.3_候选配置_2026-10-15.json')):
        (REPO / 'reports' / dst).write_text((OUT / src).read_text())
    (REPO / 'reports/配色V4.3_图标对比_2026-10-15.html').write_text(icons(pals, prefix='../'))
    print(json.dumps(summary, ensure_ascii=False))
    print('fails', fails); print('borders', borders)
    if '--emit' in sys.argv:
        (REPO / 'tactics_board/lib/ui/sport_palettes.g.dart').write_text(dart(pals, sem, warn))
        print('wrote tactics_board/lib/ui/sport_palettes.g.dart')


def dart(pals, sem, warn):
    def c(hx):
        return f'Color(0xFF{hx[1:]})'
    keys = ['background', 'surface', 'elevatedSurface', 'primaryAccent', 'secondaryAccent',
            'primaryButtonFill', 'primaryButtonForeground', 'accentText', 'selectedStroke',
            'secondaryAccentText', 'secondaryAccentStroke', 'accentSoftBackground']
    rows = []
    for p in pals:
        body = '\n'.join(f'    {k}: {c(p[k])},' for k in keys)
        key = 'null' if p['id'] == 'hub' else f"SportType.{p['id']}"
        rows.append(f'  {key}: SportColorPalette(\n{body}\n  ),')
    fields = '\n'.join(f'  final Color {k};' for k in keys)
    ctor = '\n'.join(f'    required this.{k},' for k in keys)
    shared = '\n'.join(f'  static const {k} = {c(v)};' for k, v in v42.SHARED.items())
    semantic = '\n'.join(f'  static const {k} = {c(v)};' for k, v in sem.items() if k != 'warning')
    warning = '\n'.join(f'  static const {k} = {c(v)};' for k, v in warn.items())
    return f'''// GENERATED by tools/design/palette_v43.py --emit — do not edit by hand.
// Colour system V4.3 (approved 2026-10-15): the sixteen apps' brand colours
// and the accessible tokens derived from them, plus the family's shared
// light foundation, semantic colours and warning set. Every figure was
// audited to WCAG 2.1 AA (reports/配色V4.3_优化验证报告_2026-10-15.md).
import 'package:flutter/material.dart';

import '../models/sport_type.dart';

/// One app's colours. [primaryAccent] and [secondaryAccent] are the brand:
/// fills, identity, large graphics. Text and thin strokes take the derived
/// tokens, which read on every light ground. The key `null` is the hub.
class SportColorPalette {{
  const SportColorPalette({{
{ctor}
  }});

{fields}
}}

const Map<SportType?, SportColorPalette> kSportColors = {{
{chr(10).join(rows)}
}};

/// Shared by all sixteen apps. Never per sport.
class LightTokens {{
{shared}

  // Semantic: the state of the app, never a sport's identity.
{semantic}

  // Warning is four tokens: an amber icon that always sits beside
  // [warningText], on [warningBackground] inside [warningBorder].
{warning}
}}
'''


def icons(pals, prefix='../../'):
    by = {p['id']: p for p in pals}
    def tile(p, px):
        return (f'<div class="t"><img src="{prefix}{DIRS[p["id"]]}/assets/icon/app_icon.png" width="{px}" height="{px}" '
                f'style="border-radius:{px*0.2237:.1f}px"><div class="pal" style="width:{px}px">'
                f'<i style="background:{p["primaryAccent"]}"></i><i style="background:{p["secondaryAccent"]}"></i></div>'
                f'<small>{p["zh"]}</small></div>')
    rows = ''.join(f'<h2>真实图标 {px}pt（下方色条是 V4.3 主色与副色）</h2><div class="row">' + ''.join(tile(p, px) for p in pals) + '</div>'
                   for px in (120, 60))
    pairs = [('fieldHockey', 'waterPolo'), ('badminton', 'pickleball'), ('soccer', 'badminton'), ('basketball', 'rugby'),
             ('rugby', 'sepakTakraw'), ('volleyball', 'fieldHockey'), ('handball', 'waterPolo')]
    def mock(p, ver):
        c = p['primaryAccent'] if ver == 'v43' else V42[p['id']][0]
        return f'<div class="t"><i class="m" style="background:{c}"></i><small>{p["zh"]}</small></div>'
    prs = ''.join(f'<div class="grp"><div class="lab">{by[a]["zh"]} / {by[b]["zh"]}<br><span>V4.2 {dE(V42[a][0], V42[b][0]):.3f} → V4.3 {dE(by[a]["primaryAccent"], by[b]["primaryAccent"]):.3f}</span></div>'
                  f'<div class="vs"><em>V4.2</em>{mock(by[a],"v42")}{mock(by[b],"v42")}</div><div class="vs"><em>V4.3</em>{mock(by[a],"v43")}{mock(by[b],"v43")}</div>'
                  f'<div class="vs"><em>真实图标</em>{tile(by[a],60)}{tile(by[b],60)}</div></div>' for a, b in pairs)
    return v42.HEAD.format(title='配色 V4.3 图标对比') + """
.row{display:flex;flex-wrap:wrap;gap:14px;align-items:flex-end}.t{display:flex;flex-direction:column;align-items:center;gap:5px}.t img{box-shadow:0 1px 3px rgba(0,0,0,.2)}
.pal{display:flex;height:6px;border-radius:3px;overflow:hidden}.pal i{flex:1}.t small{font-size:11px;color:#394657}
.grp{display:flex;align-items:center;gap:18px;background:#fff;border:1px solid #D8E0E8;border-radius:16px;padding:14px 18px;margin-bottom:12px;flex-wrap:wrap}
.lab{width:150px;font-weight:600;font-size:14px}.lab span{font-weight:400;font-size:12px;color:#394657}.vs{display:flex;gap:10px;align-items:flex-end}.vs em{font-style:normal;font-size:11px;color:#586577;align-self:center;width:44px}
i.m{display:block;width:60px;height:60px;border-radius:13.4px}
</style></head><body><div class="wrap"><div class="kicker">Tactics Board · Colour System V4.3 · Stage One</div><h1>图标与配色辨识对比</h1>
<p class="lede">上半部分是 16 个 app 现在真实使用的图标（写实插画，不由这套配色生成），下面的细色条是 V4.3 的主色和副色。下半部分是七组易混组合：纯主色色块的 V4.2 与 V4.3 对比，以及对应的真实图标。色块是示意，不是图标。</p>
""" + rows + '<h2>易混组合</h2>' + prs + '</div></body></html>'


if __name__ == '__main__':
    main()
