"""The rugby library.

Attacking upward. The field includes both in-goals, so the try line the attack
is aiming at sits at y=0.153 and the halfway line at y=0.5 — a drill that runs
"from our 22 to their 22" is y 0.694 down to y 0.306.
"""
from .engine import Drill, M, P, suffixed

TRY_LINE, TWENTY_TWO, HALFWAY = 0.153, 0.306, 0.50
OWN_22, OWN_TRY = 0.694, 0.847


def line_of(n, y, x0=0.16, x1=0.84):
    # A line of one stands in the middle of its span, not at its left edge —
    # at the edge it lands exactly on the last player of the pod next door.
    if n == 1:
        return [((x0 + x1) / 2, y)]
    return [(x0 + (x1 - x0) * i / (n - 1), y) for i in range(n)]


HANDLE_NAME = {
    "en": "Handling", "en-GB": "Handling", "zh-CN": "传接球", "zh-TW": "傳接球",
    "ja-JP": "ハンドリング", "ko-KR": "핸들링", "es-ES": "Manejo de balón",
    "fr-FR": "Maniement du ballon", "id-ID": "Penguasaan bola",
    "ms-MY": "Pengendalian bola", "th-TH": "การรับส่งบอล", "vi-VN": "Xử lý bóng",
}
HANDLE_NOTE = {
    "en": "Pass in front of the receiver's chest so they run onto it. A pass "
          "behind them turns a runner into a catcher.",
    "en-GB": "Pass in front of the receiver's chest so they run onto it. A "
             "pass behind them turns a runner into a catcher.",
    "zh-CN": "传到接球人胸前偏前的位置，让他跑起来接。传到身后，就把一个跑动的人变成了一个接球的人。",
    "zh-TW": "傳到接球人胸前偏前的位置，讓他跑起來接。傳到身後，就把一個跑動的人變成了一個接球的人。",
    "ja-JP": "受け手の胸の前へ、走り込めるように放る。後ろへのパスは、ランナーをキャッチャーに変えてしまう。",
    "ko-KR": "받는 사람 가슴 앞으로 던져 달려들게 하라. 뒤로 간 패스는 러너를 캐처로 만든다.",
    "es-ES": "Pasa delante del pecho para que corra al balón: un pase atrás "
             "convierte a un corredor en un receptor.",
    "fr-FR": "Passe devant la poitrine pour qu'il coure dessus : une passe "
             "derrière transforme un coureur en réceptionneur.",
    "id-ID": "Umpan di depan dada penerima agar ia berlari menyongsongnya.",
    "ms-MY": "Hantar di hadapan dada penerima supaya dia berlari menyambutnya.",
    "th-TH": "ส่งไปข้างหน้าอกคนรับ เพื่อให้เขาวิ่งเข้าหาบอล",
    "vi-VN": "Chuyền trước ngực người nhận để họ chạy vào bóng.",
}


def handling_family() -> list[Drill]:
    specs = [("grid", "in a grid", 4), ("threes", "in threes", 3), ("wide", "across the width", 6)]
    out = []
    for key, label, n in specs:
        spots = line_of(n, 0.62)
        out.append(Drill(
            id=f"rg_handling_{key}", category="warmup", minutes=8, rel=True,
            free=(key in ("grid", "threes")),
            name=suffixed(HANDLE_NAME, label), note=HANDLE_NOTE,
            home=[P(x, y, f"{i + 1}", moves=[(x, y - 0.12, 0), (x, y - 0.22, 1)])
                  for i, (x, y) in enumerate(spots)],
            markers=[M(x, 0.40, "cone", "") for x, _ in spots],
            ball=0,
        ))
    return out


PHASE_NAME = {
    "en": "Phase play", "en-GB": "Phase play", "zh-CN": "多波次进攻",
    "zh-TW": "多波次進攻", "ja-JP": "フェーズ攻撃", "ko-KR": "페이즈 플레이",
    "es-ES": "Juego por fases", "fr-FR": "Jeu au sol enchaîné",
    "id-ID": "Permainan berfase", "ms-MY": "Permainan berfasa",
    "th-TH": "การบุกต่อเนื่อง", "vi-VN": "Tấn công nhiều đợt",
}
PHASE_NOTE = {
    "en": "Get the shape set before the ball arrives, not while it is coming. "
          "A pod still forming when the nine looks up is a pod that isn't there.",
    "en-GB": "Get the shape set before the ball arrives, not while it is "
             "coming. A pod still forming when the nine looks up is a pod that isn't there.",
    "zh-CN": "球到之前站好位，不是球在路上才站。传球手抬头时还在集结的那一组，就等于不存在。",
    "zh-TW": "球到之前站好位，不是球在路上才站。傳球手抬頭時還在集結的那一組，就等於不存在。",
    "ja-JP": "ボールが来る前に形を作る。9番が顔を上げた時にまだ組んでいるポッドは、いないのと同じ。",
    "ko-KR": "공이 오기 전에 형태를 잡아라. 9번이 고개를 들 때 아직 모이고 있는 포드는 없는 포드다.",
    "es-ES": "Formad antes de que llegue el balón: un pod que aún se arma "
             "cuando el 9 levanta la cabeza es un pod que no existe.",
    "fr-FR": "Mets la structure en place avant l'arrivée du ballon : un pod qui "
             "se forme encore quand le 9 lève la tête n'existe pas.",
    "id-ID": "Bentuk formasi sebelum bola datang, bukan sambil menunggu.",
    "ms-MY": "Bentuk formasi sebelum bola tiba.",
    "th-TH": "จัดรูปให้เสร็จก่อนบอลมาถึง",
    "vi-VN": "Sắp đội hình xong trước khi bóng tới.",
}


