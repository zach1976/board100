"""The sepak takraw library.

Three a side on a badminton-sized court, net at y=0.5, home at the bottom.
A regu is a tekong who serves from the back circle and two inside players who
receive, feed and attack — so almost every drill is those three roles doing
their part of the same three touches.
"""
from .engine import Drill, M, P, Spot, suffixed

# The service circle's centre is 2.45 m from the back line of a 13.4 m
# court, which is y = 0.8172 — not 0.86. Drawn 0.57 m behind it, the tekong
# stood outside the circle on every board, and the serve drills painted
# their own circle marker at the wrong spot too, so in the app it sat half
# a metre off the one the court painter draws.
TEKONG = (0.50, 0.8172)
# The quarter circles are 0.9 m radius at the centre line, and both inside
# players must have a foot in one at the moment of service.
QUARTER_L, QUARTER_R = (0.075, 0.555), (0.925, 0.555)
LEFT_INSIDE, RIGHT_INSIDE = (0.28, 0.64), (0.72, 0.64)
FEED_POINT = (0.50, 0.58)
NET = 0.5
# The far side's circle and quarter circles. The far team faces DOWN the
# board, so its left is the screen's right: its left inside player stands in
# the right-hand quarter circle.
AWAY_TEKONG = (0.50, 1 - 0.8172)
AWAY_QUARTER_L, AWAY_QUARTER_R = (0.925, 0.445), (0.075, 0.445)
# Labels: the near side is T (tekong), L, R; the far side wears the same
# roles in lower case — t, l, r — so a sentence never reads "L plays it to L".


def mirror(pt):
    return (pt[0], 1.0 - pt[1])


WARM_NAME = {
    "en": "Warm-up", "en-GB": "Warm-up", "zh-CN": "热身", "zh-TW": "熱身",
    "ja-JP": "ウォームアップ", "ko-KR": "웜업", "es-ES": "Calentamiento",
    "fr-FR": "Échauffement", "id-ID": "Pemanasan", "ms-MY": "Memanaskan badan",
    "th-TH": "วอร์มอัพ", "vi-VN": "Khởi động",
}
WARM_NOTE = {
    "en": "Touch the ball with every surface you are allowed — foot, knee, "
          "shoulder, head. In a rally you do not get to choose which one.",
    "en-GB": "Touch the ball with every surface you are allowed — foot, knee, "
             "shoulder, head. In a rally you do not get to choose which one.",
    "zh-CN": "允许用的部位都要碰球——脚、膝、肩、头。真打起来的时候，由不得你挑。",
    "zh-TW": "允許用的部位都要碰球——腳、膝、肩、頭。真打起來的時候，由不得你挑。",
    "ja-JP": "使える部位すべてで触る。足、膝、肩、頭。ラリーの中では選んでいる余裕はない。",
    "ko-KR": "허용된 모든 부위로 만져라 — 발, 무릎, 어깨, 머리. 랠리에선 고를 수 없다.",
    "es-ES": "Toca la bola con cada superficie permitida — pie, rodilla, "
             "hombro, cabeza: en el punto no eliges cuál.",
    "fr-FR": "Touche la balle avec chaque surface autorisée — pied, genou, "
             "épaule, tête : en jeu, tu ne choisis pas.",
    "id-ID": "Sentuh bola dengan semua bagian yang diizinkan — kaki, lutut, "
             "bahu, kepala. Dalam reli kamu tidak bisa memilih.",
    "ms-MY": "Sentuh bola dengan setiap bahagian yang dibenarkan — kaki, "
             "lutut, bahu, kepala. Dalam rali anda tidak boleh memilih.",
    "th-TH": "สัมผัสบอลด้วยทุกส่วนที่ใช้ได้ — เท้า เข่า ไหล่ ศีรษะ ในเกมจริงคุณเลือกไม่ได้",
    "vi-VN": "Chạm bóng bằng mọi bộ phận được phép — chân, gối, vai, đầu.",
}


def warmup_family() -> list[Drill]:
    specs = [("juggling", "juggling in pairs"), ("all_surfaces", "on every surface"),
             ("keep_up", "keeping it up as three")]
    out = []
    for key, label in specs:
        if key == "keep_up":
            home = [P(0.30, 0.70, "1", moves=[(0.40, 0.64, 0)]),
                    P(0.50, 0.80, "2", moves=[(0.50, 0.70, 1)]),
                    P(0.70, 0.70, "3", moves=[(0.60, 0.64, 2)])]
        elif key == "all_surfaces":
            # Four legal surfaces, four stations: it used to be the same
            # two dots as the pairs juggling.
            home = [P(0.26, 0.76, "1", moves=[(0.34, 0.68, 0)]),
                    P(0.50, 0.66, "2", moves=[(0.50, 0.60, 1)]),
                    P(0.74, 0.76, "3", moves=[(0.66, 0.68, 2)])]
        else:
            home = [P(0.34, 0.72, "1", moves=[(0.38, 0.66, 0)]),
                    P(0.66, 0.72, "2", moves=[(0.62, 0.66, 0)])]
        out.append(Drill(
            id=f"st_warm_{key}", category="warmup", minutes=8, rel=True,
            free=(key in ("juggling", "keep_up")),
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            home=home, ball=0,
            # kept alive between them — pairs, or round the circle
            ball_to=([(1, 0), (0, 1)] if key == "juggling" else [(1, 0), (2, 1), (0, 2)]),
        ))
    return out


FEED_NAME = {
    "en": "Feeding", "en-GB": "Feeding", "zh-CN": "传球", "zh-TW": "傳球",
    "ja-JP": "トス", "ko-KR": "토스", "es-ES": "El pase", "fr-FR": "La passe",
    "id-ID": "Umpan", "ms-MY": "Umpanan", "th-TH": "การชง", "vi-VN": "Đường chuyền",
}
FEED_NOTE = {
    "en": "Feed the ball where the striker's foot will be, not where they are. "
          "A perfect height in the wrong place is still a wasted point.",
    "en-GB": "Feed the ball where the striker's foot will be, not where they "
             "are. A perfect height in the wrong place is still a wasted point.",
    "zh-CN": "把球传到扣球手的脚将要到的位置，不是他现在站的位置。高度再完美，位置不对，这一分照样浪费。",
    "zh-TW": "把球傳到扣球手的腳將要到的位置，不是他現在站的位置。高度再完美，位置不對，這一分照樣浪費。",
    "ja-JP": "アタッカーの足がこれから来る場所へ上げる。今いる場所ではない。高さが完璧でも位置が違えば1点の無駄だ。",
    "ko-KR": "공격수의 발이 갈 자리로 올려라, 지금 있는 자리가 아니라.",
    "es-ES": "Pasa a donde estará el pie del rematador, no a donde está: la "
             "altura perfecta en el sitio equivocado sigue siendo un punto perdido.",
    "fr-FR": "Passe là où le pied de l'attaquant sera, pas où il est : une "
             "hauteur parfaite au mauvais endroit reste un point gâché.",
    "id-ID": "Umpan ke tempat kaki penyerang akan berada, bukan tempatnya sekarang.",
    "ms-MY": "Umpan ke tempat kaki penyerang akan berada, bukan tempatnya kini.",
    "th-TH": "ชงไปยังจุดที่เท้าตัวฟาดจะไปถึง ไม่ใช่จุดที่เขายืนอยู่",
    "vi-VN": "Chuyền tới nơi chân người tấn công sẽ tới, không phải nơi họ đang đứng.",
}


