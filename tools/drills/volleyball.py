"""The volleyball library.

Volleyball is a rotation sport: the same six players solve a different problem
depending on where the rotation has left them, which is why serve receive is
generated per rotation rather than drawn once. The court is portrait with the
net across the middle at y=0.5; home defends the bottom half, and away is the
same shape mirrored through the net.
"""
from .engine import Drill, M, P, suffixed

NET = 0.5

# The six zones, by their volleyball numbers, on the home (bottom) side.
Z = {1: (0.80, 0.88), 2: (0.78, 0.62), 3: (0.50, 0.60),
     4: (0.22, 0.62), 5: (0.20, 0.88), 6: (0.50, 0.92)}
FRONT_ROW = (4, 3, 2)
# Rotation order: a side rotates 1 → 6 → 5 → 4 → 3 → 2 → 1.
ROT_ORDER = (1, 6, 5, 4, 3, 2)

# The setter's target: the right-of-middle seam they set from.
SET_POINT = (0.66, 0.545)


def mirror(pt):
    """The same court position for the team on the other side.

    A half turn, not a flip. Reflecting only y kept the x of the home
    team's frame, so the away setter — right of middle from her own side —
    was drawn in her zone 4, setting from one antenna to the other, and
    every away zone number landed on the wrong side of her court.
    """
    return (1.0 - pt[0], 1.0 - pt[1])


def zone(n, side="home"):
    return Z[n] if side == "home" else mirror(Z[n])


# ── serve receive, one drill per rotation ────────────────────────────────────

RECEIVE_NAME = {
    "en": "Serve receive rotation", "en-GB": "Serve receive rotation",
    "zh-CN": "接发球轮次", "zh-TW": "接發球輪次",
    "ja-JP": "サーブレシーブ ローテーション", "ko-KR": "서브 리시브 로테이션",
    "es-ES": "Recepción rotación", "fr-FR": "Réception rotation",
    "id-ID": "Rotasi terima servis", "ms-MY": "Rotasi terima servis",
    "th-TH": "การรับเสิร์ฟ รอบที่", "vi-VN": "Xoay vòng đỡ giao bóng",
}
RECEIVE_NOTE = {
    "en": "Three passers, one seam each. Call the ball early and loud — a "
          "silent seam is where every rotation loses its first point.",
    "en-GB": "Three passers, one seam each. Call the ball early and loud — a "
             "silent seam is where every rotation loses its first point.",
    "zh-CN": "三个接球人，每人负责一条结合部。早喊、大声喊——不喊的结合部，就是每一轮丢掉第一分的地方。",
    "zh-TW": "三個接球人，每人負責一條結合部。早喊、大聲喊——不喊的結合部，就是每一輪丟掉第一分的地方。",
    "ja-JP": "レシーバー3人、それぞれ継ぎ目を1つ。早く大きくコールする。無言の継ぎ目が最初の失点になる。",
    "ko-KR": "리시버 셋, 각자 이음새 하나. 일찍 크게 콜하라. 조용한 이음새에서 첫 점수를 잃는다.",
    "es-ES": "Tres receptores, una costura cada uno. Canta el balón pronto y "
             "fuerte: la costura silenciosa es el primer punto perdido.",
    "fr-FR": "Trois réceptionneurs, une couture chacun. Annonce tôt et fort : "
             "une couture silencieuse, c'est le premier point perdu.",
    "id-ID": "Tiga penerima, satu celah masing-masing. Panggil bola lebih awal "
             "dan lantang — celah yang sunyi adalah poin pertama yang hilang.",
    "ms-MY": "Tiga penerima, satu celah setiap seorang. Panggil bola awal dan "
             "kuat — celah yang senyap ialah mata pertama yang hilang.",
    "th-TH": "ผู้รับสามคน คนละรอยต่อ ขานบอลให้เร็วและดัง รอยต่อที่เงียบคือจุดที่เสียแต้มแรกทุกรอบ",
    "vi-VN": "Ba người đỡ, mỗi người một khe. Gọi bóng sớm và to — khe im lặng "
             "là nơi mất điểm đầu tiên của mỗi vòng xoay.",
}


def receive_family() -> list[Drill]:
    """Serve receive in each of the six rotations.

    The setter sits in a different zone every rotation, so a different three
    players are left passing and the release run changes length — six real
    drills out of one idea.
    """
    out = []
    for r in range(1, 7):
        setter_zone = ROT_ORDER[(r - 1) % 6]
        back = [z for z in (5, 6, 1) if z != setter_zone]
        # A back-row setter releases out of the pass, so a front-row outside
        # steps back into the seam they leave behind.
        if len(back) < 3:
            back.append(4 if setter_zone != 4 else 2)
        passers = back[:3]

        home = [P(*zone(setter_zone), "S", moves=[SET_POINT + (1,)])]
        for i, z in enumerate(passers):
            x, y = zone(z)
            home.append(P(x, y, f"P{i + 1}",
                          moves=[(x + (0.5 - x) * 0.18, y - 0.06, 0)]))
        for z in FRONT_ROW:
            if z == setter_zone or z in passers:
                continue
            x, y = zone(z)
            home.append(P(x, y, "H", moves=[(x, y + 0.10, 1), (x, y - 0.05, 2)]))

        out.append(Drill(
            id=f"vb_receive_r{r}", category="possession", minutes=10, rel=True,
            free=(r in (1, 4)), off_surface=True,
            name=suffixed(RECEIVE_NAME, f"{r}"), note=RECEIVE_NOTE,
            home=home,
            away=[P(0.5, -0.04, "S", moves=[(0.5, 0.02, 0)])],
            markers=[M(*SET_POINT, "square", "")],
            ball=(0.5, -0.04),          # in the server's hand, behind the line
        ))
    return out


# ── attacking from each zone ─────────────────────────────────────────────────

