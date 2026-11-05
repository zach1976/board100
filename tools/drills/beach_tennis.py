"""The beach tennis library.

A small court with a high net and no bounce: every ball is a volley, so there
is no baseline game to fall back on. Home is the bottom half, the net is at
y=0.5, and the two players cover the width between them.
"""
from .engine import Drill, M, P, Spot, figure_clear, suffixed

BASE = (0.50, 0.90)
# Base position is 1.5-2 m off the net, not 3.5: the library's own
# approach note says the pair standing closer to the net wins the
# exchange more often than not, and only one board moved them up.
LEFT, RIGHT = (0.28, 0.665), (0.72, 0.665)
NET_L, NET_R = (0.30, 0.60), (0.70, 0.60)
# Behind the far baseline with the FEET behind it: the figure hangs half its
# height below its point, toward the net, so a far man written 0.043 past
# the line stood on it (tools/check_baselines.py). The near side is 1.043.
FAR_BACK = -figure_clear("beachTennis")


def mirror(pt):
    return (pt[0], 1.0 - pt[1])


WARM_NAME = {
    "en": "Warm-up", "en-GB": "Warm-up", "zh-CN": "热身", "zh-TW": "熱身",
    "ja-JP": "ウォームアップ", "ko-KR": "웜업", "es-ES": "Calentamiento",
    "fr-FR": "Échauffement", "id-ID": "Pemanasan", "ms-MY": "Memanaskan badan",
    "th-TH": "วอร์มอัพ", "vi-VN": "Khởi động",
}
WARM_NOTE = {
    "en": "Short swings from the start. Sand punishes a big backswing more "
          "than any opponent will.",
    "en-GB": "Short swings from the start. Sand punishes a big backswing more "
             "than any opponent will.",
    "zh-CN": "一开始就用小挥拍。沙地对大引拍的惩罚，比任何对手都狠。",
    "zh-TW": "一開始就用小揮拍。沙地對大引拍的懲罰，比任何對手都狠。",
    "ja-JP": "最初から小さいスイングで。大きなテイクバックは、どんな相手より砂が罰する。",
    "ko-KR": "처음부터 작은 스윙으로. 큰 백스윙은 상대보다 모래가 더 혹독하게 벌한다.",
    "es-ES": "Gestos cortos desde el principio: la arena castiga un armado "
             "grande más que cualquier rival.",
    "fr-FR": "Gestes courts dès le début : le sable punit un grand armé plus "
             "que n'importe quel adversaire.",
    "id-ID": "Ayunan pendek sejak awal. Pasir menghukum backswing besar.",
    "ms-MY": "Hayunan pendek dari awal. Pasir menghukum hayunan besar.",
    "th-TH": "สวิงสั้นตั้งแต่ต้น ทรายลงโทษการเหวี่ยงใหญ่หนักกว่าคู่แข่ง",
    "vi-VN": "Vung ngắn ngay từ đầu. Cát trừng phạt cú lấy đà lớn.",
}


def warmup_family() -> list[Drill]:
    specs = [("volley_exchange", "volley exchange", (0.50, 0.66), (0.50, 0.34)),
             ("short_court", "short court", (0.36, 0.60), (0.64, 0.40))]
    out = []
    for key, label, h, a in specs:
        out.append(Drill(
            id=f"bt_warm_{key}", category="warmup", minutes=6, rel=True, free=True,
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            home=[P(*h, "1", moves=[(h[0], h[1] - 0.04, 0), h + (1,)])],
            away=[P(*a, "2", moves=[(a[0], a[1] + 0.04, 0), a + (1,)])],
            ball=0,
        ))
    return out


RALLY_NAME = {
    "en": "Volley rally", "en-GB": "Volley rally", "zh-CN": "截击对拉",
    "zh-TW": "截擊對拉", "ja-JP": "ボレーラリー", "ko-KR": "발리 랠리",
    "es-ES": "Peloteo de voleas", "fr-FR": "Échange de volées",
    "id-ID": "Reli voli", "ms-MY": "Rali voli", "th-TH": "โต้วอลเลย์",
    "vi-VN": "Đôi công vô lê",
}
RALLY_NOTE = {
    "en": "There is no bounce to wait for, so the racket has to be up before "
          "the ball leaves their strings, not after.",
    "en-GB": "There is no bounce to wait for, so the racket has to be up "
             "before the ball leaves their strings, not after.",
    "zh-CN": "没有落地那一下可以等，所以球拍必须在对方击球之前就举好，而不是之后。",
    "zh-TW": "沒有落地那一下可以等，所以球拍必須在對方擊球之前就舉好，而不是之後。",
    "ja-JP": "待てるバウンドがないので、相手のガットを離れる前にラケットを上げておく。",
    "ko-KR": "기다릴 바운드가 없으니 상대가 치기 전에 라켓을 올려둬야 한다.",
    "es-ES": "No hay bote que esperar: la raqueta ya debe estar arriba antes "
             "de que la bola salga de sus cuerdas.",
    "fr-FR": "Aucun rebond à attendre : la raquette est haute avant que la "
             "balle quitte leur cordage.",
    "id-ID": "Tak ada pantulan untuk ditunggu; raket harus sudah terangkat.",
    "ms-MY": "Tiada lantunan untuk ditunggu; raket mesti sudah terangkat.",
    "th-TH": "ไม่มีการกระดอนให้รอ ต้องยกไม้ก่อนบอลออกจากเอ็นของเขา",
    "vi-VN": "Không có nảy để chờ, vợt phải giơ sẵn trước khi họ đánh.",
}


