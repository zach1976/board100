"""The water polo library.

Attacking upward, goal at the top. Every spot is written in METRES — x
across the 20 m width from the left side, y down the pool from the attacked
goal line — and converted to court fractions in one place (`_r`). The lines
that matter: 2 m (nobody without the ball ahead of it inside it), 5 m (the
penalty line), 6 m (the free-throw-shot line), halfway at 12.5 m.

Pool length: 25 m between the goal lines (World Aquatics 2025 competition
regulations), the field of play the painter, the app's court rect
(SportType.fieldRect, engine.COURT) and every saved board share. It was
drawn 30 m, the old maximum; boards saved on that pool are carried onto
this one line for line when they are opened (TacticsState, legacy pool).
Spots at the attacking end are metres from the goal line and did not move;
spots up the pool (counters, the swim-off, the outlet) are measured from
the far goal line or halfway, as they always were.

What the board can and cannot draw: a figure is ~1.5 m wide and ~3 m tall on
this court and stands on its feet, so two people need 1.5 m across or 3 m of
depth between them to be told apart. That is why defenders sit goal-side and
to the inside rather than straight under their man.
"""
from .engine import Drill, M, P, suffixed

POOL_W, POOL_L = 20.0, 25.0


def _r(x: float, y: float) -> tuple[float, float]:
    """Metres → court fractions."""
    return (x / POOL_W, y / POOL_L)


def pl(x, y, label="", moves=(), **kw) -> P:
    """A player at (x, y) metres; moves are (x, y, phase) in metres too."""
    return P(x / POOL_W, y / POOL_L, label,
             moves=[(mx / POOL_W, my / POOL_L, ph) for (mx, my, ph) in moves],
             **kw)


def keeper(x=10.0, y=1.1, moves=(), label="GK", **kw) -> P:
    return pl(x, y, label, moves, role="GK", **kw)


def mk(x, y, shape="cone") -> M:
    return M(x / POOL_W, y / POOL_L, shape, "")


# The goal is 3 m wide, posts at 8.5 and 11.5 m. A shot ends INSIDE the
# mouth, a ball's width past the goal line and 0.8 m in from a post —
# not on the keeper, who stands about a metre out and is drawn 1.5 m wide.
SHOT_L = _r(9.3, -0.35)
SHOT_R = _r(10.7, -0.35)
GOAL_MOUTH_X = (8.5, 11.5)

# The 6v6 perimeter, numbered the way a coach calls it: 1 point, 2/3 flats,
# 4/5 wings, plus the centre forward (off the keeper's line by a body width).
PT, LF, RF, LW, RW = (10.0, 7.9), (5.2, 6.4), (14.8, 6.4), (1.8, 4.1), (18.2, 4.1)
PERIMETER = [PT, LF, RF, LW, RW]
# The app draws a person CENTRED on his point, ~2.9 m of pool tall (1.9 m on
# a tight board). A centre or a post whose point was at 2.5-2.8 m had his
# cap at about 1 m: on the board he stood inside 2 m, offside, although his
# point was legal. So every drill with a set two-metre player is tight=True
# and that player's point is at TWO_M_SET, where the drawn top edge (half a
# tight figure, ~0.96 m) clears the line — still the 3 m a centre sets at.
# tools/check_water_polo.py judges the rule on the drawn figure.
TWO_M_SET = 3.1
CF_SPOT = (8.4, 3.1)
HOLE_D = (6.8, 1.7)          # the hole defender, goal-side of the centre


def _inside(x: float) -> float:
    """+1 toward the middle of the pool from x (the point counts as left)."""
    return 1.0 if x <= 10.0 else -1.0


def _goal_side(spot, across=1.5, depth=1.7):
    """A defender's spot: goal-side of his man and to the inside of him."""
    x, y = spot
    return (x + _inside(x) * across, y - depth)


# ── the Setup line ─────────────────────────────────────────────────────────
# The census counts bodies, keepers included, so a 2v1 counter read "2 v 2"
# and a 6v6 game "6 v 7". Water polo counts field players and names the
# keepers apart, which is how the drill names are written.
_SETUP = {
    "en": "{h} v {a} field players{gk}; {ball}",
    "zh-CN": "场上队员 {h} 对 {a}{gk}；{ball}",
    "zh-TW": "場上隊員 {h} 對 {a}{gk}；{ball}",
    "ja-JP": "フィールドプレーヤー{h}対{a}{gk}、{ball}",
    "ko-KR": "필드 플레이어 {h} 대 {a}{gk}, {ball}",
    "es-ES": "{h} contra {a} jugadores de campo{gk}; {ball}",
    "fr-FR": "{h} contre {a} joueurs de champ{gk} ; {ball}",
    "id-ID": "{h} lawan {a} pemain lapangan{gk}; {ball}",
    "ms-MY": "{h} lawan {a} pemain padang{gk}; {ball}",
    "th-TH": "ผู้เล่นในสนาม {h} ต่อ {a}{gk} {ball}",
    "vi-VN": "{h} đấu {a} cầu thủ trên sân{gk}; {ball}",
}
_GK = {
    1: {"en": ", plus a goalkeeper in the goal", "zh-CN": "，另有一名守门员",
        "zh-TW": "，另有一名守門員", "ja-JP": "＋ゴールキーパー1人",
        "ko-KR": "와 골키퍼 1명", "es-ES": ", más un portero",
        "fr-FR": ", plus un gardien", "id-ID": ", ditambah satu kiper",
        "ms-MY": ", serta seorang penjaga gol", "th-TH": " และผู้รักษาประตู 1 คน",
        "vi-VN": ", cùng một thủ môn"},
    2: {"en": ", plus both goalkeepers", "zh-CN": "，双方守门员各一名",
        "zh-TW": "，雙方守門員各一名", "ja-JP": "＋両チームのゴールキーパー",
        "ko-KR": "와 양 팀 골키퍼", "es-ES": ", más los dos porteros",
        "fr-FR": ", plus les deux gardiens", "id-ID": ", ditambah kedua kiper",
        "ms-MY": ", serta kedua-dua penjaga gol", "th-TH": " และผู้รักษาประตูทั้งสองฝ่าย",
        "vi-VN": ", cùng hai thủ môn"},
}
_BALL_WITH = {
    "en": "ball with {w}", "zh-CN": "球在{w}手里", "zh-TW": "球在{w}手裡",
    "ja-JP": "ボールは{w}", "ko-KR": "공은 {w}에게", "es-ES": "balón para {w}",
    "fr-FR": "ballon à {w}", "id-ID": "bola di {w}", "ms-MY": "bola pada {w}",
    "th-TH": "บอลอยู่ที่ {w}", "vi-VN": "bóng ở {w}",
}
_BALL_HALFWAY = {
    "en": "ball at halfway, both teams on their own goal lines",
    "zh-CN": "球放在中线，双方都在本方门线上",
    "zh-TW": "球放在中線，雙方都在本方門線上",
    "ja-JP": "ボールはハーフウェー、両チームは自陣ゴールライン上",
    "ko-KR": "공은 하프라인, 양 팀은 자기 골라인 위",
    "es-ES": "balón en el medio campo, cada equipo sobre su línea de gol",
    "fr-FR": "ballon à mi-bassin, chaque équipe sur sa ligne de but",
    "id-ID": "bola di garis tengah, kedua tim di garis gawang sendiri",
    "ms-MY": "bola di garisan tengah, kedua-dua pasukan di garisan gol sendiri",
    "th-TH": "บอลอยู่กึ่งกลางสระ ทั้งสองทีมอยู่บนเส้นประตูของตัวเอง",
    "vi-VN": "bóng ở giữa hồ, hai đội đứng trên vạch khung thành của mình",
}
_LOCS = ["en", "en-GB", "zh-CN", "zh-TW", "ja-JP", "ko-KR", "es-ES", "fr-FR",
         "id-ID", "ms-MY", "th-TH", "vi-VN"]


def setup_line(h: int, a: int, keepers: int, holder: str | None) -> dict:
    out = {}
    for loc in _LOCS:
        key = "en" if loc == "en-GB" else loc
        gk = _GK[keepers][key] if keepers else ""
        ball = (_BALL_WITH[key].format(w=holder) if holder is not None
                else _BALL_HALFWAY[key])
        out[loc] = _SETUP[key].format(h=h, a=a, gk=gk, ball=ball)
    return out


def _auto_setup(d: Drill) -> None:
    """Field players per side and the keepers, for every drill with two sides."""
    if not d.away or d.setup is not None:
        return
    def field(side):
        return [p for p in side if p.role != "GK"]
    keepers = sum(1 for p in d.home + d.away if p.role == "GK")
    holder = None
    if isinstance(d.ball, int):
        holder = d.home[d.ball].label or "1"
    d.setup = setup_line(len(field(d.home)), len(field(d.away)), keepers, holder)


