"""The water polo library.

Attacking upward, goal at y=0. Three lines matter: 2 m (y=0.067) where the
centre forward works, 5 m (y=0.167) where the outside shot lives, and half
(y=0.5) where a counter-attack is either already won or already lost.
"""
from .engine import Drill, M, P, ring, suffixed

GOAL = (0.50, 0.03)
TWO_M, FIVE_M, HALF = 0.067, 0.167, 0.50
CENTRE_FORWARD = (0.50, 0.09)
# The 6v6 perimeter, numbered the way a coach calls it: 1 point, 2/3 flats,
# 4/5 wings, plus the centre forward.
# Point ~8 m, flats ~6 m, wings wide and shallow. Authored at 11.4 / 9.3 /
# 5.7 m it left a three-metre dead band between the centre forward and the
# nearest perimeter player — exactly where the wing shot comes from.
PERIMETER = [(0.50, 0.265), (0.26, 0.215), (0.74, 0.215), (0.085, 0.135), (0.915, 0.135)]


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


def warmup_family() -> list[Drill]:
    specs = [("eggbeater", "eggbeater and pass"), ("swim_catch", "swim and catch"),
             ("wet_pass", "wet passing")]
    out = []
    for key, label in specs:
        if key == "eggbeater":
            spots = ring(4, 0.5, 0.40, 0.22, 0.10)
            home = [P(x, y, f"{i + 1}", moves=[(x + (0.5 - x) * 0.2, y, i % 2)])
                    for i, (x, y) in enumerate(spots)]
        elif key == "swim_catch":
            home = [P(0.30, 0.62, "1", moves=[(0.30, 0.36, 0), (0.36, 0.22, 1)]),
                    P(0.70, 0.62, "2", moves=[(0.70, 0.36, 0), (0.64, 0.22, 1)])]
        else:
            home = [P(0.36, 0.44, "1", moves=[(0.40, 0.36, 0)]),
                    P(0.64, 0.36, "2", moves=[(0.60, 0.44, 0)])]
        out.append(Drill(
            id=f"wp_warm_{key}", category="warmup", minutes=8, rel=True,
            free=(key in ("eggbeater", "wet_pass")),
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            home=home, ball=0,
            # wet passes back and forth, or fed to the swimmer's catch
            ball_to=([(1, 0), (0, 1)] if key != 'swim_catch' else [(1, 1)]),
        ))
    return out


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


def perimeter_family() -> list[Drill]:
    specs = [("circulation", "circulation"), ("with_centre", "through the centre"),
             ("drive_and_kick", "drive and kick")]
    out = []
    for key, label in specs:
        home = [P(x, y, str(i + 1),
                  moves=[(x + (0.5 - x) * 0.12, y - 0.03, i % 3)])
                for i, (x, y) in enumerate(PERIMETER)]
        if key != "circulation":
            home.append(P(*CENTRE_FORWARD, "CF", moves=[(0.40, TWO_M + 0.01, 1)]))
        if key == "drive_and_kick":
            home[1] = P(*PERIMETER[1], "2",
                        moves=[(0.34, 0.16, 1), (0.26, 0.33, 2)])
        out.append(Drill(
            id=f"wp_perimeter_{key}", category="possession", minutes=12, rel=True,
            free=(key in ("circulation", "with_centre")),
            name=suffixed(PERIM_NAME, label), note=PERIM_NOTE,
            home=home,
            away=[P(x, y - 0.05, "D", moves=[(x, y - 0.02, 0)]) for x, y in PERIMETER]
                 + [P(*GOAL, "GK", role="GK")],
            ball=0,
            # round the arc, and inside to the centre when he holds position
            ball_to=([(1, 0), (2, 1)] if key == 'circulation' else [(1, 0), (len(home) - 1, 1)]),
        ))
    return out


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


