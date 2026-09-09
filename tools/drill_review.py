#!/usr/bin/env python3
"""Build the drill review page — one board at a time, with what is wrong on it.

The drill library is 624 boards across 15 sports, and the only way anyone has
ever looked at them in bulk is a contact sheet of static PNGs. A static picture
cannot show the defect that matters most: in 539 of them the players move
through their phases while the ball sits exactly where it started, so a passing
drill never passes the ball. You have to step the phases to see it.

So this writes a page: every board as the app itself draws it, a phase stepper
under it, every string it ships with, and the problems found in it.
Corrections are typed into the page and kept in localStorage; the Export button
hands back a JSON file to apply to the sources.

    tools/drill_review.py            # all sports
    tools/drill_review.py soccer     # just one

Boards come from tools/board_png/, produced by
tactics_board/tool/render_boards.dart, which renders TacticsCanvas
itself so the page shows exactly what the phone shows. Re-render after editing
any drill:

    cd tactics_board
    FLUTTER_ROOT=<flutter> flutter test tool/render_boards.dart

Writes tools/drill_review.html and opens nothing — open it yourself.
"""
import json
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
DRILLS = REPO / "tactics_board" / "assets" / "drills"
OUT = REPO / "tools" / "drill_review.html"

CANVAS_W, CANVAS_H = 1000.0, 1500.0

# Boards are rendered by the app itself — see
# tactics_board/tool/render_boards.dart — into tools/board_png/.
# The page used to draw its own SVG approximation, which is a second
# implementation of the thing being reviewed: it drifts, and a reviewer
# correcting a board they are not actually looking at is worse than no review
# page at all. Re-render after changing any drill:
#
#     cd tactics_board
#     FLUTTER_ROOT=... flutter test tool/render_boards.dart
PNG_DIR = REPO / "tools" / "board_png"

MARKER_NAME = {
    0: "none", 1: "circle", 2: "square", 3: "triangle", 4: "diamond",
    5: "cone", 6: "text", 7: "zone", 8: "referee", 9: "coach",
    10: "ladder", 11: "hurdle", 12: "arrow",
}

# A token is 44pt on a 1000-wide board rendered into roughly 400pt of screen,
# so two tokens closer than this in board units touch on the phone.
OVERLAP_UNITS = 44 * (CANVAS_W / 400)

NOTE_TARGET_WORDS = 45


def kind(p):
    if p.get("sportType") is not None:
        return "ball"
    if p.get("markerShape", 0):
        return "marker"
    return "player"


def position_at(p, step):
    """Where an element stands at [step], matching the board exactly.

    The canvas advances a move when `phase < phaseLimit`, so at step 0 nothing
    has run yet and at step N phases 0..N-1 have. Using `<=` here — which is
    the reading the field names invite — put every overlap one step early in
    the report and made the last state unreachable.
    """
    pos = p["position"]
    for dest, phase in zip(p.get("moves", []), p.get("movePhases", [])):
        if phase < step:
            pos = dest
    return pos


