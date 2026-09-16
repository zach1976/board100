#!/usr/bin/env python3
"""Build the thumbnail sheet — every drill's list picture, all at once.

The thumbnail is the one picture a coach sees before deciding whether to open
a drill, and there are 624 of them. Judging that inside the app means
scrolling one sport at a time on a phone. This lays them out side by side,
with the name and the coaching point the list shows beside them, so the ones
that say nothing are obvious next to the ones that work.

Images come from tools/thumb_png/, written by
tactics_board/tool/render_thumbs.dart, which runs the real DrillThumbnail
widget — so this page shows exactly what the app draws, not a second
implementation of it that would quietly drift.

    tools/render_thumbs first, then:
    tools/thumb_review.py            # all sports
    tools/thumb_review.py soccer     # just one

Writes tools/thumb_review.html.
"""
import html
import json
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
DRILLS = REPO / "tactics_board" / "assets" / "drills"
THUMBS = REPO / "tools" / "thumb_png"
OUT = REPO / "tools" / "thumb_review.html"

LOCALE = "zh-CN"


def pick(texts, locale=LOCALE):
    if not isinstance(texts, dict):
        return ""
    if locale in texts:
        return texts[locale]
    lang = locale.split("-")[0]
    for key in texts:
        if key.split("-")[0] == lang:
            return texts[key]
    return texts.get("en", next(iter(texts.values()), ""))


def point_of(drill):
    """The line the list shows: the coaching point, else the opening line."""
    note = pick(drill.get("note", {}))
    labelled = []
    for raw in note.split("\n"):
        line = raw.strip()
        if not line:
            continue
        if line.startswith("【"):
            close = line.index("】")
            labelled.append((line[1:close], line[close + 1:].strip()))
        else:
            labelled.append((None, line))
    if not labelled:
        return ""
    # The point is the last labelled line; the lead is the first line.
    return labelled[-1][1] if len(labelled) > 1 else labelled[0][1]


def main(argv):
    only = argv[0] if argv else None
    cards = []
    counts = {}
    for f in sorted(DRILLS.glob("*.json")):
        sport = f.stem
        if only and sport != only:
            continue
        drills = json.loads(f.read_text())["drills"]
        counts[sport] = len(drills)
        for d in drills:
            img = THUMBS / sport / f"{d['id']}.png"
            cards.append({
                "sport": sport,
                "id": d["id"],
                "name": pick(d.get("name", {})),
                "point": point_of(d),
                "img": img.relative_to(REPO / "tools").as_posix()
                       if img.exists() else None,
                "players": d.get("players", 0),
                "minutes": d.get("minutes", 0),
            })

    rows = []
    for c in cards:
        # The picture links to the drill's page on the review site, so a
        # thumbnail that looks wrong is one click from the board it depicts.
        detail = f'drill_review.html?d={c["sport"]}/{c["id"]}'
        shot = (f'<a href="{detail}" title="打开训练详情"><img src="{c["img"]}" alt=""></a>'
                if c["img"] else '<div class="missing">未渲染</div>')
        rows.append(
            f'<figure class="card" data-sport="{c["sport"]}">'
            f'{shot}'
            f'<figcaption>'
            f'<b>{html.escape(c["name"])}</b>'
            f'<code>{c["sport"]} · {c["id"]}</code>'
            f'<p>{html.escape(c["point"])}</p>'
            f'<small>{c["minutes"]} 分钟 · {c["players"]} 人</small>'
            f'</figcaption></figure>')

    chips = "".join(
        f'<button data-filter="{s}">{s} <span>{n}</span></button>'
        for s, n in sorted(counts.items(), key=lambda kv: -kv[1]))

    OUT.write_text(PAGE.format(
        total=len(cards),
        sports=len(counts),
        chips=chips,
        cards="\n".join(rows),
    ), encoding="utf-8")
    print(f"{len(cards)} thumbnails -> {OUT}")
    return 0


PAGE = """<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>训练缩略图</title>
<style>
  :root {{
    color-scheme: dark;
    --bg: #071D1F; --card: #0B272A; --line: rgba(180,205,210,.16);
    --text: #F4F7F5; --dim: #A9BAB8; --off: #718A88; --accent: #20C7C3;
  }}
  * {{ box-sizing: border-box; }}
  body {{ margin: 0; background: var(--bg); color: var(--text);
    font: 15px/1.55 -apple-system, "PingFang SC", "Helvetica Neue", sans-serif; }}
  header {{ padding: 28px 24px 16px; border-bottom: 1px solid var(--line);
    position: sticky; top: 0; background: var(--bg); z-index: 2; }}
  h1 {{ margin: 0 0 4px; font-size: 22px; letter-spacing: -.01em; }}
  .lede {{ margin: 0 0 14px; color: var(--dim); font-size: 14px; }}
  .chips {{ display: flex; flex-wrap: wrap; gap: 6px; }}
  .chips button {{ appearance: none; cursor: pointer; font: inherit;
    font-size: 13px; color: var(--dim); background: #103338;
    border: 1px solid transparent; border-radius: 9px; padding: 5px 11px; }}
  .chips button span {{ color: var(--off); font-size: 11.5px; }}
  .chips button[aria-pressed="true"] {{ color: var(--text);
    background: rgba(32,199,195,.14); border-color: rgba(32,199,195,.4); }}
  .grid {{ display: grid; gap: 14px; padding: 20px 24px 80px;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); }}
  .card[hidden] {{ display: none; }}
  .card {{ margin: 0; display: flex; gap: 14px; background: var(--card);
    border: 1px solid var(--line); border-radius: 14px; padding: 14px; }}
  .card a {{ flex: none; line-height: 0; }}
  .card img {{ width: 96px; height: auto; border-radius: 9px;
    image-rendering: auto; }}
  .card a:hover img {{ outline: 2px solid var(--accent, #6fd3a5); }}
  .missing {{ width: 96px; height: 130px; border-radius: 9px; flex: none;
    display: grid; place-items: center; background: #103338;
    color: var(--off); font-size: 12px; }}
  figcaption {{ min-width: 0; }}
  figcaption b {{ display: block; font-size: 15px; }}
  figcaption code {{ display: block; margin: 2px 0 6px; font-size: 11px;
    color: var(--off); font-family: ui-monospace, Menlo, monospace; }}
  figcaption p {{ margin: 0 0 6px; color: var(--dim); font-size: 13.5px;
    display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical;
    overflow: hidden; }}
  figcaption small {{ color: var(--off); font-size: 12px; }}
</style></head><body>
<header>
  <h1>训练缩略图</h1>
  <p class="lede">{total} 个训练、{sports} 个运动。图是 app 里真正那个组件渲染的，
    右边是列表上显示的那句教练要点。</p>
  <div class="chips" id="chips">
    <button data-filter="" aria-pressed="true">全部 <span>{total}</span></button>
    {chips}
  </div>
</header>
<div class="grid" id="grid">
{cards}
</div>
<script>
  const chips = document.getElementById('chips');
  chips.addEventListener('click', (e) => {{
    const btn = e.target.closest('button');
    if (!btn) return;
    for (const b of chips.querySelectorAll('button')) {{
      b.setAttribute('aria-pressed', String(b === btn));
    }}
    const want = btn.dataset.filter;
    for (const card of document.querySelectorAll('.card')) {{
      card.hidden = want && card.dataset.sport !== want;
    }}
  }});
  // ?sport=soccer opens the page already narrowed to one sport.
  const preset = new URLSearchParams(location.search).get('sport');
  if (preset) chips.querySelector(`button[data-filter="${{preset}}"]`)?.click();
</script>
</body></html>
"""

if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
