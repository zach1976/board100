"""Board geometry and the drill spec — the parts every sport shares.

A drill is a board: players, equipment, a ball, and a movement path per player
carrying a phase number so the play unfolds in order. This module turns that
spec into the same JSON the app writes when you save a tactic, which is why a
loaded drill is immediately editable rather than a locked diagram.

Positions are in a nominal 1000x1500 portrait canvas (attacking upward: the
opponent's goal is at y=0). The app rescales a loaded board to whatever canvas
it is on, so these numbers are proportions, not pixels. Author with rel=True
and give coordinates inside the playing surface (0..1) instead — court_rect
maps them, which is the only way to be sure nobody is standing in the margin.
"""
import math
import re as _re
from dataclasses import dataclass, field

from .vocab import NEUTRAL, V

CANVAS_W, CANVAS_H = 1000.0, 1500.0

# SportType's enum index — persisted in saved boards, so it is the sport's
# real identity and must match lib/models/sport_type.dart exactly.
SPORT_INDEX = {
    "badminton": 0, "tableTennis": 1, "tennis": 2, "basketball": 3,
    "volleyball": 4, "pickleball": 5, "soccer": 6, "fieldHockey": 7,
    "rugby": 8, "baseball": 9, "handball": 10, "waterPolo": 11,
    "sepakTakraw": 12, "beachTennis": 13, "footvolley": 14,
}

# Court geometry, mirroring SportType.fieldRect: the playing surface is
# centred in the canvas at a fixed aspect, so a basketball court leaves far
# more dead canvas at the sides than a football pitch does. Sports authored
# with rel=True give coordinates inside the court (0..1) and are mapped here,
# which is the only way to be sure a player isn't standing in the margin.
# (aspect = width/height, scale when fitting by width, scale when by height).
# A table tennis table is the odd one out: it is drawn small on purpose,
# because the players stand well back from it and the room matters.
COURT = {
    "badminton":   (6.1 / 13.4,     0.88, 0.88),
    "tableTennis": (1.525 / 2.74,   0.65, 0.55),
    "tennis":      (10.97 / 23.77,  0.85, 0.85),
    "basketball":  (15 / 28,        0.90, 0.90),
    "volleyball":  (9 / 18,         0.85, 0.85),
    "pickleball":  (6.1 / 13.41,    0.88, 0.88),
    "soccer":      (68 / 105,       0.90, 0.90),
    "fieldHockey": (55 / 91.4,      0.90, 0.90),
    "rugby":       (70 / 144,       0.92, 0.92),
    "baseball":    (1.0,            0.95, 0.95),
    "handball":    (20 / 40,        0.90, 0.90),
    "waterPolo":   (20 / 30,        0.88, 0.88),
    "sepakTakraw": (6.1 / 13.4,     0.88, 0.88),
    "beachTennis": (8 / 16,         0.85, 0.85),
    "footvolley":  (9 / 18,         0.85, 0.85),
}


def court_rect(sport: str) -> tuple[float, float, float, float]:
    aspect, scale_w, scale_h = COURT[sport]
    if CANVAS_W / CANVAS_H > aspect:
        ch = CANVAS_H * scale_h
        cw = ch * aspect
    else:
        cw = CANVAS_W * scale_w
        ch = cw / aspect
    return ((CANVAS_W - cw) / 2, (CANVAS_H - ch) / 2, cw, ch)

TEAM_HOME, TEAM_AWAY, TEAM_NEUTRAL = 0, 1, 2
# MarkerShape enum order in lib/models/player_icon.dart
MARKER = {"none": 0, "circle": 1, "square": 2, "triangle": 3, "diamond": 4,
          "cone": 5, "text": 6, "zone": 7, "referee": 8, "coach": 9,
          "ladder": 10, "hurdle": 11, "arrow": 12}

MOVE_COLORS = [0xFF40C4FF, 0xFFFF6D6D, 0xFF69F0AE, 0xFFFFD740,
               0xFFEA80FC, 0xFF84FFFF, 0xFFFF9E80, 0xFFA5D6A7]


@dataclass
class P:
    """A player. `moves` is a list of (x, y, phase) — the run, in order."""
    x: float
    y: float
    label: str = ""
    role: str | None = None
    moves: list = field(default_factory=list)


@dataclass
class M:
    """A piece of equipment: cone, ladder, hurdle, a marked zone."""
    x: float
    y: float
    shape: str = "cone"
    label: str = ""


