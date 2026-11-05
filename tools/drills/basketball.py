"""The basketball library."""
from .engine import Drill, M, P, behind, ring, suffixed


def basketball_drills() -> list[Drill]:
    """Half-court unless stated, attacking the basket at the top (y small).

    Landmarks in court coordinates: rim (0.5, 0.06), free-throw line
    (0.5, 0.19), top of the arc (0.5, 0.30), wings (0.15, 0.26) and
    (0.85, 0.26), corners (0.05, 0.11) / (0.95, 0.11), elbows (0.33, 0.19)
    and (0.67, 0.19), blocks (0.38, 0.10) / (0.62, 0.10), half court y = 0.5.
    """
    return [
        # ── warm-up ──────────────────────────────────────────────────────────
        Drill(
            id="bb_layup_lines", category="warmup", minutes=8, rel=True, free=True,
            name={"en": "Layup lines", "en-GB": "Layup lines", "zh-CN": "上篮轮转",
                  "zh-TW": "上籃輪轉", "ja-JP": "レイアップライン", "ko-KR": "레이업 라인",
                  "es-ES": "Filas de bandeja", "fr-FR": "Lignes de layup",
                  "id-ID": "Barisan layup", "ms-MY": "Barisan layup",
                  "th-TH": "แถวเลย์อัพ", "vi-VN": "Hàng lên rổ"},
            note={"en": "Inside foot, outside hand, eyes on the square — not on the ball.",
                  "en-GB": "Inside foot, outside hand, eyes on the square — not on the ball.",
                  "zh-CN": "内侧脚起跳、外侧手上篮，眼睛盯篮板方框，不是盯球。",
                  "zh-TW": "內側腳起跳、外側手上籃，眼睛盯籃板方框，不是盯球。",
                  "ja-JP": "内側の足で踏み切り外側の手で。目はボードの四角、ボールではない。",
                  "ko-KR": "안쪽 발로 점프, 바깥쪽 손으로 마무리. 시선은 백보드 사각형.",
                  "es-ES": "Pie interior, mano exterior, mirada al cuadro del tablero.",
                  "fr-FR": "Pied intérieur, main extérieure, regard sur le carré de la planche.",
                  "id-ID": "Kaki dalam, tangan luar, mata ke kotak papan.",
                  "ms-MY": "Kaki dalam, tangan luar, mata pada kotak papan.",
                  "th-TH": "เท้าใน มือนอก สายตาจับกรอบสี่เหลี่ยมบนแป้น",
                  "vi-VN": "Chân trong, tay ngoài, mắt nhìn ô vuông trên bảng."},
            home=[
                P(0.18, 0.45, "1", moves=[(0.34, 0.20, 0), (0.44, 0.09, 1)]),
                P(0.82, 0.45, "2", moves=[(0.66, 0.20, 0), (0.56, 0.09, 1)]),
                P(0.18, 0.58, "3"), P(0.82, 0.58, "4"),
            ],
            ball=0,
            # passed to the far lane, finished off the glass
            ball_to=[(1, 0), ((0.50, 0.05), 1)],
        ),
        Drill(
            id="bb_two_ball_dribble", category="warmup", minutes=6, rel=True, free=True,
            name={"en": "Two-ball dribbling", "en-GB": "Two-ball dribbling", "zh-CN": "双球运球",
                  "zh-TW": "雙球運球", "ja-JP": "2ボールドリブル", "ko-KR": "두 개 공 드리블",
                  "es-ES": "Bote con dos balones", "fr-FR": "Dribble à deux ballons",
                  "id-ID": "Dribel dua bola", "ms-MY": "Dribel dua bola",
                  "th-TH": "เลี้ยงสองลูก", "vi-VN": "Dẫn hai bóng"},
            note={"en": "Head up the whole way. If you can't call out the coach's fingers, you're watching the ball.",
                  "en-GB": "Head up the whole way. If you can't call out the coach's fingers, you're watching the ball.",
                  "zh-CN": "全程抬头。喊不出教练比的数字，就说明你在看球。",
                  "zh-TW": "全程抬頭。喊不出教練比的數字，就說明你在看球。",
                  "ja-JP": "最後まで顔を上げる。コーチの指の数が言えないなら、ボールを見ている証拠。",
                  "ko-KR": "끝까지 고개를 들어라. 코치의 손가락 수를 못 부르면 공을 보고 있는 것이다.",
                  "es-ES": "Cabeza arriba todo el rato: si no cantas los dedos del entrenador, miras el balón.",
                  "fr-FR": "Tête haute jusqu'au bout. Si tu ne peux pas annoncer les doigts du coach, tu regardes le ballon.",
                  "id-ID": "Kepala tegak terus. Kalau tak bisa menyebut jari pelatih, kamu melihat bola.",
                  "ms-MY": "Kepala tegak sepanjang masa.",
                  "th-TH": "เงยหน้าตลอด ถ้าบอกจำนวนนิ้วของโค้ชไม่ได้ แปลว่ากำลังมองบอล",
                  "vi-VN": "Ngẩng đầu suốt. Không đọc được số ngón tay của HLV nghĩa là đang nhìn bóng."},
            home=[P(0.5, 0.80, "1", moves=[(0.5, 0.55, 0), (0.5, 0.30, 1)])],
            markers=[M(0.35, 0.70), M(0.65, 0.70), M(0.35, 0.45), M(0.65, 0.45)],
            ball=0,
            # Two of them, which is the name of the drill: one in each hand,
            # down and back through the cones. The board drew one.
            balls=2,
            # dribbled the length, never leaving his hands
            ball_follow=0,
        ),
        Drill(
            id="bb_star_passing", category="warmup", minutes=8, rel=True,
            name={"en": "Star passing", "en-GB": "Star passing", "zh-CN": "五角星传球",
                  "zh-TW": "五角星傳球", "ja-JP": "スターパス", "ko-KR": "별 모양 패스",
                  "es-ES": "Pase en estrella", "fr-FR": "Passes en étoile",
                  "id-ID": "Umpan bintang", "ms-MY": "Hantaran bintang",
                  "th-TH": "ส่งบอลรูปดาว", "vi-VN": "Chuyền hình sao"},
            note={"en": "Pass and go — behind the player you passed to. A pass without movement is a stop.",
                  "en-GB": "Pass and go — behind the player you passed to. A pass without movement is a stop.",
                  "zh-CN": "传完就跑，跑到你传球对象身后。不带跑动的传球等于停球。",
                  "zh-TW": "傳完就跑，跑到你傳球對象身後。不帶跑動的傳球等於停球。",
                  "ja-JP": "パスしたら走る、渡した相手の後ろへ。動きのないパスは停滞。",
                  "ko-KR": "패스하고 달려라, 준 사람 뒤로. 움직임 없는 패스는 정지다.",
                  "es-ES": "Pasa y corre detrás de quien recibió. Un pase sin movimiento es una parada.",
                  "fr-FR": "Passe et cours derrière celui qui reçoit. Une passe sans mouvement est un arrêt.",
                  "id-ID": "Umpan lalu berlari di belakang penerima.",
                  "ms-MY": "Hantar dan berlari di belakang penerima.",
                  "th-TH": "ส่งแล้ววิ่งไปด้านหลังคนที่รับ การส่งที่ไม่มีการเคลื่อนที่คือการหยุด",
                  "vi-VN": "Chuyền rồi chạy ra sau người nhận."},
            # Follow the pass, one beat behind it, and finish the far side
            # of the man you passed to — that is what "pass and go behind
            # him" means, and it is the drill's whole coaching point. These
            # used to stop at 82% of the way, which is BETWEEN passer and
            # receiver: on the board the follower stood in front of the man
            # he had just passed to, saying the opposite of the note.
            # behind() keeps him off the receiver's exact point, which is
            # what the 82% was really guarding against.
            home=[
                P(0.500, 0.340, "1", moves=[(*behind((0.500, 0.340), (0.300, 0.629)), 1)]),
                P(0.177, 0.451, "2", moves=[(*behind((0.177, 0.451), (0.700, 0.629)), 4)]),
                P(0.300, 0.629, "3", moves=[(*behind((0.300, 0.629), (0.823, 0.451)), 2)]),
                P(0.700, 0.629, "4"),
                P(0.823, 0.451, "5", moves=[(*behind((0.823, 0.451), (0.177, 0.451)), 3)]),
            ],
            ball=0,
            # The star: every pass skips a corner, so the ball draws the
            # five-pointed shape instead of running round the pentagon.
            # The passer follows his own pass, one beat behind it.
            ball_to=[(2, 0), (4, 1), (1, 2), (3, 3)],
        ),

        # ── offense / ball movement ──────────────────────────────────────────
        Drill(
            id="bb_five_out_spacing", category="possession", minutes=12, rel=True, free=True,
            name={"en": "Five-out spacing", "en-GB": "Five-out spacing", "zh-CN": "五外站位",
                  "zh-TW": "五外站位", "ja-JP": "ファイブアウトの間隔", "ko-KR": "파이브 아웃 간격",
                  "es-ES": "Espaciado 5 abiertos", "fr-FR": "Spacing cinq dehors",
                  "id-ID": "Spasi lima di luar", "ms-MY": "Jarak lima di luar",
                  "th-TH": "การยืนแบบไฟฟ์เอาท์", "vi-VN": "Giãn biên năm ngoài"},
            note={"en": "Fifteen feet apart. One defender must never be able to guard two of you.",
                  "en-GB": "Fifteen feet apart. One defender must never be able to guard two of you.",
                  "zh-CN": "间距保持四五米。**一个防守人永远不能同时看住你们两个**。",
                  "zh-TW": "間距保持四五米。一個防守人永遠不能同時看住你們兩個。",
                  "ja-JP": "4〜5m空ける。1人のディフェンスが2人を見られる距離に立たない。",
                  "ko-KR": "4~5m 간격. 수비 한 명이 둘을 동시에 볼 수 있으면 안 된다.",
                  "es-ES": "Cuatro o cinco metros entre vosotros: un defensor nunca debe poder marcar a dos.",
                  "fr-FR": "Quatre à cinq mètres d'écart : un défenseur ne doit jamais pouvoir en couvrir deux.",
                  "id-ID": "Jarak 4-5 meter. Satu pemain bertahan tak boleh bisa menjaga dua orang.",
                  "ms-MY": "Jarak 4-5 meter. Seorang bek tidak boleh menjaga dua orang.",
                  "th-TH": "ห่างกัน 4-5 เมตร อย่าให้กองหลังคนเดียวคุมได้สองคน",
                  "vi-VN": "Cách nhau 4-5 mét. Một hậu vệ không được kèm cùng lúc hai người."},
            home=[
                P(0.50, 0.34, "1", moves=[(0.58, 0.10, 1), (0.72, 0.33, 2)]),
                P(0.14, 0.28, "2"),
                P(0.86, 0.28, "3", moves=[(0.46, 0.35, 2)]),
                P(0.06, 0.12, "4"),
                P(0.94, 0.11, "5"),
            ],
            ball=0,
            # pass, basket-cut, fill — and the ball really travels on
            ball_to=[(1, 0), (3, 2)],
        ),
        Drill(
            id="bb_pick_and_roll", category="attacking", minutes=15, rel=True, free=True,
            name={"en": "Pick and roll", "en-GB": "Pick and roll", "zh-CN": "挡拆下顺",
                  "zh-TW": "擋拆下順", "ja-JP": "ピック＆ロール", "ko-KR": "픽 앤 롤",
                  "es-ES": "Bloqueo y continuación", "fr-FR": "Pick and roll",
                  "id-ID": "Pick and roll", "ms-MY": "Pick and roll",
                  "th-TH": "พิคแอนด์โรล", "vi-VN": "Chắn và cắt"},
            note={"en": "Set the screen and hold it. The guard's job is to turn the corner tight enough that both defenders are behind him.",
                  "en-GB": "Set the screen and hold it. The guard's job is to turn the corner tight enough that both defenders are behind him.",
                  "zh-CN": "掩护要站稳别动。持球人要贴着掩护转过去，紧到两个防守人都被甩在身后。",
                  "zh-TW": "掩護要站穩別動。持球人要貼著掩護轉過去，緊到兩個防守人都被甩在身後。",
                  "ja-JP": "スクリーンは立てて動かない。ハンドラーは肩を擦るほど密着して回り、2人を背中に置く。",
                  "ko-KR": "스크린은 세우고 버텨라. 핸들러는 어깨를 스칠 만큼 붙어 돌아 두 수비를 등 뒤에 둔다.",
                  "es-ES": "Pon el bloqueo y aguántalo. El base debe girar tan pegado que ambos defensores queden detrás.",
                  "fr-FR": "Pose l'écran et tiens-le. Le meneur doit tourner assez serré pour laisser les deux défenseurs derrière.",
                  "id-ID": "Pasang screen dan tahan. Pengatur bola harus berputar rapat agar dua bek tertinggal.",
                  "ms-MY": "Pasang skrin dan tahan. Pengendali bola pusing rapat.",
                  "th-TH": "ตั้งสกรีนแล้วอยู่นิ่ง คนเลี้ยงต้องเลี้ยวชิดจนกองหลังทั้งสองอยู่ข้างหลัง",
                  "vi-VN": "Dựng màn chắn và giữ yên. Người cầm bóng phải vòng sát để cả hai hậu vệ ở lại sau lưng."},
            home=[
                P(0.50, 0.34, "1", moves=[(0.74, 0.28, 1), (0.68, 0.16, 2)]),
                P(0.67, 0.19, "5", moves=[(0.64, 0.35, 0), (0.46, 0.09, 2)]),
                P(0.14, 0.28, "2"), P(0.06, 0.11, "3"), P(0.95, 0.12, "4"),
            ],
            away=[
                P(0.50, 0.27, "x1", moves=[(0.62, 0.28, 1), (0.74, 0.21, 2)]),
                P(0.62, 0.11, "x5", moves=[(0.66, 0.21, 1), (0.54, 0.13, 2)]),
            ],
            ball=0,
            # off the screen, pocket pass to the roll
            ball_to=[(0, 1), (1, 2)],
        ),
        Drill(
            id="bb_pick_and_pop", category="attacking", minutes=12, rel=True,
            name={"en": "Pick and pop", "en-GB": "Pick and pop", "zh-CN": "挡拆外弹",
                  "zh-TW": "擋拆外彈", "ja-JP": "ピック＆ポップ", "ko-KR": "픽 앤 팝",
                  "es-ES": "Bloqueo y salida", "fr-FR": "Pick and pop",
                  "id-ID": "Pick and pop", "ms-MY": "Pick and pop",
                  "th-TH": "พิคแอนด์ป๊อป", "vi-VN": "Chắn và bật ra"},
            note={"en": "Same screen, opposite read: if the big's defender steps up, he pops instead of rolling.",
                  "en-GB": "Same screen, opposite read: if the big's defender steps up, he pops instead of rolling.",
                  "zh-CN": "同样的掩护，反向判断：只要对方内线上提，掩护人就外弹而不是下顺。",
                  "zh-TW": "同樣的掩護，反向判斷：只要對方內線上提，掩護人就外彈而不是下順。",
                  "ja-JP": "同じスクリーン、逆の判断。ビッグのマークが出てきたらロールではなくポップ。",
                  "ko-KR": "같은 스크린, 반대 판단. 빅맨 수비가 나오면 롤 대신 팝.",
                  "es-ES": "Mismo bloqueo, lectura opuesta: si el defensor del pívot sale, éste abre en vez de continuar.",
                  "fr-FR": "Même écran, lecture inverse : si le défenseur du pivot monte, il ressort au lieu de plonger.",
                  "id-ID": "Screen sama, baca sebaliknya: kalau bek big man maju, dia keluar bukan masuk.",
                  "ms-MY": "Skrin sama, bacaan bertentangan.",
                  "th-TH": "สกรีนเดิม แต่อ่านตรงข้าม ถ้ากองหลังของบิ๊กแมนขึ้นมา ให้ถอยออกแทนการมุด",
                  "vi-VN": "Cùng màn chắn, đọc ngược lại: nếu hậu vệ kèm trung phong dâng lên thì bật ra thay vì cắt vào."},
            home=[
                P(0.50, 0.34, "1", moves=[(0.74, 0.28, 1), (0.68, 0.16, 2)]),
                P(0.67, 0.19, "4", moves=[(0.64, 0.35, 0), (0.44, 0.36, 2)]),
                P(0.14, 0.28, "2"), P(0.06, 0.11, "3"), P(0.95, 0.12, "5"),
            ],
            away=[
                P(0.50, 0.27, "x1", moves=[(0.62, 0.28, 1), (0.74, 0.21, 2)]),
                P(0.62, 0.11, "x4", moves=[(0.78, 0.34, 1), (0.56, 0.31, 2)]),
            ],
            ball=0,
            # off the screen, then back to the 4 popping
            ball_to=[(0, 1), (1, 2)],
        ),
        Drill(
            id="bb_backdoor_cut", category="attacking", minutes=10, rel=True, free=True,
            name={"en": "Backdoor cut", "en-GB": "Backdoor cut", "zh-CN": "反跑空切",
                  "zh-TW": "反跑空切", "ja-JP": "バックドアカット", "ko-KR": "백도어 컷",
                  "es-ES": "Corte de puerta atrás", "fr-FR": "Backdoor",
                  "id-ID": "Potongan backdoor", "ms-MY": "Potongan backdoor",
                  "th-TH": "ตัดหลังแบ็คดอร์", "vi-VN": "Cắt sau lưng"},
            note={"en": "The cut is the answer to an overplay: two steps out, then hard to the rim the moment he turns his head.",
                  "en-GB": "The cut is the answer to an overplay: two steps out, then hard to the rim the moment he turns his head.",
                  "zh-CN": "对手过度贴防就反跑：先向外两步，等他一转头立刻直插篮下。",
                  "zh-TW": "對手過度貼防就反跑：先向外兩步，等他一轉頭立刻直插籃下。",
                  "ja-JP": "オーバープレイへの答え。外に2歩、相手が顔を向けた瞬間にリムへ全力。",
                  "ko-KR": "과도한 밀착에 대한 답. 밖으로 두 걸음, 상대가 고개를 돌리는 순간 림으로.",
                  "es-ES": "Respuesta al defensor que se pasa: dos pasos fuera y al aro en cuanto gire la cabeza.",
                  "fr-FR": "Réponse au surmarquage : deux pas dehors, puis plein axe dès qu'il tourne la tête.",
                  "id-ID": "Jawaban untuk penjagaan berlebihan: dua langkah keluar, lalu ke ring saat dia menoleh.",
                  "ms-MY": "Jawapan kepada penjagaan berlebihan.",
                  "th-TH": "คำตอบของการประกบเกิน ก้าวออกสองก้าวแล้วพุ่งเข้าห่วงทันทีที่เขาหันหน้า",
                  "vi-VN": "Câu trả lời cho kèm quá sát: bước ra hai bước rồi cắt thẳng vào rổ."},
            home=[
                P(0.50, 0.33, "1"),
                P(0.86, 0.26, "2", moves=[(0.92, 0.33, 0), (0.64, 0.09, 1)]),
                P(0.14, 0.28, "3"), P(0.36, 0.09, "5"),
            ],
            away=[P(0.75, 0.20, "x2",
                    moves=[(0.84, 0.28, 0), (0.82, 0.22, 1)])],
            ball=0,
            # the fake to the wing, then the bounce pass behind X2
            ball_to=[(1, 1)],
        ),
        Drill(
            id="bb_dho", category="attacking", minutes=12, rel=True,
            name={"en": "Dribble handoff", "en-GB": "Dribble handoff", "zh-CN": "运球手递手",
                  "zh-TW": "運球手遞手", "ja-JP": "ドリブルハンドオフ", "ko-KR": "드리블 핸드오프",
                  "es-ES": "Entrega en bote", "fr-FR": "Handoff en dribble",
                  "id-ID": "Serah bola sambil dribel", "ms-MY": "Serahan sambil dribel",
                  "th-TH": "ส่งมือต่อมือขณะเลี้ยง", "vi-VN": "Trao bóng khi dẫn"},
            note={"en": "Hand it off shoulder to shoulder — a gap the size of a defender is a gap he will use.",
                  "en-GB": "Hand it off shoulder to shoulder — a gap the size of a defender is a gap he will use.",
                  "zh-CN": "手递手时肩靠肩，留出一个防守人宽的缝，他就会从缝里挤过来。",
                  "zh-TW": "手遞手時肩靠肩，留出一個防守人寬的縫，他就會從縫裡擠過來。",
                  "ja-JP": "肩と肩を触れさせて渡す。ディフェンス1人分の隙間は必ず通られる。",
                  "ko-KR": "어깨를 맞대고 건네라. 수비 한 명이 지나갈 틈이면 반드시 지나간다.",
                  "es-ES": "Entrega hombro con hombro: un hueco del tamaño de un defensor es un hueco que usará.",
                  "fr-FR": "Remise épaule contre épaule : un espace de la taille d'un défenseur sera utilisé.",
                  "id-ID": "Serahkan bahu ke bahu — celah seukuran pemain bertahan pasti dilewati.",
                  "ms-MY": "Serah bahu ke bahu.",
                  "th-TH": "ส่งบอลไหล่ชนไหล่ ช่องว่างขนาดคนหนึ่งคือช่องที่เขาจะเสียบ",
                  "vi-VN": "Trao bóng vai kề vai — khe hở vừa một hậu vệ là khe hở sẽ bị luồn."},
            home=[
                P(0.28, 0.33, "1", moves=[(0.44, 0.31, 0), (0.30, 0.18, 2)]),
                P(0.74, 0.31, "2", moves=[(0.58, 0.31, 1), (0.70, 0.16, 2)]),
                P(0.06, 0.11, "3"), P(0.94, 0.11, "4"), P(0.34, 0.09, "5"),
            ],
            away=[P(0.82, 0.25, "x2", moves=[(0.66, 0.24, 1), (0.76, 0.20, 2)])],
            ball=0,
            # dribbled at the 2, handed off, downhill
            ball_to=[(0, 0), (1, 1), (1, 2)],
        ),
        Drill(
            id="bb_horns_set", category="possession", minutes=12, rel=True,
            name={"en": "Horns set", "en-GB": "Horns set", "zh-CN": "牛角战术",
                  "zh-TW": "牛角戰術", "ja-JP": "ホーンズ", "ko-KR": "혼스 세트",
                  "es-ES": "Sistema Horns", "fr-FR": "Système Horns",
                  "id-ID": "Set Horns", "ms-MY": "Set Horns",
                  "th-TH": "แผนฮอร์นส์", "vi-VN": "Đội hình Horns"},
            note={"en": "Two bigs at the elbows, two in the corners. Whichever screen the defence takes away, the other one is open.",
                  "en-GB": "Two bigs at the elbows, two in the corners. Whichever screen the defence takes away, the other one is open.",
                  "zh-CN": "两个内线站罚球线两肘，两人站底角。防守封掉哪一侧掩护，另一侧就是空的。",
                  "zh-TW": "兩個內線站罰球線兩肘，兩人站底角。防守封掉哪一側掩護，另一側就是空的。",
                  "ja-JP": "ビッグ2人がエルボー、2人がコーナー。守備がどちらのスクリーンを消しても、逆が空く。",
                  "ko-KR": "빅맨 둘은 엘보, 둘은 코너. 수비가 어느 스크린을 지우든 반대쪽이 열린다.",
                  "es-ES": "Dos altos en los codos, dos en las esquinas: el bloqueo que quiten deja libre el otro.",
                  "fr-FR": "Deux intérieurs aux coudes, deux aux corners : l'écran qu'ils enlèvent en libère un autre.",
                  "id-ID": "Dua big man di elbow, dua di sudut. Screen mana pun yang ditutup, satunya terbuka.",
                  "ms-MY": "Dua big man di elbow, dua di penjuru.",
                  "th-TH": "บิ๊กแมนสองคนที่เอลโบว์ อีกสองอยู่มุม ปิดสกรีนฝั่งไหน อีกฝั่งก็ว่าง",
                  "vi-VN": "Hai trung phong ở elbow, hai người ở góc. Chặn màn nào thì màn kia mở."},
            home=[
                P(0.50, 0.34, "1", moves=[(0.72, 0.26, 1)]),
                P(0.33, 0.19, "4", moves=[(0.42, 0.28, 0)]),
                P(0.67, 0.19, "5", moves=[(0.58, 0.28, 0), (0.52, 0.10, 2)]),
                P(0.05, 0.11, "2"), P(0.95, 0.11, "3"),
            ],
            ball=0,
            # off the double screen, pocket pass to the 5 diving
            ball_to=[(0, 1), (2, 2)],
        ),

        # ── finishing / shooting ─────────────────────────────────────────────
        Drill(
            id="bb_catch_and_shoot", category="finishing", minutes=10, rel=True, free=True,
            name={"en": "Catch and shoot", "en-GB": "Catch and shoot", "zh-CN": "接球就投",
                  "zh-TW": "接球就投", "ja-JP": "キャッチ＆シュート", "ko-KR": "캐치 앤 슛",
                  "es-ES": "Recibir y tirar", "fr-FR": "Catch and shoot",
                  "id-ID": "Tangkap dan tembak", "ms-MY": "Tangkap dan baling",
                  "th-TH": "รับแล้วยิง", "vi-VN": "Bắt và ném"},
            note={"en": "Feet and hands ready before the pass arrives. The shot starts on the catch, not after it.",
                  "en-GB": "Feet and hands ready before the pass arrives. The shot starts on the catch, not after it.",
                  "zh-CN": "球到之前脚步和手型就要准备好。出手动作从接球那一刻开始，不是接完再开始。",
                  "zh-TW": "球到之前腳步和手型就要準備好。出手動作從接球那一刻開始，不是接完再開始。",
                  "ja-JP": "パスが来る前に足と手を作る。シュートはキャッチの瞬間に始まる。",
                  "ko-KR": "패스가 오기 전에 발과 손을 준비하라. 슛은 잡는 순간 시작된다.",
                  "es-ES": "Pies y manos listos antes de recibir. El tiro empieza en la recepción.",
                  "fr-FR": "Appuis et mains prêts avant la passe. Le tir commence à la réception.",
                  "id-ID": "Kaki dan tangan siap sebelum bola datang. Tembakan mulai saat menangkap.",
                  "ms-MY": "Kaki dan tangan sedia sebelum bola tiba.",
                  "th-TH": "เตรียมเท้าและมือก่อนบอลมา การยิงเริ่มตั้งแต่จังหวะรับ",
                  "vi-VN": "Chân và tay sẵn sàng trước khi bóng đến. Cú ném bắt đầu từ lúc bắt bóng."},
            home=[
                P(0.62, 0.08, "5"),
                P(0.18, 0.30, "2", moves=[(0.08, 0.16, 0)]),
                P(0.82, 0.30, "3", moves=[(0.92, 0.16, 1)]),
            ],
            ball=0,
            # each shooter is on his spot a beat before the ball arrives
            ball_to=[(1, 1), (2, 2), ((0.50, 0.05), 3)],
        ),
        Drill(
            id="bb_post_finish", category="finishing", minutes=10, rel=True,
            name={"en": "Post finishing", "en-GB": "Post finishing", "zh-CN": "低位终结",
                  "zh-TW": "低位終結", "ja-JP": "ポストの仕上げ", "ko-KR": "포스트 마무리",
                  "es-ES": "Definición en poste", "fr-FR": "Finition au poste",
                  "id-ID": "Penyelesaian di post", "ms-MY": "Penamat di post",
                  "th-TH": "จบสกอร์ในโพสต์", "vi-VN": "Kết thúc ở post"},
            note={"en": "Seal, catch, one dribble, finish over the shoulder away from the help.",
                  "en-GB": "Seal, catch, one dribble, finish over the shoulder away from the help.",
                  "zh-CN": "先卡住位、接球、一次运球、朝远离协防的那侧翻身出手。",
                  "zh-TW": "先卡住位、接球、一次運球、朝遠離協防的那側翻身出手。",
                  "ja-JP": "シール、キャッチ、ワンドリブル、ヘルプと逆の肩越しに決める。",
                  "ko-KR": "자리를 먼저 잡고, 받고, 원 드리블, 헬프 반대쪽 어깨로 마무리.",
                  "es-ES": "Gana la posición, recibe, un bote y define por el hombro contrario a la ayuda.",
                  "fr-FR": "Scelle, réceptionne, un dribble, finis par-dessus l'épaule opposée à l'aide.",
                  "id-ID": "Kunci posisi, tangkap, satu dribel, selesaikan menjauhi help.",
                  "ms-MY": "Kunci kedudukan, tangkap, satu dribel, selesaikan.",
                  "th-TH": "ปิดตัว รับบอล เลี้ยงหนึ่งครั้ง แล้วจบด้านตรงข้ามกับคนมาช่วย",
                  "vi-VN": "Chèn vị trí, bắt bóng, một nhịp dẫn, kết thúc phía xa người bọc lót."},
            home=[
                P(0.34, 0.12, "5", moves=[(0.46, 0.07, 1)]),
                P(0.50, 0.32, "1"),
            ],
            away=[
                P(0.34, 0.19, "x5", moves=[(0.36, 0.13, 1)]),
                P(0.70, 0.16, "x4", moves=[(0.62, 0.09, 1)]),
            ],
            ball=1,
            # entered to the 5; he finishes through contact
            ball_to=[(0, 0), (0, 1), ((0.50, 0.04), 2)],
        ),

        # ── defending ────────────────────────────────────────────────────────
        Drill(
            id="bb_closeout", category="defending", minutes=10, rel=True, free=True,
            name={"en": "Closeouts", "en-GB": "Closeouts", "zh-CN": "封盖扑防",
                  "zh-TW": "封蓋撲防", "ja-JP": "クローズアウト", "ko-KR": "클로즈아웃",
                  "es-ES": "Cierres", "fr-FR": "Close-out",
                  "id-ID": "Closeout", "ms-MY": "Closeout",
                  "th-TH": "โคลสเอาท์", "vi-VN": "Áp sát"},
            note={"en": "Sprint two thirds, chop the last third with short steps and a high hand. Flying at a shooter is how you foul him.",
                  "en-GB": "Sprint two thirds, chop the last third with short steps and a high hand. Flying at a shooter is how you foul him.",
                  "zh-CN": "前三分之二全速冲，最后三分之一碎步刹车、举手。冲太猛就是送犯规。",
                  "zh-TW": "前三分之二全速衝，最後三分之一碎步剎車、舉手。衝太猛就是送犯規。",
                  "ja-JP": "3分の2は全力、残りは細かいステップで減速し手を上げる。突っ込めばファウル。",
                  "ko-KR": "3분의 2는 전력, 마지막은 잔발로 감속하고 손을 든다. 날아들면 파울이다.",
                  "es-ES": "Esprinta dos tercios, frena el último con pasos cortos y mano arriba. Volar es hacer falta.",
                  "fr-FR": "Sprinte deux tiers, freine le dernier en petits pas, main haute. Foncer, c'est faire faute.",
                  "id-ID": "Sprint dua pertiga, rem sepertiga terakhir dengan langkah pendek dan tangan tinggi.",
                  "ms-MY": "Pecut dua pertiga, brek sepertiga akhir dengan langkah pendek.",
                  "th-TH": "วิ่งเต็มสองในสาม ที่เหลือย่อก้าวสั้นและยกมือ พุ่งใส่คือฟาวล์",
                  "vi-VN": "Chạy hai phần ba, phanh một phần ba cuối bằng bước ngắn và giơ tay cao."},
            home=[
                P(0.50, 0.12, "x1", moves=[(0.24, 0.22, 0)]),
                P(0.50, 0.09, "x2", moves=[(0.76, 0.22, 1)]),
            ],
            away=[P(0.15, 0.26, "2"), P(0.85, 0.26, "3")],
                        # the kick-out passes the closeouts answer
            ball=(0.50, 0.10),
            ball_to=[("a0", 0), ("a1", 1)],
        ),
        Drill(
            id="bb_help_and_recover", category="defending", minutes=12, rel=True,
            name={"en": "Help and recover", "en-GB": "Help and recover", "zh-CN": "协防与回位",
                  "zh-TW": "協防與回位", "ja-JP": "ヘルプ＆リカバー", "ko-KR": "헬프 앤 리커버",
                  "es-ES": "Ayuda y recuperación", "fr-FR": "Aide et récupération",
                  "id-ID": "Bantu dan kembali", "ms-MY": "Bantu dan pulih",
                  "th-TH": "ช่วยแล้วกลับ", "vi-VN": "Bọc lót và về vị trí"},
            note={"en": "Help early, recover on the pass — not on the catch. Recovering late is worse than never helping.",
                  "en-GB": "Help early, recover on the pass — not on the catch. Recovering late is worse than never helping.",
                  "zh-CN": "协防要早，回位要在**传球出手时**，不是等对方接到球。回位慢比不协防更糟。",
                  "zh-TW": "協防要早，回位要在傳球出手時，不是等對方接到球。回位慢比不協防更糟。",
                  "ja-JP": "ヘルプは早く、リカバーはパスと同時に。キャッチ後では遅く、助けない方がまし。",
                  "ko-KR": "헬프는 빨리, 복귀는 패스가 나가는 순간에. 늦은 복귀는 안 도운 것만 못하다.",
                  "es-ES": "Ayuda pronto y recupera con el pase, no con la recepción. Llegar tarde es peor que no ayudar.",
                  "fr-FR": "Aide tôt, récupère sur la passe, pas sur la réception. Trop tard vaut moins que rien.",
                  "id-ID": "Bantu lebih awal, kembali saat bola diumpan, bukan saat ditangkap.",
                  "ms-MY": "Bantu awal, pulih ketika bola dihantar.",
                  "th-TH": "ช่วยเร็ว กลับตอนบอลถูกส่ง ไม่ใช่ตอนรับ กลับช้ายังแย่กว่าไม่ช่วย",
                  "vi-VN": "Bọc lót sớm, về vị trí ngay khi bóng được chuyền, không phải khi đối thủ bắt bóng."},
            # A real 2v2: the ball on the right wing, the shooter on the
            # left, and the whole width of the floor between them, so the
            # help is a journey and the recovery is a race.
            home=[
                P(0.84, 0.30, "1", moves=[(0.60, 0.22, 0)]),
                P(0.14, 0.28, "4"),
            ],
            away=[
                P(0.77, 0.23, "x1", moves=[(0.68, 0.26, 0)]),
                P(0.27, 0.23, "x4", moves=[(0.42, 0.18, 0), (0.24, 0.24, 1)]),
            ],
            # 1 drives; help comes off 4, the kick-out goes back to him and
            # x4 has to close out on it.
            ball=0,
            ball_follow=0,
            ball_to=[(1, 1)],
        ),
        Drill(
            id="bb_box_out", category="defending", minutes=8, rel=True, free=True,
            name={"en": "Box out", "en-GB": "Box out", "zh-CN": "卡位篮板",
                  "zh-TW": "卡位籃板", "ja-JP": "ボックスアウト", "ko-KR": "박스아웃",
                  "es-ES": "Bloqueo de rebote", "fr-FR": "Écran retard au rebond",
                  "id-ID": "Box out", "ms-MY": "Box out",
                  "th-TH": "บ็อกซ์เอาท์", "vi-VN": "Chèn bắt bật"},
            note={"en": "Find your man before you find the ball. Contact first, then go get it — every rebound is won a second before it comes off.",
                  "en-GB": "Find your man before you find the ball. Contact first, then go get it — every rebound is won a second before it comes off.",
                  "zh-CN": "先找人，再找球。先接触卡住，再去抢 —— 篮板是在球弹出来之前一秒决定的。",
                  "zh-TW": "先找人，再找球。先接觸卡住，再去搶 —— 籃板是在球彈出來之前一秒決定的。",
                  "ja-JP": "ボールより先に人を見つける。当たってから取りに行く。リバウンドは落ちる1秒前に決まる。",
                  "ko-KR": "공보다 사람을 먼저 찾아라. 접촉 먼저, 그다음 잡으러 간다.",
                  "es-ES": "Encuentra a tu hombre antes que al balón. Contacto primero: el rebote se gana un segundo antes.",
                  "fr-FR": "Trouve ton joueur avant le ballon. Contact d'abord : le rebond se gagne une seconde plus tôt.",
                  "id-ID": "Temukan lawanmu sebelum bola. Kontak dulu, baru ambil.",
                  "ms-MY": "Cari lawan anda dahulu, bukan bola.",
                  "th-TH": "หาคนก่อนหาบอล ปะทะก่อนแล้วค่อยไปเก็บ",
                  "vi-VN": "Tìm người trước khi tìm bóng. Tiếp xúc trước rồi mới bắt bóng."},
            # A box-out needs a shot to box out on: 1 shoots from the top,
            # the two bigs crash, and the two defenders turn and seal before
            # the ball comes off.
            home=[
                P(0.50, 0.32, "1"),
                P(0.28, 0.24, "4", moves=[(0.32, 0.16, 1)]),
                P(0.72, 0.24, "5", moves=[(0.68, 0.16, 1)]),
            ],
            away=[
                P(0.32, 0.17, "x4", moves=[(0.36, 0.11, 1), (0.46, 0.09, 2)]),
                P(0.68, 0.17, "x5", moves=[(0.64, 0.11, 1)]),
            ],
            ball=0,
            # the shot goes up — the rebound is the contest
            ball_to=[((0.50, 0.05), 0), ("a0", 2)],
        ),

        # ── inbounds / special situations ────────────────────────────────────
        Drill(
            id="bb_blob_box", category="setpiece", minutes=10, rel=True, free=True,
            off_surface=True,
            name={"en": "Baseline inbounds: box", "en-GB": "Baseline inbounds: box",
                  "zh-CN": "底线发球：箱型战术", "zh-TW": "底線發球：箱型戰術",
                  "ja-JP": "エンドラインOB：ボックス", "ko-KR": "엔드라인 인바운드: 박스",
                  "es-ES": "Saque de fondo: caja", "fr-FR": "Remise en jeu ligne de fond : boîte",
                  "id-ID": "Lemparan baseline: box", "ms-MY": "Lontaran baseline: box",
                  "th-TH": "ส่งบอลใต้แป้น: บ็อกซ์", "vi-VN": "Ném biên cuối sân: đội hình hộp"},
            note={"en": "The first cutter is a decoy; the screener becomes the target. Count out loud — five seconds goes fast.",
                  "en-GB": "The first cutter is a decoy; the screener becomes the target. Count out loud — five seconds goes fast.",
                  "zh-CN": "第一个跑动的人是幌子，掩护的人才是目标。出声数秒 —— 五秒过得很快。",
                  "zh-TW": "第一個跑動的人是幌子，掩護的人才是目標。出聲數秒 —— 五秒過得很快。",
                  "ja-JP": "最初のカッターは囮、スクリーナーが本命。声に出して数える。5秒は速い。",
                  "ko-KR": "첫 커터는 미끼, 스크리너가 목표다. 소리 내어 세라 — 5초는 짧다.",
                  "es-ES": "El primer cortador es señuelo; el bloqueador es el objetivo. Cuenta en voz alta.",
                  "fr-FR": "Le premier coupeur est un leurre, le poseur d'écran est la cible. Compte à voix haute.",
                  "id-ID": "Pemotong pertama umpan, pemasang screen targetnya. Hitung keras — 5 detik cepat.",
                  "ms-MY": "Pemotong pertama adalah umpan, pemasang skrin sasaran.",
                  "th-TH": "คนตัดคนแรกคือตัวล่อ คนตั้งสกรีนคือเป้าหมาย นับออกเสียง ห้าวินาทีหมดเร็ว",
                  "vi-VN": "Người cắt đầu là mồi nhử, người dựng màn mới là mục tiêu. Đếm to — năm giây trôi nhanh."},
            home=[
                P(0.50, -0.03, "1", moves=[(0.34, 0.04, 2)]),
                P(0.36, 0.10, "2", moves=[(0.08, 0.13, 0)]),
                P(0.64, 0.10, "3", moves=[(0.92, 0.13, 0)]),
                P(0.34, 0.20, "4", moves=[(0.30, 0.14, 0), (0.46, 0.06, 1)]),
                P(0.66, 0.20, "5", moves=[(0.66, 0.32, 0)]),
            ],
            away=[
                P(0.20, 0.12, "x2", moves=[(0.16, 0.18, 0)]),
                P(0.80, 0.12, "x3", moves=[(0.86, 0.18, 0)]),
                P(0.34, 0.28, "x4", moves=[(0.40, 0.14, 1)]),
            ],
            ball=0,
            # inbounded to the 4 curling off the box, laid in
            ball_to=[(3, 1), ((0.50, 0.05), 2)],
        ),
        Drill(
            id="bb_press_break", category="setpiece", minutes=12, rel=True,
            off_surface=True,
            name={"en": "Press break", "en-GB": "Press break", "zh-CN": "破全场紧逼",
                  "zh-TW": "破全場緊逼", "ja-JP": "プレスブレイク", "ko-KR": "프레스 브레이크",
                  "es-ES": "Romper la presión", "fr-FR": "Casser la pression",
                  "id-ID": "Membongkar press", "ms-MY": "Memecah tekanan",
                  "th-TH": "แก้เพรส", "vi-VN": "Phá pressing toàn sân"},
            note={"en": "Get it to the middle. A ball in the centre of the floor beats a press; a ball on the sideline feeds it.",
                  "en-GB": "Get it to the middle. A ball in the centre of the floor beats a press; a ball on the sideline feeds it.",
                  "zh-CN": "把球送到中路。球在场地中间就破了紧逼，球贴边线就是在喂给他们。",
                  "zh-TW": "把球送到中路。球在場地中間就破了緊逼，球貼邊線就是在餵給他們。",
                  "ja-JP": "ボールを中央へ。中央のボールはプレスを破り、サイドラインのボールは餌になる。",
                  "ko-KR": "공을 가운데로. 중앙의 공은 프레스를 깨고, 사이드라인의 공은 먹잇감이다.",
                  "es-ES": "Lleva el balón al centro: en el medio rompes la presión, en la banda la alimentas.",
                  "fr-FR": "Amène le ballon au centre : au milieu tu casses la presse, sur la ligne tu la nourris.",
                  "id-ID": "Bawa bola ke tengah. Bola di tengah memecah press; di garis samping justru dimakan.",
                  "ms-MY": "Bawa bola ke tengah.",
                  "th-TH": "พาบอลเข้ากลางสนาม บอลกลางแก้เพรสได้ บอลริมเส้นคืออาหารของเขา",
                  "vi-VN": "Đưa bóng vào giữa sân. Bóng ở giữa phá được pressing, bóng sát biên là mồi."},
            home=[
                P(0.50, 1.03, "5"),
                P(0.22, 0.86, "1", moves=[(0.30, 0.78, 0)]),
                P(0.78, 0.86, "2", moves=[(0.70, 0.78, 0)]),
                P(0.50, 0.68, "3", moves=[(0.50, 0.56, 1)]),
                P(0.50, 0.40, "4"),
            ],
            away=[
                P(0.36, 0.90, "x1", moves=[(0.36, 0.84, 0)]),
                P(0.64, 0.90, "x2", moves=[(0.64, 0.84, 0)]),
                P(0.50, 0.76, "x3", moves=[(0.44, 0.66, 1)]),
            ],
            ball=0,
            # in to the 1, middle to the 3, over the top to the 4
            ball_to=[(1, 0), (3, 1), (4, 2)],
        ),

        # ── small-sided ──────────────────────────────────────────────────────
        Drill(
            id="bb_3v3_no_dribble", category="ssg", minutes=15, rel=True, free=True,
            name={"en": "3v3, no dribble", "en-GB": "3v3, no dribble", "zh-CN": "3v3 不许运球",
                  "zh-TW": "3v3 不許運球", "ja-JP": "3対3 ノードリブル", "ko-KR": "3대3 노 드리블",
                  "es-ES": "3v3 sin bote", "fr-FR": "3c3 sans dribble",
                  "id-ID": "3v3 tanpa dribel", "ms-MY": "3v3 tanpa dribel",
                  "th-TH": "3v3 ห้ามเลี้ยง", "vi-VN": "3v3 không dẫn bóng"},
            note={"en": "Without the dribble the only way to move the ball is to move yourself. Cut every time you pass.",
                  "en-GB": "Without the dribble the only way to move the ball is to move yourself. Cut every time you pass.",
                  "zh-CN": "不能运球，球就只能靠人跑动来移动。每传一次就切一次。",
                  "zh-TW": "不能運球，球就只能靠人跑動來移動。每傳一次就切一次。",
                  "ja-JP": "ドリブルがなければ、動かせるのは自分だけ。パスのたびにカットする。",
                  "ko-KR": "드리블이 없으면 공을 옮기는 유일한 방법은 내가 움직이는 것이다.",
                  "es-ES": "Sin bote, la única forma de mover el balón es moverte tú. Corta cada vez que pases.",
                  "fr-FR": "Sans dribble, la seule façon de faire circuler le ballon est de bouger. Coupe après chaque passe.",
                  "id-ID": "Tanpa dribel, satu-satunya cara memindahkan bola adalah bergerak.",
                  "ms-MY": "Tanpa dribel, satu-satunya cara ialah bergerak.",
                  "th-TH": "ไม่มีการเลี้ยง วิธีเดียวที่บอลจะเคลื่อนคือคนต้องเคลื่อน ส่งแล้วตัดทุกครั้ง",
                  "vi-VN": "Không dẫn bóng thì cách duy nhất để bóng di chuyển là người di chuyển."},
            home=[
                P(0.50, 0.34, "1", moves=[(0.46, 0.10, 1)]),
                P(0.14, 0.28, "2"),
                P(0.86, 0.28, "3"),
            ],
            away=[
                P(0.50, 0.27, "x1", moves=[(0.46, 0.20, 1)]),
                P(0.16, 0.20, "x2"),
                P(0.80, 0.22, "x3"),
            ],
            ball=0,
            # no dribble: two passes beat the deny
            ball_to=[(1, 0), (0, 1)],
        ),
        Drill(
            id="bb_transition_2v1", category="ssg", minutes=10, rel=True,
            name={"en": "2v1 transition", "en-GB": "2v1 transition", "zh-CN": "2打1快攻",
                  "zh-TW": "2打1快攻", "ja-JP": "2対1 速攻", "ko-KR": "2대1 속공",
                  "es-ES": "Transición 2v1", "fr-FR": "Transition 2c1",
                  "id-ID": "Transisi 2v1", "ms-MY": "Peralihan 2v1",
                  "th-TH": "ทรานสิชัน 2v1", "vi-VN": "Chuyển đổi 2v1"},
            note={"en": "Attack the defender's inside shoulder. Pass only when he commits — an early pass lets him guard both.",
                  "en-GB": "Attack the defender's inside shoulder. Pass only when he commits — an early pass lets him guard both.",
                  "zh-CN": "冲击防守人内侧肩膀。等他站定再传 —— 传早了他一个人能防两个。",
                  "zh-TW": "衝擊防守人內側肩膀。等他站定再傳 —— 傳早了他一個人能防兩個。",
                  "ja-JP": "ディフェンスの内側の肩を攻める。相手が出てから出す。早いパスは1人に2人守らせる。",
                  "ko-KR": "수비의 안쪽 어깨를 공략하라. 그가 나올 때만 패스 — 일찍 주면 혼자 둘을 막는다.",
                  "es-ES": "Ataca el hombro interior del defensor. Pasa solo cuando se comprometa.",
                  "fr-FR": "Attaque l'épaule intérieure du défenseur. Ne passe que lorsqu'il s'engage.",
                  "id-ID": "Serang bahu dalam pemain bertahan. Umpan hanya saat dia maju.",
                  "ms-MY": "Serang bahu dalam pemain bertahan.",
                  "th-TH": "พุ่งเข้าหาไหล่ด้านในของกองหลัง จ่ายเมื่อเขาขยับเท่านั้น",
                  "vi-VN": "Tấn công vai trong của hậu vệ. Chỉ chuyền khi anh ta lao ra."},
            home=[
                P(0.32, 0.58, "1", moves=[(0.38, 0.30, 0), (0.42, 0.20, 1)]),
                P(0.74, 0.58, "2", moves=[(0.72, 0.30, 0), (0.60, 0.09, 2)]),
            ],
            away=[P(0.50, 0.20, "x1", moves=[(0.44, 0.13, 1)])],
            ball=0,
            # 2v1: carried at the defender until he commits, then a real
            # pass across to the far lane for the layup
            ball_to=[(0, 0), (0, 1), (1, 2), ((0.50, 0.04), 3)],
        ),
    ]