def man_up_family() -> list[Drill]:
    specs = [("four_two", "4-2", [(0.16, 0.08), (0.38, 0.07), (0.62, 0.07), (0.84, 0.08),
                                  (0.34, 0.24), (0.66, 0.24)]),
             ("three_three", "3-3", [(0.24, 0.08), (0.50, 0.07), (0.76, 0.08),
                                     (0.22, 0.26), (0.50, 0.28), (0.78, 0.26)]),
             # A real arc: wings on the 2 m at the posts, the next pair at
             # about 4 m, the top pair at 6 m, so no two can be covered by
             # one block. It used to be five in a flat row with a sixth man
             # stranded alone nine metres out.
             ("umbrella", "the umbrella", [(0.115, 0.075), (0.885, 0.075),
                                           (0.265, 0.145), (0.735, 0.145),
                                           (0.385, 0.215), (0.615, 0.215)])]
    out = []
    for key, label, spots in specs:
        out.append(Drill(
            id=f"wp_manup_{key}", category="attacking", minutes=12, rel=True,
# The man-up shapes are lines; opening them draws a different formation.
tight=True,
            free=(key in ("four_two", "three_three")),
            name=suffixed(MAN_UP_NAME, label), note=MAN_UP_NOTE,
            home=[P(x, y, str(i + 1),
                    moves=[(x + (0.5 - x) * 0.08, y - 0.01, i % 3)])
                  for i, (x, y) in enumerate(spots)],
            # In the seams, half a slot across from the attackers — directly
            # underneath them they stacked, and dead centre they sat on the GK.
            # Centred on the goal and sliding toward the ball. It used to sit
            # 1.4 m off-centre, away from the side the ball was always on, so
            # the near wing had nobody outside him at all.
            away=[P(0.5 + (i - 2) * 0.135, 0.058, "D",
                    moves=[(0.5 + (i - 2) * 0.125 - 0.03, 0.072, 1)])
                  for i in range(5)]
                 + [P(*GOAL, "GK", role="GK", moves=[(0.44, 0.05, 2)])],
            ball=0,
            # swung across the umbrella faster than the four can slide
            ball_to=[(1, 0), (2, 1), (3, 2)],
        ))
    return out


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


def centre_family() -> list[Drill]:
    # Four boards that were two pairs of duplicates, none of which drew a
    # shot: the entry and the exclusion differed by 0.3 m, and the backhand
    # and the sweep were mirror images. A backhand turns to the outside
    # shoulder and a sweep carries the ball across the body — so each now
    # turns a different way, against a defender on a different side, and
    # ends with a line into a corner of the goal.
    # (key, label, centre's spot, which side the defender holds, target)
    specs = [("entry", "the entry pass", (0.50, 0.095), -1, (0.395, 0.035)),
             ("backhand", "the backhand", (0.44, 0.085), -1, (0.615, 0.035)),
             ("sweep", "the sweep shot", (0.56, 0.085), 1, (0.375, 0.035)),
             ("draw_foul", "drawing the exclusion", (0.50, 0.115), 1, None)]
    out = []
    for key, label, spot, side, target in specs:
        turn = (spot[0] - 0.075 * side, TWO_M - 0.005)
        out.append(Drill(
            id=f"wp_centre_{key}", category="finishing", minutes=10, rel=True,
# The man-up shapes are lines; opening them draws a different formation.
tight=True,
            free=(key in ("entry", "backhand")),
            name=suffixed(CENTRE_NAME, label), note=CENTRE_NOTE,
            home=[P(0.50, 0.265, "1", moves=[(0.455, 0.235, 0)]),
                  P(*spot, "CF",
                    moves=[turn + (1,)] + ([] if target is None
                                           else [(target[0], target[1] + 0.03, 2)]))],
            away=[P(spot[0] + 0.055 * side, spot[1] - 0.03, "D",
                    moves=[(spot[0] + 0.03 * side, spot[1] - 0.015, 1)]),
                  P(*GOAL, "GK", role="GK",
                    moves=[((target or (0.44, 0.05))[0], 0.05, 2)])],
            markers=[M(0.50, TWO_M, "cone", ""), M(0.50, FIVE_M, "cone", "")]
                    + ([] if target is None else [M(*target, "zone", "")]),
            ball=0,
            # entered to the centre; he turns and finishes at the marked spot
            ball_to=[(1, 0)] + ([] if target is None else [(1, 1), ((target[0], 0.03), 2)]),
        ))
    return out


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