@dataclass
class Drill:
    id: str
    category: str          # warmup | possession | attacking | finishing |
                           # defending | setpiece | ssg | goalkeeping |
                           # conditioning
    minutes: int
    name: dict             # locale -> str  (en required)
    note: dict             # locale -> str  (en required; the coaching point)
    home: list             # [P]
    away: list = field(default_factory=list)
    markers: list = field(default_factory=list)
    # index into `home` whose feet the ball starts at, or an (x, y) for a loose ball
    ball: object = None
    # Coordinates are relative to the court (0..1), not the canvas. Used by
    # every sport after soccer — soccer was authored in canvas coordinates,
    # where the pitch fills all but 6% of the width so it made little
    # difference. Anything narrower (a basketball court leaves 14% margins)
    # needs this or players stand off the floor.
    rel: bool = False
    # Some drills legitimately place a player off the playing surface: the
    # thrower at a throw-in stands behind the touchline, by the rules. Marked
    # so the "everyone is on the pitch" check can stay strict for the rest.
    off_surface: bool = False
    # In the free tier. The free set is chosen so a coach can run a whole
    # session on it — warm-up through small-sided game — because a starter
    # library that can't start anything is an advert, not a starter library.
    free: bool = False
    # Where the ball goes, as [(x, y, phase), ...]. A carried ball follows
    # its holder, which is right for a dribble and useless for a throw:
    # baseball drew four double plays and two relays without a single ball
    # in flight, because the ball could not move on its own.
    ball_moves: list = field(default_factory=list)
    # Some formations really are shoulder to shoulder — a free-kick wall, a
    # scrum, a screen. Those may sit closer than one icon apart, but never
    # closer than the labels can be told apart. Everything else must not
    # overlap at all: see SPACING_* below for why the numbers are in points.
    tight: bool = False
    # foundation | development | advanced. Left None, it is derived from what
    # the drill demands (see derive_level); set it only where the rule is
    # wrong — a banana flick needs two players and years of table time.
    level: str | None = None

    @property
    def player_count(self) -> int:
        return len(self.home) + len(self.away)


def _player(idx, p: P, team: int, sport: str, color_idx: int) -> dict:
    moves = [[m[0], m[1]] for m in p.moves]
    phases = [m[2] for m in p.moves]
    return {
        "id": f"d{idx}",
        "label": p.label,
        "team": team,
        "sportType": None,
        "position": [p.x, p.y],
        "scale": 1.0,
        "moves": moves,
        "movePhases": phases,
        "moveColor": MOVE_COLORS[color_idx % len(MOVE_COLORS)],
        "customColor": None,
        "gender": 2,                      # unspecified
        "markerShape": MARKER["none"],
        "photoId": None,
        "role": p.role,
        "attachedTo": None,
    }


def _marker(idx, m: M) -> dict:
    return {
        "id": f"m{idx}",
        "label": m.label,
        "team": TEAM_NEUTRAL,
        "sportType": None,
        "position": [m.x, m.y],
        "scale": 1.0,
        "moves": [],
        "movePhases": [],
        "moveColor": MOVE_COLORS[0],
        "customColor": None,
        "gender": 2,
        "markerShape": MARKER[m.shape],
        "photoId": None,
        "role": None,
        "attachedTo": None,
    }


def _ball(idx, sport: str, x: float, y: float, attached_to: str | None,
          moves: list | None = None) -> dict:
    return {
        "id": f"b{idx}",
        "label": "",
        "team": TEAM_NEUTRAL,
        "sportType": SPORT_INDEX[sport],   # a ball is neutral WITH a sport
        "position": [x, y],
        "scale": 1.0,
        "moves": [[m[0], m[1]] for m in (moves or [])],
        "movePhases": [m[2] for m in (moves or [])],
        "moveColor": MOVE_COLORS[0],
        "customColor": None,
        "gender": 2,
        "markerShape": MARKER["none"],
        "photoId": None,
        "role": None,
        # A thrown ball is not carried: it leaves the hand.
        "attachedTo": None if moves else attached_to,
    }


def prune_degenerate_moves(drill: Drill) -> None:
    """Drop movement segments that go nowhere.

    A waypoint under 8 canvas px from the previous point draws a dead arrow
    and burns a playback step on nothing. They creep in when a family computes
    an endpoint that happens to equal the start — a relay whose target is the
    base the runner is already on — so they are pruned here rather than fixed
    fifteen separate times.
    """
    for p in drill.home + drill.away:
        pruned, prev = [], (p.x, p.y)
        for (x, y, ph) in p.moves:
            if abs(x - prev[0]) + abs(y - prev[1]) >= 8:
                pruned.append((x, y, ph))
                prev = (x, y)
        p.moves = pruned


