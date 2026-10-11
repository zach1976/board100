"""The pickleball library.

Pickleball is a game about getting to the kitchen line and staying there, so
the geometry that matters is three bands: the non-volley zone at the net, the
transition zone behind it, and the baseline. Home is the bottom half; the net
is y=0.5 and the home kitchen line is y=0.66.
"""
from .engine import Drill, M, P, Spot, suffixed

KITCHEN = 0.66          # home non-volley zone line
KITCHEN_AWAY = 0.34
# Behind the baseline by more than half a figure, so the server is not drawn
# standing on his own line. See BEHIND in tennis.py.
BEHIND = 0.03
BASELINE = 0.97
TRANSITION = 0.80
K_L, K_R = (0.30, KITCHEN), (0.70, KITCHEN)
B_L, B_R = (0.28, BASELINE), (0.72, BASELINE)


def mirror(pt):
    return (pt[0], 1.0 - pt[1])


# Behind the kitchen lines, feet never on or over them: a dink is played
# from just behind the line, and every "step in" the boards used to draw
# put a foot in the non-volley zone.
KH, KA = KITCHEN + 0.02, KITCHEN_AWAY - 0.02
# The serve: underhand, from behind the baseline, diagonally into the far
# service court past the kitchen. Home serves from his right (canvas right),
# so it lands canvas LEFT on the far side, where the returner waits behind
# his baseline. The returner's partner waits at the kitchen line — the
# serving partner stays back with the server (two-bounce rule).
SRV = (0.72, 1 + BEHIND)
SRV_PARTNER = (0.28, 1.02)
RET = (0.28, -0.02)
RET_PARTNER = (0.70, KA)


def through(frm, via, y):
    """The point at depth [y] on the line from [frm] through [via]."""
    t = (y - frm[1]) / (via[1] - frm[1])
    return (frm[0] + (via[0] - frm[0]) * t, y)


DINK_NAME = {
    "en": "Dink", "en-GB": "Dink", "zh-CN": "放小球", "zh-TW": "放小球",
    "ja-JP": "ディンク", "ko-KR": "딩크", "es-ES": "Dink",
    "fr-FR": "Dink", "id-ID": "Dink", "ms-MY": "Dink",
    "th-TH": "ดิ้งก์", "vi-VN": "Bỏ nhỏ",
}
DINK_NOTE = {
    "en": "Push from the shoulder with a still wrist, and aim for the top of "
          "the net rather than the floor. A dink that rises is a dink attacked.",
    "en-GB": "Push from the shoulder with a still wrist, and aim for the top "
             "of the net rather than the floor. A dink that rises is a dink attacked.",
    "zh-CN": "用肩推、手腕不动，瞄网带上沿而不是地板。一个往上飘的小球，就是一个被打死的小球。",
    "zh-TW": "用肩推、手腕不動，瞄網帶上沿而不是地板。一個往上飄的小球，就是一個被打死的小球。",
    "ja-JP": "手首を固めて肩から押す。狙うのは床ではなくネットの上端。浮いたディンクは叩かれるディンク。",
    "ko-KR": "손목은 고정하고 어깨로 밀어라. 바닥이 아니라 네트 윗부분을 겨냥한다. 뜬 딩크는 맞는 딩크다.",
    "es-ES": "Empuja desde el hombro con la muñeca firme y apunta al borde de "
             "la red, no al suelo: un dink que sube es un dink atacado.",
    "fr-FR": "Pousse depuis l'épaule, poignet fixe, en visant le haut du filet "
             "et non le sol : un dink qui monte est un dink attaqué.",
    "id-ID": "Dorong dari bahu dengan pergelangan diam, bidik bibir net.",
    "ms-MY": "Tolak dari bahu dengan pergelangan tangan tetap, sasarkan bibir jaring.",
    "th-TH": "ดันจากไหล่ ข้อมือนิ่ง เล็งขอบบนของเน็ต ไม่ใช่พื้น ดิ้งก์ที่ลอยคือดิ้งก์ที่โดนตบ",
    "vi-VN": "Đẩy từ vai, cổ tay cố định, nhắm mép trên của lưới.",
}


def dink_family() -> list[Drill]:
    """Both start where the pattern is played from, so the ball goes the
    way the name says. 2 used to stand straight across and slide wide only
    after the ball had arrived: "cross-court" and "pulling wide" were drawn
    as straight dinks."""
    specs = [
        # key, label, 1's spot, 2's spot, where the dink takes 2
        ("straight", "straight", (0.70, KH), (0.70, KA), None),
        ("cross", "cross-court", (0.70, KH), (0.30, KA), None),
        ("to_backhand", "to the backhand", (0.30, KH), (0.50, KA), (0.66, KA)),
        ("pull", "pulling them wide", (0.70, KH), (0.30, KA), (0.08, KA)),
    ]
    out = []
    for key, label, one, two, pulled in specs:
        two_moves = ([pulled + (0,), (two[0], two[1], 1)] if pulled
                     else [(two[0] + (0.05 if two[0] < 0.5 else -0.05), KA, 1)])
        out.append(Drill(
            id=f"pb_dink_{key}", category="possession", minutes=10, rel=True,
            free=(key in ("straight", "cross")),
            name=suffixed(DINK_NAME, label), note=DINK_NOTE,
            home=[P(*one, "1", moves=[(one[0] + (0.05 if one[0] < 0.5 else -0.05), KH, 0),
                                      one + (1,)])],
            away=[P(*two, "2", moves=two_moves)],
            markers=[M(0.5, KITCHEN, "cone", ""), M(0.5, KITCHEN_AWAY, "cone", "")],
            ball=0, ball_to=[("a0", 0), (0, 1)],
        ))
    return out