ATTACK_NAME = {
    "en": "Attack from", "en-GB": "Attack from", "zh-CN": "进攻位置",
    "zh-TW": "進攻位置", "ja-JP": "アタック", "ko-KR": "공격",
    "es-ES": "Ataque desde", "fr-FR": "Attaque depuis",
    "id-ID": "Serangan dari", "ms-MY": "Serangan dari",
    "th-TH": "บุกจาก", "vi-VN": "Tấn công từ",
}
ATTACK_NOTE = {
    "en": "Start the approach late and fast, not early and drifting. The last "
          "two steps are what gets you above the block.",
    "en-GB": "Start the approach late and fast, not early and drifting. The "
             "last two steps are what gets you above the block.",
    "zh-CN": "助跑要晚而快，不要早而飘。真正让你高过拦网的，是最后两步。",
    "zh-TW": "助跑要晚而快，不要早而飄。真正讓你高過攔網的，是最後兩步。",
    "ja-JP": "助走は遅く速く。早く出て流れるな。ブロックの上に出られるかは最後の2歩で決まる。",
    "ko-KR": "조주는 늦게, 빠르게. 일찍 나가 흘러가지 마라. 블로킹 위로 올라가는 건 마지막 두 걸음이다.",
    "es-ES": "Empieza la carrera tarde y rápido, no pronto y a la deriva: los "
             "dos últimos pasos te ponen por encima del bloqueo.",
    "fr-FR": "Déclenche la course tard et vite, pas tôt en dérive : ce sont "
             "les deux derniers appuis qui te font passer au-dessus du bloc.",
    "id-ID": "Mulai awalan telat dan cepat, bukan awal dan melayang. Dua "
             "langkah terakhir yang membawamu di atas blok.",
    "ms-MY": "Mula larian lewat dan pantas. Dua langkah terakhir yang "
             "membawa anda mengatasi sekatan.",
    "th-TH": "เริ่มวิ่งเข้าช้าแต่เร็ว อย่าออกเร็วแล้วลอย สองก้าวสุดท้ายคือสิ่งที่พาคุณข้ามบล็อก",
    "vi-VN": "Chạy đà muộn và nhanh, đừng sớm rồi trôi. Hai bước cuối mới đưa "
             "bạn vượt trên hàng chắn.",
}


def attack_family() -> list[Drill]:
    """The four attacks a set can go to: outside, middle, opposite, pipe."""
    specs = [
        ("outside", "zone 4", (0.22, 0.62), (0.16, 0.80), (0.26, 0.53)),
        ("middle", "zone 3", (0.50, 0.60), (0.44, 0.72), (0.50, 0.52)),
        ("opposite", "zone 2", (0.78, 0.62), (0.86, 0.80), (0.74, 0.53)),
        # A back-row attacker takes off behind the attack line at y=0.667.
        # Drawn at 0.58 the arrow visibly crossed it — an illegal attack.
        ("pipe", "the pipe", (0.50, 0.92), (0.50, 0.80), (0.50, 0.685)),
    ]
    out = []
    for key, label, start, wind, hit in specs:
        out.append(Drill(
            id=f"vb_attack_{key}", category="finishing", minutes=12, rel=True,
            free=(key == "outside"),
            name=suffixed(ATTACK_NAME, label), note=ATTACK_NOTE,
            home=[
                P(*zone(1), "P", moves=[(0.72, 0.80, 0)]),
                P(*SET_POINT, "S", moves=[(SET_POINT[0] - 0.03, 0.535, 1)]),
                P(*start, "A", moves=[wind + (1,), hit + (2,)]),
            ],
            away=[
                P(hit[0] - 0.04, 1 - hit[1] - 0.02, "B",
                  moves=[(hit[0] - 0.03, 0.47, 2)]),
                P(hit[0] + 0.06, 1 - hit[1] - 0.02, "B",
                  moves=[(hit[0] + 0.04, 0.47, 2)]),
                P(*mirror(zone(6)), "D", moves=[(0.5, 0.14, 2)]),
            ],
            markers=[M(*SET_POINT, "square", "")],
            ball=0,
        ))
    return out


# ── blocking ─────────────────────────────────────────────────────────────────

BLOCK_NAME = {
    "en": "Block", "en-GB": "Block", "zh-CN": "拦网", "zh-TW": "攔網",
    "ja-JP": "ブロック", "ko-KR": "블로킹", "es-ES": "Bloqueo",
    "fr-FR": "Contre", "id-ID": "Blok", "ms-MY": "Sekatan",
    "th-TH": "การบล็อก", "vi-VN": "Chắn bóng",
}
BLOCK_NOTE = {
    "en": "Close the gap between hands before you close the gap to the "
          "hitter. A double block with daylight in it is two players wasted.",
    "en-GB": "Close the gap between hands before you close the gap to the "
             "hitter. A double block with daylight in it is two players wasted.",
    "zh-CN": "先并手，再靠人。中间漏光的双人拦网，等于白白站了两个人。",
    "zh-TW": "先併手，再靠人。中間漏光的雙人攔網，等於白白站了兩個人。",
    "ja-JP": "人に寄る前に手を閉じる。隙間の空いた2枚ブロックは2人の無駄遣い。",
    "ko-KR": "붙기 전에 손부터 모아라. 사이가 벌어진 2인 블로킹은 두 명을 버리는 것이다.",
    "es-ES": "Cierra el hueco entre manos antes que el hueco con el atacante: "
             "un bloqueo doble con luz son dos jugadoras desperdiciadas.",
    "fr-FR": "Ferme l'écart entre les mains avant l'écart avec l'attaquant : "
             "un double contre ajouré, ce sont deux joueuses gaspillées.",
    "id-ID": "Rapatkan tangan sebelum merapat ke penyerang. Blok ganda yang "
             "bercelah adalah dua pemain yang terbuang.",
    "ms-MY": "Rapatkan tangan sebelum merapat kepada penyerang.",
    "th-TH": "ปิดช่องระหว่างมือก่อนปิดช่องกับตัวตบ บล็อกคู่ที่มีแสงลอดคือเสียผู้เล่นสองคนเปล่า ๆ",
    "vi-VN": "Khép tay trước khi khép khoảng cách với chủ công. Hàng chắn đôi "
             "hở sáng là lãng phí hai người.",
}


SOLO_NOTE = {
    "en": "Take the line or take the angle and let the diggers have the rest. Reaching for both gives the hitter the seam between your own hands.",
    "en-GB": "Take the line or take the angle and let the diggers have the rest. Reaching for both gives the hitter the seam between your own hands.",
    "zh-CN": "要么封直线，要么封斜线，剩下的交给后排。两边都想够，等于把自己两手之间的缝送给了对方。",
    "zh-TW": "要麼封直線，要麼封斜線，剩下的交給後排。兩邊都想夠，等於把自己兩手之間的縫送給了對方。",
    "ja-JP": "ストレートか、クロスか、どちらかを止めて残りはレシーブに任せる。両方に手を伸ばせば、自分の両手の間のコースを与える。",
    "ko-KR": "라인이든 크로스든 하나를 막고 나머지는 수비에 맡겨라. 둘 다 잡으려 뻗으면 자기 두 손 사이를 내준다.",
    "es-ES": "Cierra la paralela o la diagonal y deja el resto a la defensa: intentar las dos regala la costura entre tus propias manos.",
    "fr-FR": "Prends la ligne ou la diagonale et laisse le reste aux défenseurs : vouloir les deux offre la fente entre tes propres mains.",
    "id-ID": "Tutup garis atau tutup diagonal, sisanya serahkan ke penggali bola. Mengejar keduanya memberi celah di antara tanganmu sendiri.",
    "ms-MY": "Tutup garisan atau tutup pepenjuru, selebihnya serahkan kepada pertahanan.",
    "th-TH": "ปิดเส้นหรือปิดทแยงอย่างใดอย่างหนึ่ง ที่เหลือปล่อยให้แนวรับ ถ้าเอื้อมทั้งสองทางคือยกช่องระหว่างมือตัวเองให้เขา",
    "vi-VN": "Chắn đường thẳng hoặc chắn đường chéo rồi để phần còn lại cho hàng dưới. Với cả hai là tự mở khe giữa hai bàn tay mình.",
}


