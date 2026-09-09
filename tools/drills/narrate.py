"""The sequence section of a drill's note, derived from the board itself.

The notes were one hand-written coaching sentence, and the user's finding was
that they were too thin to run a session from — and, worse, nothing tied them
to the board: a note could describe a drill the phases no longer performed.
So the note becomes three parts:

    【组织】 setup   — hand-written when the author gives one, else a census
                      of what is on the board (players, equipment, the ball)
    【流程】 sequence — DERIVED from the same phase data that animates the
                      board, beat by beat, so text and animation cannot
                      disagree; edit the board and the words follow
    【要点】 point    — the hand-written coaching sentence, kept verbatim

Verbs the narration knows, best first:
  - a pass: a ball_to leg whose target is a player reference
  - a ball played to a spot: a ball_to leg with a point target
  - a carry: ball_follow (narrated once, with the carrier)
  - a follow: a run that ends near where the ball stopped the beat before —
    pass-and-follow detected from geometry, not annotation
  - a run: any other movement, named by its dominant direction

Twelve locales, the same set the drills ship. Adding a verb means adding
twelve strings here — the price of text that is never machine-translated.
"""
from __future__ import annotations

LOCALES = ["en", "en-GB", "zh-CN", "zh-TW", "ja-JP", "ko-KR", "es-ES",
           "fr-FR", "id-ID", "ms-MY", "th-TH", "vi-VN"]

# ── section labels ──────────────────────────────────────────────────────────
SECTION = {
    "setup": {
        "en": "Setup: ", "en-GB": "Setup: ",
        "zh-CN": "【组织】", "zh-TW": "【組織】",
        "ja-JP": "【準備】", "ko-KR": "【준비】",
        "es-ES": "Montaje: ", "fr-FR": "Mise en place : ",
        "id-ID": "Persiapan: ", "ms-MY": "Persediaan: ",
        "th-TH": "การจัด: ", "vi-VN": "Bố trí: ",
    },
    "seq": {
        "en": "Sequence: ", "en-GB": "Sequence: ",
        "zh-CN": "【流程】", "zh-TW": "【流程】",
        "ja-JP": "【流れ】", "ko-KR": "【진행】",
        "es-ES": "Secuencia: ", "fr-FR": "Déroulé : ",
        "id-ID": "Urutan: ", "ms-MY": "Urutan: ",
        "th-TH": "ลำดับ: ", "vi-VN": "Trình tự: ",
    },
    "point": {
        "en": "Coaching point: ", "en-GB": "Coaching point: ",
        "zh-CN": "【要点】", "zh-TW": "【要點】",
        "ja-JP": "【ポイント】", "ko-KR": "【포인트】",
        "es-ES": "Punto clave: ", "fr-FR": "Point clé : ",
        "id-ID": "Poin utama: ", "ms-MY": "Poin utama: ",
        "th-TH": "จุดเน้น: ", "vi-VN": "Điểm chính: ",
    },
}

# ── beats ───────────────────────────────────────────────────────────────────
BEAT = {
    "en": "Beat {n}: ", "en-GB": "Beat {n}: ",
    "zh-CN": "第{n}拍：", "zh-TW": "第{n}拍：",
    "ja-JP": "{n}拍目：", "ko-KR": "{n}박: ",
    "es-ES": "Tiempo {n}: ", "fr-FR": "Temps {n} : ",
    "id-ID": "Ketukan {n}: ", "ms-MY": "Rentak {n}: ",
    "th-TH": "จังหวะ {n}: ", "vi-VN": "Nhịp {n}: ",
}

# separators: inside a beat / between beats / end of section
AND = {
    "en": ", ", "en-GB": ", ", "zh-CN": "，", "zh-TW": "，",
    "ja-JP": "、", "ko-KR": ", ", "es-ES": ", ", "fr-FR": ", ",
    "id-ID": ", ", "ms-MY": ", ", "th-TH": " ", "vi-VN": ", ",
}
SEMI = {
    "en": "; ", "en-GB": "; ", "zh-CN": "；", "zh-TW": "；",
    "ja-JP": "。", "ko-KR": "; ", "es-ES": "; ", "fr-FR": " ; ",
    "id-ID": "; ", "ms-MY": "; ", "th-TH": " • ", "vi-VN": "; ",
}
DOT = {
    "en": ". ", "en-GB": ". ", "zh-CN": "。", "zh-TW": "。",
    "ja-JP": "。", "ko-KR": ". ", "es-ES": ". ", "fr-FR": ". ",
    "id-ID": ". ", "ms-MY": ". ", "th-TH": " ", "vi-VN": ". ",
}

