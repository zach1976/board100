"""The table tennis library.

The table is drawn small on purpose: the players stand well behind it and the
room they use is most of what a drill is about. So every board here places
people outside the table (y below 0 or above 1) and is marked off_surface —
that is not a mistake, it is where table tennis is played from.
"""
from .engine import Drill, M, P, Spot, suffixed

# Table corners in table coordinates; the net is y=0.5.
FH, BH = 0.78, 0.22               # the home player's forehand / backhand side
NEAR, DEEP = 0.62, 0.92           # where a ball lands on the home half
HOME_READY = (0.50, 1.16)         # ready position, behind the table
AWAY_READY = (0.50, -0.16)


def mirror(pt):
    return (pt[0], 1.0 - pt[1])


def tt(drill_id, category, minutes, name, note, home, away, markers=(),
       ball=None, ball_to=None, free=False, rel=True, ball2=None,
       ball2_to=None) -> Drill:
    """A table tennis board — always off the table, because that is where the
    player stands.

    Every drill here is a rally: the ball crosses the table and comes back.
    Unless a call site says otherwise, the route is exactly that — over to
    the opponent on the first beat, returned on the second — which is what
    all thirty-two of these boards were silently failing to show.
    """
    if ball_to is None and ball is not None and home and away:
        ball_to = [("a0", 0), (0, 1)]
    return Drill(id=drill_id, category=category, minutes=minutes, rel=rel,
                 free=free, off_surface=True, name=name, note=note,
                 home=home, away=away, markers=list(markers), ball=ball,
                 ball_to=ball_to or [], ball2=ball2,
                 ball2_to=ball2_to or [])


WARM_NAME = {
    "en": "Warm-up", "en-GB": "Warm-up", "zh-CN": "热身", "zh-TW": "熱身",
    "ja-JP": "ウォームアップ", "ko-KR": "웜업", "es-ES": "Calentamiento",
    "fr-FR": "Échauffement", "id-ID": "Pemanasan", "ms-MY": "Memanaskan badan",
    "th-TH": "วอร์มอัพ", "vi-VN": "Khởi động",
}
WARM_NOTE = {
    "en": "Count the rally out loud and keep it alive. Warming up by hitting "
          "winners at each other warms up nothing.",
    "en-GB": "Count the rally out loud and keep it alive. Warming up by "
             "hitting winners at each other warms up nothing.",
    "zh-CN": "把回合数喊出来，把球留在台上。互相对轰得分球的热身，什么也热不起来。",
    "zh-TW": "把回合數喊出來，把球留在台上。互相對轟得分球的熱身，什麼也熱不起來。",
    "ja-JP": "ラリー数を声に出して数え、続ける。決め球を打ち合うウォームアップは何も温まらない。",
    "ko-KR": "랠리 수를 소리 내어 세며 이어가라. 서로 위너를 치는 웜업은 아무것도 데우지 못한다.",
    "es-ES": "Cuenta el peloteo en voz alta y mantenlo vivo: calentar a base "
             "de golpes ganadores no calienta nada.",
    "fr-FR": "Compte l'échange à voix haute et fais-le durer : s'échauffer en "
             "se tirant des points gagnants n'échauffe rien.",
    "id-ID": "Hitung reli dengan suara keras dan jaga agar tetap hidup.",
    "ms-MY": "Kira rali dengan kuat dan pastikan ia berterusan.",
    "th-TH": "นับจำนวนโต้ออกเสียงและรักษาลูกไว้",
    "vi-VN": "Đếm to số lần đôi công và giữ bóng sống.",
}


def warmup_family() -> list[Drill]:
    specs = [("forehand", "forehand to forehand", FH), ("backhand", "backhand to backhand", BH),
             ("middle", "down the middle", 0.50)]
    out = []
    for key, label, x in specs:
        out.append(tt(
            f"tt_warm_{key}", "warmup", 6,
            suffixed(WARM_NAME, label), WARM_NOTE,
            home=[P(x, 1.16, "1", moves=[(x, 1.06, 0), (x, 1.16, 1)])],
            away=[P(1 - x, -0.16, "2", moves=[(1 - x, -0.06, 0), (1 - x, -0.16, 1)])],
            markers=[M(x, DEEP, "zone", "")],
            ball=0, free=(key == "forehand"),
        ))
    return out


FOOT_NAME = {
    "en": "Footwork", "en-GB": "Footwork", "zh-CN": "步法", "zh-TW": "步法",
    "ja-JP": "フットワーク", "ko-KR": "풋워크", "es-ES": "Juego de pies",
    "fr-FR": "Jeu de jambes", "id-ID": "Footwork", "ms-MY": "Kerja kaki",
    "th-TH": "ฟุตเวิร์ก", "vi-VN": "Di chuyển chân",
}
FOOT_NOTE = {
    "en": "Move with the legs, not by reaching. Every ball you stretch for is "
          "a ball you had time to step to.",
    "en-GB": "Move with the legs, not by reaching. Every ball you stretch for "
             "is a ball you had time to step to.",
    "zh-CN": "用腿移动，不要靠伸手够。每一个你伸手去够的球，其实都来得及跨一步过去。",
    "zh-TW": "用腿移動，不要靠伸手夠。每一個你伸手去夠的球，其實都來得及跨一步過去。",
    "ja-JP": "手を伸ばすのではなく脚で動く。伸ばして取った球は、本当は一歩入る時間があった球だ。",
    "ko-KR": "손을 뻗지 말고 다리로 움직여라. 뻗어서 친 공은 사실 한 발 갈 시간이 있던 공이다.",
    "es-ES": "Muévete con las piernas, no estirando el brazo: cada bola a la "
             "que llegas estirado es una a la que te daba tiempo a ir.",
    "fr-FR": "Déplace-toi avec les jambes, pas en tendant le bras : chaque "
             "balle cherchée en extension était à un pas.",
    "id-ID": "Bergerak dengan kaki, bukan dengan menjangkau.",
    "ms-MY": "Bergerak dengan kaki, bukan dengan menghulur.",
    "th-TH": "เคลื่อนที่ด้วยขา ไม่ใช่ด้วยการเอื้อม",
    "vi-VN": "Di chuyển bằng chân, không phải với tay.",
}


