"""The badminton library.

Badminton is played from a base and back to it: almost every drill here is a
shape describing where the player is pulled and how they recover. The court is
portrait with the net at y=0.5 and home at the bottom; doubles adds a partner
whose position is the other half of the answer.
"""
from .engine import Drill, M, P, suffixed

BASE = (0.50, 0.72)
# The four corners a singles player is worked between, plus the net tape.
FL, FR = (0.18, 0.58), (0.82, 0.58)
RL, RR = (0.14, 0.94), (0.86, 0.94)
NET_L, NET_R = (0.22, 0.545), (0.78, 0.545)


def mirror(pt):
    return (pt[0], 1.0 - pt[1])


FOOT_NAME = {
    "en": "Footwork to", "en-GB": "Footwork to", "zh-CN": "步法",
    "zh-TW": "步法", "ja-JP": "フットワーク", "ko-KR": "풋워크",
    "es-ES": "Desplazamiento a", "fr-FR": "Déplacement vers",
    "id-ID": "Footwork ke", "ms-MY": "Kerja kaki ke",
    "th-TH": "ฟุตเวิร์กไป", "vi-VN": "Di chuyển tới",
}
FOOT_NOTE = {
    "en": "The split step goes before the opponent hits, not after. Late split, "
          "late shuttle — no amount of speed afterwards buys that back.",
    "en-GB": "The split step goes before the opponent hits, not after. Late "
             "split, late shuttle — no amount of speed afterwards buys that back.",
    "zh-CN": "分腿垫步要在对手击球之前，不是之后。垫步晚，接球就晚——后面跑得再快也补不回来。",
    "zh-TW": "分腿墊步要在對手擊球之前，不是之後。墊步晚，接球就晚——後面跑得再快也補不回來。",
    "ja-JP": "スプリットステップは相手が打つ前。遅れれば遅れたまま、後からいくら速く走っても取り戻せない。",
    "ko-KR": "스플릿 스텝은 상대가 치기 전에. 늦으면 늦은 채로, 이후 아무리 빨라도 되돌릴 수 없다.",
    "es-ES": "El split step va antes del golpe rival, no después: si llegas "
             "tarde ahí, ninguna velocidad posterior lo recupera.",
    "fr-FR": "Le split step précède la frappe adverse. En retard là, aucune "
             "vitesse ensuite ne rattrape le volant.",
    "id-ID": "Split step sebelum lawan memukul, bukan sesudah.",
    "ms-MY": "Split step sebelum lawan memukul, bukan selepas.",
    "th-TH": "สปลิตสเต็ปต้องมาก่อนคู่แข่งตี ไม่ใช่หลัง ถ้าช้าตรงนี้ วิ่งเร็วแค่ไหนก็ไม่ทัน",
    "vi-VN": "Bước tách phải trước khi đối thủ đánh, không phải sau.",
}


def footwork_family() -> list[Drill]:
    """The four-corner shape, one corner at a time then all four."""
    specs = [("net_forehand", "the forehand net", FR),
             ("net_backhand", "the backhand net", FL),
             ("rear_forehand", "the forehand rear", RR),
             ("rear_backhand", "the backhand rear", RL)]
    out = []
    for key, label, corner in specs:
        out.append(Drill(
            id=f"bd_footwork_{key}", category="warmup", minutes=6, rel=True,
            free=(key == "net_forehand"),
            name=suffixed(FOOT_NAME, label), note=FOOT_NOTE,
            home=[P(*BASE, "1", moves=[corner + (0,), BASE + (1,)])],
            away=[P(*mirror(BASE), "F", moves=[(mirror(corner)[0], 0.40, 0)])],
            markers=[M(*c, "cone", "") for c in (FL, FR, RL, RR)],
            ball=mirror(BASE),          # the feeder has it
        ))
    out.append(Drill(
        id="bd_footwork_four_corner", category="warmup", minutes=8, rel=True,
        free=True,
        name=suffixed(FOOT_NAME, "all four corners"), note=FOOT_NOTE,
        home=[P(*BASE, "1", moves=[FR + (0,), BASE + (1,), RL + (2,), BASE + (3,),
                                   FL + (4,), BASE + (5,), RR + (6,), BASE + (7,)])],
        markers=[M(*c, "cone", "") for c in (FL, FR, RL, RR)],
    ))
    return out


