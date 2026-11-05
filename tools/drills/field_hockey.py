"""The field hockey library.

Attacking upward, goal at y=0. The shooting circle is the line that decides
everything: a shot from outside it does not count, so most of these drills are
about arriving inside it with the ball under control rather than just near it.
"""
from .engine import Drill, M, P, suffixed

GOAL = (0.50, 0.02)
# The goal is 3.66m of a 55m pitch, so the posts stand at 0.467 and 0.533 of
# the court's width (field_hockey_court_painter.dart draws them there). A
# shot is aimed between them, a couple of hundredths inside so the ball is
# drawn on the frame rather than clipping a post. Four of these were written
# at 0.42 and 0.56 — outside the posts — and on a board titled "Shooting the
# tomahawk" a shot crossing the backline wide of the goal is a miss.
LEFT_POST, RIGHT_POST = 0.478, 0.522
# The court painter draws the D itself (arcs of 14.63 m from each post), the
# 23 m lines and the penalty spots, so nothing here marks them: an unlabelled
# zone token used to sit on the top of every circle in the library, and
# players ran straight over it.
CIRCLE_Y = 0.17          # top of the shooting circle, on the centre line
TWENTY_THREE = 0.25
PENALTY_SPOT = (0.50, 0.07)


def circle_edge(x):
    """Roughly where the circle's arc sits at a given x — good enough to place
    a player 'on the edge of the D'."""
    dx = abs(x - 0.5) / 0.27
    return CIRCLE_Y * max(0.0, (1 - dx * dx)) ** 0.5


WARM_NAME = {
    "en": "Warm-up", "en-GB": "Warm-up", "zh-CN": "热身", "zh-TW": "熱身",
    "ja-JP": "ウォームアップ", "ko-KR": "웜업", "es-ES": "Calentamiento",
    "fr-FR": "Échauffement", "id-ID": "Pemanasan", "ms-MY": "Memanaskan badan",
    "th-TH": "วอร์มอัพ", "vi-VN": "Khởi động",
}
WARM_NOTE = {
    "en": "Head up, stick down. A player who has to look at the ball to move "
          "it cannot see the pass that was on.",
    "en-GB": "Head up, stick down. A player who has to look at the ball to "
             "move it cannot see the pass that was on.",
    "zh-CN": "抬头，杆压低。必须盯着球才能推球的人，看不到那条本来存在的传球线。",
    "zh-TW": "抬頭，桿壓低。必須盯著球才能推球的人，看不到那條本來存在的傳球線。",
    "ja-JP": "顔を上げ、スティックは下げる。ボールを見ないと運べない選手には、通っていたパスが見えない。",
    "ko-KR": "고개는 들고 스틱은 낮게. 공을 봐야만 움직일 수 있는 선수는 열려 있던 패스를 못 본다.",
    "es-ES": "Cabeza arriba, stick abajo: quien necesita mirar la bola para "
             "moverla no ve el pase que estaba.",
    "fr-FR": "Tête haute, crosse basse : celui qui doit regarder la balle pour "
             "la déplacer ne voit pas la passe qui existait.",
    "id-ID": "Kepala tegak, tongkat rendah.",
    "ms-MY": "Kepala tegak, kayu rendah.",
    "th-TH": "เงยหน้า ไม้ต่ำ",
    "vi-VN": "Ngẩng đầu, gậy thấp.",
}


def warmup_family() -> list[Drill]:
    specs = [("gates", "dribbling gates"), ("pairs", "passing in pairs"),
             ("elimination", "elimination skills")]
    out = []
    for key, label in specs:
        follow, to = 0, []
        if key == "gates":
            home = [P(0.50, 0.80, "1", moves=[(0.30, 0.66, 0), (0.70, 0.54, 1),
                                              (0.40, 0.42, 2)])]
            markers = [M(0.28, 0.66, "cone", ""), M(0.34, 0.66, "cone", ""),
                       M(0.66, 0.54, "cone", ""), M(0.74, 0.54, "cone", ""),
                       M(0.36, 0.42, "cone", ""), M(0.44, 0.42, "cone", "")]
            away = []
        elif key == "pairs":
            home = [P(0.34, 0.72, "1", moves=[(0.38, 0.62, 0)]),
                    P(0.66, 0.60, "2", moves=[(0.62, 0.70, 0)])]
            markers, away = [], []
            follow, to = None, [(1, 0), (0, 1)]
        else:
            # The dodge has to be visible: the cone stands beside the
            # defender, not under him, and 1's route steps off the line and
            # back onto it around a defender who holds his ground.
            home = [P(0.50, 0.76, "1", moves=[(0.38, 0.62, 0), (0.60, 0.48, 1)])]
            markers = [M(0.58, 0.62, "cone", "")]
            away = [P(0.46, 0.60, "D")]
        out.append(Drill(
            id=f"fh_warm_{key}", category="warmup", minutes=8, rel=True,
            free=(key in ("gates", "pairs")),
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            home=home, away=away, markers=markers, ball=0,
            # carried through the gates and round the defender, or knocked
            # between the pair. A carry has to ride every leg: the ball used
            # to stop at the second gate while the player ran on to the third.
            ball_follow=follow, ball_to=to,
        ))
    return out


BUILD_NAME = {
    "en": "Building up", "en-GB": "Building up", "zh-CN": "组织推进",
    "zh-TW": "組織推進", "ja-JP": "ビルドアップ", "ko-KR": "빌드업",
    "es-ES": "Salida de balón", "fr-FR": "Construction",
    "id-ID": "Membangun serangan", "ms-MY": "Membina serangan",
    "th-TH": "การต่อบอลขึ้นเกม", "vi-VN": "Triển khai bóng",
}
BUILD_NOTE = {
    "en": "Move the ball across before you move it forward. Hockey defences "
          "slide fast, but they slide one way at a time.",
    "en-GB": "Move the ball across before you move it forward. Hockey defences "
             "slide fast, but they slide one way at a time.",
    "zh-CN": "先横向转移，再往前推。曲棍球的防守滑得很快，但一次只能往一个方向滑。",
    "zh-TW": "先橫向轉移，再往前推。曲棍球的防守滑得很快，但一次只能往一個方向滑。",
    "ja-JP": "前に運ぶ前に横へ動かす。ホッケーの守備は速くスライドするが、一度に片側へしかスライドできない。",
    "ko-KR": "앞으로 보내기 전에 옆으로 옮겨라. 하키 수비는 빠르게 슬라이드하지만 한 번에 한 방향뿐이다.",
    "es-ES": "Mueve la bola en horizontal antes que hacia delante: las defensas "
             "de hockey bascular rápido, pero solo hacia un lado a la vez.",
    "fr-FR": "Déplace la balle latéralement avant de l'avancer : les défenses "
             "coulissent vite, mais d'un seul côté à la fois.",
    "id-ID": "Pindahkan bola menyamping sebelum ke depan.",
    "ms-MY": "Alihkan bola melintang sebelum ke hadapan.",
    "th-TH": "ย้ายบอลข้างก่อนดันไปข้างหน้า",
    "vi-VN": "Chuyển bóng ngang trước khi đưa lên.",
}


def buildup_family() -> list[Drill]:
    # Three different problems, not one shape at three heights: walking it
    # out of the back across the line, breaking the midfield line with a
    # through ball, and a real switch from one touchline to the other. Each
    # receiver arrives on the beat he is passed to, so the ball is never left
    # standing on a spot its target has already run out of.
    layouts = {
        "from_the_back": (
            [P(0.14, 0.84, "2", moves=[(0.20, 0.76, 0)]),
             P(0.36, 0.86, "5", moves=[(0.40, 0.74, 0)]),
             P(0.64, 0.84, "6", moves=[(0.68, 0.72, 1)]),
             P(0.88, 0.80, "3", moves=[(0.90, 0.68, 1)]),
             P(0.50, 0.60, "8", moves=[(0.56, 0.48, 2)])],
            [P(0.28, 0.60, "D", moves=[(0.26, 0.68, 0)]),
             P(0.58, 0.54, "D", moves=[(0.62, 0.64, 1)]),
             P(0.46, 0.44, "D")],
            [(1, 0), (2, 1), (4, 2)],
        ),
        "through_midfield": (
            [P(0.16, 0.72, "2", moves=[(0.22, 0.62, 0)]),
             P(0.42, 0.64, "5", moves=[(0.46, 0.54, 0)]),
             P(0.70, 0.62, "6", moves=[(0.72, 0.52, 1)]),
             P(0.90, 0.70, "3"),
             # Short of the space he then plays into. He used to finish the
             # run ON the point finish_with appends, so the last beat — "8
             # plays the ball into space" — was a ball leg six units long.
             P(0.54, 0.44, "8", moves=[(0.62, 0.36, 2)])],
            [P(0.32, 0.48, "D", moves=[(0.26, 0.56, 0)]),
             P(0.62, 0.42, "D", moves=[(0.56, 0.50, 1)]),
             P(0.46, 0.28, "D", moves=[(0.42, 0.40, 2)])],
            # 5 receives facing forward and slides it through the last line
            # into the 8's run — the point the drill is named for.
            [(1, 0), (4, 2)],
        ),
        "switching": (
            [P(0.12, 0.76, "2", moves=[(0.18, 0.68, 0)]),
             P(0.34, 0.80, "5", moves=[(0.38, 0.70, 0)]),
             P(0.62, 0.78, "6", moves=[(0.64, 0.66, 1)]),
             P(0.90, 0.74, "3", moves=[(0.88, 0.60, 2)]),
             P(0.50, 0.58, "8", moves=[(0.46, 0.46, 2)])],
            [P(0.26, 0.50, "D", moves=[(0.28, 0.62, 0)]),
             P(0.48, 0.52, "D", moves=[(0.58, 0.60, 1)]),
             P(0.72, 0.48, "D", moves=[(0.80, 0.56, 2)])],
            # "Switching the ball" used to move all five straight up the
            # pitch, x changing by at most 0.04 — no switch anywhere on it.
            # It now crosses the full width, 2 to 3.
            [(1, 0), (2, 1), (3, 2)],
        ),
    }
    specs = [("from_the_back", "from the back"),
             ("through_midfield", "through midfield"),
             ("switching", "switching the ball")]
    out = []
    for key, label in specs:
        home, away, route = layouts[key]
        out.append(Drill(
            id=f"fh_build_{key}", category="possession", minutes=12, rel=True,
            free=(key == "from_the_back"),
            name=suffixed(BUILD_NAME, label), note=BUILD_NOTE,
            home=home, away=away, ball=0, ball_to=route,
        ))
    return out


ENTRY_NAME = {
    "en": "Entering the circle", "en-GB": "Entering the circle",
    "zh-CN": "突入圆圈", "zh-TW": "突入圓圈", "ja-JP": "サークル侵入",
    "ko-KR": "서클 진입", "es-ES": "Entrada al área",
    "fr-FR": "Entrée dans le cercle", "id-ID": "Masuk ke lingkaran",
    "ms-MY": "Masuk ke bulatan", "th-TH": "การเข้าวงกลมยิง", "vi-VN": "Vào vòng cấm",
}
ENTRY_NOTE = {
    "en": "Enter with the ball under control or with a runner beside you — "
          "never with both hands full and nobody in support.",
    "en-GB": "Enter with the ball under control or with a runner beside you — "
             "never with both hands full and nobody in support.",
    "zh-CN": "要么带着控制好的球进去，要么身边有个跑动的人。绝不要两只手都占着、身边一个人都没有地冲进去。",
    "zh-TW": "要麼帶著控制好的球進去，要麼身邊有個跑動的人。絕不要兩隻手都占著、身邊一個人都沒有地衝進去。",
    "ja-JP": "コントロールしたボールを持って入るか、走り込む味方と一緒に入るか。両手が塞がってサポートゼロで入ってはいけない。",
    "ko-KR": "공을 확실히 잡고 들어가거나, 옆에 달려드는 동료와 함께 들어가라.",
    "es-ES": "Entra con la bola controlada o con alguien corriendo a tu lado, "
             "nunca con las manos llenas y sin apoyo.",
    "fr-FR": "Entre avec la balle maîtrisée ou avec un partenaire lancé à côté "
             "— jamais les mains pleines et sans soutien.",
    "id-ID": "Masuk dengan bola terkendali atau dengan rekan yang berlari di sampingmu.",
    "ms-MY": "Masuk dengan bola terkawal atau dengan rakan yang berlari di sisi.",
    "th-TH": "เข้าไปพร้อมบอลที่คุมได้ หรือพร้อมเพื่อนที่วิ่งข้าง ๆ",
    "vi-VN": "Vào với bóng trong tầm kiểm soát hoặc có đồng đội chạy bên cạnh.",
}


def entry_family() -> list[Drill]:
    """Four ways in, four different boards.

    All four used to draw the same sequence — 1 straight up the middle, a
    pass to 2, a square ball to 3 — so "on the overlap" showed no overlap,
    "give and go" never gave the ball back to 1, and "along the baseline"
    never went near the baseline. Each variant is now the thing it is named
    after, and every shot is struck from inside the circle.
    """
    layouts = {
        # 2 goes round the OUTSIDE of the carrier and receives ahead of him.
        "overlap": (
            [P(0.28, 0.48, "1", moves=[(0.24, 0.32, 0)]),
             P(0.42, 0.44, "2", moves=[(0.14, 0.36, 0), (0.16, 0.18, 1),
                                       (0.30, 0.09, 2)]),
             P(0.66, 0.40, "3", moves=[(0.56, 0.16, 1)])],
            [P(0.36, 0.28, "D", moves=[(0.22, 0.22, 1)]),
             P(0.62, 0.24, "D", moves=[(0.66, 0.12, 2)]),
             P(*GOAL, "GK", role="GK")],
            0, [(1, 1), (1, 2)],
        ),
        # 1 -> 2 -> 1: the whole point is that the ball comes back, and 1
        # runs past his marker to collect it inside the circle.
        "give_and_go": (
            [P(0.42, 0.46, "1", moves=[(0.44, 0.24, 1), (0.48, 0.14, 2)]),
             P(0.66, 0.38, "2", moves=[(0.68, 0.20, 2)]),
             P(0.24, 0.34, "3", moves=[(0.28, 0.16, 2)])],
            [P(0.46, 0.36, "D", moves=[(0.60, 0.30, 1)]),
             P(0.66, 0.24, "D", moves=[(0.58, 0.12, 2)]),
             P(*GOAL, "GK", role="GK")],
            None, [(1, 0), (0, 1), (0, 2)],
        ),
        # To the backline and back out: the pull-back from the dead ball is
        # the hardest ball in the circle to defend.
        "baseline": (
            [P(0.82, 0.50, "1", moves=[(0.80, 0.28, 0), (0.74, 0.06, 1)]),
             P(0.56, 0.36, "2", moves=[(0.54, 0.12, 1)]),
             P(0.34, 0.34, "3", moves=[(0.36, 0.09, 1)])],
            [P(0.66, 0.24, "D", moves=[(0.70, 0.14, 1)]),
             P(0.44, 0.20, "D", moves=[(0.60, 0.08, 2)]),
             P(*GOAL, "GK", role="GK")],
            0, [(1, 2), (2, 3)],
        ),
        # A real 3v2: the ball crosses both defenders before anyone shoots.
        "three_v_two": (
            [P(0.20, 0.46, "1", moves=[(0.26, 0.30, 0), (0.32, 0.10, 3)]),
             P(0.48, 0.40, "2", moves=[(0.50, 0.26, 0), (0.56, 0.09, 3)]),
             P(0.78, 0.38, "3", moves=[(0.70, 0.12, 1)])],
            [P(0.38, 0.30, "D", moves=[(0.34, 0.20, 0)]),
             P(0.62, 0.28, "D", moves=[(0.54, 0.18, 1)]),
             P(*GOAL, "GK", role="GK")],
            None, [(0, 0), (1, 1), (2, 2), ((0.52, 0.04), 3)],
        ),
    }
    specs = [("overlap", "on the overlap"), ("give_and_go", "give and go"),
             ("baseline", "along the baseline"), ("three_v_two", "3v2")]
    out = []
    for key, label in specs:
        home, away, follow, route = layouts[key]
        out.append(Drill(
            id=f"fh_entry_{key}", category="attacking", minutes=12, rel=True,
            free=(key in ("overlap", "give_and_go")),
            name=suffixed(ENTRY_NAME, label), note=ENTRY_NOTE,
            home=home, away=away, ball=0,
            ball_follow=follow, ball_to=route,
        ))
    return out