FOOT_PURPOSE = {
    "en": "Footwork with the ball: the feeder sets the pattern and the pace, so the worker learns to arrive in position for every ball and hit it the same way, again and again.",
    "en-GB": "Footwork with the ball: the feeder sets the pattern and the pace, so the worker learns to arrive in position for every ball and hit it the same way, again and again.",
    "zh-CN": "带球的步法训练：喂球的人定好线路和节奏，练习者每一球都要先移动到位，再用同样的动作击球，一遍又一遍。",
    "zh-TW": "帶球的步法訓練：餵球的人定好線路和節奏，練習者每一球都要先移動到位，再用同樣的動作擊球，一遍又一遍。",
    "ja-JP": "ボールを使ったフットワーク：送る側がコースとテンポを決め、練習者は毎球まず位置に入り、同じ形で打つことを繰り返す。",
    "ko-KR": "공을 쓰는 풋워크: 주는 쪽이 코스와 템포를 정하고, 연습자는 매 공마다 먼저 자리에 들어가 같은 동작으로 치는 것을 반복한다.",
    "es-ES": "Juego de pies con bola: quien alimenta marca el patrón y el ritmo, y el jugador aprende a llegar colocado a cada bola y a golpearla igual, una y otra vez.",
    "fr-FR": "Jeu de jambes avec balle : le distributeur fixe le parcours et le rythme, et le joueur apprend à arriver placé sur chaque balle et à la frapper de la même façon, encore et encore.",
    "id-ID": "Footwork dengan bola: pengumpan menentukan pola dan tempo, jadi pemain belajar tiba di posisi untuk setiap bola dan memukulnya dengan cara yang sama, berulang-ulang.",
    "ms-MY": "Kerja kaki dengan bola: pengumpan menetapkan corak dan rentak, jadi pemain belajar tiba di kedudukan untuk setiap bola dan memukulnya dengan cara yang sama, berulang kali.",
    "th-TH": "ฟุตเวิร์กกับลูก: คนป้อนกำหนดทางลูกและจังหวะ ผู้ฝึกต้องเข้าตำแหน่งให้ทันทุกลูกแล้วตีด้วยท่าเดิมซ้ำแล้วซ้ำเล่า",
    "vi-VN": "Di chuyển chân có bóng: người tiếp bóng định đường bóng và nhịp, người tập học cách vào đúng vị trí cho từng quả và đánh cùng một cách, lặp đi lặp lại.",
}
# The stations the feet get to, on the floor just behind the end line —
# never on the table, which is where the ball bounces, not where anyone stands.
STATION_Y = 1.12
CONE_Y = 1.05


def footwork_family() -> list[Drill]:
    """Short-then-long, the Falkenberg, and side to side — each drawn as the
    feeder's balls and the worker's returns, not a man shuffling alone."""
    out = []
    feeder = (0.50, -0.12)
    # In and out: the short ball at the table, then the step back to loop
    # the long one. (The id is the old name; the drill is this pattern.)
    out.append(tt(
        "tt_footwork_two_one", "possession", 10,
        suffixed(FOOT_NAME, {
            "en": "short, then long", "en-GB": "short, then long",
            "zh-CN": "一短一长", "zh-TW": "一短一長",
            "ja-JP": "ショートのあとロング", "ko-KR": "짧게, 그다음 길게",
            "es-ES": "corta y luego larga", "fr-FR": "courte puis longue",
            "id-ID": "pendek lalu panjang", "ms-MY": "pendek kemudian panjang",
            "th-TH": "สั้นแล้วยาว", "vi-VN": "ngắn rồi dài"}), FOOT_NOTE,
        home=[P(0.50, 1.14, "1", moves=[(0.44, 1.03, 0), (FH, 1.16, 2)])],
        # The feeder takes each return and is already set for the next.
        away=[P(*feeder, "2", moves=[(0.40, -0.12, 1), (0.50, -0.12, 3)])],
        ball=feeder, ball_to=[(0, 0), ("a0", 1), (0, 2), ("a0", 3)],
        free=True,
    ))
    # Falkenberg: backhand from the backhand corner, forehand from the same
    # corner, then across to the wide forehand.
    stations = [(BH, STATION_Y), (0.42, STATION_Y), (FH + 0.06, STATION_Y)]
    out.append(tt(
        "tt_footwork_falkenberg", "possession", 10,
        suffixed(FOOT_NAME, "Falkenberg"), FOOT_NOTE,
        home=[P(*stations[0], "1", moves=[stations[1] + (2,), stations[2] + (4,)])],
        away=[P(*feeder, "2", moves=[(0.42, -0.12, 1), (0.58, -0.12, 3),
                                    (0.50, -0.12, 5)])],
        ball=feeder,
        ball_to=[(0, 0), ("a0", 1), (0, 2), ("a0", 3), (0, 4), ("a0", 5)],
    ))
    sides = [(BH - 0.06, STATION_Y), (FH + 0.06, STATION_Y)]
    out.append(tt(
        "tt_footwork_side_to_side", "possession", 8,
        suffixed(FOOT_NAME, "side to side"), FOOT_NOTE,
        home=[P(0.50, 1.14, "1", moves=[sides[0] + (0,), sides[1] + (2,)])],
        away=[P(*feeder, "2", moves=[(0.58, -0.12, 1), (0.50, -0.12, 3)])],
        ball=feeder, ball_to=[(0, 0), ("a0", 1), (0, 2), ("a0", 3)],
    ))
    for d in out:
        d.purpose = FOOT_PURPOSE
    return out