CLEAR_NAME = {
    "en": "Clear", "en-GB": "Clear", "zh-CN": "高远球", "zh-TW": "高遠球",
    "ja-JP": "クリア", "ko-KR": "클리어", "es-ES": "Lob defensivo",
    "fr-FR": "Dégagement", "id-ID": "Lob", "ms-MY": "Lob",
    "th-TH": "ลูกโด่งหลัง (เคลียร์)", "vi-VN": "Cầu cao sâu",
}
CLEAR_NOTE = {
    "en": "A clear buys time only if it lands on the back line. Short of that "
          "it buys the opponent a smash.",
    "en-GB": "A clear buys time only if it lands on the back line. Short of "
             "that it buys the opponent a smash.",
    "zh-CN": "高远球只有到底线才买得到时间。差一点，买到的就是对手一记杀球。",
    "zh-TW": "高遠球只有到底線才買得到時間。差一點，買到的就是對手一記殺球。",
    "ja-JP": "クリアは後ろのラインまで飛んで初めて時間を稼げる。届かなければ相手にスマッシュを差し出すだけ。",
    "ko-KR": "클리어는 엔드라인까지 가야 시간을 번다. 못 가면 상대에게 스매시를 주는 것이다.",
    "es-ES": "Un lob solo da tiempo si cae en el fondo; corto, le regalas un "
             "remate al rival.",
    "fr-FR": "Un dégagement ne fait gagner du temps que s'il tombe sur la "
             "ligne de fond ; plus court, il offre un smash.",
    "id-ID": "Lob hanya membeli waktu jika jatuh di garis belakang.",
    "ms-MY": "Lob hanya membeli masa jika jatuh di garisan belakang.",
    "th-TH": "เคลียร์ซื้อเวลาได้ก็ต่อเมื่อลงเส้นหลัง ถ้าสั้นคือยกสแมชให้คู่แข่ง",
    "vi-VN": "Cầu cao chỉ mua được thời gian nếu rơi vào vạch cuối sân.",
}


def clear_family() -> list[Drill]:
    specs = [("straight", "straight", RR, mirror(RR)),
             ("cross", "cross-court", RR, mirror(RL))]
    out = []
    for key, label, frm, to in specs:
        out.append(Drill(
            id=f"bd_clear_{key}", category="possession", minutes=8, rel=True,
            free=(key == "straight"),
            name=suffixed(CLEAR_NAME, label), note=CLEAR_NOTE,
            home=[P(*BASE, "1", moves=[frm + (0,), BASE + (1,)])],
            away=[P(*mirror(BASE), "2", moves=[to + (1,), mirror(BASE) + (2,)])],
            markers=[M(*to, "zone", "")],
            ball=0,
        ))
    return out


DROP_NAME = {
    "en": "Drop", "en-GB": "Drop", "zh-CN": "吊球", "zh-TW": "吊球",
    "ja-JP": "ドロップ", "ko-KR": "드롭", "es-ES": "Dejada",
    "fr-FR": "Amorti", "id-ID": "Dropshot", "ms-MY": "Dropshot",
    "th-TH": "ลูกหยอด (ดรอป)", "vi-VN": "Bỏ nhỏ",
}
DROP_NOTE = {
    "en": "The swing has to look like the clear you just played. A drop the "
          "opponent reads from your shoulder is a lift back at you.",
    "en-GB": "The swing has to look like the clear you just played. A drop the "
             "opponent reads from your shoulder is a lift back at you.",
    "zh-CN": "挥拍动作要和刚才的高远球一模一样。被对手从你肩膀就看出来的吊球，换回来的是一记挑球。",
    "zh-TW": "揮拍動作要和剛才的高遠球一模一樣。被對手從你肩膀就看出來的吊球，換回來的是一記挑球。",
    "ja-JP": "振りは直前のクリアと同じに見せる。肩で読まれるドロップは、そのままロブで返ってくる。",
    "ko-KR": "스윙은 방금 친 클리어와 똑같아 보여야 한다. 어깨에서 읽히는 드롭은 그대로 리프트로 돌아온다.",
    "es-ES": "El gesto debe parecerse al lob anterior: una dejada que se lee "
             "en tu hombro vuelve como globo.",
    "fr-FR": "Le geste doit ressembler au dégagement précédent : un amorti lu "
             "sur ton épaule revient en lob.",
    "id-ID": "Ayunan harus terlihat seperti lob sebelumnya.",
    "ms-MY": "Hayunan mesti kelihatan seperti lob sebelumnya.",
    "th-TH": "วงสวิงต้องเหมือนเคลียร์ที่เพิ่งตี ถ้าคู่แข่งอ่านออกจากไหล่ ก็จะโดนงัดกลับ",
    "vi-VN": "Động tác vung vợt phải giống hệt quả cầu cao vừa đánh.",
}