def block_family() -> list[Drill]:
    # Nobody triple-blocks a first-tempo middle: there is no time to close
    # three, and committing the front row leaves two diggers for the court.
    # A triple goes up against a high ball at a pin.
    specs = [("solo", "solo", 1, 0.22), ("double_outside", "double outside", 2, 0.24),
             ("double_middle", "double middle", 2, 0.50), ("triple", "triple", 3, 0.30)]
    out = []
    for key, label, n, x in specs:
        blockers = [P(x + (i - (n - 1) / 2) * 0.10, 0.545, "B",
                      moves=[(x + (i - (n - 1) / 2) * 0.085, 0.53, 1)])
                    for i in range(n)]
        out.append(Drill(
            id=f"vb_block_{key}", category="defending", minutes=10, rel=True,
# Blockers press shoulder to shoulder — a gap between them is a seam.
tight=True,
            free=(key == "double_outside"),
            name=suffixed(BLOCK_NAME, label),
            # A solo block has no gap and no second blocker, so the family's
            # "close the gap between hands before the gap to the hitter" was
            # advice about a board it was not on.
            note=SOLO_NOTE if key == "solo" else BLOCK_NOTE,
            home=blockers + [
                P(0.5, 0.92, "D", moves=[(0.5, 0.84, 1)]),
                P(0.82, 0.84, "D", moves=[(0.86, 0.78, 1)]),
            ],
            away=[
                P(*mirror(SET_POINT), "S"),
                P(x, 1 - 0.62, "A", moves=[(x, 0.30, 0), (x, 0.455, 1)]),
            ],
            ball=mirror(SET_POINT),
        ))
    return out


# ── floor defence systems ────────────────────────────────────────────────────

DEFENSE_NAME = {
    "en": "Defence", "en-GB": "Defence", "zh-CN": "防守阵型", "zh-TW": "防守陣型",
    "ja-JP": "ディフェンス", "ko-KR": "수비 시스템", "es-ES": "Defensa",
    "fr-FR": "Défense", "id-ID": "Pertahanan", "ms-MY": "Pertahanan",
    "th-TH": "ระบบรับ", "vi-VN": "Phòng thủ",
}
DEFENSE_NOTE = {
    "en": "Be stopped and low before the hitter's hand moves. A defender still "
          "walking when contact happens is a spectator.",
    "en-GB": "Be stopped and low before the hitter's hand moves. A defender "
             "still walking when contact happens is a spectator.",
    "zh-CN": "对方挥臂之前就要停住、压低。击球那一刻还在挪步的防守队员，只是个观众。",
    "zh-TW": "對方揮臂之前就要停住、壓低。擊球那一刻還在挪步的防守隊員，只是個觀眾。",
    "ja-JP": "相手の腕が動く前に止まって低く。ヒットの瞬間に歩いている選手は観客だ。",
    "ko-KR": "공격수 팔이 나오기 전에 멈추고 낮춰라. 임팩트 순간에 걷고 있으면 관중이다.",
    "es-ES": "Parado y bajo antes de que se mueva la mano del atacante: quien "
             "aún camina en el contacto es público.",
    "fr-FR": "Arrêté et bas avant que la main de l'attaquant parte : un "
             "défenseur encore en marche au contact est un spectateur.",
    "id-ID": "Berhenti dan rendah sebelum tangan penyerang bergerak.",
    "ms-MY": "Berhenti dan rendah sebelum tangan penyerang bergerak.",
    "th-TH": "หยุดและย่อตัวก่อนที่มือตัวตบจะขยับ คนที่ยังเดินตอนปะทะคือคนดู",
    "vi-VN": "Đứng vững và hạ thấp trước khi tay chủ công vung. Ai còn bước "
             "lúc chạm bóng chỉ là khán giả.",
}


def defense_family() -> list[Drill]:
    """Perimeter, rotation and man-up — where the tip falls decides which."""
    specs = [
        # The fourth defender in each is the off-blocker — the front-row
        # player who did not go up — and he plays the open side. Perimeter
        # had him tucked behind his own double block, where nothing arrives,
        # and man-up had a fourth deep defender instead of him, leaving the
        # whole cross-court angle unmanned.
        ("perimeter", "perimeter",
         [(0.16, 0.86), (0.50, 0.94), (0.84, 0.86), (0.70, 0.68)]),
        ("rotation", "rotation",
         [(0.14, 0.74), (0.42, 0.92), (0.80, 0.88), (0.66, 0.68)]),
        ("man_up", "man-up",
         [(0.40, 0.62), (0.16, 0.86), (0.86, 0.84), (0.70, 0.68)]),
    ]
    out = []
    for key, label, spots in specs:
        out.append(Drill(
            id=f"vb_defense_{key}", category="defending", minutes=12, rel=True,
            free=(key == "perimeter"),
            name=suffixed(DEFENSE_NAME, label), note=DEFENSE_NOTE,
            home=[P(0.26, 0.545, "B", moves=[(0.26, 0.53, 1)]),
                  P(0.38, 0.545, "B", moves=[(0.36, 0.53, 1)])] + [
                P(x, y, "D", moves=[(x + (0.5 - x) * 0.12, y - 0.05, 1)])
                for x, y in spots
            ],
            away=[
                P(*mirror(SET_POINT), "S"),
                P(0.26, 0.38, "A", moves=[(0.26, 0.455, 1)]),
            ],
            ball=mirror(SET_POINT),
        ))
    return out


# ── serving ──────────────────────────────────────────────────────────────────

