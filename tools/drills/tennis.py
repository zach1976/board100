"""The tennis library.

The court is portrait with the net at y=0.5 and home at the bottom. Almost
every pattern here is about the same two things: where the ball is hit from,
and whether the player got back to the middle before the next one arrives —
so most drills carry the recovery step as their last phase.
"""
from .engine import Drill, M, P, Spot, figure_clear, suffixed

# These fractions are of the COURT, not the canvas, so 1.0 IS the baseline
# and anything less than that is inside the court. A groundstroke is taken
# from behind the line — you step in to attack one, you do not live there —
# and at 0.97 the whole library had its players standing on the line or in
# front of it. A metre back is about 0.04 of this court's length.
# A serve and a return are struck from BEHIND the line, and the figure is
# 44pt tall on a court drawn 620pt long — 0.84 m of it below its own point.
# Written as 0.03 of the court (0.71 m) the server stood astride his own
# baseline. 0.05 is 1.19 m: all of him is behind it.
BEHIND = 0.043
# The far side needs more: the figure hangs half its height BELOW its point,
# toward the net, so a far man 0.043 past his line had his feet on it (0.02,
# 13pt inside). FAR_BACK is half a drawn figure and 3pt of air past the far
# baseline, measured on the phone board: the feet are behind it.
FAR_BACK = -figure_clear("tennis")
BASE_C = (0.50, 1.04)
BASE_D, BASE_A = (0.72, 1.04), (0.28, 1.04)   # deuce / ad corners, home side
WIDE_D, WIDE_A = (0.93, 1.00), (0.07, 1.00)
SERVICE_D, SERVICE_A = (0.74, 0.62), (0.26, 0.62)   # service box centres
NET_D, NET_A = (0.68, 0.58), (0.32, 0.58)
# The server stands just either side of the centre mark, BEHIND the line,
# and serves from there: nobody walks into the court before the toss. The
# "S moves into position to hit" step the serve drills used to open with
# put him 1.4 m inside his baseline when the ball left the racket.
SRV_D, SRV_A = (0.57, 1 + BEHIND), (0.43, 1 + BEHIND)
# Singles sidelines are at 1.37 m of the 10.97 m width: 0.125 / 0.875. A
# target or a corner inside them is at least 0.4 m in; 0.164 is 1.8 m.
IN_L, IN_R = 0.17, 0.83


def through(frm, via, y):
    """The point at depth [y] on the line from [frm] through [via].

    Where a receiver has to stand to meet a ball that bounced at [via]:
    the serve is drawn to him, and with him on this line the arrow crosses
    the shaded zone instead of running to wherever he happened to wait.
    """
    t = (y - frm[1]) / (via[1] - frm[1])
    return (frm[0] + (via[0] - frm[0]) * t, y)


def recover(pt, k=0.5):
    """Half way back to the middle along the baseline: the middle of the
    angles the other player has, not the centre mark."""
    return (0.5 + (pt[0] - 0.5) * k, pt[1])