THIRD_NAME = {
    "en": "Third shot", "en-GB": "Third shot", "zh-CN": "第三拍",
    "zh-TW": "第三拍", "ja-JP": "サードショット", "ko-KR": "서드샷",
    "es-ES": "Tercer golpe", "fr-FR": "Troisième frappe",
    "id-ID": "Pukulan ketiga", "ms-MY": "Pukulan ketiga",
    "th-TH": "ลูกที่สาม", "vi-VN": "Cú thứ ba",
}
THIRD_NOTE = {
    "en": "The third shot exists to buy you the walk to the kitchen. Hit it "
          "and go — a perfect drop you admire from the baseline bought nothing.",
    "en-GB": "The third shot exists to buy you the walk to the kitchen. Hit it "
             "and go — a perfect drop you admire from the baseline bought nothing.",
    "zh-CN": "第三拍存在的意义，是为你换来走到网前的那几步。打完就上——站在底线欣赏自己那个完美小球，什么也没换到。",
    "zh-TW": "第三拍存在的意義，是為你換來走到網前的那幾步。打完就上——站在底線欣賞自己那個完美小球，什麼也沒換到。",
    "ja-JP": "サードショットはキッチンまで歩く時間を買うためにある。打ったら前へ。ベースラインで見惚れる完璧なドロップは何も買っていない。",
    "ko-KR": "서드샷은 키친까지 걸어갈 시간을 사기 위한 것이다. 치고 나가라.",
    "es-ES": "El tercer golpe existe para comprarte el paseo a la cocina: "
             "pégalo y avanza; un drop perfecto admirado desde el fondo no compra nada.",
    "fr-FR": "La troisième frappe sert à payer ta montée au filet : frappe et "
             "avance ; un drop parfait admiré du fond n'achète rien.",
    "id-ID": "Pukulan ketiga ada untuk membeli langkahmu ke kitchen. Pukul lalu maju.",
    "ms-MY": "Pukulan ketiga wujud untuk membeli langkah anda ke kitchen. Pukul dan maju.",
    "th-TH": "ลูกที่สามมีไว้ซื้อเวลาเดินขึ้นไปหน้าเน็ต ตีแล้วขึ้นเลย",
    "vi-VN": "Cú thứ ba tồn tại để mua bước tiến lên lưới. Đánh rồi tiến.",
}


def third_shot_family() -> list[Drill]:
    """Serve, return, THIRD shot — in that order, from where the rules put
    everybody. It used to open with a ball from the centre line landing in
    the receivers' kitchen, with the receiving team already at the line,
    and the third shot itself was never drawn."""
    out = []
    for key, label, land in [("drop", "drop", (0.44, 0.42)),
                             ("drive", "drive", (0.50, 0.24)),
                             ("fifth", "the fifth from the transition zone", (0.40, 0.42))]:
        if key == "fifth":
            # The third is dropped to B, B blocks it back to 1 in the
            # transition zone, and 1 plays the fifth into the kitchen.
            home = [P(*SRV, "1", moves=[(0.66, 1.0, 1), (0.64, 0.88, 2),
                                        (0.62, TRANSITION, 3), (0.62, 0.74, 4)]),
                    P(*SRV_PARTNER, "2", moves=[(0.34, 0.88, 2), (0.36, TRANSITION, 3)])]
            ball_to = [("a0", 0), (0, 1), ("a1", 2), (0, 3), (Spot(*land), 4)]
        else:
            home = [P(*SRV, "1", moves=[(0.66, 1.0, 1), (0.64, TRANSITION, 2)]),
                    P(*SRV_PARTNER, "2", moves=[(0.36, TRANSITION, 2)])]
            ball_to = [("a0", 0), (0, 1), (Spot(*land), 2)]
        out.append(Drill(
            id=f"pb_third_{key}", category="attacking", minutes=12, rel=True,
            free=(key == "drop"), off_surface=True,
            name=suffixed(THIRD_NAME, label), note=THIRD_NOTE,
            home=home,
            # The returner follows his return to the kitchen line.
            away=[P(*RET, "A", moves=[(0.32, KA, 1)]), P(*RET_PARTNER, "B")],
            markers=[M(*land, "zone", ""), M(0.5, KITCHEN, "cone", "")],
            ball=0, ball_to=ball_to,
        ))
    return out


SPEEDUP_NAME = {
    "en": "Speed-up", "en-GB": "Speed-up", "zh-CN": "突然加速",
    "zh-TW": "突然加速", "ja-JP": "スピードアップ", "ko-KR": "스피드업",
    "es-ES": "Aceleración", "fr-FR": "Accélération",
    "id-ID": "Percepatan", "ms-MY": "Pecutan",
    "th-TH": "การเร่งจังหวะ", "vi-VN": "Tăng tốc",
}
SPEEDUP_NOTE = {
    "en": "Attack the ball that is above the net, at the shoulder they can't "
          "reach across. Speeding up a low ball starts a fight you're losing.",
    "en-GB": "Attack the ball that is above the net, at the shoulder they "
             "can't reach across. Speeding up a low ball starts a fight you're losing.",
    "zh-CN": "只打高过网的球，打向对手够不到的那侧肩膀。把低球加速，等于主动开启一场你处于下风的对轰。",
    "zh-TW": "只打高過網的球，打向對手夠不到的那側肩膀。把低球加速，等於主動開啟一場你處於下風的對轟。",
    "ja-JP": "ネットより高い球だけを、相手が回り込めない側の肩へ。低い球を速くするのは、負けている打ち合いを自分から始めることだ。",
    "ko-KR": "네트보다 높은 공만, 상대가 넘어올 수 없는 어깨 쪽으로 공격하라.",
    "es-ES": "Ataca solo la bola por encima de la red, al hombro que no pueden "
             "cruzar: acelerar una bola baja es iniciar un duelo que pierdes.",
    "fr-FR": "N'attaque que la balle au-dessus du filet, vers l'épaule qu'ils "
             "ne peuvent pas croiser : accélérer une balle basse, c'est perdre l'échange.",
    "id-ID": "Serang hanya bola di atas net, ke bahu yang tak bisa mereka silang.",
    "ms-MY": "Serang hanya bola di atas jaring, ke bahu yang tidak dapat mereka silang.",
    "th-TH": "เร่งเฉพาะลูกที่สูงกว่าเน็ต ไปที่ไหล่ที่เขาเอื้อมข้ามไม่ได้",
    "vi-VN": "Chỉ tấn công bóng cao hơn lưới, vào vai họ không với qua được.",
}


