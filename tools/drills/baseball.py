"""The baseball library.

The field is square, with home plate at the bottom and the outfield at the
top. Baseball's drills are situations rather than shapes: the same nine
fielders stand in nearly the same places every time, and what changes is who
is on base and what everyone has already agreed to do about it.
"""
from .engine import Drill, M, P, suffixed

HOME, FIRST, SECOND, THIRD = (0.50, 0.92), (0.68, 0.74), (0.50, 0.56), (0.32, 0.74)
MOUND = (0.50, 0.78)
# Standard defensive alignment.
D = {
    "P": (0.50, 0.78), "C": (0.50, 0.97), "1B": (0.66, 0.70), "2B": (0.58, 0.63),
    "SS": (0.42, 0.63), "3B": (0.34, 0.70), "LF": (0.22, 0.36),
    "CF": (0.50, 0.28), "RF": (0.78, 0.36),
}


def defence(*, without=(), shifted=None) -> list[P]:
    """The nine, optionally moved. `shifted` maps a position to a new spot."""
    shifted = shifted or {}
    out = []
    for name, spot in D.items():
        if name in without:
            continue
        end = shifted.get(name)
        out.append(P(*spot, name,
                     role="GK" if name == "P" else None,
                     moves=[end + (0,)] if end else []))
    return out


WARM_NAME = {
    "en": "Warm-up", "en-GB": "Warm-up", "zh-CN": "热身", "zh-TW": "熱身",
    "ja-JP": "ウォームアップ", "ko-KR": "웜업", "es-ES": "Calentamiento",
    "fr-FR": "Échauffement", "id-ID": "Pemanasan", "ms-MY": "Memanaskan badan",
    "th-TH": "วอร์มอัพ", "vi-VN": "Khởi động",
}
WARM_NOTE = {
    "en": "Throw to a target, on a line, every time. Arms warm up fine on lazy "
          "throws; footwork and accuracy do not.",
    "en-GB": "Throw to a target, on a line, every time. Arms warm up fine on "
             "lazy throws; footwork and accuracy do not.",
    "zh-CN": "每一次都传向目标，走直线。随便甩几下手臂也能热开，但脚下和准头热不开。",
    "zh-TW": "每一次都傳向目標，走直線。隨便甩幾下手臂也能熱開，但腳下和準頭熱不開。",
    "ja-JP": "毎回、的に向かって一直線に投げる。肩は雑な送球でも温まるが、足の運びと精度は温まらない。",
    "ko-KR": "매번 목표를 향해 일직선으로 던져라. 팔은 대충 던져도 풀리지만 발과 정확도는 안 풀린다.",
    "es-ES": "Tira a un objetivo, en línea, siempre: el brazo se calienta con "
             "tiros flojos, los pies y la puntería no.",
    "fr-FR": "Vise une cible, à plat, à chaque fois : le bras se chauffe sur "
             "des lancers mous, pas les appuis ni la précision.",
    "id-ID": "Lempar ke target, lurus, setiap kali.",
    "ms-MY": "Baling ke sasaran, lurus, setiap kali.",
    "th-TH": "ขว้างไปที่เป้าเป็นเส้นตรงทุกครั้ง",
    "vi-VN": "Ném vào mục tiêu, theo đường thẳng, mọi lần.",
}


def warmup_family() -> list[Drill]:
    specs = [("long_toss", "long toss"), ("infield_outfield", "infield and outfield"),
             ("pitchers_fielding", "pitchers fielding practice")]
    out = []
    for key, label in specs:
        if key == "long_toss":
            home = [P(0.30, 0.86, "1", moves=[(0.30, 0.78, 0)]),
                    P(0.30, 0.42, "2", moves=[(0.30, 0.50, 0)])]
            away = []
        elif key == "infield_outfield":
            home = defence(without=("C",))
            for p in home:
                p.moves = [(p.x + (0.5 - p.x) * 0.12, p.y + 0.04, 0)]
            away = []
        else:
            home = [P(*MOUND, "P", role="GK",
                      moves=[(0.44, 0.86, 0), (0.62, 0.74, 1)]),
                    P(*D["1B"], "1B", moves=[(0.68, 0.74, 1)])]
            away = []
        out.append(Drill(
            id=f"bb_warm_{key}", category="warmup", minutes=10, rel=True,
            free=(key in ("long_toss", "infield_outfield")),
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            home=home, away=away,
            markers=[M(*HOME, "square", "")],
            ball=0,
            # thrown between the stations of the warm-up
            ball_to=([(1, 0), (0, 1)] if len(home) == 2 else [(3, 0), (1, 1)]),
        ))
    return out


DP_NAME = {
    "en": "Double play", "en-GB": "Double play", "zh-CN": "双杀",
    "zh-TW": "雙殺", "ja-JP": "ダブルプレー", "ko-KR": "병살",
    "es-ES": "Doble matanza", "fr-FR": "Double retrait",
    "id-ID": "Double play", "ms-MY": "Double play",
    "th-TH": "ดับเบิลเพลย์", "vi-VN": "Loại kép",
}
DP_NOTE = {
    "en": "The feed decides the double play, not the arm. Give the pivot man "
          "the ball chest high and slightly ahead of the bag.",
    "en-GB": "The feed decides the double play, not the arm. Give the pivot "
             "man the ball chest high and slightly ahead of the bag.",
    "zh-CN": "决定双杀的是那一记传递，不是臂力。要把球送到接应人胸口高度、垒包稍前方。",
    "zh-TW": "決定雙殺的是那一記傳遞，不是臂力。要把球送到接應人胸口高度、壘包稍前方。",
    "ja-JP": "併殺を決めるのは肩ではなくトス。ピボットの胸の高さ、ベースのやや手前へ渡す。",
    "ko-KR": "병살을 결정하는 건 어깨가 아니라 토스다. 피벗의 가슴 높이, 베이스 약간 앞으로 줘라.",
    "es-ES": "La entrega decide el doble play, no el brazo: dale la bola a la "
             "altura del pecho y algo por delante de la base.",
    "fr-FR": "C'est la transmission qui fait le double jeu, pas le bras : "
             "donne la balle à hauteur de poitrine, un peu devant le coussin.",
    "id-ID": "Umpan yang menentukan double play, bukan lengan.",
    "ms-MY": "Hantaran yang menentukan double play, bukan lengan.",
    "th-TH": "สิ่งที่ตัดสินดับเบิลเพลย์คือการส่งต่อ ไม่ใช่แรงแขน",
    "vi-VN": "Đường chuyền quyết định loại kép, không phải sức tay.",
}


