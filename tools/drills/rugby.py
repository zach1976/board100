"""The rugby library.

Every board attacks UP the page. The drawing includes both in-goals, so the
board is 70 m across and 144 m long, and everything here is written in
METRES: x from the left touchline (0..70), y from the top dead-ball line
(0..144). The try line being attacked is y=22, their 22 is y=44, their 10 m
line y=62, halfway y=72, our 10 m line y=82, our 22 y=100, our try line
y=122. The 5 m and 15 m lines run at x=5/15 and x=55/65.

Three laws the boards are held to, by tools/check_rugby_passes.py:

* No pass goes forward. A receiver catches the ball where he is at the end
  of the beat, so every receiver starts deeper than the passer by more than
  he runs during the pass — the line is staggered, each man a few metres
  behind the one inside him, and he runs ONTO the ball from depth.
* A try is grounded: the scorer carries it into the in-goal. The ball never
  flies into the in-goal on its own except off a place kick at goal.
* A kick has a kicker, and the chasers start level with him or behind him.

A drawn figure is about 4-5 m wide and 8-11 m tall at this scale, so a
scrum or a maul cannot be drawn at true spacing at the whole pitch's
scale; those boards are tight=True and keep the shape (single files, a
3-4-1 pack) at the closest spacing at which the numbers can still be read.
The lineouts (and the mauls that start from one) are drawn at Law 18's
true spacing instead and open on a close-up of it (Drill.view — the
board's viewWindow; see _lineout).
"""
from .engine import Drill, M, P, Spot, suffixed
from .vocab import V

W, L = 70.0, 144.0
TRY_Y = 22.0          # the try line being attacked


def mk(x, y, shape="cone") -> M:
    return M(x / W, y / L, shape, "")


def spot(x, y) -> Spot:
    """A place on the grass, exactly: a kick's landing, the ball placed back."""
    return Spot(x / W, y / L)


def pt(x, y) -> tuple:
    return (x / W, y / L)


class Board:
    """Players written in metres, their runs beat by beat.

    put() places a man; go() moves him on a beat; shift() moves several by
    the same amount. Anyone not moved on a beat stands still. players()
    hands back engine P objects in the order asked for.
    """

    def __init__(self):
        self.start, self.at, self.moves = {}, {}, {}

    def put(self, key, x, y):
        self.start[key] = self.at[key] = (x, y)
        self.moves[key] = []

    def go(self, key, x, y, beat):
        self.moves[key].append((x, y, beat))
        self.at[key] = (x, y)

    def shift(self, keys, dx, dy, beat):
        for k in keys:
            x, y = self.at[k]
            self.go(k, x + dx, y + dy, beat)

    def x(self, key):
        return self.at[key][0]

    def y(self, key):
        return self.at[key][1]

    def players(self, keys) -> list:
        out = []
        for k in keys:
            sx, sy = self.start[k]
            out.append(P(sx / W, sy / L, k.split("#")[0],
                         moves=[(mx / W, my / L, ph)
                                for (mx, my, ph) in self.moves[k]]))
        return out


# Variant halves that read as a heading and its subject — "Set piece — the
# scrum", not "Set piece the scrum". The shared vocabulary keeps the
# translation; the dash goes in where the languages glue with a space.
_DASH = ("en", "en-GB", "es-ES", "fr-FR", "id-ID", "ms-MY", "vi-VN")


def dashed(variant) -> dict:
    d = dict(V[variant] if isinstance(variant, str) else variant)
    for loc in _DASH:
        d[loc] = "— " + d[loc]
    return d


def _t12(en, zh, zht, ja, ko, es, fr, idn, ms, th, vi) -> dict:
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht, "ja-JP": ja,
            "ko-KR": ko, "es-ES": es, "fr-FR": fr, "id-ID": idn,
            "ms-MY": ms, "th-TH": th, "vi-VN": vi}
HANDLE_NAME = {
    "en": "Handling", "en-GB": "Handling", "zh-CN": "传接球", "zh-TW": "傳接球",
    "ja-JP": "ハンドリング", "ko-KR": "핸들링", "es-ES": "Manejo de balón",
    "fr-FR": "Maniement du ballon", "id-ID": "Penguasaan bola",
    "ms-MY": "Pengendalian bola", "th-TH": "การรับส่งบอล", "vi-VN": "Xử lý bóng",
}
HANDLE_NOTE = {
    "en": "Pass in front of the receiver's chest so they run onto it. A pass "
          "behind them turns a runner into a catcher.",
    "en-GB": "Pass in front of the receiver's chest so they run onto it. A "
             "pass behind them turns a runner into a catcher.",
    "zh-CN": "传到接球人胸前偏前的位置，让他跑起来接。传到身后，就把一个跑动的人变成了一个接球的人。",
    "zh-TW": "傳到接球人胸前偏前的位置，讓他跑起來接。傳到身後，就把一個跑動的人變成了一個接球的人。",
    "ja-JP": "受け手の胸の前へ、走り込めるように放る。後ろへのパスは、ランナーをキャッチャーに変えてしまう。",
    "ko-KR": "받는 사람 가슴 앞으로 던져 달려들게 하라. 뒤로 간 패스는 러너를 캐처로 만든다.",
    "es-ES": "Pasa delante del pecho para que corra al balón: un pase atrás "
             "convierte a un corredor en un receptor.",
    "fr-FR": "Passe devant la poitrine pour qu'il coure dessus : une passe "
             "derrière transforme un coureur en réceptionneur.",
    "id-ID": "Umpan di depan dada penerima agar ia berlari menyongsongnya.",
    "ms-MY": "Hantar di hadapan dada penerima supaya dia berlari menyambutnya.",
    "th-TH": "ส่งไปข้างหน้าอกคนรับ เพื่อให้เขาวิ่งเข้าหาบอล",
    "vi-VN": "Chuyền trước ngực người nhận để họ chạy vào bóng.",
}


PHASE_NAME = {
    "en": "Phase play", "en-GB": "Phase play", "zh-CN": "多波次进攻",
    "zh-TW": "多波次進攻", "ja-JP": "フェーズ攻撃", "ko-KR": "페이즈 플레이",
    "es-ES": "Juego por fases", "fr-FR": "Jeu au sol enchaîné",
    "id-ID": "Permainan berfase", "ms-MY": "Permainan berfasa",
    "th-TH": "การบุกต่อเนื่อง", "vi-VN": "Tấn công nhiều đợt",
}
PHASE_NOTE = {
    "en": "Get the shape set before the ball arrives, not while it is coming. "
          "A pod still forming when the nine looks up is a pod that isn't there.",
    "en-GB": "Get the shape set before the ball arrives, not while it is "
             "coming. A pod still forming when the nine looks up is a pod that isn't there.",
    "zh-CN": "球到之前站好位，不是球在路上才站。传球手抬头时还在集结的那一组，就等于不存在。",
    "zh-TW": "球到之前站好位，不是球在路上才站。傳球手抬頭時還在集結的那一組，就等於不存在。",
    "ja-JP": "ボールが来る前に形を作る。9番が顔を上げた時にまだ組んでいるポッドは、いないのと同じ。",
    "ko-KR": "공이 오기 전에 형태를 잡아라. 9번이 고개를 들 때 아직 모이고 있는 포드는 없는 포드다.",
    "es-ES": "Formad antes de que llegue el balón: un pod que aún se arma "
             "cuando el 9 levanta la cabeza es un pod que no existe.",
    "fr-FR": "Mets la structure en place avant l'arrivée du ballon : un pod qui "
             "se forme encore quand le 9 lève la tête n'existe pas.",
    "id-ID": "Bentuk formasi sebelum bola datang, bukan sambil menunggu.",
    "ms-MY": "Bentuk formasi sebelum bola tiba.",
    "th-TH": "จัดรูปให้เสร็จก่อนบอลมาถึง",
    "vi-VN": "Sắp đội hình xong trước khi bóng tới.",
}


MOVE_NAME = {
    "en": "Backline move", "en-GB": "Backline move", "zh-CN": "后卫线配合",
    "zh-TW": "後衛線配合", "ja-JP": "バックスのサインプレー", "ko-KR": "백스 사인 플레이",
    "es-ES": "Jugada de tres cuartos", "fr-FR": "Combinaison de trois-quarts",
    "id-ID": "Pola barisan belakang", "ms-MY": "Pergerakan barisan belakang",
    "th-TH": "แผนแนวหลัง", "vi-VN": "Bài phối hợp tuyến sau",
}
MOVE_NOTE = {
    "en": "Every move is a lie about where the ball is going. Sell it with the "
          "first runner's line, or the defence never has to believe anything.",
    "en-GB": "Every move is a lie about where the ball is going. Sell it with "
             "the first runner's line, or the defence never has to believe anything.",
    "zh-CN": "每一个配合都是关于球去哪的一个谎。要靠第一个跑动的人把它演真，否则防守根本不用相信任何东西。",
    "zh-TW": "每一個配合都是關於球去哪的一個謊。要靠第一個跑動的人把它演真，否則防守根本不用相信任何東西。",
    "ja-JP": "サインプレーはすべて「ボールの行き先」についての嘘だ。最初のランナーのラインで信じ込ませなければ、守備は何も信じずに済む。",
    "ko-KR": "모든 사인 플레이는 공이 어디로 가는지에 대한 거짓말이다. 첫 러너의 라인으로 팔지 못하면 수비는 믿을 필요가 없다.",
    "es-ES": "Toda jugada es una mentira sobre dónde va el balón: véndela con "
             "la línea del primer corredor o la defensa no tendrá que creerse nada.",
    "fr-FR": "Chaque combinaison est un mensonge sur la destination du ballon : "
             "vends-le avec la course du premier, sinon la défense n'a rien à croire.",
    "id-ID": "Setiap pola adalah kebohongan tentang ke mana bola pergi.",
    "ms-MY": "Setiap pergerakan ialah penipuan tentang ke mana bola pergi.",
    "th-TH": "ทุกแผนคือการโกหกว่าบอลจะไปทางไหน",
    "vi-VN": "Mỗi bài phối hợp là một lời nói dối về hướng bóng.",
}


FINISH_NAME = {
    "en": "Finishing", "en-GB": "Finishing", "zh-CN": "达阵终结",
    "zh-TW": "達陣終結", "ja-JP": "フィニッシュ", "ko-KR": "마무리",
    "es-ES": "Finalización", "fr-FR": "Finition", "id-ID": "Penyelesaian",
    "ms-MY": "Penamat", "th-TH": "การจบสกอร์", "vi-VN": "Kết thúc",
}
FINISH_NOTE = {
    "en": "Score under the posts if you can — the two points after are worth "
          "the extra second it costs to get there.",
    "en-GB": "Score under the posts if you can — the two points after are "
             "worth the extra second it costs to get there.",
    "zh-CN": "能压到门柱正下方就压过去——后面那两分，值得你多花那一秒。",
    "zh-TW": "能壓到門柱正下方就壓過去——後面那兩分，值得你多花那一秒。",
    "ja-JP": "可能ならポスト下でトライする。その後の2点は、余分にかかる1秒に見合う。",
    "ko-KR": "가능하면 골포스트 아래에 찍어라. 이후 2점은 그 1초의 값어치가 있다.",
    "es-ES": "Ensaya bajo palos si puedes: los dos puntos posteriores valen el "
             "segundo extra que cuesta llegar ahí.",
    "fr-FR": "Aplatis sous les poteaux si tu peux : les deux points d'après "
             "valent la seconde supplémentaire.",
    "id-ID": "Cetak di bawah tiang jika bisa.",
    "ms-MY": "Jaringkan di bawah tiang jika boleh.",
    "th-TH": "ถ้าทำได้ให้วางบอลใต้เสาประตู",
    "vi-VN": "Nếu được, hãy ghi điểm ngay dưới cột.",
}