def _P12(en, zh, zht, ja, ko, es, fr, idn, ms, th, vi):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht, "ja-JP": ja,
            "ko-KR": ko, "es-ES": es, "fr-FR": fr, "id-ID": idn, "ms-MY": ms,
            "th-TH": th, "vi-VN": vi}


WARM_NAME = {
    "en": "Warm-up", "en-GB": "Warm-up", "zh-CN": "热身", "zh-TW": "熱身",
    "ja-JP": "ウォームアップ", "ko-KR": "웜업", "es-ES": "Calentamiento",
    "fr-FR": "Échauffement", "id-ID": "Pemanasan", "ms-MY": "Memanaskan badan",
    "th-TH": "วอร์มอัพ", "vi-VN": "Khởi động",
}
WARM_NOTE = {
    "en": "Legs first. Everything in this sport is paid for by the eggbeater, "
          "and a player who sinks to catch has already lost the position.",
    "en-GB": "Legs first. Everything in this sport is paid for by the "
             "eggbeater, and a player who sinks to catch has already lost the position.",
    "zh-CN": "先练腿。这项运动的一切都是踩水换来的，接球时往下沉的人，位置已经丢了。",
    "zh-TW": "先練腿。這項運動的一切都是踩水換來的，接球時往下沉的人，位置已經丟了。",
    "ja-JP": "まず脚。この競技のすべては巻き足で支払われる。キャッチで沈む選手は、既にポジションを失っている。",
    "ko-KR": "다리부터. 이 종목의 모든 것은 에그비터로 지불된다. 잡으려다 가라앉는 선수는 이미 자리를 잃었다.",
    "es-ES": "Primero las piernas: todo en este deporte lo paga el batido, y "
             "quien se hunde al recibir ya ha perdido la posición.",
    "fr-FR": "Les jambes d'abord : tout se paie au rétropédalage, et celui qui "
             "coule en réceptionnant a déjà perdu la position.",
    "id-ID": "Kaki dulu. Semua di olahraga ini dibayar oleh eggbeater.",
    "ms-MY": "Kaki dahulu. Segalanya dalam sukan ini dibayar oleh eggbeater.",
    "th-TH": "ขาก่อน ทุกอย่างในกีฬานี้จ่ายด้วยการตีขาลอยตัว",
    "vi-VN": "Chân trước đã. Mọi thứ trong môn này đều trả bằng chân đạp nước.",
}

PERIM_NAME = {
    "en": "Perimeter", "en-GB": "Perimeter", "zh-CN": "外围转移",
    "zh-TW": "外圍轉移", "ja-JP": "外周のボール回し", "ko-KR": "외곽 볼 순환",
    "es-ES": "Perímetro", "fr-FR": "Périmètre", "id-ID": "Perimeter",
    "ms-MY": "Perimeter", "th-TH": "การหมุนบอลรอบนอก", "vi-VN": "Vòng ngoài",
}
PERIM_NOTE = {
    "en": "Pass across the front of the defender, not around them. A ball "
          "that goes behind the perimeter gives the whole defence time to reset.",
    "en-GB": "Pass across the front of the defender, not around them. A ball "
             "that goes behind the perimeter gives the whole defence time to reset.",
    "zh-CN": "从防守人身前传过去，不要绕到后面。球一旦走到外围后方，整条防线就有时间重新站好。",
    "zh-TW": "從防守人身前傳過去，不要繞到後面。球一旦走到外圍後方，整條防線就有時間重新站好。",
    "ja-JP": "守備の前を通してパスする、回り込まない。外周の後ろへ回った球は、守備全体に立て直す時間を与える。",
    "ko-KR": "수비 앞을 가로질러 패스하라, 돌아가지 말고. 뒤로 도는 공은 수비 전체에 정비 시간을 준다.",
    "es-ES": "Pasa por delante del defensor, no rodeándolo: una bola que va "
             "por detrás del perímetro le da tiempo a toda la defensa.",
    "fr-FR": "Passe devant le défenseur, pas autour : une balle qui repasse "
             "derrière le périmètre laisse toute la défense se replacer.",
    "id-ID": "Umpan melewati depan bek, bukan memutarinya.",
    "ms-MY": "Hantar melintasi hadapan pemain bertahan, bukan mengelilinginya.",
    "th-TH": "จ่ายผ่านหน้ากองหลัง ไม่ใช่อ้อมหลัง",
    "vi-VN": "Chuyền qua trước mặt hậu vệ, đừng vòng ra sau.",
}

MAN_UP_NAME = {
    "en": "Six on five", "en-GB": "Six on five", "zh-CN": "多打少",
    "zh-TW": "多打少", "ja-JP": "6対5", "ko-KR": "6대5",
    "es-ES": "Superioridad", "fr-FR": "Supériorité numérique",
    "id-ID": "Enam lawan lima", "ms-MY": "Enam lawan lima",
    "th-TH": "หกต่อห้า", "vi-VN": "Sáu đánh năm",
}
MAN_UP_NOTE = {
    "en": "Two passes, then shoot. The block moves on the second pass and "
          "recovers by the fourth — everything after that is a wasted ejection.",
    "en-GB": "Two passes, then shoot. The block moves on the second pass and "
             "recovers by the fourth — everything after that is a wasted ejection.",
    "zh-CN": "两次传球就出手。封堵会在第二次传球时移动，到第四次就已经补回来了——之后的一切都是白白浪费一次罚出。",
    "zh-TW": "兩次傳球就出手。封堵會在第二次傳球時移動，到第四次就已經補回來了——之後的一切都是白白浪費一次罰出。",
    "ja-JP": "パス2本で撃つ。ブロックは2本目で動き、4本目には戻る。それ以降は退水を無駄にしているだけ。",
    "ko-KR": "패스 두 번 뒤 슛. 블록은 두 번째 패스에 움직이고 네 번째면 복구된다.",
    "es-ES": "Dos pases y tira: el bloque se mueve al segundo y se recupera al "
             "cuarto; lo que venga después es una expulsión desperdiciada.",
    "fr-FR": "Deux passes puis tire : le bloc bouge à la deuxième et se "
             "replace à la quatrième — le reste gaspille l'exclusion.",
    "id-ID": "Dua umpan lalu tembak.",
    "ms-MY": "Dua hantaran kemudian tembak.",
    "th-TH": "จ่ายสองครั้งแล้วยิง บล็อกจะขยับที่ครั้งที่สองและกลับมาทันที่ครั้งที่สี่",
    "vi-VN": "Hai đường chuyền rồi dứt điểm.",
}

CENTRE_NAME = {
    "en": "Centre forward", "en-GB": "Centre forward", "zh-CN": "中锋",
    "zh-TW": "中鋒", "ja-JP": "センターフォワード", "ko-KR": "센터 포워드",
    "es-ES": "Boya", "fr-FR": "Pointe", "id-ID": "Center forward",
    "ms-MY": "Center forward", "th-TH": "เซ็นเตอร์ฟอร์เวิร์ด", "vi-VN": "Trung phong",
}
CENTRE_NOTE = {
    "en": "Win the position before the ball is thrown, not after. A centre who "
          "is still fighting when the pass arrives is a turnover with a splash.",
    "en-GB": "Win the position before the ball is thrown, not after. A centre "
             "who is still fighting when the pass arrives is a turnover with a splash.",
    "zh-CN": "在球传出之前就要卡好位，而不是之后。传球到的时候还在拼位置的中锋，就是一次带水花的失误。",
    "zh-TW": "在球傳出之前就要卡好位，而不是之後。傳球到的時候還在拼位置的中鋒，就是一次帶水花的失誤。",
    "ja-JP": "ボールが出る前にポジションを取る。パスが到着した時点でまだ競り合っているセンターは、"
              "水しぶきを上げただけのターンオーバーだ。",
    "ko-KR": "공이 던져지기 전에 자리를 잡아라. 패스가 올 때까지 싸우고 있는 센터는 그냥 턴오버다.",
    "es-ES": "Gana la posición antes del pase, no después: un boya que aún "
             "pelea cuando llega la bola es una pérdida con salpicadura.",
    "fr-FR": "Gagne la position avant la passe, pas après : une pointe qui "
             "lutte encore à l'arrivée du ballon, c'est une perte avec des éclaboussures.",
    "id-ID": "Menangkan posisi sebelum bola dilempar, bukan sesudah.",
    "ms-MY": "Menangi kedudukan sebelum bola dilempar, bukan selepas.",
    "th-TH": "ชิงตำแหน่งให้ได้ก่อนบอลจะถูกส่ง ไม่ใช่หลังจากนั้น",
    "vi-VN": "Giành vị trí trước khi bóng được ném, không phải sau.",
}