def double_play_family() -> list[Drill]:
    specs = [("six_four_three", "6-4-3", "SS", "2B"),
             ("four_six_three", "4-6-3", "2B", "SS"),
             ("five_four_three", "5-4-3", "3B", "2B"),
             ("one_six_three", "1-6-3", "P", "SS")]
    out = []
    for key, label, starter, pivot in specs:
        out.append(Drill(
            id=f"bb_dp_{key}", category="possession", minutes=12, rel=True,
# A runner stands on the bag the fielder is covering.
tight=True,
            free=(key in ("six_four_three", "four_six_three")),
            name=suffixed(DP_NAME, label), note=DP_NOTE,
            home=defence(shifted={starter: (D[starter][0] + 0.03, D[starter][1] + 0.03),
                                  pivot: SECOND, "1B": FIRST}),
            away=[P(*HOME, "B", moves=[(0.60, 0.84, 1), FIRST + (2,)]),
                  P(*FIRST, "R", moves=[SECOND + (1,)])],
            markers=[M(*HOME, "square", ""), M(*FIRST, "square", ""),
                     M(*SECOND, "square", ""), M(*THIRD, "square", "")],
            # The feed and the turn. Four double plays used to be conveyed
            # by fielders drifting toward bags, with no ball in flight
            # anywhere in the library.
            ball=(D[starter][0] + 0.05, D[starter][1] + 0.05),
            ball_moves=[(SECOND[0] + 0.02, SECOND[1] + 0.02, 1),
                        (FIRST[0] + 0.02, FIRST[1] - 0.02, 2)],
        ))
    return out


CUT_NAME = {
    "en": "Cut-off and relay", "en-GB": "Cut-off and relay",
    "zh-CN": "中继与切传", "zh-TW": "中繼與切傳", "ja-JP": "カットオフと中継",
    "ko-KR": "중계 플레이", "es-ES": "Corte y relevo",
    "fr-FR": "Relais et interception", "id-ID": "Cut-off dan relay",
    "ms-MY": "Cut-off dan relay", "th-TH": "การรับต่อและส่งต่อ", "vi-VN": "Chuyền tiếp",
}
CUT_NOTE = {
    "en": "Line the relay up between the ball and the base, and call for it "
          "loudly. A cut man nobody can see is a cut man nobody uses.",
    "en-GB": "Line the relay up between the ball and the base, and call for it "
             "loudly. A cut man nobody can see is a cut man nobody uses.",
    "zh-CN": "中继人要站在球和垒包的连线上，并且大声喊。看不见的中继人，就是没人会用的中继人。",
    "zh-TW": "中繼人要站在球和壘包的連線上，並且大聲喊。看不見的中繼人，就是沒人會用的中繼人。",
    "ja-JP": "中継はボールとベースを結ぶ線上に立ち、大声で呼ぶ。見えないカットマンは、誰も使わないカットマンだ。",
    "ko-KR": "중계는 공과 베이스를 잇는 선 위에 서서 크게 불러라. 보이지 않는 컷맨은 아무도 쓰지 않는다.",
    "es-ES": "Colócate en la línea entre la bola y la base, y pide a gritos: "
             "un cortador invisible es un cortador que nadie usa.",
    "fr-FR": "Place-toi sur la ligne entre la balle et la base, et appelle "
             "fort : un relayeur qu'on ne voit pas ne sert à personne.",
    "id-ID": "Berdirilah di garis antara bola dan base, dan berteriaklah.",
    "ms-MY": "Berdiri di garisan antara bola dan base, dan menjerit meminta.",
    "th-TH": "ยืนบนเส้นระหว่างบอลกับเบส แล้วตะโกนเรียกให้ดัง",
    "vi-VN": "Đứng trên đường nối bóng và chốt, và gọi thật to.",
}


def relay_family() -> list[Drill]:
    # Who goes out for the relay depends on which way the ball went: the
    # shortstop on a ball to left, the second baseman on a ball to right,
    # and the other one covers second. The gap ball had the shortstop
    # crossing the whole diamond while the second baseman stood still.
    specs = [("to_home", "to home", "LF", (0.30, 0.50), HOME, "SS", "2B"),
             ("to_third", "to third", "CF", (0.44, 0.44), THIRD, "SS", "2B"),
             ("gap_ball", "on the gap ball", "RF", (0.66, 0.48), THIRD, "2B", "SS")]
    out = []
    for key, label, fielder, relay, target, relay_man, cover in specs:
        chase = (D[fielder][0] - 0.06, D[fielder][1] - 0.08)
        out.append(Drill(
            id=f"bb_relay_{key}", category="possession", minutes=10, rel=True,
            free=(key == "to_home"),
            name=suffixed(CUT_NAME, label), note=CUT_NOTE,
            home=defence(shifted={fielder: chase, relay_man: relay,
                                  cover: SECOND}),
            away=[P(*SECOND, "R", moves=[
                ((SECOND[0] + THIRD[0]) / 2 - 0.03, (SECOND[1] + THIRD[1]) / 2, 1),
                THIRD + (2,)]
                if target is not HOME else [
                ((SECOND[0] + THIRD[0]) / 2 - 0.03, (SECOND[1] + THIRD[1]) / 2, 1),
                THIRD + (2,), HOME + (3,)])],
            markers=[M(*target, "zone", ""), M(*SECOND, "square", ""),
                     M(*THIRD, "square", "")],
            ball=(chase[0], chase[1] - 0.02),
            # Outfielder to the relay man to the base: the throw the whole
            # drill is about, and it was never on the board.
            ball_moves=[relay + (1,), target + (2,)],
        ))
    return out