def rally_family() -> list[Drill]:
    specs = [("straight", "straight", (0.30, 0.28)),
             ("cross-court", "cross-court", (0.72, 0.30))]
    out = []
    for key, label, to in specs:
        out.append(Drill(
            id=f"bt_rally_{key.replace('-', '_')}", category="possession",
            minutes=10, rel=True, free=True,
            name=suffixed(RALLY_NAME, label), note=RALLY_NOTE,
            home=[P(0.30, 0.66, "1", moves=[(0.30, 0.62, 0), (0.30, 0.66, 1)])],
            away=[P(*to, "2", moves=[(to[0], to[1] + 0.04, 1)])],
            ball=0,
        ))
    return out


SERVE_NAME = {
    "en": "Serve", "en-GB": "Serve", "zh-CN": "发球", "zh-TW": "發球",
    "ja-JP": "サーブ", "ko-KR": "서브", "es-ES": "Saque", "fr-FR": "Service",
    "id-ID": "Servis", "ms-MY": "Servis", "th-TH": "การเสิร์ฟ", "vi-VN": "Giao bóng",
}
SERVE_NOTE = {
    # There is no bounce at all in beach tennis — a ball that touches the
    # sand is dead. The note used to say "no second bounce", which implies
    # a first one is legal, and contradicted the library's own rally note.
    "en": "Serve low and at their feet. Nothing bounces here, so a ball below "
          "the tape has to be lifted, and everything lifted gets hit back down.",
    "en-GB": "Serve low and at their feet. Nothing bounces here, so a ball below "
             "the tape has to be lifted, and everything lifted gets hit back down.",
    "zh-CN": "发低球、打脚下。这项运动没有落地，低于网带的球只能往上挑，而挑起来的球都会被砸回来。",
    "zh-TW": "發低球、打腳下。這項運動沒有落地，低於網帶的球只能往上挑，而挑起來的球都會被砸回來。",
    "ja-JP": "低く、足元へ。ここにバウンドは存在しない。白帯より低い球は上げるしかなく、上げた球は必ず叩き返される。",
    "ko-KR": "낮게, 발밑으로 서브하라. 여기엔 바운드가 없어 네트보다 낮은 공은 띄울 수밖에 없고, 띄운 공은 되받아 내리꽂힌다.",
    "es-ES": "Saca bajo y a los pies. Aquí nada bota: una bola por debajo de "
             "la cinta hay que levantarla, y todo lo que se levanta vuelve abajo.",
    "fr-FR": "Sers bas, dans les pieds. Rien ne rebondit ici : une balle sous "
             "la bande doit être relevée, et tout ce qui est relevé revient au sol.",
    "id-ID": "Servis rendah ke arah kaki mereka. Di sini bola tidak memantul.",
    "ms-MY": "Servis rendah ke arah kaki mereka. Di sini bola tidak melantun.",
    "th-TH": "เสิร์ฟต่ำเข้าที่เท้า กีฬานี้ไม่มีการเด้ง ลูกที่ต่ำกว่าตาข่ายต้องงัดขึ้น",
    "vi-VN": "Giao thấp và vào chân họ. Ở đây bóng không nảy.",
}


SERVE_LABEL = {
    # Their own words: 平抽对抗 ("flat exchange") and 劈吊 ("sliced drop")
    # were rally terms, not serves.
    "flat": {"en": "flat", "en-GB": "flat", "zh-CN": "平击", "zh-TW": "平擊",
             "ja-JP": "フラット", "ko-KR": "플랫", "es-ES": "plano",
             "fr-FR": "à plat", "id-ID": "datar", "ms-MY": "rata",
             "th-TH": "แบบเรียบ", "vi-VN": "thẳng"},
    "sliced": {"en": "sliced", "en-GB": "sliced", "zh-CN": "切削",
               "zh-TW": "切削", "ja-JP": "スライス", "ko-KR": "슬라이스",
               "es-ES": "cortado", "fr-FR": "slicé", "id-ID": "slice",
               "ms-MY": "slice", "th-TH": "แบบสไลซ์", "vi-VN": "cắt"},
}


