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
            home.append(P(x, y, f"{10 + i}",
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
            away=[P(start[0] + 0.04, TRY_LINE + 0.02, "D",
                    moves=[(start[0] + 0.02, TRY_LINE + 0.05, 0)]),
                  P(0.50, TRY_LINE - 0.04, "D")],
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
    out = []
    for key, label, n, y in [("lineout_five", "the five-man lineout", 5, 0.46),
                             ("lineout_seven", "the seven-man lineout", 7, 0.46),
                             ("scrum", "the scrum", 8, 0.54),
                             ("kick_off", "receiving the kick-off", 6, 0.62)]:
        if key.startswith("lineout"):
            # The hooker throws from outside the touchline — a lineout with
            # no thrower is not a lineout, and they are why off_surface is set.
            home = [P(-0.02, y + 0.02 * (n // 2), "2",
                      moves=[(0.01, y + 0.02 * (n // 2), 1)])] + [
                P(0.14, y + 0.02 * i, f"{i + 3}",
                  moves=[(0.16, y - 0.03 + 0.02 * i, 0)]) for i in range(n)]
            away = [P(0.22, y + 0.02 * i, "D") for i in range(n)]
        elif key == "scrum":
            home = [P(0.44 + 0.03 * (i % 3), y + 0.02 * (i // 3), f"{i + 1}",
                      moves=[(0.44 + 0.03 * (i % 3), y - 0.03 + 0.02 * (i // 3), 0)])
                    for i in range(n)]
            away = [P(0.44 + 0.03 * (i % 3), y - 0.06 + 0.02 * (i // 3), "D")
                    for i in range(n)]
        else:
            home = [P(x, y, f"{i + 1}", moves=[(x, y - 0.10, 0), (x, y - 0.04, 1)])
                    for i, (x, y) in enumerate(line_of(n, y))]
            away = [P(x, 0.40, "D", moves=[(x, 0.50, 0)]) for x, _ in line_of(n, 0.40)]
        out.append(Drill(
            id=f"rg_set_{key}", category="setpiece", minutes=12, rel=True,
            free=(key in ("lineout_five", "kick_off")),
            off_surface=key.startswith("lineout"),
            name=suffixed(SET_NAME, label), note=SET_NOTE,
            home=home, away=away, ball=0,
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
            free=(n == 5),
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=[P(x, y, f"{i + 1}", moves=[(x, y - 0.08, 0)])
                  for i, (x, y) in enumerate(spots)],
            away=[P(x, 0.38, chr(65 + i), moves=[(x, 0.46, 0)])
                  for i, (x, _) in enumerate(spots)],
            ball=0,
        ))
    return out


def rugby_library() -> list[Drill]:
    return (handling_family() + phase_family() + breakdown_family()
            + move_family() + kicking_family() + finishing_family()
            + defence_family() + setpiece_family() + maul_family()
            + game_family())

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
            free=(key == "drive"), off_surface=True,
            name=suffixed(MAUL_NAME, label), note=MAUL_NOTE,
            home=pod,
            away=[P(0.20 + 0.03 * i, y - 0.10, "D",
                    moves=[(0.18 + 0.03 * i, y - 0.05, 1)])
                  for i in range(defenders)],
            ball=0,
        ))
    return out

