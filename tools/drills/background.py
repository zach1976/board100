"""The 背景 section — how often a drill is used, and where it comes from.

Two parts, held to different standards:

  【频度】 frequency — every drill gets one, derived from its category. How
           often a category of work appears in a season is knowable in
           general terms (a warm-up is daily, a set piece is weekly), so this
           is assigned, not invented.

  【来历】 origin — only where a drill has a genuine, documented lineage
           (the rondo out of Total Football, pepper as volleyball's oldest
           warm-up). Most drills are common practice with no single origin;
           inventing a history for 624 of them would be fiction, so the origin
           line simply does not appear for them.

Twelve locales, the set the drills ship, never machine-translated.
"""
from __future__ import annotations


def _P(en, zh, zht, ja, ko, es, fr, idn, ms, th, vi):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht, "ja-JP": ja,
            "ko-KR": ko, "es-ES": es, "fr-FR": fr, "id-ID": idn, "ms-MY": ms,
            "th-TH": th, "vi-VN": vi}


# ── frequency, by category ───────────────────────────────────────────────────
FREQUENCY = {
    "warmup": _P(
        "Used every session — it opens the training and warms the body and "
        "the touch before the work.",
        "热身常用——几乎每堂课的开场，训练前先活动身体、找回球感。",
        "熱身常用——幾乎每堂課的開場，訓練前先活動身體、找回球感。",
        "毎回のセッションで使う。練習の入りで、体とタッチを温める。",
        "매 세션마다 사용 — 훈련의 시작으로, 본격 운동 전에 몸과 감각을 데운다.",
        "Se usa cada sesión: abre el entrenamiento y calienta cuerpo y toque.",
        "Utilisé à chaque séance : il ouvre l'entraînement et échauffe le corps et la touche.",
        "Dipakai setiap sesi — membuka latihan dan menghangatkan tubuh dan sentuhan.",
        "Digunakan setiap sesi — membuka latihan dan memanaskan badan dan sentuhan.",
        "ใช้ทุกครั้ง — เปิดการฝึกและอุ่นร่างกายกับสัมผัสก่อนเริ่ม",
        "Dùng mỗi buổi — mở đầu buổi tập, làm nóng người và cảm giác bóng."),
    "possession": _P(
        "A staple of nearly every session — keeping the ball is the base "
        "everything else is built on.",
        "几乎每堂课都练——控球是其他一切的基础。",
        "幾乎每堂課都練——控球是其他一切的基礎。",
        "ほぼ毎回の定番。ボール保持は他のすべての土台になる。",
        "거의 모든 세션의 기본 — 볼 소유가 나머지 모든 것의 토대다.",
        "Un básico de casi cada sesión: conservar el balón es la base de todo lo demás.",
        "Un incontournable de presque chaque séance : garder le ballon est la base de tout le reste.",
        "Andalan hampir setiap sesi — menjaga bola adalah dasar dari semua yang lain.",
        "Asas hampir setiap sesi — mengekalkan bola ialah dasar segala yang lain.",
        "เป็นพื้นฐานเกือบทุกครั้ง — การรักษาบอลคือรากฐานของทุกอย่าง",
        "Bài chủ lực gần như mỗi buổi — giữ bóng là nền tảng của mọi thứ khác."),
    "attacking": _P(
        "A tactical block run a few times a week, as the team sharpens how it "
        "creates and takes chances.",
        "战术训练，每周练几次——磨合球队制造和把握机会的方式。",
        "戰術訓練，每週練幾次——磨合球隊製造和把握機會的方式。",
        "週に数回の戦術ブロック。チャンスの作り方と決め方を磨く。",
        "주 몇 회 진행하는 전술 블록 — 팀이 기회를 만들고 살리는 법을 다듬는다.",
        "Un bloque táctico varias veces por semana, para afinar cómo crea y aprovecha ocasiones.",
        "Un bloc tactique quelques fois par semaine, pour affiner la création et la finition des occasions.",
        "Blok taktis beberapa kali seminggu, saat tim mengasah cara menciptakan dan memanfaatkan peluang.",
        "Blok taktikal beberapa kali seminggu, ketika pasukan mengasah cara mencipta dan memanfaatkan peluang.",
        "บล็อกแทคติกสัปดาห์ละไม่กี่ครั้ง เพื่อฝึกการสร้างและใช้โอกาส",
        "Khối chiến thuật tập vài lần mỗi tuần, để đội mài giũa cách tạo và tận dụng cơ hội."),
    "defending": _P(
        "A tactical block run a few times a week — defensive shape is drilled "
        "regularly because it is the habit a match tests most.",
        "战术训练，每周练几次——防守站位要常练，因为它是比赛最常考验的习惯。",
        "戰術訓練，每週練幾次——防守站位要常練，因為它是比賽最常考驗的習慣。",
        "週に数回の戦術ブロック。守備の形は試合が最も試す習慣なので、定期的に反復する。",
        "주 몇 회의 전술 블록 — 수비 형태는 경기가 가장 자주 시험하는 습관이라 정기적으로 훈련한다.",
        "Un bloque táctico varias veces por semana: la estructura defensiva se ensaya a menudo porque es lo que más pone a prueba el partido.",
        "Un bloc tactique quelques fois par semaine : la structure défensive se travaille souvent, car c'est l'habitude que le match teste le plus.",
        "Blok taktis beberapa kali seminggu — bentuk bertahan dilatih rutin karena itu kebiasaan yang paling diuji pertandingan.",
        "Blok taktikal beberapa kali seminggu — bentuk pertahanan dilatih kerap kerana itu tabiat yang paling diuji perlawanan.",
        "บล็อกแทคติกสัปดาห์ละไม่กี่ครั้ง — รูปแบบรับต้องซ้อมสม่ำเสมอเพราะเป็นสิ่งที่เกมทดสอบบ่อยที่สุด",
        "Khối chiến thuật vài lần mỗi tuần — thế phòng ngự cần tập đều vì đó là thói quen trận đấu thử thách nhiều nhất."),
    "finishing": _P(
        "A technical block coaches run often — the finish is what the whole "
        "attack is for, so it is rehearsed regularly.",
        "技术训练，教练常练——终结是整个进攻的目的，所以要反复练。",
        "技術訓練，教練常練——終結是整個進攻的目的，所以要反覆練。",
        "指導者が頻繁に行う技術ブロック。フィニッシュは攻撃全体の目的なので、繰り返し反復する。",
        "지도자가 자주 하는 기술 블록 — 마무리는 공격 전체의 목적이라 정기적으로 반복한다.",
        "Un bloque técnico que se entrena a menudo: la definición es el fin de todo el ataque, así que se ensaya con regularidad.",
        "Un bloc technique travaillé souvent : la finition est le but de toute l'attaque, donc on la répète régulièrement.",
        "Blok teknis yang sering dilatih — penyelesaian adalah tujuan seluruh serangan, jadi diulang teratur.",
        "Blok teknikal yang kerap dilatih — penamat ialah tujuan seluruh serangan, jadi diulang secara tetap.",
        "บล็อกทักษะที่ซ้อมบ่อย — การจบสกอร์คือเป้าหมายของการบุกทั้งหมด จึงซ้อมสม่ำเสมอ",
        "Khối kỹ thuật huấn luyện viên tập thường xuyên — dứt điểm là mục đích của cả đợt tấn công, nên được tập đều."),
    "setpiece": _P(
        "Rehearsed weekly and hard before a match — set pieces decide a large "
        "share of goals, so the routines are drilled until automatic.",
        "每周练、赛前重点练——定位球贡献了很大比例的进球，所以套路要练到自动化。",
        "每週練、賽前重點練——定位球貢獻了很大比例的進球，所以套路要練到自動化。",
        "毎週、試合前は特に反復する。セットプレーは得点の多くを占めるので、型が自動化するまで仕込む。",
        "매주, 경기 전에는 집중적으로 반복 — 세트피스는 득점의 큰 비중을 차지하므로 자동화될 때까지 훈련한다.",
        "Se ensaya semanalmente y a fondo antes del partido: el balón parado decide muchos goles, así que las jugadas se drillan hasta automatizarse.",
        "Répété chaque semaine et intensément avant un match : les coups de pied arrêtés décident une grande part des buts.",
        "Dilatih mingguan dan intensif sebelum pertandingan — bola mati menentukan banyak gol, jadi rutinitas dilatih sampai otomatis.",
        "Dilatih mingguan dan intensif sebelum perlawanan — bola mati menentukan banyak gol, jadi rutin dilatih sehingga automatik.",
        "ซ้อมทุกสัปดาห์และเข้มก่อนแข่ง — ลูกตั้งเตะทำประตูสัดส่วนมาก จึงซ้อมจนเป็นอัตโนมัติ",
        "Tập hàng tuần và kỹ trước trận — bóng cố định quyết định phần lớn bàn thắng, nên các bài được tập đến mức tự động."),
    "ssg": _P(
        "A session-ender used most days — the small-sided game is where "
        "everything trained gets played out under pressure.",
        "几乎每天用来收尾——小场比赛让练过的一切在压力下落地。",
        "幾乎每天用來收尾——小場比賽讓練過的一切在壓力下落地。",
        "ほぼ毎日の締め。ミニゲームで、練習したすべてがプレッシャー下に出る。",
        "거의 매일 세션 마무리로 사용 — 미니 게임에서 훈련한 모든 것이 압박 속에 나온다.",
        "Un cierre de sesión casi diario: el juego reducido es donde todo lo entrenado se pone en juego bajo presión.",
        "Une fin de séance presque quotidienne : le jeu réduit est là où tout le travail se joue sous pression.",
        "Penutup sesi hampir tiap hari — permainan kecil adalah tempat semua yang dilatih diuji di bawah tekanan.",
        "Penutup sesi hampir setiap hari — permainan kecil ialah tempat semua yang dilatih diuji di bawah tekanan.",
        "ปิดการฝึกเกือบทุกวัน — เกมสนามเล็กคือที่ทุกอย่างที่ซ้อมถูกใช้ภายใต้แรงกดดัน",
        "Kết thúc buổi tập gần như mỗi ngày — trò chơi sân nhỏ là nơi mọi thứ đã tập được thể hiện dưới áp lực."),
    "goalkeeping": _P(
        "A keeper's daily specialist work, run alongside the outfield session.",
        "门将每天的专项训练，与球队训练同时进行。",
        "門將每天的專項訓練，與球隊訓練同時進行。",
        "GKが毎日行う専門トレーニング。フィールドの練習と並行して行う。",
        "골키퍼가 매일 하는 전문 훈련으로, 필드 세션과 병행한다.",
        "El trabajo específico diario del portero, junto a la sesión de campo.",
        "Le travail spécifique quotidien du gardien, mené en parallèle de la séance de champ.",
        "Latihan khusus kiper harian, dijalankan bersama sesi pemain lapangan.",
        "Latihan khusus penjaga gol harian, dijalankan bersama sesi pemain padang.",
        "งานเฉพาะทางของผู้รักษาประตูทุกวัน ทำคู่ไปกับการฝึกของทีม",
        "Bài chuyên biệt hằng ngày của thủ môn, tập song song với buổi của cầu thủ."),
    "conditioning": _P(
        "Loaded into fitness days and the pre-season, when the base for the "
        "whole year is built.",
        "安排在体能日和赛季初——为一整年打底子的时候。",
        "安排在體能日和賽季初——為一整年打底子的時候。",
        "フィットネス日とプレシーズンに組み込む。一年の土台を作る時期。",
        "체력 훈련일과 프리시즌에 배치 — 한 해 전체의 기초를 쌓는 시기.",
        "Se programa en los días de físico y la pretemporada, cuando se construye la base del año.",
        "Placé lors des journées physiques et de la présaison, quand se construit la base de l'année.",
        "Ditempatkan di hari kebugaran dan pramusim, saat fondasi setahun dibangun.",
        "Diletakkan pada hari kecergasan dan pramusim, ketika asas setahun dibina.",
        "จัดในวันฟิตเนสและช่วงพรีซีซัน ตอนที่สร้างพื้นฐานของทั้งปี",
        "Xếp vào ngày thể lực và tiền mùa giải, khi xây nền cho cả năm."),
}