RUN_NAME = {
    "en": "Baserunning", "en-GB": "Baserunning", "zh-CN": "跑垒",
    "zh-TW": "跑壘", "ja-JP": "走塁", "ko-KR": "주루",
    "es-ES": "Corrido de bases", "fr-FR": "Course sur les buts",
    "id-ID": "Lari base", "ms-MY": "Larian base",
    "th-TH": "การวิ่งเบส", "vi-VN": "Chạy chốt",
}
RUN_NOTE = {
    "en": "Read the pitcher's front heel, not the ball. By the time you see "
          "the ball the decision has already been made without you.",
    "en-GB": "Read the pitcher's front heel, not the ball. By the time you see "
             "the ball the decision has already been made without you.",
    "zh-CN": "看投手的前脚跟，不要看球。等你看到球，这个决定已经在没有你参与的情况下做完了。",
    "zh-TW": "看投手的前腳跟，不要看球。等你看到球，這個決定已經在沒有你參與的情況下做完了。",
    "ja-JP": "ボールではなく投手の前足のかかとを読む。ボールが見えた時には、判断はもう自分抜きで終わっている。",
    "ko-KR": "공이 아니라 투수의 앞발 뒤꿈치를 읽어라. 공이 보일 때면 판단은 이미 끝나 있다.",
    "es-ES": "Lee el talón delantero del lanzador, no la bola: cuando ves la "
             "bola, la decisión ya se tomó sin ti.",
    "fr-FR": "Lis le talon avant du lanceur, pas la balle : quand tu vois la "
             "balle, la décision s'est déjà prise sans toi.",
    "id-ID": "Baca tumit depan pelempar, bukan bolanya.",
    "ms-MY": "Baca tumit hadapan pembaling, bukan bolanya.",
    "th-TH": "อ่านส้นเท้าหน้าของพิตเชอร์ ไม่ใช่ดูลูกบอล",
    "vi-VN": "Đọc gót chân trước của người ném, đừng nhìn bóng.",
}


def baserunning_family() -> list[Drill]:
    """Five situations, each with the runner touching the bases he must.

    They used to interpolate a straight line from start to end, so first-
    to-third crossed the middle of the diamond without touching second and
    scoring from second ran over the pitcher's mound without touching
    third — both runners out for missing a base. The steal read and the
    hit-and-run were also byte-identical boards, and the secondary lead
    drew a steal of third.
    """
    # key, label, the runner's route (bases in order), what the rest does
    specs = [
        ("steal_read", "reading the steal", [FIRST, SECOND], "steal"),
        ("hit_and_run", "the hit and run", [FIRST, SECOND], "hit_and_run"),
        ("tag_up", "tagging up", [THIRD, HOME], "tag"),
        ("first_to_third", "first to third", [FIRST, SECOND, THIRD], "read"),
        ("secondary_lead", "the secondary lead", [SECOND], "lead"),
    ]
    out = []
    for key, label, route, kind in specs:
        start = route[0]
        moves, phase = [], 0
        # The lead comes first in every one of them.
        lead = (start[0] + (route[-1][0] - start[0]) * 0.14,
                start[1] + (route[-1][1] - start[1]) * 0.14)
        moves.append(lead + (phase,))
        phase += 1
        if kind == "lead":
            # Two shuffles as the ball crosses the plate, then back — not a
            # sprint to the next bag, which is a steal.
            moves.append(((lead[0] + start[0]) / 2 - 0.03,
                          (lead[1] + start[1]) / 2 + 0.02, phase))
            moves.append(start + (phase + 1,))
        else:
            for base in route[1:]:
                # Round the bag from the outside, then touch it.
                prev = moves[-1][:2]
                moves.append(((prev[0] + base[0]) / 2 + (base[0] - 0.5) * 0.06,
                              (prev[1] + base[1]) / 2 + 0.02, phase))
                moves.append(base + (phase + 1,))
                phase += 2
        batter = {
            "steal": [(0.545, 0.90, 1)],
            # The batter has to swing at whatever comes: that is the play.
            "hit_and_run": [(0.545, 0.90, 0), (0.60, 0.86, 1)],
            "tag": [(0.545, 0.90, 0)],
            "read": [(0.60, 0.87, 0), (0.655, 0.755, 1)],
            "lead": [(0.545, 0.90, 1)],
        }[kind]
        # On a hit-and-run the middle infielder breaks to cover, which is
        # the hole the batter is hitting into.
        shifted = {"2B": (0.62, 0.60)} if kind == "hit_and_run" else None
        out.append(Drill(
            id=f"bb_run_{key}", category="attacking", minutes=10, rel=True,
            # A runner stands on the bag the fielder is covering.
            tight=True,
            free=(key in ("steal_read", "hit_and_run")),
            name=suffixed(RUN_NAME, label), note=RUN_NOTE,
            # The defence is the home side on every other board in the
            # library; it used to flip to red for these five and the five
            # scoring boards, so the nine fielders changed colour halfway
            # through the sport.
            home=defence(without=("LF", "CF", "RF"), shifted=shifted),
            away=[P(*start, "R", moves=moves), P(*HOME, "B", moves=batter)],
            markers=[M(*HOME, "square", ""), M(*FIRST, "square", ""),
                     M(*SECOND, "square", ""), M(*THIRD, "square", "")],
            ball=(MOUND[0], MOUND[1] - 0.01),
            ball_moves=[(HOME[0], HOME[1] - 0.02, 1)],
        ))
    return out