ERNIE_NOTE = {
    "en": "Go around the post, not through the kitchen, and go before he can see you: an Ernie the dinker has spotted is a lob into the space you just left.",
    "en-GB": "Go around the post, not through the kitchen, and go before he can see you: an Ernie the dinker has spotted is a lob into the space you just left.",
    "zh-CN": "从边线外绕过去，不能踩进非截击区，而且要在对方看见你之前动：被对手看见的 Ernie，换来的是一记挑向你刚让开那块空当的高球。",
    "zh-TW": "從邊線外繞過去，不能踩進非截擊區，而且要在對方看見你之前動：被對手看見的 Ernie，換來的是一記挑向你剛讓開那塊空檔的高球。",
    "ja-JP": "キッチンを通らずポストの外を回り、相手に見られる前に動く。読まれたアーニーは、空けたばかりのスペースへのロブになる。",
    "ko-KR": "키친을 밟지 말고 포스트 바깥으로 돌아가고, 상대가 보기 전에 움직여라. 들킨 어니는 방금 비운 공간으로 오는 로브다.",
    "es-ES": "Rodea el poste, no pises la cocina, y sal antes de que te vea: un Ernie cantado es un globo al hueco que acabas de dejar.",
    "fr-FR": "Contourne le poteau, ne traverse pas la cuisine, et pars avant qu'il te voie : un Ernie repéré devient un lob dans l'espace que tu viens de quitter.",
    "id-ID": "Putari tiang, jangan lewat kitchen, dan bergeraklah sebelum dia melihatmu.",
    "ms-MY": "Pusing di luar tiang, jangan masuk kitchen, dan bergerak sebelum dia nampak.",
    "th-TH": "อ้อมนอกเสา ห้ามเหยียบเขตห้ามวอลเลย์ และออกตัวก่อนที่เขาจะเห็น",
    "vi-VN": "Vòng ra ngoài cột lưới, không giẫm vào vùng cấm vô-lê, và đi trước khi anh ta thấy bạn.",
}


def speedup_family() -> list[Drill]:
    """The dink, the ball that sits up, and the speed-up itself — drawn,
    into a zone at A's shoulder or hip BEHIND his kitchen line. A used to
    walk onto a target inside his own kitchen and the attacking ball was
    never hit."""
    out = []
    for key, label, land in [("shoulder", "at the shoulder", (0.22, 0.27)),
                             ("hip", "at the hip", (0.37, 0.28))]:
        out.append(Drill(
            id=f"pb_speedup_{key}", category="attacking", minutes=10, rel=True,
            free=(key == "shoulder"),
            name=suffixed(SPEEDUP_NAME, label), note=SPEEDUP_NOTE,
            home=[P(0.70, KH, "1", moves=[(0.64, KH, 1)]),
                  P(0.30, KH, "2", moves=[(0.34, KH, 1)])],
            away=[P(0.30, KA, "A"), P(0.70, KA, "B")],
            markers=[M(*land, "zone", ""), M(0.5, KITCHEN, "cone", "")],
            ball=0, ball_to=[("a0", 0), (0, 1), (Spot(*land), 2)],
        ))
    # The Ernie: 1 dinks wide down his line, slips out past the sideline
    # while A sets up, and volleys A's next dink down the line from OUTSIDE
    # the court beside the post — he never touches the kitchen, and he
    # stays on his side of the net.
    out.append(Drill(
        id="pb_speedup_ernie", category="attacking", minutes=10, rel=True,
        off_surface=True,
        name=suffixed(SPEEDUP_NAME, "the Ernie"), note=ERNIE_NOTE,
        home=[P(0.30, KH, "1", moves=[(0.02, 0.72, 1), (-0.05, 0.56, 2)]),
              P(0.70, KH, "2", moves=[(0.56, KH, 1)])],
        away=[P(0.30, KA, "A", moves=[(0.12, KA, 0)]), P(0.70, KA, "B")],
        markers=[M(0.38, 0.26, "zone", ""), M(0.5, KITCHEN, "cone", "")],
        ball=0, ball_to=[("a0", 0), (0, 2), (Spot(0.38, 0.26), 3)],
    ))
    return out


PUTAWAY_NAME = {
    "en": "Put-away", "en-GB": "Put-away", "zh-CN": "终结球",
    "zh-TW": "終結球", "ja-JP": "決め球", "ko-KR": "마무리 샷",
    "es-ES": "Definición", "fr-FR": "Coup décisif",
    "id-ID": "Pukulan penentu", "ms-MY": "Pukulan penamat",
    "th-TH": "ลูกจบ", "vi-VN": "Cú kết thúc",
}
PUTAWAY_NOTE = {
    "en": "Hit down at their feet, not at the open court. Feet are where "
          "nobody has a good answer; the open court has a scramble in it.",
    "en-GB": "Hit down at their feet, not at the open court. Feet are where "
             "nobody has a good answer; the open court has a scramble in it.",
    "zh-CN": "往下打对手的脚，而不是打空档。脚下是谁都没有好办法的地方；空档里还藏着一次救球。",
    "zh-TW": "往下打對手的腳，而不是打空檔。腳下是誰都沒有好辦法的地方；空檔裡還藏著一次救球。",
    "ja-JP": "オープンコートではなく相手の足元へ叩く。足元は誰も答えを持たない場所で、オープンコートには拾い上げが残っている。",
    "ko-KR": "빈 코트가 아니라 상대 발밑으로 내리쳐라. 발밑엔 정답이 없다.",
    "es-ES": "Pega abajo, a sus pies, no al hueco: en los pies nadie tiene "
             "buena respuesta; el hueco todavía admite una carrera.",
    "fr-FR": "Frappe vers le bas, dans leurs pieds, pas dans l'espace libre : "
             "aux pieds personne n'a de réponse.",
    "id-ID": "Pukul ke bawah ke arah kaki mereka, bukan ke ruang kosong.",
    "ms-MY": "Pukul ke bawah ke arah kaki mereka, bukan ke ruang kosong.",
    "th-TH": "ตบลงที่เท้าเขา ไม่ใช่ที่ช่องว่าง ที่เท้าไม่มีใครมีคำตอบดี ๆ",
    "vi-VN": "Đánh xuống chân họ, không phải vào khoảng trống.",
}


