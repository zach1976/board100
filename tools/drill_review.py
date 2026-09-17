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

NOTE_TARGET_WORDS = 35


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
    # Does a station routine come round again?
    #
    # A coach reported the triangle stopping: the ball went 1→2→3 and that
    # was that, when a warm-up is something you set up once and let turn over
    # for eight minutes. The shape of the defect is a cone that had somebody
    # on it at the start and has nobody on it at the end — the routine has
    # nowhere to restart from. Only for one-body-per-station drills; a rondo's
    # cones mark the grid, not places to stand.
    cones = [p for p in board["players"] if kind(p) == "marker"]
    # "Standing on it", not "somewhere near it". In the rotation drills every
    # body is within 69 units of its cone; the 2v2 that this first mis-flagged
    # had a player 229 from the nearest marker and was still counted as on
    # one, because the radius was borrowed from the overlap check and is far
    # too generous for this.
    near = 150.0

    def on_a_cone(pos):
        return any(((pos[0] - c["position"][0]) ** 2
                    + (pos[1] - c["position"][1]) ** 2) ** 0.5 <= near
                   for c in cones)

    # EVERY player has to start on a station for this to be a rotation at
    # all. Counting cones against bodies is not enough: a 4v4 with four goals
    # and a 2v2 with court markers both match the count while nobody is
    # standing on anything, and both were flagged as broken rotations.
    is_rotation = (len(cones) >= 3 and movers
                   and len(people) in (len(cones), len(cones) + 1)
                   and all(on_a_cone(p["position"]) for p in people))
    if is_rotation:
        empty = []
        for c in cones:
            cp = c["position"]
            def close(pos, cp=cp):
                return ((pos[0] - cp[0]) ** 2 + (pos[1] - cp[1]) ** 2) ** 0.5 <= near
            had = any(close(p["position"]) for p in people)
            has = any(close(position_at(p, max_step(board))) for p in people)  # noqa: E501
            if had and not has:
                empty.append(cp)
        if empty:
            out.append({
                "id": "loop_open",
                "level": "error",
                "text": f"轮转不闭环：{len(empty)} 个起始有人的锥标在结束时空着，"
                        "下一轮没人接得上",
            })

    # A circulation drill whose ball never comes back.
    #
    # The rotation check above needs somebody to vacate a station, so it is
    # blind to the shape where nobody rotates at all and only the ball moves
    # — a rondo. Every rondo shipped passing three quarters of the way round
    # and stopping, which is a picture of a fragment: the ball goes round
    # until the middle wins it, and that is the whole drill.
    #
    # Read off the ball path the drill already writes for itself, in English
    # because that locale always exists. A path whose stops are all shirt
    # numbers is a circuit among team-mates and should close; one that ends
    # at "basket", "goal" or "net" is a shot, and asking a shot to come round
    # is asking the drill to stop scoring.
    route = next((ln.split(":", 1)[1] for ln in drill.get("note", {})
                  .get("en", "").split("\n") if "→" in ln and ":" in ln), "")
    stops = [t.strip() for t in route.split("→") if t.strip()]
    # …and only where NOBODY rotates. A pass-and-follow pattern closes its
    # circle through a fresh body — the spare's number is not the starter's —
    # so demanding the same shirt at both ends flags a routine that works.
    # The shape this is about is the static ring: everyone holds station and
    # only the ball travels.
    holds_station = people and max(
        (((position_at(p, max_step(board))[0] - p["position"][0]) ** 2
          + (position_at(p, max_step(board))[1] - p["position"][1]) ** 2) ** 0.5)
        for p in people) <= 200
    if (len(stops) >= 4 and all(t.isdigit() or len(t) == 1 for t in stops)
            and stops[0] != stops[-1] and holds_station):
        out.append({
            "id": "ball_not_round",
            "level": "warn",
            "text": f"球没有转回起点：{' → '.join(stops)} —— "
                    "传接循环没有闭合，下一轮接不上",
        })

    # A drill has to be runnable more than once. Either it is a loop — the
    # last beat leaves everyone, and the ball, back where they began — or it
    # is a rep with an end (the ball's last stop is a goal, a spot, a
    # keeper: not a player who then stands holding it) AND a 【规则】 line
    # saying how the next rep starts. Anything else stops halfway: "passes
    # to 10" and then nothing, which is what the reviewer kept finding.
    last = max_step(board)
    NEAR = 220
    def dist(a, b):
        return abs(a[0] - b[0]) + abs(a[1] - b[1])
    # A loop as a set: every starting spot is filled again at the end by
    # somebody of the same team — a pass-and-follow rotation closes without
    # anyone standing where he began — and the ball is back where it was
    # (to within the width of a man: it sits on one foot or the other).
    def spots_refilled(side):
        starts = [tuple(p["position"]) for p in side]
        ends = [tuple(position_at(p, last)) for p in side]
        for s0 in starts:
            j = next((k for k, e in enumerate(ends) if dist(s0, e) <= NEAR), None)
            if j is None:
                return False
            ends.pop(j)
        return True
    teams = {}
    for p in people:
        teams.setdefault(p.get("team"), []).append(p)
    loop = (last > 0 and all(spots_refilled(side) for side in teams.values())
            and all(dist(b["position"], position_at(b, last)) <= 200
                    for b in balls))
    has_rules = any(ln.startswith("How it continues:") for ln in
                    drill.get("note", {}).get("en", "").split("\n"))
    if balls and balls[0].get("moves"):
        ball = balls[0]
        bx, by = position_at(ball, last)
        def keeper(p):
            return p.get("role") == "GK" or str(p.get("label", "")).upper() in ("GK", "K")
        # A stop at an outfield player's feet is a player; the goal, the
        # net, the keeper's hands or the space a run went into is an end.
        def nearest(pt, step, skip_keeper):
            best, who = 131, None
            for p in people:
                if skip_keeper and keeper(p):
                    continue
                dd = dist(position_at(p, step), pt)
                if dd < best:
                    best, who = dd, p
            return who
        holder = nearest((bx, by), last, True)
        # …unless he carried it there: a dribble ends where the dribbler
        # stops, and that IS the end of the rep. A carry is a leg whose
        # start was already at this man's feet — a pass that arrives as
        # he runs onto it is not one.
        carried = False
        if holder is not None and ball.get("moves"):
            prev_pt = ball["moves"][-2] if len(ball["moves"]) >= 2 else ball["position"]
            prev_ph = ball["movePhases"][-1]   # beats elapsed before the last leg
            carried = dist(position_at(holder, prev_ph), prev_pt) <= 130
        # …or the keeper played it to him: a distribution is the end of a
        # keeper's rep, whoever catches it.
        from_keeper = False
        if holder is not None and len(ball.get("moves", [])) >= 2:
            px, py = ball["moves"][-2]
            from_keeper = any(keeper(p) and dist(position_at(p, last), (px, py)) <= 150
                              for p in people)
        # The route line is the author's own word for where it ends: a
        # last stop that is not a shirt ("goal", "the open spot") is an end
        # even when a man is standing right next to it.
        labels = {str(p.get("label", "")) for p in people}
        route_en = next((ln.split(":", 1)[1] for ln in
                         drill.get("note", {}).get("en", "").split("\n")
                         if ln.startswith("Ball path:")), "")
        route_stops = [t.strip() for t in route_en.split("→") if t.strip()]
        ends_off_board = bool(route_stops) and route_stops[-1] not in labels
        # …or the other side has it now: a defender who steps in and wins
        # the ball has ended the rep as surely as a shot.
        won = False
        if holder is not None and len(ball.get("moves", [])) >= 2:
            px, py = ball["moves"][-2]
            prev_ph = ball["movePhases"][-2] + 1
            # The nearest man, not the first within reach: the one who lost
            # it is usually standing right beside the spot too.
            before = nearest((px, py), prev_ph, False)
            won = before is not None and before.get("team") != holder.get("team")
        terminal = (holder is None or carried or from_keeper or ends_off_board
                    or won)
    else:
        terminal = not movers
    if movers and not loop:
        if not terminal:
            out.append({
                "id": "half_done",
                "level": "warn",
                "text": "只做了一半：球最后停在某个球员脚下，既没有回到起点"
                        "（不成循环），也没有终点（射门/出球/门将）—— "
                        "要么补完整回合，要么让它转回起点",
            })
        elif not has_rules:
            out.append({
                "id": "no_next_rep",
                "level": "warn",
                "text": "一回合有终点，但没有【连贯】说下一回合怎么开始"
                        "（谁换、球从哪儿来）",
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
                "usage": d.get("usage", 2),
                "frame": d.get("frame"),
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
    # Within a sport, straight by how often the drill is run — the staples
    # of every category first, whatever the category — then the file order.
    # Reviewing in that order puts the drills most players will meet at
    # the top of the queue.
    drills.sort(key=lambda d: (d["sport"], -d["usage"]))
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
  /* A drill that stays in one half is shown at that half, the way the app
     shows it: the box keeps the width and 56% of the picture's height, and
     the image is pinned to the busy end. */
  .boardbox.half{overflow:hidden;border-radius:12px;border:1px solid var(--border);
                 aspect-ratio:402/409;position:relative}
  .boardbox.half img.board{border:0;border-radius:0;position:absolute;left:0;width:100%}
  .boardbox.half.top img.board{top:0}
  .boardbox.half.bottom img.board{bottom:0}
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
  .cur .beat{border-radius:4px;padding:0 2px}
  .cur .beat.on{background:rgba(32,199,195,.22);outline:1px solid var(--accent)}
  .beat-now{margin-top:10px;min-height:2.6em;padding:8px 12px;border-radius:10px;
    background:var(--bg1);border:1px solid var(--accent);font-size:14px;line-height:1.5}
  .beat-now .en{color:var(--dim);font-size:12.5px;display:block;margin-top:2px}
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

// Where the reviewer was — sport, filter, search, drill, step — so a refresh
// (or the next morning) opens the page exactly there. The drill also goes
// into the URL, so a reload lands on it even if storage is cleared.
const STATE_KEY = 'drill-review-state-v1';
function saveState() {
  try {
    localStorage.setItem(STATE_KEY, JSON.stringify({
      sport: document.getElementById('sport').value,
      filter: document.getElementById('filter').value,
      q: document.getElementById('q').value,
      drill: current ? key(current) : null,
      step,
    }));
  } catch (e) { /* private mode: nothing to remember with */ }
  if (current) {
    const url = new URL(location.href);
    url.searchParams.set('d', key(current));
    history.replaceState(null, '', url);
  }
}
function loadState() {
  try { return JSON.parse(localStorage.getItem(STATE_KEY) || 'null'); }
  catch (e) { return null; }
}
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

function select(d, at = 0) {
  current = d; step = at; preload(d);
  renderList();
  renderPane();
  saveState();
  // Keep the chosen row in view — after a refresh the list has just been
  // rebuilt and would otherwise sit at the top.
  const row = $list.querySelector('.row.on');
  if (row) row.scrollIntoView({ block: 'nearest' });
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
      <span>${d.minutes} 分钟</span><span>${d.players} 人</span><span>${['', '偶尔', '一般', '常用'][d.usage] || ''}</span>
      <span>${d.maxStep} 步</span>${d.family ? `<span>${d.family}</span>` : ''}
      <span>${d.id}</span>
    </p>

    <div class="split">
      <div class="boardwrap">
        <div class="boardbox ${d.frame ? 'half ' + d.frame : ''}">
          <img class="board" id="svg" src="${src(d, step)}" alt="第 ${step} 步">
        </div>
        <div class="steps">
          <button class="ghost" id="prev">‹</button>
          <span class="n" id="stepn">${step} / ${d.maxStep}</span>
          <button class="ghost" id="next">›</button>
          <button class="ghost" id="play">播放</button>
        </div>
        <div class="beat-now" id="beatNow"></div>
      </div>

      <div>
        ${issues}

        <h3>现有说明</h3>
        <p class="cur" id="noteEn">${noteHtml(d.note)}</p>
        <p class="cur zh" id="noteZhCur">${noteHtml(d.noteZh)}</p>

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
  // Clicking a sentence walks the board to that beat.
  for (const el of document.querySelectorAll('.cur .beat')) {
    el.style.cursor = 'pointer';
    el.addEventListener('click', () => { step = Number(el.dataset.k); redrawBoard(); });
  }
  redrawBoard();
}

// The note, with every beat of its sequence line wrapped so the stepper can
// light up the sentence the board is showing. Step 0 is the set-up line.
const SEQ_HEAD = /^(【流程】|Sequence: )/;
const SETUP_HEAD = /^(【组织】|Setup: )/;
function noteHtml(note) {
  if (!note) return '<i>空</i>';
  return note.split('\n').map(line => {
    if (SETUP_HEAD.test(line)) return `<span class="beat" data-k="0">${line}</span>`;
    if (!SEQ_HEAD.test(line)) return line;
    const head = line.match(SEQ_HEAD)[0];
    const body = line.slice(head.length);
    const parts = body.split(/(?<=；)|(?<=; )/);
    return head + parts.map((t, i) => `<span class="beat" data-k="${i + 1}">${t}</span>`).join('');
  }).join('<br>');
}
function beatText(note, k) {
  if (!note) return '';
  for (const line of note.split('\n')) {
    if (k === 0 && SETUP_HEAD.test(line)) return line.replace(SETUP_HEAD, '');
    if (k > 0 && SEQ_HEAD.test(line)) {
      const parts = line.replace(SEQ_HEAD, '').split(/(?<=；)|(?<=; )/);
      return (parts[k - 1] || '').replace(/[；;]\s*$/, '');
    }
  }
  return '';
}

function redrawBoard() {
  const img = document.getElementById('svg');
  img.src = src(current, step);
  img.alt = `第 ${step} 步`;
  document.getElementById('stepn').textContent = `${step} / ${current.maxStep}`;
  saveState();
  // The sentence for this step, under the board and lit in the note.
  const zh = beatText(current.noteZh, step), en = beatText(current.note, step);
  const box = document.getElementById('beatNow');
  if (box) box.innerHTML = `${zh || (step === 0 ? '初始站位' : '')}<span class="en">${en}</span>`;
  for (const el of document.querySelectorAll('.cur .beat')) {
    el.classList.toggle('on', Number(el.dataset.k) === step);
  }
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
  document.getElementById(id).addEventListener('input', () => { renderList(); saveState(); }));

// Restore the filters before the first list is drawn.
const saved = loadState();
if (saved) {
  for (const id of ['sport', 'filter', 'q']) {
    const el = document.getElementById(id);
    if (saved[id] != null && [...(el.options || [])].some(o => o.value === saved[id]) || id === 'q') {
      if (saved[id] != null) el.value = saved[id];
    }
  }
}
renderList();
// Open on the worked example rather than an empty pane: passing_diamond is
// the drill every fix so far was proven on, so review starts where the
// reference is. Falls back to the first visible drill for a filtered build.
// ?d=soccer/rondo_4v2 opens straight on one drill — the thumbnail page
// links here that way.
const want = new URLSearchParams(location.search).get('d') || (saved && saved.drill);
const opening = (want && DRILLS.find(d => key(d) === want))
  || DRILLS.find(d => d.id === 'passing_diamond') || visible()[0] || null;
select(opening, saved && saved.drill === want && opening ? Math.min(saved.step || 0, opening.maxStep) : 0);
</script>
</body>
</html>
"""

if __name__ == "__main__":
    sys.exit(main())