RALLY_NAME = {
    "en": "Rally control", "en-GB": "Rally control", "zh-CN": "相持控制",
    "zh-TW": "相持控制", "ja-JP": "ラリーの組み立て", "ko-KR": "랠리 컨트롤",
    "es-ES": "Control del peloteo", "fr-FR": "Contrôle de l'échange",
    "id-ID": "Kontrol reli", "ms-MY": "Kawalan rali",
    "th-TH": "การคุมเกมโต้", "vi-VN": "Kiểm soát đôi công",
}
RALLY_NOTE = {
    "en": "Play the ball early, on the rise. Every step back you take gives "
          "the other end an extra half second to choose with.",
    "en-GB": "Play the ball early, on the rise. Every step back you take gives "
             "the other end an extra half second to choose with.",
    "zh-CN": "上升期就击球。你每往后退一步，就等于多送对面半秒去选择。",
    "zh-TW": "上升期就擊球。你每往後退一步，就等於多送對面半秒去選擇。",
    "ja-JP": "ライジングで早く捉える。一歩下がるたびに、相手に選ぶための0.5秒を渡している。",
    "ko-KR": "라이징에서 일찍 잡아라. 한 발 물러설 때마다 상대에게 0.5초를 준다.",
    "es-ES": "Golpea pronto, en el ascenso: cada paso atrás le regala al rival "
             "medio segundo para elegir.",
    "fr-FR": "Prends la balle tôt, à la montée : chaque pas en arrière offre "
             "une demi-seconde de choix à l'adversaire.",
    "id-ID": "Pukul bola lebih awal, saat naik.",
    "ms-MY": "Pukul bola awal, ketika naik.",
    "th-TH": "ตีลูกเร็วตอนขาขึ้น ทุกก้าวที่ถอยคือให้เวลาคู่แข่งเพิ่มครึ่งวินาที",
    "vi-VN": "Đánh bóng sớm, ở pha bóng lên.",
}


def rally_family() -> list[Drill]:
    specs = [("block_drive", "block against the drive", 1.06, FH),
             ("counter_drive", "counter-drive", 1.20, FH),
             ("push_rally", "half-long push rally", 1.10, BH)]
    out = []
    for key, label, depth, x in specs:
        out.append(tt(
            f"tt_rally_{key}", "possession", 10,
            suffixed(RALLY_NAME, label), RALLY_NOTE,
            home=[P(x, depth, "1", moves=[(x, depth - 0.06, 0), (x, depth, 1)])],
            away=[P(1 - x, -0.16, "2", moves=[(1 - x, -0.10, 0)])],
            markers=[M(x, NEAR if key == "push_rally" else DEEP, "zone", "")],
            ball=0, free=(key == "block_drive"),
        ))
    return out


LOOP_NAME = {
    "en": "Loop", "en-GB": "Loop", "zh-CN": "拉弧圈", "zh-TW": "拉弧圈",
    "ja-JP": "ループドライブ", "ko-KR": "루프 드라이브",
    "es-ES": "Top spin", "fr-FR": "Top spin", "id-ID": "Loop",
    "ms-MY": "Loop", "th-TH": "ลูปไดรฟ์", "vi-VN": "Giật bóng",
}
LOOP_NOTE = {
    "en": "Brush the ball, don't hit through it. Against backspin the racket "
          "starts below the ball and finishes above your own head.",
    "en-GB": "Brush the ball, don't hit through it. Against backspin the "
             "racket starts below the ball and finishes above your own head.",
    "zh-CN": "要摩擦，不要撞击。对付下旋，拍子从球下面出发，收在自己头顶上方。",
    "zh-TW": "要摩擦，不要撞擊。對付下旋，拍子從球下面出發，收在自己頭頂上方。",
    "ja-JP": "こすって薄く捉える、押し抜かない。下回転に対してはラケットを球の下から出し、頭の上で振り終える。",
    "ko-KR": "때리지 말고 감아라. 백스핀에는 라켓이 공 아래에서 출발해 머리 위에서 끝난다.",
    "es-ES": "Roza la bola, no la golpees de lleno: contra el cortado la pala "
             "sale por debajo y termina por encima de tu cabeza.",
    "fr-FR": "Frotte la balle, ne la percute pas : contre le coupé, la raquette "
             "part sous la balle et finit au-dessus de la tête.",
    "id-ID": "Gesek bolanya, jangan dipukul tembus.",
    "ms-MY": "Gosok bola, jangan pukul tembus.",
    "th-TH": "ปัดเฉี่ยวลูก อย่ากระแทกทะลุ ถ้าเจอลูกหลังหมุนให้เริ่มใต้ลูกและจบเหนือหัว",
    "vi-VN": "Cọ vào bóng, đừng đánh xuyên qua.",
}


