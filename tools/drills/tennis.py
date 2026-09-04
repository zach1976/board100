"""The tennis library.

The court is portrait with the net at y=0.5 and home at the bottom. Almost
every pattern here is about the same two things: where the ball is hit from,
and whether the player got back to the middle before the next one arrives —
so most drills carry the recovery step as their last phase.
"""
from .engine import Drill, M, P, suffixed

BASE_C = (0.50, 0.97)
BASE_D, BASE_A = (0.72, 0.97), (0.28, 0.97)   # deuce / ad corners, home side
WIDE_D, WIDE_A = (0.93, 0.93), (0.07, 0.93)
SERVICE_D, SERVICE_A = (0.74, 0.62), (0.26, 0.62)   # service box centres
NET_D, NET_A = (0.68, 0.58), (0.32, 0.58)


def mirror(pt):
    return (pt[0], 1.0 - pt[1])


RALLY_NAME = {
    "en": "Rally", "en-GB": "Rally", "zh-CN": "对拉", "zh-TW": "對拉",
    "ja-JP": "ラリー", "ko-KR": "랠리", "es-ES": "Peloteo", "fr-FR": "Échange",
    "id-ID": "Reli", "ms-MY": "Rali", "th-TH": "การโต้", "vi-VN": "Đôi công",
}
RALLY_NOTE = {
    "en": "Recover to the middle of the angles they have, not to the centre "
          "mark. Standing on the T after a wide ball just looks tidy.",
    "en-GB": "Recover to the middle of the angles they have, not to the centre "
             "mark. Standing on the T after a wide ball just looks tidy.",
    "zh-CN": "回位要回到对手可能角度的中间，不是回到中点标记。打完大角度还站在中点，只是看起来整齐而已。",
    "zh-TW": "回位要回到對手可能角度的中間，不是回到中點標記。打完大角度還站在中點，只是看起來整齊而已。",
    "ja-JP": "戻る先はセンターマークではなく、相手が持つ角度の真ん中。ワイドの後にセンターに立つのは見た目が整っているだけ。",
    "ko-KR": "센터 마크가 아니라 상대가 가진 각도의 한가운데로 복귀하라. 와이드 이후 T에 서 있는 건 그저 깔끔해 보일 뿐이다.",
    "es-ES": "Recupera al centro de los ángulos que tiene el rival, no a la "
             "marca central: quedarse en la T tras una bola abierta solo queda bonito.",
    "fr-FR": "Replace-toi au milieu des angles adverses, pas sur la marque "
             "centrale : rester sur le T après une balle croisée est juste esthétique.",
    "id-ID": "Pulih ke tengah sudut yang dimiliki lawan, bukan ke tanda tengah.",
    "ms-MY": "Kembali ke tengah sudut yang ada pada lawan, bukan ke tanda tengah.",
    "th-TH": "กลับมายืนกลางมุมที่คู่แข่งมี ไม่ใช่กลับมาที่จุดกลางสนาม",
    "vi-VN": "Về giữa các góc mà đối thủ có, không phải về vạch giữa.",
}


def rally_family() -> list[Drill]:
    """The four rally patterns a baseline point is actually built from."""
    specs = [
        ("crosscourt_fh", "cross-court forehand", BASE_D, mirror(BASE_D)),
        ("crosscourt_bh", "cross-court backhand", BASE_A, mirror(BASE_A)),
        ("down_the_line", "down the line", BASE_D, mirror(BASE_A)),
        ("figure_eight", "figure of eight", BASE_C, mirror(BASE_D)),
    ]
    out = []
    for key, label, frm, to in specs:
        out.append(Drill(
            id=f"tn_rally_{key}", category="possession", minutes=10, rel=True,
            free=(key in ("crosscourt_fh", "figure_eight")),
            name=suffixed(RALLY_NAME, label), note=RALLY_NOTE,
            home=[P(*BASE_C, "1", moves=[frm + (0,), BASE_C + (1,)])],
            away=[P(*mirror(BASE_C), "2", moves=[to + (1,), mirror(BASE_C) + (2,)])],
            markers=[M(*BASE_C, "cone", ""), M(*mirror(BASE_C), "cone", "")],
            ball=0,
        ))
    return out