def putaway_family() -> list[Drill]:
    """The ball that sits up, and the put-away itself, drawn into the
    zone; the defenders stay behind their line instead of walking onto it.
    Around the post is played from OUTSIDE the sideline, the ball going
    round the post rather than over the net."""
    out = []
    specs = [
        # key, label, where 1 meets the pop-up, zone
        ("overhead", "the overhead", (0.62, 0.78), (0.50, 0.25)),
        ("roll_volley", "the roll volley", (0.64, KH), (0.20, 0.28)),
        ("atp", "around the post", (1.06, 0.58), (0.88, 0.42)),
    ]
    for key, label, meet, land in specs:
        out.append(Drill(
            id=f"pb_putaway_{key}", category="finishing", minutes=8, rel=True,
            free=(key == "overhead"), off_surface=(key == "atp"),
            name=suffixed(PUTAWAY_NAME, label), note=PUTAWAY_NOTE,
            home=[P(0.70, KH, "1", moves=[meet + (1,)]),
                  P(0.30, KH, "2", moves=[(0.36, KH, 1)])],
            away=[P(0.30, KA, "A"), P(0.70, KA, "B")],
            markers=[M(*land, "zone", "")],
            ball=0, ball_to=[("a0", 0), (0, 1), (Spot(*land), 2)],
        ))
    return out


DEFEND_NAME = {
    "en": "Defending", "en-GB": "Defending", "zh-CN": "防守", "zh-TW": "防守",
    "ja-JP": "ディフェンス", "ko-KR": "수비", "es-ES": "Defensa",
    "fr-FR": "Défense", "id-ID": "Bertahan", "ms-MY": "Pertahanan",
    "th-TH": "การรับ", "vi-VN": "Phòng thủ",
}
DEFEND_NOTE = {
    "en": "Soft hands, paddle out in front, and get the ball back down into "
          "the kitchen. Every hard reply hands them a second attack.",
    "en-GB": "Soft hands, paddle out in front, and get the ball back down into "
             "the kitchen. Every hard reply hands them a second attack.",
    "zh-CN": "手要软，拍子放在身前，把球重新压回厨房区。每一次硬碰硬的回球，都是送对方第二次进攻。",
    "zh-TW": "手要軟，拍子放在身前，把球重新壓回廚房區。每一次硬碰硬的回球，都是送對方第二次進攻。",
    "ja-JP": "手は柔らかく、パドルは体の前。ボールをキッチンへ落とし直す。強く返すたびに相手へ2度目の攻撃を渡している。",
    "ko-KR": "손은 부드럽게, 패들은 몸 앞에. 공을 다시 키친으로 떨어뜨려라.",
    "es-ES": "Manos blandas, pala por delante, y devuelve la bola abajo a la "
             "cocina: cada respuesta dura les regala un segundo ataque.",
    "fr-FR": "Mains souples, raquette devant, et remets la balle bas dans la "
             "cuisine : chaque réponse dure leur offre une seconde attaque.",
    "id-ID": "Tangan lembut, pedal di depan, dan kembalikan bola ke kitchen.",
    "ms-MY": "Tangan lembut, pedal di hadapan, dan kembalikan bola ke kitchen.",
    "th-TH": "มือนุ่ม ไม้อยู่ข้างหน้า แล้วหย่อนบอลกลับลงหน้าเน็ต",
    "vi-VN": "Tay mềm, vợt phía trước, đưa bóng trở lại vùng bếp.",
}


def defend_family() -> list[Drill]:
    # Where the DEFENDER ends up, not where the ball goes: 0.44 and 0.40 are
    # in the opponents' half, and a reset is a step up to your own kitchen
    # line, a counter is held at it.
    specs = [("block", "the block", (0.62, KITCHEN + 0.01)),
             ("reset", "the reset from transition", (0.50, KITCHEN + 0.02)),
             ("lob", "the lob over your head", (0.50, 0.92)),
             # Held at the line, a step toward the middle — not on top of
             # his partner (0.40 left them 0.6 m apart).
             ("counter", "the counter in a firefight", (0.54, KITCHEN + 0.02))]
    # A attacks, 1 meets it where the spec says, and 1's defensive ball —
    # soft, back down into A's kitchen — is drawn: the drill is named for
    # it. (A used to "move into position" with the ball, and the board
    # ended on A's attack.)
    reply = {"lob": (0.40, 0.40)}
    out = []
    for key, label, to in specs:
        start = (0.62, TRANSITION) if key == "reset" else (0.70, KH)
        out.append(Drill(
            id=f"pb_defend_{key}", category="defending", minutes=10, rel=True,
            free=(key in ("block", "reset")),
            name=suffixed(DEFEND_NAME, label), note=DEFEND_NOTE,
            home=[P(*start, "1", moves=[(to[0], min(to[1], BASELINE), 0)]),
                  P(0.30, KH, "2", moves=[(0.34, KH, 1)])],
            away=[P(0.66, KA, "A"), P(0.30, KA, "B")],
            markers=[M(0.5, KITCHEN, "cone", "")],
            ball=(0.66, KA),
            ball_to=[(0, 0), (Spot(*reply.get(key, (0.56, 0.42))), 1)],
        ))
    return out