SERVE_NAME = {
    "en": "Serve", "en-GB": "Serve", "zh-CN": "发球", "zh-TW": "發球",
    "ja-JP": "サーブ", "ko-KR": "서브", "es-ES": "Saque", "fr-FR": "Service",
    "id-ID": "Servis", "ms-MY": "Servis", "th-TH": "การเสิร์ฟ", "vi-VN": "Giao bóng",
}
SERVE_NOTE = {
    "en": "Serve at a person or at a line, never at the middle of the court. "
          "A safe serve is a free pass and a free pass is a kill.",
    "en-GB": "Serve at a person or at a line, never at the middle of the "
             "court. A safe serve is a free pass and a free pass is a kill.",
    "zh-CN": "要么发人，要么发线，绝不要发到场地中间。保守的发球等于送对方一次好接，好接就是一次扣死。",
    "zh-TW": "要麼發人，要麼發線，絕不要發到場地中間。保守的發球等於送對方一次好接，好接就是一次扣死。",
    "ja-JP": "人を狙うかラインを狙う。コート中央は絶対に狙わない。無難なサーブは相手に楽なパスを与え、それは決定打になる。",
    "ko-KR": "사람을 노리거나 라인을 노려라. 코트 한가운데는 절대 아니다. 안전한 서브는 상대에게 편한 리시브를 주는 것이다.",
    "es-ES": "Saca a una persona o a una línea, nunca al centro: un saque "
             "cómodo es una recepción regalada, y eso es un punto en contra.",
    "fr-FR": "Sers sur un joueur ou sur une ligne, jamais au milieu : un "
             "service sûr offre une réception facile, donc un point.",
    "id-ID": "Servis ke orang atau ke garis, jangan ke tengah lapangan.",
    "ms-MY": "Servis kepada seseorang atau ke garisan, bukan ke tengah gelanggang.",
    "th-TH": "เสิร์ฟใส่คนหรือใส่เส้น อย่าเสิร์ฟกลางคอร์ท เสิร์ฟปลอดภัยคือการยกให้เขาตบ",
    "vi-VN": "Giao vào người hoặc vào vạch, đừng vào giữa sân.",
}


def serve_family() -> list[Drill]:
    specs = [("float_deep", "float deep", (0.50, 0.06), (0.50, 0.04)),
             ("jump", "jump", (0.50, 0.06), (0.30, 0.10)),
             ("short", "short", (0.35, 0.06), (0.72, 0.42)),
             ("seam", "at the seam", (0.65, 0.06), (0.33, 0.22))]
    out = []
    for key, label, start, target in specs:
        out.append(Drill(
            id=f"vb_serve_{key}", category="setpiece", minutes=8, rel=True,
            free=(key == "float_deep"), off_surface=True,
            name=suffixed(SERVE_NAME, label), note=SERVE_NOTE,
            home=[P(start[0], 1.04, "S",
                    moves=[(start[0], 0.98, 0), (start[0], 1.02, 1)])],
            away=[
                P(0.22, 0.24, "P", moves=[(0.26, 0.28, 1)]),
                P(0.50, 0.14, "P", moves=[(0.48, 0.20, 1)]),
                P(0.76, 0.24, "P", moves=[(0.72, 0.28, 1)]),
            ],
            markers=[M(target[0], 1 - target[1] if target[1] > 0.5 else target[1],
                       "zone", "")],
            ball=0,
        ))
    return out


# ── setter transition ────────────────────────────────────────────────────────

SETTER_NAME = {
    "en": "Setter release from", "en-GB": "Setter release from",
    "zh-CN": "二传插上", "zh-TW": "二傳插上", "ja-JP": "セッター アップ",
    "ko-KR": "세터 침투", "es-ES": "Penetración del colocador desde",
    "fr-FR": "Pénétration du passeur depuis", "id-ID": "Penetrasi tosser dari",
    "ms-MY": "Penetrasi pengangkat dari", "th-TH": "เซตเตอร์วิ่งขึ้นจาก",
    "vi-VN": "Chuyền hai lên từ",
}
SETTER_NOTE = {
    "en": "Get to the target and stop. A setter arriving on the move sets the "
          "ball wherever their momentum was going, not where the hitter is.",
    "en-GB": "Get to the target and stop. A setter arriving on the move sets "
             "the ball wherever their momentum was going, not where the hitter is.",
    "zh-CN": "跑到位置就停住。带着惯性到位的二传，球会传向他冲的方向，而不是攻手所在的位置。",
    "zh-TW": "跑到位置就停住。帶著慣性到位的二傳，球會傳向他衝的方向，而不是攻手所在的位置。",
    "ja-JP": "定位置に入って止まる。動きながら上げるセッターは、攻撃者ではなく勢いの方向へ配球してしまう。",
    "ko-KR": "자리에 가서 멈춰라. 움직이며 올리는 세터는 공격수가 아니라 관성이 향한 곳으로 토스한다.",
    "es-ES": "Llega al objetivo y párate: un colocador en movimiento coloca "
             "hacia donde iba su inercia, no hacia el atacante.",
    "fr-FR": "Arrive à la cible et arrête-toi : un passeur en mouvement passe "
             "là où allait son élan, pas là où est l'attaquant.",
    "id-ID": "Sampai ke target lalu berhenti.",
    "ms-MY": "Sampai ke sasaran dan berhenti.",
    "th-TH": "วิ่งถึงจุดแล้วหยุด เซตเตอร์ที่เซตขณะเคลื่อนที่จะส่งบอลไปตามแรงเฉื่อย ไม่ใช่ไปหาตัวตบ",
    "vi-VN": "Đến vị trí rồi dừng lại.",
}


def setter_family() -> list[Drill]:
    out = []
    for z in (1, 6, 5):
        x, y = zone(z)
        out.append(Drill(
            id=f"vb_setter_z{z}", category="attacking", minutes=10, rel=True,
            free=(z == 1),
            name=suffixed(SETTER_NAME, f"zone {z}"), note=SETTER_NOTE,
            home=[
                P(x, y, "S", moves=[(SET_POINT[0], SET_POINT[1] + 0.03, 0),
                                    SET_POINT + (1,)]),
                P(0.30, 0.80, "P", moves=[(0.34, 0.74, 0)]),
                P(0.22, 0.62, "A", moves=[(0.16, 0.80, 1), (0.26, 0.53, 2)]),
                P(0.50, 0.60, "M", moves=[(0.46, 0.68, 1), (0.50, 0.52, 2)]),
            ],
            away=[P(0.30, 0.455, "B", moves=[(0.26, 0.47, 2)])],
            markers=[M(*SET_POINT, "square", "")],
            ball=1,
        ))
    return out