DEF_NAME = {
    "en": "Defence", "en-GB": "Defence", "zh-CN": "防守", "zh-TW": "防守",
    "ja-JP": "ディフェンス", "ko-KR": "수비", "es-ES": "Defensa",
    "fr-FR": "Défense", "id-ID": "Pertahanan", "ms-MY": "Pertahanan",
    "th-TH": "การรับ", "vi-VN": "Phòng thủ",
}
DEF_NOTE = {
    "en": "Decide who owns the centre before the set starts. Every goal from "
          "two metres began with two defenders each assuming it was the other.",
    "en-GB": "Decide who owns the centre before the set starts. Every goal "
             "from two metres began with two defenders each assuming it was the other.",
    "zh-CN": "进攻组织开始之前就分清谁盯中锋。每一个两米线上的丢球，起点都是两个防守队员各自以为是对方的责任。",
    "zh-TW": "進攻組織開始之前就分清誰盯中鋒。每一個兩米線上的丟球，起點都是兩個防守隊員各自以為是對方的責任。",
    "ja-JP": "セットが始まる前に誰がセンターを持つか決める。2mからの失点はすべて、二人が互いに相手の担当だと思ったところから始まる。",
    "ko-KR": "세트가 시작되기 전에 누가 센터를 맡을지 정하라.",
    "es-ES": "Decidid quién lleva al boya antes de que empiece el ataque: cada "
             "gol desde dos metros empezó con dos defensores creyendo que era el otro.",
    "fr-FR": "Décidez qui prend la pointe avant la mise en place : chaque but "
             "à deux mètres vient de deux défenseurs qui comptaient l'un sur l'autre.",
    "id-ID": "Tentukan siapa yang menjaga center sebelum serangan tersusun.",
    "ms-MY": "Tentukan siapa menjaga center sebelum serangan tersusun.",
    "th-TH": "ตกลงกันว่าใครดูเซ็นเตอร์ก่อนเกมรุกจะตั้ง",
    "vi-VN": "Quyết định ai kèm trung phong trước khi đợt tấn công bắt đầu.",
}

COUNTER_NAME = {
    "en": "Counter-attack", "en-GB": "Counter-attack", "zh-CN": "反击",
    "zh-TW": "反擊", "ja-JP": "カウンター", "ko-KR": "역습",
    "es-ES": "Contraataque", "fr-FR": "Contre-attaque", "id-ID": "Serangan balik",
    "ms-MY": "Serangan balas", "th-TH": "การสวนกลับ", "vi-VN": "Phản công",
}
COUNTER_NOTE = {
    "en": "Go on the shot, not on the rebound. Two strokes of a head start is "
          "the whole counter — nobody out-swims a set defence.",
    "en-GB": "Go on the shot, not on the rebound. Two strokes of a head start "
             "is the whole counter — nobody out-swims a set defence.",
    "zh-CN": "对方一出手就走，不要等球弹出来。领先两下划水就是整个反击——没人能游得过一条站好的防线。",
    "zh-TW": "對方一出手就走，不要等球彈出來。領先兩下划水就是整個反擊——沒人能游得過一條站好的防線。",
    "ja-JP": "リバウンドではなくシュートの瞬間に出る。2ストロークのアドバンテージが速攻のすべてだ。",
    "ko-KR": "리바운드가 아니라 슛하는 순간에 출발하라. 두 스트로크의 선점이 역습의 전부다.",
    "es-ES": "Sal con el tiro, no con el rechace: dos brazadas de ventaja son "
             "todo el contraataque; nadie le gana a nado a una defensa colocada.",
    "fr-FR": "Pars au tir, pas au rebond : deux mouvements d'avance font toute "
             "la contre-attaque.",
    "id-ID": "Berangkat saat tembakan, bukan saat bola memantul.",
    "ms-MY": "Bergerak ketika tembakan, bukan ketika bola melantun.",
    "th-TH": "ออกตอนเขายิง ไม่ใช่ตอนบอลกระดอน",
    "vi-VN": "Xuất phát ngay khi họ dứt điểm, không đợi bóng bật ra.",
}

SET_NAME = {
    "en": "Restart", "en-GB": "Restart", "zh-CN": "定位球",
    "zh-TW": "定位球", "ja-JP": "リスタート", "ko-KR": "리스타트",
    "es-ES": "Reanudación", "fr-FR": "Remise en jeu", "id-ID": "Restart",
    "ms-MY": "Mula semula", "th-TH": "การเริ่มเล่นใหม่", "vi-VN": "Phát bóng lại",
}
SET_NOTE = {
    "en": "Play the free throw immediately — the advantage only exists while "
          "the defence is still turning around.",
    "en-GB": "Play the free throw immediately — the advantage only exists "
             "while the defence is still turning around.",
    "zh-CN": "任意球要立刻发出——优势只存在于防守还在转身的那一瞬间。",
    "zh-TW": "任意球要立刻發出——優勢只存在於防守還在轉身的那一瞬間。",
    "ja-JP": "フリースローは即座に出す。アドバンテージは守備が振り向いている間しか存在しない。",
    "ko-KR": "프리스로는 즉시 던져라. 이점은 수비가 돌아서는 동안에만 존재한다.",
    "es-ES": "Saca el libre de inmediato: la ventaja solo existe mientras la "
             "defensa aún se está girando.",
    "fr-FR": "Joue le coup franc immédiatement : l'avantage n'existe que le "
             "temps que la défense se retourne.",
    "id-ID": "Mainkan lemparan bebas segera.",
    "ms-MY": "Main lemparan bebas dengan segera.",
    "th-TH": "เล่นลูกฟรีโทรว์ทันที",
    "vi-VN": "Thực hiện quả ném phạt ngay lập tức.",
}

GAME_NAME = {
    "en": "Game", "en-GB": "Game", "zh-CN": "对抗", "zh-TW": "對抗",
    "ja-JP": "ゲーム", "ko-KR": "게임", "es-ES": "Juego", "fr-FR": "Jeu",
    "id-ID": "Permainan", "ms-MY": "Permainan", "th-TH": "เกม", "vi-VN": "Trận đấu",
}
GAME_NOTE = {
    "en": "Put a shot clock on it. Water polo punishes indecision more than "
          "any other team sport, and only a clock teaches that.",
    "en-GB": "Put a shot clock on it. Water polo punishes indecision more than "
             "any other team sport, and only a clock teaches that.",
    "zh-CN": "加上进攻时限。水球对犹豫的惩罚比任何团队项目都重，而只有计时器教得会这一点。",
    "zh-TW": "加上進攻時限。水球對猶豫的懲罰比任何團隊項目都重，而只有計時器教得會這一點。",
    "ja-JP": "ショットクロックをつける。水球は他のどの団体競技より迷いを罰する。それを教えられるのは時計だけだ。",
    "ko-KR": "샷 클락을 걸어라. 수구는 어떤 종목보다 망설임을 벌하며, 그것을 가르치는 건 시계뿐이다.",
    "es-ES": "Ponle reloj de posesión: el waterpolo castiga la indecisión más "
             "que ningún deporte de equipo, y eso solo lo enseña un reloj.",
    "fr-FR": "Mets un chrono de possession : le water-polo punit l'hésitation "
             "plus que tout autre sport collectif.",
    "id-ID": "Pasang shot clock.",
    "ms-MY": "Pasang jam tembakan.",
    "th-TH": "ใส่เวลาจับการครองบอล",
    "vi-VN": "Đặt đồng hồ tấn công.",
}

SHOOT_NAME = {"en": "Perimeter shot", "en-GB": "Perimeter shot",
              "zh-CN": "外围射门", "zh-TW": "外圍射門", "ja-JP": "アウトサイドシュート",
              "ko-KR": "외곽 슛", "es-ES": "Tiro exterior", "fr-FR": "Tir extérieur",
              "id-ID": "Tembakan luar", "ms-MY": "Tembakan luar",
              "th-TH": "ยิงจากวงนอก", "vi-VN": "Sút xa"}
SHOOT_NOTE = {
    "en": "Get the hips out of the water before the arm goes, and pick the corner off the block, not off the keeper. A shot released from a low body is a pass to the goalkeeper.",
    "zh-CN": "手臂发力之前先把腰胯拔出水面，角度看封挡的位置，不是看门将。身体沉着出手的射门，就是给门将送了一次传球。",
    "zh-TW": "手臂發力之前先把腰胯拔出水面，角度看封擋的位置，不是看門將。身體沉著出手的射門，就是給門將送了一次傳球。",
    "ja-JP": "腕を振る前に腰を水面から出す。コースはブロックを見て決める、GKではない。体が沈んだまま放つシュートはGKへのパスだ。",
    "ko-KR": "팔을 휘두르기 전에 골반을 물 밖으로 띄워라. 코스는 블록을 보고 고르지 골키퍼를 보고 고르지 않는다.",
    "es-ES": "Saca las caderas del agua antes de que salga el brazo y elige la escuadra por el bloqueo, no por el portero. Un tiro con el cuerpo bajo es un pase al portero.",
    "fr-FR": "Sors les hanches de l'eau avant que le bras parte, et choisis l'angle en fonction du contre, pas du gardien. Un tir corps bas est une passe au gardien.",
    "id-ID": "Angkat pinggul dari air sebelum lengan diayun, dan pilih sudut dari bloknya, bukan dari kipernya.",
    "ms-MY": "Angkat pinggul dari air sebelum lengan dihayun, dan pilih sudut dari blok, bukan dari penjaga gol.",
    "th-TH": "ยกสะโพกพ้นน้ำก่อนเหวี่ยงแขน และเลือกมุมจากบล็อก ไม่ใช่จากผู้รักษาประตู",
    "vi-VN": "Nâng hông lên khỏi mặt nước trước khi vung tay, và chọn góc theo hàng chắn chứ không theo thủ môn. Cú sút tung ra khi người còn thấp chỉ là đường chuyền cho thủ môn.",
}
WP_GK_NAME = {"en": "Goalkeeping", "en-GB": "Goalkeeping", "zh-CN": "门将训练",
              "zh-TW": "門將訓練", "ja-JP": "GK練習", "ko-KR": "골키퍼 훈련",
              "es-ES": "Portería", "fr-FR": "Gardien de but", "id-ID": "Latihan kiper",
              "ms-MY": "Latihan penjaga gol", "th-TH": "ฝึกผู้รักษาประตู",
              "vi-VN": "Tập thủ môn"}