def normalise_phases(drill: Drill) -> None:
    """Renumber phases to 0,1,2… across the whole drill.

    Playback walks steps in order, so a drill whose first movement sits at
    phase 1 opens with a step where nothing happens, and a gap in the middle
    is a dead press of the button. Authors think in "this happens after that",
    not in dense integers — so fix it here instead of in every spec.
    """
    # The ball's own flight counts: a throw on phase 2 with nothing on
    # phase 1 is the same dead press of the button as a player's would be.
    used = sorted({m[2] for p in drill.home + drill.away for m in p.moves}
                  | {m[2] for m in drill.ball_moves})
    if not used or used == list(range(len(used))):
        return
    remap = {old: new for new, old in enumerate(used)}
    for p in drill.home + drill.away:
        p.moves = [(x, y, remap[ph]) for (x, y, ph) in p.moves]
    drill.ball_moves = [(x, y, remap[ph]) for (x, y, ph) in drill.ball_moves]


def to_canvas(drill: Drill, sport: str) -> None:
    """Map a rel=True drill's court coordinates onto the canvas, in place."""
    if not drill.rel:
        return
    left, top, w, h = court_rect(sport)
    def fx(x): return left + x * w
    def fy(y): return top + y * h
    for p in drill.home + drill.away:
        p.x, p.y = fx(p.x), fy(p.y)
        p.moves = [(fx(mx), fy(my), ph) for (mx, my, ph) in p.moves]
    for m in drill.markers:
        m.x, m.y = fx(m.x), fy(m.y)
    if isinstance(drill.ball, tuple):
        drill.ball = (fx(drill.ball[0]), fy(drill.ball[1]))
    drill.ball_moves = [(fx(mx), fy(my), ph) for (mx, my, ph) in drill.ball_moves]
    drill.rel = False


def reserve_keeper_number(drill: Drill, sport: str) -> None:
    """In football, 1 is the goalkeeper — nobody else may wear it.

    Generic drills number their players 1, 2, 3... as a sequence, which on a
    football pitch reads as "the keeper is in this rondo". Where a side's
    numbers are a plain run starting at 1, shift the whole run up so it
    starts at 2; anything else is left for a person, and audit() will say so.
    """
    if sport != "soccer":
        return
    for side in (drill.home, drill.away):
        nums = sorted(int(p.label) for p in side if p.label.isdigit())
        if not nums or nums[0] != 1:
            continue
        if nums != list(range(1, len(nums) + 1)):
            continue           # not a plain run — audit() will flag it
        for p in side:
            if p.label.isdigit():
                p.label = str(int(p.label) + 1)


def space_out(drill: Drill, sport: str) -> None:
    """Push overlapping people apart until their icons stop covering each other.

    Authoring is in court-relative units, which are not square — 0.01 across
    is under 4pt while 0.01 down is about 6pt — so a defender written 0.05
    "goal-side of" his man ended up standing on him at 44pt icon size. Rather
    than re-guess 154 boards' coordinates, this restores legibility without
    touching intent: each overlapping pair is pushed apart *along the line it
    already sits on*, by the smallest amount that clears the icons, so who is
    in front of whom never changes. Positions are kept inside the playing
    surface, and audit() still runs afterwards — a board too crowded for this
    to fix fails, as it should.

    Drills that declare tight=True (a scrum, a wall, a double block) keep
    their formation and are only opened to where the labels can be read.
    """
    if sport in SPACING_UNCHECKED:
        return
    floor = SPACING_TIGHT if drill.tight else SPACING_APART
    left, top, w, h = court_rect(sport)
    sx = CANVAS_PT[0] / BOARD_UNITS[0]
    sy = CANVAS_PT[1] / BOARD_UNITS[1]
    people = drill.home + drill.away
    # A thrower at a lineout or a throw-in stands outside the touchline by
    # the rules (that is what off_surface exempts). Clamping him to the
    # court would delete the very thing the drill is about, so anyone who
    # starts outside is kept outside and only held on the canvas.
    outside = {id(p) for p in people
               if not (left - 12 <= p.x <= left + w + 12
                       and top - 12 <= p.y <= top + h + 12)}
    for _ in range(60):
        moved = False
        for i in range(len(people)):
            for j in range(i + 1, len(people)):
                a, b = people[i], people[j]
                dx, dy = (b.x - a.x) * sx, (b.y - a.y) * sy
                d = math.hypot(dx, dy)
                if d >= floor:
                    continue
                if d < 1e-6:                    # exactly stacked: split sideways
                    dx, dy, d = 1.0, 0.0, 1.0
                push = (floor - d) / 2 + 0.5
                ux, uy = dx / d, dy / d
                a.x -= ux * push / sx; a.y -= uy * push / sy
                b.x += ux * push / sx; b.y += uy * push / sy
                for p in (a, b):
                    if id(p) in outside:
                        p.x = min(max(p.x, 12), BOARD_UNITS[0] - 12)
                        p.y = min(max(p.y, 12), BOARD_UNITS[1] - 12)
                    else:
                        p.x = min(max(p.x, left + 8), left + w - 8)
                        p.y = min(max(p.y, top + 8), top + h - 8)
                moved = True
        if not moved:
            return


