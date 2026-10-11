"""The footvolley library.

Beach volleyball played with everything except the hands: three touches, two
players, and a high net. The court is portrait with the net at y=0.5 and home
at the bottom — the same shape as volleyball, but every drill is limited by
what a foot, thigh, chest or head can actually do with the ball.
"""
from .engine import Drill, M, P, Spot, suffixed

LEFT, RIGHT = (0.30, 0.74), (0.70, 0.74)
SET_POINT = (0.44, 0.60)
NET = 0.5
# Behind the baseline, as far back as the phone shows: the serve is struck
# from there, never from inside the court.
HOME_SERVE_Y, AWAY_SERVE_Y = 1.025, -0.025


def mirror(pt):
    return (pt[0], 1.0 - pt[1])


WARM_NAME = {
    "en": "Warm-up", "en-GB": "Warm-up", "zh-CN": "热身", "zh-TW": "熱身",
    "ja-JP": "ウォームアップ", "ko-KR": "웜업", "es-ES": "Calentamiento",
    "fr-FR": "Échauffement", "id-ID": "Pemanasan", "ms-MY": "Memanaskan badan",
    "th-TH": "วอร์มอัพ", "vi-VN": "Khởi động",
}
WARM_NOTE = {
    "en": "Kill the ball dead on the first touch. In sand you cannot chase a "
          "bad control, so the control is the whole skill.",
    "en-GB": "Kill the ball dead on the first touch. In sand you cannot chase "
             "a bad control, so the control is the whole skill.",
    "zh-CN": "第一脚要把球彻底停死。沙地上追不了停坏的球，所以停球本身就是全部技术。",
    "zh-TW": "第一腳要把球徹底停死。沙地上追不了停壞的球，所以停球本身就是全部技術。",
    "ja-JP": "ファーストタッチで完全に殺す。砂の上ではトラップミスを追えない。だからトラップこそが技術のすべてだ。",
    "ko-KR": "첫 터치에서 공을 완전히 죽여라. 모래에서는 나쁜 트래핑을 쫓아갈 수 없다.",
    "es-ES": "Mata la bola en el primer control: en arena no puedes perseguir "
             "un mal control, así que el control es toda la técnica.",
    "fr-FR": "Amortis complètement dès la première touche : dans le sable, on "
             "ne rattrape pas un mauvais contrôle.",
    "id-ID": "Matikan bola di sentuhan pertama. Di pasir kamu tak bisa "
             "mengejar kontrol yang buruk.",
    "ms-MY": "Matikan bola pada sentuhan pertama. Di pasir anda tidak boleh "
             "mengejar kawalan yang buruk.",
    "th-TH": "หยุดบอลให้นิ่งตั้งแต่สัมผัสแรก บนทรายคุณไล่ตามการคุมบอลที่พลาดไม่ได้",
    "vi-VN": "Giữ chết bóng ngay chạm đầu. Trên cát bạn không đuổi kịp cú đỡ hỏng.",
}


def warmup_family() -> list[Drill]:
    specs = [("juggling in pairs", "juggling in pairs"),
             ("on every surface", "on every surface")]
    out = []
    for key, label in specs:
        out.append(Drill(
            id=f"fv_warm_{key.replace(' ', '_')}", category="warmup", minutes=8,
            rel=True, free=True,
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            # Four legal surfaces, four stations — it used to be the same
            # two dots as the pairs juggling.
            home=([P(0.24, 0.80, "1", moves=[(0.32, 0.72, 0)]),
                   P(0.50, 0.70, "2", moves=[(0.50, 0.64, 1)]),
                   P(0.76, 0.80, "3", moves=[(0.68, 0.72, 2)])]
                  if key == "on every surface" else
                  [P(0.34, 0.76, "1", moves=[(0.38, 0.70, 0)]),
                   P(0.66, 0.76, "2", moves=[(0.62, 0.70, 0)])]),
            ball=0,
            # kept alive between them — pairs, or round the triangle
            ball_to=([(1, 0), (2, 1), (0, 2)] if key == "on every surface" else [(1, 0), (0, 1)]),
        ))
    return out