SERVE_NAME = {
    "en": "Serve and return", "en-GB": "Serve and return",
    "zh-CN": "发球与接发", "zh-TW": "發球與接發",
    "ja-JP": "サーブとリターン", "ko-KR": "서브와 리턴",
    "es-ES": "Saque y resto", "fr-FR": "Service et retour",
    "id-ID": "Servis dan pengembalian", "ms-MY": "Servis dan pulangan",
    "th-TH": "เสิร์ฟและรับเสิร์ฟ", "vi-VN": "Giao và trả bóng",
}
SERVE_NOTE = {
    "en": "Both go deep, for different reasons: the serve to keep them back, "
          "the return to buy the time you need to walk in behind it."
             " The serve itself is underhand: contact below the waist, paddle moving upward, one foot behind the baseline, and diagonally past the kitchen.",
    "en-GB": "Both go deep, for different reasons: the serve to keep them "
             "back, the return to buy the time you need to walk in behind it."
             " The serve itself is underhand: contact below the waist, paddle moving upward, one foot behind the baseline, and diagonally past the kitchen.",
    "zh-CN": "两拍都要打深，理由不同：发球是把人压在后面，接发球是给自己换来跟着上网的时间。" "发球本身必须下手：击球点低于腰部、拍头向上挥，一只脚在底线后，斜线发过厨房区。",
    "zh-TW": "兩拍都要打深，理由不同：發球是把人壓在後面，接發球是給自己換來跟著上網的時間。" "發球本身必須下手：擊球點低於腰部、拍頭向上揮，一隻腳在底線後，斜線發過廚房區。",
    "ja-JP": "どちらも深く、理由は別。サーブは相手を下げるため、リターンは前に詰める時間を買うため。" "サーブはアンダーハンド：腰より下で打ち、パドルは下から上へ、片足はベースラインの後ろ、対角へキッチンを越えて。",
    "ko-KR": "둘 다 깊게, 이유는 다르다. 서브는 상대를 뒤에 묶고, 리턴은 앞으로 갈 시간을 산다. " "서브는 언더핸드로: 허리 아래에서 맞히고 패들은 아래에서 위로, 한 발은 베이스라인 뒤, 대각선으로 키친 너머에.",
    "es-ES": "Ambos profundos, por motivos distintos: el saque para fijarlos "
             "atrás, el resto para comprar el tiempo de subir tras él."
             " El saque es por abajo: contacto por debajo de la cintura, pala hacia arriba, un pie detrás de la línea de fondo y en diagonal, más allá de la cocina.",
    "fr-FR": "Les deux profonds, pour des raisons différentes : le service "
             "pour les tenir au fond, le retour pour gagner le temps de monter."
             " Le service se fait par en dessous : contact sous la taille, raquette montante, un pied derrière la ligne de fond, en diagonale au-delà de la cuisine.",
    "id-ID": "Keduanya dalam, dengan alasan berbeda."
             " Servisnya underhand: kontak di bawah pinggang, paddle mengayun ke atas, satu kaki di belakang garis belakang, menyilang melewati kitchen.",
    "ms-MY": "Kedua-duanya dalam, atas sebab berbeza."
             " Servis dibuat dari bawah: sentuhan di bawah pinggang, pedal dihayun ke atas, sebelah kaki di belakang garisan belakang, secara pepenjuru melepasi kitchen.",
    "th-TH": "ทั้งคู่ต้องลึก แต่ด้วยเหตุผลต่างกัน"
             " การเสิร์ฟต้องตีลูกล่าง: จุดกระทบต่ำกว่าเอว ไม้เหวี่ยงขึ้น เท้าข้างหนึ่งอยู่หลังเส้นหลัง และเสิร์ฟทแยงให้เลยเขตครัว",
    "vi-VN": "Cả hai đều sâu, vì lý do khác nhau."
             " Giao bóng phải từ dưới lên: điểm chạm dưới thắt lưng, vợt vung lên, một chân sau vạch cuối sân, chéo sân và qua khỏi vùng bếp.",
}


def serve_family() -> list[Drill]:
    # A pickleball serve is underhand, from behind the baseline, and
    # diagonal: from the right court (x 0.72) it lands in the far LEFT
    # court, past the kitchen. The receiver stands on the line from the
    # server through the zone, behind his baseline — the "deep" serve used
    # to be drawn landing at R 2.2 m inside it, the same path for both
    # targets. For a right-handed receiver on the far side the backhand is
    # screen-right of him.
    out = []
    for key, label, land in [("deep_backhand", "deep to the backhand", (0.40, 0.07)),
                             ("deep_forehand", "deep to the forehand", (0.16, 0.08))]:
        out.append(Drill(
            id=f"pb_serve_{key}", category="setpiece", minutes=8, rel=True,
            free=(key == "deep_backhand"), off_surface=True,
            name=suffixed(SERVE_NAME, label), note=SERVE_NOTE,
            # The server stays back after the serve: the return must bounce.
            home=[P(*SRV, "S", moves=[(0.66, 1 + BEHIND * 0.7, 1)])],
            away=[P(*RET, "R", moves=[through(SRV, land, -0.02) + (0,),
                                      (0.30, KA, 1)])],
            markers=[M(*land, "zone", "")],
            ball=0, ball_to=[("a0", 0), (0, 1)],
        ))
    # Return and come in: S serves from the far side; R returns deep and
    # walks in to the kitchen behind it while S stays back — the two-bounce
    # rule is what buys him the walk.
    srv_far = (0.28, -BEHIND)
    out.append(Drill(
        id="pb_serve_return_and_in", category="setpiece", minutes=8, rel=True,
        off_surface=True,
        name=suffixed(SERVE_NAME, "return and come in"), note=SERVE_NOTE,
        home=[P(0.72, 1.02, "R", moves=[(0.70, TRANSITION, 1), (0.70, KH, 2)])],
        away=[P(*srv_far, "S", moves=[(0.36, -BEHIND * 0.7, 0)])],
        markers=[M(0.36, 0.07, "zone", "")],
        ball=srv_far, ball_to=[(0, 0), ("a0", 1)],
    ))
    return out