SHOT_NAME = {
    "en": "Shooting", "en-GB": "Shooting", "zh-CN": "射门", "zh-TW": "射門",
    "ja-JP": "シュート", "ko-KR": "슛", "es-ES": "Remate", "fr-FR": "Tir",
    "id-ID": "Tembakan", "ms-MY": "Tembakan", "th-TH": "การยิงประตู", "vi-VN": "Dứt điểm",
}
SHOT_NOTE = {
    "en": "Hit it low and hard at the near post, and put someone on the "
          "rebound. Most hockey goals are the second contact, not the first.",
    "en-GB": "Hit it low and hard at the near post, and put someone on the "
             "rebound. Most hockey goals are the second contact, not the first.",
    "zh-CN": "低、狠、打近角，然后安排一个人补射。曲棍球大多数进球来自第二下触球，不是第一下。",
    "zh-TW": "低、狠、打近角，然後安排一個人補射。曲棍球大多數進球來自第二下觸球，不是第一下。",
    "ja-JP": "ニアポストへ低く強く。そしてこぼれ球に一人置く。ホッケーの得点の多くは一撃目ではなく二撃目だ。",
    "ko-KR": "니어포스트로 낮고 강하게, 그리고 리바운드에 한 명. 하키 골 대부분은 두 번째 터치다.",
    "es-ES": "Golpea raso y fuerte al primer palo y pon a alguien al rechace: "
             "la mayoría de goles son el segundo contacto, no el primero.",
    "fr-FR": "Frappe bas et fort au premier poteau et place quelqu'un sur le "
             "rebond : la plupart des buts sont le second contact.",
    "id-ID": "Pukul rendah dan keras ke tiang dekat, dan siapkan pemantul.",
    "ms-MY": "Pukul rendah dan kuat ke tiang dekat, dan sediakan pemantul.",
    "th-TH": "ยิงต่ำและแรงที่เสาใกล้ แล้ววางคนไว้ที่ลูกกระดอน",
    "vi-VN": "Đánh thấp và mạnh vào cột gần, và bố trí người đón bóng bật ra.",
}


def shooting_family() -> list[Drill]:
    """Four finishes, each struck from where that finish is actually taken.

    Every shooter finishes inside the D — a goal cannot be scored from
    outside it — and the two support players stand at the far post and on
    the rebound rather than on top of the keeper.

    The shot is the last beat. Two of these used to strike on beat two and
    then spend beat three on a support runner jogging in, so a drill called
    "Shooting the tomahawk" ended on somebody moving up the board: the
    supports come in together while the shooter lines it up, and the board
    finishes on the strike.
    """
    layouts = {
        # Low and hard across the face for the far-post touch.
        "deflection": (
            [P(0.30, 0.34, "1", moves=[(0.34, 0.12, 0)]),
             P(0.62, 0.20, "2", moves=[(0.64, 0.07, 1)]),
             P(0.48, 0.24, "3", moves=[(0.44, 0.13, 2)])],
            (0.44, 0.06), [(0, 0), (1, 1), ((RIGHT_POST, 0.03), 2)],
        ),
        # Taken on the move on the right, hit with the reverse stick.
        "reverse": (
            [P(0.72, 0.34, "1", moves=[(0.64, 0.13, 0)]),
             P(0.50, 0.26, "2", moves=[(0.52, 0.14, 1)]),
             P(0.34, 0.20, "3", moves=[(0.32, 0.07, 1)])],
            (0.56, 0.06), [(0, 0), ((LEFT_POST, 0.03), 2)],
        ),
        # The tomahawk is a reverse-edge hit from the top right of the D —
        # it used to be struck from behind the backline, off the pitch.
        "tomahawk": (
            [P(0.80, 0.36, "1", moves=[(0.68, 0.11, 0)]),
             P(0.42, 0.22, "2", moves=[(0.38, 0.09, 1)]),
             P(0.56, 0.28, "3", moves=[(0.54, 0.15, 1)])],
            (0.58, 0.06), [(0, 0), ((LEFT_POST, 0.03), 2)],
        ),
        # Shot, save, second contact: the rebound has to be on the board or
        # the drill is just another straight strike.
        "rebound": (
            [P(0.50, 0.36, "1", moves=[(0.44, 0.15, 0)]),
             P(0.70, 0.24, "2", moves=[(0.62, 0.12, 2)]),
             P(0.32, 0.22, "3", moves=[(0.36, 0.10, 2)])],
            (0.50, 0.09),
            [(0, 0), ((0.48, 0.05), 1), (1, 2), ((LEFT_POST, 0.03), 3)],
        ),
    }
    specs = [("deflection", "the deflection"), ("reverse", "on the reverse"),
             ("tomahawk", "the tomahawk"), ("rebound", "off the rebound")]
    out = []
    for key, label in specs:
        home, gk_end, route = layouts[key]
        out.append(Drill(
            id=f"fh_shot_{key}", category="finishing", minutes=10, rel=True,
            free=(key in ("deflection", "rebound")),
            name=suffixed(SHOT_NAME, label), note=SHOT_NOTE,
            home=home,
            # The keeper covers the shooter's side; the same dive was once
            # copied onto all four boards, so against the two shots from the
            # right he stepped away from the ball.
            away=[P(*GOAL, "GK", role="GK", moves=[gk_end + (1,)])],
            ball=0, ball_to=route,
        ))
    return out


PRESS_NAME = {
    "en": "Press", "en-GB": "Press", "zh-CN": "压迫", "zh-TW": "壓迫",
    "ja-JP": "プレス", "ko-KR": "압박", "es-ES": "Presión", "fr-FR": "Pressing",
    "id-ID": "Pressing", "ms-MY": "Tekanan", "th-TH": "การกดดัน", "vi-VN": "Gây áp lực",
}
PRESS_NOTE = {
    "en": "Show them the sideline and take away the switch. A press that lets "
          "the ball cross the pitch has pressed nobody.",
    "en-GB": "Show them the sideline and take away the switch. A press that "
             "lets the ball cross the pitch has pressed nobody.",
    "zh-CN": "把他们逼向边线，切断转移线路。让球能横传过场的压迫，等于谁也没压到。",
    "zh-TW": "把他們逼向邊線，切斷轉移線路。讓球能橫傳過場的壓迫，等於誰也沒壓到。",
    "ja-JP": "サイドライン側へ追い、サイドチェンジを消す。ボールが逆サイドへ渡るプレスは、誰も追い込んでいない。",
    "ko-KR": "사이드라인 쪽으로 몰고 스위치를 끊어라. 볼이 반대편으로 넘어가는 압박은 압박이 아니다.",
    "es-ES": "Muéstrales la banda y quítales el cambio: una presión que deja "
             "cruzar la bola no ha presionado a nadie.",
    "fr-FR": "Montre la ligne de touche et supprime le renversement : un "
             "pressing qui laisse traverser la balle n'a pressé personne.",
    "id-ID": "Tunjukkan garis pinggir dan tutup opsi menyilang.",
    "ms-MY": "Tunjukkan garisan tepi dan tutup pilihan silang.",
    "th-TH": "ไล่ให้ไปริมเส้นและตัดการเปลี่ยนข้าง",
    "vi-VN": "Đẩy họ ra biên và cắt đường chuyển cánh.",
}


def press_family() -> list[Drill]:
    """The three heights a hockey team actually chooses between.

    Attacking upward: the opponents defend the top goal and build out of the
    circle at the top, so a high press is a line ON their 23 (y ≈ 0.27) with
    the A's above it, and falling back is a block on our own 23 (y ≈ 0.78)
    with the A's coming down at it. Both boards used to put the attackers
    BEHIND the line of pressers, which drew each drill as its own opposite —
    a high press that read as a low block and a low block that read as a
    high press. The two presses step up onto the ball; the low block drops.

    Opponents wear A, B and C, not three A's: the ball starts at B's feet
    and is played infield to A, which is the beat the whole line jumps on.
    """
    layouts = {
        # (D line's y, the line's two moves, the A's, ball at B's feet)
        # A carries into the GAP between two pressers, at 0.17 — the line
        # falls on 0.06 and 0.28, and at 0.20 he finished 29pt from the
        # second of them with 23pt of height between: two points of daylight
        # between the drawn figures, which reads as one man standing on
        # another. The trap is the same trap; he is in the middle of it now.
        "high": (0.42, [(-0.02, 0.27), (-0.10, 0.20)],
                 [P(0.34, 0.12, "A", moves=[(0.17, 0.16, 1)]),
                  P(0.60, 0.09, "B"), P(0.84, 0.15, "C")],
                 (0.556, 0.147), (0.50, 0.56), (0.36, 0.44)),
        "half": (0.64, [(-0.02, 0.49), (-0.10, 0.42)],
                 [P(0.34, 0.33, "A", moves=[(0.17, 0.37, 1)]),
                  P(0.60, 0.30, "B"), P(0.84, 0.36, "C")],
                 (0.556, 0.357), (0.50, 0.78), (0.36, 0.66)),
        "circle": (0.52, [(0.00, 0.66), (0.02, 0.78)],
                   # Landing clear of the line's own starting column, so the
                   # A's do not end on the ghosts the D's leave behind.
                   [P(0.34, 0.34, "A", moves=[(0.28, 0.48, 1)]),
                    P(0.60, 0.30, "B", moves=[(0.64, 0.44, 1)]),
                    P(0.84, 0.36, "C", moves=[(0.88, 0.46, 1)])],
                   # The sweeper sits BEHIND the block, not in it. At 0.62
                   # he stood level with the line the moment it dropped to
                   # 0.66 — 36pt across and 23pt down from the man beside
                   # him, which at this size is a pile, not a cover.
                   (0.556, 0.357), (0.50, 0.80), (0.48, 0.88)),
    }
    specs = [("high", "high"), ("half", "half"),
             ("circle", "falling back to the 23")]
    out = []
    for key, label in specs:
        y, (leg0, leg1), aways, ball, cover, cover_end = layouts[key]
        out.append(Drill(
            id=f"fh_press_{key}", category="defending", minutes=12, rel=True,
            free=(key == "half"),
            name=suffixed(PRESS_NAME, label), note=PRESS_NOTE,
            home=[P(x, y, "D", moves=[(x + leg0[0], leg0[1], 0),
                                      (x + leg1[0], leg1[1], 1)]
                                     # The step in to win it is a real step:
                                     # at (+0.02, -0.03) it was 19pt, under
                                     # what the board draws as a run, so it
                                     # came out as a stub arrow with no start
                                     # floating beside his boots. Mostly up
                                     # the board, not across: across, he
                                     # finished shoulder to shoulder with A.
                                     + ([(x + leg1[0] + 0.01, leg1[1] - 0.07, 2)]
                                        if x == 0.16 else []),
                    why=({0: "press_ball", 1: "press_ball", 2: "win_ball"}
                         if x == 0.16 else {0: "shift", 1: "close_lane"}))
                  for x in (0.16, 0.38, 0.60, 0.82)]
                 + [P(*cover, "D", moves=[cover_end + (1,)])],
            away=aways,
            ball=ball,                  # the attack starts with it, at B
            # infield to A, A carries into the trap the press sets, and the
            # first D takes it: the press has worked when the ball is won
            ball_to=[("a0", 0), ("a0", 1), (0, 2)],
        ))
    return out


CORNER_NAME = {
    "en": "Penalty corner", "en-GB": "Penalty corner", "zh-CN": "短角球",
    "zh-TW": "短角球", "ja-JP": "ペナルティコーナー", "ko-KR": "페널티 코너",
    "es-ES": "Córner corto", "fr-FR": "Corner de pénalité",
    "id-ID": "Penalti sudut", "ms-MY": "Penjuru penalti",
    "th-TH": "ลูกมุมโทษ", "vi-VN": "Phạt góc",
}
CORNER_NOTE = {
    "en": "Injection, stop, strike — and the stop is the one that fails. Drill "
          "the trap on its own until it is boring.",
    "en-GB": "Injection, stop, strike — and the stop is the one that fails. "
             "Drill the trap on its own until it is boring.",
    "zh-CN": "推球、停球、射门——出问题的永远是停球那一下。把停球单独练到无聊为止。",
    "zh-TW": "推球、停球、射門——出問題的永遠是停球那一下。把停球單獨練到無聊為止。",
    "ja-JP": "インジェクション、ストップ、シュート。失敗するのは常にストップだ。トラップだけを退屈になるまで反復する。",
    "ko-KR": "인젝션, 스톱, 슛 — 실패하는 건 언제나 스톱이다. 트래핑만 따로 지겨울 때까지 반복하라.",
    "es-ES": "Saque, parada, remate: lo que falla es la parada. Entrena el "
             "control solo hasta que aburra.",
    "fr-FR": "Injection, blocage, frappe — c'est le blocage qui échoue. "
             "Travaille l'arrêt seul jusqu'à l'ennui.",
    "id-ID": "Injeksi, stop, tembak — yang gagal selalu stopnya.",
    "ms-MY": "Injeksi, hentian, tembakan — yang gagal sentiasa hentian.",
    "th-TH": "ส่งเข้า หยุดบอล แล้วยิง สิ่งที่พลาดคือจังหวะหยุดเสมอ",
    "vi-VN": "Đưa bóng, dừng bóng, dứt điểm — khâu hỏng luôn là dừng bóng.",
}


def setpiece_family() -> list[Drill]:
    out = []
    # The stop is taken a step outside the D, not nine metres behind the
    # 23 m line — from there a drag flick cannot reach the goal at all.
    # The routine is injection (beat 0), slip to the striker (beat 1),
    # strike (beat 2); the four sheets differ in where the ball is slipped
    # to, where the post man goes and where the strike finishes. The stopper
    # clears out of the striker's way instead of standing on him — T and F
    # used to end 22 canvas units apart, one token on top of another.
    # (striker's release, stopper's exit, post runner, strike)
    STOP = (0.50, 0.19)
    specs = [
        ("drag_flick", "the drag flick",
         (0.42, 0.21), (0.30, 0.24), (0.62, 0.20), (0.62, 0.06),
         (LEFT_POST, 0.03), (0.44, 0.07)),
        ("straight_strike", "the straight strike",
         (0.56, 0.21), (0.72, 0.25), (0.36, 0.20), (0.36, 0.06),
         (RIGHT_POST, 0.03), (0.56, 0.07)),
        ("variation_left", "a variation to the left",
         (0.32, 0.20), (0.52, 0.32), (0.62, 0.20), (0.62, 0.06),
         (RIGHT_POST, 0.035), (0.44, 0.07)),
        ("defending_it", "defending it",
         (0.42, 0.21), (0.30, 0.24), (0.62, 0.20), (0.62, 0.06),
         (LEFT_POST, 0.03), (0.52, 0.13)),
    ]
    for key, label, striker, stopper, post, post_end, strike, gk in specs:
        defending = key == "defending_it"
        out.append(Drill(
            id=f"fh_corner_{key}", category="setpiece", minutes=12, rel=True,
            # A penalty corner packs the circle by design.
            tight=True,
            free=(key in ("drag_flick", "defending_it")), off_surface=True,
            name=suffixed(CORNER_NAME, label), note=CORNER_NOTE,
            # I injects from the backline outside the circle (feet off the
            # pitch, as the rule requires), T traps at the top of the D and
            # steps away, F runs onto the slip, and P is the post runner.
            home=[P(0.80, -0.02, "I", moves=[(0.82, 0.15, 1)]),
                  P(*STOP, "T", moves=[stopper + (1,)]),
                  P(0.44, 0.34, "F", moves=[striker + (1,)]),
                  P(post[0], post[1], "P", moves=[post_end + (2,)])],
            away=([P(0.50, 0.045, "GK", role="GK", moves=[gk + (2,)])] + [
                # The four runners break out of the goal the moment the ball
                # is injected. They used to be drawn stacked behind the
                # backline, where space_out threw them off the top of the
                # board; they now start on the goal line and run out as a fan.
                P(x, 0.00, "D", moves=[end + (2,)])
                for x, end in ((0.44, (0.50, 0.23)), (0.56, (0.68, 0.17)),
                               (0.30, (0.34, 0.09)), (0.66, (0.84, 0.07)))
            ]) if defending else
            [P(*GOAL, "GK", role="GK", moves=[gk + (2,)])],
            ball=0,
            # injected, trapped at the top of the D, slipped and struck
            ball_to=[(1, 0), (2, 1), (strike, 2)],
        ))
    out.append(Drill(
        id="fh_set_free_hit", category="setpiece", minutes=8, rel=True,
        # Its own name and note: this drill used to borrow the penalty-corner
        # note, which coaches injection-stop-strike — a free hit has no
        # injection, and its defining option is the self-pass.
        name={"en": "Free hit routine", "en-GB": "Free hit routine",
              "zh-CN": "自由球战术", "zh-TW": "自由球戰術",
              "ja-JP": "フリーヒットの型", "ko-KR": "프리 히트 루틴",
              "es-ES": "Rutina de golpe franco", "fr-FR": "Routine de coup franc",
              "id-ID": "Rutinitas free hit", "ms-MY": "Rutin free hit",
              "th-TH": "แผนลูกฟรีฮิต", "vi-VN": "Bài phạt trực tiếp"},
        note={"en": "Take the self-pass before the defence sets — the free "
                    "hit's whole advantage is the three seconds they need "
                    "to get five metres back.",
              "en-GB": "Take the self-pass before the defence sets — the free "
                       "hit's whole advantage is the three seconds they need "
                       "to get five metres back.",
              "zh-CN": "趁防守没站好就自传自带。自由球的全部优势，就是对手退开五米需要的那三秒钟。",
              "zh-TW": "趁防守沒站好就自傳自帶。自由球的全部優勢，就是對手退開五米需要的那三秒鐘。",
              "ja-JP": "守備が整う前にセルフパスで動かす。フリーヒットの優位は、相手が5m下がるのに要する3秒だけだ。",
              "ko-KR": "수비가 자리 잡기 전에 셀프 패스로 시작하라. 프리 히트의 이점은 상대가 5미터 물러나는 데 걸리는 3초뿐이다.",
              "es-ES": "Juega el autopase antes de que la defensa se coloque: "
                       "la ventaja del golpe franco son los tres segundos que "
                       "tardan en retirarse cinco metros.",
              "fr-FR": "Joue l'auto-passe avant que la défense se place : "
                       "l'avantage du coup franc, ce sont les trois secondes "
                       "qu'il leur faut pour reculer de cinq mètres.",
              "id-ID": "Mainkan self-pass sebelum pertahanan siap.",
              "ms-MY": "Main self-pass sebelum pertahanan bersedia.",
              "th-TH": "เล่น self-pass ก่อนแนวรับตั้งตัว ข้อได้เปรียบคือสามวินาทีที่เขาต้องถอยห้าเมตร",
              "vi-VN": "Tự chuyền cho mình trước khi hàng thủ kịp đứng vững."},
        home=[P(0.20, 0.30, "1", moves=[(0.24, 0.26, 0)]),
              P(0.44, 0.26, "2", moves=[(0.40, 0.20, 1)]),
              P(0.68, 0.24, "3", moves=[(0.60, 0.14, 1)])],
        away=[P(0.32, 0.22, "D"), P(*GOAL, "GK", role="GK")],
        ball=0,
            # taken quickly through 2 into the 3's run at the circle
            ball_to=[(1, 0), (2, 1)],
    ))
    return out