SERVE_NAME = {
    "en": "Serve", "en-GB": "Serve", "zh-CN": "发球", "zh-TW": "發球",
    "ja-JP": "サーブ", "ko-KR": "서브", "es-ES": "Saque", "fr-FR": "Service",
    "id-ID": "Servis", "ms-MY": "Servis", "th-TH": "การเสิร์ฟ", "vi-VN": "Giao bóng",
}
SERVE_NOTE = {
    "en": "Same toss, different targets. A toss that moves with the target "
          "tells the returner where the ball is going before you hit it.",
    "en-GB": "Same toss, different targets. A toss that moves with the target "
             "tells the returner where the ball is going before you hit it.",
    "zh-CN": "抛球一样，落点不同。抛球跟着落点变，等于在你击球之前就告诉接发球的人球去哪。",
    "zh-TW": "拋球一樣，落點不同。拋球跟著落點變，等於在你擊球之前就告訴接發球的人球去哪。",
    "ja-JP": "トスは同じ、狙いは別。狙いに合わせてトスが動けば、打つ前にコースを教えているのと同じ。",
    "ko-KR": "토스는 같게, 목표는 다르게. 목표에 따라 토스가 움직이면 치기 전에 코스를 알려주는 셈이다.",
    "es-ES": "Mismo lanzamiento, distintos objetivos: si el lanzamiento se "
             "mueve con el objetivo, cantas la dirección antes de golpear.",
    "fr-FR": "Même lancer, cibles différentes : un lancer qui suit la cible "
             "annonce la direction avant même la frappe.",
    "id-ID": "Lambungan sama, target berbeda.",
    "ms-MY": "Lambungan sama, sasaran berbeza.",
    "th-TH": "โยนบอลเหมือนกัน แต่เป้าต่างกัน ถ้าการโยนเปลี่ยนตามเป้า เท่ากับบอกทางก่อนตี",
    "vi-VN": "Tung bóng như nhau, mục tiêu khác nhau.",
}


def serve_family() -> list[Drill]:
    specs = [("deuce_wide", "deuce wide", BASE_D, (0.05, 0.40)),
             ("deuce_t", "deuce down the T", BASE_D, (0.44, 0.40)),
             ("deuce_body", "deuce at the body", BASE_D, (0.24, 0.38)),
             ("ad_wide", "ad wide", BASE_A, (0.95, 0.40)),
             ("ad_t", "ad down the T", BASE_A, (0.56, 0.40))]
    out = []
    for key, label, stand, target in specs:
        out.append(Drill(
            id=f"tn_serve_{key}", category="setpiece", minutes=8, rel=True,
            free=(key == "deuce_wide"), off_surface=True,
            name=suffixed(SERVE_NAME, label), note=SERVE_NOTE,
            home=[P(stand[0], 1.03, "S", moves=[(stand[0], 0.94, 0), (0.5, 0.99, 1)])],
            away=[P(1 - stand[0], -0.03, "R",
                    moves=[(target[0], target[1] - 0.16, 1)])],
            markers=[M(*target, "zone", "")],
            ball=0,
        ))
    return out


PLUS_ONE_NAME = {
    "en": "Plus one", "en-GB": "Plus one", "zh-CN": "第一拍衔接",
    "zh-TW": "第一拍銜接", "ja-JP": "プラスワン", "ko-KR": "플러스 원",
    "es-ES": "Golpe siguiente", "fr-FR": "Coup d'après",
    "id-ID": "Pukulan lanjutan", "ms-MY": "Pukulan seterusnya",
    "th-TH": "ลูกต่อเนื่อง", "vi-VN": "Cú tiếp theo",
}
PLUS_ONE_NOTE = {
    "en": "Decide the second ball before you hit the first. Most points end "
          "on shot three, and nobody improvises well that early.",
    "en-GB": "Decide the second ball before you hit the first. Most points end "
             "on shot three, and nobody improvises well that early.",
    "zh-CN": "打第一拍之前就定好第二拍。大多数分在第三拍就结束了，没人能在那么早的时候临场发挥得好。",
    "zh-TW": "打第一拍之前就定好第二拍。大多數分在第三拍就結束了，沒人能在那麼早的時候臨場發揮得好。",
    "ja-JP": "1球目を打つ前に2球目を決めておく。ほとんどのポイントは3球目で終わり、そんな早い段階でのアドリブは誰も上手くない。",
    "ko-KR": "첫 공을 치기 전에 둘째 공을 정해둬라. 대부분의 포인트는 세 번째 샷에서 끝난다.",
    "es-ES": "Decide la segunda bola antes de golpear la primera: casi todos "
             "los puntos acaban en el tercer golpe.",
    "fr-FR": "Choisis la deuxième balle avant de frapper la première : la "
             "plupart des points finissent au troisième coup.",
    "id-ID": "Putuskan bola kedua sebelum memukul yang pertama.",
    "ms-MY": "Tentukan bola kedua sebelum memukul yang pertama.",
    "th-TH": "ตัดสินใจลูกที่สองก่อนตีลูกแรก แต้มส่วนใหญ่จบที่ลูกที่สาม",
    "vi-VN": "Quyết định quả thứ hai trước khi đánh quả đầu.",
}