def feed_family() -> list[Drill]:
    """The feed is the second touch: the serve comes over (tossed to the far
    tekong by his inside player, struck from his circle), R receives it up
    to F, and F sets it onto the square where S arrives to strike."""
    # The receiver is a back-court player, never the inside player who is
    # about to feed — the two used to share a coordinate exactly.
    specs = [("receiving_the_serve", "receiving the serve", TEKONG, FEED_POINT),
             ("the_high_feed", "the high feed", (0.20, 0.80), (0.42, 0.56)),
             ("the_quick_feed", "the quick feed", (0.80, 0.80), (0.58, 0.55))]
    out = []
    for key, label, receiver, target in specs:
        out.append(Drill(
            id=f"st_feed_{key}", category="possession", minutes=10, rel=True,
            free=(key != "the_quick_feed"),
            name=suffixed(FEED_NAME, label), note=FEED_NOTE,
            home=[P(*receiver, "R", moves=[(receiver[0], receiver[1] - 0.04, 0)]),
                  P(*LEFT_INSIDE, "F", moves=[(0.46, 0.62, 1)]),
                  P(*RIGHT_INSIDE, "S", moves=[(0.66, 0.60, 2), target + (3,)])],
            away=[P(*AWAY_TEKONG, "t"), P(*AWAY_QUARTER_L, "l")],
            markers=[M(*target, "square", "")],
            ball=AWAY_QUARTER_L,
            # toss, serve, receive, feed
            ball_to=[("a0", 0), (0, 1), (1, 2), (2, 3)],
        ))
    return out


SPIKE_NAME = {
    "en": "Spiking", "en-GB": "Spiking", "zh-CN": "扣球", "zh-TW": "扣球",
    "ja-JP": "アタック", "ko-KR": "스파이크", "es-ES": "Remate",
    "fr-FR": "Attaque", "id-ID": "Smes", "ms-MY": "Rejaman",
    "th-TH": "การฟาด", "vi-VN": "Đá tấn công",
}
SPIKE_NOTE = {
    "en": "Get the foot above the ball — above the tape if you can — while the hips stay under it. Height comes "
          "from the jump, not from kicking harder at the top.",
    "en-GB": "Get the foot above the ball — above the tape if you can — while the hips stay under it. Height comes "
             "from the jump, not from kicking harder at the top.",
    "zh-CN": "起脚之前先把胯送到球上方。高度来自起跳，不是来自到了顶点再用力踢。",
    "zh-TW": "起腳之前先把胯送到球上方。高度來自起跳，不是來自到了頂點再用力踢。",
    "ja-JP": "足を振る前に腰をボールの上へ。高さは跳躍から来る。頂点で強く蹴っても上がらない。",
    "ko-KR": "발을 휘두르기 전에 골반을 공 위로 올려라. 높이는 점프에서 나온다.",
    "es-ES": "Lleva la cadera por encima de la bola antes de golpear: la "
             "altura viene del salto, no de patear más fuerte arriba.",
    "fr-FR": "Amène les hanches au-dessus de la balle avant de frapper : la "
             "hauteur vient du saut, pas d'un coup de pied plus fort.",
    "id-ID": "Bawa pinggul di atas bola sebelum kaki mengayun.",
    "ms-MY": "Bawa pinggul di atas bola sebelum kaki menghayun.",
    "th-TH": "เอาสะโพกขึ้นเหนือบอลก่อนเหวี่ยงเท้า ความสูงมาจากการกระโดด",
    "vi-VN": "Đưa hông lên trên bóng trước khi vung chân.",
}


SUNBACK_NOTE = {
    "en": "Back to the net, and the strike goes over your own shoulder — so the set has to be behind you, not in front. Turning to look for it is how the block gets there first.",
    "en-GB": "Back to the net, and the strike goes over your own shoulder — so the set has to be behind you, not in front. Turning to look for it is how the block gets there first.",
    "zh-CN": "背对球网，从自己肩上把球踢出去——所以二传要送到你身后，不是身前。回头去找球的那一下，就是拦网先到的原因。",
    "zh-TW": "背對球網，從自己肩上把球踢出去——所以二傳要送到你身後，不是身前。回頭去找球的那一下，就是攔網先到的原因。",
    "ja-JP": "ネットに背を向け、自分の肩越しに蹴る。だからトスは前ではなく背後へ。振り返って探した瞬間にブロックが先に着く。",
    "ko-KR": "네트에 등을 지고 자기 어깨 너머로 찬다. 그래서 토스는 앞이 아니라 뒤로 와야 한다.",
    "es-ES": "De espaldas a la red, el golpe sale por encima del propio hombro: el pase debe llegar detrás de ti, no delante.",
    "fr-FR": "Dos au filet, la frappe part par-dessus ta propre épaule : la passe doit arriver derrière toi, pas devant.",
    "id-ID": "Punggung menghadap net, tendangan melewati bahu sendiri, jadi umpan harus di belakangmu.",
    "ms-MY": "Belakang menghadap jaring, tendangan melepasi bahu sendiri.",
    "th-TH": "หันหลังให้ตาข่าย เตะข้ามไหล่ตัวเอง ดังนั้นลูกเซ็ตต้องมาด้านหลัง",
    "vi-VN": "Lưng quay về lưới, cú đá đi qua vai mình, nên quả nâng phải ở phía sau bạn.",
}