# ─────────────────────────────────────────────────────────────────────────────
# Families. The half-court landmarks the generators build from.
# ─────────────────────────────────────────────────────────────────────────────
RIM = (0.50, 0.06)
FT_LINE = (0.50, 0.19)
TOP = (0.50, 0.30)
WING_L, WING_R = (0.15, 0.26), (0.85, 0.26)
CORNER_L, CORNER_R = (0.05, 0.11), (0.95, 0.11)
ELBOW_L, ELBOW_R = (0.33, 0.19), (0.67, 0.19)
BLOCK_L, BLOCK_R = (0.38, 0.10), (0.62, 0.10)
SLOT_L, SLOT_R = (0.32, 0.33), (0.68, 0.33)
HALF = 0.50

# Every ball screen in this family is authored driving to the RIGHT — the
# handler comes off the screener's shoulder toward increasing x — and the
# spots that sit on the right of the floor are mirrored, so a wing screen
# always sends the ball to the middle. Each row is a real half-court
# alignment: handler, screener lifting from an elbow, both defenders on
# their own man a body-width off, and the roll finishing with room.
PNR_SPOTS = [
    # key, label, mirror, handler path, screener path, X1 path, X5 path,
    # spacers (the three players who are not in the action)
    ("top", "top", False,
     [(0.50, 0.34), (0.74, 0.28), (0.68, 0.16)],
     [(0.67, 0.19), (0.64, 0.35), (0.46, 0.09)],
     [(0.50, 0.27), (0.62, 0.28), (0.74, 0.21)],
     [(0.62, 0.11), (0.66, 0.21), (0.54, 0.13)],
     [(0.06, 0.11), (0.95, 0.12), (0.14, 0.28)]),
    ("left wing", "left wing", False,
     [(0.14, 0.30), (0.38, 0.24), (0.44, 0.17)],
     [(0.33, 0.19), (0.24, 0.33), (0.42, 0.09)],
     [(0.23, 0.24), (0.29, 0.29), (0.34, 0.22)],
     [(0.38, 0.11), (0.30, 0.19), (0.37, 0.14)],
     [(0.94, 0.11), (0.72, 0.33), (0.05, 0.12)]),
    ("right wing", "right wing", True,
     [(0.14, 0.30), (0.38, 0.24), (0.44, 0.17)],
     [(0.33, 0.19), (0.24, 0.33), (0.42, 0.09)],
     [(0.23, 0.24), (0.29, 0.29), (0.34, 0.22)],
     [(0.38, 0.11), (0.30, 0.19), (0.37, 0.14)],
     [(0.94, 0.11), (0.72, 0.33), (0.05, 0.12)]),
    ("left slot", "left slot", False,
     [(0.30, 0.34), (0.54, 0.28), (0.48, 0.15)],
     [(0.33, 0.19), (0.44, 0.36), (0.40, 0.09)],
     [(0.30, 0.27), (0.42, 0.29), (0.54, 0.22)],
     [(0.38, 0.11), (0.44, 0.21), (0.34, 0.13)],
     [(0.94, 0.12), (0.86, 0.30), (0.06, 0.11)]),
    ("right slot", "right slot", True,
     [(0.30, 0.34), (0.54, 0.28), (0.48, 0.15)],
     [(0.33, 0.19), (0.44, 0.36), (0.40, 0.09)],
     [(0.30, 0.27), (0.42, 0.29), (0.54, 0.22)],
     [(0.38, 0.11), (0.44, 0.21), (0.34, 0.13)],
     [(0.94, 0.12), (0.86, 0.30), (0.06, 0.11)]),
]


def _mirror(pts, on: bool):
    return [(1.0 - x, y) for (x, y) in pts] if on else list(pts)


PNR_NAME = {
    "en": "Ball screen from", "en-GB": "Ball screen from", "zh-CN": "挡拆起手",
    "zh-TW": "擋拆起手", "ja-JP": "オンボールスクリーン", "ko-KR": "온볼 스크린",
    "es-ES": "Bloqueo directo desde", "fr-FR": "Écran sur porteur depuis",
    "id-ID": "Screen bola dari", "ms-MY": "Screen bola dari",
    "th-TH": "สกรีนบอลจาก", "vi-VN": "Che chắn bóng từ",
}
PNR_NOTE = {
    "en": "Set the screen and hold it. A screener already rolling when the "
          "guard arrives has set nothing and fouled nobody.",
    "en-GB": "Set the screen and hold it. A screener already rolling when the "
             "guard arrives has set nothing and fouled nobody.",
    "zh-CN": "掩护要站住、顶住。后卫还没到就已经开始下顺的掩护人，等于什么也没挡到。",
    "zh-TW": "掩護要站住、頂住。後衛還沒到就已經開始下順的掩護人，等於什麼也沒擋到。",
    "ja-JP": "スクリーンは立てて止まる。ガードが来る前に既にロールしているスクリーナーは、何もセットしていない。",
    "ko-KR": "스크린은 세우고 버텨라. 가드가 오기 전에 이미 롤하는 스크리너는 아무것도 세우지 않은 것이다.",
    "es-ES": "Pon el bloqueo y aguántalo: un bloqueador que ya va rodando "
             "cuando llega el base no ha bloqueado nada.",
    "fr-FR": "Pose l'écran et tiens-le : un poseur déjà en rouleau à l'arrivée "
             "du meneur n'a rien posé du tout.",
    "id-ID": "Pasang screen dan tahan.",
    "ms-MY": "Pasang screen dan tahan.",
    "th-TH": "ตั้งสกรีนแล้วยืนนิ่ง",
    "vi-VN": "Đặt màn chắn và giữ vững.",
}


def ball_screen_family() -> list[Drill]:
    """The same action from every spot a guard actually uses it.

    They all used to be drawn on one lane line: handler, screener and both
    defenders inside a column narrower than a token, so the roll, the
    dribble and the screen angle could not be told apart. Each spot now
    gets a real alignment — the screener lifts from the elbow, the handler
    turns the corner two token-widths past him, X1 trails and X5 covers,
    and the roller finishes on the far side of the lane.
    """
    out = []
    for key, label, mirror, one, five, x1, x5, spacers in PNR_SPOTS:
        one = _mirror(one, mirror)
        five = _mirror(five, mirror)
        x1 = _mirror(x1, mirror)
        x5 = _mirror(x5, mirror)
        spacers = _mirror(spacers, mirror)
        out.append(Drill(
            id=f"bb_screen_{key.replace(' ', '_')}", category="attacking",
            minutes=12, rel=True, free=(key in ("top", "right wing")),
            name=suffixed(PNR_NAME, label), note=PNR_NOTE,
            home=[
                P(*one[0], "1", moves=[one[1] + (1,), one[2] + (2,)]),
                P(*five[0], "5", moves=[five[1] + (0,), five[2] + (2,)]),
                P(*spacers[0], "2"), P(*spacers[1], "3"), P(*spacers[2], "4"),
            ],
            away=[P(*x1[0], "X1", moves=[x1[1] + (1,), x1[2] + (2,)]),
                  P(*x5[0], "X5", moves=[x5[1] + (1,), x5[2] + (2,)])],
            ball=0,
            # Dribbled off the screen, then the pocket pass to the roller.
            ball_to=[(0, 1), (1, 2)],
        ))
    return out


CUT_NAME = {
    "en": "Cutting", "en-GB": "Cutting", "zh-CN": "空切", "zh-TW": "空切",
    "ja-JP": "カット", "ko-KR": "컷", "es-ES": "Cortes", "fr-FR": "Coupes",
    "id-ID": "Cutting", "ms-MY": "Cutting", "th-TH": "การตัดเข้า", "vi-VN": "Cắt vào",
}
CUT_NOTE = {
    "en": "Cut when your defender turns their head, not when you get bored. "
          "The cut is a reaction to them, not a decision of yours.",
    "en-GB": "Cut when your defender turns their head, not when you get bored. "
             "The cut is a reaction to them, not a decision of yours.",
    "zh-CN": "在你的防守人扭头的那一刻切，而不是你站腻了才切。空切是对他的反应，不是你自己的决定。",
    "zh-TW": "在你的防守人扭頭的那一刻切，而不是你站膩了才切。空切是對他的反應，不是你自己的決定。",
    "ja-JP": "自分のマークが顔を向けた瞬間に切る。飽きたからではない。カットは相手への反応であって、自分の判断ではない。",
    "ko-KR": "수비가 고개를 돌릴 때 컷하라. 지루해서가 아니라. 컷은 상대에 대한 반응이다.",
    "es-ES": "Corta cuando tu defensor gira la cabeza, no cuando te aburres: "
             "el corte es una reacción a él, no una decisión tuya.",
    "fr-FR": "Coupe quand ton défenseur tourne la tête, pas quand tu t'ennuies : "
             "la coupe est une réaction, pas une décision.",
    "id-ID": "Cut saat penjagamu menoleh, bukan saat kamu bosan.",
    "ms-MY": "Cut ketika penjaga anda menoleh, bukan ketika anda bosan.",
    "th-TH": "ตัดเข้าเมื่อคนประกบหันหัว ไม่ใช่เมื่อคุณเบื่อ",
    "vi-VN": "Cắt khi người kèm quay đầu, không phải khi bạn chán.",
}


# key, label, free, and the four routes: the ball handler, the cutter, the
# cutter's defender, the on-ball defender. A fifth big and a spacer are
# placed per cut so the lane the cut finishes in is empty.
CUT_SPECS = [
    ("give_and_go", "give and go", True,
     [(0.50, 0.34), (0.66, 0.24, 1), (0.58, 0.11, 2)],   # 1 passes, then cuts
     [(0.86, 0.28)],                                      # 2 holds it on the wing
     [(0.77, 0.22)],                                      # X2 on the ball
     [(0.50, 0.27), (0.56, 0.21, 1), (0.46, 0.15, 2)],    # X1 trails the cut
     (0.33, 0.19), (0.06, 0.11), [(1, 0), (0, 2)]),
    ("backdoor", "the backdoor cut", True,
     [(0.50, 0.34)],                                      # 1 waits for the cut
     [(0.14, 0.26), (0.10, 0.34, 0), (0.38, 0.10, 1)],    # 2 steps out, then goes
     [(0.26, 0.21), (0.20, 0.30, 0), (0.26, 0.20, 1)],    # X2 denies, then beaten
     [(0.58, 0.26)],
     (0.62, 0.10), (0.94, 0.11), [(1, 1)]),
    # A flare needs a screener; without one it is a player drifting.
    ("flare", "the flare", False,
     [(0.66, 0.33)],                                      # 1 skips it across
     [(0.34, 0.33), (0.42, 0.28, 0), (0.08, 0.30, 1)],    # 2 steps in, flares out
     [(0.34, 0.26), (0.44, 0.22, 0), (0.22, 0.20, 1)],    # X2 chases into the screen
     [(0.60, 0.26)],
     None, (0.94, 0.11), [(1, 1)]),
    ("baseline", "along the baseline", False,
     [(0.50, 0.33)],
     [(0.06, 0.12), (0.34, 0.07, 0), (0.72, 0.09, 1)],
     [(0.17, 0.17), (0.36, 0.14, 0), (0.70, 0.15, 1)],
     [(0.42, 0.27)],
     (0.33, 0.19), (0.94, 0.11), [(1, 1)]),
]