def phase_family() -> list[Drill]:
    specs = [("one_three_three_one", "1-3-3-1", [(1, 0.24), (3, 0.40), (3, 0.62), (1, 0.80)]),
             ("two_four_two", "2-4-2", [(2, 0.30), (4, 0.52), (2, 0.74)]),
             ("left_to_right", "left to right", [(3, 0.44), (3, 0.62)])]
    out = []
    for key, label, pods in specs:
        home = []
        for n, x_frac in pods:
            for j, (x, y) in enumerate(line_of(n, 0.60, x_frac - 0.07, x_frac + 0.07)):
                home.append(P(x, y, f"{len(home) + 1}",
                              moves=[(x, 0.50, 0), (x + 0.03, 0.42, 1)]))
        out.append(Drill(
            id=f"rg_phase_{key}", category="possession", minutes=14, rel=True,
            # Fourteen bodies in pods: they are packed by design, so the
            # floor is "labels readable", not "icons never touch".
            tight=True,
            free=(key == "one_three_three_one"),
            name=suffixed(PHASE_NAME, label), note=PHASE_NOTE,
            home=home,
            away=[P(x, y, "D", moves=[(x, y + 0.06, 0)]) for x, y in line_of(6, 0.44)],
            ball=0,
        ))
    return out


MOVE_NAME = {
    "en": "Backline move", "en-GB": "Backline move", "zh-CN": "后卫线配合",
    "zh-TW": "後衛線配合", "ja-JP": "バックスのサインプレー", "ko-KR": "백스 사인 플레이",
    "es-ES": "Jugada de tres cuartos", "fr-FR": "Combinaison de trois-quarts",
    "id-ID": "Pola barisan belakang", "ms-MY": "Pergerakan barisan belakang",
    "th-TH": "แผนแนวหลัง", "vi-VN": "Bài phối hợp tuyến sau",
}
MOVE_NOTE = {
    "en": "Every move is a lie about where the ball is going. Sell it with the "
          "first runner's line, or the defence never has to believe anything.",
    "en-GB": "Every move is a lie about where the ball is going. Sell it with "
             "the first runner's line, or the defence never has to believe anything.",
    "zh-CN": "每一个配合都是关于球去哪的一个谎。要靠第一个跑动的人把它演真，否则防守根本不用相信任何东西。",
    "zh-TW": "每一個配合都是關於球去哪的一個謊。要靠第一個跑動的人把它演真，否則防守根本不用相信任何東西。",
    "ja-JP": "サインプレーはすべて「ボールの行き先」についての嘘だ。最初のランナーのラインで信じ込ませなければ、守備は何も信じずに済む。",
    "ko-KR": "모든 사인 플레이는 공이 어디로 가는지에 대한 거짓말이다. 첫 러너의 라인으로 팔지 못하면 수비는 믿을 필요가 없다.",
    "es-ES": "Toda jugada es una mentira sobre dónde va el balón: véndela con "
             "la línea del primer corredor o la defensa no tendrá que creerse nada.",
    "fr-FR": "Chaque combinaison est un mensonge sur la destination du ballon : "
             "vends-le avec la course du premier, sinon la défense n'a rien à croire.",
    "id-ID": "Setiap pola adalah kebohongan tentang ke mana bola pergi.",
    "ms-MY": "Setiap pergerakan ialah penipuan tentang ke mana bola pergi.",
    "th-TH": "ทุกแผนคือการโกหกว่าบอลจะไปทางไหน",
    "vi-VN": "Mỗi bài phối hợp là một lời nói dối về hướng bóng.",
}


def move_family() -> list[Drill]:
    specs = [("miss_pass", "the miss pass", 3, 0.86), ("switch", "the switch", 2, 0.30),
             ("loop", "the loop", 2, 0.66), ("cut_out", "the cut-out", 4, 0.90),
             ("dummy_runner", "with a dummy runner", 3, 0.72)]
    out = []
    for key, label, receiver, target_x in specs:
        line = line_of(5, 0.60, 0.22, 0.86)
        home = []
        for i, (x, y) in enumerate(line):
            end_x = target_x if i == receiver else x + (target_x - x) * 0.25
            # A backline from first receiver outward is 10, 12, 13, 15, 14 —
            # not 10, 11, 12, 13, 14, which puts the left wing at inside
            # centre, a position 11 never stands in.
            home.append(P(x, y, ("10", "12", "13", "15", "14")[i],
                          moves=[(x + (end_x - x) * 0.4, 0.50, 0), (end_x, 0.38, 1)]))
        out.append(Drill(
            id=f"rg_move_{key}", category="attacking", minutes=12, rel=True,
            free=(key in ("miss_pass", "switch")),
            name=suffixed(MOVE_NAME, label), note=MOVE_NOTE,
            home=home,
            away=[P(x, y, "D", moves=[(x, y + 0.05, 0), (x - 0.02, 0.44, 1)])
                  for x, y in line_of(5, 0.42, 0.24, 0.84)],
            ball=0,
        ))
    return out


FINISH_NAME = {
    "en": "Finishing", "en-GB": "Finishing", "zh-CN": "达阵终结",
    "zh-TW": "達陣終結", "ja-JP": "フィニッシュ", "ko-KR": "마무리",
    "es-ES": "Finalización", "fr-FR": "Finition", "id-ID": "Penyelesaian",
    "ms-MY": "Penamat", "th-TH": "การจบสกอร์", "vi-VN": "Kết thúc",
}
FINISH_NOTE = {
    "en": "Score under the posts if you can — the two points after are worth "
          "the extra second it costs to get there.",
    "en-GB": "Score under the posts if you can — the two points after are "
             "worth the extra second it costs to get there.",
    "zh-CN": "能压到门柱正下方就压过去——后面那两分，值得你多花那一秒。",
    "zh-TW": "能壓到門柱正下方就壓過去——後面那兩分，值得你多花那一秒。",
    "ja-JP": "可能ならポスト下でトライする。その後の2点は、余分にかかる1秒に見合う。",
    "ko-KR": "가능하면 골포스트 아래에 찍어라. 이후 2점은 그 1초의 값어치가 있다.",
    "es-ES": "Ensaya bajo palos si puedes: los dos puntos posteriores valen el "
             "segundo extra que cuesta llegar ahí.",
    "fr-FR": "Aplatis sous les poteaux si tu peux : les deux points d'après "
             "valent la seconde supplémentaire.",
    "id-ID": "Cetak di bawah tiang jika bisa.",
    "ms-MY": "Jaringkan di bawah tiang jika boleh.",
    "th-TH": "ถ้าทำได้ให้วางบอลใต้เสาประตู",
    "vi-VN": "Nếu được, hãy ghi điểm ngay dưới cột.",
}