# ── warm-up ──────────────────────────────────────────────────────────────────

WARM_NAME = {
    "en": "Warm-up", "en-GB": "Warm-up", "zh-CN": "热身", "zh-TW": "熱身",
    "ja-JP": "ウォームアップ", "ko-KR": "웜업", "es-ES": "Calentamiento",
    "fr-FR": "Échauffement", "id-ID": "Pemanasan", "ms-MY": "Memanaskan badan",
    "th-TH": "วอร์มอัพ", "vi-VN": "Khởi động",
}
WARM_NOTE = {
    "en": "Every contact has a target. Warming up without one is just moving "
          "a ball around until practice starts.",
    "en-GB": "Every contact has a target. Warming up without one is just "
             "moving a ball around until practice starts.",
    "zh-CN": "每一次触球都要有目标。没有目标的热身，只是在等训练开始之前把球颠来颠去。",
    "zh-TW": "每一次觸球都要有目標。沒有目標的熱身，只是在等訓練開始之前把球顛來顛去。",
    "ja-JP": "1本ごとに狙いを持つ。狙いのないウォームアップは、練習が始まるまでボールを転がしているだけ。",
    "ko-KR": "모든 터치에 목표가 있어야 한다. 목표 없는 웜업은 훈련 시작 전 공놀이일 뿐이다.",
    "es-ES": "Cada contacto tiene un objetivo; sin él, solo mueves el balón "
             "hasta que empiece el entrenamiento.",
    "fr-FR": "Chaque touche a une cible. Sans cible, on déplace un ballon en "
             "attendant que l'entraînement commence.",
    "id-ID": "Setiap sentuhan punya target.",
    "ms-MY": "Setiap sentuhan ada sasaran.",
    "th-TH": "ทุกการสัมผัสบอลต้องมีเป้าหมาย",
    "vi-VN": "Mỗi lần chạm bóng đều có mục tiêu.",
}


def warmup_family() -> list[Drill]:
    specs = [("pepper", "pepper"), ("butterfly", "butterfly passing"),
             ("dig_shuffle", "shuffle and dig")]
    out = []
    for i, (key, label) in enumerate(specs):
        if key == "pepper":
            home = [P(0.34, 0.80, "1", moves=[(0.38, 0.74, 0), (0.34, 0.80, 1)]),
                    P(0.66, 0.80, "2", moves=[(0.62, 0.74, 0), (0.66, 0.80, 1)])]
            away = []
        elif key == "butterfly":
            home = [P(0.22, 0.86, "1", moves=[(0.50, 0.80, 0)]),
                    P(0.50, 0.68, "2", moves=[(0.78, 0.62, 0)]),
                    P(0.78, 0.86, "3", moves=[(0.22, 0.86, 1)])]
            away = [P(0.50, 0.24, "4", moves=[(0.26, 0.30, 0)])]
        else:
            home = [P(0.20, 0.88, "1", moves=[(0.44, 0.84, 0), (0.20, 0.88, 1)]),
                    P(0.80, 0.88, "2", moves=[(0.56, 0.84, 0), (0.80, 0.88, 1)])]
            away = [P(0.50, 0.30, "C", moves=[(0.50, 0.36, 0)])]
        out.append(Drill(
            id=f"vb_warm_{key}", category="warmup", minutes=8, rel=True,
            free=(key == "pepper"),
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            home=home, away=away, ball=0,
        ))
    return out


# ── free ball and down ball ──────────────────────────────────────────────────

FREEBALL_NAME = {
    "en": "Transition off a", "en-GB": "Transition off a",
    "zh-CN": "转换进攻", "zh-TW": "轉換進攻", "ja-JP": "切り返し",
    "ko-KR": "전환 공격", "es-ES": "Transición tras", "fr-FR": "Transition sur",
    "id-ID": "Transisi dari", "ms-MY": "Peralihan daripada",
    "th-TH": "การเปลี่ยนเกมจาก", "vi-VN": "Chuyển đổi từ",
}
FREEBALL_NOTE = {
    "en": "A free ball is the easiest point in volleyball and the one most "
          "often dropped, because everybody relaxes at the same moment.",
    "en-GB": "A free ball is the easiest point in volleyball and the one most "
             "often dropped, because everybody relaxes at the same moment.",
    "zh-CN": "调整球是排球里最容易得的一分，也是丢得最多的一分——因为所有人在同一瞬间松了劲。",
    "zh-TW": "調整球是排球裡最容易得的一分，也是丟得最多的一分——因為所有人在同一瞬間鬆了勁。",
    "ja-JP": "フリーボールはバレーで最も簡単な1点であり、最も落とす1点でもある。全員が同時に緩むからだ。",
    "ko-KR": "프리볼은 배구에서 가장 쉬운 1점이자 가장 자주 놓치는 1점이다. 모두가 동시에 풀어지기 때문이다.",
    "es-ES": "Un balón libre es el punto más fácil del voleibol y el que más "
             "se falla, porque todos se relajan a la vez.",
    "fr-FR": "Une balle libre est le point le plus facile du volley et le plus "
             "souvent perdu : tout le monde relâche en même temps.",
    "id-ID": "Bola bebas adalah poin termudah sekaligus paling sering hilang.",
    "ms-MY": "Bola bebas ialah mata termudah dan paling kerap hilang.",
    "th-TH": "ฟรีบอลคือแต้มที่ง่ายที่สุดและเสียบ่อยที่สุด เพราะทุกคนผ่อนพร้อมกัน",
    "vi-VN": "Bóng tự do là điểm dễ nhất và cũng hay mất nhất.",
}


def freeball_family() -> list[Drill]:
    specs = [("free_ball", "a free ball", 0.30), ("down_ball", "a down ball", 0.42)]
    out = []
    for key, label, ay in specs:
        out.append(Drill(
            id=f"vb_{key}", category="attacking", minutes=10, rel=True,
            free=(key == "free_ball"),
            name=suffixed(FREEBALL_NAME, label), note=FREEBALL_NOTE,
            home=[
                P(0.26, 0.545, "B", moves=[(0.24, 0.66, 0)]),
                P(0.50, 0.545, "M", moves=[(0.46, 0.70, 0), (0.50, 0.52, 2)]),
                P(0.72, 0.72, "S", moves=[SET_POINT + (1,)]),
                P(0.22, 0.80, "P", moves=[(0.20, 0.74, 0), (0.26, 0.53, 2)]),
                P(0.62, 0.90, "D", moves=[(0.56, 0.84, 0)]),
            ],
            away=[P(0.50, ay, "A", moves=[(0.50, ay + 0.06, 0)])],
            markers=[M(*SET_POINT, "square", "")],
            ball=(0.50, ay),
        ))
    return out


