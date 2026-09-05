"""The most common error for each drill family, in twelve languages.

A note says what to do; this says what actually goes wrong on the pitch —
the other half of the coaching point. Keyed by (sport, family name in
English); curated one-off drills may appear under their full English name.
Coverage of every family is enforced by the generator audit, so a new
family cannot ship without one.
"""

MISTAKES: dict[tuple[str, str], dict[str, str]] = {}

# Fallback by category, for curated one-off drills that are not part of a
# family. A family's own entry (keyed by its name) always wins; this is the
# floor so no card is ever blank. Keyed (sport, "cat:<category>").
BY_CATEGORY: dict[tuple[str, str], dict[str, str]] = {}


def cat(sport, category, en, zh, tw, ja, ko, es, fr, id_, ms, th, vi):
    BY_CATEGORY[(sport, f"cat:{category}")] = {
        "en": en, "en-GB": en, "zh-CN": zh, "zh-TW": tw, "ja-JP": ja,
        "ko-KR": ko, "es-ES": es, "fr-FR": fr, "id-ID": id_, "ms-MY": ms,
        "th-TH": th, "vi-VN": vi,
    }


def lookup(sport, family_or_name, category):
    return (MISTAKES.get((sport, family_or_name))
            or BY_CATEGORY.get((sport, f"cat:{category}"))
            or BY_CATEGORY.get(("*", f"cat:{category}")))



def add(sport, family, en, zh, tw, ja, ko, es, fr, id_, ms, th, vi):
    MISTAKES[(sport, family)] = {
        "en": en, "en-GB": en, "zh-CN": zh, "zh-TW": tw, "ja-JP": ja,
        "ko-KR": ko, "es-ES": es, "fr-FR": fr, "id-ID": id_, "ms-MY": ms,
        "th-TH": th, "vi-VN": vi,
    }

# ══ soccer ═══════════════════════════════════════════════════════════════════
add("soccer", "Rondo",
    "Standing still after the pass — the circle collapses into a polygon of statues.",
    "传完球站着不动——圈子塌成一圈雕像。", "傳完球站著不動——圈子塌成一圈雕像。",
    "パスの後に止まる——円が彫像の多角形に崩れる。",
    "패스 후 멈춰 선다 — 원이 조각상 다각형으로 무너진다.",
    "Quedarse quieto tras el pase: el círculo se derrumba en un polígono de estatuas.",
    "Rester immobile après la passe — le cercle s'effondre en polygone de statues.",
    "Berdiri diam setelah mengumpan.", "Berdiri kaku selepas menghantar.",
    "ยืนนิ่งหลังจ่ายบอล วงกลมพังเป็นรูปปั้น", "Đứng im sau khi chuyền — vòng tròn thành tượng.")
add("soccer", "Small-sided game",
    "Everyone chases the ball and the width dies — the game a coach stops first.",
    "所有人追着球跑，宽度没了——教练第一个要叫停的画面。",
    "所有人追著球跑，寬度沒了——教練第一個要叫停的畫面。",
    "全員がボールを追って幅が消える——コーチが最初に止める光景。",
    "모두가 공만 쫓아 폭이 죽는다 — 코치가 가장 먼저 멈추는 장면.",
    "Todos persiguen el balón y muere la amplitud: lo primero que un técnico para.",
    "Tout le monde court après le ballon et la largeur meurt.",
    "Semua mengejar bola dan lebar lapangan mati.",
    "Semua mengejar bola dan kelebaran mati.",
    "ทุกคนวิ่งไล่บอลจนความกว้างหายไป", "Cả đội đuổi theo bóng, chiều rộng biến mất.")
add("soccer", "Counter",
    "Taking one touch too many — the counter dies in the time a defender needs to turn.",
    "多带了那一脚——防守转身的功夫，反击就死了。",
    "多帶了那一腳——防守轉身的功夫，反擊就死了。",
    "1タッチ余計に運ぶ——守備が振り向く時間で速攻は死ぬ。",
    "터치 하나가 많다 — 수비가 도는 사이 역습은 죽는다.",
    "Un toque de más: el contragolpe muere en lo que un defensa tarda en girarse.",
    "Une touche de trop — le contre meurt le temps qu'un défenseur se retourne.",
    "Satu sentuhan berlebih dan serangan balik mati.",
    "Satu sentuhan berlebihan dan serangan balas mati.",
    "เลี้ยงเกินหนึ่งจังหวะ สวนกลับก็ตาย", "Thừa một nhịp chạm — phản công chết ngay.")
add("soccer", "Playing out under pressure",
    "Passing to a marked man because he is close — pressure is beaten forward, not sideways.",
    "因为近就传给被盯死的人——压迫要向前破解，不是横传躲开。",
    "因為近就傳給被盯死的人——壓迫要向前破解，不是橫傳躲開。",
    "近いからとマークされた選手に預ける——プレスは前進で剥がすもの。",
    "가깝다는 이유로 잡힌 선수에게 준다 — 압박은 전진으로 벗겨야 한다.",
    "Pasar al marcado porque está cerca: la presión se rompe hacia delante.",
    "Passer au joueur marqué parce qu'il est proche — la pression se bat vers l'avant.",
    "Mengumpan ke pemain terkawal hanya karena dekat.",
    "Menghantar kepada pemain terkawal kerana dekat.",
    "จ่ายให้คนที่โดนประกบเพียงเพราะอยู่ใกล้", "Chuyền cho người bị kèm chỉ vì gần.")
add("soccer", "Finishing pattern",
    "Shooting off the wrong foot to save a step — the pattern exists to give you the right one.",
    "为省一步用错误脚射门——这套配合就是为了让你用对的那只脚。",
    "為省一步用錯誤腳射門——這套配合就是為了讓你用對的那隻腳。",
    "一歩を惜しんで逆足で撃つ——正しい足で撃つためのパターンだ。",
    "한 걸음 아끼려 반대발로 쏜다 — 패턴은 맞는 발을 주려고 있다.",
    "Tirar con la pierna mala por ahorrar un paso: el patrón existe para darte la buena.",
    "Tirer du mauvais pied pour gagner un pas — le schéma existe pour donner le bon.",
    "Menembak dengan kaki salah demi hemat satu langkah.",
    "Menembak dengan kaki salah untuk jimat selangkah.",
    "ยิงด้วยเท้าผิดข้างเพื่อประหยัดหนึ่งก้าว", "Sút chân trái ý chỉ để đỡ một bước.")
add("soccer", "Press",
    "The first man sprints and the rest watch — a press of one is just a tired forward.",
    "第一个人冲了，其他人在看——一个人的压迫只是一个跑累的前锋。",
    "第一個人衝了，其他人在看——一個人的壓迫只是一個跑累的前鋒。",
    "1人目だけ走って残りが見ている——1人のプレスはただの疲れたFWだ。",
    "첫 번째만 뛰고 나머지는 본다 — 혼자의 압박은 지친 공격수일 뿐.",
    "El primero esprinta y el resto mira: una presión de uno es un delantero cansado.",
    "Le premier sprinte et les autres regardent — un pressing seul n'est qu'un attaquant fatigué.",
    "Orang pertama sprint, sisanya menonton.", "Orang pertama pecut, yang lain menonton.",
    "คนแรกพุ่ง คนอื่นยืนดู", "Người đầu lao lên, còn lại đứng nhìn.")
add("soccer", "Corner",
    "Watching the flight instead of the marker — you lose your man at the moment of the kick.",
    "盯着球的弧线看，忘了自己的人——开球那一瞬间就跟丢了。",
    "盯著球的弧線看，忘了自己的人——開球那一瞬間就跟丟了。",
    "ボールの軌道に見とれてマークを忘れる——キックの瞬間に人を失う。",
    "공의 궤적만 보다 마크를 놓친다 — 킥 순간에 사람을 잃는다.",
    "Mirar el vuelo y no a tu par: pierdes a tu hombre en el momento del golpeo.",
    "Regarder la trajectoire au lieu de son joueur — on perd son homme à la frappe.",
    "Menonton bola dan kehilangan pemain yang dijaga.",
    "Menonton bola dan kehilangan pemain jagaan.",
    "มัวมองบอลจนหลุดคนประกบ", "Mải nhìn bóng mà mất người kèm.")
add("soccer", "Free kick",
    "Everyone knows the routine except the one who sells it — the dummy jogs and the trick is naked.",
    "所有人都会这套战术，除了负责演戏的那个——假跑一慢，把戏就裸奔了。",
    "所有人都會這套戰術，除了負責演戲的那個——假跑一慢，把戲就裸奔了。",
    "囮だけが本気で走らない——それだけで仕掛けは丸裸になる。",
    "미끼만 대충 뛴다 — 그 순간 속임수는 발가벗는다.",
    "Todos saben la jugada menos quien debe venderla: el señuelo trota y el truco queda desnudo.",
    "Tout le monde connaît la combinaison sauf celui qui doit la vendre.",
    "Semua hafal polanya kecuali si penjual tipuan.",
    "Semua tahu polanya kecuali penjual tipuan.",
    "ทุกคนรู้แผนยกเว้นคนที่ต้องหลอก", "Ai cũng thuộc bài trừ người phải diễn.")
add("soccer", "Goal kick",
    "The keeper waits for movement and the movement waits for the keeper.",
    "门将在等跑位，跑位在等门将。", "門將在等跑位，跑位在等門將。",
    "GKは動き出しを待ち、動き出しはGKを待つ。",
    "키퍼는 움직임을 기다리고 움직임은 키퍼를 기다린다.",
    "El portero espera el desmarque y el desmarque espera al portero.",
    "Le gardien attend le mouvement et le mouvement attend le gardien.",
    "Kiper menunggu pergerakan dan pergerakan menunggu kiper.",
    "Penjaga gol menunggu pergerakan dan sebaliknya.",
    "ผู้รักษาประตูรอการวิ่ง การวิ่งก็รอผู้รักษาประตู", "Thủ môn chờ di chuyển, di chuyển chờ thủ môn.")
add("soccer", "Goalkeeping",
    "Saving with the feet planted — a keeper set too early is a wall with a hole in each corner.",
    "脚钉在地上扑救——站定太早的门将，就是一堵四角漏风的墙。",
    "腳釘在地上撲救——站定太早的門將，就是一堵四角漏風的牆。",
    "足を地面に固めたまま守る——早く構えすぎたGKは四隅に穴の空いた壁だ。",
    "발이 땅에 박힌 채 막는다 — 너무 일찍 선 키퍼는 네 귀퉁이가 뚫린 벽.",
    "Parar con los pies clavados: un portero colocado demasiado pronto es un muro con agujeros en las esquinas.",
    "Arrêter les pieds cloués au sol — un gardien figé trop tôt est un mur troué aux angles.",
    "Menyelamatkan dengan kaki terpaku.", "Menyelamat dengan kaki terpaku.",
    "เซฟทั้งที่เท้าปักอยู่กับที่", "Cản phá với đôi chân đóng đinh.")
add("soccer", "Heading",
    "Closing the eyes at contact — the header goes where the forehead points, and nobody aims blind.",
    "触球瞬间闭眼——头球飞向前额指的方向，闭着眼没人能瞄准。",
    "觸球瞬間閉眼——頭球飛向前額指的方向，閉著眼沒人能瞄準。",
    "当たる瞬間に目を閉じる——ヘディングは額の向きに飛ぶ。目を閉じて狙える者はいない。",
    "맞는 순간 눈을 감는다 — 헤딩은 이마가 향한 곳으로 간다.",
    "Cerrar los ojos en el contacto: el cabezazo va donde apunta la frente y nadie apunta a ciegas.",
    "Fermer les yeux au contact — la tête part où pointe le front.",
    "Menutup mata saat kontak.", "Memejam mata ketika kontak.",
    "หลับตาตอนโหม่ง ลูกไปตามหน้าผาก หลับตาเล็งไม่ได้", "Nhắm mắt lúc chạm bóng.")
add("soccer", "First touch",
    "Killing the ball dead under your feet — a perfect touch into your own shadow is still a lost tempo.",
    "把球停死在脚下——停进自己影子里的完美一停，也还是丢了一拍。",
    "把球停死在腳下——停進自己影子裡的完美一停，也還是丟了一拍。",
    "足元にピタリと止める——自分の影に止めた完璧なトラップも、テンポの損失だ。",
    "발밑에 죽여 놓는다 — 제 그림자 속의 완벽한 터치도 한 박자 손해다.",
    "Matar el balón bajo los pies: un control perfecto hacia tu propia sombra sigue perdiendo un tiempo.",
    "Tuer le ballon sous ses pieds — un contrôle parfait dans son ombre perd quand même un temps.",
    "Menghentikan bola mati di bawah kaki.", "Mematikan bola di bawah kaki.",
    "หยุดบอลตายใต้เท้า", "Ghìm chết bóng dưới chân.")
add("soccer", "Crossing",
    "Crossing to the crowd instead of the space — the runner attacks where defenders are not.",
    "传中传向人堆而不是空当——跑动的人要攻击没有防守的地方。",
    "傳中傳向人堆而不是空當——跑動的人要攻擊沒有防守的地方。",
    "人混みにクロスを上げる——ランナーが襲うのは守備のいない場所だ。",
    "수비 무리 속으로 크로스한다 — 러너는 수비 없는 곳을 공격한다.",
    "Centrar a la multitud y no al espacio.",
    "Centrer dans la foule au lieu de l'espace.",
    "Umpan silang ke kerumunan, bukan ke ruang.",
    "Silang ke kerumunan, bukan ke ruang.",
    "เปิดบอลเข้ากลุ่มคนแทนที่จะเปิดเข้าที่ว่าง", "Tạt vào đám đông thay vì khoảng trống.")
