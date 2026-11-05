"""The handball library.

Attacking upward, goal at y=0. The two lines that shape everything are the
6 m goal-area arc (y≈0.15) and the 9 m free-throw line (y≈0.23): the attack
lives between them and the defence decides how much of that band it gives up.
"""
from .engine import Drill, M, P, ring, suffixed

GOAL = (0.50, 0.02)
SIX, NINE, SEVEN_M = 0.155, 0.235, 0.175
# The six attacking positions, in the order a coach names them.
# A wing plays hard against the sideline and close to the 6 m line: that
# is the whole angle he has. Drawn 2 m infield and 2 m deeper, the wing
# shot the shooting family teaches is not available from where he stands.
LW, LB, CB, RB, RW = ((0.055, 0.185), (0.26, 0.31), (0.50, 0.34),
                      (0.74, 0.31), (0.945, 0.185))
# In a gap in the wall, not behind a defender. He cannot be drawn pressed
# against it: a 44pt icon is 3.3 m of a 20 m court, so six defenders and a
# pivot already fill the width — pushed together they overlap, and the
# spacing pass then walks a defender into the goal area. Standing in the
# gap between the third and fourth defender is the readable truth.
PIVOT = (0.632, 0.208)
BACKCOURT = (LB, CB, RB)

# The goal mouth: posts at 8.5 and 11.5 m across the 20 m court, the goal
# line at y = 0. A shot ends in the net — a metre inside a post, a quarter
# of a metre over the line. Every shot used to end at (10, 1.6 m), on the
# keeper's feet, and the shooting drills aimed at squares beside the frame.
GOAL_L, GOAL_R = (0.45, -0.006), (0.55, -0.006)
# The shaded target over a corner of the frame, its square inside the posts.
ZONE_L, ZONE_R = (0.47, -0.0125), (0.53, -0.0125)
# "Shoot here": resolved by aim_shots into the corner away from the shooter's
# side, once the board knows where the shooter stands.
SHOT = (0.50, 0.04)


def _m(xm: float, ym: float) -> tuple[float, float]:
    """Metres on the 20 x 40 m court to the court-relative units."""
    return (xm / 20.0, ym / 40.0)


def crescent(n: int, r: float = 6.6, half: float = 50.0,
             outward: float = 0.0) -> list[tuple[float, float]]:
    """n defenders spread evenly along the goal-area line, r metres out.

    The 6 m line is two quarter circles round the posts joined by the 3 m
    straight in front of the goal. A wall drawn as a straight row at 6.8 m
    put the outside defenders 3.6 m off the line, on the 9 m dashes; this
    follows the arc, from [half] degrees either side of straight out.
    ``outward`` pushes every point that many metres further out, radially.
    """
    import math
    r = r + outward
    arc = math.radians(half) * r
    total = 2 * arc + 3.0
    out = []
    for i in range(n):
        s = total * (i / (n - 1) if n > 1 else 0.5)
        if s <= arc:
            th = math.radians(90 + half) - s / r
            x, y = 8.5 + r * math.cos(th), r * math.sin(th)
        elif s <= arc + 3.0:
            x, y = 8.5 + (s - arc), r
        else:
            th = math.radians(90) - (s - arc - 3.0) / r
            x, y = 11.5 + r * math.cos(th), r * math.sin(th)
        out.append(_m(x, y))
    return out


def onto_arc(p, r: float = 6.8) -> tuple[float, float]:
    """The point on the r-metre crescent between [p] and the goal."""
    import math
    xm, ym = p[0] * 20, p[1] * 40
    if 8.5 <= xm <= 11.5:
        return _m(xm, r)
    px = 8.5 if xm < 8.5 else 11.5
    d = math.hypot(xm - px, ym) or 1.0
    return _m(px + (xm - px) * r / d, ym * r / d)


def aim_shots(drills) -> None:
    """Every SHOT target becomes a corner of the goal mouth.

    The far corner from the shooter's side — a wing or a back on the left
    shoots across the keeper to the right-hand post, and the reverse. A
    shooter in the middle goes to the left.
    """
    from .engine import _pos_at
    for d in drills:
        legs = list(d.ball_to)
        for k, (t, ph) in enumerate(legs):
            if t != SHOT:
                continue
            prev = legs[k - 1][0] if k else d.ball
            if isinstance(prev, int):
                sx = _pos_at(d.home[prev], ph)[0]
            elif isinstance(prev, str):
                sx = _pos_at(d.away[int(prev[1:])], ph)[0]
            else:
                sx = prev[0]
            legs[k] = (GOAL_R if sx < 0.45 else GOAL_L, ph)
        d.ball_to = legs


def defence_line(n: int, y: float, spread: float = 0.66) -> list[tuple[float, float]]:
    """n defenders evenly across the goal area, the shape of a flat wall."""
    if n == 1:
        return [(0.5, y)]
    return [(0.5 - spread / 2 + spread * i / (n - 1), y) for i in range(n)]


WARM_NAME = {
    "en": "Warm-up", "en-GB": "Warm-up", "zh-CN": "热身", "zh-TW": "熱身",
    "ja-JP": "ウォームアップ", "ko-KR": "웜업", "es-ES": "Calentamiento",
    "fr-FR": "Échauffement", "id-ID": "Pemanasan", "ms-MY": "Memanaskan badan",
    "th-TH": "วอร์มอัพ", "vi-VN": "Khởi động",
}
WARM_NOTE = {
    "en": "Catch with the arm already cocked. A player who catches, then "
          "loads, then throws has given the defence a whole extra second.",
    "en-GB": "Catch with the arm already cocked. A player who catches, then "
             "loads, then throws has given the defence a whole extra second.",
    "zh-CN": "接球时手臂已经举好。先接、再举、再传的球员，等于白送给防守整整一秒。",
    "zh-TW": "接球時手臂已經舉好。先接、再舉、再傳的球員，等於白送給防守整整一秒。",
    "ja-JP": "腕を上げた状態で捕る。捕ってから振りかぶって投げる選手は、守備に丸1秒を献上している。",
    "ko-KR": "팔을 이미 든 채로 잡아라. 잡고 나서 들고 던지는 선수는 수비에 1초를 그냥 준다.",
    "es-ES": "Recibe con el brazo ya armado: quien recibe, arma y luego lanza "
             "le regala a la defensa un segundo entero.",
    "fr-FR": "Réceptionne bras déjà armé : celui qui attrape, arme puis tire "
             "offre une seconde entière à la défense.",
    "id-ID": "Tangkap dengan lengan sudah terangkat.",
    "ms-MY": "Tangkap dengan lengan sudah terangkat.",
    "th-TH": "รับบอลโดยยกแขนเตรียมไว้แล้ว",
    "vi-VN": "Bắt bóng với tay đã giơ sẵn.",
}


def warmup_family() -> list[Drill]:
    specs = [("star_passing", "star passing"), ("three_lane", "three lanes"),
             ("keeper", "with the keeper")]
    out = []
    for key, label in specs:
        if key == "star_passing":
            # Clear of halfway: centred at 14 m, the two bottom points of
            # the star stood on the halfway line.
            spots = ring(5, 0.5, 0.36, 0.26, 0.12)
            # A beat each, round the star — not `i % 2`. The ball makes five
            # passes, one a beat, and each player steps in on the beat the
            # pass is travelling to him. The passes go ACROSS the ring —
            # 1 to 3 to 5 to 2 to 4 and home — which is what draws the star;
            # passing to the next man round drew a circle.
            beat = {2: 0, 4: 1, 1: 2, 3: 3, 0: 4}
            home = [P(x, y, f"{i + 1}",
                      moves=[(x + (0.5 - x) * 0.2, y, beat[i])])
                    for i, (x, y) in enumerate(spots)]
            away = []
        elif key == "three_lane":
            home = [P(0.20, 0.60, "1", moves=[(0.20, 0.30, 0), (0.34, 0.22, 1)]),
                    P(0.50, 0.60, "2", moves=[(0.50, 0.32, 0), (0.50, 0.20, 1)]),
                    P(0.80, 0.60, "3", moves=[(0.80, 0.30, 0), (0.66, 0.22, 1)])]
            away = []
        else:
            home = [P(0.30, 0.34, "1", moves=[(0.34, 0.28, 0)]),
                    P(0.70, 0.34, "2", moves=[(0.66, 0.28, 0)])]
            away = [P(*GOAL, "GK", role="GK", moves=[(0.42, 0.06, 1)])]
        out.append(Drill(
            id=f"hb_warm_{key}", category="warmup", minutes=8, rel=True,
            free=(key == "star_passing"),
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            home=home, away=away, ball=0,
            # round the ring, or fed and finished when a keeper stands
            # The star goes round and back to the man it started with; the
            # three lanes finish on the middle man's shot. Two passes and a
            # stop was a diagram of a triangle.
            ball_to=(([(2, 0), (4, 1), (1, 2), (3, 3), (0, 4)] if key == "star_passing"
                      else [(1, 0), (2, 1), ((0.50, 0.04), 2)])
                     if not away else [(1, 0), ((0.50, 0.04), 1)]),
        ))
    return out