# ── setting technique ────────────────────────────────────────────────────────

SET_NAME = {
    "en": "Setting", "en-GB": "Setting", "zh-CN": "二传技术", "zh-TW": "二傳技術",
    "ja-JP": "トス", "ko-KR": "토스", "es-ES": "Colocación",
    "fr-FR": "Passe haute", "id-ID": "Umpan", "ms-MY": "Umpanan",
    "th-TH": "การเซต", "vi-VN": "Chuyền hai",
}
SET_NOTE = {
    "en": "Square the hips to the target, not the shoulders. Hands can lie "
          "about where a set is going; hips cannot.",
    "en-GB": "Square the hips to the target, not the shoulders. Hands can lie "
             "about where a set is going; hips cannot.",
    "zh-CN": "把胯正对目标，不是肩。手可以骗人，胯骗不了人。",
    "zh-TW": "把胯正對目標，不是肩。手可以騙人，胯騙不了人。",
    "ja-JP": "肩ではなく腰をターゲットに向ける。手は嘘をつけるが腰は嘘をつけない。",
    "ko-KR": "어깨가 아니라 골반을 목표로 향하게 하라. 손은 속일 수 있어도 골반은 못 속인다.",
    "es-ES": "Cuadra las caderas al objetivo, no los hombros: las manos "
             "mienten sobre el destino, las caderas no.",
    "fr-FR": "Aligne les hanches sur la cible, pas les épaules : les mains "
             "peuvent mentir sur la destination, les hanches non.",
    "id-ID": "Arahkan pinggul ke target, bukan bahu.",
    "ms-MY": "Hadapkan pinggul ke sasaran, bukan bahu.",
    "th-TH": "หันสะโพกไปหาเป้าหมาย ไม่ใช่ไหล่ มือโกหกได้ แต่สะโพกโกหกไม่ได้",
    "vi-VN": "Hướng hông về mục tiêu, không phải vai.",
}


def setting_family() -> list[Drill]:
    specs = [("front", "front set", (0.24, 0.55)), ("back", "back set", (0.88, 0.57)),
             ("jump", "jump set", (0.50, 0.52))]
    out = []
    for key, label, target in specs:
        out.append(Drill(
            id=f"vb_set_{key}", category="possession", minutes=8, rel=True,
            free=(key == "front"),
            name=suffixed(SET_NAME, label), note=SET_NOTE,
            home=[
                P(0.50, 0.86, "P", moves=[(0.54, 0.78, 0)]),
                P(*SET_POINT, "S", moves=[(SET_POINT[0] - 0.02, 0.535, 1)]),
                P(target[0], target[1] + 0.16, "A",
                  moves=[target + (2,)]),
            ],
            markers=[M(*target, "square", "")],
            ball=0,
        ))
    return out


# ── conditioned games ────────────────────────────────────────────────────────

GAME_NAME = {
    "en": "Game", "en-GB": "Game", "zh-CN": "对抗", "zh-TW": "對抗",
    "ja-JP": "ゲーム", "ko-KR": "게임", "es-ES": "Juego", "fr-FR": "Jeu",
    "id-ID": "Permainan", "ms-MY": "Permainan", "th-TH": "เกม", "vi-VN": "Trận đấu",
}
GAME_NOTE = {
    "en": "Score it. A conditioned game without a score is a rally, and a "
          "rally teaches nobody to win the point that matters.",
    "en-GB": "Score it. A conditioned game without a score is a rally, and a "
             "rally teaches nobody to win the point that matters.",
    "zh-CN": "一定要计分。不计分的限制性比赛只是来回球，而来回球教不会任何人赢下关键分。",
    "zh-TW": "一定要計分。不計分的限制性比賽只是來回球，而來回球教不會任何人贏下關鍵分。",
    "ja-JP": "必ず点数をつける。得点のない条件付きゲームはただのラリーで、勝負どころは学べない。",
    "ko-KR": "점수를 매겨라. 점수 없는 조건 게임은 그냥 랠리이고, 랠리로는 중요한 점수를 이기는 법을 못 배운다.",
    "es-ES": "Ponle marcador: un juego condicionado sin puntos es un peloteo, "
             "y un peloteo no enseña a ganar el punto que importa.",
    "fr-FR": "Compte les points : un jeu à thème sans score n'est qu'un "
             "échange, et un échange n'apprend pas à gagner le point décisif.",
    "id-ID": "Beri skor. Permainan tanpa skor hanyalah reli.",
    "ms-MY": "Beri mata. Permainan tanpa mata hanyalah rali.",
    "th-TH": "ต้องนับแต้ม เกมมีเงื่อนไขที่ไม่นับแต้มก็แค่การโต้บอล",
    "vi-VN": "Phải tính điểm. Trò chơi có điều kiện mà không tính điểm chỉ là đôi công.",
}


def game_family() -> list[Drill]:
    """2v2 up to 6v6 — the whole court every time, fewer bodies to cover it."""
    layouts = {
        2: [(0.32, 0.70), (0.66, 0.88)],
        3: [(0.26, 0.66), (0.72, 0.68), (0.50, 0.90)],
        4: [(0.24, 0.64), (0.70, 0.64), (0.34, 0.88), (0.74, 0.88)],
        6: [Z[4], Z[3], Z[2], Z[5], Z[6], Z[1]],
    }
    out = []
    for n, spots in layouts.items():
        out.append(Drill(
            id=f"vb_game_{n}v{n}", category="ssg", minutes=15 if n < 6 else 20,
            rel=True, free=(n == 4),
            name=suffixed(GAME_NAME, f"{n}v{n}"), note=GAME_NOTE,
            home=[P(x, y, f"{i + 1}", moves=[(x + (0.5 - x) * 0.14, y - 0.05, 0)])
                  for i, (x, y) in enumerate(spots)],
            away=[P(*mirror((x, y)), chr(65 + i),
                    moves=[(x + (0.5 - x) * 0.14, 1 - y + 0.05, 0)])
                  for i, (x, y) in enumerate(spots)],
            ball=0,
        ))
    return out


COVER_NAME = {"en": "Hitter coverage", "en-GB": "Hitter coverage",
              "zh-CN": "扣球掩护", "zh-TW": "扣球掩護", "ja-JP": "スパイクカバー",
              "ko-KR": "공격 커버", "es-ES": "Cobertura del atacante",
              "fr-FR": "Couverture de l'attaquant", "id-ID": "Cover pemukul",
              "ms-MY": "Perlindungan pemukul", "th-TH": "การคุ้มกันตัวตบ",
              "vi-VN": "Bọc lót cho chủ công"}
