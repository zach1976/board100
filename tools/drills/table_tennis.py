"""The table tennis library.

The table is drawn small on purpose: the players stand well behind it and the
room they use is most of what a drill is about. So every board here places
people outside the table (y below 0 or above 1) and is marked off_surface —
that is not a mistake, it is where table tennis is played from.
"""
from .engine import Drill, M, P, suffixed

# Table corners in table coordinates; the net is y=0.5.
FH, BH = 0.78, 0.22               # the home player's forehand / backhand side
NEAR, DEEP = 0.62, 0.92           # where a ball lands on the home half
HOME_READY = (0.50, 1.16)         # ready position, behind the table
AWAY_READY = (0.50, -0.16)


def mirror(pt):
    return (pt[0], 1.0 - pt[1])


def tt(drill_id, category, minutes, name, note, home, away, markers=(),
       ball=None, free=False, rel=True) -> Drill:
    """A table tennis board — always off the table, because that is where the
    player stands."""
    return Drill(id=drill_id, category=category, minutes=minutes, rel=rel,
                 free=free, off_surface=True, name=name, note=note,
                 home=home, away=away, markers=list(markers), ball=ball)


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


def footwork_family() -> list[Drill]:
    """The three classic patterns: two-one, Falkenberg, side to side."""
    out = []
    out.append(tt(
        "tt_footwork_two_one", "warmup", 10,
        suffixed(FOOT_NAME, "two-one"), FOOT_NOTE,
        home=[P(*HOME_READY, "1", moves=[(BH, 1.14, 0), (0.50, 1.10, 1),
                                        (FH, 1.14, 2), (0.50, 1.16, 3)])],
        away=[P(*AWAY_READY, "2", moves=[(0.40, -0.12, 1)])],
        markers=[M(BH, DEEP, "cone", ""), M(FH, DEEP, "cone", "")],
        ball=AWAY_READY, free=True,
    ))
    out.append(tt(
        "tt_footwork_falkenberg", "warmup", 10,
        suffixed(FOOT_NAME, "Falkenberg"), FOOT_NOTE,
        home=[P(*HOME_READY, "1", moves=[(BH, 1.14, 0), (BH - 0.08, 1.20, 1),
                                        (FH, 1.14, 2), (0.50, 1.16, 3)])],
        away=[P(*AWAY_READY, "2", moves=[(0.46, -0.10, 1)])],
        markers=[M(BH, DEEP, "cone", ""), M(FH, DEEP, "cone", ""), M(0.50, NEAR, "cone", "")],
        ball=AWAY_READY,
    ))
    out.append(tt(
        "tt_footwork_side_to_side", "warmup", 8,
        suffixed(FOOT_NAME, "side to side"), FOOT_NOTE,
        home=[P(*HOME_READY, "1", moves=[(BH - 0.06, 1.16, 0), (FH + 0.06, 1.16, 1),
                                        (0.50, 1.16, 2)])],
        away=[P(*AWAY_READY, "2", moves=[(0.50, -0.10, 0)])],
        ball=AWAY_READY,
    ))
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