DEF_NAME = {
    "en": "Defence", "en-GB": "Defence", "zh-CN": "防守", "zh-TW": "防守",
    "ja-JP": "ディフェンス", "ko-KR": "수비", "es-ES": "Defensa",
    "fr-FR": "Défense", "id-ID": "Pertahanan", "ms-MY": "Pertahanan",
    "th-TH": "การรับ", "vi-VN": "Phòng thủ",
}
DEF_NOTE = {
    "en": "Come up as a line and stay connected. One defender out of the wall "
          "is a hole, however good their tackle would have been.",
    "en-GB": "Come up as a line and stay connected. One defender out of the "
             "wall is a hole, however good their tackle would have been.",
    "zh-CN": "整条线一起上，保持连着。有一个人冒出防线，那就是一个洞——不管他这次擒抱本来会多漂亮。",
    "zh-TW": "整條線一起上，保持連著。有一個人冒出防線，那就是一個洞——不管他這次擒抱本來會多漂亮。",
    "ja-JP": "ラインで上がり、切れない。壁から飛び出した一人は穴だ。そのタックルがどれほど良くても。",
    "ko-KR": "한 줄로 올라가고 끊기지 마라. 벽에서 튀어나온 한 명은 구멍이다.",
    "es-ES": "Subid como una línea y sin desconectaros: un defensor fuera del "
             "muro es un agujero, por buena que fuera su placada.",
    "fr-FR": "Montez en ligne et restez liés : un défenseur sorti du mur est "
             "un trou, si bon qu'aurait été son plaquage.",
    "id-ID": "Naik sebagai satu garis dan tetap terhubung.",
    "ms-MY": "Naik sebagai satu barisan dan kekal berhubung.",
    "th-TH": "ขึ้นเป็นแนวเดียวกันและอย่าให้ขาด",
    "vi-VN": "Dâng lên thành một tuyến và không để đứt.",
}


SET_NAME = {
    "en": "Set piece", "en-GB": "Set piece", "zh-CN": "定位球", "zh-TW": "定位球",
    "ja-JP": "セットプレー", "ko-KR": "세트피스", "es-ES": "Jugada a balón parado",
    "fr-FR": "Phase statique", "id-ID": "Bola mati", "ms-MY": "Bola mati",
    "th-TH": "ลูกตั้งเตะ", "vi-VN": "Tình huống cố định",
}
SET_NOTE = {
    "en": "Win the ball first, then run the play. A clever move off slow "
          "possession is a slow move.",
    "en-GB": "Win the ball first, then run the play. A clever move off slow "
             "possession is a slow move.",
    "zh-CN": "先赢下球，再跑战术。慢球权上的聪明配合，就是一个慢配合。",
    "zh-TW": "先贏下球，再跑戰術。慢球權上的聰明配合，就是一個慢配合。",
    "ja-JP": "まずボールを獲る、それからプレーを走る。遅い球出しからの巧いサインは、ただの遅いサインだ。",
    "ko-KR": "먼저 공을 따내고 나서 플레이를 돌려라. 느린 볼에서 나온 영리한 사인은 그냥 느린 사인이다.",
    "es-ES": "Gana el balón primero y luego juega: una jugada ingeniosa con "
             "posesión lenta es una jugada lenta.",
    "fr-FR": "Gagne le ballon d'abord, joue ensuite : une combinaison maligne "
             "sur ballon lent est une combinaison lente.",
    "id-ID": "Menangkan bolanya dulu, baru jalankan pola.",
    "ms-MY": "Menangi bola dahulu, kemudian jalankan pola.",
    "th-TH": "ชนะบอลก่อน แล้วค่อยเล่นแผน",
    "vi-VN": "Giành bóng trước, rồi mới chạy bài.",
}


KICK_NAME = {
    "en": "Kicking", "en-GB": "Kicking", "zh-CN": "踢球战术", "zh-TW": "踢球戰術",
    "ja-JP": "キック", "ko-KR": "킥", "es-ES": "Juego al pie",
    "fr-FR": "Jeu au pied", "id-ID": "Tendangan", "ms-MY": "Sepakan",
    "th-TH": "การเตะ", "vi-VN": "Đá bóng",
}
KICK_NOTE = {
    "en": "A kick with nobody chasing is a pass to the opposition. Send the "
          "chase before you send the ball.",
    "en-GB": "A kick with nobody chasing is a pass to the opposition. Send the "
             "chase before you send the ball.",
    "zh-CN": "没人追的踢球，就是传给对手的一次传球。先把追击的人放出去，再把球踢出去。",
    "zh-TW": "沒人追的踢球，就是傳給對手的一次傳球。先把追擊的人放出去，再把球踢出去。",
    "ja-JP": "誰も追わないキックは相手へのパスだ。ボールより先にチェイスを走らせる。",
    "ko-KR": "아무도 쫓지 않는 킥은 상대에게 주는 패스다. 공보다 체이스를 먼저 보내라.",
    "es-ES": "Una patada sin persecución es un pase al rival: manda la caza "
             "antes que el balón.",
    "fr-FR": "Un coup de pied sans chasse est une passe à l'adversaire : "
             "envoie les chasseurs avant le ballon.",
    "id-ID": "Tendangan tanpa pengejar adalah umpan untuk lawan.",
    "ms-MY": "Sepakan tanpa pengejar ialah hantaran kepada lawan.",
    "th-TH": "ลูกเตะที่ไม่มีคนไล่คือการจ่ายให้คู่แข่ง",
    "vi-VN": "Cú đá không ai đuổi theo là đường chuyền cho đối thủ.",
}


BREAKDOWN_NAME = {
    "en": "Breakdown", "en-GB": "Breakdown", "zh-CN": "争球点",
    "zh-TW": "爭球點", "ja-JP": "ブレイクダウン", "ko-KR": "브레이크다운",
    "es-ES": "Ruck", "fr-FR": "Le regroupement", "id-ID": "Ruck",
    "ms-MY": "Ruck", "th-TH": "จุดปะทะ", "vi-VN": "Điểm tranh chấp",
}
BREAKDOWN_NOTE = {
    "en": "First support arrives low and past the ball. Arriving upright and "
          "beside it is how a ruck becomes a turnover.",
    "en-GB": "First support arrives low and past the ball. Arriving upright "
             "and beside it is how a ruck becomes a turnover.",
    "zh-CN": "第一个支援要压低身体、越过球再发力。站直了停在球边上，争球点就变成了丢球。",
    "zh-TW": "第一個支援要壓低身體、越過球再發力。站直了停在球邊上，爭球點就變成了丟球。",
    "ja-JP": "最初のサポートは低く、ボールを越えて入る。立ったまま横に着くから、ラックがターンオーバーになる。",
    "ko-KR": "첫 서포트는 낮게, 공을 지나쳐 들어간다. 선 채로 옆에 붙으면 럭이 턴오버가 된다.",
    "es-ES": "El primer apoyo llega bajo y pasado el balón: llegar erguido y "
             "al lado es como un ruck se convierte en pérdida.",
    "fr-FR": "Le premier soutien arrive bas et au-delà du ballon : arriver "
             "debout à côté, c'est transformer le ruck en turnover.",
    "id-ID": "Bantuan pertama datang rendah dan melewati bola.",
    "ms-MY": "Sokongan pertama datang rendah dan melepasi bola.",
    "th-TH": "คนช่วยคนแรกต้องเข้าต่ำและเลยบอลไป",
    "vi-VN": "Người hỗ trợ đầu vào thấp và vượt qua bóng.",
}


GAME_NAME = {
    "en": "Game", "en-GB": "Game", "zh-CN": "对抗", "zh-TW": "對抗",
    "ja-JP": "ゲーム", "ko-KR": "게임", "es-ES": "Juego", "fr-FR": "Jeu",
    "id-ID": "Permainan", "ms-MY": "Permainan", "th-TH": "เกม", "vi-VN": "Trận đấu",
}
GAME_NOTE = {
    "en": "Narrow the pitch and the offload appears; widen it and the kick "
          "does. Choose the width for the skill you came to coach.",
    "en-GB": "Narrow the pitch and the offload appears; widen it and the kick "
             "does. Choose the width for the skill you came to coach.",
    "zh-CN": "场地窄，传递就出来了；场地宽，踢球就出来了。按你今天要练的技术来定宽度。",
    "zh-TW": "場地窄，傳遞就出來了；場地寬，踢球就出來了。按你今天要練的技術來定寬度。",
    "ja-JP": "幅を狭めればオフロードが、広げればキックが出てくる。今日教えたいスキルで幅を決める。",
    "ko-KR": "좁히면 오프로드가, 넓히면 킥이 나온다. 가르치려는 기술에 맞춰 폭을 정하라.",
    "es-ES": "Estrecha el campo y aparece el offload; ensánchalo y aparece la "
             "patada. Elige el ancho según la destreza que vienes a entrenar.",
    "fr-FR": "Rétrécis le terrain et l'offload apparaît ; élargis-le et le jeu "
             "au pied revient. Choisis la largeur selon l'habileté visée.",
    "id-ID": "Sempitkan lapangan maka offload muncul; lebarkan maka tendangan muncul.",
    "ms-MY": "Sempitkan padang maka offload muncul; luaskan maka sepakan muncul.",
    "th-TH": "แคบสนามแล้วออฟโหลดจะมา กว้างสนามแล้วลูกเตะจะมา",
    "vi-VN": "Thu hẹp sân thì có offload; mở rộng thì có đá bóng.",
}


TACKLE_NAME = {"en": "Tackling", "en-GB": "Tackling", "zh-CN": "擒抱",
               "zh-TW": "擒抱", "ja-JP": "タックル", "ko-KR": "태클",
               "es-ES": "El placaje", "fr-FR": "Le plaquage",
               "id-ID": "Tekel", "ms-MY": "Tekel", "th-TH": "การเข้าปะทะ",
               "vi-VN": "Truy cản"}
TACKLE_NOTE = {
    "en": "Cheek to cheek, shoulder into the thigh, and squeeze on contact. A tackler who reaches with his arms first has already given up his own shoulder.",
    "en-GB": "Cheek to cheek, shoulder into the thigh, and squeeze on contact. A tackler who reaches with his arms first has already given up his own shoulder.",
    "zh-CN": "头贴在对手臀侧，肩顶大腿，接触瞬间抱紧。先用手去够的擒抱者，等于已经把自己的肩膀让出去了。",
    "zh-TW": "頭貼在對手臀側，肩頂大腿，接觸瞬間抱緊。先用手去夠的擒抱者，等於已經把自己的肩膀讓出去了。",
    "ja-JP": "頬を相手の尻に付け、肩を太腿に入れ、当たった瞬間に絞る。先に腕から行くタックラーは、自分の肩をすでに捨てている。",
    "ko-KR": "볼을 상대 엉덩이에 붙이고 어깨를 허벅지에 넣은 뒤 접촉 순간 조여라. 팔부터 뻗는 태클러는 이미 자기 어깨를 버린 것이다.",
    "es-ES": "Mejilla contra cadera, hombro en el muslo y aprieta en el contacto. Quien llega con los brazos primero ya ha regalado su propio hombro.",
    "fr-FR": "Joue contre hanche, épaule dans la cuisse, et serre à l'impact. Le plaqueur qui tend d'abord les bras a déjà abandonné son épaule.",
    "id-ID": "Pipi menempel di pinggul lawan, bahu masuk ke paha, dan kunci saat kontak.",
    "ms-MY": "Pipi rapat ke pinggul lawan, bahu masuk ke peha, dan kunci ketika kontak.",
    "th-TH": "แก้มแนบสะโพกคู่ต่อสู้ ไหล่เข้าที่ต้นขา และรัดทันทีที่ปะทะ",
    "vi-VN": "Má áp hông đối thủ, vai thúc vào đùi, và siết ngay khi tiếp xúc.",
}
HIGHBALL_NAME = {"en": "The high ball", "en-GB": "The high ball",
                 "zh-CN": "高球争顶", "zh-TW": "高球爭頂", "ja-JP": "ハイボール",
                 "ko-KR": "하이볼 경합", "es-ES": "El balón alto",
                 "fr-FR": "Le ballon haut", "id-ID": "Bola tinggi",
                 "ms-MY": "Bola tinggi", "th-TH": "ลูกโด่ง", "vi-VN": "Bóng bổng"}