def drop_family() -> list[Drill]:
    specs = [("straight", "straight", RR, NET_R), ("cross", "cross-court", RR, NET_L),
             ("slice", "sliced", RL, NET_R)]
    out = []
    for key, label, frm, to in specs:
        out.append(Drill(
            id=f"bd_drop_{key}", category="attacking", minutes=8, rel=True,
            free=(key == "straight"),
            name=suffixed(DROP_NAME, label), note=DROP_NOTE,
            home=[P(*BASE, "1", moves=[frm + (0,), BASE + (1,)])],
            away=[P(*mirror(BASE), "2", moves=[(to[0], 0.44, 1)])],
            markers=[M(to[0], 0.44, "zone", "")],
            ball=0,
        ))
    return out


SMASH_NAME = {
    "en": "Smash", "en-GB": "Smash", "zh-CN": "杀球", "zh-TW": "殺球",
    "ja-JP": "スマッシュ", "ko-KR": "스매시", "es-ES": "Remate",
    "fr-FR": "Smash", "id-ID": "Smes", "ms-MY": "Smesy",
    "th-TH": "สแมช", "vi-VN": "Đập cầu",
}
SMASH_NOTE = {
    "en": "Hit it in front of you, not above you. Behind the body the shuttle "
          "goes flat, and flat is the shot they were waiting for.",
    "en-GB": "Hit it in front of you, not above you. Behind the body the "
             "shuttle goes flat, and flat is the shot they were waiting for.",
    "zh-CN": "在身体前面击球，不是头顶正上方。在身后打，球就变平了，而平球正是对手等的那一拍。",
    "zh-TW": "在身體前面擊球，不是頭頂正上方。在身後打，球就變平了，而平球正是對手等的那一拍。",
    "ja-JP": "体の前で打つ。後ろで打つと球が平らになり、それこそ相手の待ち球だ。",
    "ko-KR": "몸 앞에서 쳐라. 몸 뒤에서 치면 셔틀이 평평해지고, 그게 상대가 기다리던 공이다.",
    "es-ES": "Golpea delante del cuerpo, no encima: por detrás el volante sale "
             "plano, y plano es justo lo que esperaban.",
    "fr-FR": "Frappe devant toi, pas au-dessus : derrière le corps le volant "
             "part à plat, et le plat est le coup qu'ils attendaient.",
    "id-ID": "Pukul di depan badan, bukan di atas kepala.",
    "ms-MY": "Pukul di hadapan badan, bukan di atas kepala.",
    "th-TH": "ตีข้างหน้าตัว ไม่ใช่เหนือหัว ถ้าตีหลังตัวลูกจะแบน และลูกแบนคือสิ่งที่เขารออยู่",
    "vi-VN": "Đánh phía trước người, không phải trên đầu.",
}


def smash_family() -> list[Drill]:
    specs = [("straight", "straight", RR, (0.82, 0.30)),
             ("cross", "cross-court", RR, (0.20, 0.32)),
             ("steep", "steep", (0.50, 0.90), (0.46, 0.40))]
    out = []
    for key, label, frm, land in specs:
        out.append(Drill(
            id=f"bd_smash_{key}", category="finishing", minutes=8, rel=True,
            free=(key == "straight"),
            name=suffixed(SMASH_NAME, label), note=SMASH_NOTE,
            home=[P(*BASE, "1", moves=[frm + (0,), (BASE[0], 0.68, 1)])],
            away=[P(*mirror(BASE), "2", moves=[(land[0], land[1] + 0.04, 1)])],
            markers=[M(*land, "zone", "")],
            ball=0,
        ))
    return out


