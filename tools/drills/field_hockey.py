"""The field hockey library.

Attacking upward, goal at y=0. The shooting circle is the line that decides
everything: a shot from outside it does not count, so most of these drills are
about arriving inside it with the ball under control rather than just near it.
"""
from .engine import Drill, M, P, suffixed

GOAL = (0.50, 0.02)
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
             P(0.54, 0.44, "8", moves=[(0.58, 0.26, 2)])],
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
    """
    layouts = {
        # Low and hard across the face for the far-post touch.
        "deflection": (
            [P(0.30, 0.34, "1", moves=[(0.34, 0.12, 0)]),
             P(0.62, 0.20, "2", moves=[(0.64, 0.07, 1)]),
             P(0.48, 0.24, "3", moves=[(0.44, 0.13, 2)])],
            (0.44, 0.06), [(0, 0), (1, 1), ((0.56, 0.03), 2)],
        ),
        # Taken on the move on the right, hit with the reverse stick.
        "reverse": (
            [P(0.72, 0.34, "1", moves=[(0.64, 0.13, 0)]),
             P(0.50, 0.26, "2", moves=[(0.52, 0.14, 2)]),
             P(0.34, 0.20, "3", moves=[(0.32, 0.07, 1)])],
            (0.56, 0.06), [(0, 0), ((0.46, 0.03), 1)],
        ),
        # The tomahawk is a reverse-edge hit from the top right of the D —
        # it used to be struck from behind the backline, off the pitch.
        "tomahawk": (
            [P(0.80, 0.36, "1", moves=[(0.68, 0.11, 0)]),
             P(0.42, 0.22, "2", moves=[(0.38, 0.09, 1)]),
             P(0.56, 0.28, "3", moves=[(0.54, 0.15, 2)])],
            (0.58, 0.06), [(0, 0), ((0.44, 0.03), 1)],
        ),
        # Shot, save, second contact: the rebound has to be on the board or
        # the drill is just another straight strike.
        "rebound": (
            [P(0.50, 0.36, "1", moves=[(0.44, 0.15, 0)]),
             P(0.70, 0.24, "2", moves=[(0.62, 0.12, 2)]),
             P(0.32, 0.22, "3", moves=[(0.36, 0.10, 2)])],
            (0.50, 0.09),
            [(0, 0), ((0.48, 0.05), 1), (1, 2), ((0.42, 0.03), 3)],
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
        "high": (0.42, [(-0.02, 0.27), (-0.10, 0.20)],
                 [P(0.34, 0.12, "A", moves=[(0.20, 0.16, 1)]),
                  P(0.60, 0.09, "B"), P(0.84, 0.15, "C")],
                 (0.556, 0.147), (0.50, 0.56), (0.36, 0.44)),
        "half": (0.64, [(-0.02, 0.49), (-0.10, 0.42)],
                 [P(0.34, 0.33, "A", moves=[(0.20, 0.37, 1)]),
                  P(0.60, 0.30, "B"), P(0.84, 0.36, "C")],
                 (0.556, 0.357), (0.50, 0.78), (0.36, 0.66)),
        "circle": (0.52, [(0.00, 0.66), (0.02, 0.78)],
                   # Landing clear of the line's own starting column, so the
                   # A's do not end on the ghosts the D's leave behind.
                   [P(0.34, 0.34, "A", moves=[(0.28, 0.48, 1)]),
                    P(0.60, 0.30, "B", moves=[(0.64, 0.44, 1)]),
                    P(0.84, 0.36, "C", moves=[(0.88, 0.46, 1)])],
                   (0.556, 0.357), (0.50, 0.62), (0.48, 0.88)),
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
                                      (x + leg1[0], leg1[1], 1)])
                  for x in (0.16, 0.38, 0.60, 0.82)]
                 + [P(*cover, "D", moves=[cover_end + (1,)])],
            away=aways,
            ball=ball,                  # the attack starts with it, at B
            # infield to A, and A carries into the trap the press sets
            ball_to=[("a0", 0), ("a0", 1)],
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
         (0.45, 0.03), (0.44, 0.07)),
        ("straight_strike", "the straight strike",
         (0.56, 0.21), (0.72, 0.25), (0.36, 0.20), (0.36, 0.06),
         (0.55, 0.03), (0.56, 0.07)),
        ("variation_left", "a variation to the left",
         (0.32, 0.20), (0.52, 0.32), (0.62, 0.20), (0.62, 0.06),
         (0.56, 0.035), (0.44, 0.07)),
        ("defending_it", "defending it",
         (0.42, 0.21), (0.30, 0.24), (0.62, 0.20), (0.62, 0.06),
         (0.45, 0.03), (0.52, 0.13)),
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
    "vi-VN": "Bat nhip toc do cua anh ta truoc, roi moi lay bong. Vao bong khi con dang lao toi la pham loi.",
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
    "vi-VN": "Tha bong xuong khoang trong khong co ai va goi som. Nam met la luat.",
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
    "vi-VN": "Thuc hien tren vach 23 m, thang hang voi diem bong ra bien, de duong chuyen dau tien da huong len phia truoc.",
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
    "vi-VN": "Ba duong chuyen den vong cam, khong phai nam. Moi cham bong thua la mot hau ve kip ve.",
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
    "vi-VN": "Ra som va thu nguoi, khong phai ra muon va dang rong. Ra hai met la da bit nua khung thanh.",
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
             [(0, 0), ((0.46, 0.05), 1), (1, 2), ((0.56, 0.04), 3)]),
            ("one_v_one", "one against one", "development",
             [P(0.50, 0.44, "1", moves=[(0.50, 0.26, 0), (0.45, 0.145, 1)])],
             (0.52, 0.10),
             [(0, 0), (0, 1), ((0.42, 0.04), 2)]),
            ("clearing", "clearing the circle", "development",
             [P(0.26, 0.22, "1", moves=[(0.32, 0.13, 0)]),
              P(0.76, 0.24, "2", moves=[(0.68, 0.12, 0)])], (0.44, 0.10),
             [(0, 0), ("a0", 1), ((0.92, 0.28), 2)]),
        ]
    ]


def field_hockey_library() -> list[Drill]:
    return (warmup_family() + buildup_family() + entry_family()
            + shooting_family() + press_family() + setpiece_family()
            + game_family() + gaps_family())