add("soccer", "Passing pattern",
    "Running the shape without scanning — patterns teach the pass, the head-check finds it in a game.",
    "只跑图形不观察——图形教你怎么传，比赛里靠回头看才找得到那条线。",
    "只跑圖形不觀察——圖形教你怎麼傳，比賽裡靠回頭看才找得到那條線。",
    "形をなぞるだけで首を振らない——形はパスを教え、首振りが試合でそれを見つける。",
    "고개 확인 없이 모양만 돈다 — 패턴은 패스를 가르치고, 스캔이 경기에서 그것을 찾는다.",
    "Correr el dibujo sin escanear: el patrón enseña el pase, mirar lo encuentra en el partido.",
    "Dérouler la figure sans scanner — le schéma apprend la passe, le regard la trouve en match.",
    "Menjalani pola tanpa memindai sekeliling.",
    "Menjalankan corak tanpa mengimbas.",
    "วิ่งตามรูปแบบโดยไม่หันมอง", "Chạy đúng hình mà không quan sát.")
add("soccer", "Switching play",
    "Switching through three short passes — by the third the far side has shifted with you.",
    "用三脚短传完成转移——传到第三脚，对面整条线已经跟着挪过去了。",
    "用三腳短傳完成轉移——傳到第三腳，對面整條線已經跟著挪過去了。",
    "短いパス3本でサイドを変える——3本目には逆サイドも移動し終えている。",
    "짧은 패스 셋으로 전환한다 — 세 번째엔 반대편도 이미 옮겨가 있다.",
    "Cambiar con tres pases cortos: al tercero el lado lejano ya se movió contigo.",
    "Renverser en trois passes courtes — à la troisième, l'autre côté a déjà coulissé.",
    "Memindah lewat tiga umpan pendek.", "Beralih melalui tiga hantaran pendek.",
    "เปลี่ยนข้างด้วยบอลสั้นสามจังหวะ", "Chuyển cánh bằng ba đường ngắn.")
add("soccer", "Combination play",
    "Both players improvising — a wall pass where neither knows who runs is a turnover with extra steps.",
    "两个人都在即兴——谁也不知道谁跑的撞墙配合，就是绕了个弯的丢球。",
    "兩個人都在即興——誰也不知道誰跑的撞牆配合，就是繞了個彎的丟球。",
    "2人とも即興——誰が走るか決まっていないワンツーは、回り道のロストだ。",
    "둘 다 즉흥 — 누가 뛰는지 모르는 원투는 돌아가는 턴오버다.",
    "Los dos improvisan: una pared sin saber quién corre es una pérdida con pasos de más.",
    "Les deux improvisent — un une-deux sans savoir qui court est une perte déguisée.",
    "Keduanya berimprovisasi.", "Kedua-duanya improvisasi.",
    "ต่างคนต่างด้น ไม่รู้ใครวิ่ง", "Cả hai cùng ứng biến — chẳng ai biết ai chạy.")
add("soccer", "1v1 duels",
    "Diving in on the first feint — the defender who bites decides the duel for the attacker.",
    "第一个假动作就出脚——扑上去的那一下，替进攻者赢了这次对抗。",
    "第一個假動作就出腳——撲上去的那一下，替進攻者贏了這次對抗。",
    "最初のフェイントに飛び込む——食いついた守備者が、対決の勝敗を攻撃者に献上する。",
    "첫 페인트에 달려든다 — 무는 순간 수비가 공격수 대신 승부를 정해준다.",
    "Tirarse al primer amago: el defensor que pica decide el duelo para el atacante.",
    "Plonger sur la première feinte — le défenseur qui mord décide le duel pour l'attaquant.",
    "Terpancing gerak tipu pertama.", "Terpedaya dengan tipuan pertama.",
    "พุ่งใส่จังหวะหลอกแรก", "Lao vào cú giả đầu tiên.")
add("soccer", "Defensive shape",
    "The line defends the ball instead of the space behind it.",
    "整条线在防球，而不是防身后的空当。", "整條線在防球，而不是防身後的空當。",
    "ラインがボールを守り、背後のスペースを守っていない。",
    "라인이 공을 막고, 그 뒤의 공간을 막지 않는다.",
    "La línea defiende el balón y no el espacio a su espalda.",
    "La ligne défend le ballon au lieu de l'espace derrière elle.",
    "Barisan menjaga bola, bukan ruang di belakangnya.",
    "Barisan menjaga bola, bukan ruang di belakang.",
    "ทั้งแนวเฝ้าบอลแทนที่จะเฝ้าพื้นที่ข้างหลัง", "Cả tuyến giữ bóng thay vì giữ khoảng trống sau lưng.")
add("soccer", "Transition",
    "Celebrating the win of the ball — the two seconds after a turnover are the whole drill.",
    "抢下球先高兴半秒——夺回球权后的那两秒，才是整个练习的意义。",
    "搶下球先高興半秒——奪回球權後的那兩秒，才是整個練習的意義。",
    "奪って満足する——ターンオーバー直後の2秒こそがこの練習のすべてだ。",
    "공 뺏고 자축한다 — 턴오버 직후 2초가 훈련의 전부다.",
    "Celebrar el robo: los dos segundos tras la recuperación son todo el ejercicio.",
    "Fêter la récupération — les deux secondes après le turnover sont tout l'exercice.",
    "Merayakan rebutan bola.", "Meraikan rampasan bola.",
    "ดีใจกับการแย่งบอลได้", "Ăn mừng khi vừa đoạt bóng.")
add("soccer", "Overload possession",
    "The spare man hides behind a defender — an overload you cannot pass to is arithmetic, not football.",
    "多出来的人藏在防守身后——传不到的多打少只是算术，不是足球。",
    "多出來的人藏在防守身後——傳不到的多打少只是算術，不是足球。",
    "余りの選手が守備の影に隠れる——パスの通らない数的優位はただの算数だ。",
    "남는 선수가 수비 뒤에 숨는다 — 줄 수 없는 수적 우위는 산수일 뿐.",
    "El hombre libre se esconde tras un defensa: una superioridad injugable es aritmética, no fútbol.",
    "L'homme libre se cache derrière un défenseur — un surnombre injouable n'est que de l'arithmétique.",
    "Pemain lebih bersembunyi di belakang bek.",
    "Pemain lebihan bersembunyi di belakang pemain bertahan.",
    "คนที่เกินไปแอบหลังกองหลัง", "Người dư nấp sau hậu vệ.")
add("soccer", "Conditioning with the ball",
    "Slowing the touch to survive the running — tired technique is the technique you will have in minute 88.",
    "为了扛住跑量放慢技术动作——疲劳下的技术，才是第 88 分钟你真正拥有的技术。",
    "為了扛住跑量放慢技術動作——疲勞下的技術，才是第 88 分鐘你真正擁有的技術。",
    "走りに耐えるためタッチを緩める——疲れた時の技術こそ88分に持っている技術だ。",
    "달리기를 버티려 터치를 늦춘다 — 지친 기술이 88분의 네 기술이다.",
    "Aflojar el toque para aguantar la carrera: la técnica cansada es la del minuto 88.",
    "Ralentir la touche pour tenir la course — la technique fatiguée est celle de la 88e minute.",
    "Memperlambat sentuhan demi bertahan lari.",
    "Melambatkan sentuhan untuk bertahan.",
    "ผ่อนเทคนิคเพื่อให้วิ่งไหว", "Chậm kỹ thuật lại để chịu nổi khối lượng chạy.")

# ══ basketball ═══════════════════════════════════════════════════════════════
add("basketball", "Ball screen",
    "Refusing the screen and dribbling away from it — the screener stood there for nothing.",
    "拒绝掩护往反方向运——掩护人白站了一趟。",
    "拒絕掩護往反方向運——掩護人白站了一趟。",
    "スクリーンを使わず逆へドリブル——スクリナーの立ち仕事が無駄になる。",
    "스크린을 안 쓰고 반대로 드리블 — 스크리너가 헛수고한다.",
    "Rechazar el bloqueo y botar en sentido contrario: el bloqueador posó para nada.",
    "Refuser l'écran et dribbler à l'opposé — le poseur a posé pour rien.",
    "Menolak screen dan menggiring menjauh.", "Menolak screen dan mengelecek menjauh.",
    "ไม่ใช้สกรีนแล้วเลี้ยงหนีไปอีกทาง", "Từ chối màn chắn, dẫn bóng đi hướng khác.")
add("basketball", "Cutting",
    "Cutting at jogging pace — a cut announces itself unless it starts at full speed.",
    "用慢跑的速度空切——不是全速起动的切入，等于提前广播。",
    "用慢跑的速度空切——不是全速起動的切入，等於提前廣播。",
    "ジョグの速さでカットする——全力で始めないカットは予告付きだ。",
    "조깅 속도로 컷한다 — 전속력이 아닌 컷은 예고편이다.",
    "Cortar al trote: un corte que no arranca a tope se anuncia solo.",
    "Couper au petit trot — une coupe qui ne démarre pas à fond s'annonce d'elle-même.",
    "Memotong dengan kecepatan joging.", "Memotong pada kelajuan berjoging.",
    "ตัดเข้าด้วยความเร็ววิ่งเหยาะ", "Cắt vào với tốc độ chạy bộ.")
add("basketball", "Shooting",
    "Drifting sideways on the catch — the shot you practised has feet under it.",
    "接球时身体横漂——你练过的那记投篮，脚是站在身体下面的。",
    "接球時身體橫漂——你練過的那記投籃，腳是站在身體下面的。",
    "キャッチで横に流れる——練習したシュートには足が下にあった。",
    "캐치하며 옆으로 흐른다 — 연습한 슛은 발이 몸 아래 있었다.",
    "Derivar lateralmente al recibir: el tiro que entrenaste tenía los pies debajo.",
    "Dériver latéralement à la réception — le tir travaillé avait les pieds dessous.",
    "Melayang ke samping saat menangkap.", "Terhanyut ke sisi ketika menangkap.",
    "ตัวลอยไปข้างตอนรับบอล", "Trôi ngang người lúc bắt bóng.")
add("basketball", "Post play",
    "Backing down forever — three dribbles into the seal, the double team has already arrived.",
    "无限背打——挤到第三次运球，包夹早就到了。",
    "無限背打——擠到第三次運球，包夾早就到了。",
    "延々と背中で押し込む——3ドリブル目には既にダブルチームが来ている。",
    "무한 등지기 — 드리블 셋이면 더블팀은 이미 와 있다.",
    "Empujar de espaldas sin fin: al tercer bote la ayuda ya llegó.",
    "Pousser dos au panier sans fin — au troisième dribble la prise à deux est là.",
    "Mendorong punggung tanpa henti.", "Menolak belakang tanpa henti.",
    "เบียดหลังไม่หยุด เลี้ยงสามครั้งโดนรุมแน่", "Tì lưng mãi — ba nhịp là bị vây.")
add("basketball", "Defence",
    "Two defenders guarding the ball and nobody guarding the promise — coverage is a pact, not a mood.",
    "两个人都去防球，没人守约定——挡拆防守是契约，不是临场情绪。",
    "兩個人都去防球，沒人守約定——擋拆防守是契約，不是臨場情緒。",
    "2人ともボールに行き、約束を守る者がいない——カバレッジは契約であって気分ではない。",
    "둘 다 공을 막고 약속은 아무도 안 지킨다 — 커버리지는 계약이지 기분이 아니다.",
    "Dos defienden el balón y nadie el pacto: la cobertura es un acuerdo, no un estado de ánimo.",
    "Deux sur le ballon et personne sur le pacte — la couverture est un contrat, pas une humeur.",
    "Dua orang menjaga bola, tak ada yang menjaga kesepakatan.",
    "Dua orang menjaga bola, tiada siapa menjaga janji.",
    "สองคนรุมบอล ไม่มีใครรักษาข้อตกลง", "Hai người kèm bóng, không ai giữ giao ước.")
add("basketball", "Transition",
    "The rebounder dribbles into traffic instead of hitting the outlet — the break dies at birth.",
    "抢下篮板往人堆里运，不找接应——快攻胎死腹中。",
    "搶下籃板往人堆裡運，不找接應——快攻胎死腹中。",
    "リバウンダーが密集へドリブル——アウトレットを飛ばした速攻は生まれる前に死ぬ。",
    "리바운더가 밀집으로 드리블 — 아웃렛 없는 속공은 태어나기 전에 죽는다.",
    "El reboteador bota hacia el tráfico en vez de dar el primer pase: el contraataque muere al nacer.",
    "Le rebondeur dribble dans le trafic au lieu de la relance — la contre-attaque meurt en naissant.",
    "Perebut bound menggiring ke kerumunan.", "Pengambil lantunan mengelecek ke kesesakan.",
    "คนเก็บรีบาวด์เลี้ยงเข้ากลางวง", "Người bắt bóng bật dẫn vào đám đông.")
add("basketball", "Inbounds",
    "The inbounder watches the first option die and panics — the count was five seconds when it started, too.",
    "发球人盯着第一选择消失然后慌了——五秒是从举球那刻开始数的。",
    "發球人盯著第一選擇消失然後慌了——五秒是從舉球那刻開始數的。",
    "スローワーが第1の選択肢が消えるのを見て慌てる——5秒は最初から5秒だった。",
    "인바운더가 1옵션이 죽는 걸 보다 당황한다 — 5초는 처음부터 5초였다.",
    "El sacador ve morir la primera opción y entra en pánico: los cinco segundos ya corrían.",
    "Le passeur regarde mourir la première option et panique — les cinq secondes couraient déjà.",
    "Pelempar menonton opsi pertama mati lalu panik.",
    "Pembaling menonton pilihan pertama mati lalu panik.",
    "คนส่งมองตัวเลือกแรกหายไปแล้วตื่น", "Người ném biên nhìn phương án một chết rồi cuống.")