CIRC_NAME = {
    "en": "Circulation", "en-GB": "Circulation", "zh-CN": "球的转移",
    "zh-TW": "球的轉移", "ja-JP": "ボール回し", "ko-KR": "볼 순환",
    "es-ES": "Circulación", "fr-FR": "Circulation",
    "id-ID": "Sirkulasi bola", "ms-MY": "Peredaran bola",
    "th-TH": "การหมุนบอล", "vi-VN": "Luân chuyển bóng",
}
CIRC_NOTE = {
    "en": "Pass and step toward the goal, not sideways. Circulation that never "
          "threatens the 9 m line lets six defenders stand still all attack.",
    "en-GB": "Pass and step toward the goal, not sideways. Circulation that "
             "never threatens the 9 m line lets six defenders stand still all attack.",
    "zh-CN": "传完球往球门方向迈一步，不要横着走。从不威胁 9 米线的转移，会让六个防守队员整场站着不动。",
    "zh-TW": "傳完球往球門方向邁一步，不要橫著走。從不威脅 9 米線的轉移，會讓六個防守隊員整場站著不動。",
    "ja-JP": "パスしたら横ではなくゴール方向へ一歩。9mラインを脅かさない回しは、6人の守備を立たせたままにする。",
    "ko-KR": "패스하고 옆이 아니라 골 쪽으로 한 발. 9m 라인을 위협하지 않는 순환은 수비 여섯을 세워둔다.",
    "es-ES": "Pasa y da un paso hacia la portería, no de lado: una circulación "
             "que nunca amenaza los 9 m deja a seis defensores quietos.",
    "fr-FR": "Passe puis avance vers le but, pas latéralement : une circulation "
             "qui ne menace jamais les 9 m laisse six défenseurs immobiles.",
    "id-ID": "Umpan lalu melangkah ke arah gawang, bukan menyamping.",
    "ms-MY": "Hantar dan melangkah ke arah gol, bukan ke tepi.",
    "th-TH": "จ่ายแล้วก้าวไปทางประตู ไม่ใช่ก้าวข้าง",
    "vi-VN": "Chuyền rồi bước về phía khung thành, không đi ngang.",
}


def circulation_family() -> list[Drill]:
    # Not "second wave": the fast-break family uses first/second/third wave
    # for the counter-attack, and a back-court player joining a set attack
    # is a different thing with a different name.
    specs = [("wide", "wide to wide"), ("with_pivot", "through the pivot"),
             ("second_wave", "with a late runner")]
    out = []
    for key, label in specs:
        # The wings had no movement at all in a drill called "wide to wide" —
        # the ball is supposed to reach them. They come to meet it and go
        # back to the line, at the two ends of the circulation.
        home = [P(*LW, "LW", moves=[(0.09, 0.215, 0), (0.055, 0.185, 1)]),
                P(*LB, "LB", moves=[(LB[0] + 0.04, LB[1] - 0.05, 0)]),
                P(*CB, "CB", moves=[(CB[0], CB[1] - 0.05, 1)]),
                P(*RB, "RB", moves=[(RB[0] - 0.04, RB[1] - 0.05, 2)]),
                P(*RW, "RW", moves=[(0.91, 0.215, 2), (0.945, 0.185, 3)])]
        if key != "wide":
            # Through the pivot, he shows for the ball in front of the CB;
            # with a late runner, he holds his screen in the left gap.
            home.append(P(*PIVOT, "PIV", moves=[
                (0.55, SIX + 0.03, 1) if key == "with_pivot"
                else (0.36, SIX + 0.02, 1)]))
        if key == "second_wave":
            # The late runner arrives from deep into the space the swing
            # opened and is the one who gets the ball and shoots over the
            # wall — he used to run in after the ball had gone past him.
            home.append(P(0.50, 0.52, "6", moves=[(0.42, 0.27, 2)]))
        out.append(Drill(
            id=f"hb_circulation_{key}", category="possession", minutes=12,
            rel=True, free=(key == "with_pivot"),
            name=suffixed(CIRC_NAME, label), note=CIRC_NOTE,
            home=home,
            away=[P(x, y, "D") for x, y in crescent(6)]
                 + [P(*GOAL, "GK", role="GK")],
            ball=1,
            # swung along the back line and out to the flying wing; or in
            # to the pivot, who lays it off; or to the late runner
            ball_to={"wide": [(2, 0), (3, 1), (4, 2)],
                     "with_pivot": [(2, 0), (5, 1), (3, 2), (4, 3)],
                     "second_wave": [(2, 0), (3, 1), (6, 2)]}[key],
        ))
    return out


ATTACK_NAME = {
    "en": "Attack", "en-GB": "Attack", "zh-CN": "进攻配合", "zh-TW": "進攻配合",
    "ja-JP": "攻撃", "ko-KR": "공격", "es-ES": "Ataque", "fr-FR": "Attaque",
    "id-ID": "Serangan", "ms-MY": "Serangan", "th-TH": "การบุก", "vi-VN": "Tấn công",
}
ATTACK_NOTE = {
    "en": "Attack the defender's outside shoulder, then cross. A crossing move "
          "that starts from standing still moves nobody.",
    "en-GB": "Attack the defender's outside shoulder, then cross. A crossing "
             "move that starts from standing still moves nobody.",
    "zh-CN": "先冲防守人的外侧肩，再交叉。从站着不动开始的交叉换位，谁也调动不了。",
    "zh-TW": "先衝防守人的外側肩，再交叉。從站著不動開始的交叉換位，誰也調動不了。",
    "ja-JP": "まず守備の外側の肩を攻め、それからクロス。止まった状態から始まるクロスは誰も動かせない。",
    "ko-KR": "수비의 바깥쪽 어깨를 먼저 공략한 뒤 교차하라. 멈춘 채 시작하는 교차는 아무도 못 움직인다.",
    "es-ES": "Ataca el hombro exterior del defensor y luego cruza: un cruce que "
             "empieza parado no mueve a nadie.",
    "fr-FR": "Attaque l'épaule extérieure du défenseur, puis croise : un croisé "
             "démarré à l'arrêt ne déplace personne.",
    "id-ID": "Serang bahu luar bek, lalu menyilang.",
    "ms-MY": "Serang bahu luar pemain bertahan, kemudian bersilang.",
    "th-TH": "บุกไหล่ด้านนอกของกองหลังก่อน แล้วค่อยไขว้",
    "vi-VN": "Tấn công vai ngoài của hậu vệ rồi mới cắt chéo.",
}


def attack_family() -> list[Drill]:
    """Five moves, each drawn as the thing it is.

    They used to share one template: two named players swapped positions,
    whatever the move was called. So the "overload" produced no overload —
    the left back and the left wing changed ends and the side was still
    two against two — the "cross" was a full-width swap through a standing
    centre back, and the screener left before the runner arrived.
    """
    def board(key, label, home, free=False):
        return Drill(
            id=f"hb_attack_{key}", category="attacking", minutes=12, rel=True,
            free=free,
            name=suffixed(ATTACK_NAME, label), note=ATTACK_NOTE,
            home=home,
            away=[P(x, y, "D") for x, y in crescent(6)]
                 + [P(*GOAL, "GK", role="GK")],
            ball=0,
            # the entry pass, and the strike the move earns
            ball_to=[(1, 0), ((0.50, 0.04), 2)],
        )

    return [
        # Adjacent backs, two or three metres, both at the same defender's
        # outside shoulder — not the two ends of the court changing places.
        board("cross_backs", "crossing the backs", free=True, home=[
            P(*LB, "LB", moves=[(0.34, 0.275, 0), (0.42, 0.245, 1)]),
            P(*CB, "CB", moves=[(0.42, 0.305, 0), (0.30, 0.255, 1)]),
            P(*RB, "RB"), P(*LW, "LW"), P(*RW, "RW"), P(*PIVOT, "PIV"),
        ]),
        # The break-in ends ON the 6 m line as a second pivot; it used to
        # end at the left back's spot, seven metres out.
        board("wing_break", "the wing break-in", free=True, home=[
            P(*LW, "LW", moves=[(0.11, 0.185, 0), (0.235, SIX + 0.008, 1)]),
            P(*LB, "LB", moves=[(0.30, 0.275, 0)]),
            P(*CB, "CB"), P(*RB, "RB"), P(*RW, "RW"), P(*PIVOT, "PIV"),
        ]),
        # A screen is held. The pivot steps into the defender and stays
        # there while the runner comes off his shoulder.
        board("pivot_screen", "off the pivot's screen", home=[
            P(*PIVOT, "PIV", moves=[(0.60, 0.196, 0)]),
            P(*CB, "CB", moves=[(0.56, 0.285, 0), (0.635, 0.235, 1)]),
            P(*LW, "LW"), P(*LB, "LB"), P(*RB, "RB"), P(*RW, "RW"),
        ]),
        # An overload is a third attacker arriving, so the side is three
        # against two. Swapping the two who were already there is not one.
        board("overload_left", "overloading the left", home=[
            P(*CB, "CB", moves=[(0.34, 0.315, 0), (0.215, 0.255, 1)]),
            P(*LB, "LB", moves=[(0.22, 0.285, 1)]),
            P(*LW, "LW"), P(*RB, "RB"), P(*RW, "RW"),
            P(*PIVOT, "PIV", moves=[(0.40, 0.20, 1)]),
        ]),
        # Seven against six needs seven attackers. It had six: the left
        # back was missing, and so was the empty goal that is the whole
        # risk of playing the system.
        board("empty_goal", "seven against six", home=[
            P(*LW, "LW"), P(*LB, "LB", moves=[(0.30, 0.27, 1)]),
            P(*CB, "CB", moves=[(0.50, 0.29, 0)]),
            P(*RB, "RB"), P(*RW, "RW"), P(*PIVOT, "PIV"),
            P(0.50, 0.62, "7", moves=[(0.44, 0.40, 1), (0.40, 0.30, 2)]),
        ]),
    ]