WP_GK_NOTE = {
    "en": "Egg-beater high enough to have the shoulders out before the shot, and hold the near post until the ball leaves the hand. Everything you give away early you cannot take back.",
    "zh-CN": "踩水踩到出手前肩膀已经出水，近角守住不动，直到球离手。提前让出去的位置，是收不回来的。",
    "zh-TW": "踩水踩到出手前肩膀已經出水，近角守住不動，直到球離手。提前讓出去的位置，是收不回來的。",
    "ja-JP": "シュート前に肩が水面上に出るまで巻き足で上がり、ボールが手を離れるまでニアを譲らない。早く空けた分は取り戻せない。",
    "ko-KR": "슛 전에 어깨가 물 밖으로 나올 만큼 에그비터로 떠올라, 공이 손을 떠날 때까지 니어를 지켜라.",
    "es-ES": "Bate lo bastante alto para tener los hombros fuera antes del tiro y guarda el palo cercano hasta que el balón salga de la mano.",
    "fr-FR": "Monte assez haut pour avoir les épaules hors de l'eau avant le tir, et garde le premier poteau jusqu'à ce que le ballon quitte la main.",
    "id-ID": "Kayuh cukup tinggi agar bahu keluar dari air sebelum tembakan, dan jaga tiang dekat sampai bola lepas dari tangan.",
    "ms-MY": "Kayuh cukup tinggi supaya bahu keluar dari air sebelum tembakan, dan jaga tiang dekat sehingga bola lepas.",
    "th-TH": "ตีขาให้สูงพอจนไหล่พ้นน้ำก่อนลูกยิง และรักษาเสาใกล้ไว้จนบอลหลุดจากมือ",
    "vi-VN": "Đạp nước đủ cao để vai nhô khỏi mặt nước trước cú sút, và giữ cột gần cho đến khi bóng rời tay. Thứ gì nhường sớm thì không lấy lại được.",
}


def warmup_family() -> list[Drill]:
    out = []
    # Eggbeater: the ball goes round all four, and whoever is about to
    # receive it eggbeaters a metre sideways to meet it.
    egg = [pl(10.0, 9.0, "1", [(9.0, 9.0, 3)]),
           pl(14.5, 12.0, "2", [(14.5, 11.0, 0)]),
           pl(10.0, 15.0, "3", [(11.0, 15.0, 1)]),
           pl(5.5, 12.0, "4", [(5.5, 13.0, 2)])]
    # Swim and catch: both swim up the pool, the pass is made on the swim.
    swim = [pl(6.0, 18.6, "1", [(6.0, 10.8, 0), (7.2, 6.6, 1)]),
            pl(14.0, 18.6, "2", [(14.0, 10.8, 0), (12.8, 6.6, 1)])]
    wet = [pl(7.2, 13.2, "1", [(8.0, 10.8, 0)]),
           pl(12.8, 10.8, "2", [(12.0, 13.2, 0)])]
    specs = [("eggbeater", "eggbeater and pass", egg, [(1, 0), (2, 1), (3, 2), (0, 3)]),
             ("swim_catch", "swim and catch", swim, [(1, 1)]),
             ("wet_pass", "wet passing", wet, [(1, 0), (0, 1)])]
    for key, label, home, route in specs:
        out.append(Drill(
            id=f"wp_warm_{key}", category="warmup", minutes=8, rel=True,
            free=(key in ("eggbeater", "wet_pass")),
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            home=home, ball=0, ball_to=route,
        ))
    return out


def _perimeter_d(i, spot, moves=(), **kw):
    x, y = _goal_side(spot)
    return pl(x, y, f"D{i + 1}", moves, **kw)


def perimeter_family() -> list[Drill]:
    out = []
    # circulation: 4 → 2 → 1 → 3 → 5, round the arc in front of the
    # defenders; each receiver pops out to meet it and his defender goes
    # with him — goal-side and to the inside, never on top of him.
    def popped(spot):
        return (spot[0] + _inside(spot[0]) * 0.3, spot[1] + 0.7)

    def pressed(spot):
        # inside of where he STARTED: the point popping half a metre right
        # must not flip his defender to the other shoulder
        px, py = popped(spot)
        return (px + _inside(spot[0]) * 1.3, py - 1.5)

    order = {1: 0, 0: 1, 2: 2, 4: 3}         # receiver index -> beat
    home = [pl(*s, str(i + 1),
               [(*popped(s), order[i])] if i in order else [])
            for i, s in enumerate(PERIMETER)]
    away = [_perimeter_d(i, s, [(*pressed(s), order[i])] if i in order else [],
                         why={order[i]: "close_lane"} if i in order else {})
            for i, s in enumerate(PERIMETER)] + [keeper()]
    out.append(Drill(
        id="wp_perimeter_circulation", category="possession", minutes=12,
        rel=True, free=True,
        name=suffixed(PERIM_NAME, "circulation"), note=PERIM_NOTE,
        home=home, away=away, ball=3,
        ball_to=[(1, 0), (0, 1), (2, 2), (4, 3)],
    ))

    # through the centre: 4 → 2 → CF, the centre sealing his man as the
    # ball arrives. The CF has his own defender (H).
    home = [pl(*s, str(i + 1), [(*popped(s), 0)] if i == 1 else [])
            for i, s in enumerate(PERIMETER)]
    home.append(pl(*CF_SPOT, "CF", [(7.9, 3.2, 1)], why={1: "wp_seal"}))
    away = [_perimeter_d(i, s, [(*pressed(s), 0)] if i == 1 else [])
            for i, s in enumerate(PERIMETER)]
    away += [pl(*HOLE_D, "H", [(7.0, 2.0, 1)]), keeper()]
    out.append(Drill(
        id="wp_perimeter_with_centre", category="possession", minutes=12,
        rel=True, free=True, tight=True,
        name=suffixed(PERIM_NAME, "through the centre"), note=PERIM_NOTE,
        home=home, away=away, ball=3, ball_to=[(1, 0), (5, 1)],
    ))

    # drive and kick: 1 → 2, 2 drives at the goal with the ball, the wing's
    # defender sags in to stop him — and the ball is kicked out to that
    # wing, now open, who shoots.
    home = [pl(*PT, "1"),
            pl(*LF, "2", [(5.0, 7.0, 0), (6.0, 4.5, 1)], why={1: "to_goal"}),
            pl(*RF, "3"),
            pl(*LW, "4", [(2.4, 5.0, 2)], why={2: "get_free"}),
            pl(*RW, "5"),
            pl(*CF_SPOT, "CF")]
    d_lf = _goal_side(LF)
    d_lw = _goal_side(LW)
    away = [_perimeter_d(0, PT),
            pl(*d_lf, "D2", [(6.4, 5.6, 0), (5.2, 5.4, 1)]),
            _perimeter_d(2, RF),
            pl(*d_lw, "D4", [(4.6, 3.2, 1)], why={1: "wp_drop"}),
            _perimeter_d(4, RW),
            pl(*HOLE_D, "H"),
            keeper(moves=[(9.1, 1.1, 2)])]
    out.append(Drill(
        id="wp_perimeter_drive_and_kick", category="possession", minutes=12,
        rel=True, tight=True,
        name=suffixed(PERIM_NAME, "drive and kick"), note=PERIM_NOTE,
        home=home, away=away, ball=0,
        ball_to=[(1, 0), (1, 1), (3, 2), (SHOT_R, 3)],
    ))
    return out