NETPLAY_NAME = {
    "en": "Net", "en-GB": "Net", "zh-CN": "网前", "zh-TW": "網前",
    "ja-JP": "ネット前", "ko-KR": "네트 앞", "es-ES": "Red",
    "fr-FR": "Filet", "id-ID": "Depan net", "ms-MY": "Depan jaring",
    "th-TH": "หน้าเน็ต", "vi-VN": "Trước lưới",
}
NETPLAY_NOTE = {
    "en": "Take it as high as the tape allows. Every centimetre you let the "
          "shuttle drop hands the point back to the other end.",
    "en-GB": "Take it as high as the tape allows. Every centimetre you let the "
             "shuttle drop hands the point back to the other end.",
    "zh-CN": "尽量在网带高度就接。你让球每往下掉一厘米，就把这一分往回还给对面一点。",
    "zh-TW": "盡量在網帶高度就接。你讓球每往下掉一釐米，就把這一分往回還給對面一點。",
    "ja-JP": "ネットの白帯の高さで触る。落とした分だけ、その1点は相手側に戻っていく。",
    "ko-KR": "네트 흰 테이프 높이에서 잡아라. 셔틀이 떨어지는 만큼 그 점수는 상대에게 돌아간다.",
    "es-ES": "Tómalo tan alto como permita la cinta: cada centímetro que dejas "
             "caer el volante devuelve el punto al otro lado.",
    "fr-FR": "Prends-le aussi haut que la bande le permet : chaque centimètre "
             "perdu rend le point à l'adversaire.",
    "id-ID": "Ambil setinggi mungkin di bibir net.",
    "ms-MY": "Ambil setinggi yang dibenarkan oleh bibir jaring.",
    "th-TH": "รับให้สูงเท่าที่ขอบเน็ตยอมให้ ทุกเซนติเมตรที่ปล่อยให้ลูกตกคือการคืนแต้ม",
    "vi-VN": "Đón cầu cao ngang mép lưới.",
}


def net_family() -> list[Drill]:
    specs = [("kill", "kill", (0.72, 0.30)), ("lift", "lift", (0.80, 0.10)),
             ("spin", "spinning net", (0.26, 0.44))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"bd_net_{key}", category="attacking", minutes=8, rel=True,
            free=(key == "kill"),
            name=suffixed(NETPLAY_NAME, label), note=NETPLAY_NOTE,
            home=[P(*BASE, "1", moves=[NET_R + (0,), (0.60, 0.64, 1)])],
            away=[P(*mirror(BASE), "2", moves=[(land[0], land[1] + 0.05, 1)])],
            markers=[M(*land, "zone", "")],
            ball=0,
        ))
    return out


DEF_NAME = {
    "en": "Defence", "en-GB": "Defence", "zh-CN": "防守", "zh-TW": "防守",
    "ja-JP": "ディフェンス", "ko-KR": "수비", "es-ES": "Defensa",
    "fr-FR": "Défense", "id-ID": "Bertahan", "ms-MY": "Pertahanan",
    "th-TH": "การรับ", "vi-VN": "Phòng thủ",
}
DEF_NOTE = {
    "en": "Racket up and in front before the smash, not after. Defence is a "
          "position you are already standing in, not a reaction.",
    "en-GB": "Racket up and in front before the smash, not after. Defence is a "
             "position you are already standing in, not a reaction.",
    "zh-CN": "杀球之前拍子就要举在身前，不是之后。防守是你已经站好的姿势，不是一个反应。",
    "zh-TW": "殺球之前拍子就要舉在身前，不是之後。防守是你已經站好的姿勢，不是一個反應。",
    "ja-JP": "スマッシュの前にラケットを前で上げておく。ディフェンスは反応ではなく、すでに取っている構えだ。",
    "ko-KR": "스매시 전에 라켓을 앞으로 세워둬라. 수비는 반응이 아니라 이미 서 있는 자세다.",
    "es-ES": "Raqueta arriba y delante antes del remate: la defensa es una "
             "posición en la que ya estás, no una reacción.",
    "fr-FR": "Raquette haute et devant avant le smash : la défense est une "
             "position déjà prise, pas une réaction.",
    "id-ID": "Raket di depan dan terangkat sebelum smes, bukan sesudah.",
    "ms-MY": "Raket di hadapan dan terangkat sebelum smesy.",
    "th-TH": "ยกไม้ไว้ข้างหน้าก่อนโดนสแมช การรับคือท่ายืนที่เตรียมไว้แล้ว ไม่ใช่ปฏิกิริยา",
    "vi-VN": "Giơ vợt phía trước trước khi bị đập, không phải sau.",
}