HIGHBALL_NOTE = {
    "en": "Call it early, jump off one foot with the knee up, and catch it above the head rather than at the chest. The chest catch is the one the chaser knocks loose.",
    "en-GB": "Call it early, jump off one foot with the knee up, and catch it above the head rather than at the chest. The chest catch is the one the chaser knocks loose.",
    "zh-CN": "早喊，单脚起跳、抬起护膝，把球接在头顶上方而不是胸前。胸前接的那个球，就是被追防的人撞掉的那个。",
    "zh-TW": "早喊，單腳起跳、抬起護膝，把球接在頭頂上方而不是胸前。胸前接的那個球，就是被追防的人撞掉的那個。",
    "ja-JP": "早くコールし、片足で膝を上げて跳び、胸ではなく頭上で捕る。胸で捕った球はチェイサーに弾かれる。",
    "ko-KR": "일찍 콜하고 한 발로 무릎을 올려 뛰어 가슴이 아니라 머리 위에서 잡아라. 가슴으로 잡은 공이 떨어지는 공이다.",
    "es-ES": "Cántala pronto, salta con una pierna y la rodilla arriba, y atrápala por encima de la cabeza, no en el pecho.",
    "fr-FR": "Annonce tôt, saute sur un pied genou levé, et capte au-dessus de la tête plutôt qu'à la poitrine.",
    "id-ID": "Serukan lebih awal, lompat satu kaki dengan lutut terangkat, dan tangkap di atas kepala.",
    "ms-MY": "Seru awal, lompat sebelah kaki dengan lutut terangkat, dan tangkap di atas kepala.",
    "th-TH": "ขานเรียกแต่เนิ่น กระโดดขาเดียวยกเข่า และรับเหนือศีรษะไม่ใช่ที่อก",
    "vi-VN": "Gọi sớm, bật một chân với đầu gối nâng lên, và bắt bóng trên đầu chứ không phải trước ngực.",
}
GOALKICK_NAME = {"en": "Place kicking", "en-GB": "Place kicking",
                 "zh-CN": "定位球射门", "zh-TW": "定位球射門",
                 "ja-JP": "プレースキック", "ko-KR": "플레이스 킥",
                 "es-ES": "Patada a palos", "fr-FR": "Le coup de pied placé",
                 "id-ID": "Tendangan penalti tiang", "ms-MY": "Sepakan tempat",
                 "th-TH": "การเตะเข้าเสา", "vi-VN": "Đá cố định"}
GOALKICK_NOTE = {
    "en": "The routine is the skill: same steps back, same steps across, same time over the ball whether it is the first minute or the last kick of the match.",
    "en-GB": "The routine is the skill: same steps back, same steps across, same time over the ball whether it is the first minute or the last kick of the match.",
    "zh-CN": "流程本身就是技术：后退几步、横移几步、在球前停留多久，第一分钟和最后一脚都必须一模一样。",
    "zh-TW": "流程本身就是技術：後退幾步、橫移幾步、在球前停留多久，第一分鐘和最後一腳都必須一模一樣。",
    "ja-JP": "ルーティンこそが技術だ。下がる歩数、横に動く歩数、ボールの前で費やす時間——開始1分でも最後の一蹴りでも同じにする。",
    "ko-KR": "루틴이 곧 기술이다. 뒤로 몇 걸음, 옆으로 몇 걸음, 공 앞에서 머무는 시간까지 언제나 똑같이.",
    "es-ES": "La rutina es la técnica: los mismos pasos atrás, los mismos de lado, el mismo tiempo sobre el balón, sea el minuto uno o la última patada.",
    "fr-FR": "La routine est la technique : mêmes pas en arrière, mêmes pas de côté, même temps au-dessus du ballon, à la première minute comme au dernier coup de pied.",
    "id-ID": "Rutinitas itulah keterampilannya: langkah mundur yang sama, langkah samping yang sama, waktu yang sama di atas bola.",
    "ms-MY": "Rutin itulah kemahirannya: langkah undur yang sama, langkah sisi yang sama.",
    "th-TH": "รูทีนคือทักษะ ถอยหลังกี่ก้าว ก้าวข้างกี่ก้าว ใช้เวลาเหนือบอลเท่าไร ต้องเหมือนเดิมเสมอ",
    "vi-VN": "Quy trình chính là kỹ thuật: cùng số bước lùi, cùng số bước ngang, cùng khoảng thời gian đứng trước bóng.",
}
EXIT_NAME = {"en": "Exit from your own 22", "en-GB": "Exit from your own 22",
             "zh-CN": "本方 22 米区出球", "zh-TW": "本方 22 公尺區出球",
             "ja-JP": "自陣22mからの脱出", "ko-KR": "자기 진영 22m 탈출",
             "es-ES": "Salida desde tus 22", "fr-FR": "Sortie de ses 22 mètres",
             "id-ID": "Keluar dari 22 m sendiri", "ms-MY": "Keluar dari 22 m sendiri",
             "th-TH": "การออกจากแดน 22 เมตรของตัวเอง", "vi-VN": "Thoát khỏi vạch 22 của mình"}
EXIT_NOTE = {
    "en": "Two phases then the kick, and the kick goes to touch or to grass, never down the throat of the back three. A rushed exit is the try you concede two minutes later.",
    "en-GB": "Two phases then the kick, and the kick goes to touch or to grass, never down the throat of the back three. A rushed exit is the try you concede two minutes later.",
    "zh-CN": "打两个波次再踢，踢出界或踢到空当，绝不要正对着对方后三人踢。仓促出球，就是两分钟后丢的那个达阵。",
    "zh-TW": "打兩個波次再踢，踢出界或踢到空檔，絕不要正對著對方後三人踢。倉促出球，就是兩分鐘後丟的那個達陣。",
    "ja-JP": "2フェーズ回してから蹴る。蹴り先はタッチか空きスペースで、相手バックスリーの正面には絶対に蹴らない。急いだ脱出は2分後の失トライだ。",
    "ko-KR": "두 페이즈를 돌린 뒤 차고, 차는 곳은 터치라인 밖이나 빈 공간이지 상대 백3의 정면이 아니다.",
    "es-ES": "Dos fases y luego el patadón, y ese patadón va a touch o a hierba libre, nunca a la garganta de los tres de atrás.",
    "fr-FR": "Deux temps de jeu puis le coup de pied, et ce coup de pied part en touche ou dans l'herbe, jamais dans les bras des trois arrières.",
    "id-ID": "Dua fase lalu tendangan, dan tendangan itu ke luar lapangan atau ke ruang kosong.",
    "ms-MY": "Dua fasa kemudian sepakan, dan sepakan itu ke luar padang atau ke ruang kosong.",
    "th-TH": "เล่นสองเฟสแล้วค่อยเตะ และเตะออกข้างสนามหรือลงพื้นที่ว่าง",
    "vi-VN": "Hai đợt tấn công rồi mới đá, và cú đá ra biên hoặc vào khoảng trống.",
}


MAUL_NAME = {
    "en": "Maul", "en-GB": "Maul", "zh-CN": "冒尔推进", "zh-TW": "冒爾推進",
    "ja-JP": "モール", "ko-KR": "몰", "es-ES": "Maul", "fr-FR": "Maul",
    "id-ID": "Maul", "ms-MY": "Maul", "th-TH": "มอล", "vi-VN": "Maul",
}
MAUL_NOTE = {
    "en": "The ball goes to the back before the drive starts. A maul that "
          "moves with the ball at the front is one rip from a turnover.",
    "en-GB": "The ball goes to the back before the drive starts. A maul that "
             "moves with the ball at the front is one rip from a turnover.",
    "zh-CN": "先把球转移到最后面，再开始推进。球还在最前面就往前推的冒尔，被抢一下就丢球权。",
    "zh-TW": "先把球轉移到最後面，再開始推進。球還在最前面就往前推的冒爾，被搶一下就丟球權。",
    "ja-JP": "ドライブの前にボールを最後尾へ送る。先頭にボールを置いたまま動くモールは、一回のもぎ取りでターンオーバーだ。",
    "ko-KR": "드라이브 전에 공을 맨 뒤로 보내라. 공이 앞에 있는 몰은 한 번 뜯기면 턴오버다.",
    "es-ES": "El balón va atrás antes de empezar a empujar: un maul que avanza "
             "con el balón delante está a un tirón de la pérdida.",
    "fr-FR": "Le ballon passe au fond avant de pousser : un maul qui avance "
             "ballon devant est à un arrachage du turnover.",
    "id-ID": "Bola ke belakang dulu sebelum dorongan dimulai.",
    "ms-MY": "Bola ke belakang dahulu sebelum tolakan bermula.",
    "th-TH": "ส่งบอลไปท้ายสุดก่อนเริ่มดัน มอลที่บอลอยู่หน้าโดนกระชากทีเดียวก็เสีย",
    "vi-VN": "Đưa bóng về cuối trước khi bắt đầu đẩy.",
}


# ── purposes that the category's own line does not fit ───────────────────
KICK_PURPOSE = _t12(
    "Use the boot to gain ground or win the ball back — a kick is only as good as the chase that goes with it.",
    "用脚赢地盘或把球抢回来——一脚踢得好不好，取决于跟上去的追击。",
    "用腳贏地盤或把球搶回來——一腳踢得好不好，取決於跟上去的追擊。",
    "キックで陣地を取り、ボールを取り返す。キックの価値は、一緒に走るチェイスで決まる。",
    "킥으로 지역을 얻거나 공을 되찾는다 — 킥의 가치는 함께 달리는 체이스가 정한다.",
    "Usar el pie para ganar terreno o recuperar el balón: una patada vale lo que vale la persecución que la acompaña.",
    "Utiliser le pied pour gagner du terrain ou récupérer le ballon : un coup de pied ne vaut que par la chasse qui l'accompagne.",
    "Memakai tendangan untuk merebut wilayah atau merebut kembali bola — tendangan hanya sebaik pengejaran yang menyertainya.",
    "Menggunakan sepakan untuk merebut kawasan atau merampas semula bola — sepakan hanya sebaik kejaran yang mengiringinya.",
    "ใช้ลูกเตะเพื่อได้พื้นที่หรือแย่งบอลคืน ลูกเตะจะดีแค่ไหนขึ้นกับการวิ่งไล่ที่ตามไป",
    "Dùng chân để giành đất hoặc đoạt lại bóng — cú đá chỉ tốt bằng đợt đuổi theo đi cùng nó.")
HIGHBALL_PURPOSE = _t12(
    "Win the high ball under pressure and turn it straight into a counter-attack before the chase is set.",
    "在压迫下拿下高球，并在对方追防站好之前立刻转为反击。",
    "在壓迫下拿下高球，並在對方追防站好之前立刻轉為反擊。",
    "プレッシャーの中でハイボールを確保し、チェイスが揃う前にそのままカウンターへ。",
    "압박 속에서 하이볼을 잡고, 체이스가 정렬되기 전에 곧바로 역습으로 바꾼다.",
    "Ganar el balón alto bajo presión y convertirlo en contraataque antes de que la persecución se organice.",
    "Gagner le ballon haut sous pression et relancer avant que la chasse ne soit en place.",
    "Menangkan bola tinggi di bawah tekanan dan langsung jadikan serangan balik sebelum pengejar tertata.",
    "Menangi bola tinggi di bawah tekanan dan terus jadikan serangan balas sebelum pengejar tersusun.",
    "เก็บลูกโด่งภายใต้แรงกดดัน แล้วสวนกลับทันทีก่อนฝ่ายไล่จะตั้งแนวได้",
    "Bắt bóng bổng dưới áp lực và biến nó ngay thành phản công trước khi hàng đuổi kịp dàn xếp.")