MAN_UP_SHAPES = {
    # 4-2: four out (wings at 4.5 m, flats at 6 m), two on the posts at 2.5.
    "four_two": [(2.8, 4.6), (7.4, 6.4), (12.6, 6.4), (17.2, 4.6),
                 (7.2, TWO_M_SET), (12.8, TWO_M_SET)],
    # 3-3: three out at 6-7.5 m, three on the 2 m (posts and the middle).
    "three_three": [(4.0, 6.4), (10.0, 7.6), (16.0, 6.4),
                    (6.0, TWO_M_SET + 0.3), (10.0, 4.1), (14.0, TWO_M_SET + 0.3)],
    # umbrella: the point at 9 m, three across the 5 m, two on the posts.
    "umbrella": [(10.0, 9.2), (3.2, 5.0), (16.8, 5.0), (10.0, 5.6),
                 (7.0, TWO_M_SET), (13.0, TWO_M_SET)],
}
# The man-down answer to each shape: two on the posts, three in a zone
# placed against THAT shape's outside players.
MAN_DOWN = {
    "four_two": [(8.5, 1.6), (11.5, 1.6), (4.6, 4.4), (10.0, 4.6), (15.4, 4.4)],
    "three_three": [(7.3, 1.6), (12.7, 1.6), (6.4, 4.8), (11.6, 5.3), (14.0, 4.6)],
    "umbrella": [(8.4, 1.6), (11.6, 1.6), (5.4, 3.9), (10.0, 3.4), (14.6, 3.9)],
}
# Two passes through the top, then the shot: (ball holder, [(receiver, his
# step to meet it)], the zone's slides per pass, keeper's step, shot corner).
MAN_UP_PLAY = {
    "four_two": (3, [(2, (12.4, 6.9)), (1, (7.6, 6.9))],
                 [{2: (5.4, 4.6), 3: (11.0, 4.9), 4: (14.8, 5.0)},
                  {2: (5.4, 4.8), 3: (8.9, 5.2), 4: (13.6, 4.6)}],
                 (9.1, 1.1), SHOT_R),
    "three_three": (0, [(1, (10.0, 8.2)), (2, (15.6, 6.9))],
                    [{2: (7.0, 5.0), 3: (11.2, 6.0), 4: (13.6, 5.0)},
                     {2: (7.6, 4.8), 3: (12.2, 5.6), 4: (14.8, 5.0)}],
                    (11.5, 1.1), SHOT_L),
    "umbrella": (1, [(0, (10.0, 9.8)), (2, (16.4, 5.6))],
                 [{2: (6.0, 4.2), 3: (10.0, 3.9), 4: (14.2, 4.2)},
                  {2: (6.6, 4.0), 3: (11.2, 3.6), 4: (15.4, 4.4)}],
                 (11.0, 1.1), SHOT_L),
}


def man_up_family() -> list[Drill]:
    labels = {"four_two": "4-2", "three_three": "3-3", "umbrella": "the umbrella"}
    out = []
    for key in ("four_two", "three_three", "umbrella"):
        spots = MAN_UP_SHAPES[key]
        holder, passes, slides, gk_step, shot = MAN_UP_PLAY[key]
        steps = {who: (to, beat) for beat, (who, to) in enumerate(passes)}
        home = [pl(x, y, str(i + 1),
                   [(*steps[i][0], steps[i][1])] if i in steps else [],
                   why={steps[i][1]: "get_free"} if i in steps else {})
                for i, (x, y) in enumerate(spots)]
        away = []
        for j, (x, y) in enumerate(MAN_DOWN[key]):
            mv = [(*slides[b][j], b) for b in range(2) if j in slides[b]]
            away.append(pl(x, y, f"D{j + 1}", mv,
                           why={b: "shift" for (_, _, b) in mv}))
        away.append(keeper(moves=[(*gk_step, 1)], why={1: "set_gk"}))
        out.append(Drill(
            id=f"wp_manup_{key}", category="attacking", minutes=12, rel=True,
            # The man-up shapes are lines; opening them draws a different formation.
            tight=True,
            free=(key in ("four_two", "three_three")),
            name=suffixed(MAN_UP_NAME, labels[key]), note=MAN_UP_NOTE,
            home=home, away=away, ball=holder,
            ball_to=[(passes[0][0], 0), (passes[1][0], 1), (shot, 2)],
        ))
    return out


def centre_family() -> list[Drill]:
    """The centre forward works at 2.5-3 m with a defender on his back, and
    shoots from there — he never follows his own shot onto the keeper.

    entry:    received, turned, shot past the keeper's far side.
    backhand: no turn at all — sealed, and the ball flicked back over the
              shoulder from where he stands.
    sweep:    he pivots off the defender to the other side and sweeps the
              ball across his body to the far corner.
    draw_foul: he seals, the defender is excluded and swims to the
              re-entry area, and the ball is played back out for the
              man-up shot.
    """
    out = []
    feeder = (10.6, 7.6)
    # The centre always stands a body width to the side of the keeper: a
    # figure is drawn ~2.7 m tall, so a centre at 2.5 m straight in front
    # of a keeper at 1 m is drawn standing on him.
    specs = {
        "entry": dict(cf=(8.2, 3.0), cf_mv=[(8.7, 2.6, 1)], cf_why={1: "turn"},
                      d=(7.0, 2.0), d_mv=[(7.6, 2.2, 1)],
                      gk=(10.4, 1.1), gk_mv=[(10.8, 1.1, 1)], shot=SHOT_L),
        "backhand": dict(cf=(11.8, 3.0), cf_mv=[(12.1, 2.8, 1)], cf_why={1: "wp_seal"},
                         d=(10.6, 2.2), d_mv=[(10.9, 2.4, 1)],
                         gk=(9.0, 1.1), gk_mv=[], shot=SHOT_R),
        "sweep": dict(cf=(8.6, 3.2), cf_mv=[(9.4, 2.9, 1)], cf_why={1: "turn"},
                      d=(7.4, 2.2), d_mv=[(8.2, 2.4, 1)],
                      gk=(11.2, 1.1), gk_mv=[(11.5, 1.1, 1)], shot=SHOT_L),
    }
    for key, label in (("entry", "the entry pass"), ("backhand", "the backhand"),
                       ("sweep", "the sweep shot")):
        s = specs[key]
        out.append(Drill(
            id=f"wp_centre_{key}", category="finishing", minutes=10, rel=True,
            tight=True, free=(key in ("entry", "backhand")),
            name=suffixed(CENTRE_NAME, label), note=CENTRE_NOTE,
            home=[pl(*feeder, "1"),
                  pl(*s["cf"], "CF", s["cf_mv"], why=s["cf_why"])],
            away=[pl(*s["d"], "D", s["d_mv"]),
                  keeper(*s["gk"], moves=s["gk_mv"])],
            markers=[mk(*_m(s["shot"]), "zone")],
            ball=0,
            ball_to=[(1, 0), (s["shot"], 2)],
        ))
    out.append(Drill(
        id="wp_centre_draw_foul", category="finishing", minutes=10, rel=True,
        tight=True,
        name=suffixed(CENTRE_NAME, "drawing the exclusion"), note=CENTRE_NOTE,
        home=[pl(*feeder, "1", [(10.0, 6.6, 2)]),
              pl(8.4, TWO_M_SET, "CF", [(8.2, TWO_M_SET, 1)], why={1: "wp_seal"})],
        away=[pl(7.2, 1.9, "D", [(7.6, 2.2, 1), (1.0, 1.0, 2)],
                 why={2: "wp_excluded"}),
              keeper(10.4, 1.1, moves=[(10.9, 1.1, 2)])],
        ball=0,
        ball_to=[(1, 0), (0, 2), (SHOT_L, 3)],
    ))
    return out


def _m(rel):
    """Court fractions → metres (for a marker on a shot target)."""
    return (rel[0] * POOL_W, rel[1] * POOL_L)