def serve_family() -> list[Drill]:
    # The server serves from behind his baseline (he used to walk 1.6 m in
    # first) and follows it in; the serve goes to R where R stands, and R
    # volleys it back — nothing bounces. Four distinct labels: S and P
    # serve, R receives with his partner N (both sides used to field a P,
    # and both receivers were "R").
    # The serve is hit deep, so R waits behind his baseline, feet behind it,
    # and takes it there, a step across to where it is aimed; the zone is
    # the deep target in front of him. He used to wait 4-6 m inside the
    # court, and the serves were aimed at mid-court.
    specs = [("flat", SERVE_LABEL["flat"], (0.32, 0.10)),
             ("sliced", SERVE_LABEL["sliced"], (0.68, 0.12)),
             ("jump", "jump", (0.50, 0.08))]
    out = []
    for key, label, land in specs:
        r_at = (0.40 if land[0] <= 0.5 else 0.60, FAR_BACK)
        n_at = (0.70, 0.32) if land[0] < 0.6 else (0.30, 0.32)
        out.append(Drill(
            id=f"bt_serve_{key}", category="setpiece", minutes=8, rel=True,
            free=(key == "flat"), off_surface=True,
            name=suffixed(SERVE_NAME, label), note=SERVE_NOTE,
            home=[P(0.32, 1.043, "S", moves=[(0.34, 0.74, 1)]),
                  P(*RIGHT, "P", moves=[(0.70, 0.62, 1)])],
            away=[P(*r_at, "R", moves=[(land[0], FAR_BACK, 0)]), P(*n_at, "N")],
            markers=[M(*land, "zone", "")],
            ball=0, ball_to=[("a0", 0), (0, 1)],
        ))
    return out


ATTACK_NAME = {
    "en": "Attacking", "en-GB": "Attacking", "zh-CN": "进攻", "zh-TW": "進攻",
    "ja-JP": "攻撃", "ko-KR": "공격", "es-ES": "Ataque", "fr-FR": "Attaque",
    "id-ID": "Serangan", "ms-MY": "Serangan", "th-TH": "การบุก", "vi-VN": "Tấn công",
}
ATTACK_NOTE = {
    "en": "Move forward on anything above the tape. On this court the pair "
          "standing closer to the net wins the exchange more often than not.",
    "en-GB": "Move forward on anything above the tape. On this court the pair "
             "standing closer to the net wins the exchange more often than not.",
    "zh-CN": "只要球高过网带就往前压。在这块场地上，站得离网更近的那一对，多半赢下这一轮。",
    "zh-TW": "只要球高過網帶就往前壓。在這塊場地上，站得離網更近的那一對，多半贏下這一輪。",
    "ja-JP": "白帯より高い球にはすべて前へ出る。このコートではネットに近い方のペアが大抵勝つ。",
    "ko-KR": "테이프보다 높은 공엔 전부 전진하라. 이 코트에선 네트에 가까운 조가 대개 이긴다.",
    "es-ES": "Avanza con cualquier bola por encima de la cinta: en esta pista "
             "gana casi siempre la pareja más cerca de la red.",
    "fr-FR": "Avance sur toute balle au-dessus de la bande : sur ce terrain, "
             "la paire la plus proche du filet gagne le plus souvent.",
    "id-ID": "Maju pada setiap bola di atas bibir net.",
    "ms-MY": "Maju pada setiap bola di atas bibir jaring.",
    "th-TH": "ขึ้นหน้าทุกครั้งที่บอลสูงกว่าขอบเน็ต",
    "vi-VN": "Tiến lên với mọi quả cao hơn mép lưới.",
}


def attack_family() -> list[Drill]:
    # A feeds, 1 plays the drilled shot INTO the zone and the pair take the
    # net behind it. The zone is open court — A and B no longer walk onto
    # it, which read as "hit it to him".
    specs = [("approach", "approach", (0.50, 0.12)),
             ("the drop", "the drop", (0.32, 0.44)),
             ("cross-court", "cross-court", (0.82, 0.26))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"bt_attack_{key.replace('-', '_').replace(' ', '_')}",
            category="attacking", minutes=10, rel=True, free=(key == "approach"),
            name=suffixed(ATTACK_NAME, label), note=ATTACK_NOTE,
            home=[P(*LEFT, "1", moves=[(0.30, 0.64, 0), NET_L + (1,)]),
                  P(*RIGHT, "2", moves=[NET_R + (1,)])],
            away=[P(0.30, 0.22, "A"), P(0.64, 0.22, "B")],
            markers=[M(*land, "zone", "")],
            ball=(0.30, 0.22), ball_to=[(0, 0), (Spot(*land), 1)],
        ))
    return out


