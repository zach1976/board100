"""The sepak takraw library.

Three a side on a badminton-sized court, net at y=0.5, home at the bottom.
A regu is a tekong who serves from the back circle and two inside players who
receive, feed and attack — so almost every drill is those three roles doing
their part of the same three touches.
"""
from .engine import Drill, M, P, suffixed

TEKONG = (0.50, 0.86)
LEFT_INSIDE, RIGHT_INSIDE = (0.28, 0.64), (0.72, 0.64)
FEED_POINT = (0.50, 0.58)
NET = 0.5


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
        else:
            home = [P(0.34, 0.72, "1", moves=[(0.38, 0.66, 0)]),
                    P(0.66, 0.72, "2", moves=[(0.62, 0.66, 0)])]
        out.append(Drill(
            id=f"st_warm_{key}", category="warmup", minutes=8, rel=True,
            free=(key in ("juggling", "keep_up")),
            name=suffixed(WARM_NAME, label), note=WARM_NOTE,
            home=home, ball=0,
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
            home=[P(*receiver, "R", moves=[(receiver[0], receiver[1] - 0.06, 0)]),
                  P(*LEFT_INSIDE, "F", moves=[target + (1,)]),
                  P(*RIGHT_INSIDE, "S", moves=[(target[0] + 0.10, 0.54, 2)])],
            away=[P(0.50, 0.14, "T", moves=[(0.50, 0.22, 0)])],
            markers=[M(*target, "square", "")],
            ball=(0.50, 0.14),
        ))
    return out


SPIKE_NAME = {
    "en": "Spiking", "en-GB": "Spiking", "zh-CN": "扣球", "zh-TW": "扣球",
    "ja-JP": "アタック", "ko-KR": "스파이크", "es-ES": "Remate",
    "fr-FR": "Attaque", "id-ID": "Smes", "ms-MY": "Rejaman",
    "th-TH": "การฟาด", "vi-VN": "Đá tấn công",
}
SPIKE_NOTE = {
    "en": "Get the hips above the ball before the foot swings. Height comes "
          "from the jump, not from kicking harder at the top.",
    "en-GB": "Get the hips above the ball before the foot swings. Height comes "
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


def spike_family() -> list[Drill]:
    specs = [("roll", "the roll spike", (0.30, 0.24)),
             ("scissor", "the scissor kick", (0.70, 0.22)),
             ("sunback", "the sunback spike", (0.50, 0.16))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"st_spike_{key}", category="finishing", minutes=12, rel=True,
            free=(key == "roll"),
            name=suffixed(SPIKE_NAME, label), note=SPIKE_NOTE,
            home=[P(*RIGHT_INSIDE, "S", moves=[(0.58, 0.54, 1)]),
                  P(*LEFT_INSIDE, "F", moves=[FEED_POINT + (0,)])],
            away=[P(0.56, 0.46, "B", moves=[(0.58, 0.455, 1)]),
                  P(land[0], land[1] - 0.06, "D", moves=[(land[0], land[1], 2)])],
            markers=[M(*land, "zone", "")],
            ball=0,
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
    specs = [("straight", "straight", (0.72, 0.22)),
             ("cross-court", "cross-court", (0.24, 0.26)),
             ("the feint", "the feint", (0.62, 0.42))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"st_attack_{key.replace('-', '_').replace(' ', '_')}",
            category="attacking", minutes=10, rel=True,
            free=(key == "straight"),
            name=suffixed(ATTACK_NAME, label), note=ATTACK_NOTE,
            home=[P(*RIGHT_INSIDE, "S", moves=[(0.62, 0.54, 1)]),
                  P(*LEFT_INSIDE, "F", moves=[FEED_POINT + (0,)]),
                  P(*TEKONG, "T", moves=[(0.50, 0.76, 1)])],
            away=[P(0.62, 0.46, "B"),
                  P(land[0], land[1] - 0.05, "D", moves=[(land[0], land[1], 2)])],
            markers=[M(*land, "zone", "")],
            ball=0,
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
    specs = [("at the net", "at the net", (0.68, 0.56)),
             ("behind the block", "behind the block", (0.40, 0.72)),
             ("covering the block", "covering the block", (0.30, 0.60))]
    out = []
    for key, label, spot in specs:
        out.append(Drill(
            id=f"st_defence_{key.replace(' ', '_')}", category="defending",
            minutes=10, rel=True, free=(key != "covering the block"),
            name=suffixed(DEF_NAME, label), note=DEF_NOTE,
            home=[P(0.58, 0.53, "B", moves=[(0.58, 0.515, 1)]),
                  P(*spot, "D", moves=[(spot[0] - 0.04, spot[1] + 0.04, 1)]),
                  P(*TEKONG, "T", moves=[(0.46, 0.80, 1)])],
            away=[P(0.60, 0.36, "S", moves=[(0.60, 0.46, 1)]),
                  P(0.36, 0.30, "F", moves=[(0.44, 0.40, 0)])],
            ball=1,
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
    "th-TH": "ลูกเสิร์ฟของเทกงคือการบุกอย่างเดียวที่ไม่มีใครบล็อก",
    "vi-VN": "Cú giao của tekong là đòn tấn công duy nhất không ai chắn.",
}


def serve_family() -> list[Drill]:
    specs = [("deep", "deep", (0.50, 0.06)), ("at the seam", "at the seam", (0.36, 0.28)),
             ("short", "short", (0.62, 0.42))]
    out = []
    for key, label, land in specs:
        out.append(Drill(
            id=f"st_serve_{key.replace(' ', '_')}", category="setpiece",
            minutes=8, rel=True, free=(key == "deep"),
            name=suffixed(SERVE_NAME, label), note=SERVE_NOTE,
            # The inside players start in the quarter circles at the net —
            # that is where the rules put them for the serve; mid-court is
            # where they drop to once it is away.
            home=[P(*TEKONG, "T", moves=[(0.50, 0.80, 1)]),
                  P(0.12, 0.54, "L", moves=[(0.34, 0.60, 0)]),
                  P(0.88, 0.54, "R", moves=[(0.66, 0.60, 0)])],
            away=[P(land[0], land[1] - 0.06, "D", moves=[(land[0], land[1], 1)])],
            markers=[M(*TEKONG, "circle", ""), M(*land, "zone", "")],
            ball=0,
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


def game_family() -> list[Drill]:
    specs = [("2v2", "2v2", [(0.34, 0.68), (0.66, 0.68)]),
             ("3v3", "3v3", [LEFT_INSIDE, RIGHT_INSIDE, TEKONG]),
             ("no_block", "with no block", [LEFT_INSIDE, RIGHT_INSIDE, TEKONG])]
    out = []
    for key, label, spots in specs:
        out.append(Drill(
            id=f"st_game_{key}", category="ssg", minutes=15, rel=True,
            free=(key in ("2v2", "3v3")),
            name=suffixed(GAME_NAME, label), note=GAME_NOTE,
            home=[P(x, y, str(i + 1), moves=[(x, y - 0.04, 0)])
                  for i, (x, y) in enumerate(spots)],
            away=[P(*mirror((x, y)), chr(65 + i), moves=[(x, 1 - y + 0.04, 0)])
                  for i, (x, y) in enumerate(spots)],
            ball=0,
        ))
    return out


def sepak_takraw_library() -> list[Drill]:
    return (warmup_family() + feed_family() + attack_family()
            + spike_family() + defence_family() + serve_family()
            + game_family())
