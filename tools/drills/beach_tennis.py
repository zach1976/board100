"""The beach tennis library.

A small court with a high net and no bounce: every ball is a volley, so there
is no baseline game to fall back on. Home is the bottom half, the net is at
y=0.5, and the two players cover the width between them.
"""
from .engine import Drill, M, P, suffixed

BASE = (0.50, 0.90)
LEFT, RIGHT = (0.28, 0.74), (0.72, 0.74)
NET_L, NET_R = (0.30, 0.60), (0.70, 0.60)


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
    "en": "Serve low and at their feet. There is no second bounce to save "
          "them, so a ball below the net tape is already a problem.",
    "en-GB": "Serve low and at their feet. There is no second bounce to save "
             "them, so a ball below the net tape is already a problem.",
    "zh-CN": "发低球、打脚下。没有第二跳能救他们，所以低于网带的球本身就是个麻烦。",
    "zh-TW": "發低球、打腳下。沒有第二跳能救他們，所以低於網帶的球本身就是個麻煩。",
    "ja-JP": "低く、足元へ。救ってくれる2バウンド目はない。ネットの白帯より低い球はそれだけで難題だ。",
    "ko-KR": "낮게, 발밑으로 서브하라. 구해줄 두 번째 바운드는 없다.",
    "es-ES": "Saca bajo y a los pies: no hay segundo bote que los salve, una "
             "bola por debajo de la cinta ya es un problema.",
    "fr-FR": "Sers bas, dans les pieds : aucun second rebond ne les sauvera, "
             "une balle sous la bande est déjà un problème.",
    "id-ID": "Servis rendah ke arah kaki mereka.",
    "ms-MY": "Servis rendah ke arah kaki mereka.",
    "th-TH": "เสิร์ฟต่ำเข้าที่เท้า ไม่มีการกระดอนครั้งที่สองมาช่วยเขา",
    "vi-VN": "Giao thấp và vào chân họ.",
}