GOALKICK_PURPOSE = _t12(
    "Make the place kick a routine: the same set-up every time, so that the scoreboard and the clock change nothing.",
    "把定位踢变成固定流程：每次准备动作都一样，比分和时间都改变不了它。",
    "把定位踢變成固定流程：每次準備動作都一樣，比分和時間都改變不了它。",
    "プレースキックをルーティンにする。毎回同じ準備をして、スコアも時間も何も変えない。",
    "플레이스 킥을 루틴으로 만든다. 매번 같은 준비로, 점수와 시간이 아무것도 바꾸지 못하게.",
    "Convertir la patada a palos en rutina: la misma preparación siempre, para que el marcador y el reloj no cambien nada.",
    "Faire du coup de pied placé une routine : la même préparation à chaque fois, pour que le score et le chrono ne changent rien.",
    "Jadikan tendangan tempat sebuah rutinitas: persiapan yang sama setiap kali, sehingga skor dan waktu tak mengubah apa pun.",
    "Jadikan sepakan tempat satu rutin: persediaan yang sama setiap kali, supaya mata dan masa tidak mengubah apa-apa.",
    "ทำให้การเตะวางเป็นรูทีน เตรียมตัวเหมือนเดิมทุกครั้ง คะแนนและเวลาจะไม่เปลี่ยนอะไรเลย",
    "Biến cú đá đặt thành thói quen: chuẩn bị giống hệt mỗi lần, để tỷ số và đồng hồ không thay đổi được gì.")
EXIT_PURPOSE = _t12(
    "Get out of your own 22 under pressure: secure possession through two carries, then a kick that finds touch or grass.",
    "在压迫下打出本方 22 米区：先靠两次持球冲撞稳住球权，再一脚踢出界或踢到空当。",
    "在壓迫下打出本方 22 公尺區：先靠兩次持球衝撞穩住球權，再一腳踢出界或踢到空檔。",
    "プレッシャーの中で自陣22mから脱出する。2回のキャリーでボールを確保し、タッチか空いた芝へ蹴る。",
    "압박 속에서 자기 진영 22m를 벗어난다. 두 번의 캐리로 공을 지키고, 터치나 빈 곳으로 킥한다.",
    "Salir de tus 22 bajo presión: asegurar la posesión con dos cargas y una patada que encuentre touch o hierba libre.",
    "Sortir de ses 22 mètres sous pression : sécuriser le ballon sur deux charges, puis un coup de pied qui trouve la touche ou l'herbe.",
    "Keluar dari 22 m sendiri di bawah tekanan: amankan bola lewat dua bawaan, lalu tendangan ke luar lapangan atau ruang kosong.",
    "Keluar dari 22 m sendiri di bawah tekanan: kukuhkan bola melalui dua bawaan, kemudian sepakan ke luar padang atau ruang kosong.",
    "ออกจากแดน 22 เมตรของตัวเองภายใต้แรงกดดัน รักษาบอลด้วยการพาบอลปะทะสองครั้ง แล้วเตะออกข้างหรือลงพื้นที่ว่าง",
    "Thoát khỏi vạch 22 của mình dưới áp lực: giữ bóng qua hai lần ôm bóng lao lên, rồi một cú đá ra biên hoặc vào khoảng trống.")
TACKLE_PURPOSE = _t12(
    "Tackle safely and effectively: the carrier goes down where he is met, and the tackler is the first man back on his feet.",
    "安全而有效地擒抱：持球人在哪里被接住就在哪里倒地，擒抱者第一个站起来。",
    "安全而有效地擒抱：持球人在哪裡被接住就在哪裡倒地，擒抱者第一個站起來。",
    "安全で効果的なタックル。ボールキャリアは当たった場所で倒れ、タックラーが真っ先に立ち上がる。",
    "안전하고 효과적인 태클: 볼 캐리어는 맞닥뜨린 자리에서 넘어지고, 태클러가 가장 먼저 일어선다.",
    "Placar con seguridad y eficacia: el portador cae donde se le encuentra y el placador es el primero en levantarse.",
    "Plaquer en sécurité et efficacement : le porteur tombe là où il est rencontré, et le plaqueur est le premier debout.",
    "Tekel yang aman dan efektif: pembawa bola jatuh di tempat ia dihadang, dan penekel yang pertama berdiri lagi.",
    "Tekel yang selamat dan berkesan: pembawa bola jatuh di tempat dia ditemui, dan penekel yang pertama bangun semula.",
    "แท็กเกิลอย่างปลอดภัยและได้ผล คนถือบอลล้มตรงจุดที่ถูกปะทะ และคนแท็กเกิลลุกขึ้นก่อนใคร",
    "Truy cản an toàn và hiệu quả: người cầm bóng ngã đúng chỗ bị chặn, và người truy cản là người đứng dậy đầu tiên.")


# ── handling ──────────────────────────────────────────────────────────────
def handling_family() -> list[Drill]:
    """A staggered line running onto the ball: each man starts STAGGER
    deeper than the one inside him and runs RUN up the field a beat, so the
    pass he takes is always flat or behind the man who threw it."""
    STAGGER, RUN = 4.0, 3.0
    specs = [
        # key, label, lanes (x), front man's start (y), cones
        ("grid", "in a grid", [23, 29, 35, 41], 92.0,
         [(18, 72), (46, 72), (18, 106), (46, 106)], 76.0),
        ("threes", "in threes", [27, 35, 43], 92.0,
         [(27, 78), (35, 78), (43, 78)], 80.0),
        ("wide", "across the width", [5, 17, 29, 41, 53, 65], 84.0,
         [(x, 62) for x in (5, 17, 29, 41, 53, 65)], 64.0),
    ]
    out = []
    for key, label, xs, y0, cones, finish in specs:
        n = len(xs)
        b = Board()
        keys = [str(i + 1) for i in range(n)]
        for i, (k, x) in enumerate(zip(keys, xs)):
            b.put(k, x, y0 + STAGGER * i)
        for beat in range(n):
            for i, k in enumerate(keys):
                if beat == n - 1 and i == n - 1:
                    # the end man takes it over the line of cones
                    b.go(k, b.x(k), finish, beat)
                else:
                    b.go(k, b.x(k), b.y(k) - RUN, beat)
        out.append(Drill(
            id=f"rg_handling_{key}", category="warmup", minutes=8, rel=True,
            free=(key in ("grid", "threes")),
            name=suffixed(HANDLE_NAME, label), note=HANDLE_NOTE,
            home=b.players(keys),
            markers=[mk(x, y) for x, y in cones],
            ball=0,
            ball_to=[(i + 1, i) for i in range(n - 1)] + [(n - 1, n - 1)],
        ))
    return out


# ── phase play ────────────────────────────────────────────────────────────
def _pod(labels, cx, y):
    """A pod's shape: one is a man, two stand side by side, three are a
    shallow arrow with the hitter in front, four a flat four."""
    offs = {1: [(0, 0)], 2: [(-2.5, 0), (2.5, 0)],
            3: [(-4.6, 4), (0, 0), (4.6, 4)],
            4: [(-6.9, 4), (-2.3, 0), (2.3, 0), (6.9, 4)]}[len(labels)]
    return [(lbl, cx + dx, y + dy) for lbl, (dx, dy) in zip(labels, offs)]


def _phase(key, label, free, ruck_x, groups, hit1, hit2, edge, d_xs):
    """Two phases and the finish.

    The 9 at the base passes to the first pod's hitter, who carries into
    the tackle and places the ball back; the 9 passes again to the second
    hitter, who gives it to the edge man, and the edge man scores. Every
    receiver catches deeper than the ball was released; the defence comes
    up and meets each carrier at the gain line rather than running through.
    """
    b = Board()
    order = []
    for labels, cx in groups:
        for lbl, x, y in _pod(labels, cx, 58.0):
            b.put(lbl, x, y)
            order.append(lbl)
    b.put("9", ruck_x, 53.0)
    dkeys = [f"D#{i}" for i in range(len(d_xs))]
    for k, x in zip(dkeys, d_xs):
        b.put(k, x, 38.0)
    pod1 = next(g for g, _ in groups if hit1 in g)
    mates = [m for m in pod1 if m != hit1]

    # beat 0: the 9 passes, the hitter runs onto it from depth
    b.go(hit1, b.x(hit1), b.y(hit1) - 3.0, 0)
    b.shift([k for k in order if k != hit1], 0, -2.0, 0)
    b.shift(dkeys, 0, 3.0, 0)
    # beat 1: into contact; two defenders meet him on the gain line
    cx, cy = b.x(hit1) - 1.0, 48.0
    b.go(hit1, cx, cy, 1)
    near = sorted(dkeys, key=lambda k: abs(b.x(k) - cx))[:2]
    tacklers = sorted(near, key=lambda k: b.x(k))
    b.go(tacklers[0], cx - 2.5, cy - 4.0, 1)
    b.go(tacklers[1], cx + 2.5, cy - 4.0, 1)
    left = [m for m in mates if b.x(m) < cx]
    right = [m for m in mates if b.x(m) >= cx]
    if left:
        b.go(left[-1], cx - 5.0, cy + 3.0, 1)
    if right:
        b.go(right[0], cx + 5.0, cy + 3.0, 1)
    b.go("9", cx + 4.5, cy + 11.0, 1)
    rest = [k for k in order if k not in pod1]
    b.shift(rest, -2.0, 0, 1)
    # beat 2: the ball is placed back at the 9's feet; the second pod
    # drops to depth and the defence realigns on it
    ball_back = spot(cx + 3.0, cy + 9.0)
    b.shift([k for k in [g for g, _ in groups if hit2 in g][0] if k != edge],
            0, 2.0, 2)
    free_d = [k for k in dkeys if k not in tacklers]
    b.shift(free_d, 2.0, 1.0, 2)
    # beat 3: the 9 passes to the second hitter, running onto it
    h2_y = max(b.y(hit2) - 1.5, cy + 13.0)
    b.go(hit2, b.x(hit2), h2_y, 3)
    b.shift([k for k in [g for g, _ in groups if hit2 in g][0]
             if k not in (hit2, edge)], 0, -1.5, 3)
    b.go(edge, b.x(edge), b.y(edge) - 1.0, 3)
    # beat 4: he draws the last defenders and gives it to the edge man
    # behind him; they meet him at the line
    e_y = max(b.y(edge) - 1.0, h2_y + 2.0)
    b.go(edge, b.x(edge) + 1.0, e_y, 4)
    hx, hy = b.x(hit2), h2_y - 5.0
    b.go(hit2, hx, hy, 4)
    on_h2 = sorted(free_d, key=lambda k: abs(b.x(k) - hx))[:2]
    for i, k in enumerate(sorted(on_h2, key=lambda k: b.x(k))):
        b.go(k, hx - 2.5 + 5.0 * i, hy - 4.0, 4)
    # beat 5: the edge man goes over and grounds it
    b.go(edge, b.x(edge), 16.0, 5)
    chaser = max(dkeys, key=lambda k: b.x(k)) if b.x(edge) > 35 else min(
        dkeys, key=lambda k: b.x(k))
    # the cover chases him in, inside him and beaten for pace
    if chaser in on_h2:
        chaser = [k for k in dkeys if k not in on_h2][-1]
    inside = -9.0 if b.x(edge) > 35 else 9.0
    b.go(chaser, b.x(edge) + inside, 30.0, 5)
    home_keys = order + ["9"]
    return Drill(
        id=f"rg_phase_{key}", category="possession", minutes=14, rel=True,
        tight=True, free=free,
        name=suffixed(PHASE_NAME, label), note=PHASE_NOTE,
        home=b.players(home_keys),
        away=b.players(dkeys),
        ball=home_keys.index("9"), ball_spot=pt(ruck_x + 2.0, 51.0),
        ball_to=[(home_keys.index(hit1), 0), (home_keys.index(hit1), 1),
                 (ball_back, 2), (home_keys.index(hit2), 3),
                 (home_keys.index(edge), 4), (home_keys.index(edge), 5)],
    )