CONTROL_NAME = {
    "en": "Ball control", "en-GB": "Ball control", "zh-CN": "控球",
    "zh-TW": "控球", "ja-JP": "ボールコントロール", "ko-KR": "볼 컨트롤",
    "es-ES": "Control", "fr-FR": "Contrôle", "id-ID": "Kontrol bola",
    "ms-MY": "Kawalan bola", "th-TH": "การคุมบอล", "vi-VN": "Khống chế bóng",
}
CONTROL_NOTE = {
    "en": "Three touches and no hands: the first one has to end up somewhere "
          "your partner can actually set from, not just somewhere on your side.",
    "en-GB": "Three touches and no hands: the first one has to end up "
             "somewhere your partner can actually set from, not just somewhere on your side.",
    "zh-CN": "三次触球、不能用手：第一下必须停到同伴真能传球的位置，而不只是停在自己这半场某个地方。",
    "zh-TW": "三次觸球、不能用手：第一下必須停到同伴真能傳球的位置，而不只是停在自己這半場某個地方。",
    "ja-JP": "3タッチ、手は使えない。1本目は「自陣のどこか」ではなく、相方が実際に上げられる場所へ落とす。",
    "ko-KR": "세 번의 터치, 손은 금지. 첫 터치는 파트너가 실제로 올릴 수 있는 자리로 가야 한다.",
    "es-ES": "Tres toques y sin manos: el primero debe caer donde tu pareja "
             "pueda colocar de verdad, no en cualquier sitio de tu campo.",
    "fr-FR": "Trois touches, sans les mains : la première doit finir là où ton "
             "partenaire peut vraiment relever.",
    "id-ID": "Tiga sentuhan tanpa tangan: yang pertama harus jatuh di tempat "
             "rekanmu benar-benar bisa mengumpan.",
    "ms-MY": "Tiga sentuhan tanpa tangan: yang pertama mesti jatuh di tempat "
             "rakan anda benar-benar boleh mengumpan.",
    "th-TH": "สามสัมผัสและห้ามใช้มือ สัมผัสแรกต้องลงในจุดที่คู่หูชงต่อได้จริง",
    "vi-VN": "Ba chạm, không dùng tay: chạm đầu phải rơi vào nơi đồng đội thực sự chuyền được.",
}


def control_family() -> list[Drill]:
    # F feeds, 1 controls (chest, shoulder, the high ball) and the control
    # is the touch that puts it on the square for 2 — the second touch is
    # the point of the drill, so it is drawn.
    specs = [("chest control", "chest control", (0.44, 0.66)),
             ("the shoulder pass", "the shoulder pass", (0.52, 0.62)),
             ("the high feed", "the high feed", SET_POINT)]
    out = []
    for key, label, target in specs:
        out.append(Drill(
            id=f"fv_control_{key.replace(' ', '_')}", category="possession",
            minutes=10, rel=True, free=(key != "the shoulder pass"),
            name=suffixed(CONTROL_NAME, label), note=CONTROL_NOTE,
            home=[P(*RIGHT, "1", moves=[(target[0] + 0.14, target[1] + 0.08, 0)]),
                  P(*LEFT, "2", moves=[target + (1,)])],
            away=[P(0.50, 0.28, "F", moves=[(0.50, 0.32, 1)])],
            markers=[M(*target, "square", "")],
            ball=(0.50, 0.28), ball_to=[(0, 0), (1, 1)],
        ))
    return out


SERVE_NAME = {
    "en": "Serve", "en-GB": "Serve", "zh-CN": "发球", "zh-TW": "發球",
    "ja-JP": "サーブ", "ko-KR": "서브", "es-ES": "Saque", "fr-FR": "Service",
    "id-ID": "Servis", "ms-MY": "Servis", "th-TH": "การเสิร์ฟ", "vi-VN": "Giao bóng",
}
SERVE_NOTE = {
    "en": "A serve they have to take on the chest is worth two they take on "
          "the foot. Height is the weapon here, not power.",
    "en-GB": "A serve they have to take on the chest is worth two they take on "
             "the foot. Height is the weapon here, not power.",
    "zh-CN": "逼对手用胸口接的发球，抵得上两个让他用脚接的。这里的武器是高度，不是力量。",
    "zh-TW": "逼對手用胸口接的發球，抵得上兩個讓他用腳接的。這裡的武器是高度，不是力量。",
    "ja-JP": "胸で受けざるを得ないサーブは、足で受けられるサーブ2本分の価値がある。ここでの武器は高さであって力ではない。",
    "ko-KR": "가슴으로 받게 만드는 서브가 발로 받는 서브 두 개 값이다. 여기선 힘이 아니라 높이가 무기다.",
    "es-ES": "Un saque que deban controlar con el pecho vale por dos que "
             "controlan con el pie: aquí el arma es la altura, no la potencia.",
    "fr-FR": "Un service qu'ils doivent prendre de la poitrine en vaut deux "
             "pris du pied : l'arme ici, c'est la hauteur, pas la puissance.",
    "id-ID": "Servis yang harus mereka ambil dengan dada bernilai dua kali lipat.",
    "ms-MY": "Servis yang perlu mereka ambil dengan dada bernilai dua kali ganda.",
    "th-TH": "ลูกเสิร์ฟที่บังคับให้เขารับด้วยอกมีค่าเท่าสองลูกที่รับด้วยเท้า",
    "vi-VN": "Cú giao buộc họ đỡ bằng ngực đáng giá hai cú họ đỡ bằng chân.",
}