def defence_family() -> list[Drill]:
    """Every board ends on the defence's answer, never on the centre scoring.

    press:   five defenders on their men's hips, goal-side; the point's pass
             to the flat is jumped by the flat's defender, who goes.
    drop:    the flats' defenders sag into the hole; the flat's entry to the
             centre is picked off by the man who dropped into its lane.
    front:   H swims round to the ball side of the centre, the weak-side
             flat drops in behind him, and the lob over H is his.
    five on six: a 4-2 power play against the zone; two passes, the shot,
             the keeper's save.
    """
    out = []
    # Attackers set up a stroke deeper and swim onto their spots on beat 0.
    def att(i, s, extra=()):
        return pl(s[0], s[1] + 1.5, str(i + 1), [(s[0], s[1], 0), *extra])

    def cf(extra=(), why=None):
        return pl(CF_SPOT[0], CF_SPOT[1] + 1.4, "CF", [(*CF_SPOT, 0), *extra],
                  why=why or {})

    def start(s):
        """Where a defender begins, before he takes his spot."""
        return (s[0] + _inside(s[0]) * 1.5, s[1] - 0.2)

    hip = {i: _goal_side(s, 1.1, 1.1) for i, s in enumerate(PERIMETER)}

    # press
    away = []
    for i, s in enumerate(PERIMETER):
        mv = [(*hip[i], 0)]
        why = {0: "wp_press"}
        if i == 1:
            # into the lane between the point and the left flat
            mv.append((7.4, 6.6, 1))
            why[1] = "close_lane"
            mv.append((7.6, 10.6, 2))
            why[2] = "recover"
        away.append(pl(*start(s), f"D{i + 1}", mv, why=why))
    away += [pl(*HOLE_D, "H"), keeper()]
    home = [att(i, s, [(5.0, 6.9, 1)] if i == 1 else [])
            for i, s in enumerate(PERIMETER)] + [cf()]
    out.append(Drill(
        id="wp_defence_press", category="defending", minutes=12, rel=True,
        free=True, tight=True, name=suffixed(DEF_NAME, "pressing"), note=DEF_NOTE,
        home=home, away=away, ball=0,
        ball_to=[("a1", 1), ("a1", 2)],
    ))

    # drop
    sag = {1: (6.6, 4.9), 2: (12.6, 4.6), 0: (10.6, 5.2)}
    away = []
    for i, s in enumerate(PERIMETER):
        mv = [(*(sag[i] if i in sag else hip[i]), 0)]
        why = {0: "wp_drop" if i in sag else "wp_press"}
        away.append(pl(*start(s), f"D{i + 1}", mv, why=why))
    away += [pl(*HOLE_D, "H"), keeper()]
    home = [att(i, s, [(5.0, 6.9, 1)] if i == 1 else [])
            for i, s in enumerate(PERIMETER)] + [cf([(8.0, 3.2, 2)], {2: "wp_seal"})]
    away[1].moves.append((6.3 / POOL_W, 5.4 / POOL_L, 1))
    out.append(Drill(
        id="wp_defence_drop", category="defending", minutes=12, rel=True,
        free=True, tight=True, name=suffixed(DEF_NAME, "dropping off"), note=DEF_NOTE,
        home=home, away=away, ball=0,
        ball_to=[(1, 1), ("a1", 2)],
    ))

    # fronting the centre
    away = []
    for i, s in enumerate(PERIMETER):
        if i == 2:
            # the weak-side flat drops in behind the centre for the lob
            away.append(pl(*start(s), "D3", [(6.6, 1.6, 0)], why={0: "wp_drop"}))
        else:
            away.append(pl(*start(s), f"D{i + 1}", [(*hip[i], 0)],
                           why={0: "wp_press"}))
    away += [pl(9.4, 1.9, "H", [(9.2, 4.4, 0), (7.6, 4.3, 1)],
                why={0: "wp_front", 1: "wp_front"}),
             keeper(11.0, 1.1, moves=[(10.1, 1.1, 1)])]
    home = [att(i, s, [(5.0, 6.9, 1)] if i == 1 else [])
            for i, s in enumerate(PERIMETER)] + [cf([(8.0, 3.2, 2)], {2: "wp_seal"})]
    out.append(Drill(
        id="wp_defence_front_the_centre", category="defending", minutes=12,
        rel=True, tight=True,
        name=suffixed(DEF_NAME, "fronting the centre"), note=DEF_NOTE,
        home=home, away=away, ball=0,
        ball_to=[(1, 1), ("a2", 2)],
    ))

    # five against six: the 4-2 power play against the man-down zone.
    spots = MAN_UP_SHAPES["four_two"]
    home = [pl(*s, str(i + 1),
               [(12.4, 6.9, 0)] if i == 2 else [(7.6, 6.9, 1)] if i == 1 else [])
            for i, s in enumerate(spots)]
    slides = MAN_UP_PLAY["four_two"][2]
    away = []
    for j, (x, y) in enumerate(MAN_DOWN["four_two"]):
        mv = [(*slides[b][j], b) for b in range(2) if j in slides[b]]
        away.append(pl(x, y, f"D{j + 1}", mv, why={b: "shift" for (_, _, b) in mv}))
    away.append(keeper(moves=[(9.1, 1.1, 1)], why={1: "set_gk"}))
    out.append(Drill(
        id="wp_defence_five_on_six", category="defending", minutes=12,
        rel=True, tight=True,
        name=suffixed(DEF_NAME, "five against six"), note=DEF_NOTE,
        home=home, away=away, ball=3,
        ball_to=[(2, 0), (1, 1), ("a5", 2)],
    ))
    return out


COUNTER_PURPOSE = _P12(
    "Turn a change of possession into a goal before the defence is back: "
    "leave on the shot, swim the lanes wide, and finish with the trailer or "
    "the man who got to two metres first.",
    "把一次球权转换变成进球，赶在对方回防之前：对方一出手就出发，泳道拉开，用插上的后点或先到两米的人完成射门。",
    "把一次球權轉換變成進球，趕在對方回防之前：對方一出手就出發，泳道拉開，用插上的後點或先到兩米的人完成射門。",
    "守備が戻る前に攻守の切り替えを得点にする。相手のシュートで出て、レーンを広く泳ぎ、トレーラーか先に2mへ着いた選手で決める。",
    "수비가 돌아오기 전에 공수 전환을 골로 만든다. 상대 슛에 출발하고, 레인을 넓게 헤엄쳐, 뒤따라온 선수나 먼저 2m에 도착한 선수로 마무리한다.",
    "Convertir el cambio de posesión en gol antes de que vuelva la defensa: "
    "salir con el tiro, nadar las calles abiertas y terminar con el que llega "
    "detrás o con el primero en los dos metros.",
    "Transformer la perte de balle adverse en but avant le repli : partir au "
    "tir, nager les couloirs écartés, finir par le joueur qui suit ou par "
    "celui arrivé le premier aux deux mètres.",
    "Mengubah pergantian penguasaan bola menjadi gol sebelum pertahanan "
    "kembali: berangkat saat tembakan, berenang melebar, dan selesaikan lewat "
    "pemain yang menyusul atau yang lebih dulu tiba di dua meter.",
    "Menukar pertukaran milikan bola menjadi gol sebelum pertahanan kembali: "
    "bergerak ketika tembakan, berenang melebar, dan habiskan melalui pemain "
    "yang menyusul atau yang terlebih dahulu tiba di dua meter.",
    "เปลี่ยนการได้บอลคืนให้เป็นประตูก่อนแนวรับกลับมาทัน ออกตัวตอนคู่แข่งยิง ว่ายแยกเลนให้กว้าง "
    "แล้วจบด้วยคนที่ตามขึ้นมาหรือคนที่ถึงสองเมตรก่อน",
    "Biến pha đổi quyền kiểm soát bóng thành bàn thắng trước khi hàng thủ kịp "
    "về: xuất phát ngay khi đối phương dứt điểm, bơi dàn rộng các làn và kết "
    "thúc bằng người băng lên sau hoặc người tới vạch hai mét trước.",
)


def counter_family() -> list[Drill]:
    """A counter starts at the OTHER end: the attackers have just won the
    ball in their own half and the defenders, who were attacking, start
    level with them or behind them — one stroke down, which is the whole
    counter. They used to stand set at 6 m before the break began."""
    out = []
    # (label, start, beat-0 swim, beat-1 swim, beat-2 step)
    att = {
        2: [("1", (7.0, 16.0), (7.5, 8.5), (8.2, 5.6), None),
            ("2", (13.0, 16.5), (13.0, 7.8), (12.8, 4.6), (12.4, 3.6))],
        3: [("1", (6.0, 15.5), (6.5, 8.5), (7.0, 6.0), None),
            ("2", (14.0, 16.0), (13.5, 7.8), (13.0, 4.8), None),
            ("3", (10.0, 18.0), (10.0, 10.7), (10.0, 8.6), (10.0, 6.6))],
        4: [("1", (5.5, 15.5), (6.0, 8.5), (6.6, 6.0), None),
            ("2", (14.5, 16.0), (15.0, 7.8), (15.8, 5.4), None),
            ("3", (10.0, 18.0), (10.0, 10.7), (10.0, 8.8), None),
            ("4", (11.5, 16.5), (12.0, 6.7), (12.3, TWO_M_SET), (12.8, 3.3))],
    }
    dfn = {
        2: [((10.0, 18.5), (10.0, 9.6), (9.6, 5.2), (10.8, 4.2))],
        3: [((8.5, 19.0), (8.3, 10.3), (8.4, 4.6), (9.0, 5.0)),
            ((12.0, 19.5), (12.0, 10.0), (11.8, 3.6), None)],
        4: [((7.0, 20.0), (7.8, 10.3), (8.0, 4.8), None),
            ((11.6, 20.5), (11.6, 9.6), (11.5, 5.8), (11.0, 4.6)),
            ((14.0, 20.0), (13.6, 10.0), (14.8, 4.0), None)],
    }
    # who receives the lay-off on beat 2, the corner he finishes in, and
    # where the keeper has gone
    finish = {2: (1, SHOT_L, (10.9, 1.1)), 3: (2, SHOT_R, (9.1, 1.1)),
              4: (3, SHOT_L, (10.8, 1.1))}
    for n in (2, 3, 4):
        home = []
        for lab, s, b0, b1, b2 in att[n]:
            mv = [(*b0, 0), (*b1, 1)] + ([(*b2, 2)] if b2 else [])
            why = {0: "swim"}
            if lab == "4":
                why[2] = "wp_seal"
            home.append(pl(*s, lab, mv, why=why))
        away = []
        for k, (s, b0, b1, b2) in enumerate(dfn[n]):
            mv = [(*b0, 0), (*b1, 1)] + ([(*b2, 2)] if b2 else [])
            away.append(pl(*s, f"D{k + 1}", mv, why={0: "recover"}))
        who, shot, gk_to = finish[n]
        away.append(keeper(moves=[(*gk_to, 2)]))
        out.append(Drill(
            id=f"wp_counter_{n}v{n - 1}", category="attacking", minutes=10,
            # the 4v3's fourth man sets at two metres: see TWO_M_SET
            rel=True, free=(n == 3), tight=(n == 4),
            name=suffixed(COUNTER_NAME, f"{n}v{n - 1}"), note=COUNTER_NOTE,
            purpose=COUNTER_PURPOSE,
            home=home, away=away, ball=0,
            # carried up the pool on the swim, laid off, finished
            ball_to=[(0, 0), (0, 1), (who, 2), (shot, 3)],
        ))
    return out