def phase_family() -> list[Drill]:
    return [
        # one forward on each edge, two pods of three between them
        _phase("one_three_three_one", "1-3-3-1", True, 13.0,
               [(["6"], 5.0), (["1", "2", "3"], 25.0),
                (["4", "8", "5"], 46.0), (["7"], 65.0)],
               "2", "8", "7", [12, 22, 32, 42, 52, 60]),
        # a pair on each edge, four in the middle
        _phase("two_four_two", "2-4-2", False, 19.0,
               [(["6", "2"], 7.0), (["1", "4", "5", "3"], 34.0),
                (["8", "7"], 61.0)],
               "4", "8", "7", [12, 22, 32, 42, 52, 60]),
        # off a ruck on the left, the ball goes across to the right
        _phase("left_to_right", "left to right", False, 12.0,
               [(["1", "2", "3"], 24.0), (["4", "5", "6"], 40.0),
                (["10"], 52.0), (["13"], 63.0)],
               "2", "10", "13", [10, 20, 30, 40, 50, 60]),
    ]


# ── backline moves ────────────────────────────────────────────────────────
def move_family() -> list[Drill]:
    """Five backs against four defenders, off first-phase ball.

    The line is staggered three metres a man and runs two a beat, so every
    pass along it is caught behind the passer. Each move ends with the man
    it frees carrying the ball over the line; the decoys and the carriers
    the defence reaches are met at the gain line, not run through.
    """
    out = []
    for key, label in [("miss_pass", "the miss pass"), ("switch", "the switch"),
                       ("loop", "the loop"), ("cut_out", "the cut-out"),
                       ("dummy_runner", "with a dummy runner")]:
        b = Board()
        backs = ["10", "12", "13", "15", "14"]
        for i, k in enumerate(backs):
            b.put(k, 20.0 + 10.0 * i, 56.0 + 3.0 * i)
        dk = [f"D#{i}" for i in range(4)]
        for i, k in enumerate(dk):
            b.put(k, 24.0 + 10.0 * i, 42.0)
        D1, D2, D3, D4 = dk
        # beat 0, every move: 10 passes to 12 as the line comes up
        b.shift(backs, 0, -2.0, 0)
        b.shift(dk, 0, 3.0, 0)
        i10, i12, i13, i15, i14 = range(5)
        if key == "miss_pass":
            b.shift(["10", "12", "15", "14"], 0, -2.0, 1)
            b.go("13", 41.0, 52.0, 1)               # holds his man
            b.go(D3, 42.0, 50.0, 1)
            b.shift([D1, D2], 0, 3.0, 1)
            b.go(D4, 55.0, 48.0, 1)
            b.go("14", 61.0, 62.0, 2)
            b.go("15", 51.0, 57.0, 2)               # draws D4 and gives it
            b.go(D4, 52.5, 55.0, 2)
            b.shift(["10", "12"], 0, -1.0, 2)
            b.go("14", 62.0, 16.0, 3)
            b.go(D4, 50.0, 46.0, 3)
            ball_to = [(i12, 0), (i15, 1), (i14, 2), (i14, 3)]
        elif key == "switch":
            b.go("12", 37.0, 53.0, 1)               # drifts out with it
            b.go("13", 31.0, 59.0, 1)               # cuts back behind him
            b.go("10", 22.0, 53.0, 1)
            b.shift(["15", "14"], 0, -2.0, 1)
            b.go(D2, 36.0, 48.0, 1)
            b.go(D3, 41.0, 48.0, 1)
            b.go(D1, 23.0, 48.0, 1)
            b.go(D4, 54.0, 48.0, 1)
            b.go("13", 29.0, 56.5, 2)
            b.go("12", 38.0, 50.5, 2)               # taken by D3 after
            b.go(D3, 40.0, 49.0, 2)
            b.go(D2, 36.0, 49.0, 2)
            b.go("10", 22.0, 51.0, 2)               # holds D1
            b.go(D1, 22.5, 49.0, 2)
            b.go("13", 28.0, 16.0, 3)
            b.go(D2, 36.0, 44.0, 3)
            ball_to = [(i12, 0), (i12, 1), (i13, 2), (i13, 3)]
        elif key == "loop":
            b.go("10", 34.5, 61.0, 1)               # round the back of 12
            b.go("12", 30.0, 55.5, 1)
            b.go("13", 45.0, 60.0, 1)
            b.go("15", 53.0, 61.0, 1)
            b.go("14", 62.0, 64.0, 1)
            b.go(D2, 32.0, 48.0, 1)
            b.go(D3, 45.0, 48.0, 1)
            b.go(D1, 26.0, 48.0, 1)
            b.go(D4, 55.0, 48.0, 1)
            b.go("10", 36.5, 59.0, 2)               # outside 12, behind him
            b.go("12", 31.0, 51.5, 2)               # into D2
            b.go(D2, 31.0, 49.5, 2)
            b.go("13", 45.0, 53.0, 2)               # holds D3
            b.go(D3, 45.0, 51.0, 2)
            b.go("10", 38.0, 16.0, 3)
            b.go(D4, 47.0, 40.0, 3)
            ball_to = [(i12, 0), (i12, 1), (i10, 2), (i10, 3)]
        elif key == "cut_out":
            b.go("14", 61.0, 63.5, 1)
            b.go("12", 30.0, 54.0, 1)
            b.go("13", 42.0, 53.0, 1)               # decoys hold their men
            b.go("15", 51.0, 57.0, 1)
            b.go("10", 20.0, 52.0, 1)
            b.go(D3, 43.0, 51.0, 1)
            b.go(D4, 52.0, 51.0, 1)
            b.shift([D1, D2], 0, 3.0, 1)
            b.go("14", 63.0, 16.0, 2)
            b.go(D4, 51.0, 46.0, 2)
            ball_to = [(i12, 0), (i14, 1), (i14, 2)]
        else:   # dummy_runner
            b.go("13", 35.0, 53.0, 1)               # the hard, short dummy line
            b.go("12", 29.0, 55.5, 1)
            b.go("15", 47.0, 61.0, 1)               # out the back
            b.go("14", 60.0, 64.0, 1)
            b.go("10", 20.0, 52.0, 1)
            b.go(D3, 37.0, 50.5, 1)                 # bites on the dummy
            b.go(D2, 32.0, 49.0, 1)
            b.go(D4, 54.0, 49.0, 1)
            b.go(D1, 24.0, 48.0, 1)
            b.go("15", 45.0, 16.0, 2)
            b.go(D4, 56.0, 46.0, 2)
            ball_to = [(i12, 0), (i15, 1), (i15, 2)]
        out.append(Drill(
            id=f"rg_move_{key}", category="attacking", minutes=12, rel=True,
            tight=True, free=(key in ("miss_pass", "switch")),
            name=suffixed(MOVE_NAME, dashed(label)), note=MOVE_NOTE,
            home=b.players(backs), away=b.players(dk),
            ball=0, ball_to=ball_to,
        ))
    return out


# ── finishing ─────────────────────────────────────────────────────────────
WIDE_FINISH_NOTE = _t12(
    "In the corner, finish low and away from the cover: ball in the hand furthest from the touchline, and down before the corner flag, not on it.",
    "在角上终结要压低、远离补防：球拿在离边线远的那只手里，在角旗之前按下，不要压在角旗上。",
    "在角上終結要壓低、遠離補防：球拿在離邊線遠的那隻手裡，在角旗之前按下，不要壓在角旗上。",
    "コーナーでは低く、カバーから離れてフィニッシュ。ボールはタッチラインから遠い手に持ち、コーナーフラッグより手前で置く。",
    "코너에서는 낮게, 커버에서 멀리 마무리한다. 공은 터치라인에서 먼 손에 들고, 코너 플래그 앞에서 찍는다.",
    "En la esquina, termina bajo y lejos del que cubre: el balón en la mano más alejada de la línea de touche, y abajo antes del banderín, no encima.",
    "Dans le coin, finis bas et loin du couvreur : le ballon dans la main la plus éloignée de la touche, aplati avant le drapeau, pas dessus.",
    "Di sudut, selesaikan rendah dan jauh dari penutup: bola di tangan yang terjauh dari garis samping, tekan sebelum bendera sudut.",
    "Di sudut, selesaikan rendah dan jauh daripada penutup: bola di tangan yang paling jauh dari garisan tepi, tekan sebelum bendera sudut.",
    "ในมุมสนามให้จบต่ำและห่างจากคนตามปิด ถือบอลมือที่ไกลเส้นข้าง และวางก่อนถึงธงมุม",
    "Ở góc, dứt điểm thấp người và tránh xa người bọc lót: bóng ở tay xa đường biên, ấn xuống trước cờ góc chứ không phải trên nó.")


def finishing_family() -> list[Drill]:
    out = []
    # pick and go: the ball at the base of a ruck three metres out
    b = Board()
    b.put("1", 38.5, 31.0)
    b.put("2", 43.0, 37.0)
    b.put("D#0", 35.0, 21.0)
    b.put("D#1", 41.0, 21.0)
    b.go("1", 36.0, 25.0, 0)        # picks it up and drives at the line
    b.go("D#0", 35.5, 22.5, 0)
    b.go("D#1", 39.5, 22.0, 0)
    b.go("2", 40.5, 31.0, 0)        # binds on behind him
    b.go("1", 35.5, 17.0, 1)        # over, and down
    b.go("D#0", 34.0, 15.0, 1)
    b.go("2", 40.0, 24.0, 1)
    out.append(Drill(
        id="rg_finish_pick_and_go", category="finishing", minutes=10, rel=True,
        tight=True, free=True,
        name=suffixed(FINISH_NAME, dashed("pick and go")), note=FINISH_NOTE,
        home=b.players(["1", "2"]), away=b.players(["D#0", "D#1"]),
        markers=[mk(35, 14, "zone")],
        ball=pt(36.5, 28.5),
        ball_to=[(0, 0), (0, 1)],
    ))

    # in the corner: draw the cover, give it outside, dive in at the flag
    b = Board()
    b.put("1", 56.0, 42.0)
    b.put("2", 64.0, 48.0)
    b.put("D#0", 48.0, 28.0)
    b.put("D#1", 60.0, 26.0)
    b.go("1", 57.0, 35.0, 0)
    b.go("2", 64.0, 41.0, 0)
    b.go("D#0", 54.0, 30.0, 0)
    b.go("D#1", 59.0, 30.0, 0)
    b.go("2", 65.0, 37.5, 1)        # outside him and behind the ball
    b.go("1", 57.0, 32.0, 1)        # taken as he gives it
    b.go("D#1", 58.0, 30.5, 1)
    b.go("D#0", 59.0, 27.0, 1)
    b.go("2", 65.5, 15.0, 2)
    b.go("D#0", 62.0, 21.0, 2)
    out.append(Drill(
        id="rg_finish_wide_finish", category="finishing", minutes=10, rel=True,
        name=suffixed(FINISH_NAME, "in the corner"), note=WIDE_FINISH_NOTE,
        home=b.players(["1", "2"]), away=b.players(["D#0", "D#1"]),
        markers=[mk(63, 13, "zone")],
        ball=0,
        ball_to=[(0, 0), (1, 1), (1, 2)],
    ))

    # off the kick chase: a chip over the line, regathered and grounded
    b = Board()
    b.put("10", 30.0, 42.0)
    b.put("13", 38.0, 44.0)          # behind the kicker: onside
    b.put("D#0", 24.0, 30.0)
    b.put("D#1", 38.0, 31.0)
    b.go("13", 34.0, 32.0, 0)
    b.go("10", 29.0, 36.0, 0)
    b.go("D#0", 25.0, 28.0, 0)
    b.go("D#1", 37.0, 27.0, 0)
    b.go("13", 31.5, 27.5, 1)
    b.go("D#1", 35.5, 24.5, 1)
    b.go("13", 31.0, 16.0, 2)
    b.go("D#1", 34.5, 19.0, 2)
    out.append(Drill(
        id="rg_finish_kick_chase", category="finishing", minutes=10, rel=True,
        name=suffixed(FINISH_NAME, "off the kick chase"), note=FINISH_NOTE,
        home=b.players(["10", "13"]), away=b.players(["D#0", "D#1"]),
        markers=[mk(31, 13, "zone")],
        ball=0,
        ball_to=[(spot(31.0, 26.0), 0), (1, 1), (1, 2)],
    ))
    return out