def defence_family() -> list[Drill]:
    specs = [("block", "block return", (0.72, 0.545)),
             ("drive", "drive return", (0.68, 0.62)),
             ("lift", "lift return", (0.50, 0.30))]
    out = []
    for key, label, to in specs:
        out.append(Drill(
            id=f"bd_defence_{key}", category="defending", minutes=8, rel=True,
            free=(key == "block"),
            name=suffixed(DEF_NAME, label), note=DEF_NOTE,
            home=[P(0.66, 0.76, "1",
                    moves=[(0.70, 0.72, 0), (to[0], min(to[1], 0.76), 1)])],
            away=[P(*mirror(RR), "2", moves=[(0.80, 0.16, 0)])],
            markers=[M(*to, "zone", "")],
            ball=mirror(RR),            # the smasher has it
        ))
    return out


SERVE_NAME = {
    "en": "Serve", "en-GB": "Serve", "zh-CN": "发球", "zh-TW": "發球",
    "ja-JP": "サーブ", "ko-KR": "서브", "es-ES": "Saque", "fr-FR": "Service",
    "id-ID": "Servis", "ms-MY": "Servis", "th-TH": "การเสิร์ฟ", "vi-VN": "Giao cầu",
}
SERVE_NOTE = {
    "en": "The serve is the only shot nobody can rush you on — so it is the "
          "only one with no excuse for being loose.",
    "en-GB": "The serve is the only shot nobody can rush you on — so it is the "
             "only one with no excuse for being loose.",
    "zh-CN": "发球是唯一没人能逼你的一拍——所以也是唯一没有借口打随便的一拍。",
    "zh-TW": "發球是唯一沒人能逼你的一拍——所以也是唯一沒有藉口打隨便的一拍。",
    "ja-JP": "サーブは誰にも急かされない唯一の一打。だから雑に打つ言い訳が一切ない唯一の一打でもある。",
    "ko-KR": "서브는 아무도 몰아붙일 수 없는 유일한 샷이다. 그래서 대충 칠 핑계가 없는 유일한 샷이다.",
    "es-ES": "El saque es el único golpe que nadie puede apurarte: por eso es "
             "el único sin excusa para ser flojo.",
    "fr-FR": "Le service est le seul coup où personne ne peut te presser — "
             "donc le seul sans excuse d'être approximatif.",
    "id-ID": "Servis adalah satu-satunya pukulan yang tak bisa diburu-buru.",
    "ms-MY": "Servis ialah satu-satunya pukulan yang tiada siapa boleh mendesak.",
    "th-TH": "เสิร์ฟคือลูกเดียวที่ไม่มีใครเร่งคุณได้ จึงเป็นลูกเดียวที่ไม่มีข้ออ้างให้หลวม",
    "vi-VN": "Giao cầu là cú duy nhất không ai ép được bạn.",
}


def serve_family() -> list[Drill]:
    specs = [("short", "short", (0.36, 0.42)), ("flick", "flick", (0.34, 0.10)),
             ("high", "high singles", (0.32, 0.06)), ("drive", "drive", (0.66, 0.34))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"bd_serve_{key}", category="setpiece", minutes=6, rel=True,
            free=(key == "short"),
            name=suffixed(SERVE_NAME, label), note=SERVE_NOTE,
            home=[P(0.62, 0.60, "S", moves=[(0.60, 0.64, 1)])],
            away=[P(0.34, 0.36, "R", moves=[(land[0], land[1] + 0.05, 1)])],
            markers=[M(*land, "zone", "")],
            ball=0,
        ))
    return out


