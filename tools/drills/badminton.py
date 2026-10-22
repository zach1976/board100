"""The badminton library.

Badminton is played from a base and back to it: almost every drill here is a
shape describing where the player is pulled and how they recover. The court is
portrait with the net at y=0.5 and home at the bottom; doubles adds a partner
whose position is the other half of the answer.
"""
from .engine import Drill, M, P, figure_clear, suffixed

# The base is the middle of the half court. A figure is drawn centred on its
# point with its feet half a figure below it, so 0.72 LOOKED a metre too
# close to the net (2026-10-22); 0.76 reads as centre.
BASE = (0.50, 0.76)
# The four corners a singles player is worked between, plus the net tape.
# The rear corners are at the baseline — a clear is hit from it, not from
# a metre inside it.
FL, FR = (0.18, 0.58), (0.82, 0.58)
RL, RR = (0.14, 0.96), (0.86, 0.96)
NET_L, NET_R = (0.22, 0.545), (0.78, 0.545)
# A far-side server stands in his service court with his FEET behind his
# short service line (0.352): the figure hangs half its height below its
# point, toward the net, so at 0.315 his feet were over the line, in the
# front court (tools/check_baselines.py).
SRV_FAR_Y = 0.5 - 1.98 / 13.4 - figure_clear("badminton")
# Where a feeder stands: behind his short service line, feeding from
# mid-court the way a coach with a box of shuttles does. At 0.44 the
# figure hung half its height toward the net and his feet were on the tape.
FEED = (0.50, SRV_FAR_Y)


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
    """The four-corner shape, one corner at a time then all four.

    Shadow footwork, so no shuttle. These drills' own flow text says the
    player "plays the shadow stroke there and gets back to base", and the
    board used to contradict it: a shuttle really was played, 765 board
    points of it, and the feeder ran 280 to hit it. What is being trained
    is the journey to the corner and the recovery, which is why the fifth
    drill of the family — all four corners — has always been one player
    and nothing else.

    The feeder stays where he is for the same reason. He is the coach's
    arm: he points, the player goes. A feeder who crosses his own court
    every repetition reads as a rally.

    One cone, not four. Four is how a court is set up for a session and is
    right for the drill that works all of them; on a board that trains one
    corner the other three are furniture, and the note then has to explain
    three things nobody does.
    """
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
            away=[P(*mirror(BASE), "C", coach=True)],
            markers=[M(*corner, "cone", "")],
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


def recover(frm, home=True):
    """A stride out of a corner and no more.

    Between two clears you come off the corner towards the middle and go
    straight back to it; you do not return to base and set off again. A
    quarter of the way is a step, which is what these boards want to show.
    """
    mid = BASE if home else mirror(BASE)
    return (frm[0] + (mid[0] - frm[0]) * 0.25,
            frm[1] + (mid[1] - frm[1]) * 0.25)