# ── defence ───────────────────────────────────────────────────────────────
def defence_family() -> list[Drill]:
    """The home side defends here: six numbered defenders facing down the
    page, against five attackers lettered A-E running up it."""
    out = []
    att = ["A", "B", "C", "D", "E"]
    defs = ["1", "2", "3", "4", "5", "6"]
    for key, label in [("drift", "drifting"), ("blitz", "the blitz"),
                       ("scramble", "scrambling back")]:
        b = Board()
        for i, k in enumerate(att):
            b.put(k, 14.0 + 12.0 * i, 64.0 + 3.0 * i)
        for i, k in enumerate(defs):
            b.put(k, 10.0 + 10.0 * i, 50.0)
        home_keys = list(defs)
        if key == "drift":
            ball = pt(14.0, 62.0)
            b.shift(att, 0, -1.5, 0)
            b.shift(defs, 2.5, 1.5, 0)
            b.shift(att, 0, -1.5, 1)
            b.shift(defs, 2.5, 1.0, 1)
            b.shift(att, 0, -1.5, 2)
            b.shift(defs, 2.5, 0.5, 2)
            b.go("D", 50.0, 64.0, 3)                # into the tackle
            b.go("4", 49.5, 61.0, 3)
            b.go("5", 59.5, 59.0, 3)                # on E, inside him
            ball_to = [("a1", 0), ("a2", 1), ("a3", 2), ("a3", 3)]
        elif key == "blitz":
            ball = pt(14.0, 62.0)
            b.shift(att, 0, -2.0, 0)
            b.shift(defs, -1.0, 8.0, 0)
            b.go("B", 26.0, 62.0, 1)                # B takes it into contact
            b.go("2", 25.0, 60.5, 1)
            b.go("1", 14.0, 57.5, 1)                # each stops short of his man
            b.go("3", 38.0, 63.5, 1)
            b.go("4", 50.0, 66.5, 1)
            b.go("5", 61.0, 69.5, 1)
            b.go("6", 66.5, 64.0, 1)
            b.shift(["A", "C", "D", "E"], 0, -1.0, 1)
            ball_to = [("a1", 0), ("a1", 1)]
        else:
            # The line has been broken: B gives it to C on the gap and the
            # defenders turn and chase back toward their own try line, the
            # full-back coming across to make the tackle short of it.
            b.put("15", 52.0, 28.0)
            home_keys = defs + ["15"]
            ball = pt(26.0, 65.0)
            b.go("C", 36.0, 68.0, 0)
            b.shift(["A", "B", "D", "E"], 0, -2.0, 0)
            b.shift(defs, 0, 2.0, 0)
            b.go("C", 35.0, 44.0, 1)                # through the gap
            b.shift(defs, 0, -6.0, 1)               # turned, chasing back
            b.go("15", 43.0, 34.0, 1)
            b.go("C", 34.0, 31.0, 2)
            b.go("15", 35.0, 29.5, 2)               # the tackle
            b.shift(defs, 0, -8.0, 2)
            b.shift(["A", "B", "D", "E"], 0, -3.0, 1)
            ball_to = [("a2", 0), ("a2", 1), ("a2", 2)]
        out.append(Drill(
            id=f"rg_defence_{key}", category="defending", minutes=12, rel=True,
            free=(key == "drift"),
            name=suffixed(DEF_NAME, dashed(label)), note=DEF_NOTE,
            home=b.players(home_keys), away=b.players(att),
            ball=ball, ball_to=ball_to,
        ))
    return out


# ── set pieces ────────────────────────────────────────────────────────────
def _lineout(b, jumpers, line_y, d_label="D"):
    """Law 18: two straight single files, at right angles to touch, 1 m
    apart — ours 0.5 m on our side of the line of touch, theirs 0.5 m on
    theirs — everyone between the 5 m and 15 m lines. The thrower stands
    outside the touchline on the line of touch, and the throw goes straight
    down it (the middle of the gap).

    At the whole pitch's scale a figure is 4 m wide and that cannot be
    drawn, so these boards open on a close-up (_lineout_view, the board's
    view window) where the tight figure is about 0.7 m wide. The two files
    are staggered — each man opposite a gap in the other file — because a
    figure is drawn twice as tall as it is wide and two files 1 m apart,
    man opposite man, would draw every pair as one."""
    n = len(jumpers)
    lo, hi = 5.1, 14.9
    step = (hi - lo) / (2 * n - 1)
    keys = []
    for i, lbl in enumerate(jumpers):
        b.put(lbl, lo + step * 2 * i, line_y + 0.5)
        keys.append(lbl)
    dk = [f"{d_label}#{i}" for i in range(n)]
    for i, k in enumerate(dk):
        b.put(k, lo + step * (2 * i + 1), line_y - 0.5)
    b.put("2", -0.8, line_y)
    return keys, dk


def _lineout_view(line_y, up, down):
    """The close-up a lineout board opens on: touch (and the thrower just
    outside it) to past the 15 m line, [up] metres toward the try line and
    [down] back from the line of touch. Its width sets the zoom (the phone
    is fitted by width: about 5x, a tight figure 0.7 m wide); keep
    up + down under 30 m or the height would bind instead."""
    return (-1.2 / W, (line_y - up) / L, 15.4 / W, (line_y + down) / L)


def setpiece_family() -> list[Drill]:
    out = []

    # ── the scrum: 8 v 8, the 9 feeds the tunnel, the hooker strikes it
    # back to the No. 8's feet and the 9 passes it away from the base.
    b = Board()
    pack = {"1": (30.5, 68), "2": (35.0, 68), "3": (39.5, 68),
            "6": (28.25, 76), "4": (32.75, 76), "5": (37.25, 76),
            "7": (41.75, 76), "8": (35.0, 84)}
    for k, (x, y) in pack.items():
        b.put(k, x, y)
    b.put("9", 25.0, 64.0)
    b.put("10", 16.0, 92.0)
    theirs = [(39.5, 60), (35.0, 60), (30.5, 60),
              (41.75, 52), (37.25, 52), (32.75, 52), (28.25, 52), (35.0, 44)]
    dk = [f"D#{i}" for i in range(8)]
    for k, (x, y) in zip(dk, theirs):
        b.put(k, x, y)
    b.put("9#a", 45.0, 58.0)
    b.shift(list(pack), 0, -2.0, 0)                 # engage
    b.shift(dk, 0, 2.0, 0)
    b.go("9#a", 44.5, 61.0, 1)                      # their 9 follows the feed
    b.go("10", 18.0, 91.0, 1)
    b.go("9", 30.5, 89.0, 2)                        # round to the base
    b.go("9#a", 42.0, 64.0, 2)
    b.go("10", 20.0, 95.0, 3)                       # onto the pass, deep
    home = list(pack) + ["9", "10"]
    out.append(Drill(
        id="rg_set_scrum", category="setpiece", minutes=12, rel=True,
        tight=True, name=suffixed(SET_NAME, dashed("the scrum")), note=SET_NOTE,
        home=b.players(home), away=b.players(dk + ["9#a"]),
        ball=home.index("9"), ball_spot=pt(27.5, 64.0),
        ball_to=[(spot(33.5, 65.0), 1), (spot(34.0, 89.5), 2),
                 (home.index("10"), 3)],
    ))

    # ── the lineouts
    for key, label, jumpers, jumper in [
            ("lineout_five", "the five-man lineout",
             ["4", "5", "6", "7", "8"], "5"),
            ("lineout_seven", "the seven-man lineout",
             ["1", "3", "4", "5", "6", "7", "8"], "5")]:
        b = Board()
        line_y = 66.0
        keys, dk = _lineout(b, jumpers, line_y)
        jx = b.x(jumper)
        # The receiver: 2 m or more behind his own file (Law 18), between
        # the 5 m and 15 m lines. The 10 is a back: 10 m behind the line of
        # touch until the lineout is over.
        b.put("9", jx + 1.0, line_y + 3.0)
        b.put("10", 14.6, line_y + 13.5)
        jd = min(dk, key=lambda k: abs(b.x(k) - jx))
        jdx = b.x(jd)
        b.go(jd, jx, line_y - 0.5, 0)               # their jumper contests,
        b.go("10", 14.2, line_y + 12.6, 0)          # on his own side of the gap
        b.go("9", jx + 0.2, line_y + 2.6, 1)
        b.go("10", 13.7, line_y + 11.6, 2)
        b.go("10", 13.0, line_y + 10.5, 3)
        b.go("10", 14.0, line_y + 6.0, 4)           # and takes it up
        b.go(jd, jdx, line_y - 0.5, 2)
        home = ["2"] + keys + ["9", "10"]
        out.append(Drill(
            id=f"rg_set_{key}", category="setpiece", minutes=12, rel=True,
            # The thrower stands just outside touch, inside the surface
            # check's tolerance — no off_surface needed.
            tight=True, free=(key == "lineout_five"),
            view=_lineout_view(line_y, 6.0, 14.0),
            name=suffixed(SET_NAME, dashed(label)), note=SET_NOTE,
            home=b.players(home), away=b.players(dk),
            ball=0, ball_spot=pt(-0.3, line_y),
            # straight down the middle of the gap to the jumper's mark,
            # taken, given back to the 9 and on to the 10
            ball_to=[(spot(jx, line_y), 0), (home.index(jumper), 1),
                     (home.index("9"), 2), (home.index("10"), 3),
                     (home.index("10"), 4)],
        ))

    # ── receiving the kick-off: the ball from the centre of halfway,
    # landing past our 10 m line on a pod of three, the 9 behind it.
    b = Board()
    for k, (x, y) in {"4": (19.6, 94), "5": (24.0, 92), "6": (28.4, 94),
                      "8": (42.0, 94), "9": (33.0, 102),
                      "15": (35.0, 114)}.items():
        b.put(k, x, y)
    b.put("10#a", 35.0, 69.0)
    b.put("D#0", 20.0, 69.0)
    b.put("D#1", 50.0, 69.0)
    b.go("5", 24.0, 87.5, 0)
    b.go("4", 19.6, 89.0, 0)
    b.go("6", 28.4, 89.0, 0)
    b.go("D#0", 22.0, 79.0, 0)
    b.go("D#1", 38.0, 80.0, 0)
    b.go("10#a", 35.0, 75.0, 0)
    b.go("D#0", 23.5, 83.0, 1)
    b.go("9", 30.0, 96.0, 1)
    b.go("8", 40.0, 92.0, 2)
    b.go("15", 38.0, 108.0, 2)
    home = ["4", "5", "6", "8", "9", "15"]
    out.append(Drill(
        id="rg_set_kick_off", category="setpiece", minutes=12, rel=True,
        tight=True, free=True,
        name=suffixed(SET_NAME, dashed("receiving the kick-off")), note=SET_NOTE,
        home=b.players(home), away=b.players(["10#a", "D#0", "D#1"]),
        markers=[mk(24, 86, "zone")],
        ball=pt(35.0, 72.0),
        ball_to=[(spot(24.0, 86.0), 0), (home.index("5"), 1),
                 (home.index("9"), 2)],
    ))
    return out