# ── verbs ───────────────────────────────────────────────────────────────────
# {a}/{b} are shirt labels. The ball word varies per sport family (a puck-less
# library: everything here is a ball, a shuttle, or a stone-cold "ball").
PASS = {
    "en": "{a} passes to {b}", "en-GB": "{a} passes to {b}",
    "zh-CN": "{a} 传 {b}", "zh-TW": "{a} 傳 {b}",
    "ja-JP": "{a}が{b}へパス", "ko-KR": "{a}가 {b}에게 패스",
    "es-ES": "{a} pasa a {b}", "fr-FR": "{a} passe à {b}",
    "id-ID": "{a} mengoper ke {b}", "ms-MY": "{a} menghantar kepada {b}",
    "th-TH": "{a} จ่ายให้ {b}", "vi-VN": "{a} chuyền cho {b}",
}
# Net sports: the ball crosses to the other side, "hit" reads better than
# "pass" for a shuttle or a spiked ball.
HIT = {
    "en": "{a} plays it to {b}", "en-GB": "{a} plays it to {b}",
    "zh-CN": "{a} 打向 {b}", "zh-TW": "{a} 打向 {b}",
    "ja-JP": "{a}が{b}へ打つ", "ko-KR": "{a}가 {b} 쪽으로 친다",
    "es-ES": "{a} la juega hacia {b}", "fr-FR": "{a} joue vers {b}",
    "id-ID": "{a} memukul ke {b}", "ms-MY": "{a} memukul ke arah {b}",
    "th-TH": "{a} ตีไปที่ {b}", "vi-VN": "{a} đánh sang {b}",
}
THROW = {
    "en": "{a} throws to {b}", "en-GB": "{a} throws to {b}",
    "zh-CN": "{a} 传给 {b}", "zh-TW": "{a} 傳給 {b}",
    "ja-JP": "{a}が{b}へ送球", "ko-KR": "{a}가 {b}에게 송구",
    "es-ES": "{a} lanza a {b}", "fr-FR": "{a} lance à {b}",
    "id-ID": "{a} melempar ke {b}", "ms-MY": "{a} membaling kepada {b}",
    "th-TH": "{a} ขว้างให้ {b}", "vi-VN": "{a} ném cho {b}",
}
PASS_SPOT = {
    "en": "{a} plays the ball on", "en-GB": "{a} plays the ball on",
    "zh-CN": "{a} 把球传到下一个点", "zh-TW": "{a} 把球傳到下一個點",
    "ja-JP": "{a}が次のポイントへ送る", "ko-KR": "{a}가 다음 지점으로 보낸다",
    "es-ES": "{a} envía el balón al siguiente punto",
    "fr-FR": "{a} envoie le ballon au point suivant",
    "id-ID": "{a} memainkan bola ke titik berikutnya",
    "ms-MY": "{a} memainkan bola ke titik seterusnya",
    "th-TH": "{a} ส่งบอลไปจุดถัดไป", "vi-VN": "{a} đưa bóng tới điểm kế tiếp",
}
CARRY = {
    "en": "{a} carries the ball on the move",
    "en-GB": "{a} carries the ball on the move",
    "zh-CN": "{a} 带球移动", "zh-TW": "{a} 帶球移動",
    "ja-JP": "{a}がボールを運ぶ", "ko-KR": "{a}가 공을 몰고 이동",
    "es-ES": "{a} conduce el balón", "fr-FR": "{a} conduit le ballon",
    "id-ID": "{a} menggiring bola", "ms-MY": "{a} membawa bola",
    "th-TH": "{a} พาบอลไป", "vi-VN": "{a} dẫn bóng di chuyển",
}
# A ball that starts loose (a served ball, an opponent's pass into the
# board): there is no holder to name, so the ball itself is the subject.
PASS_IN = {
    "en": "the ball is played to {b}", "en-GB": "the ball is played to {b}",
    "zh-CN": "球传到 {b}", "zh-TW": "球傳到 {b}",
    "ja-JP": "ボールが{b}へ入る", "ko-KR": "공이 {b}에게 온다",
    "es-ES": "el balón llega a {b}", "fr-FR": "le ballon arrive sur {b}",
    "id-ID": "bola dimainkan ke {b}", "ms-MY": "bola dimainkan kepada {b}",
    "th-TH": "บอลถูกส่งมาที่ {b}", "vi-VN": "bóng được đưa tới {b}",
}
SHOOT = {
    "en": "{a} shoots", "en-GB": "{a} shoots",
    "zh-CN": "{a} 射门", "zh-TW": "{a} 射門",
    "ja-JP": "{a}がシュート", "ko-KR": "{a} 슛",
    "es-ES": "{a} remata", "fr-FR": "{a} frappe",
    "id-ID": "{a} menembak", "ms-MY": "{a} menjaring",
    "th-TH": "{a} ยิงประตู", "vi-VN": "{a} dứt điểm",
}
# The whole side moving the same way is one idea, not ten subjects.
ALL_MOVE = {
    "en": "the whole team moves {dir}", "en-GB": "the whole team moves {dir}",
    "zh-CN": "全队{dir}压上", "zh-TW": "全隊{dir}壓上",
    "ja-JP": "チーム全体が{dir}へスライド", "ko-KR": "팀 전체가 {dir} 이동",
    "es-ES": "todo el equipo bascula {dir}", "fr-FR": "tout le bloc coulisse {dir}",
    "id-ID": "seluruh tim bergerak {dir}", "ms-MY": "seluruh pasukan bergerak {dir}",
    "th-TH": "ทั้งทีมขยับ{dir}", "vi-VN": "cả đội di chuyển {dir}",
}