COVER_NOTE = {
    "en": "Three low and close around your own hitter before he lands. The ball off the block falls inside three metres, and nobody digs it standing up.",
    "en-GB": "Three low and close around your own hitter before he lands. The ball off the block falls inside three metres, and nobody digs it standing up.",
    "zh-CN": "在自己扣球手落地之前，三个人压低重心围到他身边。被拦回来的球落点都在三米以内，站着的人一个也救不起来。",
    "zh-TW": "在自己扣球手落地之前，三個人壓低重心圍到他身邊。被攔回來的球落點都在三米以內，站著的人一個也救不起來。",
    "ja-JP": "スパイカーが着地する前に3人が低く近く囲む。ブロックに当たった球は3m以内に落ち、棒立ちでは誰も上げられない。",
    "ko-KR": "공격수가 착지하기 전에 세 명이 낮게 가까이 붙어라. 블로킹에 맞은 공은 3미터 안에 떨어지고, 서 있는 사람은 못 올린다.",
    "es-ES": "Tres bajos y cerca del propio atacante antes de que caiga. El balón del bloqueo cae dentro de tres metros y nadie lo levanta de pie.",
    "fr-FR": "Trois joueurs bas et proches de votre attaquant avant qu'il retombe. Le ballon repoussé tombe à moins de trois mètres, et personne ne le relève debout.",
    "id-ID": "Tiga orang rendah dan dekat di sekitar pemukul sendiri sebelum ia mendarat. Bola dari blok jatuh dalam tiga meter.",
    "ms-MY": "Tiga orang rendah dan rapat di sekeliling pemukul sendiri sebelum dia mendarat.",
    "th-TH": "สามคนย่อตัวต่ำและเข้าใกล้ตัวตบของเราก่อนเขาลงพื้น บอลที่กระดอนจากบล็อกตกในระยะสามเมตร",
    "vi-VN": "Ba người hạ thấp và áp sát chủ công của mình trước khi anh ta tiếp đất. Bóng bật chắn rơi trong ba mét.",
}
TEMPO_NAME = {"en": "First tempo", "en-GB": "First tempo", "zh-CN": "快球",
              "zh-TW": "快球", "ja-JP": "速攻", "ko-KR": "속공",
              "es-ES": "Primer tiempo", "fr-FR": "Premier temps",
              "id-ID": "Bola cepat", "ms-MY": "Bola pantas",
              "th-TH": "บอลเร็ว", "vi-VN": "Bóng nhanh"}
TEMPO_NOTE = {
    "en": "The middle jumps before the set, not after it. If the setter has to wait for him the block has already read the whole play.",
    "en-GB": "The middle jumps before the set, not after it. If the setter has to wait for him the block has already read the whole play.",
    "zh-CN": "副攻在传球之前起跳，不是之后。二传要等他，说明对方拦网已经把整套球都读完了。",
    "zh-TW": "副攻在傳球之前起跳，不是之後。二傳要等他，說明對方攔網已經把整套球都讀完了。",
    "ja-JP": "ミドルはトスの前に跳ぶ、後ではない。セッターが待たされる時点で、ブロックは全部読み終えている。",
    "ko-KR": "미들은 토스 전에 뛴다, 후가 아니라. 세터가 기다려야 한다면 블로킹은 이미 다 읽었다.",
    "es-ES": "El central salta antes del pase, no después. Si el colocador tiene que esperarlo, el bloqueo ya ha leído toda la jugada.",
    "fr-FR": "Le central saute avant la passe, pas après. Si le passeur doit l'attendre, le contre a déjà tout lu.",
    "id-ID": "Middle melompat sebelum umpan, bukan sesudah. Jika tosser harus menunggunya, blok sudah membaca seluruh permainan.",
    "ms-MY": "Pemain tengah melompat sebelum umpan, bukan selepas.",
    "th-TH": "ตัวกลางกระโดดก่อนเซ็ต ไม่ใช่หลังเซ็ต ถ้าตัวเซ็ตต้องรอ แปลว่าบล็อกอ่านเกมออกหมดแล้ว",
    "vi-VN": "Phụ công bật trước khi chuyền hai, không phải sau. Nếu chuyền hai phải chờ thì hàng chắn đã đọc hết bài.",
}
LIBERO_NAME = {"en": "Libero", "en-GB": "Libero", "zh-CN": "自由人",
               "zh-TW": "自由人", "ja-JP": "リベロ", "ko-KR": "리베로",
               "es-ES": "Líbero", "fr-FR": "Libéro", "id-ID": "Libero",
               "ms-MY": "Libero", "th-TH": "ลิเบโร", "vi-VN": "Libero"}