def defence_family() -> list[Drill]:
    # front-the-centre is a real step, not zero: the whole point of the
    # scheme is the defender moving ball-side of the centre forward.
    specs = [("press", "pressing", 0.04), ("drop", "dropping off", -0.06),
             ("front_the_centre", "fronting the centre", 0.035),
             ("five_on_six", "five against six", -0.02)]
    out = []
    for key, label, push in specs:
        away = [P(x, y, "D", moves=[(x, y + push, 0)]) for x, y in PERIMETER]
        if key == "five_on_six":
            # A man-down is defended as a zone, not man-to-man on the
            # perimeter — and it is five field defenders, not four. Four
            # across the 2 m line, one out, sliding with the ball.
            away = [P(0.5 + (i - 1.5) * 0.17, TWO_M + 0.02, "D",
                      moves=[(0.5 + (i - 1.5) * 0.15, TWO_M + 0.035, 0)])
                    for i in range(4)]
            away.append(P(0.42, 0.175, "D", moves=[(0.34, 0.16, 0)]))
        else:
            # The hole-D. Every one of these boards drew five defenders on
            # five perimeter attackers and left the centre forward — the
            # player the note is entirely about — unmarked.
            hole_y = CENTRE_FORWARD[1] - 0.035 if key == "front_the_centre" \
                else CENTRE_FORWARD[1] + 0.035
            away.append(P(CENTRE_FORWARD[0] - 0.03, hole_y, "H",
                          moves=[(CENTRE_FORWARD[0] + 0.02,
                                  hole_y + (push * 0.5), 1)]))
        away.append(P(*GOAL, "GK", role="GK"))
        out.append(Drill(
            id=f"wp_defence_{key}", category="defending", minutes=12, rel=True,
            free=(key in ("press", "drop")),
            name=suffixed(DEF_NAME, label), note=DEF_NOTE,
            home=[P(x, y + 0.05, str(i + 1), moves=[(x, y + 0.02, 0)])
                  for i, (x, y) in enumerate(PERIMETER)]
                 + [P(*CENTRE_FORWARD, "CF", moves=[(0.44, TWO_M + 0.01, 1)])],
            away=away,
            markers=[M(0.50, TWO_M, "cone", ""), M(0.50, FIVE_M, "cone", "")],
            ball=0,
            # their swing into the hole set — the ball the system answers.
            # Five on the perimeter, the CF is the sixth man (index 5).
            ball_to=[(1, 0), (5, 1)],
        ))
    return out


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


def counter_family() -> list[Drill]:
    out = []
    for n in (2, 3, 4):
        starts = [(0.14, 0.72), (0.86, 0.72), (0.36, 0.80), (0.64, 0.80)][:n]
        out.append(Drill(
            id=f"wp_counter_{n}v{n - 1}", category="attacking", minutes=10,
            rel=True, free=(n == 3),
            name=suffixed(COUNTER_NAME, f"{n}v{n - 1}"), note=COUNTER_NOTE,
            home=[P(x, y, str(i + 1),
                    moves=[(x + (0.5 - x) * 0.12, 0.36, 0), (x + (0.5 - x) * 0.12, 0.12, 1)])
                  for i, (x, y) in enumerate(starts)],
            away=[P(0.5 + (i - (n - 2) / 2) * 0.18, 0.22, "D",
                    moves=[(0.5 + (i - (n - 2) / 2) * 0.16, 0.12, 1)])
                  for i in range(n - 1)]
                 + [P(*GOAL, "GK", role="GK")],
            ball=0,
            # carried up the pool, laid across, finished
            ball_to=[(0, 0), (1 % n, 1), ((0.50, 0.04), 1)],
        ))
    return out