GAME_NAME = {
    "en": "Game", "en-GB": "Game", "zh-CN": "对抗", "zh-TW": "對抗",
    "ja-JP": "ゲーム", "ko-KR": "게임", "es-ES": "Juego", "fr-FR": "Jeu",
    "id-ID": "Permainan", "ms-MY": "Permainan", "th-TH": "เกม", "vi-VN": "Trận đấu",
}
GAME_NOTE = {
    "en": "Play to circle entries rather than goals when you want the build-up "
          "to improve; the finishing will follow the arrivals.",
    "en-GB": "Play to circle entries rather than goals when you want the "
             "build-up to improve; the finishing will follow the arrivals.",
    "zh-CN": "想练组织的时候，就用进圈次数计分，而不是进球。终结能力会跟着进圈次数一起长。",
    "zh-TW": "想練組織的時候，就用進圈次數計分，而不是進球。終結能力會跟著進圈次數一起長。",
    "ja-JP": "ビルドアップを伸ばしたいなら、得点ではなくサークル侵入で点をつける。フィニッシュは侵入回数に付いてくる。",
    "ko-KR": "빌드업을 키우려면 골이 아니라 서클 진입으로 점수를 매겨라.",
    "es-ES": "Puntúa entradas al área en vez de goles cuando quieras mejorar "
             "la construcción: la definición seguirá a las llegadas.",
    "fr-FR": "Compte les entrées de cercle plutôt que les buts quand tu veux "
             "améliorer la construction : la finition suivra.",
    "id-ID": "Beri nilai untuk masuk lingkaran, bukan gol, saat ingin memperbaiki build-up.",
    "ms-MY": "Beri mata untuk masuk bulatan, bukan gol, ketika ingin memperbaiki binaan.",
    "th-TH": "ถ้าจะพัฒนาการต่อบอล ให้นับแต้มจากการเข้าวงกลม ไม่ใช่ประตู",
    "vi-VN": "Tính điểm theo số lần vào vòng cấm thay vì bàn thắng.",
}


def game_family() -> list[Drill]:
    """Small-sided games in a shape, not in two flat rows.

    Both sides used to be a lattice that stepped five metres — no lines, no
    striker, nobody in either circle. Each side now stands in the shape that
    number of players is actually organised in, and the board shows one
    sequence out of the back and into the circle, which is what the note
    asks a coach to score.
    """
    # Home, deepest first; away is the same shape mirrored into the far half.
    shapes = {
        3: [(0.30, 0.78), (0.68, 0.72), (0.48, 0.44)],
        5: [(0.22, 0.84), (0.62, 0.86), (0.34, 0.66), (0.72, 0.62),
            (0.50, 0.40)],
        7: [(0.16, 0.88), (0.36, 0.92), (0.74, 0.86), (0.28, 0.68),
            (0.62, 0.66), (0.88, 0.74), (0.50, 0.40)],
    }
    out = []
    for n in (3, 5, 7):
        spots = shapes[n]
        mid = n // 2
        home = []
        for i, (x, y) in enumerate(spots):
            moves = []
            if i == 0:
                moves = [(x + 0.04, y - 0.12, 0)]
            elif i == mid:
                moves = [(x - 0.05, y - 0.12, 0)]
            elif i == n - 1:
                # Received at the top of the D, then taken in: one pass from
                # halfway to the goal line is not what a circle entry is.
                moves = [(0.52, 0.24, 1), (0.50, 0.12, 2)]
            home.append(P(x, y, f"{i + 1}", moves=moves))
        away = []
        for i, (x, y) in enumerate(spots):
            moves = [(0.58, 0.20, 1)] if i == mid else []
            away.append(P(1 - x, 1 - y, chr(65 + i), moves=moves))
        out.append(Drill(
            id=f"fh_game_{n}v{n}", category="ssg", minutes=15, rel=True,
            free=(n == 5),
            name=suffixed(GAME_NAME, f"{n}v{n}"), note=GAME_NOTE,
            home=home, away=away + [P(*GOAL, "GK", role="GK")],
            ball=0,
            # out of the back, through midfield, into the circle entry the
            # game is scored on
            ball_to=[(mid, 0), (n - 1, 1), (n - 1, 2), ((0.50, 0.04), 3)],
        ))
    return out


TACKLE_NOTE = {
    "en": "Match his speed first, then take the ball. A tackle made while you are still closing is a foul, and the umpire has seen it before you have.",
    "zh-CN": "先跟上他的速度，再去断球。还在冲过去的时候出杆，那是犯规，而且裁判比你先看见。",
    "zh-TW": "先跟上他的速度，再去斷球。還在衝過去的時候出桿，那是犯規，而且裁判比你先看見。",
    "ja-JP": "まず相手のスピードに合わせ、それからボールを奪う。詰めながらのタックルはファウルで、審判の方が先に見ている。",
    "ko-KR": "먼저 상대 속도에 맞춘 다음 공을 뺏어라. 달려들면서 하는 태클은 파울이고, 심판이 먼저 본다.",
    "es-ES": "Iguala primero su velocidad y luego quitale la bola. Una entrada hecha mientras aun te acercas es falta, y el arbitro la ve antes que tu.",
    "fr-FR": "Aligne d abord ta vitesse sur la sienne, puis prends la balle. Un tacle fait en pleine course est une faute, et l arbitre l a vue avant toi.",
    "id-ID": "Samakan dulu kecepatannya, baru ambil bolanya. Tekel sambil masih menutup jarak adalah pelanggaran.",
    "ms-MY": "Samakan dahulu kelajuannya, kemudian rampas bola. Rampasan sambil masih meluru ialah kesalahan.",
    "th-TH": "ปรับความเร็วให้เท่าเขาก่อน แล้วค่อยแย่งบอล เข้าปะทะขณะยังวิ่งเข้าหาคือฟาวล์",
    "vi-VN": "Bắt nhịp tốc độ của anh ta trước, rồi mới lấy bóng. Vào bóng khi còn đang lao tới là phạm lỗi, và trọng tài thấy điều đó trước cả bạn.",
}
AERIAL_NOTE = {
    "en": "Land it in space with nobody under it, and shout early. Five metres is the rule and the receiver cannot claim it if he arrived at the same time as the ball.",
    "zh-CN": "把球落到没人的空当里，并且早喊。五米是规则，接球人和球同时到，就没有优先权。",
    "zh-TW": "把球落到沒人的空檔裡，並且早喊。五米是規則，接球人和球同時到，就沒有優先權。",
    "ja-JP": "誰もいないスペースへ落とし、早くコールする。5メートルがルールで、ボールと同時に着いた受け手に権利はない。",
    "ko-KR": "아무도 없는 공간에 떨어뜨리고 일찍 콜하라. 5미터가 규칙이고, 공과 동시에 도착한 선수는 권리가 없다.",
    "es-ES": "Hazla caer en espacio libre y canta pronto. Cinco metros es la regla, y el receptor no la reclama si llego a la vez que la bola.",
    "fr-FR": "Fais-la retomber dans un espace vide et annonce tot. Cinq metres est la regle, et le receveur ne peut pas la reclamer s il arrive en meme temps que la balle.",
    "id-ID": "Jatuhkan di ruang kosong dan berserulah lebih awal. Lima meter adalah aturannya.",
    "ms-MY": "Jatuhkan di ruang kosong dan bersuara awal. Lima meter ialah peraturannya.",
    "th-TH": "ส่งให้ตกในพื้นที่ว่างและตะโกนเรียกแต่เนิ่น ห้าเมตรคือกติกา",
    "vi-VN": "Thả bóng xuống khoảng trống không có ai bên dưới và gọi sớm. Luật là năm mét, người nhận không được giành bóng nếu đến cùng lúc với bóng.",
}
LONG_CORNER_NOTE = {
    "en": "Taken on the 23 m line, in line with where the ball crossed, so the first pass is already going forward. Standing over it while everyone jogs into place hands the defence the twenty seconds it needed.",
    "en-GB": "Taken on the 23 m line, in line with where the ball crossed, so the first pass is already going forward. Standing over it while everyone jogs into place hands the defence the twenty seconds it needed.",
    "zh-CN": "在23米线上、球出界位置的延长线上开出，第一脚就已经是向前的。站在球边等所有人慢跑就位，等于白送给对方二十秒。",
    "zh-TW": "在23公尺線上、球出界位置的延長線上開出，第一腳就已經是向前的。站在球邊等所有人慢跑就位，等於白送給對方二十秒。",
    "ja-JP": "ボールが出た地点の延長線上、23メートルラインから始める。最初のパスがすでに前向きになる。全員が歩いて配置につくのを待てば、守備に20秒を献上する。",
    "ko-KR": "공이 나간 지점과 같은 선상, 23미터 라인에서 시작하니 첫 패스부터 전방이다. 모두가 자리를 잡을 때까지 기다리면 수비에 20초를 준다.",
    "es-ES": "Se saca en la linea de 23 m, a la altura de donde salio la bola, asi el primer pase ya va hacia adelante. Esperar a que todos troten a su sitio regala veinte segundos a la defensa.",
    "fr-FR": "Joue sur la ligne des 23 m, dans l axe de la sortie de balle, pour que la premiere passe aille deja vers l avant. Attendre que tout le monde se place offre vingt secondes a la defense.",
    "id-ID": "Diambil di garis 23 m, segaris dengan tempat bola keluar, sehingga umpan pertama sudah ke depan.",
    "ms-MY": "Diambil di garisan 23 m, segaris dengan tempat bola keluar, supaya hantaran pertama sudah ke hadapan.",
    "th-TH": "เล่นจากเส้น 23 เมตร ตรงแนวที่บอลออก เพื่อให้จ่ายลูกแรกไปข้างหน้าได้เลย",
    "vi-VN": "Thực hiện trên vạch 23 m, thẳng hàng với điểm bóng ra biên, để đường chuyền đầu tiên đã hướng lên phía trước. Đứng chờ trong khi mọi người chạy chậm vào vị trí là trao cho hàng thủ hai mươi giây họ cần.",
}
COUNTER_NOTE = {
    "en": "Three passes to the circle, not five. Every extra touch is a defender getting back, and hockey's defenders get back very fast.",
    "zh-CN": "三脚球进圈，不是五脚。每多碰一下，就多一个回防到位的人——曲棍球的回防非常快。",
    "zh-TW": "三腳球進圈，不是五腳。每多碰一下，就多一個回防到位的人——曲棍球的回防非常快。",
    "ja-JP": "サークルまで3本、5本ではない。1タッチ増えるごとに守備が1人戻る。ホッケーの戻りは非常に速い。",
    "ko-KR": "서클까지 세 번의 패스로, 다섯 번이 아니라. 터치가 하나 늘 때마다 수비가 한 명 돌아온다.",
    "es-ES": "Tres pases hasta el area, no cinco. Cada toque de mas es un defensor que vuelve, y en hockey vuelven muy rapido.",
    "fr-FR": "Trois passes jusqu au cercle, pas cinq. Chaque touche en plus est un defenseur qui revient, et au hockey ils reviennent tres vite.",
    "id-ID": "Tiga umpan sampai ke lingkaran, bukan lima. Setiap sentuhan tambahan adalah satu bek yang kembali.",
    "ms-MY": "Tiga hantaran ke bulatan, bukan lima. Setiap sentuhan tambahan ialah seorang bek yang kembali.",
    "th-TH": "สามจังหวะจ่ายถึงวงกลม ไม่ใช่ห้า ทุกการสัมผัสที่เกินมาคือกองหลังหนึ่งคนที่กลับมาทัน",
    "vi-VN": "Ba đường chuyền đến vòng tròn, không phải năm. Mỗi lần chạm bóng thừa là một hậu vệ kịp về, và hậu vệ khúc côn cầu về rất nhanh.",
}
FH_GK_NAME = {"en": "Goalkeeping", "en-GB": "Goalkeeping", "zh-CN": "门将训练",
              "zh-TW": "門將訓練", "ja-JP": "GK練習", "ko-KR": "골키퍼 훈련",
              "es-ES": "Porteria", "fr-FR": "Gardien de but", "id-ID": "Latihan kiper",
              "ms-MY": "Latihan penjaga gol", "th-TH": "ฝึกผู้รักษาประตู",
              "vi-VN": "Tap thu mon"}
FH_GK_NOTE = {
    "en": "Come off the line early and small, not late and big. Two metres out takes half the goal away before the shot is even hit.",
    "zh-CN": "早出门线、身形收紧，不要等到最后再张开。出来两米，射门还没打出去就已经封掉半个门。",
    "zh-TW": "早出門線、身形收緊，不要等到最後再張開。出來兩米，射門還沒打出去就已經封掉半個門。",
    "ja-JP": "早く、小さく出る。遅く大きくではない。2メートル出れば、打たれる前にゴールの半分が消える。",
    "ko-KR": "일찍 작게 나가라, 늦게 크게가 아니라. 2미터만 나가도 슛을 맞기 전에 골문 절반이 사라진다.",
    "es-ES": "Sal pronto y pequeno, no tarde y grande: dos metros fuera quitan media porteria antes de que golpeen.",
    "fr-FR": "Sors tot et petit, pas tard et grand : deux metres devant enlevent la moitie du but avant meme la frappe.",
    "id-ID": "Keluar lebih awal dan kecil, bukan terlambat dan besar. Dua meter maju sudah menutup separuh gawang.",
    "ms-MY": "Keluar awal dan kecil, bukan lewat dan besar. Dua meter ke hadapan sudah menutup separuh gol.",
    "th-TH": "ออกมาเร็วและตัวเล็ก ไม่ใช่ช้าและตัวใหญ่ ออกมาสองเมตรก็ปิดประตูไปครึ่งหนึ่งแล้ว",
    "vi-VN": "Rời vạch sớm và thu người nhỏ, đừng ra muộn và dang rộng. Lao ra hai mét là đã che mất nửa khung thành trước khi cú đánh được thực hiện.",
}