def spike_family() -> list[Drill]:
    # Three different actions, drawn as three different pictures. They used
    # to share one board with the target cone moved, which cannot tell a
    # roll spike from a scissor kick from a sunback — so the boards say
    # what a board can: the approach angle, where the set is put, where the
    # spiker takes off relative to the net, and which way the blocker goes.
    # (key, label, approach start, take-off, the set, target, blocker)
    specs = [
        # The roll: approach from wide, turn side-on, strike across.
        ("roll", "the roll spike", (0.80, 0.66), (0.68, 0.545),
         (0.62, 0.58), (0.30, 0.24), (0.60, 0.455)),
        # The scissor: a straight run, both legs through the ball.
        ("scissor", "the scissor kick", (0.62, 0.72), (0.60, 0.535),
         (0.56, 0.60), (0.70, 0.22), (0.56, 0.455)),
        # The sunback: back to the net, struck over the shoulder.
        ("sunback", {"en": "the sunback", "en-GB": "the sunback",
                     "zh-CN": "背向倒挂", "zh-TW": "背向倒掛", "ja-JP": "サンバック",
                     "ko-KR": "선백", "es-ES": "de espaldas", "fr-FR": "dos au filet",
                     "id-ID": "sunback", "ms-MY": "membelakang",
                     "th-TH": "ลูกฟาดหลังหัน", "vi-VN": "đá lộn người"},
         (0.36, 0.70), (0.44, 0.545),
         (0.46, 0.62), (0.50, 0.16), (0.46, 0.455)),
    ]
    out = []
    for key, label, start, jump, set_at, land, blocker in specs:
        out.append(Drill(
            id=f"st_spike_{key}", category="finishing", minutes=12, rel=True,
            free=(key == "roll"),
            name=suffixed(SPIKE_NAME, label),
            # The sunback is struck with the back to the net, over the
            # shoulder, so the family's turning cue does not describe it.
            note=SUNBACK_NOTE if key == "sunback" else SPIKE_NOTE,
            home=[P(*start, "S", moves=[jump + (1,)]),
                  P(*LEFT_INSIDE, "F", moves=[set_at + (0,)])],
            away=[P(*blocker, "B", moves=[(blocker[0] + (0.5 - blocker[0]) * 0.2,
                                           0.45, 1)]),
                  P(land[0], land[1] - 0.06, "D", moves=[(land[0], land[1], 2)])],
            markers=[M(*land, "zone", "")],
            ball=1,
            ball_moves=[set_at + (0,), (jump[0], jump[1] - 0.02, 1),
                        land + (2,)],
        ))
    return out


ATTACK_NAME = {
    "en": "Attacking", "en-GB": "Attacking", "zh-CN": "进攻", "zh-TW": "進攻",
    "ja-JP": "攻撃", "ko-KR": "공격", "es-ES": "Ataque", "fr-FR": "Attaque",
    "id-ID": "Serangan", "ms-MY": "Serangan", "th-TH": "การบุก", "vi-VN": "Tấn công",
}
ATTACK_NOTE = {
    "en": "Look at the blocker's hands on the way up. Three touches is barely "
          "any time, so the decision has to be made in the air.",
    "en-GB": "Look at the blocker's hands on the way up. Three touches is "
             "barely any time, so the decision has to be made in the air.",
    "zh-CN": "起跳过程中就要看拦网人的手。三次触球几乎没有时间，决定必须在空中做完。",
    "zh-TW": "起跳過程中就要看攔網人的手。三次觸球幾乎沒有時間，決定必須在空中做完。",
    "ja-JP": "跳び上がる途中でブロッカーの手を見る。3タッチは時間がほぼない。判断は空中で終える。",
    "ko-KR": "떠오르면서 블로커의 손을 봐라. 세 번의 터치는 시간이 없다. 판단은 공중에서 끝난다.",
    "es-ES": "Mira las manos del bloqueador mientras subes: con tres toques no "
             "hay tiempo, la decisión se toma en el aire.",
    "fr-FR": "Regarde les mains du contreur en montant : trois touches, c'est "
             "presque aucun temps — la décision se prend en l'air.",
    "id-ID": "Lihat tangan pemblok saat naik.",
    "ms-MY": "Lihat tangan pemblok ketika naik.",
    "th-TH": "มองมือคนบล็อกตอนลอยขึ้น สามสัมผัสแทบไม่มีเวลา ต้องตัดสินใจกลางอากาศ",
    "vi-VN": "Nhìn tay người chắn khi bật lên.",
}


def attack_family() -> list[Drill]:
    """F sets, S strikes past the block into the zone. The block jumps where
    the attack is NOT going, which is the read the drill trains."""
    # (key, label, landing zone, where the block jumps)
    specs = [("straight", "straight", (0.72, 0.22), (0.50, 0.455)),
             ("cross-court", "cross-court", (0.24, 0.26), (0.66, 0.455)),
             ("the feint", "the feint", (0.62, 0.40), (0.62, 0.455))]
    out = []
    for key, label, land, block in specs:
        out.append(Drill(
            id=f"st_attack_{key.replace('-', '_').replace(' ', '_')}",
            category="attacking", minutes=10, rel=True,
            free=(key == "straight"),
            name=suffixed(ATTACK_NAME, label), note=ATTACK_NOTE,
            home=[P(*RIGHT_INSIDE, "S", moves=[(0.62, 0.54, 0)]),
                  P(*LEFT_INSIDE, "F", moves=[(0.44, 0.60, 1)]),
                  P(*TEKONG, "T", moves=[(0.56, 0.70, 1)])],
            away=[P(0.56, 0.47, "B", moves=[block + (1,)]),
                  P(0.50, 0.20, "D", moves=[(0.50 + (land[0] - 0.50) * 0.4,
                                             0.22, 1)])],
            markers=[M(*land, "zone", "")],
            ball=1, ball_to=[(0, 0), (Spot(*land), 1)],
        ))
    return out


DEF_NAME = {
    "en": "Defending", "en-GB": "Defending", "zh-CN": "防守", "zh-TW": "防守",
    "ja-JP": "ディフェンス", "ko-KR": "수비", "es-ES": "Defensa",
    "fr-FR": "Défense", "id-ID": "Bertahan", "ms-MY": "Pertahanan",
    "th-TH": "การรับ", "vi-VN": "Phòng thủ",
}
DEF_NOTE = {
    "en": "The blocker turns their back and the two behind cover what the "
          "block leaves. Nobody defends a takraw spike by reacting to it.",
    "en-GB": "The blocker turns their back and the two behind cover what the "
             "block leaves. Nobody defends a takraw spike by reacting to it.",
    "zh-CN": "拦网的人转身用背，后面两个人补拦网留下的空当。没有人是靠反应去防藤球扣杀的。",
    "zh-TW": "攔網的人轉身用背，後面兩個人補攔網留下的空檔。沒有人是靠反應去防藤球扣殺的。",
    "ja-JP": "ブロッカーは背中を向け、後ろの2人がブロックの残した所を埋める。反応で takraw のアタックは拾えない。",
    "ko-KR": "블로커는 등을 돌리고, 뒤의 둘이 블록이 남긴 곳을 메운다. 반응만으로는 못 막는다.",
    "es-ES": "El bloqueador gira la espalda y los dos de atrás cubren lo que "
             "el bloqueo deja: nadie defiende un remate reaccionando.",
    "fr-FR": "Le contreur tourne le dos et les deux derrière couvrent ce que "
             "le contre laisse : on ne défend pas une attaque en réagissant.",
    "id-ID": "Pemblok memunggungi dan dua di belakang menutup sisa blok.",
    "ms-MY": "Pemblok membelakangi dan dua di belakang menutup baki blok.",
    "th-TH": "คนบล็อกหันหลัง และอีกสองคนคุมช่องที่บล็อกเหลือไว้",
    "vi-VN": "Người chắn quay lưng, hai người sau bọc phần hàng chắn bỏ lại.",
}