def cut_family() -> list[Drill]:
    """Four cuts, each with the right player cutting.

    Every one of them used to move the receiver while the passer nudged
    0.7 m backwards — but a give-and-go is the *passer* cutting off his own
    pass, and a flare is read off a screen that was not on the board at all.
    They were also drawn on top of their defenders in a column one token
    wide; each cut now starts with the pair a body-width apart and finishes
    in a lane the big has vacated.
    """
    out = []
    for key, label, free, one, two, x2, x1, big, spacer, route in CUT_SPECS:
        home = [P(one[0][0], one[0][1], "1",
                  moves=[m for m in one[1:]]),
                P(two[0][0], two[0][1], "2", moves=[m for m in two[1:]]),
                P(*spacer, "3")]
        if big is None:
            # The flare's big is the screener: he steps into X2's path.
            home.append(P(*ELBOW_L, "5", moves=[(0.26, 0.26, 0)]))
        else:
            home.append(P(*big, "5"))
        out.append(Drill(
            id=f"bb_cut_{key}", category="attacking", minutes=10, rel=True,
            free=free,
            name=suffixed(CUT_NAME, label), note=CUT_NOTE,
            home=home,
            away=[P(x2[0][0], x2[0][1], "X2", moves=[m for m in x2[1:]]),
                  P(x1[0][0], x1[0][1], "X1", moves=[m for m in x1[1:]])],
            ball=0,
            # Give and go: pass, cut, get it back at the rim. The other
            # three: the pass is thrown to where the cut finishes.
            ball_to=route,
        ))
    return out


SHOT_NAME = {
    "en": "Shooting", "en-GB": "Shooting", "zh-CN": "投篮", "zh-TW": "投籃",
    "ja-JP": "シュート", "ko-KR": "슛", "es-ES": "Tiro", "fr-FR": "Tir",
    "id-ID": "Tembakan", "ms-MY": "Tembakan", "th-TH": "การยิง", "vi-VN": "Ném rổ",
}
SHOT_NOTE = {
    "en": "Feet set before the ball arrives, every time. A shooter who catches "
          "and then organises has already let the closeout arrive.",
    "en-GB": "Feet set before the ball arrives, every time. A shooter who "
             "catches and then organises has already let the closeout arrive.",
    "zh-CN": "球到之前脚就要站好，每一次都是。先接球再调整的投手，已经等来了对方的扑防。",
    "zh-TW": "球到之前腳就要站好，每一次都是。先接球再調整的投手，已經等來了對方的撲防。",
    "ja-JP": "ボールが来る前に足を作る、毎回。キャッチしてから整えるシューターは、クローズアウトを待っているだけだ。",
    "ko-KR": "공이 오기 전에 발을 만들어라, 매번. 잡고 나서 정리하는 슈터는 클로즈아웃을 부른 것이다.",
    "es-ES": "Pies listos antes de recibir, siempre: quien recibe y luego se "
             "organiza ya ha dejado llegar la ayuda.",
    "fr-FR": "Appuis prêts avant la réception, à chaque fois : celui qui "
             "s'organise après avoir attrapé a déjà laissé venir le contest.",
    "id-ID": "Kaki siap sebelum bola datang, setiap kali.",
    "ms-MY": "Kaki sedia sebelum bola tiba, setiap kali.",
    "th-TH": "ตั้งเท้าก่อนบอลมาถึงทุกครั้ง",
    "vi-VN": "Đặt chân xong trước khi bóng tới, mọi lần.",
}


def shooting_family() -> list[Drill]:
    """A shooter, a feeder under the rim, and a closeout to shoot over.

    The passer used to stand on the free-throw line — in front of the
    shooter, in the way of both the pass and the shot — and a spot marker
    sat between him and the defender with nobody standing on it, so a coach
    could not tell whether it was a chair to be used or clutter. The feeder
    is now under the basket where he can rebound, the shooter steps up onto
    his spot, and the defender closes out from the paint.
    """
    # spot; the feeder's rebounding spot under the rim (on the shooter's
    # side, so the pass does not thread the defender); where the closeout
    # starts (the far side of the paint) and where it finishes.
    spots = [("the corner", CORNER_L, (0.40, 0.08), (0.60, 0.12), (0.19, 0.15)),
             ("left wing", WING_L, (0.40, 0.08), (0.60, 0.12), (0.28, 0.22)),
             ("top", TOP, (0.58, 0.08), (0.36, 0.12), (0.42, 0.24)),
             ("right wing", WING_R, (0.60, 0.08), (0.40, 0.12), (0.72, 0.22)),
             ("the elbow", ELBOW_R, (0.60, 0.08), (0.38, 0.12), (0.60, 0.14))]
    out = []
    for label, spot, feed, xstart, close in spots:
        out.append(Drill(
            id=f"bb_shot_{label.replace(' ', '_')}", category="finishing",
            minutes=8, rel=True, free=(label in ("the corner", "top")),
            name=suffixed(SHOT_NAME, label), note=SHOT_NOTE,
            home=[P(spot[0], spot[1] + 0.10, "1", moves=[spot + (0,)]),
                  P(*feed, "P")],
            away=[P(*xstart, "X", moves=[close + (1,)])],
            ball=1,
            # Fed from under the rim once the shooter is set, up on the catch.
            ball_to=[(0, 1), ((0.50, 0.05), 2)],
        ))
    return out


POST_NAME = {
    "en": "Post play", "en-GB": "Post play", "zh-CN": "低位单打",
    "zh-TW": "低位單打", "ja-JP": "ポストプレー", "ko-KR": "포스트 플레이",
    "es-ES": "Juego de poste", "fr-FR": "Jeu au poste", "id-ID": "Permainan post",
    "ms-MY": "Permainan post", "th-TH": "การเล่นในโพสต์", "vi-VN": "Chơi trụ",
}
POST_NOTE = {
    "en": "Seal before the pass, then hold the seal. Fighting for position "
          "after the ball is in the air is fighting a defender who already won.",
    "en-GB": "Seal before the pass, then hold the seal. Fighting for position "
             "after the ball is in the air is fighting a defender who already won.",
    "zh-CN": "传球之前就要封住位置，然后守住。球都到空中了才开始抢位，是在跟一个已经赢了的防守人较劲。",
    "zh-TW": "傳球之前就要封住位置，然後守住。球都到空中了才開始搶位，是在跟一個已經贏了的防守人較勁。",
    "ja-JP": "パスの前にシールし、そのまま保つ。ボールが浮いてから位置を争うのは、既に勝った守備と争うことだ。",
    "ko-KR": "패스 전에 자리를 봉하고 유지하라. 공이 뜬 뒤 자리를 다투는 건 이미 진 싸움이다.",
    "es-ES": "Sella antes del pase y mantén el sello: pelear la posición con "
             "la bola en el aire es pelear con un defensor que ya ganó.",
    "fr-FR": "Scelle avant la passe et tiens la position : se battre une fois "
             "le ballon en l'air, c'est se battre contre un défenseur déjà gagnant.",
    "id-ID": "Kunci posisi sebelum umpan, lalu pertahankan.",
    "ms-MY": "Kunci kedudukan sebelum hantaran, kemudian pertahankan.",
    "th-TH": "ปิดตำแหน่งก่อนบอลจะถูกส่ง แล้วรักษาไว้",
    "vi-VN": "Chốt vị trí trước đường chuyền rồi giữ nguyên.",
}


# Each post drill written out: where 5 works, where his defender starts
# (on the high side, not on top of him), where the help comes from, and
# what the finish is. (key, label, free, home, away, ball_to).
POST_SETS = [
    ("drop_step", "the drop step", True, [
        ("1", (0.84, 0.30), []),
        ("5", (0.34, 0.12), [(0.44, 0.06, 1)]),      # baseline-side drop step
        ("2", (0.06, 0.11), []),
        ("3", (0.50, 0.33), []),
    ], [
        ("X5", (0.34, 0.19), [(0.36, 0.13, 1)]),     # stays on the high side
        ("X4", (0.66, 0.16), [(0.60, 0.10, 1)]),
    ], [(1, 0), (1, 1), ((0.50, 0.04), 2)]),
    ("face_up", "facing up", False, [
        ("1", (0.88, 0.30), []),
        ("5", (0.66, 0.20), [(0.54, 0.09, 1)]),
        ("2", (0.06, 0.11), []),
        ("3", (0.46, 0.33), []),
    ], [
        ("X5", (0.66, 0.13), [(0.64, 0.05, 1)]),
        ("X4", (0.34, 0.16), [(0.42, 0.10, 1)]),
    ], [(1, 0), (1, 1), ((0.50, 0.04), 2)]),
    # The kick-out: 5 holds the seal, the dig comes, the ball leaves from
    # the block he is actually standing on.
    ("kick_out", "the kick-out", True, [
        ("1", (0.88, 0.30), []),
        ("5", (0.66, 0.12), []),
        ("2", (0.06, 0.12), []),
        ("3", (0.46, 0.33), []),
    ], [
        ("X5", (0.66, 0.20), []),
        ("X4", (0.34, 0.16), [(0.50, 0.13, 1)]),     # the dig off the corner
    ], [(1, 0), (2, 2)]),
    # A short roll is a ball screen, not a high-post entry: 5 screens,
    # X5 shows, 5 rolls only as far as the free-throw line and plays 4-on-3.
    ("short_roll", "the short roll", False, [
        ("1", (0.50, 0.34), [(0.70, 0.28, 1), (0.78, 0.22, 2)]),
        ("5", (0.66, 0.19), [(0.62, 0.33, 0), (0.52, 0.20, 2)]),
        ("2", (0.06, 0.11), []),
        ("3", (0.16, 0.30), []),
    ], [
        ("X5", (0.62, 0.12), [(0.72, 0.33, 1), (0.68, 0.24, 2)]),
        ("X4", (0.32, 0.13), [(0.44, 0.15, 2)]),
    ], [(0, 1), (1, 2)]),
]


def post_family() -> list[Drill]:
    out = []
    for key, label, free, home, away, route in POST_SETS:
        out.append(Drill(
            id=f"bb_post_{key}", category="attacking", minutes=10, rel=True,
            free=free,
            name=suffixed(POST_NAME, label), note=POST_NOTE,
            home=[P(*st, lab, moves=list(mv)) for lab, st, mv in home],
            away=[P(*st, lab, moves=list(mv)) for lab, st, mv in away],
            ball=0,
            ball_to=route,
        ))
    return out


DEF_NAME = {
    "en": "Defence", "en-GB": "Defence", "zh-CN": "防守", "zh-TW": "防守",
    "ja-JP": "ディフェンス", "ko-KR": "수비", "es-ES": "Defensa",
    "fr-FR": "Défense", "id-ID": "Pertahanan", "ms-MY": "Pertahanan",
    "th-TH": "การรับ", "vi-VN": "Phòng thủ",
}
DEF_NOTE = {
    "en": "Every ball screen coverage is a promise between two defenders. Say "
          "which one you are before the screen, out loud, every possession.",
    "en-GB": "Every ball screen coverage is a promise between two defenders. "
             "Say which one you are before the screen, out loud, every possession.",
    "zh-CN": "每一种挡拆防守都是两个防守人之间的约定。在掩护之前就把你要用哪种喊出来，每一回合都喊。",
    "zh-TW": "每一種擋拆防守都是兩個防守人之間的約定。在掩護之前就把你要用哪種喊出來，每一回合都喊。",
    "ja-JP": "スクリーンの守り方はすべて、二人の守備者の約束だ。スクリーン前にどれかを声に出す。毎ポゼッション。",
    "ko-KR": "모든 스크린 수비는 두 수비수 사이의 약속이다. 스크린 전에 어느 것인지 소리 내어 말하라.",
    "es-ES": "Cada defensa del bloqueo es un pacto entre dos: dilo en voz alta "
             "antes del bloqueo, en cada posesión.",
    "fr-FR": "Chaque couverture d'écran est un pacte entre deux défenseurs : "
             "annonce-la à voix haute avant l'écran, à chaque possession.",
    "id-ID": "Setiap cara bertahan screen adalah janji antara dua pemain.",
    "ms-MY": "Setiap cara bertahan screen ialah janji antara dua pemain.",
    "th-TH": "ทุกวิธีรับสกรีนคือข้อตกลงระหว่างสองคน พูดออกมาก่อนทุกครั้ง",
    "vi-VN": "Mỗi cách chống màn chắn là một giao ước giữa hai hậu vệ.",
}


def defence_family() -> list[Drill]:
    """Four ball-screen coverages, each doing what it is called.

    Run as the 2v2 every coach runs it as, and laid out as a real
    half-court screen: the handler above the arc, the big lifting from the
    elbow to screen his outside shoulder, and each defender starting on his
    own man. Only the two defenders' routes change from drill to drill —
    that is the whole point of the family. The ball rides with the handler
    (a dribble, not a pass from his own defender, which is what the loose
    ball at his feet used to narrate as).
    """
    specs = [
        # key, label, 1's path, 5's path, X1's path, X5's path
        ("drop", "in drop coverage",
         [(0.50, 0.34), (0.74, 0.28), (0.68, 0.16)],
         [(0.67, 0.19), (0.64, 0.35), (0.46, 0.09)],
         [(0.50, 0.27), (0.62, 0.28), (0.74, 0.21)],
         [(0.62, 0.11), (0.60, 0.20), (0.58, 0.13)]),
        ("hedge", "hedging",
         [(0.50, 0.34), (0.74, 0.28), (0.68, 0.16)],
         [(0.67, 0.19), (0.64, 0.35), (0.46, 0.09)],
         [(0.50, 0.27), (0.62, 0.28), (0.74, 0.21)],
         [(0.62, 0.11), (0.76, 0.33), (0.56, 0.14)]),
        # The switch: the big picks up the ball and the guard peels back
        # onto the roller, who used to roll to the rim with nobody on him.
        ("switch", "switching",
         [(0.50, 0.34), (0.74, 0.28), (0.68, 0.16)],
         [(0.67, 0.19), (0.64, 0.35), (0.46, 0.09)],
         [(0.50, 0.27), (0.62, 0.25), (0.52, 0.14)],
         [(0.62, 0.11), (0.74, 0.35), (0.72, 0.22)]),
        # ICE is a side screen, and X1 jumps above it to send the ball down
        # the sideline instead of chasing over the top.
        ("ice", "icing the side screen",
         [(0.86, 0.30), (0.88, 0.20), (0.84, 0.10)],
         [(0.67, 0.19), (0.76, 0.38), (0.62, 0.10)],
         # X1 jumps ABOVE the screen — on the ball's high shoulder — which
         # is the whole coverage: it sends the dribble down the line.
         [(0.86, 0.23), (0.88, 0.36), (0.90, 0.20)],
         [(0.70, 0.12), (0.76, 0.20), (0.72, 0.13)]),
    ]
    out = []
    for key, label, one, five, x1, x5 in specs:
        out.append(Drill(
            id=f"bb_defence_{key}", category="defending", minutes=12, rel=True,
            free=(key in ("drop", "switch")),
            name=suffixed(DEF_NAME, label), note=DEF_NOTE,
            home=[P(*one[0], "1", moves=[one[1] + (1,), one[2] + (2,)]),
                  P(*five[0], "5", moves=[five[1] + (0,), five[2] + (2,)])],
            away=[P(*x1[0], "X1", moves=[x1[1] + (1,), x1[2] + (2,)]),
                  P(*x5[0], "X5", moves=[x5[1] + (1,), x5[2] + (2,)])],
            ball=0,
            # Their 1 dribbles off the screen and attacks — the action every
            # coverage in this family exists to answer.
            ball_follow=0,
        ))
    return out


TRANS_NAME = {
    "en": "Transition", "en-GB": "Transition", "zh-CN": "转换进攻",
    "zh-TW": "轉換進攻", "ja-JP": "トランジション", "ko-KR": "트랜지션",
    "es-ES": "Transición", "fr-FR": "Transition", "id-ID": "Transisi",
    "ms-MY": "Peralihan", "th-TH": "การเปลี่ยนเกม", "vi-VN": "Chuyển đổi",
}
TRANS_NOTE = {
    "en": "Run wide and run early. Two players sprinting the sidelines make a "
          "three-on-two out of a rebound; three players trailing the ball do not.",
    "en-GB": "Run wide and run early. Two players sprinting the sidelines make "
             "a three-on-two out of a rebound; three players trailing the ball do not.",
    "zh-CN": "跑边、早跑。两个人冲边线，能把一个篮板变成三打二；三个人跟着球跑，什么也变不出来。",
    "zh-TW": "跑邊、早跑。兩個人衝邊線，能把一個籃板變成三打二；三個人跟著球跑，什麼也變不出來。",
    "ja-JP": "広く、早く走る。二人がサイドラインを走ればリバウンドが3対2になる。三人がボールを追いかけても何も起きない。",
    "ko-KR": "넓게, 일찍 뛰어라. 두 명이 사이드라인을 달리면 리바운드가 3대2가 된다.",
    "es-ES": "Corre abierto y pronto: dos que esprintan las bandas convierten "
             "un rebote en un tres contra dos; tres siguiendo la bola, no.",
    "fr-FR": "Cours large et tôt : deux joueurs qui sprintent les lignes de "
             "touche transforment un rebond en trois contre deux.",
    "id-ID": "Lari melebar dan lari lebih awal.",
    "ms-MY": "Lari melebar dan lari lebih awal.",
    "th-TH": "วิ่งกว้างและวิ่งเร็ว",
    "vi-VN": "Chạy rộng và chạy sớm.",
}


# Where each lane finishes the break: the wings fill the corners, the ball
# takes the middle, the trailers stop at the arc — instead of all five
# running into the same square metre of paint.
TRANS_FILL = {0.10: (0.08, 0.16), 0.90: (0.92, 0.16), 0.50: (0.44, 0.14),
              0.30: (0.24, 0.32), 0.70: (0.76, 0.32)}
# The defenders retreat in the shape the numbers demand: two in tandem,
# three in a triangle, four in a box — never a flat line across the
# free-throw line, which is the one shape a break never meets.
TRANS_D = {
    2: ([(0.50, 0.25), (0.56, 0.08)], [(0.56, 0.20, 1)]),
    3: ([(0.50, 0.25), (0.34, 0.09), (0.66, 0.09)], [(0.56, 0.20, 1)]),
    4: ([(0.36, 0.22), (0.64, 0.22), (0.34, 0.08), (0.66, 0.08)],
        [(0.32, 0.31, 1), (0.68, 0.31, 1)]),
}


def transition_family() -> list[Drill]:
    out = []
    for n, d in ((3, 2), (4, 3), (5, 4)):
        lanes = [0.10, 0.90, 0.50, 0.30, 0.70][:n]
        if n == 5:
            fill = {**TRANS_FILL, 0.30: (0.20, 0.34), 0.70: (0.80, 0.34)}
        else:
            fill = TRANS_FILL
        spots, dmoves = TRANS_D[d]
        mid = lanes.index(0.50)
        out.append(Drill(
            id=f"bb_transition_{n}v{d}", category="ssg", minutes=12, rel=True,
            free=(n == 3),
            name=suffixed(TRANS_NAME, f"{n}v{d}"), note=TRANS_NOTE,
            home=[P(x, 0.62, str(i + 1),
                    moves=[(x, 0.38, 0), fill[x] + (1,)])
                  for i, x in enumerate(lanes)],
            away=[P(*sp, f"X{i + 1}",
                    moves=[dmoves[i]] if i < len(dmoves) else [])
                  for i, sp in enumerate(spots)],
            ball=0,
            # Pushed ahead to the middle lane, carried into the paint and
            # finished from where the ball actually ends up.
            ball_to=[(mid, 0), (mid, 1), ((0.50, 0.04), 2)],
        ))
    return out


SET_NAME = {
    "en": "Inbounds", "en-GB": "Inbounds", "zh-CN": "发球战术",
    "zh-TW": "發球戰術", "ja-JP": "スローイン", "ko-KR": "인바운드",
    "es-ES": "Saque", "fr-FR": "Remise en jeu", "id-ID": "Bola masuk",
    "ms-MY": "Bola masuk", "th-TH": "การส่งบอลเข้าเล่น", "vi-VN": "Ném biên",
}
SET_NOTE = {
    "en": "The first cutter is the decoy and knows it. If they run it like a "
          "decoy nobody guards the second one either.",
    "en-GB": "The first cutter is the decoy and knows it. If they run it like a "
             "decoy nobody guards the second one either.",
    "zh-CN": "第一个跑动的人就是诱饵，而且他自己知道。如果他跑得像个诱饵，第二个人也没人防了。",
    "zh-TW": "第一個跑動的人就是誘餌，而且他自己知道。如果他跑得像個誘餌，第二個人也沒人防了。",
    "ja-JP": "最初のカッターは囮であり、本人もそれを知っている。囮らしく走れば、二人目も誰も見なくなる。",
    "ko-KR": "첫 커터는 미끼이고 본인도 안다. 미끼답게 뛰면 두 번째도 아무도 안 막는다.",
    "es-ES": "El primer cortador es el señuelo y lo sabe: si lo corre como "
             "señuelo, al segundo tampoco lo marca nadie.",
    "fr-FR": "Le premier coupeur est le leurre et le sait : s'il joue le "
             "leurre, personne ne prend le second non plus.",
    "id-ID": "Pemotong pertama adalah umpan dan dia tahu itu.",
    "ms-MY": "Pemotong pertama ialah umpan dan dia tahu itu.",
    "th-TH": "คนตัดคนแรกคือตัวล่อ และเขารู้ตัว",
    "vi-VN": "Người cắt đầu tiên là mồi nhử và anh ta biết điều đó.",
}


# Each set is written out in full: the inbounder is always outside the
# line he is throwing from, the players break in different directions
# instead of shuffling down the lane together, and the pass is aimed at the
# man the set is designed to free. (key, label, free, home, away, ball_to);
# a player is (label, start, [(x, y, phase), ...]).
INBOUNDS_SETS = [
    ("stack", "stack", True, [
        ("1", (0.50, -0.03), [(0.30, 0.05, 1)]),
        ("2", (0.40, 0.10), [(0.08, 0.12, 0)]),      # first out: ball-side corner
        ("3", (0.40, 0.17), [(0.64, 0.09, 0)]),      # second: across to the far block
        ("4", (0.40, 0.24), [(0.52, 0.33, 0)]),      # third: back to the top
    ], [
        ("X2", (0.26, 0.13), [(0.16, 0.17, 0)]),
        ("X3", (0.26, 0.20), [(0.50, 0.15, 0)]),
    ], [(2, 0), ((0.50, 0.05), 1)]),
    ("the box", "the box", True, [
        ("1", (0.50, -0.03), [(0.44, 0.03, 2)]),
        ("2", (0.33, 0.19), [(0.20, 0.30, 0)]),
        ("3", (0.67, 0.19), [(0.80, 0.30, 0)]),
        ("4", (0.38, 0.10), [(0.28, 0.06, 0)]),
        ("5", (0.62, 0.10), [(0.56, 0.06, 1)]),      # the screener is the target
    ], [
        ("X2", (0.33, 0.26), [(0.24, 0.35, 1)]),
        ("X3", (0.67, 0.26), [(0.76, 0.35, 1)]),
    ], [(4, 1), ((0.50, 0.05), 2)]),
    ("the zipper", "the zipper", False, [
        ("1", (0.50, -0.03), [(0.60, 0.05, 2)]),
        ("2", (0.36, 0.10), [(0.44, 0.33, 1)]),      # straight up the lane line
        ("4", (0.64, 0.20), [(0.32, 0.21, 0)]),      # the down screen at the elbow
        ("3", (0.86, 0.28), []),
    ], [
        ("X2", (0.52, 0.07), [(0.52, 0.26, 1)]),
        ("X4", (0.64, 0.13), [(0.42, 0.16, 0)]),
    ], [(1, 1), ((0.50, 0.05), 2)]),
    ("sideline", "from the sideline", False, [
        # Just outside the sideline. It can only be JUST outside: the court
        # is drawn to 938 of a 1000-unit canvas and a token is 109 wide, so
        # the margin holds half an inbounder and no more.
        ("1", (1.03, 0.19), [(0.94, 0.24, 1)]),      # outside the SIDELINE
        ("2", (0.66, 0.20), [(0.86, 0.31, 0)]),
        ("3", (0.14, 0.28), []),
        ("4", (0.64, 0.08), [(0.44, 0.18, 0)]),
    ], [
        ("X2", (0.80, 0.15), [(0.78, 0.24, 0)]),
        ("X4", (0.50, 0.12), [(0.42, 0.08, 0)]),
    ], [(1, 0), ((0.50, 0.05), 1)]),
]


def inbounds_family() -> list[Drill]:
    # A sideline out-of-bounds is taken from outside the *sideline*, near
    # the free-throw line extended — not from behind the endline at
    # mid-width, which is where it stood, identical to the three baseline
    # sets. And the zipper is a player rising from the block up the lane
    # line off a down screen, not the box with two players deleted.
    out = []
    for key, label, free, home, away, route in INBOUNDS_SETS:
        out.append(Drill(
            id=f"bb_inbounds_{key.replace(' ', '_')}", category="setpiece",
            minutes=8, rel=True, free=free, off_surface=True,
            name=suffixed(SET_NAME, label), note=SET_NOTE,
            home=[P(*start, lab, moves=list(mv)) for lab, start, mv in home],
            away=[P(*start, lab, moves=list(mv)) for lab, start, mv in away],
            ball=0,
            # In to the man the set frees, then finished.
            ball_to=route,
        ))
    return out


ZONE_NAME = {"en": "Zone defence", "en-GB": "Zone defence", "zh-CN": "区域联防",
             "zh-TW": "區域聯防", "ja-JP": "ゾーンディフェンス", "ko-KR": "지역 방어",
             "es-ES": "Defensa en zona", "fr-FR": "Défense de zone",
             "id-ID": "Pertahanan zona", "ms-MY": "Pertahanan zon",
             "th-TH": "การป้องกันแบบโซน", "vi-VN": "Phòng ngự khu vực"}
ZONE_NOTE = {
    "en": "Move on the flight of the pass, not on the catch. A zone that shifts when the ball arrives is five players permanently one pass behind.",
    "en-GB": "Move on the flight of the pass, not on the catch. A zone that shifts when the ball arrives is five players permanently one pass behind.",
    "zh-CN": "在传球飞行途中就移动，不是等接到球才动。等球到了才转移的联防，就是五个人永远慢一传。",
    "zh-TW": "在傳球飛行途中就移動，不是等接到球才動。等球到了才轉移的聯防，就是五個人永遠慢一傳。",
    "ja-JP": "パスが飛んでいる間に動く。キャッチしてから動くゾーンは、5人が永久に1本遅れている。",
    "ko-KR": "패스가 날아가는 동안 움직여라. 잡은 뒤에 움직이는 지역방어는 다섯이 영원히 한 패스 늦는다.",
    "es-ES": "Muévete con el vuelo del pase, no con la recepción: una zona que se desplaza cuando llega el balón va siempre un pase por detrás.",
    "fr-FR": "Bouge pendant le vol de la passe, pas à la réception : une zone qui glisse à l'arrivée du ballon a toujours une passe de retard.",
    "id-ID": "Bergeraklah saat bola melayang, bukan saat ditangkap.",
    "ms-MY": "Bergerak semasa bola melayang, bukan semasa disambut.",
    "th-TH": "ขยับตอนบอลกำลังลอย ไม่ใช่ตอนรับบอล",
    "vi-VN": "Di chuyển khi bóng đang bay, không phải khi bắt bóng.",
}
OFFBALL_NAME = {"en": "Off-ball screen", "en-GB": "Off-ball screen",
                "zh-CN": "无球掩护", "zh-TW": "無球掩護", "ja-JP": "オフボールスクリーン",
                "ko-KR": "오프볼 스크린", "es-ES": "Bloqueo indirecto",
                "fr-FR": "Écran sans ballon", "id-ID": "Screen tanpa bola",
                "ms-MY": "Skrin tanpa bola", "th-TH": "การสกรีนนอกบอล",
                "vi-VN": "Màn chắn không bóng"}