LIBERO_NOTE = {
    "en": "Two passers means the libero owns everything to his left and calls the seam early. Silence in a two-passer system is a service ace waiting to happen.",
    "en-GB": "Two passers means the libero owns everything to his left and calls the seam early. Silence in a two-passer system is a service ace waiting to happen.",
    "zh-CN": "两人接发意味着自由人负责他左边的全部区域，并且要早喊结合部。两人接发里的沉默，就是一个还没发生的发球得分。",
    "zh-TW": "兩人接發意味著自由人負責他左邊的全部區域，並且要早喊結合部。兩人接發裡的沉默，就是一個還沒發生的發球得分。",
    "ja-JP": "2人レセプションではリベロが自分の左側すべてを持ち、継ぎ目は早くコールする。2人でだまっているのは、これから起きるサービスエースだ。",
    "ko-KR": "2인 리시브는 리베로가 자기 왼쪽 전부를 맡고 이음새를 미리 콜한다는 뜻이다. 침묵은 곧 서브 에이스다.",
    "es-ES": "Con dos receptores el líbero se hace cargo de todo lo que tiene a su izquierda y canta la costura pronto. El silencio es un ace en camino.",
    "fr-FR": "À deux réceptionneurs, le libéro prend tout ce qui est à sa gauche et annonce la fente tôt. Le silence est un ace en préparation.",
    "id-ID": "Dua penerima berarti libero menguasai semua yang ada di kirinya dan menyerukan celah lebih awal.",
    "ms-MY": "Dua penerima bermakna libero menguasai semua di sebelah kirinya dan menyeru celah lebih awal.",
    "th-TH": "รับสองคนหมายความว่าลิเบโรดูแลทุกอย่างทางซ้ายของเขา และต้องขานรอยต่อแต่เนิ่น",
    "vi-VN": "Đỡ hai người nghĩa là libero ôm toàn bộ phía bên trái và gọi khe sớm.",
}
DUMP_NOTE = {
    "en": "Dump on the second ball only when the block is already moving with your hands. A dump telegraphed by a look is the easiest point the other side will get.",
    "en-GB": "Dump on the second ball only when the block is already moving with your hands. A dump telegraphed by a look is the easiest point the other side will get.",
    "zh-CN": "只有在对方拦网已经跟着你的手动了的时候才二次球偷吊。用眼神暴露出来的偷吊，是对方拿分最轻松的一次。",
    "zh-TW": "只有在對方攔網已經跟著你的手動了的時候才二次球偷吊。用眼神暴露出來的偷吊，是對方拿分最輕鬆的一次。",
    "ja-JP": "ツーは、ブロックが自分の手に反応して動いている時だけ。目線で読まれたツーは相手にとって一番簡単な1点だ。",
    "ko-KR": "블로킹이 이미 내 손을 따라 움직일 때만 세터 다이렉트를 쓴다. 눈빛으로 들킨 다이렉트는 가장 쉬운 실점이다.",
    "es-ES": "Finta en el segundo toque solo cuando el bloqueo ya se mueve con tus manos. Una finta anunciada con la mirada es el punto más fácil del rival.",
    "fr-FR": "Ne feinte au deuxième ballon que si le contre suit déjà tes mains. Une feinte annoncée par le regard est le point le plus facile pour l'adversaire.",
    "id-ID": "Dump di bola kedua hanya ketika blok sudah bergerak mengikuti tanganmu.",
    "ms-MY": "Dump pada bola kedua hanya apabila blok sudah bergerak mengikut tangan anda.",
    "th-TH": "หยอดลูกที่สองเฉพาะตอนที่บล็อกขยับตามมือคุณแล้วเท่านั้น",
    "vi-VN": "Chỉ bỏ nhỏ ở nhịp hai khi hàng chắn đã di chuyển theo tay bạn.",
}


def gaps_family() -> list[Drill]:
    """Coverage, tempo, the libero and the setter dump.

    Seven blocking and defence boards and not one on covering your own
    hitter; six serve-receive rotations and no libero, no two-passer
    pattern; four attacks and no first tempo, no slide, no second-ball
    attack. All verified absent from every name and note.
    """
    return [
        Drill(
            id="vb_cover_hitter", category="defending", minutes=10, rel=True,
            free=True, level="foundation",
            name=suffixed(COVER_NAME, "around the outside hitter"),
            note=COVER_NOTE,
            home=[P(0.22, 0.62, "A", moves=[(0.18, 0.575, 1)]),
                  P(*SET_POINT, "S", moves=[(0.44, 0.62, 1)]),
                  P(0.34, 0.70, "C", moves=[(0.28, 0.655, 1)]),
                  P(0.20, 0.86, "C", moves=[(0.235, 0.735, 1)]),
                  P(0.52, 0.92, "C", moves=[(0.42, 0.79, 1)])],
            away=[P(0.20, 0.455, "B"), P(0.32, 0.455, "B")],
            markers=[M(0.26, 0.70, "zone", "")],
            ball=0,
        ),
        Drill(
            id="vb_attack_quick", category="finishing", minutes=12, rel=True,
            name=suffixed(TEMPO_NAME, "the quick in front"), note=TEMPO_NOTE,
            home=[P(*zone(1), "P", moves=[(0.72, 0.80, 0)]),
                  P(*SET_POINT, "S", moves=[(0.62, 0.545, 1)]),
                  P(0.50, 0.62, "M", moves=[(0.56, 0.575, 0), (0.58, 0.545, 1)])],
            away=[P(0.54, 0.455, "B", moves=[(0.58, 0.47, 2)]),
                  P(*mirror(zone(6)), "D")],
            markers=[M(*SET_POINT, "square", "")],
            ball=0,
        ),
        Drill(
            id="vb_attack_slide", category="finishing", minutes=12, rel=True,
            level="advanced",
            name=suffixed(TEMPO_NAME, "the slide behind the setter"),
            note=TEMPO_NOTE,
            home=[P(*zone(1), "P", moves=[(0.72, 0.80, 0)]),
                  P(*SET_POINT, "S", moves=[(0.62, 0.545, 1)]),
                  P(0.46, 0.64, "M", moves=[(0.62, 0.60, 0), (0.80, 0.555, 1)])],
            away=[P(0.24, 0.455, "B", moves=[(0.18, 0.47, 2)]),
                  P(*mirror(zone(6)), "D")],
            markers=[M(*SET_POINT, "square", "")],
            ball=0,
        ),
        Drill(
            id="vb_receive_two_passer", category="possession", minutes=12, rel=True,
            free=True, level="advanced",
            name=suffixed(LIBERO_NAME, "in a two-passer receive"), note=LIBERO_NOTE,
            home=[P(0.34, 0.84, "L", moves=[(0.42, 0.78, 1)]),
                  P(0.74, 0.82, "P", moves=[(0.68, 0.76, 1)]),
                  P(*SET_POINT, "S", moves=[(0.60, 0.555, 1)]),
                  P(0.22, 0.62, "H"), P(0.50, 0.60, "M"), P(0.78, 0.62, "H")],
            away=[P(0.50, 0.06, "SV", moves=[(0.46, 0.115, 0)])],
            markers=[M(*SET_POINT, "square", "")],
            ball=3,
        ),
        Drill(
            id="vb_setter_dump", category="attacking", minutes=8, rel=True,
            level="foundation",
            name=suffixed(SETTER_NAME, "the second-ball dump"), note=DUMP_NOTE,
            home=[P(0.20, 0.84, "P", moves=[(0.28, 0.76, 0)]),
                  P(*SET_POINT, "S", moves=[(0.62, 0.545, 1), (0.56, 0.525, 2)]),
                  P(0.22, 0.62, "H", moves=[(0.18, 0.575, 2)])],
            away=[P(0.26, 0.455, "B", moves=[(0.20, 0.47, 2)]),
                  P(0.42, 0.455, "B", moves=[(0.36, 0.47, 2)]),
                  P(*mirror(zone(6)), "D")],
            markers=[M(0.62, 0.40, "zone", "")],
            ball=0,
        ),
    ]


def volleyball_library() -> list[Drill]:
    return (warmup_family() + receive_family() + setting_family()
            + setter_family() + freeball_family() + attack_family()
            + block_family() + defense_family() + serve_family()
            + game_family() + gaps_family())