def audit(drill, sport):
    """The problems in one board, worst first."""
    out = []
    board = drill["board"]
    people = [p for p in board["players"] if kind(p) == "player"]
    balls = [p for p in board["players"] if kind(p) == "ball"]
    movers = [p for p in people if p.get("moves")]

    if movers and balls and not any(b.get("moves") for b in balls):
        out.append({
            "id": "ball_static",
            "level": "error",
            "text": f"球从头到尾不动：{len(movers)} 名球员走了 "
                    f"{max_step(board)} 步，球停在 "
                    f"({balls[0]['position'][0]:.0f}, {balls[0]['position'][1]:.0f})",
        })
    if movers and not balls:
        out.append({
            "id": "no_ball",
            "level": "warn",
            "text": "板上没有球",
        })

    for p in board["players"]:
        if p.get("moves") and len(p.get("movePhases", [])) != len(p["moves"]):
            out.append({
                "id": "phase_mismatch",
                "level": "error",
                "text": f"{p['id']} 有 {len(p['moves'])} 段移动但 "
                        f"{len(p.get('movePhases', []))} 个阶段",
            })

    words = len(drill.get("note", {}).get("en", "").split())
    if words < NOTE_TARGET_WORDS:
        out.append({
            "id": "short_note",
            "level": "info",
            "text": f"说明只有 {words} 词，目标 {NOTE_TARGET_WORDS}+",
        })

    if not drill.get("tags"):
        out.append({"id": "no_tags", "level": "info", "text": "没有标签"})

    # One card for all the overlaps, not one per finding. Three cards each
    # opening with 第 N 步 read as a step-by-step description of the drill —
    # a four-beat drill with collisions on beats 1–3 was read as "only has
    # three steps". And players are named by shirt number, not internal id.
    hits = []
    for step in range(max_step(board) + 1):
        # People only. A ball 40 units from a player is at their feet — that
        # is possession, placed there on purpose by at_the_feet_of — and
        # equipment under a player is the arrangement the drill means. The
        # board's own fan-out draws the same line.
        at = [(p, position_at(p, step)) for p in board["players"]
              if kind(p) == "player"]
        for i in range(len(at)):
            for j in range(i + 1, len(at)):
                (a, pa), (b, pb) = at[i], at[j]
                d = ((pa[0] - pb[0]) ** 2 + (pa[1] - pb[1]) ** 2) ** 0.5
                if d < OVERLAP_UNITS * 0.55:
                    na = a.get("label") or a["id"]
                    nb = b.get("label") or b["id"]
                    hits.append((step, na, nb, d))
    if hits:
        parts = "；".join(
            f"第 {step} 步 {na}+{nb}" + ("（完全重合）" if d < 1 else f"（相距 {d:.0f}）")
            for step, na, nb, d in hits)
        out.append({
            "id": "overlap",
            "level": "warn",
            "text": f"{len(hits)} 处球员重叠：{parts}"
                    + ("——后到者踩在还没让开的位置上"
                       if all(d < 1 for *_x, d in hits) else ""),
        })
    rank = {"error": 0, "warn": 1, "info": 2}
    out.sort(key=lambda i: rank[i["level"]])
    return out


def max_phase(board):
    phases = [ph for p in board["players"] for ph in p.get("movePhases", [])]
    return max(phases) if phases else -1


def max_step(board):
    """TacticsState.maxMoveSteps — the number the app's indicator counts to.

    Phases 0..maxPhase inclusive, so a board with phases {0,1,2,3} has four
    beats and five states: the start, then one after each beat.
    """
    return max_phase(board) + 1


def collect(only=None):
    drills = []
    for f in sorted(DRILLS.glob("*.json")):
        sport = f.stem
        if only and sport != only:
            continue
        data = json.loads(f.read_text())
        for d in data["drills"]:
            board = d["board"]
            drills.append({
                "sport": sport,
                "id": d["id"],
                "name": d["name"].get("en", d["id"]),
                "nameZh": d["name"].get("zh-CN", ""),
                "note": d.get("note", {}).get("en", ""),
                "noteZh": d.get("note", {}).get("zh-CN", ""),
                "mistake": d.get("mistake", {}).get("en", ""),
                "mistakeZh": d.get("mistake", {}).get("zh-CN", ""),
                "category": d.get("category"),
                "level": d.get("level"),
                "minutes": d.get("minutes"),
                "players": d.get("players"),
                "family": d.get("familyName") or "",
                "tags": d.get("tags", []),
                "maxStep": max_step(board),
                "els": [{
                    "id": p["id"],
                    "k": kind(p),
                    "l": p.get("label", ""),
                    "m": MARKER_NAME.get(p.get("markerShape", 0), "none"),
                } for p in board["players"]],
                "issues": audit(d, sport),
            })
    return drills


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    drills = collect(only)
    if not drills:
        print(f"no drills for {only!r}")
        return 1
    missing = [d for d in drills
               if not (PNG_DIR / d["sport"] / f'{d["id"]}-0.png').exists()]
    if missing:
        print(f"! {len(missing)} boards have no render "
              f"(e.g. {missing[0]['sport']}/{missing[0]['id']}) — run "
              f"tool/render_boards.dart")
    payload = json.dumps(drills, ensure_ascii=False, separators=(",", ":"))
    html = TEMPLATE.replace("/*__DATA__*/", payload)
    OUT.write_text(html)
    bad = sum(1 for d in drills if any(i["level"] == "error" for i in d["issues"]))
    print(f"{len(drills)} drills, {bad} with errors -> {OUT}")
    return 0