OFFBALL_NOTE = {
    "en": "The cutter sets up his own screen: two steps the wrong way first, so the defender is on the wrong hip when the screen arrives.",
    "en-GB": "The cutter sets up his own screen: two steps the wrong way first, so the defender is on the wrong hip when the screen arrives.",
    "zh-CN": "跑位的人自己制造掩护效果：先朝反方向走两步，等掩护到位时防守人已经贴错了一侧。",
    "zh-TW": "跑位的人自己製造掩護效果：先朝反方向走兩步，等掩護到位時防守人已經貼錯了一側。",
    "ja-JP": "カッターが自分でスクリーンを活かす。まず逆へ2歩、スクリーンが来た時に守備が逆側の腰についている状態を作る。",
    "ko-KR": "커터가 스스로 스크린을 살린다. 먼저 반대로 두 걸음, 스크린이 올 때 수비가 반대쪽 허리에 붙어 있게 만든다.",
    "es-ES": "El cortador se prepara el bloqueo: dos pasos al lado contrario primero, para que el defensor esté en la cadera equivocada.",
    "fr-FR": "Le coupeur prépare son propre écran : deux pas dans le mauvais sens d'abord, pour que le défenseur soit sur la mauvaise hanche.",
    "id-ID": "Pemotong menyiapkan screen-nya sendiri: dua langkah ke arah salah dulu.",
    "ms-MY": "Pemotong menyediakan skrinnya sendiri: dua langkah ke arah salah dahulu.",
    "th-TH": "คนตัดเข้าต้องจัดสกรีนให้ตัวเอง ก้าวผิดทางสองก้าวก่อน",
    "vi-VN": "Người cắt tự tạo màn chắn: bước sai hướng hai bước trước đã.",
}
FT_NOTE = {
    "en": "Same routine, same number of dribbles, same breath — every time, in practice as well. A free throw is the only shot nobody is guarding, so nothing about it should ever change.",
    "en-GB": "Same routine, same number of dribbles, same breath — every time, in practice as well. A free throw is the only shot nobody is guarding, so nothing about it should ever change.",
    "zh-CN": "同一套动作、同样次数的运球、同一次呼吸——每一次都一样，训练时也一样。罚球是全场唯一没人防的球，所以它不该有任何变化。",
    "zh-TW": "同一套動作、同樣次數的運球、同一次呼吸——每一次都一樣，訓練時也一樣。罰球是全場唯一沒人防的球，所以它不該有任何變化。",
    "ja-JP": "同じルーティン、同じドリブル数、同じ呼吸。練習でも毎回同じに。フリースローは誰も守っていない唯一のシュートで、だからこそ何も変えてはいけない。",
    "ko-KR": "같은 루틴, 같은 드리블 횟수, 같은 호흡 — 연습에서도 매번. 자유투는 아무도 막지 않는 유일한 슛이다.",
    "es-ES": "La misma rutina, los mismos botes, la misma respiración, también en el entrenamiento. El tiro libre es el único que nadie defiende.",
    "fr-FR": "Même routine, même nombre de dribbles, même respiration — à l'entraînement aussi. Le lancer franc est le seul tir que personne ne défend.",
    "id-ID": "Rutinitas sama, jumlah dribel sama, napas sama — setiap kali, termasuk saat latihan.",
    "ms-MY": "Rutin sama, bilangan dribel sama, nafas sama — setiap kali.",
    "th-TH": "รูทีนเดิม จำนวนเลี้ยงบอลเท่าเดิม ลมหายใจเดิม ทุกครั้ง แม้ในการซ้อม",
    "vi-VN": "Cùng một quy trình, cùng số nhịp dẫn bóng, cùng một hơi thở — mọi lần, kể cả khi tập.",
}


# Off-ball screening, written out per set. All three used to share one
# generator that put cutter, screener and defender on the same lane line —
# a stagger with only one screener, a flex with the big under the rim, a
# pin-down nobody could see. (key, label, level, home, away).
OFFBALL_SETS = [
    ("pin_down", "the pin-down", "foundation", [
        ("1", (0.56, 0.33), []),
        ("2", (0.08, 0.12), [(0.14, 0.30, 1)]),      # curls up to the wing
        ("5", (0.34, 0.24), [(0.24, 0.19, 0)]),      # pins down at the block
        ("3", (0.94, 0.11), []),
    ], [
        ("X2", (0.14, 0.19), [(0.28, 0.26, 1)]),
        ("X1", (0.56, 0.26), []),
    ]),
    ("stagger", "the stagger", "development", [
        ("1", (0.36, 0.33), []),
        ("2", (0.92, 0.09), [(0.88, 0.31, 1)]),      # off both screens
        ("5", (0.62, 0.09), [(0.76, 0.12, 0)]),      # first screen
        ("4", (0.62, 0.22), [(0.76, 0.21, 0)]),      # second, a stride above it
        ("3", (0.06, 0.11), []),
    ], [
        ("X2", (0.86, 0.16), [(0.78, 0.26, 1)]),
        ("X1", (0.36, 0.26), []),
    ]),
    ("flex", "the flex cut", "development", [
        ("1", (0.66, 0.33), []),
        ("2", (0.08, 0.11), [(0.06, 0.16, 0), (0.62, 0.08, 1)]),
        ("5", (0.36, 0.20), [(0.36, 0.13, 0)]),      # weak-side block screen
        ("3", (0.30, 0.33), []),
    ], [
        ("X2", (0.18, 0.17), [(0.16, 0.22, 0), (0.46, 0.16, 1)]),
        ("X1", (0.76, 0.27), []),
    ]),
]


def gaps_family() -> list[Drill]:
    """Zone defence, off-ball screening and free throws.

    Forty-eight drills with no 2-3, no 1-3-1, no zone offence; one flare
    and nothing else off the ball — no pin-down, no stagger, no floppy;
    and not a single free throw. All verified absent from every name and
    note.
    """
    out = []
    zones = [("two_three", "the 2-3", "foundation",
              [(0.34, 0.24), (0.66, 0.24), (0.21, 0.15), (0.50, 0.09), (0.80, 0.14)]),
             ("one_three_one", "the 1-3-1", "advanced",
              [(0.50, 0.28), (0.22, 0.19), (0.50, 0.17), (0.78, 0.19), (0.50, 0.07)]),
             ("zone_offence", "attacking the zone", "development", None)]
    for key, label, lvl, spots in zones:
        if spots is None:
            # The offence: two guards up top to move the ball, a high post
            # in the middle of the zone, and a baseline runner behind it.
            home = [P(0.36, 0.34, "1", moves=[(0.26, 0.32, 0)]),
                    P(0.64, 0.34, "2", moves=[(0.76, 0.31, 1)]),
                    P(0.50, 0.20, "5", moves=[(0.34, 0.12, 1)]),
                    P(*CORNER_L, "3", moves=[(0.16, 0.09, 2)]),
                    P(*CORNER_R, "4", moves=[(0.84, 0.09, 2)])]
            away = [P(x, y, f"X{i + 1}",
                      moves=[(x + (0.5 - x) * 0.18, y + 0.02, 1)])
                    for i, (x, y) in enumerate(
                        [(0.34, 0.24), (0.66, 0.24), (0.16, 0.11),
                         (0.46, 0.08), (0.84, 0.11)])]
        else:
            # The zone attack stands OUTSIDE the zone, not on top of it:
            # the point guard above the top man, the big in the gap.
            two_three = (key == "two_three")
            home = [P(0.50, 0.34 if two_three else 0.36, "1",
                      moves=[((0.64, 0.35) if two_three else (0.66, 0.34))
                             + (1 if two_three else 0,)]),
                    P(*((0.96, 0.08) if two_three else CORNER_R), "2",
                      moves=[((0.88, 0.18) if two_three else (0.84, 0.14))
                             + (1 if two_three else 0,)]),
                    P(*(CORNER_L if two_three else (0.06, 0.24)), "3"),
                    P(*((0.40, 0.16) if two_three else (0.36, 0.11)), "5")]
            away = [P(x, y, f"X{i + 1}",
                      moves=[(x + (0.62 - x) * 0.22, y + 0.03, 1)])
                    for i, (x, y) in enumerate(spots)]
        out.append(Drill(
            id=f"bb_zone_{key}", category="defending", minutes=12, rel=True,
            level=lvl, free=(key == "two_three"),
            name=suffixed(ZONE_NAME, label), note=ZONE_NOTE,
            home=home, away=away, ball=0,
            # Swung across the top and into the baseline runner — the two
            # passes that make a zone shift and the shift that opens it.
            ball_to=([(1, 0), (1, 1), (3, 2)] if key == "two_three"
                     else [(0, 0), (1, 1), ((0.50, 0.05), 2)]),
        ))
    for key, label, lvl, home, away in OFFBALL_SETS:
        out.append(Drill(
            id=f"bb_offball_{key}", category="attacking", minutes=10, rel=True,
            level=lvl, free=(key == "pin_down"),
            name=suffixed(OFFBALL_NAME, label), note=OFFBALL_NOTE,
            home=[P(*st, lab, moves=list(mv)) for lab, st, mv in home],
            away=[P(*st, lab, moves=list(mv)) for lab, st, mv in away],
            ball=0,
            # Held up top while the 2 fights off the screen, delivered the
            # moment he clears — the pass the whole screen exists to earn.
            ball_to=[(1, 1)],
        ))
    out.append(Drill(
        id="bb_free_throw", category="finishing", minutes=8, rel=True,
        level="foundation", free=True,
        name={"en": "Free throws", "en-GB": "Free throws", "zh-CN": "罚球",
              "zh-TW": "罰球", "ja-JP": "フリースロー", "ko-KR": "자유투",
              "es-ES": "Tiros libres", "fr-FR": "Lancers francs",
              "id-ID": "Lemparan bebas", "ms-MY": "Lontaran percuma",
              "th-TH": "การยิงลูกโทษ", "vi-VN": "Ném phạt"},
        note=FT_NOTE,
        # By rule the defending team takes the two spaces closest to the
        # basket; the shooter's own team-mates line up outside them. That is
        # also why the rebound off a missed free throw belongs to X2.
        home=[P(0.50, 0.21, "1"),
              P(0.35, 0.17, "2", moves=[(0.28, 0.12, 1)]),
              P(0.65, 0.17, "3")],
        away=[P(0.35, 0.095, "X2", moves=[(0.46, 0.07, 1)]),
              P(0.65, 0.095, "X3")],
        ball=0,
            # the shot goes up; the rebound is the drill
            ball_to=[((0.50, 0.05), 0), ("a0", 1)],
    ))
    return out


# The sets whose last pass frees a man for the shot — so the shot is drawn.
# A pattern that ended on the roller's or the cutter's hands showed what he
# was freed for only in the note. The basket is at (0.50, 0.05).
FINISH_AT_THE_BASKET = [
    "bb_five_out_spacing", "bb_pick_and_roll", "bb_pick_and_pop",
    "bb_backdoor_cut", "bb_horns_set", "bb_closeout", "bb_3v3_no_dribble",
    "bb_screen_top", "bb_cut_give_and_go", "bb_cut_backdoor", "bb_cut_flare",
    "bb_cut_baseline", "bb_post_kick_out", "bb_zone_two_three",
    "bb_offball_pin_down", "bb_offball_stagger", "bb_offball_flex",
    # …and the coverage drills end on the handler's shot the coverage
    # is there to contest.
    "bb_defence_drop", "bb_defence_hedge", "bb_defence_switch", "bb_defence_ice",
]
# The press break is over when the ball is across halfway.
OVER_HALFWAY = ["bb_press_break"]


def basketball_library() -> list[Drill]:
    from .engine import finish_with, merge
    drills = merge(basketball_drills(), ball_screen_family(), cut_family(),
                   shooting_family(), post_family(), defence_family(),
                   shell_drill(), transition_family(), inbounds_family(), gaps_family(),
                   set_plays(), pnr_reads(), inbound_plays(), press_plays(),
                   zone_offence(), zone_defence_more(), man_defence(),
                   transition_plays(), skill_drills())
    finish_with(drills, (0.50, 0.05), FINISH_AT_THE_BASKET)
    finish_with(drills, (0.50, 0.42), OVER_HALFWAY)
    return drills

def shell_drill() -> list[Drill]:
    """4v4 shell — the one defensive drill every programme runs. Its absence
    was the first thing a coach reviewing this library would have noticed."""
    o = [CORNER_L, WING_L, WING_R, CORNER_R]
    D = [(0.20, 0.08), (0.27, 0.21), (0.73, 0.21), (0.80, 0.08)]
    return [Drill(
        id="bb_shell_4v4", category="defending", minutes=12, rel=True,
        free=True,
        name={"en": "Shell drill 4v4", "en-GB": "Shell drill 4v4",
              "zh-CN": "4v4 防守轮转", "zh-TW": "4v4 防守輪轉",
              "ja-JP": "シェルドリル 4対4", "ko-KR": "쉘 드릴 4대4",
              "es-ES": "Shell 4c4", "fr-FR": "Shell drill 4c4",
              "id-ID": "Shell drill 4v4", "ms-MY": "Shell drill 4v4",
              "th-TH": "เชลล์ดริล 4v4", "vi-VN": "Shell drill 4v4"},
        note={"en": "On every pass the whole shell moves — ball, you, man. "
                    "The defender who shifts late is the one a guard hunts.",
              "en-GB": "On every pass the whole shell moves — ball, you, man. "
                       "The defender who shifts late is the one a guard hunts.",
              "zh-CN": "每一次传球，整个防守壳都要动——球、你、人三点连线。谁挪得慢，控卫就打谁。",
              "zh-TW": "每一次傳球，整個防守殼都要動——球、你、人三點連線。誰挪得慢，控衛就打誰。",
              "ja-JP": "パスのたびにシェル全体が動く。ボール・自分・マークの3点を結び直す。ずれるのが遅い守備者こそガードの獲物だ。",
              "ko-KR": "패스 한 번마다 셸 전체가 움직인다 — 볼, 나, 맨. 늦게 움직이는 수비수가 가드의 사냥감이 된다.",
              "es-ES": "En cada pase se mueve toda la concha: balón, tú, atacante. "
                       "Al defensor que llega tarde es al que caza el base.",
              "fr-FR": "À chaque passe toute la coquille bouge : ballon, toi, joueur. "
                       "Le défenseur en retard est celui que le meneur chasse.",
              "id-ID": "Setiap umpan seluruh shell bergerak — bola, kamu, lawan.",
              "ms-MY": "Setiap hantaran seluruh shell bergerak — bola, anda, lawan.",
              "th-TH": "ทุกการส่งบอล เชลล์ทั้งวงต้องขยับ — บอล ตัวเอง คนที่ประกบ ใครขยับช้าคือเหยื่อของการ์ด",
              "vi-VN": "Mỗi đường chuyền cả lớp vỏ phòng thủ phải dịch — bóng, bạn, người. "
                       "Ai dịch chậm là con mồi của hậu vệ."},
        # The four attackers hold the shell's four spots; each defender
        # starts a stride inside his man, toward the lane and toward the
        # basket, which is the shell's whole starting rule.
        home=[P(x, y, f"{i + 1}") for i, (x, y) in enumerate(o)],
        away=[P(*d, f"X{i + 1}",
                moves=[(d[0] * 0.6 + 0.5 * 0.4, d[1] * 0.7 + 0.06 * 0.3,
                        (i + 1) % 3),
                       (d[0], d[1], ((i + 1) % 3) + 1)])
              for i, d in enumerate(D)],
        ball=0,                     # the swing starts from the corner
        # And swings back. A shell drill is the defence shifting on every
        # pass; stopping at the far man shows the shift out and never the
        # shift home, which is the half a guard hunts.
        ball_to=[(1, 0), (2, 1), (3, 2), (0, 3)],
    )]




# ─────────────────────────────────────────────────────────────────────────────
# The play bank (2026-10-13). What a coach opens a basketball board for is a
# named play he can run on Tuesday: the flex, a floppy, Spain, a 2-2-1 press,
# how a 2-3 zone rotates to the corner. Every one below is written out — its
# own alignment on the real court, its own coaching point — rather than
# generated, because a set play is defined by where each man stands and in
# what order he moves, and that differs set by set.
#
# Court landmarks as the app draws them (measured off the renders): rim
# (0.50, 0.057), free-throw line y 0.21 with the elbows at x 0.38 / 0.62,
# lane 0.30..0.70 wide at the baseline, top of the arc y 0.30, corner threes
# outside x 0.06 / 0.94. A perimeter man stands a stride outside the arc.
# ─────────────────────────────────────────────────────────────────────────────
def _n(en, zh, zht, ja, ko, es, fr, id_, ms, th, vi):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht, "ja-JP": ja,
            "ko-KR": ko, "es-ES": es, "fr-FR": fr, "id-ID": id_, "ms-MY": ms,
            "th-TH": th, "vi-VN": vi}


def _play(id_, category, name, note, home, away=(), *, ball=0, to=(),
          follow=None, free=False, level=None, minutes=12, usage=2,
          off=False, markers=()):
    """One play: players as (label, (x, y), [(x, y, beat), ...])."""
    return Drill(
        id=id_, category=category, minutes=minutes, rel=True, free=free,
        level=level, usage=usage, off_surface=off, name=name, note=note,
        home=[P(*st, lab, moves=list(mv)) for lab, st, mv in home],
        away=[P(*st, lab, moves=list(mv)) for lab, st, mv in away],
        markers=list(markers), ball=ball, ball_to=list(to),
        ball_follow=follow)


BASKET = (0.50, 0.05)