FOLLOW = {
    "en": "{a} follows the pass", "en-GB": "{a} follows the pass",
    "zh-CN": "{a} 跟进", "zh-TW": "{a} 跟進",
    "ja-JP": "{a}がパスを追って移動", "ko-KR": "{a}는 패스를 따라간다",
    "es-ES": "{a} sigue su pase", "fr-FR": "{a} suit sa passe",
    "id-ID": "{a} mengikuti operannya", "ms-MY": "{a} mengikut hantarannya",
    "th-TH": "{a} วิ่งตามบอล", "vi-VN": "{a} chạy theo đường chuyền",
}
RUN = {
    "en": "{a} moves {dir}", "en-GB": "{a} moves {dir}",
    "zh-CN": "{a} {dir}移动", "zh-TW": "{a} {dir}移動",
    "ja-JP": "{a}が{dir}へ移動", "ko-KR": "{a}는 {dir} 이동",
    "es-ES": "{a} se desplaza {dir}", "fr-FR": "{a} se déplace {dir}",
    "id-ID": "{a} bergerak {dir}", "ms-MY": "{a} bergerak {dir}",
    "th-TH": "{a} ขยับ{dir}", "vi-VN": "{a} di chuyển {dir}",
}
# Directions in board space: -y is toward the top of the phone. Whether that
# is "forward" depends on which half the player is in, which is more theory
# than a warm-up needs — up/down/left/right in pitch terms is unambiguous.
DIR = {
    "up": {"en": "up the board", "en-GB": "up the board", "zh-CN": "向前",
           "zh-TW": "向前", "ja-JP": "前方", "ko-KR": "앞으로",
           "es-ES": "hacia delante", "fr-FR": "vers l'avant",
           "id-ID": "ke depan", "ms-MY": "ke hadapan", "th-TH": "ไปข้างหน้า",
           "vi-VN": "lên phía trước"},
    "down": {"en": "back", "en-GB": "back", "zh-CN": "回撤", "zh-TW": "回撤",
             "ja-JP": "後方", "ko-KR": "뒤로", "es-ES": "hacia atrás",
             "fr-FR": "vers l'arrière", "id-ID": "ke belakang",
             "ms-MY": "ke belakang", "th-TH": "ถอยหลัง", "vi-VN": "lùi lại"},
    "left": {"en": "left", "en-GB": "left", "zh-CN": "向左", "zh-TW": "向左",
             "ja-JP": "左", "ko-KR": "왼쪽으로", "es-ES": "a la izquierda",
             "fr-FR": "à gauche", "id-ID": "ke kiri", "ms-MY": "ke kiri",
             "th-TH": "ไปทางซ้าย", "vi-VN": "sang trái"},
    "right": {"en": "right", "en-GB": "right", "zh-CN": "向右", "zh-TW": "向右",
              "ja-JP": "右", "ko-KR": "오른쪽으로", "es-ES": "a la derecha",
              "fr-FR": "à droite", "id-ID": "ke kanan", "ms-MY": "ke kanan",
              "th-TH": "ไปทางขวา", "vi-VN": "sang phải"},
}