def gaps_family() -> list[Drill]:
    """What a hockey coach found missing.

    No tackling in twenty-five drills, no aerial, no long corner, no
    counter-attack — and no goalkeeping at all, on boards that draw a
    goalkeeper eleven times.
    """
    return [
        Drill(
            id="fh_defend_tackle", category="defending", minutes=10, rel=True,
            level="foundation", free=True,
            # A tackle is not a press, and a long corner is not a penalty
            # corner: both borrowed a family name that misfiled them.
            name={"en": "Tackling", "en-GB": "Tackling", "zh-CN": "抢断",
                  "zh-TW": "搶斷", "ja-JP": "タックル", "ko-KR": "태클",
                  "es-ES": "La entrada", "fr-FR": "Le tacle",
                  "id-ID": "Tekel", "ms-MY": "Rampasan",
                  "th-TH": "การแย่งบอล", "vi-VN": "Vào bóng"},
            note=TACKLE_NOTE,
            # The attacker runs at his own goal, so the defender has to be
            # goal-side when the tackle is made: A used to end BEYOND D —
            # beaten defender, ball to the defender — and the ball started
            # loose behind A with nobody to have played it. S serves it in.
            home=[P(0.52, 0.80, "D", moves=[(0.50, 0.68, 0), (0.44, 0.78, 1)])],
            away=[P(0.44, 0.46, "A", moves=[(0.44, 0.60, 0), (0.38, 0.72, 1)]),
                  P(0.30, 0.40, "S")],
            markers=[M(0.30, 0.70), M(0.58, 0.70)],
            # the carrier comes at the tackle; the ball is what changes hands
            ball=(0.35, 0.46),
            ball_to=[("a0", 0), (0, 1)],
        ),
        Drill(
            id="fh_build_aerial", category="possession", minutes=10, rel=True,
            name=suffixed(BUILD_NAME, "with the aerial"), note=AERIAL_NOTE,
            home=[P(0.20, 0.80, "2", moves=[(0.26, 0.70, 0)]),
                  P(0.78, 0.44, "7", moves=[(0.76, 0.34, 1)]),
                  P(0.50, 0.58, "8", moves=[(0.56, 0.50, 1)])],
            away=[P(0.40, 0.60, "D", moves=[(0.32, 0.52, 0)]),
                  P(0.62, 0.56, "D", moves=[(0.60, 0.44, 1)])],
            markers=[M(0.78, 0.40, "zone", "")],
            ball=0,
            # the aerial over both lines, killed by the 7 in the space
            ball_to=[(0, 0), (1, 1)],
        ),
        Drill(
            id="fh_set_long_corner", category="setpiece", minutes=8, rel=True,
            name={"en": "Long corner", "en-GB": "Long corner", "zh-CN": "长角球",
                  "zh-TW": "長角球", "ja-JP": "ロングコーナー", "ko-KR": "롱 코너",
                  "es-ES": "Córner largo", "fr-FR": "Corner long",
                  "id-ID": "Sudut panjang", "ms-MY": "Penjuru panjang",
                  "th-TH": "ลูกมุมยาว", "vi-VN": "Phạt góc dài"},
            note=LONG_CORNER_NOTE,
            # Taken on the 23 m line, in line with where the ball crossed —
            # not from beside the corner flag, which the rules stopped using
            # in 2015. Both receivers arrive on the beat they are passed to;
            # the ball used to be left on a spot its target had already left.
            home=[P(0.92, 0.25, "7", moves=[(0.86, 0.14, 1)]),
                  P(0.62, 0.30, "9", moves=[(0.66, 0.20, 0)]),
                  P(0.40, 0.26, "10", moves=[(0.46, 0.14, 1)])],
            away=[P(0.78, 0.26, "D", moves=[(0.72, 0.15, 0)]),
                  P(0.50, 0.22, "D", moves=[(0.58, 0.10, 1)]),
                  P(*GOAL, "GK", role="GK", moves=[(0.48, 0.07, 2)])],
            ball=0,
            # worked in off the 23 through the 9 and finished by the 10
            ball_to=[(1, 0), (2, 1), ((0.52, 0.04), 2)],
        ),
        Drill(
            id="fh_counter_attack", category="attacking", minutes=12, rel=True,
            level="advanced",
            name={"en": "Counter-attack", "en-GB": "Counter-attack",
                  "zh-CN": "快速反击", "zh-TW": "快速反擊",
                  "ja-JP": "カウンターアタック", "ko-KR": "역습",
                  "es-ES": "Contraataque", "fr-FR": "Contre-attaque",
                  "id-ID": "Serangan balik", "ms-MY": "Serangan balas",
                  "th-TH": "การสวนกลับ", "vi-VN": "Phản công"},
            note=COUNTER_NOTE,
            home=[P(0.30, 0.66, "5", moves=[(0.34, 0.52, 0)]),
                  P(0.14, 0.48, "11", moves=[(0.18, 0.28, 1)]),
                  P(0.62, 0.50, "9", moves=[(0.58, 0.30, 1), (0.52, 0.13, 2)]),
                  P(0.86, 0.46, "7", moves=[(0.84, 0.24, 2)])],
            away=[P(0.44, 0.44, "D", moves=[(0.40, 0.30, 1)]),
                  P(0.70, 0.36, "D", moves=[(0.64, 0.22, 2)]),
                  P(*GOAL, "GK", role="GK", moves=[(0.54, 0.06, 2)])],
            ball=0,
            # Won by the 5, sprung to the 9, carried in and struck. The
            # carry and the strike used to share one beat, which drew the
            # pass from where the 5 had been standing before he broke out
            # and left the ball on its own in the middle of the pitch.
            ball_to=[(0, 0), (2, 1), (2, 2), ((0.50, 0.03), 3)],
        ),
    ] + [
        Drill(
            id=f"fh_gk_{key}", category="goalkeeping", minutes=10, rel=True,
            level=lvl, free=(key == "angles"),
            name=suffixed(FH_GK_NAME, label), note=FH_GK_NOTE,
            home=home,
            away=[P(*GOAL, "GK", role="GK", moves=[gk + (1,)])],
            # The keeper clears to a target wide of the circle, so the
            # clearance has somewhere to be judged against.
            markers=([M(0.90, 0.30, "cone", "")] if key == "clearing" else []),
            ball=0,
            # What each keeper drill actually answers: three of these used
            # to stop at the shot, so the drill named for the rebound had no
            # rebound and the one named for clearing never cleared.
            ball_to=route,
        )
        for key, label, lvl, home, gk, route in [
            ("angles", "angles", "foundation",
             [P(0.32, 0.155, "1", moves=[(0.36, 0.115, 0)]),
              P(0.68, 0.155, "2", moves=[(0.64, 0.115, 0)])], (0.415, 0.055),
             [((0.50, 0.03), 1)]),
            ("first_save", "the first save and the rebound", "development",
             [P(0.50, 0.26, "1", moves=[(0.44, 0.15, 0)]),
              P(0.70, 0.22, "2", moves=[(0.62, 0.11, 2)])], (0.48, 0.09),
             [(0, 0), ((LEFT_POST, 0.05), 1), (1, 2), ((RIGHT_POST, 0.04), 3)]),
            ("one_v_one", "one against one", "development",
             [P(0.50, 0.44, "1", moves=[(0.50, 0.26, 0), (0.45, 0.145, 1)])],
             (0.52, 0.10),
             [(0, 0), (0, 1), ((LEFT_POST, 0.04), 2)]),
            ("clearing", "clearing the circle", "development",
             [P(0.26, 0.22, "1", moves=[(0.32, 0.13, 0)]),
              P(0.76, 0.24, "2", moves=[(0.68, 0.12, 0)])], (0.44, 0.10),
             [(0, 0), ("a0", 1), ((0.92, 0.28), 2)]),
        ]
    ]


# ─────────────────────────────────────────────────────────────────────────────
# 2026-10 expansion: what coaches in the niche asked for and the library did
# not have — more penalty-corner variations at both ends, the corner defence
# with masks, counter-pressing and pressing triggers, playing out against a
# press, aerial outlets, overloads, keeper work, and the two other pitches
# hockey is played on: indoor and Hockey5s.
# ─────────────────────────────────────────────────────────────────────────────

def _l(en, zh, zht, ja, ko, es, fr, id_, ms, th, vi):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht, "ja-JP": ja,
            "ko-KR": ko, "es-ES": es, "fr-FR": fr, "id-ID": id_, "ms-MY": ms,
            "th-TH": th, "vi-VN": vi}


# The indoor pitch (44 x 22 m) and the Hockey5s court (40 x 23.76 m) are drawn
# as tall as the outdoor pitch's box but narrower (FieldHockeyCourtPainter.
# indoorWidthShare / hockey5sWidthShare). Drills on them are written in the
# pitch's own fractions — 0..1 across ITS width — and pulled in here.
INDOOR_SHARE = (22 / 44) / (55 / 91.4)
HOCKEY5S_SHARE = (23.76 / 40) / (55 / 91.4)
# Indoor, in the indoor pitch's fractions: a 3 m goal (posts 0.432 / 0.568),
# a 9 m circle (its top at 0.205 of the 44 m), the penalty spot at 7 m.
IN_LEFT_POST, IN_RIGHT_POST = 0.46, 0.54     # a shot's aim, inside the posts
IN_CIRCLE_Y = 9 / 44


def _on_pitch(d: Drill, court: str, share: float) -> Drill:
    """Move a drill written in another pitch's fractions onto the board."""
    def fx(x):
        assert -0.03 <= x <= 1.03, f"{d.id}: x={x} is off the {court} pitch"
        return round(0.5 + (x - 0.5) * share, 4)

    for p in d.home + d.away:
        p.x = fx(p.x)
        p.moves = [(fx(m[0]), m[1], m[2]) for m in p.moves]
    for m in d.markers:
        m.x = fx(m.x)
    if isinstance(d.ball, tuple):
        d.ball = (fx(d.ball[0]), d.ball[1])
    d.ball_to = [((fx(t[0][0]), t[0][1]), t[1]) if isinstance(t[0], tuple)
                 else t for t in d.ball_to]
    d.court = court
    return d


# ── penalty corner: more ways to score one ──────────────────────────────────
def corner_variations() -> list[Drill]:
    """Four more corners, each named for what makes it different.

    Same rules as the four above: the injector pushes from the backline with
    a foot off the pitch, everybody else waits outside the circle, and the
    ball goes out of the circle (the stop at the top of the D) before anyone
    shoots.
    """
    STOP = (0.50, 0.19)
    inj = lambda end: P(0.80, -0.02, "I", moves=[end + (1,)])
    v = {
        # Stopped, slipped left to a hitter who hits LOW across the face for
        # the man on the right post to deflect in: the first shot is a hit,
        # so it must cross the line below the 460 mm backboard — low by rule.
        "deflection": (
            _l("the deflection", "变线", "變線", "ディフレクション", "디플렉션",
               "el desvío", "la déviation", "defleksi", "pesongan",
               "การเปลี่ยนทางบอล", "đổi hướng"),
            [inj((0.80, 0.12)),
             P(*STOP, "T", moves=[(0.62, 0.26, 1)]),
             P(0.40, 0.32, "H", moves=[(0.40, 0.21, 1)]),
             P(0.64, 0.22, "P", moves=[(0.56, 0.07, 1)])],
            [P(*GOAL, "GK", role="GK", moves=[(0.52, 0.05, 2)])],
            [(1, 0), (2, 1), (3, 2), ((LEFT_POST, 0.03), 3)],
        ),
        # The injector does not stand and watch: he runs in along the
        # backline, the stopper gives it straight back to him, and he
        # finishes at the near post before the runners have turned round.
        "injector_run": (
            _l("the injector's run", "推球人插上", "推球人插上",
               "インジェクターの走り込み", "인젝터의 침투",
               "la carrera del sacador", "la course de l'injecteur",
               "lari pengumpan", "larian pemain injeksi",
               "การวิ่งเข้าของคนส่งบอล", "người đưa bóng băng vào"),
            [P(0.80, -0.02, "I", moves=[(0.70, 0.10, 1)]),
             P(*STOP, "T", moves=[(0.62, 0.27, 2)]),
             P(0.44, 0.34, "F", moves=[(0.44, 0.24, 1)]),
             P(0.34, 0.22, "P", moves=[(0.42, 0.08, 2)])],
            [P(*GOAL, "GK", role="GK", moves=[(0.53, 0.06, 1)])],
            [(1, 0), (0, 1), ((RIGHT_POST, 0.03), 2)],
        ),
        # Two flickers: the first runs over the ball as if to drag it and
        # takes the keeper and the runners with him; the stop is slipped to
        # the second, on the left, who flicks for the post the keeper left.
        "decoy": (
            _l("the decoy", "假动作掩护", "假動作掩護", "おとり", "미끼 러너",
               "el señuelo", "le leurre", "umpan pengecoh", "umpan tipu",
               "ตัวหลอก", "người nghi binh"),
            [inj((0.82, 0.14)),
             P(*STOP, "T", moves=[(0.48, 0.30, 2)]),
             P(0.58, 0.34, "F", moves=[(0.58, 0.23, 1)]),
             P(0.32, 0.32, "G", moves=[(0.38, 0.22, 1)]),
             P(0.70, 0.22, "P", moves=[(0.62, 0.08, 2)])],
            [P(*GOAL, "GK", role="GK", moves=[(0.54, 0.06, 1)])],
            [(1, 0), (3, 1), ((LEFT_POST, 0.03), 2)],
        ),
        # Flick, save, and the man on the post finishes the second ball:
        # most corner goals that are not the first shot are this one.
        "rebound": (
            _l("the rebound", "补射", "補射", "こぼれ球", "리바운드",
               "el rechace", "le rebond", "bola pantul", "bola lantun",
               "ลูกกระดอน", "bóng bật ra"),
            [inj((0.80, 0.13)),
             P(*STOP, "T", moves=[(0.30, 0.25, 1)]),
             P(0.44, 0.34, "F", moves=[(0.42, 0.21, 1)]),
             P(0.64, 0.20, "P", moves=[(0.62, 0.13, 2), (0.56, 0.08, 3)])],
            [P(*GOAL, "GK", role="GK", moves=[(0.46, 0.07, 2)])],
            [(1, 0), (2, 1), ((0.47, 0.05), 2), (3, 3),
             ((RIGHT_POST, 0.03), 4)],
        ),
    }
    out = []
    for key, (label, home, away, route) in v.items():
        out.append(Drill(
            id=f"fh_corner_{key}", category="setpiece", minutes=12, rel=True,
            tight=True, off_surface=True, level="advanced",
            free=(key == "deflection"),
            name=suffixed(CORNER_NAME, label), note=CORNER_NOTE,
            home=home, away=away, ball=0, ball_to=route,
        ))
    return out


# ── penalty corner defence, with masks ──────────────────────────────────────
PCD_NAME = _l("Defending the penalty corner", "防守短角球", "防守短角球",
              "ペナルティコーナーの守備", "페널티 코너 수비",
              "Defensa del córner corto", "Défense du corner de pénalité",
              "Bertahan penalti sudut", "Mempertahankan penjuru penalti",
              "การป้องกันลูกมุมโทษ", "Phòng ngự phạt góc")
PCD_NOTE = _l(
    "Masks on before you leave the goal — they are compulsory for corner "
    "defenders at FIH events and in more leagues every season — and off as "
    "soon as the corner is over. The first runner goes at the ball, not at "
    "the stopper: he arrives as it is stopped, on the flicker's line, stick "
    "low on the side the flick is coming.",
    "离开球门前戴好面罩——国际赛事已强制角球防守者佩戴，越来越多联赛也在跟进——角球一结束就摘下。第一个冲出的人冲向球，不是冲向停球人：在球被停住的那一刻赶到，站在拖射者的出球线上，杆子压低放在球要出来的那一侧。",
    "離開球門前戴好面罩——國際賽事已強制角球防守者佩戴，越來越多聯賽也在跟進——角球一結束就摘下。第一個衝出的人衝向球，不是衝向停球人：在球被停住的那一刻趕到，站在拖射者的出球線上，桿子壓低放在球要出來的那一側。",
    "ゴールを出る前にフェイスマスクを着ける——FIH大会では義務化され、採用するリーグも毎年増えている——そしてコーナーが終わったらすぐ外す。ファーストランナーはストッパーではなくボールへ行く。止まった瞬間にフリッカーのコース上に着き、フリックが来る側にスティックを低く構える。",
    "골문을 나서기 전에 마스크를 쓴다 — FIH 대회에서는 의무이고 해마다 더 많은 리그가 따른다 — 코너가 끝나면 바로 벗는다. 퍼스트 러너는 스토퍼가 아니라 공으로 간다: 공이 멈추는 순간 플리커의 라인 위에 도착해, 플릭이 나올 쪽에 스틱을 낮게 둔다.",
    "Máscara puesta antes de salir de la portería —es obligatoria para los defensores de córner en los torneos FIH y en cada vez más ligas— y fuera en cuanto acaba el córner. El primer corredor va a la bola, no al parador: llega cuando se para, en la línea del arrastrador, con el stick bajo del lado por donde saldrá el arrastre.",
    "Masque mis avant de sortir du but — il est obligatoire pour les défenseurs de corner dans les tournois FIH et dans de plus en plus de ligues — et retiré dès que le corner est terminé. Le premier coureur va vers la balle, pas vers le stoppeur : il arrive quand elle est arrêtée, sur la ligne du dragueur, crosse basse du côté où partira le flick.",
    "Pakai masker sebelum keluar dari gawang — wajib bagi bek penalti sudut di turnamen FIH dan di makin banyak liga — dan lepas begitu penalti sudut selesai. Pelari pertama menuju bola, bukan ke penghenti: tiba saat bola dihentikan, di jalur pemukul drag flick, tongkat rendah di sisi arah flick.",
    "Pakai topeng sebelum keluar dari gol — wajib bagi pemain pertahanan penjuru penalti dalam kejohanan FIH dan semakin banyak liga — dan tanggalkan sebaik penjuru tamat. Pelari pertama menuju bola, bukan kepada penghenti: sampai ketika bola dihentikan, di laluan pemain drag flick, kayu rendah di sisi flick akan datang.",
    "ใส่หน้ากากก่อนออกจากประตู ซึ่งเป็นข้อบังคับสำหรับผู้เล่นรับลูกมุมโทษในรายการของ FIH และลีกอื่น ๆ ก็ทยอยใช้ตาม แล้วถอดทันทีเมื่อจบลูกมุม คนวิ่งออกคนแรกวิ่งเข้าหาบอล ไม่ใช่คนหยุดบอล ไปถึงตอนบอลถูกหยุด อยู่บนแนวของคนลากยิง ไม้ต่ำทางด้านที่ลูกจะออกมา",
    "Đeo mặt nạ trước khi rời khung thành — bắt buộc với người phòng ngự quả phạt góc tại các giải FIH và ngày càng nhiều giải khác — và tháo ra ngay khi quả phạt góc kết thúc. Người lao ra đầu tiên lao vào bóng, không phải vào người dừng bóng: đến nơi đúng lúc bóng được dừng, trên đường bóng của người kéo đẩy, gậy thấp ở phía cú flick sẽ đi.")


