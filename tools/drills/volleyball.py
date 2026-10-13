"""The volleyball library.

Volleyball is a rotation sport: the same six players solve a different problem
depending on where the rotation has left them, which is why serve receive is
generated per rotation rather than drawn once. The court is portrait with the
net across the middle at y=0.5; home defends the bottom half, and away is the
same shape mirrored through the net.
"""
from .engine import Drill, M, P, court_rect, figure_clear, suffixed

NET = 0.5

# The court in canvas units, for ball_spot below.
_L, _T, _W, _H = court_rect("volleyball")

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


def ball_spot(pt):
    """Where to author a point ball target so the ball is DRAWN at `pt`.

    resolve_ball puts every ball at_the_feet_of its target — offset by a
    ball's width, as if somebody were standing there — and does it for a bare
    (x, y) too. A landing spot written literally is therefore drawn short of
    itself, which on a volleyball court is the difference between a short
    serve and a ball on the net tape. These two numbers are the offset by
    eye, not engine.FEET_PT: they were tuned against the rendered boards.
    """
    x, y = pt
    ax = x - 40.0 / _W if x < 0.5 else x + 40.0 / _W
    return (ax, y - 70.0 / _H)


# The server stands behind the end line.
#
# A serve is struck from behind the line, and written as 0.04 of the court
# (0.72 m) the token sat half over it — the one thing a coach would correct
# on a board about serve receive. A figure is drawn centred on its point,
# half of it below: a near server 0.043 back has all of him behind his line,
# but a far one had his feet on it (0.4pt behind), because the margin outside
# the end line was 54pt of the 730 the board is drawn in, about one figure.
# The court is now drawn at 0.84 (engine.COURT), and the far server stands
# half a figure and 3pt of air past his line (FAR_BACK): feet behind it,
# head on the board.
SERVE_BACK = 0.043
FAR_BACK = -figure_clear("volleyball")
SERVE_SPOT = (0.5, FAR_BACK)

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
            away=[P(*SERVE_SPOT, "S", moves=[(0.5, 0.02, 0)])],
            markers=[M(*SET_POINT, "square", "")],
            ball=SERVE_SPOT,            # in the server's hand, behind the line
            # Serve, pass, set, hit: over the net to P1, up to the setter
            # releasing to the net, delivered to the hitter stepping in —
            # and put away into the far court. The side-out is the point.
            ball_to=[(1, 0), (0, 1), (len(home) - 1, 2), (ball_spot((0.34, 0.24)), 3)],
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
    """The four attacks a set can go to: outside, middle, opposite, pipe.

    A front-row hitter waits BEHIND the 3 m line and runs at the net while
    the set is in the air, contacting it about a metre off the tape — so the
    set travels along the net, not four metres backwards into the court, and
    the swing starts where a front-row swing starts. (It used to be drawn the
    other way round: A began at the net, backed off to the attack line, and
    the setter delivered the ball to the retreat.)
    """
    specs = [
        # key, label, where the approach starts, where the ball is contacted
        ("outside", "zone 4", (0.12, 0.76), (0.17, 0.555)),
        ("middle", "zone 3", (0.40, 0.74), (0.38, 0.555)),
        ("opposite", "zone 2", (0.90, 0.76), (0.86, 0.555)),
        # A back-row attacker takes off behind the attack line at y=0.667.
        # Drawn at 0.58 the arrow visibly crossed it — an illegal attack.
        ("pipe", "the pipe", (0.50, 0.92), (0.50, 0.70)),
    ]
    out = []
    for key, label, start, hit in specs:
        out.append(Drill(
            id=f"vb_attack_{key}", category="finishing", minutes=12, rel=True,
            free=(key == "outside"),
            name=suffixed(ATTACK_NAME, label), note=ATTACK_NOTE,
            home=[
                P(*zone(1), "P", moves=[(0.72, 0.80, 0)]),
                P(*SET_POINT, "S", moves=[(SET_POINT[0] - 0.03, 0.535, 1)]),
                P(*start, "A", moves=[hit + (1,)]),
            ],
            away=[
                # The block stands at the net from the first beat — blockers
                # do not start three metres off it — and only closes sideways
                # onto the hitter as the swing comes.
                P(hit[0] - 0.09, 0.465, "B",
                  moves=[(hit[0] - 0.065, 0.475, 2)]),
                P(hit[0] + 0.09, 0.465, "B",
                  moves=[(hit[0] + 0.065, 0.475, 2)]),
                P(*mirror(zone(6)), "D", moves=[(0.5, 0.14, 2)]),
            ],
            markers=[M(*SET_POINT, "square", "")],
            ball=0,
            # Pass to the setter, the set out to the hitter running in, the
            # swing across the net at their deep defender.
            ball_to=[(1, 0), (2, 1), ("a2", 2)],
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


# Where the coach feeds from: their back court, on the far side, so the ball
# comes up out of a dig the way a real rally starts. The drills that use it
# put a figure on the spot — a ball on an empty floor is a ball nobody fed.
FEED_SPOT = (0.62, 0.14)


def block_family() -> list[Drill]:
    # Nobody triple-blocks a first-tempo middle: there is no time to close
    # three, and committing the front row leaves two diggers for the court.
    # A triple goes up against a high ball at a pin.
    # x is where their hitter attacks. Kept out of the band either side of
    # the midline: a ball is drawn at its target's feet, offset toward the
    # middle, so a set from their setter to a hitter just across the middle
    # is drawn shorter than one token and reads as no set at all.
    specs = [("solo", "solo", 1, 0.20), ("double_outside", "double outside", 2, 0.24),
             ("double_middle", "double middle", 2, 0.62), ("triple", "triple", 3, 0.78)]
    out = []
    for key, label, n, x in specs:
        # Closing to a shoulder-to-shoulder wall, not to one point: three
        # blockers stacked on the same spot cannot be counted or read.
        blockers = [P(x + (i - (n - 1) / 2) * 0.14, 0.545, "B",
                      moves=[(x + (i - (n - 1) / 2) * 0.115, 0.53, 1)])
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
                P(0.38, 0.47, "S"),
                P(x, 0.32, "A", moves=[(x, 0.22, 0), (x, 0.44, 1)]),
                # Somebody has to be standing where the ball starts. The text
                # has always said the setter "takes the feed" and the feeder
                # "keeps the balls coming"; on the board the ball lay five
                # metres from the nearest body, which reads as a ball nobody
                # put there. Last in the list so a0 and a1 still name the
                # setter and the hitter.
                P(*FEED_SPOT, "C", coach=True),
            ],
            ball=FEED_SPOT,
            # Pass, set, and the swing into our floor defence — the ball the
            # block is timed against.
            ball_to=[("a0", 0), ("a1", 1), (n, 2)],
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
         [(0.42, 0.63), (0.16, 0.86), (0.86, 0.84), (0.70, 0.68)]),
    ]
    out = []
    for key, label, spots in specs:
        out.append(Drill(
            id=f"vb_defense_{key}", category="defending", minutes=12, rel=True,
            free=(key == "perimeter"),
            name=suffixed(DEFENSE_NAME, label), note=DEFENSE_NOTE,
            home=[P(0.21, 0.55, "B", moves=[(0.225, 0.53, 1)]),
                  P(0.36, 0.55, "B", moves=[(0.345, 0.53, 1)])] + [
                P(x, y, "D", moves=[(x + (0.5 - x) * 0.12, y - 0.05, 1)])
                for x, y in spots
            ],
            away=[
                P(0.40, 0.47, "S"),
                P(0.20, 0.34, "A", moves=[(0.20, 0.22, 0), (0.20, 0.44, 1)]),
                P(*FEED_SPOT, "C", coach=True),   # see block_family
            ],
            ball=FEED_SPOT,
            # Pass, set to the hitter running in, swing, and the dig in the
            # deep corner — where every one of these systems says the ball
            # must be kept off the floor.
            ball_to=[("a0", 0), ("a1", 1), (4, 2)],
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


# Where the three receivers stand, the same shape behind every serve.
SERVE_PASSERS = [(0.22, 0.24), (0.50, 0.18), (0.76, 0.24)]


def serve_family() -> list[Drill]:
    # (key, label, where the server stands, where the serve lands)
    specs = [("float_deep", "float deep", (0.50, 0.06), (0.50, 0.07)),
             ("jump", "jump", (0.50, 0.06), (0.26, 0.10)),
             ("short", "short", (0.35, 0.06), (0.72, 0.40)),
             ("seam", "at the seam", (0.65, 0.06), (0.33, 0.22)),
             # 2026-10: the spin serves and the two deep corners. Their
             # zone 1 is on our left as we serve, their zone 5 on our right.
             ("topspin", "with topspin", (0.50, 0.06), (0.76, 0.10)),
             ("jump_float", "jump float", (0.30, 0.06), (0.62, 0.16)),
             ("zone1", "to zone 1", (0.80, 0.06), mirror(zone(1))),
             ("zone5", "to zone 5", (0.20, 0.06), mirror(zone(5)))]
    levels = {"topspin": "development", "jump_float": "advanced",
              "zone1": "foundation", "zone5": "foundation"}
    out = []
    for key, label, start, land in specs:
        # The receiver nearest the landing spot plays it, and steps TO the
        # ball — which behind a deep float means backwards. All three used to
        # step toward the net whatever the serve did.
        def gap(sp):
            return ((sp[0] - land[0]) * 9) ** 2 + ((sp[1] - land[1]) * 18) ** 2
        i = min(range(3), key=lambda k: gap(SERVE_PASSERS[k]))
        away = []
        for k, (px, py) in enumerate(SERVE_PASSERS):
            # All the way, and WHILE the serve is in the air — phase 0, the
            # serve's own beat. Sixty per cent of the way on the beat after
            # meant the ball landed on an empty floor and a passer arrived
            # at it later: nobody receives a serve by watching it bounce.
            step = [(land[0], land[1], 0)]
            away.append(P(px, py, "P", moves=step if k == i else []))
        # Their setter, standing on her own target. The pass used to go up
        # to an empty spot — a ball played to nobody. She is last in the
        # list so a0–a2 still name the three passers.
        away.append(P(*mirror(SET_POINT), "S"))
        out.append(Drill(
            id=f"vb_serve_{key}", category="setpiece", minutes=8, rel=True,
            free=(key == "float_deep"), off_surface=True, level=levels.get(key),
            name=suffixed(SERVE_NAME, label), note=SERVE_NOTE,
            home=[P(start[0], 1.0 + SERVE_BACK, "SV",
                    moves=[(start[0], 0.98, 0),
                           (start[0], 1.0 + SERVE_BACK, 1)])],
            away=away,
            markers=[M(*land, "zone", "")],
            ball=0,
            # Over the net into the marked zone — ball_spot so the ball is
            # drawn ON the zone and not 70 units past it, which for the short
            # serve put the landing disc on the net tape.
            # …and the pass goes up to their setter: a serve is judged by
            # the pass it forces.
            ball_to=[(ball_spot(land), 0), (f"a{i}", 1), ("a3", 2)],
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


# The passer stands clear of the lane the setter releases through. Drawn on
# it — zone 5 released straight over the libero — the run, the player and the
# pass line were one arrow nobody could take apart.
SETTER_PASSER = {1: (0.34, 0.84), 6: (0.24, 0.82), 5: (0.56, 0.90)}


def setter_family() -> list[Drill]:
    out = []
    for z in (1, 6, 5):
        x, y = zone(z)
        px, py = SETTER_PASSER[z]
        out.append(Drill(
            id=f"vb_setter_z{z}", category="attacking", minutes=10, rel=True,
            free=(z == 1),
            name=suffixed(SETTER_NAME, f"zone {z}"), note=SETTER_NOTE,
            home=[
                P(x, y, "S", moves=[(SET_POINT[0], SET_POINT[1] + 0.03, 0),
                                    SET_POINT + (1,)]),
                P(px, py, "P", moves=[(px + 0.04, py - 0.06, 0)]),
                # Both hitters wait behind the 3 m line and run at the net as
                # the set goes up, which is where the set is delivered.
                P(0.16, 0.74, "A", moves=[(0.20, 0.555, 2)]),
                P(0.46, 0.70, "M", moves=[(0.46, 0.545, 2)]),
            ],
            away=[P(0.30, 0.455, "B", moves=[(0.24, 0.47, 2)])],
            markers=[M(*SET_POINT, "square", "")],
            ball=1,
            # The pass climbs as the setter releases; he delivers the pin
            # attack as the middle holds the blocker — and it is hit into
            # the far court.
            ball_to=[(0, 0), (2, 2), (ball_spot((0.72, 0.22)), 3)],
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
            # Pepper is played down the length of a half at five metres:
            # closer than that and there is no room to pass, set and hit.
            home = [P(0.44, 0.94, "1", moves=[(0.44, 0.84, 0), (0.44, 0.94, 1)]),
                    P(0.44, 0.64, "2", moves=[(0.48, 0.74, 0), (0.44, 0.64, 1)])]
            away = []
            ball_to = [(1, 0), (0, 1)]
        elif key == "butterfly":
            # The butterfly proper: 1 serves, 4 passes to the target T at the
            # net, and everyone follows the ball one station on — server to
            # passer, passer to target, target to the back of the serving
            # line. It used to be 4 passing straight back over the net, which
            # is a rally, not a butterfly.
            #
            # Run on ONE court. The gym version sends each player round the
            # post to the other side, and a board cannot draw "round the
            # post" — it draws a straight line, and a straight line from one
            # half to the other goes through the net, which is the one thing
            # a volleyball player may not do. Both lines on the same side say
            # the same drill and nobody walks through the tape.
            home = [P(0.32, 1.0 + SERVE_BACK, "1", moves=[(0.62, 0.78, 2)]),
                    P(0.18, 1.0 + SERVE_BACK, "2"),
                    P(0.46, 1.0 + SERVE_BACK, "3"),
                    P(0.62, 0.78, "4", moves=[(0.44, 0.60, 2)]),
                    P(0.44, 0.60, "T", moves=[(0.46, 1.0 + SERVE_BACK, 2)])]
            away = []
            ball_to = [(3, 0), (4, 1)]
        else:
            # Both shuffle the same way, to the cone and back: shuffling into
            # each other until the tokens touch reads as a collision.
            home = [P(0.24, 0.88, "1", moves=[(0.46, 0.84, 0), (0.24, 0.88, 1)]),
                    P(0.58, 0.88, "2", moves=[(0.80, 0.84, 0), (0.58, 0.88, 1)])]
            away = [P(0.50, 0.30, "C", moves=[(0.50, 0.40, 0)])]
            ball_to = [("a0", 0), (1, 1)]
        out.append(Drill(
            id=f"vb_warm_{key}", category="warmup", minutes=8, rel=True,
            # The butterfly's serving line waits behind the end line, which
            # is where a server belongs and is off the playing surface.
            free=(key == "pepper"), off_surface=(key == "butterfly"),
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            home=home, away=away, ball=0,
            # Back and forth — the ball is the metronome of every warm-up.
            ball_to=ball_to,
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
    # ay: where their contact is made — a free ball is sent up from deep, a
    # down ball is struck standing from around their attack line.
    specs = [("free_ball", "a free ball", 0.24), ("down_ball", "a down ball", 0.36)]
    out = []
    for key, label, ay in specs:
        out.append(Drill(
            id=f"vb_{key}", category="attacking", minutes=10, rel=True,
            free=(key == "free_ball"),
            name=suffixed(FREEBALL_NAME, label), note=FREEBALL_NOTE,
            home=[
                P(0.26, 0.545, "B", moves=[(0.24, 0.66, 0)]),
                P(0.50, 0.545, "M", moves=[(0.46, 0.70, 0), (0.40, 0.545, 2)]),
                P(0.72, 0.72, "S", moves=[SET_POINT + (1,)]),
                P(0.22, 0.80, "P", moves=[(0.20, 0.74, 0), (0.26, 0.545, 2)]),
                P(0.62, 0.90, "D", moves=[(0.56, 0.84, 0)]),
            ],
            away=[P(0.50, ay, "A", moves=[(0.50, ay + 0.08, 0)])],
            markers=[M(*SET_POINT, "square", "")],
            # Beside their hitter, not under him — and far enough from our
            # front row that the text does not credit the first touch to one
            # of our own blockers.
            ball=(0.44, ay + 0.05),
            # The gift comes over slow; dig, set to the middle running in,
            # and the swing puts it back on their floor — the whole point of
            # a free ball. It used to be set BACK over the net to the
            # opponent, and the middle never touched it.
            ball_to=[(4, 0), (2, 1), (1, 2), (ball_spot((0.62, 0.26)), 3)],
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
    # target = the window the set is delivered into, a metre off the net;
    # start = where the hitter waits, behind the 3 m line, before running in.
    # The set used to travel four metres BACKWARD to a hitter standing on the
    # attack line, leaving the target box at the net empty on every board.
    specs = [("front", "front set", (0.18, 0.555), (0.12, 0.76)),
             ("back", "back set", (0.86, 0.565), (0.92, 0.76)),
             ("jump", "jump set", (0.38, 0.545), (0.36, 0.74))]
    out = []
    for key, label, target, start in specs:
        out.append(Drill(
            id=f"vb_set_{key}", category="possession", minutes=8, rel=True,
            free=(key == "front"),
            name=suffixed(SET_NAME, label), note=SET_NOTE,
            home=[
                P(0.60, 0.88, "P", moves=[(0.58, 0.78, 0)]),
                P(*SET_POINT, "S", moves=[(SET_POINT[0] - 0.02, 0.535, 1)]),
                P(*start, "A", moves=[target + (1,)]),
            ],
            markers=[M(*target, "square", "")],
            ball=0,
            # Pass up to the setter, delivered to the target window as the
            # hitter arrives in it, put away over the net.
            ball_to=[(1, 0), (2, 1),
                     (ball_spot((target[0], 0.30)), 2)],
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


def _away_player(spot, label):
    """An away player and his small step toward the ball, from HIS own spot."""
    ax, ay = spot
    return P(ax, ay, label, moves=[(ax + (0.5 - ax) * 0.14, ay + 0.05, 0)])


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
            # Shift each away player toward the ball from where THEY stand.
            # Written against the home x, every away player crossed the court
            # to his mirror image — two X-crossings through team-mates on the
            # 6v6 board for no tactical reason at all.
            away=[_away_player(mirror((x, y)), chr(65 + i))
                  for i, (x, y) in enumerate(spots)],
            ball=0,
            # One exchange of the rally — over to their A, back to our 2.
            # One trip per beat: their serve and our pass off it both on
            # beat 0 meant the serve was never drawn.
            ball_to=[("a0", 0), (1 % n, 1)],
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
            # A coverage board needs a hit and a block to cover: the only
            # ball movement used to be A playing it a metre backwards to a C.
            home=[P(0.17, 0.575, "A"),
                  P(*SET_POINT, "S", moves=[(0.44, 0.62, 0)]),
                  P(0.34, 0.70, "C", moves=[(0.27, 0.62, 0)]),
                  P(0.20, 0.86, "C", moves=[(0.17, 0.70, 0)]),
                  P(0.52, 0.92, "C", moves=[(0.38, 0.76, 0)])],
            away=[P(0.12, 0.465, "B"), P(0.27, 0.465, "B")],
            markers=[M(0.24, 0.68, "zone", "")],
            ball=0,
            # cover first, then the swing into the block and the rebound
            # dropping into the arc that is already there
            ball_to=[("a0", 1), (2, 2)],
        ),
        Drill(
            id="vb_attack_quick", category="finishing", minutes=12, rel=True,
            name=suffixed(TEMPO_NAME, "the quick in front"), note=TEMPO_NOTE,
            home=[P(*zone(1), "P", moves=[(0.72, 0.80, 0)]),
                  P(*SET_POINT, "S", moves=[(0.62, 0.545, 1)]),
                  # In the air before the set, and a metre and a bit in front
                  # of the setter — ending ON him hid both labels and left
                  # the "set" with no length at all.
                  P(0.36, 0.68, "M", moves=[(0.38, 0.55, 0)])],
            away=[P(0.54, 0.455, "B", moves=[(0.50, 0.47, 2)]),
                  P(*mirror(zone(6)), "D")],
            markers=[M(*SET_POINT, "square", "")],
            ball=0,
            # pass, one-beat set, the quick dies before the block closes
            ball_to=[(1, 0), (2, 1), (ball_spot((0.56, 0.28)), 2)],
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
            # pass, set chasing the slide, hit from behind the setter
            ball_to=[(1, 0), (2, 1), (ball_spot((0.82, 0.30)), 2)],
        ),
        Drill(
            id="vb_receive_two_passer", category="possession", minutes=12, rel=True,
            free=True, level="advanced",
            name=suffixed(LIBERO_NAME, "in a two-passer receive"), note=LIBERO_NOTE,
            home=[P(0.34, 0.84, "L", moves=[(0.40, 0.76, 0)]),
                  P(0.74, 0.82, "P", moves=[(0.66, 0.74, 0)]),
                  P(*SET_POINT, "S", moves=[(0.60, 0.555, 1)]),
                  # Clear of where the pass comes to rest at the setter's
                  # feet, which is otherwise on top of the middle.
                  P(0.20, 0.62, "H"), P(0.44, 0.60, "M"), P(0.80, 0.62, "H")],
            away=[P(0.50, 0.06, "SV", moves=[(0.50, 0.16, 0)])],
            markers=[M(*SET_POINT, "square", "")],
            # In the server's hand. A serve-receive drill in which the ball
            # started inside our own court with a front-row hitter had nobody
            # serving in it.
            ball=(0.45, 0.10),
            # their serve into the seam; the libero takes it to the setter,
            # who sets it out to the pin
            ball_to=[(0, 0), (2, 1), (ball_spot((0.16, 0.56)), 2)],
        ),
        Drill(
            id="vb_setter_dump", category="attacking", minutes=8, rel=True,
            level="foundation",
            name=suffixed(SETTER_NAME, "the second-ball dump"), note=DUMP_NOTE,
            home=[P(0.20, 0.84, "P", moves=[(0.28, 0.76, 0)]),
                  P(*SET_POINT, "S", moves=[(0.62, 0.545, 1)]),
                  P(0.20, 0.62, "H", moves=[(0.24, 0.555, 2)])],
            away=[P(0.26, 0.455, "B", moves=[(0.20, 0.47, 2)]),
                  P(0.42, 0.455, "B", moves=[(0.36, 0.47, 2)]),
                  P(*mirror(zone(6)), "D")],
            markers=[M(0.62, 0.40, "zone", "")],
            ball=0,
            # pass up — and the setter drops it over on two, INTO their
            # court behind the block. Written as a bare point it was drawn
            # 70 units short of itself, which left the dump on the net tape.
            ball_to=[(1, 0), (ball_spot((0.62, 0.40)), 2)],
        ),
    ]


# ══ The 2026-10 expansion ════════════════════════════════════════════════════
#
# The competitor read (research_notes/四项运动战术板竞品分析/volleyball.md)
# put us at 44 drills against libraries of 200–320. What follows fills the
# gaps a coach reaches for every week — passing, out-of-system sets, shot
# selection, middle blocking, digging, the counterattack, serving to a zone,
# the 5-1 and 6-2 receive rotations, wash and king of the court — under the
# same house rules as the rest of this file: a person at every feed, the
# receiver standing where the ball lands on the beat it lands, nobody
# through the net, servers behind their line.


def _t(en, zh, tw, ja, ko, es, fr, id_, ms, th, vi):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": tw, "ja-JP": ja,
            "ko-KR": ko, "es-ES": es, "fr-FR": fr, "id-ID": id_, "ms-MY": ms,
            "th-TH": th, "vi-VN": vi}


# Where a front-row hitter waits behind the 3 m line, and where she meets
# the set a metre off the tape — the same numbers attack_family uses.
LEFT_START, LEFT_HIT = (0.12, 0.74), (0.17, 0.555)
RIGHT_START, RIGHT_HIT = (0.90, 0.72), (0.86, 0.555)
QUICK_START, QUICK_HIT = (0.44, 0.66), (0.52, 0.555)


def _sv():
    """Their server: behind their end line, into the court once she has hit."""
    return P(*SERVE_SPOT, "SV", moves=[(0.5, 0.02, 0)])


# ── warm-up: more of the family ──────────────────────────────────────────────

def warmup_more() -> list[Drill]:
    return [
        Drill(
            id="vb_warm_pepper_three", category="warmup", minutes=8, rel=True,
            name=suffixed(WARM_NAME, "three-person pepper"), note=WARM_NOTE,
            # Hit, dig, set round a triangle: the hitter plays it down to
            # the digger, who digs it up to the setter, who sets the hitter.
            home=[P(0.30, 0.64, "H", moves=[(0.33, 0.60, 2)]),
                  P(0.46, 0.93, "D", moves=[(0.42, 0.90, 0)]),
                  P(0.72, 0.74, "S", moves=[(0.68, 0.72, 1)])],
            ball=0,
            ball_to=[(1, 0), (2, 1), (0, 2), (1, 3)],
        ),
        Drill(
            id="vb_warm_partner_pass", category="warmup", minutes=8, rel=True,
            free=True,
            name=suffixed(WARM_NAME, "partner passing"), note=WARM_NOTE,
            # One stands at the net, the other passes and shuffles: every
            # pass is made from a new spot, so the platform is angled, not
            # just held out.
            home=[P(0.30, 0.90, "1", moves=[(0.52, 0.90, 1)]),
                  P(0.40, 0.62, "2", moves=[(0.44, 0.66, 0), (0.60, 0.64, 2)])],
            ball=0,
            ball_to=[(1, 0), (0, 1), (1, 2)],
        ),
        Drill(
            id="vb_warm_partner_set", category="warmup", minutes=8, rel=True,
            name=suffixed(WARM_NAME, "partner setting"), note=WARM_NOTE,
            # Along the net, the length of a set to the pin.
            home=[P(0.26, 0.60, "1", moves=[(0.30, 0.66, 1)]),
                  P(0.70, 0.62, "2", moves=[(0.66, 0.68, 0), (0.70, 0.60, 2)])],
            ball=0,
            ball_to=[(1, 0), (0, 1), (1, 2)],
        ),
        Drill(
            id="vb_warm_hitting_lines", category="warmup", minutes=10, rel=True,
            name=suffixed(WARM_NAME, "hitting lines"), note=WARM_NOTE,
            # The coach stands at the net on the hitters' side and tosses;
            # the next hitter waits behind the 3 m line.
            home=[P(0.34, 0.60, "C", coach=True),
                  P(0.10, 0.76, "A", moves=[(0.17, 0.555, 0)]),
                  P(0.10, 0.88, "A")],
            markers=[M(0.72, 0.22, "zone", "")],
            ball=0,
            ball_to=[(1, 0), (ball_spot((0.72, 0.22)), 1)],
        ),
    ]


# ── passing ──────────────────────────────────────────────────────────────────

PASS_NAME = _t("Passing", "一传", "一傳", "パス", "리시브", "Recepción",
               "Réception", "Passing", "Hantaran", "การรับบอล", "Đỡ bước một")
PASS_NOTE = _t(
    "Get there first, then pass: feet stopped behind the ball, platform angled at the target before the ball arrives. Swinging the arms at it is how a pass ends up in the net.",
    "先到位再垫：脚在球后面停稳，球到之前手臂平面就已经对准目标。抡胳膊去打球，球就会进网。",
    "先到位再墊：腳在球後面停穩，球到之前手臂平面就已經對準目標。掄胳膊去打球，球就會進網。",
    "先に入ってから返す。ボールの後ろで足を止め、ボールが来る前に面をターゲットへ向けておく。腕を振ればネットに刺さる。",
    "먼저 가서 받는다. 공 뒤에서 발을 멈추고, 공이 오기 전에 팔 면을 목표로 향해 둔다. 팔을 휘두르면 공은 네트로 간다.",
    "Llega primero y luego recibe: pies parados detrás del balón y la plataforma orientada al objetivo antes de que llegue. Balancear los brazos es como acaba en la red.",
    "Arrive d'abord, réceptionne ensuite : appuis arrêtés derrière le ballon, plan des avant-bras orienté vers la cible avant qu'il arrive. Balancer les bras, c'est l'envoyer dans le filet.",
    "Sampai dulu, baru passing: kaki berhenti di belakang bola, lengan sudah diarahkan ke target sebelum bola datang. Mengayun lengan membuat bola masuk net.",
    "Sampai dahulu, baru menghantar: kaki berhenti di belakang bola, lengan sudah dihalakan ke sasaran sebelum bola tiba. Menghayun lengan membawa bola ke jaring.",
    "ไปถึงก่อนแล้วค่อยรับ เท้าหยุดหลังบอล แขนหันไปที่เป้าก่อนบอลมาถึง เหวี่ยงแขนใส่บอลคือบอลติดเน็ต",
    "Đến trước rồi mới đỡ: chân dừng sau bóng, mặt tay hướng về mục tiêu trước khi bóng tới. Vung tay vào bóng là bóng vào lưới.")


def passing_family() -> list[Drill]:
    return [
        Drill(
            id="vb_pass_target", category="possession", minutes=10, rel=True,
            free=True, level="foundation",
            name=suffixed(PASS_NAME, "to the target"), note=PASS_NOTE,
            # The coach tosses over the net from the other side; the pass
            # goes up to T standing on the setter's spot, who sends it back.
            home=[P(0.30, 0.84, "P", moves=[(0.34, 0.80, 0), (0.30, 0.86, 1)]),
                  P(*SET_POINT, "T")],
            away=[P(0.40, 0.30, "C", coach=True)],
            markers=[M(*SET_POINT, "square", "")],
            ball=(0.40, 0.30),
            ball_to=[(0, 0), (1, 1), ("a0", 2)],
        ),
        Drill(
            id="vb_pass_on_the_move", category="possession", minutes=10, rel=True,
            level="foundation",
            name=suffixed(PASS_NAME, "on the move"), note=PASS_NOTE,
            # The toss is wide: the passer shuffles out to it, passes, and
            # is back in the middle before the next one.
            home=[P(0.50, 0.84, "P", moves=[(0.24, 0.82, 0), (0.50, 0.84, 2)]),
                  P(*SET_POINT, "T", moves=[(0.62, 0.56, 1)])],
            away=[P(0.50, 0.30, "C", coach=True)],
            markers=[M(*SET_POINT, "square", "")],
            ball=(0.50, 0.30),
            ball_to=[(0, 0), (1, 1), ("a0", 2)],
        ),
        Drill(
            id="vb_pass_overhead", category="possession", minutes=10, rel=True,
            off_surface=True,
            name=suffixed(PASS_NAME, "with the hands"), note=PASS_NOTE,
            # A deep float served from behind their line; the passer steps
            # back under it and takes it overhead to the target.
            home=[P(0.50, 0.84, "P", moves=[(0.54, 0.90, 0)]),
                  P(*SET_POINT, "T", moves=[(0.62, 0.56, 1)])],
            away=[_sv()],
            markers=[M(*SET_POINT, "square", "")],
            ball=SERVE_SPOT,
            ball_to=[(0, 0), (1, 1)],
        ),
    ]


# ── serve receive patterns ───────────────────────────────────────────────────

RECV_NAME = _t("Serve receive", "接发球阵型", "接發球陣型", "サーブレシーブ",
               "서브 리시브", "Recepción de saque", "Réception de service",
               "Penerimaan servis", "Penerimaan servis", "รับเสิร์ฟ",
               "Đỡ giao bóng")
RECV_NOTE = _t(
    "Every passer added is a seam added. Three passers each own a lane; four and five cover more floor but must call every ball between them before it crosses the net.",
    "每多一个接发球的人，就多一条结合部。三人接发每人一条通道；四人、五人覆盖的场地更大，但两人之间的每一个球都必须在过网之前就喊出来。",
    "每多一個接發球的人，就多一條結合部。三人接發每人一條通道；四人、五人覆蓋的場地更大，但兩人之間的每一個球都必須在過網之前就喊出來。",
    "レシーバーが1人増えるごとに継ぎ目が1つ増える。3人なら各自のレーンを持つ。4人、5人は守る床が広いが、間に来る球はネットを越える前にすべてコールする。",
    "리시버가 한 명 늘 때마다 이음새도 하나 는다. 3인은 각자 한 레인을 맡고, 4인·5인은 더 넓게 덮지만 사이로 오는 공은 네트를 넘기 전에 모두 콜해야 한다.",
    "Cada receptor que se añade es una costura más. Con tres, cada uno tiene su carril; con cuatro y cinco se cubre más suelo, pero cada balón entre dos se canta antes de que cruce la red.",
    "Chaque réceptionneur ajouté est une couture de plus. À trois, chacun a son couloir ; à quatre ou cinq on couvre plus de terrain, mais chaque ballon entre deux s'annonce avant qu'il passe le filet.",
    "Setiap penerima tambahan berarti satu celah lagi. Tiga penerima masing-masing punya jalur; empat dan lima menutup lebih luas, tetapi setiap bola di antara dua orang harus dipanggil sebelum melewati net.",
    "Setiap penerima tambahan bermakna satu celah lagi. Tiga penerima masing-masing ada lorong; empat dan lima menutup lebih luas, tetapi setiap bola di antara dua orang mesti dipanggil sebelum melepasi jaring.",
    "เพิ่มผู้รับหนึ่งคนคือเพิ่มรอยต่อหนึ่งจุด สามคนรับต่างคนต่างมีช่องของตัวเอง สี่และห้าคนคุมพื้นที่ได้มากกว่า แต่ทุกลูกที่มาระหว่างสองคนต้องขานก่อนข้ามเน็ต",
    "Thêm một người đỡ là thêm một khe. Ba người thì mỗi người một làn; bốn, năm người phủ rộng hơn nhưng mọi quả giữa hai người phải gọi trước khi bóng qua lưới.")


def receive_patterns() -> list[Drill]:
    """Three, four and five passers — legal at the serve, then the attack."""
    three = [   # rotation 1: setter in zone 1 behind her right-side passer
        P(0.90, 0.90, "S", moves=[SET_POINT + (0,)]),
        P(0.78, 0.78, "O1", moves=[(0.90, 0.72, 1)]),
        P(0.44, 0.57, "M", moves=[(0.44, 0.66, 0), (0.52, 0.555, 1)]),
        P(0.14, 0.57, "OP", moves=[(0.12, 0.74, 0), (0.17, 0.555, 2)]),
        P(0.22, 0.80, "O2"),
        P(0.50, 0.82, "L", moves=[(0.48, 0.78, 0)]),
    ]
    four = [    # rotation 1 again, the opposite and O1 passing short
        P(0.88, 0.92, "S", moves=[SET_POINT + (0,)]),
        P(0.80, 0.68, "O1", moves=[(0.88, 0.74, 1), (0.86, 0.555, 2)]),
        P(0.46, 0.60, "M", moves=[(0.52, 0.555, 1)]),
        P(0.20, 0.66, "OP"),
        P(0.28, 0.86, "O2", moves=[(0.30, 0.82, 0)]),
        P(0.62, 0.86, "L"),
    ]
    five = [    # setter in zone 2 at the net; everybody else passes in a W
        P(0.80, 0.555, "S", moves=[SET_POINT + (0,)]),
        P(0.84, 0.72, "O1"),
        P(0.50, 0.70, "M", moves=[(0.52, 0.555, 1)]),
        P(0.30, 0.86, "OP", moves=[(0.32, 0.82, 0)]),
        P(0.18, 0.70, "O2", moves=[(0.12, 0.76, 1), (0.17, 0.555, 2)]),
        P(0.64, 0.86, "L"),
    ]
    specs = [
        # id, label, home, who receives, who is set, where it is put away
        ("three", "with three passers", three, 5, 3, (0.70, 0.22), "development", True),
        ("four", "with four passers", four, 4, 1, (0.80, 0.20), "foundation", False),
        ("w5", "in a five-passer W", five, 3, 4, (0.70, 0.22), "foundation", False),
    ]
    out = []
    for key, label, home, recv, hitter, kill, level, free in specs:
        out.append(Drill(
            id=f"vb_receive_{key}", category="possession", minutes=12, rel=True,
            free=free, level=level, off_surface=True,
            name=suffixed(RECV_NAME, label), note=RECV_NOTE,
            home=home, away=[_sv()], markers=[M(*SET_POINT, "square", "")],
            ball=SERVE_SPOT,
            ball_to=[(recv, 0), (0, 1), (hitter, 2), (ball_spot(kill), 3)],
        ))
    return out


# ── out-of-system sets ───────────────────────────────────────────────────────

OOS_NAME = _t("Out-of-system set", "调整二传", "調整二傳", "二段トス", "이단 토스",
              "Colocación fuera de sistema", "Passe hors système",
              "Umpan di luar sistem", "Umpanan luar sistem", "เซตนอกระบบ",
              "Chuyền hai điều chỉnh")
OOS_NOTE = _t(
    "High, off the net and to the outside: aim a metre and a half inside the antenna and two metres off the tape, so the hitter can see it coming and still swing. A ball set tight from deep is a ball the block owns.",
    "高、离网、往边上：目标是标志杆内一米半、离网两米，让攻手看得见球、还能挥得出手。从后场传得贴网，这球就归对方拦网了。",
    "高、離網、往邊上：目標是標誌桿內一米半、離網兩米，讓攻手看得見球、還能揮得出手。從後場傳得貼網，這球就歸對方攔網了。",
    "高く、ネットから離して、サイドへ。アンテナの1.5m内側、白帯から2mを狙えば、アタッカーは球を見ながら打ち切れる。後ろからネットに近く上げた球はブロックのものだ。",
    "높게, 네트에서 떨어뜨려, 사이드로. 안테나 안쪽 1.5m, 네트에서 2m를 노리면 공격수가 공을 보면서 끝까지 때릴 수 있다. 뒤에서 네트에 붙인 공은 블로킹의 것이다.",
    "Alta, separada de la red y hacia fuera: metro y medio dentro de la antena y dos metros de la cinta, para que el atacante la vea venir y pueda golpear. Una bola pegada a la red desde el fondo es del bloqueo.",
    "Haute, décollée du filet et vers l'extérieur : un mètre et demi à l'intérieur de l'antenne, deux mètres de la bande, pour que l'attaquant la voie venir et frappe. Une balle collée au filet depuis le fond appartient au contre.",
    "Tinggi, jauh dari net, dan ke sisi: satu setengah meter di dalam antena dan dua meter dari pita, agar penyerang bisa melihat bola datang dan tetap memukul. Bola rapat ke net dari belakang adalah milik blok.",
    "Tinggi, jauh dari jaring dan ke tepi: satu setengah meter di dalam antena dan dua meter dari pita, supaya penyerang nampak bola datang dan masih boleh memukul. Bola rapat ke jaring dari belakang milik sekatan.",
    "สูง ห่างเน็ต และออกข้าง เล็งเข้ามาจากเสาอากาศหนึ่งเมตรครึ่ง ห่างแถบเน็ตสองเมตร ให้ตัวตบเห็นบอลและยังตบได้เต็มแขน บอลที่เซตชิดเน็ตจากท้ายคอร์ทเป็นของบล็อก",
    "Cao, xa lưới và ra biên: nhắm cách cột ăng-ten một mét rưỡi vào trong và cách mép lưới hai mét, để chủ công thấy bóng và vẫn đập được. Bóng chuyền sát lưới từ cuối sân là bóng của hàng chắn.")


def oos_family() -> list[Drill]:
    kill = ball_spot((0.20, 0.20))   # down the line, clear of the coach
    return [
        Drill(
            id="vb_oos_deep", category="possession", minutes=10, rel=True,
            level="development",
            name=suffixed(OOS_NAME, "from deep in the court"), note=OOS_NOTE,
            # The pass is shanked deep; the setter leaves the net, gets
            # under it and sets the left pin high.
            home=[P(0.30, 0.82, "P", moves=[(0.32, 0.79, 0)]),
                  P(*SET_POINT, "S", moves=[(0.70, 0.84, 1)]),
                  P(*LEFT_START, "A", moves=[LEFT_HIT + (2,)])],
            away=[P(0.44, 0.30, "C", coach=True)],
            ball=(0.44, 0.30),
            ball_to=[(0, 0), (1, 1), (2, 2), (kill, 3)],
        ),
        Drill(
            id="vb_oos_libero", category="possession", minutes=10, rel=True,
            level="development",
            name=suffixed(OOS_NAME, "by the libero"), note=OOS_NOTE,
            # The setter digs the first ball, so the libero sets — with her
            # hands, from behind the 3 m line, which is the only way her set
            # may be attacked above the net.
            home=[P(0.80, 0.86, "S", moves=[(0.78, 0.82, 0)]),
                  P(0.46, 0.90, "L", moves=[(0.52, 0.75, 1)]),
                  P(*LEFT_START, "A", moves=[LEFT_HIT + (2,)])],
            away=[P(0.60, 0.30, "C", coach=True)],
            ball=(0.60, 0.30),
            ball_to=[(0, 0), (1, 1), (2, 2), (kill, 3)],
        ),
        Drill(
            id="vb_oos_forearm", category="possession", minutes=10, rel=True,
            level="development",
            name=suffixed(OOS_NAME, "with the forearms"), note=OOS_NOTE,
            # The setter digs again; the right-side hitter pulls off the net
            # to the middle and bumps the ball high to the outside.
            home=[P(0.80, 0.86, "S", moves=[(0.78, 0.82, 0)]),
                  P(0.84, 0.58, "OP", moves=[(0.54, 0.70, 1)]),
                  P(*LEFT_START, "A", moves=[LEFT_HIT + (2,)])],
            away=[P(0.60, 0.30, "C", coach=True)],
            ball=(0.60, 0.30),
            ball_to=[(0, 0), (1, 1), (2, 2), (kill, 3)],
        ),
    ]


# ── setter footwork ──────────────────────────────────────────────────────────

SETFOOT_NAME = _t("Setter footwork", "二传步法", "二傳步法", "セッターのフットワーク",
                  "세터 풋워크", "Desplazamiento del colocador",
                  "Déplacement du passeur", "Langkah tosser", "Langkah pengumpan",
                  "ฟุตเวิร์กเซตเตอร์", "Di chuyển của chuyền hai")
SETFOOT_NOTE = _t(
    "Feet first, hands last: get to the ball, stop with the right foot forward and the hips facing the left antenna, then set. A setter who arrives together with the ball is already late.",
    "先到脚，后出手：跑到球下，右脚在前停稳，胯朝向左边标志杆，然后再传。和球同时到的二传，已经晚了。",
    "先到腳，後出手：跑到球下，右腳在前停穩，胯朝向左邊標誌桿，然後再傳。和球同時到的二傳，已經晚了。",
    "足が先、手は最後。ボールの下に入り、右足を前にして止まり、腰を左アンテナへ向けてから上げる。ボールと同時に着くセッターはもう遅い。",
    "발이 먼저, 손은 마지막. 공 밑으로 가서 오른발을 앞에 두고 멈추고, 골반을 왼쪽 안테나로 향한 뒤 올린다. 공과 동시에 도착하는 세터는 이미 늦다.",
    "Primero los pies, las manos al final: llega al balón, para con el pie derecho adelantado y la cadera hacia la antena izquierda, y entonces coloca. El colocador que llega a la vez que el balón ya va tarde.",
    "Les pieds d'abord, les mains en dernier : arrive sous le ballon, arrête-toi pied droit devant, hanches vers l'antenne gauche, puis passe. Le passeur qui arrive en même temps que le ballon est déjà en retard.",
    "Kaki dulu, tangan terakhir: sampai ke bola, berhenti dengan kaki kanan di depan dan pinggul menghadap antena kiri, lalu umpan. Tosser yang tiba bersamaan dengan bola sudah terlambat.",
    "Kaki dahulu, tangan terakhir: sampai ke bola, berhenti dengan kaki kanan di hadapan dan pinggul menghadap antena kiri, kemudian umpan. Pengumpan yang tiba serentak dengan bola sudah terlambat.",
    "เท้าก่อน มือทีหลัง ไปถึงใต้บอล หยุดโดยเท้าขวานำ สะโพกหันไปเสาอากาศซ้าย แล้วค่อยเซต เซตเตอร์ที่ไปถึงพร้อมบอลคือช้าไปแล้ว",
    "Chân trước, tay sau: đến dưới bóng, dừng với chân phải trước, hông hướng về cột ăng-ten trái, rồi mới chuyền. Chuyền hai đến cùng lúc với bóng là đã muộn.")


def setter_footwork() -> list[Drill]:
    return [
        Drill(
            id="vb_setter_off_block", category="attacking", minutes=10, rel=True,
            level="advanced",
            name=suffixed(SETFOOT_NAME, "off the block"), note=SETFOOT_NOTE,
            # A front-row setter blocks their outside, lands, and releases
            # off the net to the target for the dig; the left-side hitter
            # opens off the net and comes in for the set.
            home=[P(0.82, 0.56, "S", moves=[(0.80, 0.535, 1), SET_POINT + (2,)]),
                  P(0.24, 0.86, "D", moves=[(0.28, 0.82, 1)]),
                  P(0.20, 0.58, "A", moves=[LEFT_START + (2,), LEFT_HIT + (3,)])],
            away=[P(0.80, 0.40, "A", moves=[(0.80, 0.455, 0)]),
                  P(*FEED_SPOT, "C", coach=True)],
            markers=[M(*SET_POINT, "square", "")],
            ball=FEED_SPOT,
            ball_to=[("a0", 0), (1, 1), (0, 2), (2, 3),
                     (ball_spot((0.30, 0.24)), 4)],
        ),
        Drill(
            id="vb_setter_off_net", category="attacking", minutes=10, rel=True,
            level="development", off_surface=True,
            name=suffixed(SETFOOT_NAME, "to a pass off the net"), note=SETFOOT_NOTE,
            # The pass comes up three metres off the net: the setter goes
            # to it, squares up and back-sets the right side.
            home=[P(0.40, 0.84, "P", moves=[(0.42, 0.80, 0)]),
                  P(*SET_POINT, "S", moves=[(0.58, 0.68, 1)]),
                  P(*RIGHT_START, "OP", moves=[RIGHT_HIT + (2,)])],
            away=[_sv()],
            markers=[M(*SET_POINT, "square", "")],
            ball=SERVE_SPOT,
            ball_to=[(0, 0), (1, 1), (2, 2), (ball_spot((0.82, 0.20)), 3)],
        ),
    ]


# ── shot selection ───────────────────────────────────────────────────────────

SPIKE_NAME = _t("Spike", "扣球", "扣球", "スパイク", "스파이크", "Remate",
                "Attaque", "Smes", "Rejaman", "การตบ", "Đập bóng")
SPIKE_NOTE = _t(
    "Pick the shot from what the block shows you on the way up: a blocker on the line means cross-court, a blocker inside means line. The shot planned in the huddle is hit into the block.",
    "起跳过程中看对方拦网再决定线路：拦网封直线就打斜线，拦网靠里就打直线。在场边就想好的线路，往往直接打在拦网手上。",
    "起跳過程中看對方攔網再決定線路：攔網封直線就打斜線，攔網靠裡就打直線。在場邊就想好的線路，往往直接打在攔網手上。",
    "跳びながらブロックを見てコースを決める。ストレートを塞がれたらクロス、内側に寄られたらストレート。最初から決めたコースはブロックに当たる。",
    "올라가면서 블로킹을 보고 코스를 정한다. 라인을 막으면 크로스, 안쪽을 막으면 라인. 미리 정한 코스는 블로킹에 맞는다.",
    "Elige el golpe por lo que muestra el bloqueo mientras subes: bloqueador en la línea, diagonal; bloqueador por dentro, paralela. El golpe pensado antes acaba en el bloqueo.",
    "Choisis la frappe d'après ce que montre le contre pendant la montée : contreur sur la ligne, diagonale ; contreur à l'intérieur, ligne. La frappe décidée à l'avance finit dans le contre.",
    "Pilih arah dari apa yang ditunjukkan blok saat naik: blok di garis berarti silang, blok di dalam berarti lurus. Arah yang direncanakan sebelumnya akan mengenai blok.",
    "Pilih arah daripada apa yang ditunjukkan sekatan semasa naik: sekatan di garisan bermakna silang, sekatan di dalam bermakna lurus. Arah yang dirancang awal akan terkena sekatan.",
    "เลือกทิศจากสิ่งที่บล็อกเปิดให้ระหว่างลอยขึ้น บล็อกปิดเส้นให้ตบทแยง บล็อกปิดด้านในให้ตบเส้น ทิศที่คิดไว้ก่อนจะตบเข้าบล็อก",
    "Chọn hướng đập theo hàng chắn khi đang bật lên: chắn đường thẳng thì đập chéo, chắn phía trong thì đập thẳng. Hướng định sẵn từ trước sẽ đập vào tay chắn.")
OFFSPEED_NAME = _t("Off-speed shot", "轻打", "輕打", "軟打", "연타", "Ataque suave",
                   "Attaque placée", "Pukulan pelan", "Pukulan perlahan",
                   "ตบเบา", "Đánh nhẹ")
OFFSPEED_NOTE = _t(
    "Sell it as a full swing until the last moment: an off-speed shot announced by the approach is a free ball. Put it on the floor nobody is standing on — behind the block, or in the seam between two diggers.",
    "直到最后一刻都要做成全力扣球的样子：助跑就暴露的轻打，等于送对方一个调整球。打到没人站的地方——拦网身后，或者两个防守人之间的结合部。",
    "直到最後一刻都要做成全力扣球的樣子：助跑就暴露的輕打，等於送對方一個調整球。打到沒人站的地方——攔網身後，或者兩個防守人之間的結合部。",
    "最後の瞬間まで強打に見せる。助走でばれる軟打は相手へのフリーボールだ。誰もいない床へ——ブロックの後ろか、2人のレシーバーの継ぎ目へ。",
    "마지막 순간까지 강타처럼 보이게 하라. 도움닫기에서 들킨 연타는 상대에게 주는 프리볼이다. 아무도 없는 바닥으로 — 블로킹 뒤나 두 수비수 사이 이음새로.",
    "Véndelo como un remate completo hasta el último momento: un golpe suave que se anuncia en la carrera es un balón libre. Ponlo donde no hay nadie: detrás del bloqueo o en la costura entre dos defensores.",
    "Fais croire à une frappe pleine jusqu'au dernier moment : une attaque placée annoncée dès l'élan est une balle gratuite. Pose-la là où personne ne se tient — derrière le contre ou dans la couture entre deux défenseurs.",
    "Buat seperti pukulan penuh sampai detik terakhir: pukulan pelan yang terbaca dari awalan adalah bola gratis. Taruh di lantai yang kosong — di belakang blok atau di celah antara dua penjaga.",
    "Jadikan seperti pukulan penuh sehingga saat terakhir: pukulan perlahan yang terbaca daripada larian ialah bola percuma. Letakkan di lantai yang kosong — di belakang sekatan atau di celah antara dua pemain bertahan.",
    "ทำให้ดูเหมือนตบเต็มแรงจนวินาทีสุดท้าย ตบเบาที่ถูกอ่านออกจากการวิ่งเข้าคือฟรีบอลให้คู่แข่ง วางลงพื้นที่ไม่มีใครยืน หลังบล็อกหรือรอยต่อระหว่างผู้รับสองคน",
    "Giả như đập mạnh đến phút cuối: cú đánh nhẹ lộ ra từ bước chạy đà là bóng tự do cho đối thủ. Đặt bóng vào chỗ không ai đứng — sau hàng chắn hoặc vào khe giữa hai người phòng thủ.")


def shot_family() -> list[Drill]:
    """Line, cross-court, the tip and the roll — off the same left-side set.

    The block tells the story: for the line shot their blocker sits inside,
    for the cross-court shot on the line, and against the double the
    off-speed shots go behind it or into the seam the deep defence leaves.
    """
    specs = [
        # id, name, variant, their blockers' x, their diggers, target
        ("vb_spike_line", SPIKE_NAME, SPIKE_NOTE, "down the line", [0.30],
         [(0.80, 0.14), (0.50, 0.08)], (0.18, 0.16), True),
        ("vb_spike_cross", SPIKE_NAME, SPIKE_NOTE, "cross-court", [0.12],
         [(0.20, 0.14), (0.50, 0.08)], (0.80, 0.16), False),
        ("vb_offspeed_tip", OFFSPEED_NAME, OFFSPEED_NOTE, "tipped over the block",
         [0.12, 0.26], [(0.20, 0.14), (0.80, 0.14)], (0.30, 0.38), False),
        ("vb_offspeed_roll", OFFSPEED_NAME, OFFSPEED_NOTE, "rolled to the seam",
         [0.12, 0.26], [(0.24, 0.14), (0.78, 0.14)], (0.50, 0.24), False),
    ]
    out = []
    for did, base, note, label, blocks, diggers, target, free in specs:
        away = [P(bx, 0.465, "B", moves=[(bx + 0.025, 0.475, 2)]) for bx in blocks]
        away += [P(x, y, "D") for x, y in diggers]
        out.append(Drill(
            id=did, category="finishing", minutes=12, rel=True,
            free=free, level="development",
            name=suffixed(base, label), note=note,
            home=[P(*zone(1), "P", moves=[(0.72, 0.80, 0)]),
                  P(*SET_POINT, "S", moves=[(SET_POINT[0] - 0.03, 0.535, 1)]),
                  P(*LEFT_START, "A", moves=[LEFT_HIT + (1,)])],
            away=away,
            markers=[M(*target, "zone", "")],
            ball=0,
            ball_to=[(1, 0), (2, 1), (ball_spot(target), 2)],
        ))
    return out


# ── the attack family: the back-row D ────────────────────────────────────────

def attack_more() -> list[Drill]:
    return [
        Drill(
            id="vb_attack_back_row", category="finishing", minutes=12, rel=True,
            level="advanced",
            name=suffixed(ATTACK_NAME, "zone 1"), note=ATTACK_NOTE,
            # The D: a back-row swing from zone 1, taking off behind the 3 m
            # line, set back over the setter's head.
            home=[P(*zone(5), "P", moves=[(0.28, 0.80, 0)]),
                  P(*SET_POINT, "S", moves=[(SET_POINT[0] - 0.03, 0.535, 1)]),
                  P(0.86, 0.92, "A", moves=[(0.82, 0.70, 1)])],
            away=[P(0.71, 0.465, "B", moves=[(0.735, 0.475, 2)]),
                  P(0.89, 0.465, "B", moves=[(0.865, 0.475, 2)]),
                  P(*mirror(zone(6)), "D", moves=[(0.5, 0.14, 2)])],
            markers=[M(*SET_POINT, "square", "")],
            ball=0,
            ball_to=[(1, 0), (2, 1), ("a2", 2)],
        ),
    ]


# ── combination plays ────────────────────────────────────────────────────────

COMBO_NAME = _t("Combination play", "配合进攻", "配合進攻", "コンビネーション",
                "콤비네이션 공격", "Jugada combinada", "Combinaison",
                "Serangan kombinasi", "Serangan kombinasi", "บุกแบบผสม",
                "Phối hợp tấn công")
COMBO_NOTE = _t(
    "The quick goes first and goes for real: if the middle is not in the air before the set, their middle blocker never jumps with her and the second hitter meets a block. The X crosses behind the quick; the tandem follows it.",
    "快球先起、而且要真打：副攻在传球之前没有起跳，对方副攻就不会跟着她跳，第二攻手面对的就还是一个完整的拦网。交叉是从快球身后穿过，梯次是跟在快球后面。",
    "快球先起、而且要真打：副攻在傳球之前沒有起跳，對方副攻就不會跟著她跳，第二攻手面對的就還是一個完整的攔網。交叉是從快球身後穿過，梯次是跟在快球後面。",
    "クイックが先に、本気で跳ぶ。トスの前にミドルが空中にいなければ、相手のミドルは釣られず、2人目のアタッカーはブロックと向き合う。Xはクイックの後ろを交差し、タンデムはその後に続く。",
    "속공이 먼저, 진짜로 뛴다. 토스 전에 미들이 공중에 없으면 상대 미들은 따라 뛰지 않고, 두 번째 공격수는 블로킹을 만난다. X는 속공 뒤로 교차하고, 탠덤은 그 뒤를 따른다.",
    "El rápido va primero y va de verdad: si el central no está en el aire antes de la colocación, su central no salta con él y el segundo atacante encuentra bloqueo. La X cruza por detrás del rápido; el tándem lo sigue.",
    "La courte part d'abord, et pour de vrai : si le central n'est pas en l'air avant la passe, leur central ne saute pas avec lui et le deuxième attaquant trouve un contre. Le X croise derrière la courte ; le tandem la suit.",
    "Quick jalan lebih dulu dan sungguhan: jika middle belum melayang sebelum umpan, middle lawan tidak ikut melompat dan penyerang kedua bertemu blok. X menyilang di belakang quick; tandem mengikutinya.",
    "Bola pantas bergerak dahulu dan bersungguh-sungguh: jika pemain tengah belum di udara sebelum umpan, pemain tengah lawan tidak ikut melompat dan penyerang kedua bertemu sekatan. X menyilang di belakang bola pantas; tandem mengikutinya.",
    "บอลเร็วต้องขึ้นก่อนและขึ้นจริง ถ้าตัวกลางไม่ลอยก่อนเซต ตัวกลางฝ่ายตรงข้ามจะไม่กระโดดตาม และตัวตบคนที่สองจะเจอบล็อก X ตัดหลังบอลเร็ว แทนเด็มตามหลังมัน",
    "Bóng nhanh phải đi trước và đi thật: nếu phụ công chưa bật trước khi chuyền, phụ công đối phương sẽ không bật theo và người đập thứ hai gặp hàng chắn. X cắt chéo sau bóng nhanh; tandem theo sau nó.")


def combo_family() -> list[Drill]:
    specs = [
        # the X: the right side runs inside, behind the middle's quick
        ("vb_combo_x", "crossing behind the quick",
         [P(0.48, 0.70, "M", moves=[(0.52, 0.62, 0), (0.56, 0.555, 1)]),
          P(0.90, 0.74, "OP", moves=[(0.74, 0.68, 0), (0.40, 0.555, 1)])],
         0.56, (0.30, 0.22)),
        # the tandem: a second hitter on the middle's heels, a beat later
        ("vb_combo_tandem", "following the quick",
         [P(0.50, 0.68, "M", moves=[(0.56, 0.555, 0)]),
          P(0.40, 0.80, "A", moves=[(0.48, 0.66, 0), (0.44, 0.555, 1)])],
         0.56, (0.34, 0.22)),
    ]
    out = []
    for did, label, hitters, decoy_x, kill in specs:
        out.append(Drill(
            id=did, category="finishing", minutes=12, rel=True, level="advanced",
            name=suffixed(COMBO_NAME, label), note=COMBO_NOTE,
            home=[P(*zone(1), "P", moves=[(0.72, 0.80, 0)]),
                  P(*SET_POINT, "S")] + hitters,
            # Their middle jumps with our quick — that is the point — and
            # their outside blocker arrives late on the second hitter.
            away=[P(decoy_x, 0.455, "B", moves=[(decoy_x, 0.475, 1)]),
                  P(0.22, 0.455, "B", moves=[(0.30, 0.47, 2)]),
                  P(*mirror(zone(6)), "D")],
            markers=[M(*SET_POINT, "square", "")],
            ball=0,
            ball_to=[(1, 0), (3, 1), (ball_spot(kill), 2)],
        ))
    return out


# ── the middle blocker ───────────────────────────────────────────────────────

MBLOCK_NAME = _t("Middle blocker", "副攻拦网", "副攻攔網", "ミドルブロッカー",
                 "미들 블로커", "Central en el bloqueo", "Contreur central",
                 "Blocker tengah", "Penyekat tengah", "บล็อกตัวกลาง",
                 "Phụ công chắn bóng")
MBLOCK_NOTE = _t(
    "Read means waiting for the ball to leave the setter's hands; commit means jumping with the quick before it does. Decide which before the serve and do it whole — half a read and half a commit is beaten both ways.",
    "看传球判断，是等球离开二传的手再动；盯快球，是在球离手之前就跟着快攻起跳。发球前决定用哪一种，然后做彻底——一半判断一半盯人，两头都会被打穿。",
    "看傳球判斷，是等球離開二傳的手再動；盯快球，是在球離手之前就跟著快攻起跳。發球前決定用哪一種，然後做徹底——一半判斷一半盯人，兩頭都會被打穿。",
    "リードはボールがセッターの手を離れるまで待つこと。コミットは離れる前にクイックと一緒に跳ぶこと。サーブ前にどちらかを決め、やり切る。半分ずつでは両方で抜かれる。",
    "리드는 공이 세터 손을 떠날 때까지 기다리는 것, 커밋은 떠나기 전에 속공과 함께 뛰는 것이다. 서브 전에 정하고 끝까지 하라. 반은 리드, 반은 커밋이면 양쪽 다 뚫린다.",
    "Leer es esperar a que el balón salga de las manos del colocador; comprometerse es saltar con el rápido antes. Decide antes del saque y hazlo entero: medio leer y medio comprometerse pierde por los dos lados.",
    "Lire, c'est attendre que le ballon quitte les mains du passeur ; s'engager, c'est sauter avec la courte avant. Décide avant le service et fais-le jusqu'au bout — à moitié l'un et l'autre, on est battu des deux côtés.",
    "Membaca berarti menunggu bola lepas dari tangan tosser; komit berarti melompat bersama quick sebelum itu. Putuskan sebelum servis dan lakukan sepenuhnya — setengah membaca setengah komit kalah di dua sisi.",
    "Membaca bermakna menunggu bola lepas dari tangan pengumpan; komit bermakna melompat bersama bola pantas sebelum itu. Putuskan sebelum servis dan lakukan sepenuhnya — separuh membaca separuh komit kalah di kedua-dua sisi.",
    "การอ่านคือรอให้บอลออกจากมือเซตเตอร์ การดักคือกระโดดไปกับบอลเร็วก่อนบอลออกจากมือ ตัดสินใจก่อนเสิร์ฟแล้วทำให้สุด อ่านครึ่งดักครึ่งจะโดนทั้งสองทาง",
    "Đọc là chờ bóng rời tay chuyền hai; chắn theo là bật cùng bóng nhanh trước khi bóng rời tay. Quyết định trước khi giao bóng và làm trọn vẹn — nửa đọc nửa theo sẽ thua cả hai phía.")


def middle_block_family() -> list[Drill]:
    """Read, commit and the swing block — where their setter puts the ball."""
    their_s = mirror(SET_POINT)        # their setter at their own target
    specs = [
        # id, variant, who the set goes to (away index), our middle's run,
        # our pin blocker (start, close), our digger and his step
        ("vb_block_read", "reading the set", 2, (0.735, 0.535),
         (0.84, 0.545), (0.84, 0.535), (0.70, 0.88), (0.74, 0.84), True),
        ("vb_block_commit", "committing to the quick", 1, (0.52, 0.535),
         (0.84, 0.545), (0.84, 0.53), (0.50, 0.90), (0.52, 0.80), False),
        ("vb_block_swing", "swinging to the pin", 3, (0.28, 0.535),
         (0.16, 0.545), (0.17, 0.53), (0.30, 0.88), (0.26, 0.84), False),
    ]
    out = []
    for did, label, to, run, pin, pin_to, dig, dig_to, free in specs:
        out.append(Drill(
            id=did, category="defending", minutes=10, rel=True, free=free,
            level="development" if free else "advanced",
            name=suffixed(MBLOCK_NAME, label), note=MBLOCK_NOTE,
            home=[P(0.50, 0.555, "M", moves=[run + (1,)]),
                  P(*pin, "B", moves=[pin_to + (1,)]),
                  P(*dig, "D", moves=[dig_to + (2,)])],
            # Their setter, their middle running the quick, their outside
            # (on our right) and their right side (on our left), and the
            # coach feeding the setter from their back court.
            away=[P(*their_s, "S"),
                  P(0.48, 0.36, "MB", moves=[(0.48, 0.455, 1)]),
                  P(0.82, 0.36, "OH", moves=[(0.80, 0.455, 1)]),
                  P(0.18, 0.36, "RS", moves=[(0.20, 0.455, 1)]),
                  P(*FEED_SPOT, "C", coach=True)],
            ball=FEED_SPOT,
            ball_to=[("a0", 0), (f"a{to}", 1), (2, 2)],
        ))
    return out


# ── digging ──────────────────────────────────────────────────────────────────

DIG_NAME = _t("Digging", "防守起球", "防守起球", "ディグ", "디그",
              "Defensa en campo", "Défense basse", "Dig", "Dig",
              "การรับลูกตบ", "Phòng thủ đỡ bóng")
DIG_NOTE = _t(
    "Platform angled to the target before the ball arrives, and the ball played up, high and into the middle of your own court. A dig that goes back over the net or out to the sideline is a dig nobody can set.",
    "球到之前手臂平面就对准目标，把球垫高、垫到本方场地中间。垫回对方场地或垫向边线的球，没有人能组织进攻。",
    "球到之前手臂平面就對準目標，把球墊高、墊到本方場地中間。墊回對方場地或墊向邊線的球，沒有人能組織進攻。",
    "ボールが来る前に面をターゲットへ向け、高く、自陣の中央へ上げる。ネットを越えて返る球やサイドへ飛ぶ球は、誰もトスにできない。",
    "공이 오기 전에 팔 면을 목표로 향하고, 높게, 우리 코트 가운데로 올린다. 네트를 넘어가거나 사이드로 나가는 디그는 아무도 토스할 수 없다.",
    "Plataforma orientada al objetivo antes de que llegue el balón, y el balón arriba, alto y al centro de tu campo. Una defensa que vuelve por encima de la red o sale a la banda no la coloca nadie.",
    "Plan des avant-bras orienté vers la cible avant l'arrivée du ballon, et le ballon renvoyé haut, au milieu de ton terrain. Une défense qui repasse le filet ou part sur la touche, personne ne peut la jouer.",
    "Lengan diarahkan ke target sebelum bola datang, bola dimainkan tinggi ke tengah lapangan sendiri. Dig yang kembali melewati net atau keluar ke samping tidak bisa diumpan siapa pun.",
    "Lengan dihalakan ke sasaran sebelum bola tiba, bola dimainkan tinggi ke tengah gelanggang sendiri. Dig yang kembali melepasi jaring atau keluar ke tepi tidak boleh diumpan sesiapa.",
    "หันแขนไปที่เป้าก่อนบอลมา แล้วรับให้สูงเข้ากลางคอร์ทตัวเอง ลูกรับที่ข้ามเน็ตกลับไปหรือออกข้างคือลูกที่ไม่มีใครเซตได้",
    "Mặt tay hướng về mục tiêu trước khi bóng tới, đỡ bóng lên cao vào giữa sân nhà. Pha đỡ bay ngược qua lưới hoặc ra biên là bóng không ai chuyền được.")


def dig_family() -> list[Drill]:
    return [
        Drill(
            id="vb_dig_target", category="defending", minutes=10, rel=True,
            free=True, level="foundation",
            name=suffixed(DIG_NAME, "to the target"), note=DIG_NOTE,
            # The coach hits from a box at the net on the far side; the dig
            # goes up to T on the setter's spot, who hands it back.
            home=[P(0.30, 0.86, "D", moves=[(0.34, 0.82, 0), (0.30, 0.86, 1)]),
                  P(*SET_POINT, "T")],
            away=[P(0.40, 0.42, "C", coach=True)],
            markers=[M(*SET_POINT, "square", "")],
            ball=(0.40, 0.42),
            ball_to=[(0, 0), (1, 1), ("a0", 2)],
        ),
        Drill(
            id="vb_dig_line_angle", category="defending", minutes=12, rel=True,
            level="development",
            name=suffixed(DIG_NAME, "line and angle"), note=DIG_NOTE,
            # The coach hits from their left side (our right): one ball down
            # the line to D1, the next across to D2 in the other back corner.
            home=[P(0.84, 0.84, "D1", moves=[(0.86, 0.80, 0), (0.84, 0.84, 2)]),
                  P(0.24, 0.82, "D2", moves=[(0.26, 0.78, 1), (0.30, 0.74, 3)]),
                  P(*SET_POINT, "T")],
            away=[P(0.78, 0.42, "C", coach=True)],
            markers=[M(*SET_POINT, "square", "")],
            ball=(0.78, 0.42),
            ball_to=[(0, 0), (2, 1), ("a0", 2), (1, 3), (2, 4)],
        ),
        Drill(
            id="vb_dig_pursuit", category="defending", minutes=10, rel=True,
            level="development",
            name=suffixed(DIG_NAME, "in pursuit"), note=DIG_NOTE,
            # The first pass is shanked into the deep corner; R chases it
            # down and plays it high back into the middle for T.
            home=[P(0.30, 0.80, "P", moves=[(0.32, 0.77, 0)]),
                  P(0.62, 0.80, "R", moves=[(0.90, 0.94, 1)]),
                  P(0.50, 0.62, "T", moves=[(0.48, 0.66, 2)])],
            away=[P(0.40, 0.30, "C", coach=True)],
            ball=(0.40, 0.30),
            ball_to=[(0, 0), (1, 1), (2, 2)],
        ),
    ]


# ── counterattack ────────────────────────────────────────────────────────────

COUNTER_NAME = _t("Counterattack", "防反", "防反", "反撃", "반격", "Contraataque",
                  "Contre-attaque", "Serangan balik", "Serangan balas",
                  "การโต้กลับ", "Phản công")
COUNTER_NOTE = _t(
    "The rally is won on the ball after the dig: the hitter lands, opens off the net to the 3 m line and is ready to approach before the setter touches it. A hitter still standing at the net has no approach left.",
    "这一分赢在防起来之后的那一球：攻手落地后马上撤到三米线，在二传触球之前就准备好助跑。还站在网前的攻手，已经没有助跑距离了。",
    "這一分贏在防起來之後的那一球：攻手落地後馬上撤到三米線，在二傳觸球之前就準備好助跑。還站在網前的攻手，已經沒有助跑距離了。",
    "ラリーはディグの次の1本で決まる。アタッカーは着地したらネットから3mラインへ開き、セッターが触る前に助走の準備を終える。ネット際に立ったままでは助走が残っていない。",
    "랠리는 디그 다음 공에서 이긴다. 공격수는 착지 후 네트에서 3m 라인으로 빠져, 세터가 공을 만지기 전에 도움닫기 준비를 끝낸다. 네트 앞에 서 있는 공격수는 도움닫기가 없다.",
    "El punto se gana en el balón después de la defensa: el atacante cae, se abre de la red a la línea de 3 m y está listo para la carrera antes de que el colocador toque. Quien sigue en la red no tiene carrera.",
    "Le point se gagne sur le ballon après la défense : l'attaquant retombe, s'écarte du filet jusqu'aux 3 m et est prêt à prendre son élan avant que le passeur touche. Resté au filet, il n'a plus d'élan.",
    "Reli dimenangkan pada bola setelah dig: penyerang mendarat, mundur dari net ke garis 3 m, dan siap mengambil awalan sebelum tosser menyentuh bola. Penyerang yang tetap di net tidak punya awalan.",
    "Rali dimenangi pada bola selepas dig: penyerang mendarat, berundur dari jaring ke garisan 3 m, dan sedia membuat larian sebelum pengumpan menyentuh bola. Penyerang yang kekal di jaring tiada larian.",
    "แต้มตัดสินที่ลูกถัดจากการรับ ตัวตบลงพื้นแล้วถอยออกจากเน็ตไปเส้น 3 เมตร พร้อมวิ่งเข้าก่อนเซตเตอร์แตะบอล ตัวตบที่ยังยืนที่เน็ตไม่มีระยะวิ่งเหลือ",
    "Điểm được quyết ở quả sau pha đỡ: chủ công tiếp đất, lùi khỏi lưới về vạch 3 m và sẵn sàng chạy đà trước khi chuyền hai chạm bóng. Ai còn đứng ở lưới thì không còn đà.")


def counter_family() -> list[Drill]:
    their_attack = [P(0.80, 0.40, "A", moves=[(0.80, 0.455, 0)]),
                    P(*FEED_SPOT, "C", coach=True)]
    return [
        Drill(
            id="vb_counter_dig", category="attacking", minutes=12, rel=True,
            level="development",
            name=suffixed(COUNTER_NAME, "from the dig"), note=COUNTER_NOTE,
            # Their outside swings cross-court; our left back digs it, the
            # setter releases to the target, and our left side — who did
            # not block — has opened off the net and comes in.
            home=[P(0.82, 0.56, "B", moves=[(0.82, 0.535, 1)]),
                  P(0.20, 0.86, "D", moves=[(0.26, 0.82, 1)]),
                  P(0.80, 0.88, "S", moves=[SET_POINT + (2,)]),
                  P(0.22, 0.58, "A", moves=[LEFT_START + (1,), LEFT_HIT + (3,)])],
            away=their_attack,
            markers=[M(*SET_POINT, "square", "")],
            ball=FEED_SPOT,
            ball_to=[("a0", 0), (1, 1), (2, 2), (3, 3),
                     (ball_spot((0.50, 0.28)), 4)],
        ),
        Drill(
            id="vb_counter_block", category="attacking", minutes=12, rel=True,
            level="advanced",
            name=suffixed(COUNTER_NAME, "off the block"), note=COUNTER_NOTE,
            # Our opposite blocks their outside, lands, opens off the net
            # and hits the counter herself from the right side.
            home=[P(0.82, 0.56, "OP", moves=[(0.82, 0.535, 1), RIGHT_START + (2,),
                                             RIGHT_HIT + (3,)]),
                  P(0.50, 0.88, "L", moves=[(0.62, 0.84, 1)]),
                  P(0.30, 0.82, "S", moves=[SET_POINT + (2,)])],
            away=[P(0.80, 0.40, "A", moves=[(0.80, 0.455, 0)]),
                  P(*FEED_SPOT, "C", coach=True)],
            markers=[M(*SET_POINT, "square", "")],
            ball=FEED_SPOT,
            ball_to=[("a0", 0), (1, 1), (2, 2), (0, 3),
                     (ball_spot((0.24, 0.22)), 4)],
        ),
        Drill(
            id="vb_counter_cover", category="attacking", minutes=12, rel=True,
            level="development",
            name=suffixed(COUNTER_NAME, "after the cover"), note=COUNTER_NOTE,
            # Our hitter is blocked; the ball drops into the cover, goes back
            # up to the setter, and the same hitter — already reopened —
            # swings again.
            home=[P(*SET_POINT, "S", moves=[(0.62, 0.56, 2)]),
                  P(*LEFT_START, "A", moves=[LEFT_HIT + (0,), (0.12, 0.72, 2),
                                             LEFT_HIT + (4,)]),
                  P(0.30, 0.80, "C1", moves=[(0.26, 0.66, 0)]),
                  P(0.50, 0.86, "C2", moves=[(0.38, 0.74, 0), (0.50, 0.82, 3)])],
            away=[P(0.14, 0.465, "B", moves=[(0.16, 0.475, 1)]),
                  P(0.28, 0.465, "B", moves=[(0.26, 0.475, 1)]),
                  P(*mirror(zone(6)), "D")],
            markers=[M(*SET_POINT, "square", "")],
            ball=0,
            ball_to=[(1, 0), ("a0", 1), (2, 2), (0, 3), (1, 4),
                     (ball_spot((0.66, 0.22)), 5)],
        ),
    ]


# ── the 5-1 and the 6-2, rotation by rotation ────────────────────────────────
#
# Positions are the serve-receive formation at the moment their server
# strikes the ball, and every one is legal under the overlap rule: each
# front-row player nearer the net than the back-row player behind her
# (4 before 5, 3 before 6, 2 before 1), and each row in order across
# (4–3–2, 5–6–1). Stacks and hidden setters are only allowed inside that.
# Rotation n has the setter in ROT_ORDER[n - 1], the US convention the
# vb_receive_r* family already uses: 1, 6, 5, 4, 3, 2.

LINEUP = {"S": 1, "O1": 2, "M1": 3, "OP": 4, "O2": 5, "M2": 6}


def _zone_after(start: int, k: int) -> int:
    z = start
    for _ in range(k):
        z = 6 if z == 1 else z - 1
    return z


def _legal_at_serve(by_zone: dict) -> None:
    for front, back in ((4, 5), (3, 6), (2, 1)):
        assert by_zone[front][1] < by_zone[back][1], (front, back, by_zone)
    for left, right in ((4, 3), (3, 2), (5, 6), (6, 1)):
        assert by_zone[left][0] < by_zone[right][0], (left, right, by_zone)


# Per rotation: where each role stands at the serve, who takes the serve,
# the runs after it (the setter's release to the target is added for all),
# who is set and where the ball is put away. Roles: S setter, O1/O2 the
# outside hitters, M the middle in the front row, OP the opposite, L the
# libero in for the middle in the back row.
ROT51 = {
    1: ({"S": (0.90, 0.90), "O1": (0.78, 0.78), "M": (0.44, 0.57),
         "OP": (0.14, 0.57), "O2": (0.22, 0.80), "L": (0.50, 0.82)},
        "L", {"L": [(0.48, 0.78, 0)], "OP": [(0.12, 0.74, 0), (0.17, 0.555, 2)],
              "M": [(0.44, 0.66, 0), (0.52, 0.555, 1)], "O1": [(0.90, 0.72, 1)]},
        "OP", (0.70, 0.22)),
    2: ({"S": (0.64, 0.68), "O1": (0.78, 0.80), "M": (0.86, 0.56),
         "OP": (0.56, 0.56), "O2": (0.20, 0.76), "L": (0.48, 0.82)},
        "O1", {"O1": [(0.76, 0.78, 0)], "OP": [(0.90, 0.72, 0), (0.86, 0.555, 2)],
               "M": [(0.46, 0.66, 0), (0.52, 0.555, 1)], "O2": [(0.12, 0.74, 1)]},
        "OP", (0.82, 0.20)),
    3: ({"S": (0.34, 0.62), "O1": (0.52, 0.82), "M": (0.10, 0.57),
         "OP": (0.86, 0.57), "O2": (0.24, 0.74), "L": (0.80, 0.80)},
        "O1", {"O1": [(0.52, 0.78, 0)], "M": [(0.44, 0.66, 0), (0.52, 0.555, 2)],
               "O2": [(0.12, 0.74, 1)], "OP": [(0.90, 0.72, 1)]},
        "M", (0.46, 0.26)),
    4: ({"S": (0.20, 0.56), "O1": (0.20, 0.80), "M": (0.44, 0.57),
         "OP": (0.90, 0.90), "O2": (0.78, 0.78), "L": (0.50, 0.82)},
        "L", {"L": [(0.48, 0.78, 0)], "M": [(0.44, 0.66, 0), (0.52, 0.555, 1)],
              "O2": [(0.90, 0.72, 1), (0.86, 0.555, 2)]},
        "O2", (0.80, 0.20)),
    5: ({"S": (0.56, 0.56), "O1": (0.20, 0.74), "M": (0.86, 0.56),
         "OP": (0.64, 0.70), "O2": (0.80, 0.80), "L": (0.48, 0.82)},
        "O2", {"O2": [(0.80, 0.76, 0)], "M": [(0.46, 0.66, 0), (0.52, 0.555, 1)],
               "O1": [(0.12, 0.74, 1), (0.17, 0.555, 2)]},
        "O1", (0.70, 0.22)),
    6: ({"S": (0.84, 0.56), "O1": (0.30, 0.74), "M": (0.14, 0.57),
         "OP": (0.12, 0.86), "O2": (0.54, 0.82), "L": (0.80, 0.80)},
        "O2", {"O2": [(0.52, 0.78, 0), (0.50, 0.92, 1), (0.50, 0.70, 2)],
               "M": [(0.44, 0.66, 0), (0.52, 0.555, 1)], "O1": [(0.12, 0.74, 1)]},
        "O2", (0.46, 0.20)),
}
# The 6-2: the same three back-row-setter rotations, the second setter in
# the front row as the opposite (S2), and three front-row hitters every
# time — so the set goes somewhere the 5-1 board did not send it.
ROT62 = {
    1: (ROT51[1][0], "L",
        {"L": [(0.48, 0.78, 0)], "OP": [(0.12, 0.74, 0)],
         "M": [(0.44, 0.66, 0), (0.52, 0.555, 1)],
         "O1": [(0.90, 0.72, 1), (0.86, 0.555, 2)]},
        "O1", (0.80, 0.20)),
    2: (ROT51[2][0], "O1",
        {"O1": [(0.76, 0.78, 0)], "OP": [(0.90, 0.72, 0)],
         "M": [(0.46, 0.66, 0), (0.52, 0.555, 1)],
         "O2": [(0.12, 0.74, 1), (0.17, 0.555, 2)]},
        "O2", (0.70, 0.22)),
    3: (ROT51[3][0], "O1",
        {"O1": [(0.52, 0.78, 0)], "M": [(0.44, 0.66, 0), (0.52, 0.555, 1)],
         "O2": [(0.12, 0.74, 1)], "OP": [(0.90, 0.72, 1), (0.86, 0.555, 2)]},
        "OP", (0.82, 0.20)),
}

ROT51_NAME = _t("5-1 receive rotation", "5-1 接发轮次", "5-1 接發輪次",
                "5-1 レセプション ローテーション", "5-1 리시브 로테이션",
                "5-1 recepción rotación", "5-1 réception rotation",
                "5-1 rotasi terima servis", "5-1 rotasi terima servis",
                "5-1 รับเสิร์ฟ รอบที่", "5-1 đỡ giao bóng vòng")
ROT62_NAME = _t("6-2 receive rotation", "6-2 接发轮次", "6-2 接發輪次",
                "6-2 レセプション ローテーション", "6-2 리시브 로테이션",
                "6-2 recepción rotación", "6-2 réception rotation",
                "6-2 rotasi terima servis", "6-2 rotasi terima servis",
                "6-2 รับเสิร์ฟ รอบที่", "6-2 đỡ giao bóng vòng")
ROT51_NOTE = _t(
    "Stand where the overlap rule allows, not where the rotation chart draws the zones: each player only has to be in front of, or beside, the right two team-mates when the serve is struck. Hide the setter near the target, keep the three passers in one line, and let the switch happen the moment the ball is hit.",
    "按站位犯规的规则站，而不是按轮转表上画的位置站：发球击球的瞬间，每个人只需要在规定的那两名队友前面或旁边。二传藏在目标点附近，三个接发球的人站成一线，球一发出就换位。",
    "按站位犯規的規則站，而不是按輪轉表上畫的位置站：發球擊球的瞬間，每個人只需要在規定的那兩名隊友前面或旁邊。二傳藏在目標點附近，三個接發球的人站成一線，球一發出就換位。",
    "ローテーション表の位置ではなく、反則にならない位置に立つ。サーブが打たれる瞬間、各選手は決められた2人の前か横にいればよい。セッターはターゲット近くに隠し、3人のレシーバーは一列に、打たれた瞬間にスイッチ。",
    "로테이션 표의 자리가 아니라 포지션 폴트가 안 나는 자리에 선다. 서브 순간 각자는 정해진 두 동료의 앞이나 옆에만 있으면 된다. 세터는 목표 근처에 숨기고, 세 리시버는 한 줄로, 서브가 맞는 순간 스위치.",
    "Colócate donde lo permite la regla de posición, no donde el cuadro de rotación dibuja las zonas: en el saque, cada jugador solo tiene que estar delante o al lado de los dos compañeros que le corresponden. Esconde al colocador cerca del objetivo, los tres receptores en línea y el cambio en cuanto se golpea.",
    "Place-toi là où la règle de position le permet, pas là où le tableau de rotation dessine les zones : au service, chaque joueur doit seulement être devant ou à côté des deux bons coéquipiers. Cache le passeur près de la cible, aligne les trois réceptionneurs et permute dès la frappe.",
    "Berdiri sesuai aturan posisi, bukan sesuai gambar zona di tabel rotasi: saat servis dipukul, tiap pemain cukup berada di depan atau di samping dua rekan yang tepat. Sembunyikan tosser dekat target, tiga penerima satu garis, dan bertukar posisi begitu bola dipukul.",
    "Berdiri mengikut peraturan kedudukan, bukan mengikut zon dalam carta putaran: ketika servis dipukul, setiap pemain hanya perlu berada di hadapan atau di sisi dua rakan yang betul. Sembunyikan pengumpan dekat sasaran, tiga penerima sebaris, dan bertukar sebaik bola dipukul.",
    "ยืนตามที่กฎการยืนผิดตำแหน่งอนุญาต ไม่ใช่ตามโซนในตารางหมุน ตอนเสิร์ฟแต่ละคนแค่ต้องอยู่หน้าหรือข้างเพื่อนสองคนที่กำหนด ซ่อนเซตเตอร์ใกล้เป้า ผู้รับสามคนเรียงแถว และสลับตำแหน่งทันทีที่บอลถูกตี",
    "Đứng theo luật lỗi vị trí cho phép, không theo ô vẽ trên bảng xoay vòng: lúc phát bóng, mỗi người chỉ cần ở trước hoặc cạnh đúng hai đồng đội. Giấu chuyền hai gần điểm chuyền, ba người đỡ một hàng, và đổi chỗ ngay khi bóng được đánh.")
ROT62_NOTE = _t(
    "In a 6-2 the setter always comes from the back row, so there are three front-row hitters in every rotation. When she reaches the front row she becomes the opposite and the other setter takes over from the back: rotations 4 to 6 are these three boards with S1 and S2 swapped.",
    "6-2 体系里二传永远从后排插上，所以每一轮前排都有三个攻手。二传转到前排就当接应二传进攻，另一名二传从后排接手：第 4 到第 6 轮，就是这三块板把 S1 和 S2 对调。",
    "6-2 體系裡二傳永遠從後排插上，所以每一輪前排都有三個攻手。二傳轉到前排就當接應二傳進攻，另一名二傳從後排接手：第 4 到第 6 輪，就是這三塊板把 S1 和 S2 對調。",
    "6-2ではセッターは常に後衛から上がるので、どのローテーションでも前衛にアタッカーが3人いる。前衛に回ったセッターはオポジットになり、もう1人が後衛から上げる。ローテーション4〜6はこの3枚のS1とS2を入れ替えたものだ。",
    "6-2에서는 세터가 항상 후위에서 올라오므로 모든 로테이션에서 전위 공격수가 셋이다. 전위로 온 세터는 아포짓이 되고 다른 세터가 후위에서 이어받는다. 로테이션 4~6은 이 세 장에서 S1과 S2를 바꾼 것이다.",
    "En un 6-2 el colocador siempre sale de la zaga, así que hay tres atacantes delanteros en cada rotación. Cuando llega a la red pasa a ser el opuesto y el otro colocador toma el relevo desde atrás: las rotaciones 4 a 6 son estas tres con S1 y S2 cambiados.",
    "En 6-2, le passeur vient toujours de l'arrière, donc il y a trois attaquants avant à chaque rotation. Arrivé à l'avant, il devient pointu et l'autre passeur prend le relais depuis l'arrière : les rotations 4 à 6 sont ces trois tableaux avec S1 et S2 échangés.",
    "Dalam 6-2 tosser selalu datang dari barisan belakang, jadi ada tiga penyerang depan di setiap rotasi. Saat ia tiba di depan, ia menjadi opposite dan tosser lainnya mengambil alih dari belakang: rotasi 4–6 adalah tiga papan ini dengan S1 dan S2 ditukar.",
    "Dalam 6-2 pengumpan sentiasa datang dari barisan belakang, jadi ada tiga penyerang hadapan dalam setiap putaran. Apabila dia tiba di hadapan, dia menjadi opposite dan pengumpan lain mengambil alih dari belakang: putaran 4–6 ialah tiga papan ini dengan S1 dan S2 ditukar.",
    "ในระบบ 6-2 เซตเตอร์ขึ้นมาจากแดนหลังเสมอ ทุกรอบจึงมีตัวตบแดนหน้าสามคน เมื่อเซตเตอร์หมุนมาแดนหน้าจะกลายเป็นบีอีกคนจะเซตจากแดนหลังแทน รอบที่ 4 ถึง 6 คือสามกระดานนี้โดยสลับ S1 กับ S2",
    "Trong 6-2, chuyền hai luôn lên từ hàng sau nên vòng nào cũng có ba người đập hàng trên. Khi lên hàng trên, người đó thành đối chuyền và chuyền hai kia đảm nhận từ hàng sau: vòng 4 đến 6 là ba bảng này với S1 và S2 đổi chỗ.")

_ROT_SETUP_51 = _t(
    "Rotation {r}: the setter (S) starts in zone {z}. O1 and O2 are the outside hitters, M the front-row middle, OP the opposite, L the libero in for the back-row middle; their server (SV) stands behind their end line. Everyone is in a legal position when the serve is struck",
    "第 {r} 轮：二传（S）在 {z} 号位。O1、O2 是主攻，M 是前排副攻，OP 是接应，L 是替换后排副攻的自由人；对方发球员（SV）站在对方端线后。发球击球时所有人站位合法",
    "第 {r} 輪：二傳（S）在 {z} 號位。O1、O2 是主攻，M 是前排副攻，OP 是接應，L 是替換後排副攻的自由人；對方發球員（SV）站在對方端線後。發球擊球時所有人站位合法",
    "ローテーション{r}：セッター（S）はゾーン{z}から。O1・O2はアウトサイド、Mは前衛ミドル、OPはオポジット、Lは後衛ミドルに代わるリベロ。相手サーバー（SV）はエンドラインの後ろ。サーブの瞬間、全員が正しい位置にいる",
    "로테이션 {r}: 세터(S)는 {z}번 자리에서 시작한다. O1·O2는 아웃사이드, M은 전위 미들, OP는 아포짓, L은 후위 미들 대신 들어간 리베로; 상대 서버(SV)는 엔드라인 뒤에 선다. 서브 순간 모두 정위치다",
    "Rotación {r}: el colocador (S) empieza en zona {z}. O1 y O2 son los receptores-atacantes, M el central delantero, OP el opuesto, L el líbero en lugar del central zaguero; su sacador (SV) está detrás de su línea de fondo. Todos en posición legal en el momento del saque",
    "Rotation {r} : le passeur (S) part de la zone {z}. O1 et O2 sont les réceptionneurs-attaquants, M le central avant, OP le pointu, L le libéro à la place du central arrière ; leur serveur (SV) est derrière sa ligne de fond. Tout le monde est en position régulière à la frappe du service",
    "Rotasi {r}: tosser (S) mulai di zona {z}. O1 dan O2 pemain sayap, M middle barisan depan, OP opposite, L libero pengganti middle belakang; server lawan (SV) di belakang garis akhir mereka. Semua dalam posisi sah saat servis dipukul",
    "Putaran {r}: pengumpan (S) bermula di zon {z}. O1 dan O2 pemain sayap, M pemain tengah barisan hadapan, OP opposite, L libero menggantikan pemain tengah belakang; pelayan servis lawan (SV) di belakang garisan hujung mereka. Semua dalam kedudukan sah ketika servis dipukul",
    "รอบที่ {r}: เซตเตอร์ (S) เริ่มที่ตำแหน่ง {z} O1 และ O2 คือตัวตบหัวเสา M ตัวบล็อกกลางแดนหน้า OP บีหรือตัวตรงข้าม L ลิเบโรแทนตัวกลางแดนหลัง ผู้เสิร์ฟฝ่ายตรงข้าม (SV) ยืนหลังเส้นหลังของเขา ตอนเสิร์ฟทุกคนยืนถูกตำแหน่ง",
    "Vòng {r}: chuyền hai (S) bắt đầu ở vị trí {z}. O1, O2 là chủ công, M là phụ công hàng trên, OP là đối chuyền, L là libero thay phụ công hàng sau; người phát bóng đối phương (SV) đứng sau vạch cuối sân của họ. Mọi người đứng đúng vị trí lúc phát bóng")
_ROT_SETUP_62 = _t(
    "Rotation {r} (and {r3} with the setters swapped): S1 sets from zone {z}; S2, the second setter, is in the front row and hits as the opposite. O1 and O2 are the outside hitters, M the front-row middle, L the libero; their server (SV) stands behind their end line. Everyone is in a legal position when the serve is struck",
    "第 {r} 轮（两名二传对调即第 {r3} 轮）：S1 从 {z} 号位插上组织；S2 是另一名二传，在前排当接应进攻。O1、O2 是主攻，M 是前排副攻，L 是自由人；对方发球员（SV）站在对方端线后。发球击球时所有人站位合法",
    "第 {r} 輪（兩名二傳對調即第 {r3} 輪）：S1 從 {z} 號位插上組織；S2 是另一名二傳，在前排當接應進攻。O1、O2 是主攻，M 是前排副攻，L 是自由人；對方發球員（SV）站在對方端線後。發球擊球時所有人站位合法",
    "ローテーション{r}（セッターを入れ替えれば{r3}）：S1がゾーン{z}から上げる。S2はもう1人のセッターで前衛のオポジットとして打つ。O1・O2はアウトサイド、Mは前衛ミドル、Lはリベロ。相手サーバー（SV）はエンドラインの後ろ。サーブの瞬間、全員が正しい位置にいる",
    "로테이션 {r} (세터를 바꾸면 {r3}): S1이 {z}번 자리에서 올린다. 두 번째 세터 S2는 전위에서 아포짓으로 공격한다. O1·O2는 아웃사이드, M은 전위 미들, L은 리베로; 상대 서버(SV)는 엔드라인 뒤에 선다. 서브 순간 모두 정위치다",
    "Rotación {r} (y {r3} con los colocadores cambiados): S1 coloca desde zona {z}; S2, el segundo colocador, está delante y ataca como opuesto. O1 y O2 son los receptores-atacantes, M el central delantero, L el líbero; su sacador (SV) está detrás de su línea de fondo. Todos en posición legal en el momento del saque",
    "Rotation {r} (et {r3} avec les passeurs échangés) : S1 passe depuis la zone {z} ; S2, le second passeur, est à l'avant et attaque en pointu. O1 et O2 sont les réceptionneurs-attaquants, M le central avant, L le libéro ; leur serveur (SV) est derrière sa ligne de fond. Tout le monde est en position régulière à la frappe du service",
    "Rotasi {r} (dan {r3} bila tosser ditukar): S1 mengumpan dari zona {z}; S2, tosser kedua, di barisan depan dan menyerang sebagai opposite. O1 dan O2 pemain sayap, M middle depan, L libero; server lawan (SV) di belakang garis akhir mereka. Semua dalam posisi sah saat servis dipukul",
    "Putaran {r} (dan {r3} jika pengumpan ditukar): S1 mengumpan dari zon {z}; S2, pengumpan kedua, di barisan hadapan dan menyerang sebagai opposite. O1 dan O2 pemain sayap, M pemain tengah hadapan, L libero; pelayan servis lawan (SV) di belakang garisan hujung mereka. Semua dalam kedudukan sah ketika servis dipukul",
    "รอบที่ {r} (และรอบที่ {r3} เมื่อสลับเซตเตอร์): S1 เซตจากตำแหน่ง {z} S2 เซตเตอร์อีกคนอยู่แดนหน้าและตบในฐานะบี O1 และ O2 คือตัวตบหัวเสา M ตัวบล็อกกลางแดนหน้า L ลิเบโร ผู้เสิร์ฟฝ่ายตรงข้าม (SV) ยืนหลังเส้นหลังของเขา ตอนเสิร์ฟทุกคนยืนถูกตำแหน่ง",
    "Vòng {r} (và vòng {r3} khi đổi hai chuyền hai): S1 chuyền từ vị trí {z}; S2, chuyền hai thứ hai, ở hàng trên và đập như đối chuyền. O1, O2 là chủ công, M là phụ công hàng trên, L là libero; người phát bóng đối phương (SV) đứng sau vạch cuối sân của họ. Mọi người đứng đúng vị trí lúc phát bóng")

_ROLE_ORDER = ("S", "O1", "M", "OP", "O2", "L")

# The setpiece purpose line is about serving; these boards are about where
# the receiving six stand, so they say so.
ROT_PURPOSE = _t(
    "Learn the receive formation of every rotation: where each player stands when the serve is struck, and where she goes the moment it is.",
    "把每一轮的接发球站位练熟：发球击球时每个人站在哪里，球一发出又跑到哪里。",
    "把每一輪的接發球站位練熟：發球擊球時每個人站在哪裡，球一發出又跑到哪裡。",
    "各ローテーションのレセプション隊形を身につける。サーブが打たれる瞬間に誰がどこに立ち、打たれた瞬間にどこへ動くか。",
    "로테이션마다 리시브 대형을 익힌다. 서브 순간 각자 어디에 서고, 서브가 맞는 순간 어디로 가는지.",
    "Aprender la formación de recepción de cada rotación: dónde está cada jugador cuando se golpea el saque y adónde va en ese mismo momento.",
    "Apprendre la formation de réception de chaque rotation : où se tient chaque joueur à la frappe du service, et où il part à cet instant.",
    "Menguasai formasi penerimaan setiap rotasi: di mana tiap pemain berdiri saat servis dipukul, dan ke mana ia bergerak saat itu juga.",
    "Menguasai formasi penerimaan setiap putaran: di mana setiap pemain berdiri ketika servis dipukul, dan ke mana dia bergerak pada saat itu.",
    "ฝึกรูปแบบรับเสิร์ฟของทุกรอบ ใครยืนตรงไหนตอนเสิร์ฟถูกตี และเคลื่อนไปที่ไหนทันทีที่บอลถูกตี",
    "Thuộc đội hình đỡ giao bóng của từng vòng: mỗi người đứng đâu lúc bóng được phát và di chuyển đi đâu ngay khi bóng được đánh.")


def _rotation_board(system: str, r: int, spec, free: bool) -> Drill:
    pos, recv, runs, to, kill = spec
    k = r - 1
    zs = ROT_ORDER[k]
    # Which zone every role is in this rotation, to prove the board legal.
    zone_of = {}
    for role, z0 in LINEUP.items():
        zone_of[role] = _zone_after(z0, k)
    front_mid = "M1" if zone_of["M1"] in FRONT_ROW else "M2"
    back_mid = "M2" if front_mid == "M1" else "M1"
    roles_zone = {"S": zone_of["S"], "O1": zone_of["O1"], "OP": zone_of["OP"],
                  "O2": zone_of["O2"], "M": zone_of[front_mid], "L": zone_of[back_mid]}
    assert roles_zone["S"] == zs
    _legal_at_serve({roles_zone[role]: pos[role] for role in _ROLE_ORDER})
    labels = {"S": "S1", "OP": "S2"} if system == "62" else {}
    home = []
    for role in _ROLE_ORDER:
        moves = list(runs.get(role, []))
        if role == "S":
            moves = [SET_POINT + (0,)]
        home.append(P(*pos[role], labels.get(role, role), moves=moves))
    idx = {role: i for i, role in enumerate(_ROLE_ORDER)}
    tmpl = _ROT_SETUP_62 if system == "62" else _ROT_SETUP_51
    setup = {loc: text.format(r=r, z=zs, r3=r + 3) for loc, text in tmpl.items()}
    return Drill(
        id=f"vb_rot{system}_r{r}", category="setpiece", minutes=12, rel=True,
        free=free, level="advanced" if system == "62" else "development",
        off_surface=True,
        name=suffixed(ROT62_NAME if system == "62" else ROT51_NAME, f"{r}"),
        note=ROT62_NOTE if system == "62" else ROT51_NOTE,
        setup=setup, purpose=ROT_PURPOSE,
        home=home, away=[_sv()],
        markers=[M(*SET_POINT, "square", "")],
        ball=SERVE_SPOT,
        ball_to=[(idx[recv], 0), (idx["S"], 1), (idx[to], 2), (ball_spot(kill), 3)],
    )


def rotation_family() -> list[Drill]:
    return ([_rotation_board("51", r, ROT51[r], r == 1) for r in range(1, 7)]
            + [_rotation_board("62", r, ROT62[r], False) for r in range(1, 4)])


# ── game-like ────────────────────────────────────────────────────────────────

WASH_NAME = _t("Wash drill 6v6", "两球连胜对抗 6v6", "兩球連勝對抗 6v6",
               "ウォッシュドリル 6v6", "워시 드릴 6v6", "Ejercicio wash 6v6",
               "Exercice wash 6v6", "Latihan wash 6v6", "Latihan wash 6v6",
               "แบบฝึกวอช 6v6", "Bài wash 6v6")
WASH_NOTE = _t(
    "A big point only for winning both balls — the serve-receive rally and the free ball that follows it. One good side-out is half a point; the transition ball decides the wash.",
    "只有两球都赢——接发球那一分和紧接着的调整球——才算一个大分。打好一次接发只算半分，决定胜负的是转换的那一球。",
    "只有兩球都贏——接發球那一分和緊接著的調整球——才算一個大分。打好一次接發只算半分，決定勝負的是轉換的那一球。",
    "サーブレシーブのラリーと、続くフリーボールの両方を取って初めて大きな1点。良いサイドアウト1本は半分にすぎず、勝負を決めるのは切り返しの1本だ。",
    "서브 리시브 랠리와 이어지는 프리볼을 모두 이겨야 큰 1점이다. 좋은 사이드아웃 하나는 반 점일 뿐, 승부는 전환 공 하나가 가른다.",
    "Punto grande solo si se ganan los dos balones: la recepción y el balón libre que la sigue. Un buen side-out es medio punto; el balón de transición decide el wash.",
    "Un gros point seulement si les deux ballons sont gagnés : le point en réception et la balle libre qui suit. Un bon side-out ne vaut qu'un demi-point ; la transition décide du wash.",
    "Poin besar hanya jika kedua bola dimenangkan — reli terima servis dan bola bebas sesudahnya. Satu side-out bagus hanya setengah poin; bola transisi yang menentukan.",
    "Mata besar hanya jika kedua-dua bola dimenangi — rali terima servis dan bola bebas selepasnya. Satu side-out yang baik hanya separuh mata; bola peralihan yang menentukan.",
    "ได้แต้มใหญ่ก็ต่อเมื่อชนะทั้งสองลูก คือลูกรับเสิร์ฟและฟรีบอลที่ตามมา ไซด์เอาต์ดี ๆ หนึ่งครั้งเป็นแค่ครึ่งแต้ม ลูกเปลี่ยนเกมคือตัวตัดสิน",
    "Chỉ được điểm lớn khi thắng cả hai bóng — pha đỡ giao bóng và quả bóng tự do ngay sau đó. Một lần giành quyền phát tốt chỉ là nửa điểm; bóng chuyển đổi mới quyết định.")
KING_NAME = _t("King of the court", "擂台赛", "擂台賽", "キング・オブ・ザ・コート",
               "킹 오브 더 코트", "Rey de la pista", "Roi du terrain",
               "Raja lapangan", "Raja gelanggang", "ราชาแห่งคอร์ท", "Vua sân")
KING_NOTE = _t(
    "Every rally is a final: win it on the kings' side to score, win it on the challengers' side to take the court. A safe free ball over the net is a rally handed to the other pair.",
    "每一球都是决赛：在擂主一侧赢球才得分，在挑战者一侧赢球就把擂台抢过来。保守地送过网的调整球，等于把这一分让给对面。",
    "每一球都是決賽：在擂主一側贏球才得分，在挑戰者一側贏球就把擂台搶過來。保守地送過網的調整球，等於把這一分讓給對面。",
    "毎ラリーが決勝。キング側で取れば得点、チャレンジャー側で取ればコートを奪う。安全に返したフリーボールは相手ペアに渡したラリーだ。",
    "모든 랠리가 결승이다. 킹 쪽에서 이기면 득점, 도전자 쪽에서 이기면 코트를 빼앗는다. 안전하게 넘긴 프리볼은 상대에게 건넨 랠리다.",
    "Cada punto es una final: ganarlo en el lado de los reyes puntúa, ganarlo en el de los aspirantes les da la pista. Un balón libre seguro por encima de la red es un punto regalado.",
    "Chaque échange est une finale : gagné côté rois, il compte ; gagné côté challengers, il prend le terrain. Une balle libre prudente au-dessus du filet est un échange offert.",
    "Setiap reli adalah final: menang di sisi raja mencetak poin, menang di sisi penantang merebut lapangan. Bola bebas yang aman ke seberang net adalah reli yang diberikan.",
    "Setiap rali ialah final: menang di sisi raja mendapat mata, menang di sisi pencabar merampas gelanggang. Bola bebas yang selamat ke seberang jaring ialah rali yang diberi.",
    "ทุกแต้มคือรอบชิง ชนะฝั่งราชาได้แต้ม ชนะฝั่งผู้ท้าชิงได้คอร์ทไป ฟรีบอลเซฟ ๆ ข้ามเน็ตคือแต้มที่ยกให้อีกคู่",
    "Mỗi pha bóng là một trận chung kết: thắng ở phía vua thì ghi điểm, thắng ở phía người thách đấu thì chiếm sân. Bóng tự do an toàn qua lưới là pha bóng tặng cho đối phương.")


def game_more() -> list[Drill]:
    # Rotation 1 in three-passer receive against six in their base.
    home = [P(0.90, 0.90, "S", moves=[SET_POINT + (0,)]),
            P(0.78, 0.78, "O1", moves=[(0.90, 0.72, 1)]),
            P(0.44, 0.57, "M", moves=[(0.44, 0.66, 0), (0.52, 0.555, 1)]),
            P(0.14, 0.57, "OP", moves=[(0.12, 0.74, 0), (0.17, 0.555, 2)]),
            P(0.22, 0.80, "O2"),
            P(0.50, 0.82, "L", moves=[(0.48, 0.78, 0)])]
    their_server = (0.20, FAR_BACK)
    away = [P(*their_server, "1", moves=[(0.20, 0.12, 0)]),
            P(*mirror(zone(2)), "2", moves=[(0.20, 0.465, 2)]),
            P(*mirror(zone(3)), "3", moves=[(0.32, 0.465, 2)]),
            P(*mirror(zone(4)), "4"),
            P(*mirror(zone(5)), "5"),
            P(0.50, 0.08, "6")]
    return [
        Drill(
            id="vb_game_wash", category="ssg", minutes=20, rel=True,
            level="development", off_surface=True,
            name=WASH_NAME, note=WASH_NOTE,
            home=home, away=away,
            markers=[M(*SET_POINT, "square", "")],
            ball=their_server,
            ball_to=[(5, 0), (0, 1), (3, 2), (ball_spot((0.62, 0.22)), 3)],
        ),
        Drill(
            id="vb_game_king", category="ssg", minutes=15, rel=True,
            free=True, level="development", off_surface=True,
            name=KING_NAME, note=KING_NOTE,
            # The kings hold the near side. The challenging pair serve from
            # behind their line; the next pairs wait behind it too.
            home=[P(0.30, 0.74, "K1", moves=[(0.32, 0.78, 0), (0.30, 0.56, 2)]),
                  P(0.68, 0.84, "K2", moves=[(0.60, 0.60, 1)])],
            away=[P(0.40, FAR_BACK, "C1", moves=[(0.36, 0.20, 0)]),
                  P(0.66, 0.28, "C2", moves=[(0.70, 0.22, 3)]),
                  P(0.80, FAR_BACK, "C3"),
                  P(0.92, FAR_BACK, "C4")],
            ball=(0.40, FAR_BACK),
            ball_to=[(0, 0), (1, 1), (0, 2), ("a1", 3)],
        ),
    ]


def volleyball_library() -> list[Drill]:
    return (warmup_family() + receive_family() + setting_family()
            + setter_family() + freeball_family() + attack_family()
            + block_family() + defense_family() + serve_family()
            + game_family() + gaps_family()
            + warmup_more() + passing_family() + receive_patterns()
            + oos_family() + setter_footwork() + shot_family()
            + attack_more() + combo_family() + middle_block_family()
            + dig_family() + counter_family() + rotation_family()
            + game_more())