# ── setup census ────────────────────────────────────────────────────────────
SETUP_PLAYERS = {
    "en": "{n} players", "en-GB": "{n} players", "zh-CN": "{n} 人",
    "zh-TW": "{n} 人", "ja-JP": "{n}人", "ko-KR": "{n}명",
    "es-ES": "{n} jugadores", "fr-FR": "{n} joueurs", "id-ID": "{n} pemain",
    "ms-MY": "{n} pemain", "th-TH": "ผู้เล่น {n} คน", "vi-VN": "{n} cầu thủ",
}
SETUP_VS = {
    "en": "{h} v {a}", "en-GB": "{h} v {a}", "zh-CN": "{h} 对 {a}",
    "zh-TW": "{h} 對 {a}", "ja-JP": "{h}対{a}", "ko-KR": "{h}대{a}",
    "es-ES": "{h} contra {a}", "fr-FR": "{h} contre {a}",
    "id-ID": "{h} lawan {a}", "ms-MY": "{h} lawan {a}",
    "th-TH": "{h} ต่อ {a}", "vi-VN": "{h} đấu {a}",
}
SETUP_CONES = {
    "en": "{n} cones", "en-GB": "{n} cones", "zh-CN": "{n} 个锥标",
    "zh-TW": "{n} 個錐標", "ja-JP": "コーン{n}個", "ko-KR": "콘 {n}개",
    "es-ES": "{n} conos", "fr-FR": "{n} plots", "id-ID": "{n} kerucut",
    "ms-MY": "{n} kon", "th-TH": "กรวย {n} อัน", "vi-VN": "{n} cọc",
}
SETUP_BALL_AT = {
    "en": "ball with {a}", "en-GB": "ball with {a}", "zh-CN": "球在 {a} 脚下",
    "zh-TW": "球在 {a} 腳下", "ja-JP": "ボールは{a}", "ko-KR": "공은 {a}",
    "es-ES": "balón con {a}", "fr-FR": "ballon avec {a}",
    "id-ID": "bola pada {a}", "ms-MY": "bola dengan {a}",
    "th-TH": "บอลอยู่ที่ {a}", "vi-VN": "bóng ở chỗ {a}",
}

# Sports where a ball_to leg reads as a throw / a hit rather than a kick-pass.
THROW_SPORTS = {"baseball", "handball", "waterPolo", "rugby", "basketball"}
HIT_SPORTS = {"volleyball", "tennis", "badminton", "tableTennis",
              "pickleball", "sepakTakraw", "beachTennis", "footvolley"}

# A run ending this close to where the ball stopped last beat is following
# the pass. Wide enough to cover the queue-behind offset (runs end 80 short
# of the cone) plus the ball's at-feet offset; the next cone is 400+ away.
FOLLOW_NEAR = 240.0


def _label(p) -> str:
    return p.label or "?"


def _pass_verb(sport: str) -> dict:
    if sport in THROW_SPORTS:
        return THROW
    if sport in HIT_SPORTS:
        return HIT
    return PASS