def corner_defence() -> list[Drill]:
    """Four defenders and the keeper, starting in the goal.

    By the rules up to five defenders (the keeper among them) start behind
    the backline and the rest go beyond the centre line; they leave the
    line when the ball is pushed out. The defenders are the coach's team
    here, so they are the ones the moves are about: R1 the first runner,
    R2 the second, PO on the left post, LS the line stop on the right.
    """
    STOP = (0.50, 0.19)
    attack = lambda striker, end: [
        P(0.80, -0.02, "I", moves=[(0.80, 0.12, 1)]),
        P(*STOP, "T", moves=[(0.62, 0.27, 2)]),
        P(striker[0], striker[1], "F", moves=[end + (1,)])]
    v = {
        # The first runner gets to the flick as it is struck and smothers
        # it; the keeper has set a step off his line behind him.
        "first_runner": (
            _l("the first runner", "第一冲出人", "第一衝出人",
               "ファーストランナー", "퍼스트 러너", "el primer corredor",
               "le premier coureur", "pelari pertama", "pelari pertama",
               "คนวิ่งออกคนแรก", "người lao ra đầu tiên"),
            attack((0.44, 0.34), (0.42, 0.22)),
            [P(0.50, 0.04, "GK", role="GK", moves=[(0.51, 0.08, 0)]),
             P(0.44, 0.00, "R1", moves=[(0.43, 0.11, 0), (0.44, 0.17, 1)],
               why={0: "press_ball", 1: "press_ball"}),
             P(0.56, 0.00, "R2", moves=[(0.62, 0.11, 0), (0.58, 0.17, 1)],
               why={0: "press_ball", 1: "cover"}),
             P(0.40, 0.00, "PO", moves=[(0.465, 0.012, 0)]),
             P(0.62, 0.00, "LS", moves=[(0.535, 0.012, 0)])],
            # pushed out, stopped, slipped to F, and the flick is blocked by
            # the first runner, who clears it wide
            [(1, 0), (2, 1), ("a1", 2), ((0.08, 0.22), 3)],
        ),
        # Slipped right to a hitter: the runners are beaten, the low hit
        # goes for the right post, and the line stop is the one there.
        "line_stop": (
            _l("post and line stop", "门柱与门线封堵", "門柱與門線封堵",
               "ポストとラインストップ", "포스트와 라인 스톱",
               "poste y bloqueo en línea", "poteau et arrêt sur la ligne",
               "tiang dan penjaga garis", "tiang dan penahan garisan",
               "คนเฝ้าเสาและคนกันบนเส้น", "người giữ cột và chặn trên vạch"),
            attack((0.62, 0.34), (0.60, 0.22)),
            [P(0.50, 0.04, "GK", role="GK", moves=[(0.47, 0.08, 0)]),
             P(0.44, 0.00, "R1", moves=[(0.40, 0.12, 0), (0.50, 0.16, 1)],
               why={0: "press_ball", 1: "press_ball"}),
             P(0.56, 0.00, "R2", moves=[(0.64, 0.10, 0), (0.62, 0.16, 1)],
               why={0: "press_ball", 1: "press_ball"}),
             P(0.40, 0.00, "PO", moves=[(0.465, 0.012, 0)]),
             P(0.62, 0.00, "LS", moves=[(0.535, 0.012, 0), (0.54, 0.03, 2)])],
            [(1, 0), (2, 1), ("a4", 2), ((0.92, 0.10), 3)],
        ),
        # Slipped left instead: the first runner is committed, so the second
        # runner breaks across behind him and the keeper takes the shot.
        "slip": (
            _l("covering the slip", "补防横拨", "補防橫撥",
               "スリップへの対応", "슬립 커버", "cubrir el pase lateral",
               "couvrir la passe latérale", "menutup umpan geser",
               "menutup hantaran sisi", "คุมลูกส่งข้าง",
               "bọc lót đường chuyền ngang"),
            attack((0.36, 0.34), (0.34, 0.22)),
            [P(0.50, 0.04, "GK", role="GK",
               moves=[(0.47, 0.08, 0), (0.43, 0.08, 1)]),
             P(0.44, 0.00, "R1", moves=[(0.54, 0.12, 0), (0.50, 0.16, 1)],
               why={0: "press_ball", 1: "press_ball"}),
             P(0.34, 0.00, "R2", moves=[(0.38, 0.11, 0), (0.36, 0.17, 1)],
               why={0: "press_ball", 1: "cover"}),
             P(0.40, 0.00, "PO", moves=[(0.465, 0.012, 0)]),
             P(0.62, 0.00, "LS", moves=[(0.535, 0.012, 0)])],
            [(1, 0), (2, 1), ("a0", 2), ((0.10, 0.18), 3)],
        ),
    }
    out = []
    for key, (label, home, away, route) in v.items():
        out.append(Drill(
            id=f"fh_pcd_{key}", category="setpiece", minutes=12, rel=True,
            tight=True, off_surface=True, level="advanced",
            free=(key == "first_runner"),
            name=suffixed(PCD_NAME, label), note=PCD_NOTE,
            home=home, away=away, ball=0, ball_to=route,
        ))
    return out


# ── counter-pressing and pressing triggers ──────────────────────────────────
CPRESS_NAME = _l("Counter-press", "反抢", "反搶", "カウンタープレス",
                 "카운터프레스", "Presión tras pérdida", "Contre-pressing",
                 "Counter-press", "Tekanan balas",
                 "การเพรสทันทีหลังเสียบอล", "Phản pressing")
CPRESS_NOTE = _l(
    "The five seconds after losing it are the best chance to win it back: "
    "the man who lost it presses at once, the next two shut the passes out, "
    "and if it is not won by then everyone drops into shape.",
    "丢球后的五秒是抢回来的最好时机：丢球的人立刻压上，旁边两人封住传球线路；五秒内没抢回，所有人退回阵型。",
    "丟球後的五秒是搶回來的最好時機：丟球的人立刻壓上，旁邊兩人封住傳球路線；五秒內沒搶回，所有人退回陣型。",
    "失った直後の5秒が奪い返す最大のチャンスだ。失った本人がすぐにプレスし、近くの2人がパスコースを消す。それまでに奪えなければ全員が陣形に戻る。",
    "잃은 직후 5초가 되찾을 최고의 기회다. 잃은 선수가 즉시 압박하고, 옆의 두 명이 패스 길을 막는다. 그때까지 못 뺏으면 모두 대형으로 돌아간다.",
    "Los cinco segundos tras perderla son la mejor ocasión de recuperarla: quien la pierde presiona al instante, los dos más cercanos cierran los pases, y si no se recupera, todos vuelven a su sitio.",
    "Les cinq secondes après la perte sont la meilleure chance de la récupérer : celui qui l'a perdue presse aussitôt, les deux plus proches ferment les passes, et sinon tout le monde se replace.",
    "Lima detik setelah kehilangan bola adalah peluang terbaik merebutnya kembali: yang kehilangan langsung menekan, dua terdekat menutup jalur umpan; jika gagal, semua kembali ke formasi.",
    "Lima saat selepas kehilangan bola ialah peluang terbaik merampasnya semula: yang kehilangan terus menekan, dua terdekat menutup laluan hantaran; jika gagal, semua kembali ke formasi.",
    "ห้าวินาทีหลังเสียบอลคือโอกาสดีที่สุดที่จะแย่งคืน คนที่เสียบอลเพรสทันที สองคนใกล้สุดปิดทางจ่าย ถ้ายังแย่งไม่ได้ ทุกคนถอยกลับเข้ารูปทรง",
    "Năm giây sau khi mất bóng là cơ hội tốt nhất để đoạt lại: người mất bóng áp sát ngay, hai người gần nhất chặn đường chuyền; nếu không đoạt được, cả đội lùi về đội hình.")

TRIGGER_NAME = _l("Pressing trigger", "压迫信号", "壓迫信號",
                  "プレスのスイッチ", "압박 트리거", "Disparador de presión",
                  "Déclencheur de pressing", "Pemicu pressing",
                  "Isyarat tekanan", "สัญญาณเริ่มเพรส", "Tín hiệu pressing")
TRIGGER_NOTE = _l(
    "Press on a signal, all together: a back pass, a ball played to the "
    "sideline, a heavy first touch. One player going alone is a sprint, not "
    "a press — the line steps up as one or not at all.",
    "看信号一起压：回传、球到边线、第一脚停大了。一个人单独冲上去只是冲刺，不是压迫——整条线要么一起上，要么都不上。",
    "看信號一起壓：回傳、球到邊線、第一腳停大了。一個人單獨衝上去只是衝刺，不是壓迫——整條線要麼一起上，要麼都不上。",
    "合図で全員一緒にプレスする。バックパス、サイドラインへのボール、大きくなったファーストタッチ。一人で行けばただのダッシュで、プレスではない。ラインは揃って上がるか、上がらないかだ。",
    "신호에 맞춰 다 함께 압박한다: 백패스, 사이드라인으로 간 공, 무거운 첫 터치. 혼자 가면 압박이 아니라 질주일 뿐 — 라인은 함께 올라가거나 아예 안 올라간다.",
    "Presiona con una señal y todos a la vez: un pase atrás, una bola a la banda, un mal primer control. Uno solo es un esprint, no una presión: la línea sube junta o no sube.",
    "Presse sur un signal, tous ensemble : une passe en retrait, une balle vers la touche, un premier contrôle raté. Un joueur seul, c'est un sprint, pas un pressing — la ligne monte ensemble ou pas du tout.",
    "Tekan saat ada sinyal, semuanya bersama: umpan balik, bola ke garis samping, sentuhan pertama yang berat. Satu pemain sendirian hanya berlari, bukan pressing — garis naik bersama atau tidak sama sekali.",
    "Tekan apabila ada isyarat, semua serentak: hantaran ke belakang, bola ke garisan tepi, sentuhan pertama yang berat. Seorang sahaja hanyalah pecutan, bukan tekanan — barisan naik bersama atau tidak langsung.",
    "เพรสตามสัญญาณ พร้อมกันทั้งทีม: การจ่ายคืนหลัง บอลไปริมเส้นข้าง การรับบอลแรกหลุด คนเดียววิ่งขึ้นไปคือการวิ่งเร็ว ไม่ใช่การเพรส แนวต้องขึ้นพร้อมกันหรือไม่ขึ้นเลย",
    "Pressing theo tín hiệu, cả đội cùng lúc: đường chuyền về, bóng ra sát biên, cú chạm đầu hỏng. Một người lao lên một mình chỉ là chạy nước rút, không phải pressing — cả hàng cùng dâng hoặc không dâng.")


def pressing_family() -> list[Drill]:
    """Winning it back, and choosing when to go for it.

    Attacking upward, as everywhere in this library: the opponents defend
    the top goal, so a press steps UP the board at them, and a ball won is
    taken on toward the top circle.
    """
    out = []
    # Lost in midfield: A has just won it. 9 who lost it presses straight
    # away, 8 and 10 shut the two outlets, 9 wins it and 10 goes.
    out.append(Drill(
        id="fh_cpress_five_seconds", category="defending", minutes=12,
        rel=True, free=True,
        name=suffixed(CPRESS_NAME, _l(
            "five seconds", "五秒", "五秒", "5秒", "5초", "cinco segundos",
            "cinq secondes", "lima detik", "lima saat", "ห้าวินาที",
            "năm giây")),
        note=CPRESS_NOTE,
        home=[P(0.48, 0.26, "9", moves=[(0.44, 0.35, 0), (0.42, 0.42, 1)],
                why={0: "press_ball", 1: "win_ball"}),
              P(0.24, 0.40, "8", moves=[(0.28, 0.48, 0)],
                why={0: "close_lane"}),
              P(0.70, 0.36, "10", moves=[(0.62, 0.44, 0), (0.64, 0.30, 2)],
                why={0: "close_lane", 2: "get_free"})],
        away=[P(0.40, 0.34, "A", moves=[(0.40, 0.44, 0)]),
              P(0.20, 0.56, "B"), P(0.72, 0.58, "C")],
        # A carries out of the trap, 9 takes it off him, and the ball goes
        # straight back forward to 10
        ball=(0.40, 0.37),
        ball_to=[("a0", 0), (0, 1), (2, 2)],
    ))
    # Lost at the top of their circle: the defender who picked it up is
    # boxed in before he can clear, and the ball is back in the circle.
    out.append(Drill(
        id="fh_cpress_their_circle", category="defending", minutes=12,
        rel=True, level="advanced",
        name=suffixed(CPRESS_NAME, _l(
            "in their circle", "在对方圈内", "在對方圈內", "相手サークル内で",
            "상대 서클 안에서", "en su área", "dans leur cercle",
            "di lingkaran lawan", "dalam bulatan lawan",
            "ในวงของคู่แข่ง", "trong vòng của đối phương")),
        note=CPRESS_NOTE,
        home=[P(0.50, 0.25, "9", moves=[(0.44, 0.20, 0), (0.38, 0.18, 1)],
                why={0: "press_ball", 1: "win_ball"}),
              P(0.20, 0.34, "11", moves=[(0.24, 0.26, 0)],
                why={0: "close_lane"}),
              P(0.70, 0.32, "10", moves=[(0.64, 0.26, 0), (0.56, 0.12, 2)],
                why={0: "close_lane", 2: "get_free"})],
        away=[P(0.42, 0.13, "A", moves=[(0.37, 0.12, 0)]),
              P(0.18, 0.20, "B"), P(0.72, 0.17, "C"),
              P(*GOAL, "GK", role="GK", moves=[(0.53, 0.06, 2)])],
        ball=(0.42, 0.16),
        # A tries to carry it out, 9 wins it on the edge, squares it to 10
        # inside the circle, and 10 finishes
        ball_to=[("a0", 0), (0, 1), (2, 2), ((LEFT_POST, 0.03), 3)],
    ))
    # Back pass: A plays it back to B, which is the signal — the whole line
    # steps up together, 9 takes B, and the ball is won high.
    out.append(Drill(
        id="fh_trigger_back_pass", category="defending", minutes=12,
        rel=True, free=True,
        name=suffixed(TRIGGER_NAME, _l(
            "the back pass", "回传", "回傳", "バックパス", "백패스",
            "el pase atrás", "la passe en retrait", "umpan balik",
            "hantaran ke belakang", "การจ่ายคืนหลัง", "đường chuyền về")),
        note=TRIGGER_NOTE,
        home=[P(0.40, 0.46, "9", moves=[(0.46, 0.30, 1), (0.48, 0.25, 2)],
                why={1: "press_ball", 2: "win_ball"}),
              P(0.64, 0.44, "10", moves=[(0.66, 0.30, 1), (0.60, 0.15, 3)],
                why={1: "close_lane", 3: "get_free"}),
              P(0.18, 0.46, "11", moves=[(0.22, 0.32, 1)],
                why={1: "close_lane"}),
              P(0.46, 0.60, "8", moves=[(0.42, 0.48, 1)],
                why={1: "cover"})],
        away=[P(0.30, 0.36, "A"), P(0.50, 0.22, "B"),
              P(0.80, 0.24, "C"), P(0.16, 0.20, "D")],
        ball=(0.30, 0.39),
        # back to B is the signal; 9 wins it off B and 10 goes in behind
        ball_to=[("a1", 0), (0, 2), (1, 3)],
    ))
    # Sideline: the ball goes out to C on the touchline. 10 presses from the
    # inside, so the line is the second defender, 9 shuts the inside pass.
    out.append(Drill(
        id="fh_trigger_sideline", category="defending", minutes=12,
        rel=True,
        name=suffixed(TRIGGER_NAME, _l(
            "the sideline", "边线", "邊線", "サイドライン", "사이드라인",
            "la banda", "la ligne de touche", "garis samping",
            "garisan tepi", "เส้นข้าง", "đường biên")),
        note=TRIGGER_NOTE,
        home=[P(0.70, 0.46, "10", moves=[(0.84, 0.36, 1), (0.88, 0.31, 2)],
                why={1: "press_ball", 2: "win_ball"}),
              P(0.48, 0.44, "9", moves=[(0.66, 0.32, 1)],
                why={1: "close_lane"}),
              P(0.84, 0.58, "7", moves=[(0.92, 0.42, 1)],
                why={1: "cover"}),
              P(0.30, 0.48, "11", moves=[(0.44, 0.38, 1)],
                why={1: "shift"})],
        away=[P(0.56, 0.26, "A"), P(0.90, 0.30, "C"),
              P(0.62, 0.14, "B"), P(0.24, 0.24, "D")],
        ball=(0.56, 0.29),
        ball_to=[("a1", 0), (0, 2), (1, 3)],
    ))
    # Heavy touch: A's pass to B runs away from him, and the nearest man
    # pounces on the loose ball before B can recover it.
    out.append(Drill(
        id="fh_trigger_heavy_touch", category="defending", minutes=10,
        rel=True,
        name=suffixed(TRIGGER_NAME, _l(
            "the heavy touch", "停球失误", "停球失誤", "トラップミス",
            "무거운 첫 터치", "el mal control", "le contrôle raté",
            "sentuhan berat", "sentuhan berat", "การรับบอลหลุด",
            "chạm bóng hỏng")),
        note=TRIGGER_NOTE,
        home=[P(0.56, 0.44, "9", moves=[(0.54, 0.38, 1)],
                why={1: "press_ball"}),
              P(0.30, 0.44, "8", moves=[(0.36, 0.36, 1)],
                why={1: "close_lane"}),
              P(0.78, 0.42, "10", moves=[(0.72, 0.32, 1), (0.66, 0.22, 2)],
                why={1: "close_lane", 2: "get_free"})],
        away=[P(0.30, 0.28, "A"), P(0.52, 0.30, "B", moves=[(0.50, 0.34, 1)]),
              P(0.78, 0.22, "C")],
        ball=(0.30, 0.31),
        # the pass runs past B; 9 is on it first and finds 10 in behind
        ball_to=[((0.54, 0.38), 0), (0, 1), (2, 2)],
    ))
    return out


