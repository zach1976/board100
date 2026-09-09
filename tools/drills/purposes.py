"""The 目的 section of a drill's note — what it trains and why it matters.

A note now says how to set the drill up (组织), where the ball goes (球路),
what happens beat by beat (流程) and the one thing to coach (要点). What it did
not say was the first thing a coach asks: what am I training here, and why.

Purpose is keyed by category, because a warm-up trains the same thing whatever
the sport, and so does a possession or a finishing drill. Where a category
means something genuinely different in a family of sports — "attacking" is
breaking a defence in team ball, but winning the point in a net sport — the
GROUP override says so. Every drill gets a purpose automatically from its
category; no per-drill authoring.

Twelve locales, the set the drills ship, never machine-translated.
"""
from __future__ import annotations

# Which purpose vocabulary a sport draws on. A net/racket sport rallies to win
# a point; a goal sport attacks a goal; baseball is its own game of bases.
NET_SPORTS = {"badminton", "tennis", "tableTennis", "pickleball",
              "beachTennis", "footvolley", "sepakTakraw", "volleyball"}
BASEBALL = {"baseball"}
# everything else (soccer, basketball, handball, rugby, hockey, water polo)
# is a team goal-scoring game and takes the default.


def _P(en, zh, zht, ja, ko, es, fr, idn, ms, th, vi):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht, "ja-JP": ja,
            "ko-KR": ko, "es-ES": es, "fr-FR": fr, "id-ID": idn, "ms-MY": ms,
            "th-TH": th, "vi-VN": vi}