LONG_SERVE_NOTE = {
    "en": "Long and fast means flat and to the baseline: the receiver should still be moving back when it arrives. Hang it up and it is a free ball; drop it short and it is an easy chest control.",
    "en-GB": "Long and fast means flat and to the baseline: the receiver should still be moving back when it arrives. Hang it up and it is a free ball; drop it short and it is an easy chest control.",
    "zh-CN": "又长又快，就是要平、要压底线：球到的时候，接球人应该还在往后退。发高了就是送过去的机会球，发短了就是一个轻松的胸部停球。",
    "zh-TW": "又長又快，就是要平、要壓底線：球到的時候，接球人應該還在往後退。發高了就是送過去的機會球，發短了就是一個輕鬆的胸部停球。",
    "ja-JP": "ロングで速いとは、低く速くベースラインまで。届いた時に相手がまだ下がっている状態にする。高く上げればチャンスボール、短ければ楽な胸トラップになる。",
    "ko-KR": "길고 빠르다는 건 낮고 평평하게 베이스라인까지라는 뜻이다. 공이 도착할 때 리시버가 아직 뒤로 물러나고 있어야 한다. 띄우면 찬스볼, 짧으면 편한 가슴 트래핑이다.",
    "es-ES": "Largo y rápido es plano y hasta la línea de fondo: el receptor tiene que seguir retrocediendo cuando llega. Si lo cuelgas es un balón regalado; si se queda corto, un control de pecho fácil.",
    "fr-FR": "Long et rapide, c'est tendu et jusqu'à la ligne de fond : le receveur doit encore reculer quand il arrive. Trop haut, c'est une balle facile ; trop court, un contrôle de poitrine tranquille.",
    "id-ID": "Panjang dan cepat berarti datar sampai garis belakang: penerima harus masih mundur saat bola tiba. Terlalu tinggi jadi bola gratis; terlalu pendek jadi kontrol dada yang mudah.",
    "ms-MY": "Panjang dan laju bermaksud rata hingga ke garisan belakang: penerima mesti masih berundur ketika bola tiba. Terlalu tinggi jadi bola percuma; terlalu pendek jadi kawalan dada yang mudah.",
    "th-TH": "ยาวและเร็วคือเสิร์ฟเรียดไปถึงเส้นหลัง ตอนลูกมาถึงคนรับต้องยังถอยหลังอยู่ ถ้าโยนสูงจะกลายเป็นลูกง่าย ถ้าสั้นก็กลายเป็นลูกที่รับด้วยอกได้สบาย",
    "vi-VN": "Dài và nhanh là bóng căng, sát đường biên ngang: khi bóng tới, người đỡ vẫn phải đang lùi. Bổng lên là bóng cho không; ngắn quá là một cú đỡ ngực dễ dàng.",
}


def serve_family() -> list[Drill]:
    # The serve is struck from behind the baseline and lands IN the zone;
    # the receiver nearer the zone moves onto it as it comes.
    specs = [("long and fast", "long and fast", (0.50, 0.06)),
             ("in the corner", {"en": "in the corner", "en-GB": "in the corner",
                                "zh-CN": "打底角", "zh-TW": "打底角",
                                "ja-JP": "コーナーへ", "ko-KR": "코너로",
                                "es-ES": "a la esquina", "fr-FR": "dans le coin",
                                "id-ID": "ke sudut", "ms-MY": "ke penjuru",
                                "th-TH": "ลงมุม", "vi-VN": "vào góc"},
              (0.14, 0.10)),
             ("at the seam", "at the seam", (0.50, 0.28))]
    out = []
    for key, label, land in specs:
        near_left = land[0] <= 0.50
        mover = (0.30, 0.26) if near_left else (0.70, 0.26)
        other = (0.70, 0.26) if near_left else (0.30, 0.26)
        out.append(Drill(
            id=f"fv_serve_{key.replace(' ', '_')}", category="setpiece",
            minutes=8, rel=True, free=(key == "long and fast"), off_surface=True,
            name=suffixed(SERVE_NAME, label),
            note=LONG_SERVE_NOTE if key == "long and fast" else SERVE_NOTE,
            home=[P(0.50, HOME_SERVE_Y, "S", moves=[(0.50, 0.80, 1)])],
            away=[P(*mover, "A", moves=[land + (0,)]),
                  P(*other, "B", moves=[(0.54 if near_left else 0.46, 0.36, 1)])],
            markers=[M(*land, "zone", "")],
            ball=0, ball_to=[("a0", 0), ("a1", 1)],
        ))
    return out