def build_board(drill: Drill, sport: str) -> dict:
    reserve_keeper_number(drill, sport)
    to_canvas(drill, sport)
    space_out(drill, sport)
    prune_degenerate_moves(drill)
    normalise_phases(drill)
    players, i, color = [], 0, 0
    home_ids = []
    for p in drill.home:
        players.append(_player(i, p, TEAM_HOME, sport, color))
        home_ids.append(f"d{i}")
        i += 1
        color += 1
    for p in drill.away:
        players.append(_player(i, p, TEAM_AWAY, sport, color))
        i += 1
        color += 1
    for j, m in enumerate(drill.markers):
        players.append(_marker(j, m))

    if drill.ball is not None:
        if isinstance(drill.ball, int):
            assert drill.ball < len(drill.home), (
                f"{drill.id}: ball={drill.ball} but the drill has "
                f"{len(drill.home)} home player(s) — an away player holding "
                f"the ball is given as an (x, y) instead")
            holder = drill.home[drill.ball]
            bx, by = at_the_feet_of(holder.x, holder.y, sport)
            players.append(_ball(0, sport, bx, by, home_ids[drill.ball],
                                 drill.ball_moves))
        else:
            players.append(_ball(0, sport, drill.ball[0], drill.ball[1], None,
                                 drill.ball_moves))

    return {
        "sportType": SPORT_INDEX[sport],
        "players": players,
        "strokes": [],
        "canvasWidth": CANVAS_W,
        "canvasHeight": CANVAS_H,
    }



# ─────────────────────────────────────────────────────────────────────────────
# Drill families
#
# Real coaching libraries are mostly families, not one-offs: a rondo is run at
# 4v2, 5v2, 6v3; a small-sided game at 3v3 through 7v7; a counter at 2v1
# through 5v4. Each is a genuinely different session — the numbers change what
# the players have to solve — so they are generated from one spec rather than
# copy-pasted, and the geometry is computed instead of hand-placed.
#
# Names compose as "<family> <variant>", where the variant ("5v2", "4v4") is
# the same in every language, so a family needs translating once.
# ─────────────────────────────────────────────────────────────────────────────

def suffixed(base: dict, suffix) -> dict:
    """Family name in every locale, with the variant appended in that locale.

    A variant is one of three things. A dict is used as given. A
    language-neutral string — "5v2", "4-4-2", "zone 4" — reads the same
    everywhere and passes through. Anything else is an English phrase and must
    be in the shared vocabulary, or this raises: the alternative is a Chinese
    coach reading "步法 the forehand net", which is what this check exists to
    prevent.
    """
    if isinstance(suffix, dict):
        parts = suffix
    elif NEUTRAL.match(suffix):
        parts = {}
    else:
        try:
            parts = V[suffix]
        except KeyError:
            raise KeyError(
                f"drill variant {suffix!r} has no translation — add it to "
                f"tools/drills/vocab.py") from None
    out = {}
    for loc, text in base.items():
        variant = parts.get(loc, parts.get('en', suffix))
        # De-duplicate the seam. A variant's translation often carries the
        # category noun the family name already ends with — "Saque" + "saque
        # alto de individual", "Depan net" + "net berputar" — and the glued
        # name read as a stutter in 72 places across the library.
        def core(w):
            # French elision: "l'échange" ends in the same noun "échange".
            return w.lower().split("'")[-1]
        tw = text.split(" ")
        vw = variant.split(" ")
        while vw and tw and core(vw[0]) == core(tw[-1]):
            vw = vw[1:]
        out[loc] = f"{text} {' '.join(vw)}".rstrip() if vw else text
    return out