DOUBLES_NAME = {
    "en": "Doubles", "en-GB": "Doubles", "zh-CN": "双打", "zh-TW": "雙打",
    "ja-JP": "ダブルス", "ko-KR": "복식", "es-ES": "Dobles",
    "fr-FR": "Double", "id-ID": "Ganda", "ms-MY": "Beregu",
    "th-TH": "ประเภทคู่", "vi-VN": "Đôi",
}
DOUBLES_NOTE = {
    "en": "Front-back when you attack, side-by-side when you defend. The pair "
          "that rotates late is the pair playing four corners with two players.",
    "en-GB": "Front-back when you attack, side-by-side when you defend. The "
             "pair that rotates late is the pair playing four corners with two players.",
    "zh-CN": "进攻前后站，防守左右站。轮转慢的那一对，就是用两个人去防四个角。",
    "zh-TW": "進攻前後站，防守左右站。輪轉慢的那一對，就是用兩個人去防四個角。",
    "ja-JP": "攻めるときはトップアンドバック、守るときはサイドバイサイド。ローテーションが遅いペアは2人で4隅を守るはめになる。",
    "ko-KR": "공격은 앞뒤, 수비는 좌우. 로테이션이 늦은 조는 두 명으로 네 구석을 지키게 된다.",
    "es-ES": "Delante-detrás al atacar, lado a lado al defender: la pareja que "
             "rota tarde acaba cubriendo cuatro esquinas con dos jugadores.",
    "fr-FR": "Avant-arrière en attaque, côte à côte en défense : la paire qui "
             "tourne trop tard couvre quatre coins à deux.",
    "id-ID": "Depan-belakang saat menyerang, sejajar saat bertahan.",
    "ms-MY": "Depan-belakang ketika menyerang, sebelah-menyebelah ketika bertahan.",
    "th-TH": "บุกยืนหน้า-หลัง รับยืนซ้าย-ขวา คู่ที่หมุนช้าคือคู่ที่ใช้สองคนคุมสี่มุม",
    "vi-VN": "Tấn công đứng trước-sau, phòng thủ đứng ngang.",
}


def doubles_family() -> list[Drill]:
    specs = [
        ("attack", "attacking shape", [(0.50, 0.60), (0.50, 0.88)],
         [(0.50, 0.66), (0.50, 0.92)]),
        ("defence", "defending shape", [(0.26, 0.78), (0.74, 0.78)],
         [(0.30, 0.74), (0.70, 0.74)]),
        ("rotation", "rotating on the lift", [(0.34, 0.60), (0.62, 0.86)],
         [(0.66, 0.62), (0.36, 0.88)]),
    ]
    out = []
    for key, label, start, end in specs:
        out.append(Drill(
            id=f"bd_doubles_{key}",
            category="defending" if key == "defence" else "attacking",
            minutes=10, rel=True, free=(key == "attack"),
            name=suffixed(DOUBLES_NAME, label), note=DOUBLES_NOTE,
            home=[P(sx, sy, f"{i + 1}", moves=[end[i] + (0,)])
                  for i, (sx, sy) in enumerate(start)],
            away=[P(0.34, 0.28, "A", moves=[(0.34, 0.22, 0)]), P(0.68, 0.28, "B")],
        ))
    return out