def defence_family() -> list[Drill]:
    """Their F sets, their S spikes; B blocks and D digs the ball the block
    lets through — at the spot the drill is named for — up to T."""
    # (key, label, D's start, where D digs it)
    specs = [("at the net", "at the net", (0.74, 0.62), (0.72, 0.57)),
             ("behind the block", "behind the block", (0.46, 0.78), (0.58, 0.68)),
             ("covering the block", "covering the block", (0.28, 0.68), (0.36, 0.62))]
    out = []
    for key, start, dig in [(s[0], s[2], s[3]) for s in specs]:
        out.append(Drill(
            id=f"st_defence_{key.replace(' ', '_')}", category="defending",
            minutes=10, rel=True, free=(key != "covering the block"),
            name=suffixed(DEF_NAME, key), note=DEF_NOTE,
            home=[P(0.58, 0.53, "B", moves=[(0.58, 0.515, 1)]),
                  P(*start, "D", moves=[dig + (1,)]),
                  P(*TEKONG, "T", moves=[(0.50, 0.66, 2)])],
            away=[P(0.62, 0.38, "S", moves=[(0.60, 0.455, 0)]),
                  P(0.36, 0.34, "F", moves=[(0.42, 0.40, 1)])],
            ball=(0.36, 0.34),
            # set, spike, dig
            ball_to=[("a0", 0), (1, 1), (2, 2)],
        ))
    return out


SERVE_NAME = {
    "en": "Serve", "en-GB": "Serve", "zh-CN": "发球", "zh-TW": "發球",
    "ja-JP": "サーブ", "ko-KR": "서브", "es-ES": "Saque", "fr-FR": "Service",
    "id-ID": "Servis", "ms-MY": "Servis", "th-TH": "การเสิร์ฟ", "vi-VN": "Giao cầu",
}
SERVE_NOTE = {
    "en": "The tekong's serve is the only attack nobody blocks. Serve at a "
          "receiver's weak surface, not into the middle where anyone can take it.",
    "en-GB": "The tekong's serve is the only attack nobody blocks. Serve at a "
             "receiver's weak surface, not into the middle where anyone can take it.",
    "zh-CN": "发球手的发球是唯一没人拦的进攻。要发向接球人不擅长的部位，不要发到中间——那里谁都接得到。",
    "zh-TW": "發球手的發球是唯一沒人攔的進攻。要發向接球人不擅長的部位，不要發到中間——那裡誰都接得到。",
    "ja-JP": "テコンのサーブは誰にもブロックされない唯一の攻撃だ。相手の苦手な部位を狙う。真ん中は誰でも取れる。",
    "ko-KR": "테콩의 서브는 아무도 막지 않는 유일한 공격이다. 상대가 약한 부위를 노려라.",
    "es-ES": "El saque del tekong es el único ataque que nadie bloquea: busca "
             "la superficie débil del receptor, no el centro.",
    "fr-FR": "Le service du tekong est la seule attaque que personne ne "
             "contre : vise la surface faible du receveur, pas le milieu.",
    "id-ID": "Servis tekong adalah satu-satunya serangan yang tak diblok.",
    "ms-MY": "Servis tekong ialah satu-satunya serangan yang tidak diblok.",
    "th-TH": "ลูกเสิร์ฟของตัวเสิร์ฟคือการบุกอย่างเดียวที่ไม่มีใครบล็อก",
    "vi-VN": "Cú giao của tekong là đòn tấn công duy nhất không ai chắn.",
}


def serve_family() -> list[Drill]:
    """L tosses, the tekong serves from his circle into the zone."""
    specs = [("deep", "deep", (0.50, 0.06)), ("at the seam", "at the seam", (0.40, 0.26)),
             ("short", "short", (0.62, 0.42))]
    out = []
    for key, label, land in specs:
        if key == "at the seam":
            # The seam is BETWEEN two receivers: they stand 2.5 m apart
            # with the zone in the gap, and the serve splits them.
            away = [P(land[0] - 0.20, land[1] - 0.02, "D",
                      moves=[(land[0] - 0.04, land[1], 1)]),
                    P(land[0] + 0.20, land[1] - 0.02, "E",
                      moves=[(land[0] + 0.16, land[1], 1)])]
        else:
            away = [P(land[0], land[1] - 0.06, "D", moves=[(land[0], land[1], 1)])]
        out.append(Drill(
            id=f"st_serve_{key.replace(' ', '_')}", category="setpiece",
            minutes=8, rel=True, free=(key == "deep"),
            name=suffixed(SERVE_NAME, label), note=SERVE_NOTE,
            # The inside players start in the quarter circles at the net —
            # that is where the rules put them for the serve; mid-court is
            # where they drop to once it is away.
            home=[P(*TEKONG, "T"),
                  P(*QUARTER_L, "L", moves=[(0.32, 0.61, 1)]),
                  P(*QUARTER_R, "R", moves=[(0.68, 0.61, 1)])],
            away=away,
            markers=[M(*TEKONG, "circle", ""), M(*land, "zone", "")],
            ball=1, ball_to=[(0, 0), ("a0", 1)],
        ))
    return out


GAME_NAME = {
    "en": "Game", "en-GB": "Game", "zh-CN": "对抗", "zh-TW": "對抗",
    "ja-JP": "ゲーム", "ko-KR": "게임", "es-ES": "Juego", "fr-FR": "Jeu",
    "id-ID": "Permainan", "ms-MY": "Permainan", "th-TH": "เกม", "vi-VN": "Trận đấu",
}
GAME_NOTE = {
    "en": "Three touches, three players, one rally. Take the block away and "
          "the attackers have to learn to place the ball instead of hitting it.",
    "en-GB": "Three touches, three players, one rally. Take the block away and "
             "the attackers have to learn to place the ball instead of hitting it.",
    "zh-CN": "三次触球，三个人，一个回合。把拦网去掉，进攻手就必须学会把球放到位置，而不是一味砸。",
    "zh-TW": "三次觸球，三個人，一個回合。把攔網去掉，進攻手就必須學會把球放到位置，而不是一味砸。",
    "ja-JP": "3タッチ、3人、1本のラリー。ブロックを外せば、アタッカーは強く蹴るのではなく置くことを覚える。",
    "ko-KR": "세 번의 터치, 세 명, 한 랠리. 블록을 없애면 공격수는 때리는 대신 놓는 법을 배운다.",
    "es-ES": "Tres toques, tres jugadores, un punto. Quita el bloqueo y los "
             "atacantes tendrán que colocar en vez de pegar.",
    "fr-FR": "Trois touches, trois joueurs, un échange. Supprime le contre et "
             "les attaquants apprennent à placer plutôt qu'à frapper.",
    "id-ID": "Tiga sentuhan, tiga pemain, satu reli.",
    "ms-MY": "Tiga sentuhan, tiga pemain, satu rali.",
    "th-TH": "สามสัมผัส สามคน หนึ่งการโต้",
    "vi-VN": "Ba chạm, ba người, một pha bóng.",
}