def finishing_family() -> list[Drill]:
    specs = [("pick_and_go", "pick and go", (0.50, 0.20)), ("wide_finish", "in the corner", (0.90, 0.20)),
             ("kick_chase", "off the kick chase", (0.70, 0.18))]
    out = []
    for key, label, start in specs:
        out.append(Drill(
            id=f"rg_finish_{key}", category="finishing", minutes=10, rel=True,
            free=(key == "pick_and_go"),
            name=suffixed(FINISH_NAME, label), note=FINISH_NOTE,
            home=[P(*start, "1", moves=[(start[0] + (0.5 - start[0]) * 0.4,
                                         TRY_LINE - 0.05, 1)]),
                  P(start[0] - 0.14, start[1] + 0.06, "2",
                    moves=[(start[0] - 0.06, TRY_LINE + 0.02, 1)])],
            # The second defender used to stand at TRY_LINE - 0.04, which
            # is 5.7 m *behind* the try line, in the in-goal — a goalkeeper
            # from another sport's template. He covers across instead.
            away=[P(start[0] + 0.04, TRY_LINE + 0.02, "D",
                    moves=[(start[0] + 0.02, TRY_LINE + 0.05, 0)]),
                  P(0.5 + (0.5 - start[0]) * 0.55, TRY_LINE + 0.075, "D",
                    moves=[(start[0] * 0.4 + 0.30, TRY_LINE + 0.045, 1)])],
            markers=[M(0.50, TRY_LINE, "zone", "")],
            ball=0,
        ))
    return out


DEF_NAME = {
    "en": "Defence", "en-GB": "Defence", "zh-CN": "防守", "zh-TW": "防守",
    "ja-JP": "ディフェンス", "ko-KR": "수비", "es-ES": "Defensa",
    "fr-FR": "Défense", "id-ID": "Pertahanan", "ms-MY": "Pertahanan",
    "th-TH": "การรับ", "vi-VN": "Phòng thủ",
}
DEF_NOTE = {
    "en": "Come up as a line and stay connected. One defender out of the wall "
          "is a hole, however good their tackle would have been.",
    "en-GB": "Come up as a line and stay connected. One defender out of the "
             "wall is a hole, however good their tackle would have been.",
    "zh-CN": "整条线一起上，保持连着。有一个人冒出防线，那就是一个洞——不管他这次擒抱本来会多漂亮。",
    "zh-TW": "整條線一起上，保持連著。有一個人冒出防線，那就是一個洞——不管他這次擒抱本來會多漂亮。",
    "ja-JP": "ラインで上がり、切れない。壁から飛び出した一人は穴だ。そのタックルがどれほど良くても。",
    "ko-KR": "한 줄로 올라가고 끊기지 마라. 벽에서 튀어나온 한 명은 구멍이다.",
    "es-ES": "Subid como una línea y sin desconectaros: un defensor fuera del "
             "muro es un agujero, por buena que fuera su placada.",
    "fr-FR": "Montez en ligne et restez liés : un défenseur sorti du mur est "
             "un trou, si bon qu'aurait été son plaquage.",
    "id-ID": "Naik sebagai satu garis dan tetap terhubung.",
    "ms-MY": "Naik sebagai satu barisan dan kekal berhubung.",
    "th-TH": "ขึ้นเป็นแนวเดียวกันและอย่าให้ขาด",
    "vi-VN": "Dâng lên thành một tuyến và không để đứt.",
}


def defence_family() -> list[Drill]:
    specs = [("drift", "drifting", 0.06, 0.03), ("blitz", "the blitz", 0.14, 0.0),
             ("scramble", "scrambling back", 0.02, 0.10)]
    out = []
    for key, label, push, slide in specs:
        line = line_of(6, 0.42)
        out.append(Drill(
            id=f"rg_defence_{key}", category="defending", minutes=12, rel=True,
            free=(key == "drift"),
            name=suffixed(DEF_NAME, label), note=DEF_NOTE,
            home=[P(x, y, "D", moves=[(x + slide, y + push, 0), (x + slide * 2, y + push * 1.4, 1)])
                  for x, y in line],
            away=[P(x, 0.60, "A", moves=[(x + 0.04, 0.52, 0)]) for x, _ in line_of(5, 0.60, 0.24, 0.84)],
            ball=(0.24, 0.60),          # the attack starts with it
        ))
    return out


SET_NAME = {
    "en": "Set piece", "en-GB": "Set piece", "zh-CN": "定位球", "zh-TW": "定位球",
    "ja-JP": "セットプレー", "ko-KR": "세트피스", "es-ES": "Jugada a balón parado",
    "fr-FR": "Phase statique", "id-ID": "Bola mati", "ms-MY": "Bola mati",
    "th-TH": "ลูกตั้งเตะ", "vi-VN": "Tình huống cố định",
}
SET_NOTE = {
    "en": "Win the ball first, then run the play. A clever move off slow "
          "possession is a slow move.",
    "en-GB": "Win the ball first, then run the play. A clever move off slow "
             "possession is a slow move.",
    "zh-CN": "先赢下球，再跑战术。慢球权上的聪明配合，就是一个慢配合。",
    "zh-TW": "先贏下球，再跑戰術。慢球權上的聰明配合，就是一個慢配合。",
    "ja-JP": "まずボールを獲る、それからプレーを走る。遅い球出しからの巧いサインは、ただの遅いサインだ。",
    "ko-KR": "먼저 공을 따내고 나서 플레이를 돌려라. 느린 볼에서 나온 영리한 사인은 그냥 느린 사인이다.",
    "es-ES": "Gana el balón primero y luego juega: una jugada ingeniosa con "
             "posesión lenta es una jugada lenta.",
    "fr-FR": "Gagne le ballon d'abord, joue ensuite : une combinaison maligne "
             "sur ballon lent est une combinaison lente.",
    "id-ID": "Menangkan bolanya dulu, baru jalankan pola.",
    "ms-MY": "Menangi bola dahulu, kemudian jalankan pola.",
    "th-TH": "ชนะบอลก่อน แล้วค่อยเล่นแผน",
    "vi-VN": "Giành bóng trước, rồi mới chạy bài.",
}


