#!/usr/bin/env python3
"""The facing review page: every drill, every beat, who is looking where.

Reads tools/facing_audit.json (from facing_audit.py, which reads what the
app itself says in tools/facing_headings.json) and the frames in
tools/board_png/ (from tactics_board/tool/render_boards.dart), and writes
tools/facing_review.html — worst boards first.

    cd tactics_board && flutter test tool/facing_dump.dart
    cd tactics_board && flutter test tool/render_boards.dart
    python3 tools/facing_audit.py && python3 tools/facing_review.py
    open -a "Google Chrome" tools/facing_review.html
"""
import json, html
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
AUDIT = json.loads((REPO / 'tools/facing_audit.json').read_text())
PNG = REPO / 'tools/board_png'
OUT = REPO / 'tools/facing_review.html'

# A turn the board can explain is not a defect; these are the explanations,
# and anything else sorts to the top of the page.
EXPLAINED = {
    'the ball went past them',
    'watching the ball → facing their run',
    'watching the ball → playing it away',
    'they are playing the ball the other way',
    'has the ball → facing their run',
}


def odd(d):
    return [s for s in d['spins'] if s[4] not in EXPLAINED]


def score(d):
    # A back turned on the ball is the defect this page was built to catch;
    # then a turn nothing explains; then the explained ones, to be read.
    return len(d['back']) * 100 + len(odd(d)) * 10 + len(d['spins'])


cards = []
n_back = n_odd = n_spin = n_clean = 0
for sport, drills in AUDIT.items():
    for d in drills:
        d['sport'] = sport
        if d['back']:
            n_back += 1
        elif odd(d):
            n_odd += 1
        elif d['spins']:
            n_spin += 1
        else:
            n_clean += 1
        cards.append(d)
cards.sort(key=lambda d: (-score(d), d['sport'], d['id']))
why = Counter(w for d in cards for *_, w in d['spins'])


def card(d):
    frames = ''.join(
        f'<figure><img loading="lazy" src="board_png/{d["sport"]}/{d["id"]}-{i}.png" alt="">'
        f'<figcaption>beat {i}</figcaption></figure>'
        for i in range(d['steps'] + 1)
        if (PNG / d['sport'] / f'{d["id"]}-{i}.png').exists())
    head = ''.join(f'<th>{i}</th>' for i in range(d['steps'] + 1))
    rows = ''.join(
        f'<tr><th>{html.escape(str(l))}</th>'
        + ''.join(f'<td>{c}</td>' for c in seq) + '</tr>'
        for l, seq in d['rows'])
    flags = [f'<span class="flag defect">{html.escape(str(l))} stands at beat {st} '
             f'facing {a} with the ball {b}, {g}pt away</span>'
             for l, st, a, b, g in d['back']]
    flags += [f'<span class="flag {"odd" if w not in EXPLAINED else "ok"}">'
              f'{html.escape(str(l))} turns {a}→{b} at beat {st} · {html.escape(w)}</span>'
              for l, st, a, b, w in d['spins']]
    if d['nocue']:
        flags.append(f'<span class="flag ok">{d["nocue"]} beat(s) the board says '
                     f'nothing about — the drill\'s own opening stance stands</span>')
    cls = 'defect' if d['back'] else ('odd' if odd(d) else ('spin' if d['spins'] else 'clean'))
    return f'''<section class="card {cls}" id="{d['sport']}-{d['id']}">
  <header><h3>{html.escape(d['sport'])} / {html.escape(d['id'])}</h3>
    <span class="name">{html.escape(str(d['name']))}</span>
    <span class="meta">{d['players']} players · {d['steps'] + 1} beats</span></header>
  <div class="flags">{''.join(flags) or '<span class="flag ok">nothing to look at</span>'}</div>
  <div class="frames">{frames}</div>
  <table><thead><tr><th>beat</th>{head}</tr></thead><tbody>{rows}</tbody></table>
</section>'''


