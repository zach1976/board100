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
    """Reflect a home-side point through the net onto the away side."""
    return (pt[0], 1.0 - pt[1])


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
        ("pipe", "the pipe", (0.50, 0.92), (0.50, 0.86), (0.50, 0.58)),
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


def block_family() -> list[Drill]:
    specs = [("solo", "solo", 1, 0.22), ("double_outside", "double outside", 2, 0.24),
             ("double_middle", "double middle", 2, 0.50), ("triple", "triple", 3, 0.50)]
    out = []
    for key, label, n, x in specs:
        blockers = [P(x + (i - (n - 1) / 2) * 0.10, 0.545, "B",
                      moves=[(x + (i - (n - 1) / 2) * 0.085, 0.53, 1)])
                    for i in range(n)]
        out.append(Drill(
            id=f"vb_block_{key}", category="defending", minutes=10, rel=True,
            free=(key == "double_outside"),
            name=suffixed(BLOCK_NAME, label), note=BLOCK_NOTE,
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
        ("perimeter", "perimeter",
         [(0.16, 0.86), (0.50, 0.94), (0.84, 0.86), (0.30, 0.70)]),
        ("rotation", "rotation",
         [(0.14, 0.74), (0.42, 0.92), (0.80, 0.88), (0.60, 0.70)]),
        ("man_up", "man-up",
         [(0.34, 0.62), (0.18, 0.86), (0.52, 0.92), (0.84, 0.84)]),
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


def volleyball_library() -> list[Drill]:
    return (warmup_family() + receive_family() + setting_family()
            + setter_family() + freeball_family() + attack_family()
            + block_family() + defense_family() + serve_family()
            + game_family())