SCORE_NAME = {
    "en": "Scoring the run", "en-GB": "Scoring the run", "zh-CN": "回本垒得分",
    "zh-TW": "回本壘得分", "ja-JP": "生還", "ko-KR": "득점 상황",
    "es-ES": "Anotar la carrera", "fr-FR": "Marquer le point",
    "id-ID": "Mencetak run", "ms-MY": "Menjaringkan run",
    "th-TH": "การทำแต้ม", "vi-VN": "Ghi điểm",
}
SCORE_NOTE = {
    "en": "Decide before the pitch whether you are going on contact. A runner "
          "who decides at the plate is a runner thrown out at the plate.",
    "en-GB": "Decide before the pitch whether you are going on contact. A "
             "runner who decides at the plate is a runner thrown out at the plate.",
    "zh-CN": "投球之前就决定是不是击中就跑。到了本垒前才做决定的跑者，就是在本垒被传杀的跑者。",
    "zh-TW": "投球之前就決定是不是擊中就跑。到了本壘前才做決定的跑者，就是在本壘被傳殺的跑者。",
    "ja-JP": "投球前に、打った瞬間に走るかどうかを決めておく。本塁手前で迷う走者は、本塁で刺される走者だ。",
    "ko-KR": "투구 전에 접촉 시 뛸지 정하라. 홈 앞에서 정하는 주자는 홈에서 잡히는 주자다.",
    "es-ES": "Decide antes del lanzamiento si sales con el contacto: quien lo "
             "decide en el plato es quien muere en el plato.",
    "fr-FR": "Décide avant le lancer si tu pars au contact : celui qui décide "
             "au marbre est celui qu'on retire au marbre.",
    "id-ID": "Putuskan sebelum lemparan apakah kamu lari saat kontak.",
    "ms-MY": "Tentukan sebelum balingan sama ada anda lari ketika kontak.",
    "th-TH": "ตัดสินใจก่อนขว้างว่าจะออกวิ่งเมื่อโดนบอลหรือไม่",
    "vi-VN": "Quyết định trước khi ném xem có chạy khi chạm bóng không.",
}


def scoring_family() -> list[Drill]:
    specs = [("contact_play", "the contact play", (0.42, 0.60)),
             ("squeeze", "the squeeze", (0.46, 0.86)),
             ("from_second", "scoring from second", (0.30, 0.44))]
    out = []
    for key, label, ball_at in specs:
        start = THIRD if key != "from_second" else SECOND
        out.append(Drill(
            id=f"bb_score_{key}", category="finishing", minutes=10, rel=True,
# A runner stands on the bag the fielder is covering.
tight=True,
            free=(key == "contact_play"),
            name=suffixed(SCORE_NAME, label), note=SCORE_NOTE,
            home=[P(*start, "R", moves=[(start[0] + (0.5 - start[0]) * 0.4,
                                         (start[1] + HOME[1]) / 2, 1), HOME + (2,)]),
                  P(*HOME, "B", moves=[(0.58, 0.88, 1), FIRST + (2,)])],
            away=defence(without=("LF", "RF")),
            markers=[M(*HOME, "zone", "")],
            ball=ball_at,               # where the batted ball goes
            # the ball comes home as the runner does — the race the play is
            ball_to=[("a1", 1)],
        ))
    return out


DEF_NAME = {
    "en": "Defending the situation", "en-GB": "Defending the situation",
    "zh-CN": "局面防守", "zh-TW": "局面防守", "ja-JP": "状況の守備",
    "ko-KR": "상황 수비", "es-ES": "Defensa de la situación",
    "fr-FR": "Défense de situation", "id-ID": "Bertahan dalam situasi",
    "ms-MY": "Bertahan dalam situasi", "th-TH": "การรับตามสถานการณ์",
    "vi-VN": "Phòng thủ theo tình huống",
}
DEF_NOTE = {
    "en": "Say the play out loud before the pitch — every fielder, every time. "
          "Silence is how two players end up covering the same base.",
    "en-GB": "Say the play out loud before the pitch — every fielder, every "
             "time. Silence is how two players end up covering the same base.",
    "zh-CN": "投球之前把这一球怎么防说出来——每个野手，每一次。不说话，就会出现两个人守同一个垒。",
    "zh-TW": "投球之前把這一球怎麼防說出來——每個野手，每一次。不說話，就會出現兩個人守同一個壘。",
    "ja-JP": "投球前に、どう守るかを声に出す。全員、毎回。黙っているから二人が同じベースに入る。",
    "ko-KR": "투구 전에 어떻게 수비할지 소리 내어 말하라. 침묵은 두 사람이 같은 베이스를 덮게 만든다.",
    "es-ES": "Di la jugada en voz alta antes del lanzamiento, todos y siempre: "
             "el silencio hace que dos cubran la misma base.",
    "fr-FR": "Annonce l'action à voix haute avant le lancer, chacun, à chaque "
             "fois : le silence, c'est deux joueurs sur le même but.",
    "id-ID": "Sebutkan rencananya dengan lantang sebelum lemparan.",
    "ms-MY": "Sebutkan rancangannya dengan kuat sebelum balingan.",
    "th-TH": "พูดแผนออกมาดัง ๆ ก่อนขว้างทุกครั้ง",
    "vi-VN": "Nói to phương án trước mỗi quả ném.",
}


