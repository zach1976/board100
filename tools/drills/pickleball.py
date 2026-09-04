"""The pickleball library.

Pickleball is a game about getting to the kitchen line and staying there, so
the geometry that matters is three bands: the non-volley zone at the net, the
transition zone behind it, and the baseline. Home is the bottom half; the net
is y=0.5 and the home kitchen line is y=0.66.
"""
from .engine import Drill, M, P, suffixed

KITCHEN = 0.66          # home non-volley zone line
KITCHEN_AWAY = 0.34
BASELINE = 0.97
TRANSITION = 0.80
K_L, K_R = (0.30, KITCHEN), (0.70, KITCHEN)
B_L, B_R = (0.28, BASELINE), (0.72, BASELINE)


def mirror(pt):
    return (pt[0], 1.0 - pt[1])


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
    specs = [("straight", "straight", K_R, mirror(K_R)),
             ("cross", "cross-court", K_R, mirror(K_L)),
             ("to_backhand", "to the backhand", K_L, mirror(K_L)),
             ("pull", "pulling them wide", K_R, (0.92, 0.36))]
    out = []
    for key, label, frm, to in specs:
        out.append(Drill(
            id=f"pb_dink_{key}", category="possession", minutes=10, rel=True,
            free=(key in ("straight", "cross")),
            name=suffixed(DINK_NAME, label), note=DINK_NOTE,
            home=[P(*frm, "1", moves=[(frm[0], KITCHEN + 0.02, 0), frm + (1,)])],
            away=[P(*mirror(K_R), "2", moves=[(to[0], max(to[1], 0.30), 1)])],
            markers=[M(0.5, KITCHEN, "cone", ""), M(0.5, KITCHEN_AWAY, "cone", "")],
            ball=0,
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
    specs = [("drop", "drop", (0.44, 0.40)), ("drive", "drive", (0.30, 0.30)),
             ("fifth", "the fifth from the transition zone", (0.56, 0.42))]
    out = []
    for key, label, land in specs:
        start = (0.50, BASELINE) if key != "fifth" else (0.50, TRANSITION)
        out.append(Drill(
            id=f"pb_third_{key}", category="attacking", minutes=12, rel=True,
            free=(key == "drop"),
            name=suffixed(THIRD_NAME, label), note=THIRD_NOTE,
            home=[P(*start, "1",
                    moves=[(start[0], TRANSITION, 1), (start[0], KITCHEN, 2)]),
                  P(0.78, BASELINE, "2",
                    moves=[(0.76, TRANSITION, 1), (0.74, KITCHEN, 2)])],
            away=[P(*mirror(K_L), "A", moves=[(land[0], land[1] - 0.04, 1)]),
                  P(*mirror(K_R), "B")],
            markers=[M(*land, "zone", ""), M(0.5, KITCHEN, "cone", "")],
            ball=0,
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


def speedup_family() -> list[Drill]:
    specs = [("shoulder", "at the shoulder", (0.34, 0.40)),
             ("hip", "at the hip", (0.42, 0.42)),
             ("ernie", "the Ernie", (0.06, 0.44))]
    out = []
    for key, label, land in specs:
        run = [(0.66, KITCHEN - 0.02, 1)] if key != "ernie" else [
            (0.10, KITCHEN, 1), (0.04, 0.52, 2)]
        out.append(Drill(
            id=f"pb_speedup_{key}", category="attacking", minutes=10, rel=True,
            free=(key == "shoulder"),
            name=suffixed(SPEEDUP_NAME, label), note=SPEEDUP_NOTE,
            home=[P(*K_R, "1", moves=run), P(*K_L, "2")],
            away=[P(*mirror(K_R), "A", moves=[(land[0], land[1] - 0.04, 2)]),
                  P(*mirror(K_L), "B")],
            markers=[M(*land, "zone", ""), M(0.5, KITCHEN, "cone", "")],
            ball=0,
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
    specs = [("overhead", "the overhead", (0.50, 0.20)),
             ("roll_volley", "the roll volley", (0.24, 0.40)),
             ("atp", "around the post", (0.02, 0.48))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"pb_putaway_{key}", category="finishing", minutes=8, rel=True,
            free=(key == "overhead"),
            name=suffixed(PUTAWAY_NAME, label), note=PUTAWAY_NOTE,
            home=[P(*K_R, "1", moves=[(0.60, KITCHEN + 0.06, 1)]), P(*K_L, "2")],
            away=[P(*mirror(K_L), "A", moves=[(land[0], land[1] - 0.05, 2)]),
                  P(*mirror(K_R), "B")],
            markers=[M(*land, "zone", "")],
            ball=0,
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
    specs = [("block", "the block", (0.62, KITCHEN + 0.01)),
             ("reset", "the reset from transition", (0.50, 0.44)),
             ("lob", "the lob over your head", (0.50, 0.92)),
             ("counter", "the counter in a firefight", (0.40, 0.40))]
    out = []
    for key, label, to in specs:
        start = (0.62, TRANSITION) if key == "reset" else K_R
        out.append(Drill(
            id=f"pb_defend_{key}", category="defending", minutes=10, rel=True,
            free=(key in ("block", "reset")),
            name=suffixed(DEFEND_NAME, label), note=DEFEND_NOTE,
            home=[P(*start, "1", moves=[(to[0], min(to[1], BASELINE), 1)]),
                  P(*K_L, "2")],
            away=[P(*mirror(K_R), "A", moves=[(0.68, KITCHEN_AWAY - 0.03, 0)]),
                  P(*mirror(K_L), "B")],
            markers=[M(0.5, KITCHEN, "cone", "")],
            ball=mirror(K_R),
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
          "the return to buy the time you need to walk in behind it.",
    "en-GB": "Both go deep, for different reasons: the serve to keep them "
             "back, the return to buy the time you need to walk in behind it.",
    "zh-CN": "两拍都要打深，理由不同：发球是把人压在后面，接发球是给自己换来跟着上网的时间。",
    "zh-TW": "兩拍都要打深，理由不同：發球是把人壓在後面，接發球是給自己換來跟著上網的時間。",
    "ja-JP": "どちらも深く、理由は別。サーブは相手を下げるため、リターンは前に詰める時間を買うため。",
    "ko-KR": "둘 다 깊게, 이유는 다르다. 서브는 상대를 뒤에 묶고, 리턴은 앞으로 갈 시간을 산다.",
    "es-ES": "Ambos profundos, por motivos distintos: el saque para fijarlos "
             "atrás, el resto para comprar el tiempo de subir tras él.",
    "fr-FR": "Les deux profonds, pour des raisons différentes : le service "
             "pour les tenir au fond, le retour pour gagner le temps de monter.",
    "id-ID": "Keduanya dalam, dengan alasan berbeda.",
    "ms-MY": "Kedua-duanya dalam, atas sebab berbeza.",
    "th-TH": "ทั้งคู่ต้องลึก แต่ด้วยเหตุผลต่างกัน",
    "vi-VN": "Cả hai đều sâu, vì lý do khác nhau.",
}


def serve_family() -> list[Drill]:
    specs = [("deep_backhand", "deep to the backhand", (0.26, 0.06)),
             ("deep_forehand", "deep to the forehand", (0.74, 0.06)),
             ("return_and_in", "return and come in", (0.50, 0.08))]
    out = []
    for key, label, land in specs:
        home = [P(0.72, 1.03, "S", moves=[(0.72, BASELINE, 1)])]
        if key == "return_and_in":
            home = [P(0.72, BASELINE, "R",
                      moves=[(0.72, TRANSITION, 1), (0.72, KITCHEN, 2)])]
        out.append(Drill(
            id=f"pb_serve_{key}", category="setpiece", minutes=8, rel=True,
            free=(key == "deep_backhand"), off_surface=(key != "return_and_in"),
            name=suffixed(SERVE_NAME, label), note=SERVE_NOTE,
            home=home,
            away=[P(0.28, 0.10, "R", moves=[(land[0], land[1] + 0.06, 1)])],
            markers=[M(*land, "zone", "")],
            ball=0,
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
        ("stacking", "stacking", [(0.42, BASELINE), (0.52, KITCHEN)],
         [(0.72, TRANSITION), (0.30, KITCHEN)]),
        ("switch_on_lob", "switching on the lob", [K_L, K_R],
         [(0.66, TRANSITION), (0.30, KITCHEN)]),
    ]
    out = []
    for key, label, start, end in specs:
        out.append(Drill(
            id=f"pb_shape_{key}", category="defending", minutes=10, rel=True,
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
    specs = [("dink_warm", "dinking", K_R, mirror(K_R)),
             ("hands", "hand speed", (0.50, KITCHEN), (0.50, KITCHEN_AWAY)),
             ("transition", "transition footwork", (0.50, BASELINE), (0.50, 0.20))]
    out = []
    for key, label, h, a in specs:
        moves = ([(h[0], h[1] - 0.02, 0), h + (1,)] if key != "transition"
                 else [(h[0], TRANSITION, 0), (h[0], KITCHEN, 1), h + (2,)])
        out.append(Drill(
            id=f"pb_warm_{key}", category="warmup", minutes=6, rel=True,
            free=(key == "dink_warm"),
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            home=[P(*h, "1", moves=moves)],
            away=[P(*a, "2", moves=[(a[0], a[1] + 0.02, 0)])],
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
    specs = [
        ("dink_only", "dinks only", [K_L, K_R]),
        ("skinny_singles", "skinny singles", [(0.72, BASELINE)]),
        ("third_shot", "third shot game", [(0.30, BASELINE), (0.70, BASELINE)]),
        ("full_doubles", "full doubles", [K_L, K_R]),
    ]
    out = []
    for key, label, home in specs:
        out.append(Drill(
            id=f"pb_game_{key}", category="ssg", minutes=15, rel=True,
            free=(key in ("dink_only", "full_doubles")),
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=[P(x, y, f"{i + 1}", moves=[(x, y - 0.04, 0)])
                  for i, (x, y) in enumerate(home)],
            away=[P(*mirror((x, y)), chr(65 + i), moves=[(x, 1 - y + 0.04, 0)])
                  for i, (x, y) in enumerate(home)],
            markers=[M(0.5, KITCHEN, "cone", ""), M(0.5, KITCHEN_AWAY, "cone", "")],
            ball=0,
        ))
    return out


def pickleball_library() -> list[Drill]:
    return (warmup_family() + dink_family() + serve_family()
            + third_shot_family() + speedup_family() + putaway_family()
            + defend_family() + shape_family() + game_family())
