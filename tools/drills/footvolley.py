"""The footvolley library.

Beach volleyball played with everything except the hands: three touches, two
players, and a high net. The court is portrait with the net at y=0.5 and home
at the bottom — the same shape as volleyball, but every drill is limited by
what a foot, thigh, chest or head can actually do with the ball.
"""
from .engine import Drill, M, P, suffixed

LEFT, RIGHT = (0.30, 0.74), (0.70, 0.74)
SET_POINT = (0.44, 0.60)
NET = 0.5


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
            home=[P(0.34, 0.76, "1", moves=[(0.38, 0.70, 0)]),
                  P(0.66, 0.76, "2", moves=[(0.62, 0.70, 0)])],
            ball=0,
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
    specs = [("chest control", "chest control", (0.44, 0.66)),
             ("the shoulder pass", "the shoulder pass", (0.52, 0.62)),
             ("the high feed", "the high feed", SET_POINT)]
    out = []
    for key, label, target in specs:
        out.append(Drill(
            id=f"fv_control_{key.replace(' ', '_')}", category="possession",
            minutes=10, rel=True, free=(key != "the shoulder pass"),
            name=suffixed(CONTROL_NAME, label), note=CONTROL_NOTE,
            home=[P(*RIGHT, "1", moves=[(target[0] + 0.14, target[1] + 0.06, 0)]),
                  P(*LEFT, "2", moves=[target + (1,)])],
            away=[P(0.50, 0.28, "F", moves=[(0.50, 0.36, 0)])],
            markers=[M(*target, "square", "")],
            ball=(0.50, 0.28),
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


def serve_family() -> list[Drill]:
    specs = [("long and fast", "long and fast", (0.50, 0.06)),
             ("in the corner", "in the corner", (0.14, 0.10)),
             ("at the seam", "at the seam", (0.50, 0.28))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"fv_serve_{key.replace(' ', '_')}", category="setpiece",
            minutes=8, rel=True, free=(key == "long and fast"), off_surface=True,
            name=suffixed(SERVE_NAME, label), note=SERVE_NOTE,
            home=[P(0.50, 1.04, "S", moves=[(0.50, 0.96, 0), (0.50, 0.80, 1)])],
            away=[P(0.30, 0.26, "R", moves=[(land[0], land[1] + 0.06, 1)]),
                  P(0.70, 0.26, "R")],
            markers=[M(*land, "zone", "")],
            ball=0,
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
    specs = [("the shark attack", "the shark attack", (0.28, 0.30)),
             ("the sombrero", "the sombrero", (0.68, 0.40)),
             ("cross-court", "cross-court", (0.74, 0.24))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"fv_attack_{key.replace(' ', '_').replace('-', '_')}",
            category="attacking", minutes=12, rel=True,
            free=(key == "the shark attack"),
            name=suffixed(ATTACK_NAME, label), note=ATTACK_NOTE,
            home=[P(*LEFT, "1", moves=[SET_POINT + (0,)]),
                  P(*RIGHT, "2", moves=[(0.56, 0.62, 0), (0.50, 0.54, 1)])],
            away=[P(0.50, 0.46, "B", moves=[(0.52, 0.455, 1)]),
                  P(land[0], land[1] - 0.06, "D", moves=[(land[0], land[1], 2)])],
            markers=[M(*land, "zone", "")],
            ball=0,
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
    specs = [("the bicycle kick", "the bicycle kick", (0.34, 0.22)),
             ("the header", "the header", (0.62, 0.28)),
             ("the drop", "the drop", (0.50, 0.44))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"fv_finish_{key.replace(' ', '_')}", category="finishing",
            minutes=10, rel=True, free=(key == "the header"),
            name=suffixed(FINISH_NAME, label), note=FINISH_NOTE,
            home=[P(*LEFT, "1", moves=[SET_POINT + (0,)]),
                  P(*RIGHT, "2", moves=[(0.52, 0.56, 1)])],
            away=[P(land[0], land[1] - 0.06, "D", moves=[(land[0], land[1], 2)]),
                  P(0.34, 0.46, "B")],
            markers=[M(*land, "zone", "")],
            ball=0,
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
    specs = [("the block", "the block", (0.44, 0.53), (0.66, 0.80)),
             ("covering the block", "covering the block", (0.40, 0.53), (0.56, 0.86)),
             ("the dig", "the dig", (0.34, 0.70), (0.68, 0.72))]
    out = []
    for key, label, first, second in specs:
        out.append(Drill(
            id=f"fv_defence_{key.replace(' ', '_')}", category="defending",
            minutes=10, rel=True, free=(key == "the block"),
            name=suffixed(DEF_NAME, label), note=DEF_NOTE,
            home=[P(*LEFT, "1", moves=[first + (1,)]),
                  P(*RIGHT, "2", moves=[second + (1,)])],
            away=[P(0.44, 0.36, "A", moves=[(0.44, 0.45, 1)]),
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
    specs = [("1v1", "1v1", [(0.50, 0.76)]), ("2v2", "2v2", [LEFT, RIGHT]),
             ("4v4", "4v4", [(0.20, 0.66), (0.44, 0.80), (0.60, 0.66), (0.82, 0.80)])]
    out = []
    for key, label, spots in specs:
        out.append(Drill(
            id=f"fv_game_{key}", category="ssg", minutes=15, rel=True,
            free=(key in ("2v2", "4v4")),
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=[P(x, y, str(i + 1), moves=[(x, y - 0.05, 0)])
                  for i, (x, y) in enumerate(spots)],
            away=[P(*mirror((x, y)), chr(65 + i), moves=[(x, 1 - y + 0.05, 0)])
                  for i, (x, y) in enumerate(spots)],
            ball=0,
        ))
    return out


def footvolley_library() -> list[Drill]:
    return (warmup_family() + control_family() + serve_family()
            + attack_family() + finishing_family() + defence_family()
            + game_family())