SET_NAME = {
    "en": "Restart", "en-GB": "Restart", "zh-CN": "死球恢复",
    "zh-TW": "死球恢復", "ja-JP": "リスタート", "ko-KR": "리스타트",
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


def setpiece_family() -> list[Drill]:
    out = [Drill(
        id="wp_set_penalty", category="setpiece", minutes=6, rel=True, free=True,
        name=suffixed(SET_NAME, "the five-metre penalty"), note=SET_NOTE,
        home=[P(0.50, FIVE_M, "S", moves=[(0.50, FIVE_M - 0.02, 0)])],
        away=[P(*GOAL, "GK", role="GK", moves=[(0.42, 0.05, 1)])],
        markers=[M(0.50, FIVE_M, "square", "")],
        ball=0,
            # five metres: one strike
            ball_to=[((0.42, 0.04), 1)],
    ), Drill(
        id="wp_set_free_throw", category="setpiece", minutes=8, rel=True,
        name=suffixed(SET_NAME, "the quick free throw"), note=SET_NOTE,
        home=[P(0.24, 0.30, "1", moves=[(0.28, 0.26, 0)]),
              P(*CENTRE_FORWARD, "CF", moves=[(0.40, TWO_M, 1)]),
              P(0.68, 0.28, "3", moves=[(0.60, 0.16, 1)])],
        away=[P(0.34, 0.24, "D"), P(0.56, 0.14, "D"), P(*GOAL, "GK", role="GK")],
        ball=0,
            # taken quickly to the 3 breaking before the defence sets
            ball_to=[(2, 1), ((0.50, 0.04), 2)],
    ), Drill(
        id="wp_set_swim_off", category="setpiece", minutes=6, rel=True, free=True,
        name=suffixed(SET_NAME, "the swim-off"), note=SET_NOTE,
        home=[P(0.50, 0.94, "1", moves=[(0.50, 0.54, 0)]),
              P(0.22, 0.94, "2", moves=[(0.26, 0.62, 0)]),
              P(0.78, 0.94, "3", moves=[(0.74, 0.62, 0)])],
        away=[P(0.50, 0.06, "A", moves=[(0.50, 0.46, 0)])],
        ball=(0.50, 0.50),
            # the sprint decides it — first hand on the ball takes it forward
            ball_to=[(0, 1)],
    )]
    return out


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


def game_family() -> list[Drill]:
    out = []
    for n in (3, 4, 6):
        spots = ring(n, 0.5, 0.30, 0.28, 0.10)
        out.append(Drill(
            id=f"wp_game_{n}v{n}", category="ssg", minutes=15, rel=True,
            free=(n == 4),
            name=suffixed(GAME_NAME, f"{n}v{n}"), note=GAME_NOTE,
            home=[P(x, y + 0.10, str(i + 1), moves=[(x, y + 0.04, 0)])
                  for i, (x, y) in enumerate(spots)],
            away=[P(x, y - 0.06, chr(65 + i), moves=[(x, y - 0.01, 0)])
                  for i, (x, y) in enumerate(spots)]
                 + [P(*GOAL, "GK", role="GK")],
            ball=0,
            # two passes round the ring under pressure
            ball_to=[(1 % n, 0), (2 % n, 0)],
        ))
    return out


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
    "fr-FR": "Sors les hanches de l eau avant que le bras parte, et choisis l angle en fonction du contre, pas du gardien. Un tir corps bas est une passe au gardien.",
    "id-ID": "Angkat pinggul dari air sebelum lengan diayun, dan pilih sudut dari bloknya, bukan dari kipernya.",
    "ms-MY": "Angkat pinggul dari air sebelum lengan dihayun, dan pilih sudut dari blok, bukan dari penjaga gol.",
    "th-TH": "ยกสะโพกพ้นน้ำก่อนเหวี่ยงแขน และเลือกมุมจากบล็อก ไม่ใช่จากผู้รักษาประตู",
    "vi-VN": "Nang hong len khoi mat nuoc truoc khi vung tay, va chon goc theo hang chan chu khong theo thu mon.",
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
    "fr-FR": "Monte assez haut pour avoir les épaules hors de l eau avant le tir, et garde le premier poteau jusqu à ce que le ballon quitte la main.",
    "id-ID": "Kayuh cukup tinggi agar bahu keluar dari air sebelum tembakan, dan jaga tiang dekat sampai bola lepas dari tangan.",
    "ms-MY": "Kayuh cukup tinggi supaya bahu keluar dari air sebelum tembakan, dan jaga tiang dekat sehingga bola lepas.",
    "th-TH": "ตีขาให้สูงพอจนไหล่พ้นน้ำก่อนลูกยิง และรักษาเสาใกล้ไว้จนบอลหลุดจากมือ",
    "vi-VN": "Dap chan du cao de vai nho khoi mat nuoc truoc cu sut, va giu cot gan cho den khi bong roi tay.",
}