def defence_family() -> list[Drill]:
    # Sacrifice-bunt defence with a runner on first: the pitcher breaks off
    # the mound, the corners charge, the second baseman covers first and
    # the shortstop covers second. Nobody covered anything, under a note
    # about two players covering the same base.
    specs = [("bunt", "against the bunt",
              {"1B": (0.60, 0.84), "3B": (0.40, 0.84),
               "P": (0.50, 0.86), "2B": FIRST, "SS": SECOND}),
             ("first_and_third", "first and third", {"2B": SECOND, "SS": (0.46, 0.68)}),
             ("infield_in", "with the infield in", {"1B": (0.62, 0.78), "2B": (0.58, 0.72),
                                                    "SS": (0.42, 0.72), "3B": (0.38, 0.78)}),
             # Priority means both go to the same ball and the outfielder
             # calls the infielder off it; they used to drift 300 units apart.
             ("pop_up", "the pop-up priority", {"SS": (0.48, 0.46), "CF": (0.50, 0.42)})]
    out = []
    for key, label, shifted in specs:
        out.append(Drill(
            id=f"bb_defence_{key}", category="defending", minutes=12, rel=True,
            free=(key in ("bunt", "infield_in")),
            name=suffixed(DEF_NAME, label), note=DEF_NOTE,
            home=defence(shifted=shifted),
            away=[P(*HOME, "B", moves=[(0.58, 0.86, 1)]),
                  P(*FIRST, "R", moves=[SECOND + (1,)])]
                 + ([P(*THIRD, "R", moves=[(0.38, 0.82, 1)])]
                    if key == "first_and_third" else []),
            markers=[M(*HOME, "square", ""), M(*FIRST, "square", ""),
                     M(*SECOND, "square", ""), M(*THIRD, "square", "")],
            ball=0,
            # fielded where the play dictates, thrown to the out
            ball_to=[(1, 0), (2, 1)],
        ))
    return out


PICK_NAME = {
    "en": "Holding the runner", "en-GB": "Holding the runner",
    "zh-CN": "牵制跑者", "zh-TW": "牽制跑者", "ja-JP": "走者を釘付けにする",
    "ko-KR": "주자 견제", "es-ES": "Sujetar al corredor",
    "fr-FR": "Fixer le coureur", "id-ID": "Menahan pelari",
    "ms-MY": "Menahan pelari", "th-TH": "การตรึงผู้วิ่ง", "vi-VN": "Giữ chân người chạy",
}
PICK_NOTE = {
    "en": "Vary the hold, not just the throw. A pitcher who counts to the same "
          "number every time has already told the runner when to leave.",
    "en-GB": "Vary the hold, not just the throw. A pitcher who counts to the "
             "same number every time has already told the runner when to leave.",
    "zh-CN": "要变的是停顿时间，不只是牵制球。每次都数到同一个数的投手，等于已经告诉跑者什么时候起跑。",
    "zh-TW": "要變的是停頓時間，不只是牽制球。每次都數到同一個數的投手，等於已經告訴跑者什麼時候起跑。",
    "ja-JP": "変えるのは牽制球だけでなく「間」だ。毎回同じ数を数える投手は、走者にスタートの合図を送っている。",
    "ko-KR": "견제구만이 아니라 정지 시간을 바꿔라. 매번 같은 박자로 세는 투수는 주자에게 출발 신호를 주는 셈이다.",
    "es-ES": "Varía la pausa, no solo el tiro: un lanzador que cuenta siempre "
             "igual ya le ha dicho al corredor cuándo salir.",
    "fr-FR": "Varie le temps d'arrêt, pas seulement le tir : un lanceur qui "
             "compte toujours pareil a déjà donné le départ au coureur.",
    "id-ID": "Variasikan jeda menahannya, bukan hanya lemparannya.",
    "ms-MY": "Pelbagaikan jeda menahan, bukan hanya balingan.",
    "th-TH": "เปลี่ยนจังหวะการหน่วง ไม่ใช่แค่ลูกขว้างเช็ค",
    "vi-VN": "Thay đổi nhịp giữ, không chỉ cú ném kiểm tra.",
}


def pickoff_family() -> list[Drill]:
    # The rundown needs a fielder at each end with the runner trapped
    # between them, and the pitch-out is for catching a runner stealing —
    # so his runner leads off first, not stands on home plate.
    specs = [("first", "the pick-off at first", FIRST, {"1B": FIRST}, FIRST, None),
             ("second", "the pick-off at second", SECOND, {"SS": SECOND}, SECOND, None),
             ("rundown", "the rundown", (0.59, 0.65),
              {"1B": FIRST, "2B": SECOND}, FIRST, SECOND),
             ("pitchout", "the pitch-out", FIRST,
              {"2B": SECOND, "SS": (0.46, 0.60)}, FIRST, SECOND)]
    out = []
    for key, label, spot, shifted, from_base, to_base in specs:
        if key == "rundown":
            runner = P(*spot, "R", moves=[(0.635, 0.695, 1), (0.555, 0.615, 2)])
            ball = (FIRST[0] + 0.02, FIRST[1] - 0.02)
            ball_moves = [(SECOND[0] + 0.02, SECOND[1] + 0.02, 1),
                          (FIRST[0] + 0.02, FIRST[1] - 0.02, 2)]
        else:
            runner = P(spot[0] - 0.05, spot[1] + 0.03, "R",
                       moves=[(spot[0] - 0.02, spot[1] + 0.01, 1), spot + (2,)])
            ball = (MOUND[0], MOUND[1] - 0.01) if key != "pitchout" \
                else (HOME[0] + 0.03, HOME[1] - 0.02)
            ball_moves = ([(spot[0] + 0.02, spot[1] - 0.02, 2)] if key != "pitchout"
                          else [(SECOND[0] + 0.02, SECOND[1] + 0.02, 2)])
        out.append(Drill(
            id=f"bb_pick_{key}", category="setpiece", minutes=8, rel=True,
            # A runner stands on the bag the fielder is covering.
            tight=True,
            free=(key in ("first", "rundown")),
            name=suffixed(PICK_NAME, label), note=PICK_NOTE,
            home=defence(shifted=shifted),
            away=[runner],
            markers=[M(*FIRST, "square", ""), M(*SECOND, "square", ""),
                     M(*THIRD, "square", "")],
            ball=ball, ball_moves=ball_moves,
        ))
    return out