ATTACK_NAME = {
    "en": "Setting up", "en-GB": "Setting up", "zh-CN": "进攻", "zh-TW": "進攻",
    "ja-JP": "攻撃", "ko-KR": "공격", "es-ES": "Ataque", "fr-FR": "Attaque",
    "id-ID": "Serangan", "ms-MY": "Serangan", "th-TH": "การบุก", "vi-VN": "Tấn công",
}
ATTACK_NOTE = {
    "en": "The set decides the attack. A ball that drifts over the net gives "
          "away the only thing you had — the choice of where to put it.",
    "en-GB": "The set decides the attack. A ball that drifts over the net "
             "gives away the only thing you had — the choice of where to put it.",
    "zh-CN": "传球决定了进攻。传球飘过网，就把你唯一拥有的东西送掉了——选择落点的权利。",
    "zh-TW": "傳球決定了進攻。傳球飄過網，就把你唯一擁有的東西送掉了——選擇落點的權利。",
    "ja-JP": "アタックを決めるのはトスだ。ネットを越えて流れたトスは、唯一持っていたもの——どこへ落とすかの選択権を手放す。",
    "ko-KR": "토스가 공격을 결정한다. 네트를 넘어가 버린 토스는 어디에 놓을지 고를 권리를 넘겨준다.",
    "es-ES": "La colocación decide el ataque: una bola que se va sobre la red "
             "regala lo único que tenías, elegir dónde ponerla.",
    "fr-FR": "C'est la passe qui décide de l'attaque : une balle qui dérive "
             "au-dessus du filet donne le seul atout que tu avais.",
    "id-ID": "Umpan menentukan serangan.",
    "ms-MY": "Umpanan menentukan serangan.",
    "th-TH": "การเซตเป็นตัวกำหนดการบุก",
    "vi-VN": "Đường chuyền quyết định pha tấn công.",
}


def attack_family() -> list[Drill]:
    # A shark attack is smashed at the tape and a sombrero is lobbed softly
    # over a committed blocker: the same picture with the cone moved could
    # not tell them apart. The attacker's height relative to the net and
    # what the blocker does now differ on each board.
    # (key, label, target, where the attacker strikes from, blocker's move)
    # Attacker and blocker each keep about 0.6 m off the net line: nobody
    # crosses, and the board must not read as contact over the tape.
    specs = [("the shark attack", "the shark attack", (0.28, 0.30),
              (0.52, 0.535), (0.50, 0.465)),
             ("the sombrero", "the sombrero", (0.50, 0.30),
              (0.50, 0.575), (0.50, 0.455)),
             ("cross-court", "cross-court", (0.74, 0.24),
              (0.40, 0.545), (0.44, 0.465))]
    out = []
    for key, label, land, strike, block_to in specs:
        out.append(Drill(
            id=f"fv_attack_{key.replace(' ', '_').replace('-', '_')}",
            category="attacking", minutes=12, rel=True,
            free=(key == "the shark attack"),
            name=suffixed(ATTACK_NAME, label), note=ATTACK_NOTE,
            home=[P(*LEFT, "1", moves=[SET_POINT + (0,)]),
                  P(*RIGHT, "2", moves=[(strike[0] + 0.06, strike[1] + 0.08, 0),
                                        strike + (1,)])],
            away=[P(0.50, 0.46, "B", moves=[block_to + (1,)]),
                  P(land[0], land[1] - 0.06, "D", moves=[(land[0], land[1], 2)])],
            markers=[M(*land, "zone", "")],
            ball=0,
            ball_moves=[SET_POINT + (0,), (strike[0], strike[1] - 0.01, 1),
                        land + (2,)],
        ))
    return out


FINISH_NAME = {
    "en": "Finishing", "en-GB": "Finishing", "zh-CN": "终结", "zh-TW": "終結",
    "ja-JP": "決め球", "ko-KR": "마무리", "es-ES": "Definición",
    "fr-FR": "Finition", "id-ID": "Penyelesaian", "ms-MY": "Penamat",
    "th-TH": "การจบสกอร์", "vi-VN": "Dứt điểm",
}
FINISH_NOTE = {
    "en": "Contact above the tape or place it instead. A footvolley attack hit "
          "from below net height is a free ball with extra steps.",
    "en-GB": "Contact above the tape or place it instead. A footvolley attack "
             "hit from below net height is a free ball with extra steps.",
    "zh-CN": "要么在网带以上击球，要么就改为放点。低于网高打出的进攻，只是绕了个弯的调整球。",
    "zh-TW": "要麼在網帶以上擊球，要麼就改為放點。低於網高打出的進攻，只是繞了個彎的調整球。",
    "ja-JP": "白帯より上で当てるか、置きにいくか。ネットより低い位置から打つ攻撃は、手間をかけたフリーボールでしかない。",
    "ko-KR": "테이프 위에서 맞히거나 아니면 놓아라. 네트보다 낮은 곳에서 친 공격은 번거로운 프리볼일 뿐이다.",
    "es-ES": "Contacta por encima de la cinta o colócala: un ataque golpeado "
             "por debajo de la red es un balón libre con pasos de más.",
    "fr-FR": "Frappe au-dessus de la bande, sinon place la balle : une attaque "
             "portée sous la hauteur du filet n'est qu'une balle libre compliquée.",
    "id-ID": "Kontak di atas bibir net, atau tempatkan saja bolanya.",
    "ms-MY": "Sentuh di atas bibir jaring, atau letakkan sahaja bolanya.",
    "th-TH": "ปะทะบอลเหนือขอบเน็ต ไม่งั้นก็หย่อนวางแทน",
    "vi-VN": "Chạm bóng trên mép lưới, nếu không thì đặt bóng.",
}