def serve_family() -> list[Drill]:
    specs = [("flat", "flat exchange", (0.32, 0.30)), ("sliced", "sliced", (0.68, 0.32)),
             ("jump", "jump", (0.50, 0.22))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"bt_serve_{key}", category="setpiece", minutes=8, rel=True,
            free=(key == "flat"), off_surface=True,
            name=suffixed(SERVE_NAME, label), note=SERVE_NOTE,
            home=[P(0.32, 1.03, "S", moves=[(0.32, 0.94, 0), (0.34, 0.74, 1)]),
                  P(*RIGHT, "P", moves=[(0.70, 0.66, 1)])],
            away=[P(land[0], land[1] - 0.06, "R", moves=[(land[0], land[1], 1)]),
                  P(0.70, 0.30, "R")],
            markers=[M(*land, "zone", "")],
            ball=0,
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
    specs = [("approach", "approach", (0.30, 0.30)),
             ("the drop", "the drop", (0.32, 0.44)),
             ("cross-court", "cross-court", (0.74, 0.28))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"bt_attack_{key.replace('-', '_').replace(' ', '_')}",
            category="attacking", minutes=10, rel=True, free=(key == "approach"),
            name=suffixed(ATTACK_NAME, label), note=ATTACK_NOTE,
            home=[P(*LEFT, "1", moves=[NET_L + (1,)]), P(*RIGHT, "2", moves=[NET_R + (1,)])],
            away=[P(land[0], land[1] - 0.06, "A", moves=[(land[0], land[1], 2)]),
                  P(0.66, 0.28, "B")],
            markers=[M(*land, "zone", "")],
            ball=0,
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


def smash_family() -> list[Drill]:
    specs = [("straight", "straight", (0.30, 0.24)), ("cross-court", "cross-court", (0.74, 0.26)),
             ("jump", "jump", (0.50, 0.18))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"bt_smash_{key.replace('-', '_')}", category="finishing",
            minutes=10, rel=True, free=(key == "straight"),
            name=suffixed(SMASH_NAME, label), note=SMASH_NOTE,
            home=[P(*LEFT, "1", moves=[(0.32, 0.68, 1)]), P(*RIGHT, "2")],
            away=[P(land[0], land[1] - 0.05, "A", moves=[(land[0], land[1], 2)]),
                  P(0.62, 0.30, "B")],
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


def defence_family() -> list[Drill]:
    specs = [("the block", "the block", (0.36, 0.46)),
             ("the lob", "the lob", (0.44, 0.08)),
             ("the drop", "the drop", (0.62, 0.44))]
    out = []
    for key, label, to in specs:
        out.append(Drill(
            id=f"bt_defence_{key.replace(' ', '_')}", category="defending",
            minutes=10, rel=True, free=(key == "the block"),
            name=suffixed(DEF_NAME, label), note=DEF_NOTE,
            home=[P(*LEFT, "1", moves=[(to[0], min(to[1] + 0.30, 0.94), 1)]),
                  P(*RIGHT, "2", moves=[(0.68, 0.70, 1)])],
            away=[P(0.34, 0.30, "A", moves=[(0.34, 0.40, 0)]), P(0.68, 0.32, "B")],
            markers=[M(*to, "zone", "")],
            ball=(0.34, 0.30),
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
    specs = [("half_court", "half-court singles", [(0.30, 0.74)]),
             ("king_of_the_court", "king of the court", [LEFT, RIGHT]),
             ("full_doubles", "full doubles", [LEFT, RIGHT])]
    out = []
    for key, label, spots in specs:
        out.append(Drill(
            id=f"bt_game_{key}", category="ssg", minutes=15, rel=True,
            free=(key != "king_of_the_court"),
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=[P(x, y, str(i + 1), moves=[(x, y - 0.05, 0)])
                  for i, (x, y) in enumerate(spots)],
            away=[P(*mirror((x, y)), chr(65 + i), moves=[(x, 1 - y + 0.05, 0)])
                  for i, (x, y) in enumerate(spots)],
            markers=([M(0.50, 0.26, "cone", ""), M(0.50, 0.74, "cone", "")]
                     if key == "half_court" else []),
            ball=0,
        ))
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
    specs = [("block", "the block", (0.30, 0.10)),
             ("attacking", "on the attack", (0.70, 0.35))]
    out = []
    for key, label, to in specs:
        out.append(Drill(
            id=f"bt_return_{key}", category="possession", minutes=8, rel=True,
            free=(key == "block"), off_surface=True,   # the server behind the line
            name=suffixed(RETURN_NAME, label), note=RETURN_NOTE,
            home=[P(0.34, 0.80, "R", moves=[(to[0], min(to[1] + 0.42, 0.72), 1)]),
                  P(0.70, 0.66, "P", moves=[(0.68, 0.60, 1)])],
            away=[P(0.30, -0.02, "S", moves=[(0.32, 0.20, 1)]),
                  P(0.72, 0.32, "P")],
            markers=[M(*to, "zone", "")],
            ball=(0.30, -0.02),
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
    specs = [("over", "over the net pair", (0.66, 0.90)),
             ("recover", "recovering it", (0.34, 0.06))]
    out = []
    for key, label, land in specs:
        home = ([P(0.30, 0.72, "1", moves=[(0.34, 0.80, 1)]),
                 P(0.70, 0.66, "2", moves=[(land[0], land[1], 1)])]
                if key == "recover" else
                [P(0.30, 0.86, "1", moves=[(0.32, 0.80, 1)]),
                 P(0.70, 0.86, "2")])
        out.append(Drill(
            id=f"bt_lob_{key}", category="attacking", minutes=8, rel=True,
            free=(key == "over"),
            name=suffixed(LOB_NAME, label), note=LOB_NOTE,
            home=home,
            away=[P(0.32, 0.42, "A", moves=[(0.30, 0.24, 1)]),
                  P(0.68, 0.42, "B", moves=[(0.66, 0.30, 1)])],
            markers=[M(*land, "zone", "")] if key == "over" else [],
            ball=0,
        ))
    return out