GAME_NAME = {
    "en": "Situational scrimmage", "en-GB": "Situational scrimmage",
    "zh-CN": "情境模拟对抗", "zh-TW": "情境模擬對抗", "ja-JP": "状況設定のシート打撃",
    "ko-KR": "상황별 실전 연습", "es-ES": "Práctica situacional",
    "fr-FR": "Opposition à thème", "id-ID": "Simulasi situasi",
    "ms-MY": "Simulasi situasi", "th-TH": "การซ้อมตามสถานการณ์",
    "vi-VN": "Đấu tập theo tình huống",
}
GAME_NOTE = {
    "en": "Set the count and the outs before every pitch. Baseball practice "
          "without a situation is nine people watching one person hit.",
    "en-GB": "Set the count and the outs before every pitch. Baseball practice "
             "without a situation is nine people watching one person hit.",
    "zh-CN": "每一球之前先设定好球数和出局数。没有情境的棒球训练，就是九个人看一个人打击。",
    "zh-TW": "每一球之前先設定好球數和出局數。沒有情境的棒球訓練，就是九個人看一個人打擊。",
    "ja-JP": "毎球、カウントとアウト数を設定する。状況のない練習は、9人が1人の打撃を眺めているだけだ。",
    "ko-KR": "매 투구 전에 볼카운트와 아웃카운트를 정하라. 상황 없는 연습은 아홉 명이 한 명 치는 걸 구경하는 것이다.",
    "es-ES": "Fija la cuenta y los outs antes de cada lanzamiento: un "
             "entrenamiento sin situación son nueve mirando a uno batear.",
    "fr-FR": "Fixe le compte et les retraits avant chaque lancer : un "
             "entraînement sans situation, c'est neuf joueurs qui en regardent un frapper.",
    "id-ID": "Tetapkan count dan out sebelum setiap lemparan.",
    "ms-MY": "Tetapkan count dan out sebelum setiap balingan.",
    "th-TH": "กำหนดเคานต์และจำนวนเอาต์ก่อนทุกลูกขว้าง",
    "vi-VN": "Đặt số bóng và số loại trước mỗi quả ném.",
}


def game_family() -> list[Drill]:
    specs = [("two_outs", "two outs, runner on second", [SECOND]),
             ("bases_loaded", "bases loaded", [FIRST, SECOND, THIRD]),
             ("baserunning_game", "the baserunning game", [FIRST])]
    out = []
    for key, label, runners in specs:
        out.append(Drill(
            id=f"bb_game_{key}", category="ssg", minutes=20, rel=True,
            free=(key in ("two_outs", "bases_loaded")),
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=defence(),
            away=[P(*HOME, "B", moves=[(0.58, 0.88, 1)])] + [
                P(*r, "R", moves=[(r[0] + (0.5 - r[0]) * 0.12, r[1] - 0.03, 1)])
                for r in runners
            ],
            markers=[M(*HOME, "square", ""), M(*FIRST, "square", ""),
                     M(*SECOND, "square", ""), M(*THIRD, "square", "")],
            ball=0,
            # the pitch — everything else starts on its release
            ball_to=[((500, 1180), 0), (0, 1)],
        ))
    return out


HIT_NAME = {"en": "Hitting", "en-GB": "Hitting", "zh-CN": "打击",
            "zh-TW": "打擊", "ja-JP": "打撃", "ko-KR": "타격",
            "es-ES": "Bateo", "fr-FR": "Frappe", "id-ID": "Memukul",
            "ms-MY": "Memukul", "th-TH": "การตี", "vi-VN": "Đánh bóng"}