def finishing_family() -> list[Drill]:
    # D sends a free ball over, 1 takes it and sets 2 at the net, and 2 —
    # the finisher — plays the finish the drill is named for into the zone.
    specs = [("the bicycle kick", "the bicycle kick", (0.34, 0.22), (0.46, 0.56)),
             ("the header", "the header", (0.62, 0.28), (0.54, 0.545)),
             ("the drop", "the drop", (0.50, 0.44), (0.50, 0.545))]
    out = []
    for key, label, land, hit in specs:
        feed = (0.25 if land[0] >= 0.5 else 0.75,)
        out.append(Drill(
            id=f"fv_finish_{key.replace(' ', '_')}", category="finishing",
            minutes=10, rel=True, free=(key == "the header"),
            name=suffixed(FINISH_NAME, label), note=FINISH_NOTE,
            home=[P(*LEFT, "1", moves=[(0.36, 0.70, 0)]),
                  P(*RIGHT, "2", moves=[hit + (1,)])],
            # The feeder starts across the court from the zone, so the
            # finish is played away from him, not back to where he stood.
            away=[P(feed[0], 0.24, "D", moves=[(feed[0], 0.18, 1)]),
                  P(0.40, 0.46, "B", moves=[(0.44, 0.465, 2)])],
            markers=[M(*land, "zone", "")],
            ball=(feed[0], 0.24),
            ball_to=[(0, 0), (1, 1), (Spot(*land), 2)],
        ))
    return out


DEF_NAME = {
    "en": "Defending", "en-GB": "Defending", "zh-CN": "防守", "zh-TW": "防守",
    "ja-JP": "ディフェンス", "ko-KR": "수비", "es-ES": "Defensa",
    "fr-FR": "Défense", "id-ID": "Bertahan", "ms-MY": "Pertahanan",
    "th-TH": "การรับ", "vi-VN": "Phòng thủ",
}
DEF_NOTE = {
    "en": "One blocks and one covers — never both at the net, never both back. "
          "Two players cannot defend a court twice.",
    "en-GB": "One blocks and one covers — never both at the net, never both "
             "back. Two players cannot defend a court twice.",
    "zh-CN": "一个拦、一个保护——不要两个人都在网前，也不要两个人都在后面。两个人没法把一块场地防两遍。",
    "zh-TW": "一個攔、一個保護——不要兩個人都在網前，也不要兩個人都在後面。兩個人沒法把一塊場地防兩遍。",
    "ja-JP": "一人がブロック、一人がカバー。二人ともネット前も、二人とも後ろもだめだ。二人で一つのコートを二度守ることはできない。",
    "ko-KR": "한 명은 막고 한 명은 커버한다. 둘 다 네트도, 둘 다 뒤도 안 된다.",
    "es-ES": "Uno bloquea y otro cubre: nunca los dos en la red ni los dos "
             "atrás. Dos jugadores no pueden defender una pista dos veces.",
    "fr-FR": "L'un contre, l'autre couvre : jamais les deux au filet, jamais "
             "les deux au fond. À deux, on ne défend pas un terrain deux fois.",
    "id-ID": "Satu memblok dan satu menutup — jangan keduanya di net.",
    "ms-MY": "Seorang menyekat dan seorang menutup — jangan kedua-duanya di jaring.",
    "th-TH": "คนหนึ่งบล็อก อีกคนคุมหลัง อย่าอยู่หน้าเน็ตทั้งคู่",
    "vi-VN": "Một người chắn, một người bọc lót — đừng cả hai lên lưới.",
}


def defence_family() -> list[Drill]:
    specs = [("the block", "the block", (0.44, 0.535), (0.66, 0.80)),
             ("covering the block", "covering the block", (0.40, 0.535), (0.56, 0.86)),
             ("the dig", "the dig", (0.34, 0.70), (0.68, 0.72))]
    out = []
    for key, label, first, second in specs:
        out.append(Drill(
            id=f"fv_defence_{key.replace(' ', '_')}", category="defending",
            minutes=10, rel=True, free=(key == "the block"),
            name=suffixed(DEF_NAME, label), note=DEF_NOTE,
            home=[P(*LEFT, "1", moves=[first + (1,)]),
                  P(*RIGHT, "2", moves=[second + (1,)])],
            away=[P(0.44, 0.36, "A", moves=[(0.44, 0.465, 1)]),
                  P(0.66, 0.30, "F", moves=[(0.56, 0.40, 0)])],
            ball=(0.66, 0.30),
        ))
    return out