SMASH_NAME = {
    "en": "Smash", "en-GB": "Smash", "zh-CN": "扣杀", "zh-TW": "扣殺",
    "ja-JP": "スマッシュ", "ko-KR": "스매시", "es-ES": "Remate",
    "fr-FR": "Smash", "id-ID": "Smes", "ms-MY": "Smesy", "th-TH": "สแมช",
    "vi-VN": "Đập bóng",
}
SMASH_NOTE = {
    "en": "Aim at the sand between them, not at a sideline. The gap moves with "
          "them; the line does not, and the line is where errors live.",
    "en-GB": "Aim at the sand between them, not at a sideline. The gap moves "
             "with them; the line does not, and the line is where errors live.",
    "zh-CN": "打两人之间的沙地，不要打边线。空当会跟着他们移动，边线不会——而失误都住在边线上。",
    "zh-TW": "打兩人之間的沙地，不要打邊線。空檔會跟著他們移動，邊線不會——而失誤都住在邊線上。",
    "ja-JP": "サイドラインではなく二人の間の砂を狙う。隙間は相手と一緒に動くが、ラインは動かない。ミスはラインに住んでいる。",
    "ko-KR": "사이드라인이 아니라 둘 사이의 모래를 노려라. 틈은 함께 움직이지만 라인은 움직이지 않는다.",
    "es-ES": "Apunta a la arena entre ellos, no a la línea: el hueco se mueve "
             "con ellos, la línea no, y en la línea viven los errores.",
    "fr-FR": "Vise le sable entre eux, pas la ligne : l'espace bouge avec eux, "
             "la ligne non — et c'est là que vivent les fautes.",
    "id-ID": "Bidik pasir di antara mereka, bukan garis samping.",
    "ms-MY": "Sasarkan pasir antara mereka, bukan garisan tepi.",
    "th-TH": "เล็งทรายระหว่างสองคน ไม่ใช่เส้นข้าง",
    "vi-VN": "Nhắm vào cát giữa hai người, không phải vạch biên.",
}


JUMP_SMASH = {
    # "jump" alone is the vocabulary's jump SERVE (跳发, ジャンプサーブ…).
    "en": "jump", "en-GB": "jump", "zh-CN": "跳起", "zh-TW": "跳起",
    "ja-JP": "ジャンプ", "ko-KR": "점프", "es-ES": "en salto",
    "fr-FR": "sauté", "id-ID": "lompat", "ms-MY": "lompat",
    "th-TH": "กระโดด", "vi-VN": "bật nhảy",
}


def smash_family() -> list[Drill]:
    # A LOBS (the feed used to be a flat drive at chest height), 1 gets
    # under it and the smash itself is drawn into the zone — the sand
    # between A and B or beside them, not where A walks to.
    specs = [("straight", "straight", (0.20, 0.22)),
             ("cross-court", "cross-court", (0.80, 0.22)),
             ("jump", JUMP_SMASH, (0.50, 0.22))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"bt_smash_{key.replace('-', '_')}", category="finishing",
            minutes=10, rel=True, free=(key == "straight"),
            name=suffixed(SMASH_NAME, label), note=SMASH_NOTE,
            home=[P(*LEFT, "1", moves=[(0.32, 0.74, 0)]),
                  P(*RIGHT, "2", moves=[(0.68, 0.64, 1)])],
            away=[P(0.34, 0.34, "A"), P(0.66, 0.34, "B")],
            markers=[M(*land, "zone", "")],
            ball=(0.34, 0.34), ball_to=[(0, 0), (Spot(*land), 1)],
        ))
    return out


DEF_NAME = {
    "en": "Defending", "en-GB": "Defending", "zh-CN": "防守", "zh-TW": "防守",
    "ja-JP": "ディフェンス", "ko-KR": "수비", "es-ES": "Defensa",
    "fr-FR": "Défense", "id-ID": "Bertahan", "ms-MY": "Pertahanan",
    "th-TH": "การรับ", "vi-VN": "Phòng thủ",
}
DEF_NOTE = {
    "en": "Block it back short rather than trying to hit through them. In sand "
          "the counter-attack is a shot they have to run to, not one they duck.",
    "en-GB": "Block it back short rather than trying to hit through them. In "
             "sand the counter-attack is a shot they have to run to, not one they duck.",
    "zh-CN": "挡短回去，别想着硬打穿他们。在沙地上，反击是让对方必须跑过去的那一球，而不是让他们低头躲的那一球。",
    "zh-TW": "擋短回去，別想著硬打穿他們。在沙地上，反擊是讓對方必須跑過去的那一球，而不是讓他們低頭躲的那一球。",
    "ja-JP": "撃ち抜こうとせず、短くブロックして返す。砂の上での反撃とは、相手が走らされる球であって、かわされる球ではない。",
    "ko-KR": "뚫으려 하지 말고 짧게 막아 넘겨라. 모래에서 반격은 상대가 뛰어야 하는 공이다.",
    "es-ES": "Bloquea corto en vez de intentar atravesarlos: en arena el "
             "contragolpe es una bola que deben correr, no una que esquivan.",
    "fr-FR": "Bloque court plutôt que de vouloir les transpercer : sur le "
             "sable, le contre est une balle qu'on doit courir chercher.",
    "id-ID": "Blok pendek daripada mencoba menembus mereka.",
    "ms-MY": "Blok pendek daripada cuba menembusi mereka.",
    "th-TH": "บล็อกคืนสั้น ๆ ดีกว่าพยายามตีทะลุ",
    "vi-VN": "Chắn trả ngắn thay vì cố đánh xuyên qua họ.",
}