# ══ volleyball ═══════════
# ── Category floors — the default when a curated one-off has no family ────────
cat("soccer", "warmup",
    "Going through the motions cold — the warm-up sets the standard the session keeps.",
    "冷着身子走过场——热身定的标准，整堂课都跟着走。",
    "冷著身子走過場——熱身定的標準，整堂課都跟著走。",
    "冷えたまま流す——ウォームアップが設けた基準を練習全体が引き継ぐ。",
    "몸이 식은 채 대충 — 웜업이 세운 기준을 세션 전체가 따른다.",
    "Hacerlo en frío y de trámite: el calentamiento fija el nivel de la sesión.",
    "Faire l'exercice à froid, machinalement — l'échauffement fixe le niveau de la séance.",
    "Sekadar formalitas saat masih dingin.", "Sekadar melepas batuk ketika masih sejuk.",
    "ทำแบบขอไปทีตอนตัวยังเย็น", "Làm cho có khi người còn nguội.")
cat("soccer", "possession",
    "Passing to feet when the pass into space was on — the safe ball keeps possession and goes nowhere.",
    "有向前的空当却往脚下传——保险球留住了球权，却哪也没去。",
    "有向前的空當卻往腳下傳——保險球留住了球權，卻哪也沒去。",
    "スペースへ通せるのに足元へ——安全なパスは保持はするが前進しない。",
    "공간으로 줄 수 있는데 발밑으로 — 안전한 패스는 점유만 하고 나아가지 않는다.",
    "Pasar a los pies cuando el pase al espacio estaba: el balón seguro conserva y no avanza.",
    "Passer dans les pieds quand la passe dans l'espace était là.",
    "Mengumpan ke kaki padahal ruang terbuka.", "Menghantar ke kaki sedangkan ruang terbuka.",
    "จ่ายเข้าเท้าทั้งที่มีช่องว่างข้างหน้า", "Chuyền vào chân khi có khoảng trống phía trước.")
cat("soccer", "attacking",
    "Waiting for the perfect ball — the run made late is a run defended easily.",
    "等一个完美的球——跑得晚的插上，防起来毫不费力。",
    "等一個完美的球——跑得晚的插上，防起來毫不費力。",
    "完璧なボールを待つ——遅れて出る動き出しは簡単に守られる。",
    "완벽한 볼을 기다린다 — 늦은 침투는 쉽게 막힌다.",
    "Esperar el balón perfecto: la desmarcada tardía se defiende sola.",
    "Attendre le ballon parfait — la course tardive se défend facilement.",
    "Menunggu bola sempurna.", "Menunggu bola sempurna.",
    "รอบอลที่สมบูรณ์แบบ", "Chờ đường bóng hoàn hảo.")
cat("soccer", "finishing",
    "Placing when power was on, blasting when placement was — the finish reads the keeper, not the coach.",
    "该发力时求角度，该求角度时猛轰——终结要读门将，不是读教练。",
    "該發力時求角度，該求角度時猛轟——終結要讀門將，不是讀教練。",
    "力むべき時に狙い、狙うべき時に力む——フィニッシュはGKを読むもの。",
    "힘 쓸 때 각을 노리고, 각 볼 때 세게 찬다 — 마무리는 코치가 아니라 키퍼를 읽는다.",
    "Colocar cuando tocaba potencia y reventarla cuando tocaba colocar: define leyendo al portero.",
    "Placer quand il fallait frapper, écraser quand il fallait placer.",
    "Menempatkan saat harus keras, dan sebaliknya.", "Meletak bila patut kuat, dan sebaliknya.",
    "จะยิงแรงก็เล็งมุม จะเล็งมุมก็ซัด", "Cần lực thì đặt, cần đặt thì phang.")
cat("soccer", "defending",
    "Reaching with a leg instead of moving the feet — the tackle you lunge for is the one you miss.",
    "用腿去够而不是挪脚——扑出去抢的那一下，正是你抢不到的那一下。",
    "用腿去夠而不是挪腳——撲出去搶的那一下，正是你搶不到的那一下。",
    "足を運ばず脚を伸ばす——飛び込むタックルこそ外すタックルだ。",
    "발을 옮기지 않고 다리를 뻗는다 — 달려드는 태클이 놓치는 태클이다.",
    "Estirar la pierna en vez de mover los pies: la entrada a la que te lanzas es la que fallas.",
    "Tendre la jambe au lieu de bouger les pieds — le tacle plongé est le tacle raté.",
    "Menjulurkan kaki alih-alih menggerakkannya.", "Menghulur kaki dan bukannya menggerakkannya.",
    "เอื้อมขาแทนที่จะขยับเท้า", "Với chân thay vì di chuyển chân.")
cat("soccer", "setpiece",
    "Improvising a rehearsed moment — the whole value of a set piece is that it was decided beforehand.",
    "把排练好的时刻临场发挥——定位球的全部价值，就在于它是事先定好的。",
    "把排練好的時刻臨場發揮——定位球的全部價值，就在於它是事先定好的。",
    "仕込んだ場面を即興でやる——セットプレーの価値は事前に決めてあること。",
    "연습한 순간을 즉흥으로 — 세트피스의 가치는 미리 정했다는 데 있다.",
    "Improvisar un momento ensayado: el valor de una jugada a balón parado es haberla decidido antes.",
    "Improviser un moment répété — tout l'intérêt d'un coup de pied arrêté est d'être décidé d'avance.",
    "Berimprovisasi di momen yang sudah dilatih.", "Berimprovisasi pada saat yang telah dilatih.",
    "ด้นสดในจังหวะที่ซ้อมมาแล้ว", "Ứng biến ở tình huống đã tập.")
cat("soccer", "ssg",
    "Playing the game and forgetting the constraint — the rule is the lesson, not an obstacle.",
    "只顾比赛忘了限制条件——那条规则才是课题，不是障碍。",
    "只顧比賽忘了限制條件——那條規則才是課題，不是障礙。",
    "ゲームに夢中で制約を忘れる——ルールこそが課題で、障害ではない。",
    "경기에 빠져 제약을 잊는다 — 규칙이 곧 과제다, 장애물이 아니라.",
    "Jugar y olvidar la condición: la regla es la lección, no un estorbo.",
    "Jouer et oublier la contrainte — la règle est la leçon, pas un obstacle.",
    "Bermain sampai lupa batasannya.", "Bermain sehingga lupa syaratnya.",
    "เล่นจนลืมกติกาที่ตั้งไว้", "Mải chơi mà quên điều kiện ràng buộc.")