# ── kicking ───────────────────────────────────────────────────────────────
def kicking_family() -> list[Drill]:
    """The kicker holds the ball, the chasers start level with him or
    behind him, and the ball lands in the zone before anybody plays it."""
    out = []
    # box kick: off the base of a ruck by our 22, contested where it lands
    b = Board()
    b.put("9", 14.0, 98.0)
    b.put("11", 6.0, 101.0)
    b.put("13", 24.0, 101.0)
    b.put("14#a", 16.0, 60.0)
    b.put("15#a", 36.0, 52.0)
    b.go("11", 10.0, 80.0, 0)
    b.go("13", 22.0, 82.0, 0)
    b.go("14#a", 16.0, 68.5, 0)
    b.go("15#a", 30.0, 60.0, 0)
    b.go("11", 13.0, 72.0, 1)
    b.go("13", 20.0, 72.5, 1)
    b.go("15#a", 26.0, 66.0, 1)
    out.append(Drill(
        id="rg_kick_box", category="attacking", minutes=10, rel=True,
        free=True, purpose=KICK_PURPOSE,
        name=suffixed(KICK_NAME, dashed("the box kick")), note=KICK_NOTE,
        home=b.players(["9", "11", "13"]), away=b.players(["14#a", "15#a"]),
        markers=[mk(16, 70, "zone")],
        ball=0,
        ball_to=[(spot(16.0, 70.0), 0), ("a0", 1)],
    ))

    # cross-field kick: 10 to the far wing, who takes it and scores
    b = Board()
    b.put("10", 30.0, 40.0)
    b.put("14", 60.0, 42.0)
    b.put("13", 44.0, 43.0)
    for i, (x, y) in enumerate([(18, 27), (34, 27), (48, 28), (56, 30)]):
        b.put(f"D#{i}", x, y)
    b.go("14", 62.0, 34.0, 0)
    b.go("13", 46.0, 36.0, 0)
    b.shift(["D#0", "D#1", "D#2"], 0, 2.0, 0)
    b.go("D#3", 57.0, 28.0, 0)
    b.go("14", 62.0, 31.5, 1)
    b.go("D#3", 58.5, 28.0, 1)
    b.go("13", 50.0, 30.0, 1)
    b.go("14", 63.0, 15.0, 2)
    out.append(Drill(
        id="rg_kick_cross_field", category="attacking", minutes=10, rel=True,
        purpose=KICK_PURPOSE,
        name=suffixed(KICK_NAME, dashed("the cross-field kick")), note=KICK_NOTE,
        home=b.players(["10", "14", "13"]),
        away=b.players([f"D#{i}" for i in range(4)]),
        markers=[mk(62, 28, "zone")],
        ball=0,
        ball_to=[(spot(62.0, 28.0), 0), (1, 1), (1, 2)],
    ))

    # territory: from inside our 22 to grass by their touchline
    b = Board()
    b.put("10", 35.0, 104.0)
    b.put("11", 8.0, 106.0)
    b.put("14", 62.0, 106.0)
    b.put("11#a", 8.0, 50.0)
    b.put("15#a", 35.0, 44.0)
    b.put("14#a", 60.0, 48.0)
    b.go("11", 20.0, 84.0, 0)
    b.go("14", 60.0, 80.0, 0)
    b.go("14#a", 63.0, 54.0, 0)
    b.go("15#a", 45.0, 48.0, 0)
    b.go("14", 62.0, 64.0, 1)
    b.go("11", 40.0, 66.0, 1)
    b.go("15#a", 52.0, 50.0, 1)
    out.append(Drill(
        id="rg_kick_territory", category="attacking", minutes=10, rel=True,
        purpose=KICK_PURPOSE,
        name=suffixed(KICK_NAME, "for territory"), note=KICK_NOTE,
        home=b.players(["10", "11", "14"]),
        away=b.players(["11#a", "15#a", "14#a"]),
        markers=[mk(64, 56, "zone")],
        ball=0,
        ball_to=[(spot(64.0, 56.0), 0), ("a2", 1)],
    ))

    # grubber: through the line, regathered by the chaser from behind
    b = Board()
    b.put("10", 35.0, 46.0)
    b.put("12", 27.0, 48.0)
    b.put("13", 45.0, 48.0)
    b.put("D#0", 28.0, 34.0)
    b.put("D#1", 42.0, 34.0)
    b.go("13", 41.0, 33.0, 0)
    b.go("12", 30.0, 36.0, 0)
    b.go("D#0", 29.0, 33.0, 0)
    b.go("D#1", 43.0, 31.0, 0)
    b.go("13", 38.5, 28.5, 1)
    b.go("D#1", 41.5, 32.0, 1)
    b.go("12", 32.0, 32.0, 1)
    b.go("13", 37.0, 16.0, 2)
    b.go("D#1", 40.0, 25.0, 2)
    out.append(Drill(
        id="rg_kick_grubber", category="attacking", minutes=10, rel=True,
        purpose=KICK_PURPOSE,
        name=suffixed(KICK_NAME, dashed("the grubber")), note=KICK_NOTE,
        home=b.players(["10", "12", "13"]), away=b.players(["D#0", "D#1"]),
        markers=[mk(38, 27, "zone")],
        ball=0,
        ball_to=[(spot(38.0, 27.0), 0), (2, 1), (2, 2)],
    ))
    return out


# ── the breakdown ─────────────────────────────────────────────────────────
def breakdown_family() -> list[Drill]:
    """A tackle, the ball placed back, and what happens over it."""
    out = []

    # quick ball: two supporters arrive low and past the ball, the 9 clears
    b = Board()
    b.put("1", 35.0, 66.0)
    b.put("2", 29.0, 74.0)
    b.put("3", 41.0, 74.0)
    b.put("9", 46.0, 80.0)
    b.put("10", 56.0, 84.0)
    b.put("D#0", 35.0, 52.0)
    b.put("D#1", 44.0, 50.0)
    b.go("1", 35.0, 60.0, 0)
    b.go("D#0", 35.0, 57.5, 0)
    b.go("2", 30.0, 66.0, 0)
    b.go("3", 40.0, 66.0, 0)
    b.go("9", 43.0, 73.0, 0)
    b.go("D#1", 41.0, 54.0, 0)
    b.go("2", 30.5, 58.0, 1)
    b.go("3", 39.5, 57.0, 1)
    b.go("9", 40.5, 67.0, 1)
    b.go("D#1", 40.0, 55.5, 1)
    b.go("10", 54.0, 78.0, 1)
    b.go("10", 52.0, 74.0, 2)
    out.append(Drill(
        id="rg_breakdown_quick_ball", category="possession", minutes=10,
        rel=True, tight=True, free=True,
        name=suffixed(BREAKDOWN_NAME, "for quick ball"), note=BREAKDOWN_NOTE,
        home=b.players(["1", "2", "3", "9", "10"]),
        away=b.players(["D#0", "D#1"]),
        ball=0,
        ball_to=[(0, 0), (spot(38.5, 65.5), 1), (4, 2)],
    ))

    # the jackal: a defender gets over the ball on his feet first; the
    # support man clears him out past it and the 9 gets it away
    b = Board()
    b.put("1", 35.0, 66.0)
    b.put("2", 29.0, 76.0)
    b.put("9", 46.0, 80.0)
    b.put("10", 56.0, 84.0)
    b.put("D#0", 35.0, 52.0)
    b.put("D#j", 44.0, 50.0)
    b.go("1", 35.0, 60.0, 0)
    b.go("D#0", 35.0, 57.5, 0)
    b.go("D#j", 40.0, 55.0, 0)
    b.go("2", 31.0, 68.0, 0)
    b.go("D#j", 37.5, 62.5, 1)                 # over the ball, on his feet
    b.go("2", 31.0, 63.0, 1)
    b.go("9", 43.0, 73.0, 1)
    b.go("2", 39.5, 57.0, 2)                 # the clear-out, past the ball
    b.go("D#j", 40.5, 54.0, 2)
    b.go("9", 40.5, 67.0, 2)
    b.go("10", 54.0, 78.0, 2)
    b.go("10", 52.0, 74.0, 3)
    out.append(Drill(
        id="rg_breakdown_jackal", category="possession", minutes=10,
        rel=True, tight=True,
        name=suffixed(BREAKDOWN_NAME, dashed("the jackal")), note=BREAKDOWN_NOTE,
        home=b.players(["1", "2", "9", "10"]),
        away=b.players(["D#0", "D#j"]),
        ball=0,
        ball_to=[(0, 0), (spot(38.5, 65.5), 1), (3, 3)],
    ))

    # the counter-ruck: here WE defend (facing down the page). Their
    # carrier is tackled and places the ball; our three drive over it,
    # their support is pushed off, and our 9 takes it and passes away —
    # back up the page, which is behind him now that we have the ball.
    b = Board()
    b.put("A", 35.0, 74.0)
    b.put("B", 30.0, 84.0)
    b.put("6", 35.0, 56.0)
    b.put("7", 29.0, 52.0)
    b.put("8", 41.0, 52.0)
    b.put("9", 47.0, 46.0)
    b.put("10", 57.0, 40.0)
    b.go("A", 35.0, 66.0, 0)
    b.go("6", 35.0, 63.5, 0)
    b.go("7", 30.0, 58.0, 0)
    b.go("8", 40.0, 58.0, 0)
    b.go("B", 32.0, 76.0, 0)
    b.go("B", 34.0, 70.0, 1)
    b.go("7", 30.5, 64.0, 1)
    b.go("8", 39.5, 64.0, 1)
    b.go("9", 42.0, 58.0, 1)
    b.go("7", 30.0, 76.0, 2)                 # drive over the ball
    b.go("8", 40.0, 76.0, 2)
    b.go("B", 34.5, 80.0, 2)
    b.go("6", 26.0, 63.0, 2)                 # the tackler rolls away
    b.go("9", 35.5, 66.5, 2)
    b.go("10", 52.0, 52.0, 2)
    b.go("10", 48.0, 58.0, 3)
    home = ["6", "7", "8", "9", "10"]
    out.append(Drill(
        id="rg_breakdown_counter_ruck", category="possession", minutes=10,
        rel=True, tight=True,
        name=suffixed(BREAKDOWN_NAME, dashed("the counter-ruck")),
        note=BREAKDOWN_NOTE,
        home=b.players(home), away=b.players(["A", "B"]),
        ball=pt(35.0, 72.0),
        ball_to=[("a0", 0), (spot(35.0, 71.0), 1), (home.index("10"), 3)],
    ))
    return out


# ── games ─────────────────────────────────────────────────────────────────
# The area is shaded with the app's zone, which is a token-sized wash 1.2
# times as wide as it is deep, so it cannot be square: at this scale it
# covers 60 m across (5 m line to 5 m line) and 50 m down (their try line
# to halfway), measured off the render (scale 6.0 drew 42.2 x 35.1 m).
GAME_ZONE_SCALE = 8.55


def game_family() -> list[Drill]:
    """A reduced area, 60 m by 50 m, shaded and marked by four cones: 5 m
    line to 5 m line, their try line back to halfway. Two passes along the
    line and a carry into the defender who comes up to meet it."""
    out = []
    for n, label in [(5, "touch 5v5"), (7, "sevens 7v7"), (8, "contact 8v8")]:
        b = Board()
        xs = [13.0 + 44.0 * i / (n - 1) for i in range(n)]
        hk = [str(i + 1) for i in range(n)]
        ak = [chr(65 + i) for i in range(n)]
        for i, (k, x) in enumerate(zip(hk, xs)):
            b.put(k, x, 58.0 + 3.5 * min(i, 3))
        for k, x in zip(ak, xs):
            b.put(k, x + 1.0, 44.0)
        b.shift(hk, 0, -2.5, 0)
        b.shift(ak, 0, 3.0, 0)
        b.shift(hk, 0, -2.5, 1)
        b.shift(ak, 0, 2.0, 1)
        b.go("3", b.x("3"), 54.0, 2)
        b.go("C", b.x("3") + 0.5, 52.5, 2)
        b.shift([k for k in ak if k != "C"], 0, 1.0, 2)
        out.append(Drill(
            id=f"rg_game_{n}v{n}", category="ssg", minutes=15, rel=True,
            tight=True, free=(n == 5),
            name=suffixed(GAME_NAME, dashed(label)), note=GAME_NOTE,
            home=b.players(hk), away=b.players(ak),
            markers=[M(35 / W, 47 / L, "zone", "", GAME_ZONE_SCALE),
                     mk(5, 22), mk(65, 22), mk(5, 72), mk(65, 72)],
            ball=0,
            ball_to=[(1, 0), (2, 1), (2, 2)],
        ))
    return out