def set_plays() -> list[Drill]:
    """Half-court sets, each with the alignment that names it."""
    return [
        # Ball reversed from the right slot; the weak-side corner man runs
        # the baseline off the block screen to the ball-side block, and the
        # passer then screens down for the screener, who comes to the top.
        _play("bb_set_flex", "attacking",
              _n("Flex offence", "弹性进攻", "彈性進攻", "フレックスオフェンス",
                 "플렉스 오펜스", "Ataque flex", "Attaque flex", "Serangan flex",
                 "Serangan flex", "เกมรุกเฟล็กซ์", "Hệ thống tấn công flex"),
              _n("The flex cutter waits for the screen to be set, then runs shoulder to shoulder off it — leave early and the screener has nobody to hit. The passer then screens the screener: every cut in the flex is followed by a screen.",
                 "Flex 切入者要等掩护站稳再贴着掩护人的肩膀切——走早了，掩护人什么也挡不到。传球人随后给掩护人做下掩护：Flex 里每一次切入后面都跟着一次掩护。",
                 "Flex 切入者要等掩護站穩再貼著掩護人的肩膀切——走早了，掩護人什麼也擋不到。傳球人隨後給掩護人做下掩護：Flex 裡每一次切入後面都跟著一次掩護。",
                 "フレックスカッターはスクリーンがセットされるのを待ち、肩を擦るように使う。早く出るとスクリナーは誰にも当たれない。パサーは続けてスクリナーにスクリーンをかける。フレックスでは全てのカットの後にスクリーンが続く。",
                 "플렉스 커터는 스크린이 세워질 때까지 기다렸다가 어깨를 스치듯 지나간다 — 일찍 떠나면 스크리너는 아무도 막지 못한다. 패서는 이어서 스크리너에게 스크린을 걸어 준다. 플렉스에서는 모든 컷 뒤에 스크린이 따라온다.",
                 "El cortador del flex espera a que el bloqueo esté puesto y sale rozándolo hombro con hombro; si sale antes, el bloqueador no golpea a nadie. Después el pasador bloquea al bloqueador: en el flex cada corte va seguido de un bloqueo.",
                 "Le coupeur du flex attend que l'écran soit posé, puis le frôle épaule contre épaule — parti trop tôt, l'écran ne touche personne. Le passeur pose ensuite un écran pour le poseur : dans le flex, chaque coupe est suivie d'un écran.",
                 "Pemotong flex menunggu screen terpasang, lalu lewat bahu ke bahu — berangkat terlalu cepat dan screen tak mengenai siapa pun. Pengumpan lalu memasang screen untuk si pemasang screen.",
                 "Pemotong flex menunggu skrin dipasang, kemudian lalu bahu ke bahu — bergerak terlalu awal dan skrin tidak mengenai sesiapa. Penghantar kemudian memasang skrin untuk pemasang skrin.",
                 "คนตัดของเฟล็กซ์ต้องรอให้สกรีนตั้งนิ่งก่อน แล้ววิ่งเฉียดไหล่ผ่านไป ออกเร็วไปสกรีนก็ไม่โดนใคร จากนั้นคนส่งบอลลงไปสกรีนให้คนสกรีน ทุกการตัดในเฟล็กซ์จะตามด้วยสกรีน",
                 "Người cắt flex chờ màn chắn đứng vững rồi mới lướt sát vai qua — đi sớm thì người chắn không chặn được ai. Sau đó người chuyền chắn cho người vừa chắn: trong flex, mỗi pha cắt đều có một màn chắn theo sau."),
              [("1", (0.70, 0.33), [(0.67, 0.21, 2)]),
               ("2", (0.30, 0.33), []),
               ("3", (0.95, 0.10), [(0.33, 0.09, 1)]),
               ("4", (0.69, 0.11), [(0.58, 0.32, 3)]),
               ("5", (0.05, 0.10), [])],
              to=[(1, 0), (2, 2), (BASKET, 3)], free=True, usage=3),
        # 4-out 1-in: pass to the wing, screen away for the far wing, who
        # curls to the top; the screener pops once the cutter is past him.
        _play("bb_set_screen_away", "attacking",
              _n("Motion offence: screen away", "移动进攻：传球后弱侧掩护",
                 "移動進攻：傳球後弱側掩護", "モーション：スクリーンアウェイ",
                 "모션 오펜스: 스크린 어웨이", "Ataque en movimiento: bloqueo lejos del balón",
                 "Attaque motion : écran loin du ballon", "Motion offense: screen menjauh",
                 "Serangan motion: skrin menjauh", "โมชันออฟเฟนส์: สกรีนฝั่งไกลบอล",
                 "Tấn công chuyển động: chắn xa bóng"),
              _n("Screen the man, not the space: chest on the defender's shoulder, feet still. The cutter reads him — if he trails, curl to the ball; if he goes under, pop out for the shot.",
                 "掩护的是人，不是一块空地：胸口顶在防守人的肩膀上，脚站住不动。切的人看防守人——他跟在后面就内切迎球，他从下面绕就外弹投篮。",
                 "掩護的是人，不是一塊空地：胸口頂在防守人的肩膀上，腳站住不動。切的人看防守人——他跟在後面就內切迎球，他從下面繞就外彈投籃。",
                 "スペースではなく人にスクリーン：胸を相手の肩に当て、足は止める。カッターは相手を読む——後ろから追えばカールしてボールへ、下をくぐればポップしてシュート。",
                 "공간이 아니라 사람에게 스크린: 가슴을 수비의 어깨에 대고 발은 멈춘다. 커터는 수비를 읽는다 — 뒤따라오면 컬로 공에게, 아래로 돌면 팝으로 슛.",
                 "Bloquea al hombre, no al espacio: el pecho en el hombro del defensor y los pies quietos. El cortador lo lee: si lo persigue, curl hacia el balón; si pasa por debajo, abre para tirar.",
                 "Écrante le joueur, pas l'espace : poitrine sur l'épaule du défenseur, pieds immobiles. Le coupeur le lit — s'il suit, curl vers le ballon ; s'il passe dessous, ressors pour tirer.",
                 "Screen orangnya, bukan ruangnya: dada di bahu bek, kaki diam. Pemotong membaca bek — jika mengekor, curl ke bola; jika lewat bawah, keluar untuk menembak.",
                 "Skrin orangnya, bukan ruangnya: dada pada bahu pemain bertahan, kaki diam. Pemotong membaca — jika mengekor, curl ke bola; jika lalu bawah, keluar untuk menjaring.",
                 "สกรีนที่ตัวคน ไม่ใช่พื้นที่ อกชนไหล่กองหลัง เท้านิ่ง คนตัดอ่านกองหลัง ถ้าไล่ตามหลังให้เคิร์ลเข้าหาบอล ถ้าลอดใต้ให้ป๊อปออกไปยิง",
                 "Chắn người chứ không chắn khoảng trống: ngực áp vai hậu vệ, chân đứng yên. Người cắt đọc hậu vệ — bám sau thì vòng vào đón bóng, luồn dưới thì bật ra ném."),
              [("1", (0.50, 0.34), [(0.76, 0.22, 1), (0.90, 0.16, 3)]),
               ("2", (0.13, 0.25), []),
               ("3", (0.87, 0.27), [(0.54, 0.33, 2)]),
               ("4", (0.04, 0.09), []),
               ("5", (0.69, 0.11), [])],
              [("X3", (0.80, 0.21), [(0.74, 0.25, 2)])],
              to=[(1, 0), (2, 3), (BASKET, 4)], free=True, usage=3),
        # The shooter under the rim, a single screen on one block and a
        # double on the other; he takes the double and comes out on the wing.
        _play("bb_set_floppy", "attacking",
              _n("Floppy set", "篮下选边双掩护", "籃下選邊雙掩護",
                 "フロッピー", "플로피 세트", "Sistema floppy", "Système floppy",
                 "Set floppy", "Set floppy", "แผนฟลอปปี้", "Bài floppy"),
              _n("The shooter starts under the rim and makes his defender choose. Trail him and he runs off the double; cheat toward the double and he takes the single. Catch with the feet already turned to the rim.",
                 "投手从篮下出发，逼防守人做选择：跟在身后，他就绕双掩护那侧；提前抢到双掩护那侧，他就走单掩护。接球时脚尖已经对准篮筐。",
                 "投手從籃下出發，逼防守人做選擇：跟在身後，他就繞雙掩護那側；提前搶到雙掩護那側，他就走單掩護。接球時腳尖已經對準籃框。",
                 "シューターはリング下から始め、マークに選ばせる。後ろを追えばダブル側へ、ダブル側を先読みすればシングル側へ。キャッチの時には足がもうリングを向いている。",
                 "슈터는 림 아래에서 출발해 수비에게 선택을 강요한다. 뒤따라오면 더블 쪽으로, 더블 쪽을 미리 막으면 싱글 쪽으로. 잡을 때 발은 이미 림을 향해 있다.",
                 "El tirador sale de debajo del aro y obliga a su defensor a elegir: si lo persigue, sale por el doble; si se adelanta al doble, toma el simple. Recibe con los pies ya mirando al aro.",
                 "Le shooteur part sous le cercle et force son défenseur à choisir : s'il suit, il sort par le double ; s'il anticipe le double, il prend le simple. Il réceptionne les pieds déjà tournés vers le panier.",
                 "Penembak mulai di bawah ring dan memaksa penjaganya memilih: mengekor, dia lewat screen ganda; mendahului ke ganda, dia ambil yang tunggal. Tangkap dengan kaki sudah menghadap ring.",
                 "Penjaring bermula di bawah jaring dan memaksa penjaganya memilih: mengekor, dia guna skrin berganda; mendahului ke berganda, dia ambil skrin tunggal. Tangkap dengan kaki sudah menghadap jaring.",
                 "คนยิงเริ่มใต้ห่วงและบังคับให้คนประกบเลือก ไล่ตามหลังก็ออกทางสกรีนคู่ ดักฝั่งสกรีนคู่ก็ออกทางสกรีนเดี่ยว รับบอลโดยเท้าหันเข้าห่วงแล้ว",
                 "Xạ thủ xuất phát dưới rổ và buộc người kèm phải chọn: bám theo thì chạy qua màn chắn đôi; đoán trước bên đôi thì lấy bên đơn. Bắt bóng khi chân đã hướng về rổ."),
              [("1", (0.50, 0.38), []),
               ("2", (0.50, 0.09), [(0.42, 0.09, 0), (0.86, 0.25, 1)]),
               ("5", (0.32, 0.14), []),
               ("4", (0.66, 0.15), []),
               ("3", (0.74, 0.15), [])],
              [("X2", (0.50, 0.14), [(0.44, 0.13, 0), (0.68, 0.10, 1), (0.80, 0.21, 2)])],
              to=[(1, 2), (BASKET, 3)], level="advanced"),
        # Pass to the wing, then cut off the high post's back screen; the
        # screener pops to the top as the second option.
        _play("bb_set_ucla", "attacking",
              _n("UCLA cut", "高位背掩护切入", "高位背掩護切入", "ハイポストのバックスクリーンカット", "하이포스트 백스크린 컷",
                 "Corte UCLA", "Coupe UCLA", "Potongan UCLA", "Potongan UCLA",
                 "การตัดผ่านสกรีนหลังที่ไฮโพสต์", "Cắt UCLA"),
              _n("Pass to the wing and cut at once, off the high post's shoulder — the defender who turns to watch the pass is the one who gets screened. The screener then pops to the top: he is the second option, not a spectator.",
                 "传给侧翼后立刻切，贴着高位掩护人的肩膀走——回头看球的防守人就是被挡住的那个。掩护人随后外弹到弧顶：他是第二选择，不是看客。",
                 "傳給側翼後立刻切，貼著高位掩護人的肩膀走——回頭看球的防守人就是被擋住的那個。掩護人隨後外彈到弧頂：他是第二選擇，不是看客。",
                 "ウイングへパスしたらすぐ、ハイポストの肩を擦ってカット。パスを目で追ったディフェンスがスクリーンにかかる。スクリナーはその後トップへポップ。彼は第2の選択肢で、観客ではない。",
                 "윙에 패스하자마자 하이포스트의 어깨를 스치며 컷 — 패스를 쳐다본 수비가 스크린에 걸린다. 스크리너는 이어서 탑으로 팝: 그는 두 번째 옵션이지 구경꾼이 아니다.",
                 "Pasa al alero y corta enseguida rozando al poste alto: el defensor que se gira a mirar el pase es el que se come el bloqueo. Luego el bloqueador sale al frontal: es la segunda opción, no un espectador.",
                 "Passe à l'aile et coupe aussitôt en frôlant le poste haut — le défenseur qui se retourne pour suivre la passe prend l'écran. Le poseur ressort ensuite en tête de raquette : c'est la deuxième option, pas un spectateur.",
                 "Umpan ke sayap lalu langsung cut menyusur bahu high post — bek yang menoleh melihat umpan itulah yang kena screen. Pemasang screen lalu keluar ke puncak: dia opsi kedua, bukan penonton.",
                 "Hantar ke sayap dan terus potong menyusur bahu tiang tinggi — pemain bertahan yang menoleh melihat hantaran itulah yang terkena skrin. Pemasang skrin kemudian keluar ke puncak: dia pilihan kedua, bukan penonton.",
                 "ส่งให้ปีกแล้วตัดทันทีเฉียดไหล่ไฮโพสต์ กองหลังที่หันไปมองบอลคือคนที่โดนสกรีน จากนั้นคนสกรีนป๊อปขึ้นยอดวง เขาคือทางเลือกที่สอง ไม่ใช่คนดู",
                 "Chuyền ra cánh rồi cắt ngay sát vai người ở high post — hậu vệ quay đầu nhìn đường chuyền chính là người dính màn chắn. Người chắn sau đó bật lên đỉnh vòng: anh ta là phương án hai, không phải khán giả."),
              [("1", (0.66, 0.34), [(0.56, 0.09, 1)]),
               ("2", (0.87, 0.25), []),
               ("5", (0.62, 0.21), [(0.50, 0.34, 2)]),
               ("3", (0.13, 0.25), []),
               ("4", (0.04, 0.09), [])],
              [("X1", (0.64, 0.28), [(0.72, 0.29, 0), (0.65, 0.22, 1)])],
              to=[(1, 0), (0, 2), (BASKET, 3)], free=True),
        # Drive baseline from the right wing; the weak-side help drops into
        # the lane and the hammer screen pins him there for the skip.
        _play("bb_set_hammer", "attacking",
              _n("Hammer action", "锤子战术", "鎚子戰術", "ハンマー",
                 "해머 액션", "Acción hammer", "Action hammer", "Aksi hammer",
                 "Aksi hammer", "แฮมเมอร์แอ็กชัน", "Pha hammer"),
              _n("The baseline drive is bait: it pulls the weak-side corner defender into the lane, and he is the man the hammer screen hits. Throw the skip the moment he commits — once he has recovered, the screen was for nothing.",
                 "底线突破是诱饵：把弱侧底角的防守人吸进禁区，锤子掩护挡的就是他。他一动就甩出转移长传——等他回位了，这个掩护就白做了。",
                 "底線突破是誘餌：把弱側底角的防守人吸進禁區，鎚子掩護擋的就是他。他一動就甩出轉移長傳——等他回位了，這個掩護就白做了。",
                 "ベースラインドライブは餌。弱サイドのコーナーディフェンスをレーンへ引き込み、ハンマースクリーンはその男に当てる。彼が動いた瞬間にスキップパス。戻られたらスクリーンは無駄だ。",
                 "베이스라인 돌파는 미끼다. 약측 코너 수비를 레인으로 끌어들이고, 해머 스크린은 바로 그를 친다. 그가 움직이는 순간 스킵 패스 — 복귀한 뒤면 스크린은 헛수고다.",
                 "La penetración por fondo es el cebo: atrae al defensor de la esquina débil a la zona, y es a él a quien golpea el bloqueo hammer. Lanza el pase cruzado en cuanto se comprometa; si ya ha vuelto, el bloqueo no sirvió.",
                 "La pénétration en ligne de fond est l'appât : elle attire le défenseur du corner faible dans la raquette, et c'est lui que l'écran hammer frappe. Lance la passe transversale dès qu'il s'engage — s'il est revenu, l'écran n'a servi à rien.",
                 "Penetrasi baseline adalah umpan: menarik bek sudut sisi lemah ke area, dan dialah yang dihantam screen hammer. Lempar umpan silang begitu dia bergerak — kalau sudah kembali, screen sia-sia.",
                 "Rempuhan garisan belakang ialah umpan: menarik pemain bertahan penjuru sisi lemah ke kawasan, dan dialah yang dikenai skrin hammer. Baling hantaran silang sebaik dia bergerak.",
                 "การเลี้ยงเลียบเส้นหลังคือเหยื่อ ดึงกองหลังมุมฝั่งอ่อนเข้ามาในเขต และเขาคือคนที่สกรีนแฮมเมอร์ชน โยนข้ามฝั่งทันทีที่เขาขยับ ถ้าเขากลับไปแล้วสกรีนก็สูญเปล่า",
                 "Pha đột phá đường biên ngang là mồi: kéo hậu vệ góc bên yếu vào khu vực, và màn chắn hammer nhắm vào chính anh ta. Chuyền vượt sân ngay khi anh ta lao vào — đợi anh ta về thì màn chắn vô ích."),
              [("1", (0.86, 0.25), [(0.80, 0.07, 0)]),
               ("2", (0.72, 0.35), []),
               ("5", (0.50, 0.36), []),
               ("4", (0.13, 0.27), [(0.24, 0.13, 1), (0.40, 0.08, 2)]),
               ("3", (0.04, 0.09), [(0.07, 0.22, 1)])],
              [("X1", (0.80, 0.20), [(0.84, 0.11, 0)]),
               ("X3", (0.16, 0.14), [(0.36, 0.10, 0), (0.28, 0.13, 1)])],
              to=[(0, 0), (4, 2), (BASKET, 3)], level="advanced"),
        # Two screeners at the top of the key with a gap between them; the
        # shooter runs up the middle and they shut the doors behind him.
        _play("bb_set_elevator", "attacking",
              _n("Elevator doors", "电梯门战术", "電梯門戰術", "エレベーター",
                 "엘리베이터 도어", "Puertas del ascensor", "Portes d'ascenseur",
                 "Pintu lift", "Pintu lif", "ประตูลิฟต์", "Cửa thang máy"),
              _n("The two screeners stand a body apart until the shooter is through, then step together and shut the gap on his defender. Close too early and you screen your own man; too late and the defender walks straight through.",
                 "两个掩护人先隔开一个身位，等投手穿过去，再并拢把缝关上，挡住追来的防守人。关早了挡的是自己人，关晚了防守人直接穿过去。",
                 "兩個掩護人先隔開一個身位，等投手穿過去，再併攏把縫關上，擋住追來的防守人。關早了擋的是自己人，關晚了防守人直接穿過去。",
                 "2人のスクリナーは体1つ分空けて立ち、シューターが抜けたら寄って隙間を閉じ、追うディフェンスを止める。早く閉じれば味方を止め、遅ければ相手は素通りする。",
                 "두 스크리너는 몸 하나 간격으로 서 있다가 슈터가 지나가면 붙어서 틈을 닫아 수비를 막는다. 너무 일찍 닫으면 자기 편을 막고, 늦으면 수비가 그냥 통과한다.",
                 "Los dos bloqueadores separados un cuerpo hasta que pasa el tirador; entonces se juntan y cierran el hueco a su defensor. Cerrar pronto es bloquear al compañero; tarde, y el defensor pasa tan tranquilo.",
                 "Les deux poseurs restent écartés d'un corps jusqu'au passage du shooteur, puis se rapprochent et ferment l'espace à son défenseur. Trop tôt, ils bloquent leur coéquipier ; trop tard, le défenseur passe.",
                 "Dua pemasang screen berjarak satu badan sampai penembak lewat, lalu merapat menutup celah bagi penjaganya. Terlalu cepat menutup berarti menghalangi rekan sendiri; terlambat, bek lewat begitu saja.",
                 "Dua pemasang skrin berjarak satu badan sehingga penjaring lalu, kemudian merapat menutup ruang bagi penjaganya. Terlalu awal menghalang rakan sendiri; terlambat, pemain bertahan terus lalu.",
                 "คนสกรีนสองคนยืนห่างกันหนึ่งตัวจนคนยิงผ่านไป แล้วขยับชิดปิดช่องใส่คนที่ไล่ตาม ปิดเร็วไปจะขวางเพื่อนเอง ปิดช้าไปกองหลังก็เดินผ่าน",
                 "Hai người chắn đứng cách nhau một thân người cho đến khi xạ thủ đi qua, rồi khép lại đóng khe trước hậu vệ đuổi theo. Khép sớm là chặn đồng đội; khép muộn thì hậu vệ đi thẳng qua."),
              [("1", (0.87, 0.25), []),
               ("2", (0.50, 0.12), [(0.50, 0.34, 1)]),
               ("4", (0.41, 0.24), [(0.46, 0.25, 2)]),
               ("5", (0.59, 0.24), [(0.54, 0.25, 2)]),
               ("3", (0.13, 0.25), [])],
              [("X2", (0.44, 0.08), [(0.48, 0.18, 1), (0.50, 0.21, 2)])],
              to=[(1, 2), (BASKET, 3)], usage=1),
        # A pin-down for the wing, run straight into a handoff from the big
        # dribbling at him; the big rolls and the wing turns downhill.
        _play("bb_set_chicago", "attacking",
              _n("Chicago action", "芝加哥战术（下掩护接手递手）", "芝加哥戰術（下掩護接手遞手）",
                 "シカゴアクション", "시카고 액션", "Acción Chicago", "Action Chicago",
                 "Aksi Chicago", "Aksi Chicago", "ชิคาโกแอ็กชัน", "Pha Chicago"),
              _n("A pin-down straight into a handoff — two screens in one run. The cutter never stops between them: a defender who trailed the pin-down is still behind him when the handoff comes.",
                 "下掩护直接接手递手——一趟跑动吃两个掩护。切的人中间绝不停：跟在下掩护后面的防守人，到手递手时还落在后面。",
                 "下掩護直接接手遞手——一趟跑動吃兩個掩護。切的人中間絕不停：跟在下掩護後面的防守人，到手遞手時還落在後面。",
                 "ピンダウンからそのままハンドオフ——1回の走りで2つのスクリーン。カッターは間で止まらない。ピンダウンで遅れたマークは、ハンドオフの時もまだ後ろにいる。",
                 "핀다운에서 곧장 핸드오프로 — 한 번 뛰며 스크린 두 개. 커터는 그 사이에 절대 멈추지 않는다. 핀다운에서 뒤처진 수비는 핸드오프 때도 여전히 뒤에 있다.",
                 "Un bloqueo hacia abajo directo a una entrega: dos bloqueos en una carrera. El cortador no se para entre ellos: el defensor que llegó tarde al primero sigue detrás en la entrega.",
                 "Un écran descendant enchaîné sur une remise : deux écrans dans une seule course. Le coupeur ne s'arrête jamais entre les deux — le défenseur en retard sur le premier l'est encore à la remise.",
                 "Pin-down langsung ke handoff — dua screen dalam satu lari. Pemotong tak berhenti di antaranya: bek yang tertinggal di pin-down masih di belakang saat handoff.",
                 "Pin-down terus ke serahan — dua skrin dalam satu larian. Pemotong tidak berhenti di antaranya: pemain bertahan yang ketinggalan masih di belakang semasa serahan.",
                 "พินดาวน์ต่อด้วยแฮนด์ออฟทันที สองสกรีนในการวิ่งครั้งเดียว คนตัดไม่หยุดระหว่างกลาง กองหลังที่ตามไม่ทันพินดาวน์ก็ยังอยู่ข้างหลังตอนรับแฮนด์ออฟ",
                 "Màn chắn xuống nối thẳng vào pha trao bóng — hai màn chắn trong một lần chạy. Người cắt không dừng ở giữa: hậu vệ chậm ở màn chắn đầu vẫn còn ở sau lưng khi nhận trao bóng."),
              [("5", (0.44, 0.35), [(0.36, 0.32, 1), (0.56, 0.08, 2)]),
               ("2", (0.20, 0.07), [(0.28, 0.27, 1), (0.42, 0.15, 3)]),
               ("4", (0.13, 0.26), [(0.20, 0.15, 0)]),
               ("1", (0.72, 0.35), []),
               ("3", (0.96, 0.09), [])],
              [("X2", (0.24, 0.12), [(0.22, 0.19, 1), (0.32, 0.24, 2), (0.38, 0.20, 3)])],
              to=[(0, 1), (1, 2), (1, 3), (BASKET, 4)], level="advanced"),
        # The wing runs across the top of both elbow screens to the far wing.
        _play("bb_set_iverson", "attacking",
              _n("Iverson cut", "艾弗森切（高位双掩护横切）", "艾佛森切（高位雙掩護橫切）",
                 "アイバーソンカット", "아이버슨 컷", "Corte Iverson", "Coupe Iverson",
                 "Potongan Iverson", "Potongan Iverson", "การตัดไอเวอร์สัน", "Cắt Iverson"),
              _n("Run across the top off both elbow screens without slowing — the screeners stand still and let the trailing defender run into them. Catch on the far wing with the feet set; the big can follow with a ball screen.",
                 "不减速地从两肘的两个掩护上方横切过去——掩护人站住不动，让追在后面的防守人自己撞上来。在另一侧侧翼接球时脚已站好；内线可以接着上来挡拆。",
                 "不減速地從兩肘的兩個掩護上方橫切過去——掩護人站住不動，讓追在後面的防守人自己撞上來。在另一側側翼接球時腳已站好；內線可以接著上來擋拆。",
                 "両エルボーのスクリーンの上を減速せずに横切る。スクリナーは動かず、追ってくるディフェンスをぶつからせる。逆ウイングで足を作ってキャッチ。ビッグはそのままボールスクリーンへ。",
                 "양쪽 엘보 스크린 위를 속도를 줄이지 않고 가로지른다 — 스크리너는 가만히 서서 뒤따르는 수비가 부딪치게 둔다. 반대쪽 윙에서 발을 준비하고 받는다. 빅맨은 이어서 볼 스크린.",
                 "Cruza por arriba de los dos bloqueos de los codos sin frenar: los bloqueadores quietos dejan que el defensor que persigue choque con ellos. Recibe en el ala contraria con los pies listos; el pívot puede seguir con un bloqueo directo.",
                 "Traverse au-dessus des deux écrans aux coudes sans ralentir — les poseurs restent immobiles et laissent le défenseur qui suit s'y heurter. Réceptionne à l'aile opposée appuis prêts ; l'intérieur peut enchaîner sur un écran porteur.",
                 "Lari menyeberang di atas dua screen elbow tanpa melambat — pemasang screen diam dan biarkan bek yang mengejar menabrak. Tangkap di sayap seberang dengan kaki siap; big man bisa lanjut dengan screen bola.",
                 "Lari menyeberang di atas dua skrin elbow tanpa perlahan — pemasang skrin diam dan biarkan pemain bertahan yang mengejar melanggar. Tangkap di sayap bertentangan dengan kaki sedia.",
                 "วิ่งตัดผ่านเหนือสกรีนสองตัวที่เอลโบว์โดยไม่ชะลอ คนสกรีนยืนนิ่งให้กองหลังที่ไล่ตามชนเอง รับที่ปีกฝั่งตรงข้ามโดยตั้งเท้าแล้ว บิ๊กแมนต่อด้วยสกรีนบอลได้",
                 "Chạy ngang phía trên hai màn chắn ở elbow mà không giảm tốc — người chắn đứng yên để hậu vệ đuổi theo tự va vào. Bắt bóng ở cánh bên kia với chân đã sẵn; trung phong có thể lên chắn tiếp."),
              [("1", (0.50, 0.42), [(0.66, 0.38, 0)]),
               ("2", (0.13, 0.25), [(0.50, 0.29, 1), (0.86, 0.26, 2)]),
               ("4", (0.37, 0.21), []),
               ("5", (0.63, 0.21), []),
               ("3", (0.04, 0.09), [])],
              [("X2", (0.20, 0.20), [(0.42, 0.23, 1), (0.70, 0.22, 2), (0.78, 0.23, 3)])],
              to=[(0, 0), (1, 3), (BASKET, 4)], free=True),
    ]


def pnr_reads() -> list[Drill]:
    """The reads off a ball screen that a coach teaches after the basic roll."""
    return [
        # A drop big; the third man back-screens him as the roll starts,
        # then pops to the arc for the open three.
        _play("bb_pnr_spain", "attacking",
              _n("Spain pick-and-roll", "西班牙挡拆", "西班牙擋拆", "スペインピック＆ロール",
                 "스페인 픽앤롤", "Pick and roll Spain", "Spain pick-and-roll",
                 "Spain pick and roll", "Spain pick and roll", "สเปนพิคแอนด์โรล",
                 "Pick and roll kiểu Tây Ban Nha"),
              _n("As the big rolls, a third man sets a back screen on the big's defender, then pops straight out to the arc. The roll is free to the rim and the screener is free for three — the defence can take one of them, not both.",
                 "内线下顺的同时，第三个人给内线的防守人做背掩护，然后立刻外弹到三分线外。下顺的人直通篮下，背掩护的人三分空位——防守只能顾一个。",
                 "內線下順的同時，第三個人給內線的防守人做背掩護，然後立刻外彈到三分線外。下順的人直通籃下，背掩護的人三分空位——防守只能顧一個。",
                 "ビッグがロールする瞬間、3人目がビッグのマークにバックスクリーンをかけ、すぐアークの外へポップ。ロールはリングへフリー、スクリナーは3Pでフリー。守備はどちらか一方しか取れない。",
                 "빅맨이 롤하는 순간 세 번째 선수가 빅맨 수비에게 백스크린을 걸고 곧장 아크 밖으로 팝. 롤러는 림까지 열리고 스크리너는 3점이 열린다 — 수비는 둘 중 하나만 막을 수 있다.",
                 "Mientras el pívot continúa, un tercero pone un bloqueo por la espalda a su defensor y abre de inmediato al triple. El que continúa llega libre al aro y el bloqueador queda libre para tirar: la defensa solo puede con uno.",
                 "Pendant que l'intérieur plonge, un troisième joueur pose un écran dans le dos de son défenseur puis ressort aussitôt derrière l'arc. Le rouleur file seul au cercle, le poseur est seul à trois points : la défense ne peut en prendre qu'un.",
                 "Saat big man roll, pemain ketiga memasang back screen pada penjaganya lalu langsung keluar ke garis tiga. Roller bebas ke ring dan pemasang screen bebas untuk tiga angka — bertahan hanya bisa menutup satu.",
                 "Semasa big man roll, pemain ketiga memasang skrin belakang pada penjaganya lalu terus keluar ke garisan tiga mata. Penggolek bebas ke jaring dan pemasang skrin bebas untuk tiga mata.",
                 "ตอนบิ๊กแมนโรล คนที่สามตั้งสกรีนหลังใส่คนประกบบิ๊กแมน แล้วป๊อปออกนอกเส้นสามแต้มทันที คนโรลโล่งถึงห่วง คนสกรีนโล่งยิงสาม กองหลังเลือกได้แค่คนเดียว",
                 "Khi trung phong cắt vào, người thứ ba chắn sau lưng hậu vệ của anh ta rồi bật ngay ra ngoài vạch ba điểm. Người cắt vào trống tới rổ, người chắn trống để ném ba — phòng ngự chỉ lo được một."),
              [("1", (0.50, 0.42), [(0.70, 0.30, 1)]),
               ("5", (0.63, 0.21), [(0.58, 0.35, 0), (0.52, 0.10, 2)]),
               ("2", (0.40, 0.22), [(0.58, 0.20, 1), (0.44, 0.34, 2)]),
               ("3", (0.04, 0.09), []),
               ("4", (0.96, 0.09), [])],
              [("X1", (0.50, 0.36), [(0.63, 0.33, 1)]),
               ("X5", (0.62, 0.27), [(0.60, 0.27, 0), (0.60, 0.24, 2)]),
               ("X2", (0.42, 0.17), [(0.52, 0.17, 1), (0.50, 0.13, 2), (0.46, 0.27, 3)])],
              to=[(0, 1), (2, 3), (BASKET, 4)], free=True, level="advanced"),
        # Both defenders jump out to trap; the screener slips to the rim
        # before the contact and the weak side has to come across.
        _play("bb_pnr_slip", "attacking",
              _n("Pick-and-roll: the slip", "挡拆：假掩护真下顺", "擋拆：假掩護真下順",
                 "ピック＆ロール：スリップ", "픽앤롤: 슬립", "Bloqueo directo: el slip",
                 "Pick-and-roll : le slip", "Pick and roll: slip", "Pick and roll: slip",
                 "พิคแอนด์โรล: สลิป", "Pick and roll: chắn giả cắt sớm"),
              _n("When both defenders jump out to trap the screen, the screener leaves before the contact and dives. Slip against the hedge or the switch, never against drop coverage — there the roll is open anyway.",
                 "两个防守人都扑出来包夹掩护时，掩护人不等接触就提前下顺。对上延误或换防才用假掩护，对上退防不要——那时正常下顺本来就空。",
                 "兩個防守人都撲出來包夾掩護時，掩護人不等接觸就提前下順。對上延誤或換防才用假掩護，對上退防不要——那時正常下順本來就空。",
                 "2人の守備がスクリーンにトラップで飛び出したら、スクリナーは接触前に抜けてダイブ。スリップはヘッジやスイッチに対して使い、ドロップには使わない——その時は普通のロールが空いている。",
                 "두 수비가 스크린에 트랩하러 튀어나오면 스크리너는 접촉 전에 빠져서 다이브한다. 헤지나 스위치에 쓰고 드롭에는 쓰지 마라 — 그때는 일반 롤이 이미 열려 있다.",
                 "Cuando los dos defensores saltan a atrapar el bloqueo, el bloqueador se va antes del contacto y corta al aro. El slip, contra el hedge o el cambio; nunca contra el drop: ahí la continuación ya está libre.",
                 "Quand les deux défenseurs sortent piéger l'écran, le poseur part avant le contact et plonge. Le slip contre le hedge ou le changement, jamais contre le drop — là, la plongée est déjà libre.",
                 "Saat dua bek melompat menjebak screen, pemasang screen pergi sebelum kontak dan menukik. Slip melawan hedge atau switch, jangan melawan drop — di situ roll sudah terbuka.",
                 "Apabila dua pemain bertahan melompat memerangkap skrin, pemasang skrin pergi sebelum sentuhan dan menjunam. Slip menentang hedge atau tukar, jangan menentang drop.",
                 "เมื่อกองหลังสองคนพุ่งออกมาดักสกรีน คนสกรีนชิ่งก่อนปะทะแล้วดิ่งเข้าห่วง ใช้สลิปกับการเฮดจ์หรือสวิตช์ อย่าใช้กับดรอป เพราะโรลปกติก็โล่งอยู่แล้ว",
                 "Khi cả hai hậu vệ lao ra bẫy màn chắn, người chắn rời đi trước khi tiếp xúc và lao vào rổ. Dùng slip với hedge hoặc đổi người, đừng dùng với drop — khi đó cắt vào bình thường đã trống."),
              [("1", (0.50, 0.42), []),
               ("5", (0.63, 0.21), [(0.58, 0.34, 0), (0.54, 0.10, 1)]),
               ("2", (0.13, 0.26), []),
               ("3", (0.04, 0.09), []),
               ("4", (0.96, 0.09), [])],
              [("X1", (0.50, 0.36), [(0.46, 0.37, 1)]),
               ("X5", (0.62, 0.27), [(0.64, 0.36, 0), (0.56, 0.40, 1)]),
               ("X4", (0.86, 0.12), [(0.64, 0.10, 2)])],
              to=[(1, 2), (BASKET, 3)], free=True),
        # A side screen to send the ball middle; the handler's man jumps to
        # it, so the handler goes baseline and the screener dives.
        _play("bb_pnr_reject", "attacking",
              _n("Pick-and-roll: rejecting the screen", "挡拆：拒绝掩护反向突破",
                 "擋拆：拒絕掩護反向突破", "ピック＆ロール：リジェクト", "픽앤롤: 스크린 거부",
                 "Bloqueo directo: rechazar el bloqueo", "Pick-and-roll : refuser l'écran",
                 "Pick and roll: menolak screen", "Pick and roll: menolak skrin",
                 "พิคแอนด์โรล: ปฏิเสธสกรีน", "Pick and roll: từ chối màn chắn"),
              _n("Reject the screen only when the handler's defender jumps to the screen side to beat him there — he has given you the other way. The screener reads the reject and dives at once, and the corner lifts to clear the baseline.",
                 "只有当持球人的防守人抢先跳到掩护那一侧时才拒绝掩护——他把另一边让给你了。掩护人看到拒绝立刻下顺，底角的人上提把底线让出来。",
                 "只有當持球人的防守人搶先跳到掩護那一側時才拒絕掩護——他把另一邊讓給你了。掩護人看到拒絕立刻下順，底角的人上提把底線讓出來。",
                 "リジェクトは、ハンドラーのマークがスクリーン側へ先回りした時だけ。逆側を空けてくれたのだ。スクリナーはリジェクトを読んで即ダイブ、コーナーはリフトしてベースラインを空ける。",
                 "핸들러의 수비가 스크린 쪽으로 먼저 뛰어 막을 때만 거부하라 — 그가 반대쪽을 내준 것이다. 스크리너는 거부를 읽고 즉시 다이브, 코너는 위로 올라가 베이스라인을 비운다.",
                 "Rechaza el bloqueo solo cuando el defensor del base salta al lado del bloqueo para adelantarse: te ha regalado el otro lado. El bloqueador lo lee y corta al aro, y el de la esquina sube para despejar la línea de fondo.",
                 "Refuse l'écran seulement quand le défenseur du porteur saute côté écran pour le devancer — il t'offre l'autre côté. Le poseur lit le refus et plonge aussitôt, et le corner remonte pour libérer la ligne de fond.",
                 "Tolak screen hanya saat bek pengatur bola melompat ke sisi screen lebih dulu — dia memberimu sisi lain. Pemasang screen membaca penolakan dan langsung menukik, pemain sudut naik membuka baseline.",
                 "Tolak skrin hanya apabila pemain bertahan pengendali bola melompat ke sisi skrin dahulu — dia memberi anda sisi lain. Pemasang skrin terus menjunam, pemain penjuru naik membuka garisan belakang.",
                 "ปฏิเสธสกรีนเฉพาะตอนที่คนประกบคนเลี้ยงกระโดดไปดักฝั่งสกรีนก่อน เขายกอีกฝั่งให้คุณแล้ว คนสกรีนอ่านออกก็ดิ่งเข้าห่วงทันที คนมุมขยับขึ้นเปิดเส้นหลัง",
                 "Chỉ từ chối màn chắn khi hậu vệ của người cầm bóng nhảy trước sang phía màn chắn — anh ta đã nhường phía kia cho bạn. Người chắn đọc được thì lao vào rổ ngay, người ở góc dâng lên mở đường biên ngang."),
              [("1", (0.72, 0.33), [(0.80, 0.12, 1)]),
               ("5", (0.63, 0.21), [(0.62, 0.31, 0), (0.46, 0.10, 1)]),
               ("2", (0.30, 0.34), []),
               ("3", (0.04, 0.09), []),
               ("4", (0.96, 0.09), [(0.90, 0.27, 0)])],
              [("X1", (0.70, 0.27), [(0.66, 0.30, 0), (0.76, 0.18, 1)]),
               ("X5", (0.62, 0.14), [(0.62, 0.25, 0), (0.66, 0.16, 1), (0.74, 0.10, 2)])],
              to=[(0, 1), (1, 2), (BASKET, 3)]),
        # The weak-side corner defender drops to tag the roller; the handler
        # skips it over the top to the corner he left.
        _play("bb_pnr_skip", "attacking",
              _n("Pick-and-roll: the skip to the corner", "挡拆：转移底角", "擋拆：轉移底角",
                 "ピック＆ロール：コーナーへのスキップ", "픽앤롤: 코너 스킵 패스",
                 "Bloqueo directo: el pase a la esquina", "Pick-and-roll : la passe vers le corner",
                 "Pick and roll: umpan silang ke sudut", "Pick and roll: hantaran silang ke penjuru",
                 "พิคแอนด์โรล: จ่ายข้ามไปมุม", "Pick and roll: chuyền vượt sân ra góc"),
              _n("When the weak-side corner defender drops to tag the roller, the corner is open. Throw it over the top on the tag, not after it — a one-handed skip from the hip arrives before the closeout does.",
                 "弱侧底角的防守人下来卡顺下的人，底角就空了。他一卡就传，别等——单手从腰侧甩出的转移球，比他回扑到得早。",
                 "弱側底角的防守人下來卡順下的人，底角就空了。他一卡就傳，別等——單手從腰側甩出的轉移球，比他回撲到得早。",
                 "弱サイドのコーナーディフェンスがロールマンにタグしに下りたら、コーナーが空く。タグの瞬間に頭越しへ——腰からの片手スキップはクローズアウトより先に届く。",
                 "약측 코너 수비가 롤맨을 태그하러 내려오면 코너가 열린다. 태그하는 순간 머리 위로 던져라 — 허리에서 한 손으로 던진 스킵 패스가 클로즈아웃보다 먼저 닿는다.",
                 "Cuando el defensor de la esquina débil baja a frenar al que continúa, la esquina queda libre. Pasa por encima en el momento de la ayuda, no después: un pase cruzado a una mano desde la cadera llega antes que el cierre.",
                 "Quand le défenseur du corner faible descend toucher le rouleur, le corner est libre. Passe par-dessus au moment de l'aide, pas après — une transversale à une main depuis la hanche arrive avant le close-out.",
                 "Saat bek sudut sisi lemah turun menahan roller, sudutnya terbuka. Lempar melewati atas saat dia menahan, bukan sesudahnya — umpan silang satu tangan dari pinggul tiba sebelum closeout.",
                 "Apabila pemain bertahan penjuru sisi lemah turun menahan penggolek, penjuru terbuka. Baling melepasi atas ketika dia menahan, bukan selepasnya.",
                 "เมื่อกองหลังมุมฝั่งอ่อนลงมาแตะคนโรล มุมจะโล่ง โยนข้ามหัวตอนเขาลงมา ไม่ใช่หลังจากนั้น บอลข้ามฝั่งมือเดียวจากสะโพกถึงก่อนเขาจะกลับไปปิด",
                 "Khi hậu vệ góc bên yếu lùi xuống chặn người cắt vào, góc sẽ trống. Chuyền vượt qua đầu ngay lúc anh ta chặn, đừng đợi — đường chuyền một tay từ hông tới trước khi anh ta kịp áp sát."),
              [("1", (0.50, 0.42), [(0.70, 0.29, 1)]),
               ("5", (0.63, 0.21), [(0.58, 0.35, 0), (0.52, 0.11, 2)]),
               ("4", (0.04, 0.09), []),
               ("3", (0.13, 0.27), []),
               ("2", (0.96, 0.09), [])],
              [("X1", (0.50, 0.36), [(0.64, 0.31, 1)]),
               ("X5", (0.62, 0.27), [(0.60, 0.22, 1), (0.58, 0.16, 2)]),
               ("X4", (0.14, 0.13), [(0.42, 0.12, 2), (0.18, 0.11, 3)]),
               ("X3", (0.22, 0.24), [(0.30, 0.22, 2)])],
              to=[(0, 1), (2, 3), (BASKET, 4)]),
    ]