add("basketball", "Ball screen", "Rejecting the screen out of habit — use it or the whole action was decoration.", "习惯性拒绝掩护——要用掉它，否则整个战术只是摆设。", "習慣性拒絕掩護——要用掉它，否則整個戰術只是擺設。", "習慣でスクリーンを断る——使わなければ全部が飾りだ。", "습관적으로 스크린을 거부한다 — 안 쓰면 전부 장식.", "Rechazar el bloqueo por costumbre: úsalo o toda la acción fue decoración.", "Refuser l'écran par habitude — sers-t'en, sinon tout n'était que décor.", "Menolak screen karena kebiasaan.", "Menolak screen kerana kebiasaan.", "ปฏิเสธสกรีนโดยเคยชิน", "Từ chối màn chắn theo thói quen.")
add("basketball", "Cutting", "Cutting when bored, not when the defender's head turns.", "站腻了才切，而不是趁防守扭头时切。", "站膩了才切，而不是趁防守扭頭時切。", "飽きたら切る——守備が顔を背けた瞬間ではなく。", "지루하면 컷 — 수비가 고개 돌릴 때가 아니라.", "Cortar por aburrimiento, no cuando el defensor gira la cabeza.", "Couper par ennui, pas quand le défenseur tourne la tête.", "Cut karena bosan, bukan saat penjaga menoleh.", "Cut kerana bosan, bukan ketika penjaga menoleh.", "ตัดเพราะเบื่อ ไม่ใช่ตอนคนประกบหันหน้า", "Cắt vì chán chứ không phải khi người kèm quay đầu.")
add("basketball", "Shooting", "Catching, then setting the feet — the closeout arrives in the time you take to organise.", "先接球再摆脚——你调整的功夫，扑防就到了。", "先接球再擺腳——你調整的功夫，撲防就到了。", "捕ってから足を作る——整える間にクローズアウトが来る。", "잡고 나서 발을 만든다 — 정리하는 사이 클로즈아웃이 온다.", "Recibir y luego colocar los pies: la ayuda llega mientras te organizas.", "Attraper puis placer les appuis — le contest arrive pendant que tu t'organises.", "Menangkap lalu baru menata kaki.", "Menangkap kemudian baru menyusun kaki.", "รับแล้วค่อยตั้งเท้า", "Bắt bóng rồi mới đặt chân.")
add("basketball", "Post play", "Fighting for position after the entry pass is already in the air.", "球都传到空中了才开始卡位。", "球都傳到空中了才開始卡位。", "エントリーパスが浮いてから位置を争う。", "엔트리 패스가 뜬 뒤에 자리를 다툰다.", "Pelear la posición cuando el pase interior ya va por el aire.", "Se battre pour la position une fois la passe déjà en l'air.", "Berebut posisi setelah umpan melayang.", "Berebut kedudukan selepas umpan melayang.", "แย่งตำแหน่งหลังบอลลอยแล้ว", "Tranh vị trí khi bóng đã bay tới.")
add("basketball", "Defence", "Two defenders assuming the other has the screen — say it out loud, every possession.", "两个防守人都以为对方去挡——每一回合都要喊出来。", "兩個防守人都以為對方去擋——每一回合都要喊出來。", "二人が互いに相手が対応すると思い込む——毎回声に出す。", "둘 다 상대가 스크린을 맡는다고 여긴다 — 매 소유마다 콜하라.", "Dos defensores creyendo que el otro cubre el bloqueo: dilo en voz alta cada posesión.", "Deux défenseurs comptant l'un sur l'autre — annonce-le à chaque possession.", "Dua pemain saling mengira yang lain menutup screen.", "Dua pemain saling menyangka yang lain menutup.", "สองคนต่างคิดว่าอีกคนรับสกรีน", "Hai người đều tưởng người kia lo màn chắn.")
add("basketball", "Transition", "Everyone follows the ball instead of filling the lanes.", "所有人跟着球跑，没人拉开跑道。", "所有人跟著球跑，沒人拉開跑道。", "全員がボールを追い、レーンを埋めない。", "모두 공만 따라가고 레인을 채우지 않는다.", "Todos siguen el balón en vez de llenar los carriles.", "Tout le monde suit le ballon au lieu de remplir les couloirs.", "Semua mengikuti bola, bukan mengisi jalur.", "Semua mengikut bola, bukan mengisi lorong.", "ทุกคนตามบอลแทนที่จะวิ่งเลน", "Ai cũng theo bóng thay vì lấp làn.")
add("basketball", "Inbounds", "The first cutter runs it like a decoy he does not believe in.", "第一个跑动的人当诱饵，自己都不信。", "第一個跑動的人當誘餌，自己都不信。", "最初のカッターが自分でも信じていない囮を走る。", "첫 커터가 스스로도 안 믿는 미끼를 뛴다.", "El primer cortador corre un señuelo que ni él se cree.", "Le premier coupeur joue un leurre auquel il ne croit pas.", "Pemotong pertama berlari sebagai umpan yang ia sendiri tak yakini.", "Pemotong pertama berlari sebagai umpan yang dia sendiri tak percaya.", "คนตัดคนแรกวิ่งหลอกแบบไม่เชื่อเอง", "Người cắt đầu chạy mồi mà chính mình không tin.")
add("badminton", "Footwork", "Splitting after the opponent hits, not before — late split, late shuttle.", "对手击球后才分腿，而不是之前——垫步晚，接球就晚。", "對手擊球後才分腿——墊步晚，接球就晚。", "相手が打ってから割る——遅れれば遅れたまま。", "상대가 친 뒤 스플릿 — 늦으면 늦은 채로.", "Hacer el split tras el golpe rival, no antes.", "Faire le split après la frappe adverse, pas avant.", "Split setelah lawan memukul, bukan sebelum.", "Split selepas lawan memukul, bukan sebelum.", "สปลิตหลังคู่แข่งตี ไม่ใช่ก่อน", "Bước tách sau khi đối thủ đánh.")
add("badminton", "Clear", "Clearing short — anything off the back line buys the opponent a smash.", "高远球不到位——差一点到底线，就送对手一记杀。", "高遠球不到位——差一點到底線，就送對手一記殺。", "クリアが短い——ラインに届かなければスマッシュを献上。", "클리어가 짧다 — 라인 못 미치면 스매시 헌납.", "Dejar el lob corto: fuera del fondo, regalas un remate.", "Dégagement trop court — hors de la ligne, tu offres un smash.", "Lob kurang dalam.", "Lob tak cukup dalam.", "ตีโด่งไม่ถึงเส้นหลัง", "Cầu cao không tới vạch cuối.")
add("badminton", "Drive rally", "Winding up big — the first big swing loses the exchange.", "抡大拍——谁先大挥谁输这一轮。", "掄大拍——誰先大揮誰輸這一輪。", "大振りする——先に大きく振った方が負ける。", "크게 휘두른다 — 먼저 크게 휘두르면 진다.", "Armar grande: el primer swing amplio pierde el intercambio.", "Armer grand — le premier grand geste perd l'échange.", "Mengayun besar.", "Menghayun besar.", "เหวี่ยงใหญ่", "Vung lớn.")
add("badminton", "Drop", "A swing that reads different from the clear — telegraphed, it comes back as a lift.", "挥拍和高远球不一样——被看穿的吊球，换回来一记挑球。", "揮拍和高遠球不一樣——被看穿的吊球，換回一記挑球。", "クリアと違う振り——読まれたドロップはロブで返る。", "클리어와 다른 스윙 — 읽히면 리프트로 돌아온다.", "Un gesto distinto al lob: cantada, la dejada vuelve como globo.", "Un geste différent du dégagement — lu, l'amorti revient en lob.", "Ayunan berbeda dari lob.", "Hayunan berbeza dari lob.", "วงสวิงต่างจากตีโด่ง", "Động tác khác quả cầu cao.")
add("badminton", "Smash", "Hitting from behind the body — the shuttle flattens and that is their wait.", "在身后击球——球变平，正是对手等的那拍。", "在身後擊球——球變平，正是對手等的那拍。", "体の後ろで打つ——球が平らになり待たれる。", "몸 뒤에서 친다 — 평평해져 상대가 기다린다.", "Golpear detrás del cuerpo: el volante sale plano y eso esperan.", "Frapper derrière le corps — le volant s'aplatit, c'est leur attente.", "Memukul di belakang badan.", "Memukul di belakang badan.", "ตีหลังตัว ลูกแบน", "Đánh sau người, cầu bị phẳng.")
add("badminton", "Net", "Letting the shuttle drop before you take it — every centimetre hands the point back.", "让球掉下来才接——掉一厘米就还一分。", "讓球掉下來才接——掉一釐米就還一分。", "落ちてから触る——落ちた分だけ点を返す。", "떨어진 뒤 잡는다 — 떨어질수록 점수를 돌려준다.", "Dejar caer el volante: cada centímetro devuelve el punto.", "Laisser tomber le volant — chaque centimètre rend le point.", "Membiarkan bola turun dulu.", "Membiarkan bola jatuh dahulu.", "ปล่อยลูกตกก่อนรับ", "Để cầu rơi mới đón.")
add("badminton", "Deception", "Adding a movement instead of a pause — deception is holding, not flourishing.", "多做一个动作而不是一个停顿——假动作是顶住，不是花哨。", "多做一個動作而不是一個停頓——假動作是頂住，不是花哨。", "間ではなく動作を足す——フェイントは「溜め」であって装飾ではない。", "멈춤 대신 동작을 더한다 — 페인트는 참는 것.", "Añadir un gesto en vez de una pausa: el engaño es retener, no adornar.", "Ajouter un geste au lieu d'une pause — la feinte, c'est retenir.", "Menambah gerakan, bukan jeda.", "Menambah gerakan, bukan jeda.", "เพิ่มท่าแทนการหน่วง", "Thêm động tác thay vì khoảng dừng.")
add("badminton", "Doubles", "Rotating late — the pair that turns slowly covers four corners with two.", "轮转慢——转得慢的一对用两人守四角。", "輪轉慢——轉得慢的一對用兩人守四角。", "ローテが遅い——遅いペアは2人で四隅を守る。", "로테이션이 느리다 — 느린 조는 둘이 네 구석을 지킨다.", "Rotar tarde: la pareja lenta cubre cuatro esquinas con dos.", "Tourner tard — la paire lente couvre quatre coins à deux.", "Rotasi lambat.", "Rotasi lambat.", "หมุนช้า", "Xoay vòng chậm.")
add("badminton", "Defence", "Racket down until the smash — defence is a stance you hold, not a reaction.", "杀球前拍子一直垂着——防守是姿势，不是反应。", "殺球前拍子一直垂著——防守是姿勢，不是反應。", "スマッシュまでラケットを下げている——守備は反応ではなく構え。", "스매시 전까지 라켓을 내린다 — 수비는 반응 아닌 자세.", "Raqueta baja hasta el remate: la defensa es una postura, no una reacción.", "Raquette basse jusqu'au smash — la défense est une posture.", "Raket turun sampai smes.", "Raket turun sehingga smesy.", "ไม้ตกจนกว่าจะโดนสแมช", "Vợt hạ tới lúc bị đập.")
add("badminton", "Serve", "Treating the one shot nobody can rush as if it did not matter.", "把唯一没人能逼你的一拍打得随随便便。", "把唯一沒人能逼你的一拍打得隨隨便便。", "誰にも急かされない一打を雑に扱う。", "아무도 못 몰아붙이는 샷을 대충 친다.", "Tratar el único golpe que nadie apura como si diera igual.", "Traiter le seul coup où nul ne te presse comme s'il ne comptait pas.", "Menyepelekan satu-satunya pukulan tanpa tekanan.", "Memandang ringan satu-satunya pukulan tanpa tekanan.", "เล่นลูกที่ไม่มีใครเร่งแบบชุ่ย", "Xem nhẹ cú duy nhất không ai ép.")
add("badminton", "Conditioned game", "Playing to win and forgetting the constraint that was the lesson.", "只想赢，忘了那条作为课题的限制。", "只想贏，忘了那條作為課題的限制。", "勝ちに行って課題の制約を忘れる。", "이기려다 과제인 제약을 잊는다.", "Jugar a ganar y olvidar la condición que era la lección.", "Jouer pour gagner et oublier la contrainte-leçon.", "Main untuk menang, lupa batasannya.", "Main untuk menang, lupa syaratnya.", "เล่นเอาชนะจนลืมกติกา", "Chơi để thắng mà quên điều kiện.")
# ── Generic category floors (sport "*") for every remaining one-off ──
cat("*", "warmup", "Going through the motions cold.", "冷着身子走过场。", "冷著身子走過場。", "冷えたまま流す。", "몸이 식은 채 대충.", "Hacerlo en frío, de trámite.", "Le faire à froid, machinalement.", "Sekadar formalitas saat dingin.", "Sekadar melepas batuk.", "ทำขอไปทีตอนตัวเย็น", "Làm cho có khi còn nguội.")
cat("*", "possession", "Taking the safe touch when the sharp one was on.", "该处理得果断时选了保险的一下。", "該處理得果斷時選了保險的一下。", "鋭い選択があるのに安全なタッチを選ぶ。", "날카로운 선택이 있는데 안전하게.", "Elegir el toque seguro cuando había uno agudo.", "Choisir la touche sûre quand la tranchante était là.", "Memilih sentuhan aman padahal ada yang tajam.", "Memilih sentuhan selamat sedangkan ada yang tajam.", "เลือกเล่นปลอดภัยทั้งที่มีทางคม", "Chọn xử lý an toàn khi có phương án sắc bén.")
cat("*", "attacking", "Forcing it early instead of waiting the half-second the opening needs.", "过早强行出手，不等空当需要的那半秒。", "過早強行出手，不等空當需要的那半秒。", "空きに必要な半秒を待たず早く仕掛ける。", "기회에 필요한 0.5초를 안 기다린다.", "Forzarla pronto en vez de esperar el medio segundo del hueco.", "Forcer trop tôt sans attendre la demi-seconde nécessaire.", "Memaksa terlalu dini.", "Memaksa terlalu awal.", "รีบทำเร็วเกินไป", "Ép quá sớm.")
cat("*", "finishing", "Deciding late — the finish is chosen before the ball arrives, not after.", "决定得太晚——终结在球到之前就该定好。", "決定得太晚——終結在球到之前就該定好。", "決断が遅い——フィニッシュは球が来る前に決める。", "늦게 정한다 — 마무리는 공 오기 전에.", "Decidir tarde: la definición se elige antes de que llegue el balón.", "Décider tard — la finition se choisit avant l'arrivée du ballon.", "Memutuskan terlambat.", "Membuat keputusan lewat.", "ตัดสินใจช้า", "Quyết định muộn.")
cat("*", "defending", "Reacting to the ball instead of holding the position.", "对着球做反应，而不是守住位置。", "對著球做反應，而不是守住位置。", "位置を保たずボールに反応する。", "자리를 지키지 않고 공에 반응한다.", "Reaccionar al balón en vez de mantener la posición.", "Réagir au ballon au lieu de tenir la position.", "Bereaksi pada bola alih-alih menjaga posisi.", "Bertindak balas kepada bola dan bukan menjaga kedudukan.", "รับตามบอลแทนที่จะรักษาตำแหน่ง", "Phản ứng theo bóng thay vì giữ vị trí.")
cat("*", "setpiece", "Improvising a moment whose value was that it was rehearsed.", "把价值在于排练的时刻临场发挥。", "把價值在於排練的時刻臨場發揮。", "仕込みが価値の場面を即興でやる。", "연습이 가치인 순간을 즉흥으로.", "Improvisar un momento cuyo valor era estar ensayado.", "Improviser un moment dont la valeur était d'être répété.", "Berimprovisasi di momen yang mestinya terlatih.", "Berimprovisasi pada saat yang sepatutnya terlatih.", "ด้นสดในจังหวะที่ควรซ้อม", "Ứng biến ở tình huống lẽ ra đã tập.")
cat("*", "ssg", "Playing to win and forgetting the constraint that was the lesson.", "只想赢，忘了那条作为课题的限制。", "只想贏，忘了那條作為課題的限制。", "勝ちに行って課題の制約を忘れる。", "이기려다 과제인 제약을 잊는다.", "Jugar a ganar y olvidar la condición que era la lección.", "Jouer pour gagner en oubliant la contrainte-leçon.", "Main untuk menang, lupa batasannya.", "Main untuk menang, lupa syaratnya.", "เล่นเอาชนะจนลืมกติกา", "Chơi để thắng mà quên điều kiện.")
add("volleyball", "Serve receive rotation", "A silent seam — the ball drops between two passers who both left it.", "结合部没人喊——球掉在两个都以为对方接的人中间。", "結合部沒人喊——球掉在兩個都以為對方接的人中間。", "無言の継ぎ目——互いに譲り合った2人の間に落ちる。", "조용한 이음새 — 서로 미룬 둘 사이로 떨어진다.", "Una costura muda: cae entre dos que la dejaron.", "Une couture muette — la balle tombe entre deux qui l'ont laissée.", "Celah tanpa panggilan.", "Celah tanpa panggilan.", "รอยต่อที่ไม่มีใครขาน", "Khe im lặng — bóng rơi giữa hai người.")
add("volleyball", "Setting", "Squaring the shoulders, not the hips — the hands lie about where the set goes, the hips cannot.", "对肩不对胯——手能骗人，胯骗不了。", "對肩不對胯——手能騙人，胯騙不了。", "肩を向けて腰を向けない——手は嘘をつくが腰はつけない。", "어깨만 맞추고 골반은 아니다 — 손은 속여도 골반은 못 속인다.", "Cuadrar hombros y no caderas: las manos mienten, las caderas no.", "Aligner les épaules, pas les hanches — les mains mentent, pas les hanches.", "Menghadapkan bahu, bukan pinggul.", "Menghadapkan bahu, bukan pinggul.", "หันไหล่ไม่หันสะโพก", "Xoay vai chứ không xoay hông.")
add("volleyball", "Setter release from zone", "Setting on the move — the ball goes where momentum went, not where the hitter is.", "带着惯性传球——球去了冲的方向，不是攻手的位置。", "帶著慣性傳球——球去了衝的方向，不是攻手的位置。", "動きながら上げる——勢いの方向へ配球する。", "움직이며 올린다 — 관성 방향으로 간다.", "Colocar en movimiento: la bola va hacia la inercia, no al rematador.", "Passer en mouvement — la balle part vers l'élan, pas vers l'attaquant.", "Umpan sambil bergerak.", "Umpan sambil bergerak.", "เซตขณะเคลื่อนที่", "Chuyền khi đang di chuyển.")
add("volleyball", "Attack", "Starting the approach early and drifting — the last two steps make the jump, not the first.", "助跑起太早还飘——起跳靠最后两步，不是第一步。", "助跑起太早還飄——起跳靠最後兩步，不是第一步。", "助走を早く出て流れる——跳躍は最後の2歩で決まる。", "조주를 일찍 나가 흘러간다 — 마지막 두 걸음이 점프를 만든다.", "Iniciar la carrera pronto y derivar: los dos últimos pasos hacen el salto.", "Partir tôt et dériver — les deux derniers appuis font le saut.", "Awalan terlalu dini dan melayang.", "Awalan terlalu awal dan melayang.", "ออกวิ่งเร็วแล้วลอย", "Chạy đà sớm rồi trôi.")
add("volleyball", "Block", "A double block with daylight in it — two players wasted on one gap.", "中间漏光的双人拦网——两个人白站。", "中間漏光的雙人攔網——兩個人白站。", "隙間の空いた2枚ブロック——2人の無駄。", "사이가 벌어진 2인 블록 — 두 명 낭비.", "Un bloqueo doble con luz: dos jugadoras desperdiciadas.", "Un double contre ajouré — deux joueuses gaspillées.", "Blok ganda bercelah.", "Blok ganda bercelah.", "บล็อกคู่มีช่องโหว่", "Chắn đôi hở sáng.")
add("volleyball", "Defence", "Still moving when the hitter contacts — a defender in motion is a spectator.", "对方击球时还在挪步——移动中的防守只是观众。", "對方擊球時還在挪步——移動中的防守只是觀眾。", "ヒットの瞬間に動いている——動く守備は観客だ。", "임팩트에 움직인다 — 움직이는 수비는 관중.", "Aún moviéndose en el contacto: un defensor en marcha es público.", "Encore en mouvement au contact — un défenseur qui bouge est spectateur.", "Masih bergerak saat kontak.", "Masih bergerak ketika kontak.", "ยังขยับตอนเขาตบ", "Còn di chuyển lúc chạm bóng.")
add("volleyball", "Serve", "Serving to the middle, safe — a free pass is a free kill for them.", "保险地发到中间——好接的球就是对方一次扣死。", "保險地發到中間——好接的球就是對方一次扣死。", "無難に真ん中へ——楽なパスは相手の決定打。", "안전하게 가운데로 — 편한 리시브는 상대 결정타.", "Sacar al centro, cómodo: una recepción fácil es un remate suyo.", "Servir au milieu, prudent — une réception facile est un point pour eux.", "Servis aman ke tengah.", "Servis selamat ke tengah.", "เสิร์ฟกลางแบบปลอดภัย", "Giao vào giữa cho an toàn.")
add("volleyball", "Transition", "Relaxing on the free ball — the easiest point in the sport, and the most dropped.", "调整球先松劲——全场最好得的一分，也是丢得最多的。", "調整球先鬆勁——全場最好得的一分，也是丟得最多的。", "フリーボールで緩む——最も簡単で最も落とす1点。", "프리볼에서 풀어진다 — 가장 쉽고 가장 자주 놓치는 점수.", "Relajarse en el balón libre: el punto más fácil y el más fallado.", "Se relâcher sur la balle libre — le point le plus facile et le plus perdu.", "Lengah pada bola bebas.", "Lengah pada bola bebas.", "ผ่อนตอนฟรีบอล", "Lơi lỏng ở bóng tự do.")
add("tennis", "Rally", "Recovering to the centre mark, not the middle of their angles — tidy, and wrong.", "回到中点标记而不是对手角度的中间——看着整齐，其实错了。", "回到中點標記而不是對手角度的中間——看著整齊，其實錯了。", "角度の中間ではなくセンターマークへ戻る——整って見えるが誤り。", "각도의 한가운데가 아니라 센터마크로 — 깔끔하지만 틀렸다.", "Recuperar a la marca central, no al medio de sus ángulos.", "Se replacer sur la marque centrale, pas au milieu des angles.", "Pulih ke tanda tengah, bukan tengah sudut lawan.", "Kembali ke tanda tengah, bukan tengah sudut lawan.", "กลับจุดกลางแทนกลางมุมคู่แข่ง", "Về vạch giữa thay vì giữa các góc.")
add("tennis", "Serve", "A toss that moves with the target — you announce the direction before you hit.", "抛球跟着落点走——击球前就报了方向。", "拋球跟著落點走——擊球前就報了方向。", "狙いに合わせて動くトス——打つ前にコースを教えている。", "목표 따라 움직이는 토스 — 치기 전에 코스를 알린다.", "Un lanzamiento que se mueve con el objetivo: cantas la dirección.", "Un lancer qui suit la cible — tu annonces la direction.", "Lambungan yang bergerak mengikuti target.", "Lambungan bergerak mengikut sasaran.", "โยนบอลตามเป้า บอกทางล่วงหน้า", "Tung bóng theo mục tiêu — lộ hướng trước.")
add("tennis", "Plus one", "Improvising the second ball — most points end on shot three, too early to wing it.", "临场想第二拍——大多数分第三拍就结束，来不及现编。", "臨場想第二拍——大多數分第三拍就結束，來不及現編。", "2球目を即興で——多くは3球目で終わる、アドリブには早い。", "둘째 공을 즉흥으로 — 대부분 3구에 끝난다.", "Improvisar la segunda bola: casi todo acaba en el tercer golpe.", "Improviser la deuxième balle — la plupart finissent au troisième coup.", "Improvisasi bola kedua.", "Improvisasi bola kedua.", "ด้นลูกที่สอง แต้มจบที่ลูกสาม", "Ứng biến quả hai — điểm kết ở quả ba.")
add("tennis", "At the net", "Volleying flat-footed — a volley hit standing still comes from wherever you stopped.", "站定了打截击——停着打的截击，从你恰好停下的地方来。", "站定了打截擊——停著打的截擊，從你恰好停下的地方來。", "止まってボレー——止まって打つ球は止まった場所から。", "멈춰서 발리 — 멈춘 자리에서 나온 공.", "Volear parado: una volea a pie firme sale de donde te paraste.", "Volée à l'arrêt — elle part d'où tu t'es arrêté.", "Voli sambil diam.", "Voli sambil berdiri.", "วอลเลย์ยืนนิ่ง", "Vô lê đứng yên.")
add("tennis", "Defending", "Going for angle on a defensive ball — short and wide is the last shot of the point.", "防守球求角度——又浅又偏，是这一分最后一拍。", "防守球求角度——又淺又偏，是這一分最後一拍。", "守備の球で角度を狙う——浅く広くはその点の最後。", "수비 공에 각을 노린다 — 짧고 넓으면 마지막 샷.", "Buscar ángulo en una bola defensiva: corta y abierta, último golpe.", "Chercher l'angle en défense — court et large, dernier coup du point.", "Mencari sudut pada bola bertahan.", "Mencari sudut pada bola bertahan.", "หาลูกมุมตอนตั้งรับ", "Tìm góc khi phòng thủ.")
add("tennis", "Doubles", "Moving as two, not one line — when your partner is pulled wide you watch instead of cross.", "两个人各动各的——同伴被拉边时你在看，不是补。", "兩個人各動各的——同伴被拉邊時你在看，不是補。", "一本の線でなく個々に動く——相棒が振られたら見ている。", "한 줄이 아니라 따로 움직인다 — 파트너가 밀리면 구경한다.", "Moverse por separado: cuando abren a tu compañero, miras.", "Bouger séparément — quand ton partenaire est écarté, tu regardes.", "Bergerak sendiri-sendiri.", "Bergerak sendiri-sendiri.", "ต่างคนต่างขยับ", "Di chuyển rời rạc.")
add("tennis", "Point play", "Not playing for real from the first ball — a drill you cannot lose teaches nothing.", "第一球起没当真打——输不掉的练习什么也教不了。", "第一球起沒當真打——輸不掉的練習什麼也教不了。", "1球目から本気でない——負けようのない練習は無意味。", "첫 공부터 진지하지 않다 — 질 수 없는 훈련은 무의미.", "No jugar en serio desde la primera: un ejercicio que no se pierde no enseña.", "Ne pas jouer sérieusement dès la première balle.", "Tidak sungguh-sungguh sejak bola pertama.", "Tidak bersungguh dari bola pertama.", "ไม่เอาจริงตั้งแต่ลูกแรก", "Không đánh thật từ quả đầu.")
add("tableTennis", "Footwork", "Reaching with the arm instead of the legs — every stretch was a ball you could step to.", "用手够而不是用腿——每个伸手够的球都来得及跨步。", "用手夠而不是用腿——每個伸手夠的球都來得及跨步。", "脚でなく腕で届かせる——伸ばした球は入れた球。", "팔로 뻗는다 — 뻗은 공은 갈 수 있던 공.", "Llegar con el brazo, no con las piernas.", "Aller avec le bras, pas les jambes.", "Menjangkau dengan lengan, bukan kaki.", "Menjangkau dengan lengan, bukan kaki.", "เอื้อมมือแทนขา", "Với tay thay vì di chân.")
add("tableTennis", "Rally control", "Backing off the table — every step back gives the far end half a second.", "退离球台——每退一步就送对面半秒。", "退離球台——每退一步就送對面半秒。", "台から下がる——一歩下がるごとに0.5秒渡す。", "탁구대에서 물러난다 — 한 발마다 0.5초.", "Alejarse de la mesa: cada paso atrás regala medio segundo.", "Reculer de la table — chaque pas offre une demi-seconde.", "Mundur dari meja.", "Berundur dari meja.", "ถอยห่างโต๊ะ", "Lùi xa bàn.")
add("tableTennis", "Short game", "Reaching from outside — a short ball taken from off the table goes long.", "站台外去够——从台外处理的短球会变长。", "站台外去夠——從台外處理的短球會變長。", "外から手を伸ばす——台外で取る短球は長くなる。", "밖에서 뻗는다 — 밖에서 처리한 짧은 공은 길어진다.", "Llegar desde fuera: una bola corta tomada lejos sale larga.", "Aller de l'extérieur — une balle courte prise hors table part longue.", "Menjangkau dari luar meja.", "Menjangkau dari luar meja.", "เอื้อมจากนอกโต๊ะ", "Với từ ngoài bàn.")
add("tableTennis", "Loop", "Hitting through the ball instead of brushing — against backspin, brush up and over.", "撞击而不是摩擦——对下旋要向上包裹摩擦。", "撞擊而不是摩擦——對下旋要向上包裹摩擦。", "こすらず押し抜く——下回転には薄くこすり上げる。", "때리고 감지 않는다 — 백스핀엔 위로 감아라.", "Golpear de lleno en vez de rozar.", "Percuter au lieu de frotter.", "Memukul tembus, bukan menggesek.", "Memukul tembus, bukan menggosok.", "กระแทกแทนปัด", "Đánh xuyên thay vì cọ.")
add("tableTennis", "Finishing", "Deciding the corner late — a sitter ends up three-quarter pace into the middle.", "选角犹豫——机会球变成七成力打中路。", "選角猶豫——機會球變成七成力打中路。", "コース決断が遅い——絶好球が七分で真ん中へ。", "코스를 늦게 정한다 — 찬스볼이 가운데로.", "Decidir la esquina tarde: un regalo acaba al medio.", "Décider le coin tard — une balle facile finit au milieu.", "Memilih sudut terlambat.", "Memilih sudut lewat.", "เลือกมุมช้า", "Chọn góc muộn.")
add("tableTennis", "Defending", "Returning the same spin — a chop that comes back unchanged is a ball hit harder next.", "旋转不变地回球——削球原样回去，下一板打得更重。", "旋轉不變地回球——削球原樣回去，下一板打得更重。", "同じ回転で返す——変わらぬカットは次に強打される。", "같은 회전으로 돌려준다 — 다음엔 더 세게 맞는다.", "Devolver el mismo efecto: un corte igual vuelve más fuerte.", "Renvoyer le même effet — un coupé inchangé revient plus fort.", "Mengembalikan spin yang sama.", "Mengembalikan putaran yang sama.", "คืนสปินเดิม", "Trả cùng độ xoáy.")
add("tableTennis", "Serve", "Serving without a planned third ball — a great serve with no plan wins one point by luck.", "发球没想好第三板——没计划的好发球只能靠运气赢一分。", "發球沒想好第三板——沒計劃的好發球只能靠運氣贏一分。", "3球目の計画なしのサーブ——狙いなき好サーブは運。", "서드볼 계획 없는 서브 — 운으로 1점.", "Sacar sin tercer bola planeada: sin plan, un punto de suerte.", "Servir sans troisième balle prévue — un point de chance.", "Servis tanpa rencana bola ketiga.", "Servis tanpa rancangan bola ketiga.", "เสิร์ฟไม่มีแผนลูกสาม", "Giao mà không tính quả ba.")
add("tableTennis", "Match play", "Trying to win by hitting harder — half-table games expose exactly that player.", "只想靠打得更重赢——半台对抗专治这种人。", "只想靠打得更重贏——半台對抗專治這種人。", "強打だけで勝とうとする——ハーフ台がそれを暴く。", "세게만 쳐서 이기려 한다 — 하프테이블이 드러낸다.", "Querer ganar pegando más fuerte: la media mesa lo desnuda.", "Vouloir gagner en frappant plus fort — la demi-table le démasque.", "Ingin menang dengan pukulan lebih keras.", "Mahu menang dengan pukulan lebih kuat.", "หวังชนะด้วยแรงตบ", "Chỉ muốn thắng bằng lực.")
add("handball", "Circulation", "Passing sideways instead of stepping at goal — six defenders stand still all attack.", "只横传不往门前迈步——六个防守整场站着不动。", "只橫傳不往門前邁步——六個防守整場站著不動。", "横パスばかりでゴールへ踏まない——6人が立ったまま。", "횡패스만 하고 골로 안 밟는다 — 여섯이 서 있다.", "Pasar en horizontal sin pisar hacia portería.", "Passer latéralement sans avancer vers le but.", "Umpan menyamping tanpa melangkah ke gawang.", "Hantar melintang tanpa melangkah ke gol.", "จ่ายข้างไม่ก้าวหาประตู", "Chuyền ngang mà không bước lên.")
add("handball", "Attack", "Crossing from a standstill — a cross that starts still moves no defender.", "站着不动就交叉——从静止开始的交叉调动不了防守。", "站著不動就交叉——從靜止開始的交叉調動不了防守。", "止まってクロス——静止からの交差は誰も動かせない。", "멈춘 채 교차 — 아무도 못 움직인다.", "Cruzar parado: un cruce sin arrancada no mueve a nadie.", "Croiser à l'arrêt — un croisé statique ne déplace personne.", "Menyilang dari diam.", "Bersilang dari diam.", "ไขว้จากจุดนิ่ง", "Cắt chéo từ tư thế đứng.")
add("handball", "Fast break", "Wings leaving on the outlet, not the save — half a second is the break.", "边锋等接到球才跑，不是扑到球就跑——就差那半秒。", "邊鋒等接到球才跑，不是撲到球就跑——就差那半秒。", "ウイングがセーブでなくパスで走る——その0.5秒が速攻。", "윙이 세이브가 아니라 패스에 뛴다 — 0.5초 차.", "Los extremos salen con el pase, no con la parada.", "Les ailiers partent sur la relance, pas sur l'arrêt.", "Sayap lari saat umpan, bukan penyelamatan.", "Pemain sayap lari ketika umpan, bukan penyelamatan.", "ปีกออกตอนจ่าย ไม่ใช่ตอนเซฟ", "Cánh chạy khi chuyền ra, không phải khi cản phá.")
add("handball", "Shooting", "Looking at the goal, not the keeper's feet — their weight tells you the open corner.", "看球门不看门将的脚——他的重心告诉你哪个角空。", "看球門不看門將的腳——他的重心告訴你哪個角空。", "ゴールを見てGKの足を見ない——重心が空く隅を教える。", "골대만 보고 골키퍼 발을 안 본다.", "Mirar la portería y no los pies del portero.", "Regarder le but, pas les appuis du gardien.", "Melihat gawang, bukan kaki kiper.", "Melihat gol, bukan kaki penjaga.", "ดูประตูไม่ดูเท้าผู้รักษา", "Nhìn khung thành, không nhìn chân thủ môn.")
add("handball", "Defence", "One defender stepping out alone — that is not pressure, it is an open gate.", "单独一个人上抢——那不是压迫，是开了一扇门。", "單獨一個人上搶——那不是壓迫，是開了一扇門。", "一人だけ前に出る——プレスではなく門を開ける。", "혼자 나간다 — 압박이 아니라 문 열기.", "Un defensor sale solo: no es presión, es una puerta.", "Un défenseur sort seul — ce n'est pas presser, c'est ouvrir.", "Satu bek maju sendiri.", "Seorang bek maju sendiri.", "คนเดียวออกไปกดดัน", "Một hậu vệ dâng lẻ.")
add("handball", "Set piece", "Three players still reading each other — a rehearsed play played by eye is wasted.", "三个人还在互相看——靠眼神打的定位球是浪费。", "三個人還在互相看——靠眼神打的定位球是浪費。", "3人が目で相談——仕込みを目で打つのは無駄。", "셋이 눈치 본다 — 눈으로 하는 세트는 낭비.", "Tres mirándose: una jugada ensayada leída con los ojos se pierde.", "Trois qui se cherchent du regard — une combinaison lue à l'œil est perdue.", "Tiga pemain saling membaca.", "Tiga pemain saling membaca.", "สามคนยังสบตากัน", "Ba người còn nhìn nhau.")
add("waterPolo", "Perimeter", "Passing behind the defender instead of across his face — the defence resets.", "从防守身后传球而不是身前——整条防线有时间重整。", "從防守身後傳球而不是身前——整條防線有時間重整。", "守備の前でなく後ろへ回す——守備が立て直す。", "수비 앞이 아니라 뒤로 — 수비가 정비한다.", "Pasar por detrás del defensor, no por delante.", "Passer derrière le défenseur au lieu de devant.", "Umpan di belakang bek, bukan di depan.", "Hantar di belakang bek, bukan di depan.", "จ่ายหลังกองหลังแทนหน้า", "Chuyền sau hậu vệ thay vì trước mặt.")
add("waterPolo", "Counter-attack", "Going on the rebound, not the shot — two strokes late is a set defence.", "等球弹出来才走，不是出手就走——晚两下就是阵地防守。", "等球彈出來才走，不是出手就走——晚兩下就是陣地防守。", "シュートでなくリバウンドで出る——2ストローク遅れれば守備が揃う。", "슛이 아니라 리바운드에 출발 — 두 스트로크 늦으면 세트 수비.", "Salir con el rechace, no con el tiro.", "Partir sur le rebond, pas sur le tir.", "Berangkat saat bola memantul, bukan saat tembakan.", "Bergerak ketika bola melantun, bukan tembakan.", "ออกตอนบอลกระดอน ไม่ใช่ตอนยิง", "Xuất phát khi bóng bật, không phải khi dứt điểm.")
add("waterPolo", "Centre forward", "Fighting for position after the pass — win it before the ball is thrown.", "传球后才拼位置——要在球传出前赢下来。", "傳球後才拼位置——要在球傳出前贏下來。", "パス後に位置を争う——投げる前に取る。", "패스 후 자리 다툼 — 던지기 전에.", "Pelear la posición tras el pase: gánala antes del lanzamiento.", "Lutter la position après la passe — gagne-la avant.", "Berebut posisi setelah umpan.", "Berebut kedudukan selepas umpan.", "แย่งตำแหน่งหลังส่งบอล", "Tranh vị trí sau đường chuyền.")
add("waterPolo", "Six on five", "Holding the ball past the fourth pass — the block recovers and the ejection is wasted.", "球过了第四传还不出手——封堵补回来，罚出白费。", "球過了第四傳還不出手——封堵補回來，罰出白費。", "4本目を過ぎても持つ——ブロックが戻り退水が無駄。", "네 번째 패스 넘겨 쥐고 있다 — 블록 복구, 퇴수 낭비.", "Retener más allá del cuarto pase: el bloque se recupera.", "Garder au-delà de la quatrième passe — le bloc se replace.", "Menahan lewat umpan keempat.", "Menahan melepasi umpan keempat.", "ถือเกินจ่ายที่สี่", "Giữ quá đường chuyền thứ tư.")
add("waterPolo", "Defence", "Two defenders each assuming the other has the centre — every 2m goal starts there.", "两个人都以为对方盯中锋——每个两米球都是这么丢的。", "兩個人都以為對方盯中鋒——每個兩米球都是這麼丟的。", "二人が互いにセンター担当と思う——2mの失点はそこから。", "둘 다 상대가 센터를 맡는다고 여긴다.", "Dos creyendo que el otro lleva al boya.", "Deux comptant l'un sur l'autre pour la pointe.", "Dua mengira yang lain menjaga center.", "Dua menyangka yang lain menjaga center.", "สองคนคิดว่าอีกคนดูเซ็นเตอร์", "Hai người tưởng người kia kèm trung phong.")
add("waterPolo", "Restart", "Waiting to play the free throw — the advantage lasts only while they turn.", "任意球慢慢来——优势只在对方转身那一瞬。", "任意球慢慢來——優勢只在對方轉身那一瞬。", "フリースローを待つ——優位は相手が振り向く間だけ。", "프리스로를 기다린다 — 이점은 돌아서는 동안만.", "Esperar para sacar el libre: la ventaja dura lo que tardan en girarse.", "Attendre pour jouer le coup franc — l'avantage ne dure que le retournement.", "Menunda lemparan bebas.", "Melengahkan lemparan bebas.", "รอเล่นฟรีโทรว์", "Chần chừ ném phạt.")
add("pickleball", "Dink", "Letting the dink rise — a ball above the net is a ball they attack.", "小球放高了——高过网的球就是被打死的球。", "小球放高了——高過網的球就是被打死的球。", "ディンクが浮く——ネットより高い球は叩かれる。", "딩크가 뜬다 — 네트 위 공은 맞는 공.", "Dejar subir el dink: una bola sobre la red la atacan.", "Laisser monter le dink — une balle au-dessus du filet est attaquée.", "Membiarkan dink naik.", "Membiarkan dink naik.", "ดิ้งก์ลอย", "Bỏ nhỏ bị nổi.")
add("pickleball", "Third shot", "Admiring the drop from the baseline — the third shot buys the walk to the kitchen; go.", "站底线欣赏自己的落球——第三拍换的是上网的步子，快上。", "站底線欣賞自己的落球——第三拍換的是上網的步子，快上。", "ベースラインでドロップに見とれる——3球目は前進を買う球。", "베이스라인에서 감상한다 — 서드샷은 전진을 산다.", "Admirar el drop desde el fondo: el tercer golpe compra la subida.", "Admirer le drop du fond — la troisième frappe paie la montée.", "Mengagumi drop dari garis belakang.", "Mengagumi drop dari garisan belakang.", "ยืนชมดรอปจากเส้นหลัง", "Đứng ngắm cú thả từ cuối sân.")
add("pickleball", "Speed-up", "Speeding up a low ball — you start a firefight from underneath.", "把低球加速——从下风位置主动开打。", "把低球加速——從下風位置主動開打。", "低い球を速くする——不利な位置から撃ち合いを始める。", "낮은 공을 빠르게 — 불리하게 난타 시작.", "Acelerar una bola baja: inicias un tiroteo en desventaja.", "Accélérer une balle basse — tu ouvres l'échange en dessous.", "Mempercepat bola rendah.", "Mempercepat bola rendah.", "เร่งลูกต่ำ", "Tăng tốc bóng thấp.")
add("pickleball", "Put-away", "Aiming at open court, not their feet — the court has a scramble in it, the feet do not.", "打空档不打脚——空档里藏着救球，脚下没有。", "打空檔不打腳——空檔裡藏著救球，腳下沒有。", "足元でなくオープンへ——空きには拾いが残る。", "발밑이 아니라 빈 코트로 — 빈 코트엔 수습이 남는다.", "Apuntar al hueco, no a los pies: el hueco admite carrera.", "Viser l'espace libre, pas les pieds — l'espace laisse une course.", "Membidik ruang kosong, bukan kaki.", "Membidik ruang kosong, bukan kaki.", "เล็งช่องว่างไม่เล็งเท้า", "Nhắm khoảng trống thay vì chân.")
add("pickleball", "Defending", "Blocking hard instead of soft — every hard reply hands them a second attack.", "硬挡而不是软挡——每次硬回都送对方第二次进攻。", "硬擋而不是軟擋——每次硬回都送對方第二次進攻。", "柔らかくでなく硬くブロック——硬い返球は2度目の攻撃を渡す。", "부드럽게가 아니라 세게 막는다 — 두 번째 공격을 준다.", "Bloquear duro en vez de blando: cada respuesta dura da otro ataque.", "Bloquer dur au lieu de doux — chaque réponse dure offre une 2e attaque.", "Blok keras alih-alih lembut.", "Blok keras dan bukannya lembut.", "บล็อกแข็งแทนที่จะนุ่ม", "Chắn mạnh thay vì mềm.")
add("pickleball", "Team shape", "Breaking the two-man line — the gap between you is the shot they want.", "破坏两人一线——你们之间的空当正是对手想打的。", "破壞兩人一線——你們之間的空當正是對手想打的。", "2人の線を崩す——間の隙間こそ相手の狙い。", "두 명의 선이 깨진다 — 그 틈이 상대의 노림수.", "Romper la línea de dos: el hueco entre vosotros es su golpe.", "Casser la ligne à deux — le trou entre vous est leur coup.", "Memecah garis dua orang.", "Memecahkan garisan dua orang.", "แนวสองคนขาด", "Đứt tuyến hai người.")
add("pickleball", "Serve and return", "A shallow serve or return — depth is what keeps them off the kitchen.", "发球或接发太浅——深度才能把对方挡在厨房外。", "發球或接發太淺——深度才能把對方擋在廚房外。", "浅いサーブやリターン——深さが相手を前に来させない。", "얕은 서브나 리턴 — 깊이가 상대를 막는다.", "Un saque o resto corto: la profundidad los aleja de la cocina.", "Un service ou retour court — la profondeur les tient loin de la cuisine.", "Servis atau pengembalian pendek.", "Servis atau pulangan pendek.", "เสิร์ฟหรือรับตื้น", "Giao hay trả nông.")
add("rugby", "Handling", "Passing behind the receiver — a pass behind turns a runner into a catcher.", "传到接球人身后——传身后就把跑动的人变成接球的人。", "傳到接球人身後——傳身後就把跑動的人變成接球的人。", "受け手の後ろへパス——後ろは走者を捕球者に変える。", "받는 사람 뒤로 — 러너를 캐처로 만든다.", "Pasar detrás del receptor: lo conviertes en receptor parado.", "Passer derrière le receveur — un coureur devient réceptionneur.", "Umpan di belakang penerima.", "Umpan di belakang penerima.", "ส่งหลังคนรับ", "Chuyền sau người nhận.")
add("rugby", "Phase play", "The pod still forming when the nine looks up is a pod that is not there.", "传球手抬头时还在集结的组，等于不存在。", "傳球手抬頭時還在集結的組，等於不存在。", "9番が顔を上げた時にまだ組んでいるポッドはいない。", "9번이 고개 들 때 아직 모이는 포드는 없는 것.", "Un pod que aún se forma cuando el 9 mira no existe.", "Un pod encore en formation quand le 9 lève la tête n'existe pas.", "Pod yang masih membentuk saat 9 melihat.", "Pod yang masih membentuk ketika 9 melihat.", "พ็อดที่ยังจัดตัวตอนสครัมฮาล์ฟเงย", "Pod còn đang tụ khi số 9 ngẩng lên.")
add("rugby", "Breakdown", "First support arriving upright and beside the ball — that is how a ruck becomes a turnover.", "第一个支援站直了停在球边——争球点就这么变成丢球。", "第一個支援站直了停在球邊——爭球點就這麼變成丟球。", "最初のサポートが立ったまま横に着く——ラックがターンオーバーに。", "첫 서포트가 선 채 옆에 붙는다 — 럭이 턴오버로.", "El primer apoyo llega erguido y al lado: así el ruck es pérdida.", "Le premier soutien arrive debout à côté — le ruck devient turnover.", "Bantuan pertama datang tegak di samping.", "Sokongan pertama datang tegak di sisi.", "คนช่วยคนแรกเข้าตัวตรงข้างบอล", "Người hỗ trợ đầu vào đứng thẳng bên bóng.")
add("rugby", "Backline move", "Not selling it with the first runner's line — the defence never has to believe.", "第一个跑动的人没把线路演真——防守根本不用信。", "第一個跑動的人沒把線路演真——防守根本不用信。", "最初のランナーのラインで売り込まない——守備は信じずに済む。", "첫 러너의 라인으로 안 판다 — 수비가 믿을 필요 없다.", "No venderlo con la línea del primero: la defensa no cree nada.", "Ne pas le vendre avec la course du premier — la défense n'y croit pas.", "Tidak menjualnya lewat pelari pertama.", "Tidak menjualnya melalui pelari pertama.", "ไม่ขายด้วยไลน์คนวิ่งแรก", "Không bán được bằng đường chạy người đầu.")
add("rugby", "Kicking", "Kicking with nobody chasing — a kick without a chase is a pass to the opposition.", "没人追就踢——没人追的踢球是传给对手。", "沒人追就踢——沒人追的踢球是傳給對手。", "誰も追わずに蹴る——チェイスなきキックは相手へのパス。", "아무도 안 쫓고 찬다 — 체이스 없는 킥은 상대에게 패스.", "Patear sin persecución: una patada sin caza es un pase al rival.", "Taper sans chasse — un coup de pied sans chasseur est une passe à l'adversaire.", "Menendang tanpa pengejar.", "Menyepak tanpa pengejar.", "เตะโดยไม่มีคนไล่", "Đá mà không ai đuổi.")
add("rugby", "Finishing", "Scoring wide when under the posts was on — the two points cost one extra second.", "能压门柱下却压在边上——那两分只要多花一秒。", "能壓門柱下卻壓在邊上——那兩分只要多花一秒。", "ポスト下に行けるのに外で置く——2点は1秒の差。", "골포스트 아래 갈 수 있는데 넓게 — 2점이 1초 차.", "Ensayar abierto pudiendo bajo palos: los dos puntos cuestan un segundo.", "Aplatir large alors que sous les poteaux était là.", "Mencetak di pinggir padahal bisa di bawah tiang.", "Menjaringkan di tepi walhal boleh di bawah tiang.", "วางบอลข้างทั้งที่ลงใต้เสาได้", "Ghi ở biên khi có thể dưới cột.")
add("rugby", "Defence", "One defender out of the wall — a hole, however good the tackle would have been.", "有一个人冒出防线——那就是个洞，不管擒抱本会多好。", "有一個人冒出防線——那就是個洞，不管擒抱本會多好。", "一人が壁から飛び出す——タックルが良くても穴。", "한 명이 벽에서 튀어나온다 — 태클이 좋아도 구멍.", "Un defensor fuera del muro: un agujero, por buena que fuera la placada.", "Un défenseur hors du mur — un trou, si bon qu'aurait été le plaquage.", "Satu bek keluar dari tembok.", "Seorang bek keluar dari tembok.", "คนเดียวหลุดกำแพง", "Một hậu vệ nhô khỏi hàng.")
add("rugby", "Set piece", "Running the play off slow ball — a clever move off slow possession is a slow move.", "慢球权上跑战术——慢球上的聪明配合就是慢配合。", "慢球權上跑戰術——慢球上的聰明配合就是慢配合。", "遅い球出しでプレー——遅い球からの巧手は遅い。", "느린 볼에서 사인 — 느린 볼의 영리한 수는 느린 수.", "Jugar sobre balón lento: una jugada lista con posesión lenta es lenta.", "Jouer sur ballon lent — une combinaison maligne sur ballon lent est lente.", "Menjalankan pola dari bola lambat.", "Menjalankan pola dari bola lambat.", "เล่นแผนจากบอลช้า", "Chạy bài từ bóng chậm.")
add("rugby", "Maul", "Driving with the ball at the front — one rip from a turnover.", "球在最前面就往前推——被抢一下就丢。", "球在最前面就往前推——被搶一下就丟。", "先頭にボールを置いて押す——一回のもぎ取りで終わり。", "공이 앞에 있는 채 민다 — 한 번 뜯기면 끝.", "Empujar con el balón delante: a un tirón de la pérdida.", "Pousser ballon devant — à un arrachage du turnover.", "Mendorong dengan bola di depan.", "Menolak dengan bola di hadapan.", "ดันโดยบอลอยู่หน้า", "Đẩy khi bóng ở phía trước.")
add("fieldHockey", "Building up", "Moving the ball forward before across — the defence slides one way, so go the other first.", "先纵后横——防守只能往一边滑，先横向调动它。", "先縱後橫——防守只能往一邊滑，先橫向調動它。", "横より先に前へ運ぶ——守備は片側にしか滑れない、先に横へ。", "앞보다 옆으로 먼저 — 수비는 한쪽으로만 슬라이드.", "Adelantar antes de mover en horizontal.", "Avancer avant de déplacer latéralement.", "Memajukan bola sebelum menyilang.", "Memajukan bola sebelum melintang.", "ดันหน้าก่อนย้ายข้าง", "Đưa lên trước khi chuyển ngang.")
add("fieldHockey", "Entering the circle", "Entering with both hands full and no support.", "两手占着、没人支援就冲进圈里。", "兩手占著、沒人支援就衝進圈裡。", "両手が塞がりサポートなしで入る。", "양손이 찬 채 지원 없이 들어간다.", "Entrar con las manos llenas y sin apoyo.", "Entrer les mains pleines sans soutien.", "Masuk dengan tangan penuh tanpa bantuan.", "Masuk dengan tangan penuh tanpa sokongan.", "เข้าวงมือเต็มไม่มีคนช่วย", "Vào vòng tay đầy, không hỗ trợ.")
add("fieldHockey", "Press", "A press that lets the ball switch across the pitch has pressed nobody.", "让球横传过场的压迫等于没压。", "讓球橫傳過場的壓迫等於沒壓。", "逆サイドへ渡すプレスは誰も追い込んでいない。", "반대편으로 넘기는 압박은 압박이 아니다.", "Una presión que deja cambiar el juego no presionó a nadie.", "Un pressing qui laisse renverser n'a pressé personne.", "Pressing yang membiarkan bola menyilang.", "Tekanan yang membiarkan bola melintang.", "กดดันแต่ปล่อยเปลี่ยนข้าง", "Gây áp lực mà để chuyển cánh.")
add("fieldHockey", "Shooting", "Hitting high and clean, not low with a body on the rebound — most goals are the second contact.", "打高打干净，不打低、不安排补射——大多数进球是第二下触球。", "打高打乾淨，不打低、不安排補射——大多數進球是第二下觸球。", "高く綺麗に打ちこぼれ球に人を置かない——得点の多くは2度目の触球。", "높고 깨끗하게, 리바운드에 사람 없이 — 대부분 두 번째 터치.", "Pegar alto y limpio sin nadie al rechace.", "Frapper haut et propre sans personne au rebond.", "Memukul tinggi bersih tanpa pemantul.", "Memukul tinggi bersih tanpa pemantul.", "ตีสูงสะอาดไม่มีคนตามเก็บ", "Đánh cao sạch mà không ai đón bóng bật.")
add("fieldHockey", "Penalty corner", "The stop is what fails — drill the trap on its own until it is boring.", "出问题的是停球——把停球单独练到无聊为止。", "出問題的是停球——把停球單獨練到無聊為止。", "失敗するのはストップ——トラップだけを退屈になるまで。", "실패하는 건 스톱 — 트래핑만 지겹도록.", "Lo que falla es la parada: entrena el control hasta aburrir.", "C'est le blocage qui échoue — travaille l'arrêt jusqu'à l'ennui.", "Yang gagal adalah stopnya.", "Yang gagal ialah hentiannya.", "สิ่งที่พลาดคือการหยุดบอล", "Khâu hỏng là dừng bóng.")
add("baseball", "Double play", "Rushing the throw instead of the feed — the feed makes the double play, not the arm.", "急着传球而不是急着送球——决定双杀的是那记送球，不是臂力。", "急著傳球而不是急著送球——決定雙殺的是那記送球，不是臂力。", "トスでなく送球を急ぐ——併殺を作るのはトス。", "송구를 서두른다 — 병살은 토스가 만든다.", "Apurar el tiro y no la entrega: el doble play lo hace la entrega.", "Précipiter le lancer, pas la transmission — c'est elle qui fait le double jeu.", "Terburu melempar, bukan mengumpan.", "Tergesa membaling, bukan menghantar.", "รีบขว้างแทนที่จะรีบส่งต่อ", "Vội ném thay vì vội chuyền.")
add("baseball", "Cut-off and relay", "A cut man nobody can see is a cut man nobody uses — line up and call loudly.", "看不见的中继人没人用——站到连线上，大声喊。", "看不見的中繼人沒人用——站到連線上，大聲喊。", "見えないカットマンは使われない——線上に立ち大声で。", "안 보이는 컷맨은 안 쓴다 — 선상에 서서 크게.", "Un cortador invisible no se usa: alinéate y pide a gritos.", "Un relayeur invisible ne sert pas — aligne-toi et appelle fort.", "Cut-off yang tak terlihat tak terpakai.", "Cut-off yang tak kelihatan tak digunakan.", "คนรับต่อที่มองไม่เห็นก็ไม่มีใครใช้", "Cắt bóng không ai thấy thì không ai dùng.")
add("baseball", "Baserunning", "Reading the ball, not the pitcher's heel — by the time you see the ball, it is decided.", "看球而不是看投手脚跟——等你看到球，决定已经做完了。", "看球而不是看投手腳跟——等你看到球，決定已經做完了。", "投手のかかとでなくボールを読む——見えた時には決している。", "공을 읽는다, 투수 뒤꿈치가 아니라 — 보이면 이미 끝.", "Leer la bola y no el talón del lanzador.", "Lire la balle, pas le talon du lanceur.", "Membaca bola, bukan tumit pelempar.", "Membaca bola, bukan tumit pembaling.", "อ่านบอลไม่อ่านส้นพิตเชอร์", "Đọc bóng thay vì gót người ném.")
add("baseball", "Scoring the run", "Deciding at the plate — a runner who decides late is thrown out at home.", "到本垒才决定——决定得晚的跑者在本垒被杀。", "到本壘才決定——決定得晚的跑者在本壘被殺。", "本塁で迷う——遅い判断は本塁で刺される。", "홈에서 정한다 — 늦으면 홈에서 잡힌다.", "Decidir en el plato: quien decide tarde muere en casa.", "Décider au marbre — celui qui décide tard est retiré au marbre.", "Memutuskan di home plate.", "Membuat keputusan di home plate.", "ตัดสินใจที่โฮม", "Quyết định ở chốt nhà.")
add("baseball", "Holding the runner", "Counting to the same number every time — you tell the runner when to leave.", "每次都数到同一个数——等于告诉跑者何时起跑。", "每次都數到同一個數——等於告訴跑者何時起跑。", "毎回同じ数を数える——走者に出発を教える。", "매번 같은 박자 — 주자에게 출발 신호.", "Contar siempre igual: le dices al corredor cuándo salir.", "Compter toujours pareil — tu dis au coureur quand partir.", "Menghitung sama setiap kali.", "Mengira sama setiap kali.", "นับจังหวะเดิมทุกครั้ง", "Đếm cùng nhịp mỗi lần.")
add("baseball", "Defending the situation", "Silence before the pitch — two fielders end up covering the same base.", "投球前没人说话——两个野手守同一个垒。", "投球前沒人說話——兩個野手守同一個壘。", "投球前の沈黙——二人が同じベースに入る。", "투구 전 침묵 — 둘이 같은 베이스.", "Silencio antes del lanzamiento: dos cubren la misma base.", "Silence avant le lancer — deux couvrent le même but.", "Hening sebelum lemparan.", "Senyap sebelum balingan.", "เงียบก่อนขว้าง", "Im lặng trước khi ném.")
add("baseball", "Situational scrimmage", "Playing with no count and no outs set — practice without a situation is nine watching one.", "不设球数和出局数就打——没情境的练习是九个人看一个。", "不設球數和出局數就打——沒情境的練習是九個人看一個。", "カウントもアウトも決めず打つ——状況なしは9人が1人を見る。", "카운트·아웃 없이 — 상황 없는 연습은 아홉이 하나 구경.", "Jugar sin cuenta ni outs: sin situación, nueve miran a uno.", "Jouer sans compte ni retraits — sans situation, neuf en regardent un.", "Bermain tanpa count dan out.", "Bermain tanpa count dan out.", "เล่นโดยไม่ตั้งเคานต์และเอาต์", "Chơi mà không đặt bóng và loại.")
add("sepakTakraw", "Serve", "Serving to the middle where anyone reaches it — go at the weak surface.", "发到谁都够得到的中间——要打对手不擅长的部位。", "發到誰都夠得到的中間——要打對手不擅長的部位。", "誰でも届く真ん中へ——苦手な部位を狙う。", "누구나 닿는 가운데로 — 약한 부위를 노려라.", "Sacar al centro donde todos llegan: busca la superficie débil.", "Servir au milieu accessible — vise la surface faible.", "Servis ke tengah yang mudah dijangkau.", "Servis ke tengah yang mudah dicapai.", "เสิร์ฟกลางที่ใครก็รับได้", "Giao vào giữa ai cũng đỡ.")
add("sepakTakraw", "Tekong serve", "A toss that drifts — the tekong's foot cannot fix an inconsistent throw.", "抛球飘忽——发球手那只脚补不了不稳定的抛球。", "拋球飄忽——發球手那隻腳補不了不穩定的拋球。", "トスがぶれる——テコンの足では不安定な投げを直せない。", "토스가 흔들린다 — 테콩의 발로는 못 고친다.", "Un lanzamiento inestable: el pie del tekong no lo arregla.", "Un lancer instable — le pied du tekong ne rattrape pas.", "Lambungan yang goyah.", "Lambungan yang tidak stabil.", "การโยนที่ไม่นิ่ง", "Cú tung chao đảo.")
add("sepakTakraw", "Feeding", "Feeding where the striker is, not where his foot will be — perfect height, wrong place.", "把球传到扣球手现在的位置，不是脚将到的位置——高度对，位置错。", "把球傳到扣球手現在的位置，不是腳將到的位置——高度對，位置錯。", "今いる場所へ上げる——高さは合っても場所が違う。", "지금 자리에 올린다 — 높이는 맞고 위치가 틀리다.", "Pasar donde está y no donde estará su pie.", "Passer où il est, pas où sera son pied.", "Umpan ke tempat sekarang, bukan tempat kaki akan berada.", "Umpan ke tempat kini, bukan tempat kaki akan berada.", "ชงตรงที่ยืน ไม่ใช่ตรงที่เท้าจะไป", "Chuyền nơi họ đứng, không phải nơi chân sẽ tới.")
add("sepakTakraw", "Serve receive", "A flat first touch — cushion upward so the feeder can reach it.", "一传停平了——要向上卸力，让二传赶得到。", "一傳停平了——要向上卸力，讓二傳趕得到。", "1タッチ目が平ら——上へ吸収してトサーが間に合うように。", "첫 터치가 평평 — 위로 죽여 토서가 닿게.", "Un primer toque plano: amortigua arriba para que llegue el pasador.", "Une première touche plate — amortis vers le haut.", "Sentuhan pertama datar.", "Sentuhan pertama rata.", "สัมผัสแรกแบน", "Chạm đầu bị phẳng.")
add("sepakTakraw", "Spiking", "Kicking from below the ball — get the hips above it before the foot swings.", "在球下方起脚——起脚前先把胯送到球上方。", "在球下方起腳——起腳前先把胯送到球上方。", "ボールの下から蹴る——足を振る前に腰を上へ。", "공 아래에서 찬다 — 발 휘두르기 전 골반을 위로.", "Golpear desde debajo: lleva la cadera por encima antes de golpear.", "Frapper sous la balle — hisse les hanches au-dessus d'abord.", "Menendang dari bawah bola.", "Menyepak dari bawah bola.", "เตะจากใต้ลูก", "Đá từ dưới bóng.")
add("sepakTakraw", "Attacking", "Not reading the block on the way up — three touches leave no time to decide on the ground.", "起跳时不看拦网——三次触球没时间落地再想。", "起跳時不看攔網——三次觸球沒時間落地再想。", "跳びながらブロックを見ない——3タッチは地上で考える暇なし。", "뜨면서 블록을 안 본다 — 세 번엔 지상에서 정할 시간 없다.", "No leer el bloqueo al subir.", "Ne pas lire le contre en montant.", "Tidak membaca blok saat naik.", "Tidak membaca blok ketika naik.", "ไม่อ่านบล็อกตอนลอย", "Không đọc hàng chắn khi bật lên.")
add("sepakTakraw", "Defending", "Reacting to the spike instead of reading the setter — nobody digs a takraw kill by reflex.", "对着扣杀做反应而不是读二传——藤球扣死没人靠反射救得起。", "對著扣殺做反應而不是讀二傳——藤球扣死沒人靠反射救得起。", "セッターでなくスパイクに反応——反射では拾えない。", "세터가 아니라 스파이크에 반응 — 반사로는 못 막는다.", "Reaccionar al remate y no leer al colocador.", "Réagir à l'attaque au lieu de lire le passeur.", "Bereaksi pada smes, bukan membaca tosser.", "Bertindak balas pada rejaman, bukan membaca tosser.", "รับตามลูกฟาดแทนอ่านเซตเตอร์", "Phản xạ theo cú đá thay vì đọc chuyền.")
add("footvolley", "Ball control", "A first touch that lands anywhere on your side, not where the setter can use it.", "第一脚停在本方随便一处，不是二传用得上的位置。", "第一腳停在本方隨便一處，不是二傳用得上的位置。", "自陣のどこかに落ちる1タッチ——上げられる場所ではなく。", "자기 쪽 아무 데나 — 세터가 쓸 곳이 아니라.", "Un primer toque en cualquier sitio, no donde el pasador lo use.", "Une première touche n'importe où dans ton camp.", "Sentuhan pertama jatuh sembarang.", "Sentuhan pertama jatuh merata.", "สัมผัสแรกตกที่ไหนก็ได้", "Chạm đầu rơi bừa bên mình.")
add("footvolley", "Receiving", "Changing surface mid-flight — the first touch flies to the crowd.", "球飞到一半换部位——一传飞进观众席。", "球飛到一半換部位——一傳飛進觀眾席。", "空中で部位を変える——レシーブが観客席へ。", "공중에서 부위를 바꾼다 — 관중석으로.", "Cambiar de superficie en pleno vuelo.", "Changer de surface en plein vol.", "Mengganti bagian tubuh saat bola melayang.", "Menukar bahagian badan ketika bola melayang.", "เปลี่ยนส่วนรับกลางอากาศ", "Đổi bộ phận giữa chừng.")
add("footvolley", "Setting up", "A set that drifts over the net — you hand away the one thing you had, the choice.", "传球飘过网——把你唯一的东西送掉：选择权。", "傳球飄過網——把你唯一的東西送掉：選擇權。", "ネットを越えて流れるトス——唯一の武器、選択を手放す。", "네트 넘어가는 토스 — 유일한 선택권을 넘긴다.", "Una colocación que se va sobre la red: regalas la elección.", "Une passe qui dérive au-dessus du filet — tu offres le choix.", "Umpan yang melayang melewati net.", "Umpanan yang melepasi jaring.", "เซตลอยข้ามเน็ต", "Chuyền trôi qua lưới.")
add("footvolley", "Combination", "A silent set at the net — a coin flip over who attacks.", "网前不出声的传球——谁进攻全靠抛硬币。", "網前不出聲的傳球——誰進攻全靠拋硬幣。", "ネット際の無言トス——誰が打つかコイントス。", "네트에서 조용한 토스 — 누가 칠지 동전 던지기.", "Una colocación muda en la red: cara o cruz sobre quién ataca.", "Une passe muette au filet — pile ou face sur l'attaquant.", "Umpan diam di net.", "Umpanan senyap di jaring.", "เซตเงียบหน้าเน็ต", "Chuyền im ở lưới.")
add("footvolley", "Finishing", "Hitting from below net height — an attack under the tape is a free ball with steps.", "低于网高击球——低于网带的进攻是绕弯的调整球。", "低於網高擊球——低於網帶的進攻是繞彎的調整球。", "ネットより低く打つ——白帯下の攻撃は手間をかけたフリーボール。", "네트보다 낮게 친다 — 번거로운 프리볼.", "Golpear bajo la red: un ataque bajo la cinta es un balón libre con pasos.", "Frapper sous le filet — une attaque sous la bande est une balle libre.", "Memukul di bawah tinggi net.", "Memukul di bawah ketinggian jaring.", "ตีต่ำกว่าเน็ต", "Đánh dưới mép lưới.")
add("footvolley", "Defending", "Both at the net or both back — two players cannot defend a court twice.", "两个人都在网前或都在后场——两个人没法把一块场地防两遍。", "兩個人都在網前或都在後場——兩個人沒法把一塊場地防兩遍。", "二人ともネットか二人とも後ろ——二人で一つのコートは二度守れない。", "둘 다 네트 또는 둘 다 뒤 — 한 코트를 두 번 못 지킨다.", "Los dos en la red o los dos atrás: dos no defienden una pista dos veces.", "Les deux au filet ou les deux au fond — à deux, pas deux fois.", "Keduanya di net atau keduanya di belakang.", "Kedua-duanya di jaring atau di belakang.", "อยู่หน้าทั้งคู่หรือหลังทั้งคู่", "Cả hai lên lưới hoặc cả hai lùi.")
add("footvolley", "Serve", "A serve they take on the foot — height is the weapon here, not power.", "让对手用脚接的发球——这里的武器是高度，不是力量。", "讓對手用腳接的發球——這裡的武器是高度，不是力量。", "足で受けさせるサーブ——武器は高さで力ではない。", "발로 받게 하는 서브 — 무기는 높이지 힘이 아니다.", "Un saque que toman con el pie: aquí el arma es la altura.", "Un service pris du pied — ici l'arme est la hauteur.", "Servis yang mereka ambil dengan kaki.", "Servis yang diambil dengan kaki.", "เสิร์ฟที่เขารับด้วยเท้า", "Cú giao họ đỡ bằng chân.")
add("beachTennis", "Volley rally", "Waiting for a bounce that never comes — the racket must be up before they hit.", "在等一个不会来的落地——对方击球前拍子就要举好。", "在等一個不會來的落地——對方擊球前拍子就要舉好。", "来ないバウンドを待つ——相手が打つ前にラケットを上げる。", "오지 않는 바운드를 기다린다 — 치기 전에 라켓을.", "Esperar un bote que no llega: la raqueta arriba antes del golpe.", "Attendre un rebond qui ne vient pas — raquette haute avant la frappe.", "Menunggu pantulan yang tak datang.", "Menunggu lantunan yang tak datang.", "รอการกระดอนที่ไม่มา", "Chờ cú nảy không tới.")
add("beachTennis", "Return", "Blocking short — a shallow return lets the server take the net first.", "接发挡短——回球太浅让发球方先上网。", "接發擋短——回球太淺讓發球方先上網。", "浅くブロック——浅いリターンはサーバーに先にネットを取らせる。", "짧게 막는다 — 얕은 리턴은 서버가 먼저 네트.", "Bloquear corto: un resto flojo deja la red al sacador.", "Bloquer court — un retour mou laisse le filet au serveur.", "Blok pendek.", "Blok pendek.", "บล็อกสั้น", "Chặn ngắn.")
add("beachTennis", "Serve", "A serve above their waist — anything they meet high, they meet comfortably.", "发到对手腰以上——他们高点接到的球都接得很舒服。", "發到對手腰以上——他們高點接到的球都接得很舒服。", "腰より上へのサーブ——高く取れる球は楽に返される。", "허리 위로 — 높게 잡으면 편하게 받는다.", "Un saque por encima de la cintura: lo alto lo devuelven cómodos.", "Un service au-dessus de la taille — pris haut, il revient facile.", "Servis di atas pinggang.", "Servis di atas pinggang.", "เสิร์ฟสูงกว่าเอว", "Giao trên thắt lưng.")
add("beachTennis", "Attacking", "Hanging back when a ball is up — the pair closer to the net wins the exchange.", "有高球却不上前——离网更近的一对赢下这一轮。", "有高球卻不上前——離網更近的一對贏下這一輪。", "浮き球で下がる——ネットに近いペアが勝つ。", "떠 있는데 물러난다 — 네트에 가까운 조가 이긴다.", "Quedarse atrás con una bola alta: gana la pareja más cerca de la red.", "Rester en retrait sur une balle haute — la paire proche du filet gagne.", "Diam di belakang saat bola melambung.", "Berdiam di belakang saat bola tinggi.", "ถอยตอนบอลลอย", "Lùi khi bóng nổi.")
add("beachTennis", "Smash", "Aiming at a sideline, not the gap between them — the gap moves with them, the line does not.", "打边线不打两人之间——空当会跟着人动，边线不会。", "打邊線不打兩人之間——空當會跟著人動，邊線不會。", "サイドラインを狙う——隙間は動くがラインは動かない。", "사이드라인을 노린다 — 틈은 움직이고 라인은 안 움직인다.", "Apuntar a la línea, no al hueco: el hueco se mueve, la línea no.", "Viser la ligne, pas l'écart — l'écart bouge, la ligne non.", "Membidik garis, bukan celah.", "Membidik garisan, bukan celah.", "เล็งเส้นข้างไม่เล็งช่องกลาง", "Nhắm vạch biên thay vì khe giữa.")
add("beachTennis", "Lob battle", "Lobbing with the wind at your back — the same lob downwind is a feed.", "顺风放高球——顺风的同一个高球是喂球。", "順風放高球——順風的同一個高球是餵球。", "追い風でロブ——追い風の同じロブは餌だ。", "등바람에 로브 — 순풍의 로브는 먹이.", "Globear a favor del viento: el mismo globo downwind es comida.", "Lober vent dans le dos — le même lob vent portant est une offrande.", "Lob searah angin.", "Lob mengikut angin.", "ลอบตามลม", "Bổng theo chiều gió.")
add("beachTennis", "Court coverage", "Two rackets meeting in the middle — call it before the point, the middle is the forehand's.", "两把拍子在中间相撞——分前说好，中路归正手。", "兩把拍子在中間相撞——分前說好，中路歸正手。", "真ん中でラケットが2本——ポイント前に決める、中央はフォア。", "가운데서 라켓 둘 — 포인트 전에, 가운데는 포핸드.", "Dos palas en el centro: decídelo antes, el medio es de la derecha.", "Deux raquettes au centre — décide avant, le milieu au coup droit.", "Dua raket bertemu di tengah.", "Dua raket bertemu di tengah.", "สองไม้ชนกลาง", "Hai vợt gặp giữa sân.")