PENALTY_NOTE = _P12(
    "Pick the corner before the whistle and throw in one movement — any "
    "pause, fake or step forward after the whistle is a foul, and the "
    "keeper is reading the shoulder, not the ball.",
    "哨响之前就选好角度，一个动作出手——哨后任何停顿、假动作或往前移动都是犯规，而门将读的是你的肩膀，不是球。",
    "哨響之前就選好角度，一個動作出手——哨後任何停頓、假動作或往前移動都是犯規，而門將讀的是你的肩膀，不是球。",
    "笛の前にコースを決め、一つの動作で投げる。笛の後の間、フェイク、前進はすべて反則で、GKが読んでいるのはボールではなく肩だ。",
    "휘슬 전에 코스를 정하고 한 동작으로 던진다. 휘슬 뒤의 멈춤, 페이크, 전진은 모두 반칙이고, 골키퍼는 공이 아니라 어깨를 읽는다.",
    "Elige la esquina antes del silbato y lanza en un solo movimiento: "
    "cualquier pausa, finta o avance tras el silbato es falta, y el portero "
    "lee el hombro, no el balón.",
    "Choisis le coin avant le coup de sifflet et tire d'un seul geste : toute "
    "pause, feinte ou avancée après le sifflet est une faute, et le gardien "
    "lit l'épaule, pas le ballon.",
    "Pilih sudut sebelum peluit dan lempar dalam satu gerakan — jeda, tipuan "
    "atau maju setelah peluit adalah pelanggaran, dan kiper membaca bahu, "
    "bukan bola.",
    "Pilih sudut sebelum wisel dan lempar dalam satu gerakan — jeda, helah "
    "atau mara selepas wisel ialah kesalahan, dan penjaga gol membaca bahu, "
    "bukan bola.",
    "เลือกมุมก่อนเสียงนกหวีดแล้วยิงในจังหวะเดียว การหยุด หลอก หรือขยับไปข้างหน้าหลังนกหวีดคือฟาวล์ "
    "และผู้รักษาประตูอ่านไหล่ ไม่ใช่บอล",
    "Chọn góc trước tiếng còi và ném trong một động tác — mọi khựng lại, "
    "động tác giả hay tiến lên sau tiếng còi đều là phạm lỗi, và thủ môn "
    "đọc vai bạn chứ không đọc bóng.",
)
SWIM_OFF_NOTE = _P12(
    "Win the first three strokes, head up: the sprinter who reaches the ball "
    "a hand ahead turns his team's possession into the first attack, and one "
    "who arrives level should play it back, not fight for it.",
    "前三划决定一切，抬头游：领先一只手到球的人，就把球权变成本方的第一次进攻；同时到的，回传给队友，别去硬抢。",
    "前三划決定一切，抬頭游：領先一隻手到球的人，就把球權變成本方的第一次進攻；同時到的，回傳給隊友，別去硬搶。",
    "最初の3ストロークを顔を上げて制する。手一つ先にボールへ着いた者がチームの最初の攻撃を作る。並んで着いたら争わずに戻す。",
    "처음 세 스트로크를 고개 들고 이겨라. 손 하나 먼저 공에 닿은 선수가 팀의 첫 공격을 만든다. 동시에 닿으면 다투지 말고 뒤로 돌려라.",
    "Gana las tres primeras brazadas con la cabeza fuera: quien llega una "
    "mano antes convierte la posesión en el primer ataque; si llegáis a la "
    "vez, devuélvela, no la pelees.",
    "Gagne les trois premiers mouvements tête haute : celui qui touche le "
    "ballon une main avant fait de la possession la première attaque ; à "
    "égalité, on la remet en arrière au lieu de la disputer.",
    "Menangkan tiga kayuhan pertama dengan kepala di atas air: yang tiba satu "
    "tangan lebih dulu mengubah bola menjadi serangan pertama; jika tiba "
    "bersamaan, kembalikan, jangan diperebutkan.",
    "Menangi tiga kayuhan pertama dengan kepala di atas air: yang tiba satu "
    "tangan lebih awal menjadikan bola serangan pertama; jika tiba serentak, "
    "pulangkan, jangan berebut.",
    "ชนะสามจังหวะแรกโดยเงยหน้า คนที่ถึงบอลก่อนหนึ่งช่วงมือจะเปลี่ยนการครองบอลเป็นการบุกครั้งแรก "
    "ถ้าถึงพร้อมกันให้ส่งคืนหลัง อย่าแย่ง",
    "Thắng ba nhịp bơi đầu tiên với đầu ngẩng cao: người chạm bóng trước nửa "
    "sải tay biến quyền bóng thành đợt tấn công đầu tiên; nếu tới cùng lúc, "
    "hãy chuyền về, đừng tranh chấp.",
)


def setpiece_family() -> list[Drill]:
    out = [Drill(
        # From ON the five-metre line, in one motion, no advance: the
        # taker used to stand on the 6 m line and swim forward first.
        # A team-mate and a defender wait outside the 5 m area for the
        # rebound and go as the ball leaves the hand.
        id="wp_set_penalty", category="setpiece", minutes=6, rel=True, free=True,
        name=suffixed(SET_NAME, "the five-metre penalty"), note=PENALTY_NOTE,
        home=[pl(10.0, 5.0, "1"),
              pl(5.0, 6.8, "2", [(6.6, 4.4, 0)], why={0: "to_goal"})],
        away=[pl(6.6, 6.2, "D", [(7.8, 3.8, 0)], why={0: "recover"}),
              keeper(10.0, 1.1, moves=[(9.1, 1.1, 0)])],
        markers=[mk(10.0, 5.0, "square")],
        ball=0,
        ball_to=[(SHOT_R, 0)],
    ), Drill(
        id="wp_set_free_throw", category="setpiece", minutes=8, rel=True,
        tight=True,
        name=suffixed(SET_NAME, "the quick free throw"), note=SET_NOTE,
        home=[pl(4.8, 9.0, "1"),
              pl(13.6, 8.4, "2", [(12.2, 5.2, 0)], why={0: "run_behind"}),
              pl(*CF_SPOT, "CF", [(8.0, 3.2, 0)], why={0: "wp_seal"})],
        away=[pl(6.4, 7.6, "D1", [(5.8, 8.2, 0)]),
              pl(12.0, 6.4, "D2", [(12.6, 6.0, 0)]),
              pl(*HOLE_D, "H"),
              keeper(moves=[(10.9, 1.1, 1)])],
        ball=0,
        # taken at once to the 2 breaking past a defender still turning
        ball_to=[(1, 0), (SHOT_L, 1)],
    ), Drill(
        # One sprinter a side, level on the two goal lines, the rest of
        # each team and both keepers on their lines, the ball at halfway.
        # The home sprinter gets there a stroke first and plays it back.
        id="wp_set_swim_off", category="setpiece", minutes=6, rel=True, free=True,
        name=suffixed(SET_NAME, "the swim-off"), note=SWIM_OFF_NOTE,
        home=[pl(11.6, 23.9, "1", [(10.6, 13.1, 0), (10.4, 12.6, 1)],
                 why={0: "swim"}),
              pl(5.0, 23.9, "2", [(6.0, 18.0, 0)]),
              pl(15.0, 23.9, "3", [(14.0, 18.0, 0), (14.5, 16.0, 2)]),
              keeper(10.0, 23.9)],
        away=[pl(8.4, 1.1, "A", [(9.4, 10.1, 0)], why={0: "swim"}),
              pl(5.0, 1.1, "B", [(6.0, 6.7, 0)]),
              pl(15.0, 1.1, "C", [(14.0, 6.7, 0)]),
              keeper(10.0, 1.1)],
        ball=_r(10.0, 12.5),
        ball_to=[(0, 1), (2, 2)],
    )]
    return out