def clear_family() -> list[Drill]:
    """Clear to clear, down one side of the court.

    A clear rally lives in two corners: both players stand in the one the
    shuttle keeps coming back to, and what travels is the shuttle. The
    straight version runs up and down a single tramline; the cross-court
    one runs along a single diagonal, because a cross answered with a
    cross comes back where it started.

    These boards used to put the player at base and send him out to the
    corner and home again on every rally — a tour of the court for a drill
    whose whole point is the shot. That is the footwork family, two doors
    down.
    """
    specs = [("straight", "straight", RR, mirror(RR)),
             ("cross", "cross-court", RR, mirror(RL))]
    out = []
    for key, label, frm, to in specs:
        out.append(Drill(
            id=f"bd_clear_{key}", category="possession", minutes=8, rel=True,
            free=(key == "straight"),
            name=suffixed(CLEAR_NAME, label), note=CLEAR_NOTE,
            home=[P(*frm, "1",
                    moves=[recover(frm) + (0,), frm + (1,)])],
            away=[P(*to, "2",
                    moves=[recover(to, home=False) + (1,), to + (2,)])],
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
    """A drop goes to the net. That is what makes it a drop.

    The shuttle used to be left to the generator, which sends it to the
    other player — and the other player stands at his base in the middle
    of his court, so the board drew a shot dying half way down the far
    side. It lands just over the tape now, in the zone, and the man over
    there comes forward to take it and lifts it back deep.

    The hitter stands in the corner he hits from, as in the clear family:
    an overhead drop is played from the back, not run to from base.
    """
    specs = [("straight", "straight", RR, NET_R), ("cross", "cross-court", RR, NET_L),
             ("slice", "sliced", RL, NET_R)]
    out = []
    for key, label, frm, to in specs:
        land = (to[0], 0.44)        # just over the tape, the far side of it
        out.append(Drill(
            id=f"bd_drop_{key}", category="attacking", minutes=8, rel=True,
            free=(key == "straight"),
            name=suffixed(suffixed(DROP_NAME, label), "multi-shuttle"), note=DROP_NOTE,
            home=[P(*frm, "1", moves=[recover(frm) + (0,), frm + (1,)])],
            # The feeder stands where the drop is going and stays there.
            # One side is training here, the other is giving him the
            # shuttle back, and a feeder does not run the drill — he was
            # starting at his base and crossing half his court to every
            # drop, which reads as a rally between equals. Both sides move
            # in the clear family, because there both sides are working.
            away=[P(land[0], 0.36, "C", coach=True)],
            markers=[M(*land, "zone", "")],
            ball=0,
            ball_moves=[land + (0,), (frm[0], 0.88, 1)],
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
        # A smash answers a lift: 2 lifts to the corner, 1 gets back under
        # it, smashes into the zone, recovers; 2 defends where it lands.
        # The old board had 1 strike from base on the first beat — before
        # he had moved — and sent the shuttle to 2, so the zone it was
        # supposed to hit was decoration.
        start2 = mirror(BASE)
        cover = (land[0] + (start2[0] - land[0]) * 0.3,
                 land[1] + (start2[1] - land[1]) * 0.3)
        out.append(Drill(
            id=f"bd_smash_{key}", category="finishing", minutes=8, rel=True,
            free=(key == "straight"),
            name=suffixed(suffixed(SMASH_NAME, label), "multi-shuttle"), note=SMASH_NOTE,
            home=[P(*BASE, "1", moves=[frm + (0,), BASE + (2,)])],
            away=[P(*start2, "C", coach=True, moves=[cover + (1,)])],
            markers=[M(*land, "zone", "")],
            ball=start2,
            ball_moves=[frm + (0,), land + (1,)],
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
    """In to the tape, play the shot there, out again.

    Three beats, in that order: step up to the net, play it from the net,
    recover to base. The board used to open with the home player striking
    from his own base and only then walking forward, which is the rally
    the drill sits inside rather than the drill — and it left him parked
    short of base at the end, so the next repetition had nowhere to start.

    The man on the other side covers where the shot is going, but from
    his own side of it: a third of the way back towards his base. He was
    being sent to within a stride of the tape, and a figure is 52 points
    tall — on the spinning-net board that drew him standing across the net.
    """
    # All three are played from the forehand net corner, NET_R at x=0.78,
    # and where the shuttle goes is what tells them apart. The spinning net
    # shot is a TIGHT one, back down the same tramline, tumbling over the
    # tape — it was landing at x=0.26, the other side of the court, which
    # is a cross-court net shot and has a different name in every language
    # this library ships.
    specs = [("kill", "kill", (0.72, 0.30)), ("lift", "lift", (0.80, 0.10)),
             ("spin", "spinning net", (0.74, 0.44))]
    out = []
    for key, label, land in specs:
        start2 = mirror(BASE)
        cover = (land[0] + (start2[0] - land[0]) * 0.3,
                 land[1] + (start2[1] - land[1]) * 0.3)
        out.append(Drill(
            id=f"bd_net_{key}", category="attacking", minutes=8, rel=True,
            free=(key == "kill"),
            name=suffixed(suffixed(NETPLAY_NAME, label), "multi-shuttle"), note=NETPLAY_NOTE,
            home=[P(*BASE, "1", moves=[NET_R + (0,), BASE + (2,)])],
            away=[P(*start2, "C", coach=True, moves=[cover + (1,)])],
            markers=[M(*land, "zone", "")],
            # The feed comes from the other side; the shuttle is never
            # lying about. Parking it at the tape for the home player to
            # walk up to drew beat zero as a shuttle on the floor with
            # nobody near it, which is not a thing a court ever shows.
            ball=start2,
            ball_moves=[NET_R + (0,), land + (1,)],
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
    # Where the *shuttle* goes, and it has to cross the net: a block and a
    # drive used to be drawn landing on the defender's own side, and the
    # lift was encoded as the defender's own run, so his arrow crossed the
    # net and finished in the opponent's midcourt — the short lift this
    # drill's mistake text warns about.
    specs = [("block", "block return", (0.30, 0.44)),
             ("drive", "drive return", (0.30, 0.375)),
             ("lift", "lift return", (0.50, 0.075))]
    out = []
    for key, label, to in specs:
        out.append(Drill(
            id=f"bd_defence_{key}", category="defending", minutes=8, rel=True,
            free=(key == "block"),
            name=suffixed(suffixed(DEF_NAME, label), "multi-shuttle"), note=DEF_NOTE,
            home=[P(0.66, 0.76, "1", moves=[(0.70, 0.70, 0), (0.62, 0.74, 1)])],
            away=[P(*mirror(RR), "C", coach=True, moves=[(0.80, 0.16, 0)])],
            markers=[M(*to, "zone", "")],
            ball=mirror(RR),            # the smasher has it
            # The reply itself, over the net into the target.
            ball_moves=[(0.70, 0.70, 0), to + (1,)],
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
    # The short service line is 1.98 m either side of the net, at y 0.648
    # and 0.352 on this board. The server used to stand at 0.60 — in front
    # of his own line — and the short serve landed at 0.42, inside the
    # receiver's non-valid area. Both are faults, on the four boards whose
    # whole subject is the serve.
    SHORT_LINE_NEAR, SHORT_LINE_FAR = 0.648, 0.352
    # S serves from the right-hand court, so every serve has to land in
    # the box DIAGONALLY opposite — the receiver's court on x < 0.5. The
    # drive serve was aimed at x=0.66, the straight box: a fault, on the
    # one board whose subject is the serve.
    specs = [("short", "short", (0.36, 0.325), 0.685),
             ("flick", "flick", (0.34, 0.085), 0.685),
             ("high", "high singles", (0.32, 0.025), 0.80),
             ("drive", "drive", (0.34, 0.295), 0.685)]
    out = []
    for key, label, land, from_y in specs:
        # The serve lands in the zone — that is the whole drill — and R
        # moves to meet it there. Left to the generator it was sent to R
        # where he stood, so only the short serve, whose zone happens to
        # be at his feet, ever reached its target; the flick, the high
        # and the drive all landed on a man standing by the short line.
        ready = (0.36, SHORT_LINE_FAR - 0.06)
        meet = (land[0] + (ready[0] - land[0]) * 0.3,
                land[1] + (ready[1] - land[1]) * 0.3)
        # The return is a shot, so it goes to a space, not to the server:
        # a short serve is pushed deep past him, a flick or a high serve
        # is hit down into the mid-court, a drive serve is blocked to the
        # net. "R plays it to S" is what a feed looks like, not a reply.
        reply = {"short": (0.50, 0.84), "flick": (0.36, 0.76),
                 "high": (0.36, 0.76), "drive": (0.44, 0.60)}[key]
        out.append(Drill(
            id=f"bd_serve_{key}", category="setpiece", minutes=6, rel=True,
            free=(key == "short"),
            name=suffixed(SERVE_NAME, label), note=SERVE_NOTE,
            home=[P(0.62, from_y, "S",
                    moves=[(0.60, min(from_y + 0.04, 0.94), 1)])],
            # Behind his own short service line, which is where a receiver
            # must stand.
            away=[P(*ready, "R", moves=[meet + (0,)])],
            markers=[M(*land, "zone", ""),
                     M(0.50, SHORT_LINE_NEAR, "cone", ""),
                     M(0.50, SHORT_LINE_FAR, "cone", "")],
            ball=0,
            ball_moves=[land + (0,), reply + (1,)],
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
        # Defending shape only exists against an attacking pair: the
        # opponents were drawn side-by-side too, so there was nothing to
        # defend. And "rotating on the lift" started front-back and slid
        # sideways — the rotation is side-by-side turning INTO front-back.
        ("defence", "defending shape", [(0.26, 0.78), (0.74, 0.78)],
         [(0.30, 0.74), (0.70, 0.74)]),
        ("rotation", "rotating on the lift", [(0.28, 0.78), (0.72, 0.78)],
         [(0.50, 0.60), (0.50, 0.90)]),
    ]
    out = []
    REPLY = {"attack": (0.50, 0.42),      # the kill, short of a side-by-side pair
             "defence": (0.22, 0.08),     # the lift, to the open rear corner
             "rotation": (0.78, 0.30)}    # the smash, down the open side
    for key, label, start, end in specs:
        reply = REPLY[key]
        # Front-back when they are attacking, which is the only shape a
        # defending pair has anything to defend against.
        away = ([P(0.50, 0.40, "A", moves=[(0.46, 0.36, 0)]),
                 P(0.50, 0.14, "B")] if key in ("defence", "rotation")
                else [P(0.34, 0.28, "A", moves=[(0.34, 0.22, 0)]),
                      P(0.68, 0.28, "B")])
        out.append(Drill(
            id=f"bd_doubles_{key}",
            category="defending" if key == "defence" else "attacking",
            minutes=10, rel=True, free=(key == "attack"),
            name=suffixed(DOUBLES_NAME, label), note=DOUBLES_NOTE,
            # The shuttle that makes the shape mean something: theirs comes
            # over, the pair answers it. It starts IN A'S HAND, wherever he
            # is standing — a fixed point in their half happened to be on
            # him in two of these three, and in the third it was a shuttle
            # hanging in mid-court belonging to nobody.
            ball=(away[0].x, away[0].y),
            # On the rotation board the ball that comes over IS the lift:
            # it goes deep, to the man who drops back to take it — player 2,
            # who ends at the rear — while 1 goes forward to the net. It
            # used to go to 1, who had just moved UP, so the shuttle landed
            # at the net and nothing on the board was a lift.
            #
            # The reply is a shot and goes into the gap the opponents'
            # shape leaves open, which is the zone: between a side-by-side
            # pair, into the open rear corner behind a front-back pair, down
            # the open side when they are both in the middle. It used to go
            # back to A, which is what a feed does.
            ball_moves=[end[1 if key == "rotation" else 0] + (0,),
                        reply + (1,)],
            markers=[M(*reply, "zone", "")],
            home=[P(sx, sy, f"{i + 1}", moves=[end[i] + (0,)])
                  for i, (sx, sy) in enumerate(start)],
            away=away,
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
    """The hold happens at the tape, and somebody has to be fooled by it.

    Three beats. The feed comes to the net and 1 steps up to it; 2 commits
    — a stride towards the net, on 1's column, reading a net reply — and in
    the same beat 1 plays the other shot, over him to the rear (the flick)
    or across him to the far net (the double motion); 1 recovers, 2
    scrambles towards where it went.

    What this replaces struck from base before 1 had reached the net,
    sent the shuttle to 2 rather than into the zone, and walked 2 up to
    within a stride of the tape — on the double-motion board he stood
    across the net. Nothing on it was a deception: nobody held anything
    and nobody was sent the wrong way.
    """
    specs = [("hold_flick", "hold and flick", NET_R, (0.20, 0.08)),
             ("double_motion", "double motion", NET_L, (0.76, 0.44))]
    out = []
    for key, label, frm, land in specs:
        start2 = mirror(BASE)
        commit = (frm[0], 0.40)          # his side of the tape, on 1's column
        chase = (land[0] + (start2[0] - land[0]) * 0.3,
                 land[1] + (start2[1] - land[1]) * 0.3)
        out.append(Drill(
            id=f"bd_deception_{key}", category="attacking", minutes=8, rel=True,
            name=suffixed(suffixed(DECEPTION_NAME, label), "multi-shuttle"), note=DECEPTION_NOTE,
            home=[P(*BASE, "1", moves=[frm + (0,), BASE + (2,)])],
            away=[P(*start2, "C", coach=True, moves=[commit + (1,), chase + (2,)])],
            markers=[M(*land, "zone", "")],
            ball=start2,
            ball_moves=[frm + (0,), land + (1,)],
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


# The short service lines, in these court fractions: 0.647 on the home
# side and 0.352 on the far one. A flat exchange is played from BEHIND
# them, and the first beat of this family used to walk both players
# straight across.
SHORT_SERVICE_H, SHORT_SERVICE_A = 0.647, 0.352


def drive_family() -> list[Drill]:
    """A drive exchange is hands and racket, not feet.

    Both players stand a stride behind their own short service line and
    stay there. What used to happen was a stride forward on the first
    beat, which put both of them in front of the line — the one place a
    flat drive is not played from — and made a rally of two standing
    players look like an advance.
    """
    specs = [("flat", "flat exchange", 0.66), ("crosscourt", "cross-court", 0.34)]
    out = []
    for key, label, x in specs:
        ax = 1 - x if key == "crosscourt" else x
        out.append(Drill(
            id=f"bd_drive_{key}", category="possession", minutes=8, rel=True,
            free=(key == "flat"),
            name=suffixed(DRIVE_NAME, label), note=DRIVE_NOTE,
            home=[P(x, 0.72, "1", moves=[(x, 0.69, 0), (x, 0.72, 1)])],
            away=[P(ax, 0.28, "2", moves=[(ax, 0.31, 0)])],
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
    # Where each side's shot lands: a space, not the other player. A game
    # is the one place nobody hits to anybody — half-court goes to the
    # open corner of the half, front-court to the side of the tape, 2v1
    # into the gap between the two and the single player's open corner,
    # doubles between a side-by-side pair and down the side of a front-back
    # one. The rally used to be "1 plays it to A, A plays it to 1".
    SHOTS = {"half_court": ((0.22, 0.10), (0.22, 0.90)),
             "front_court": ((0.22, 0.44), (0.78, 0.56)),
             "two_v_one": ((0.22, 0.10), (0.50, 0.90)),
             "full_doubles": ((0.50, 0.12), (0.22, 0.78))}

    def toward(frm, to):
        # A shot into a space is only a rally if somebody goes and gets
        # it: the first player on each side runs to the spot the other
        # side hit to, and plays the next shot from there.
        return (to[0] + (frm[0] - to[0]) * 0.3, to[1] + (frm[1] - to[1]) * 0.3)

    for key, label, home, away in specs:
        ours, theirs = SHOTS[key]
        out.append(Drill(
            id=f"bd_game_{key}", category="ssg", minutes=15, rel=True,
            free=(key in ("half_court", "full_doubles")),
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=[P(x, y, f"{i + 1}",
                    moves=([toward((x, y), theirs) + (1,)] if i == 0
                           else [(x, y - 0.05, 0)]))
                  for i, (x, y) in enumerate(home)],
            away=[P(x, y, chr(65 + i),
                    moves=([toward((x, y), ours) + (0,)] if i == 0
                           else [(x, y + 0.05, 0)]))
                  for i, (x, y) in enumerate(away)],
            markers=([M(0.50, 0.30, "cone", ""), M(0.50, 0.70, "cone", "")]
                     if key == "half_court" else []),
            ball=0,
            ball_moves=[ours + (0,), theirs + (1,)],
        ))
    return out


RETURN_NAME = {"en": "Return of serve", "en-GB": "Return of serve",
               "zh-CN": "接发球", "zh-TW": "接發球", "ja-JP": "レシーブ",
               "ko-KR": "서브 리턴", "es-ES": "Resto del saque",
               "fr-FR": "Retour de service", "id-ID": "Pengembalian servis",
               "ms-MY": "Kembalian servis", "th-TH": "การรับเสิร์ฟ",
               "vi-VN": "Đỡ giao cầu"}
RETURN_NOTE = {
    "en": "Racket up at tape height before the serve is struck, weight forward, and take it early enough that the reply goes downward. A shuttle met below the tape has already lost you the rally.",
    "en-GB": "Racket up at tape height before the serve is struck, weight forward, and take it early enough that the reply goes downward. A shuttle met below the tape has already lost you the rally.",
    "zh-CN": "发球出手前拍头就举到网带高度，重心前压，早点碰到球，让回球往下走。在网带以下才碰到的球，这一分已经输了一半。",
    "zh-TW": "發球出手前拍頭就舉到網帶高度，重心前壓，早點碰到球，讓回球往下走。在網帶以下才碰到的球，這一分已經輸了一半。",
    "ja-JP": "サーブが打たれる前にラケットをネット高に上げ、重心を前に、早い打点で返して下向きにする。ネットより下で触った時点でラリーは負けている。",
    "ko-KR": "서브가 맞기 전에 라켓을 네트 높이로 들고 체중은 앞으로, 리턴이 아래로 향할 만큼 빠르게 잡아라.",
    "es-ES": "Raqueta arriba a la altura de la cinta antes del saque, peso adelante, y tómalo pronto para que la respuesta baje.",
    "fr-FR": "Raquette haute au niveau de la bande avant la frappe, appui avant, et prends-le assez tôt pour que la réponse descende.",
    "id-ID": "Raket diangkat setinggi net sebelum servis dipukul, berat badan ke depan, dan ambil cukup awal agar pengembalian menukik.",
    "ms-MY": "Raket diangkat setinggi jaring sebelum servis dipukul, berat badan ke hadapan.",
    "th-TH": "ยกไม้ให้สูงระดับขอบตาข่ายก่อนลูกเสิร์ฟถูกตี ถ่ายน้ำหนักไปข้างหน้า และรับให้เร็วพอที่จะตีลง",
    "vi-VN": "Nâng vợt ngang mép lưới trước khi quả giao được đánh, trọng tâm dồn trước, và đón sớm để trả cầu đi xuống.",
}
OVERHEAD_NOTE = {
    "en": "Take it round the head rather than turning your back: the moment you turn, the straight reply is gone and the opponent only has to cover one side.",
    "en-GB": "Take it round the head rather than turning your back: the moment you turn, the straight reply is gone and the opponent only has to cover one side.",
    "zh-CN": "用头顶球处理，不要转身背对：一转身，直线回球就没有了，对手只需要守一边。",
    "zh-TW": "用頭頂球處理，不要轉身背對：一轉身，直線回球就沒有了，對手只需要守一邊。",
    "ja-JP": "背中を向けずラウンド・ザ・ヘッドで処理する。背を向けた瞬間にストレートは消え、相手は片側だけ守ればよくなる。",
    "ko-KR": "등을 돌리지 말고 라운드 더 헤드로 처리하라. 돌아서는 순간 스트레이트가 사라지고 상대는 한쪽만 지키면 된다.",
    "es-ES": "Juégalo por encima de la cabeza en vez de girar la espalda: al girar pierdes la paralela y el rival solo cubre un lado.",
    "fr-FR": "Joue-le au-dessus de la tête plutôt que de tourner le dos : dès que tu tournes, la parallèle disparaît et l'adversaire ne couvre qu'un côté.",
    "id-ID": "Ambil dengan round-the-head, jangan memutar punggung: begitu berbalik, pengembalian lurus hilang.",
    "ms-MY": "Ambil secara round-the-head, jangan pusingkan belakang.",
    "th-TH": "ตีแบบรอบศีรษะแทนการหันหลัง พอหันหลังลูกตรงก็หายไป",
    "vi-VN": "Đánh vòng qua đầu thay vì xoay lưng: vừa xoay là mất đường cầu thẳng.",
}
NETBATTLE_NOTE = {
    "en": "Whoever gets the racket above the tape first wins it. Two players fighting at the net is one decision — go up, or lift — and hesitating makes it for you.",
    "en-GB": "Whoever gets the racket above the tape first wins it. Two players fighting at the net is one decision — go up, or lift — and hesitating makes it for you.",
    "zh-CN": "谁先把拍子举到网带以上，谁就赢这一分。网前搏杀只有一个决定：上手，还是挑起来——犹豫本身就替你做了决定。",
    "zh-TW": "誰先把拍子舉到網帶以上，誰就贏這一分。網前搏殺只有一個決定：上手，還是挑起來——猶豫本身就替你做了決定。",
    "ja-JP": "先にラケットをネットの上に出した方が勝つ。前での競り合いは「上から入るか、上げるか」の一択で、迷いはその選択を勝手に決めてしまう。",
    "ko-KR": "라켓을 네트 위로 먼저 올린 쪽이 이긴다. 네트 앞 싸움은 위로 갈지 띄울지 하나의 선택이고, 망설임이 대신 결정해 버린다.",
    "es-ES": "Gana quien sube antes la raqueta por encima de la cinta. En la red solo hay una decisión: entrar arriba o levantar; dudar la toma por ti.",
    "fr-FR": "Celui qui monte la raquette au-dessus de la bande en premier gagne. Au filet il n'y a qu'une décision : monter ou lever ; hésiter la prend pour toi.",
    "id-ID": "Siapa yang lebih dulu mengangkat raket di atas net, dia yang menang.",
    "ms-MY": "Siapa lebih dahulu mengangkat raket di atas jaring, dia menang.",
    "th-TH": "ใครยกไม้ขึ้นเหนือขอบตาข่ายก่อน คนนั้นชนะ",
    "vi-VN": "Ai đưa vợt lên trên mép lưới trước thì người đó thắng.",
}


def gaps_family() -> list[Drill]:
    """The return of serve, the round-the-head and the net battle.

    Thirty-five drills and no return of serve anywhere — in doubles the
    most decisive shot in the game. No round-the-head either, and no
    front-court battle between two players. All verified absent.
    """
    return [
        # Home is the bottom half on every board in this library, and the
        # two returns were written with R at the top: everything that
        # keys on which half is yours — which way a figure faces, which
        # corner is his backhand — came out backwards, and R stood with
        # his back to the net on both. Same drill, turned round.
        Drill(
            id="bd_return_short_serve", category="setpiece", minutes=8, rel=True,
            level="foundation", free=True,
            name=suffixed(RETURN_NAME, "against the short serve"),
            note=RETURN_NOTE,
            home=[P(0.36, 0.71, "R", moves=[(0.40, 0.625, 0), (0.38, 0.68, 1)])],
            away=[P(0.62, SRV_FAR_Y, "S", moves=[(0.60, SRV_FAR_Y - 0.035, 1)])],
            markers=[M(0.66, 0.40, "zone", ""), M(0.50, 0.352, "cone", ""),
                     M(0.50, 0.648, "cone", "")],
            ball=(0.615, SRV_FAR_Y + 0.02),
            ball_moves=[(0.40, 0.625, 0), (0.66, 0.40, 1)],
        ),
        Drill(
            id="bd_return_flick_serve", category="setpiece", minutes=8, rel=True,
            name=suffixed(RETURN_NAME, "against the flick"), note=RETURN_NOTE,
            home=[P(0.36, 0.71, "R", moves=[(0.34, 0.84, 0), (0.40, 0.70, 2)])],
            away=[P(0.62, SRV_FAR_Y, "S", moves=[(0.58, SRV_FAR_Y - 0.055, 1)])],
            markers=[M(0.70, 0.24, "zone", ""), M(0.50, 0.352, "cone", ""),
                     M(0.50, 0.648, "cone", "")],
            ball=(0.615, SRV_FAR_Y + 0.02),
            ball_moves=[(0.34, 0.86, 0), (0.70, 0.24, 1)],
        ),
        Drill(
            id="bd_clear_round_the_head", category="possession", minutes=8, rel=True,
            name=suffixed(suffixed(CLEAR_NAME, "round the head"), "multi-shuttle"), note=OVERHEAD_NOTE,
            # Feed and move, clear and cover, recover — the clear used to
            # wait a beat after 1 had arrived, with nothing happening on
            # the board but the feeder shuffling sideways.
            home=[P(*BASE, "1", moves=[(0.30, 0.84, 0), BASE + (2,)])],
            away=[P(*mirror(BASE), "C", coach=True, moves=[(0.34, 0.30, 1)])],
            # The cone is the centre he recovers to — the note says so — not
            # the corner he hits from: there it sat on the baseline (2026-10-22).
            markers=[M(*BASE, "cone", ""), M(0.72, 0.14, "zone", "")],
            ball=mirror(BASE),
            ball_moves=[(0.30, 0.84, 0), (0.72, 0.14, 1)],
        ),
        Drill(
            id="bd_net_battle", category="attacking", minutes=8, rel=True,
            level="advanced",
            name=suffixed(NETPLAY_NAME, "the battle at the tape"),
            note=NETBATTLE_NOTE,
            # Both a stride off the tape, not on it. A figure stands 26pt
            # below its own point, and the far player's feet go TOWARDS
            # the net — placed at 0.475 he was drawn standing on the cord.
            home=[P(0.42, 0.60, "1", moves=[(0.44, 0.565, 0), (0.40, 0.60, 2)])],
            away=[P(0.44, 0.40, "2", moves=[(0.44, 0.43, 1)])],
            # The winning shot crosses the net. The zone was authored at
            # y=0.30 — 2's own half — so the board had him beating 1 by
            # hitting the shuttle into his own court. It lands deep in the
            # corner 1 has left open by coming to the tape.
            markers=[M(0.30, 0.72, "zone", "")],
            ball=(0.435, 0.575),
            ball_moves=[(0.44, 0.46, 1), (0.30, 0.72, 2)],
        ),
    ]


def badminton_library() -> list[Drill]:
    return (footwork_family() + multi_shuttle() + clear_family() + drive_family()
            + drop_family() + net_family() + deception_family()
            + doubles_family() + smash_family() + defence_family()
            + serve_family() + game_family() + gaps_family())

def multi_shuttle() -> list[Drill]:
    """Multi-shuttle feeding — the staple of Asian badminton training, and a
    gap any coach would have flagged: a feeder with a box of shuttles sets a
    tempo no rally can."""
    return [Drill(
        id="bd_multi_shuttle", category="warmup", minutes=10, rel=True,
        free=False,
        name={"en": "Multi-shuttle feeding", "en-GB": "Multi-shuttle feeding",
              "zh-CN": "多球训练", "zh-TW": "多球訓練",
              "ja-JP": "ノック練習", "ko-KR": "멀티셔틀 훈련",
              "es-ES": "Multivolantes", "fr-FR": "Multivolants",
              "id-ID": "Latihan multi-shuttlecock", "ms-MY": "Latihan multi-bulu tangkis",
              "th-TH": "ตีลูกป้อนต่อเนื่อง", "vi-VN": "Tập đa cầu"},
        note={"en": "The feed sets the tempo just past comfortable. Technique "
                    "that survives the tenth shuttle is technique you own.",
              "en-GB": "The feed sets the tempo just past comfortable. Technique "
                       "that survives the tenth shuttle is technique you own.",
              "zh-CN": "喂球节奏要比舒服再快一点。第十个球还不变形的技术，才是真正属于你的技术。",
              "zh-TW": "餵球節奏要比舒服再快一點。第十個球還不變形的技術，才是真正屬於你的技術。",
              "ja-JP": "ノックのテンポは「余裕より少し速く」。10球目でも崩れない技術だけが本物の技術だ。",
              "ko-KR": "피딩 템포는 편안함보다 살짝 빠르게. 열 번째 셔틀에도 무너지지 않는 기술이 진짜 네 기술이다.",
              "es-ES": "El ritmo de alimentación va justo por encima de lo cómodo: "
                       "la técnica que sobrevive al décimo volante es la tuya.",
              "fr-FR": "La cadence dépasse juste le confortable : la technique qui "
                       "tient au dixième volant est celle qui t'appartient.",
              "id-ID": "Tempo umpan sedikit di atas nyaman.",
              "ms-MY": "Tempo suapan sedikit melebihi selesa.",
              "th-TH": "จังหวะป้อนต้องเร็วกว่าที่สบายนิดหนึ่ง เทคนิคที่รอดถึงลูกที่สิบคือของจริง",
              "vi-VN": "Nhịp cấp cầu nhanh hơn mức thoải mái một chút."},
        # All four corners, and a cone on each. A feeder with a box of
        # shuttles works the whole court — that is what multi-shuttle is
        # for — and this board used to send the player to three of them
        # and leave the backhand rear alone, with the cones to match.
        home=[P(*BASE, "1", moves=[FR + (0,), BASE + (1,), FL + (2,),
                                   BASE + (3,), RR + (4,), BASE + (5,),
                                   RL + (6,), BASE + (7,)])],
        away=[P(*FEED, "C", coach=True)],
        markers=[M(*c, "cone", "") for c in (FL, FR, RL, RR)],
        ball=FEED,                  # in the feeder's hand
        # The shuttle is hit AT THE CORNERS. Left to the generator the feed
        # simply went to the player, and the player's own route starts at
        # base — so the one shot on the board was played in the middle of
        # the court, which is the one place a multi-shuttle feed never
        # goes. It is fed to the corner the player has just reached, comes
        # back, and goes out to the next one.
        #
        # Every beat but the last carries a leg on purpose. A beat the ball
        # has no leg for, with a written leg still to come, is given one
        # that follows the player — fine when a man runs with the ball,
        # wrong here: the shuttle would have walked back to base with him
        # between feeds.
        ball_moves=[FR + (0,), FEED + (1,), FL + (2,), FEED + (3,),
                    RR + (4,), FEED + (5,), RL + (6,)],
    )]