GAME_2V2_NOTE = {
    "en": "Two players, three touches: whoever does not take the first touch sets, and the one who received it attacks. Nobody can stand and watch.",
    "en-GB": "Two players, three touches: whoever does not take the first touch sets, and the one who received it attacks. Nobody can stand and watch.",
    "zh-CN": "两个人、三次触球：没接第一下的人传，接第一下的人攻。谁也不能站着看。",
    "zh-TW": "兩個人、三次觸球：沒接第一下的人傳，接第一下的人攻。誰也不能站著看。",
    "ja-JP": "2人で3タッチ。1本目を取らなかった方が上げ、受けた方が攻める。立って見ている暇は誰にもない。",
    "ko-KR": "두 명, 세 번의 터치: 첫 터치를 받지 않은 사람이 올리고, 받은 사람이 공격한다. 서서 보는 사람은 없다.",
    "es-ES": "Dos jugadores, tres toques: el que no recibe pasa y el que recibió ataca. Nadie puede quedarse mirando.",
    "fr-FR": "Deux joueurs, trois touches : celui qui ne reçoit pas passe, celui qui a reçu attaque. Personne ne peut rester à regarder.",
    "id-ID": "Dua pemain, tiga sentuhan: yang tidak menerima sentuhan pertama mengumpan, yang menerima menyerang. Tak ada yang boleh diam menonton.",
    "ms-MY": "Dua pemain, tiga sentuhan: yang tidak menerima sentuhan pertama mengumpan, yang menerima menyerang. Tiada siapa boleh berdiri melihat.",
    "th-TH": "สองคน สามสัมผัส คนที่ไม่ได้รับลูกแรกเป็นคนชง คนที่รับลูกแรกเป็นคนฟาด ไม่มีใครยืนดูเฉยได้",
    "vi-VN": "Hai người, ba chạm: ai không đỡ chạm đầu thì chuyền, người đã đỡ thì tấn công. Không ai được đứng nhìn.",
}
GAME_3V3_NOTE = {
    "en": "Three touches, three players, one rally. The serve is the tekong's, the first touch is the receiver's, and the feed has to arrive where the striker takes off — play it out and keep score.",
    "en-GB": "Three touches, three players, one rally. The serve is the tekong's, the first touch is the receiver's, and the feed has to arrive where the striker takes off — play it out and keep score.",
    "zh-CN": "三次触球、三个人、一个回合。发球归发球手，一传归接球人，二传必须送到攻手起跳的位置——打完整一分并计分。",
    "zh-TW": "三次觸球、三個人、一個回合。發球歸發球手，一傳歸接球人，二傳必須送到攻手起跳的位置——打完整一分並計分。",
    "ja-JP": "3タッチ、3人、1本のラリー。サーブはテコン、1本目はレシーバー、トスはアタッカーの踏み切り位置へ。最後までプレーして得点を数える。",
    "ko-KR": "세 번의 터치, 세 명, 한 랠리. 서브는 테콩, 첫 터치는 리시버, 토스는 공격수가 도약하는 자리로 — 끝까지 플레이하고 점수를 센다.",
    "es-ES": "Tres toques, tres jugadores, un punto. El saque es del tekong, el primer toque del receptor y el pase tiene que llegar donde salta el rematador: jugadlo entero y contad.",
    "fr-FR": "Trois touches, trois joueurs, un échange. Le service est au tekong, la première touche au receveur, et la passe doit arriver là où l'attaquant décolle : jouez le point et comptez.",
    "id-ID": "Tiga sentuhan, tiga pemain, satu reli. Servis milik tekong, sentuhan pertama milik penerima, dan umpan harus tiba di titik tolakan penyerang — mainkan sampai habis dan hitung skornya.",
    "ms-MY": "Tiga sentuhan, tiga pemain, satu rali. Servis milik tekong, sentuhan pertama milik penerima, dan umpanan mesti tiba di titik lonjakan penyerang — main sampai habis dan kira mata.",
    "th-TH": "สามสัมผัส สามคน หนึ่งการโต้ ลูกเสิร์ฟเป็นของตัวเสิร์ฟ ลูกแรกเป็นของคนรับ และลูกชงต้องไปถึงจุดที่ตัวฟาดกระโดด เล่นให้จบแต้มและนับคะแนน",
    "vi-VN": "Ba chạm, ba người, một pha bóng. Giao cầu là của tekong, chạm đầu là của người đỡ, đường chuyền phải tới đúng chỗ người tấn công bật nhảy — đánh hết điểm và tính điểm.",
}
GAME_REGU_NOTE = {
    "en": "A full regu, block and all. The attack now has to beat a block, so the feed decides the point: set it tight to the net and the blocker wins; set it a metre off and the striker gets a look past him.",
    "en-GB": "A full regu, block and all. The attack now has to beat a block, so the feed decides the point: set it tight to the net and the blocker wins; set it a metre off and the striker gets a look past him.",
    "zh-CN": "完整的三人制，带拦网。进攻要过拦网，所以二传决定这一分：传得贴网，拦网人赢；离网一米，攻手才看得到拦网人身后的空当。",
    "zh-TW": "完整的三人制，帶攔網。進攻要過攔網，所以二傳決定這一分：傳得貼網，攔網人贏；離網一公尺，攻手才看得到攔網人身後的空檔。",
    "ja-JP": "ブロックありのフルレグ。攻撃はブロックを破らなければならないので、トスが1点を決める。ネットに近すぎればブロッカーの勝ち、1m離せばアタッカーにブロックの外が見える。",
    "ko-KR": "블로킹까지 있는 완전한 레구. 공격이 블록을 넘어야 하므로 토스가 포인트를 정한다: 네트에 붙이면 블로커가 이기고, 1m 떨어뜨리면 공격수가 블록 너머를 본다.",
    "es-ES": "Un regu completo, con bloqueo. El ataque tiene que superar un bloqueo, así que el pase decide el punto: pegado a la red gana el bloqueador; a un metro, el rematador ve el hueco.",
    "fr-FR": "Un regu complet, avec contre. L'attaque doit passer un contre, donc la passe décide du point : collée au filet, le contreur gagne ; à un mètre, l'attaquant voit au-delà de lui.",
    "id-ID": "Regu lengkap, dengan blok. Serangan harus melewati blok, jadi umpan menentukan poin: terlalu dekat net, pemblok menang; satu meter dari net, penyerang bisa melihat celah di sampingnya.",
    "ms-MY": "Regu penuh, dengan sekatan. Serangan mesti melepasi sekatan, jadi umpanan menentukan mata: terlalu rapat ke jaring, penyekat menang; satu meter dari jaring, penyerang nampak ruang di sebelahnya.",
    "th-TH": "เล่นเต็มทีมสามคนพร้อมบล็อก การบุกต้องผ่านบล็อก ลูกชงจึงตัดสินแต้ม ชงชิดเน็ตคนบล็อกชนะ ชงห่างเน็ตหนึ่งเมตรตัวฟาดจะเห็นช่องข้างบล็อก",
    "vi-VN": "Đội hình đủ ba người, có chắn. Tấn công phải vượt hàng chắn nên đường chuyền quyết định điểm: chuyền sát lưới thì người chắn thắng; cách lưới một mét thì người đá thấy khoảng trống.",
}