LOOP_FLAT_NOTE = {
    "en": "Against topspin the bat starts behind the ball, not below it, and the arm drives forward rather than up. Brushing up against a ball that already spins forward sends it into the net.",
    "en-GB": "Against topspin the bat starts behind the ball, not below it, and the arm drives forward rather than up. Brushing up against a ball that already spins forward sends it into the net.",
    "zh-CN": "对上旋球，拍子从球的后面出发，不是从球的下面；手臂向前送，不是向上兜。对着本来就往前转的球往上刷，只会下网。",
    "zh-TW": "對上旋球，拍子從球的後面出發，不是從球的下面；手臂向前送，不是向上兜。對著本來就往前轉的球往上刷，只會下網。",
    "ja-JP": "上回転に対してはラケットをボールの後ろから出す。下からではない。腕は上ではなく前へ。前進回転の球を下から擦れば必ずネットだ。",
    "ko-KR": "톱스핀 상대로는 라켓이 공 아래가 아니라 뒤에서 출발하고, 팔은 위가 아니라 앞으로 민다.",
    "es-ES": "Contra el topspin la pala sale por detrás de la bola, no por debajo, y el brazo empuja hacia delante, no hacia arriba.",
    "fr-FR": "Contre le lift, la raquette part derrière la balle et non dessous, et le bras pousse vers l'avant plutôt que vers le haut.",
    "id-ID": "Melawan topspin, bet mulai dari belakang bola, bukan dari bawah, dan lengan mendorong ke depan.",
    "ms-MY": "Menentang topspin, bet bermula dari belakang bola, bukan dari bawah.",
    "th-TH": "เจอลูกท็อปสปิน ไม้เริ่มจากด้านหลังลูก ไม่ใช่ด้านล่าง และแขนดันไปข้างหน้า",
    "vi-VN": "Trước bóng xoáy lên, vợt xuất phát từ phía sau bóng chứ không phải bên dưới, và tay đẩy tới trước.",
}


def loop_family() -> list[Drill]:
    # 2 gives the ball the drill is named against (a push, a block, a loop);
    # 1 loops it into the zone and recovers. 1 never starts with the ball:
    # that would be a serve, and no loop drill starts with one.
    specs = [("vs_backspin", "against backspin", 1.16, FH),
             ("vs_block", "against the block", 1.12, FH),
             # From the backhand corner: 1 stays in it and pivots — the
             # whole point is not drifting to the middle first.
             ("from_backhand", "from the backhand corner", 1.14, BH - 0.04),
             ("counter_loop", "counter-loop", 1.18, FH)]
    out = []
    for key, label, depth, x in specs:
        feeder = (1 - x, -0.12)
        zone = (FH if x < 0.5 else BH, 1 - DEEP)
        out.append(tt(
            f"tt_loop_{key}", "attacking", 10,
            suffixed(LOOP_NAME, label),
            # Looping a block or counterlooping starts behind the ball and
            # drives forward; the family note is about looping backspin,
            # where the racket starts below. Taught the other way round it
            # puts every ball into the net.
            LOOP_NOTE if key == "vs_backspin" else LOOP_FLAT_NOTE,
            home=[P(0.50, 1.14, "1", moves=[(x, depth, 0), (0.50, 1.14, 2)])],
            away=[P(*feeder, "2", moves=[(zone[0], -0.10, 1)])],
            markers=[M(*zone, "zone", "")],
            ball=feeder, ball_to=[(0, 0), (Spot(*zone), 1)],
            free=(key == "vs_backspin"),
        ))
    return out


SHORT_NAME = {
    "en": "Short game", "en-GB": "Short game", "zh-CN": "台内球",
    "zh-TW": "台內球", "ja-JP": "台上プレー", "ko-KR": "테이블 위 플레이",
    "es-ES": "Juego corto", "fr-FR": "Jeu court", "id-ID": "Permainan pendek",
    "ms-MY": "Permainan pendek", "th-TH": "ลูกสั้นบนโต๊ะ", "vi-VN": "Bóng ngắn trên bàn",
}
SHORT_NOTE = {
    "en": "Step in with the right foot under the table and take it at the top "
          "of the bounce. Reaching from outside makes every short ball long.",
    "en-GB": "Step in with the right foot under the table and take it at the "
             "top of the bounce. Reaching from outside makes every short ball long.",
    "zh-CN": "右脚上步伸进台下，在最高点触球。站在台外伸手够，会把每一个短球都处理成长球。",
    "zh-TW": "右腳上步伸進台下，在最高點觸球。站在台外伸手夠，會把每一個短球都處理成長球。",
    "ja-JP": "右足を台の下へ踏み込み、バウンドの頂点で捉える。外から手を伸ばすと短い球が全部長くなる。",
    "ko-KR": "오른발을 테이블 밑으로 넣고 바운드 정점에서 잡아라.",
    "es-ES": "Entra con el pie derecho bajo la mesa y tómala en el punto alto: "
             "estirarte desde fuera alarga todas las bolas cortas.",
    "fr-FR": "Entre le pied droit sous la table et prends la balle au sommet "
             "du rebond : tendre le bras de l'extérieur allonge toutes les balles courtes.",
    "id-ID": "Masukkan kaki kanan ke bawah meja dan ambil di puncak pantulan.",
    "ms-MY": "Masukkan kaki kanan ke bawah meja dan ambil di puncak lantunan.",
    "th-TH": "ก้าวเท้าขวาเข้าใต้โต๊ะ แล้วรับที่จุดสูงสุดของการกระดอน",
    "vi-VN": "Bước chân phải vào dưới bàn và đón ở đỉnh nảy.",
}


def short_family() -> list[Drill]:
    # 2 serves short; 1 steps in under the table and plays the stroke the
    # drill is named for into the zone on 2's half, then gets back out.
    specs = [("touch", "the short touch", (0.50, 0.42)),
             ("flick", "the flick", (BH, 0.30)),
             ("banana", "the banana flick", (FH, 0.34)),
             ("long_push", "the long push", (BH, 0.08))]
    out = []
    for key, label, land in specs:
        server = (0.50, -0.12)
        out.append(tt(
            f"tt_short_{key}", "attacking", 8,
            suffixed(SHORT_NAME, label), SHORT_NOTE,
            home=[P(*HOME_READY, "1", moves=[(0.42, 1.02, 0), (0.50, 1.14, 2)])],
            away=[P(*server, "2", moves=[(land[0], -0.10, 1)])],
            markers=[M(*land, "zone", "")],
            ball=server, ball_to=[(0, 0), (Spot(*land), 1)],
            free=(key == "touch"),
        ))
    return out