GAME_NAME = {
    "en": "Game", "en-GB": "Game", "zh-CN": "对抗", "zh-TW": "對抗",
    "ja-JP": "ゲーム", "ko-KR": "게임", "es-ES": "Juego", "fr-FR": "Jeu",
    "id-ID": "Permainan", "ms-MY": "Permainan", "th-TH": "เกม", "vi-VN": "Trận đấu",
}
GAME_NOTE = {
    "en": "One touch fewer and the game changes completely. Play a set at two "
          "touches and watch how fast the first control improves.",
    "en-GB": "One touch fewer and the game changes completely. Play a set at "
             "two touches and watch how fast the first control improves.",
    "zh-CN": "少一次触球，整个比赛就完全不同。用两次触球打一局，看看第一脚停球进步得有多快。",
    "zh-TW": "少一次觸球，整個比賽就完全不同。用兩次觸球打一局，看看第一腳停球進步得有多快。",
    "ja-JP": "1タッチ減らすだけでゲームは一変する。2タッチ制で1セットやれば、ファーストタッチが一気に良くなる。",
    "ko-KR": "터치 하나만 줄여도 경기가 완전히 달라진다. 두 번 터치로 한 세트 해보라.",
    "es-ES": "Un toque menos y el juego cambia por completo: juega un set a "
             "dos toques y mira cuánto mejora el primer control.",
    "fr-FR": "Une touche de moins et le jeu change du tout au tout : joue un "
             "set à deux touches et regarde le premier contrôle progresser.",
    "id-ID": "Kurangi satu sentuhan dan permainannya berubah total.",
    "ms-MY": "Kurangkan satu sentuhan dan permainannya berubah sepenuhnya.",
    "th-TH": "ลดหนึ่งสัมผัส เกมก็เปลี่ยนไปทั้งหมด",
    "vi-VN": "Bớt một chạm là cả trận đấu đổi khác.",
}


def game_family() -> list[Drill]:
    """Every game opens with the serve from behind the baseline: the server
    strikes it and runs in, the far side receives and sets."""
    out = []
    out.append(Drill(
        id="fv_game_1v1", category="ssg", minutes=15, rel=True, free=False,
        off_surface=True, name=suffixed(GAME_NAME, "1v1"), note=GAME_NOTE,
        home=[P(0.50, HOME_SERVE_Y, "1", moves=[(0.50, 0.76, 0)])],
        away=[P(0.50, 0.26, "A", moves=[(0.44, 0.22, 0)])],
        ball=0, ball_to=[("a0", 0), (0, 1)],
    ))
    # 2v2 and 4v4: serve, receive, set — A receives, B comes in to set.
    for key, label, home_xy, away_xy in [
            ("2v2", "2v2", [(0.30, HOME_SERVE_Y), (0.70, 0.72)],
             [(0.30, 0.26), (0.70, 0.26)]),
            ("4v4", "4v4", [(0.44, HOME_SERVE_Y), (0.20, 0.66), (0.62, 0.66), (0.82, 0.82)],
             [(0.20, 0.34), (0.44, 0.20), (0.60, 0.34), (0.82, 0.18)])]:
        home = [P(*home_xy[0], "1", moves=[(home_xy[0][0], 0.80, 0)])] + [
            P(x, y, str(i + 2)) for i, (x, y) in enumerate(home_xy[1:])]
        away = [P(x, y, chr(65 + i)) for i, (x, y) in enumerate(away_xy)]
        away[1].moves = [(0.52, 0.40, 1)]
        away[0].moves = [(away_xy[0][0] + 0.06, 0.42, 2)]
        out.append(Drill(
            id=f"fv_game_{key}", category="ssg", minutes=15, rel=True,
            free=True, off_surface=True,
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=home, away=away,
            ball=0, ball_to=[("a0", 0), ("a1", 1), ("a0", 2),
                             (Spot(0.56, 0.93), 3)],
        ))
    return out


def footvolley_library() -> list[Drill]:
    return (warmup_family() + control_family() + receive_family()
            + serve_family() + attack_family() + combo_family()
            + finishing_family() + defence_family() + block_timing()
            + game_family() + game3_family())