# ── origin, only where genuinely documented ──────────────────────────────────
# (sport, id-substring) -> origin. Matched loosely by substring so a family
# and its variants share one origin. Absent = no origin line (most drills).
ORIGINS = [
    (None, "rondo", _P(
        "Born in Dutch Total Football and made famous by Barcelona's tiki-taka "
        "— possession as the identity of a team.",
        "源自荷兰全攻全守、由巴萨 tiki-taka 发扬光大——把控球当成一支球队的身份。",
        "源自荷蘭全攻全守、由巴薩 tiki-taka 發揚光大——把控球當成一支球隊的身份。",
        "オランダのトータルフットボールに生まれ、バルセロナのティキ・タカで有名になった。保持をチームの哲学とする。",
        "네덜란드 토탈 풋볼에서 태어나 바르셀로나의 티키타카로 유명해졌다 — 점유를 팀의 정체성으로.",
        "Nacido en el Fútbol Total neerlandés y popularizado por el tiki-taka del Barça: la posesión como identidad de un equipo.",
        "Né du football total néerlandais et rendu célèbre par le tiki-taka du Barça : la possession comme identité d'une équipe.",
        "Lahir dari Total Football Belanda dan dipopulerkan tiki-taka Barcelona — penguasaan bola sebagai identitas tim.",
        "Lahir daripada Total Football Belanda dan dipopularkan tiki-taka Barcelona — penguasaan bola sebagai identiti pasukan.",
        "ถือกำเนิดจากโททัลฟุตบอลเนเธอร์แลนด์และโด่งดังด้วยติกิ-ตากาของบาร์ซา — การครองบอลคือตัวตนของทีม",
        "Ra đời từ Total Football Hà Lan và nổi tiếng nhờ tiki-taka của Barca — kiểm soát bóng là bản sắc của một đội.")),
    ("volleyball", "pepper", _P(
        "Volleyball's oldest warm-up — a pass, a set and a hit between two "
        "players, played the world over before every session.",
        "排球最古老的热身——两人之间垫、传、扣，全世界赛前都这么练。",
        "排球最古老的熱身——兩人之間墊、傳、扣，全世界賽前都這麼練。",
        "バレーボール最古のウォームアップ。2人でパス・トス・スパイクを繰り返す、世界共通の準備。",
        "배구에서 가장 오래된 웜업 — 두 사람이 리시브·세트·스파이크를 주고받는, 전 세계 공통 준비 운동.",
        "El calentamiento más antiguo del voleibol: pase, colocación y golpe entre dos, jugado en todo el mundo.",
        "L'échauffement le plus ancien du volley : passe, passe haute et frappe à deux, pratiqué partout.",
        "Pemanasan voli tertua — pas, umpan, dan pukulan antara dua orang, dimainkan di seluruh dunia.",
        "Memanaskan badan bola tampar tertua — pas, angkat, dan pukulan antara dua orang, dimainkan di seluruh dunia.",
        "การวอร์มที่เก่าแก่ที่สุดของวอลเลย์บอล — อันเดอร์ เซ็ต ตบ ระหว่างสองคน เล่นกันทั่วโลก",
        "Bài khởi động lâu đời nhất của bóng chuyền — đệm, chuyền, đập giữa hai người, chơi khắp thế giới.")),
    ("baseball", "warm_infield", _P(
        "Infield-outfield with a fungo bat — a fielding warm-up as old as the "
        "pro game, run before batting practice on every field.",
        "教练用细长球棒（fungo）打内外野守备——和职业棒球一样古老的守备热身，每块场地打击练习前都练。",
        "教練用細長球棒（fungo）打內外野守備——和職業棒球一樣古老的守備熱身，每塊場地打擊練習前都練。",
        "ノックバット（fungo）で行う内外野の守備練習。プロ野球と同じ歴史を持ち、打撃練習前に必ず行う。",
        "펑고 배트로 하는 내야·외야 수비 — 프로야구만큼 오래된 수비 웜업으로, 타격 연습 전에 늘 한다.",
        "Infield-outfield con bate de fungo: un calentamiento defensivo tan antiguo como el béisbol profesional.",
        "Intérieur-extérieur au fungo : un échauffement défensif aussi vieux que le baseball pro.",
        "Infield-outfield dengan tongkat fungo — pemanasan bertahan setua bisbol profesional.",
        "Infield-outfield dengan kayu fungo — memanaskan pertahanan setua besbol profesional.",
        "อินฟิลด์-เอาต์ฟิลด์ด้วยไม้ฟังโก — วอร์มรับเก่าแก่พอ ๆ กับเบสบอลอาชีพ",
        "Nội-ngoại trường với gậy fungo — bài khởi động phòng thủ lâu đời như bóng chày chuyên nghiệp.")),
    (None, "pick_and_roll", _P(
        "The most-used action in modern basketball — a screen and a roll that "
        "forces two defenders to guard one ball.",
        "现代篮球用得最多的战术——挡拆下顺，逼两个防守人去防一个持球人。",
        "現代籃球用得最多的戰術——擋拆下順，逼兩個防守人去防一個持球人。",
        "現代バスケで最も使われる連携。スクリーンとロールで、2人に1人のボールマンを守らせる。",
        "현대 농구에서 가장 많이 쓰는 액션 — 스크린과 롤로 두 수비수가 한 볼 핸들러를 막게 만든다.",
        "La acción más usada del baloncesto moderno: un bloqueo y continuación que obliga a dos a defender un balón.",
        "L'action la plus utilisée du basket moderne : un écran et une plongée qui forcent deux défenseurs sur un porteur.",
        "Aksi paling sering di bola basket modern — screen dan roll yang memaksa dua bek menjaga satu pembawa bola.",
        "Aksi paling kerap dalam bola keranjang moden — skrin dan roll yang memaksa dua pemain bertahan menjaga satu pembawa bola.",
        "แอ็กชันที่ใช้มากที่สุดในบาสสมัยใหม่ — สกรีนและโรลบังคับให้สองคนประกบผู้เลี้ยงบอลคนเดียว",
        "Pha bóng dùng nhiều nhất trong bóng rổ hiện đại — chặn người và cuộn xuống, ép hai người kèm một người cầm bóng.")),
]