# ── default (team goal sports) ───────────────────────────────────────────────
DEFAULT = {
    "warmup": _P(
        "Raise the heart rate and sharpen touch before the load comes; it "
        "sets the standard the session keeps.",
        "在负荷到来前提升心率、找回球感；它定下整堂课的标准。",
        "在負荷到來前提升心率、找回球感；它定下整堂課的標準。",
        "負荷が来る前に心拍を上げ、ボールタッチを整える。練習全体の基準を作る。",
        "본격적인 부하 전에 심박수를 올리고 볼 감각을 살린다. 세션 전체의 기준을 세운다.",
        "Eleva pulsaciones y afina el toque antes de la carga; fija el nivel de la sesión.",
        "Élève le rythme cardiaque et affine la touche avant la charge ; fixe le niveau de la séance.",
        "Menaikkan detak jantung dan menajamkan sentuhan sebelum beban; menetapkan standar sesi.",
        "Menaikkan degupan jantung dan menajamkan sentuhan sebelum beban; menetapkan piawaian sesi.",
        "เพิ่มอัตราหัวใจและปรับสัมผัสบอลก่อนโหลดหนัก และตั้งมาตรฐานของการฝึก",
        "Tăng nhịp tim và làm nhạy cảm giác bóng trước khi vào tải; đặt chuẩn cho cả buổi."),
    "possession": _P(
        "Keep the ball under pressure — support angles, first touch and the "
        "pass that beats a line rather than just the nearest man.",
        "在压迫下保住球——支应角度、第一脚触球，以及能穿透防线而不只是传给最近人的那一脚。",
        "在壓迫下保住球——支應角度、第一腳觸球，以及能穿透防線而不只是傳給最近人的那一腳。",
        "プレッシャー下でボールを保持する。サポートの角度、ファーストタッチ、そして最も近い味方ではなくラインを破るパス。",
        "압박 속에서 공을 지킨다. 지원 각도, 첫 터치, 그리고 가까운 동료가 아니라 수비 라인을 깨는 패스.",
        "Conservar el balón bajo presión: ángulos de apoyo, control y el pase que rompe una línea, no solo al más cercano.",
        "Conserver le ballon sous pression : angles de soutien, première touche et la passe qui casse une ligne.",
        "Menjaga bola di bawah tekanan — sudut dukungan, sentuhan pertama, dan umpan yang menembus garis.",
        "Mengekalkan bola di bawah tekanan — sudut sokongan, sentuhan pertama, dan hantaran yang menembusi barisan.",
        "รักษาบอลภายใต้แรงกดดัน — มุมสนับสนุน สัมผัสแรก และบอลที่เจาะแนวรับ",
        "Giữ bóng dưới áp lực — góc hỗ trợ, xử lý chạm đầu, và đường chuyền xuyên tuyến."),
    "attacking": _P(
        "Break a set defence: create and use an overload, commit a defender, "
        "and play the pass his movement opens.",
        "破解站好位的防守：制造并利用局部人数优势，逼防守人做决定，再打他移动让出的那条传球线。",
        "破解站好位的防守：製造並利用局部人數優勢，逼防守人做決定，再打他移動讓出的那條傳球線。",
        "整った守備を崩す。数的優位を作って使い、守備者に決断を迫り、その動きが空けたパスを通す。",
        "정돈된 수비를 깬다. 수적 우위를 만들고 이용하며, 수비수에게 결정을 강요하고 그 움직임이 여는 패스를 넣는다.",
        "Romper una defensa colocada: crea y usa la superioridad, obliga al defensa a decidir y juega el pase que abre su movimiento.",
        "Casser une défense en place : créer et exploiter le surnombre, engager un défenseur et jouer la passe que son mouvement ouvre.",
        "Membongkar pertahanan yang tersusun: buat dan manfaatkan overload, paksa bek memutuskan, lalu mainkan umpan yang terbuka.",
        "Memecahkan pertahanan tersusun: cipta dan guna lebihan pemain, paksa bek membuat keputusan, mainkan hantaran yang terbuka.",
        "เจาะแนวรับที่ตั้งรับ: สร้างและใช้ความได้เปรียบจำนวน บังคับกองหลังให้ตัดสินใจ แล้วจ่ายบอลที่เปิดออก",
        "Phá vỡ hàng thủ đã dựng: tạo và tận dụng hơn người, buộc hậu vệ quyết định, rồi chuyền vào khoảng trống mở ra."),
    "defending": _P(
        "Deny space as a unit — the whole line shifts with the ball, closes "
        "the pass on either side of the presser, and covers behind.",
        "作为整体压缩空间——整条线随球移动，封住上抢者两侧的传球线，并在身后补位。",
        "作為整體壓縮空間——整條線隨球移動，封住上搶者兩側的傳球線，並在身後補位。",
        "組織として空間を消す。ラインが球に合わせてスライドし、プレスした選手の両脇のパスを封じ、背後をカバーする。",
        "조직적으로 공간을 지운다. 라인 전체가 공을 따라 이동하고, 압박한 선수 양옆의 패스를 막고, 뒤를 커버한다.",
        "Negar el espacio como bloque: la línea bascula con el balón, cierra el pase a ambos lados del que presiona y cubre por detrás.",
        "Refuser l'espace en bloc : la ligne coulisse avec le ballon, ferme la passe de chaque côté du presseur et couvre derrière.",
        "Menutup ruang sebagai satu unit — seluruh garis bergeser mengikuti bola, menutup umpan di kedua sisi penekan, dan menutup di belakang.",
        "Menafikan ruang sebagai satu unit — seluruh barisan bergerak mengikut bola, menutup hantaran di kedua-dua sisi penekan, dan melindungi di belakang.",
        "ปิดพื้นที่เป็นทีม — ทั้งแนวขยับตามบอล ปิดบอลสองข้างของคนที่ขึ้นบีบ และคุมด้านหลัง",
        "Bịt không gian như một khối — cả tuyến dịch theo bóng, chặn đường chuyền hai bên người áp sát, và bọc lót phía sau."),
    "finishing": _P(
        "Turn a chance into a goal: arrive with the feet set, strike early "
        "and low, and hit the space rather than the shirt.",
        "把机会转化为进球：到位时脚步站好，早出脚、打低平球，瞄准空当而不是人。",
        "把機會轉化為進球：到位時腳步站好，早出腳、打低平球，瞄準空檔而不是人。",
        "チャンスを得点に変える。足を作って到達し、早く低く打ち、人ではなくスペースを狙う。",
        "기회를 골로 바꾼다. 발을 갖춰 도착하고, 빠르고 낮게 슛하며, 사람이 아니라 공간을 노린다.",
        "Convertir la ocasión en gol: llegar con los apoyos puestos, rematar pronto y raso, y buscar el espacio, no la camiseta.",
        "Transformer l'occasion en but : arriver appuis posés, frapper tôt et à ras de terre, viser l'espace et non le maillot.",
        "Mengubah peluang jadi gol: tiba dengan kaki siap, tembak cepat dan rendah, arahkan ke ruang bukan ke pemain.",
        "Menukar peluang jadi gol: tiba dengan kaki bersedia, tembak awal dan rendah, arah ke ruang bukan pemain.",
        "เปลี่ยนโอกาสเป็นประตู: มาถึงโดยตั้งเท้าพร้อม ยิงเร็วและต่ำ เล็งพื้นที่ไม่ใช่ตัวคน",
        "Biến cơ hội thành bàn thắng: đến nơi với chân đã sẵn, dứt điểm sớm và sệt, nhắm khoảng trống chứ không nhắm người."),
    "setpiece": _P(
        "Rehearse a restart until it runs without a word — everyone knows the "
        "movement before the whistle, so the delivery, not the decision, is the "
        "hard part.",
        "把定位球演练到不用说话就能跑——哨响前每个人都知道跑位，难的只是传球质量，而不是临场决定。",
        "把定位球演練到不用說話就能跑——哨響前每個人都知道跑位，難的只是傳球質量，而不是臨場決定。",
        "セットプレーを声なしで回るまで反復する。笛の前に全員が動きを知っているから、難しいのは配球であって判断ではない。",
        "세트피스를 말 없이 돌아갈 때까지 반복한다. 휘슬 전에 모두가 움직임을 알기에 어려운 건 배급이지 판단이 아니다.",
        "Ensayar la jugada a balón parado hasta que salga sin hablar: todos saben el movimiento antes del pitido; lo difícil es el envío, no la decisión.",
        "Répéter le coup de pied arrêté jusqu'à ce qu'il tourne sans un mot : chacun connaît le mouvement avant le sifflet ; le difficile, c'est la transmission.",
        "Melatih bola mati sampai jalan tanpa kata — semua tahu pergerakan sebelum peluit; yang sulit adalah pengiriman, bukan keputusan.",
        "Melatih bola mati sehingga berjalan tanpa sepatah kata — semua tahu pergerakan sebelum wisel; yang sukar ialah penghantaran, bukan keputusan.",
        "ซ้อมลูกตั้งเตะจนเล่นได้โดยไม่ต้องพูด — ทุกคนรู้การเคลื่อนที่ก่อนเป่านกหวีด สิ่งที่ยากคือการจ่าย ไม่ใช่การตัดสินใจ",
        "Tập bóng cố định đến khi chạy không cần nói — ai cũng biết di chuyển trước tiếng còi; cái khó là đường bóng, không phải quyết định."),
    "ssg": _P(
        "A small-sided game: fewer players, so the ball and every decision "
        "arrive faster and nobody can hide from the play.",
        "小场比赛：人少，球和每个决定都来得更快，谁也躲不开比赛。",
        "小場比賽：人少，球和每個決定都來得更快，誰也躲不開比賽。",
        "ミニゲーム。人数が少ない分、ボールも判断も速く来て、誰もプレーから隠れられない。",
        "미니 게임: 인원이 적어 공과 모든 결정이 더 빨리 오고, 누구도 플레이에서 숨을 수 없다.",
        "Juego reducido: menos jugadores, así el balón y cada decisión llegan antes y nadie se esconde.",
        "Jeu réduit : moins de joueurs, donc le ballon et chaque décision arrivent plus vite et personne ne se cache.",
        "Permainan skala kecil: pemain lebih sedikit, jadi bola dan setiap keputusan datang lebih cepat dan tak ada yang bisa sembunyi.",
        "Permainan kecil: pemain lebih sedikit, jadi bola dan setiap keputusan datang lebih cepat dan tiada siapa boleh menyorok.",
        "เกมสนามเล็ก: คนน้อยลง บอลและทุกการตัดสินใจมาเร็วขึ้น และไม่มีใครหลบเกมได้",
        "Trò chơi sân nhỏ: ít người hơn nên bóng và mọi quyết định đến nhanh hơn, không ai trốn khỏi trận đấu được."),
    "goalkeeping": _P(
        "Train the keeper's craft — set before the strike, take the angle, "
        "and start the next attack with the first pass out.",
        "训练门将的基本功——出脚前先站定、封好角度，并用第一脚出球发动下一次进攻。",
        "訓練門將的基本功——出腳前先站定、封好角度，並用第一腳出球發動下一次進攻。",
        "GKの技術を鍛える。シュート前に構え、角度を切り、最初のパスで次の攻撃を始める。",
        "골키퍼의 기술을 훈련한다. 슛 전에 자세를 잡고 각을 좁히며, 첫 패스로 다음 공격을 시작한다.",
        "Entrenar el oficio del portero: colocado antes del disparo, cerrar el ángulo y empezar el ataque con la primera salida.",
        "Travailler le métier du gardien : placé avant la frappe, fermer l'angle et lancer l'attaque dès la première relance.",
        "Melatih keahlian kiper — set sebelum tembakan, ambil sudut, dan mulai serangan dengan umpan pertama.",
        "Melatih kemahiran penjaga gol — sedia sebelum tendangan, ambil sudut, dan mulakan serangan dengan hantaran pertama.",
        "ฝึกทักษะผู้รักษาประตู — ตั้งหลักก่อนยิง ปิดมุม และเริ่มบุกด้วยการจ่ายแรก",
        "Rèn kỹ năng thủ môn — đứng vững trước cú sút, khép góc, và mở đợt tấn công bằng đường chuyền đầu tiên."),
    "conditioning": _P(
        "Build match fitness with the ball, so technique holds when the legs "
        "are tired — which is when the game is decided.",
        "带球练体能，让腿累了技术动作也不散——而比赛正是在那时候被决定的。",
        "帶球練體能，讓腿累了技術動作也不散——而比賽正是在那時候被決定的。",
        "ボールを使って試合の体力を作る。脚が疲れても技術が崩れないように。試合はそこで決まる。",
        "공을 가지고 경기 체력을 기른다. 다리가 지쳐도 기술이 무너지지 않도록 — 경기는 그때 결정된다.",
        "Construir fondo con balón para que la técnica aguante con las piernas cansadas, que es cuando se decide el partido.",
        "Développer le physique avec le ballon, pour que la technique tienne jambes lourdes — c'est là que le match se décide.",
        "Membangun kebugaran main dengan bola, agar teknik bertahan saat kaki lelah — saat itulah pertandingan ditentukan.",
        "Membina kecergasan dengan bola, supaya teknik bertahan ketika kaki penat — ketika itulah perlawanan ditentukan.",
        "สร้างความฟิตกับบอล เพื่อให้เทคนิคยังอยู่เมื่อขาล้า ซึ่งเป็นตอนที่เกมถูกตัดสิน",
        "Xây thể lực thi đấu cùng bóng, để kỹ thuật vẫn vững khi chân đã mỏi — đó là lúc trận đấu được định đoạt."),
}