HIT_NOTE = {
    "en": "Same load, same stride, whatever the pitch is. A swing that changes its start because the ball changed is already late.",
    "en-GB": "Same load, same stride, whatever the pitch is. A swing that changes its start because the ball changed is already late.",
    "zh-CN": "无论来球是什么，引拍和跨步都一样。因为球变了才改变起手动作的挥棒，已经晚了。",
    "zh-TW": "無論來球是什麼，引拍和跨步都一樣。因為球變了才改變起手動作的揮棒，已經晚了。",
    "ja-JP": "どんな球でも、テイクバックとステップは同じ。球種に合わせて始動を変えるスイングは、その時点で振り遅れている。",
    "ko-KR": "어떤 공이 와도 로드와 스트라이드는 같다. 공에 따라 시작을 바꾸는 스윙은 이미 늦은 스윙이다.",
    "es-ES": "La misma carga y el mismo paso, venga lo que venga. Un swing que cambia su inicio porque cambió la bola ya llega tarde.",
    "fr-FR": "Même armé, même appui, quel que soit le lancer. Un swing qui modifie son départ parce que la balle a changé est déjà en retard.",
    "id-ID": "Muatan dan langkah yang sama, apa pun lemparannya.",
    "ms-MY": "Muatan dan langkah yang sama, apa pun balingannya.",
    "th-TH": "โหลดเหมือนเดิม ก้าวเหมือนเดิม ไม่ว่าลูกจะมาแบบไหน",
    "vi-VN": "Cùng một nhịp lấy đà, cùng một bước chân, dù bóng thế nào.",
}
CATCH_NAME = {"en": "Catching", "en-GB": "Catching", "zh-CN": "捕手训练",
              "zh-TW": "捕手訓練", "ja-JP": "捕手練習", "ko-KR": "포수 훈련",
              "es-ES": "Receptor", "fr-FR": "Receveur", "id-ID": "Latihan catcher",
              "ms-MY": "Latihan penangkap", "th-TH": "ฝึกแคตเชอร์",
              "vi-VN": "Tập bắt bóng"}
CATCH_NOTE = {
    "en": "Get the body behind it and the chin down before the ball arrives. A block is a ball you keep in front of you, not a ball you catch.",
    "en-GB": "Get the body behind it and the chin down before the ball arrives. A block is a ball you keep in front of you, not a ball you catch.",
    "zh-CN": "球到之前先把身体挡到球后面、下巴收下去。挡球是把球留在身前，不是把球接住。",
    "zh-TW": "球到之前先把身體擋到球後面、下巴收下去。擋球是把球留在身前，不是把球接住。",
    "ja-JP": "ボールが来る前に体を後ろに入れ、顎を引く。ブロッキングは前に落とすことで、捕ることではない。",
    "ko-KR": "공이 오기 전에 몸을 뒤에 두고 턱을 당겨라. 블로킹은 앞에 떨어뜨리는 것이지 잡는 것이 아니다.",
    "es-ES": "Pon el cuerpo detrás y la barbilla abajo antes de que llegue. Bloquear es dejarla delante de ti, no atraparla.",
    "fr-FR": "Mets le corps derrière et le menton bas avant l'arrivée. Bloquer, c'est garder la balle devant soi, pas l'attraper.",
    "id-ID": "Tempatkan badan di belakang bola dan dagu turun sebelum bola tiba.",
    "ms-MY": "Letakkan badan di belakang bola dan dagu turun sebelum bola tiba.",
    "th-TH": "เอาลำตัวไปอยู่หลังบอลและเก็บคางลงก่อนบอลมาถึง",
    "vi-VN": "Đưa thân người ra sau bóng và cúi cằm trước khi bóng tới.",
}
FIELD_NAME = {"en": "Fielding fundamentals", "en-GB": "Fielding fundamentals",
              "zh-CN": "守备基本功", "zh-TW": "守備基本功",
              "ja-JP": "守備の基本", "ko-KR": "수비 기본기",
              "es-ES": "Fundamentos de defensa", "fr-FR": "Bases de la défense",
              "id-ID": "Dasar bertahan", "ms-MY": "Asas pertahanan",
              "th-TH": "พื้นฐานการรับลูก", "vi-VN": "Kỹ thuật bắt bóng cơ bản"}
FIELD_NOTE = {
    "en": "Move through the ball, not to it. Fielding flat-footed turns a routine grounder into a long throw you have no time for.",
    "en-GB": "Move through the ball, not to it. Fielding flat-footed turns a routine grounder into a long throw you have no time for.",
    "zh-CN": "要穿过球去接，不是跑到球那儿停住。原地站定接的滚地球，会把一个常规出局变成一次你来不及的长传。",
    "zh-TW": "要穿過球去接，不是跑到球那兒停住。原地站定接的滾地球，會把一個常規出局變成一次你來不及的長傳。",
    "ja-JP": "ボールへ行くのではなく、ボールを通り抜ける。棒立ちで捕れば、平凡なゴロが間に合わない遠投になる。",
    "ko-KR": "공으로 가는 게 아니라 공을 통과해 움직여라. 멈춰 서서 잡으면 평범한 땅볼이 시간 없는 긴 송구가 된다.",
    "es-ES": "Atraviesa la bola, no vayas hacia ella. Fildear parado convierte un rodado de rutina en un tiro largo sin tiempo.",
    "fr-FR": "Traverse la balle, ne va pas seulement jusqu'à elle. Cueillir à l'arrêt transforme un roulant facile en un long lancer sans temps.",
    "id-ID": "Bergeraklah menembus bola, bukan sekadar menuju bola.",
    "ms-MY": "Bergerak menembusi bola, bukan sekadar menuju bola.",
    "th-TH": "เคลื่อนผ่านบอล ไม่ใช่แค่วิ่งไปหาบอล",
    "vi-VN": "Di chuyển xuyên qua bóng, không phải chỉ chạy tới bóng.",
}