# ── playing out against a press, and the aerial outlet ──────────────────────
AERIAL_OUT_NAME = _l("Aerial outlet", "高球出球", "高球出球",
                     "エリアルでの脱出", "에어리얼 아웃렛", "Salida en aérea",
                     "Sortie par une aérienne", "Bola atas untuk keluar",
                     "Bola tinggi untuk keluar", "ลูกโด่งออกจากแรงกด",
                     "Bóng bổng thoát pressing")
AERIAL_OUT_NOTE = _l(
    "The aerial is an outlet, not a hope: land it in space beyond the press "
    "and ahead of the receiver. Nobody may come within 5 m of the first "
    "receiver until it is controlled and on the ground, so whoever gets "
    "under it first owns it.",
    "高球是出球手段，不是碰运气：落到压迫线之后的空当、接球人前方。在球被接住、控好并落地之前，对方不得进入第一接球人5米内，所以谁先到落点球就是谁的。",
    "高球是出球手段，不是碰運氣：落到壓迫線之後的空檔、接球人前方。在球被接住、控好並落地之前，對方不得進入第一接球人5公尺內，所以誰先到落點球就是誰的。",
    "エリアルは脱出の手段で、運任せではない。プレスの背後のスペース、受け手の前方に落とす。最初の受け手がボールをコントロールして地面に置くまで、相手は5m以内に近づけない。だから先に落下点に入った者のボールだ。",
    "에어리얼은 탈출 수단이지 운에 맡기는 공이 아니다. 압박 뒤 공간, 받는 선수 앞쪽에 떨어뜨려라. 첫 리시버가 컨트롤해서 바닥에 내려놓을 때까지 상대는 5m 안에 들어올 수 없으니, 낙하지점에 먼저 간 사람의 공이다.",
    "La aérea es una salida, no una esperanza: déjala caer en el espacio tras la presión y por delante del receptor. Nadie puede acercarse a menos de 5 m del primer receptor hasta que la controle en el suelo, así que es de quien llega primero.",
    "L'aérienne est une sortie, pas un espoir : fais-la retomber dans l'espace derrière le pressing, devant le receveur. Personne ne peut approcher à moins de 5 m du premier receveur avant qu'il l'ait contrôlée au sol : elle est à celui qui arrive le premier.",
    "Bola atas adalah jalan keluar, bukan untung-untungan: jatuhkan di ruang di belakang pressing dan di depan penerima. Lawan tak boleh mendekat dalam 5 m dari penerima pertama sampai bola dikuasai di tanah, jadi bola milik yang lebih dulu tiba.",
    "Bola tinggi ialah jalan keluar, bukan untung nasib: jatuhkan di ruang di belakang tekanan dan di hadapan penerima. Lawan tidak boleh menghampiri dalam 5 m daripada penerima pertama sehingga bola dikawal di tanah, jadi bola milik yang tiba dahulu.",
    "ลูกโด่งคือทางออก ไม่ใช่การเสี่ยงดวง ให้ตกในที่ว่างหลังแนวเพรสและอยู่หน้าคนรับ ฝ่ายตรงข้ามห้ามเข้าใกล้คนรับคนแรกในระยะ 5 เมตรจนกว่าจะรับบอลลงพื้นได้ ใครถึงจุดตกก่อนก็เป็นบอลของคนนั้น",
    "Bóng bổng là lối thoát, không phải cầu may: thả xuống khoảng trống sau tuyến pressing, phía trước người nhận. Đối phương không được vào trong 5 m quanh người nhận đầu tiên cho đến khi bóng được khống chế trên mặt sân, nên ai tới điểm rơi trước thì bóng là của người đó.")


def beating_the_press() -> list[Drill]:
    out = []
    # The third man: 5 into 8 who has dropped, 8 lays it off first time to
    # 6 coming up the inside facing forward, 6 slips 9 in behind.
    out.append(Drill(
        id="fh_build_press_third_man", category="possession", minutes=12,
        rel=True,
        name=suffixed(BUILD_NAME, _l(
            "against the press: the third man", "破压迫：第三人",
            "破壓迫：第三人", "プレス回避：サードマン", "압박 탈출: 서드맨",
            "contra la presión: el tercer hombre",
            "contre le pressing : le troisième homme",
            "melawan pressing: orang ketiga",
            "menentang tekanan: pemain ketiga", "หนีเพรส: คนที่สาม",
            "thoát pressing: người thứ ba")),
        note=BUILD_NOTE,
        home=[P(0.34, 0.86, "5"),
              P(0.50, 0.62, "8", moves=[(0.46, 0.72, 0)],
                why={0: "meet"}),
              P(0.74, 0.82, "6", moves=[(0.64, 0.68, 1)],
                why={1: "third_man"}),
              P(0.30, 0.50, "9", moves=[(0.36, 0.40, 2)],
                why={2: "run_behind"})],
        away=[P(0.40, 0.72, "A", moves=[(0.36, 0.78, 0)]),
              P(0.56, 0.60, "B", moves=[(0.50, 0.66, 0)]),
              P(0.76, 0.62, "C", moves=[(0.70, 0.70, 1)])],
        ball=0,
        ball_to=[(1, 0), (2, 1), (3, 2)],
    ))
    # Three against two: 8 drops between the backs, so two strikers can
    # no longer press three, and the free back carries it out.
    out.append(Drill(
        id="fh_build_press_drop", category="possession", minutes=12,
        rel=True,
        name=suffixed(BUILD_NAME, _l(
            "against the press: the midfielder drops", "破压迫：中场回撤",
            "破壓迫：中場回撤", "プレス回避：ボランチが下りる",
            "압박 탈출: 미드필더 내려오기",
            "contra la presión: baja el medio",
            "contre le pressing : le milieu décroche",
            "melawan pressing: gelandang turun",
            "menentang tekanan: pemain tengah turun",
            "หนีเพรส: กองกลางลงมารับ", "thoát pressing: tiền vệ lùi xuống")),
        note=BUILD_NOTE,
        home=[P(0.26, 0.84, "2", moves=[(0.20, 0.82, 0)], why={0: "width"}),
              P(0.74, 0.84, "3", moves=[(0.80, 0.80, 0), (0.84, 0.66, 2)],
                why={0: "width", 2: "get_free"}),
              P(0.50, 0.62, "8", moves=[(0.50, 0.84, 0)], why={0: "drop_deep"})],
        away=[P(0.40, 0.68, "A", moves=[(0.28, 0.76, 1)]),
              P(0.60, 0.66, "B", moves=[(0.54, 0.76, 1)])],
        ball=0,
        # 2 to 8 in the gap, 8 on to 3 as he steps up the free side, and
        # 3 carries it into the space the press left
        ball_to=[(2, 1), (1, 2), (1, 3)],
    ))
    # Over the press: 5 lifts it over three pressers into the space in
    # front of 7 on the left; D cannot close inside 5 m until it is down.
    out.append(Drill(
        id="fh_aerial_over_press", category="possession", minutes=10,
        rel=True, free=True,
        name=suffixed(AERIAL_OUT_NAME, _l(
            "over the press", "越过压迫", "越過壓迫", "プレスの頭越し",
            "압박 위로", "por encima de la presión", "par-dessus le pressing",
            "melewati pressing", "melepasi tekanan", "ข้ามแนวเพรส",
            "qua đầu pressing")),
        note=AERIAL_OUT_NOTE,
        home=[P(0.44, 0.86, "5"),
              P(0.16, 0.62, "7", moves=[(0.14, 0.48, 0), (0.18, 0.36, 1)],
                why={0: "get_free"})],
        away=[P(0.44, 0.74, "A", moves=[(0.44, 0.80, 0)]),
              P(0.26, 0.70, "B"), P(0.64, 0.72, "C"),
              P(0.38, 0.40, "D", moves=[(0.34, 0.45, 0)])],
        ball=0,
        ball_to=[(1, 0), (1, 1)],
    ))
    # The switch: 2, pressed on the right, lifts it across the whole pitch
    # to 11 who has held the width on the far side.
    out.append(Drill(
        id="fh_aerial_switch", category="possession", minutes=10,
        rel=True,
        name=suffixed(AERIAL_OUT_NAME, _l(
            "the cross-field switch", "大范围转移", "大範圍轉移",
            "逆サイドへの展開", "반대편 전환", "el cambio de orientación",
            "le renversement", "pindah sisi", "tukar sisi",
            "เปลี่ยนข้างไกล", "chuyển cánh dài")),
        note=AERIAL_OUT_NOTE,
        home=[P(0.84, 0.72, "2"),
              P(0.12, 0.56, "11", moves=[(0.10, 0.44, 0), (0.16, 0.32, 1)],
                why={0: "width"})],
        away=[P(0.78, 0.62, "A", moves=[(0.82, 0.66, 0)]),
              P(0.62, 0.56, "B"), P(0.46, 0.50, "C"),
              P(0.32, 0.36, "D", moves=[(0.28, 0.40, 0)])],
        ball=0,
        ball_to=[(1, 0), (1, 1)],
    ))
    return out


# ── into the circle, and the overloads ──────────────────────────────────────
OVERLOAD_NAME = _l("Overload", "以多打少", "以多打少", "数的優位", "수적 우위",
                   "Superioridad", "Surnombre", "Unggul jumlah",
                   "Kelebihan pemain", "ได้เปรียบจำนวน", "Hơn người")
OVERLOAD_NOTE = _l(
    "Commit the defender before you pass: carry at him until he has to "
    "choose, then play the option he did not take. An overload passed too "
    "early becomes two 1v1s.",
    "传球前先把防守人吸过来：带球直冲他，逼他做选择，再传他放掉的那个人。太早出球，以多打少就变成两个一对一。",
    "傳球前先把防守人吸過來：帶球直衝他，逼他做選擇，再傳他放掉的那個人。太早出球，以多打少就變成兩個一對一。",
    "パスの前にディフェンダーを食いつかせる。選ばざるを得なくなるまで運び、彼が選ばなかった方へ出す。早すぎるパスは数的優位を1対1二つに変えてしまう。",
    "패스 전에 수비를 끌어들여라. 선택할 수밖에 없을 때까지 몰고 간 뒤, 그가 고르지 않은 쪽으로 내준다. 너무 일찍 준 패스는 수적 우위를 1대1 두 개로 만든다.",
    "Fija al defensor antes de pasar: condúcela hacia él hasta que tenga que elegir y juega la opción que no tomó. Una superioridad pasada demasiado pronto se convierte en dos 1v1.",
    "Fixe le défenseur avant de passer : porte la balle sur lui jusqu'à ce qu'il doive choisir, puis joue l'option qu'il n'a pas prise. Un surnombre joué trop tôt devient deux 1 contre 1.",
    "Pancing bek sebelum mengumpan: bawa bola ke arahnya sampai ia harus memilih, lalu mainkan opsi yang tidak ia ambil. Umpan terlalu dini mengubah keunggulan jumlah menjadi dua 1 lawan 1.",
    "Tarik pemain pertahanan sebelum menghantar: bawa bola ke arahnya sehingga dia terpaksa memilih, kemudian main pilihan yang tidak diambilnya. Hantaran terlalu awal menjadikan kelebihan itu dua 1 lawan 1.",
    "ดึงกองหลังเข้ามาก่อนจ่าย พาบอลเข้าหาเขาจนเขาต้องเลือก แล้วจ่ายไปทางที่เขาไม่ได้เลือก ถ้าจ่ายเร็วไป ความได้เปรียบจะกลายเป็นตัวต่อตัวสองคู่",
    "Kéo hậu vệ vào trước khi chuyền: dẫn thẳng vào anh ta đến khi buộc phải chọn, rồi chuyền cho phương án anh ta bỏ. Chuyền quá sớm thì lợi thế hơn người thành hai pha 1 đấu 1.")