DECEPTION_NAME = {
    "en": "Deception", "en-GB": "Deception", "zh-CN": "假动作", "zh-TW": "假動作",
    "ja-JP": "フェイント", "ko-KR": "페인트", "es-ES": "Engaño",
    "fr-FR": "Feinte", "id-ID": "Tipuan", "ms-MY": "Tipuan",
    "th-TH": "การหลอก", "vi-VN": "Động tác giả",
}
DECEPTION_NOTE = {
    "en": "Deception is a pause, not an extra movement. Hold the shuttle one "
          "beat longer than they expect and the corner opens by itself.",
    "en-GB": "Deception is a pause, not an extra movement. Hold the shuttle "
             "one beat longer than they expect and the corner opens by itself.",
    "zh-CN": "假动作是一个停顿，不是多做一个动作。比对手预期多顶住一拍，角落自己就空出来了。",
    "zh-TW": "假動作是一個停頓，不是多做一個動作。比對手預期多頂住一拍，角落自己就空出來了。",
    "ja-JP": "フェイントは余分な動作ではなく「間」だ。相手の予想より一拍長く持てば、コーナーは勝手に空く。",
    "ko-KR": "페인트는 여분의 동작이 아니라 멈춤이다. 상대 예상보다 한 박자 더 참으면 코너는 저절로 열린다.",
    "es-ES": "El engaño es una pausa, no un gesto de más: retén el volante un "
             "tiempo más y la esquina se abre sola.",
    "fr-FR": "La feinte est une pause, pas un geste en plus : retiens le "
             "volant un temps de plus et le coin s'ouvre tout seul.",
    "id-ID": "Tipuan adalah jeda, bukan gerakan tambahan.",
    "ms-MY": "Tipuan ialah jeda, bukan pergerakan tambahan.",
    "th-TH": "การหลอกคือการหยุด ไม่ใช่การเพิ่มท่าทาง ถือลูกช้ากว่าที่เขาคาดหนึ่งจังหวะ มุมจะเปิดเอง",
    "vi-VN": "Động tác giả là một khoảng dừng, không phải thêm động tác.",
}


def deception_family() -> list[Drill]:
    specs = [("hold_flick", "hold and flick", NET_R, (0.20, 0.08)),
             ("double_motion", "double motion", NET_L, (0.76, 0.44))]
    out = []
    for key, label, frm, land in specs:
        out.append(Drill(
            id=f"bd_deception_{key}", category="attacking", minutes=8, rel=True,
            name=suffixed(DECEPTION_NAME, label), note=DECEPTION_NOTE,
            home=[P(*BASE, "1", moves=[frm + (0,), (frm[0], 0.60, 2)])],
            away=[P(*mirror(BASE), "2",
                    moves=[(frm[0], 0.42, 1), (land[0], land[1] + 0.05, 2)])],
            markers=[M(*land, "zone", "")],
            ball=0,
        ))
    return out


DRIVE_NAME = {
    "en": "Drive rally", "en-GB": "Drive rally", "zh-CN": "平抽挡",
    "zh-TW": "平抽擋", "ja-JP": "ドライブの打ち合い", "ko-KR": "드라이브 랠리",
    "es-ES": "Peloteo de drives", "fr-FR": "Échange en drive",
    "id-ID": "Reli drive", "ms-MY": "Rali drive",
    "th-TH": "โต้ลูกดาด", "vi-VN": "Đôi công ngang",
}
DRIVE_NOTE = {
    "en": "Short grip, short swing, hit flat and slightly rising. Whoever "
          "swings big first is the one who loses the exchange.",
    "en-GB": "Short grip, short swing, hit flat and slightly rising. Whoever "
             "swings big first is the one who loses the exchange.",
    "zh-CN": "握短、挥短，打平且略微上扬。谁先抡大拍，谁就输掉这一轮对抽。",
    "zh-TW": "握短、揮短，打平且略微上揚。誰先掄大拍，誰就輸掉這一輪對抽。",
    "ja-JP": "グリップ短く、スイング小さく、フラットにわずかに上向きへ。先に大振りした方が競り負ける。",
    "ko-KR": "짧게 잡고 짧게 휘두르며 평평하게 살짝 올려 쳐라. 먼저 크게 휘두르는 쪽이 진다.",
    "es-ES": "Empuñadura corta, gesto corto, plano y algo ascendente: el "
             "primero que arma grande pierde el intercambio.",
    "fr-FR": "Prise courte, geste court, à plat et légèrement montant : le "
             "premier qui arme grand perd l'échange.",
    "id-ID": "Pegangan pendek, ayunan pendek, datar dan sedikit naik.",
    "ms-MY": "Pegangan pendek, hayunan pendek, rata dan sedikit menaik.",
    "th-TH": "จับสั้น สวิงสั้น ตีแบนและเชิดขึ้นนิด ใครเหวี่ยงใหญ่ก่อนคนนั้นแพ้",
    "vi-VN": "Cầm ngắn, vung ngắn, đánh phẳng và hơi lên.",
}