def inbound_plays() -> list[Drill]:
    """Baseline and sideline plays beyond the four in INBOUNDS_SETS."""
    return [
        # In to the corner against a 2-3, then the inbounder steps in behind
        # a screen on the low man and gets it straight back.
        _play("bb_inbounds_zone", "setpiece",
              _n("Inbounds: against a zone", "发球战术：破区域联防", "發球戰術：破區域聯防",
                 "スローイン：ゾーン攻略", "인바운드: 지역 방어 공략", "Saque: contra zona",
                 "Remise en jeu : contre une zone", "Bola masuk: melawan zona",
                 "Bola masuk: menentang zon", "การส่งบอลเข้าเล่น: แก้โซน",
                 "Ném biên: phá phòng ngự khu vực"),
              _n("Against a zone the inbounder is the best shooter on the floor: nobody guards him once he steps in. Throw it to the corner, step in behind the screen on the low man, and get it straight back.",
                 "对区域联防时，发球人就是场上最好的投篮点：他一踏进场内就没人防。先传底角，再踏进场内躲到挡住底线防守人的掩护后面，球马上回传给他。",
                 "對區域聯防時，發球人就是場上最好的投籃點：他一踏進場內就沒人防。先傳底角，再踏進場內躲到擋住底線防守人的掩護後面，球馬上回傳給他。",
                 "ゾーン相手ではスローワーがコート上で一番のシューターになる。入った瞬間に誰も見ていないからだ。コーナーへ入れ、ローマンへのスクリーンの陰に踏み込み、すぐ返してもらう。",
                 "지역 방어 상대로는 인바운더가 코트 위 최고의 슈터다: 코트에 들어서면 아무도 막지 않는다. 코너로 넣고, 로우 수비에게 건 스크린 뒤로 들어가 곧바로 돌려받는다.",
                 "Contra zona, el que saca es el mejor tirador de la pista: en cuanto entra nadie lo marca. Pasa a la esquina, entra por detrás del bloqueo al defensor bajo y recíbela de vuelta al instante.",
                 "Contre une zone, le passeur est le meilleur shooteur du terrain : une fois entré, personne ne le prend. Passe au corner, entre derrière l'écran posé sur le défenseur du bas, et récupère le ballon aussitôt.",
                 "Melawan zona, pelempar adalah penembak terbaik di lapangan: begitu masuk tak ada yang menjaganya. Umpan ke sudut, masuk di belakang screen pada bek bawah, dan terima kembali segera.",
                 "Menentang zon, pembaling ialah penjaring terbaik di gelanggang: sebaik masuk tiada siapa menjaganya. Hantar ke penjuru, masuk di belakang skrin pada pemain bawah, dan terima semula segera.",
                 "เจอโซน คนส่งบอลคือมือยิงที่ดีที่สุดในสนาม เพราะพอก้าวเข้ามาก็ไม่มีใครประกบ ส่งไปมุม ก้าวเข้ามาหลังสกรีนที่ขวางกองหลังตัวล่าง แล้วรับบอลคืนทันที",
                 "Trước phòng ngự khu vực, người ném biên là xạ thủ tốt nhất trên sân: bước vào là không ai kèm. Chuyền ra góc, bước vào sau màn chắn đặt lên hậu vệ dưới và nhận lại bóng ngay."),
              [("1", (0.70, -0.03), [(0.76, 0.05, 1)]),
               ("2", (0.86, 0.24), [(0.95, 0.15, 0)]),
               ("5", (0.60, 0.22), [(0.70, 0.12, 1)]),
               ("3", (0.13, 0.26), []),
               ("4", (0.40, 0.35), [])],
              [("X1", (0.36, 0.25), []),
               ("X2", (0.64, 0.25), [(0.74, 0.22, 0)]),
               ("X3", (0.26, 0.12), []),
               ("X5", (0.50, 0.09), [(0.64, 0.09, 1)]),
               ("X4", (0.76, 0.12), [(0.88, 0.17, 0), (0.82, 0.09, 2)])],
              to=[(1, 0), (0, 2), (BASKET, 3)], free=True, off=True, minutes=8),
        # From the sideline: the target is denied at the top, so the big
        # back-screens his defender and the lob goes over the top.
        _play("bb_inbounds_lob", "setpiece",
              _n("Inbounds: the back-screen lob", "发球战术：背掩护空接", "發球戰術：背掩護空接",
                 "スローイン：バックスクリーンからのロブ", "인바운드: 백스크린 롭",
                 "Saque: el alley-oop tras bloqueo ciego", "Remise en jeu : le lob sur écran dans le dos",
                 "Bola masuk: lob dari back screen", "Bola masuk: lob dari skrin belakang",
                 "การส่งบอลเข้าเล่น: ลอยจากสกรีนหลัง", "Ném biên: chuyền bổng sau màn chắn lưng"),
              _n("A defender denying the pass is facing the ball with his back to the rim — that is the back the screen hits. The lob is thrown to the front of the rim, high enough that only your man can reach it; the screener pops as the safety.",
                 "绕前防接球的防守人面朝球、背对篮筐——背掩护挡的就是那个背。空接球要传到篮筐前沿，高到只有自己人够得着；掩护人外弹做安全出球点。",
                 "繞前防接球的防守人面朝球、背對籃框——背掩護擋的就是那個背。空接球要傳到籃框前沿，高到只有自己人夠得著；掩護人外彈做安全出球點。",
                 "パスを止めようとするディフェンスはボールを向き、リングに背を向けている。スクリーンはその背中に当てる。ロブはリングの手前へ、味方しか届かない高さで。スクリナーはセーフティとしてポップ。",
                 "패스를 막는 수비는 공을 보고 림을 등지고 있다 — 스크린은 그 등을 친다. 롭은 림 앞쪽으로, 우리 편만 닿을 높이로 던진다. 스크리너는 안전 옵션으로 팝.",
                 "El defensor que niega el pase mira al balón de espaldas al aro: esa espalda es la que golpea el bloqueo. El pase alto va a la parte delantera del aro, tan alto que solo llegue tu compañero; el bloqueador abre como seguro.",
                 "Le défenseur qui refuse la passe fait face au ballon, dos au cercle — c'est ce dos que l'écran frappe. Le lob vise l'avant du cercle, assez haut pour que seul ton coéquipier l'atteigne ; le poseur ressort en sécurité.",
                 "Bek yang menolak umpan menghadap bola dan membelakangi ring — punggung itulah yang dihantam screen. Lob dilempar ke depan ring, cukup tinggi agar hanya rekanmu yang meraihnya; pemasang screen keluar sebagai opsi aman.",
                 "Pemain bertahan yang menafikan hantaran menghadap bola dan membelakangi jaring — belakang itulah yang dikenai skrin. Lob dibaling ke depan jaring, cukup tinggi untuk rakan sahaja; pemasang skrin keluar sebagai pilihan selamat.",
                 "กองหลังที่ปิดทางส่งจะหันหน้าหาบอลและหันหลังให้ห่วง หลังนั้นแหละที่สกรีนชน ลอยบอลไปด้านหน้าห่วง สูงพอให้แค่เพื่อนเอื้อมถึง คนสกรีนป๊อปออกเป็นทางสำรอง",
                 "Hậu vệ chặn đường chuyền thì mặt hướng bóng, lưng quay về rổ — màn chắn nhắm vào cái lưng đó. Bóng bổng chuyền tới phía trước vành rổ, đủ cao để chỉ đồng đội với tới; người chắn bật ra làm phương án an toàn."),
              [("1", (1.03, 0.30), []),
               ("2", (0.52, 0.36), [(0.56, 0.08, 1)]),
               ("5", (0.63, 0.21), [(0.60, 0.27, 0), (0.78, 0.36, 2)]),
               ("3", (0.13, 0.26), []),
               ("4", (0.04, 0.09), [])],
              [("X2", (0.60, 0.35), [(0.61, 0.30, 1), (0.58, 0.18, 2)])],
              to=[(1, 2), (BASKET, 3)], off=True, minutes=8),
        # Late clock from the sideline: the shooter runs up from the block
        # off two screens a stride apart for a catch-and-shoot three.
        _play("bb_inbounds_stagger", "setpiece",
              _n("Inbounds: the stagger for a three", "发球战术：交错掩护投三分",
                 "發球戰術：交錯掩護投三分", "スローイン：スタッガーから3P", "인바운드: 스태거 3점",
                 "Saque: bloqueos escalonados para el triple",
                 "Remise en jeu : écrans décalés pour un tir à trois points",
                 "Bola masuk: stagger untuk tiga angka", "Bola masuk: stagger untuk tiga mata",
                 "การส่งบอลเข้าเล่น: สแตกเกอร์ยิงสาม", "Ném biên: hai màn chắn so le để ném ba"),
              _n("The late-clock three: the shooter starts low, sells the baseline, then runs off two screens set a stride apart. The second screener holds until the defender arrives — he is the one who frees the shot.",
                 "时间不多时的三分战术：投手从低位出发，先假装往底线跑，再连续借两个间隔一步的掩护上来。第二个掩护人要顶到防守人撞上来——真正放出投篮的是他。",
                 "時間不多時的三分戰術：投手從低位出發，先假裝往底線跑，再連續借兩個間隔一步的掩護上來。第二個掩護人要頂到防守人撞上來——真正放出投籃的是他。",
                 "残り時間わずかの3P：シューターはロウから始め、ベースラインへ行くと見せて、1歩ずつ離れた2枚のスクリーンを使って上がる。2枚目のスクリナーはマークが来るまで動かない。シュートを生むのは彼だ。",
                 "시간이 없을 때의 3점: 슈터는 로우에서 출발해 베이스라인으로 가는 척하고, 한 걸음 간격의 스크린 두 개를 타고 올라온다. 두 번째 스크리너는 수비가 올 때까지 버틴다 — 슛을 만드는 건 그다.",
                 "El triple de final de posesión: el tirador sale de abajo, amaga hacia la línea de fondo y sube por dos bloqueos separados un paso. El segundo bloqueador aguanta hasta que llega el defensor: es él quien libera el tiro.",
                 "Le tir à trois points de fin de possession : le shooteur part du bas, feinte la ligne de fond, puis remonte sur deux écrans espacés d'un pas. Le second poseur tient jusqu'à l'arrivée du défenseur — c'est lui qui libère le tir.",
                 "Tembakan tiga di akhir waktu: penembak mulai di bawah, pura-pura ke baseline, lalu naik lewat dua screen berjarak satu langkah. Pemasang screen kedua bertahan sampai bek tiba — dialah yang membebaskan tembakan.",
                 "Jaringan tiga mata di hujung masa: penjaring bermula di bawah, berpura-pura ke garisan belakang, kemudian naik melalui dua skrin berjarak satu langkah. Pemasang skrin kedua bertahan sehingga pemain bertahan tiba.",
                 "สามแต้มช่วงเวลาใกล้หมด คนยิงเริ่มจากด้านล่าง หลอกว่าจะไปเส้นหลัง แล้ววิ่งขึ้นผ่านสกรีนสองตัวที่ห่างกันหนึ่งก้าว คนสกรีนตัวที่สองยืนจนกองหลังมาชน เขาคือคนที่เปิดช่องยิง",
                 "Cú ném ba khi sắp hết giờ: xạ thủ xuất phát dưới thấp, giả chạy ra biên ngang rồi đi lên qua hai màn chắn cách nhau một bước. Người chắn thứ hai giữ đến khi hậu vệ tới — chính anh ta tạo ra cú ném."),
              [("1", (1.03, 0.33), []),
               ("2", (0.31, 0.11), [(0.24, 0.07, 0), (0.62, 0.35, 1)]),
               ("4", (0.38, 0.20), []),
               ("5", (0.50, 0.29), []),
               ("3", (0.96, 0.09), [])],
              [("X2", (0.34, 0.15), [(0.28, 0.11, 0), (0.44, 0.23, 1), (0.58, 0.30, 2)])],
              to=[(1, 2), (BASKET, 3)], off=True, minutes=8, level="advanced"),
    ]


PRESS_NAME = _n("Full-court press", "全场紧逼", "全場緊逼", "オールコートプレス",
                "올코트 프레스", "Presión a toda pista", "Presse tout terrain",
                "Press seluruh lapangan", "Tekanan seluruh gelanggang",
                "เพรสเต็มสนาม", "Pressing toàn sân")
PRESS_NOTE = _n(
    "Let the inbound go to the corner, then trap it on the sideline: the sideline is a third defender. The two men off the trap read the passer's eyes and steal the pass back to the middle — a trap without interceptors is just two men fouling.",
    "让发球进到边角，然后在边线上包夹：边线就是第三个防守人。不参与包夹的人盯着传球人的眼睛，抢断回传中路的那一球——没人抢断的包夹，只是两个人在犯规。",
    "讓發球進到邊角，然後在邊線上包夾：邊線就是第三個防守人。不參與包夾的人盯著傳球人的眼睛，搶斷回傳中路的那一球——沒人搶斷的包夾，只是兩個人在犯規。",
    "スローインはコーナーへ入れさせ、サイドラインでトラップ。サイドラインは3人目の守備だ。トラップに入らない2人はパサーの目を読み、中央へのパスを奪う。インターセプトのいないトラップはファウルするだけの2人だ。",
    "인바운드는 코너로 들어가게 두고 사이드라인에서 트랩하라: 사이드라인이 세 번째 수비수다. 트랩에 안 들어간 둘은 패서의 눈을 읽고 가운데로 가는 패스를 끊는다 — 가로챌 사람이 없는 트랩은 파울하는 두 사람일 뿐이다.",
    "Deja que el saque vaya a la esquina y atrápalo en la banda: la banda es un tercer defensor. Los que no están en el 2c1 leen los ojos del pasador y roban el pase al centro; un trap sin interceptores son dos jugadores haciendo falta.",
    "Laisse la remise aller dans le coin, puis piège sur la ligne de touche : la ligne est un troisième défenseur. Ceux qui ne piègent pas lisent les yeux du passeur et volent la passe vers le centre — un piège sans intercepteurs, c'est deux joueurs qui font faute.",
    "Biarkan bola masuk ke sudut, lalu jebak di garis samping: garis samping adalah bek ketiga. Dua yang tidak menjebak membaca mata pengumpan dan mencuri umpan ke tengah — jebakan tanpa pencuri hanyalah dua orang yang melanggar.",
    "Biarkan bola masuk ke penjuru, kemudian perangkap di garisan tepi: garisan tepi ialah pemain bertahan ketiga. Dua yang tidak memerangkap membaca mata penghantar dan merampas hantaran ke tengah.",
    "ปล่อยให้บอลเข้ามุม แล้วดักที่เส้นข้าง เส้นข้างคือกองหลังคนที่สาม สองคนที่ไม่ได้ดักอ่านสายตาคนส่งแล้วตัดบอลที่ส่งกลับเข้ากลาง การดักที่ไม่มีคนตัดบอลก็แค่สองคนทำฟาวล์",
    "Để bóng ném biên vào góc rồi bẫy ở biên dọc: đường biên là hậu vệ thứ ba. Hai người không tham gia bẫy đọc mắt người chuyền và cướp đường chuyền vào giữa — bẫy mà không ai cắt bóng chỉ là hai người phạm lỗi.")


def press_plays() -> list[Drill]:
    """Pressing the length of the floor, and breaking a press.

    Full court: the attack still goes up the board, so its own half — where
    the press is played — is the bottom one, and the inbounder stands just
    behind the bottom baseline.
    """
    return [
        _play("bb_press_two_two_one", "defending",
              suffixed(PRESS_NAME, "2-2-1"), PRESS_NOTE,
              [("5", (0.50, 1.03), []),
               ("1", (0.36, 0.80), [(0.18, 0.88, 0), (0.12, 0.72, 1)]),
               ("2", (0.64, 0.82), [(0.50, 0.70, 1)]),
               ("3", (0.30, 0.58), []),
               ("4", (0.72, 0.56), [])],
              [("X1", (0.38, 0.86), [(0.28, 0.88, 0), (0.18, 0.80, 1)]),
               ("X2", (0.62, 0.86), [(0.50, 0.82, 0), (0.44, 0.76, 1), (0.34, 0.73, 2)]),
               ("X3", (0.28, 0.72), [(0.14, 0.65, 1)]),
               ("X4", (0.72, 0.70), [(0.44, 0.60, 1)]),
               ("X5", (0.50, 0.45), [(0.36, 0.44, 1)])],
              to=[(1, 0), (1, 1), ("a1", 2)], free=True, off=True),
        _play("bb_press_diamond", "defending",
              suffixed(PRESS_NAME, "1-2-1-1"), PRESS_NOTE,
              [("5", (0.50, 1.03), []),
               ("1", (0.40, 0.84), [(0.18, 0.90, 0)]),
               ("2", (0.64, 0.84), [(0.56, 0.74, 1)]),
               ("3", (0.16, 0.62), []),
               ("4", (0.80, 0.60), [])],
              [("X1", (0.50, 0.96), [(0.27, 0.95, 1)]),
               ("X2", (0.28, 0.80), [(0.18, 0.82, 1)]),
               ("X3", (0.72, 0.80), [(0.48, 0.76, 1)]),
               ("X4", (0.50, 0.64), [(0.24, 0.66, 1), (0.17, 0.70, 2)]),
               ("X5", (0.50, 0.42), [(0.38, 0.42, 1)])],
              to=[(1, 0), ("a3", 2)], off=True, level="advanced", usage=1),
        # Four across the free-throw line extended; the inside two go to the
        # ball and deep middle, the outside two up the sidelines.
        _play("bb_press_break_four_across", "setpiece",
              _n("Press break: four across", "破全场紧逼：一字排开", "破全場緊逼：一字排開",
                 "プレスブレイク：4人横並び", "프레스 브레이크: 4명 일렬",
                 "Romper la presión: cuatro en línea", "Casser la pression : quatre en ligne",
                 "Membongkar press: empat sejajar", "Memecah tekanan: empat sebaris",
                 "แก้เพรส: สี่คนเรียงหน้ากระดาน", "Phá pressing: bốn người hàng ngang"),
              _n("Four across the free-throw line extended, then all four go at once: the inside two to the ball and deep middle, the outside two up the sidelines. The press cannot cover four directions; the catch is made facing up the floor.",
                 "四人在罚球线延长线上一字排开，然后同时启动：里面两人一个迎球、一个直插中路深处，外面两人沿边线往前跑。紧逼盖不住四个方向；接球时要面向前场。",
                 "四人在罰球線延長線上一字排開，然後同時啟動：裡面兩人一個迎球、一個直插中路深處，外面兩人沿邊線往前跑。緊逼蓋不住四個方向；接球時要面向前場。",
                 "フリースローラインの延長に4人が横並び、そして同時に動く。内側の2人はボールへと中央の奥へ、外側の2人はサイドラインを上がる。プレスは4方向を守れない。キャッチは前を向いて。",
                 "자유투 라인 연장선에 네 명이 일렬로 섰다가 동시에 움직인다: 안쪽 둘은 공 쪽과 중앙 깊숙이, 바깥 둘은 사이드라인을 따라 올라간다. 프레스는 네 방향을 다 막지 못한다. 받을 때는 앞을 보고.",
                 "Cuatro en línea a la altura del tiro libre y los cuatro salen a la vez: los dos de dentro, uno al balón y otro al centro profundo; los dos de fuera, por las bandas. La presión no cubre cuatro direcciones; recibe mirando hacia delante.",
                 "Quatre alignés à hauteur de la ligne des lancers francs, puis tous partent ensemble : les deux du milieu vers le ballon et au centre en profondeur, les deux extérieurs le long des lignes. La presse ne couvre pas quatre directions ; réceptionne face au jeu.",
                 "Empat sejajar di perpanjangan garis lemparan bebas, lalu keempatnya bergerak bersamaan: dua di dalam ke bola dan ke tengah dalam, dua di luar naik menyusur garis samping. Press tak bisa menutup empat arah; tangkap sambil menghadap ke depan.",
                 "Empat sebaris di lanjutan garisan balingan percuma, kemudian keempat-empatnya bergerak serentak: dua di dalam ke bola dan ke tengah dalam, dua di luar naik menyusur garisan tepi. Tangkap sambil menghadap ke hadapan.",
                 "สี่คนเรียงหน้ากระดานแนวเส้นโทษ แล้วออกพร้อมกัน สองคนในหนึ่งคนเข้าหาบอลอีกคนพุ่งลึกตรงกลาง สองคนนอกวิ่งเลียบเส้นข้าง เพรสปิดสี่ทิศไม่ได้ รับบอลแล้วหันหน้าไปข้างหน้า",
                 "Bốn người đứng hàng ngang ngang vạch ném phạt rồi cùng xuất phát: hai người trong, một đón bóng một lao sâu vào giữa; hai người ngoài chạy dọc biên. Pressing không thể che bốn hướng; bắt bóng trong tư thế quay mặt lên sân."),
              [("5", (0.50, 1.03), [(0.56, 0.91, 1)]),
               ("1", (0.38, 0.80), [(0.30, 0.90, 0)]),
               ("4", (0.62, 0.80), [(0.50, 0.58, 0)]),
               ("2", (0.12, 0.80), [(0.10, 0.58, 0), (0.12, 0.36, 2)]),
               ("3", (0.88, 0.80), [(0.90, 0.62, 0), (0.88, 0.38, 2)])],
              [("X1", (0.36, 0.87), [(0.30, 0.84, 0), (0.24, 0.88, 1)]),
               ("X2", (0.64, 0.87), [(0.44, 0.88, 1)]),
               ("X3", (0.28, 0.70), [(0.32, 0.80, 1)]),
               ("X4", (0.72, 0.70), [(0.58, 0.62, 1)]),
               ("X5", (0.50, 0.45), [(0.40, 0.40, 2)])],
              to=[(1, 0), (2, 1), (3, 2)], free=True, off=True),
    ]


ZOFF_NAME = _n("Zone offence", "破区域联防", "破區域聯防", "ゾーンオフェンス",
               "지역 방어 공략", "Ataque a la zona", "Attaque de zone",
               "Menyerang zona", "Menyerang zon", "บุกโซน", "Tấn công khu vực")
# The 2-3 the zone attacks below play against, spot by spot.
ZONE_23 = [("X1", (0.36, 0.25)), ("X2", (0.64, 0.25)), ("X3", (0.25, 0.12)),
           ("X4", (0.75, 0.12)), ("X5", (0.50, 0.09))]


def zone_offence() -> list[Drill]:
    def z(moves):
        return [(lab, st, moves.get(lab, [])) for lab, st in ZONE_23]
    return [
        # A flash to the free-throw line draws the middle of the 2-3 up;
        # the low post seals behind him for the high-low pass.
        _play("bb_zone_attack_high_low", "attacking",
              suffixed(ZOFF_NAME, _n("high-low", "高低位配合", "高低位配合", "ハイロー",
                                     "하이로우", "alto-bajo", "high-low", "high-low",
                                     "high-low", "ไฮโลว์", "cao - thấp")),
              _n("Put a man in the hole at the free-throw line: the middle of a 2-3 has to step up to him, and the low post seals the space he left. The high man catches facing the rim and looks low before he looks out.",
                 "派一个人站进罚球线中间的空当：2-3 联防的中锋必须上来顶他，低位就卡住他让出的位置。高位接球后面向篮筐，先看低位，再看外线。",
                 "派一個人站進罰球線中間的空當：2-3 聯防的中鋒必須上來頂他，低位就卡住他讓出的位置。高位接球後面向籃框，先看低位，再看外線。",
                 "フリースローライン中央の穴に1人置く。2-3の真ん中が上がって対応するしかなく、ローポストはその空いた場所をシールする。ハイの選手はリングを向いてキャッチし、外より先にローを見る。",
                 "자유투 라인의 빈 곳에 한 명을 세워라: 2-3의 가운데가 올라와야 하고, 로우 포스트는 그가 비운 자리를 실한다. 하이 선수는 림을 보고 받고, 밖보다 로우를 먼저 본다.",
                 "Pon a alguien en el hueco del tiro libre: el centro de la 2-3 tiene que subir a por él, y el poste bajo sella el sitio que dejó. El de arriba recibe de cara al aro y mira abajo antes que fuera.",
                 "Place un joueur dans le trou à la ligne des lancers francs : le milieu de la 2-3 doit monter sur lui, et le poste bas scelle l'espace laissé. Le joueur haut réceptionne face au panier et regarde en bas avant de regarder dehors.",
                 "Taruh satu orang di celah garis lemparan bebas: tengah zona 2-3 harus naik menjaganya, dan post bawah mengunci ruang yang ditinggalkan. Pemain atas menangkap menghadap ring dan melihat ke bawah sebelum ke luar.",
                 "Letak seorang di lubang garisan balingan percuma: tengah zon 2-3 terpaksa naik, dan tiang bawah mengunci ruang yang ditinggalkan. Pemain atas menangkap menghadap jaring dan melihat ke bawah dahulu.",
                 "ส่งคนไปยืนในช่องที่เส้นโทษ ตัวกลางของโซน 2-3 ต้องขึ้นมาประกบ แล้วโพสต์ต่ำก็ปิดตัวในที่ที่เขาทิ้งไว้ คนบนรับบอลหันหน้าเข้าห่วง มองล่างก่อนมองนอก",
                 "Đặt một người vào khoảng trống ở vạch ném phạt: người giữa của 2-3 buộc phải dâng lên, và người ở post thấp chèn vào chỗ anh ta bỏ trống. Người ở cao bắt bóng quay mặt về rổ, nhìn xuống thấp trước khi nhìn ra ngoài."),
              [("1", (0.34, 0.36), []),
               ("5", (0.30, 0.12), [(0.50, 0.24, 0)]),
               ("4", (0.70, 0.10), [(0.57, 0.07, 1)]),
               ("2", (0.87, 0.26), []),
               ("3", (0.13, 0.26), [])],
              z({"X5": [(0.50, 0.16, 1)], "X4": [(0.66, 0.10, 2)]}),
              to=[(1, 1), (2, 2), (BASKET, 3)], free=True),
        # The short corner behind the low man of the 2-3; when he steps out
        # to it, the high post dives behind him.
        _play("bb_zone_attack_short_corner", "attacking",
              suffixed(ZOFF_NAME, _n("the short corner", "底线短角", "底線短角",
                                     "ショートコーナー", "숏 코너", "la esquina corta",
                                     "le short corner", "short corner", "short corner",
                                     "ชอร์ตคอร์เนอร์", "góc ngắn")),
              _n("The short corner sits behind the 2-3's low man, where nobody in the zone faces. When the ball reaches him the low man must step out, and the high post dives into the space behind him.",
                 "底线短角在 2-3 联防底线人的身后，联防里没人面对那里。球一到短角，底线人就得出来，高位的人立刻下潜到他身后的空当。",
                 "底線短角在 2-3 聯防底線人的身後，聯防裡沒人面對那裡。球一到短角，底線人就得出來，高位的人立刻下潛到他身後的空當。",
                 "ショートコーナーは2-3のローマンの背後、ゾーンの誰も向いていない場所。ボールが入ればローマンは出るしかなく、ハイポストはその背後のスペースへダイブする。",
                 "숏 코너는 2-3 로우 수비의 등 뒤, 지역 방어 누구도 보지 않는 곳이다. 공이 들어가면 로우 수비가 나와야 하고, 하이 포스트는 그 뒤 공간으로 다이브한다.",
                 "La esquina corta está detrás del defensor bajo de la 2-3, donde nadie de la zona mira. Cuando el balón llega allí, el bajo tiene que salir, y el poste alto se lanza al espacio que deja atrás.",
                 "Le short corner est dans le dos du défenseur bas de la 2-3, là où personne ne regarde. Quand le ballon y arrive, il doit sortir, et le poste haut plonge dans l'espace derrière lui.",
                 "Short corner ada di belakang bek bawah zona 2-3, tempat yang tak dihadapi siapa pun. Saat bola tiba di sana, bek bawah harus keluar, dan high post menukik ke ruang di belakangnya.",
                 "Short corner berada di belakang pemain bawah zon 2-3, tempat tiada siapa menghadap. Apabila bola tiba, pemain bawah terpaksa keluar, dan tiang tinggi menjunam ke ruang di belakangnya.",
                 "ชอร์ตคอร์เนอร์อยู่หลังตัวล่างของโซน 2-3 ที่ไม่มีใครในโซนหันหน้าไปดู พอบอลถึงตรงนั้น ตัวล่างต้องออกมา แล้วไฮโพสต์ก็ดิ่งเข้าที่ว่างด้านหลังเขา",
                 "Góc ngắn nằm sau lưng người thấp của 2-3, nơi không ai trong khu vực quay mặt về. Bóng tới đó thì người thấp phải bước ra, và người ở high post lao vào khoảng trống sau lưng anh ta."),
              [("1", (0.50, 0.37), []),
               ("3", (0.13, 0.26), []),
               ("5", (0.30, 0.12), [(0.20, 0.06, 0)]),
               ("4", (0.50, 0.23), [(0.40, 0.08, 1)]),
               ("2", (0.87, 0.26), [])],
              [("X1", (0.36, 0.25), [(0.20, 0.22, 0)]),
               ("X2", (0.64, 0.25), [(0.48, 0.27, 0)]),
               ("X3", (0.28, 0.14), [(0.22, 0.10, 1)]),
               ("X4", (0.75, 0.12), []),
               ("X5", (0.50, 0.09), [(0.44, 0.11, 2)])],
              to=[(1, 0), (2, 1), (3, 2), (BASKET, 3)]),
        # Two guards split the top man of the 1-3-1; every swing to a corner
        # makes the one baseline defender run the width of the floor.
        _play("bb_zone_attack_one_three_one", "attacking",
              suffixed(ZOFF_NAME, _n("attacking the 1-3-1", "打 1-3-1", "打 1-3-1",
                                     "1-3-1攻略", "1-3-1 공략", "contra la 1-3-1",
                                     "contre la 1-3-1", "melawan 1-3-1",
                                     "menentang 1-3-1", "แก้ 1-3-1", "phá 1-3-1")),
              _n("A 1-3-1 has one man for the whole baseline. Split the top with two guards, put shooters in both corners, and every swing to a corner makes that one man run the width of the floor — the pass behind him is to the man ducking in.",
                 "1-3-1 整条底线只有一个人。两个后卫把顶端一分为二，两个底角都放投手，每转移一次到底角，那一个人就得横跑整个场宽——他身后的那一传给往里钻的人。",
                 "1-3-1 整條底線只有一個人。兩個後衛把頂端一分為二，兩個底角都放投手，每轉移一次到底角，那一個人就得橫跑整個場寬——他身後的那一傳給往裡鑽的人。",
                 "1-3-1はベースライン全体を1人で守る。2ガードでトップを割り、両コーナーにシューター。コーナーへ振るたびにその1人がコート幅を走る。背後へのパスは中へ潜り込む選手へ。",
                 "1-3-1은 베이스라인 전체를 한 명이 막는다. 두 가드로 탑을 나누고, 양 코너에 슈터를 둔다. 코너로 돌릴 때마다 그 한 명이 코트 폭을 뛰어야 한다 — 그 뒤로 가는 패스는 안으로 파고드는 선수에게.",
                 "La 1-3-1 tiene un solo hombre para toda la línea de fondo. Divide arriba con dos bases, tiradores en ambas esquinas, y cada balón a una esquina obliga a ese hombre a cruzar la pista; el pase a su espalda es para el que entra por dentro.",
                 "La 1-3-1 n'a qu'un joueur pour toute la ligne de fond. Coupe le haut avec deux meneurs, des shooteurs dans les deux corners, et chaque renversement vers un corner fait courir ce joueur sur toute la largeur — la passe dans son dos va à celui qui plonge.",
                 "Zona 1-3-1 hanya punya satu orang untuk seluruh baseline. Bagi puncak dengan dua guard, taruh penembak di kedua sudut, dan setiap bola ke sudut membuat satu orang itu berlari selebar lapangan — umpan di belakangnya untuk pemain yang menyelinap masuk.",
                 "Zon 1-3-1 hanya ada seorang untuk seluruh garisan belakang. Bahagi puncak dengan dua pengawal, letak penjaring di kedua-dua penjuru, dan setiap bola ke penjuru memaksa dia berlari selebar gelanggang.",
                 "1-3-1 มีคนเดียวคุมทั้งเส้นหลัง แยกยอดด้วยการ์ดสองคน วางมือยิงไว้ทั้งสองมุม ทุกครั้งที่บอลไปมุม คนคนนั้นต้องวิ่งทั้งความกว้างสนาม บอลที่ส่งหลังเขาคือให้คนที่มุดเข้ามา",
                 "1-3-1 chỉ có một người cho cả đường biên ngang. Chia đỉnh bằng hai hậu vệ, đặt xạ thủ ở cả hai góc, mỗi lần chuyền ra góc buộc người đó chạy hết chiều ngang sân — đường chuyền sau lưng anh ta dành cho người lách vào."),
              [("1", (0.34, 0.38), []),
               ("2", (0.66, 0.38), []),
               ("3", (0.04, 0.09), []),
               ("4", (0.96, 0.09), []),
               ("5", (0.36, 0.11), [(0.58, 0.08, 1)])],
              [("X1", (0.50, 0.32), [(0.62, 0.33, 0)]),
               ("X2", (0.24, 0.22), [(0.30, 0.20, 1)]),
               ("X3", (0.50, 0.20), [(0.62, 0.15, 1), (0.57, 0.12, 2)]),
               ("X4", (0.76, 0.22), [(0.80, 0.25, 0)]),
               ("X5", (0.50, 0.08), [(0.62, 0.09, 0), (0.88, 0.12, 1)])],
              to=[(1, 0), (3, 1), (4, 2), (BASKET, 3)]),
    ]