def ring(n: int, cx: float, cy: float, rx: float, ry: float,
         start_deg: float = -90.0) -> list[tuple[float, float]]:
    """n points evenly spaced on an ellipse, first at start_deg (up = -90)."""
    out = []
    for i in range(n):
        a = math.radians(start_deg + 360.0 * i / n)
        out.append((cx + rx * math.cos(a), cy + ry * math.sin(a)))
    return out


def grid(cols: int, rows: int, x0: float, y0: float, x1: float, y1: float
         ) -> list[tuple[float, float]]:
    """A cols x rows lattice of positions inside the given box."""
    out = []
    for r in range(rows):
        for c in range(cols):
            fx = x0 if cols == 1 else x0 + (x1 - x0) * c / (cols - 1)
            fy = y0 if rows == 1 else y0 + (y1 - y0) * r / (rows - 1)
            out.append((fx, fy))
    return out


def merge(curated: list[Drill], *families: list[Drill]) -> list[Drill]:
    """Curated drills first; a family variant with the same id is dropped.

    Families cover sizes that were also written by hand (rondo 4v2, counter
    3v2). The hand-written one wins: it was tuned, and its coaching note is
    specific to that size."""
    out = list(curated)
    seen = {d.id for d in out}
    for family in families:
        for d in family:
            if d.id in seen:
                continue
            seen.add(d.id)
            out.append(d)
    return out


def _common_prefix(names: list[str]) -> str:
    """The family half of "<family> <variant>", found back from the variants."""
    if not names:
        return ""
    head = names[0]
    for other in names[1:]:
        i = 0
        while i < min(len(head), len(other)) and head[i] == other[i]:
            i += 1
        head = head[:i]
    # Cut to a word boundary first: "Maul driving…" and "Maul defending…"
    # share the characters "Maul d", and a family must never be christened
    # with half a word. Composition always joins with a space, so the last
    # space in the raw prefix is the last safe place to stand.
    cut = head.rfind(" ")
    if cut >= 0 and head and head[-1] != " ":
        head = head[:cut + 1]
    head = head.rstrip(" ·-–—,+")
    # Then drop trailing function words. A family name reads as "<family>
    # <variant>" by construction, so several legitimately end in a preposition
    # or article ("Footwork to", "Attack from") — fine inside a full name,
    # wrong as a heading on its own. CJK and Thai need none of this.
    stop = {"to", "from", "off", "a", "an", "the", "at", "in", "on", "with",
            "for", "into", "and", "under", "against", "by", "de", "del", "en",
            "sur", "depuis", "dans", "des", "du", "la", "le", "les", "el",
            "dari", "ke", "dengan", "di", "pada", "từ", "vào", "trong"}
    parts = head.split(" ")
    while len(parts) > 1 and parts[-1].lower() in stop:
        parts.pop()
    return " ".join(parts).strip(" ·-–—,")


def assign_families(drills: list[Drill], sport: str) -> dict:
    """Group the variants of a family so the library can show them as one.

    A family is generated from one spec, so its variants share a note word for
    word — five cards carrying the same paragraph read as padding even though
    the coaching point really is the same for all five. Rather than invent
    five different paragraphs, the app shows the family once with its variants
    beside it, and that grouping is decided here, where the shared note is
    the evidence.

    Returns {drill id: (family id, {locale: family name})}.
    """
    buckets: dict[tuple, list[Drill]] = {}
    for d in drills:
        buckets.setdefault((d.category, d.note.get("en", d.id)), []).append(d)

    out = {}
    for n, (_, group) in enumerate(sorted(buckets.items(), key=lambda kv: kv[0][1])):
        if len(group) < 2:
            continue
        # Only group where the names really are "<family> <variant>": a couple
        # of hand-written drills share a note by coincidence, and forcing them
        # under a made-up heading would be worse than leaving them apart.
        # sorted: a set's iteration order changes with the hash seed, and an
        # unordered dict here made the generated JSON differ byte-for-byte
        # between two runs of the same code.
        locales = sorted(set().union(*(set(d.name) for d in group)))
        family_name = {}
        for loc in locales:
            names = [d.name.get(loc, d.name["en"]) for d in group]
            prefix = _common_prefix(names)
            if prefix:
                family_name[loc] = prefix
        if "en" not in family_name or len(family_name["en"]) < 3:
            continue
        fid = f"{sport}_family_{n}"
        for d in group:
            out[d.id] = (fid, family_name)
    return out


LEVELS = ("foundation", "development", "advanced")