def plus_one_family() -> list[Drill]:
    specs = [
        ("serve_plus_one", "serve", BASE_D, (0.30, 0.86), (0.10, 0.30)),
        ("return_plus_one", "return", BASE_A, (0.62, 0.90), (0.90, 0.28)),
        ("inside_out", "inside-out forehand", BASE_A, (0.34, 0.92), (0.90, 0.30)),
        ("approach", "approach", BASE_C, (0.62, 0.72), (0.70, 0.56)),
    ]
    out = []
    for key, label, start, second, target in specs:
        out.append(Drill(
            id=f"tn_{key}", category="attacking", minutes=10, rel=True,
            free=(key in ("serve_plus_one", "approach")),
            name=suffixed(PLUS_ONE_NAME, label), note=PLUS_ONE_NOTE,
            home=[P(*start, "1", moves=[second + (1,), (0.5, min(second[1], 0.94), 2)])],
            away=[P(*mirror(BASE_C), "2",
                    moves=[(0.34, 0.06, 0), (target[0], target[1], 2)])],
            markers=[M(*target, "zone", "")],
            ball=0,
        ))
    return out


NET_NAME = {
    "en": "At the net", "en-GB": "At the net", "zh-CN": "网前",
    "zh-TW": "網前", "ja-JP": "ネットプレー", "ko-KR": "네트 플레이",
    "es-ES": "En la red", "fr-FR": "Au filet", "id-ID": "Di depan net",
    "ms-MY": "Di jaring", "th-TH": "หน้าเน็ต", "vi-VN": "Trên lưới",
}
NET_NOTE = {
    "en": "Move forward through the volley. A volley hit standing still is a "
          "volley hit from wherever you happened to stop.",
    "en-GB": "Move forward through the volley. A volley hit standing still is "
             "a volley hit from wherever you happened to stop.",
    "zh-CN": "截击要向前迎着打。站着打的截击，只是从你恰好停下的地方打的球。",
    "zh-TW": "截擊要向前迎著打。站著打的截擊，只是從你恰好停下的地方打的球。",
    "ja-JP": "ボレーは前に出ながら打つ。止まって打つボレーは、たまたま止まった場所から打っただけ。",
    "ko-KR": "발리는 앞으로 나가며 쳐라. 멈춰서 친 발리는 어쩌다 멈춘 자리에서 친 공일 뿐이다.",
    "es-ES": "Avanza a través de la volea: una volea parada es una volea "
             "golpeada desde donde te tocó detenerte.",
    "fr-FR": "Avance à travers la volée : une volée à l'arrêt est frappée là "
             "où tu t'es arrêté par hasard.",
    "id-ID": "Maju melewati voli, jangan diam di tempat.",
    "ms-MY": "Maju menerusi voli, jangan berdiri diam.",
    "th-TH": "ก้าวไปข้างหน้าขณะวอลเลย์ ถ้ายืนนิ่งตี ก็คือตีจากจุดที่บังเอิญหยุด",
    "vi-VN": "Tiến lên khi vô lê, đừng đứng yên.",
}