def zone_defence_more() -> list[Drill]:
    """More of the zone family: the same ZONE_NOTE, so they group with it."""
    return [
        _play("bb_zone_two_three_corner", "defending",
              suffixed(ZONE_NAME, _n("2-3, ball in the corner", "2-3 球到底角", "2-3 球到底角",
                                     "2-3 コーナーにボール", "2-3 코너 볼",
                                     "2-3 con balón en la esquina", "2-3, ballon dans le corner",
                                     "2-3, bola di sudut", "2-3, bola di penjuru",
                                     "2-3 บอลอยู่มุม", "2-3 khi bóng ở góc")),
              ZONE_NOTE,
              [("1", (0.50, 0.36), []), ("2", (0.12, 0.26), []),
               ("3", (0.04, 0.09), []), ("4", (0.88, 0.26), []),
               ("5", (0.80, 0.07), [])],
              [("X1", (0.36, 0.25), [(0.20, 0.22, 0), (0.25, 0.20, 1)]),
               ("X2", (0.64, 0.25), [(0.46, 0.27, 0), (0.42, 0.24, 1)]),
               ("X3", (0.25, 0.12), [(0.11, 0.12, 1)]),
               ("X5", (0.50, 0.09), [(0.33, 0.10, 1)]),
               ("X4", (0.75, 0.12), [(0.52, 0.10, 1)])],
              to=[(1, 0), (2, 1), (BASKET, 2)], free=True, usage=3),
        _play("bb_zone_one_three_one_trap", "defending",
              suffixed(ZONE_NAME, _n("1-3-1, the corner trap", "1-3-1 底角包夹", "1-3-1 底角包夾",
                                     "1-3-1 コーナートラップ", "1-3-1 코너 트랩",
                                     "1-3-1 con trap en la esquina", "1-3-1, piège dans le corner",
                                     "1-3-1, jebakan di sudut", "1-3-1, perangkap di penjuru",
                                     "1-3-1 ดักที่มุม", "1-3-1 bẫy ở góc")),
              ZONE_NOTE,
              [("1", (0.50, 0.38), []), ("2", (0.12, 0.26), []),
               ("3", (0.04, 0.09), []), ("4", (0.88, 0.26), []),
               ("5", (0.62, 0.22), [])],
              [("X1", (0.50, 0.31), [(0.36, 0.30, 0), (0.20, 0.29, 1), (0.15, 0.24, 2)]),
               ("X2", (0.24, 0.22), [(0.16, 0.24, 0), (0.06, 0.17, 1)]),
               ("X3", (0.50, 0.20), [(0.40, 0.20, 0), (0.30, 0.12, 1)]),
               ("X4", (0.76, 0.22), [(0.62, 0.16, 0), (0.50, 0.14, 1)]),
               ("X5", (0.50, 0.08), [(0.34, 0.08, 0), (0.13, 0.07, 1)])],
              to=[(1, 0), (2, 1), ("a0", 2)], level="advanced"),
        _play("bb_zone_three_two", "defending",
              suffixed(ZONE_NAME, "3-2"), ZONE_NOTE,
              [("1", (0.50, 0.38), []), ("2", (0.12, 0.26), []),
               ("3", (0.88, 0.26), []), ("4", (0.04, 0.09), []),
               ("5", (0.69, 0.11), [])],
              [("X1", (0.50, 0.30), [(0.38, 0.26, 0)]),
               ("X2", (0.24, 0.22), [(0.18, 0.24, 0), (0.22, 0.20, 1)]),
               ("X3", (0.76, 0.22), [(0.60, 0.20, 0), (0.56, 0.16, 1)]),
               ("X4", (0.34, 0.10), [(0.28, 0.10, 0), (0.12, 0.12, 1)]),
               ("X5", (0.66, 0.10), [(0.52, 0.09, 0), (0.34, 0.09, 1)])],
              to=[(1, 0), (3, 1), (BASKET, 2)]),
        _play("bb_zone_box_and_one", "defending",
              suffixed(ZONE_NAME, _n("box-and-one", "盒子加一", "盒子加一", "ボックスワン",
                                     "박스 앤 원", "caja y uno", "boîte et un", "box-and-one",
                                     "box-and-one", "บ็อกซ์แอนด์วัน", "hộp cộng một")),
              ZONE_NOTE,
              [("1", (0.50, 0.36), []), ("2", (0.04, 0.09), [(0.96, 0.09, 0)]),
               ("3", (0.88, 0.26), []), ("4", (0.12, 0.27), []),
               ("5", (0.69, 0.11), [])],
              [("X1", (0.12, 0.14), [(0.88, 0.12, 0), (0.92, 0.17, 1)]),
               ("X2", (0.36, 0.22), [(0.44, 0.22, 1), (0.24, 0.23, 2)]),
               ("X3", (0.64, 0.22), [(0.78, 0.24, 1), (0.66, 0.22, 2)]),
               ("X4", (0.34, 0.10), [(0.42, 0.10, 1), (0.32, 0.11, 2)]),
               ("X5", (0.66, 0.10), [(0.70, 0.14, 1)])],
              to=[(2, 1), (3, 2), (BASKET, 3)], level="advanced", usage=1),
    ]


MAN_NAME = _n("Man defence", "人盯人防守", "人盯人防守", "マンツーマンディフェンス",
              "맨투맨 수비", "Defensa individual", "Défense individuelle",
              "Pertahanan satu lawan satu", "Pertahanan individu",
              "การป้องกันแบบคนต่อคน", "Phòng ngự kèm người")
MAN_NOTE = _n(
    "Ball, you, man: see both on every pass and move while the ball is in the air. One pass away you deny, two passes away you help from the lane, and on the ball you are a body between him and the rim.",
    "球、你、人：每一次传球都要同时看到球和你的人，在球还在空中时就移动。离球一传就封堵，离球两传就到禁区里协防，防持球人时你就是挡在他和篮筐之间的那堵墙。",
    "球、你、人：每一次傳球都要同時看到球和你的人，在球還在空中時就移動。離球一傳就封堵，離球兩傳就到禁區裡協防，防持球人時你就是擋在他和籃框之間的那堵牆。",
    "ボール・自分・マーク：パスのたびに両方を視野に入れ、ボールが空中にある間に動く。ワンパス離れたらディナイ、ツーパス離れたらレーンでヘルプ、ボールマンには彼とリングの間に体を置く。",
    "볼, 나, 맨: 패스마다 둘 다 보고 공이 떠 있는 동안 움직인다. 한 패스 거리면 디나이, 두 패스 거리면 레인에서 헬프, 볼 핸들러에게는 그와 림 사이의 몸이 된다.",
    "Balón, tú, hombre: ve a los dos en cada pase y muévete mientras el balón vuela. A un pase, niega; a dos pases, ayuda desde la zona; sobre el balón, eres un cuerpo entre él y el aro.",
    "Ballon, toi, joueur : vois les deux à chaque passe et bouge pendant que le ballon vole. À une passe, refuse ; à deux passes, aide depuis la raquette ; sur le porteur, tu es un corps entre lui et le cercle.",
    "Bola, kamu, lawan: lihat keduanya di setiap umpan dan bergerak selagi bola di udara. Satu umpan jauhnya, tolak; dua umpan, bantu dari area; pada pembawa bola, jadilah badan di antara dia dan ring.",
    "Bola, anda, lawan: lihat kedua-duanya pada setiap hantaran dan bergerak semasa bola di udara. Satu hantaran jauh, nafikan; dua hantaran, bantu dari kawasan; pada pembawa bola, jadi badan di antara dia dan jaring.",
    "บอล ตัวเอง คนที่ประกบ มองเห็นทั้งสองทุกครั้งที่มีการส่ง และขยับตอนบอลยังลอย ห่างหนึ่งการส่งให้ปิด ห่างสองการส่งให้ช่วยในเขต ประกบคนถือบอลให้เป็นกำแพงระหว่างเขากับห่วง",
    "Bóng, bạn, người: mỗi đường chuyền phải thấy cả hai và di chuyển khi bóng còn trên không. Cách một đường chuyền thì chặn, cách hai đường chuyền thì bọc lót trong khu vực, kèm người có bóng thì bạn là bức tường giữa anh ta và rổ.")


def man_defence() -> list[Drill]:
    return [
        # The wing V-cuts in, out, then backdoor; his defender stays in the
        # passing lane, opens to the ball on the backdoor and takes it.
        _play("bb_man_deny", "defending",
              suffixed(MAN_NAME, _n("denying the wing", "封堵侧翼接球", "封堵側翼接球",
                                    "ウイングのディナイ", "윙 디나이", "negando el ala",
                                    "refuser l'aile", "menolak sayap", "menafikan sayap",
                                    "ปิดปีก", "chặn bắt bóng ở cánh")),
              MAN_NOTE,
              [("1", (0.50, 0.36), []),
               ("2", (0.13, 0.25), [(0.22, 0.14, 0), (0.12, 0.30, 1), (0.34, 0.08, 2)]),
               ("3", (0.88, 0.26), [])],
              [("X1", (0.50, 0.30), []),
               ("X2", (0.20, 0.27), [(0.26, 0.17, 0), (0.19, 0.29, 1), (0.36, 0.12, 2)]),
               ("X3", (0.66, 0.20), [])],
              to=[("a1", 2)], free=True, usage=3),
        # Ball to the wing: the post defender steps round to the ball side,
        # and the weak-side defender sinks behind for the lob.
        _play("bb_man_post_front", "defending",
              suffixed(MAN_NAME, _n("fronting the post", "绕前防低位", "繞前防低位",
                                    "ポストのフロント", "포스트 프런트", "por delante del poste",
                                    "devant le poste", "menjaga post dari depan",
                                    "mengawal tiang dari depan", "ยืนหน้าโพสต์",
                                    "đứng trước người ở post")),
              MAN_NOTE,
              [("1", (0.50, 0.36), []),
               ("2", (0.13, 0.26), []),
               ("5", (0.31, 0.11), [(0.40, 0.07, 1)]),
               ("4", (0.88, 0.26), [])],
              [("X1", (0.50, 0.30), [(0.40, 0.31, 0)]),
               ("X2", (0.22, 0.28), [(0.19, 0.22, 0)]),
               ("X5", (0.36, 0.15), [(0.24, 0.13, 0)]),
               ("X4", (0.70, 0.18), [(0.52, 0.10, 0), (0.43, 0.06, 1)])],
              to=[(1, 0), ("a3", 1)], free=True),
        # Pass and cut: the passer's defender jumps toward the ball on the
        # pass, so the give-and-go comes back into his hands.
        _play("bb_man_jump_to_ball", "defending",
              suffixed(MAN_NAME, _n("jumping to the ball", "随球移位", "隨球移位",
                                    "ジャンプ・トゥ・ザ・ボール", "점프 투 더 볼",
                                    "saltando hacia el balón", "sauter vers le ballon",
                                    "melompat ke arah bola", "melompat ke arah bola",
                                    "กระโดดตามบอล", "nhảy theo hướng bóng")),
              MAN_NOTE,
              [("1", (0.50, 0.36), [(0.58, 0.12, 1)]),
               ("2", (0.87, 0.26), []),
               ("3", (0.13, 0.26), [])],
              [("X1", (0.50, 0.30), [(0.60, 0.27, 0), (0.62, 0.18, 1), (0.66, 0.16, 2)]),
               ("X2", (0.76, 0.24), [(0.80, 0.21, 0)]),
               ("X3", (0.30, 0.18), [])],
              to=[(1, 0), ("a0", 2)]),
        # Baseline drive: the big helps, the weak-side man drops to the
        # big's man, and the top defender sinks and closes out on the kick.
        _play("bb_man_help_the_helper", "defending",
              suffixed(MAN_NAME, _n("helping the helper", "补防轮转", "補防輪轉",
                                    "ヘルプ・ザ・ヘルパー", "헬프의 헬프",
                                    "ayudando al que ayuda", "aider l'aidant",
                                    "membantu yang membantu", "membantu yang membantu",
                                    "ช่วยคนที่ไปช่วย", "bọc lót cho người bọc lót")),
              MAN_NOTE,
              [("1", (0.86, 0.25), [(0.80, 0.08, 0)]),
               ("5", (0.31, 0.11), [(0.42, 0.07, 1)]),
               ("4", (0.12, 0.26), []),
               ("2", (0.50, 0.36), [])],
              [("X1", (0.80, 0.20), [(0.84, 0.11, 0)]),
               ("X5", (0.38, 0.14), [(0.66, 0.08, 1)]),
               ("X4", (0.26, 0.20), [(0.38, 0.10, 1)]),
               ("X2", (0.50, 0.30), [(0.33, 0.27, 1), (0.20, 0.24, 2)])],
              to=[(0, 0), (2, 2), (BASKET, 3)], level="advanced"),
    ]


def transition_plays() -> list[Drill]:
    """Full court: the attack goes up the board from the rebound below."""
    return [
        _play("bb_break_outlet", "ssg",
              _n("Fast break: rebound, outlet, three lanes", "快攻：篮板、一传、三线推进",
                 "快攻：籃板、一傳、三線推進", "速攻：リバウンド、アウトレット、3レーン",
                 "속공: 리바운드, 아웃렛, 3레인", "Contraataque: rebote, primer pase y tres carriles",
                 "Contre-attaque : rebond, relance, trois couloirs",
                 "Serangan cepat: rebound, outlet, tiga jalur",
                 "Serangan pantas: lantunan, hantaran pertama, tiga lorong",
                 "เกมบุกเร็ว: รีบาวด์ เอาท์เล็ต สามเลน", "Phản công nhanh: bắt bóng bật, chuyền thoát, ba làn"),
              _n("The outlet is caught on the sideline at the free-throw line extended, facing up the floor. The ball goes to the middle on the dribble, the wings run wide to the corners and cut at the last moment — sprint wide first, cut late.",
                 "一传在罚球线延长线的边线附近接，接球时面向前场。球靠运球推到中路，两翼贴边跑到底角，最后一刻才斜插——先跑宽，晚切入。",
                 "一傳在罰球線延長線的邊線附近接，接球時面向前場。球靠運球推到中路，兩翼貼邊跑到底角，最後一刻才斜插——先跑寬，晚切入。",
                 "アウトレットはフリースローライン延長のサイドライン際で、前を向いてキャッチ。ボールはドリブルで中央へ、両ウイングはワイドにコーナーまで走り、最後の瞬間にカット。まず広く、切るのは遅く。",
                 "아웃렛은 자유투 라인 연장선의 사이드라인 근처에서 앞을 보고 받는다. 공은 드리블로 가운데로, 양 윙은 넓게 코너까지 달리다 마지막 순간에 컷 — 먼저 넓게, 컷은 늦게.",
                 "El primer pase se recibe junto a la banda a la altura del tiro libre, mirando hacia delante. El balón va al centro botando, los aleros corren abiertos hasta las esquinas y cortan en el último momento: primero abierto, el corte tarde.",
                 "La relance se reçoit le long de la ligne de touche à hauteur des lancers francs, face au jeu. Le ballon rejoint le centre en dribble, les ailiers courent larges jusqu'aux corners et coupent au dernier moment — d'abord large, la coupe tard.",
                 "Outlet ditangkap di dekat garis samping sejajar garis lemparan bebas, menghadap ke depan. Bola dibawa ke tengah dengan dribel, sayap berlari melebar ke sudut dan baru memotong di saat terakhir — lebar dulu, potong belakangan.",
                 "Hantaran pertama ditangkap berhampiran garisan tepi selari garisan balingan percuma, menghadap ke hadapan. Bola dibawa ke tengah dengan dribel, sayap berlari lebar ke penjuru dan memotong pada saat akhir.",
                 "เอาท์เล็ตรับที่ริมเส้นข้างแนวเส้นโทษ หันหน้าไปข้างหน้า เลี้ยงบอลเข้ากลาง ปีกทั้งสองวิ่งกว้างไปถึงมุมแล้วค่อยตัดตอนท้าย วิ่งกว้างก่อน ตัดทีหลัง",
                 "Đường chuyền thoát được bắt sát biên dọc ngang vạch ném phạt, mặt hướng lên sân. Bóng được dẫn vào giữa, hai cánh chạy rộng tới góc rồi mới cắt vào phút cuối — chạy rộng trước, cắt muộn."),
              [("5", (0.50, 0.90), [(0.50, 0.74, 1), (0.46, 0.56, 2)]),
               ("1", (0.62, 0.80), [(0.88, 0.78, 0), (0.50, 0.52, 1), (0.50, 0.34, 2)]),
               ("2", (0.30, 0.88), [(0.10, 0.62, 0), (0.08, 0.36, 1), (0.06, 0.14, 2)]),
               ("3", (0.70, 0.92), [(0.76, 0.66, 0), (0.90, 0.40, 1), (0.94, 0.16, 2),
                                    (0.66, 0.08, 3)])],
              to=[(1, 0), (1, 1), (1, 2), (3, 3), (BASKET, 4)], free=True, usage=3),
        _play("bb_break_drag", "attacking",
              _n("Transition: the drag screen", "转换进攻：拖后掩护",
                 "轉換進攻：拖後掩護", "トランジション：ドラッグスクリーン",
                 "트랜지션: 드래그 스크린", "Transición: el bloqueo drag",
                 "Transition : l'écran drag", "Transisi: drag screen", "Peralihan: skrin drag",
                 "ทรานสิชัน: ดรากสกรีน", "Chuyển đổi: màn chắn kéo (drag)"),
              _n("The trailing big sprints straight into a ball screen before the defence has matched up — nobody has called a coverage yet. The wings stay in the corners and the rim-runner sits on the block, so the roll has the lane to itself.",
                 "后面跟进的内线直接冲上去挡拆，趁防守还没对好人——这时还没人喊出挡拆防守方式。两翼留在底角，冲篮的人卡在低位，下顺的人独享整个禁区。",
                 "後面跟進的內線直接衝上去擋拆，趁防守還沒對好人——這時還沒人喊出擋拆防守方式。兩翼留在底角，衝籃的人卡在低位，下順的人獨享整個禁區。",
                 "トレーラーのビッグは守備がマッチアップする前に一直線にボールスクリーンへ。まだ誰もカバレッジを決めていない。ウイングはコーナー、リムランナーはブロックに残り、ロールはレーンを独占する。",
                 "뒤따르는 빅맨이 수비가 매치업하기 전에 곧장 볼 스크린으로 달려간다 — 아직 아무도 커버리지를 정하지 못했다. 윙은 코너에, 림 러너는 블록에 남아 롤러가 레인을 독차지한다.",
                 "El pívot que llega tarde va directo a un bloqueo directo antes de que la defensa se empareje: nadie ha cantado aún cómo defenderlo. Los aleros en las esquinas y el que corre al aro en el poste bajo, así la continuación tiene la zona para ella sola.",
                 "L'intérieur qui suit file directement poser un écran porteur avant que la défense ne se soit organisée — personne n'a encore annoncé de couverture. Les ailiers restent dans les corners et le coureur au poste bas, la plongée a la raquette pour elle seule.",
                 "Big man yang menyusul langsung berlari memasang screen bola sebelum pertahanan mendapat lawannya — belum ada yang menyebut cara bertahan. Sayap tetap di sudut, pelari ring di blok, sehingga roller memiliki area sendirian.",
                 "Big man yang menyusul terus berlari memasang skrin bola sebelum pertahanan mendapat lawannya. Sayap kekal di penjuru dan pelari jaring di blok, jadi penggolek memiliki kawasan sendirian.",
                 "บิ๊กแมนที่วิ่งตามมาพุ่งเข้าตั้งสกรีนบอลทันทีก่อนกองหลังจับคู่ได้ ยังไม่มีใครเรียกวิธีรับ ปีกอยู่ที่มุม คนวิ่งเข้าห่วงอยู่ที่บล็อก คนโรลจึงมีเขตทั้งหมดเป็นของตัวเอง",
                 "Trung phong chạy sau lao thẳng lên chắn bóng trước khi phòng ngự kịp ghép người — chưa ai kịp hô cách phòng thủ. Hai cánh ở góc, người lao rổ đứng ở block, nên người cắt vào có trọn khu vực."),
              [("1", (0.30, 0.62), [(0.30, 0.40, 0), (0.54, 0.27, 2)]),
               ("5", (0.50, 0.72), [(0.42, 0.47, 0), (0.38, 0.35, 1), (0.47, 0.11, 2)]),
               ("2", (0.04, 0.10), []),
               ("3", (0.96, 0.10), []),
               ("4", (0.69, 0.10), [])],
              [("X1", (0.30, 0.52), [(0.32, 0.33, 0), (0.40, 0.31, 2)]),
               ("X5", (0.50, 0.40), [(0.50, 0.24, 0), (0.52, 0.17, 2), (0.50, 0.13, 3)])],
              to=[(0, 0), (0, 2), (1, 3), (BASKET, 4)]),
        _play("bb_break_defence", "defending",
              _n("Transition defence: sprint back, stop the ball", "退防：冲回去，先挡球",
                 "退防：衝回去，先擋球", "トランジションディフェンス：全力で戻りボールを止める",
                 "전환 수비: 전력 복귀, 공 저지", "Defensa de transición: volver y parar el balón",
                 "Repli défensif : sprinter et stopper le ballon",
                 "Bertahan transisi: lari kembali, hentikan bola",
                 "Pertahanan peralihan: lari pulang, hentikan bola",
                 "รับทรานสิชัน: วิ่งกลับ หยุดบอล", "Phòng ngự chuyển đổi: chạy về, chặn bóng"),
              _n("The first man back runs to the rim, not to his man. The second stops the ball above the arc, and everyone else matches up on the way in — talk while you run: 'Ball!', 'Rim!'",
                 "第一个退回来的人跑向篮下，而不是去找自己的人。第二个人在三分线外把球拦住，其余的人边跑边对人——一边跑一边喊：「我防球！」「我守篮！」",
                 "第一個退回來的人跑向籃下，而不是去找自己的人。第二個人在三分線外把球攔住，其餘的人邊跑邊對人——一邊跑一邊喊：「我防球！」「我守籃！」",
                 "最初に戻る選手はマークではなくリングへ走る。2人目はアークの外でボールを止め、残りは戻りながらマッチアップ。走りながら声を出す：「ボール！」「リング！」",
                 "가장 먼저 돌아온 선수는 자기 맨이 아니라 림으로 달린다. 두 번째는 아크 밖에서 공을 멈추고, 나머지는 돌아오면서 매치업한다 — 뛰면서 말하라: '볼!' '림!'",
                 "El primero en volver corre al aro, no a su hombre. El segundo para el balón por encima del triple y el resto se empareja por el camino; hablad mientras corréis: «¡Balón!», «¡Aro!»",
                 "Le premier replié court au cercle, pas sur son joueur. Le deuxième stoppe le ballon au-dessus de l'arc, les autres prennent leur joueur en revenant — parlez en courant : « Ballon ! », « Cercle ! »",
                 "Orang pertama yang kembali lari ke ring, bukan ke lawannya. Orang kedua menghentikan bola di luar garis tiga, sisanya mengambil lawan sambil berlari — bicara sambil lari: 'Bola!', 'Ring!'",
                 "Orang pertama yang pulang lari ke jaring, bukan ke lawannya. Orang kedua menghentikan bola di luar garisan tiga mata, yang lain mengambil lawan sambil berlari — bercakap sambil berlari.",
                 "คนแรกที่วิ่งกลับไปที่ห่วง ไม่ใช่ไปหาคนของตัวเอง คนที่สองหยุดบอลนอกเส้นสามแต้ม ที่เหลือจับคู่ระหว่างวิ่งกลับ พูดขณะวิ่ง: 'บอล!' 'ห่วง!'",
                 "Người về đầu tiên chạy tới rổ, không phải tới người của mình. Người thứ hai chặn bóng ngoài vạch ba điểm, những người còn lại ghép người trên đường về — vừa chạy vừa hô: 'Bóng!', 'Rổ!'"),
              [("1", (0.44, 0.66), [(0.46, 0.48, 0), (0.48, 0.38, 1)]),
               ("2", (0.14, 0.70), [(0.10, 0.46, 0), (0.12, 0.26, 1)]),
               ("3", (0.86, 0.70), [(0.90, 0.46, 0), (0.88, 0.26, 1)])],
              [("X1", (0.56, 0.58), [(0.50, 0.12, 0), (0.80, 0.20, 2)]),
               ("X2", (0.62, 0.70), [(0.46, 0.42, 0), (0.48, 0.31, 1), (0.52, 0.14, 2)]),
               ("X3", (0.30, 0.78), [(0.20, 0.50, 0), (0.18, 0.22, 1)])],
              to=[(0, 0), (0, 1), (2, 2), (BASKET, 3)], free=True),
    ]