# ── tackling, the high ball, place kicking, the exit ──────────────────────
def gaps_family() -> list[Drill]:
    out = []

    # Two channels, each a pair of cones 5 m apart. In the left one the
    # tackler meets the carrier front on; in the right one he comes from
    # the side. Each carrier has his own ball.
    b = Board()
    b.put("A", 24.5, 74.0)
    b.put("B", 44.5, 74.0)
    b.put("1", 24.5, 46.0)
    b.put("2", 35.0, 54.0)
    b.go("A", 24.5, 64.0, 0)
    b.go("B", 44.5, 64.0, 0)
    b.go("1", 24.5, 54.0, 0)
    b.go("2", 39.5, 57.0, 0)
    b.go("A", 24.5, 59.5, 1)
    b.go("1", 24.5, 57.5, 1)                 # front on, in the channel
    b.go("B", 44.5, 59.5, 1)
    b.go("2", 43.0, 58.5, 1)                 # from the side
    out.append(Drill(
        id="rg_defence_tackle", category="defending", minutes=12, rel=True,
        level="foundation", free=True, purpose=TACKLE_PURPOSE,
        name=suffixed(TACKLE_NAME, "front on and from the side"),
        note=TACKLE_NOTE,
        home=b.players(["1", "2"]), away=b.players(["A", "B"]),
        markers=[mk(22, 58), mk(27, 58), mk(42, 58), mk(47, 58)],
        ball=pt(24.5, 72.0), ball_to=[("a0", 0), ("a0", 1)],
        ball2=pt(44.5, 72.0), ball2_to=[("a1", 0), ("a1", 1)],
    ))

    # The high ball: their 10 kicks it up, his chasers start behind him;
    # our 15 takes it, gives it to the 11 coming from behind, and we go.
    b = Board()
    b.put("10#a", 35.0, 48.0)
    b.put("12#a", 25.0, 45.0)
    b.put("13#a", 45.0, 45.0)
    b.put("15", 35.0, 98.0)
    b.put("11", 12.0, 96.0)
    b.put("14", 58.0, 96.0)
    b.go("12#a", 28.0, 66.0, 0)
    b.go("13#a", 40.0, 66.0, 0)
    b.go("15", 33.0, 86.0, 0)
    b.go("11", 16.0, 94.0, 0)
    b.go("14", 54.0, 94.0, 0)
    b.go("12#a", 29.5, 80.0, 1)
    b.go("13#a", 37.5, 79.5, 1)
    b.go("11", 20.0, 93.0, 1)
    b.go("11", 22.0, 92.0, 2)
    b.go("15", 31.0, 82.5, 2)
    b.go("14", 50.0, 88.0, 2)
    b.go("11", 14.0, 66.0, 3)
    b.go("14", 46.0, 78.0, 3)
    home = ["15", "11", "14"]
    out.append(Drill(
        id="rg_kick_high_ball", category="defending", minutes=12, rel=True,
        purpose=HIGHBALL_PURPOSE,
        name=suffixed(HIGHBALL_NAME, dashed("the contest and the counter")),
        note=HIGHBALL_NOTE,
        home=b.players(home), away=b.players(["10#a", "12#a", "13#a"]),
        markers=[mk(33, 84, "zone")],
        ball=pt(35.0, 50.0),
        ball_to=[(spot(33.0, 84.0), 0), (0, 1), (1, 2), (1, 3)],
    ))

    # Place kicking: the same steps back and across every time.
    out.append(Drill(
        id="rg_kick_at_goal", category="finishing", minutes=10, rel=True,
        level="foundation", purpose=GOALKICK_PURPOSE,
        setup={"en": "One kicker, a kicking tee and a bag of balls; five kicking spots across the 22 metre line, two kicks from each",
               "en-GB": "One kicker, a kicking tee and a bag of balls; five kicking spots across the 22 metre line, two kicks from each",
               "zh-CN": "一名踢球者、一个球座和一袋球；沿 22 米线横向设五个踢球点，每点踢两脚",
               "zh-TW": "一名踢球者、一個球座和一袋球；沿 22 公尺線橫向設五個踢球點，每點踢兩腳"},
        name=suffixed(GOALKICK_NAME, dashed("the routine")), note=GOALKICK_NOTE,
        home=[P(0.42, 0.34, "10", moves=[(0.375, 0.365, 0), (0.405, 0.345, 1)])],
        markers=[M(0.42, 0.32, "square", ""), mk(35, 15, "zone")],
        ball=(0.42, 0.325),
        ball_moves=[(35 / W, 15 / L, 2)],
    ))

    # The exit: two pick-and-drives off the 9 with the ball placed back
    # each time, then the 9 to the 10 and the kick to grass by touch,
    # well away from their 15.
    b = Board()
    b.put("9", 30.0, 110.0)
    b.put("1", 22.0, 116.0)
    b.put("4", 38.0, 118.0)
    b.put("10", 46.0, 122.0)
    b.put("D#0", 24.0, 98.0)
    b.put("D#1", 36.0, 98.0)
    b.put("15#a", 30.0, 56.0)
    b.go("1", 23.0, 113.0, 0)                # 9 to 1, from depth
    b.shift(["D#0", "D#1"], 0, 2.0, 0)
    b.go("1", 25.0, 106.0, 1)                # carries into contact
    b.go("D#0", 25.0, 104.0, 1)
    b.go("4", 37.0, 117.0, 2)
    b.go("D#1", 35.0, 102.0, 2)
    b.go("4", 36.0, 113.0, 3)                # 9 to 4
    b.go("D#0", 28.0, 102.0, 3)
    b.go("4", 37.0, 106.0, 4)                # into contact
    b.go("D#1", 37.0, 104.0, 4)
    b.go("9", 41.5, 111.0, 4)
    b.go("1", 27.0, 110.0, 4)
    b.go("10", 50.0, 119.0, 5)
    b.go("D#0", 31.0, 103.0, 5)
    b.go("10", 52.0, 118.0, 6)               # 9 to 10, deep
    b.go("15#a", 26.0, 60.0, 6)
    b.go("15#a", 24.0, 64.0, 7)
    b.go("D#0", 40.0, 106.0, 7)
    home = ["9", "1", "4", "10"]
    out.append(Drill(
        id="rg_kick_exit", category="possession", minutes=14, rel=True,
        tight=True, level="advanced", purpose=EXIT_PURPOSE,
        name=suffixed(EXIT_NAME, dashed("two phases and the kick")),
        note=EXIT_NOTE,
        home=b.players(home), away=b.players(["D#0", "D#1", "15#a"]),
        markers=[mk(66, 74, "zone")],
        ball=0, ball_spot=pt(30.0, 108.0),
        ball_to=[(1, 0), (1, 1), (spot(28.5, 110.0), 2), (2, 3), (2, 4),
                 (spot(40.0, 110.0), 5), (3, 6), (spot(66.0, 74.0), 7)],
    ))
    return out


# The maul's names are written whole: "Maul" + "defending it" borrowed a
# hockey variant whose Chinese is "defending a short corner".
MAUL_NAMES = {
    "drive": _t12(
        "Maul — driving off the lineout", "冒尔 争边球后推进", "冒爾 爭邊球後推進",
        "モール ラインアウトからのドライブ", "몰 라인아웃 후 드라이브",
        "Maul — empuje tras el lineout", "Maul — poussée après la touche",
        "Maul — dorongan dari lineout", "Maul — tolakan dari lineout",
        "มอล ดันต่อจากไลน์เอาต์", "Maul — đẩy từ tình huống ném biên"),
    "defend": _t12(
        "Maul — defending the drive", "冒尔 防守冒尔推进", "冒爾 防守冒爾推進",
        "モール ドライブを止める守り", "몰 드라이브 수비",
        "Maul — defender el empuje", "Maul — défendre la poussée",
        "Maul — bertahan dari dorongan", "Maul — bertahan daripada tolakan",
        "มอล การป้องกันการดัน", "Maul — phòng thủ cú đẩy"),
}


def maul_family() -> list[Drill]:
    """The lineout's second act: the jumper takes it, the pod binds on
    him, the ball goes to the No. 8 at the back, and the maul drives — or,
    defended, is stopped where it formed."""
    out = []
    for key in ("drive", "defend"):
        b = Board()
        line_y = 40.0
        keys, dk = _lineout(b, ["4", "5", "6", "7", "8"], line_y)
        jx = b.x("5")
        jd = min(dk, key=lambda k: abs(b.x(k) - jx))
        b.go(jd, jx, line_y - 0.5, 0)
        # The pod binds on the jumper: one either side of him, two behind
        # them — a row clear of the next by a figure's height at this zoom.
        b.go("4", jx - 0.75, line_y + 0.9, 1)
        b.go("6", jx + 0.75, line_y + 0.9, 1)
        b.go("7", jx - 0.4, line_y + 2.5, 1)
        b.go("8", jx + 0.4, line_y + 2.5, 1)
        b.go(jd, jx, line_y - 0.6, 2)                # their front engages
        b.go("2", jx, line_y + 4.1, 2)               # the thrower joins
        # their pod binds onto the front of it: two beside their jumper,
        # two behind them
        others = [k for k in dk if k != jd]
        for k, (x, y) in zip(others, [(jx - 0.75, line_y - 1.0),
                                      (jx + 0.75, line_y - 1.0),
                                      (jx - 0.4, line_y - 2.6),
                                      (jx + 0.4, line_y - 2.6)]):
            b.go(k, x, y, 2)
        mauls = ["5", "4", "6", "7", "8", "2"]
        if key == "drive":
            b.shift(mauls, 0, -4.0, 3)
            b.shift(dk, 0, -4.0, 3)
            b.shift(mauls, 0, -5.0, 4)
            b.shift(dk, 0, -5.0, 4)
            ball_to = [(spot(jx, line_y), 0), (2, 1), (5, 2), (5, 3), (5, 4)]
            view = _lineout_view(line_y, 15.0, 7.0)
        else:
            # A sixth defender comes in from his own side, behind the
            # hindmost of theirs, and holds it up.
            b.put("D#x", 13.5, line_y - 7.0)
            dk = dk + ["D#x"]
            b.shift(mauls, 0, -1.0, 3)               # held where it formed
            b.go("D#x", jx, line_y - 4.2, 3)
            ball_to = [(spot(jx, line_y), 0), (2, 1), (5, 2), (5, 3)]
            view = _lineout_view(line_y, 9.0, 7.0)
        home = ["2"] + keys
        out.append(Drill(
            id=f"rg_maul_{key}", category="setpiece", minutes=12, rel=True,
            tight=True, free=(key == "drive"),
            view=view,
            name=MAUL_NAMES[key], note=MAUL_NOTE,
            home=b.players(home), away=b.players(dk),
            ball=0, ball_spot=pt(-0.3, line_y),
            ball_to=ball_to,
        ))
    return out


def rugby_library() -> list[Drill]:
    return (handling_family() + phase_family() + breakdown_family()
            + move_family() + kicking_family() + finishing_family()
            + defence_family() + setpiece_family() + maul_family()
            + game_family() + gaps_family())