# ── net / racket sports: attacking, defending and finishing mean the rally ───
NET = {
    "attacking": _P(
        "Take control of the rally — move the opponent, open the court, and "
        "force the ball you want to attack.",
        "掌控回合——调动对手、拉开场地，制造出你想进攻的那个球。",
        "掌控回合——調動對手、拉開場地，製造出你想進攻的那個球。",
        "ラリーの主導権を握る。相手を動かし、コートを開き、攻めたいボールを引き出す。",
        "랠리의 주도권을 잡는다. 상대를 움직이고 코트를 열어 원하는 공을 끌어낸다.",
        "Tomar el control del peloteo: mover al rival, abrir la pista y provocar la bola que quieres atacar.",
        "Prendre le contrôle de l'échange : déplacer l'adversaire, ouvrir le court et provoquer la balle à attaquer.",
        "Menguasai reli — menggerakkan lawan, membuka lapangan, dan memaksa bola yang ingin diserang.",
        "Menguasai rali — menggerakkan lawan, membuka gelanggang, dan memaksa bola yang ingin diserang.",
        "ควบคุมการโต้ — ขยับคู่ต่อสู้ เปิดคอร์ต และบังคับให้ได้ลูกที่อยากบุก",
        "Kiểm soát pha bóng — di chuyển đối thủ, mở sân, và ép ra quả bóng muốn tấn công."),
    "defending": _P(
        "Stay in the rally under pressure — reset from defence, buy time, and "
        "turn the point back to neutral before you attack again.",
        "在压力下保住回合——从被动中稳住、争取时间，把球势拉回均势再重新进攻。",
        "在壓力下保住回合——從被動中穩住、爭取時間，把球勢拉回均勢再重新進攻。",
        "プレッシャー下でラリーに残る。守備から立て直し、時間を作り、再び攻める前に五分に戻す。",
        "압박 속에서 랠리를 이어간다. 수비에서 재정비하고 시간을 벌어, 다시 공격하기 전에 균형으로 되돌린다.",
        "Sostener el peloteo bajo presión: recomponer desde la defensa, ganar tiempo y devolver el punto a igualdad antes de atacar.",
        "Rester dans l'échange sous pression : se replacer en défense, gagner du temps et ramener le point à l'équilibre avant de réattaquer.",
        "Bertahan dalam reli di bawah tekanan — pulihkan dari bertahan, ulur waktu, kembalikan poin ke seimbang sebelum menyerang lagi.",
        "Kekal dalam rali di bawah tekanan — pulih daripada bertahan, beli masa, kembalikan mata ke seimbang sebelum menyerang semula.",
        "อยู่ในการโต้ภายใต้แรงกดดัน — ตั้งหลักจากรับ ซื้อเวลา และดึงแต้มกลับมาเสมอก่อนบุกอีกครั้ง",
        "Trụ lại pha bóng dưới áp lực — gượng dậy từ thế thủ, kéo dài thời gian, đưa điểm về cân bằng trước khi tấn công lại."),
    "finishing": _P(
        "End the point cleanly — take the ball early, hit into the open space, "
        "and finish rather than give the rally back.",
        "干净利落地终结一分——早点击球、打向空当，把球拍死而不是把回合还给对手。",
        "乾淨俐落地終結一分——早點擊球、打向空檔，把球拍死而不是把回合還給對手。",
        "ポイントをきれいに決める。早く打ち、空いた場所へ叩き、ラリーを返さず終わらせる。",
        "포인트를 깔끔하게 끝낸다. 공을 일찍 치고 빈 곳으로 때려, 랠리를 돌려주지 말고 마무리한다.",
        "Cerrar el punto con limpieza: golpear pronto, dirigir al hueco y definir en vez de devolver el peloteo.",
        "Conclure le point proprement : frapper tôt, viser l'espace libre et finir plutôt que de rendre l'échange.",
        "Menyelesaikan poin dengan bersih — pukul lebih awal, arahkan ke ruang kosong, dan tuntaskan bukan mengembalikan reli.",
        "Menamatkan mata dengan bersih — pukul lebih awal, arah ke ruang kosong, dan selesaikan bukan memulangkan rali.",
        "จบแต้มให้เด็ดขาด — ตีเร็ว ตีเข้าที่ว่าง และจบ ไม่ใช่คืนลูกให้คู่ต่อสู้",
        "Kết thúc điểm dứt khoát — đánh sớm, đánh vào khoảng trống, và ghi điểm thay vì trả lại pha bóng."),
    "possession": _P(
        "Control the ball on your own side — clean contacts and a set-up touch "
        "so the attacking ball is there when you want it.",
        "在本方半场把球控好——干净的触球加一次做球，让你想进攻时那个球就在。",
        "在本方半場把球控好——乾淨的觸球加一次做球，讓你想進攻時那個球就在。",
        "自陣でボールをコントロールする。きれいなタッチとお膳立ての一打で、攻めたい時に攻めるボールを用意する。",
        "자기 진영에서 공을 통제한다. 깔끔한 접촉과 세팅 터치로, 공격하고 싶을 때 그 공이 있게 한다.",
        "Controlar la bola en tu campo: contactos limpios y un toque de preparación para tener la bola de ataque cuando quieras.",
        "Contrôler la balle dans son camp : contacts propres et une touche de préparation pour avoir la balle d'attaque au bon moment.",
        "Mengontrol bola di sisi sendiri — sentuhan bersih dan satu sentuhan penyiapan agar bola serangan siap saat diinginkan.",
        "Mengawal bola di pihak sendiri — sentuhan bersih dan satu sentuhan persediaan supaya bola serangan ada bila dikehendaki.",
        "คุมบอลในฝั่งตัวเอง — สัมผัสสะอาดและการเซ็ตหนึ่งจังหวะ เพื่อให้มีลูกบุกเมื่อต้องการ",
        "Khống chế bóng bên sân mình — chạm bóng sạch và một nhịp dựng bóng để có quả tấn công khi muốn."),
    "setpiece": _P(
        "Rehearse the serve and its patterns — the one ball you start with full "
        "control of, placed to set up the point you want.",
        "演练发球及其套路——这是你唯一能完全掌控的开球，落到你想打的那个位置上。",
        "演練發球及其套路——這是你唯一能完全掌控的開球，落到你想打的那個位置上。",
        "サーブとそのパターンを反復する。完全に主導権を持って始められる唯一のボールを、狙った展開に置く。",
        "서브와 그 패턴을 반복한다. 완전한 주도권으로 시작하는 유일한 공을, 원하는 전개로 배치한다.",
        "Ensayar el saque y sus patrones: la única bola que empiezas con control total, colocada para armar el punto que quieres.",
        "Répéter le service et ses schémas : la seule balle que tu débutes en plein contrôle, placée pour construire le point voulu.",
        "Melatih servis dan polanya — satu bola yang kamu mulai dengan kendali penuh, ditempatkan untuk menyiapkan poin.",
        "Melatih servis dan coraknya — satu bola yang anda mula dengan kawalan penuh, diletak untuk menyiapkan mata.",
        "ซ้อมการเสิร์ฟและแพตเทิร์น — ลูกเดียวที่เริ่มด้วยการควบคุมเต็มที่ วางเพื่อจัดแต้มที่ต้องการ",
        "Tập giao bóng và các bài của nó — quả duy nhất bạn bắt đầu với toàn quyền kiểm soát, đặt để dựng điểm bạn muốn."),
}