SHOT_NAME = {
    "en": "Shooting", "en-GB": "Shooting", "zh-CN": "射门", "zh-TW": "射門",
    "ja-JP": "シュート", "ko-KR": "슛", "es-ES": "Lanzamiento",
    "fr-FR": "Tir", "id-ID": "Tembakan", "ms-MY": "Tembakan",
    "th-TH": "การยิงประตู", "vi-VN": "Dứt điểm",
}
SHOT_NOTE = {
    "en": "Look at the keeper's feet, not the goal. Where their weight already "
          "is tells you which corner is actually open.",
    "en-GB": "Look at the keeper's feet, not the goal. Where their weight "
             "already is tells you which corner is actually open.",
    "zh-CN": "看门将的脚，不是看球门。他重心已经在哪一侧，就告诉了你哪个角是真的空的。",
    "zh-TW": "看門將的腳，不是看球門。他重心已經在哪一側，就告訴了你哪個角是真的空的。",
    "ja-JP": "ゴールではなくGKの足を見る。体重が既にどちらへ乗っているかが、本当に空いている隅を教えてくれる。",
    "ko-KR": "골대가 아니라 골키퍼의 발을 봐라. 체중이 실린 방향이 열린 구석을 알려준다.",
    "es-ES": "Mira los pies del portero, no la portería: donde ya está su peso "
             "te dice qué esquina está de verdad abierta.",
    "fr-FR": "Regarde les appuis du gardien, pas le but : là où son poids est "
             "déjà te dit quel angle est vraiment ouvert.",
    "id-ID": "Lihat kaki kiper, bukan gawangnya.",
    "ms-MY": "Lihat kaki penjaga gol, bukan gol.",
    "th-TH": "ดูเท้าผู้รักษาประตู ไม่ใช่ดูประตู",
    "vi-VN": "Nhìn chân thủ môn, đừng nhìn khung thành.",
}


def shooting_family() -> list[Drill]:
    # Each shot is defined by where it is released, so each one says so. The
    # first version sent every shooter to the same spot 1 m in front of the
    # goal area: the "9 m jump shot" was released at 7.4 m and the wing
    # abandoned his angle and shot from the middle, which is the one thing
    # a wing shot is not.
    specs = [
        # key, label, start, release, the corner it goes in, its zone.
        # Each one into the net between the posts — they used to be aimed
        # at squares beside the frame, 1.2 m out inside the goal area.
        ("jump_nine", "the jump shot from 9 m", CB, (0.50, NINE), GOAL_L, ZONE_L),
        ("wing_angle", "from the wing angle", LW, (0.045, SIX - 0.01), GOAL_R, ZONE_R),
        ("pivot_turn", "the pivot's turn", PIVOT, (0.60, SIX + 0.005), GOAL_L, ZONE_L),
        ("break_through", "after breaking through", LB, (0.34, SIX + 0.02), GOAL_R, ZONE_R),
    ]
    out = []
    for key, label, frm, release, target, zone in specs:
        # Goal-side of the shooter and toward the middle, so a wing's marker
        # never ends up off the sideline.
        dx = 0.06 if frm[0] < 0.5 else -0.06
        out.append(Drill(
            id=f"hb_shot_{key}", category="finishing", minutes=10, rel=True,
            free=(key in ("jump_nine", "wing_angle")),
            name=suffixed(SHOT_NAME, label), note=SHOT_NOTE,
            home=[P(*frm, "S", moves=[release + (0,)])],
            # The keeper's weight goes the wrong way: he leans to the
            # other post, which is the corner the shooter reads open.
            away=[P(*GOAL, "GK", role="GK", moves=[(1.0 - target[0] * 0.5 - 0.25, 0.05, 1)]),
                  P(frm[0] + dx, SIX + 0.03, "D",
                    moves=[(release[0] + dx * 0.6, SIX + 0.045, 0)])],
            markers=[M(*zone, "zone", "")],
            ball=0,
            # carried into the release point, struck at the marked corner
            ball_to=[(0, 0), (target, 1)],
        ))
    return out


DEF_NAME = {
    "en": "Defence", "en-GB": "Defence", "zh-CN": "防守阵型", "zh-TW": "防守陣型",
    "ja-JP": "ディフェンスシステム", "ko-KR": "수비 시스템",
    "es-ES": "Defensa", "fr-FR": "Défense", "id-ID": "Pertahanan",
    "ms-MY": "Pertahanan", "th-TH": "ระบบรับ", "vi-VN": "Phòng thủ",
}
DEF_NOTE = {
    "en": "Step out together and recover together. One defender who advances "
          "alone has not pressed the ball, they have opened a gate.",
    "en-GB": "Step out together and recover together. One defender who "
             "advances alone has not pressed the ball, they have opened a gate.",
    "zh-CN": "一起上步，一起退回。单独往前顶的那一个人，不是在逼球，是开了一扇门。",
    "zh-TW": "一起上步，一起退回。單獨往前頂的那一個人，不是在逼球，是開了一扇門。",
    "ja-JP": "一緒に出て、一緒に戻る。一人だけ前に出た守備は、ボールを潰したのではなく門を開けたのだ。",
    "ko-KR": "함께 나가고 함께 물러나라. 혼자 나간 수비는 압박한 게 아니라 문을 연 것이다.",
    "es-ES": "Salid juntos y replegad juntos: el defensor que avanza solo no "
             "ha presionado, ha abierto una puerta.",
    "fr-FR": "Sortez ensemble, repliez ensemble : un défenseur qui avance seul "
             "n'a pas pressé, il a ouvert une porte.",
    "id-ID": "Maju bersama, mundur bersama.",
    "ms-MY": "Maju bersama, berundur bersama.",
    "th-TH": "ออกพร้อมกัน ถอยพร้อมกัน",
    "vi-VN": "Cùng dâng lên, cùng lùi về.",
}


def defence_family() -> list[Drill]:
    """The four systems, described by how far the front line stands out.

    The back line follows the 6 m arc, not a straight row at 6.8 m that
    left the outside defenders 3.6 m off the line. The advanced players in
    a 4-2 or a 3-2-1 are the half-backs, who stand at about 9 m opposite the
    backs (6 and 14 m across): drawn in front of the outside defenders near
    the sidelines, they left both backs free.
    """
    HALF_BACKS = [_m(6.0, 8.6), _m(14.0, 8.6)]
    specs = [("six_zero", "6-0", crescent(6), []),
             ("five_one", "5-1", crescent(5), [_m(10.0, 9.6)]),
             ("three_two_one", "3-2-1", crescent(3), HALF_BACKS + [_m(10.0, 10.8)]),
             ("four_two", "4-2", crescent(4), HALF_BACKS)]
    out = []
    for key, label, back, front in specs:
        away = []
        # Stepping out is stepping *away* from your own goal, toward the
        # ball side's attackers, and back together.
        out_line = {xy: o for xy, o in zip(back, crescent(len(back), outward=1.2))}
        for x, y in back:
            ox, oy = out_line[(x, y)]
            away.append(P(x, y, "D", moves=[(ox, oy, 0), (x, y, 1)]))
        for x, y in front:
            away.append(P(x, y, "D", moves=[(x + (0.5 - x) * 0.10, y + 0.03, 0),
                                            (x, y, 1)]))
        away.append(P(*GOAL, "GK", role="GK"))
        out.append(Drill(
            id=f"hb_defence_{key}", category="defending", minutes=12, rel=True,
            free=(key in ("six_zero", "five_one")),
            name=suffixed(DEF_NAME, label), note=DEF_NOTE,
            home=[P(*p, lbl, moves=[(p[0], p[1] - 0.03, 0)]) for p, lbl in
                  ((LW, "LW"), (LB, "LB"), (CB, "CB"), (RB, "RB"),
                   (RW, "RW"), (PIVOT, "PIV"))],
            away=away, ball=2,
            # their swing — the ball the wall shifts against
            ball_to=[(3, 0), (4, 1)],
        ))
    return out