def net_family() -> list[Drill]:
    specs = [("first_volley", "first volley", (0.56, 0.70), (0.62, 0.60), (0.20, 0.26)),
             ("second_volley", "second volley", (0.62, 0.60), (0.66, 0.55), (0.86, 0.24)),
             ("overhead", "overhead", (0.60, 0.60), (0.56, 0.72), (0.30, 0.18)),
             ("drop_volley", "drop volley", (0.60, 0.60), (0.64, 0.56), (0.72, 0.44))]
    out = []
    for key, label, start, hit, target in specs:
        out.append(Drill(
            id=f"tn_net_{key}", category="finishing", minutes=8, rel=True,
            free=(key == "first_volley"),
            name=suffixed(NET_NAME, label), note=NET_NOTE,
            home=[P(*start, "1", moves=[hit + (1,)])],
            away=[P(*mirror(BASE_C), "2",
                    moves=[(0.40, 0.05, 0), (target[0], target[1] + 0.06, 2)])],
            markers=[M(*target, "zone", "")],
            ball=mirror(BASE_C),        # fed from the far baseline
        ))
    return out


DEFEND_NAME = {
    "en": "Defending", "en-GB": "Defending", "zh-CN": "防守", "zh-TW": "防守",
    "ja-JP": "ディフェンス", "ko-KR": "수비", "es-ES": "Defensa",
    "fr-FR": "Défense", "id-ID": "Bertahan", "ms-MY": "Pertahanan",
    "th-TH": "การรับ", "vi-VN": "Phòng thủ",
}
DEFEND_NOTE = {
    "en": "Height and depth first, angle never. A defensive ball that lands "
          "short is the last shot you play in the point.",
    "en-GB": "Height and depth first, angle never. A defensive ball that lands "
             "short is the last shot you play in the point.",
    "zh-CN": "先要高度和深度，绝不要角度。防守球一旦落浅，就是你这一分打的最后一拍。",
    "zh-TW": "先要高度和深度，絕不要角度。防守球一旦落淺，就是你這一分打的最後一拍。",
    "ja-JP": "まず高さと深さ、角度は絶対に狙わない。浅くなった守備の一球が、そのポイントの最後の一球になる。",
    "ko-KR": "높이와 깊이 먼저, 각도는 절대 금물. 짧게 떨어진 수비 공은 그 포인트의 마지막 샷이다.",
    "es-ES": "Altura y profundidad primero, ángulo nunca: una bola defensiva "
             "corta es el último golpe que juegas en ese punto.",
    "fr-FR": "Hauteur et longueur d'abord, jamais l'angle : une balle de "
             "défense courte est ton dernier coup du point.",
    "id-ID": "Tinggi dan dalam dulu, sudut jangan pernah.",
    "ms-MY": "Tinggi dan dalam dahulu, sudut jangan sekali.",
    "th-TH": "เอาความสูงและความลึกก่อน อย่าเอามุม ลูกรับที่สั้นคือลูกสุดท้ายของแต้มนั้น",
    "vi-VN": "Ưu tiên độ cao và độ sâu, tuyệt đối không góc.",
}


def defend_family() -> list[Drill]:
    specs = [("slice", "the slice", WIDE_A, (0.5, 0.06)),
             ("lob", "the lob", WIDE_D, (0.5, 0.04)),
             ("block_return", "the block return", BASE_A, (0.5, 0.10))]
    out = []
    for key, label, pulled, target in specs:
        out.append(Drill(
            id=f"tn_defend_{key}", category="defending", minutes=8, rel=True,
            free=(key == "slice"),
            name=suffixed(DEFEND_NAME, label), note=DEFEND_NOTE,
            home=[P(*BASE_C, "1", moves=[pulled + (0,), BASE_C + (2,)])],
            away=[P(*mirror(BASE_C), "2",
                    moves=[(mirror(pulled)[0], 0.10, 0), (target[0], target[1], 1)])],
            markers=[M(*target, "zone", "")],
            ball=mirror(BASE_C),        # the attacker starts with it
        ))
    return out