DROP_DEF_NOTE = {
    "en": "Start forward the moment you see the short swing: there is no bounce to wait for, so a drop you reach late is a drop that has already landed. Lift it deep and get back.",
    "en-GB": "Start forward the moment you see the short swing: there is no bounce to wait for, so a drop you reach late is a drop that has already landed. Lift it deep and get back.",
    "zh-CN": "一看到对方小挥拍就向前启动：没有落地可以等，晚到一步的吊球就已经落在沙上了。挑深，然后退回位置。",
    "zh-TW": "一看到對方小揮拍就向前啟動：沒有落地可以等，晚到一步的吊球就已經落在沙上了。挑深，然後退回位置。",
    "ja-JP": "小さなスイングが見えた瞬間に前へ。待てるバウンドはないので、遅れて届いたドロップはもう砂に落ちている。深く上げて戻る。",
    "ko-KR": "작은 스윙이 보이는 순간 앞으로 출발하라. 기다릴 바운드가 없으니 늦게 닿은 드롭은 이미 모래에 떨어진 공이다. 깊게 올리고 돌아가라.",
    "es-ES": "Arranca hacia delante en cuanto veas el gesto corto: no hay bote que esperar, y una dejada a la que llegas tarde ya ha tocado la arena. Levántala profunda y vuelve.",
    "fr-FR": "Pars vers l'avant dès que tu vois le geste court : aucun rebond à attendre, un amorti atteint en retard a déjà touché le sable. Remonte-le long et replace-toi.",
    "id-ID": "Maju begitu melihat ayunan pendek: tidak ada pantulan untuk ditunggu, drop yang terlambat dijangkau sudah menyentuh pasir. Angkat dalam lalu kembali.",
    "ms-MY": "Mara sebaik nampak hayunan pendek: tiada lantunan untuk ditunggu, drop yang lambat dicapai sudah menyentuh pasir. Angkat dalam dan kembali.",
    "th-TH": "ออกตัวไปข้างหน้าทันทีที่เห็นวงสวิงสั้น ไม่มีการเด้งให้รอ ลูกหยอดที่ไปถึงช้าก็ตกทรายไปแล้ว งัดให้ลึกแล้วกลับที่",
    "vi-VN": "Lao lên ngay khi thấy vung vợt ngắn: không có nảy để chờ, quả bỏ nhỏ tới muộn là đã chạm cát. Nâng sâu rồi lùi về.",
}
LOB_DEF_NOTE = {
    "en": "Turn and run, don't backpedal, and answer the lob with height and depth: a lob played back over them buys the time to get back to the net. Smashing it from behind your head is their point.",
    "en-GB": "Turn and run, don't backpedal, and answer the lob with height and depth: a lob played back over them buys the time to get back to the net. Smashing it from behind your head is their point.",
    "zh-CN": "转身跑，不要倒退，用高度和深度回应高球：再挑回他们头顶，才能换来回到网前的时间。从脑后硬扣，就是送分。",
    "zh-TW": "轉身跑，不要倒退，用高度和深度回應高球：再挑回他們頭頂，才能換來回到網前的時間。從腦後硬扣，就是送分。",
    "ja-JP": "後ろ向きに下がらず振り向いて走り、高さと深さでロブに答える。相手の頭上へ返すロブがネットへ戻る時間を買う。頭の後ろから叩けば相手の得点だ。",
    "ko-KR": "뒷걸음질 말고 돌아서 뛰어라. 로브에는 높이와 깊이로 답하라. 상대 머리 위로 다시 띄운 로브가 네트로 돌아갈 시간을 산다.",
    "es-ES": "Gira y corre, no retrocedas de espaldas, y responde al globo con altura y profundidad: un globo devuelto sobre ellos compra el tiempo de volver a la red.",
    "fr-FR": "Tourne-toi et cours, ne recule pas en pas chassés, et réponds au lob par de la hauteur et de la longueur : un lob renvoyé au-dessus d'eux te rend le temps de remonter au filet.",
    "id-ID": "Berbalik dan lari, jangan mundur, dan jawab lob dengan tinggi dan dalam: lob balik di atas mereka memberi waktu kembali ke net.",
    "ms-MY": "Pusing dan lari, jangan berundur, dan balas lob dengan tinggi dan dalam: lob balik di atas mereka memberi masa untuk kembali ke jaring.",
    "th-TH": "หมุนตัววิ่ง อย่าถอยหลัง ตอบลูกโด่งด้วยความสูงและความลึก โด่งกลับข้ามหัวเขาจะได้เวลากลับขึ้นหน้าเน็ต",
    "vi-VN": "Quay người chạy, đừng lùi giật lùi, đáp bóng bổng bằng độ cao và độ sâu: trả bổng qua đầu họ để có thời gian lên lưới lại.",
}