BREAK_NAME = {
    "en": "Fast break", "en-GB": "Fast break", "zh-CN": "快攻", "zh-TW": "快攻",
    "ja-JP": "速攻", "ko-KR": "속공", "es-ES": "Contraataque",
    "fr-FR": "Contre-attaque", "id-ID": "Serangan balik",
    "ms-MY": "Serangan balas", "th-TH": "การสวนกลับเร็ว", "vi-VN": "Phản công nhanh",
}
BREAK_NOTE = {
    "en": "The wings leave on the save, not on the outlet pass. Half a second "
          "there is the whole difference between a break and a set attack.",
    "en-GB": "The wings leave on the save, not on the outlet pass. Half a "
             "second there is the whole difference between a break and a set attack.",
    "zh-CN": "边锋在门将扑到球的瞬间就跑，不是等接到传球才跑。就这半秒，决定了这是快攻还是阵地战。",
    "zh-TW": "邊鋒在門將撲到球的瞬間就跑，不是等接到傳球才跑。就這半秒，決定了這是快攻還是陣地戰。",
    "ja-JP": "ウイングはセーブの瞬間に走り出す。アウトレットを待ってからでは遅い。その0.5秒が速攻とセットオフェンスの差だ。",
    "ko-KR": "윙은 선방하는 순간 뛴다, 패스를 받고서가 아니라. 그 0.5초가 속공과 세트 공격을 가른다.",
    "es-ES": "Los extremos salen con la parada, no con el pase: ese medio "
             "segundo separa un contraataque de un ataque posicional.",
    "fr-FR": "Les ailiers partent sur l'arrêt, pas sur la relance : cette "
             "demi-seconde sépare la contre-attaque de l'attaque placée.",
    "id-ID": "Sayap lari saat penyelamatan, bukan saat umpan keluar.",
    "ms-MY": "Pemain sayap berlari ketika penyelamatan, bukan ketika hantaran keluar.",
    "th-TH": "ปีกออกวิ่งตอนเซฟ ไม่ใช่ตอนจ่ายออก",
    "vi-VN": "Cánh chạy ngay khi thủ môn cản phá, không đợi đường chuyền.",
}