KILL_NAME = {
    "en": "Finishing", "en-GB": "Finishing", "zh-CN": "得分球", "zh-TW": "得分球",
    "ja-JP": "決定打", "ko-KR": "결정타", "es-ES": "Definición",
    "fr-FR": "Coup décisif", "id-ID": "Pukulan penentu", "ms-MY": "Pukulan penamat",
    "th-TH": "ลูกจบ", "vi-VN": "Cú dứt điểm",
}
KILL_NOTE = {
    "en": "Pick the corner before the ball arrives. Deciding late is how a "
          "sitter ends up hit at three-quarter pace into the middle.",
    "en-GB": "Pick the corner before the ball arrives. Deciding late is how a "
             "sitter ends up hit at three-quarter pace into the middle.",
    "zh-CN": "球到之前就选好角。犹豫得晚，机会球就会变成七成力打向中路的那一板。",
    "zh-TW": "球到之前就選好角。猶豫得晚，機會球就會變成七成力打向中路的那一板。",
    "ja-JP": "球が来る前にコースを決める。決断が遅いから、絶好球が七分の力で真ん中に飛ぶ。",
    "ko-KR": "공이 오기 전에 코스를 정하라. 늦게 정하면 찬스볼이 70퍼센트 힘으로 가운데로 간다.",
    "es-ES": "Elige la esquina antes de que llegue la bola: decidir tarde "
             "convierte un regalo en un golpe al medio a tres cuartos de fuerza.",
    "fr-FR": "Choisis le coin avant l'arrivée de la balle : décider tard, "
             "c'est frapper une balle facile au trois quarts, au milieu.",
    "id-ID": "Pilih sudutnya sebelum bola datang.",
    "ms-MY": "Pilih sudutnya sebelum bola sampai.",
    "th-TH": "เลือกมุมก่อนบอลมาถึง ถ้าตัดสินใจช้า ลูกง่ายจะกลายเป็นลูกกลางโต๊ะแรงเจ็ดส่วน",
    "vi-VN": "Chọn góc trước khi bóng đến.",
}


def kill_family() -> list[Drill]:
    # 2 gives the high or loose ball, 1 moves in and finishes into the zone.
    specs = [("smash", "the smash", (BH, 0.06)), ("wide_forehand", "from the wide forehand", (BH, 0.14)),
             ("into_the_body", "into the body", (0.50, 0.10))]
    out = []
    for key, label, land in specs:
        x = FH + 0.10 if key == "wide_forehand" else 0.50
        feeder = (0.50, -0.12)
        out.append(tt(
            f"tt_kill_{key}", "finishing", 8,
            suffixed(KILL_NAME, label), KILL_NOTE,
            home=[P(0.50, 1.16, "1", moves=[(x, 1.08, 0), (0.50, 1.14, 2)])],
            away=[P(*feeder, "2", moves=[(land[0], -0.10, 1)])],
            markers=[M(*land, "zone", "")],
            ball=feeder, ball_to=[(0, 0), (Spot(*land), 1)],
            free=(key == "smash"),
        ))
    return out


DEF_NAME = {
    "en": "Defending", "en-GB": "Defending", "zh-CN": "防守", "zh-TW": "防守",
    "ja-JP": "ディフェンス", "ko-KR": "수비", "es-ES": "Defensa",
    "fr-FR": "Défense", "id-ID": "Bertahan", "ms-MY": "Pertahanan",
    "th-TH": "การรับ", "vi-VN": "Phòng thủ",
}
DEF_NOTE = {
    "en": "Change the spin, not just the direction. A defensive ball that "
          "comes back the same is a ball they get to hit again, harder.",
    "en-GB": "Change the spin, not just the direction. A defensive ball that "
             "comes back the same is a ball they get to hit again, harder.",
    "zh-CN": "要变旋转，不只是变线路。旋转不变的防守球，只是让对手再打一板，而且更重。",
    "zh-TW": "要變旋轉，不只是變線路。旋轉不變的防守球，只是讓對手再打一板，而且更重。",
    "ja-JP": "コースだけでなく回転を変える。同じ回転で返す守備は、相手にもう一度、より強く打たせるだけ。",
    "ko-KR": "방향만이 아니라 회전을 바꿔라. 같은 회전으로 돌아온 공은 더 세게 한 번 더 맞을 공이다.",
    "es-ES": "Cambia el efecto, no solo la dirección: una bola defensiva igual "
             "es una bola que volverán a pegar, más fuerte.",
    "fr-FR": "Change l'effet, pas seulement la direction : une balle défensive "
             "identique sera reprise, plus fort.",
    "id-ID": "Ubah spinnya, bukan hanya arahnya.",
    "ms-MY": "Ubah putarannya, bukan hanya arahnya.",
    "th-TH": "เปลี่ยนสปิน ไม่ใช่แค่เปลี่ยนทาง",
    "vi-VN": "Đổi độ xoáy, không chỉ đổi hướng.",
}