# ── badminton's own frequencies ──────────────────────────────────────────────
# The table above is one set of sentences for every sport, and it says
# "goals" to a badminton player and "the team" to a singles player.
FREQUENCY_BADMINTON = {
    "warmup": _P(
        "Every session, first thing — ten minutes of footwork before the "
        "first shuttle.",
        "每堂课开场——先做十分钟步法，再碰第一只球。",
        "每堂課開場——先做十分鐘步法，再碰第一隻球。",
        "毎回、最初に。最初のシャトルの前に10分のフットワーク。",
        "매 세션 맨 처음 — 첫 셔틀 전에 풋워크 10분.",
        "Cada sesión, lo primero: diez minutos de desplazamientos antes del primer volante.",
        "Chaque séance, en premier : dix minutes de déplacements avant le premier volant.",
        "Setiap sesi, paling awal — sepuluh menit footwork sebelum kok pertama.",
        "Setiap sesi, paling awal — sepuluh minit footwork sebelum bulu tangkis pertama.",
        "ทุกครั้ง เป็นอย่างแรก — ฟุตเวิร์กสิบนาทีก่อนแตะลูกแรก",
        "Mỗi buổi, việc đầu tiên — mười phút di chuyển trước quả cầu đầu."),
    "possession": _P(
        "Most sessions — clear and drive rallies are the base of the stroke "
        "work and go in early, straight after the warm-up.",
        "大多数课都练——高远球和平抽的对拉是击球训练的底子，热身之后紧接着就上。",
        "大多數課都練——高遠球和平抽的對拉是擊球訓練的底子，熱身之後緊接著就上。",
        "ほとんどのセッションで。クリアとドライブのラリーはストローク練習の土台で、ウォームアップ直後に入れる。",
        "대부분의 세션에서. 클리어와 드라이브 랠리는 스트로크 훈련의 토대로, 웜업 직후에 들어간다.",
        "Casi todas las sesiones: los peloteos de globo y drive son la base del trabajo de golpes y van justo tras el calentamiento.",
        "Presque chaque séance : les échanges en dégagement et en drive sont la base du travail de frappe et viennent juste après l'échauffement.",
        "Hampir setiap sesi — reli lob dan drive adalah dasar latihan pukulan, langsung setelah pemanasan.",
        "Hampir setiap sesi — rali lob dan drive ialah asas latihan pukulan, terus selepas memanaskan badan.",
        "แทบทุกครั้ง — แรลลีเคลียร์และดาดคือพื้นฐานของการซ้อมตี ใส่ทันทีหลังวอร์ม",
        "Hầu hết các buổi — đôi công cầu cao và đập ngang là nền của tập kỹ thuật, vào ngay sau khởi động."),
    "attacking": _P(
        "A few times a week in the technical block — drops, net play and "
        "deception are built shot by shot and kept sharp.",
        "每周几次，放在技术训练里——吊球、网前和假动作一拍一拍地练，练出来还要保持住。",
        "每週幾次，放在技術訓練裡——吊球、網前和假動作一拍一拍地練，練出來還要保持住。",
        "週に数回、技術練習の枠で。ドロップ、ネット前、フェイントは一打ずつ作り、切らさない。",
        "주 몇 회, 기술 훈련 블록에서. 드롭, 네트 플레이, 페인트는 한 샷씩 쌓고 날을 유지한다.",
        "Varias veces por semana en el bloque técnico: dejadas, juego de red y engaños se construyen golpe a golpe y se mantienen afilados.",
        "Plusieurs fois par semaine dans le bloc technique : amortis, jeu au filet et feintes se construisent coup par coup et s'entretiennent.",
        "Beberapa kali seminggu dalam blok teknik — dropshot, permainan net dan tipuan dibangun pukulan demi pukulan dan dijaga tajam.",
        "Beberapa kali seminggu dalam blok teknik — dropshot, permainan jaring dan tipuan dibina pukulan demi pukulan dan dikekalkan tajam.",
        "สัปดาห์ละหลายครั้งในช่วงซ้อมเทคนิค — หยอด เน็ต และหลอก สร้างทีละลูกและรักษาความคม",
        "Vài lần mỗi tuần trong phần kỹ thuật — bỏ nhỏ, chơi lưới và động tác giả được xây từng cú và giữ cho sắc."),
    "defending": _P(
        "Weekly, fed from a smash — defence is a position you hold, and it is "
        "drilled off the feed before it is trusted in a game.",
        "每周一次，用杀球来喂——防守是先站好的姿势，先在喂球里练熟，再放进比赛里用。",
        "每週一次，用殺球來餵——防守是先站好的姿勢，先在餵球裡練熟，再放進比賽裡用。",
        "週1回、スマッシュの球出しで。守備は構えておく姿勢であり、ゲームで頼る前に球出しで固める。",
        "주 1회, 스매시 피딩으로. 수비는 미리 잡아두는 자세이고, 경기에서 믿기 전에 피딩으로 다진다.",
        "Semanal, alimentado con remates: la defensa es una posición que se mantiene, y se trabaja con bolas lanzadas antes de fiarse de ella en partido.",
        "Hebdomadaire, nourri au smash : la défense est une position qu'on tient, travaillée sur envois avant de s'y fier en match.",
        "Mingguan, diumpan dengan smes — bertahan adalah posisi yang dijaga, dilatih dari umpan sebelum dipercaya di pertandingan.",
        "Mingguan, disuap dengan smesy — pertahanan ialah kedudukan yang dikekalkan, dilatih daripada suapan sebelum dipercayai dalam perlawanan.",
        "สัปดาห์ละครั้ง ป้อนด้วยลูกตบ — การรับคือท่าที่ตั้งไว้ ซ้อมจากการป้อนก่อนจะเชื่อใจในเกม",
        "Hàng tuần, có người đập để tập — phòng thủ là tư thế giữ sẵn, luyện từ quả cấp trước khi tin dùng trong trận."),
    "finishing": _P(
        "Often, and late in the session — the smash is what the attack is "
        "for, and it is practised when the legs are already tired.",
        "经常练，放在课的后半——杀球是整个进攻的目的，要在腿已经累了的时候练。",
        "經常練，放在課的後半——殺球是整個進攻的目的，要在腿已經累了的時候練。",
        "よく、セッションの終盤に。スマッシュは攻撃の目的そのもので、脚が疲れた状態で練習する。",
        "자주, 세션 후반에. 스매시는 공격의 목적이며, 다리가 이미 지친 상태에서 연습한다.",
        "A menudo y al final de la sesión: el remate es el fin del ataque y se practica con las piernas ya cansadas.",
        "Souvent, et en fin de séance : le smash est le but de l'attaque et se travaille jambes déjà fatiguées.",
        "Sering, di akhir sesi — smes adalah tujuan serangan, dilatih saat kaki sudah lelah.",
        "Kerap, di hujung sesi — smesy ialah tujuan serangan, dilatih ketika kaki sudah penat.",
        "บ่อย และช่วงท้ายการซ้อม — ลูกตบคือจุดหมายของการบุก ซ้อมตอนขาล้าแล้ว",
        "Thường xuyên, và ở cuối buổi — cú đập là mục đích của tấn công, tập khi chân đã mỏi."),
    "setpiece": _P(
        "Every week and before every match — ten serves a set, returns with "
        "a live reply, until the placement is automatic.",
        "每周都练、赛前必练——每组十个发球、接发球要有真实回球，练到落点成为本能。",
        "每週都練、賽前必練——每組十個發球、接發球要有真實回球，練到落點成為本能。",
        "毎週、そして試合前に必ず。1セット10本のサーブ、実戦の返球付きのレシーブ、置き所が無意識になるまで。",
        "매주, 그리고 경기 전마다. 한 세트 서브 10개, 실전 리턴이 붙은 리시브, 위치가 자동이 될 때까지.",
        "Cada semana y antes de cada partido: diez saques por serie, restos con réplica real, hasta que la colocación sea automática.",
        "Chaque semaine et avant chaque match : dix services par série, retours avec réplique réelle, jusqu'à ce que le placement soit automatique.",
        "Setiap minggu dan sebelum setiap pertandingan — sepuluh servis per set, pengembalian dengan balasan nyata, sampai penempatan jadi otomatis.",
        "Setiap minggu dan sebelum setiap perlawanan — sepuluh servis satu set, kembalian dengan balasan sebenar, sehingga penempatan menjadi automatik.",
        "ทุกสัปดาห์และก่อนทุกแมตช์ — เสิร์ฟสิบลูกต่อเซ็ต รับเสิร์ฟพร้อมลูกตอบจริง จนการวางเป็นอัตโนมัติ",
        "Mỗi tuần và trước mỗi trận — mười quả giao một hiệp, đỡ giao có trả cầu thật, đến khi điểm rơi thành phản xạ."),
    "ssg": _P(
        "Most sessions, at the end — the conditioned game is where the day's "
        "stroke gets used under pressure.",
        "大多数课的结尾——限制性对抗是把当天练的那一拍放到压力下去用的地方。",
        "大多數課的結尾——限制性對抗是把當天練的那一拍放到壓力下去用的地方。",
        "ほとんどのセッションの最後に。条件付きゲームは、その日の一打をプレッシャーの中で使う場。",
        "대부분의 세션 마지막에. 조건 게임은 그날의 샷을 압박 속에서 써보는 자리다.",
        "Casi todas las sesiones, al final: el juego condicionado es donde el golpe del día se usa bajo presión.",
        "Presque chaque séance, à la fin : le jeu à contrainte est là où le coup du jour est utilisé sous pression.",
        "Hampir setiap sesi, di akhir — permainan bersyarat adalah tempat pukulan hari itu dipakai di bawah tekanan.",
        "Hampir setiap sesi, di hujung — permainan bersyarat ialah tempat pukulan hari itu digunakan di bawah tekanan.",
        "แทบทุกครั้ง ตอนท้าย — เกมมีเงื่อนไขคือที่ที่ลูกของวันนั้นถูกใช้ภายใต้แรงกดดัน",
        "Hầu hết các buổi, ở cuối — trận có điều kiện là nơi cú đánh của hôm đó được dùng dưới áp lực."),
    "conditioning": _P(
        "Fitness days and the pre-season — two or three times a week off-peak, "
        "less in competition weeks.",
        "体能日和赛季前——非比赛周每周两三次，比赛周减量。",
        "體能日和賽季前——非比賽週每週兩三次，比賽週減量。",
        "フィットネスの日とプレシーズンに。オフピークは週2〜3回、試合週は減らす。",
        "체력 훈련일과 프리시즌에. 비시즌 주 2~3회, 시합 주에는 줄인다.",
        "Días de físico y pretemporada: dos o tres veces por semana fuera de competición, menos en semanas de torneo.",
        "Jours de physique et présaison : deux ou trois fois par semaine hors pic, moins en semaine de compétition.",
        "Hari kebugaran dan pramusim — dua tiga kali seminggu di luar puncak, lebih sedikit di minggu kompetisi.",
        "Hari kecergasan dan pramusim — dua tiga kali seminggu di luar puncak, kurang pada minggu pertandingan.",
        "วันฟิตเนสและก่อนฤดูกาล — สัปดาห์ละสองสามครั้งนอกช่วงแข่ง น้อยลงในสัปดาห์แข่ง",
        "Ngày thể lực và trước mùa giải — hai ba lần mỗi tuần ngoài cao điểm, ít hơn vào tuần thi đấu."),
}


def _origin_for(sport: str, drill_id: str):
    for sp, key, text in ORIGINS:
        if (sp is None or sp == sport) and key in drill_id:
            return text
    return None


def background_texts(sport: str, category: str, drill_id: str):
    """(frequency, origin) for a drill; origin may be None."""
    table = FREQUENCY_BADMINTON if sport == "badminton" else FREQUENCY
    return table.get(category), _origin_for(sport, drill_id)