# Advanced is a judgment about technique or tactical literacy, not geometry —
# a banana flick needs two players and years of table time, while a 6-4-3 is
# nine bodies doing something every little-league team drills. So advanced is
# never derived; it is named here, drill by drill, where a coach would name it.
# The other end of the scale. derive_level calls a drill foundation when it
# is a warm-up or needs three people and no opposition, which misses the
# technical work that happens with a server and a keeper — a coach reading
# "Development" on first-time finishing does not believe the filter.
FOUNDATION = {
    # rugby: the technique boards
    "rg_handling_threes", "rg_kick_at_goal", "rg_move_switch",
    # basketball: the technique boards, and the shell every team teaches
    "bb_catch_and_shoot", "bb_layup_lines", "bb_closeout", "bb_box_out",
    "bb_shot_the_corner", "bb_shot_top",
    # baseball: the technique boards a session starts with
    "bb_run_tag_up", "bb_pick_first", "bb_warm_long_toss",
    # volleyball: technique and the receive patterns a beginner starts on
    "vb_receive_r1", "vb_set_front", "vb_serve_float_deep", "vb_block_solo",
    # water polo: technique and the two-player boards
    "wp_centre_entry", "wp_counter_2v1", "wp_gk_two_metre",
    "wp_set_penalty",
    # field hockey: technique and the two-player boards
    "fh_shot_deflection", "fh_shot_rebound", "fh_gk_one_v_one",
    "fh_entry_baseline",
    # handball: technique and the two-player shots
    "hb_shot_wing_angle", "hb_shot_pivot_turn", "hb_gk_seven_metre",
    "hb_set_seven_metre", "hb_break_first_wave",
    # soccer: technique with a server, and the rondo every squad starts on
    "rondo_4v2", "wall_pass_wide", "one_v_one_gk", "defend_1v1_channel",
    "finish_first_time", "finish_turn_shoot", "finish_volley_side",
    "finish_penalty_routine", "header_attacking", "header_defensive",
    "counter_2v1", "duel_wide_left", "duel_wide_right", "duel_central",
    "duel_half_left", "gk_handling", "gk_angles", "gk_set_position",
    "gk_distribution", "gk_one_v_one",
}

ADVANCED = {
    # soccer: pressing by formation, block heights, and the rest of the work
    # that needs a squad organised rather than a skill practised
    "press_442", "press_433", "press_4231", "press_352",
    "shape_high", "shape_mid", "shape_low",
    "build_from_gk", "buildup_v3", "defend_counter_press",
    "defend_shape_shift", "possession_3_zone",
    "possession_overload_4v2_plus", "attack_double_pivot_switch",
    "rondo_8v4", "ssg_6v6_transition", "transition_6v6", "switch_final",
    "setpiece_defend_corner", "corner_decoy_stack", "corner_second_ball",
    "fk_runner", "gk_sweeper",
    # rugby: the structures and the set pieces that need a pack
    "rg_phase_one_three_three_one", "rg_phase_two_four_two",
    "rg_set_scrum", "rg_defence_blitz", "rg_game_8v8",
    # basketball: the five-man structures
    "bb_shell_4v4", "bb_zone_zone_offence", "bb_transition_5v4",
    "bb_inbounds_sideline", "bb_offball_stagger",
    # baseball: the plays that need nine people agreeing beforehand
    "bb_dp_four_six_three", "bb_defence_first_and_third", "bb_pick_rundown",
    "bb_relay_gap_ball", "bb_score_squeeze",
    # volleyball: the systems and tempos that need a full six organised
    "vb_defense_rotation", "vb_attack_pipe", "vb_block_triple",
    "vb_game_6v6", "vb_setter_z5",
    # water polo: the systems that need six swimmers organised
    "wp_defence_front_the_centre", "wp_manup_umbrella", "wp_game_6v6",
    "wp_shot_lob",
    # field hockey: the set piece and the pressing structures
    "fh_corner_drag_flick", "fh_corner_variation_left", "fh_corner_defending_it",
    "fh_press_high", "fh_build_switching", "fh_game_7v7",
    # handball: systems and the games that need a squad organised
    "hb_defence_four_two", "hb_defence_three_two_one", "hb_attack_empty_goal",
    "hb_break_third_wave", "hb_game_6v6", "hb_set_nine_metre",
    # basketball
    "bb_press_break", "bb_defence_ice",
    # volleyball
    "vb_serve_jump",
    # badminton
    "bd_deception_hold_flick", "bd_deception_double_motion", "bd_net_spin",
    # tennis
    "tn_doubles_australian", "tn_inside_out",
    # table tennis
    "tt_short_banana", "tt_loop_counter_loop", "tt_defence_deep_chop",
    # handball
    "hb_defence_three_two_one", "hb_attack_empty_goal",
    # rugby
    # field hockey
    "fh_corner_drag_flick", "fh_shot_tomahawk",
    # water polo
    "wp_manup_umbrella", "wp_defence_five_on_six",
    # baseball
    # pickleball
    "pb_speedup_ernie", "pb_putaway_atp",
    # sepak takraw — the acrobatic spikes ARE the advanced tier
    "st_spike_roll", "st_spike_scissor", "st_spike_sunback",
    # footvolley
    "fv_finish_the_bicycle_kick", "fv_attack_the_shark_attack",
    "fv_attack_the_sombrero",
    # beach tennis
    "bt_serve_jump", "bt_smash_jump",
}