def defence_family() -> list[Drill]:
    # Three different strokes at three different distances: a chop block is
    # played *at* the table with a short sideways action, a deep chop from
    # well back, a lob from further back still. The board shows as much floor
    # as a phone has — 0.55 m behind the table — so "deep" is drawn as the
    # back of the board, never off it.
    feeder = (0.50, -0.12)
    specs = [("chop_block", "the chop block", (0.36, 0.04),
              [(BH, 1.02, 0), (0.50, 1.06, 2)],
              [(0, 0), (Spot(0.36, 0.04), 1)]),
             ("deep_chop", "the deep chop", (0.50, 0.06),
              [(BH, 1.18, 0), (FH, 1.18, 2)],
              [(0, 0), ("a0", 1), (0, 2), (Spot(0.50, 0.06), 3)]),
             ("lob", "the lob and recover", (0.50, 0.10),
              [(FH + 0.06, 1.20, 0), (0.50, 1.12, 2)],
              [(0, 0), (Spot(0.50, 0.10), 1)])]
    out = []
    for key, label, target, path, route in specs:
        out.append(tt(
            f"tt_defence_{key}", "defending", 10,
            suffixed(DEF_NAME, {
                "en": "the chop block", "en-GB": "the chop block",
                "zh-CN": "侧切挡", "zh-TW": "側切擋", "ja-JP": "チョップブロック",
                "ko-KR": "촙 블록", "es-ES": "bloqueo cortado",
                "fr-FR": "bloc coupé", "id-ID": "blok potong",
                "ms-MY": "blok potong", "th-TH": "บล็อกตัด",
                "vi-VN": "chặn cắt"} if key == "chop_block" else label),
            DEF_NOTE,
            home=[P(0.50, 1.10, "1", moves=path)],
            away=[P(*feeder, "2", moves=[(target[0] + 0.06, -0.10, 1)])],
            markers=[M(*target, "zone", "")],
            ball=feeder, ball_to=route, free=(key == "chop_block"),
        ))
    return out


SERVE_NAME = {
    "en": "Serve", "en-GB": "Serve", "zh-CN": "发球", "zh-TW": "發球",
    "ja-JP": "サーブ", "ko-KR": "서브", "es-ES": "Saque", "fr-FR": "Service",
    "id-ID": "Servis", "ms-MY": "Servis", "th-TH": "การเสิร์ฟ", "vi-VN": "Giao bóng",
}
SERVE_NOTE = {
    "en": "Serve to set up the third ball you already know you want to play. "
          "A great serve with no plan behind it wins one point by accident.",
    "en-GB": "Serve to set up the third ball you already know you want to "
             "play. A great serve with no plan behind it wins one point by accident.",
    "zh-CN": "发球是为了铺垫你早就想好的第三板。没有后续计划的好发球，只能靠运气赢一分。",
    "zh-TW": "發球是為了鋪墊你早就想好的第三板。沒有後續計畫的好發球，只能靠運氣贏一分。",
    "ja-JP": "サーブは、既に打つと決めている3球目を作るためのもの。狙いのない好サーブは偶然1点取るだけ。",
    "ko-KR": "서브는 이미 정해둔 3구를 만들기 위한 것이다. 계획 없는 좋은 서브는 우연히 1점일 뿐이다.",
    "es-ES": "Saca para preparar la tercera bola que ya sabes que quieres "
             "jugar: un gran saque sin plan gana un punto por casualidad.",
    "fr-FR": "Sers pour préparer la troisième balle que tu as déjà choisie : "
             "un beau service sans plan gagne un point par hasard.",
    "id-ID": "Servis untuk menyiapkan bola ketiga yang sudah kamu rencanakan.",
    "ms-MY": "Servis untuk menyediakan bola ketiga yang sudah anda rancang.",
    "th-TH": "เสิร์ฟเพื่อเตรียมลูกที่สามที่คุณตั้งใจจะเล่นอยู่แล้ว",
    "vi-VN": "Giao bóng để dọn cho quả thứ ba bạn đã định đánh.",
}


def _through(src, zone, y):
    """Where a receiver standing at depth y meets a serve from src that
    bounces in zone — so the line drawn to him crosses the zone it names."""
    sx, sy = src
    zx, zy = zone
    return (sx + (zx - sx) * (sy - y) / (sy - zy), y)


def serve_family() -> list[Drill]:
    server = (BH - 0.10, 1.14)
    specs = [("short_backspin", "short backspin", (0.50, 0.38), -0.10),
             ("long_fast", "long and fast", (BH, 0.06), -0.12),
             ("sidespin_wide", "sidespin wide", (FH + 0.08, 0.30), -0.08),
             ("third_ball", "serve and third ball", (0.50, 0.36), -0.10)]
    out = []
    for key, label, land, depth in specs:
        receive = _through(server, land, depth)
        markers = [M(*land, "zone", "")]
        if key == "third_ball":
            # Serve short, take the push with the forehand, attack it deep.
            attack = (0.20, 0.12)
            home = [P(*server, "S", moves=[(0.62, 1.12, 1)])]
            route = [("a0", 0), (0, 1), (Spot(*attack), 2)]
            markers.append(M(*attack, "zone", ""))
        else:
            home = [P(*server, "S", moves=[(0.50, 1.14, 1)])]
            route = [("a0", 0), (0, 1)]
        out.append(tt(
            f"tt_serve_{key}", "setpiece", 8,
            suffixed(SERVE_NAME, label), SERVE_NOTE,
            home=home,
            away=[P(0.50, -0.14, "R", moves=[receive + (0,)])],
            markers=markers,
            ball=0, ball_to=route,
            free=(key in ("short_backspin", "third_ball")),
        ))
    return out