def defence_family() -> list[Drill]:
    """1 is the defender: A attacks him — a drive at his body, a drop short
    in front of him, a lob over him — and 1's defensive ball is drawn into
    the zone. The drop and lob drills used to show 1 HITTING the drop and
    the lob, i.e. the opposite drill."""
    specs = [
        # key, label, where A's ball takes 1, zone for 1's reply, note
        ("the block", "the block", (0.32, 0.66), (0.36, 0.44), DEF_NOTE),
        ("the drop", "the drop", (0.34, 0.57), (0.40, 0.10), DROP_DEF_NOTE),
        ("the lob", "the lob", (0.36, 0.90), (0.44, 0.08), LOB_DEF_NOTE),
    ]
    out = []
    for key, label, meet, to, note in specs:
        out.append(Drill(
            id=f"bt_defence_{key.replace(' ', '_')}", category="defending",
            minutes=10, rel=True, free=(key == "the block"),
            name=suffixed(DEF_NAME, label), note=note,
            home=[P(*LEFT, "1", moves=[meet + (0,), LEFT + (1,)]),
                  P(*RIGHT, "2", moves=[(0.64, 0.68, 1)])],
            away=[P(0.34, 0.36, "A"), P(0.68, 0.34, "B")],
            markers=[M(*to, "zone", "")],
            ball=(0.34, 0.36), ball_to=[(0, 0), (Spot(*to), 1)],
        ))
    return out


GAME_NAME = {
    "en": "Game", "en-GB": "Game", "zh-CN": "对抗", "zh-TW": "對抗",
    "ja-JP": "ゲーム", "ko-KR": "게임", "es-ES": "Juego", "fr-FR": "Jeu",
    "id-ID": "Permainan", "ms-MY": "Permainan", "th-TH": "เกม", "vi-VN": "Trận đấu",
}
GAME_NOTE = {
    "en": "Rallies are short here, so play more of them. Twenty short points "
          "teach more than one long one anybody can remember.",
    "en-GB": "Rallies are short here, so play more of them. Twenty short "
             "points teach more than one long one anybody can remember.",
    "zh-CN": "这里的回合本来就短，那就多打几个。二十个短分教会的东西，比一个人人记得住的长分要多。",
    "zh-TW": "這裡的回合本來就短，那就多打幾個。二十個短分教會的東西，比一個人人記得住的長分要多。",
    "ja-JP": "ここではラリーが短い。ならば本数を打つ。20本の短いポイントは、誰もが覚えている1本の長いラリーより多くを教える。",
    "ko-KR": "여기선 랠리가 짧으니 더 많이 하라. 짧은 20점이 기억에 남는 긴 1점보다 많이 가르친다.",
    "es-ES": "Aquí los puntos son cortos: juega más. Veinte puntos cortos "
             "enseñan más que uno largo que todos recuerdan.",
    "fr-FR": "Les échanges sont courts ici : jouez-en davantage. Vingt points "
             "courts apprennent plus qu'un long dont tout le monde se souvient.",
    "id-ID": "Reli di sini pendek, jadi mainkan lebih banyak.",
    "ms-MY": "Rali di sini pendek, jadi mainkan lebih banyak.",
    "th-TH": "ที่นี่แต้มสั้น ก็เล่นให้มากขึ้น",
    "vi-VN": "Ở đây pha bóng ngắn, nên hãy chơi nhiều hơn.",
}


def game_family() -> list[Drill]:
    # The point starts with the server BEHIND his baseline (he used to
    # stand 5 m in); he serves and moves up. King of the court is 2 v 2 on
    # the sand with the challenging pairs queuing off it, behind the
    # sidelines — not 4 v 4 with the queue standing in the corners.
    out = []
    specs = [
        ("half_court", "half-court singles",
         [P(0.28, 1.043, "1", moves=[(0.28, 0.72, 0)])],
         [P(0.28, FAR_BACK, "A")]),
        ("king_of_the_court", "king of the court",
         [P(0.30, 1.043, "1", moves=[LEFT + (0,)]), P(*RIGHT, "2"),
          P(1.07, 0.84, "3"), P(1.07, 0.96, "4")],
         [P(0.70, FAR_BACK, "A"), P(0.30, 0.335, "B"),
          P(-0.07, 0.16, "C"), P(-0.07, 0.04, "D")]),
        ("full_doubles", "full doubles",
         [P(0.30, 1.043, "1", moves=[LEFT + (0,)]), P(*RIGHT, "2")],
         [P(0.70, FAR_BACK, "A"), P(0.30, 0.335, "B")]),
    ]
    for key, label, home, away in specs:
        out.append(Drill(
            id=f"bt_game_{key}", category="ssg", minutes=15, rel=True,
            free=(key != "king_of_the_court"), off_surface=True,
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=home, away=away,
            markers=([M(0.50, 1.0, "cone", ""), M(0.50, 0.0, "cone", "")]
                     if key == "half_court" else []),
            ball=0, ball_to=[("a0", 0), (0, 1)],
        ))
    out[1].setup = {
        "en": "2 v 2 on the sand; the challenging pairs (3, 4 and C, D) queue off the court beside the sidelines",
        "en-GB": "2 v 2 on the sand; the challenging pairs (3, 4 and C, D) queue off the court beside the sidelines",
        "zh-CN": "场上 2 对 2；挑战的组合（3、4 和 C、D）在边线外的场外排队",
        "zh-TW": "場上 2 對 2；挑戰的組合（3、4 和 C、D）在邊線外的場外排隊",
    }
    return out


def beach_tennis_library() -> list[Drill]:
    return (warmup_family() + rally_family() + return_family()
            + serve_family() + attack_family() + lob_family()
            + smash_family() + defence_family() + coverage_family()
            + game_family())