CSS = '''
:root{--bg:#0e1112;--panel:#161b1d;--line:#2a3336;--text:#e8eef0;--dim:#9fb0b5;
      --bad:#ff6b6b;--odd:#ffb84d;--ok:#3ddc97;--accent:#4dd0e1}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);
     font:15px/1.6 -apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif}
.wrap{max-width:1180px;margin:0 auto;padding:28px 16px 80px}
h1{font-size:26px;margin:0 0 6px}
.lede{color:var(--dim);margin:0 0 20px;max-width:70ch}
.tally{display:flex;gap:10px;flex-wrap:wrap;margin:0 0 22px}
.tally b{display:block;font-size:22px}
.tally div{background:var(--panel);border:1px solid var(--line);border-radius:10px;
           padding:10px 14px;min-width:130px}
.why{background:var(--panel);border:1px solid var(--line);border-radius:10px;
     padding:12px 16px;margin:0 0 22px}
.why table{border-collapse:collapse}.why td{padding:2px 10px 2px 0;color:var(--dim)}
.why td:first-child{color:var(--text);text-align:right;font-variant-numeric:tabular-nums}
.card{background:var(--panel);border:1px solid var(--line);border-radius:12px;
      padding:14px 16px;margin:0 0 16px}
.card.defect{border-color:var(--bad)}.card.odd{border-color:var(--odd)}
header{display:flex;gap:10px;align-items:baseline;flex-wrap:wrap;margin-bottom:8px}
h3{margin:0;font-size:15px;font-family:ui-monospace,Menlo,monospace;color:var(--accent)}
.name{color:var(--text)}.meta{color:var(--dim);font-size:13px;margin-left:auto}
.flags{display:flex;gap:6px;flex-wrap:wrap;margin-bottom:10px}
.flag{font-size:12.5px;padding:3px 9px;border-radius:99px;border:1px solid var(--line);color:var(--dim)}
.flag.defect{border-color:var(--bad);color:var(--bad)}
.flag.odd{border-color:var(--odd);color:var(--odd)}
.flag.ok{border-color:#2f4f45;color:var(--ok)}
.frames{display:flex;gap:8px;overflow-x:auto;padding-bottom:6px}
figure{margin:0;flex:0 0 auto}
figure img{height:300px;border-radius:8px;display:block;background:#0a0d0e}
figcaption{color:var(--dim);font-size:12px;text-align:center;padding-top:4px}
table{border-collapse:collapse;margin-top:10px;font-size:12.5px}
th,td{border:1px solid var(--line);padding:2px 8px;text-align:center;
      font-family:ui-monospace,Menlo,monospace}
thead th{color:var(--dim)}tbody th{color:var(--text);text-align:right}
'''

OUT.write_text(f'''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>朝向复查</title><style>{CSS}</style></head><body><div class="wrap">
<h1>朝向复查 · {len(cards)} 个 drill</h1>
<p class="lede">每一拍的朝向都由 app 自己的 <code>boardHeading()</code> 算出来
（<code>tool/facing_dump.dart</code>），这里只做判断，不再用 Python 复刻规则。
红框＝站着不动却背对着球（就是 C 那一类）；黄框＝转身 135° 以上而且解释不了；
其余的转身都注明了原因。</p>
<div class="tally">
  <div><b>{n_back}</b>背对着球</div>
  <div><b>{n_odd}</b>解释不了的转身</div>
  <div><b>{n_spin}</b>只有能解释的转身</div>
  <div><b>{n_clean}</b>干净</div>
</div>
<div class="why"><table>{''.join(f'<tr><td>{n}</td><td>{html.escape(k)}</td></tr>' for k, n in why.most_common())}</table></div>
{''.join(card(d) for d in cards)}
</div></body></html>''')
print(f'wrote {OUT}  ({len(cards)} drills, {n_back} with a back to the ball, '
      f'{n_odd} with an unexplained turn)')