def sequence_texts(drill, sport: str) -> dict | None:
    """The 流程 section, one string per locale, from the resolved drill.

    Call after build_board has run resolve_ball and normalise_phases — the
    beats narrated here are exactly the beats the stepper walks.
    """
    # (verb_table_or_None, params) per beat, balls first within a beat.
    beats: dict[int, list] = {}

    def add(ph, table, **params):
        beats.setdefault(ph, []).append((table, params))

    people = drill.home + drill.away
    if drill.ball_follow is not None:
        carrier = drill.home[drill.ball_follow]
        for (_, _, ph) in carrier.moves[:1]:
            add(ph, CARRY, a=_label(carrier))
    if drill.ball_to:
        holder = (drill.home[drill.ball]
                  if isinstance(drill.ball, int) else None)
        prev = holder
        for (target, ph) in drill.ball_to:
            if isinstance(target, tuple):
                # A point in the last twelfth of the pitch is the goal — that
                # leg is a shot, not "the ball played on".
                from .engine import court_rect
                _, top, _, ch = court_rect(sport)
                shooty = (target[1] < top + ch * 0.085
                          or target[1] > top + ch * 0.915)
                add(ph, SHOOT if shooty else PASS_SPOT,
                    a=_label(prev) if prev else "?")
                prev = None
            else:
                t = (drill.away[int(target[1:])] if isinstance(target, str)
                     else drill.home[target])
                if prev is None:
                    add(ph, PASS_IN, b=_label(t))
                elif t is prev:
                    # A leg whose target is the holder himself is a carry —
                    # the ball rides that player's run for this beat. The
                    # board draws it the same way (the escorted rule), and
                    # "2 passes to 2" is not a sentence.
                    add(ph, CARRY, a=_label(t))
                else:
                    add(ph, _pass_verb(sport), a=_label(prev), b=_label(t))
                prev = t

    # Where the ball stops per phase, for follow detection.
    stops = {ph: (x, y) for (x, y, ph) in drill.ball_moves}
    for p in people:
        for i, (x, y, ph) in enumerate(p.moves):
            if i > 0:
                continue  # narrate a player's first leg; chains stay terse
            prev_stop = stops.get(ph - 1)
            if prev_stop and (abs(x - prev_stop[0]) + abs(y - prev_stop[1])
                              < FOLLOW_NEAR):
                add(ph, FOLLOW, a=_label(p))
                continue
            dx, dy = x - p.x, y - p.y
            d = ("right" if dx > 0 else "left") if abs(dx) > abs(dy) else \
                ("down" if dy > 0 else "up")
            add(ph, RUN, a=_label(p), dir_key=d)

    if not beats:
        return None
    out = {}
    LIST = {"zh-CN": "、", "zh-TW": "、", "ja-JP": "・"}
    for loc in LOCALES:
        parts = []
        for ph in sorted(beats):
            acts = []
            # Identical actions share one clause: a five-man push read as
            # "1 moves up, 2 moves up, 3 moves up, 4 moves up, 5 moves up" —
            # five copies of the same sentence. Grouped, it is one clause
            # with five subjects.
            grouped: dict[tuple, list] = {}
            for table, params in beats[ph]:
                if "b" in params:
                    acts.append((table, params))
                elif "dir_key" in params or len(params) == 1:
                    grouped.setdefault(
                        (id(table), params.get("dir_key")), []
                    ).append(params["a"])
                else:
                    acts.append((table, params))
            rendered = []
            for table, params in acts:
                rendered.append(table[loc].format(**params))
            for (tid, dir_key), subjects in grouped.items():
                table = next(t for t in (RUN, FOLLOW, CARRY, PASS_SPOT, SHOOT, PASS_IN)
                             if id(t) == tid)
                joined = LIST.get(loc, ", ").join(subjects)
                if dir_key:
                    if len(subjects) >= 6 and \
                            len(subjects) == len(drill.home):
                        rendered.append(ALL_MOVE[loc].format(
                            dir=DIR[dir_key][loc]))
                        continue
                    rendered.append(RUN[loc].format(
                        a=joined, dir=DIR[dir_key][loc]))
                else:
                    rendered.append(table[loc].format(a=joined))
            parts.append(BEAT[loc].format(n=ph + 1) + AND[loc].join(rendered))
        out[loc] = SEMI[loc].join(parts) + DOT[loc].strip() \
            if loc in ("zh-CN", "zh-TW", "ja-JP", "th-TH") \
            else SEMI[loc].join(parts) + "."
    return out


def setup_texts(drill, sport: str) -> dict:
    """The 组织 census — overridden by a hand-written drill.setup when given."""
    hand = getattr(drill, "setup", None)
    if hand:
        return {loc: hand.get(loc, hand["en"]) for loc in LOCALES}
    out = {}
    for loc in LOCALES:
        bits = []
        if drill.away:
            bits.append(SETUP_VS[loc].format(h=len(drill.home),
                                             a=len(drill.away)))
        else:
            bits.append(SETUP_PLAYERS[loc].format(n=len(drill.home)))
        cones = sum(1 for m in drill.markers if m.shape == "cone")
        if cones:
            bits.append(SETUP_CONES[loc].format(n=cones))
        if isinstance(drill.ball, int):
            bits.append(SETUP_BALL_AT[loc].format(
                a=_label(drill.home[drill.ball])))
        out[loc] = AND[loc].join(bits)
    return out


def compose_note(drill, sport: str) -> None:
    """Rebuild drill.note as 组织+流程+要点, keeping the hand-written point.

    Mutates the note in place; the point is whatever the author wrote as the
    note. Runs once per drill at the end of build_board, after phases are
    final. A drill with no movement keeps its plain note untouched.
    """
    seq = sequence_texts(drill, sport)
    if seq is None:
        return
    setup = setup_texts(drill, sport)
    new = {}
    cjk = ("zh-CN", "zh-TW", "ja-JP")
    for loc in LOCALES:
        point = drill.note.get(loc) or drill.note["en"]
        gap = "" if loc in cjk else " "
        new[loc] = (SECTION["setup"][loc] + setup[loc] + DOT[loc].rstrip()
                    + gap + SECTION["seq"][loc] + seq[loc]
                    + gap + SECTION["point"][loc] + point)
    drill.note = new
