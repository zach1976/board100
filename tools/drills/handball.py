"""The handball library.

Attacking upward, goal at y=0. The two lines that shape everything are the
6 m goal-area arc (y≈0.15) and the 9 m free-throw line (y≈0.23): the attack
lives between them and the defence decides how much of that band it gives up.
"""
from .engine import Drill, M, P, ring, suffixed

GOAL = (0.50, 0.02)
SIX, NINE, SEVEN_M = 0.155, 0.235, 0.175
# The six attacking positions, in the order a coach names them.
LW, LB, CB, RB, RW = ((0.10, 0.22), (0.26, 0.31), (0.50, 0.34),
                      (0.74, 0.31), (0.90, 0.22))
PIVOT = (0.50, 0.175)
BACKCOURT = (LB, CB, RB)


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
            spots = ring(5, 0.5, 0.40, 0.26, 0.13)
            home = [P(x, y, f"{i + 1}", moves=[(x + (0.5 - x) * 0.2, y, i % 2)])
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
    specs = [("wide", "wide to wide"), ("with_pivot", "through the pivot"),
             ("second_wave", "with a second wave")]
    out = []
    for key, label in specs:
        home = [P(*LW, "LW"), P(*LB, "LB", moves=[(LB[0] + 0.04, LB[1] - 0.05, 0)]),
                P(*CB, "CB", moves=[(CB[0], CB[1] - 0.05, 1)]),
                P(*RB, "RB", moves=[(RB[0] - 0.04, RB[1] - 0.05, 2)]),
                P(*RW, "RW")]
        if key != "wide":
            home.append(P(*PIVOT, "PIV", moves=[(0.36, SIX + 0.02, 1)]))
        if key == "second_wave":
            home.append(P(0.50, 0.52, "6", moves=[(0.44, 0.34, 2)]))
        out.append(Drill(
            id=f"hb_circulation_{key}", category="possession", minutes=12,
            rel=True, free=(key == "with_pivot"),
            name=suffixed(CIRC_NAME, label), note=CIRC_NOTE,
            home=home,
            away=[P(x, y, "D") for x, y in defence_line(6, SIX + 0.015)]
                 + [P(*GOAL, "GK", role="GK")],
            ball=1,
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
    specs = [
        ("cross_backs", "crossing the backs", LB, RB),
        ("wing_break", "the wing break-in", LW, LB),
        ("pivot_screen", "off the pivot's screen", CB, PIVOT),
        ("overload_left", "overloading the left", LB, LW),
        ("empty_goal", "seven against six", CB, RB),
    ]
    out = []
    for key, label, a, b in specs:
        runners = [
            P(*a, "1", moves=[(a[0] + (b[0] - a[0]) * 0.7, SIX + 0.05, 0),
                              (b[0], SIX + 0.02, 1)]),
            P(*b, "2", moves=[(a[0], b[1] - 0.05, 0), (a[0], SIX + 0.03, 1)]),
        ]
        rest = [P(*p, lbl) for p, lbl in
                ((LW, "LW"), (CB, "CB"), (RW, "RW"), (PIVOT, "PIV"))
                if p not in (a, b)]
        if key == "empty_goal":
            rest.append(P(0.50, 0.52, "7", moves=[(0.44, 0.36, 1)]))
        out.append(Drill(
            id=f"hb_attack_{key}", category="attacking", minutes=12, rel=True,
            free=(key in ("cross_backs", "wing_break")),
            name=suffixed(ATTACK_NAME, label), note=ATTACK_NOTE,
            home=runners + rest,
            away=[P(x, y, "D") for x, y in defence_line(6, SIX + 0.015)]
                 + [P(*GOAL, "GK", role="GK")],
            ball=0,
        ))
    return out


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
    specs = [("jump_nine", "the jump shot from 9 m", CB, (0.38, 0.03)),
             ("wing_angle", "from the wing angle", LW, (0.60, 0.04)),
             ("pivot_turn", "the pivot's turn", PIVOT, (0.40, 0.04)),
             ("break_through", "after breaking through", LB, (0.58, 0.03))]
    out = []
    for key, label, frm, target in specs:
        out.append(Drill(
            id=f"hb_shot_{key}", category="finishing", minutes=10, rel=True,
            free=(key in ("jump_nine", "wing_angle")),
            name=suffixed(SHOT_NAME, label), note=SHOT_NOTE,
            home=[P(*frm, "S", moves=[(frm[0] + (0.5 - frm[0]) * 0.3,
                                       SIX + 0.03, 0)])],
            away=[P(*GOAL, "GK", role="GK", moves=[(target[0] * 0.5 + 0.25, 0.05, 1)]),
                  P(frm[0], SIX + 0.02, "D", moves=[(frm[0], SIX + 0.05, 0)])],
            markers=[M(*target, "zone", "")],
            ball=0,
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
    """The four systems, described by how far the front line stands out."""
    specs = [("six_zero", "6-0", [(6, SIX + 0.015)]),
             ("five_one", "5-1", [(5, SIX + 0.015), (1, NINE)]),
             ("three_two_one", "3-2-1", [(3, SIX + 0.015), (2, NINE - 0.03), (1, NINE + 0.03)]),
             ("four_two", "4-2", [(4, SIX + 0.015), (2, NINE - 0.02)])]
    out = []
    for key, label, rows in specs:
        away = []
        for n, y in rows:
            for x, yy in defence_line(n, y, 0.66 if y < NINE else 0.30):
                away.append(P(x, yy, "D", moves=[(x + (0.5 - x) * 0.10, yy - 0.03, 0),
                                                 (x, yy, 1)]))
        away.append(P(*GOAL, "GK", role="GK"))
        out.append(Drill(
            id=f"hb_defence_{key}", category="defending", minutes=12, rel=True,
            free=(key in ("six_zero", "five_one")),
            name=suffixed(DEF_NAME, label), note=DEF_NOTE,
            home=[P(*p, lbl, moves=[(p[0], p[1] - 0.04, 0)]) for p, lbl in
                  ((LW, "LW"), (LB, "LB"), (CB, "CB"), (RB, "RB"),
                   (RW, "RW"), (PIVOT, "PIV"))],
            away=away, ball=2,
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
        starts = [(0.10, 0.72), (0.90, 0.72), (0.30, 0.80),
                  (0.70, 0.80), (0.50, 0.86)][:n]
        out.append(Drill(
            id=f"hb_break_{key}", category="attacking", minutes=10, rel=True,
            free=(key == "first_wave"),
            name=suffixed(BREAK_NAME, label), note=BREAK_NOTE,
            home=[P(0.50, 0.95, "GK", role="GK")] + [
                P(x, y, f"{i + 1}",
                  moves=[(x + (0.5 - x) * 0.4, 0.40, 0), (x + (0.5 - x) * 0.7, SIX + 0.03, 1)])
                for i, (x, y) in enumerate(starts)
            ],
            away=[P(0.44, 0.30, "D", moves=[(0.46, 0.20, 1)]),
                  P(*GOAL, "GK", role="GK")],
            ball=1,
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


def setpiece_family() -> list[Drill]:
    out = [Drill(
        id="hb_set_seven_metre", category="setpiece", minutes=6, rel=True,
        free=True, name=suffixed(SET_NAME, "the 7 m throw"), note=SET_NOTE,
        home=[P(0.50, SEVEN_M, "S", moves=[(0.50, SEVEN_M - 0.02, 0)])],
        away=[P(*GOAL, "GK", role="GK", moves=[(0.42, 0.05, 1)])],
        markers=[M(0.50, SEVEN_M, "square", ""), M(0.38, 0.03, "zone", "")],
        ball=0,
    )]
    routines = [("nine_metre", "the 9 m free throw", CB, LB),
                ("throw_off", "the throw-off", (0.50, 0.50), (0.34, 0.44)),
                ("sideline", "the sideline throw", (0.02, 0.30), (0.22, 0.26))]
    for key, label, thrower, runner in routines:
        out.append(Drill(
            id=f"hb_set_{key}", category="setpiece", minutes=8, rel=True,
            free=(key == "nine_metre"), off_surface=(key == "sideline"),
            name=suffixed(SET_NAME, label), note=SET_NOTE,
            home=[P(*thrower, "1", moves=[(thrower[0], thrower[1] - 0.03, 1)]),
                  P(*runner, "2", moves=[(runner[0] + (0.5 - runner[0]) * 0.5,
                                          SIX + 0.04, 1)]),
                  P(*PIVOT, "PIV", moves=[(0.62, SIX + 0.02, 0)])],
            away=[P(x, y, "D") for x, y in defence_line(6, SIX + 0.015)]
                 + [P(*GOAL, "GK", role="GK")],
            ball=0,
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
        spots = ring(n, 0.5, 0.32, 0.30, 0.09)
        out.append(Drill(
            id=f"hb_game_{n}v{n}", category="ssg", minutes=15, rel=True,
            free=(n == 4),
            name=suffixed(GAME_NAME, f"{n}v{n}"), note=GAME_NOTE,
            home=[P(x, y, f"{i + 1}", moves=[(x + (0.5 - x) * 0.2, y - 0.04, 0)])
                  for i, (x, y) in enumerate(spots)],
            away=[P(x, y + 0.10, "D", moves=[(x, y + 0.06, 0)]) for x, y in spots]
                 + [P(*GOAL, "GK", role="GK")],
            ball=0,
        ))
    return out


def handball_library() -> list[Drill]:
    return (warmup_family() + circulation_family() + attack_family()
            + break_family() + shooting_family() + defence_family()
            + setpiece_family() + game_family())