GAME_NAME = {
    "en": "Match play", "en-GB": "Match play", "zh-CN": "实战对抗",
    "zh-TW": "實戰對抗", "ja-JP": "ゲーム練習", "ko-KR": "실전 게임",
    "es-ES": "Juego de partido", "fr-FR": "Jeu en match",
    "id-ID": "Permainan pertandingan", "ms-MY": "Permainan perlawanan",
    "th-TH": "เล่นแบบแข่งขัน", "vi-VN": "Đánh như thi đấu",
}
GAME_NOTE = {
    "en": "Restrict the table and the tactic has nowhere to hide. Half-table "
          "games expose the player who only wins by hitting harder.",
    "en-GB": "Restrict the table and the tactic has nowhere to hide. "
             "Half-table games expose the player who only wins by hitting harder.",
    "zh-CN": "把台面限制住，战术就无处可藏。半台对抗会立刻暴露那种只会靠打得更重赢球的人。",
    "zh-TW": "把台面限制住，戰術就無處可藏。半台對抗會立刻暴露那種只會靠打得更重贏球的人。",
    "ja-JP": "台を制限すれば戦術は隠れられない。ハーフ台のゲームは、強く打つだけの選手をすぐ暴く。",
    "ko-KR": "테이블을 제한하면 전술은 숨을 곳이 없다. 하프 테이블 게임은 세게만 치는 선수를 드러낸다.",
    "es-ES": "Restringe la mesa y la táctica no tiene dónde esconderse: media "
             "mesa desnuda al que solo gana pegando más fuerte.",
    "fr-FR": "Restreins la table et la tactique n'a plus où se cacher : la "
             "demi-table démasque celui qui ne gagne qu'en frappant fort.",
    "id-ID": "Batasi mejanya dan taktik tak punya tempat sembunyi.",
    "ms-MY": "Hadkan meja dan taktik tiada tempat untuk bersembunyi.",
    "th-TH": "จำกัดพื้นที่โต๊ะ แล้วแท็กติกจะไม่มีที่ซ่อน",
    "vi-VN": "Giới hạn mặt bàn, chiến thuật hết chỗ trốn.",
}


OPEN_GAME_NOTE = {
    "en": "Play the point you have, not the one you rehearsed. Most rallies end by the fifth ball, so the plan has to survive the first two or it was never a plan.",
    "en-GB": "Play the point you have, not the one you rehearsed. Most rallies end by the fifth ball, so the plan has to survive the first two or it was never a plan.",
    "zh-CN": "打眼前这一分，不是打你练过的那一分。多数回合在第五板之前就结束了，所以战术必须能挺过前两板，否则它根本不算战术。",
    "zh-TW": "打眼前這一分，不是打你練過的那一分。多數回合在第五板之前就結束了，所以戰術必須能挺過前兩板，否則它根本不算戰術。",
    "ja-JP": "練習した点ではなく、目の前の点を打つ。多くのラリーは5球目までに終わるので、戦術は最初の2球を生き延びなければ戦術ではない。",
    "ko-KR": "연습한 포인트가 아니라 지금 있는 포인트를 쳐라. 대부분의 랠리는 다섯 번째 공 안에 끝난다.",
    "es-ES": "Juega el punto que tienes, no el que ensayaste: casi todos los peloteos acaban en la quinta bola.",
    "fr-FR": "Joue le point que tu as, pas celui que tu as répété : la plupart des échanges finissent à la cinquième balle.",
    "id-ID": "Mainkan poin yang ada, bukan yang kamu latih. Kebanyakan reli selesai pada bola kelima.",
    "ms-MY": "Mainkan mata yang ada, bukan yang anda latih.",
    "th-TH": "เล่นแต้มที่อยู่ตรงหน้า ไม่ใช่แต้มที่ซ้อมมา แรลลี่ส่วนใหญ่จบภายในลูกที่ห้า",
    "vi-VN": "Chơi điểm đang có, không phải điểm đã tập. Phần lớn các pha bóng kết thúc trước quả thứ năm.",
}
DOUBLES_GAME_NOTE = {
    "en": "Every serve goes right half to right half, and you must alternate every ball — so the rotation is the drill: hit, and get out of your partner's way on the same movement.",
    "en-GB": "Every serve goes right half to right half, and you must alternate every ball — so the rotation is the drill: hit, and get out of your partner's way on the same movement.",
    "zh-CN": "发球必须右半台发到对方右半台，而且每球轮换——所以轮转本身就是训练内容：击完球的同一个动作里就让开搭档的位置。",
    "zh-TW": "發球必須右半台發到對方右半台，而且每球輪換——所以輪轉本身就是訓練內容：擊完球的同一個動作裡就讓開搭檔的位置。",
    "ja-JP": "サーブは必ず右半面から右半面へ、そして一球ごとに交互に打つ。だからローテーションこそが練習だ。打つ動作のまま相手の進路を空ける。",
    "ko-KR": "서브는 오른쪽 반면에서 오른쪽 반면으로, 그리고 매 공마다 교대한다. 그래서 로테이션 자체가 훈련이다.",
    "es-ES": "El saque va siempre de media derecha a media derecha y hay que alternar cada bola: la rotación es el ejercicio.",
    "fr-FR": "Le service va toujours de demi-table droite à demi-table droite et il faut alterner à chaque balle : la rotation est l'exercice.",
    "id-ID": "Servis selalu dari separuh kanan ke separuh kanan, dan harus bergantian setiap bola.",
    "ms-MY": "Servis sentiasa dari separuh kanan ke separuh kanan, dan mesti berselang-seli setiap bola.",
    "th-TH": "เสิร์ฟจากครึ่งขวาไปครึ่งขวาเสมอ และต้องสลับตีทุกลูก",
    "vi-VN": "Giao bóng luôn từ nửa phải sang nửa phải, và phải luân phiên mỗi quả.",
}