def game_family() -> list[Drill]:
    """Real shapes: an arc and a centre forward at 2.5-3 m against defenders
    goal-side of their men, and a shot from inside 7 m. They used to stand
    in two rings and shoot from twelve metres."""
    out = []
    games = {
        3: dict(home=[(5.0, 6.6), (15.0, 6.6), (11.6, TWO_M_SET)],
                away=[(6.4, 5.0), (13.4, 5.2), (13.2, 1.9)],
                ball=0,
                moves={1: [(14.6, 7.2, 0)], 2: [(11.9, 3.3, 1)]},
                amoves={1: [(13.4, 5.8, 0)], 2: [(12.8, 2.2, 1)]},
                gk=[(9.3, 1.1, 1)],
                route=[(1, 0), (2, 1), (SHOT_R, 2)]),
        4: dict(home=[(10.0, 8.2), (3.6, 5.0), (15.4, 6.2), (8.4, TWO_M_SET)],
                away=[(11.4, 6.6), (5.0, 3.6), (14.0, 4.8), (6.8, 1.9)],
                ball=0,
                moves={2: [(15.2, 6.8, 0), (12.8, 5.0, 1)]},
                amoves={2: [(14.0, 5.4, 0), (14.2, 5.8, 1)],
                        0: [(11.6, 6.2, 1)]},
                gk=[(10.9, 1.1, 1)],
                route=[(2, 0), (2, 1), (SHOT_L, 2)]),
        6: dict(home=[(10.0, 8.4), (5.4, 6.8), (14.6, 6.8), (2.0, 4.2),
                      (18.0, 4.2), (8.4, TWO_M_SET)],
                away=[(11.4, 7.0), (6.8, 5.3), (13.2, 5.3), (3.4, 2.8),
                      (16.6, 2.8), (6.8, 1.8)],
                ball=0,
                moves={1: [(5.2, 7.4, 0)], 3: [(2.6, 4.8, 1)],
                       5: [(8.0, 3.3, 2)]},
                amoves={1: [(6.8, 5.8, 0)], 3: [(3.8, 3.4, 1)],
                        5: [(6.8, 2.2, 2)]},
                gk=[(10.9, 1.1, 2)],
                route=[(1, 0), (3, 1), (5, 2), (SHOT_L, 3)]),
    }
    for n in (3, 4, 6):
        g = games[n]
        home = [pl(x, y, str(i + 1), g["moves"].get(i, []))
                for i, (x, y) in enumerate(g["home"])]
        away = [pl(x, y, chr(65 + i), g["amoves"].get(i, []))
                for i, (x, y) in enumerate(g["away"])]
        away.append(keeper(moves=g["gk"]))
        out.append(Drill(
            id=f"wp_game_{n}v{n}", category="ssg", minutes=15, rel=True,
            tight=True,          # each has a centre at two metres
            free=(n == 4),
            name=suffixed(GAME_NAME, f"{n}v{n}"), note=GAME_NOTE,
            home=home, away=away, ball=g["ball"], ball_to=g["route"],
        ))
    return out


def gaps_family() -> list[Drill]:
    """Perimeter shooting and goalkeeping.

    The shooter shoots from where he is — he no longer swims after the ball
    onto the keeper — and the shot goes into the corner away from the block
    and the keeper, so it is seen arriving in the goal.
    """
    out = []
    shots = {
        # skip: from the right flat, carried in, skipped low across to the
        # far corner past a block on the near side.
        "skip": dict(lvl="foundation", label="the skip shot",
                     home=[pl(12.6, 7.0, "1", [(12.0, 6.0, 0)], why={0: "to_goal"})],
                     d=pl(13.8, 5.2, "D", [(13.0, 4.6, 0)]),
                     gk=[(10.9, 1.1, 0)], ball=0,
                     route=[(0, 0), (SHOT_L, 1)], shot=SHOT_L),
        # power: from the point, a metre's lift, over a block from the left.
        "power_point": dict(lvl="development", label="the power shot from the point",
                            home=[pl(10.0, 8.4, "1", [(10.2, 7.6, 0)])],
                            d=pl(8.6, 6.4, "D", [(9.0, 6.8, 0)]),
                            gk=[(9.1, 1.1, 0)], ball=0,
                            route=[(0, 0), (SHOT_R, 1)], shot=SHOT_R),
        # lob: from the left wing over a keeper drawn to the near post.
        "lob": dict(lvl="development", label="the lob",
                    home=[pl(3.0, 5.2, "1", [(3.6, 4.6, 0)])],
                    d=pl(4.4, 3.4, "D", [(4.8, 3.6, 0)]),
                    gk=[(9.1, 1.1, 0)], ball=0,
                    route=[(0, 0), (SHOT_R, 1)], shot=SHOT_R),
        # catch and shoot: the point passes, the flat shoots on the catch.
        "catch_and_shoot": dict(lvl="development", label="catch and shoot",
                                home=[pl(14.6, 6.6, "1", [(14.2, 6.0, 0)],
                                         why={0: "get_free"}),
                                      pl(10.0, 8.6, "2")],
                                d=pl(13.0, 4.8, "D", [(13.4, 5.4, 0)]),
                                gk=[(10.9, 1.1, 0)], ball=1,
                                route=[(0, 0), (SHOT_L, 1)], shot=SHOT_L),
    }
    for key in ("skip", "power_point", "lob", "catch_and_shoot"):
        s = shots[key]
        out.append(Drill(
            id=f"wp_shot_{key}", category="finishing", minutes=10, rel=True,
            level=s["lvl"], free=(key == "skip"),
            name=suffixed(SHOOT_NAME, s["label"]), note=SHOOT_NOTE,
            home=s["home"], away=[s["d"], keeper(moves=s["gk"])],
            markers=[mk(*_m(s["shot"]), "zone")],
            ball=s["ball"], ball_to=s["route"],
        ))

    # The keeper's four. angles and the two-metre shot end in his save — the
    # drill is his — and the penalty in his read of it.
    out.append(Drill(
        id="wp_gk_angles", category="goalkeeping", minutes=10, rel=True,
        level="foundation", free=True,
        name=suffixed(WP_GK_NAME, "angles"), note=WP_GK_NOTE,
        home=[pl(5.6, 6.6, "1"),
              pl(14.4, 6.6, "2", [(13.8, 5.8, 0)], why={0: "get_free"})],
        away=[keeper(moves=[(10.8, 1.1, 0)], why={0: "set_gk"})],
        ball=0,
        ball_to=[(1, 0), ("a0", 1)],
    ))
    out.append(Drill(
        id="wp_gk_two_metre", category="goalkeeping", minutes=10, rel=True,
        level="development", tight=True,
        name=suffixed(WP_GK_NAME, "the two-metre shot"), note=WP_GK_NOTE,
        home=[pl(10.6, 7.6, "1"),
              pl(8.4, TWO_M_SET, "CF", [(8.9, 2.5, 1)], why={1: "turn"})],
        away=[pl(7.2, 2.0, "D", [(7.8, 2.2, 1)]),
              keeper(10.6, 1.1, moves=[(10.4, 1.1, 1)], why={1: "set_gk"})],
        ball=0,
        ball_to=[(1, 0), ("a1", 2)],
    ))
    out.append(Drill(
        id="wp_gk_penalty", category="goalkeeping", minutes=10, rel=True,
        level="development",
        name=suffixed(WP_GK_NAME, "the five-metre penalty"), note=WP_GK_NOTE,
        # the next taker waits his turn outside the 5 m area
        home=[pl(10.0, 5.0, "1"), pl(14.6, 7.6, "2")],
        away=[keeper(10.0, 1.1, moves=[(10.8, 1.1, 0)])],
        markers=[mk(10.0, 5.0, "square")],
        ball=0,
        ball_to=[("a0", 0)],
    ))
    # The outlet: HIS ball. The keeper's team is the home side here, at the
    # bottom goal; the wings break and he hits the one his defender has not
    # gone with.
    out.append(Drill(
        id="wp_gk_outlet", category="goalkeeping", minutes=10, rel=True,
        level="development",
        name=suffixed(WP_GK_NAME, "the outlet that starts the counter"),
        note=WP_GK_NOTE,
        home=[keeper(10.0, 23.9),
              pl(3.0, 20.0, "1", [(2.6, 14.0, 0), (2.8, 11.5, 1)], why={0: "swim"}),
              pl(17.0, 20.0, "2", [(17.4, 14.0, 0), (17.2, 12.5, 1)], why={0: "swim"})],
        away=[pl(15.4, 17.6, "D", [(16.0, 12.6, 0), (16.2, 11.3, 1)])],
        ball=0,
        ball_to=[(1, 1)],
    ))
    return out


def water_polo_library() -> list[Drill]:
    drills = (warmup_family() + perimeter_family() + counter_family()
              + man_up_family() + centre_family() + defence_family()
              + setpiece_family() + game_family() + gaps_family())
    for d in drills:
        _auto_setup(d)
    return drills