SHAPE_NAME = {
    "en": "Team shape", "en-GB": "Team shape", "zh-CN": "站位配合",
    "zh-TW": "站位配合", "ja-JP": "ペアの陣形", "ko-KR": "팀 포메이션",
    "es-ES": "Posicionamiento", "fr-FR": "Placement de l'équipe",
    "id-ID": "Formasi tim", "ms-MY": "Formasi pasukan",
    "th-TH": "การยืนของทีม", "vi-VN": "Đội hình",
}
SHAPE_NOTE = {
    "en": "The pair moves as one line and stays connected — the gap between "
          "you is the only shot they actually want.",
    "en-GB": "The pair moves as one line and stays connected — the gap between "
             "you is the only shot they actually want.",
    "zh-CN": "两个人像一条线一样一起移动，始终连着——你们之间的空当，才是对手真正想打的那一拍。",
    "zh-TW": "兩個人像一條線一樣一起移動，始終連著——你們之間的空檔，才是對手真正想打的那一拍。",
    "ja-JP": "ペアは一本の線として動き、離れない。二人の間の隙間こそ、相手が本当に狙っているコースだ。",
    "ko-KR": "두 사람은 한 줄로 움직이며 끊기지 않는다. 둘 사이의 틈이 상대가 진짜 노리는 코스다.",
    "es-ES": "La pareja se mueve como una línea y no se desconecta: el hueco "
             "entre vosotros es el único golpe que quieren de verdad.",
    "fr-FR": "La paire se déplace comme une ligne et reste connectée : le trou "
             "entre vous est le seul coup qu'ils veulent vraiment.",
    "id-ID": "Pasangan bergerak sebagai satu garis dan tetap terhubung.",
    "ms-MY": "Pasangan bergerak sebagai satu garisan dan kekal berhubung.",
    "th-TH": "คู่ต้องขยับเป็นเส้นเดียวและไม่ขาดจากกัน",
    "vi-VN": "Cặp đôi di chuyển như một đường và luôn liền mạch.",
}


def shape_family() -> list[Drill]:
    specs = [
        ("both_up", "both at the kitchen", [K_L, K_R], [K_L, K_R]),
        # Stacking means both partners on the SAME side of the centreline
        # before the ball is struck, then one crosses. They used to straddle
        # it at 0.42 and 0.52, which is just standard positioning. The
        # server is also behind his baseline now, not 0.4 m inside it.
        ("stacking", "stacking", [(0.30, 1.02), (0.36, KITCHEN)],
         [(0.66, TRANSITION), (0.34, KITCHEN)]),
        ("switch_on_lob", "switching on the lob", [K_L, K_R],
         [(0.66, TRANSITION), (0.30, KITCHEN)]),
    ]
    out = []
    for key, label, start, end in specs:
        out.append(Drill(
            # Both at the kitchen is the attacking position in pickleball
            # and stacking is a serve/return tactic; neither is defending.
            id=f"pb_shape_{key}", category="attacking", minutes=10, rel=True,
            # The stacking server stands behind his own baseline, which is
            # where the rules put him.
            off_surface=(key == "stacking"),
            free=(key == "both_up"),
            name=suffixed(SHAPE_NAME, label), note=SHAPE_NOTE,
            home=[P(x, y, f"{i + 1}", moves=[end[i] + (0,)])
                  for i, (x, y) in enumerate(start)],
            away=[P(*mirror(K_L), "A", moves=[(0.34, KITCHEN_AWAY - 0.03, 0)]),
                  P(*mirror(K_R), "B")],
            markers=[M(0.5, KITCHEN, "cone", ""), M(0.5, KITCHEN_AWAY, "cone", "")],
            ball=mirror(K_L),
        ))
    return out


WARM_NAME = {
    "en": "Warm-up", "en-GB": "Warm-up", "zh-CN": "热身", "zh-TW": "熱身",
    "ja-JP": "ウォームアップ", "ko-KR": "웜업", "es-ES": "Calentamiento",
    "fr-FR": "Échauffement", "id-ID": "Pemanasan", "ms-MY": "Memanaskan badan",
    "th-TH": "วอร์มอัพ", "vi-VN": "Khởi động",
}
WARM_NOTE = {
    "en": "Start at the kitchen, not the baseline. The game is won there, so "
          "that is where the hands should wake up.",
    "en-GB": "Start at the kitchen, not the baseline. The game is won there, "
             "so that is where the hands should wake up.",
    "zh-CN": "从厨房线开始，不要从底线开始。比赛是在那里赢下来的，手感也应该在那里醒过来。",
    "zh-TW": "從廚房線開始，不要從底線開始。比賽是在那裡贏下來的，手感也應該在那裡醒過來。",
    "ja-JP": "ベースラインではなくキッチンから始める。試合はそこで決まるのだから、手もそこで目を覚ますべきだ。",
    "ko-KR": "베이스라인이 아니라 키친에서 시작하라. 경기는 거기서 결정된다.",
    "es-ES": "Empieza en la cocina, no en el fondo: el partido se gana ahí, "
             "así que ahí deben despertar las manos.",
    "fr-FR": "Commence à la cuisine, pas au fond : le match s'y gagne, c'est "
             "donc là que les mains doivent se réveiller.",
    "id-ID": "Mulai di kitchen, bukan di garis belakang.",
    "ms-MY": "Mula di kitchen, bukan di garisan belakang.",
    "th-TH": "เริ่มที่หน้าเน็ต ไม่ใช่เส้นหลัง เกมชนะกันตรงนั้น",
    "vi-VN": "Bắt đầu ở vùng bếp, không phải vạch cuối.",
}


