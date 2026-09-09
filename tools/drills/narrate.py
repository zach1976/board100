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
    "route": {
        "en": "Ball path: ", "en-GB": "Ball path: ",
        "zh-CN": "【球路】", "zh-TW": "【球路】",
        "ja-JP": "【ボールの道筋】", "ko-KR": "【볼 경로】",
        "es-ES": "Recorrido del balón: ", "fr-FR": "Trajet du ballon : ",
        "id-ID": "Jalur bola: ", "ms-MY": "Laluan bola: ",
        "th-TH": "เส้นทางบอล: ", "vi-VN": "Đường bóng: ",
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
# Named the way the playback indicator counts ("0/4", stepped in 步), so a
# coach can hold the note against the stepper and follow beat for beat.
BEAT = {
    "en": "Step {n}: ", "en-GB": "Step {n}: ",
    "zh-CN": "第{n}步：", "zh-TW": "第{n}步：",
    "ja-JP": "ステップ{n}：", "ko-KR": "{n}단계: ",
    "es-ES": "Paso {n}: ", "fr-FR": "Étape {n} : ",
    "id-ID": "Langkah {n}: ", "ms-MY": "Langkah {n}: ",
    "th-TH": "ขั้นที่ {n}: ", "vi-VN": "Bước {n}: ",
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
    "zh-CN": "{a}把球传给{b}", "zh-TW": "{a}把球傳給{b}",
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
    "zh-CN": "{a}把球传到下一个点", "zh-TW": "{a}把球傳到下一個點",
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
    "zh-CN": "{a}带球推进", "zh-TW": "{a}帶球推進",
    "ja-JP": "{a}がボールを運ぶ", "ko-KR": "{a}가 공을 몰고 이동",
    "es-ES": "{a} conduce el balón", "fr-FR": "{a} conduit le ballon",
    "id-ID": "{a} menggiring bola", "ms-MY": "{a} membawa bola",
    "th-TH": "{a} พาบอลไป", "vi-VN": "{a} dẫn bóng di chuyển",
}
# A ball that starts loose (a served ball, an opponent's pass into the
# board): there is no holder to name, so the ball itself is the subject.
PASS_IN = {
    "en": "the ball is played to {b}", "en-GB": "the ball is played to {b}",
    "zh-CN": "球被传给{b}", "zh-TW": "球被傳給{b}",
    "ja-JP": "ボールが{b}へ入る", "ko-KR": "공이 {b}에게 온다",
    "es-ES": "el balón llega a {b}", "fr-FR": "le ballon arrive sur {b}",
    "id-ID": "bola dimainkan ke {b}", "ms-MY": "bola dimainkan kepada {b}",
    "th-TH": "บอลถูกส่งมาที่ {b}", "vi-VN": "bóng được đưa tới {b}",
}
GOAL_WORD = {
    "en": "goal", "en-GB": "goal", "zh-CN": "球门", "zh-TW": "球門",
    "ja-JP": "ゴール", "ko-KR": "골문", "es-ES": "portería", "fr-FR": "but",
    "id-ID": "gawang", "ms-MY": "gol", "th-TH": "ประตู", "vi-VN": "khung thành",
}
BACK_TO_START = {
    "en": "back to the start", "en-GB": "back to the start",
    "zh-CN": "回到起点", "zh-TW": "回到起點",
    "ja-JP": "スタート位置へ戻る", "ko-KR": "시작 지점으로",
    "es-ES": "de vuelta al inicio", "fr-FR": "retour au départ",
    "id-ID": "kembali ke awal", "ms-MY": "kembali ke permulaan",
    "th-TH": "กลับจุดเริ่ม", "vi-VN": "về điểm xuất phát",
}
SPOT_WORD = {
    "en": "the open spot", "en-GB": "the open spot", "zh-CN": "空位",
    "zh-TW": "空位", "ja-JP": "スペース", "ko-KR": "빈 자리",
    "es-ES": "el espacio libre", "fr-FR": "l'espace libre",
    "id-ID": "titik kosong", "ms-MY": "ruang kosong",
    "th-TH": "จุดว่าง", "vi-VN": "vị trí trống",
}
SHOOT = {
    "en": "{a} shoots", "en-GB": "{a} shoots",
    "zh-CN": "{a}起脚射门", "zh-TW": "{a}起腳射門",
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

# With a known destination (the spot the receiver vacates) the follow reads
# "2号球员跑位到3号球员的位置". Without one it falls back to FOLLOW_PLAIN.
FOLLOW = {
    "en": "{a} follows the pass into {to}'s spot",
    "en-GB": "{a} follows the pass into {to}'s spot",
    "zh-CN": "{a}跟着传球跑位到{to}的位置",
    "zh-TW": "{a}跟著傳球跑位到{to}的位置",
    "ja-JP": "{a}がパスを追って{to}の位置へ",
    "ko-KR": "{a}가 패스를 따라 {to}의 자리로",
    "es-ES": "{a} sigue su pase hasta el sitio de {to}",
    "fr-FR": "{a} suit sa passe jusqu'à la place de {to}",
    "id-ID": "{a} mengikuti operan ke posisi {to}",
    "ms-MY": "{a} mengikut hantaran ke kedudukan {to}",
    "th-TH": "{a} วิ่งตามบอลไปยังตำแหน่งของ{to}",
    "vi-VN": "{a} theo đường chuyền tới vị trí của {to}",
}
FOLLOW_PLAIN = {
    "en": "{a} follows the pass", "en-GB": "{a} follows the pass",
    "zh-CN": "{a}跟着传球跑上去", "zh-TW": "{a}跟著傳球跑上去",
    "ja-JP": "{a}がパスを追って移動", "ko-KR": "{a}는 패스를 따라간다",
    "es-ES": "{a} sigue su pase", "fr-FR": "{a} suit sa passe",
    "id-ID": "{a} mengikuti operannya", "ms-MY": "{a} mengikut hantarannya",
    "th-TH": "{a} วิ่งตามบอล", "vi-VN": "{a} chạy theo đường chuyền",
}
RUN = {
    "en": "{a} moves {dir}", "en-GB": "{a} moves {dir}",
    "zh-CN": "{a}{dir}移动", "zh-TW": "{a}{dir}移動",
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


# How a shirt label reads as a sentence subject, per locale. "3" alone is a
# telegram; Chinese wants "3号球员". Letters (away A/B, GK, P) and non-CJK
# locales keep the bare label — "A号球员" is not a word.
_SUBJ = {
    "zh-CN": "{n}号球员", "zh-TW": "{n}號球員",
    "ja-JP": "{n}番", "ko-KR": "{n}번",
}


def _subj(label, loc):
    label = str(label)
    tmpl = _SUBJ.get(loc)
    if tmpl and label.isdigit():
        return tmpl.format(n=label)
    return label


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

    # The player who played the ball on each beat — a follow is that player
    # chasing his own pass, nobody else drifting near the ball.
    passer_on = {}
    if drill.ball_to:
        holder2 = (drill.home[drill.ball]
                   if isinstance(drill.ball, int) else None)
        prev2 = holder2
        for (target, ph) in drill.ball_to:
            if prev2 is not None:
                passer_on[ph] = prev2
            if isinstance(target, tuple):
                prev2 = None
            else:
                prev2 = (drill.away[int(target[1:])]
                         if isinstance(target, str) else drill.home[target])

    # Where the ball stops per phase, for follow detection.
    stops = {ph: (x, y) for (x, y, ph) in drill.ball_moves}
    for p in people:
        for i, (x, y, ph) in enumerate(p.moves):
            if i > 0:
                continue  # narrate a player's first leg; chains stay terse
            prev_stop = stops.get(ph - 1)
            is_follow = (prev_stop is not None
                         and passer_on.get(ph - 1) is p
                         and abs(x - prev_stop[0]) + abs(y - prev_stop[1])
                         < FOLLOW_NEAR)
            if is_follow:
                # Name the spot: whichever OTHER player started nearest where
                # the ball stopped last beat is the receiver whose position
                # the follower is running into.
                dest = None
                best = 1e9
                for q in people:
                    if q is p:
                        continue
                    dq = abs(q.x - prev_stop[0]) + abs(q.y - prev_stop[1])
                    if dq < best:
                        best, dest = dq, q
                if dest is not None and best < FOLLOW_NEAR:
                    add(ph, FOLLOW, a=_label(p), to=_label(dest))
                else:
                    add(ph, FOLLOW_PLAIN, a=_label(p))
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
                if "b" in params or "to" in params:
                    acts.append((table, params))
                elif "dir_key" in params or len(params) == 1:
                    grouped.setdefault(
                        (id(table), params.get("dir_key")), []
                    ).append(params["a"])
                else:
                    acts.append((table, params))
            rendered = []
            for table, params in acts:
                fmt = {k: (_subj(v, loc) if k in ("a", "b", "to") else v)
                       for k, v in params.items()}
                rendered.append(table[loc].format(**fmt))
            for (tid, dir_key), subjects in grouped.items():
                table = next(t for t in (RUN, FOLLOW_PLAIN, CARRY, PASS_SPOT,
                                         SHOOT, PASS_IN)
                             if id(t) == tid)
                joined = LIST.get(loc, ", ").join(
                    _subj(x, loc) for x in subjects)
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


def route_texts(drill, sport: str) -> dict | None:
    """One line: where the ball goes, start to finish — 2 → 3 → 4 → goal.

    The step-by-step below it is precise but sequential; this is the shape of
    the whole drill in a glance, and it is what makes the steps scannable.
    """
    if not drill.ball_to:
        return None
    from .engine import court_rect
    _, top, _, ch = court_rect(sport)
    stops_by_loc = {loc: [] for loc in LOCALES}
    start = (_label(drill.home[drill.ball])
             if isinstance(drill.ball, int) else None)
    for loc in LOCALES:
        stops = [start] if start else []
        for (t, ph) in drill.ball_to:
            if isinstance(t, tuple):
                shooty = (t[1] < top + ch * 0.085 or t[1] > top + ch * 0.915)
                sx, sy = ((drill.home[drill.ball].x, drill.home[drill.ball].y)
                          if isinstance(drill.ball, int) else
                          (drill.ball if isinstance(drill.ball, tuple)
                           else (None, None)))
                if shooty:
                    stops.append(GOAL_WORD[loc])
                elif sx is not None and abs(t[0]-sx) + abs(t[1]-sy) < 120:
                    stops.append(BACK_TO_START[loc])
                else:
                    stops.append(SPOT_WORD[loc])
            elif isinstance(t, str):
                stops.append(_label(drill.away[int(t[1:])]))
            else:
                stops.append(_label(drill.home[t]))
        # A carry leg repeats the holder; collapse runs of the same stop so
        # the path reads 9 → 11 → goal, not 9 → 9 → 9 → 11 → goal.
        clean = [x for i, x in enumerate(stops) if i == 0 or x != stops[i-1]]
        stops_by_loc[loc] = " → ".join(clean)
    return stops_by_loc


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
    route = route_texts(drill, sport)
    new = {}
    for loc in LOCALES:
        point = drill.note.get(loc) or drill.note["en"]
        parts = [SECTION["setup"][loc] + setup[loc] + DOT[loc].rstrip()]
        if route:
            parts.append(SECTION["route"][loc] + route[loc])
        parts.append(SECTION["seq"][loc] + seq[loc])
        parts.append(SECTION["point"][loc] + point)
        # One section per line: as a single run-on paragraph the note made
        # the reader find the section markers themselves.
        new[loc] = "\n".join(parts)
    drill.note = new