def skill_drills() -> list[Drill]:
    return [
        # Pass and go behind the receiver, the length of the floor.
        _play("bb_weave", "warmup",
              _n("Three-man weave", "三人八字传球", "三人八字傳球", "スリーメンウィーブ",
                 "3인 위브", "Ocho a tres", "Huit à trois", "Weave tiga orang",
                 "Weave tiga orang", "วีฟสามคน", "Chuyền đan ba người"),
              _n("Pass and go behind the man you passed to — always behind, never in front. The ball never touches the floor, and the receiver is moving toward the middle when it arrives.",
                 "传给谁就从谁身后绕过去——永远从身后，绝不从身前。球不落地，接球的人在球到的时候正往中路跑。",
                 "傳給誰就從誰身後繞過去——永遠從身後，絕不從身前。球不落地，接球的人在球到的時候正往中路跑。",
                 "パスした相手の後ろを回る——必ず後ろ、前は通らない。ボールは床につかず、受け手はボールが届く時に中央へ向かって動いている。",
                 "패스한 사람의 뒤로 돌아간다 — 언제나 뒤로, 절대 앞으로 가지 않는다. 공은 바닥에 닿지 않고, 받는 사람은 공이 올 때 가운데로 움직이고 있다.",
                 "Pasa y ve por detrás de quien recibe: siempre por detrás, nunca por delante. El balón no toca el suelo y el receptor va hacia el centro cuando le llega.",
                 "Passe et passe derrière celui qui reçoit — toujours derrière, jamais devant. Le ballon ne touche pas le sol, et le receveur se dirige vers le centre quand il arrive.",
                 "Umpan lalu lari di belakang penerima — selalu di belakang, tak pernah di depan. Bola tak menyentuh lantai, dan penerima bergerak ke tengah saat bola tiba.",
                 "Hantar dan lari di belakang penerima — sentiasa di belakang, tidak pernah di depan. Bola tidak menyentuh lantai, dan penerima bergerak ke tengah apabila bola tiba.",
                 "ส่งแล้ววิ่งอ้อมหลังคนที่รับ อ้อมหลังเสมอ ไม่ผ่านหน้า บอลไม่แตะพื้น และคนรับกำลังวิ่งเข้ากลางตอนบอลมาถึง",
                 "Chuyền rồi chạy vòng sau lưng người nhận — luôn phía sau, không bao giờ phía trước. Bóng không chạm sàn, và người nhận đang di chuyển vào giữa khi bóng tới."),
              [("1", (0.50, 0.92), [(0.86, 0.76, 0), (0.86, 0.58, 1), (0.60, 0.42, 2),
                                    (0.14, 0.24, 3), (0.22, 0.14, 4)]),
               ("2", (0.18, 0.92), [(0.16, 0.74, 0), (0.40, 0.60, 1), (0.86, 0.40, 2),
                                    (0.84, 0.22, 3), (0.60, 0.10, 4)]),
               ("3", (0.82, 0.92), [(0.62, 0.78, 0), (0.14, 0.56, 1), (0.14, 0.40, 2),
                                    (0.40, 0.26, 3), (0.40, 0.18, 4)])],
              to=[(2, 0), (1, 1), (0, 2), (2, 3), (1, 4), (BASKET, 5)],
              free=True, usage=3, minutes=8),
        # Under the rim, alternate hook finishes off the glass, no dribble.
        _play("bb_mikan", "finishing",
              _n("Mikan drill", "麦肯篮下练习", "麥肯籃下練習", "マイカンドリル", "마이칸 드릴",
                 "Ejercicio Mikan", "Exercice Mikan", "Latihan Mikan", "Latihan Mikan",
                 "ดริลไมแคน", "Bài tập Mikan"),
              _n("Catch it out of the net, one step across, finish with the outside hand off the glass — no dribble, ever. The ball stays above the shoulders the whole time.",
                 "球从网里落下就接住，横跨一步，用外侧手打板上篮——永远不运球。球全程保持在肩膀以上。",
                 "球從網裡落下就接住，橫跨一步，用外側手打板上籃——永遠不運球。球全程保持在肩膀以上。",
                 "ネットから落ちたボールをキャッチ、横へ1歩、外側の手でボードに当てて決める。ドリブルは絶対にしない。ボールはずっと肩より上。",
                 "그물에서 떨어진 공을 잡고, 옆으로 한 발, 바깥손으로 백보드에 맞혀 마무리 — 드리블은 절대 없다. 공은 내내 어깨 위에.",
                 "Recoge el balón de la red, un paso al otro lado y finaliza a tabla con la mano exterior; nunca botes. El balón siempre por encima de los hombros.",
                 "Récupère le ballon sous le filet, un pas de l'autre côté, finis avec la main extérieure contre la planche — jamais de dribble. Le ballon reste au-dessus des épaules tout du long.",
                 "Tangkap bola dari jaring, satu langkah menyeberang, selesaikan dengan tangan luar ke papan — tanpa dribel. Bola selalu di atas bahu.",
                 "Tangkap bola dari jaring, satu langkah ke seberang, selesaikan dengan tangan luar ke papan — tanpa dribel. Bola sentiasa di atas bahu.",
                 "รับบอลที่หล่นจากตาข่าย ก้าวข้ามหนึ่งก้าว จบด้วยมือนอกกระทบแป้น ไม่เลี้ยงเด็ดขาด บอลอยู่เหนือไหล่ตลอด",
                 "Bắt bóng rơi từ lưới, bước ngang một bước, kết thúc bằng tay ngoài vào bảng — không bao giờ dẫn bóng. Bóng luôn ở trên vai."),
              [("1", (0.61, 0.13), [(0.57, 0.09, 0), (0.39, 0.13, 1), (0.43, 0.09, 2),
                                    (0.61, 0.13, 3), (0.57, 0.09, 4)])],
              to=[(BASKET, 0), (0, 1), (BASKET, 2), (0, 3), (BASKET, 4)],
              free=True, usage=3, minutes=6),
        # The passer feeds, closes out, and runs back to rebound while the
        # shooter moves on to the next spot.
        _play("bb_shoot_circuit", "finishing",
              _n("Partner shooting: three spots", "搭档投篮：三点轮换", "搭檔投籃：三點輪換",
                 "パートナーシューティング：3スポット", "파트너 슈팅: 3스팟",
                 "Tiro por parejas: tres posiciones", "Tir à deux : trois positions",
                 "Menembak berpasangan: tiga titik", "Menjaring berpasangan: tiga titik",
                 "ยิงคู่: สามจุด", "Ném rổ theo cặp: ba vị trí"),
              _n("The passer follows his pass with a hand up and runs back for the rebound, so every shot is taken over a closeout. Relocate on the rebound — the shooter is on his next spot before the ball comes back out.",
                 "传球人传完就举手扑过去，再跑回去抢篮板，所以每一投都要越过扑防出手。抢篮板的时候投手就换位——球还没传出来，他已经站到下一个点。",
                 "傳球人傳完就舉手撲過去，再跑回去搶籃板，所以每一投都要越過撲防出手。搶籃板的時候投手就換位——球還沒傳出來，他已經站到下一個點。",
                 "パサーはパスに続いて手を上げて寄り、戻ってリバウンド。だから全てのシュートはクローズアウト越しになる。リバウンドの間にシューターは移動し、ボールが戻る前に次のスポットにいる。",
                 "패서는 패스를 따라 손을 들고 다가갔다가 리바운드하러 돌아간다. 그래서 모든 슛은 클로즈아웃을 넘어 쏜다. 리바운드 동안 슈터는 이동해, 공이 다시 나오기 전에 다음 자리에 있다.",
                 "El pasador sigue su pase con la mano arriba y vuelve a por el rebote, así cada tiro es sobre un cierre. El tirador se recoloca durante el rebote: está en su siguiente sitio antes de que vuelva el balón.",
                 "Le passeur suit sa passe main levée puis revient au rebond : chaque tir se prend face à un close-out. Le shooteur se replace pendant le rebond — il est sur sa position suivante avant que le ballon ne ressorte.",
                 "Pengumpan mengikuti umpannya dengan tangan terangkat lalu kembali merebut rebound, jadi setiap tembakan dilakukan melewati closeout. Penembak berpindah saat rebound — sudah di titik berikutnya sebelum bola keluar lagi.",
                 "Penghantar mengikut hantarannya dengan tangan diangkat lalu kembali merebut lantunan, jadi setiap jaringan melepasi closeout. Penjaring beralih semasa lantunan.",
                 "คนส่งตามบอลไปพร้อมยกมือแล้ววิ่งกลับไปเก็บรีบาวด์ ทุกการยิงจึงต้องยิงข้ามโคลสเอาท์ คนยิงย้ายจุดระหว่างรีบาวด์ อยู่จุดต่อไปก่อนบอลจะออกมา",
                 "Người chuyền theo đường chuyền giơ tay áp sát rồi chạy về bắt bóng bật, nên mọi cú ném đều qua một pha áp sát. Xạ thủ đổi chỗ trong lúc bắt bóng bật — đã ở vị trí tiếp theo trước khi bóng được chuyền ra."),
              [("1", (0.05, 0.10), [(0.12, 0.27, 2), (0.50, 0.36, 5)]),
               ("2", (0.42, 0.08), [(0.17, 0.11, 0), (0.42, 0.08, 1), (0.24, 0.21, 3),
                                    (0.44, 0.09, 4), (0.50, 0.25, 6), (0.50, 0.11, 7)])],
              ball=1,
              to=[(0, 0), (BASKET, 1), (1, 2), (0, 3), (BASKET, 4), (1, 5), (0, 6),
                  (BASKET, 7)], free=True),
        _play("bb_shoot_curl", "finishing",
              _n("Shooting off a curl", "借掩护弧线切出投篮", "借掩護弧線切出投籃",
                 "カールからのシュート", "컬 컷 슈팅", "Tiro saliendo en curl", "Tir après un curl",
                 "Menembak dari curl", "Menjaring dari curl", "ยิงจากการเคิร์ล",
                 "Ném rổ sau pha vòng màn chắn"),
              _n("When the defender trails, curl: run tight round the screener's hip and catch moving toward the rim. A wide curl gives the trailer a short cut; a tight one leaves him on the screener's back.",
                 "防守人跟在后面时就弧线内切：贴着掩护人的胯部绕过去，接球时身体朝着篮筐方向移动。绕得太大，跟防的人就能抄近路；绕得紧，他就被挂在掩护人背上。",
                 "防守人跟在後面時就弧線內切：貼著掩護人的胯部繞過去，接球時身體朝著籃框方向移動。繞得太大，跟防的人就能抄近路；繞得緊，他就被掛在掩護人背上。",
                 "マークが後ろを追ってきたらカール。スクリナーの腰をなめるように回り、リングへ向かいながらキャッチ。大回りは近道を与え、小回りなら相手はスクリナーの背中に引っかかる。",
                 "수비가 뒤따라오면 컬: 스크리너의 엉덩이를 바짝 돌아 림 쪽으로 움직이며 받는다. 크게 돌면 지름길을 주고, 바짝 돌면 수비는 스크리너 등에 걸린다.",
                 "Si el defensor persigue, curl: gira pegado a la cadera del bloqueador y recibe yendo hacia el aro. Un curl abierto le da un atajo al perseguidor; uno cerrado lo deja en la espalda del bloqueador.",
                 "Quand le défenseur suit, curl : tourne au ras de la hanche du poseur et réceptionne en allant vers le cercle. Un curl large offre un raccourci ; un curl serré le laisse dans le dos du poseur.",
                 "Saat bek mengekor, curl: putari rapat pinggul pemasang screen dan tangkap sambil bergerak ke ring. Curl lebar memberi jalan pintas; curl rapat meninggalkannya di punggung pemasang screen.",
                 "Apabila pemain bertahan mengekor, curl: pusing rapat pinggul pemasang skrin dan tangkap sambil bergerak ke jaring. Curl lebar memberi jalan pintas; curl rapat meninggalkannya di belakang pemasang skrin.",
                 "เมื่อคนประกบไล่ตามหลัง ให้เคิร์ล วิ่งอ้อมชิดสะโพกคนสกรีนแล้วรับบอลขณะเคลื่อนเข้าหาห่วง เคิร์ลกว้างคือให้ทางลัด เคิร์ลแคบทำให้เขาติดอยู่หลังคนสกรีน",
                 "Khi hậu vệ bám sau, hãy vòng (curl): ôm sát hông người chắn và bắt bóng khi đang di chuyển về rổ. Vòng rộng cho kẻ bám đường tắt; vòng hẹp bỏ anh ta lại sau lưng người chắn."),
              [("1", (0.68, 0.36), []),
               ("2", (0.24, 0.10), [(0.18, 0.06, 0), (0.44, 0.24, 1)]),
               ("4", (0.30, 0.20), [])],
              [("X2", (0.26, 0.14), [(0.21, 0.10, 0), (0.25, 0.16, 1), (0.38, 0.21, 2)])],
              to=[(1, 2), (BASKET, 3)]),
        _play("bb_shoot_pull_up", "finishing",
              _n("Pull-up jumper", "急停跳投", "急停跳投", "プルアップジャンパー", "풀업 점퍼",
                 "Tiro tras bote (pull-up)", "Tir en pull-up", "Tembakan pull-up",
                 "Jaringan pull-up", "พูลอัพจัมเปอร์", "Bật nhảy ném sau dẫn bóng"),
              _n("Two hard dribbles, then stop on the second step with the shoulders square — the pull-up is won in the stop, not in the jump. A defender backing off is telling you to shoot.",
                 "两次大力运球，第二步急停、肩膀摆正——急停跳投赢在停，不在跳。防守人往后退，就是在告诉你可以投。",
                 "兩次大力運球，第二步急停、肩膀擺正——急停跳投贏在停，不在跳。防守人往後退，就是在告訴你可以投。",
                 "強いドリブル2回、2歩目で止まり肩をスクエアに。プルアップはジャンプでなくストップで決まる。下がるディフェンスは「打て」と言っている。",
                 "강한 드리블 두 번, 두 번째 스텝에서 멈추고 어깨를 정면으로 — 풀업은 점프가 아니라 멈춤에서 이긴다. 물러서는 수비는 슛하라고 말하고 있다.",
                 "Dos botes fuertes y parada en el segundo paso con los hombros cuadrados: el pull-up se gana en la parada, no en el salto. Un defensor que retrocede te está diciendo que tires.",
                 "Deux dribbles appuyés, arrêt sur le deuxième appui, épaules face au panier — le pull-up se gagne à l'arrêt, pas au saut. Un défenseur qui recule te dit de tirer.",
                 "Dua dribel keras, berhenti di langkah kedua dengan bahu lurus — pull-up dimenangkan saat berhenti, bukan saat melompat. Bek yang mundur sedang menyuruhmu menembak.",
                 "Dua dribel kuat, berhenti pada langkah kedua dengan bahu lurus — pull-up dimenangi semasa berhenti, bukan semasa melompat. Pemain bertahan yang berundur menyuruh anda menjaring.",
                 "เลี้ยงแรงสองครั้ง หยุดที่ก้าวที่สองไหล่ตรง พูลอัพชนะกันที่การหยุด ไม่ใช่ที่การกระโดด กองหลังที่ถอยกำลังบอกให้คุณยิง",
                 "Hai nhịp dẫn mạnh, dừng ở bước thứ hai với vai vuông — cú pull-up thắng ở pha dừng chứ không ở cú bật. Hậu vệ lùi lại là đang bảo bạn ném."),
              [("1", (0.66, 0.42), [(0.62, 0.24, 0)])],
              [("X1", (0.62, 0.34), [(0.59, 0.16, 0)])],
              to=[(0, 0), (BASKET, 1)], level="foundation", minutes=8),
        _play("bb_finish_euro_step", "finishing",
              _n("Euro-step finish", "欧洲步上篮", "歐洲步上籃", "ユーロステップ",
                 "유로 스텝 마무리", "Finalización en paso europeo", "Finition en pas européen",
                 "Penyelesaian euro step", "Penamat euro step", "จบด้วยยูโรสเต็ป",
                 "Lên rổ bước châu Âu"),
              _n("Gather, first step at the help defender, second step across his body — the ball moves with the second step, away from his hands. Two steps after the gather, never three.",
                 "收球，第一步朝协防人迈，第二步横跨到他身体另一侧——球随第二步移开，远离他的手。收球后只有两步，绝不三步。",
                 "收球，第一步朝協防人邁，第二步橫跨到他身體另一側——球隨第二步移開，遠離他的手。收球後只有兩步，絕不三步。",
                 "ギャザーし、1歩目はヘルプへ、2歩目は相手の体の反対側へ。ボールは2歩目と一緒に相手の手から離す。ギャザー後は2歩、3歩は絶対にない。",
                 "개더 후 첫 스텝은 헬프 수비 쪽으로, 두 번째 스텝은 그의 몸 반대편으로 — 공은 두 번째 스텝과 함께 그의 손에서 멀어진다. 개더 후 두 스텝, 세 스텝은 절대 없다.",
                 "Recoge, primer paso hacia el defensor que ayuda, segundo paso cruzando su cuerpo: el balón se mueve con el segundo paso, lejos de sus manos. Dos pasos tras recoger, nunca tres.",
                 "Ramasse, premier appui vers le défenseur en aide, second appui de l'autre côté de son corps — le ballon part avec le second appui, loin de ses mains. Deux appuis après le ramassé, jamais trois.",
                 "Gather, langkah pertama ke arah bek help, langkah kedua menyeberangi badannya — bola bergerak bersama langkah kedua, menjauhi tangannya. Dua langkah setelah gather, tak pernah tiga.",
                 "Kumpul, langkah pertama ke arah pembantu, langkah kedua merentas badannya — bola bergerak bersama langkah kedua, jauh dari tangannya. Dua langkah selepas kumpul, tidak pernah tiga.",
                 "เก็บบอล ก้าวแรกเข้าหาคนมาช่วย ก้าวที่สองข้ามไปอีกฝั่งตัวเขา บอลย้ายไปพร้อมก้าวที่สอง ห่างจากมือเขา หลังเก็บบอลมีสองก้าว ไม่มีสาม",
                 "Thu bóng, bước một hướng vào người bọc lót, bước hai cắt ngang qua người anh ta — bóng di chuyển cùng bước hai, xa tầm tay anh ta. Hai bước sau khi thu bóng, không bao giờ ba."),
              [("1", (0.86, 0.30), [(0.70, 0.19, 0), (0.63, 0.13, 1), (0.52, 0.09, 2)])],
              [("X5", (0.50, 0.17), [(0.60, 0.15, 0), (0.63, 0.11, 2)])],
              to=[(0, 0), (0, 1), (0, 2), (BASKET, 3)], free=True, level="foundation",
              minutes=8),
        _play("bb_handle_cones", "warmup",
              _n("Ball-handling: attacking the cones", "运球：锥桶变向突破", "運球：錐桶變向突破",
                 "ハンドリング：コーンアタック", "볼 핸들링: 콘 어택",
                 "Manejo de balón: atacar los conos", "Dribble : attaquer les plots",
                 "Dribel: menyerang kerucut", "Kawalan bola: menyerang kon",
                 "การเลี้ยงบอล: บุกผ่านกรวย", "Dẫn bóng: tấn công cọc"),
              _n("Attack each cone as if it were a defender's front foot: full speed until one step away, change hands low and explode past it. A move made two metres away fools nobody.",
                 "把每个锥桶当成防守人的前脚去攻：全速冲到只差一步，再低手换手、爆发过去。离着两米就做动作，谁也骗不了。",
                 "把每個錐桶當成防守人的前腳去攻：全速衝到只差一步，再低手換手、爆發過去。離著兩米就做動作，誰也騙不了。",
                 "各コーンを相手の前足と思って攻める。1歩手前まで全速、低く持ち替えて一気に抜く。2m手前の動きでは誰もだませない。",
                 "각 콘을 수비의 앞발이라 생각하고 공략하라: 한 걸음 앞까지 전속력, 낮게 손을 바꿔 폭발적으로 지나간다. 2m 앞에서 하는 동작은 아무도 속이지 못한다.",
                 "Ataca cada cono como si fuera el pie adelantado de un defensor: a tope hasta un paso de él, cambio de mano bajo y explota al pasarlo. Un cambio a dos metros no engaña a nadie.",
                 "Attaque chaque plot comme le pied avant d'un défenseur : pleine vitesse jusqu'à un pas, changement de main bas et explose en le passant. Un changement à deux mètres ne trompe personne.",
                 "Serang setiap kerucut seperti kaki depan bek: kecepatan penuh sampai satu langkah, ganti tangan rendah dan meledak melewatinya. Gerakan dari dua meter tak menipu siapa pun.",
                 "Serang setiap kon seperti kaki depan pemain bertahan: kelajuan penuh hingga satu langkah, tukar tangan rendah dan meletup melepasinya.",
                 "บุกกรวยแต่ละอันเหมือนเท้าหน้าของกองหลัง เต็มสปีดจนเหลือหนึ่งก้าว เปลี่ยนมือต่ำแล้วระเบิดผ่าน ทำท่าห่างสองเมตรหลอกใครไม่ได้",
                 "Tấn công mỗi cọc như chân trước của hậu vệ: tốc độ tối đa tới khi còn một bước, đổi tay thấp rồi bứt qua. Động tác cách hai mét chẳng lừa được ai."),
              [("1", (0.52, 0.74), [(0.48, 0.60, 0), (0.55, 0.48, 1), (0.46, 0.36, 2),
                                    (0.56, 0.12, 3)])],
              markers=[M(0.40, 0.58), M(0.62, 0.46), M(0.38, 0.34)],
              to=[(0, 0), (0, 1), (0, 2), (0, 3), (BASKET, 4)], free=True, minutes=8),
        _play("bb_zigzag_1v1", "defending",
              _n("Zig-zag 1v1", "之字形 1v1 防运球", "之字形 1v1 防運球", "ジグザグ1対1",
                 "지그재그 1대1", "Zigzag 1c1", "Zigzag 1c1", "Zig-zag 1v1",
                 "Zig-zag 1v1", "ซิกแซก 1v1", "Zíc zắc 1v1"),
              _n("The defender beats the dribbler to every turn: slide without crossing the feet, and when he changes direction drop-step and run to cut him off before sliding again. Hands active, but the feet do the work.",
                 "防守人要比运球人先到每一个转折点：滑步，脚不交叉；他一变向就撤步、跑过去截住，再继续滑。手要动，但真正干活的是脚。",
                 "防守人要比運球人先到每一個轉折點：滑步，腳不交叉；他一變向就撤步、跑過去截住，再繼續滑。手要動，但真正幹活的是腳。",
                 "ディフェンスは全ての折り返しにドリブラーより先に着く。スライドで足は交差させず、方向転換されたらドロップステップで走って先回りしてから再びスライド。手は動かすが、仕事をするのは足だ。",
                 "수비는 모든 방향 전환 지점에 드리블러보다 먼저 도착한다: 슬라이드, 발은 꼬지 않는다. 그가 방향을 바꾸면 드롭스텝 후 달려서 막고 다시 슬라이드. 손은 바쁘게, 일은 발이 한다.",
                 "El defensor llega antes que el atacante a cada giro: desplazamiento sin cruzar los pies, y cuando cambia de dirección, paso atrás y carrera para cortarle antes de volver a deslizar. Manos activas, pero el trabajo lo hacen los pies.",
                 "Le défenseur arrive avant le dribbleur à chaque virage : pas chassés sans croiser les pieds, et au changement de direction, pas de retrait et course pour lui couper la route avant de reprendre. Mains actives, mais ce sont les pieds qui travaillent.",
                 "Bek tiba lebih dulu di setiap belokan: geser tanpa menyilangkan kaki, dan saat dia ganti arah, drop step lalu lari memotong sebelum geser lagi. Tangan aktif, tapi kaki yang bekerja.",
                 "Pemain bertahan tiba dahulu di setiap belokan: geser tanpa menyilang kaki, dan apabila dia tukar arah, langkah undur dan lari memintas sebelum geser semula.",
                 "กองหลังต้องถึงทุกจุดเลี้ยวก่อนคนเลี้ยง สไลด์โดยไม่ไขว้เท้า เมื่อเขาเปลี่ยนทิศให้ดรอปสเต็ปแล้ววิ่งไปตัดหน้าก่อนสไลด์ต่อ มือขยับ แต่งานอยู่ที่เท้า",
                 "Hậu vệ phải tới mỗi khúc quanh trước người dẫn bóng: trượt ngang không bắt chéo chân, khi anh ta đổi hướng thì lùi chân rồi chạy chặn đầu trước khi trượt tiếp. Tay hoạt động, nhưng chân mới làm việc."),
              [("1", (0.12, 0.92), [(0.34, 0.78, 0), (0.12, 0.62, 1), (0.34, 0.46, 2),
                                    (0.12, 0.30, 3), (0.34, 0.14, 4)])],
              [("X1", (0.18, 0.86), [(0.36, 0.72, 0), (0.15, 0.56, 1), (0.36, 0.40, 2),
                                     (0.15, 0.24, 3), (0.34, 0.08, 4)])],
              follow=0, minutes=8),
        _play("bb_closeout_1v1", "ssg",
              _n("1v1 from a closeout", "扑防后 1v1", "撲防後 1v1", "クローズアウトからの1対1",
                 "클로즈아웃 1대1", "1c1 tras el cierre", "1c1 après un close-out",
                 "1v1 dari closeout", "1v1 dari closeout", "1v1 จากโคลสเอาท์",
                 "1v1 sau pha áp sát"),
              _n("The defender passes and closes out; the attacker reads his feet. High hand and short steps — shoot; flying at you — one dribble past the high foot and finish. Two dribbles at most, so the read is made on the catch.",
                 "防守人传球后扑防，进攻人看他的脚。举高手、碎步刹住——就投；整个人飞过来——从他前脚那侧一次运球过人上篮。最多两次运球，所以判断要在接球那一刻做出。",
                 "防守人傳球後撲防，進攻人看他的腳。舉高手、碎步剎住——就投；整個人飛過來——從他前腳那側一次運球過人上籃。最多兩次運球，所以判斷要在接球那一刻做出。",
                 "ディフェンスがパスしてクローズアウト、オフェンスは足を読む。手が高く小刻みに止まれば打つ。飛び込んでくれば高い方の足の側へワンドリブルで抜いて決める。ドリブルは最大2回、判断はキャッチの瞬間に。",
                 "수비가 패스하고 클로즈아웃, 공격은 발을 읽는다. 손이 높고 잔발로 멈추면 슛, 날아들면 높은 발 쪽으로 원 드리블 돌파 후 마무리. 드리블은 최대 두 번, 판단은 잡는 순간에.",
                 "El defensor pasa y cierra; el atacante lee sus pies. Mano alta y pasos cortos: tira. Si vuela hacia ti: un bote por el lado del pie adelantado y finaliza. Máximo dos botes, así que la lectura se hace al recibir.",
                 "Le défenseur passe et fait son close-out ; l'attaquant lit ses appuis. Main haute et petits pas : tire. S'il arrive en volant : un dribble côté pied avant et finis. Deux dribbles maximum, la lecture se fait à la réception.",
                 "Bek mengumpan lalu closeout; penyerang membaca kakinya. Tangan tinggi dan langkah pendek — tembak; melayang ke arahmu — satu dribel melewati kaki depannya dan selesaikan. Maksimal dua dribel, jadi keputusan dibuat saat menangkap.",
                 "Pemain bertahan menghantar dan closeout; penyerang membaca kakinya. Tangan tinggi dan langkah pendek — jaring; meluru ke arah anda — satu dribel melepasi kaki depannya dan selesaikan.",
                 "กองหลังส่งบอลแล้วโคลสเอาท์ ฝ่ายบุกอ่านเท้าเขา มือสูงและก้าวสั้นให้ยิง ถ้าพุ่งใส่ให้เลี้ยงหนึ่งครั้งผ่านฝั่งเท้าหน้าแล้วจบ เลี้ยงได้มากสุดสองครั้ง จึงต้องตัดสินใจตอนรับบอล",
                 "Hậu vệ chuyền rồi áp sát; người tấn công đọc chân anh ta. Tay cao và bước ngắn — ném; lao bay tới — một nhịp dẫn qua phía chân trước rồi kết thúc. Tối đa hai nhịp dẫn, nên phải quyết định ngay lúc bắt bóng."),
              # The board opens on the catch: X1 has just thrown it out from
              # under the rim (a pass to an opponent would read as a steal).
              [("1", (0.86, 0.27), [(0.68, 0.08, 1)])],
              [("X1", (0.50, 0.10), [(0.78, 0.21, 0), (0.72, 0.12, 1)])],
              to=[(0, 1), (BASKET, 2)], free=True,
              minutes=10),
    ]
