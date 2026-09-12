"""The basketball library."""
from .engine import Drill, M, P, ring, suffixed


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
            # Follow the pass, one beat behind it, and stop 82% of the way —
            # queue behind the receiver, do not stand on him. Ending on his
            # exact point (and on the same beat as the pass) stacked every
            # pair dead centre, the same rotation defect as the passing
            # diamond.
            home=[
                P(0.500, 0.340, "1", moves=[(0.344, 0.565, 1)]),
                P(0.177, 0.451, "2", moves=[(0.585, 0.590, 4)]),
                P(0.300, 0.629, "3", moves=[(0.708, 0.490, 2)]),
                P(0.700, 0.629, "4"),
                P(0.823, 0.451, "5", moves=[(0.319, 0.451, 3)]),
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


def basketball_library() -> list[Drill]:
    from .engine import merge
    return merge(basketball_drills(), ball_screen_family(), cut_family(),
                 shooting_family(), post_family(), defence_family(),
                 shell_drill(), transition_family(), inbounds_family(), gaps_family())

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