def derive_level(drill: Drill) -> str:
    """Foundation is derived — warm-ups and small unopposed work, which is
    where any session starts. Advanced is named in ADVANCED, never guessed.
    Everything else, which is most of a library, is development."""
    if drill.level:
        assert drill.level in LEVELS, f"{drill.id}: unknown level {drill.level}"
        return drill.level
    if drill.id in ADVANCED:
        return "advanced"
    if (drill.id in FOUNDATION
            or drill.category in ("warmup", "conditioning")
            or (drill.player_count <= 3 and not drill.away)):
        return "foundation"
    return "development"


# Two players are dots 44pt across (kPlayerIconSize) on a phone, and the
# 1000x1500 board is rescaled to the canvas — about 400x700pt — when it
# loads. So a gap has to be measured in points, not in board units: the old
# rule asked for 20 board units, which is 8pt, and let a four-man free-kick
# wall ship as one unreadable blob.
CANVAS_PT = (400.0, 700.0)      # the app's own default canvas
BOARD_UNITS = (1000.0, 1500.0)  # what these boards are authored in
SPACING_APART = 44.0            # one icon: no overlap at all
SPACING_TIGHT = 30.0            # shoulder to shoulder, labels still readable

# Was a list of sports whose boards predated the rule. Empty since
# 2026-09-07: space_out() applies the rule to every sport.
SPACING_UNCHECKED: set[str] = set()


def at_the_feet_of(x: float, y: float, sport: str) -> tuple[float, float]:
    """Where a carried ball sits: at the holder's feet, not on his number.

    Placed on the holder's own point, the ball icon is the same 44pt as the
    player circle and covers it completely — every board in the library drew
    a ball with nobody visibly carrying it. Offset toward the middle of the
    pitch and down, far enough to clear the digit and close enough to still
    read as his. The app keeps this offset through the animation.
    """
    left, top, w, h = court_rect(sport)
    dx = 40.0 if x < left + w / 2 else -40.0
    dy = 70.0 if y + 70.0 <= top + h - 20 else -70.0
    return x + dx, y + dy


def apart(sport: str, dx_pt: float = 0.0, dy_pt: float = 0.0) -> tuple[float, float]:
    """An offset in court-relative units worth the given distance in points.

    Relative units are not square: these courts are tall and narrow, so 0.01
    across is 2.6-3.8pt while 0.01 down is about 6pt. Every module was
    written as though they matched, which is why a defender authored 0.05
    "away" from his man stood on top of him on a phone. Ask for the distance
    you mean and let the court do the conversion.
    """
    _, _, w, h = court_rect(sport)
    sx = CANVAS_PT[0] / BOARD_UNITS[0]
    sy = CANVAS_PT[1] / BOARD_UNITS[1]
    return (dx_pt / (w * sx), dy_pt / (h * sy))


def _screen_gap(a, b) -> float:
    """Distance between two board points as the coach's phone shows it."""
    sx = CANVAS_PT[0] / BOARD_UNITS[0]
    sy = CANVAS_PT[1] / BOARD_UNITS[1]
    return math.hypot((a[0] - b[0]) * sx, (a[1] - b[1]) * sy)


_NVM = _re.compile(r"\b(\d+)v(\d+)\b")
_STUTTER = _re.compile(r"\b(\w+) \1\b", _re.IGNORECASE)