RETURN_NAME = {
    "en": "Return", "en-GB": "Return", "zh-CN": "接发", "zh-TW": "接發",
    "ja-JP": "リターン", "ko-KR": "리턴", "es-ES": "Resto", "fr-FR": "Retour",
    "id-ID": "Pengembalian", "ms-MY": "Pulangan", "th-TH": "การรับเสิร์ฟ",
    "vi-VN": "Trả giao bóng",
}
RETURN_NOTE = {
    "en": "The return is a volley like everything else here — block it deep "
          "and take the net before the server's partner does.",
    "en-GB": "The return is a volley like everything else here — block it "
             "deep and take the net before the server's partner does.",
    "zh-CN": "接发也是截击。挡深，然后抢在发球方同伴之前占住网前。",
    "zh-TW": "接發也是截擊。擋深，然後搶在發球方同伴之前占住網前。",
    "ja-JP": "リターンも他と同じボレーだ。深くブロックし、サーバーの相方より先にネットを取る。",
    "ko-KR": "리턴도 발리다. 깊게 막고, 서버의 파트너보다 먼저 네트를 차지하라.",
    "es-ES": "El resto es una volea como todo aquí: bloquéalo profundo y toma "
             "la red antes que el compañero del sacador.",
    "fr-FR": "Le retour est une volée comme tout le reste : bloque profond et "
             "prends le filet avant le partenaire du serveur.",
    "id-ID": "Pengembalian juga voli — blok dalam dan rebut net lebih dulu.",
    "ms-MY": "Pulangan juga voli — blok dalam dan rebut jaring dahulu.",
    "th-TH": "การรับเสิร์ฟก็คือวอลเลย์ บล็อกให้ลึกแล้วชิงหน้าเน็ตก่อนคู่ของฝ่ายเสิร์ฟ",
    "vi-VN": "Trả giao cũng là vô lê — chặn sâu rồi chiếm lưới trước.",
}


def return_family() -> list[Drill]:
    # R meets the serve 3-4 m off the net — it is a volley, nothing bounces
    # — and the return itself is drawn into the zone; then R takes the net.
    # He used to sprint to the tape to take the serve with his head over
    # the net, and the return was never hit. Labels: R and his partner N
    # against S and P.
    specs = [("block", "the block", (0.20, 0.10), (0.34, 0.74)),
             ("attacking", "on the attack", (0.64, 0.36), (0.36, 0.70))]
    out = []
    for key, label, to, meet in specs:
        out.append(Drill(
            id=f"bt_return_{key}", category="possession", minutes=8, rel=True,
            free=(key == "block"), off_surface=True,   # the server behind the line
            name=suffixed(RETURN_NAME, label), note=RETURN_NOTE,
            home=[P(0.34, 0.80, "R", moves=[meet + (0,), NET_L + (1,)]),
                  P(0.70, 0.66, "N", moves=[(0.68, 0.60, 1)])],
            away=[P(0.30, FAR_BACK, "S", moves=[(0.40, 0.30, 1)]),
                  P(0.72, 0.32, "P")],
            markers=[M(*to, "zone", "")],
            ball=(0.30, FAR_BACK), ball_to=[(0, 0), (Spot(*to), 1)],
        ))
    return out


COVER_NAME = {
    "en": "Court coverage", "en-GB": "Court coverage", "zh-CN": "补位",
    "zh-TW": "補位", "ja-JP": "コートカバー", "ko-KR": "코트 커버",
    "es-ES": "Cobertura", "fr-FR": "Couverture", "id-ID": "Menutup lapangan",
    "ms-MY": "Litupan gelanggang", "th-TH": "การคุมพื้นที่", "vi-VN": "Bọc sân",
}
COVER_NOTE = {
    "en": "The middle belongs to the forehand — call it before the point, not "
          "during it. Two rackets meeting in the middle is a point for them.",
    "en-GB": "The middle belongs to the forehand — call it before the point, "
             "not during it. Two rackets meeting in the middle is a point for them.",
    "zh-CN": "中路归正手——分开始之前就说好，别在球飞过来时才商量。两把拍子在中间相撞，这分就是对面的。",
    "zh-TW": "中路歸正手——分開始之前就說好，別在球飛過來時才商量。兩把拍子在中間相撞，這分就是對面的。",
    "ja-JP": "真ん中はフォアハンド側のもの。ポイントの前に決めておく。真ん中でラケットが2本ぶつかったら相手の得点だ。",
    "ko-KR": "가운데는 포핸드의 몫 — 포인트 전에 정해둬라. 라켓 두 개가 가운데서 만나면 상대 점수다.",
    "es-ES": "El medio es de la derecha: decidlo antes del punto. Dos palas "
             "chocando en el centro es un punto para ellos.",
    "fr-FR": "Le milieu appartient au coup droit — décidez-le avant le point. "
             "Deux raquettes au centre, c'est un point pour eux.",
    "id-ID": "Tengah milik forehand — sepakati sebelum poin dimulai.",
    "ms-MY": "Tengah milik forehand — setuju sebelum mata bermula.",
    "th-TH": "ตรงกลางเป็นของโฟร์แฮนด์ ตกลงกันก่อนเริ่มแต้ม",
    "vi-VN": "Khoảng giữa thuộc về thuận tay — thống nhất trước điểm đấu.",
}