def game_family() -> list[Drill]:
    specs = [("half_table", "half table", BH), ("serve_receive", "serve and receive only", 0.50),
             ("full_match", "full match", 0.50), ("doubles", "doubles rotation", FH)]
    out = []
    for key, label, x in specs:
        home = [P(x, 1.14, "1", moves=[(x, 1.08, 0)])]
        away = [P(1 - x, -0.14, "A", moves=[(1 - x, -0.08, 0)])]
        route = [("a0", 0), (0, 1)]
        markers = []
        if key == "half_table":
            # The backhand diagonal: each side's backhand half is shaded.
            markers = [M(0.25, 0.75, "zone", ""), M(0.75, 0.25, "zone", "")]
        if key == "serve_receive":
            # A serve-and-receive game is two balls and stop: the serve, and
            # the receiver's answer; the server is back in position for it.
            home = [P(0.50, 1.14, "1", moves=[(0.56, 1.14, 1)])]
            away = [P(0.44, -0.14, "A",
                      moves=[_through((0.50, 1.14), (0.44, 0.06), -0.12) + (0,)])]
            markers = [M(0.44, 0.06, "zone", "")]
        if key == "doubles":
            # ITTF 2.2.2 and 2.8.3: serve from the server's right half to the
            # receiver's right half (diagonal), then strict alternation —
            # 1, A, 2, B. Each hitter steps out sideways on the same movement
            # so the partner can step in; the depth stays on the board.
            home = [P(FH, 1.10, "1", moves=[(FH + 0.16, 1.18, 0), (0.50, 1.10, 3)]),
                    P(BH, 1.18, "2", moves=[(0.46, 1.10, 1), (BH - 0.10, 1.18, 2)])]
            away = [P(BH, -0.10, "A", moves=[(BH - 0.16, -0.18, 1)]),
                    P(FH, -0.18, "B", moves=[(0.54, -0.10, 1), (FH + 0.10, -0.18, 3)])]
            route = [("a0", 0), (1, 1), ("a1", 2), (0, 3)]
        out.append(tt(
            f"tt_game_{key}", "ssg", 15,
            suffixed(GAME_NAME, label),
            # "Restrict the table and the tactic has nowhere to hide" is
            # about the half-table game only; it said nothing on the other
            # three, and nothing at all about doubles rotation.
            GAME_NOTE if key == "half_table" else
            (DOUBLES_GAME_NOTE if key == "doubles" else OPEN_GAME_NOTE),
            home=home, away=away, markers=markers,
            ball=0, ball_to=route, free=(key in ("full_match", "half_table")),
        ))
    return out


def table_tennis_library() -> list[Drill]:
    return (warmup_family() + multiball() + footwork_family() + rally_family()
            + short_family() + loop_family() + kill_family()
            + defence_family() + serve_family() + game_family())

def multiball() -> list[Drill]:
    """Multiball — the other canonical feeding drill. The coach stands beside
    the far end of the table with a basket; the player never waits for a
    rally to restart. Two balls, alternated: forehand corner, backhand corner."""
    # Behind the far end line, a little to one side, feeding over the net
    # the way a multiball coach does — not beside the table, where the
    # feed would come across the court instead of down it.
    basket = (0.62, -0.12)
    d = tt(
        "tt_multiball", "possession", 10,
        {"en": "Multiball", "en-GB": "Multiball",
         "zh-CN": "多球训练", "zh-TW": "多球訓練",
         "ja-JP": "多球練習", "ko-KR": "다구 연습",
         "es-ES": "Multibolas", "fr-FR": "Panier de balles",
         "id-ID": "Latihan multibola", "ms-MY": "Latihan multibola",
         "th-TH": "ฝึกหลายลูก", "vi-VN": "Tập đa bóng"},
        {"en": "One ball a second and no time to think between strokes — "
               "multiball buys ten times the repetitions of any rally.",
         "en-GB": "One ball a second and no time to think between strokes — "
                  "multiball buys ten times the repetitions of any rally.",
         "zh-CN": "一秒一球，两板之间没时间想。多球换来的重复次数，是对拉的十倍。",
         "zh-TW": "一秒一球，兩板之間沒時間想。多球換來的重複次數，是對拉的十倍。",
         "ja-JP": "1秒1球、考える間はない。多球はラリーの10倍の反復を買ってくれる。",
         "ko-KR": "1초에 한 공, 생각할 틈이 없다. 다구는 랠리의 열 배의 반복을 사준다.",
         "es-ES": "Una bola por segundo y sin tiempo de pensar entre golpes: "
                  "el multibolas compra diez veces las repeticiones de un peloteo.",
         "fr-FR": "Une balle par seconde, pas le temps de réfléchir : le panier "
                  "achète dix fois les répétitions d'un échange.",
         "id-ID": "Satu bola per detik, tanpa waktu berpikir di antara pukulan.",
         "ms-MY": "Satu bola sesaat, tiada masa berfikir antara pukulan.",
         "th-TH": "วินาทีละลูก ไม่มีเวลาคิดระหว่างจังหวะ ได้จำนวนซ้ำสิบเท่าของการโต้",
         "vi-VN": "Mỗi giây một bóng, không kịp nghĩ giữa hai cú đánh."},
        home=[P(0.50, 1.14, "1", moves=[(FH, 1.10, 0), (0.56, 1.14, 1),
                                        (BH, 1.10, 2), (0.44, 1.14, 3)])],
        away=[P(*basket, "C", coach=True)],
        markers=[M(0.75, 0.22, "zone", ""), M(0.25, 0.22, "zone", "")],
        ball=basket, ball_to=[(0, 0), (Spot(0.75, 0.22), 1)],
        ball2=basket, ball2_to=[(0, 2), (Spot(0.25, 0.22), 3)],
        free=True,
    )
    d.purpose = FOOT_PURPOSE
    d.setup = {
        "en": "a coach with a basket of balls behind the far end of the table, one player at the near end",
        "en-GB": "a coach with a basket of balls behind the far end of the table, one player at the near end",
        "zh-CN": "教练带一筐球站在球台远端的端线后，一名练习者在近端",
        "zh-TW": "教練帶一筐球站在球檯遠端的端線後，一名練習者在近端"}
    return [d]