def attacking_extras() -> list[Drill]:
    out = []
    # The V-drag: the carrier shows the ball to the defender's stick side,
    # drags it back across him in a V and is past him into the circle.
    out.append(Drill(
        id="fh_entry_v_drag", category="attacking", minutes=10, rel=True,
        name=suffixed(ENTRY_NAME, _l(
            "with the V-drag", "V字拉球", "V字拉球", "Vドラッグで",
            "V드래그로", "con el arrastre en V", "avec le V-drag",
            "dengan V-drag", "dengan V-drag", "ด้วยการลากตัววี",
            "với cú kéo chữ V")),
        note=ENTRY_NOTE,
        home=[P(0.46, 0.40, "1", moves=[(0.54, 0.31, 0), (0.42, 0.22, 1),
                                        (0.40, 0.12, 2)])],
        away=[P(0.50, 0.26, "D", moves=[(0.58, 0.27, 1)]),
              P(*GOAL, "GK", role="GK", moves=[(0.46, 0.07, 2)])],
        ball=0,
        ball_to=[(0, 0), (0, 1), (0, 2), ((RIGHT_POST, 0.03), 3)],
    ))
    # In on the left, a reverse hit across the face for the far-post touch.
    out.append(Drill(
        id="fh_entry_reverse_across", category="attacking", minutes=12,
        rel=True, level="advanced",
        name=suffixed(ENTRY_NAME, _l(
            "the reverse across goal", "反手横扫门前", "反手橫掃門前",
            "ゴール前へのリバース", "골문 앞 리버스",
            "el revés cruzado ante la portería", "le revers devant le but",
            "pukulan balik menyilang gawang",
            "pukulan songsang merentasi gol", "ตีแบ็คแฮนด์ตัดหน้าประตู",
            "cú trái tay ngang khung thành")),
        note=ENTRY_NOTE,
        home=[P(0.20, 0.34, "1", moves=[(0.26, 0.22, 0), (0.32, 0.12, 1)]),
              P(0.66, 0.30, "2", moves=[(0.64, 0.18, 1), (0.56, 0.07, 2)],
                why={2: "far_post"})],
        away=[P(0.34, 0.24, "D", moves=[(0.36, 0.17, 1)]),
              P(0.58, 0.20, "D", moves=[(0.62, 0.12, 2)]),
              P(*GOAL, "GK", role="GK", moves=[(0.46, 0.06, 1)])],
        ball=0,
        ball_to=[(0, 0), (0, 1), (1, 2), ((RIGHT_POST, 0.03), 3)],
    ))
    # 2v1: 1 carries at the defender until he commits, then 2 finishes.
    out.append(Drill(
        id="fh_overload_2v1", category="attacking", minutes=10, rel=True,
        free=True,
        name=suffixed(OVERLOAD_NAME, "2v1"), note=OVERLOAD_NOTE,
        home=[P(0.40, 0.42, "1", moves=[(0.44, 0.32, 0)]),
              P(0.70, 0.40, "2", moves=[(0.68, 0.28, 0), (0.62, 0.13, 1)],
                why={0: "width"})],
        away=[P(0.54, 0.26, "D", moves=[(0.48, 0.27, 0), (0.56, 0.19, 1)]),
              P(*GOAL, "GK", role="GK", moves=[(0.54, 0.06, 1)])],
        ball=0,
        ball_to=[(0, 0), (1, 1), ((LEFT_POST, 0.03), 2)],
    ))
    # 4v3 from halfway: the spare man is found by moving the ball, not by
    # dribbling — two passes across before the one in.
    out.append(Drill(
        id="fh_overload_4v3", category="attacking", minutes=12, rel=True,
        name=suffixed(OVERLOAD_NAME, "4v3"), note=OVERLOAD_NOTE,
        home=[P(0.18, 0.46, "11", moves=[(0.16, 0.34, 1), (0.30, 0.13, 3)]),
              P(0.42, 0.46, "10", moves=[(0.42, 0.37, 0)]),
              P(0.64, 0.45, "9", moves=[(0.62, 0.37, 1), (0.54, 0.12, 3)]),
              P(0.86, 0.44, "7", moves=[(0.84, 0.32, 2), (0.74, 0.20, 3)])],
        away=[P(0.30, 0.34, "D", moves=[(0.36, 0.32, 0), (0.26, 0.26, 2)]),
              P(0.52, 0.30, "D", moves=[(0.54, 0.28, 1), (0.62, 0.22, 2)]),
              P(0.74, 0.32, "D", moves=[(0.80, 0.28, 2)]),
              P(*GOAL, "GK", role="GK", moves=[(0.53, 0.06, 3)])],
        ball=1,
        # 10 draws the first defender, 9, then 7 on the outside, and 7 cuts
        # it back for 9 arriving in the circle
        ball_to=[(1, 0), (2, 1), (3, 2), (2, 3), ((LEFT_POST, 0.03), 4)],
    ))
    return out


# ── keepers ──────────────────────────────────────────────────────────────────
def keeper_extras() -> list[Drill]:
    STOP = (0.50, 0.19)
    out = [
        # Against the flick: set a step off the line, still as it is struck,
        # and the save is made with the stick and kickers on the flick side.
        Drill(
            id="fh_gk_drag_flick", category="goalkeeping", minutes=10,
            rel=True, tight=True, off_surface=True, level="advanced",
            name=suffixed(FH_GK_NAME, _l(
                "against the drag flick", "扑拖射", "撲拖射",
                "ドラッグフリック対応", "드래그 플릭 막기",
                "contra el arrastre", "face au flick", "melawan drag flick",
                "menentang drag flick", "รับลูกลากยิง",
                "chống cú kéo đẩy")),
            note=FH_GK_NOTE,
            home=[P(0.80, -0.02, "I", moves=[(0.80, 0.12, 1)]),
                  P(*STOP, "T", moves=[(0.62, 0.26, 1)]),
                  P(0.40, 0.34, "F", moves=[(0.42, 0.22, 1)])],
            away=[P(*GOAL, "GK", role="GK",
                    moves=[(0.49, 0.08, 1), (0.45, 0.08, 2)])],
            ball=0,
            ball_to=[(1, 0), (2, 1), ((0.45, 0.06), 2), ((0.20, 0.10), 3)],
        ),
        # The shoot-out: 8 seconds from the 23 m line, one on one. Come out
        # to meet him, stay up, make him go round — and go round with him.
        Drill(
            id="fh_gk_shoot_out", category="goalkeeping", minutes=10,
            rel=True, free=True,
            name=suffixed(FH_GK_NAME, _l(
                "the shoot-out", "点球大战一对一", "點球大戰一對一",
                "シュートアウト", "슛아웃", "los shoot-outs",
                "les shoot-outs", "adu shoot-out", "penentuan shoot-out",
                "ชู้ตเอาต์", "loạt shoot-out")),
            note=FH_GK_NOTE,
            home=[P(0.50, 0.26, "1", moves=[(0.46, 0.17, 0), (0.58, 0.11, 1)])],
            away=[P(*GOAL, "GK", role="GK",
                    moves=[(0.48, 0.09, 0), (0.54, 0.08, 1)])],
            ball=0,
            ball_to=[(0, 0), (0, 1), ((LEFT_POST, 0.03), 2)],
        ),
        # Reading the deflection: the hit comes across from the left and the
        # keeper moves with the ball, not with the hitter, to the post where
        # the stick is waiting.
        Drill(
            id="fh_gk_deflection", category="goalkeeping", minutes=10,
            rel=True, level="development",
            name=suffixed(FH_GK_NAME, _l(
                "reading the deflection", "预判变线", "預判變線",
                "ディフレクションを読む", "디플렉션 읽기", "leer el desvío",
                "lire la déviation", "membaca defleksi", "membaca pesongan",
                "อ่านลูกเปลี่ยนทาง", "đọc cú đổi hướng")),
            note=FH_GK_NOTE,
            home=[P(0.28, 0.24, "1", moves=[(0.32, 0.15, 0)]),
                  P(0.70, 0.22, "2", moves=[(0.58, 0.08, 0)])],
            away=[P(*GOAL, "GK", role="GK",
                    moves=[(0.44, 0.07, 0), (0.53, 0.07, 1)])],
            ball=0,
            ball_to=[(0, 0), (1, 1), ((0.53, 0.05), 2)],
        ),
    ]
    return out


# ── indoor (zaalhockey / Hallenhockey) ──────────────────────────────────────
INDOOR_RULES = _l(
    "A goal only counts if the ball is played inside the circle. No hitting: "
    "the ball is pushed, and it may only be raised for a shot at goal. The "
    "side-boards are in play; over a board, the other team restarts with a "
    "free push from where it went out.",
    "只有在射门圈内触球后进的才算进球。室内不许击球，只能推，除了射门球不能离地。边板在比赛范围内；球越过边板，由对方在出界处推任意球重新开始。",
    "只有在射門圈內觸球後進的才算進球。室內不許擊球，只能推，除了射門球不能離地。邊板在比賽範圍內；球越過邊板，由對方在出界處推任意球重新開始。",
    "サークル内でプレーされたボールだけが得点になる。ヒットは禁止でプッシュのみ、シュート以外でボールを浮かせてはいけない。サイドボードはプレーの一部。ボードを越えたら、出た地点から相手のフリープッシュで再開。",
    "서클 안에서 플레이된 공만 득점이 된다. 히트는 금지, 푸시만 하고 슛이 아니면 공을 띄울 수 없다. 사이드보드는 경기의 일부이며, 보드를 넘으면 나간 지점에서 상대의 프리 푸시로 재개한다.",
    "Solo es gol si la bola se juega dentro del área. No se golpea: se empuja, y solo se levanta en un tiro a portería. Las bandas están en juego; si la bola las salta, el rival reanuda con un empuje libre desde donde salió.",
    "Un but ne compte que si la balle est jouée dans le cercle. Pas de frappe : on pousse, et la balle ne se lève que pour un tir au but. Les bandes sont en jeu ; si la balle les passe, l'adversaire reprend par une poussée libre à l'endroit de la sortie.",
    "Gol hanya sah jika bola dimainkan di dalam lingkaran. Tidak ada pukulan: bola didorong, dan hanya boleh diangkat untuk tembakan ke gawang. Papan samping bagian dari permainan; jika bola melewati papan, lawan memulai lagi dengan free push dari tempat bola keluar.",
    "Gol hanya sah jika bola dimainkan dalam bulatan. Tiada pukulan: bola ditolak, dan hanya boleh diangkat untuk rembatan ke gol. Papan sisi sebahagian daripada permainan; jika bola melepasi papan, lawan memulakan semula dengan tolakan bebas dari tempat bola keluar.",
    "จะเป็นประตูต้องเล่นบอลในวงยิงเท่านั้น ห้ามตี ใช้การผลัก และยกบอลได้เฉพาะตอนยิงประตู บอร์ดข้างอยู่ในการเล่น ถ้าบอลข้ามบอร์ดออกไป ฝ่ายตรงข้ามเริ่มใหม่ด้วยฟรีพุชตรงจุดที่ออก",
    "Chỉ tính bàn khi bóng được chơi trong vòng sút. Không được đánh: chỉ đẩy, và chỉ được nâng bóng khi sút cầu môn. Tấm biên nằm trong cuộc chơi; bóng vượt qua tấm biên thì đối phương đẩy phạt lại từ chỗ bóng ra.")