def gaps_family() -> list[Drill]:
    """Half a baseball library was missing.

    Twenty-nine drills and not one on hitting, bunt technique, catching,
    pitching or fielding fundamentals — all verified absent from every
    name and note. These are the boards a coach starts a session with.
    """
    plate = (HOME[0] + 0.03, HOME[1] - 0.03)
    return [
        Drill(
            id="bb_hit_tee_and_toss", category="warmup", minutes=12, rel=True,
            level="foundation", free=True,
            name=suffixed(HIT_NAME, "off the tee and the front toss"),
            note=HIT_NOTE,
            home=[P(*plate, "B", moves=[(plate[0] + 0.04, plate[1] - 0.02, 1)]),
                  P(0.36, 0.86, "F", moves=[(0.40, 0.855, 0)])],
            markers=[M(*HOME, "square", ""), M(0.62, 0.62, "zone", "")],
            ball=(0.40, 0.855), ball_moves=[(plate[0] + 0.02, plate[1] - 0.01, 1),
                                            (0.62, 0.62, 2)],
        ),
        Drill(
            id="bb_hit_two_strike", category="attacking", minutes=12, rel=True,
            name=suffixed(HIT_NAME, "the two-strike approach"), note=HIT_NOTE,
            home=defence(without=("LF", "RF")),
            away=[P(*plate, "B", moves=[(plate[0] + 0.04, plate[1] - 0.02, 1)])],
            markers=[M(*HOME, "square", ""), M(0.70, 0.56, "zone", ""),
                     M(0.30, 0.56, "zone", "")],
            ball=(MOUND[0], MOUND[1] - 0.01),
            ball_moves=[(plate[0], plate[1] - 0.02, 0), (0.70, 0.56, 2)],
        ),
        Drill(
            id="bb_hit_bunt_technique", category="attacking", minutes=10, rel=True,
            level="foundation",
            name=suffixed(HIT_NAME, "laying down the bunt"), note=HIT_NOTE,
            home=defence(without=("LF", "CF", "RF"),
                         shifted={"1B": (0.60, 0.84), "3B": (0.40, 0.84)}),
            away=[P(*plate, "B", moves=[(plate[0] - 0.02, plate[1] - 0.02, 1),
                                        FIRST + (2,)])],
            markers=[M(*HOME, "square", ""), M(0.38, 0.86, "zone", ""),
                     M(0.62, 0.86, "zone", "")],
            ball=(MOUND[0], MOUND[1] - 0.01),
            ball_moves=[(plate[0], plate[1] - 0.02, 0), (0.38, 0.86, 1)],
        ),
        Drill(
            id="bb_catch_blocking", category="defending", minutes=10, rel=True,
            level="foundation", free=True,
            name=suffixed(CATCH_NAME, "blocking the ball in the dirt"),
            note=CATCH_NOTE,
            home=[P(*D["C"], "C", moves=[(D["C"][0] - 0.03, D["C"][1] - 0.03, 1)]),
                  P(*MOUND, "P", role="GK", moves=[(0.50, 0.82, 0)])],
            markers=[M(*HOME, "square", "")],
            ball=(MOUND[0], MOUND[1] - 0.01),
            ball_moves=[(0.47, 0.93, 1)],
        ),
        Drill(
            id="bb_catch_throw_down", category="defending", minutes=10, rel=True,
            name=suffixed(CATCH_NAME, "the throw down to second"), note=CATCH_NOTE,
            home=defence(without=("LF", "CF", "RF"), shifted={"SS": SECOND}),
            away=[P(FIRST[0] - 0.05, FIRST[1] + 0.02, "R",
                    moves=[(0.62, 0.68, 1), SECOND + (2,)])],
            markers=[M(*FIRST, "square", ""), M(*SECOND, "square", "")],
            ball=(MOUND[0], MOUND[1] - 0.01),
            ball_moves=[(HOME[0] + 0.02, HOME[1] - 0.02, 0),
                        (SECOND[0] + 0.02, SECOND[1] + 0.02, 2)],
        ),
        Drill(
            id="bb_field_ground_ball", category="defending", minutes=12, rel=True,
            level="foundation",
            name=suffixed(FIELD_NAME, "the ground ball and the backhand"),
            note=FIELD_NOTE,
            home=[P(*D["SS"], "SS", moves=[(0.36, 0.665, 0), (0.44, 0.70, 1)]),
                  P(*FIRST, "1B"), P(*plate, "F")],
            markers=[M(*FIRST, "square", ""), M(*HOME, "square", "")],
            ball=(plate[0], plate[1] - 0.02),
            ball_moves=[(0.36, 0.665, 0), (FIRST[0] + 0.02, FIRST[1] - 0.02, 2)],
        ),
        Drill(
            id="bb_field_fly_ball", category="defending", minutes=12, rel=True,
            name=suffixed(FIELD_NAME, "the drop step and the fly ball"),
            note=FIELD_NOTE,
            home=[P(*D["CF"], "CF", moves=[(0.56, 0.20, 0), (0.54, 0.26, 1)]),
                  P(*D["2B"], "2B", moves=[(0.54, 0.50, 1)]),
                  P(*plate, "F")],
            markers=[M(*SECOND, "square", "")],
            ball=(plate[0], plate[1] - 0.02),
            ball_moves=[(0.56, 0.20, 0), (SECOND[0] + 0.02, SECOND[1] + 0.02, 2)],
        ),
        Drill(
            id="bb_pitch_bullpen", category="setpiece", minutes=12, rel=True,
            level="foundation",
            name=suffixed(FIELD_NAME, "the bullpen and the sequence"),
            note=FIELD_NOTE,
            home=[P(*MOUND, "P", role="GK", moves=[(0.50, 0.83, 0)]),
                  P(*D["C"], "C", moves=[(0.53, 0.955, 1)])],
            markers=[M(*HOME, "square", ""), M(0.545, 0.935, "zone", ""),
                     M(0.455, 0.935, "zone", "")],
            ball=(MOUND[0], MOUND[1] - 0.01),
            ball_moves=[(0.545, 0.935, 1)],
        ),
    ]


def baseball_library() -> list[Drill]:
    return (warmup_family() + double_play_family() + relay_family()
            + baserunning_family() + scoring_family() + defence_family()
            + pickoff_family() + game_family() + gaps_family())