RECEIVE_NAME = {
    "en": "Receiving", "en-GB": "Receiving", "zh-CN": "一传", "zh-TW": "一傳",
    "ja-JP": "レシーブ", "ko-KR": "리시브", "es-ES": "Recepción",
    "fr-FR": "Réception", "id-ID": "Menerima", "ms-MY": "Menerima",
    "th-TH": "การรับลูกแรก", "vi-VN": "Bước một",
}
RECEIVE_NOTE = {
    "en": "Take the serve on the surface it arrives at — chest for the flat "
          "one, thigh for the dipping one. Changing surface mid-flight is how "
          "the first touch flies to the crowd.",
    "en-GB": "Take the serve on the surface it arrives at — chest for the "
             "flat one, thigh for the dipping one. Changing surface mid-flight "
             "is how the first touch flies to the crowd.",
    "zh-CN": "球到哪个部位就用哪个部位接——平球用胸，下坠球用大腿。球飞到一半换部位，一传就飞进观众席了。",
    "zh-TW": "球到哪個部位就用哪個部位接——平球用胸，下墜球用大腿。球飛到一半換部位，一傳就飛進觀眾席了。",
    "ja-JP": "来た高さの部位で取る。フラットなら胸、落ちてくるなら腿。空中で部位を変えるからレシーブが観客席へ飛ぶ。",
    "ko-KR": "오는 높이의 부위로 받아라 — 평평하면 가슴, 떨어지면 허벅지. 도중에 부위를 바꾸면 첫 터치가 관중석으로 간다.",
    "es-ES": "Recibe con la superficie a la que llega: pecho para el saque "
             "plano, muslo para el que cae. Cambiar en pleno vuelo manda el "
             "primer toque a la grada.",
    "fr-FR": "Prends le service avec la surface où il arrive — poitrine pour "
             "le tendu, cuisse pour le plongeant. Changer en plein vol envoie "
             "la première touche dans le public.",
    "id-ID": "Terima servis dengan bagian tubuh tempat bola datang.",
    "ms-MY": "Terima servis dengan bahagian badan tempat bola tiba.",
    "th-TH": "รับด้วยส่วนที่ลูกมาถึง อกสำหรับลูกเรียบ ต้นขาสำหรับลูกหยอด",
    "vi-VN": "Đỡ giao bằng bộ phận bóng bay tới — ngực cho bóng căng, đùi cho bóng cắm.",
}


def receive_family() -> list[Drill]:
    # The server stays behind his baseline and serves from there; 1 takes it
    # on the named surface and the first touch goes up to 2 on the square.
    specs = [("chest", "chest control", 0.34), ("thigh", "with the thigh", 0.66)]
    out = []
    for key, label, x in specs:
        out.append(Drill(
            id=f"fv_receive_{key}", category="possession", minutes=10, rel=True,
            off_surface=True, free=(key == "chest"),
            name=suffixed(RECEIVE_NAME, label), note=RECEIVE_NOTE,
            home=[P(x, 0.76, "1", moves=[(x, 0.70, 0)]),
                  P(1 - x, 0.70, "2", moves=[SET_POINT + (1,)])],
            away=[P(0.50, AWAY_SERVE_Y, "S", moves=[(0.50, 0.20, 1)])],
            markers=[M(*SET_POINT, "square", "")],
            ball=(0.50, AWAY_SERVE_Y), ball_to=[(0, 0), (1, 1)],
        ))
    return out


COMBO_NAME = {
    "en": "Combination", "en-GB": "Combination", "zh-CN": "二三配合",
    "zh-TW": "二三配合", "ja-JP": "コンビネーション", "ko-KR": "콤비네이션",
    "es-ES": "Combinación", "fr-FR": "Combinaison", "id-ID": "Kombinasi",
    "ms-MY": "Kombinasi", "th-TH": "ลูกผสม", "vi-VN": "Phối hợp",
}
COMBO_NOTE = {
    "en": "The second touch decides who attacks; say the name before the ball "
          "arrives. A silent set is a coin flip at the net.",
    "en-GB": "The second touch decides who attacks; say the name before the "
             "ball arrives. A silent set is a coin flip at the net.",
    "zh-CN": "第二次触球决定谁来进攻——球到之前把名字喊出来。不出声的二传，网前就是抛硬币。",
    "zh-TW": "第二次觸球決定誰來進攻——球到之前把名字喊出來。不出聲的二傳，網前就是拋硬幣。",
    "ja-JP": "2タッチ目が誰の攻撃かを決める。ボールが来る前に名前を呼ぶ。無言のトスはネット際のコイントスだ。",
    "ko-KR": "두 번째 터치가 누가 공격할지 정한다. 공이 오기 전에 이름을 불러라.",
    "es-ES": "El segundo toque decide quién ataca: di el nombre antes de que "
             "llegue. Una colocación muda es una moneda al aire en la red.",
    "fr-FR": "La deuxième touche décide qui attaque : dis le nom avant "
             "l'arrivée. Une passe muette est un pile ou face au filet.",
    "id-ID": "Sentuhan kedua menentukan siapa menyerang — sebut namanya lebih dulu.",
    "ms-MY": "Sentuhan kedua menentukan siapa menyerang — sebut nama dahulu.",
    "th-TH": "สัมผัสที่สองตัดสินว่าใครบุก เรียกชื่อก่อนบอลมาถึง",
    "vi-VN": "Chạm thứ hai quyết định ai tấn công — gọi tên trước khi bóng tới.",
}