def drive_family() -> list[Drill]:
    specs = [("flat", "flat exchange", 0.66), ("crosscourt", "cross-court", 0.34)]
    out = []
    for key, label, x in specs:
        ax = 1 - x if key == "crosscourt" else x
        out.append(Drill(
            id=f"bd_drive_{key}", category="possession", minutes=8, rel=True,
            free=(key == "flat"),
            name=suffixed(DRIVE_NAME, label), note=DRIVE_NOTE,
            home=[P(x, 0.68, "1", moves=[(x, 0.62, 0), (x, 0.68, 1)])],
            away=[P(ax, 0.32, "2", moves=[(ax, 0.38, 0)])],
            ball=0,
        ))
    return out


GAME_NAME = {
    "en": "Conditioned game", "en-GB": "Conditioned game", "zh-CN": "限制性对抗",
    "zh-TW": "限制性對抗", "ja-JP": "条件付きゲーム", "ko-KR": "조건 게임",
    "es-ES": "Juego condicionado", "fr-FR": "Jeu à thème",
    "id-ID": "Permainan bersyarat", "ms-MY": "Permainan bersyarat",
    "th-TH": "เกมมีเงื่อนไข", "vi-VN": "Trận đấu có điều kiện",
}
GAME_NOTE = {
    "en": "Shrink the court and the tactic appears on its own — players stop "
          "hitting harder and start hitting somewhere.",
    "en-GB": "Shrink the court and the tactic appears on its own — players "
             "stop hitting harder and start hitting somewhere.",
    "zh-CN": "把场地缩小，战术自己就出来了——球员不再一味打得更重，而是开始打到某个位置。",
    "zh-TW": "把場地縮小，戰術自己就出來了——球員不再一味打得更重，而是開始打到某個位置。",
    "ja-JP": "コートを狭めれば戦術は自然に現れる。強く打つのをやめ、どこかへ打ち始める。",
    "ko-KR": "코트를 좁히면 전술은 저절로 나온다. 더 세게가 아니라 어딘가로 치기 시작한다.",
    "es-ES": "Reduce la pista y la táctica aparece sola: dejan de pegar más "
             "fuerte y empiezan a pegar a algún sitio.",
    "fr-FR": "Réduis le terrain et la tactique apparaît d'elle-même : on cesse "
             "de frapper plus fort pour frapper quelque part.",
    "id-ID": "Perkecil lapangan dan taktik muncul dengan sendirinya.",
    "ms-MY": "Kecilkan gelanggang dan taktik akan muncul dengan sendirinya.",
    "th-TH": "ย่อคอร์ทลง แล้วแท็กติกจะโผล่มาเอง",
    "vi-VN": "Thu nhỏ sân, chiến thuật sẽ tự xuất hiện.",
}


def game_family() -> list[Drill]:
    specs = [
        ("half_court", "half-court singles", [(0.30, 0.72)], [(0.30, 0.28)]),
        ("front_court", "front-court only", [(0.50, 0.60)], [(0.50, 0.40)]),
        ("two_v_one", "2v1", [(0.34, 0.74), (0.66, 0.74)], [(0.50, 0.30)]),
        ("full_doubles", "full doubles", [(0.50, 0.62), (0.50, 0.90)],
         [(0.30, 0.28), (0.70, 0.28)]),
    ]
    out = []
    for key, label, home, away in specs:
        out.append(Drill(
            id=f"bd_game_{key}", category="ssg", minutes=15, rel=True,
            free=(key in ("half_court", "full_doubles")),
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=[P(x, y, f"{i + 1}", moves=[(x, y - 0.05, 0)])
                  for i, (x, y) in enumerate(home)],
            away=[P(x, y, chr(65 + i), moves=[(x, y + 0.05, 0)])
                  for i, (x, y) in enumerate(away)],
            markers=([M(0.50, 0.30, "cone", ""), M(0.50, 0.70, "cone", "")]
                     if key == "half_court" else []),
            ball=0,
        ))
    return out


def badminton_library() -> list[Drill]:
    return (footwork_family() + clear_family() + drive_family()
            + drop_family() + net_family() + deception_family()
            + doubles_family() + smash_family() + defence_family()
            + serve_family() + game_family())