def warmup_family() -> list[Drill]:
    specs = [("dink_warm", "dinking", (0.70, KH), (0.70, KA)),
             ("hands", "hand speed", (0.50, KH), (0.50, KA)),
             ("transition", "transition footwork", (0.50, BASELINE), (0.50, 0.20))]
    out = []
    for key, label, h, a in specs:
        # Side steps along the line, not steps over it into the kitchen.
        moves = ([(h[0] - 0.06, h[1], 0), h + (1,)] if key != "transition"
                 else [(h[0], TRANSITION, 0), (h[0], KH, 1), h + (2,)])
        a_moves = ([(a[0] + 0.06, a[1], 0)] if key != "transition"
                   else [(a[0], a[1] + 0.02, 0)])
        out.append(Drill(
            id=f"pb_warm_{key}", category="warmup", minutes=6, rel=True,
            free=(key == "dink_warm"),
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            home=[P(*h, "1", moves=moves)],
            away=[P(*a, "2", moves=a_moves)],
            markers=[M(0.5, KITCHEN, "cone", ""), M(0.5, KITCHEN_AWAY, "cone", "")],
            ball=0,
        ))
    return out


GAME_NAME = {
    "en": "Game", "en-GB": "Game", "zh-CN": "对抗", "zh-TW": "對抗",
    "ja-JP": "ゲーム", "ko-KR": "게임", "es-ES": "Juego", "fr-FR": "Jeu",
    "id-ID": "Permainan", "ms-MY": "Permainan", "th-TH": "เกม", "vi-VN": "Trận đấu",
}
GAME_NOTE = {
    "en": "Ban the shot they overuse and the rest of the game has to improve. "
          "That is the whole point of a conditioned game.",
    "en-GB": "Ban the shot they overuse and the rest of the game has to "
             "improve. That is the whole point of a conditioned game.",
    "zh-CN": "禁掉他们用得最滥的那一拍，其他部分自然就得变好。这就是限制性对抗的全部意义。",
    "zh-TW": "禁掉他們用得最濫的那一拍，其他部分自然就得變好。這就是限制性對抗的全部意義。",
    "ja-JP": "使いすぎている一打を禁止すれば、残りが良くなるしかない。条件付きゲームの意味はそれだけだ。",
    "ko-KR": "남용하는 샷을 금지하면 나머지가 좋아질 수밖에 없다.",
    "es-ES": "Prohíbe el golpe del que abusan y el resto del juego tiene que "
             "mejorar: para eso existe un juego condicionado.",
    "fr-FR": "Interdis le coup dont ils abusent et le reste doit progresser : "
             "c'est tout l'intérêt d'un jeu à thème.",
    "id-ID": "Larang pukulan yang berlebihan dipakai, sisanya pasti membaik.",
    "ms-MY": "Haramkan pukulan yang terlebih guna, selebihnya pasti bertambah baik.",
    "th-TH": "ห้ามลูกที่เขาใช้บ่อยเกินไป ส่วนที่เหลือจะดีขึ้นเอง",
    "vi-VN": "Cấm cú họ lạm dụng, phần còn lại buộc phải tốt lên.",
}


def game_family() -> list[Drill]:
    # Every game starts the way the rules start a point: the serve from
    # behind the baseline, diagonal, the returner back and his partner at
    # the kitchen line, the serving partner back. Dinks-only starts at the
    # line with the feet behind it — it used to step everyone 0.5 m INTO
    # the kitchen on the first beat.
    serve_start = dict(
        home=[P(*SRV, "1", moves=[(0.66, 1.0, 1), (0.64, TRANSITION, 2)]),
              P(*SRV_PARTNER, "2", moves=[(0.36, TRANSITION, 2)])],
        away=[P(*RET, "A", moves=[(0.32, KA, 1)]), P(*RET_PARTNER, "B")],
        ball_to=[("a0", 0), (0, 1), ("a1", 2)])
    specs = [
        ("dink_only", "dinks only", dict(
            home=[P(0.64, KH, "1", moves=[(0.58, KH, 1)]), P(0.30, KH, "2", moves=[(0.36, KH, 1)])],
            away=[P(0.36, KA, "A", moves=[(0.42, KA, 0)]), P(0.70, KA, "B", moves=[(0.64, KA, 0)])],
            ball_to=[("a0", 0), (0, 1)])),
        # Skinny singles is a rally in one half, down the line.
        ("skinny_singles", "skinny singles", dict(
            home=[P(0.72, 1.02, "1")], away=[P(0.72, -0.02, "A")],
            ball_to=[("a0", 0), (0, 1)])),
        ("third_shot", "third shot game", serve_start),
        ("full_doubles", "full doubles", dict(
            home=[P(*SRV, "1", moves=[(0.66, 1.0, 1)]), P(*SRV_PARTNER, "2", moves=[(0.34, 1.0, 1)])],
            away=[P(*RET, "A", moves=[(0.32, KA, 1)]), P(*RET_PARTNER, "B")],
            ball_to=[("a0", 0), (0, 1)])),
    ]
    out = []
    for key, label, spec in specs:
        out.append(Drill(
            id=f"pb_game_{key}", category="ssg", minutes=15, rel=True,
            free=(key in ("dink_only", "full_doubles")),
            off_surface=(key != "dink_only"),
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=spec["home"], away=spec["away"],
            markers=[M(0.5, KITCHEN, "cone", ""), M(0.5, KITCHEN_AWAY, "cone", "")],
            ball=0, ball_to=spec["ball_to"],
        ))
    return out