def setpiece_family() -> list[Drill]:
    """Scrum, lineouts and the kick-off, each with its own law-shaped setup.

    The scrum used to be a 3/3/2 grid, which makes 6 a lock and packs 7
    where the number 8 goes; a scrum is 3-2-3 with the flankers bound on
    the *sides* of the second row. The lineouts picked their jumpers by
    counting from 3, which put the tighthead in a five-man and the
    scrum-half — who never stands in the line — in a seven. And the
    kick-off had no kicker, no ball in the air and no catch pod.
    """
    out = []

    # ── the scrum: front row, locks behind them, flankers on the flanks,
    # 8 at the back, and a 9 to feed and clear ─────────────────────────
    y = 0.54
    front = [(0.455, y, "1"), (0.50, y, "2"), (0.545, y, "3")]
    locks = [(0.478, y + 0.045, "4"), (0.522, y + 0.045, "5")]
    flanks = [(0.425, y + 0.045, "6"), (0.575, y + 0.045, "7")]
    eight = [(0.50, y + 0.09, "8")]
    out.append(Drill(
        id="rg_set_scrum", category="setpiece", minutes=12, rel=True,
        tight=True, name=suffixed(SET_NAME, "the scrum"), note=SET_NOTE,
        home=[P(x, yy, lbl, moves=[(x, yy - 0.025, 0)])
              for x, yy, lbl in front + locks + flanks + eight]
             + [P(0.60, y + 0.10, "9", moves=[(0.56, y + 0.095, 1),
                                              (0.66, y + 0.045, 2)])],
        away=[P(0.455 + 0.045 * i, y - 0.05, "D") for i in range(3)]
             + [P(0.478 + 0.044 * i, y - 0.095, "D") for i in range(2)]
             + [P(0.425, y - 0.095, "D"), P(0.575, y - 0.095, "D"),
                P(0.50, y - 0.14, "D")],
        ball=8,
    ))

    # ── the lineouts: the jumpers a team actually lifts ────────────────
    for key, label, jumpers, y in [
            ("lineout_five", "the five-man lineout", ["4", "5", "6", "7", "8"], 0.46),
            ("lineout_seven", "the seven-man lineout",
             ["1", "3", "4", "5", "6", "7", "8"], 0.46)]:
        n = len(jumpers)
        out.append(Drill(
            id=f"rg_set_{key}", category="setpiece", minutes=12, rel=True,
            tight=True, free=(key == "lineout_five"), off_surface=True,
            name=suffixed(SET_NAME, label), note=SET_NOTE,
            # The hooker throws from outside the touchline; the jumper in
            # the middle rises while his two lifters close on him.
            home=[P(-0.02, y + 0.02 * (n // 2), "2",
                    moves=[(0.01, y + 0.02 * (n // 2), 1)])] + [
                P(0.14, y + 0.024 * i, lbl,
                  moves=[(0.145, y + 0.024 * i - (0.02 if i == n // 2 else 0.0)
                          + (0.012 if abs(i - n // 2) == 1 else 0.0), 1)])
                for i, lbl in enumerate(jumpers)
            ] + [P(0.26, y + 0.024 * (n // 2) + 0.05, "9",
                   moves=[(0.24, y + 0.024 * (n // 2) + 0.02, 2)])],
            away=[P(0.225, y + 0.024 * i, "D") for i in range(n)],
            ball=0,
        ))

    # ── the kick-off: a kicker, a ball in the air, a catch pod ─────────
    out.append(Drill(
        id="rg_set_kick_off", category="setpiece", minutes=12, rel=True,
        tight=True, free=True,
        name=suffixed(SET_NAME, "receiving the kick-off"), note=SET_NOTE,
        # The receiving team: a pod of three under the ball with lifters,
        # and the full-back behind for anything long.
        home=[P(0.26, 0.60, "4", moves=[(0.30, 0.545, 1)]),
              P(0.34, 0.585, "5", moves=[(0.345, 0.525, 1)]),
              P(0.42, 0.60, "6", moves=[(0.39, 0.545, 1)]),
              P(0.62, 0.62, "8", moves=[(0.52, 0.585, 2)]),
              P(0.50, 0.76, "15", moves=[(0.44, 0.66, 2)])],
        away=[P(0.50, 0.44, "10", moves=[(0.47, 0.475, 0)]),
              P(0.30, 0.455, "D", moves=[(0.32, 0.52, 1)]),
              P(0.70, 0.455, "D", moves=[(0.62, 0.52, 1)])],
        markers=[M(0.345, 0.525, "zone", "")],
        ball=(0.50, 0.455),
        ball_moves=[(0.345, 0.525, 1)],
    ))
    return out


KICK_NAME = {
    "en": "Kicking", "en-GB": "Kicking", "zh-CN": "踢球战术", "zh-TW": "踢球戰術",
    "ja-JP": "キック", "ko-KR": "킥", "es-ES": "Juego al pie",
    "fr-FR": "Jeu au pied", "id-ID": "Tendangan", "ms-MY": "Sepakan",
    "th-TH": "การเตะ", "vi-VN": "Đá bóng",
}
KICK_NOTE = {
    "en": "A kick with nobody chasing is a pass to the opposition. Send the "
          "chase before you send the ball.",
    "en-GB": "A kick with nobody chasing is a pass to the opposition. Send the "
             "chase before you send the ball.",
    "zh-CN": "没人追的踢球，就是传给对手的一次传球。先把追击的人放出去，再把球踢出去。",
    "zh-TW": "沒人追的踢球，就是傳給對手的一次傳球。先把追擊的人放出去，再把球踢出去。",
    "ja-JP": "誰も追わないキックは相手へのパスだ。ボールより先にチェイスを走らせる。",
    "ko-KR": "아무도 쫓지 않는 킥은 상대에게 주는 패스다. 공보다 체이스를 먼저 보내라.",
    "es-ES": "Una patada sin persecución es un pase al rival: manda la caza "
             "antes que el balón.",
    "fr-FR": "Un coup de pied sans chasse est une passe à l'adversaire : "
             "envoie les chasseurs avant le ballon.",
    "id-ID": "Tendangan tanpa pengejar adalah umpan untuk lawan.",
    "ms-MY": "Sepakan tanpa pengejar ialah hantaran kepada lawan.",
    "th-TH": "ลูกเตะที่ไม่มีคนไล่คือการจ่ายให้คู่แข่ง",
    "vi-VN": "Cú đá không ai đuổi theo là đường chuyền cho đối thủ.",
}


def kicking_family() -> list[Drill]:
    specs = [("box", "the box kick", (0.34, 0.60), (0.34, 0.30)),
             ("cross_field", "the cross-field kick", (0.50, 0.56), (0.88, 0.24)),
             ("territory", "for territory", (0.50, 0.72), (0.14, 0.24)),
             ("grubber", "the grubber", (0.66, 0.44), (0.72, 0.20))]
    out = []
    for key, label, kicker, land in specs:
        out.append(Drill(
            id=f"rg_kick_{key}", category="attacking", minutes=10, rel=True,
            free=(key == "box"),
            name=suffixed(KICK_NAME, label), note=KICK_NOTE,
            home=[P(*kicker, "9", moves=[(kicker[0], kicker[1] - 0.06, 1)]),
                  P(kicker[0] + 0.10, kicker[1] - 0.06, "C",
                    moves=[(land[0], land[1] + 0.06, 1)]),
                  P(kicker[0] - 0.10, kicker[1] - 0.04, "C",
                    moves=[(land[0] - 0.10, land[1] + 0.08, 1)])],
            away=[P(land[0], land[1] - 0.04, "F", moves=[(land[0], land[1], 1)])],
            markers=[M(*land, "zone", "")],
            ball=0,
        ))
    return out


BREAKDOWN_NAME = {
    "en": "Breakdown", "en-GB": "Breakdown", "zh-CN": "争球点",
    "zh-TW": "爭球點", "ja-JP": "ブレイクダウン", "ko-KR": "브레이크다운",
    "es-ES": "Ruck", "fr-FR": "Le regroupement", "id-ID": "Ruck",
    "ms-MY": "Ruck", "th-TH": "จุดปะทะ", "vi-VN": "Điểm tranh chấp",
}
BREAKDOWN_NOTE = {
    "en": "First support arrives low and past the ball. Arriving upright and "
          "beside it is how a ruck becomes a turnover.",
    "en-GB": "First support arrives low and past the ball. Arriving upright "
             "and beside it is how a ruck becomes a turnover.",
    "zh-CN": "第一个支援要压低身体、越过球再发力。站直了停在球边上，争球点就变成了丢球。",
    "zh-TW": "第一個支援要壓低身體、越過球再發力。站直了停在球邊上，爭球點就變成了丟球。",
    "ja-JP": "最初のサポートは低く、ボールを越えて入る。立ったまま横に着くから、ラックがターンオーバーになる。",
    "ko-KR": "첫 서포트는 낮게, 공을 지나쳐 들어간다. 선 채로 옆에 붙으면 럭이 턴오버가 된다.",
    "es-ES": "El primer apoyo llega bajo y pasado el balón: llegar erguido y "
             "al lado es como un ruck se convierte en pérdida.",
    "fr-FR": "Le premier soutien arrive bas et au-delà du ballon : arriver "
             "debout à côté, c'est transformer le ruck en turnover.",
    "id-ID": "Bantuan pertama datang rendah dan melewati bola.",
    "ms-MY": "Sokongan pertama datang rendah dan melepasi bola.",
    "th-TH": "คนช่วยคนแรกต้องเข้าต่ำและเลยบอลไป",
    "vi-VN": "Người hỗ trợ đầu vào thấp và vượt qua bóng.",
}


def breakdown_family() -> list[Drill]:
    specs = [("quick_ball", "for quick ball", 2), ("jackal", "the jackal", 1),
             ("counter_ruck", "the counter-ruck", 3)]
    out = []
    for key, label, n in specs:
        out.append(Drill(
            id=f"rg_breakdown_{key}", category="possession", minutes=10, rel=True,
            # Bodies over the ball at a breakdown are touching.
            tight=True,
            free=(key == "quick_ball"),
            name=suffixed(BREAKDOWN_NAME, label), note=BREAKDOWN_NOTE,
            home=[P(0.50, 0.56, "1", moves=[(0.50, 0.50, 0)])] + [
                P(0.42 + 0.08 * i, 0.66, f"{i + 2}",
                  moves=[(0.46 + 0.06 * i, 0.52, 0), (0.50, 0.48, 1)])
                for i in range(n)
            ],
            away=[P(0.50, 0.44, "D", moves=[(0.50, 0.50, 0)]),
                  P(0.58, 0.42, "D", moves=[(0.54, 0.49, 1)])],
            ball=0,
        ))
    return out


GAME_NAME = {
    "en": "Game", "en-GB": "Game", "zh-CN": "对抗", "zh-TW": "對抗",
    "ja-JP": "ゲーム", "ko-KR": "게임", "es-ES": "Juego", "fr-FR": "Jeu",
    "id-ID": "Permainan", "ms-MY": "Permainan", "th-TH": "เกม", "vi-VN": "Trận đấu",
}
GAME_NOTE = {
    "en": "Narrow the pitch and the offload appears; widen it and the kick "
          "does. Choose the width for the skill you came to coach.",
    "en-GB": "Narrow the pitch and the offload appears; widen it and the kick "
             "does. Choose the width for the skill you came to coach.",
    "zh-CN": "场地窄，传递就出来了；场地宽，踢球就出来了。按你今天要练的技术来定宽度。",
    "zh-TW": "場地窄，傳遞就出來了；場地寬，踢球就出來了。按你今天要練的技術來定寬度。",
    "ja-JP": "幅を狭めればオフロードが、広げればキックが出てくる。今日教えたいスキルで幅を決める。",
    "ko-KR": "좁히면 오프로드가, 넓히면 킥이 나온다. 가르치려는 기술에 맞춰 폭을 정하라.",
    "es-ES": "Estrecha el campo y aparece el offload; ensánchalo y aparece la "
             "patada. Elige el ancho según la destreza que vienes a entrenar.",
    "fr-FR": "Rétrécis le terrain et l'offload apparaît ; élargis-le et le jeu "
             "au pied revient. Choisis la largeur selon l'habileté visée.",
    "id-ID": "Sempitkan lapangan maka offload muncul; lebarkan maka tendangan muncul.",
    "ms-MY": "Sempitkan padang maka offload muncul; luaskan maka sepakan muncul.",
    "th-TH": "แคบสนามแล้วออฟโหลดจะมา กว้างสนามแล้วลูกเตะจะมา",
    "vi-VN": "Thu hẹp sân thì có offload; mở rộng thì có đá bóng.",
}


def game_family() -> list[Drill]:
    out = []
    for n, label in [(5, "touch 5v5"), (7, "sevens 7v7"), (8, "contact 8v8")]:
        spots = line_of(n, 0.62, 0.20, 0.86)
        out.append(Drill(
            id=f"rg_game_{n}v{n}", category="ssg", minutes=15, rel=True,
            # Fourteen to sixteen players do not fit a phone at one icon
            # apart; readable labels is the honest bar for a game board.
            tight=True,
            free=(n == 5),
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=[P(x, y, f"{i + 1}", moves=[(x, y - 0.08, 0)])
                  for i, (x, y) in enumerate(spots)],
            away=[P(x, 0.38, chr(65 + i), moves=[(x, 0.46, 0)])
                  for i, (x, _) in enumerate(spots)],
            ball=0,
        ))
    return out


TACKLE_NAME = {"en": "Tackling", "en-GB": "Tackling", "zh-CN": "擒抱",
               "zh-TW": "擒抱", "ja-JP": "タックル", "ko-KR": "태클",
               "es-ES": "El placaje", "fr-FR": "Le plaquage",
               "id-ID": "Tekel", "ms-MY": "Tekel", "th-TH": "การเข้าปะทะ",
               "vi-VN": "Truy cản"}
TACKLE_NOTE = {
    "en": "Cheek to cheek, shoulder into the thigh, and squeeze on contact. A tackler who reaches with his arms first has already given up his own shoulder.",
    "en-GB": "Cheek to cheek, shoulder into the thigh, and squeeze on contact. A tackler who reaches with his arms first has already given up his own shoulder.",
    "zh-CN": "头贴在对手臀侧，肩顶大腿，接触瞬间抱紧。先用手去够的擒抱者，等于已经把自己的肩膀让出去了。",
    "zh-TW": "頭貼在對手臀側，肩頂大腿，接觸瞬間抱緊。先用手去夠的擒抱者，等於已經把自己的肩膀讓出去了。",
    "ja-JP": "頬を相手の尻に付け、肩を太腿に入れ、当たった瞬間に絞る。先に腕から行くタックラーは、自分の肩をすでに捨てている。",
    "ko-KR": "볼을 상대 엉덩이에 붙이고 어깨를 허벅지에 넣은 뒤 접촉 순간 조여라. 팔부터 뻗는 태클러는 이미 자기 어깨를 버린 것이다.",
    "es-ES": "Mejilla contra cadera, hombro en el muslo y aprieta en el contacto. Quien llega con los brazos primero ya ha regalado su propio hombro.",
    "fr-FR": "Joue contre hanche, épaule dans la cuisse, et serre à l'impact. Le plaqueur qui tend d'abord les bras a déjà abandonné son épaule.",
    "id-ID": "Pipi menempel di pinggul lawan, bahu masuk ke paha, dan kunci saat kontak.",
    "ms-MY": "Pipi rapat ke pinggul lawan, bahu masuk ke peha, dan kunci ketika kontak.",
    "th-TH": "แก้มแนบสะโพกคู่ต่อสู้ ไหล่เข้าที่ต้นขา และรัดทันทีที่ปะทะ",
    "vi-VN": "Má áp hông đối thủ, vai thúc vào đùi, và siết ngay khi tiếp xúc.",
}
HIGHBALL_NAME = {"en": "The high ball", "en-GB": "The high ball",
                 "zh-CN": "高球争顶", "zh-TW": "高球爭頂", "ja-JP": "ハイボール",
                 "ko-KR": "하이볼 경합", "es-ES": "El balón alto",
                 "fr-FR": "Le ballon haut", "id-ID": "Bola tinggi",
                 "ms-MY": "Bola tinggi", "th-TH": "ลูกโด่ง", "vi-VN": "Bóng bổng"}
HIGHBALL_NOTE = {
    "en": "Call it early, jump off one foot with the knee up, and catch it above the head rather than at the chest. The chest catch is the one the chaser knocks loose.",
    "en-GB": "Call it early, jump off one foot with the knee up, and catch it above the head rather than at the chest. The chest catch is the one the chaser knocks loose.",
    "zh-CN": "早喊，单脚起跳、抬起护膝，把球接在头顶上方而不是胸前。胸前接的那个球，就是被追防的人撞掉的那个。",
    "zh-TW": "早喊，單腳起跳、抬起護膝，把球接在頭頂上方而不是胸前。胸前接的那個球，就是被追防的人撞掉的那個。",
    "ja-JP": "早くコールし、片足で膝を上げて跳び、胸ではなく頭上で捕る。胸で捕った球はチェイサーに弾かれる。",
    "ko-KR": "일찍 콜하고 한 발로 무릎을 올려 뛰어 가슴이 아니라 머리 위에서 잡아라. 가슴으로 잡은 공이 떨어지는 공이다.",
    "es-ES": "Cántala pronto, salta con una pierna y la rodilla arriba, y atrápala por encima de la cabeza, no en el pecho.",
    "fr-FR": "Annonce tôt, saute sur un pied genou levé, et capte au-dessus de la tête plutôt qu'à la poitrine.",
    "id-ID": "Serukan lebih awal, lompat satu kaki dengan lutut terangkat, dan tangkap di atas kepala.",
    "ms-MY": "Seru awal, lompat sebelah kaki dengan lutut terangkat, dan tangkap di atas kepala.",
    "th-TH": "ขานเรียกแต่เนิ่น กระโดดขาเดียวยกเข่า และรับเหนือศีรษะไม่ใช่ที่อก",
    "vi-VN": "Gọi sớm, bật một chân với đầu gối nâng lên, và bắt bóng trên đầu chứ không phải trước ngực.",
}
GOALKICK_NAME = {"en": "Place kicking", "en-GB": "Place kicking",
                 "zh-CN": "定位球射门", "zh-TW": "定位球射門",
                 "ja-JP": "プレースキック", "ko-KR": "플레이스 킥",
                 "es-ES": "Patada a palos", "fr-FR": "Le coup de pied placé",
                 "id-ID": "Tendangan penalti tiang", "ms-MY": "Sepakan tempat",
                 "th-TH": "การเตะเข้าเสา", "vi-VN": "Đá cố định"}
GOALKICK_NOTE = {
    "en": "The routine is the skill: same steps back, same steps across, same time over the ball whether it is the first minute or the last kick of the match.",
    "en-GB": "The routine is the skill: same steps back, same steps across, same time over the ball whether it is the first minute or the last kick of the match.",
    "zh-CN": "流程本身就是技术：后退几步、横移几步、在球前停留多久，第一分钟和最后一脚都必须一模一样。",
    "zh-TW": "流程本身就是技術：後退幾步、橫移幾步、在球前停留多久，第一分鐘和最後一腳都必須一模一樣。",
    "ja-JP": "ルーティンこそが技術だ。下がる歩数、横に動く歩数、ボールの前で費やす時間——開始1分でも最後の一蹴りでも同じにする。",
    "ko-KR": "루틴이 곧 기술이다. 뒤로 몇 걸음, 옆으로 몇 걸음, 공 앞에서 머무는 시간까지 언제나 똑같이.",
    "es-ES": "La rutina es la técnica: los mismos pasos atrás, los mismos de lado, el mismo tiempo sobre el balón, sea el minuto uno o la última patada.",
    "fr-FR": "La routine est la technique : mêmes pas en arrière, mêmes pas de côté, même temps au-dessus du ballon, à la première minute comme au dernier coup de pied.",
    "id-ID": "Rutinitas itulah keterampilannya: langkah mundur yang sama, langkah samping yang sama, waktu yang sama di atas bola.",
    "ms-MY": "Rutin itulah kemahirannya: langkah undur yang sama, langkah sisi yang sama.",
    "th-TH": "รูทีนคือทักษะ ถอยหลังกี่ก้าว ก้าวข้างกี่ก้าว ใช้เวลาเหนือบอลเท่าไร ต้องเหมือนเดิมเสมอ",
    "vi-VN": "Quy trình chính là kỹ thuật: cùng số bước lùi, cùng số bước ngang, cùng khoảng thời gian đứng trước bóng.",
}
EXIT_NAME = {"en": "Exit from your own 22", "en-GB": "Exit from your own 22",
             "zh-CN": "本方 22 米区出球", "zh-TW": "本方 22 公尺區出球",
             "ja-JP": "自陣22mからの脱出", "ko-KR": "자기 진영 22m 탈출",
             "es-ES": "Salida desde tus 22", "fr-FR": "Sortie de ses 22 mètres",
             "id-ID": "Keluar dari 22 m sendiri", "ms-MY": "Keluar dari 22 m sendiri",
             "th-TH": "การออกจากแดน 22 เมตรของตัวเอง", "vi-VN": "Thoát khỏi vạch 22 của mình"}
EXIT_NOTE = {
    "en": "Two phases then the kick, and the kick goes to touch or to grass, never down the throat of the back three. A rushed exit is the try you concede two minutes later.",
    "en-GB": "Two phases then the kick, and the kick goes to touch or to grass, never down the throat of the back three. A rushed exit is the try you concede two minutes later.",
    "zh-CN": "打两个波次再踢，踢出界或踢到空当，绝不要正对着对方后三人踢。仓促出球，就是两分钟后丢的那个达阵。",
    "zh-TW": "打兩個波次再踢，踢出界或踢到空檔，絕不要正對著對方後三人踢。倉促出球，就是兩分鐘後丟的那個達陣。",
    "ja-JP": "2フェーズ回してから蹴る。蹴り先はタッチか空きスペースで、相手バックスリーの正面には絶対に蹴らない。急いだ脱出は2分後の失トライだ。",
    "ko-KR": "두 페이즈를 돌린 뒤 차고, 차는 곳은 터치라인 밖이나 빈 공간이지 상대 백3의 정면이 아니다.",
    "es-ES": "Dos fases y luego el patadón, y ese patadón va a touch o a hierba libre, nunca a la garganta de los tres de atrás.",
    "fr-FR": "Deux temps de jeu puis le coup de pied, et ce coup de pied part en touche ou dans l'herbe, jamais dans les bras des trois arrières.",
    "id-ID": "Dua fase lalu tendangan, dan tendangan itu ke luar lapangan atau ke ruang kosong.",
    "ms-MY": "Dua fasa kemudian sepakan, dan sepakan itu ke luar padang atau ke ruang kosong.",
    "th-TH": "เล่นสองเฟสแล้วค่อยเตะ และเตะออกข้างสนามหรือลงพื้นที่ว่าง",
    "vi-VN": "Hai đợt tấn công rồi mới đá, và cú đá ra biên hoặc vào khoảng trống.",
}


def gaps_family() -> list[Drill]:
    """No tackling in a thirty-three-drill contact sport.

    'Tackle' appeared only inside a shared defence note. Also absent from
    every name and note: the high ball and the back-three counter, place
    kicking, and the exit from your own 22.
    """
    return [
        Drill(
            id="rg_defence_tackle", category="defending", minutes=12, rel=True,
            level="foundation", free=True,
            name=suffixed(TACKLE_NAME, "front on and from the side"),
            note=TACKLE_NOTE,
            home=[P(0.38, 0.56, "D", moves=[(0.40, 0.50, 0), (0.44, 0.455, 1)]),
                  P(0.62, 0.56, "D", moves=[(0.60, 0.50, 0), (0.555, 0.455, 1)])],
            away=[P(0.42, 0.40, "A", moves=[(0.44, 0.455, 1)]),
                  P(0.58, 0.40, "A", moves=[(0.555, 0.455, 1)])],
            markers=[M(0.30, 0.46), M(0.70, 0.46)],
            ball=None,
        ),
        Drill(
            id="rg_kick_high_ball", category="defending", minutes=12, rel=True,
            name=suffixed(HIGHBALL_NAME, "the contest and the counter"),
            note=HIGHBALL_NOTE,
            home=[P(0.50, 0.66, "15", moves=[(0.46, 0.56, 1), (0.34, 0.46, 2)]),
                  P(0.24, 0.62, "11", moves=[(0.28, 0.50, 2)]),
                  P(0.76, 0.62, "14", moves=[(0.66, 0.50, 2)])],
            away=[P(0.50, 0.36, "10", moves=[(0.50, 0.42, 0)]),
                  P(0.40, 0.40, "C", moves=[(0.44, 0.52, 1)]),
                  P(0.60, 0.40, "C", moves=[(0.56, 0.52, 1)])],
            markers=[M(0.46, 0.56, "zone", "")],
            ball=(0.50, 0.375),
            ball_moves=[(0.46, 0.56, 1)],
        ),
        Drill(
            id="rg_kick_at_goal", category="finishing", minutes=10, rel=True,
            level="foundation",
            name=suffixed(GOALKICK_NAME, "the routine"), note=GOALKICK_NOTE,
            home=[P(0.42, 0.34, "10", moves=[(0.375, 0.365, 0), (0.405, 0.345, 1)])],
            markers=[M(0.42, 0.32, "square", ""), M(0.50, TRY_LINE - 0.02, "zone", "")],
            ball=(0.42, 0.325),
            ball_moves=[(0.50, TRY_LINE - 0.02, 2)],
        ),
        Drill(
            id="rg_kick_exit", category="possession", minutes=14, rel=True,
            level="advanced",
            name=suffixed(EXIT_NAME, "two phases and the kick"), note=EXIT_NOTE,
            home=[P(0.34, 0.78, "9", moves=[(0.42, 0.755, 0), (0.50, 0.735, 1)]),
                  P(0.50, 0.82, "1", moves=[(0.44, 0.775, 0)]),
                  P(0.64, 0.80, "4", moves=[(0.58, 0.755, 1)]),
                  P(0.78, 0.76, "10", moves=[(0.70, 0.725, 2)])],
            away=[P(0.40, 0.68, "D", moves=[(0.42, 0.72, 1)]),
                  P(0.60, 0.68, "D", moves=[(0.58, 0.72, 1)]),
                  P(0.80, 0.50, "15", moves=[(0.86, 0.42, 2)])],
            markers=[M(0.92, 0.44, "zone", "")],
            ball=0,
            ball_moves=[(0.92, 0.44, 2)],
        ),
    ]


def rugby_library() -> list[Drill]:
    return (handling_family() + phase_family() + breakdown_family()
            + move_family() + kicking_family() + finishing_family()
            + defence_family() + setpiece_family() + maul_family()
            + game_family() + gaps_family())

MAUL_NAME = {
    "en": "Maul", "en-GB": "Maul", "zh-CN": "冒尔推进", "zh-TW": "冒爾推進",
    "ja-JP": "モール", "ko-KR": "몰", "es-ES": "Maul", "fr-FR": "Maul",
    "id-ID": "Maul", "ms-MY": "Maul", "th-TH": "มอล", "vi-VN": "Maul",
}
MAUL_NOTE = {
    "en": "The ball goes to the back before the drive starts. A maul that "
          "moves with the ball at the front is one rip from a turnover.",
    "en-GB": "The ball goes to the back before the drive starts. A maul that "
             "moves with the ball at the front is one rip from a turnover.",
    "zh-CN": "先把球转移到最后面，再开始推进。球还在最前面就往前推的冒尔，被抢一下就丢球权。",
    "zh-TW": "先把球轉移到最後面，再開始推進。球還在最前面就往前推的冒爾，被搶一下就丟球權。",
    "ja-JP": "ドライブの前にボールを最後尾へ送る。先頭にボールを置いたまま動くモールは、一回のもぎ取りでターンオーバーだ。",
    "ko-KR": "드라이브 전에 공을 맨 뒤로 보내라. 공이 앞에 있는 몰은 한 번 뜯기면 턴오버다.",
    "es-ES": "El balón va atrás antes de empezar a empujar: un maul que avanza "
             "con el balón delante está a un tirón de la pérdida.",
    "fr-FR": "Le ballon passe au fond avant de pousser : un maul qui avance "
             "ballon devant est à un arrachage du turnover.",
    "id-ID": "Bola ke belakang dulu sebelum dorongan dimulai.",
    "ms-MY": "Bola ke belakang dahulu sebelum tolakan bermula.",
    "th-TH": "ส่งบอลไปท้ายสุดก่อนเริ่มดัน มอลที่บอลอยู่หน้าโดนกระชากทีเดียวก็เสีย",
    "vi-VN": "Đưa bóng về cuối trước khi bắt đầu đẩy.",
}


def maul_family() -> list[Drill]:
    """The lineout's second act — a coach reviewing the set pieces asked
    where it was."""
    out = []
    for key, label, defenders in [("drive", "driving from the lineout", 3),
                                  ("defend", "defending it", 5)]:
        y = 0.40
        pod = [P(-0.02 if i == 0 else 0.13 + 0.025 * (i - 1),
                 y + (0.012 * i if i else 0.03), "2" if i == 0 else f"{i + 3}",
                 moves=[(0.16 + 0.02 * (i - 1), y - 0.06 + 0.012 * i, 1)]
                 if i else [(0.06, y + 0.02, 1)])
               for i in range(6)]
        out.append(Drill(
            id=f"rg_maul_{key}", category="setpiece", minutes=12, rel=True,
            # A maul is players bound to each other; spread apart it is not a maul.
            tight=True,
            free=(key == "drive"), off_surface=True,
            name=suffixed(MAUL_NAME, label), note=MAUL_NOTE,
            home=pod,
            away=[P(0.20 + 0.03 * i, y - 0.10, "D",
                    moves=[(0.18 + 0.03 * i, y - 0.05, 1)])
                  for i in range(defenders)],
            ball=0,
        ))
    return out