def gaps_family() -> list[Drill]:
    """Perimeter shooting and goalkeeping, neither of which existed.

    Every shot in the library was taken by the centre forward from two
    metres, and the goalkeeper was a stationary dot on twenty-two boards
    with no drill of his own — while DrillCategory.goalkeeping already
    existed and water polo used none of it.
    """
    out = []
    shots = [("skip", "the skip shot", (0.50, 0.245), (0.615, 0.035), "foundation"),
             ("power_point", "the power shot from the point", (0.50, 0.265), (0.375, 0.035), "development"),
             ("lob", "the lob", (0.135, 0.175), (0.665, 0.045), "development"),
             ("catch_and_shoot", "catch and shoot", (0.735, 0.215), (0.395, 0.035), "development")]
    for key, label, spot, target, lvl in shots:
        out.append(Drill(
            id=f"wp_shot_{key}", category="finishing", minutes=10, rel=True,
            level=lvl, free=(key == "skip"),
            name=suffixed(SHOOT_NAME, label), note=SHOOT_NOTE,
            home=[P(*spot, "1", moves=[(spot[0] + (0.5 - spot[0]) * 0.2,
                                        spot[1] - 0.045, 0),
                                       (target[0], target[1] + 0.05, 1)]),
                  P(0.5 + (0.5 - spot[0]) * 0.8, spot[1] + 0.03, "2",
                    moves=[(0.5 + (0.5 - spot[0]) * 0.6, spot[1] - 0.02, 0)])],
            away=[P(spot[0] + 0.045, spot[1] - 0.05, "D",
                    moves=[(spot[0] + 0.02, spot[1] - 0.08, 0)]),
                  P(*GOAL, "GK", role="GK", moves=[(target[0], 0.05, 1)])],
            markers=[M(0.50, TWO_M, "cone", ""), M(0.50, FIVE_M, "cone", ""),
                     M(*target, "zone", "")],
            ball=0,
            # carried in, and the shot goes for the marked corner
            ball_to=[(0, 0), ((target[0], 0.03), 1)],
        ))
    keepers = [("angles", "angles", "foundation",
                [P(0.29, 0.215, "1", moves=[(0.325, 0.175, 0)]),
                 P(0.71, 0.215, "2", moves=[(0.675, 0.175, 0)])], (0.395, 0.05)),
               ("two_metre", "the two-metre shot", "development",
                [P(0.44, 0.095, "1", moves=[(0.485, TWO_M - 0.005, 0)])], (0.545, 0.05)),
               ("penalty", "the five-metre penalty", "development",
                [P(0.50, FIVE_M, "1", moves=[(0.50, FIVE_M - 0.012, 0)])], (0.615, 0.05)),
               ("outlet", "the outlet that starts the counter", "development",
                [P(0.11, 0.30, "1", moves=[(0.10, 0.52, 1)]),
                 P(0.89, 0.30, "2", moves=[(0.90, 0.52, 1)])], (0.50, 0.10))]
    for key, label, lvl, home, gk in keepers:
        out.append(Drill(
            id=f"wp_gk_{key}", category="goalkeeping", minutes=10, rel=True,
            level=lvl, free=(key == "angles"),
            name=suffixed(WP_GK_NAME, label), note=WP_GK_NOTE,
            home=home,
            # On the goal line, which is where a keeper must be for a
            # five-metre penalty and where he starts for everything else.
            away=[P(0.50, 0.012, "GK", role="GK", moves=[gk + (1,)])],
            markers=[M(0.50, TWO_M, "cone", ""), M(0.50, FIVE_M, "cone", "")],
            ball=0,
            # the shot or the outlet the keeper's move answers
            ball_to=([((0.50, 0.03), 1)] if key != 'outlet' else [(0, 1)]),
        ))
    return out


def water_polo_library() -> list[Drill]:
    return (warmup_family() + perimeter_family() + counter_family()
            + man_up_family() + centre_family() + defence_family()
            + setpiece_family() + game_family() + gaps_family())