def mirror(pt):
    """The same court position for the player on the other side.

    A half turn, not a flip. Reflecting only y kept the near player's x, so
    "cross-court forehand" put both players in the same column — which is
    down the line — and "down the line" drew the diagonal.

    A man behind the near baseline is behind the far one, at FAR_BACK: the
    reflected depth left the far man's feet on his line.
    """
    if pt[1] > 1.0:
        return (1.0 - pt[0], min(1.0 - pt[1], FAR_BACK))
    return (1.0 - pt[0], 1.0 - pt[1])


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
    """The four rally patterns a baseline point is actually built from.

    Both players START in the corners the pattern is played from, and every
    ball goes corner to corner. The players used to stand on the centre
    marks and shuffle to a corner only after the ball had gone, so all four
    drills drew the same vertical line down the T — "cross-court" and "down
    the line" were names on one picture. Between shots each recovers half
    way to the middle and steps back out to meet the next ball.
    """
    # The rally corners: 1.3 m inside the singles sidelines, so the diagonal
    # reads as one on a phone.
    RALLY_D, RALLY_A = (0.77, 1.04), (0.23, 1.04)

    def cone_on(frm, to, y):
        return through(frm, to, y)

    out = []
    for key, label in [("crosscourt_fh", "cross-court forehand"),
                       ("crosscourt_bh", "cross-court backhand"),
                       ("down_the_line", "down the line"),
                       ("figure_eight", "figure of eight")]:
        if key == "figure_eight":
            # 1 always cross-court, 2 always down the line: both run the
            # width of the court, which is the figure of eight.
            a1, b1 = RALLY_D, mirror(RALLY_D)
            a2 = RALLY_A
            b2 = mirror(RALLY_A)
            # …and 2's second down-the-line ball takes 1 back to where he
            # started: the loop closes.
            home = [P(*a1, "1", moves=[recover(a1, 0.5) + (0,), a2 + (1,),
                                       recover(a2, 0.5) + (2,), a1 + (3,)])]
            away = [P(*b1, "2", moves=[recover(b1, 0.5) + (1,), b2 + (2,),
                                       recover(b2, 0.5) + (3,)])]
            ball_to = [("a0", 0), (0, 1), ("a0", 2), (0, 3)]
            cones = [cone_on(a1, b1, 0.07), cone_on(b1, a2, 0.93)]
        else:
            a1, b1 = {"crosscourt_fh": (RALLY_D, mirror(RALLY_D)),
                      "crosscourt_bh": (RALLY_A, mirror(RALLY_A)),
                      "down_the_line": (RALLY_D, mirror(RALLY_A))}[key]
            home = [P(*a1, "1", moves=[recover(a1) + (0,), a1 + (1,)])]
            away = [P(*b1, "2", moves=[recover(b1) + (1,)])]
            ball_to = [("a0", 0), (0, 1)]
            cones = [cone_on(a1, b1, 0.07), cone_on(b1, a1, 0.93)]
        out.append(Drill(
            id=f"tn_rally_{key}", category="possession", minutes=10, rel=True,
            free=(key in ("crosscourt_fh", "figure_eight")),
            name=suffixed(RALLY_NAME, label), note=RALLY_NOTE,
            home=home, away=away,
            markers=[M(*c, "cone", "") for c in cones],
            ball=0, ball_to=ball_to,
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
    # Singles sidelines are at x 0.125 and 0.875, so the wide targets used
    # to be 0.8 m outside the court — a fault. And every target sat 2.4 m
    # past the net in a 6.4 m box; a serve target belongs on the service
    # line, at y 0.25.
    # The serve is drawn to the receiver, so the receiver stands on the
    # line from the server through the zone — where that serve really
    # takes him. Every deuce variant used to draw the same arrow to a man
    # waiting in the middle, crossing the service line metres from the
    # "wide" zone; only the shading moved.
    specs = [("deuce_wide", "deuce wide", SRV_D, (0.165, 0.255)),
             ("deuce_t", "deuce down the T", SRV_D, (0.435, 0.25)),
             ("deuce_body", "deuce at the body", SRV_D, (0.33, 0.27)),
             ("ad_wide", "ad wide", SRV_A, (0.835, 0.255)),
             ("ad_t", "ad down the T", SRV_A, (0.565, 0.25))]
    out = []
    for key, label, stand, target in specs:
        r0 = (0.24 if stand is SRV_D else 0.76, FAR_BACK)
        meet = through(stand, target, FAR_BACK)
        out.append(Drill(
            id=f"tn_serve_{key}", category="setpiece", minutes=8, rel=True,
            free=(key == "deuce_wide"), off_surface=True,
            name=suffixed(SERVE_NAME, label), note=SERVE_NOTE,
            # Served from behind the line; he recovers to the middle while
            # the return is on its way.
            home=[P(*stand, "S", moves=[(0.5, 1 + BEHIND * 0.7, 1)])],
            # R meets the serve, returns it, and recovers to the middle —
            # not on toward the alley.
            away=[P(*r0, "R", moves=[meet + (0,), (0.5, FAR_BACK, 1)])],
            markers=[M(*target, "zone", "")],
            ball=0, ball_to=[("a0", 0), (0, 1)],
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
    """The ball the drill is named for is drawn, into its zone.

    These used to stop one ball early: feed, reply, and the board ended with
    the ball on 1's racket while 2 walked onto the target — "hit it to him".
    Now the last leg is 1's shot into the zone, the zone is inside the
    singles lines (three of them sat in the doubles alley, out in a 1v1),
    and 2 is left where a real opponent would be: recovering, short of it.
    """
    out = []
    # Serve +1: a wide deuce serve, the return comes back, and the +1 goes
    # to the open court on the other side.
    serve_via = (0.18, 0.26)
    r_meet = through(SRV_D, serve_via, FAR_BACK)
    out.append(Drill(
        id="tn_serve_plus_one", category="attacking", minutes=10, rel=True, off_surface=True,
        free=True, name=suffixed(PLUS_ONE_NAME, "serve"), note=PLUS_ONE_NOTE,
        home=[P(*SRV_D, "1", moves=[(0.52, 1 + BEHIND * 0.7, 1)])],
        away=[P(0.24, FAR_BACK, "2", moves=[r_meet + (0,), (0.36, FAR_BACK, 1)])],
        markers=[M(0.80, 0.10, "zone", "")],
        ball=0, ball_to=[("a0", 0), (0, 1), (Spot(0.80, 0.10), 2)],
    ))
    # Return +1: 2 serves from his ad side diagonally into 1's ad box, 1
    # returns deep, and plays the +1 off the next ball.
    srv2 = (0.57, FAR_BACK)
    meet1 = through(srv2, (0.30, 0.73), 1.02)
    out.append(Drill(
        id="tn_return_plus_one", category="attacking", minutes=10, rel=True,
        name=suffixed(PLUS_ONE_NAME, "return"), note=PLUS_ONE_NOTE,
        off_surface=True,
        home=[P(0.24, 1 + BEHIND, "1",
                moves=[meet1 + (0,), (0.48, 1 + BEHIND * 0.7, 1), (0.58, 0.97, 2)])],
        away=[P(*srv2, "2", moves=[(0.50, FAR_BACK, 0)])],
        markers=[M(0.20, 0.10, "zone", "")],
        ball=(srv2[0], srv2[1]),
        ball_to=[(0, 0), ("a0", 1), (0, 2), (Spot(0.20, 0.10), 3)],
    ))
    # Inside-out forehand: the ball comes to the backhand corner, 1 runs
    # round it and hits the forehand cross to the far ad corner.
    out.append(Drill(
        id="tn_inside_out", category="attacking", minutes=10, rel=True, off_surface=True,
        name=suffixed(PLUS_ONE_NAME, "inside-out forehand"), note=PLUS_ONE_NOTE,
        home=[P(*BASE_C, "1", moves=[(0.36, 1.02, 0), (0.52, 1 + BEHIND, 1)])],
        away=[P(*mirror(BASE_C), "2")],
        markers=[M(0.80, 0.10, "zone", "")],
        ball=mirror(BASE_C), ball_to=[(0, 0), (Spot(0.80, 0.10), 1)],
    ))
    # Approach: a short ball, 1 steps in and approaches deep into the
    # corner (2 m from the baseline — an approach goes deep), and follows
    # it in.
    out.append(Drill(
        id="tn_approach", category="attacking", minutes=10, rel=True,
        free=True, name=suffixed(PLUS_ONE_NAME, "approach"), note=PLUS_ONE_NOTE,
        home=[P(*BASE_C, "1", moves=[(0.58, 0.74, 0), (0.64, 0.62, 1)])],
        away=[P(*mirror(BASE_C), "2")],
        markers=[M(0.80, 0.09, "zone", "")],
        ball=mirror(BASE_C), ball_to=[(0, 0), (Spot(0.80, 0.09), 1)],
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
    # (start, where the volley is struck, where 1 goes after it, zone).
    # The feed comes from 2 on the far baseline, 1 moves to meet it, and
    # the volley/overhead itself is the last leg — into the zone, which the
    # feeder no longer walks onto. Each finishes with 1 still moving
    # forward through the shot (the overhead is struck going back).
    specs = [("first_volley", "first volley", (0.56, 0.78), (0.58, 0.70), (0.60, 0.64), (0.22, 0.12)),
             ("second_volley", "second volley", (0.60, 0.66), (0.63, 0.59), (0.64, 0.56), (0.80, 0.26)),
             ("overhead", "overhead", (0.58, 0.60), (0.56, 0.72), (0.57, 0.66), (0.30, 0.18)),
             ("drop_volley", "drop volley", (0.60, 0.62), (0.62, 0.58), None, (0.72, 0.43))]
    out = []
    for key, label, start, hit, after, target in specs:
        moves = [hit + (0,)] + ([after + (1,)] if after else [])
        # On the drop volley the feeder sprints in for it and gets nowhere
        # near: he stops 3 m short of the net, not on top of it.
        away_moves = [(0.66, 0.24, 1)] if key == "drop_volley" else []
        out.append(Drill(
            id=f"tn_net_{key}", category="finishing", minutes=8, rel=True,
            free=(key == "first_volley"),
            name=suffixed(NET_NAME, label), note=NET_NOTE,
            home=[P(*start, "1", moves=moves)],
            away=[P(*mirror(BASE_C), "2", moves=away_moves)],
            markers=[M(*target, "zone", "")],
            ball=mirror(BASE_C),        # fed from the far baseline
            ball_to=[(0, 0), (Spot(*target), 1)],
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
    # A lob answers a player at the net, and a block return answers a
    # serve; both used to be drawn against a second baseliner, so neither
    # had the premise it is named for. The attacking ball goes to a corner
    # INSIDE the singles lines (it used to pull 1 into the doubles alley,
    # which in a 1v1 is out), 1's defensive ball is drawn into the deep
    # zone, and 2 no longer walks onto it.
    srv2 = (0.43, FAR_BACK)                      # 2's deuce half: canvas left
    block_meet = through(srv2, (0.70, 0.73), 1.02)   # into 1's deuce box
    specs = [
        # key, label, 2's spot, where 1 is pulled to, zone, 2's move on 1's shot
        ("slice", "the slice", mirror(BASE_C), (IN_L, 1.0), (0.50, 0.07), None),
        ("lob", "the lob", (0.48, 0.30), (IN_R, 1.0), (0.40, 0.07), (0.47, 0.23)),
        ("block_return", "the block return", srv2, block_meet, (0.50, 0.08), None),
    ]
    out = []
    for key, label, two, pulled, target, chase in specs:
        start = (0.76, 1 + BEHIND) if key == "block_return" else BASE_C
        away_moves = ([(0.50, FAR_BACK, 0)] if key == "block_return"
                      else [chase + (1,)] if chase else [])
        out.append(Drill(
            id=f"tn_defend_{key}", category="defending", minutes=8, rel=True,
            free=(key == "slice"),
            off_surface=(key == "block_return"),
            name=suffixed(DEFEND_NAME, label), note=DEFEND_NOTE,
            home=[P(*start, "1", moves=[pulled + (0,), (0.5, 1 + BEHIND * 0.7, 1)])],
            # On the lob 2 stays at the net to be lobbed, then turns and
            # chases it.
            away=[P(*two, "2", moves=away_moves)],
            markers=[M(*target, "zone", "")],
            ball=two,
            ball_to=[(0, 0), (Spot(*target), 1)],
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
    # The back player stands BEHIND the baseline (0.94 was 1.4 m inside it),
    # and the opponents take the shape each formation is played against —
    # all four used to face the same one-up-one-back pair.
    back_l, back_r = (0.28, 1.02), (0.72, 1.02)
    specs = [
        ("one_up_one_back", "one up one back", [back_r, (0.30, 0.62)],
         [(0.62, 1.01), (0.40, 0.60)],
         [(0.28, FAR_BACK), (0.70, 0.38)]),         # the same shape
        ("both_back", "both back", [back_l, back_r],
         [(0.36, 1.01), (0.64, 1.01)],
         [(0.32, 0.38), (0.68, 0.38)]),              # against two at the net
        ("both_up", "both up", [(0.30, 0.60), (0.70, 0.60)],
         [(0.38, 0.57), (0.62, 0.57)],
         [(0.30, FAR_BACK), (0.70, FAR_BACK)]),      # against two back
        # Australian: server and net man on the SAME side; the server
        # crosses behind after the serve.
        ("australian", "the Australian formation", [SRV_D, (0.66, 0.60)],
         [(0.30, 1.02), (0.56, 0.58)],
         [(0.26, FAR_BACK), (0.70, 0.38)]),
    ]
    out = []
    for key, label, start, end, opp in specs:
        out.append(Drill(
            id=f"tn_doubles_{key}", category="attacking", minutes=12, rel=True,
            free=(key == "one_up_one_back"), off_surface=(key == "australian"),
            name=suffixed(DOUBLES_NAME, label), note=DOUBLES_NOTE,
            home=[P(x, y, f"{i + 1}", moves=[end[i] + (0,)])
                  for i, (x, y) in enumerate(start)],
            away=[P(*opp[0], "A"), P(*opp[1], "B")],
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
             # Behind the baselines: a "baseline" feed 1.4 m inside them
             # was a mid-court rally.
             ("baseline_feed", "baseline feed", (0.50, 1.02), (0.50, FAR_BACK))]
    out = []
    for key, label, h, a in specs:
        dy = 0.0 if key == "baseline_feed" else 0.03
        out.append(Drill(
            id=f"tn_warm_{key}", category="warmup", minutes=8, rel=True,
            free=(key == "mini_tennis"),
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            # A step across to the ball and back; in the baseline feed he
            # stays behind his line (a step in put the far man's feet in
            # the court).
            home=[P(*h, "1", moves=[(h[0] + 0.08, h[1] - dy, 0), h + (1,)])],
            away=[P(*a, "2", moves=[(a[0] - 0.08, a[1] + dy, 0), a + (1,)])],
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
    # Every point starts with the server behind his baseline and the serve
    # going diagonally into the right box; the return comes back to where
    # he has recovered. The players used to open by stepping 1-5 m INTO the
    # court before anyone had hit a ball.
    rec = (0.5, 1 + BEHIND * 0.7)
    specs = [
        # Half-court singles is a rally down one half, not a serve.
        ("half_court", "half-court singles",
         [P(0.70, 1.02, "1")], [P(0.70, FAR_BACK, "A")], [("a0", 0), (0, 1)]),
        ("first_to_seven", "first to seven",
         [P(*SRV_D, "1", moves=[rec + (0,)])],
         [P(0.26, FAR_BACK, "A", moves=[(0.5, FAR_BACK, 1)])],
         [("a0", 0), (0, 1)]),
        # Approach-and-volley only: serve, follow it in, volley the return.
        ("approach_only", "approach and volley only",
         [P(*SRV_D, "1", moves=[(0.60, 0.84, 0), (0.58, 0.72, 1)])],
         [P(0.26, FAR_BACK, "A", moves=[(0.5, FAR_BACK, 1)])],
         [("a0", 0), (0, 1)]),
        ("doubles_set", {
            "en": "doubles to eleven", "en-GB": "doubles to eleven",
            "zh-CN": "双打 11 分制", "zh-TW": "雙打 11 分制",
            "ja-JP": "ダブルス 11点ゲーム", "ko-KR": "복식 11점 게임",
            "es-ES": "dobles a 11", "fr-FR": "double en 11 points",
            "id-ID": "ganda sampai 11", "ms-MY": "beregu hingga 11",
            "th-TH": "ประเภทคู่ 11 แต้ม", "vi-VN": "đôi đến 11 điểm"},
         [P(*SRV_D, "1", moves=[(0.62, 1 + BEHIND * 0.7, 0)]), P(0.30, 0.62, "2")],
         [P(0.26, FAR_BACK, "A", moves=[(0.40, FAR_BACK, 1)]), P(0.70, 0.38, "B")],
         [("a0", 0), (0, 1)]),
    ]
    out = []
    for key, label, home, away, ball_to in specs:
        out.append(Drill(
            id=f"tn_game_{key}", category="ssg", minutes=20, rel=True,
            free=(key in ("first_to_seven", "doubles_set")), off_surface=True,
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=home, away=away,
            # The two centre marks: the line between them halves the court
            # lengthwise, and only the half the players stand in is in.
            markers=([M(0.5, 1.0, "cone", ""), M(0.5, 0.0, "cone", "")]
                     if key == "half_court" else []),
            ball=0, ball_to=ball_to,
        ))
    return out


SECOND_NOTE = {
    "en": "Spin first, speed second: a second serve that clears the net by a metre and kicks is worth two that clip the tape. Nobody ever lost a match to a kick serve that went in.",
    "en-GB": "Spin first, speed second: a second serve that clears the net by a metre and kicks is worth two that clip the tape. Nobody ever lost a match to a kick serve that went in.",
    "zh-CN": "先要旋转，再谈速度：过网一米、落地窜起的二发，胜过两个擦网而过的。没人因为一个进了的上旋二发输掉比赛。",
    "zh-TW": "先要旋轉，再談速度：過網一米、落地竄起的二發，勝過兩個擦網而過的。沒人因為一個進了的上旋二發輸掉比賽。",
    "ja-JP": "まず回転、速度は二の次。ネットを1m越えて跳ねるセカンドは、テープをかすめる2本に勝る。入ったキックサーブで試合を落とした者はいない。",
    "ko-KR": "회전이 먼저, 속도는 그다음. 네트를 1미터 넘겨 튀어 오르는 세컨드가 네트를 스치는 두 개보다 낫다.",
    "es-ES": "Primero el efecto, después la velocidad: un segundo saque que pasa un metro sobre la red y salta vale por dos que rozan la cinta.",
    "fr-FR": "L'effet d'abord, la vitesse ensuite : une deuxième balle qui passe à un mètre du filet et rebondit haut en vaut deux qui frôlent la bande.",
    "id-ID": "Spin dulu, kecepatan kemudian: servis kedua yang melewati net satu meter dan memantul tinggi setara dua yang menyerempet net.",
    "ms-MY": "Putaran dahulu, kelajuan kemudian.",
    "th-TH": "สปินมาก่อน ความเร็วทีหลัง เสิร์ฟสองที่ข้ามตาข่ายหนึ่งเมตรและกระดอนสูงคุ้มกว่าสองลูกที่เฉียดเน็ต",
    "vi-VN": "Xoáy trước, tốc độ sau: quả giao hai qua lưới một mét và nảy cao đáng giá bằng hai quả sượt mép lưới.",
}
SV_NOTE = {
    "en": "Split step where you land, not where you meant to get to. A serve-volleyer still running when the return is struck is volleying from his shoelaces.",
    "en-GB": "Split step where you land, not where you meant to get to. A serve-volleyer still running when the return is struck is volleying from his shoelaces.",
    "zh-CN": "在你落地的位置做分腿垫步，而不是在你原本想到达的位置。接发球击出时人还在跑，那一拍截击就只能从鞋带上打。",
    "zh-TW": "在你落地的位置做分腿墊步，而不是在你原本想到達的位置。接發球擊出時人還在跑，那一拍截擊就只能從鞋帶上打。",
    "ja-JP": "着地したその場でスプリットステップを踏む。狙った位置ではない。リターンが打たれた時にまだ走っていれば、靴紐の高さでボレーすることになる。",
    "ko-KR": "도착하려던 곳이 아니라 착지한 곳에서 스플릿 스텝을 밟아라. 리턴이 맞을 때까지 뛰고 있으면 발목 높이에서 발리하게 된다.",
    "es-ES": "Split step donde caes, no donde pretendías llegar: quien sigue corriendo cuando golpean el resto volea desde los cordones.",
    "fr-FR": "Split step là où tu atterris, pas là où tu voulais arriver : celui qui court encore au moment du retour volleye dans ses lacets.",
    "id-ID": "Split step di tempat kamu mendarat, bukan di tempat yang kamu tuju.",
    "ms-MY": "Split step di tempat anda mendarat, bukan di tempat yang anda tuju.",
    "th-TH": "สปลิตสเต็ปตรงที่คุณลงเท้า ไม่ใช่ตรงที่ตั้งใจจะไปถึง",
    "vi-VN": "Bước tách ở nơi bạn tiếp đất, không phải nơi bạn định tới.",
}
DROP_NOTE = {
    "en": "Play it from inside the baseline off a short ball, and follow it in. A drop shot hit from behind the baseline gives the other player the two extra steps he needs.",
    "en-GB": "Play it from inside the baseline off a short ball, and follow it in. A drop shot hit from behind the baseline gives the other player the two extra steps he needs.",
    "zh-CN": "接短球时在底线内打出，然后跟上网。站在底线后面打的放小球，正好给了对手他需要的那两步。",
    "zh-TW": "接短球時在底線內打出，然後跟上網。站在底線後面打的放小球，正好給了對手他需要的那兩步。",
    "ja-JP": "短い球をベースライン内側から打ち、そのまま前へ出る。ベースラインの後ろから打つドロップは、相手に必要な2歩を与えるだけだ。",
    "ko-KR": "짧은 공을 베이스라인 안쪽에서 치고 그대로 전진하라. 베이스라인 뒤에서 친 드롭샷은 상대에게 두 걸음을 그냥 준다.",
    "es-ES": "Juégala desde dentro de la línea de fondo sobre una bola corta y sube detrás. Una dejada desde atrás regala dos pasos al rival.",
    "fr-FR": "Joue-la depuis l'intérieur du court sur une balle courte, et monte derrière. Un amorti frappé derrière la ligne offre deux pas à l'adversaire.",
    "id-ID": "Mainkan dari dalam garis belakang pada bola pendek, lalu ikuti maju.",
    "ms-MY": "Mainkan dari dalam garisan belakang pada bola pendek, kemudian ikut ke depan.",
    "th-TH": "เล่นจากในเส้นหลังเมื่อได้ลูกสั้น แล้วตามขึ้นหน้า",
    "vi-VN": "Đánh từ trong vạch cuối sân khi có bóng ngắn, rồi theo lên lưới.",
}
POACH_NOTE = {
    "en": "Move on the returner's contact, straight across and forward — never back. A poach that starts early is a signal, and a poach that starts late is a spectator.",
    "en-GB": "Move on the returner's contact, straight across and forward — never back. A poach that starts early is a signal, and a poach that starts late is a spectator.",
    "zh-CN": "在接发球的人击球那一刻启动，横向并向前，绝不能后退。启动太早就是把意图告诉对方，启动太晚就只是个观众。",
    "zh-TW": "在接發球的人擊球那一刻啟動，橫向並向前，絕不能後退。啟動太早就是把意圖告訴對方，啟動太晚就只是個觀眾。",
    "ja-JP": "リターナーのインパクトで動く。横かつ前へ、決して後ろへは動かない。早すぎるポーチは合図であり、遅すぎるポーチは観客だ。",
    "ko-KR": "리터너가 공을 맞히는 순간 움직여라. 옆으로 그리고 앞으로, 절대 뒤로는 아니다.",
    "es-ES": "Sal en el impacto del restador, en diagonal hacia delante, nunca hacia atrás. Salir pronto es avisar; salir tarde es mirar.",
    "fr-FR": "Pars à l'impact du relanceur, en travers et vers l'avant, jamais en arrière. Partir tôt, c'est prévenir ; partir tard, c'est regarder.",
    "id-ID": "Bergeraklah saat pengembali menyentuh bola, menyilang dan ke depan, tidak pernah mundur.",
    "ms-MY": "Bergerak ketika pemulang menyentuh bola, melintang dan ke hadapan.",
    "th-TH": "ออกตัวตอนคนรับเสิร์ฟกระทบบอล ตัดข้างและไปข้างหน้า ห้ามถอยหลัง",
    "vi-VN": "Di chuyển khi người đỡ chạm bóng, cắt ngang và tiến lên, không bao giờ lùi.",
}


def gaps_family() -> list[Drill]:
    """The second serve, serve-and-volley, the drop shot and the poach.

    All four verified absent from every name and note in the library, along
    with the passing shot the drop shot sets up.
    """
    second_via = (0.20, 0.26)
    sv_via = (0.435, 0.25)
    poach_r = through(SRV_D, sv_via, FAR_BACK)
    # N crosses on the returner's contact and meets the cross-court return
    # on its line, 2 m off the net.
    poach_n = through(poach_r, (0.62, 1.0), 0.58)
    return [
        Drill(
            id="tn_serve_second", category="setpiece", minutes=8, rel=True,
            level="foundation", free=True, off_surface=True,
            name=suffixed(SERVE_NAME, "the kicking second serve"),
            note=SECOND_NOTE,
            # Served from behind the line, to R standing where the kick
            # takes him; ONE return, back to the server who has recovered.
            home=[P(*SRV_D, "S", moves=[(0.5, 1 + BEHIND * 0.7, 1)])],
            away=[P(0.24, FAR_BACK, "R",
                    moves=[through(SRV_D, second_via, FAR_BACK) + (0,),
                           (0.48, FAR_BACK, 1)])],
            markers=[M(*second_via, "zone", "")],
            ball=0, ball_to=[("a0", 0), (0, 1)],
        ),
        Drill(
            id="tn_serve_and_volley", category="attacking", minutes=10, rel=True,
            level="advanced",
            name={"en": "Serve and volley", "en-GB": "Serve and volley",
                  "zh-CN": "发球上网", "zh-TW": "發球上網",
                  "ja-JP": "サーブ＆ボレー", "ko-KR": "서브 앤 발리",
                  "es-ES": "Saque y volea", "fr-FR": "Service-volée",
                  "id-ID": "Servis dan voli", "ms-MY": "Servis dan voli",
                  "th-TH": "เสิร์ฟแล้วขึ้นวอลเลย์", "vi-VN": "Giao bóng lên lưới"},
            note=SV_NOTE,
            # Serve from behind the line, follow it in, split-step on the
            # service line as R strikes the return, and volley it deep.
            home=[P(*SRV_D, "S",
                    moves=[(0.60, 0.86, 0), (0.60, 0.75, 1), (0.60, 0.68, 2)])],
            away=[P(0.24, FAR_BACK, "R",
                    moves=[through(SRV_D, sv_via, FAR_BACK) + (0,),
                           (0.46, FAR_BACK, 1)])],
            markers=[M(*sv_via, "zone", ""), M(0.20, 0.12, "zone", "")],
            ball=0, off_surface=True,
            ball_to=[("a0", 0), (0, 1), (Spot(0.20, 0.12), 2)],
        ),
        Drill(
            id="tn_attack_drop_shot", category="attacking", minutes=8, rel=True,
            name=suffixed(RALLY_NAME, "the drop shot and the pass"), note=DROP_NOTE,
            # 2 stays deep until the drop is struck; 1 takes the short ball
            # inside the baseline, plays the drop and follows it in; 2
            # sprints up for it and tries to pass.
            home=[P(*BASE_C, "1", moves=[(0.56, 0.82, 0), (0.55, 0.67, 1)])],
            away=[P(*mirror(BASE_C), "2", moves=[(0.42, 0.33, 1)])],
            markers=[M(0.40, 0.385, "zone", ""), M(0.82, 0.86, "zone", "")],
            ball=mirror(BASE_C),
            ball_to=[(0, 0), (Spot(0.40, 0.385), 1), (Spot(0.82, 0.86), 2)],
        ),
        Drill(
            id="tn_doubles_poach", category="attacking", minutes=10, rel=True,
            name=suffixed(DOUBLES_NAME, "the poach"), note=POACH_NOTE,
            # S serves from behind the line; R meets the serve on its line;
            # N crosses on R's contact and volleys the return into the gap
            # between R and P. S switches behind him.
            home=[P(*SRV_D, "S", moves=[(0.34, 1 + BEHIND * 0.7, 1)]),
                  P(0.30, 0.62, "N", moves=[poach_n + (1,)])],
            away=[P(0.24, FAR_BACK, "R", moves=[poach_r + (0,), (0.36, FAR_BACK, 1)]),
                  P(0.70, 0.38, "P")],
            markers=[M(*sv_via, "zone", ""), M(0.58, 0.12, "zone", "")],
            ball=0, off_surface=True,
            ball_to=[("a0", 0), (1, 1), (Spot(0.58, 0.12), 2)],
        ),
    ]


def tennis_library() -> list[Drill]:
    return (warmup_family() + rally_family() + plus_one_family()
            + doubles_family() + net_family() + defend_family()
            + serve_family() + game_family() + gaps_family())