def loop_family() -> list[Drill]:
    specs = [("vs_backspin", "against backspin", 1.24, FH),
             ("vs_block", "against the block", 1.14, FH),
             ("from_backhand", "from the backhand corner", 1.18, BH),
             ("counter_loop", "counter-loop", 1.30, FH)]
    out = []
    for key, label, depth, x in specs:
        out.append(tt(
            f"tt_loop_{key}", "attacking", 10,
            suffixed(LOOP_NAME, label), LOOP_NOTE,
            home=[P(x, depth, "1", moves=[(x, depth - 0.10, 0), (0.50, 1.18, 1)])],
            away=[P(1 - x, -0.18, "2", moves=[(1 - x, -0.10, 1)])],
            markers=[M(1 - x, 1 - DEEP, "zone", "")],
            ball=0, free=(key == "vs_backspin"),
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
    specs = [("touch", "the short touch", (0.50, 0.42)),
             ("flick", "the flick", (BH, 0.30)),
             ("banana", "the banana flick", (FH, 0.34)),
             ("long_push", "the long push", (BH, 0.08))]
    out = []
    for key, label, land in specs:
        out.append(tt(
            f"tt_short_{key}", "attacking", 8,
            suffixed(SHORT_NAME, label), SHORT_NOTE,
            home=[P(*HOME_READY, "1", moves=[(0.40, 1.02, 0), (0.50, 1.16, 2)])],
            away=[P(*AWAY_READY, "2", moves=[(land[0], -0.10, 1)])],
            markers=[M(*land, "zone", ""), M(0.40, NEAR, "cone", "")],
            ball=AWAY_READY, free=(key == "touch"),
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
    specs = [("smash", "the smash", (BH, 0.06)), ("wide_forehand", "from the wide forehand", (BH, 0.14)),
             ("into_the_body", "into the body", (0.50, 0.10))]
    out = []
    for key, label, land in specs:
        x = FH + 0.10 if key == "wide_forehand" else 0.50
        out.append(tt(
            f"tt_kill_{key}", "finishing", 8,
            suffixed(KILL_NAME, label), KILL_NOTE,
            home=[P(x, 1.18, "1", moves=[(x, 1.08, 1), (0.50, 1.16, 2)])],
            away=[P(*AWAY_READY, "2", moves=[(land[0], -0.12, 2)])],
            markers=[M(*land, "zone", "")],
            ball=AWAY_READY, free=(key == "smash"),
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
    specs = [("chop_block", "the chop block", 1.08), ("deep_chop", "the deep chop", 1.34),
             ("lob", "the lob and recover", 1.30)]
    out = []
    for key, label, depth in specs:
        out.append(tt(
            f"tt_defence_{key}", "defending", 10,
            suffixed(DEF_NAME, label), DEF_NOTE,
            home=[P(0.50, depth, "1",
                    moves=[(BH, depth, 0), (FH, depth, 1), (0.50, depth, 2)])],
            away=[P(*AWAY_READY, "2", moves=[(BH, -0.12, 0), (FH, -0.12, 1)])],
            markers=[M(0.50, DEEP, "zone", "")],
            ball=AWAY_READY, free=(key == "chop_block"),
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


def serve_family() -> list[Drill]:
    specs = [("short_backspin", "short backspin", (0.50, 0.38)),
             ("long_fast", "long and fast", (BH, 0.06)),
             ("sidespin_wide", "sidespin wide", (FH + 0.08, 0.30)),
             ("third_ball", "serve and third ball", (0.50, 0.36))]
    out = []
    for key, label, land in specs:
        home = [P(BH - 0.10, 1.14, "S", moves=[(0.50, 1.16, 1)])]
        if key == "third_ball":
            home = [P(BH - 0.10, 1.14, "S",
                      moves=[(0.50, 1.16, 1), (FH, 1.14, 3)])]
        out.append(tt(
            f"tt_serve_{key}", "setpiece", 8,
            suffixed(SERVE_NAME, label), SERVE_NOTE,
            home=home,
            away=[P(*AWAY_READY, "R", moves=[(land[0], -0.10, 2)])],
            markers=[M(*land, "zone", "")],
            ball=0, free=(key in ("short_backspin", "third_ball")),
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


def game_family() -> list[Drill]:
    specs = [("half_table", "half table", BH), ("serve_receive", "serve and receive only", 0.50),
             ("full_match", "full match", 0.50), ("doubles", "doubles rotation", FH)]
    out = []
    for key, label, x in specs:
        home = [P(x, 1.16, "1", moves=[(x, 1.08, 0)])]
        away = [P(1 - x, -0.16, "A", moves=[(1 - x, -0.08, 0)])]
        if key == "doubles":
            home = [P(BH, 1.14, "1", moves=[(BH - 0.14, 1.24, 1)]),
                    P(BH - 0.16, 1.26, "2", moves=[(FH, 1.14, 1)])]
            away = [P(FH, -0.14, "A", moves=[(FH + 0.14, -0.24, 1)]),
                    P(FH + 0.16, -0.26, "B", moves=[(BH, -0.14, 1)])]
        out.append(tt(
            f"tt_game_{key}", "ssg", 15,
            suffixed(GAME_NAME, label), GAME_NOTE,
            home=home, away=away,
            markers=([M(0.50, DEEP, "cone", ""), M(0.50, 1 - DEEP, "cone", "")]
                     if key == "half_table" else []),
            ball=0, free=(key in ("full_match", "half_table")),
        ))
    return out


def table_tennis_library() -> list[Drill]:
    return (warmup_family() + multiball() + footwork_family() + rally_family()
            + short_family() + loop_family() + kill_family()
            + defence_family() + serve_family() + game_family())

def multiball() -> list[Drill]:
    """Multiball — the other canonical feeding drill. The coach stands beside
    the table with a basket; the player never waits for a rally to restart."""
    return [tt(
        "tt_multiball", "warmup", 10,
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
        home=[P(*HOME_READY, "1",
                moves=[(FH, 1.14, 0), (BH, 1.14, 1), (FH, 1.14, 2),
                       (0.50, 1.16, 3)])],
        away=[P(-0.28, 0.20, "C", moves=[(-0.28, 0.24, 1)])],
        markers=[M(FH, DEEP, "zone", ""), M(BH, DEEP, "zone", "")],
        ball=(-0.28, 0.20), free=True,
    )]