TEMPLATE = r"""<!doctype html>
<html lang="zh">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>训练素材矫正</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Archivo:wght@500;600;700&family=Source+Sans+3:wght@400;600&family=JetBrains+Mono:wght@400;500&display=swap">
<style>
  :root{
    color-scheme:dark;
    --bg0:#071A1D; --bg1:#0B2328; --surface:#12333B; --surfaceHi:#173E47;
    --border:rgba(180,205,210,.18); --text:#F3F7F6; --dim:#9AAEB1; --off:#60777B;
    --accent:#18C7BC; --warning:#E6A93D; --danger:#EF5B62;
    --home:#3E8EF7; --away:#FF5964; --turf:#1E783C; --turfHi:#176B35;
    --display:'Archivo','Helvetica Neue',Arial,sans-serif;
    --body:'Source Sans 3','PingFang SC','Helvetica Neue',Arial,sans-serif;
    --mono:'JetBrains Mono','SFMono-Regular',Menlo,monospace;
  }
  *{box-sizing:border-box}
  html,body{height:100%}
  body{margin:0;background:var(--bg0);color:var(--text);font-family:var(--body);
       font-size:15px;line-height:1.55;-webkit-font-smoothing:antialiased;
       display:flex;flex-direction:column}

  header.top{display:flex;align-items:center;gap:16px;padding:12px 20px;
             border-bottom:1px solid var(--border);background:var(--bg1);flex:none}
  .brand{font-family:var(--display);font-weight:700;font-size:16px;white-space:nowrap}
  .counts{font-family:var(--mono);font-size:12px;color:var(--off);white-space:nowrap}
  .counts b{color:var(--danger);font-weight:500}
  .grow{flex:1}
  select,input[type=search]{font-family:var(--body);font-size:14px;color:var(--text);
       background:var(--surface);border:1px solid var(--border);border-radius:9px;
       padding:7px 11px}
  button{font-family:var(--body);font-size:14px;font-weight:600;color:#04191B;
         background:var(--accent);border:0;border-radius:9px;padding:8px 15px;cursor:pointer}
  button.ghost{background:var(--surface);color:var(--text);border:1px solid var(--border)}
  button:hover{filter:brightness(1.08)}
  button:focus-visible{outline:2px solid var(--text);outline-offset:2px}

  main{flex:1;display:grid;grid-template-columns:300px 1fr;min-height:0}
  aside{border-right:1px solid var(--border);overflow-y:auto;background:var(--bg1)}
  .row{display:block;width:100%;text-align:left;background:none;border:0;color:inherit;
       padding:10px 14px;border-bottom:1px solid var(--border);cursor:pointer;
       font-weight:400;font-size:14px;border-radius:0}
  .row:hover{background:var(--surface);filter:none}
  .row.on{background:var(--surfaceHi)}
  .row .nm{display:block;color:var(--text)}
  .row .sub{display:block;font-family:var(--mono);font-size:11px;color:var(--off);margin-top:2px}
  .dots{float:right;display:flex;gap:3px;margin-top:4px}
  .dot{width:7px;height:7px;border-radius:50%}
  .dot.error{background:var(--danger)} .dot.warn{background:var(--warning)}
  .dot.info{background:var(--off)} .dot.done{background:var(--accent)}

  section.pane{overflow-y:auto;padding:24px 28px 64px}
  .head{display:flex;align-items:flex-start;gap:16px;margin-bottom:4px}
  h1{font-family:var(--display);font-weight:700;font-size:26px;margin:0;letter-spacing:-.01em}
  .zh{color:var(--dim);font-size:16px;margin:2px 0 0}
  .meta{font-family:var(--mono);font-size:12px;color:var(--off);margin:10px 0 0}
  .meta span{display:inline-block;padding:3px 8px;border:1px solid var(--border);
             border-radius:999px;margin:0 6px 6px 0}

  .split{display:grid;grid-template-columns:minmax(280px,360px) 1fr;gap:28px;margin-top:20px;
         align-items:start}
  @media (max-width:1100px){.split{grid-template-columns:1fr}main{grid-template-columns:240px 1fr}}

  .boardwrap{position:sticky;top:0}
  img.board{width:100%;height:auto;border-radius:12px;border:1px solid var(--border);
            display:block;background:var(--turfHi)}
  .steps{display:flex;align-items:center;gap:8px;margin-top:10px}
  .steps .n{font-family:var(--mono);font-size:13px;color:var(--dim);min-width:52px;text-align:center}
  .steps button{padding:6px 12px}

  .issues{margin:0 0 22px;padding:0;list-style:none}
  .issue{border:1px solid var(--border);border-left:3px solid var(--off);
         border-radius:0 10px 10px 0;padding:10px 14px;margin:0 0 8px;background:var(--bg1);
         font-size:14px}
  .issue.error{border-left-color:var(--danger)}
  .issue.warn{border-left-color:var(--warning)}
  .issue .tag{font-family:var(--mono);font-size:11px;color:var(--off);
              text-transform:uppercase;letter-spacing:.06em;display:block;margin-bottom:2px}
  .clean{color:var(--accent);font-size:14px;margin:0 0 22px}

  h3{font-family:var(--display);font-weight:600;font-size:14px;letter-spacing:.06em;
     text-transform:uppercase;color:var(--off);margin:22px 0 8px}
  .cur{background:var(--bg1);border:1px solid var(--border);border-radius:10px;
       padding:12px 14px;font-size:14.5px;color:var(--dim);margin:0 0 6px;
       white-space:pre-line}
  .cur.zh{font-size:14px}
  textarea{width:100%;font-family:var(--body);font-size:14.5px;line-height:1.6;color:var(--text);
           background:var(--surface);border:1px solid var(--border);border-radius:10px;
           padding:12px 14px;resize:vertical;min-height:96px}
  textarea:focus,input:focus,select:focus{outline:2px solid var(--accent);outline-offset:-1px}
  .wc{font-family:var(--mono);font-size:11.5px;color:var(--off);margin-top:5px}
  .wc.ok{color:var(--accent)}

  .tags{display:flex;flex-wrap:wrap;gap:6px;margin:0 0 10px}
  .tag-btn{font-family:var(--body);font-size:13px;font-weight:400;padding:5px 11px;
           border-radius:999px;border:1px solid var(--border);background:transparent;
           color:var(--dim);cursor:pointer}
  .tag-btn.on{background:rgba(24,199,188,.14);border-color:rgba(24,199,188,.5);color:var(--accent)}
  .tag-btn:hover{filter:none;border-color:var(--dim)}

  .actions{display:flex;gap:10px;align-items:center;margin-top:26px;
           padding-top:18px;border-top:1px solid var(--border)}
  .saved{font-size:13px;color:var(--accent)}
  .empty{color:var(--off);padding:60px 0;text-align:center}
</style>
</head>
<body>

<header class="top">
  <span class="brand">训练素材矫正</span>
  <select id="sport"></select>
  <select id="filter">
    <option value="all">全部</option>
    <option value="error">只看有错的</option>
    <option value="ball_static">球不动</option>
    <option value="overlap">有重叠</option>
    <option value="short_note">说明太短</option>
    <option value="edited">我改过的</option>
    <option value="todo">还没改的</option>
  </select>
  <input type="search" id="q" placeholder="搜索名称…" style="width:180px">
  <span class="counts" id="counts"></span>
  <span class="grow"></span>
  <button class="ghost" id="clear">清空我的修改</button>
  <button id="export">导出修改</button>
</header>

<main>
  <aside id="list"></aside>
  <section class="pane" id="pane"></section>
</main>

<script>
const DRILLS = /*__DATA__*/;
const KEY = 'drill-review-edits-v1';
let edits = {};
try { edits = JSON.parse(localStorage.getItem(KEY) || '{}'); } catch (e) { edits = {}; }

const TAGS = [
  '传球','接球','控球','转身','运球','一对一','射门','头球',
  '定位球','压迫','退防','盯人','区域防守','攻防转换',
  '门将','小场比赛','体能','热身','技术','战术',
  '需要球门','需要锥桶','需要栏架','需要敏捷梯'
];

const key = d => d.sport + '/' + d.id;
const save = () => localStorage.setItem(KEY, JSON.stringify(edits));
const editOf = d => edits[key(d)] || {};
const isEdited = d => {
  const e = editOf(d);
  return !!(e.note && e.note.trim()) || !!(e.noteZh && e.noteZh.trim())
      || (e.tags && e.tags.length) || !!(e.fix && e.fix.trim());
};

// ── controls ───────────────────────────────────────────────────────────────
const sports = [...new Set(DRILLS.map(d => d.sport))];
const $sport = document.getElementById('sport');
$sport.innerHTML = '<option value="all">全部运动</option>' +
  sports.map(s => `<option value="${s}">${s} (${DRILLS.filter(d=>d.sport===s).length})</option>`).join('');

let current = null;
const $list = document.getElementById('list');
const $pane = document.getElementById('pane');

function visible() {
  const sp = $sport.value, f = document.getElementById('filter').value;
  const q = document.getElementById('q').value.trim().toLowerCase();
  return DRILLS.filter(d => {
    if (sp !== 'all' && d.sport !== sp) return false;
    if (q && !(d.name.toLowerCase().includes(q) || d.nameZh.includes(q) || d.id.includes(q))) return false;
    if (f === 'error') return d.issues.some(i => i.level === 'error');
    if (f === 'edited') return isEdited(d);
    if (f === 'todo') return !isEdited(d);
    if (f !== 'all') return d.issues.some(i => i.id === f);
    return true;
  });
}

function renderList() {
  const vis = visible();
  const errs = vis.filter(d => d.issues.some(i => i.level === 'error')).length;
  const done = vis.filter(isEdited).length;
  document.getElementById('counts').innerHTML =
    `${vis.length} 个 · <b>${errs}</b> 个有错 · ${done} 个已改`;
  $list.innerHTML = vis.map(d => {
    const lv = new Set(d.issues.map(i => i.level));
    const dots = ['error','warn','info'].filter(l => lv.has(l))
      .map(l => `<span class="dot ${l}"></span>`).join('') +
      (isEdited(d) ? '<span class="dot done"></span>' : '');
    return `<button class="row ${current && key(current)===key(d) ? 'on':''}" data-k="${key(d)}">
      <span class="dots">${dots}</span>
      <span class="nm">${d.nameZh || d.name}</span>
      <span class="sub">${d.sport} · ${d.id}</span>
    </button>`;
  }).join('') || '<p class="empty">没有匹配的训练</p>';
  $list.querySelectorAll('.row').forEach(b =>
    b.addEventListener('click', () => select(DRILLS.find(d => key(d) === b.dataset.k))));
}

// ── board ──────────────────────────────────────────────────────────────────
// The boards are PNGs rendered by the app's own TacticsCanvas, so this page
// cannot disagree with the phone about what a drill looks like.
const src = (d, step) => `board_png/${d.sport}/${d.id}-${step}.png`;

function preload(d) {
  for (let i = 0; i <= d.maxStep; i++) new Image().src = src(d, i);
}

// ── detail ─────────────────────────────────────────────────────────────────
let step = 0;

function select(d) {
  current = d; step = 0; preload(d);
  renderList();
  renderPane();
}

function renderPane() {
  const d = current;
  if (!d) { $pane.innerHTML = '<p class="empty">从左边选一个训练</p>'; return; }
  const e = editOf(d);
  const issues = d.issues.length
    ? `<ul class="issues">${d.issues.map(i =>
        `<li class="issue ${i.level}"><span class="tag">${i.id}</span>${i.text}</li>`).join('')}</ul>`
    : '<p class="clean">没有查出问题</p>';

  $pane.innerHTML = `
    <div class="head">
      <div>
        <h1>${d.nameZh || d.name}</h1>
        <p class="zh">${d.name}</p>
      </div>
    </div>
    <p class="meta">
      <span>${d.sport}</span><span>${d.category}</span><span>${d.level}</span>
      <span>${d.minutes} 分钟</span><span>${d.players} 人</span>
      <span>${d.maxStep} 步</span>${d.family ? `<span>${d.family}</span>` : ''}
      <span>${d.id}</span>
    </p>

    <div class="split">
      <div class="boardwrap">
        <img class="board" id="svg" src="${src(d, step)}" alt="第 ${step} 步">
        <div class="steps">
          <button class="ghost" id="prev">‹</button>
          <span class="n" id="stepn">${step} / ${d.maxStep}</span>
          <button class="ghost" id="next">›</button>
          <button class="ghost" id="play">播放</button>
        </div>
      </div>

      <div>
        ${issues}

        <h3>现有说明</h3>
        <p class="cur">${d.note || '<i>空</i>'}</p>
        <p class="cur zh">${d.noteZh || '<i>空</i>'}</p>

        <h3>改写后的说明 · 中文</h3>
        <textarea id="noteZh" placeholder="怎么摆、怎么跑、教练看什么。写到 45 词以上才算详细。">${e.noteZh || ''}</textarea>
        <p class="wc" id="wcZh"></p>

        <h3>改写后的说明 · English</h3>
        <textarea id="note" placeholder="Setup, how it runs, what the coach is looking for.">${e.note || ''}</textarea>
        <p class="wc" id="wc"></p>

        <h3>标签</h3>
        <div class="tags" id="tags"></div>

        <h3>板子要怎么改</h3>
        <textarea id="fix" placeholder="例如：球要跟着 2→3→4→5 走完四步；3 号起始位置往右挪 60。">${e.fix || ''}</textarea>

        <h3>现有常见错误</h3>
        <p class="cur">${d.mistake || '<i>空</i>'}</p>
        <p class="cur zh">${d.mistakeZh || '<i>空</i>'}</p>

        <div class="actions">
          <button id="save">保存这一条</button>
          <button class="ghost" id="nextTodo">保存并跳到下一个</button>
          <span class="saved" id="savedmsg"></span>
        </div>
      </div>
    </div>`;

  const tagBox = document.getElementById('tags');
  const chosen = new Set(e.tags || d.tags || []);
  tagBox.innerHTML = TAGS.map(t =>
    `<button class="tag-btn ${chosen.has(t)?'on':''}" data-t="${t}">${t}</button>`).join('');
  tagBox.querySelectorAll('.tag-btn').forEach(b => b.addEventListener('click', () => {
    b.classList.toggle('on');
  }));

  const count = (ta, out, target) => {
    const n = ta.value.trim() ? ta.value.trim().split(/\s+|(?<=[一-龥])/).filter(Boolean).length : 0;
    out.textContent = `${n} 词 / 目标 ${target}+`;
    out.className = 'wc' + (n >= target ? ' ok' : '');
  };
  const zh = document.getElementById('noteZh'), en = document.getElementById('note');
  const wcZh = document.getElementById('wcZh'), wc = document.getElementById('wc');
  count(zh, wcZh, 45); count(en, wc, 45);
  zh.addEventListener('input', () => count(zh, wcZh, 45));
  en.addEventListener('input', () => count(en, wc, 45));

  document.getElementById('prev').onclick = () => { step = Math.max(0, step-1); redrawBoard(); };
  document.getElementById('next').onclick = () => { step = Math.min(d.maxStep, step+1); redrawBoard(); };
  document.getElementById('play').onclick = () => {
    step = 0; redrawBoard();
    const t = setInterval(() => {
      if (step >= d.maxStep) return clearInterval(t);
      step++; redrawBoard();
    }, 700);
  };
  document.getElementById('save').onclick = () => doSave(false);
  document.getElementById('nextTodo').onclick = () => doSave(true);
}

function redrawBoard() {
  const img = document.getElementById('svg');
  img.src = src(current, step);
  img.alt = `第 ${step} 步`;
  document.getElementById('stepn').textContent = `${step} / ${current.maxStep}`;
}

function doSave(advance) {
  const d = current;
  const tags = [...document.querySelectorAll('#tags .tag-btn.on')].map(b => b.dataset.t);
  edits[key(d)] = {
    sport: d.sport, id: d.id,
    noteZh: document.getElementById('noteZh').value.trim(),
    note: document.getElementById('note').value.trim(),
    fix: document.getElementById('fix').value.trim(),
    tags,
  };
  if (!isEdited(d)) delete edits[key(d)];
  save();
  document.getElementById('savedmsg').textContent = '已保存';
  setTimeout(() => { const m = document.getElementById('savedmsg'); if (m) m.textContent = ''; }, 1400);
  renderList();
  if (advance) {
    const vis = visible();
    const i = vis.findIndex(x => key(x) === key(d));
    if (i >= 0 && i + 1 < vis.length) select(vis[i+1]);
  }
}

document.getElementById('export').onclick = () => {
  const rows = Object.values(edits);
  if (!rows.length) return alert('还没有任何修改');
  const blob = new Blob([JSON.stringify(rows, null, 2)], {type:'application/json'});
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'drill_corrections.json';
  a.click();
};
document.getElementById('clear').onclick = () => {
  if (!confirm('清空所有本地修改？')) return;
  edits = {}; save(); renderList(); renderPane();
};
['sport','filter','q'].forEach(id =>
  document.getElementById(id).addEventListener('input', () => { renderList(); }));

renderList();
// Open on the worked example rather than an empty pane: passing_diamond is
// the drill every fix so far was proven on, so review starts where the
// reference is. Falls back to the first visible drill for a filtered build.
select(DRILLS.find(d => d.id === 'passing_diamond') || visible()[0] || null);
</script>
</body>
</html>
"""

if __name__ == "__main__":
    sys.exit(main())