DOUBLES_NAME = {
    "en": "Doubles", "en-GB": "Doubles", "zh-CN": "双打", "zh-TW": "雙打",
    "ja-JP": "ダブルス", "ko-KR": "복식", "es-ES": "Dobles", "fr-FR": "Double",
    "id-ID": "Ganda", "ms-MY": "Beregu", "th-TH": "ประเภทคู่", "vi-VN": "Đôi",
}
DOUBLES_NOTE = {
    "en": "The pair moves as one line, diagonally. When your partner is pulled "
          "wide, you are already crossing — not watching.",
    "en-GB": "The pair moves as one line, diagonally. When your partner is "
             "pulled wide, you are already crossing — not watching.",
    "zh-CN": "两个人像一条线一样斜着一起动。同伴被拉到边线时，你应该已经在横移了，而不是在看。",
    "zh-TW": "兩個人像一條線一樣斜著一起動。同伴被拉到邊線時，你應該已經在橫移了，而不是在看。",
    "ja-JP": "ペアは一本の線として斜めに動く。相棒が外に振られたら、見ているのではなく既に寄っている。",
    "ko-KR": "두 사람은 한 줄로 대각선으로 움직인다. 파트너가 밀려나면 보고 있지 말고 이미 이동 중이어야 한다.",
    "es-ES": "La pareja se mueve como una línea, en diagonal: si a tu compañero "
             "lo abren, tú ya estás cruzando, no mirando.",
    "fr-FR": "La paire se déplace comme une ligne, en diagonale : quand ton "
             "partenaire est écarté, tu traverses déjà — tu ne regardes pas.",
    "id-ID": "Pasangan bergerak sebagai satu garis, diagonal.",
    "ms-MY": "Pasangan bergerak sebagai satu garisan, secara pepenjuru.",
    "th-TH": "คู่ต้องขยับเป็นเส้นเดียวกันในแนวทแยง",
    "vi-VN": "Cặp đôi di chuyển như một đường thẳng, theo đường chéo.",
}


def doubles_family() -> list[Drill]:
    specs = [
        ("one_up_one_back", "one up one back", [(0.72, 0.94), (0.30, 0.60)],
         [(0.60, 0.90), (0.40, 0.58)]),
        ("both_back", "both back", [(0.28, 0.94), (0.72, 0.94)],
         [(0.36, 0.90), (0.66, 0.90)]),
        ("both_up", "both up", [(0.30, 0.60), (0.70, 0.60)],
         [(0.38, 0.56), (0.62, 0.56)]),
        ("australian", "the Australian formation", [(0.60, 0.99), (0.66, 0.60)],
         [(0.28, 0.90), (0.44, 0.57)]),
    ]
    out = []
    for key, label, start, end in specs:
        out.append(Drill(
            id=f"tn_doubles_{key}", category="attacking", minutes=12, rel=True,
            free=(key == "one_up_one_back"),
            name=suffixed(DOUBLES_NAME, label), note=DOUBLES_NOTE,
            home=[P(x, y, f"{i + 1}", moves=[end[i] + (0,)])
                  for i, (x, y) in enumerate(start)],
            away=[P(0.30, 0.06, "A", moves=[(0.30, 0.10, 0)]), P(0.70, 0.40, "B")],
            ball=0,
        ))
    return out


WARM_NAME = {
    "en": "Warm-up", "en-GB": "Warm-up", "zh-CN": "热身", "zh-TW": "熱身",
    "ja-JP": "ウォームアップ", "ko-KR": "웜업", "es-ES": "Calentamiento",
    "fr-FR": "Échauffement", "id-ID": "Pemanasan", "ms-MY": "Memanaskan badan",
    "th-TH": "วอร์มอัพ", "vi-VN": "Khởi động",
}
WARM_NOTE = {
    "en": "Start inside the service boxes and work back. Rhythm first, power "
          "later — the first ten minutes decide how the next hour feels.",
    "en-GB": "Start inside the service boxes and work back. Rhythm first, "
             "power later — the first ten minutes decide how the next hour feels.",
    "zh-CN": "从发球区里面开始，再往后退。先找节奏，后加力量——前十分钟决定了接下来一小时的手感。",
    "zh-TW": "從發球區裡面開始，再往後退。先找節奏，後加力量——前十分鐘決定了接下來一小時的手感。",
    "ja-JP": "サービスボックスの中から始めて下がっていく。まずリズム、力は後。最初の10分がその後の1時間を決める。",
    "ko-KR": "서비스 박스 안에서 시작해 뒤로 물러나라. 리듬 먼저, 힘은 나중에.",
    "es-ES": "Empieza dentro de los cuadros y ve retrocediendo: primero ritmo, "
             "luego potencia; los diez primeros minutos deciden la hora siguiente.",
    "fr-FR": "Commence dans les carrés de service puis recule : le rythme "
             "d'abord, la puissance ensuite.",
    "id-ID": "Mulai di dalam kotak servis lalu mundur. Ritme dulu, tenaga kemudian.",
    "ms-MY": "Mula dalam kotak servis kemudian berundur. Rentak dahulu.",
    "th-TH": "เริ่มในกรอบเสิร์ฟแล้วค่อยถอยออก จังหวะก่อน พลังทีหลัง",
    "vi-VN": "Bắt đầu trong ô giao bóng rồi lùi dần. Nhịp trước, lực sau.",
}