# ── baseball: the categories map to phases of its own game ────────────────────
BASE = {
    "attacking": _P(
        "Hitting and baserunning — put the ball in play and take the extra base "
        "the defence gives you.",
        "击球与跑垒——把球击进场内，抓住防守让出的那个额外垒。",
        "擊球與跑壘——把球擊進場內，抓住防守讓出的那個額外壘。",
        "打撃と走塁。ボールをフェアに運び、守備が与える次の塁を奪う。",
        "타격과 주루 — 공을 인플레이로 만들고 수비가 주는 추가 베이스를 차지한다.",
        "Bateo y corrido de bases: pon la bola en juego y toma la base extra que te da la defensa.",
        "Frappe et course sur les bases : mettre la balle en jeu et prendre la base que la défense concède.",
        "Memukul dan berlari base — mainkan bola dan ambil base tambahan yang diberi pertahanan.",
        "Memukul dan berlari base — mainkan bola dan ambil base tambahan yang diberi pertahanan.",
        "การตีและวิ่งเบส — ตีบอลให้อยู่ในเกมและคว้าเบสที่ฝ่ายรับยกให้",
        "Đánh bóng và chạy chốt — đưa bóng vào cuộc và chiếm chốt mà hàng thủ để hở."),
    "defending": _P(
        "Fielding and the throw — get to the ball on balance and turn it into an "
        "out where the play is.",
        "守备与传杀——平衡地接到球，在有出局机会的地方把它变成一个出局。",
        "守備與傳殺——平衡地接到球，在有出局機會的地方把它變成一個出局。",
        "守備と送球。バランスよく打球に入り、プレーのある塁でアウトにする。",
        "수비와 송구 — 균형 잡고 타구에 접근해, 플레이가 있는 곳에서 아웃으로 만든다.",
        "Fildeo y tiro: llega a la bola en equilibrio y conviértela en out donde está la jugada.",
        "Défense et relais : arriver équilibré sur la balle et la transformer en retrait là où se joue l'action.",
        "Menangkap dan melempar — jangkau bola dengan seimbang dan jadikan out di tempat mainnya.",
        "Menangkap dan membaling — capai bola dengan seimbang dan jadikan out di tempat mainnya.",
        "การรับและการโยน — เข้าหาบอลอย่างสมดุลและทำเอาต์ตรงที่มีเพลย์",
        "Bắt bóng và ném — tiếp cận bóng cân bằng và biến nó thành out ở nơi có pha chơi."),
    "finishing": _P(
        "Situational hitting — the swing the count and the runners call for, not "
        "the one you feel like taking.",
        "情境击球——根据球数和垒上跑者该打的那一棒，而不是你想打的那一棒。",
        "情境擊球——根據球數和壘上跑者該打的那一棒，而不是你想打的那一棒。",
        "状況に応じた打撃。カウントと走者が求めるスイングで、気分で振るのではない。",
        "상황 타격 — 볼카운트와 주자가 요구하는 스윙이지, 내키는 스윙이 아니다.",
        "Bateo situacional: el swing que piden la cuenta y los corredores, no el que te apetece.",
        "Frappe situationnelle : le swing que le compte et les coureurs exigent, pas celui qui te tente.",
        "Memukul situasional — ayunan yang diminta hitungan dan pelari, bukan yang kamu mau.",
        "Memukul situasi — ayunan yang diminta kiraan dan pelari, bukan yang anda suka.",
        "การตีตามสถานการณ์ — สวิงที่เคานต์และรันเนอร์ต้องการ ไม่ใช่ที่อยากตี",
        "Đánh theo tình huống — cú vung mà số bóng và người chạy đòi hỏi, không phải cú bạn thích."),
    "possession": _P(
        "Battery and infield work — the pitch, the receive and the throws that "
        "hold runners and turn the ball around cleanly.",
        "投捕与内野配合——投球、接球，以及牵制跑者、干净转移球的传接。",
        "投捕與內野配合——投球、接球，以及牽制跑者、乾淨轉移球的傳接。",
        "バッテリーと内野の連携。投球、捕球、そして走者を抑え、ボールをきれいに回す送球。",
        "배터리와 내야 연계 — 투구, 포구, 그리고 주자를 묶고 공을 깔끔하게 돌리는 송구.",
        "Trabajo de batería e infield: el lanzamiento, la recepción y los tiros que sujetan corredores y giran la bola limpia.",
        "Travail batterie–avant-champ : le lancer, la réception et les relais qui figent les coureurs et font tourner la balle proprement.",
        "Kerja battery dan infield — lemparan, tangkapan, dan lemparan yang menahan pelari dan memutar bola bersih.",
        "Kerja battery dan infield — balingan, tangkapan, dan balingan yang menahan pelari dan memutar bola bersih.",
        "งานแบตเตอรีและอินฟิลด์ — การขว้าง การรับ และการโยนที่คุมรันเนอร์และหมุนบอลอย่างสะอาด",
        "Phối hợp battery và nội trường — cú ném bóng, bắt bóng, và những đường ném ghìm người chạy và luân chuyển bóng gọn gàng."),
    "setpiece": _P(
        "A dead-ball routine — the bunt, the pick, the first-and-third: a play "
        "run the same way every time so it works under pressure.",
        "死球战术——触击、牵制、一三垒配合：每次都用同一套跑法，才能在压力下奏效。",
        "死球戰術——觸擊、牽制、一三壘配合：每次都用同一套跑法，才能在壓力下奏效。",
        "デッドボールの型。バント、牽制、一三塁の連携。毎回同じ形で回すからこそ、重圧下でも決まる。",
        "정지 상황 루틴 — 번트, 견제, 1·3루 상황: 매번 같은 방식으로 돌려야 압박 속에서도 통한다.",
        "Jugada a balón parado: el toque, el pickoff, primera-y-tercera: una jugada igual siempre para que funcione bajo presión.",
        "Routine sur balle arrêtée : l'amorti, le pickoff, le premier-et-troisième : jouée pareil à chaque fois pour tenir sous pression.",
        "Rutinitas bola mati — bunt, pickoff, first-and-third: dijalankan sama tiap kali agar berhasil di bawah tekanan.",
        "Rutin bola mati — bunt, pickoff, first-and-third: dijalankan sama setiap kali supaya berkesan di bawah tekanan.",
        "รูทีนลูกตาย — บันต์ พิคออฟ เฟิร์สต์-แอนด์-เทิร์ด: เล่นแบบเดิมทุกครั้งเพื่อให้ได้ผลใต้แรงกดดัน",
        "Bài bóng chết — bunt, pick, first-and-third: chạy giống nhau mỗi lần để hiệu quả dưới áp lực."),
    "ssg": _P(
        "A situational game — read the count and the runners and make the right "
        "baseball play, over and over.",
        "情境对抗——读球数和跑者，反复做出正确的棒球选择。",
        "情境對抗——讀球數和跑者，反覆做出正確的棒球選擇。",
        "状況ゲーム。カウントと走者を読み、正しい野球のプレーを繰り返す。",
        "상황 게임 — 볼카운트와 주자를 읽고 올바른 야구 플레이를 반복한다.",
        "Juego situacional: lee la cuenta y los corredores y haz la jugada correcta, una y otra vez.",
        "Jeu situationnel : lire le compte et les coureurs et faire le bon choix de jeu, encore et encore.",
        "Permainan situasional — baca hitungan dan pelari, buat keputusan bisbol yang benar berulang.",
        "Permainan situasi — baca kiraan dan pelari, buat keputusan besbol yang betul berulang kali.",
        "เกมตามสถานการณ์ — อ่านเคานต์และรันเนอร์ แล้วเล่นให้ถูกซ้ำ ๆ",
        "Trò chơi tình huống — đọc số bóng và người chạy, chọn nước chơi bóng chày đúng, lặp đi lặp lại."),
}


def purpose_texts(sport: str, category: str) -> dict | None:
    """The 目的 section for a drill, by sport family and category."""
    if sport in BASEBALL and category in BASE:
        return BASE[category]
    if sport in NET_SPORTS and category in NET:
        return NET[category]
    return DEFAULT.get(category)