def coverage_family() -> list[Drill]:
    specs = [("middle", "the middle ball", [(0.34, 0.70), (0.66, 0.70)],
              [(0.46, 0.62), (0.70, 0.72)]),
             ("switching", "switching sides", [(0.28, 0.62), (0.72, 0.78)],
              [(0.70, 0.64), (0.30, 0.78)])]
    out = []
    for key, label, start, end in specs:
        out.append(Drill(
            id=f"bt_cover_{key}", category="defending", minutes=10, rel=True,
            free=(key == "middle"),
            name=suffixed(COVER_NAME, label), note=COVER_NOTE,
            home=[P(x, y, f"{i + 1}", moves=[end[i] + (1,)])
                  for i, (x, y) in enumerate(start)],
            away=[P(0.50, 0.30, "A", moves=[(0.52, 0.38, 0)]), P(0.24, 0.28, "B")],
            ball=(0.50, 0.30),
        ))
    return out


LOB_NAME = {
    "en": "Lob battle", "en-GB": "Lob battle", "zh-CN": "高球攻防",
    "zh-TW": "高球攻防", "ja-JP": "ロブ戦", "ko-KR": "로브 싸움",
    "es-ES": "Duelo de globos", "fr-FR": "Bataille de lobs",
    "id-ID": "Adu lob", "ms-MY": "Adu lob", "th-TH": "เกมลูกโด่ง",
    "vi-VN": "Đấu bóng bổng",
}
LOB_NOTE = {
    "en": "A lob into the sun or the wind is a weapon; the same lob with them "
          "at your back is a feed. Check both before you choose it.",
    "en-GB": "A lob into the sun or the wind is a weapon; the same lob with "
             "them at your back is a feed. Check both before you choose it.",
    "zh-CN": "顶着太阳或逆风的高球是武器；顺风背光的同一个高球是喂球。选它之前先看这两样。",
    "zh-TW": "頂著太陽或逆風的高球是武器；順風背光的同一個高球是餵球。選它之前先看這兩樣。",
    "ja-JP": "太陽や風に向かわせるロブは武器。追い風で打つ同じロブはただの餌だ。上げる前に両方を確認する。",
    "ko-KR": "해와 바람을 상대에게 안기는 로브는 무기고, 등지고 올리는 같은 로브는 먹이다.",
    "es-ES": "Un globo contra el sol o el viento es un arma; el mismo globo "
             "con ellos a favor es comida. Mira ambos antes de elegirlo.",
    "fr-FR": "Un lob dans le soleil ou le vent est une arme ; le même lob "
             "vent dans le dos est une offrande. Vérifie les deux avant.",
    "id-ID": "Lob melawan matahari atau angin adalah senjata.",
    "ms-MY": "Lob melawan matahari atau angin ialah senjata.",
    "th-TH": "ลูกโด่งเข้าหาแดดหรือลมคืออาวุธ ลูกเดียวกันตามลมคือการป้อน",
    "vi-VN": "Bóng bổng ngược nắng hay ngược gió là vũ khí.",
}


def lob_family() -> list[Drill]:
    out = []
    # Over the net pair: A and B are at the net, 1 lobs over them into the
    # zone by THEIR baseline, and they turn and chase it while 1 and 2 take
    # the net. (The zone used to be in 1's own half and the lob was never
    # drawn.)
    out.append(Drill(
        id="bt_lob_over", category="attacking", minutes=8, rel=True, free=True,
        name=suffixed(LOB_NAME, "over the net pair"), note=LOB_NOTE,
        home=[P(0.30, 0.80, "1", moves=[(0.32, 0.70, 1)]),
              P(0.70, 0.80, "2", moves=[(0.68, 0.68, 1)])],
        away=[P(0.32, 0.38, "A", moves=[(0.34, 0.22, 1)]),
              P(0.68, 0.38, "B", moves=[(0.62, 0.24, 1)])],
        markers=[M(0.46, 0.08, "zone", "")],
        ball=(0.32, 0.38), ball_to=[(0, 0), (Spot(0.46, 0.08), 1)],
    ))
    # Recovering it: the lob goes over the home pair, 2 turns and runs it
    # down, 1 covers forward.
    out.append(Drill(
        id="bt_lob_recover", category="attacking", minutes=8, rel=True,
        name=suffixed(LOB_NAME, "recovering it"), note=LOB_NOTE,
        home=[P(0.30, 0.66, "1", moves=[(0.34, 0.60, 1)]),
              P(0.70, 0.66, "2", moves=[(0.62, 0.90, 0), (0.66, 0.70, 1)])],
        away=[P(0.32, 0.38, "A"), P(0.68, 0.38, "B")],
        ball=(0.32, 0.38), ball_to=[(1, 0), ("a0", 1)],
    ))
    return out