def warmup_family() -> list[Drill]:
    specs = [("mini_tennis", "mini tennis", (0.50, 0.60), (0.50, 0.40)),
             ("service_box", "service box rally", (0.74, 0.62), (0.26, 0.38)),
             ("baseline_feed", "baseline feed", (0.50, 0.94), (0.50, 0.06))]
    out = []
    for key, label, h, a in specs:
        out.append(Drill(
            id=f"tn_warm_{key}", category="warmup", minutes=8, rel=True,
            free=(key == "mini_tennis"),
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            home=[P(*h, "1", moves=[(h[0] + 0.08, h[1] - 0.03, 0), h + (1,)])],
            away=[P(*a, "2", moves=[(a[0] - 0.08, a[1] + 0.03, 0), a + (1,)])],
            ball=0,
        ))
    return out


GAME_NAME = {
    "en": "Point play", "en-GB": "Point play", "zh-CN": "分制对抗",
    "zh-TW": "分制對抗", "ja-JP": "ポイント練習", "ko-KR": "포인트 게임",
    "es-ES": "Juego de puntos", "fr-FR": "Jeu au point",
    "id-ID": "Bermain poin", "ms-MY": "Permainan mata",
    "th-TH": "เล่นแต้ม", "vi-VN": "Đánh điểm",
}
GAME_NOTE = {
    "en": "Play it for points from the first ball. A drill you can't lose is a "
          "drill nobody concentrates in.",
    "en-GB": "Play it for points from the first ball. A drill you can't lose "
             "is a drill nobody concentrates in.",
    "zh-CN": "从第一球起就计分。输不掉的练习，就是没人会集中注意力的练习。",
    "zh-TW": "從第一球起就計分。輸不掉的練習，就是沒人會集中注意力的練習。",
    "ja-JP": "1球目からポイントを取り合う。負けようのない練習には誰も集中しない。",
    "ko-KR": "첫 공부터 점수를 걸어라. 질 수 없는 훈련에는 아무도 집중하지 않는다.",
    "es-ES": "Juega a puntos desde la primera bola: en un ejercicio que no se "
             "puede perder nadie se concentra.",
    "fr-FR": "Joue au point dès la première balle : un exercice qu'on ne peut "
             "pas perdre, personne ne s'y concentre.",
    "id-ID": "Mainkan untuk poin sejak bola pertama.",
    "ms-MY": "Main untuk mata dari bola pertama.",
    "th-TH": "เล่นเอาแต้มตั้งแต่ลูกแรก แบบฝึกที่แพ้ไม่ได้คือแบบฝึกที่ไม่มีใครตั้งใจ",
    "vi-VN": "Tính điểm ngay từ quả đầu tiên.",
}


def game_family() -> list[Drill]:
    specs = [
        ("half_court", "half-court singles", [(0.70, 0.94)], [(0.70, 0.06)]),
        ("first_to_seven", "first to seven", [(0.50, 0.96)], [(0.50, 0.04)]),
        ("approach_only", "approach and volley only", [(0.50, 0.80)], [(0.50, 0.10)]),
        ("doubles_set", "doubles set", [(0.30, 0.94), (0.70, 0.60)],
         [(0.70, 0.06), (0.30, 0.40)]),
    ]
    out = []
    for key, label, home, away in specs:
        out.append(Drill(
            id=f"tn_game_{key}", category="ssg", minutes=20, rel=True,
            free=(key in ("first_to_seven", "doubles_set")),
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=[P(x, y, f"{i + 1}", moves=[(x, y - 0.05, 0)])
                  for i, (x, y) in enumerate(home)],
            away=[P(x, y, chr(65 + i), moves=[(x, y + 0.05, 0)])
                  for i, (x, y) in enumerate(away)],
            markers=([M(0.5, 0.30, "cone", ""), M(0.5, 0.70, "cone", "")]
                     if key == "half_court" else []),
            ball=0,
        ))
    return out


def tennis_library() -> list[Drill]:
    return (warmup_family() + rally_family() + plus_one_family()
            + doubles_family() + net_family() + defend_family()
            + serve_family() + game_family())