def game_family() -> list[Drill]:
    """Every game opens the legal way: the inside player in his quarter
    circle tosses, the server strikes from the circle, and the far side
    receives from mid-court and sets."""
    out = []
    # 2v2 (the doubles event): one serves from the circle, the partner tosses.
    out.append(Drill(
        id="st_game_2v2", category="ssg", minutes=15, rel=True, free=True,
        name=suffixed(GAME_NAME, "2v2"), note=GAME_2V2_NOTE,
        home=[P(*TEKONG, "1"),
              P(*QUARTER_L, "2", moves=[(0.36, 0.64, 1)])],
        away=[P(0.34, 0.30, "A", moves=[(0.32, 0.26, 1), (0.40, 0.44, 3)]),
              P(0.66, 0.30, "B", moves=[(0.52, 0.42, 2)])],
        # serve, receive, set, and the kill into the server's court
        ball=1, ball_to=[(0, 0), ("a0", 1), ("a1", 2), ("a0", 3),
                         (Spot(0.66, 0.76), 4)],
    ))
    for key, label, note in [("3v3", "3v3", GAME_3V3_NOTE),
                             ("no_block", "with no block", GAME_NOTE)]:
        out.append(Drill(
            id=f"st_game_{key}", category="ssg", minutes=15, rel=True,
            free=(key == "3v3"),
            name=suffixed(GAME_NAME, label), note=note,
            home=[P(*QUARTER_L, "1", moves=[(0.30, 0.64, 1)]),
                  P(*QUARTER_R, "2", moves=[(0.70, 0.64, 1)]),
                  P(*TEKONG, "3")],
            away=[P(0.70, 0.30, "A", moves=[(0.54, 0.42, 2)]),
                  P(0.30, 0.30, "B", moves=[(0.28, 0.26, 1), (0.40, 0.44, 3)]),
                  P(*AWAY_TEKONG, "C")],
            # No block: cones on both sidelines a metre off the net mark the
            # line nobody may cross to block.
            markers=([M(0.0, 0.5 + 1 / 13.4, "cone", ""), M(1.0, 0.5 + 1 / 13.4, "cone", ""),
                      M(0.0, 0.5 - 1 / 13.4, "cone", ""), M(1.0, 0.5 - 1 / 13.4, "cone", "")]
                     if key == "no_block" else []),
            ball=0, ball_to=[(2, 0), ("a1", 1), ("a0", 2), ("a1", 3),
                             (Spot(0.16, 0.86), 4)],
        ))
    return out


BLOCK_NOTE = {
    "en": "Turn your back and take it on the shoulder or the back — not the chest, which sends it straight down on your own side. Jump on his hip, not on the ball.",
    "en-GB": "Turn your back and take it on the shoulder or the back — not the chest, which sends it straight down on your own side. Jump on his hip, not on the ball.",
    "zh-CN": "转身用肩或背去挡，不要用胸——胸挡会把球直接砸回自己半场。看他的髋起跳，不是看球起跳。",
    "zh-TW": "轉身用肩或背去擋，不要用胸——胸擋會把球直接砸回自己半場。看他的髖起跳，不是看球起跳。",
    "ja-JP": "背を向けて肩か背中で受ける。胸は自陣に真下へ落ちるので使わない。跳ぶのはボールではなく相手の腰に対して。",
    "ko-KR": "등을 돌려 어깨나 등으로 막아라. 가슴은 자기 코트로 그대로 떨어뜨린다. 공이 아니라 상대의 허리를 보고 뛰어라.",
    "es-ES": "Gira la espalda y bloquea con el hombro o la espalda, no con el pecho, que la manda abajo en tu propio campo.",
    "fr-FR": "Tourne le dos et bloque de l'épaule ou du dos, pas de la poitrine, qui la renvoie au sol dans ton camp.",
    "id-ID": "Putar punggung dan blok dengan bahu atau punggung, bukan dada.",
    "ms-MY": "Pusing belakang dan sekat dengan bahu atau belakang, bukan dada.",
    "th-TH": "หันหลังแล้วบล็อกด้วยไหล่หรือหลัง ไม่ใช่หน้าอก",
    "vi-VN": "Xoay lưng và chắn bằng vai hoặc lưng, không phải bằng ngực.",
}
HEAD_NOTE = {
    "en": "The head is one of the four surfaces, and the only one that can take a hard serve cleanly at chest height. Meet it with the forehead, moving forward, not with the top of the skull.",
    "en-GB": "The head is one of the four surfaces, and the only one that can take a hard serve cleanly at chest height. Meet it with the forehead, moving forward, not with the top of the skull.",
    "zh-CN": "头是四个合法触球部位之一，也是唯一能在胸高干净地接住重发球的那个。要用前额、身体往前迎，不是用头顶。",
    "zh-TW": "頭是四個合法觸球部位之一，也是唯一能在胸高乾淨地接住重發球的那個。要用前額、身體往前迎，不是用頭頂。",
    "ja-JP": "頭は4つの接触面のひとつで、胸の高さの強いサーブをきれいに処理できる唯一の面だ。前へ出ながら額で当てる。頭頂ではない。",
    "ko-KR": "머리는 네 개의 접촉면 중 하나이며, 가슴 높이의 강한 서브를 깔끔히 받을 수 있는 유일한 면이다. 이마로, 앞으로 나가며 맞춰라.",
    "es-ES": "La cabeza es una de las cuatro superficies y la única que recibe limpio un saque fuerte a la altura del pecho: con la frente y avanzando.",
    "fr-FR": "La tête est l'une des quatre surfaces et la seule qui reprend proprement un service fort à hauteur de poitrine : avec le front, en avançant.",
    "id-ID": "Kepala adalah satu dari empat permukaan sah, dan satu-satunya yang bisa menerima servis keras setinggi dada dengan bersih.",
    "ms-MY": "Kepala ialah satu daripada empat permukaan sah untuk menyambut servis keras separas dada.",
    "th-TH": "ศีรษะเป็นหนึ่งในสี่ส่วนที่ใช้ได้ และเป็นส่วนเดียวที่รับลูกเสิร์ฟแรงระดับอกได้สะอาด",
    "vi-VN": "Đầu là một trong bốn bề mặt hợp lệ, và là bề mặt duy nhất đỡ gọn quả giao mạnh ngang ngực.",
}