def indoor_family() -> list[Drill]:
    """Six drills on the indoor pitch (court="indoor"), written in its own
    fractions: x across its 22 m, y down its 44 m, goal at the top."""
    out = [
        Drill(
            id="fh_in_board_pass", category="attacking", minutes=10,
            rel=True, free=True,
            name=_l("Indoor: playing off the board", "室内：借板传球",
                    "室內：借板傳球", "インドア：ボードを使ったパス",
                    "실내: 보드를 이용한 패스", "Sala: jugar con la banda",
                    "En salle : jouer avec la bande",
                    "Dalam ruang: umpan memantul papan",
                    "Dalam dewan: hantaran lantun papan",
                    "ในร่ม: จ่ายเด้งบอร์ด", "Trong nhà: chuyền bật tường biên"),
            note=_l(
                "The side-board is a team-mate who never misses: play it off "
                "the board past the defender and collect it on the other "
                "side. Push it — indoor the ball may not be hit, and it stays "
                "on the floor except for a shot at goal.",
                "边板是一个从不失误的队友：把球推到板上弹过防守人，在另一侧接回来。只能推——室内不许击球，除了射门，球不能离地。",
                "邊板是一個從不失誤的隊友：把球推到板上彈過防守人，在另一側接回來。只能推——室內不許擊球，除了射門，球不能離地。",
                "サイドボードは絶対にミスしない味方だ。ボードに当ててディフェンダーをかわし、反対側で回収する。打つのではなく押す——インドアではヒットは禁止で、シュート以外ボールを浮かせてはいけない。",
                "사이드보드는 절대 실수하지 않는 동료다. 보드에 맞혀 수비를 지나 반대편에서 다시 잡아라. 밀기만 한다 — 실내에서는 히트가 금지이고, 슛이 아니면 공을 띄울 수 없다.",
                "La banda es un compañero que nunca falla: juega contra ella para superar al defensor y recógela al otro lado. Empuja: en sala no se puede golpear y la bola no se levanta salvo en un tiro a portería.",
                "La bande est un partenaire qui ne rate jamais : joue contre elle pour passer le défenseur et récupère de l'autre côté. Pousse — en salle, la frappe est interdite et la balle ne se lève que pour un tir au but.",
                "Papan samping adalah rekan yang tak pernah salah: pantulkan bola ke papan melewati bek dan ambil di sisi lain. Dorong saja — di dalam ruang bola tidak boleh dipukul dan tidak boleh diangkat kecuali untuk tembakan ke gawang.",
                "Papan sisi ialah rakan yang tidak pernah silap: lantunkan bola ke papan melepasi pemain pertahanan dan ambil di sebelah sana. Tolak sahaja — dalam dewan bola tidak boleh dipukul dan tidak boleh diangkat kecuali untuk rembatan ke gol.",
                "บอร์ดข้างคือเพื่อนร่วมทีมที่ไม่เคยพลาด จ่ายเด้งบอร์ดผ่านกองหลังแล้วไปรับอีกฝั่ง ใช้การผลักเท่านั้น ในร่มห้ามตี และห้ามยกบอลยกเว้นตอนยิงประตู",
                "Tấm biên là đồng đội không bao giờ hỏng: đẩy bóng vào biên để vượt hậu vệ rồi đón lại ở phía bên kia. Chỉ đẩy — trong nhà không được đánh bóng và không được nâng bóng trừ khi sút cầu môn."),
            # 1 pushes it against the right-hand board beside the defender,
            # runs round him, collects the rebound and goes in to shoot.
            home=[P(0.62, 0.58, "1", moves=[(0.70, 0.48, 0), (0.66, 0.38, 1),
                                            (0.84, 0.28, 2), (0.62, 0.17, 3)])],
            away=[P(0.84, 0.42, "D", moves=[(0.80, 0.44, 0)]),
                  P(0.50, 0.03, "GK", role="GK", moves=[(0.53, 0.07, 3)])],
            ball=0,
            ball_to=[(0, 0), ((0.99, 0.36), 1), (0, 2), (0, 3),
                     ((IN_LEFT_POST, 0.02), 4)],
        ),
        Drill(
            id="fh_in_build_212", category="possession", minutes=12,
            rel=True,
            name=_l("Indoor: building out 2-1-2", "室内：2-1-2出球",
                    "室內：2-1-2出球", "インドア：2-1-2のビルドアップ",
                    "실내: 2-1-2 빌드업", "Sala: salida en 2-1-2",
                    "En salle : relance en 2-1-2",
                    "Dalam ruang: membangun 2-1-2",
                    "Dalam dewan: binaan 2-1-2",
                    "ในร่ม: ต่อบอลขึ้นแบบ 2-1-2", "Trong nhà: triển khai 2-1-2"),
            note=_l(
                "Indoor there is no long ball to save you: keep the width "
                "from board to board, give the man on the ball two options "
                "every time, and play it on the floor.",
                "室内没有长传可以救你：两侧贴板拉开宽度，每次都给持球人两个出球选择，球始终贴地走。",
                "室內沒有長傳可以救你：兩側貼板拉開寬度，每次都給持球人兩個出球選擇，球始終貼地走。",
                "インドアには助けてくれるロングボールがない。ボードからボードまで幅を取り、ボール保持者に毎回2つの選択肢を与え、ボールは床の上で運ぶ。",
                "실내에는 위기를 넘길 롱볼이 없다. 보드에서 보드까지 폭을 넓히고, 볼 가진 선수에게 매번 두 개의 선택지를 주며, 공은 바닥으로 보낸다.",
                "En sala no hay balón largo que te salve: mantén la amplitud de banda a banda, da siempre dos opciones al poseedor y juega por el suelo.",
                "En salle, aucun long ballon ne te sauve : garde la largeur de bande à bande, donne toujours deux options au porteur et joue au sol.",
                "Di dalam ruang tak ada bola panjang yang menyelamatkan: jaga lebar dari papan ke papan, beri pembawa bola dua pilihan setiap saat, dan mainkan bola di lantai.",
                "Dalam dewan tiada bola panjang yang menyelamatkan: kekalkan kelebaran dari papan ke papan, beri pembawa bola dua pilihan setiap kali, dan main bola di lantai.",
                "ในร่มไม่มีบอลยาวมาช่วย ยืนกว้างจากบอร์ดถึงบอร์ด ให้คนถือบอลมีทางเลือกสองทางทุกครั้ง และเล่นบอลเรียดพื้น",
                "Trong nhà không có đường chuyền dài cứu nguy: giữ chiều rộng từ biên này sang biên kia, luôn cho người cầm bóng hai lựa chọn, và chơi bóng sát mặt sân."),
            home=[P(0.24, 0.82, "2", moves=[(0.14, 0.76, 0)], why={0: "width"}),
                  P(0.76, 0.82, "3", moves=[(0.86, 0.72, 2)], why={2: "width"}),
                  P(0.50, 0.68, "4", moves=[(0.56, 0.62, 1)], why={1: "support"}),
                  P(0.24, 0.52, "5", moves=[(0.16, 0.56, 0)], why={0: "meet"}),
                  P(0.76, 0.52, "6", moves=[(0.84, 0.40, 3)],
                    why={3: "get_free"})],
            away=[P(0.38, 0.70, "A", moves=[(0.26, 0.76, 0), (0.40, 0.74, 1)]),
                  P(0.62, 0.66, "B", moves=[(0.70, 0.70, 1)])],
            ball=0,
            # out wide on the left, across through the 4 to the 3 on the
            # other board, and up the line to the 6
            ball_to=[(3, 0), (2, 1), (1, 2), (4, 3)],
        ),
        Drill(
            id="fh_in_box_press", category="defending", minutes=12,
            rel=True,
            name=_l("Indoor: the box press", "室内：方块压迫", "室內：方塊壓迫",
                    "インドア：ボックスプレス", "실내: 박스 압박",
                    "Sala: la presión en cuadrado",
                    "En salle : le pressing en carré",
                    "Dalam ruang: pressing kotak", "Dalam dewan: tekanan kotak",
                    "ในร่ม: เพรสแบบกล่อง", "Trong nhà: pressing hình hộp"),
            note=_l(
                "Four in a box, and the board does the fifth man's job: show "
                "the ball to the side-board, close the inside pass, and the "
                "board traps it for you.",
                "四个人站成方块，边板替你干第五个人的活：把球逼向边板，封住内线传球，边板就帮你把球困住。",
                "四個人站成方塊，邊板替你幹第五個人的活：把球逼向邊板，封住內線傳球，邊板就幫你把球困住。",
                "4人でボックスを作り、5人目の仕事はボードがやる。ボールをサイドボードへ追い込み、内側のパスを消せば、ボードが閉じ込めてくれる。",
                "넷이 박스를 만들고, 다섯 번째 선수 몫은 보드가 한다. 공을 사이드보드 쪽으로 몰고 안쪽 패스를 막으면 보드가 가둬 준다.",
                "Cuatro en cuadrado y la banda hace de quinto: lleva la bola hacia la banda, cierra el pase interior y la banda la atrapa por ti.",
                "Quatre en carré, et la bande fait le travail du cinquième : pousse la balle vers la bande, ferme la passe intérieure, et la bande la piège pour toi.",
                "Empat orang membentuk kotak, papan menjalankan tugas orang kelima: giring bola ke papan samping, tutup umpan ke dalam, dan papan menjebaknya untukmu.",
                "Empat orang membentuk kotak, papan menjalankan tugas orang kelima: halakan bola ke papan sisi, tutup hantaran ke dalam, dan papan memerangkapnya untuk anda.",
                "สี่คนยืนเป็นกล่อง บอร์ดทำหน้าที่คนที่ห้า ไล่บอลไปทางบอร์ดข้าง ปิดทางจ่ายเข้าใน แล้วบอร์ดจะขังบอลไว้ให้",
                "Bốn người đứng thành hộp, tấm biên làm thay người thứ năm: dồn bóng ra biên, chặn đường chuyền vào trong, tấm biên sẽ nhốt bóng giúp bạn."),
            # their keeper's side is the top: they build out of it, we box
            # them in against the right-hand board
            home=[P(0.34, 0.40, "1", moves=[(0.44, 0.30, 0), (0.46, 0.17, 3)],
                    why={0: "press_ball", 3: "get_free"}),
                  P(0.66, 0.40, "2", moves=[(0.80, 0.26, 1), (0.86, 0.22, 2)],
                    why={1: "press_ball", 2: "win_ball"}),
                  P(0.34, 0.58, "3", moves=[(0.48, 0.44, 1)],
                    why={1: "close_lane"}),
                  P(0.66, 0.58, "4", moves=[(0.76, 0.42, 1)],
                    why={1: "cover"})],
            away=[P(0.50, 0.22, "A"), P(0.86, 0.30, "B"),
                  P(0.16, 0.28, "C"), P(0.56, 0.44, "D")],
            ball=(0.50, 0.25),
            # A to B on the board is the trap; 2 wins it against the board
            # and finds 1 inside their circle
            ball_to=[("a1", 0), (1, 2), (0, 3)],
        ),
        Drill(
            id="fh_in_corner", category="setpiece", minutes=12, rel=True,
            tight=True, off_surface=True, level="advanced",
            name=suffixed(CORNER_NAME, _l(
                "indoor", "室内", "室內", "インドア", "실내", "en sala",
                "en salle", "dalam ruang", "dalam dewan", "ในร่ม",
                "trong nhà")),
            note=_l(
                "Indoor the push-out is taken from the back-line at least 6 m "
                "from the post, the defenders start behind the line on the "
                "far side of the goal, and there is no hitting — every shot "
                "is a push or a flick. No goal counts until the ball has been "
                "outside the circle, so take it out, stop it and shoot before "
                "the runners arrive.",
                "室内短角球：推球点在底线上、离门柱至少6米，防守方从球门远侧的底线后出发；室内不许击球，射门只能推或挑。球没出过圈就不算进球，所以先让球出圈、停稳，赶在防守冲到之前射门。",
                "室內短角球：推球點在底線上、離門柱至少6公尺，防守方從球門遠側的底線後出發；室內不許擊球，射門只能推或挑。球沒出過圈就不算進球，所以先讓球出圈、停穩，趕在防守衝到之前射門。",
                "インドアのコーナーは、ポストから6m以上離れたバックライン上から押し出し、守備はゴールの反対側のライン外からスタートする。ヒットは禁止で、シュートはプッシュかフリックだけ。ボールが一度サークルの外に出るまで得点にならないので、外で止めて、ランナーが来る前に打つ。",
                "실내 코너는 포스트에서 6m 이상 떨어진 백라인에서 밀어 넣고, 수비는 골문 반대쪽 라인 뒤에서 출발한다. 히트는 금지이고 슛은 푸시나 플릭뿐이다. 공이 서클 밖에 한 번 나가야 득점이 되므로, 밖에서 멈추고 러너가 오기 전에 슛한다.",
                "En sala el saque se hace desde la línea de fondo a al menos 6 m del poste, los defensores salen de detrás de la línea por el lado lejano de la portería y no se golpea: todo tiro es empuje o flick. No hay gol hasta que la bola haya salido del área, así que sácala, párala y tira antes de que lleguen.",
                "En salle, la remise se joue depuis la ligne de fond à au moins 6 m du poteau, les défenseurs partent derrière la ligne du côté opposé du but, et la frappe est interdite : tout tir est une poussée ou un flick. Aucun but avant que la balle soit sortie du cercle : sors-la, arrête-la et tire avant l'arrivée des coureurs.",
                "Di dalam ruang, dorongan dilakukan dari garis belakang minimal 6 m dari tiang, bek mulai dari belakang garis di sisi jauh gawang, dan tidak ada pukulan — setiap tembakan adalah dorongan atau flick. Gol tidak sah sebelum bola keluar lingkaran, jadi keluarkan, hentikan, lalu tembak sebelum pelari tiba.",
                "Dalam dewan, tolakan dibuat dari garisan belakang sekurang-kurangnya 6 m dari tiang, pemain pertahanan bermula di belakang garisan di sisi jauh gol, dan tiada pukulan — setiap rembatan ialah tolakan atau flick. Gol tidak sah sebelum bola keluar bulatan, jadi bawa keluar, hentikan dan rembat sebelum pelari tiba.",
                "ลูกมุมในร่มส่งจากเส้นหลังห่างเสาอย่างน้อย 6 เมตร ฝ่ายรับเริ่มจากหลังเส้นด้านไกลของประตู และห้ามตี ยิงได้แค่ผลักหรือฟลิก บอลต้องออกนอกวงก่อนจึงนับประตู จึงพาออก หยุด แล้วยิงก่อนคนวิ่งมาถึง",
                "Phạt góc trong nhà: đẩy bóng từ đường biên ngang cách cột ít nhất 6 m, hậu vệ xuất phát sau vạch ở phía xa khung thành, và không được đánh — mọi cú sút là đẩy hoặc hất. Bàn chỉ được tính sau khi bóng đã ra ngoài vòng, nên đưa ra, dừng lại và sút trước khi người lao tới."),
            # Injected from 6 m+ right of the post (x ≥ 0.84), foot off the
            # pitch; stopped just outside the circle top (0.205); pushed to
            # the shooter on the left. Defenders on the far (left) side.
            home=[P(0.88, -0.02, "I", moves=[(0.82, 0.10, 1)]),
                  P(0.50, 0.24, "T", moves=[(0.66, 0.30, 1)]),
                  P(0.30, 0.34, "F", moves=[(0.36, 0.23, 1)])],
            away=[P(0.50, 0.03, "GK", role="GK", moves=[(0.46, 0.07, 2)]),
                  P(0.24, -0.02, "D", moves=[(0.38, 0.14, 1)]),
                  P(0.14, -0.02, "D", moves=[(0.28, 0.12, 2)])],
            ball=0,
            ball_to=[(1, 0), (2, 1), ((IN_RIGHT_POST, 0.02), 2)],
        ),
        Drill(
            id="fh_in_gk", category="goalkeeping", minutes=10, rel=True,
            name=suffixed(FH_GK_NAME, _l(
                "indoor: staying on your feet", "室内：保持站立",
                "室內：保持站立", "インドア：立ったまま", "실내: 서서 막기",
                "en sala: de pie", "en salle : rester debout",
                "dalam ruang: tetap berdiri", "dalam dewan: kekal berdiri",
                "ในร่ม: ยืนรับ", "trong nhà: đứng vững")),
            note=_l(
                "Indoor the shots come from close and along the floor: stay "
                "on your feet, small and square, and let the pads and stick "
                "take the low ball. A keeper who goes down early has given "
                "away the flick over him.",
                "室内射门近、多是地滚球：保持站立，身形收紧正对球，让护腿和球杆去挡低球。过早倒地的门将，等于把头顶的挑射送给了对方。",
                "室內射門近、多是地滾球：保持站立，身形收緊正對球，讓護腿和球桿去擋低球。過早倒地的門將，等於把頭頂的挑射送給了對方。",
                "インドアのシュートは近く、床を這ってくる。立ったまま小さく正対し、低いボールはパッドとスティックで止める。早く倒れたキーパーは、頭上へのフリックを差し出している。",
                "실내 슛은 가깝고 바닥으로 온다. 서서 작고 정면으로 서고, 낮은 공은 패드와 스틱으로 막아라. 일찍 넘어진 골키퍼는 머리 위 플릭을 내준 것이다.",
                "En sala los tiros llegan de cerca y a ras de suelo: quédate de pie, compacto y de frente, y deja que las protecciones y el stick paren la bola baja. El portero que se tira pronto regala el flick por encima.",
                "En salle, les tirs viennent de près et au ras du sol : reste debout, compact et face au jeu, laisse les jambières et la crosse prendre la balle basse. Le gardien qui se couche tôt offre le flick par-dessus.",
                "Di dalam ruang tembakan datang dari dekat dan menyusur lantai: tetap berdiri, rapat dan menghadap bola, biarkan pelindung kaki dan tongkat menahan bola rendah. Kiper yang menjatuhkan diri terlalu cepat memberi flick di atasnya.",
                "Dalam dewan rembatan datang dari dekat dan menyusur lantai: kekal berdiri, padat dan menghadap bola, biar pad dan kayu menahan bola rendah. Penjaga gol yang rebah terlalu awal memberi flick di atasnya.",
                "ในร่มลูกยิงมาใกล้และเลียดพื้น ยืนไว้ ตัวเล็ก หันตรง ให้สนับขาและไม้รับลูกต่ำ ผู้รักษาประตูที่ล้มเร็วคือยกลูกฟลิกข้ามหัวให้คู่แข่ง",
                "Trong nhà các cú sút đến gần và sát sàn: đứng vững, thu gọn và đối diện bóng, để giáp chân và gậy chặn bóng thấp. Thủ môn ngã sớm là đã dâng cú hất bóng qua đầu."),
            home=[P(0.26, 0.24, "1", moves=[(0.30, 0.15, 0)]),
                  P(0.74, 0.24, "2", moves=[(0.68, 0.14, 2)])],
            away=[P(0.50, 0.03, "GK", role="GK",
                    moves=[(0.47, 0.06, 0), (0.41, 0.07, 1),
                           (0.56, 0.07, 2)])],
            ball=0,
            # a push at the near post, saved and sent out to 2, whose flick
            # the keeper has to have moved across for
            ball_to=[(0, 0), ((0.42, 0.05), 1), (1, 2),
                     ((IN_RIGHT_POST, 0.03), 3)],
        ),
        Drill(
            id="fh_in_game_5v5", category="ssg", minutes=15, rel=True,
            free=True,
            name=suffixed(GAME_NAME, _l(
                "indoor 5v5", "室内 5v5", "室內 5v5", "インドア 5v5",
                "실내 5v5", "en sala 5v5", "en salle 5v5",
                "dalam ruang 5v5", "dalam dewan 5v5", "ในร่ม 5v5",
                "trong nhà 5v5")),
            note=_l(
                "Five and a keeper a side with the side-boards in play. Count "
                "a goal double when the move used a board pass or a switch — "
                "indoor the gaps come from width, not from running.",
                "每队五人加门将，边板可以利用。如果进球前用过借板传球或横向转移，进球算两分——室内的空当来自宽度，不是靠跑。",
                "每隊五人加門將，邊板可以利用。如果進球前用過借板傳球或橫向轉移，進球算兩分——室內的空檔來自寬度，不是靠跑。",
                "各チーム5人とキーパー、サイドボードも使える。ボードパスかサイドチェンジを経たゴールは2点。インドアの隙間は走りではなく幅から生まれる。",
                "팀당 5명과 골키퍼, 사이드보드도 쓴다. 보드 패스나 전환을 거친 골은 2점 — 실내의 틈은 달리기가 아니라 폭에서 나온다.",
                "Cinco y un portero por equipo, con las bandas en juego. El gol vale doble si la jugada usó la banda o un cambio de lado: en sala los huecos salen de la amplitud, no de correr.",
                "Cinq et un gardien par équipe, bandes en jeu. Le but compte double si l'action a utilisé la bande ou un renversement : en salle, les espaces naissent de la largeur, pas de la course.",
                "Lima pemain dan kiper per tim, papan samping ikut dimainkan. Gol bernilai dua jika serangan memakai pantulan papan atau pindah sisi — di dalam ruang celah datang dari lebar, bukan dari berlari.",
                "Lima pemain dan penjaga gol setiap pasukan, papan sisi dalam permainan. Gol bernilai dua jika serangan menggunakan lantunan papan atau tukar sisi — dalam dewan ruang datang daripada kelebaran, bukan larian.",
                "ฝ่ายละห้าคนกับผู้รักษาประตู ใช้บอร์ดข้างได้ ประตูที่มาจากการจ่ายเด้งบอร์ดหรือเปลี่ยนข้างนับสองแต้ม ในร่มช่องว่างเกิดจากความกว้าง ไม่ใช่จากการวิ่ง",
                "Mỗi đội năm người và thủ môn, tấm biên được dùng. Bàn thắng tính đôi nếu pha bóng có chuyền bật biên hoặc chuyển cánh — trong nhà khoảng trống đến từ chiều rộng, không phải từ chạy."),
            # the 2-1-2 against the 2-1-2 (the formation preset): out of the
            # back, switched across, into the circle
            home=[P(0.30, 0.80, "2", moves=[(0.22, 0.74, 0)]),
                  P(0.70, 0.80, "3"),
                  P(0.50, 0.66, "4", moves=[(0.56, 0.56, 1)]),
                  P(0.30, 0.56, "5", moves=[(0.24, 0.40, 1)]),
                  P(0.70, 0.56, "6", moves=[(0.78, 0.38, 2), (0.62, 0.16, 3)]),
                  P(0.50, 0.95, "GK", role="GK")],
            away=[P(0.70, 0.22, "A"), P(0.30, 0.22, "B"),
                  P(0.50, 0.34, "C", moves=[(0.44, 0.44, 1)]),
                  P(0.70, 0.44, "D", moves=[(0.66, 0.30, 2)]),
                  P(0.30, 0.44, "E"),
                  P(0.50, 0.03, "GK", role="GK", moves=[(0.54, 0.07, 3)])],
            ball=0,
            ball_to=[(2, 1), (4, 2), (4, 3), ((IN_LEFT_POST, 0.02), 4)],
        ),
    ]
    return [_on_pitch(d, "indoor", INDOOR_SHARE) for d in out]


def field_hockey_expansion() -> list[Drill]:
    return (corner_variations() + corner_defence() + pressing_family()
            + beating_the_press() + attacking_extras() + keeper_extras()
            + indoor_family())


# Where a passage was left on the last receiver's stick: the build-ups
# carry the ball into the attacking half, the circle entry and the free hit
# finish on goal, the presses end with the ball won, the aerial is carried
# on by its receiver.
INTO_THE_ATTACKING_HALF = ["fh_build_from_the_back", "fh_build_through_midfield",
                           "fh_build_switching", "fh_build_aerial",
                           "fh_build_press_third_man", "fh_in_build_212"]
FINISH_AT_GOAL = ["fh_entry_baseline", "fh_set_free_hit"]


def field_hockey_library() -> list[Drill]:
    from .engine import finish_with
    drills = (warmup_family() + buildup_family() + entry_family()
              + shooting_family() + press_family() + setpiece_family()
              + game_family() + gaps_family() + field_hockey_expansion())
    finish_with(drills, (0.50, 0.30), INTO_THE_ATTACKING_HALF)
    finish_with(drills, (0.50, 0.04), FINISH_AT_GOAL)
    return drills