def combo_family() -> list[Drill]:
    # Three touches, drawn: D sends it over, 2 receives it to 1, 1 sets it
    # onto the square, and 2 attacks into the zone. "Attacking the second
    # ball" is the variation where 1 plays the pass straight over instead
    # of setting.
    # (key, label, square, attack landing, where 2 hits from)
    specs = [("quick", "off the quick set", (0.48, 0.555), (0.28, 0.24), (0.30, 0.60)),
             ("back", "from the back court", (0.64, 0.68), (0.30, 0.10), (0.38, 0.58)),
             ("second_ball", "attacking the second ball", (0.44, 0.56), (0.24, 0.20), None)]
    out = []
    for key, label, square, land, setter in specs:
        second = key == "second_ball"
        home = [P(*LEFT, "1", moves=[(square if second else setter) + (1,)]),
                P(*RIGHT, "2", moves=[(0.68, 0.70, 0)] + ([] if second else [square + (2,)]))]
        route = ([(1, 0), (0, 1), (Spot(*land), 2)] if second else
                 [(1, 0), (0, 1), (1, 2), (Spot(*land), 3)])
        out.append(Drill(
            id=f"fv_combo_{key}", category="attacking", minutes=10, rel=True,
            free=(key == "quick"),
            name=suffixed(COMBO_NAME, label), note=COMBO_NOTE,
            home=home,
            away=[P(0.44, 0.46, "B", moves=[(0.44, 0.465, 2 if second else 3)]),
                  P(0.66, 0.30, "D", moves=[(0.56, 0.24, 1)])],
            markers=[M(*square, "square", ""), M(*land, "zone", "")],
            ball=(0.66, 0.30), ball_to=route,
        ))
    return out


BLOCKTIME_NAME = {
    "en": "Block timing", "en-GB": "Block timing", "zh-CN": "拦网时机",
    "zh-TW": "攔網時機", "ja-JP": "ブロックのタイミング", "ko-KR": "블로킹 타이밍",
    "es-ES": "Tiempo de bloqueo", "fr-FR": "Timing du contre",
    "id-ID": "Waktu blok", "ms-MY": "Masa sekatan", "th-TH": "จังหวะบล็อก",
    "vi-VN": "Thời điểm chắn",
}
BLOCKTIME_NOTE = {
    "en": "Jump off the attacker's plant leg, not off the ball. The ball can "
          "be faked; the leg that jumps cannot.",
    "en-GB": "Jump off the attacker's plant leg, not off the ball. The ball "
             "can be faked; the leg that jumps cannot.",
    "zh-CN": "看进攻人的支撑腿起跳，别看球。球可以做假，起跳那条腿做不了假。",
    "zh-TW": "看進攻人的支撐腿起跳，別看球。球可以做假，起跳那條腿做不了假。",
    "ja-JP": "ボールではなくアタッカーの踏み込み足に合わせて跳ぶ。ボールは騙せるが、踏み切る脚は騙せない。",
    "ko-KR": "공이 아니라 공격수의 디딤발에 맞춰 뛰어라. 공은 속여도 뛰는 다리는 못 속인다.",
    "es-ES": "Salta con la pierna de apoyo del atacante, no con el balón: el "
             "balón se puede fintar, la pierna que salta no.",
    "fr-FR": "Saute sur la jambe d'appui de l'attaquant, pas sur le ballon : "
             "le ballon peut feinter, la jambe qui saute non.",
    "id-ID": "Lompat mengikuti kaki tumpu penyerang, bukan bolanya.",
    "ms-MY": "Lompat mengikut kaki tumpuan penyerang, bukan bola.",
    "th-TH": "กระโดดตามขาหลักของตัวบุก อย่าตามบอล บอลหลอกได้ ขาหลอกไม่ได้",
    "vi-VN": "Bật theo chân trụ của người tấn công, đừng theo bóng.",
}


def block_timing() -> list[Drill]:
    return [Drill(
        id="fv_block_timing", category="defending", minutes=10, rel=True,
        # It was named 1v1 and drawn 2v2. Blocker against attacker, with
        # the feeder off the board's own side where a feeder stands.
        name=suffixed(BLOCKTIME_NAME, "one against one at the net"),
        note=BLOCKTIME_NOTE,
        home=[P(0.44, 0.56, "B", moves=[(0.44, 0.53, 1)])],
        away=[P(0.44, 0.34, "A", moves=[(0.44, 0.44, 1)]),
              P(0.68, 0.24, "F", moves=[(0.58, 0.30, 0)])],
        ball=(0.64, 0.28),
    )]


def game3_family() -> list[Drill]:
    return [Drill(
        id="fv_game_3v3", category="ssg", minutes=15, rel=True, free=True,
        off_surface=True, name=suffixed(GAME_NAME, "3v3"), note=GAME_NOTE,
        home=[P(0.26, 0.66, "1"),
              P(0.74, 0.66, "2"),
              P(0.50, HOME_SERVE_Y, "3", moves=[(0.50, 0.84, 0)])],
        away=[P(0.26, 0.30, "A", moves=[(0.30, 0.42, 2)]),
              P(0.74, 0.34, "B", moves=[(0.56, 0.40, 1)]),
              P(0.50, 0.14, "C")],
        ball=2, ball_to=[("a2", 0), ("a1", 1), ("a0", 2), (Spot(0.70, 0.80), 3)],
    )]