def gaps_family() -> list[Drill]:
    """Blocking and heading, neither of which had a board.

    The block appeared only as an opposition dummy inside the defending
    family; 'header' appeared nowhere at all, in a sport whose own warm-up
    lists the head as one of the four legal surfaces.
    """
    return [
        Drill(
            id="st_block_at_the_net", category="defending", minutes=10, rel=True,
            level="foundation", free=True,
            name=suffixed(DEF_NAME, "blocking at the net"), note=BLOCK_NOTE,
            home=[P(0.46, 0.545, "B", moves=[(0.50, 0.525, 1)]),
                  P(0.72, 0.66, "C", moves=[(0.62, 0.62, 2)])],
            away=[P(0.54, 0.455, "S", moves=[(0.50, 0.475, 1)]),
                  P(0.26, 0.34, "F", moves=[(0.34, 0.40, 0)])],
            # Where the block has to send it: back down on THEIR side.
            markers=[M(0.40, 0.40, "zone", "")],
            # fed to their striker; the kill meets the block; the block
            # drops it into their court
            ball=(0.28, 0.36),
            ball_to=[("a0", 0), (0, 1), (Spot(0.40, 0.40), 2)],
        ),
        Drill(
            id="st_receive_header", category="possession", minutes=10, rel=True,
            level="foundation",
            name=suffixed(RECEIVE2_NAME, "with the head"), note=HEAD_NOTE,
            # The far tekong serves from HIS circle, tossed by his inside
            # player; R heads it up to F. (The server used to stand in the
            # receivers' own circle, so the serve never crossed the net.)
            home=[P(0.34, 0.68, "R", moves=[(0.40, 0.62, 1)]),
                  P(0.62, 0.66, "F", moves=[(0.54, 0.58, 2)])],
            away=[P(*AWAY_TEKONG, "t"), P(*AWAY_QUARTER_L, "l")],
            markers=[M(*AWAY_TEKONG, "circle", ""), M(0.40, 0.62, "zone", "")],
            ball=AWAY_QUARTER_L,
            ball_to=[("a0", 0), (0, 1), (1, 2)],
        ),
    ]


def sepak_takraw_library() -> list[Drill]:
    return (warmup_family() + receive2_family() + feed_family()
            + attack_family() + spike_family() + defence_family()
            + cover_family() + serve_family() + tekong_family()
            + game_family() + gaps_family())

TEKONG_NAME = {
    "en": "Tekong serve", "en-GB": "Tekong serve", "zh-CN": "发球手发球",
    "zh-TW": "發球手發球", "ja-JP": "テコンのサーブ", "ko-KR": "테콩 서브",
    "es-ES": "Saque del tekong", "fr-FR": "Service du tekong",
    "id-ID": "Servis tekong", "ms-MY": "Servis tekong",
    "th-TH": "ลูกเสิร์ฟของตัวเสิร์ฟ", "vi-VN": "Giao cầu tekong",
}
TEKONG_NOTE = {
    "en": "The toss is the serve. The inside player throws it to the same "
          "spot every time, and the tekong's kicking foot does the rest.",
    "en-GB": "The toss is the serve. The inside player throws it to the same "
             "spot every time, and the tekong's kicking foot does the rest.",
    "zh-CN": "抛球就是发球。内场球员每次抛到同一个点，剩下的交给发球手那只脚。",
    "zh-TW": "拋球就是發球。內場球員每次拋到同一個點，剩下的交給發球手那隻腳。",
    "ja-JP": "トスがサーブそのものだ。インサイドは毎回同じ点へ投げる。あとはテコンの足がやってくれる。",
    "ko-KR": "토스가 곧 서브다. 인사이드는 매번 같은 지점에 던지고, 나머지는 테콩의 발이 한다.",
    "es-ES": "El lanzamiento es el saque: el interior lo lanza siempre al "
             "mismo punto y el pie del tekong hace el resto.",
    "fr-FR": "Le lancer est le service : l'intérieur le lance toujours au "
             "même point, le pied du tekong fait le reste.",
    "id-ID": "Lambungan adalah servisnya — pelambung selalu ke titik yang sama.",
    "ms-MY": "Lambungan ialah servisnya — pelambung sentiasa ke titik sama.",
    "th-TH": "การโยนคือการเสิร์ฟ คนโยนต้องโยนจุดเดิมทุกครั้ง ที่เหลือเป็นหน้าที่ของเท้าตัวเสิร์ฟ",
    "vi-VN": "Cú tung chính là cú giao — người tung phải tung đúng một điểm.",
}


def tekong_family() -> list[Drill]:
    """The serve from the server's side: the toss-kick partnership. The
    inside player in his quarter circle tosses to the tekong, the tekong
    strikes it from the circle, and the far side returns it."""
    # The tosser must have a foot in his quarter circle when he throws; he
    # used to stand beside the tekong, four metres outside it. Named by the
    # side he stands on: the near team faces up, so its left is screen-left.
    specs = [("high_toss", "off the high toss", QUARTER_L, "L", QUARTER_R, "R"),
             ("low_drive", "driven low", QUARTER_R, "R", QUARTER_L, "L")]
    out = []
    for key, label, thrower, tlab, other, olab in specs:
        drop = lambda q: (0.5 + (q[0] - 0.5) * 0.55, 0.63)
        out.append(Drill(
            id=f"st_tekong_{key}", category="setpiece", minutes=10, rel=True,
            free=(key == "high_toss"),
            name=suffixed(TEKONG_NAME, label), note=TEKONG_NOTE,
            home=[P(*TEKONG, "T", moves=[(0.50, 0.78, 2)]),
                  P(*thrower, tlab, moves=[drop(thrower) + (1,)]),
                  P(*other, olab, moves=[drop(other) + (1,)])],
            away=[P(0.50, 0.24, "D", moves=[(0.44, 0.16 if key == "high_toss"
                                             else 0.30, 1)])],
            markers=[M(*TEKONG, "circle", "")],
            ball=1,
            # toss, serve, the return to the inside player who threw it
            ball_to=[(0, 0), ("a0", 1), (1, 2)],
        ))
    return out