TWO_BOUNCE_NOTE = {
    "en": "The serve bounces, the return bounces, and only then may anyone volley. Every third shot in this sport exists because of that rule — so drill the sequence, not the shots.",
    "en-GB": "The serve bounces, the return bounces, and only then may anyone volley. Every third shot in this sport exists because of that rule — so drill the sequence, not the shots.",
    "zh-CN": "发球要落地，接发球也要落地，之后才允许截击。这项运动的第三拍之所以存在，全是因为这条规则——所以要练这个顺序，不是练单个球。",
    "zh-TW": "發球要落地，接發球也要落地，之後才允許截擊。這項運動的第三拍之所以存在，全是因為這條規則——所以要練這個順序，不是練單個球。",
    "ja-JP": "サーブはワンバウンド、リターンもワンバウンド、そこで初めてボレーが許される。この競技のサードショットはすべてこのルールから生まれる。だから一球ずつではなく順番を練習する。",
    "ko-KR": "서브도 한 번 튀고 리턴도 한 번 튄 뒤에야 발리가 허용된다. 이 종목의 서드샷은 전부 그 규칙에서 나온다.",
    "es-ES": "El saque bota, el resto bota, y solo entonces se puede volear. El tercer golpe de este deporte existe por esa regla: entrena la secuencia, no los golpes.",
    "fr-FR": "Le service rebondit, le retour rebondit, et seulement ensuite la volée est permise. Le troisième coup de ce sport existe à cause de cette règle.",
    "id-ID": "Servis memantul, pengembalian memantul, baru setelah itu boleh voli.",
    "ms-MY": "Servis melantun, kembalian melantun, barulah voli dibenarkan.",
    "th-TH": "ลูกเสิร์ฟต้องเด้ง ลูกรับต้องเด้ง จากนั้นจึงวอลเลย์ได้",
    "vi-VN": "Quả giao phải nảy, quả đỡ phải nảy, sau đó mới được vô-lê.",
}
LOB_NOTE = {
    "en": "Lob over the shoulder they cannot reach across, and go with it. An offensive lob that leaves you at the kitchen is a point you gave back on the reply.",
    "en-GB": "Lob over the shoulder they cannot reach across, and go with it. An offensive lob that leaves you at the kitchen is a point you gave back on the reply.",
    "zh-CN": "挑向对方够不着的那侧肩膀，然后自己跟着上。挑完还站在网前不动的进攻性高球，回球时就把这一分还回去了。",
    "zh-TW": "挑向對方夠不著的那側肩膀，然後自己跟著上。挑完還站在網前不動的進攻性高球，回球時就把這一分還回去了。",
    "ja-JP": "相手が横に手を伸ばせない側の肩越しへ上げ、自分もついていく。上げたままキッチンに残る攻撃的ロブは、返球で失う1点だ。",
    "ko-KR": "상대가 가로질러 닿을 수 없는 어깨 너머로 띄우고 함께 따라가라.",
    "es-ES": "Globo por encima del hombro al que no llegan cruzados, y acompáñalo. Un globo ofensivo que te deja en la cocina es un punto devuelto.",
    "fr-FR": "Lobe par-dessus l'épaule qu'il ne peut pas atteindre en travers, et suis-le. Un lob offensif qui te laisse à la cuisine est un point rendu.",
    "id-ID": "Lob melewati bahu yang tak bisa dijangkau menyilang, lalu ikuti.",
    "ms-MY": "Lob melepasi bahu yang tidak dapat dicapai secara silang, kemudian ikut.",
    "th-TH": "โยนข้ามไหล่ข้างที่เขาเอื้อมไขว้ไม่ถึง แล้วตามขึ้นไป",
    "vi-VN": "Bỏ bóng bổng qua vai mà họ không với chéo tới được, rồi theo lên.",
}


def gaps_family() -> list[Drill]:
    """The two-bounce rule and the offensive lob.

    The rule that dictates the whole serve-return-third-shot sequence the
    library is built around had no drill, and only the defensive lob
    existed. Both verified absent from every name and note.
    """
    serve_land, return_land = (0.34, 0.10), (0.66, 0.90)
    r_meet = through(SRV, serve_land, -0.02)
    return [
        Drill(
            id="pb_two_bounce_rule", category="possession", minutes=10, rel=True,
            level="foundation", free=True, off_surface=True,
            name=suffixed(SHAPE_NAME, "the two-bounce sequence"),
            note=TWO_BOUNCE_NOTE,
            # P is the SERVER's partner and stays back beside him; the
            # returner's partner B is the one at the kitchen. S is at the
            # return's landing point when it arrives, plays the third, and
            # only then does the serving team walk in.
            home=[P(*SRV, "S", moves=[(0.66, 0.94, 1), (0.64, TRANSITION, 2)]),
                  P(*SRV_PARTNER, "P", moves=[(0.36, TRANSITION, 2)])],
            away=[P(*RET, "R", moves=[r_meet + (0,), (0.32, KA, 1)]),
                  P(*RET_PARTNER, "B")],
            markers=[M(*serve_land, "zone", ""), M(*return_land, "zone", ""),
                     M(0.5, KITCHEN, "cone", ""), M(0.5, KITCHEN_AWAY, "cone", "")],
            ball=0,
            ball_to=[("a0", 0), (0, 1), (Spot(0.42, 0.42), 2)],
        ),
        Drill(
            id="pb_attack_lob", category="attacking", minutes=8, rel=True,
            name=suffixed(SHAPE_NAME, "the offensive lob"), note=LOB_NOTE,
            # A dinks, 1 lobs it over A's backhand shoulder (screen-right
            # of a far-side right-hander) into the deep
            # zone, A turns and chases, and 1 and 2 step back off the line
            # to cover the reply — nobody walks into the kitchen.
            home=[P(0.70, KH, "1", moves=[(0.66, KH, 0), (0.64, 0.74, 2)]),
                  P(0.30, KH, "2", moves=[(0.34, 0.74, 2)])],
            away=[P(0.66, KA, "A", moves=[(0.74, 0.22, 1)]),
                  P(0.30, KA, "B")],
            markers=[M(0.80, 0.10, "zone", ""), M(0.5, KITCHEN, "cone", "")],
            ball=(0.66, KA),
            ball_to=[(0, 0), (Spot(0.80, 0.10), 1)],
        ),
    ]


def pickleball_library() -> list[Drill]:
    return (warmup_family() + dink_family() + serve_family()
            + third_shot_family() + speedup_family() + putaway_family()
            + defend_family() + shape_family() + game_family() + gaps_family())