def break_family() -> list[Drill]:
    specs = [("first_wave", "first wave", 1), ("second_wave", "second wave", 3),
             ("third_wave", "third wave", 5)]
    out = []
    for key, label, n in specs:
        # Everyone starts outside his own goal area: the centre back of a
        # third wave used to stand 5.6 m from his own goal, inside it.
        starts = [(0.10, 0.72), (0.90, 0.72), (0.30, 0.80),
                  (0.70, 0.80), (0.50, 0.78)][:n]

        def runs(i, x, y):
            # The wings (the first wave) finish on the 6 m line; the backs
            # behind them stop at about 10 m, where the wall is not set yet.
            lane = x + (0.5 - x) * 0.35
            end = SIX + 0.03 if i < 2 else (0.26 if i < 4 else 0.29)
            return [(x + (0.5 - x) * 0.20, 0.40, i // 2), (lane, end, i // 2 + 1)]

        home = [P(0.50, 0.95, "GK", role="GK", moves=[(0.42, 0.88, 0)])] + [
            P(x, y, f"{i + 1}", moves=runs(i, x, y))
            for i, (x, y) in enumerate(starts)]
        # The keeper has just saved it and throws the outlet; the ball then
        # goes to the wave the drill is named for, who finishes. The third
        # wave used to arrive after the shot had already been taken.
        if n == 1:
            ball_to = [(1, 1), (SHOT, 2)]
        elif n == 3:
            ball_to = [(2, 1), (3, 2), (SHOT, 3)]
        else:
            ball_to = [(2, 1), (4, 2), (5, 3), (SHOT, 4)]
        out.append(Drill(
            id=f"hb_break_{key}", category="attacking", minutes=10, rel=True,
            free=(key == "first_wave"),
            name=suffixed(BREAK_NAME, label), note=BREAK_NOTE,
            # The waves ARE the stagger. Wings go on the save; each later
            # wave is one beat behind the one in front.
            home=home,
            away=[P(0.44, 0.30, "D", moves=[(0.40, 0.19, 1)]),
                  P(*GOAL, "GK", role="GK")],
            ball=0,
            ball_to=ball_to,
        ))
    return out


SET_NAME = {
    "en": "Set piece", "en-GB": "Set piece", "zh-CN": "定位球", "zh-TW": "定位球",
    "ja-JP": "セットプレー", "ko-KR": "세트 플레이", "es-ES": "Jugada a balón parado",
    "fr-FR": "Phase arrêtée", "id-ID": "Bola mati", "ms-MY": "Bola mati",
    "th-TH": "ลูกตั้งเตะ", "vi-VN": "Tình huống cố định",
}
SET_NOTE = {
    "en": "Rehearse it until nobody has to look up. A free throw where three "
          "players are still reading each other is a free throw wasted.",
    "en-GB": "Rehearse it until nobody has to look up. A free throw where "
             "three players are still reading each other is a free throw wasted.",
    "zh-CN": "练到没人需要抬头找人为止。三个人还在互相看的那次任意球，就是浪费掉的一次机会。",
    "zh-TW": "練到沒人需要抬頭找人為止。三個人還在互相看的那次任意球，就是浪費掉的一次機會。",
    "ja-JP": "誰も顔を上げずに済むまで反復する。3人が互いを見合っているフリースローは、無駄にしたフリースローだ。",
    "ko-KR": "아무도 고개를 들 필요 없을 때까지 반복하라. 서로 눈치 보는 프리스로는 버린 기회다.",
    "es-ES": "Ensáyalo hasta que nadie tenga que levantar la vista: un golpe "
             "franco donde tres se están leyendo es un golpe franco perdido.",
    "fr-FR": "Répète-la jusqu'à ce que personne n'ait à lever la tête : un jet "
             "franc où trois joueurs se cherchent est un jet franc gâché.",
    "id-ID": "Latih sampai tak ada yang perlu mendongak.",
    "ms-MY": "Latih sehingga tiada siapa perlu mendongak.",
    "th-TH": "ซ้อมจนไม่มีใครต้องเงยหน้ามอง",
    "vi-VN": "Tập đến khi không ai phải ngẩng lên tìm nhau.",
}


PENALTY_NOTE = {
    "en": "Pick the corner before you step to the line, and do not change it "
          "because the keeper moved first — he moved to make you change it.",
    "en-GB": "Pick the corner before you step to the line, and do not change "
             "it because the keeper moved first — he moved to make you change it.",
    "zh-CN": "站上线之前就把角度定下来，别因为门将先动就改主意 —— 他先动，就是为了让你改主意。",
    "zh-TW": "站上線之前就把角度定下來，別因為門將先動就改主意 —— 他先動，就是為了讓你改主意。",
    "ja-JP": "線に立つ前にコースを決め、GKが先に動いても変えない。動いたのは変えさせるためだ。",
    "ko-KR": "라인에 서기 전에 코스를 정하고, 골키퍼가 먼저 움직여도 바꾸지 마라. 바꾸게 하려고 움직인 것이다.",
    "es-ES": "Elige la escuadra antes de pisar la línea y no la cambies porque "
             "el portero se mueva primero: se mueve para que la cambies.",
    "fr-FR": "Choisis ton angle avant d'arriver sur la ligne et n'en change "
             "pas parce que le gardien a bougé : il bouge pour ça.",
    "id-ID": "Pilih sudutnya sebelum melangkah ke garis, dan jangan diubah "
             "karena kiper bergerak lebih dulu — dia bergerak agar kamu berubah.",
    "ms-MY": "Pilih sudut sebelum melangkah ke garisan, dan jangan ubah kerana "
             "penjaga gol bergerak dahulu.",
    "th-TH": "เลือกมุมก่อนก้าวไปที่เส้น และอย่าเปลี่ยนเพราะผู้รักษาประตูขยับก่อน เขาขยับเพื่อให้คุณเปลี่ยน",
    "vi-VN": "Chọn góc trước khi bước lên vạch, và đừng đổi vì thủ môn động trước — anh ta động chính là để bạn đổi.",
}


THROW_OFF_NOTE = {
    "en": "Everyone in his own half until the ball leaves the thrower's hand, "
          "then run. A throw-off rehearsed to the second scores before the "
          "defence has finished getting back.",
    "en-GB": "Everyone in his own half until the ball leaves the thrower's "
             "hand, then run. A throw-off rehearsed to the second scores "
             "before the defence has finished getting back.",
    "zh-CN": "球离开开球人的手之前，所有人都在本方半场，球一出手再跑。练到分秒不差的开球，能在对方退防到位之前就进球。",
    "zh-TW": "球離開開球人的手之前，所有人都在本方半場，球一出手再跑。練到分秒不差的開球，能在對方退防到位之前就進球。",
    "ja-JP": "ボールが投げ手の手を離れるまで全員が自陣に残り、離れた瞬間に走る。秒単位で練習したスローオフは、守備が戻りきる前に得点する。",
    "ko-KR": "공이 던지는 선수의 손을 떠날 때까지 모두 자기 진영에 있다가, 떠나는 순간 뛴다. 초 단위로 맞춘 스로오프는 수비가 다 돌아오기 전에 득점한다.",
    "es-ES": "Todos en su propio campo hasta que el balón sale de la mano del "
             "lanzador, y entonces a correr: un saque de centro ensayado al "
             "segundo marca antes de que la defensa termine de replegar.",
    "fr-FR": "Tout le monde dans sa moitié jusqu’à ce que le ballon quitte la "
             "main du lanceur, puis on court : un engagement répété à la "
             "seconde marque avant que la défense ait fini de se replier.",
    "id-ID": "Semua tetap di setengah lapangan sendiri sampai bola lepas dari "
             "tangan pelempar, lalu lari. Lemparan awal yang dilatih sampai "
             "hitungan detik mencetak gol sebelum pertahanan selesai kembali.",
    "ms-MY": "Semua kekal di separuh gelanggang sendiri sehingga bola lepas "
             "dari tangan pelempar, kemudian lari. Lemparan permulaan yang "
             "dilatih hingga ke saat menjaringkan gol sebelum pertahanan "
             "sempat kembali.",
    "th-TH": "ทุกคนอยู่ในแดนตัวเองจนกว่าบอลจะหลุดจากมือคนเปิดเกม แล้วจึงวิ่ง การเปิดเกมที่ซ้อมจนแม่นถึงวินาทีจะได้ประตูก่อนที่แนวรับจะกลับมาตั้งได้ทัน",
    "vi-VN": "Mọi người ở yên trong phần sân nhà cho đến khi bóng rời tay "
             "người ném, rồi mới chạy. Một pha phát bóng được tập đến từng "
             "giây sẽ ghi bàn trước khi hàng thủ kịp lùi về.",
}
THROW_IN_NOTE = {
    "en": "One foot on the sideline and the ball in play at once. A throw-in "
          "taken while the defence is still turning round is worth more than "
          "any routine run after it has set.",
    "en-GB": "One foot on the sideline and the ball in play at once. A "
             "throw-in taken while the defence is still turning round is worth "
             "more than any routine run after it has set.",
    "zh-CN": "一只脚踩在边线上，马上把球发出去。趁防守还在转身时发的边线球，比等对方站好后再打的任何配合都值钱。",
    "zh-TW": "一隻腳踩在邊線上，馬上把球發出去。趁防守還在轉身時發的邊線球，比等對方站好後再打的任何配合都值錢。",
    "ja-JP": "片足をサイドラインに置いて、すぐにボールを入れる。守備がまだ向き直っている間のスローインは、整った後のどんなセットプレーより価値がある。",
    "ko-KR": "한 발을 사이드라인에 두고 바로 공을 넣어라. 수비가 아직 몸을 돌리는 중에 하는 스로인은, 수비가 자리 잡은 뒤의 어떤 패턴보다 값지다.",
    "es-ES": "Un pie sobre la línea de banda y el balón en juego al instante: "
             "un saque de banda hecho mientras la defensa aún se gira vale más "
             "que cualquier jugada lanzada cuando ya está colocada.",
    "fr-FR": "Un pied sur la ligne de touche et le ballon en jeu tout de "
             "suite : une remise en jeu jouée pendant que la défense se "
             "retourne vaut plus que n’importe quelle combinaison lancée une "
             "fois qu’elle est en place.",
    "id-ID": "Satu kaki di garis samping dan bola langsung dimainkan. Lemparan "
             "ke dalam saat pertahanan masih berbalik lebih berharga daripada "
             "pola apa pun setelah mereka siap.",
    "ms-MY": "Sebelah kaki di garisan tepi dan bola terus dimainkan. Lemparan "
             "ke dalam ketika pertahanan masih berpusing lebih bernilai "
             "daripada sebarang corak selepas mereka bersedia.",
    "th-TH": "เท้าข้างหนึ่งอยู่บนเส้นข้างแล้วส่งบอลเข้าเล่นทันที ลูกทุ่มที่เล่นตอนแนวรับยังหันตัวไม่ทัน มีค่ากว่าแผนใด ๆ ที่เล่นหลังจากเขาตั้งแนวเสร็จแล้ว",
    "vi-VN": "Một chân đặt trên đường biên và đưa bóng vào cuộc ngay. Một quả "
             "ném biên thực hiện khi hàng thủ còn đang xoay người đáng giá hơn "
             "bất kỳ bài phối hợp nào chạy sau khi họ đã đứng vào vị trí.",
}


def setpiece_family() -> list[Drill]:
    # The taker stands behind the 7 m line and does not touch or cross it
    # before the ball has left his hand (Rule 14.6): no step in. He used to
    # walk from 7.0 to 6.4 m first.
    out = [Drill(
        id="hb_set_seven_metre", category="setpiece", minutes=6, rel=True,
        free=True, name=suffixed(SET_NAME, "the 7 m throw"),
        # Its own point: there is no defence to rehearse a routine against,
        # so the shared free-throw note said nothing about this drill.
        note=PENALTY_NOTE,
        home=[P(0.50, SEVEN_M + 0.008, "S")],
        away=[P(*GOAL, "GK", role="GK", moves=[(0.53, 0.05, 0)]),
              # The two team-mates who must stand outside the 9 m line until
              # the throw, and follow in for the rebound once it is gone.
              P(0.30, NINE + 0.03, "D", moves=[(0.36, NINE - 0.005, 1)]),
              P(0.70, NINE + 0.03, "D", moves=[(0.64, NINE - 0.005, 1)])],
        markers=[M(0.50, SEVEN_M, "square", ""), M(*ZONE_L, "zone", "")],
        ball=0,
        # seven metres: one strike at the marked corner
        ball_to=[(GOAL_L, 0)],
    )]
    wall = crescent(6)
    # The 9 m free throw: thrower on the line, every attacker outside it
    # when the throw is taken (Rule 13.7) — the pivot used to wait among the
    # defenders. They go in as the ball does.
    out.append(Drill(
        id="hb_set_nine_metre", category="setpiece", minutes=8, rel=True,
        free=True,
        name=suffixed(SET_NAME, "the 9 m free throw"), note=SET_NOTE,
        home=[P(0.50, NINE, "1", moves=[(0.50, NINE - 0.015, 0)]),
              P(0.28, 0.26, "2", moves=[(0.36, 0.22, 0)]),
              P(0.68, 0.255, "PIV", moves=[(0.62, SIX + 0.03, 0)])],
        away=[P(x, y, "D") for x, y in wall] + [P(*GOAL, "GK", role="GK")],
        ball=0,
        # played to the 2 cutting off the routine, struck at goal
        ball_to=[(1, 0), (SHOT, 1)],
    ))
    # The throw-off: every attacker in his own half until the ball goes
    # (Rule 10.3). The runner and the pivot used to start in the
    # opponents' half, the pivot already on their 6 m line.
    out.append(Drill(
        id="hb_set_throw_off", category="setpiece", minutes=8, rel=True,
        name=suffixed(SET_NAME, "the throw-off"),
        note=THROW_OFF_NOTE,
        home=[P(0.50, 0.50, "1", moves=[(0.50, 0.42, 1)]),
              P(0.30, 0.54, "2", moves=[(0.36, 0.34, 0), (0.38, 0.25, 1)]),
              P(0.68, 0.54, "PIV", moves=[(0.64, 0.32, 0), (0.62, SIX + 0.03, 1)])],
        away=[P(x, y, "D") for x, y in wall] + [P(*GOAL, "GK", role="GK")],
        ball=0,
        # thrown to the 2 on the run, carried in, struck at goal
        ball_to=[(1, 0), (1, 1), (SHOT, 2)],
    ))
    # The thrower stands with a foot on the line, which is what the
    # off_surface flag is for.
    out.append(Drill(
        id="hb_set_sideline", category="setpiece", minutes=8, rel=True,
        off_surface=True,
        name=suffixed(SET_NAME, "the sideline throw"), note=THROW_IN_NOTE,
        home=[P(-0.02, 0.30, "1", moves=[(-0.02, 0.27, 1)]),
              P(0.22, 0.26, "2", moves=[(0.34, 0.22, 1)]),
              P(*PIVOT, "PIV", moves=[(0.62, SIX + 0.03, 0)])],
        away=[P(x, y, "D") for x, y in wall] + [P(*GOAL, "GK", role="GK")],
        ball=0,
        ball_to=[(1, 1), (SHOT, 2)],
    ))
    return out


GAME_NAME = {
    "en": "Game", "en-GB": "Game", "zh-CN": "对抗", "zh-TW": "對抗",
    "ja-JP": "ゲーム", "ko-KR": "게임", "es-ES": "Juego", "fr-FR": "Jeu",
    "id-ID": "Permainan", "ms-MY": "Permainan", "th-TH": "เกม", "vi-VN": "Trận đấu",
}
GAME_NOTE = {
    "en": "Fewer players, same goal size — the shooting chances arrive faster "
          "and so does every decision that has to come before them.",
    "en-GB": "Fewer players, same goal size — the shooting chances arrive "
             "faster and so does every decision that has to come before them.",
    "zh-CN": "人少了，球门一样大——射门机会来得更快，而机会之前那些决定，也必须更快。",
    "zh-TW": "人少了，球門一樣大——射門機會來得更快，而機會之前那些決定，也必須更快。",
    "ja-JP": "人数は減ってもゴールの大きさは同じ。シュートチャンスが早く来る分、その前の判断も早くなる。",
    "ko-KR": "인원은 줄고 골대는 그대로. 슛 기회가 빨리 오는 만큼 그 앞의 판단도 빨라진다.",
    "es-ES": "Menos jugadores, misma portería: las ocasiones llegan antes, y "
             "con ellas todas las decisiones previas.",
    "fr-FR": "Moins de joueurs, même but : les occasions arrivent plus vite, "
             "et toutes les décisions qui les précèdent aussi.",
    "id-ID": "Pemain lebih sedikit, gawang sama besar.",
    "ms-MY": "Pemain lebih sedikit, gol sama besar.",
    "th-TH": "คนน้อยลง ประตูเท่าเดิม โอกาสยิงมาเร็วขึ้น",
    "vi-VN": "Ít người hơn, khung thành như cũ.",
}


def game_family() -> list[Drill]:
    out = []
    for n in (3, 4, 5, 6):
        spots = ring(n, 0.5, 0.37, 0.30, 0.09)
        # Half the ring adjusts on each pass, not all of it on the
        # first: with everyone moving on beat zero, the second pass went
        # round an arc that had already stopped.
        # The man at the top of the ring moves across, not in: stepping in
        # he walked into the middle of three defenders.
        steps = [(x - 0.06, y) if i == 0 else (x + (0.5 - x) * 0.15, y - 0.02)
                 for i, (x, y) in enumerate(spots)]
        # Goal-side of their man, on the line between him and the goal
        # and clear of him — on the goal-area arc, stepping out a metre
        # as he comes. They used to step onto the very spot their man
        # stepped to, so the board drew pairs standing on each other.
        home = [P(x, y, f"{i + 1}", moves=[(sx, sy, i % 2)])
                for i, ((x, y), (sx, sy)) in enumerate(zip(spots, steps))]
        # Each takes the arc spot in the order his man stands round the
        # goal; projecting each man straight onto the arc piled the two
        # central defenders on one point.
        import math
        order = sorted(range(n), key=lambda i: -math.atan2(spots[i][1] * 40,
                                                            spots[i][0] * 20 - 10))
        half = min(50.0, 15.0 + 6.0 * n)
        line, stepped = crescent(n, 6.8, half), crescent(n, 6.8, half, outward=0.5)
        slot = {i: k for k, i in enumerate(order)}
        away = [P(*line[slot[i]], "D", moves=[(*stepped[slot[i]], i % 2)])
                for i in range(n)]
        out.append(Drill(
            id=f"hb_game_{n}v{n}", category="ssg", minutes=15, rel=True,
            free=(n == 4),
            name=suffixed(GAME_NAME, f"{n}v{n}"), note=GAME_NOTE,
            home=home,
            away=away + [P(*GOAL, "GK", role="GK")],
            ball=0,
            # two passes round the arc against matched defence
            ball_to=[(1 % n, 0), (2 % n, 1)],
        ))
    return out


ONE_V_ONE_NOTE = {
    "en": "Change direction once, at speed, off the foot nearest the defender. A feint he can watch you set up is not a feint.",
    "zh-CN": "全速中变向一次，用靠近防守人的那只脚蹬地。让他看着你做出来的假动作，不叫假动作。",
    "zh-TW": "全速中變向一次，用靠近防守人的那隻腳蹬地。讓他看著你做出來的假動作，不叫假動作。",
    "ja-JP": "スピードの中で一度だけ方向を変える。相手に近い側の足で踏み切る。準備を見られるフェイントはフェイントではない。",
    "ko-KR": "속도를 유지한 채 한 번만 방향을 바꾼다. 수비수 쪽 발로 밟아라. 준비 과정을 보여주는 페인트는 페인트가 아니다.",
    "es-ES": "Cambia de dirección una sola vez, a velocidad, apoyando el pie más cercano al defensor. Una finta que te ve preparar no es una finta.",
    "fr-FR": "Change de direction une seule fois, à pleine vitesse, en appui sur le pied le plus proche du défenseur. Une feinte qu’il te voit préparer n’en est pas une.",
    "id-ID": "Ubah arah sekali saja, dalam kecepatan, bertumpu pada kaki terdekat dengan bek. Gerak tipu yang terlihat disiapkan bukan gerak tipu.",
    "ms-MY": "Tukar arah sekali sahaja, dalam kelajuan, bertumpu pada kaki terdekat dengan pemain bertahan.",
    "th-TH": "เปลี่ยนทิศทางครั้งเดียวด้วยความเร็ว ลงน้ำหนักที่เท้าข้างที่ใกล้กองหลัง หลอกที่เขาเห็นคุณตั้งท่าไม่ใช่การหลอก",
    "vi-VN": "Đổi hướng một lần duy nhất, ở tốc độ cao, trụ chân gần hậu vệ nhất. Động tác giả mà đối thủ nhìn thấy bạn chuẩn bị thì không còn là động tác giả.",
}
# Man to man is what the board draws: six defenders, each with one attacker.
# It used to be drawn and coached as 5+1 — one marker and a 5-0 behind him.
MANMARK_NOTE = {
    "en": "Every defender takes one attacker and stays between him and the goal, a step off, on the ball side. Switch only by calling it: two defenders on one man leave an attacker free behind them.",
    "zh-CN": "每个防守人盯住一个进攻人，站在他和球门之间，隔一步，偏向有球一侧。换人必须喊出来：两个人盯同一个人，身后就空出一个进攻人。",
    "zh-TW": "每個防守人盯住一個進攻人，站在他和球門之間，隔一步，偏向有球一側。換人必須喊出來：兩個人盯同一個人，身後就空出一個進攻人。",
    "ja-JP": "守備は一人ずつ相手を持ち、相手とゴールの間に、一歩離れてボール側に立つ。マークの受け渡しは必ず声で。二人が同じ相手につけば、背後で一人が空く。",
    "ko-KR": "수비수마다 공격수 한 명을 맡아 그와 골 사이, 한 걸음 떨어진 공 쪽에 선다. 마크 교대는 반드시 콜로 한다. 두 명이 한 사람을 잡으면 뒤에서 공격수 한 명이 빈다.",
    "es-ES": "Cada defensor toma a un atacante y se queda entre él y la portería, a un paso, del lado del balón. Solo se cambia de marca cantándolo: dos defensores sobre un hombre dejan a un atacante libre detrás.",
    "fr-FR": "Chaque défenseur prend un attaquant et reste entre lui et le but, à un pas, côté ballon. On ne change de marquage qu’en l’annonçant : deux défenseurs sur un homme laissent un attaquant libre derrière eux.",
    "id-ID": "Setiap bek menjaga satu penyerang dan berdiri di antara dia dan gawang, selangkah jauhnya, di sisi bola. Bertukar jagaan hanya dengan berteriak: dua bek pada satu orang membiarkan satu penyerang bebas di belakang.",
    "ms-MY": "Setiap pemain bertahan mengawal seorang penyerang dan berdiri di antara dia dan gol, selangkah jauhnya, di sebelah bola. Tukar kawalan hanya dengan memanggilnya: dua pemain bertahan pada seorang membiarkan seorang penyerang bebas di belakang.",
    "th-TH": "กองหลังแต่ละคนประกบผู้บุกหนึ่งคน ยืนระหว่างเขากับประตู ห่างหนึ่งก้าว ค่อนไปทางฝั่งบอล จะสลับประกบต้องตะโกนบอกเท่านั้น สองคนประกบคนเดียวคือปล่อยผู้บุกอีกคนว่างอยู่ข้างหลัง",
    "vi-VN": "Mỗi hậu vệ kèm một cầu thủ tấn công và đứng giữa anh ta với khung thành, cách một bước, lệch về phía có bóng. Chỉ đổi người kèm khi đã hô lên: hai hậu vệ cùng kèm một người là bỏ trống một cầu thủ tấn công phía sau.",
}
RETURN_NOTE = {
    "en": "Sprint to the six metre line first and sort out who marks whom there. Running back watching the ball is how a five-on-four becomes a goal.",
    "zh-CN": "先冲回 6 米线，回到位再分谁盯谁。一边往回跑一边看球，五打四就是这样变成一个球的。",
    "zh-TW": "先衝回 6 米線，回到位再分誰盯誰。一邊往回跑一邊看球，五打四就是這樣變成一個球的。",
    "ja-JP": "まず6mラインまで全力で戻り、そこで誰が誰につくかを決める。ボールを見ながら戻るから、5対4が失点になる。",
    "ko-KR": "먼저 6미터 라인까지 전력으로 돌아가서 거기서 누가 누구를 잡을지 정한다. 공을 보며 돌아오면 5대4가 실점이 된다.",
    "es-ES": "Corre primero a la línea de seis metros y reparte allí las marcas. Volver mirando el balón es como un cinco contra cuatro acaba en gol.",
    "fr-FR": "Sprinte d’abord jusqu’à la ligne des six mètres et répartis les marquages là-bas. Revenir en regardant le ballon, c’est ainsi qu’un cinq contre quatre devient un but.",
    "id-ID": "Sprint dulu ke garis enam meter dan bagi penjagaan di sana.",
    "ms-MY": "Pecut dahulu ke garisan enam meter dan bahagikan penjagaan di sana.",
    "th-TH": "วิ่งกลับถึงเส้นหกเมตรก่อน แล้วค่อยแบ่งว่าใครประกบใคร",
    "vi-VN": "Chạy hết sức về vạch sáu mét trước, rồi mới phân ai kèm ai ở đó. Vừa chạy về vừa nhìn bóng là cách một pha năm đánh bốn biến thành bàn thua.",
}
BLOCK_NOTE = {
    "en": "Two hands up and together, arms locked, and take the ball with the hands rather than the face. A block that flinches is a deflection into your own goal.",
    "zh-CN": "双手举起并拢、手臂锁住，用手去挡球而不是用脸。缩一下的封挡，就是把球折射进自家球门。",
    "zh-TW": "雙手舉起併攏、手臂鎖住，用手去擋球而不是用臉。縮一下的封擋，就是把球折射進自家球門。",
    "ja-JP": "両手を上げて揃え、腕を固める。顔ではなく手でボールを受ける。ひるんだブロックは自陣ゴールへの軌道変更だ。",
    "ko-KR": "두 손을 위로 모으고 팔을 고정한 채 얼굴이 아니라 손으로 공을 받는다. 움찔하는 블록은 자기 골문으로 굴절시킨다.",
    "es-ES": "Dos manos arriba y juntas, brazos firmes, y recibe el balón con las manos y no con la cara. Un bloqueo que se encoge es un desvío a tu propia portería.",
    "fr-FR": "Deux mains hautes et jointes, bras verrouillés, et prends le ballon avec les mains plutôt qu’avec le visage. Un contre qui recule dévie dans ton propre but.",
    "id-ID": "Dua tangan naik dan rapat, lengan terkunci, dan sambut bola dengan tangan bukan wajah.",
    "ms-MY": "Dua tangan naik dan rapat, lengan terkunci, dan sambut bola dengan tangan bukan muka.",
    "th-TH": "ยกสองมือชิดกัน ล็อกแขน และรับบอลด้วยมือไม่ใช่ด้วยหน้า",
    "vi-VN": "Hai tay giơ lên sát nhau, khóa cánh tay, và đón bóng bằng tay chứ không phải bằng mặt. Một pha chắn bóng mà co người lại là đổi hướng bóng vào khung thành nhà.",
}
TRANSITION_GAME_NOTE = {
    "en": "Both goals live, so every turnover is a run the length of the court. The team that stops arguing about the whistle first gets the goal.",
    "zh-CN": "两边球门都算，所以每次丢球都要跑一整个全场。谁先不跟裁判理论，谁就先进球。",
    "zh-TW": "兩邊球門都算，所以每次丟球都要跑一整個全場。誰先不跟裁判理論，誰就先進球。",
    "ja-JP": "両ゴールとも生きているので、ターンオーバーはすべてコート全長のランになる。笛に文句を言うのをやめたチームが得点する。",
    "ko-KR": "양쪽 골이 모두 살아 있어 턴오버마다 코트를 끝까지 달려야 한다. 휘슬에 항의를 먼저 그만두는 팀이 득점한다.",
    "es-ES": "Las dos porterías cuentan, así que cada pérdida es una carrera de cancha entera. Marca el equipo que antes deja de discutir el silbato.",
    "fr-FR": "Les deux buts comptent, donc chaque perte de balle est une course sur toute la longueur. L’équipe qui arrête la première de discuter l’arbitrage marque.",
    "id-ID": "Kedua gawang hidup, jadi setiap kehilangan bola berarti lari sepanjang lapangan.",
    "ms-MY": "Kedua-dua gol hidup, jadi setiap kehilangan bola bermakna berlari sepanjang gelanggang.",
    "th-TH": "ประตูสองฝั่งใช้ได้ทั้งคู่ ทุกการเสียบอลจึงต้องวิ่งยาวทั้งสนาม",
    "vi-VN": "Cả hai khung thành đều tính, nên mỗi lần mất bóng là một pha chạy hết chiều dài sân. Đội nào thôi cãi trọng tài trước sẽ ghi bàn.",
}
GK_NAME = {"en": "Goalkeeping", "en-GB": "Goalkeeping", "zh-CN": "门将训练",
           "zh-TW": "門將訓練", "ja-JP": "GK練習", "ko-KR": "골키퍼 훈련",
           "es-ES": "Portería", "fr-FR": "Gardien de but", "id-ID": "Latihan kiper",
           "ms-MY": "Latihan penjaga gol", "th-TH": "ฝึกผู้รักษาประตู",
           "vi-VN": "Tập thủ môn"}
GK_NOTE = {
    "en": "Move on the shooter's plant foot, not on the ball. By the time you can see the ball the ball has already been thrown.",
    "zh-CN": "看射门者的支撑脚起动，不是看球。等你看得见球的时候，球已经出手了。",
    "zh-TW": "看射門者的支撐腳起動，不是看球。等你看得見球的時候，球已經出手了。",
    "ja-JP": "動き出すのはシューターの踏み切り足に対してで、ボールに対してではない。ボールが見えた時にはもう投げ終わっている。",
    "ko-KR": "슈터의 디딤발을 보고 움직여라. 공이 보일 때는 이미 던져진 뒤다.",
    "es-ES": "Muévete con el pie de apoyo del lanzador, no con el balón: cuando ves el balón ya está lanzado.",
    "fr-FR": "Bouge sur le pied d’appui du tireur, pas sur le ballon : quand tu vois le ballon, il est déjà parti.",
    "id-ID": "Bergeraklah pada kaki tumpu penembak, bukan pada bola.",
    "ms-MY": "Bergerak pada kaki tumpuan penembak, bukan pada bola.",
    "th-TH": "ขยับตามเท้าหลักของคนยิง ไม่ใช่ตามบอล",
    "vi-VN": "Di chuyển theo chân trụ của người ném, không phải theo bóng. Khi bạn thấy được bóng thì bóng đã rời tay rồi.",
}


def _marking(xm: float, ym: float, gap: float = 2.0) -> tuple[float, float]:
    """A man-marker's spot: [gap] metres from his man toward the goal."""
    import math
    dx, dy = 10.0 - xm, -ym
    d = math.hypot(dx, dy) or 1.0
    return _m(xm + dx * gap / d, ym + dy * gap / d)


def _man_to_man() -> Drill:
    """Six defenders, each on one attacker, moving as their men move."""
    # name, start, [(x, y, phase)] in metres
    men = [("LW", (1.6, 9.0), [(2.6, 10.6, 1)]),
           ("LB", (5.0, 13.0), [(5.6, 11.6, 0), (6.6, 13.0, 1)]),
           ("CB", (10.0, 14.5), [(10.6, 13.6, 0)]),
           ("RB", (15.0, 13.0), [(14.4, 12.0, 0)]),
           ("RW", (18.4, 9.0), [(17.8, 10.0, 1)]),
           ("PIV", (12.6, 9.6), [(8.8, 9.4, 0)])]
    home, away = [], []
    for lbl, (x, y), mv in men:
        home.append(P(*_m(x, y), lbl, moves=[(*_m(mx, my), ph) for mx, my, ph in mv]))
        away.append(P(*_marking(x, y), "D",
                      moves=[(*_marking(mx, my), ph) for mx, my, ph in mv]))
    return Drill(
        id="hb_defence_man_to_man", category="defending", minutes=12, rel=True,
        level="advanced",
        name=suffixed(DEF_NAME, "man to man"), note=MANMARK_NOTE,
        home=home, away=away + [P(*GOAL, "GK", role="GK")],
        ball=2,
        # CB to LB as the pivot cuts across, LB out to the wing: every
        # marker goes with his own man and stays goal-side of him
        ball_to=[(1, 0), (0, 1)],
    )


def gaps_family() -> list[Drill]:
    """The parts of handball the library had no drill for.

    A coach going through it found the same holes: no individual 1v1, which
    is the most-drilled skill in the game; no man-to-man defence; nothing on
    getting back after losing the ball; no shot-blocking; no full-court
    game; and — on boards that draw a goalkeeper twenty-eight times out of
    thirty — no goalkeeping at all.
    """
    returns = [(0.24, 0.24), (0.50, 0.22), (0.76, 0.24)]
    return [
        Drill(
            id="hb_attack_one_v_one", category="attacking", minutes=10, rel=True,
            level="foundation", free=True,
            name=suffixed(ATTACK_NAME, "one against one"), note=ONE_V_ONE_NOTE,
            home=[P(*CB, "CB", moves=[(0.42, 0.28, 0), (0.58, 0.235, 1)])],
            away=[P(0.50, SIX + 0.05, "D", moves=[(0.44, SIX + 0.035, 0)]),
                  P(*GOAL, "GK", role="GK", moves=[(0.53, 0.05, 1)])],
            markers=[M(*ZONE_L, "zone", "")],
            ball=0,
            # carried at the defender both ways, finished across the keeper
            ball_to=[(0, 0), (0, 1), (GOAL_L, 2)],
        ),
        _man_to_man(),
        Drill(
            id="hb_defence_return", category="defending", minutes=10, rel=True,
            name=suffixed(DEF_NAME, "getting back"), note=RETURN_NOTE, free=True,
            home=[P(0.28, 0.44, "1", moves=[(*returns[0], 0)]),
                  P(0.50, 0.40, "2", moves=[(*returns[1], 0)]),
                  P(0.72, 0.44, "3", moves=[(*returns[2], 0)])],
            # They lost it at the other end and sprint back to the 6 m line,
            # each to the arc in front of an attacker.
            away=[P(0.22, 0.66, "D", moves=[(0.20, 0.34, 0), (*onto_arc(returns[0]), 1)]),
                  P(0.50, 0.72, "D", moves=[(0.50, 0.38, 0), (*onto_arc(returns[1]), 1)]),
                  P(0.78, 0.66, "D", moves=[(0.80, 0.34, 0), (*onto_arc(returns[2]), 1)]),
                  P(*GOAL, "GK", role="GK")],
            ball=1,
            # The attack moves the ball across while the defence gets back;
            # it used to be passed to a defender, who dribbled toward his
            # own goal.
            ball_to=[(0, 0), (2, 1), (SHOT, 2)],
        ),
        Drill(
            id="hb_defence_block", category="defending", minutes=8, rel=True,
            level="foundation", tight=True,
            name=suffixed(DEF_NAME, "blocking the shot"), note=BLOCK_NOTE,
            home=[P(0.50, 0.38, "CB", moves=[(0.50, 0.35, 0)])],
            # A double block, shoulder to shoulder in the shooter's lane.
            away=[P(0.45, SIX + 0.05, "D", moves=[(0.465, SIX + 0.08, 0)]),
                  P(0.55, SIX + 0.05, "D", moves=[(0.535, SIX + 0.08, 0)]),
                  P(*GOAL, "GK", role="GK", moves=[(0.44, 0.05, 1)])],
            ball=0,
            # the CB winds up and the shot meets the four hands of the block
            # — it used to fly through the gap between them to the keeper
            ball_to=[("a0", 1)],
        ),
        Drill(
            id="hb_game_transition", category="ssg", minutes=18, rel=True,
            level="advanced",
            name=suffixed(GAME_NAME, "end to end"), note=TRANSITION_GAME_NOTE,
            home=[P(0.24, 0.62, "1", moves=[(0.20, 0.34, 0), (0.24, 0.80, 2)]),
                  P(0.50, 0.58, "2", moves=[(0.50, 0.30, 0), (0.50, 0.78, 2)]),
                  P(0.76, 0.62, "3", moves=[(0.80, 0.34, 0), (0.76, 0.80, 2)]),
                  P(0.50, 0.92, "GK", role="GK")],
            away=[P(0.30, 0.40, "D", moves=[(0.28, 0.66, 2), (0.36, 0.74, 3)]),
                  P(0.44, 0.43, "D", moves=[(0.50, 0.62, 2)]),
                  # steps into the lane and intercepts the pass to 3
                  P(0.70, 0.40, "D", moves=[(0.66, 0.33, 1), (0.68, 0.55, 2)]),
                  P(*GOAL, "GK", role="GK")],
            ball=1,
            # attack; the pass to the wing is intercepted; carried the
            # other way, laid off, and finished in the far goal
            ball_to=[(1, 0), ("a2", 1), ("a2", 2), ("a0", 3), ((0.55, 1.006), 4)],
        ),
        # The keeper's drills: every shot into the goal mouth, the keeper
        # moving to it — the zones used to sit outside both posts.
        Drill(
            id="hb_gk_angles", category="goalkeeping", minutes=10, rel=True,
            level="foundation", free=True,
            name=suffixed(GK_NAME, "angles"), note=GK_NOTE,
            home=[P(0.30, NINE + 0.02, "1", moves=[(0.34, NINE - 0.01, 0)]),
                  P(0.70, NINE + 0.02, "2", moves=[(0.66, NINE - 0.01, 0)])],
            away=[P(*GOAL, "GK", role="GK", moves=[(0.46, 0.05, 1)])],
            markers=[M(0.46, ZONE_L[1], "zone", ""), M(0.54, ZONE_R[1], "zone", "")],
            ball=0,
            ball_to=[(GOAL_L, 1)],
        ),
        Drill(
            id="hb_gk_one_v_one", category="goalkeeping", minutes=10, rel=True,
            level="development",
            name=suffixed(GK_NAME, "one against one"), note=GK_NOTE,
            home=[P(0.50, 0.42, "1", moves=[(0.50, 0.26, 0), (0.44, SIX + 0.012, 1)])],
            away=[P(*GOAL, "GK", role="GK", moves=[(0.47, 0.065, 1)])],
            markers=[M(*ZONE_R, "zone", "")],
            ball=0,
            ball_to=[(GOAL_R, 2)],
        ),
        Drill(
            id="hb_gk_seven_metre", category="goalkeeping", minutes=10, rel=True,
            level="development",
            name=suffixed(GK_NAME, "saving the 7 m"), note=GK_NOTE,
            # behind the line, and no step over it before the release
            home=[P(0.50, SEVEN_M + 0.008, "1")],
            away=[P(*GOAL, "GK", role="GK", moves=[(0.535, 0.05, 0)])],
            markers=[M(0.50, SEVEN_M, "square", "")],
            ball=0,
            ball_to=[(GOAL_R, 0)],
        ),
        # The keeper has the ball after a save and throws the first pass of
        # the break to his own near wing, sprinting away up the sideline;
        # the back breaking up the middle is the second option. It used to
        # be the attackers running at him, and the ball went from one of
        # them to the other into empty court.
        Drill(
            id="hb_gk_outlet", category="goalkeeping", minutes=10, rel=True,
            level="development",
            name=suffixed(GK_NAME, "the outlet pass"), note=GK_NOTE,
            home=[P(*GOAL, "GK", role="GK", moves=[(0.44, 0.07, 0)]),
                  P(0.06, 0.17, "LW", moves=[(0.08, 0.38, 0), (0.10, 0.58, 1)]),
                  P(0.32, 0.30, "B", moves=[(0.36, 0.42, 0), (0.40, 0.55, 1)])],
            markers=[M(0.10, 0.62, "zone", ""), M(0.40, 0.59, "zone", "")],
            ball=0,
            ball_to=[(1, 1)],
        ),
    ]


# Passages that ended on the wing's or the last receiver's hands: the wing
# shoots, the game passage finishes, the keeper's outlet is carried on.
FINISH_AT_GOAL = [
    "hb_circulation_wide", "hb_circulation_with_pivot", "hb_circulation_second_wave",
    "hb_defence_six_zero", "hb_defence_five_one", "hb_defence_three_two_one",
    "hb_defence_four_two",
    "hb_game_3v3", "hb_game_4v4", "hb_game_5v5", "hb_game_6v6",
]
# The star and the three lanes come back round to the start: the next
# man goes; the keeper's outlet pass is carried over halfway.
BACK_TO_START = ["hb_warm_star_passing", "hb_warm_three_lane"]


def handball_library() -> list[Drill]:
    from .engine import finish_with
    drills = (warmup_family() + circulation_family() + attack_family()
              + break_family() + shooting_family() + defence_family()
              + setpiece_family() + game_family() + gaps_family())
    finish_with(drills, SHOT, FINISH_AT_GOAL)
    aim_shots(drills)
    return drills