def audit(sport: str, drill: Drill, board: dict) -> None:
    """Refuse to ship a board the review pass already caught once.

    Every rule here found real defects on 2026-09-05: 13 pairs of players
    standing on the same point, 15 dead movement arrows, 72 names reading
    "Servis servis tinggi", and — the one that held everywhere — "4v2" in a
    name always matching the bodies on the board. Cheap to keep, expensive
    to relearn.
    """
    people = [p for p in board["players"]
              if p["markerShape"] == 0 and p.get("sportType") is None]

    if sport not in SPACING_UNCHECKED:
        floor = SPACING_TIGHT if drill.tight else SPACING_APART
        for i in range(len(people)):
            for j in range(i + 1, len(people)):
                d = _screen_gap(people[i]["position"], people[j]["position"])
                assert d >= floor, (
                    f"{sport}/{drill.id}: {people[i]['label']!r} and "
                    f"{people[j]['label']!r} are {d:.0f}pt apart on a phone — "
                    f"{'labels collide' if drill.tight else 'icons overlap'} "
                    f"(need {floor:.0f}pt)")

    for p in people:
        prev = p["position"]
        for mv in p["moves"]:
            step = math.hypot(mv[0] - prev[0], mv[1] - prev[1])
            assert step >= 8, (
                f"{sport}/{drill.id}/{p['label']}: {step:.0f}px move — "
                f"a dead arrow (prune_degenerate_moves should have eaten it)")
            prev = mv

    if sport == "soccer":
        for p in people:
            assert p["label"] != "1" or p.get("role") == "GK", (
                f"{sport}/{drill.id}: an outfield player wears 1 — that is "
                f"the goalkeeper's shirt (see reserve_keeper_number)")
        seen = {}
        for p in people:
            if not p["label"]:
                continue
            other = seen.get(p["label"])
            assert other is None or other == p["team"], (
                f"{sport}/{drill.id}: both sides field a {p['label']!r} — "
                f"two players in the same shirt on one board")
            seen[p["label"]] = p["team"]

    for loc, name in drill.name.items():
        assert not _STUTTER.search(name) and "  " not in name, (
            f"{sport}/{drill.id} [{loc}]: {name!r} reads as a stutter")

    if drill.off_surface:
        left, top, w, h = court_rect(sport)
        def outside(pt):
            return not (left - 12 <= pt[0] <= left + w + 12
                        and top - 12 <= pt[1] <= top + h + 12)
        exercised = any(
            outside(p["position"]) or any(outside(m) for m in p["moves"])
            for p in people)
        assert exercised, (
            f"{sport}/{drill.id}: marked off_surface but nobody leaves the "
            f"surface — the flag only exists to exempt someone who does, and "
            f"an unused one is a hole in the on-surface check")

    m = _NVM.search(drill.name["en"])
    if m:
        n1, n2 = int(m.group(1)), int(m.group(2))
        h = sum(1 for p in people if p["team"] == 0)
        a = sum(1 for p in people if p["team"] == 1)
        ok = {(h, a), (a, h)} & {(n1, n2), (n1 + 1, n2), (n1, n2 + 1),
                                 (n1 + 1, n2 + 1)}
        assert ok, (f"{sport}/{drill.id}: name says {n1}v{n2}, "
                    f"board has {h} home vs {a} away")


def build(sport: str, library) -> dict:
    """Render one sport's library to the JSON the app ships."""
    from .mistakes import lookup
    drills = library()
    ids = [d.id for d in drills]
    assert len(ids) == len(set(ids)), f"duplicate drill id in {sport}"
    families = assign_families(drills, sport)

    # Every family must carry a mistake — the note's other half. A new family
    # with none is a blank line on the card, so the build refuses it.
    from .mistakes import lookup
    missing = sorted({
        (families[d.id][1].get("en", "") if d.id in families else d.name["en"],
         d.category)
        for d in drills
        if lookup(sport,
                  families[d.id][1].get("en", "") if d.id in families
                  else d.name["en"], d.category) is None
    })
    assert not missing, (
        f"{sport}: no common-mistake for: {missing}\n"
        f"    add a family entry, or a category floor via cat() in mistakes.py")

    return {
        "sport": sport,
        "version": 1,
        "drills": [
            {
                "id": d.id,
                "level": derive_level(d),
                # Set when this drill is one variant of a generated family, so
                # the library can show the family once instead of repeating
                # its coaching point on every variant.
                "family": families.get(d.id, (None, None))[0],
                "familyName": families.get(d.id, (None, None))[1],
                "category": d.category,
                "minutes": d.minutes,
                "players": d.player_count,
                "free": d.free,
                "offSurface": d.off_surface,
                "name": d.name,
                "note": d.note,
                # The family's most common error — the other half of the
                # coaching point, shown once per card like the note.
                "mistake": lookup(
                    sport,
                    families[d.id][1].get("en", "") if d.id in families
                    else d.name["en"],
                    d.category),
                "board": (lambda b, dd=d: (audit(sport, dd, b), b)[1])(
                    build_board(d, sport)),
            }
            for d in drills
        ],
    }