RECEIVE2_NAME = {
    "en": "Serve receive", "en-GB": "Serve receive", "zh-CN": "接发球",
    "zh-TW": "接發球", "ja-JP": "サーブレシーブ", "ko-KR": "서브 리시브",
    "es-ES": "Recepción de saque", "fr-FR": "Réception de service",
    "id-ID": "Terima servis", "ms-MY": "Terima servis",
    "th-TH": "การรับเสิร์ฟ", "vi-VN": "Đỡ giao cầu",
}
RECEIVE2_NOTE = {
    "en": "Receive with the inside of the foot and cushion upward — the first "
          "touch has to hang long enough for the feeder to reach it.",
    "en-GB": "Receive with the inside of the foot and cushion upward — the "
             "first touch has to hang long enough for the feeder to reach it.",
    "zh-CN": "用脚内侧接，向上卸力——一传要在空中停留得够久，让二传的人来得及赶到。",
    "zh-TW": "用腳內側接，向上卸力——一傳要在空中停留得夠久，讓二傳的人來得及趕到。",
    "ja-JP": "足の内側で受けて上へ吸収する。1タッチ目はトサーが間に合う高さまで浮かせる。",
    "ko-KR": "발 안쪽으로 받아 위로 죽여라 — 첫 터치는 토서가 닿을 만큼 떠 있어야 한다.",
    "es-ES": "Recibe con el interior del pie y amortigua hacia arriba: el "
             "primer toque debe flotar hasta que llegue el pasador.",
    "fr-FR": "Reçois de l'intérieur du pied en amortissant vers le haut : la "
             "première touche doit flotter le temps que le passeur arrive.",
    "id-ID": "Terima dengan kaki bagian dalam dan redam ke atas.",
    "ms-MY": "Terima dengan bahagian dalam kaki dan redam ke atas.",
    "th-TH": "รับด้วยข้างเท้าด้านในและผ่อนขึ้นบน ลูกแรกต้องลอยนานพอให้คนชงมาถึง",
    "vi-VN": "Đỡ bằng lòng bàn chân và hoãn lực lên cao.",
}


def receive2_family() -> list[Drill]:
    # 1 receives where the drill says — on the left or the right, not in
    # front of his own tekong — and plays it up to 2 on the square.
    specs = [("left", "on the left", 0.26), ("right", "on the right", 0.74)]
    out = []
    for key, label, x in specs:
        out.append(Drill(
            id=f"st_receive_{key}", category="possession", minutes=10, rel=True,
            free=(key == "left"),
            name=suffixed(RECEIVE2_NAME, label), note=RECEIVE2_NOTE,
            home=[P(x, 0.76, "1", moves=[(x, 0.70, 0)]),
                  P(1 - x, 0.62, "2", moves=[FEED_POINT + (1,)]),
                  P(*TEKONG, "T", moves=[(0.50, 0.78, 1)])],
            away=[P(*AWAY_TEKONG, "t")],
            markers=[M(*FEED_POINT, "square", "")],
            ball=AWAY_TEKONG,
            # the serve comes over to 1, the first touch goes up to the
            # square, where 2 takes it
            ball_to=[(0, 0), (1, 1)],
        ))
    return out


COVER_NAME = {
    "en": "Covering the spike", "en-GB": "Covering the spike",
    "zh-CN": "保护补位", "zh-TW": "保護補位", "ja-JP": "スパイクカバー",
    "ko-KR": "스파이크 커버", "es-ES": "Cobertura del remate",
    "fr-FR": "Couverture de l'attaque", "id-ID": "Menutup smes",
    "ms-MY": "Menutup rejaman", "th-TH": "การคุมลูกฟาดกลับ",
    "vi-VN": "Bọc lót cú đá",
}
COVER_NOTE = {
    "en": "The block sends the ball straight down on your own side more often "
          "than over — two players crouch under your own spiker, every time.",
    "en-GB": "The block sends the ball straight down on your own side more "
             "often than over — two players crouch under your own spiker, every time.",
    "zh-CN": "被拦回来的球多数直坠在本方场内——每一次进攻，都要有两个人蹲在自己攻手身后。",
    "zh-TW": "被攔回來的球多數直墜在本方場內——每一次進攻，都要有兩個人蹲在自己攻手身後。",
    "ja-JP": "ブロックされた球は越えるより自陣に真下に落ちることの方が多い。毎回、自分のアタッカーの下に2人が沈む。",
    "ko-KR": "블록된 공은 넘어가기보다 자기 쪽에 수직으로 떨어진다. 매번 두 명이 자기 공격수 밑에 앉아라.",
    "es-ES": "El bloqueo devuelve la bola en vertical a tu campo más veces de "
             "las que pasa: dos jugadores agachados bajo vuestro rematador, siempre.",
    "fr-FR": "Le contre renvoie la balle à la verticale chez toi plus souvent "
             "qu'il ne passe : deux joueurs accroupis sous votre attaquant, à chaque fois.",
    "id-ID": "Bola yang diblok lebih sering jatuh tegak di sisi sendiri.",
    "ms-MY": "Bola yang disekat lebih kerap jatuh tegak di pihak sendiri.",
    "th-TH": "ลูกที่โดนบล็อกมักตกดิ่งฝั่งตัวเอง ต้องมีสองคนย่อรอใต้ตัวฟาดทุกครั้ง",
    "vi-VN": "Bóng bị chắn thường rơi thẳng xuống sân mình — hai người phải chùng sẵn dưới chân đá.",
}


def cover_family() -> list[Drill]:
    return [Drill(
        # The one attack drill where the spike meets the block on purpose:
        # F sets, S hits into B, the block drops it on our side and T, who
        # was crouched under the spiker, plays the rebound up.
        id="st_cover_spike", category="defending", minutes=10, rel=True,
        free=True,
        name=suffixed(COVER_NAME, "behind your own attack"), note=COVER_NOTE,
        home=[P(*RIGHT_INSIDE, "S", moves=[(0.62, 0.54, 0)]),
              P(*LEFT_INSIDE, "F", moves=[(0.52, 0.62, 1)]),
              P(*TEKONG, "T", moves=[(0.66, 0.66, 0)])],
        away=[P(0.62, 0.47, "B", moves=[(0.62, 0.455, 1)])],
        ball=1, ball_to=[(0, 0), ("a0", 1), (2, 2)],
    ), Drill(
        # The far side receives deep: the serve goes to the back half, not
        # at an inside player hugging the net.
        id="st_game_regu", category="ssg", minutes=20, rel=True, free=True,
        name=suffixed(GAME_NAME, {
            "en": "full regu", "en-GB": "full regu", "zh-CN": "三人制整队对抗",
            "zh-TW": "三人制整隊對抗", "ja-JP": "レグ戦", "ko-KR": "레구 경기",
            "es-ES": "regu completo", "fr-FR": "regu complet",
            "id-ID": "regu penuh", "ms-MY": "regu penuh",
            "th-TH": "เรกูเต็มทีม", "vi-VN": "regu đầy đủ"}), note=GAME_REGU_NOTE,
        home=[P(*QUARTER_L, "L", moves=[(0.28, 0.62, 1)]),
              P(*QUARTER_R, "R", moves=[(0.72, 0.62, 1)]),
              P(*TEKONG, "T")],
        away=[P(0.72, 0.30, "l", moves=[(0.54, 0.42, 2)]),
              P(0.28, 0.28, "r", moves=[(0.26, 0.24, 1), (0.40, 0.44, 3)]),
              P(*AWAY_TEKONG, "t")],
        ball=0, ball_to=[(2, 0), ("a1", 1), ("a0", 2), ("a1", 3),
                         (Spot(0.66, 0.76), 4)],
    )]


