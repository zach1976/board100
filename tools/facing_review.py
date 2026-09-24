#!/usr/bin/env python3
"""The facing review page: every drill, every beat, who is looking where.

Reads tools/facing_audit.json (from facing_audit.py) and the frames in
tools/board_png/ (from tactics_board/tool/render_boards.dart), and writes
tools/facing_review.html — worst boards first: a pass that starts at
nobody's feet or lands on grass leaves a player facing the wrong way, and
those are the drills to fix in the source. Under each board, the frames of
its beats and a table of every player's facing at every beat.

    python3 tools/facing_review.py && open -a "Google Chrome" tools/facing_review.html
"""
import json, html
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
AUDIT = json.loads((REPO / 'tools/facing_audit.json').read_text())
PNG = REPO / 'tools/board_png'
OUT = REPO / 'tools/facing_review.html'

def score(d):
    # Spins first: they are the one thing the rule itself can make look
    # odd. Legs with no passer or receiver are by design and only sort
    # after that.
    return len(d['spins']) * 10 + len(d['legs'])

cards = []
n_defect = n_expected = n_clean = 0
for sport, drills in AUDIT.items():
    for d in drills:
        d['sport'] = sport
        if d['spins']: n_defect += 1
        elif d['legs']: n_expected += 1
        else: n_clean += 1
        cards.append(d)
cards.sort(key=lambda d: (-score(d), d['sport'], d['id']))

def card(d):
    frames = ''.join(
        f'<figure><img loading="lazy" src="board_png/{d["sport"]}/{d["id"]}-{i}.png" alt=""><figcaption>beat {i}</figcaption></figure>'
        for i in range(d['steps'] + 1)
        if (PNG / d['sport'] / f'{d["id"]}-{i}.png').exists())
    head = ''.join(f'<th>{i}</th>' for i in range(d['steps'] + 1))
    rows = ''.join(f'<tr><th>{html.escape(str(l))}</th>' + ''.join(f'<td>{c}</td>' for c in seq) + '</tr>'
                   for l, seq in d['rows'])
    flags = []
    flags += [f'<span class="flag defect">{html.escape(str(l))} turns {a}→{b} at beat {st}</span>' for l, st, a, b in d['spins']]
    flags += [f'<span class="flag expected">{html.escape(k)} · beat {ph}</span>' for k, ph in d['legs']]
    cls = 'defect' if d['spins'] else ('expected' if d['legs'] else 'clean')
    return f'''<section class="card {cls}" id="{d['sport']}-{d['id']}">
  <header><h2>{html.escape(d['name'])}</h2><span class="meta">{d['sport']} · {d['id']} · {d['players']} players · {d['steps']} beats</span></header>
  <div class="flags">{''.join(flags) or '<span class="flag ok">every beat has a cue</span>'}</div>
  <div class="frames">{frames}</div>
  <table><thead><tr><th>player</th>{head}</tr></thead><tbody>{rows}</tbody></table>
</section>'''

page = f'''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Facing review</title>
<style>
:root{{color-scheme:dark;--bg:#0A1411;--panel:#111E19;--line:#1E3129;--text:#E6F0EB;--muted:#86A096;--accent:#20C7C3;--bad:#E26B62;--warn:#E9A94B;--ok:#4DBA78}}
*{{box-sizing:border-box}} body{{margin:0;background:var(--bg);color:var(--text);font:15px/1.55 "PingFang SC","Hiragino Sans GB",sans-serif}}
.wrap{{max-width:1180px;margin:0 auto;padding:40px 20px 80px}}
h1{{font-size:34px;margin:0 0 6px}} .lede{{color:var(--muted);max-width:70ch;margin:0 0 20px}}
.summary{{display:flex;gap:12px;flex-wrap:wrap;margin:0 0 28px}} .summary div{{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:12px 16px}} .summary b{{font-size:24px;display:block}}
.filters{{display:flex;gap:8px;margin:0 0 20px;flex-wrap:wrap}} .filters button{{background:var(--panel);border:1px solid var(--line);color:var(--muted);border-radius:8px;padding:6px 12px;cursor:pointer}} .filters button.on{{color:var(--accent);border-color:var(--accent)}}
.card{{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:16px;margin:0 0 18px;border-left-width:4px}}
.card.defect{{border-left-color:var(--bad)}} .card.expected{{border-left-color:var(--warn)}} .card.clean{{border-left-color:var(--line)}}
.card header{{display:flex;gap:14px;align-items:baseline;flex-wrap:wrap}} .card h2{{margin:0;font-size:18px}} .meta{{color:var(--muted);font-size:12.5px;font-family:Menlo,monospace}}
.flags{{display:flex;gap:6px;flex-wrap:wrap;margin:10px 0}} .flag{{font-size:12px;padding:3px 8px;border-radius:6px;border:1px solid}}
.flag.defect{{color:var(--bad);border-color:var(--bad)}} .flag.expected{{color:var(--warn);border-color:var(--warn)}} .flag.spin{{color:var(--muted);border-color:var(--line)}} .flag.ok{{color:var(--ok);border-color:var(--ok)}}
.frames{{display:flex;gap:8px;overflow-x:auto;padding:4px 0}} .frames figure{{margin:0;flex:0 0 auto}} .frames img{{height:300px;border-radius:8px;display:block}} .frames figcaption{{font-size:11px;color:var(--muted);text-align:center}}
table{{border-collapse:collapse;font:12px Menlo,monospace;margin-top:10px}} th,td{{border:1px solid var(--line);padding:3px 8px;text-align:center}} th{{color:var(--muted)}} tbody th{{text-align:left}}
</style></head><body><div class="wrap">
<h1>Facing review</h1>
<p class="lede">每个训练在每一拍里每个人看向哪里，按 app 里同一条规则算出来：要传的人看目标，要接的人看球，要跑的人看跑向，其余看球。
排在前面的是<b>有人原地转身 135° 以上去跟球</b>的板 —— 规则本身唯一可能显得别扭的地方，值得看一眼是不是真的别扭。
黄标是"这一拍的球不从任何人脚下出发（场外喂球）或不落在任何人身上（射门、发球、传中）"，按设计如此，只是说明，不算缺陷。</p>
<div class="summary"><div><b>{n_defect}</b>有人原地转身</div><div><b>{n_expected}</b>球来自场外/射向目标</div><div><b>{n_clean}</b>干净</div><div><b>{len(cards)}</b>训练总数</div></div>
<div class="filters"><button class="on" data-f="all">全部</button><button data-f="defect">只看原地转身</button><button data-f="expected">只看场外/射门</button><button data-f="clean">只看干净</button></div>
{''.join(card(d) for d in cards)}
</div>
<script>
document.querySelectorAll('.filters button').forEach(b=>b.addEventListener('click',()=>{{
  document.querySelectorAll('.filters button').forEach(x=>x.classList.remove('on')); b.classList.add('on');
  const f=b.dataset.f; document.querySelectorAll('.card').forEach(c=>c.style.display=(f==='all'||c.classList.contains(f))?'':'none');
}}));
</script></body></html>'''
OUT.write_text(page)
print(f'wrote {OUT} — {n_defect} defect / {n_expected} expected / {n_clean} clean')
