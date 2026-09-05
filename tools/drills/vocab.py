"""Translations for the variant half of a family drill's name.

A family composes its name as "<family> <variant>" — "Rondo 5v2", "Footwork
the forehand net". The family half is translated where it is written; this is
where the variant half is translated, once, for every sport that uses it.

Anything language-neutral (5v2, 4-4-2, zone 4, +2) passes straight through.
Anything else must appear here: engine.suffixed raises if it does not, so a
variant cannot reach a Chinese user still reading in English.
"""
import re

# Numbers, scorelines, formations, "+1" overloads — the same in every
# language a coach writes in. A zone number is not one of these: Chinese
# calls volleyball's zone 4 "4号位", so it is translated below.
NEUTRAL = re.compile(r"^[+\-\d]+(?:[v\-]\d+)*$")

V: dict[str, dict[str, str]] = {}


def add(en, zh, tw, ja, ko, es, fr, id_, ms, th, vi):
    V[en] = {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": tw, "ja-JP": ja,
             "ko-KR": ko, "es-ES": es, "fr-FR": fr, "id-ID": id_,
             "ms-MY": ms, "th-TH": th, "vi-VN": vi}


# ── direction and target, shared by every sport ──────────────────────────────
add("straight", "直线", "直線", "ストレート", "스트레이트",
    "paralelo", "long de ligne", "lurus", "lurus", "แนวตรง", "đường thẳng")
add("cross-court", "斜线", "斜線", "クロス", "크로스",
    "cruzado", "croisé", "silang", "silang", "ทแยงมุม", "chéo sân")
add("down the line", "沿边线", "沿邊線", "ライン際", "라인 따라",
    "paralelo", "le long de la ligne", "menyusur garis", "menyusur garisan",
    "ตามเส้นข้าง", "dọc biên")
add("down the middle", "走中路", "走中路", "センターへ", "가운데로",
    "por el centro", "dans l'axe", "lewat tengah", "melalui tengah",
    "ตรงกลาง", "vào giữa")
add("wide left", "左路拉开", "左路拉開", "左サイドへ", "왼쪽 넓게",
    "abierto izquierda", "large à gauche", "melebar kiri", "melebar kiri",
    "กว้างซ้าย", "dạt trái")
add("wide right", "右路拉开", "右路拉開", "右サイドへ", "오른쪽 넓게",
    "abierto derecha", "large à droite", "melebar kanan", "melebar kanan",
    "กว้างขวา", "dạt phải")
add("near post", "近角", "近角", "ニアポスト", "니어 포스트",
    "primer palo", "premier poteau", "tiang dekat", "tiang dekat",
    "เสาใกล้", "cột gần")
add("far post", "远角", "遠角", "ファーポスト", "파 포스트",
    "segundo palo", "second poteau", "tiang jauh", "tiang jauh",
    "เสาไกล", "cột xa")
add("left · near post", "左路 · 近角", "左路 · 近角", "左 · ニアポスト",
    "왼쪽 · 니어 포스트", "izquierda · primer palo", "gauche · premier poteau",
    "kiri · tiang dekat", "kiri · tiang dekat", "ซ้าย · เสาใกล้", "trái · cột gần")
add("left · far post", "左路 · 远角", "左路 · 遠角", "左 · ファーポスト",
    "왼쪽 · 파 포스트", "izquierda · segundo palo", "gauche · second poteau",
    "kiri · tiang jauh", "kiri · tiang jauh", "ซ้าย · เสาไกล", "trái · cột xa")
add("right · near post", "右路 · 近角", "右路 · 近角", "右 · ニアポスト",
    "오른쪽 · 니어 포스트", "derecha · primer palo", "droite · premier poteau",
    "kanan · tiang dekat", "kanan · tiang dekat", "ขวา · เสาใกล้", "phải · cột gần")
add("right · far post", "右路 · 远角", "右路 · 遠角", "右 · ファーポスト",
    "오른쪽 · 파 포스트", "derecha · segundo palo", "droite · second poteau",
    "kanan · tiang jauh", "kanan · tiang jauh", "ขวา · เสาไกล", "phải · cột xa")
add("short", "短球", "短球", "ショート", "짧게",
    "corto", "court", "pendek", "pendek", "สั้น", "ngắn")
add("long", "长球", "長球", "ロング", "길게",
    "largo", "long", "panjang", "panjang", "ยาว", "dài")
add("high", "高位", "高位", "ハイ", "높게",
    "alto", "haut", "tinggi", "tinggi", "สูง", "cao")
add("half", "中场高度", "中場高度", "ミドル", "중간",
    "medio", "médian", "tengah", "tengah", "กลาง", "giữa sân")
add("deep", "深区", "深區", "深く", "깊게",
    "profundo", "profond", "dalam", "dalam", "ลึก", "sâu")
add("central", "中路", "中路", "中央", "중앙",
    "central", "axial", "tengah", "tengah", "กลาง", "trung lộ")
add("attacking", "进攻", "進攻", "攻撃", "공격",
    "ofensivo", "offensif", "menyerang", "menyerang", "เกมรุก", "tấn công")
add("defensive", "防守", "防守", "守備", "수비",
    "defensivo", "défensif", "bertahan", "bertahan", "เกมรับ", "phòng thủ")

# ── zones of the pitch ───────────────────────────────────────────────────────
add("own third", "本方三区", "本方三區", "自陣サード", "자기 진영 3분의 1",
    "campo propio", "premier tiers", "sepertiga sendiri", "satu pertiga sendiri",
    "โซนตัวเอง", "một phần ba sân nhà")
add("middle third", "中三区", "中三區", "ミドルサード", "중앙 3분의 1",
    "campo medio", "tiers médian", "sepertiga tengah", "satu pertiga tengah",
    "โซนกลาง", "một phần ba giữa")
add("final third", "前三区", "前三區", "アタッキングサード", "공격 3분의 1",
    "último tercio", "dernier tiers", "sepertiga akhir", "satu pertiga akhir",
    "โซนสุดท้าย", "một phần ba cuối")
add("half-space", "肋部", "肋部", "ハーフスペース", "하프 스페이스",
    "intervalo", "demi-espace", "half-space", "half-space",
    "ช่องฮาล์ฟสเปซ", "khoảng bán không gian")
add("left halfspace", "左肋部", "左肋部", "左ハーフスペース", "왼쪽 하프 스페이스",
    "intervalo izquierdo", "demi-espace gauche", "half-space kiri",
    "half-space kiri", "ฮาล์ฟสเปซซ้าย", "bán không gian trái")
add("right halfspace", "右肋部", "右肋部", "右ハーフスペース", "오른쪽 하프 스페이스",
    "intervalo derecho", "demi-espace droit", "half-space kanan",
    "half-space kanan", "ฮาล์ฟสเปซขวา", "bán không gian phải")
add("left wing", "左边路", "左邊路", "左サイド", "왼쪽 측면",
    "banda izquierda", "aile gauche", "sayap kiri", "sayap kiri",
    "ริมเส้นซ้าย", "cánh trái")
add("right wing", "右边路", "右邊路", "右サイド", "오른쪽 측면",
    "banda derecha", "aile droite", "sayap kanan", "sayap kanan",
    "ริมเส้นขวา", "cánh phải")
add("box to box", "禁区到禁区", "禁區到禁區", "ボックス・トゥ・ボックス", "박스 투 박스",
    "de área a área", "surface à surface", "kotak ke kotak", "kotak ke kotak",
    "จากกรอบถึงกรอบ", "từ vòng cấm đến vòng cấm")

# ── soccer combinations and patterns ─────────────────────────────────────────
add("overlap left", "左路套边", "左路套邊", "左オーバーラップ", "왼쪽 오버래핑",
    "desdoble izquierda", "débordement gauche", "overlap kiri", "overlap kiri",
    "โอเวอร์แลปซ้าย", "chồng biên trái")
add("overlap right", "右路套边", "右路套邊", "右オーバーラップ", "오른쪽 오버래핑",
    "desdoble derecha", "débordement droit", "overlap kanan", "overlap kanan",
    "โอเวอร์แลปขวา", "chồng biên phải")
add("underlap", "内切插上", "內切插上", "インナーラップ", "언더래핑",
    "desdoble interior", "course intérieure", "underlap", "underlap",
    "วิ่งสอดด้านใน", "chạy luồn trong")
add("wall pass left", "左侧撞墙", "左側撞牆", "左のワンツー", "왼쪽 원투 패스",
    "pared izquierda", "une-deux à gauche", "wall pass kiri", "wall pass kiri",
    "วันทูซ้าย", "phối hợp một-hai trái")
add("wall pass right", "右侧撞墙", "右側撞牆", "右のワンツー", "오른쪽 원투 패스",
    "pared derecha", "une-deux à droite", "wall pass kanan", "wall pass kanan",
    "วันทูขวา", "phối hợp một-hai phải")
add("layoff", "回做", "回做", "落とし", "레이오프",
    "descarga", "remise", "layoff", "layoff", "เขี่ยคืน", "trả bóng")
add("pull back", "倒三角", "倒三角", "マイナスの折り返し", "컷백",
    "pase atrás", "passe en retrait", "umpan tarik", "hantaran tarik",
    "เปิดถอยหลัง", "chuyền ngược")
add("runner across", "反向穿插", "反向穿插", "クロスランナー", "가로지르는 침투",
    "desmarque cruzado", "course croisée", "pelari menyilang",
    "pelari menyilang", "วิ่งตัดหน้า", "chạy cắt ngang")
add("second ball", "二点球", "二點球", "セカンドボール", "세컨드 볼",
    "segunda jugada", "second ballon", "bola kedua", "bola kedua",
    "บอลจังหวะสอง", "bóng hai")
add("crosses", "传中", "傳中", "クロス", "크로스",
    "centros", "centres", "umpan silang", "hantaran lintang",
    "การเปิดบอล", "tạt bóng")
add("direct", "直接射门", "直接射門", "直接", "직접",
    "directo", "direct", "langsung", "terus", "ยิงตรง", "sút thẳng")
add("distribution", "手抛发动", "手拋發動", "配球", "배급",
    "distribución", "relance", "distribusi", "pengagihan",
    "การจ่ายบอลออก", "phát động bóng")
add("angles", "角度选位", "角度選位", "角度", "각도",
    "ángulos", "angles", "sudut", "sudut", "การตัดมุม", "chọn góc")
add("repeat sprints", "反复冲刺", "反覆衝刺", "反復スプリント", "반복 스프린트",
    "series de sprints", "sprints répétés", "sprint berulang",
    "pecutan berulang", "สปรินต์ซ้ำ", "chạy nước rút lặp lại")
add("shuttle to finish", "折返后终结", "折返後終結", "シャトルランからのフィニッシュ",
    "왕복 후 마무리", "ida y vuelta y definición", "navette puis finition",
    "lari bolak-balik lalu selesaikan", "lari ulang-alik lalu selesaikan",
    "วิ่งกลับตัวแล้วจบสกอร์", "chạy con thoi rồi dứt điểm")
add("to the full-back", "给边后卫", "給邊後衛", "サイドバックへ", "풀백에게",
    "al lateral", "vers le latéral", "ke bek sayap", "kepada bek sayap",
    "ไปที่แบ็ก", "cho hậu vệ biên")
add("triangle", "三角形", "三角形", "三角形", "삼각형",
    "triángulo", "triangle", "segitiga", "segi tiga", "สามเหลี่ยม", "tam giác")
add("diamond", "菱形", "菱形", "ダイヤモンド", "다이아몬드",
    "rombo", "losange", "berlian", "berlian", "ข้าวหลามตัด", "kim cương")
add("pentagon", "五边形", "五邊形", "五角形", "오각형",
    "pentágono", "pentagone", "segi lima", "segi lima", "ห้าเหลี่ยม", "ngũ giác")
add("hexagon", "六边形", "六邊形", "六角形", "육각형",
    "hexágono", "hexagone", "segi enam", "segi enam", "หกเหลี่ยม", "lục giác")
add("high block", "高位防线", "高位防線", "ハイブロック", "하이 블록",
    "bloque alto", "bloc haut", "blok tinggi", "blok tinggi",
    "ตั้งรับสูง", "khối phòng ngự cao")
add("mid block", "中位防线", "中位防線", "ミドルブロック", "미드 블록",
    "bloque medio", "bloc médian", "blok tengah", "blok tengah",
    "ตั้งรับกลาง", "khối phòng ngự giữa")
add("low block", "低位防线", "低位防線", "ローブロック", "로우 블록",
    "bloque bajo", "bloc bas", "blok rendah", "blok rendah",
    "ตั้งรับต่ำ", "khối phòng ngự thấp")
add("open body", "侧身接球", "側身接球", "半身で受ける", "몸을 열고",
    "cuerpo abierto", "corps ouvert", "badan terbuka", "badan terbuka",
    "เปิดลำตัว", "mở thân người")
add("in traffic", "人堆中", "人堆中", "密集地帯で", "밀집 상황",
    "entre rivales", "dans le trafic", "di tengah kerumunan",
    "dalam kesesakan", "ในที่แออัด", "trong đám đông")
add("pressed from behind", "背身受压", "背身受壓", "背後からのプレッシャー",
    "뒤에서 압박받으며", "presionado por detrás", "pressé de dos",
    "ditekan dari belakang", "ditekan dari belakang", "โดนกดดันจากด้านหลัง",
    "bị ép từ phía sau")
add("pressed side on", "侧向受压", "側向受壓", "横からのプレッシャー",
    "측면 압박받으며", "presionado de lado", "pressé de côté",
    "ditekan dari samping", "ditekan dari sisi", "โดนกดดันด้านข้าง",
    "bị ép từ bên hông")

# ── net sports: strokes and shots ────────────────────────────────────────────
add("the forehand net", "正手网前", "正手網前", "フォア前", "포핸드 네트 앞",
    "red de derecha", "filet coup droit", "net forehand", "jaring forehand",
    "หน้าเน็ตโฟร์แฮนด์", "trước lưới thuận tay")
add("the backhand net", "反手网前", "反手網前", "バック前", "백핸드 네트 앞",
    "red de revés", "filet revers", "net backhand", "jaring backhand",
    "หน้าเน็ตแบ็กแฮนด์", "trước lưới trái tay")
add("the forehand rear", "正手后场", "正手後場", "フォア奥", "포핸드 후위",
    "fondo de derecha", "fond coup droit", "belakang forehand",
    "belakang forehand", "หลังคอร์ตโฟร์แฮนด์", "cuối sân thuận tay")
add("the backhand rear", "反手后场", "反手後場", "バック奥", "백핸드 후위",
    "fondo de revés", "fond revers", "belakang backhand", "belakang backhand",
    "หลังคอร์ตแบ็กแฮนด์", "cuối sân trái tay")
add("all four corners", "四点全场", "四點全場", "四隅すべて", "네 코너 전부",
    "las cuatro esquinas", "les quatre coins", "keempat sudut",
    "keempat-empat sudut", "ครบสี่มุม", "cả bốn góc")
add("sliced", "劈吊", "劈吊", "カット", "슬라이스",
    "cortado", "slicé", "slice", "slice", "ตัดเฉียง", "cắt bóng")
add("steep", "陡角", "陡角", "角度をつけて", "가파르게",
    "vertical", "plongeant", "menukik", "menukik", "ชันลง", "cắm xuống")
add("kill", "扑杀", "撲殺", "プッシュ", "킬",
    "remate", "kill", "kill", "kill", "ตบจบ", "vụt kết")
add("lift", "挑球", "挑球", "ロブ", "리프트",
    "globo", "lob", "lob", "lob", "งัด", "nâng bóng")
add("spinning net", "搓球旋转", "搓球旋轉", "スピンネット", "스핀 네트",
    "dejada con efecto", "amorti lifté", "net berputar", "jaring berputar",
    "หยอดหมุน", "bỏ nhỏ xoáy")
add("block return", "挡网还击", "擋網還擊", "ブロックリターン", "블록 리턴",
    "bloqueo", "contre bloqué", "blok balik", "blok balas",
    "รับด้วยการบล็อก", "chắn trả")
add("drive return", "平抽还击", "平抽還擊", "ドライブリターン", "드라이브 리턴",
    "resto de drive", "retour en drive", "drive balik", "drive balas",
    "รับด้วยลูกดาด", "trả bóng ngang")
add("lift return", "挑球还击", "挑球還擊", "ロブリターン", "리프트 리턴",
    "globo de resto", "retour lobé", "lob balik", "lob balas",
    "รับด้วยการงัด", "trả bóng nâng")
add("solo", "单人", "單人", "1枚", "1인",
    "individual", "seul", "tunggal", "tunggal", "คนเดียว", "một người")
add("double outside", "外侧双人", "外側雙人", "アウトサイド2枚", "아웃사이드 2인",
    "doble exterior", "double extérieur", "ganda luar", "ganda luar",
    "บล็อกคู่ริม", "chắn đôi biên")
add("double middle", "中间双人", "中間雙人", "ミドル2枚", "미들 2인",
    "doble central", "double central", "ganda tengah", "ganda tengah",
    "บล็อกคู่กลาง", "chắn đôi giữa")
add("triple", "三人", "三人", "3枚", "3인",
    "triple", "triple", "tripel", "tripel", "สามคน", "ba người")
add("flick", "勾手发球", "勾手發球", "フリック", "플릭",
    "flick", "flick", "flick", "flick", "ฟลิก", "cầu lao")
add("high singles", "单打高远发球", "單打高遠發球", "シングルスのハイサーブ",
    "단식 하이 서브", "saque alto de individual", "service haut en simple",
    "servis tinggi tunggal", "servis tinggi perseorangan",
    "เสิร์ฟสูงประเภทเดี่ยว", "giao cao đơn")
add("drive", "平快", "平快", "ドライブ", "드라이브",
    "drive", "drive", "drive", "drive", "ลูกดาด", "bóng ngang")
add("attacking shape", "进攻站位", "進攻站位", "攻撃の陣形", "공격 대형",
    "formación de ataque", "dispositif offensif", "formasi menyerang",
    "formasi menyerang", "รูปแบบบุก", "đội hình tấn công")
add("defending shape", "防守站位", "防守站位", "守備の陣形", "수비 대형",
    "formación defensiva", "dispositif défensif", "formasi bertahan",
    "formasi bertahan", "รูปแบบรับ", "đội hình phòng thủ")
add("rotating on the lift", "挑球后轮转", "挑球後輪轉", "ロブ後のローテーション",
    "리프트 후 로테이션", "rotación tras el globo", "rotation après le lob",
    "rotasi setelah lob", "putaran selepas lob", "หมุนหลังงัดบอล",
    "xoay vòng sau khi nâng bóng")
add("hold and flick", "停顿后勾", "停頓後勾", "ホールドからのフリック",
    "홀드 후 플릭", "retención y flick", "retenue puis flick",
    "tahan lalu flick", "tahan kemudian flick", "หน่วงแล้วฟลิก",
    "giữ rồi lao cầu")
add("double motion", "双动作", "雙動作", "二重動作", "이중 동작",
    "doble gesto", "double armé", "gerakan ganda", "gerakan ganda",
    "สองจังหวะ", "động tác kép")
add("flat exchange", "平抽对抗", "平抽對抗", "フラットの打ち合い", "플랫 랠리",
    "intercambio plano", "échange à plat", "adu datar", "adu rata",
    "โต้ลูกแบน", "đôi công phẳng")
add("half-court singles", "半场单打", "半場單打", "ハーフコートシングルス",
    "하프코트 단식", "individual en media pista", "simple en demi-terrain",
    "tunggal setengah lapangan", "perseorangan separuh gelanggang",
    "เดี่ยวครึ่งคอร์ท", "đơn nửa sân")
add("front-court only", "只打前场", "只打前場", "前衛エリアのみ", "전위만",
    "solo pista delantera", "avant-court seulement", "hanya area depan",
    "kawasan depan sahaja", "เฉพาะหน้าคอร์ท", "chỉ nửa trên")
add("full doubles", "完整双打", "完整雙打", "フルダブルス", "정식 복식",
    "dobles completo", "double complet", "ganda penuh", "beregu penuh",
    "คู่เต็มรูปแบบ", "đôi đầy đủ")
add("doubles rotation", "双打轮转", "雙打輪轉", "ダブルスのローテーション",
    "복식 로테이션", "rotación de dobles", "rotation en double",
    "rotasi ganda", "putaran beregu", "การหมุนของคู่", "xoay vòng đôi")
add("doubles set", "双打一盘", "雙打一盤", "ダブルスの1セット", "복식 한 세트",
    "set de dobles", "set en double", "set ganda", "set beregu",
    "หนึ่งเซตประเภทคู่", "một set đôi")
add("one up one back", "一前一后", "一前一後", "前後の陣形", "일전일후",
    "uno arriba uno atrás", "un devant un derrière", "satu depan satu belakang",
    "satu depan satu belakang", "หนึ่งหน้าหนึ่งหลัง", "một trên một dưới")
add("both back", "双底线", "雙底線", "二人とも後ろ", "둘 다 뒤",
    "los dos atrás", "les deux au fond", "keduanya di belakang",
    "kedua-duanya di belakang", "ยืนหลังทั้งคู่", "cả hai ở cuối sân")
add("both up", "双上网", "雙上網", "二人とも前", "둘 다 앞",
    "los dos arriba", "les deux au filet", "keduanya di depan",
    "kedua-duanya di hadapan", "ขึ้นหน้าทั้งคู่", "cả hai lên lưới")
add("the Australian formation", "澳式站位", "澳式站位", "オーストラリアン・フォーメーション",
    "오스트레일리언 포메이션", "formación australiana", "formation australienne",
    "formasi Australia", "formasi Australia", "การยืนแบบออสเตรเลียน",
    "đội hình Australia")
add("mini tennis", "小场地网球", "小場地網球", "ミニテニス", "미니 테니스",
    "mini tenis", "mini-tennis", "mini tenis", "mini tenis",
    "มินิเทนนิส", "quần vợt mini")
add("service box rally", "发球区对拉", "發球區對拉", "サービスボックスのラリー",
    "서비스 박스 랠리", "peloteo en el cuadro", "échange dans le carré",
    "reli di kotak servis", "rali dalam kotak servis", "โต้ในกรอบเสิร์ฟ",
    "đôi công trong ô giao bóng")
add("baseline feed", "底线喂球", "底線餵球", "ベースラインからの球出し",
    "베이스라인 피딩", "alimentación desde el fondo", "distribution du fond",
    "umpan dari garis belakang", "suapan dari garisan belakang",
    "ป้อนบอลจากเส้นหลัง", "tiếp bóng từ cuối sân")
add("cross-court forehand", "正手斜线", "正手斜線", "フォアのクロス", "포핸드 크로스",
    "derecha cruzada", "coup droit croisé", "forehand silang",
    "forehand silang", "โฟร์แฮนด์ทแยง", "thuận tay chéo sân")
add("cross-court backhand", "反手斜线", "反手斜線", "バックのクロス", "백핸드 크로스",
    "revés cruzado", "revers croisé", "backhand silang", "backhand silang",
    "แบ็กแฮนด์ทแยง", "trái tay chéo sân")
add("figure of eight", "八字循环", "八字循環", "8の字", "8자 랠리",
    "en ocho", "en huit", "angka delapan", "angka lapan",
    "รูปเลขแปด", "hình số tám")
add("deuce wide", "右区外角", "右區外角", "デュースサイド ワイド", "듀스 사이드 와이드",
    "abierto por deuce", "extérieur côté égalité", "melebar sisi deuce",
    "melebar sisi deuce", "ฝั่งดิวซ์ริม", "ô chẵn góc rộng")
add("deuce down the T", "右区中线", "右區中線", "デュースサイド センター",
    "듀스 사이드 T", "a la T por deuce", "sur le T côté égalité",
    "ke T sisi deuce", "ke T sisi deuce", "ฝั่งดิวซ์กลางที", "ô chẵn vào chữ T")
add("deuce at the body", "右区追身", "右區追身", "デュースサイド ボディ",
    "듀스 사이드 보디", "al cuerpo por deuce", "sur le corps côté égalité",
    "ke badan sisi deuce", "ke badan sisi deuce", "ฝั่งดิวซ์เข้าตัว",
    "ô chẵn vào người")
add("ad wide", "左区外角", "左區外角", "アドサイド ワイド", "애드 사이드 와이드",
    "abierto por ventaja", "extérieur côté avantage", "melebar sisi ad",
    "melebar sisi ad", "ฝั่งแอดริม", "ô lẻ góc rộng")
add("ad down the T", "左区中线", "左區中線", "アドサイド センター", "애드 사이드 T",
    "a la T por ventaja", "sur le T côté avantage", "ke T sisi ad",
    "ke T sisi ad", "ฝั่งแอดกลางที", "ô lẻ vào chữ T")
add("first volley", "第一截击", "第一截擊", "ファーストボレー", "첫 발리",
    "primera volea", "première volée", "voli pertama", "voli pertama",
    "วอลเลย์แรก", "vô lê thứ nhất")
add("second volley", "第二截击", "第二截擊", "セカンドボレー", "두 번째 발리",
    "segunda volea", "seconde volée", "voli kedua", "voli kedua",
    "วอลเลย์ที่สอง", "vô lê thứ hai")
add("overhead", "高压", "高壓", "スマッシュ", "스매시",
    "smash", "smash", "smash", "smes", "ลูกเหนือหัว", "đập trên đầu")
add("drop volley", "放小截击", "放小截擊", "ドロップボレー", "드롭 발리",
    "volea dejada", "amortie de volée", "voli drop", "voli drop",
    "วอลเลย์หยอด", "vô lê bỏ nhỏ")
add("approach", "上网球", "上網球", "アプローチ", "어프로치",
    "aproximación", "approche", "approach", "approach",
    "ลูกขึ้นหน้า", "bóng lên lưới")
add("inside-out forehand", "正手反打斜线", "正手反打斜線", "回り込みフォア",
    "인사이드 아웃 포핸드", "derecha invertida", "coup droit décroisé",
    "forehand inside-out", "forehand inside-out", "โฟร์แฮนด์อินไซด์เอาต์",
    "thuận tay đảo hướng")
add("return", "接发球", "接發球", "リターン", "리턴",
    "resto", "retour", "pengembalian", "pulangan", "การรับเสิร์ฟ", "trả giao bóng")
add("serve", "发球", "發球", "サーブ", "서브",
    "saque", "service", "servis", "servis", "การเสิร์ฟ", "giao bóng")
add("the slice", "削球", "削球", "スライス", "슬라이스",
    "el cortado", "le slice", "slice", "slice", "ลูกสไลซ์", "cắt bóng")
add("the lob", "放高球", "放高球", "ロブ", "로브",
    "el globo", "le lob", "lob", "lob", "ลูกโด่ง", "bóng bổng")
add("the block return", "挡回球", "擋回球", "ブロックリターン", "블록 리턴",
    "el bloqueo de resto", "le retour bloqué", "blok pengembalian",
    "blok pulangan", "การรับแบบบล็อก", "trả bóng chắn")
add("first to seven", "先到七分", "先到七分", "7ポイント先取", "7점 먼저",
    "primero a siete", "premier à sept", "pertama ke tujuh",
    "pertama ke tujuh", "ใครถึงเจ็ดก่อน", "ai đến bảy trước")
add("approach and volley only", "只准上网截击", "只准上網截擊",
    "アプローチとボレーのみ", "어프로치와 발리만",
    "solo aproximación y volea", "approche et volée seulement",
    "hanya approach dan voli", "hanya approach dan voli",
    "เฉพาะขึ้นหน้าและวอลเลย์", "chỉ lên lưới và vô lê")
add("skinny singles", "窄场单打", "窄場單打", "細長シングルス", "좁은 코트 단식",
    "individual estrecho", "simple étroit", "tunggal sempit",
    "perseorangan sempit", "เดี่ยวคอร์ทแคบ", "đơn sân hẹp")

# ── volleyball ───────────────────────────────────────────────────────────────
add("the pipe", "后攻(中)", "後攻(中)", "パイプ", "파이프",
    "pipe", "pipe", "pipe", "pipe", "ไปป์", "tấn công biên giữa")
add("front set", "正面传球", "正面傳球", "フロントトス", "앞 토스",
    "colocación adelante", "passe avant", "umpan depan", "umpanan depan",
    "เซตหน้า", "chuyền trước")
add("back set", "背传", "背傳", "バックトス", "백 토스",
    "colocación atrás", "passe arrière", "umpan belakang", "umpanan belakang",
    "เซตหลัง", "chuyền sau")
add("jump set", "跳传", "跳傳", "ジャンプトス", "점프 토스",
    "colocación en salto", "passe sautée", "umpan lompat", "umpanan lompat",
    "เซตกระโดด", "chuyền nhảy")
add("pepper", "对垫练习", "對墊練習", "対人パス", "페퍼",
    "pepper", "pepper", "pepper", "pepper", "เป๊ปเปอร์", "chuyền đôi")
add("butterfly passing", "蝴蝶跑动传球", "蝴蝶跑動傳球", "バタフライパス",
    "버터플라이 패싱", "pases en mariposa", "passes en papillon",
    "passing kupu-kupu", "hantaran rama-rama", "การส่งแบบผีเสื้อ",
    "chuyền hình bướm")
add("shuffle and dig", "滑步救球", "滑步救球", "サイドステップ・ディグ",
    "셔플 후 디그", "desplazamiento y defensa", "pas chassés et défense",
    "geser lalu dig", "gelongsor lalu dig", "สไลด์แล้วรับ",
    "bước ngang rồi đỡ")
add("float deep", "飘球到底线", "飄球到底線", "深いフローター", "딥 플로터",
    "flotante profundo", "flottant long", "float dalam", "float dalam",
    "ลูกลอยลึก", "phát bóng nổi sâu")
add("jump", "跳发", "跳發", "ジャンプサーブ", "점프 서브",
    "salto", "sauté", "lompat", "lompat", "กระโดดเสิร์ฟ", "nhảy phát bóng")
add("at the seam", "打结合部", "打結合部", "継ぎ目を狙う", "이음새 공략",
    "a la costura", "sur la couture", "ke celah", "ke celah",
    "เข้าที่รอยต่อ", "vào khe")
add("perimeter", "外围", "外圍", "ペリメーター", "페리미터",
    "perímetro", "périmètre", "perimeter", "perimeter",
    "รอบนอก", "vòng ngoài")
add("rotation", "轮转", "輪轉", "ローテーション", "로테이션",
    "rotación", "rotation", "rotasi", "putaran", "การหมุน", "xoay vòng")
add("man-up", "堵人防守", "堵人防守", "マンアップ", "맨업",
    "man-up", "man-up", "man-up", "man-up", "แมนอัพ", "chắn người")
add("a free ball", "调整球", "調整球", "フリーボール", "프리볼",
    "un balón libre", "une balle libre", "bola bebas", "bola bebas",
    "ฟรีบอล", "bóng tự do")
add("a down ball", "下手攻球", "下手攻球", "ダウンボール", "다운볼",
    "un balón de ataque bajo", "une balle attaquée basse", "bola down",
    "bola down", "ดาวน์บอล", "bóng đập thấp")
add("circulation", "球的转移", "球的轉移", "ボール回し", "볼 순환",
    "circulación", "circulation", "sirkulasi", "peredaran",
    "การหมุนบอล", "luân chuyển bóng")

# ── pickleball ───────────────────────────────────────────────────────────────
add("to the backhand", "打反手", "打反手", "バック側へ", "백핸드 쪽으로",
    "al revés", "sur le revers", "ke backhand", "ke backhand",
    "ไปด้านแบ็กแฮนด์", "vào trái tay")
add("pulling them wide", "把人拉开", "把人拉開", "外へ引き出す", "넓게 끌어내기",
    "abriéndolos", "en les écartant", "menarik mereka melebar",
    "menarik mereka melebar", "ดึงให้ออกกว้าง", "kéo họ ra rộng")
add("drop", "落点球", "落點球", "ドロップ", "드롭",
    "drop", "drop", "drop", "drop", "ดรอป", "bóng thả")
add("the fifth from the transition zone", "过渡区的第五拍", "過渡區的第五拍",
    "トランジションからの5球目", "트랜지션 존에서의 다섯 번째 샷",
    "el quinto desde la zona de transición", "la cinquième depuis la zone de transition",
    "pukulan kelima dari zona transisi", "pukulan kelima dari zon peralihan",
    "ลูกที่ห้าจากโซนเปลี่ยนผ่าน", "cú thứ năm từ vùng chuyển tiếp")
add("at the shoulder", "打肩部", "打肩部", "肩を狙う", "어깨 쪽으로",
    "al hombro", "sur l'épaule", "ke bahu", "ke bahu",
    "เข้าที่ไหล่", "vào vai")
add("at the hip", "打髋部", "打髖部", "腰を狙う", "허리 쪽으로",
    "a la cadera", "sur la hanche", "ke pinggul", "ke pinggul",
    "เข้าที่สะโพก", "vào hông")
add("the Ernie", "厄尼横切", "厄尼橫切", "アーニー", "어니",
    "el Ernie", "l'Ernie", "Ernie", "Ernie", "เออร์นี่", "cú Ernie")
add("the roll volley", "上旋截击", "上旋截擊", "ロールボレー", "롤 발리",
    "la volea liftada", "la volée liftée", "voli roll", "voli roll",
    "วอลเลย์ม้วน", "vô lê xoáy lên")
add("around the post", "绕柱球", "繞柱球", "ポスト外の一撃", "포스트 바깥",
    "por fuera del poste", "autour du poteau", "melewati luar tiang",
    "melepasi luar tiang", "อ้อมเสา", "vòng ngoài cột")
add("the block", "挡球", "擋球", "ブロック", "블록",
    "el bloqueo", "le blocage", "blok", "blok", "การบล็อก", "chắn bóng")
add("the reset from transition", "过渡区的缓冲球", "過渡區的緩衝球",
    "トランジションからのリセット", "트랜지션에서의 리셋",
    "el reseteo desde transición", "la remise depuis la transition",
    "reset dari transisi", "reset dari peralihan",
    "การรีเซ็ตจากโซนเปลี่ยนผ่าน", "đưa bóng về từ vùng chuyển tiếp")
add("the lob over your head", "头顶挑高球", "頭頂挑高球", "頭上を越えるロブ",
    "머리 위 로브", "el globo por encima", "le lob par-dessus",
    "lob melewati kepala", "lob melepasi kepala", "ลูกโด่งข้ามหัว",
    "bóng bổng qua đầu")
add("the counter in a firefight", "对轰中的反击", "對轟中的反擊",
    "打ち合いのカウンター", "난타전에서의 카운터",
    "el contragolpe en el tiroteo", "le contre dans l'échange rapide",
    "serangan balik dalam adu cepat", "serangan balas dalam adu pantas",
    "การสวนกลับในการปะทะเร็ว", "phản đòn trong pha đôi công")
add("deep to the backhand", "深打反手", "深打反手", "バック側へ深く",
    "백핸드 깊게", "profundo al revés", "profond sur le revers",
    "dalam ke backhand", "dalam ke backhand", "ลึกไปด้านแบ็กแฮนด์",
    "sâu vào trái tay")
add("deep to the forehand", "深打正手", "深打正手", "フォア側へ深く",
    "포핸드 깊게", "profundo a la derecha", "profond sur le coup droit",
    "dalam ke forehand", "dalam ke forehand", "ลึกไปด้านโฟร์แฮนด์",
    "sâu vào thuận tay")
add("return and come in", "接发后上网", "接發後上網", "リターンして前へ",
    "리턴 후 전진", "resto y subida", "retour et montée",
    "kembalikan lalu maju", "pulangkan lalu maju", "รับแล้วขึ้นหน้า",
    "trả bóng rồi lên lưới")
add("both at the kitchen", "双双到位", "雙雙到位", "二人ともキッチンへ",
    "둘 다 키친에", "los dos en la cocina", "les deux à la cuisine",
    "keduanya di kitchen", "kedua-duanya di kitchen",
    "ขึ้นหน้าเน็ตทั้งคู่", "cả hai ở vùng bếp")
add("stacking", "叠站", "疊站", "スタッキング", "스태킹",
    "stacking", "stacking", "stacking", "stacking",
    "การยืนซ้อน", "xếp chồng vị trí")
add("switching on the lob", "挑高球时换位", "挑高球時換位", "ロブでのスイッチ",
    "로브 시 스위치", "cambio en el globo", "permutation sur le lob",
    "bertukar saat lob", "bertukar ketika lob", "สลับตำแหน่งตอนโดนลอบ",
    "đổi chỗ khi bị lob")
add("dinking", "小球对拉", "小球對拉", "ディンクのラリー", "딩크 랠리",
    "peloteo de dinks", "échange de dinks", "adu dink", "adu dink",
    "โต้ดิ้งก์", "đôi công bỏ nhỏ")
add("hand speed", "手速对抗", "手速對抗", "ハンドスピード", "핸드 스피드",
    "velocidad de manos", "vitesse de mains", "kecepatan tangan",
    "kepantasan tangan", "ความเร็วมือ", "tốc độ tay")
add("transition footwork", "过渡区步法", "過渡區步法", "トランジションの足",
    "트랜지션 풋워크", "pies en transición", "appuis en transition",
    "footwork transisi", "kerja kaki peralihan", "ฟุตเวิร์กโซนเปลี่ยนผ่าน",
    "di chuyển vùng chuyển tiếp")
add("dinks only", "只准放小球", "只准放小球", "ディンクのみ", "딩크만",
    "solo dinks", "dinks seulement", "hanya dink", "hanya dink",
    "เฉพาะดิ้งก์", "chỉ bỏ nhỏ")
add("third shot game", "第三拍对抗", "第三拍對抗", "サードショットゲーム",
    "서드샷 게임", "juego del tercer golpe", "jeu de la troisième frappe",
    "permainan pukulan ketiga", "permainan pukulan ketiga",
    "เกมลูกที่สาม", "trò chơi cú thứ ba")

# ── table tennis ─────────────────────────────────────────────────────────────
add("forehand to forehand", "正手对正手", "正手對正手", "フォア対フォア",
    "포핸드 대 포핸드", "derecha contra derecha", "coup droit contre coup droit",
    "forehand lawan forehand", "forehand lawan forehand",
    "โฟร์แฮนด์ชนโฟร์แฮนด์", "thuận tay đối thuận tay")
add("backhand to backhand", "反手对反手", "反手對反手", "バック対バック",
    "백핸드 대 백핸드", "revés contra revés", "revers contre revers",
    "backhand lawan backhand", "backhand lawan backhand",
    "แบ็กแฮนด์ชนแบ็กแฮนด์", "trái tay đối trái tay")
add("two-one", "两点对一点", "兩點對一點", "2対1", "2대1",
    "dos-uno", "deux-un", "dua-satu", "dua-satu", "สองต่อหนึ่ง", "hai-một")
add("Falkenberg", "法尔肯贝里", "法爾肯貝里", "ファルケンベリ", "팔켄베리",
    "Falkenberg", "Falkenberg", "Falkenberg", "Falkenberg",
    "ฟัลเคนเบิร์ก", "Falkenberg")
add("side to side", "左右移动", "左右移動", "左右の移動", "좌우 이동",
    "de lado a lado", "d'un côté à l'autre", "kiri ke kanan",
    "kiri ke kanan", "ซ้ายไปขวา", "trái sang phải")
add("block against the drive", "挡对方快攻", "擋對方快攻", "ドライブへのブロック",
    "드라이브에 대한 블록", "bloqueo al drive", "bloc face au drive",
    "blok melawan drive", "blok melawan drive", "บล็อกลูกไดรฟ์",
    "chắn bóng đối công")
add("counter-drive", "对攻", "對攻", "カウンタードライブ", "카운터 드라이브",
    "contradrive", "contre-drive", "counter drive", "counter drive",
    "สวนไดรฟ์", "đối công")
add("half-long push rally", "半出台搓球对拉", "半出台搓球對拉",
    "ハーフロングのツッツキ", "하프롱 푸시 랠리",
    "peloteo de push medio largo", "échange de poussettes mi-longues",
    "reli push setengah panjang", "rali push separuh panjang",
    "โต้ลูกจิ้มกึ่งยาว", "đôi công gò nửa dài")
add("against backspin", "对付下旋", "對付下旋", "下回転に対して", "백스핀에 대해",
    "contra cortado", "contre le coupé", "melawan backspin",
    "melawan backspin", "สู้ลูกหลังหมุน", "chống bóng xoáy xuống")
add("against the block", "对付挡球", "對付擋球", "ブロックに対して", "블록에 대해",
    "contra el bloqueo", "contre le bloc", "melawan blok", "melawan blok",
    "สู้ลูกบล็อก", "chống bóng chắn")
add("from the backhand corner", "反手位起板", "反手位起板", "バック側から",
    "백핸드 코너에서", "desde la esquina de revés", "depuis le coin revers",
    "dari sudut backhand", "dari sudut backhand", "จากมุมแบ็กแฮนด์",
    "từ góc trái tay")
add("counter-loop", "反拉", "反拉", "カウンターループ", "카운터 루프",
    "contratop", "contre-top", "counter loop", "counter loop",
    "สวนลูป", "giật đối giật")
add("the short touch", "摆短", "擺短", "ストップ", "짧은 스톱",
    "el toque corto", "la touche courte", "sentuhan pendek",
    "sentuhan pendek", "การหยุดสั้น", "chạm ngắn")
add("the flick", "挑打", "挑打", "フリック", "플릭",
    "el flick", "le flip", "flick", "flick", "การสะบัด", "cú hất")
add("the banana flick", "拧拉", "擰拉", "チキータ", "치키타",
    "el flick banana", "la banane", "banana flick", "banana flick",
    "บานาน่าฟลิก", "cú giật chuối")
add("the long push", "劈长", "劈長", "深いツッツキ", "긴 푸시",
    "el push largo", "la poussette longue", "push panjang",
    "push panjang", "การจิ้มยาว", "gò dài")
add("the smash", "扣杀", "扣殺", "スマッシュ", "스매시",
    "el remate", "le smash", "smes", "smesy", "การตบ", "cú đập")
add("from the wide forehand", "正手大角", "正手大角", "フォアの大きく開いた位置",
    "넓은 포핸드에서", "desde la derecha abierta", "depuis le coup droit large",
    "dari forehand melebar", "dari forehand melebar", "จากโฟร์แฮนด์กว้าง",
    "từ thuận tay rộng")
add("into the body", "追身", "追身", "ボディを狙う", "몸쪽으로",
    "al cuerpo", "sur le corps", "ke badan", "ke badan",
    "เข้าตัว", "vào người")
add("the chop block", "减力挡", "減力擋", "チョップブロック", "촙 블록",
    "el bloqueo cortado", "le bloc coupé", "chop block", "chop block",
    "บล็อกตัด", "chắn cắt")
add("the deep chop", "远台削球", "遠台削球", "深いカット", "먼 거리 커트",
    "el corte lejano", "la coupe lointaine", "chop jauh", "chop jauh",
    "การตัดจากระยะไกล", "cắt bóng xa bàn")
add("the lob and recover", "放高球并回位", "放高球並回位", "ロブと復帰",
    "로브 후 복귀", "el globo y recuperación", "le lob et le replacement",
    "lob lalu pulih", "lob lalu pulih", "ลอบแล้วกลับตำแหน่ง",
    "bạt bổng rồi về vị trí")
add("short backspin", "短下旋", "短下旋", "短い下回転", "짧은 백스핀",
    "cortado corto", "coupé court", "backspin pendek", "backspin pendek",
    "หลังหมุนสั้น", "xoáy xuống ngắn")
add("long and fast", "长且快", "長且快", "速い深い球", "길고 빠르게",
    "largo y rápido", "long et rapide", "panjang dan cepat",
    "panjang dan pantas", "ยาวและเร็ว", "dài và nhanh")
add("sidespin wide", "侧旋大角", "側旋大角", "横回転を大きく外へ",
    "사이드스핀 넓게", "lateral abierto", "latéral large",
    "sidespin melebar", "sidespin melebar", "ข้างหมุนกว้าง",
    "xoáy ngang rộng")
add("serve and third ball", "发球抢攻", "發球搶攻", "サーブ3球目攻撃",
    "서브 3구 공격", "saque y tercera bola", "service et troisième balle",
    "servis dan bola ketiga", "servis dan bola ketiga",
    "เสิร์ฟและลูกที่สาม", "giao bóng và quả ba")
add("half table", "半台", "半台", "ハーフ台", "하프 테이블",
    "media mesa", "demi-table", "setengah meja", "separuh meja",
    "ครึ่งโต๊ะ", "nửa bàn")
add("serve and receive only", "只练发接发", "只練發接發", "サーブとレシーブのみ",
    "서브와 리시브만", "solo saque y resto", "service et retour seulement",
    "hanya servis dan terima", "hanya servis dan terima",
    "เฉพาะเสิร์ฟและรับ", "chỉ giao và đỡ")
add("full match", "整场比赛", "整場比賽", "フルマッチ", "정식 경기",
    "partido completo", "match complet", "pertandingan penuh",
    "perlawanan penuh", "แข่งเต็มรูปแบบ", "trận đấu đầy đủ")

# ── handball ─────────────────────────────────────────────────────────────────
add("star passing", "星形传球", "星形傳球", "スターパス", "스타 패싱",
    "pases en estrella", "passes en étoile", "operan bintang",
    "hantaran bintang", "การส่งรูปดาว", "chuyền hình sao")
add("three lanes", "三线推进", "三線推進", "3レーン", "3레인",
    "tres carriles", "trois couloirs", "tiga jalur", "tiga lorong",
    "สามช่องวิ่ง", "ba làn")
add("with the keeper", "带门将", "帶門將", "GKを入れて", "골키퍼와 함께",
    "con portero", "avec le gardien", "dengan kiper", "dengan penjaga gol",
    "มีผู้รักษาประตู", "có thủ môn")
add("wide to wide", "边到边", "邊到邊", "サイドからサイドへ", "사이드에서 사이드로",
    "de banda a banda", "d'aile à aile", "sayap ke sayap", "sayap ke sayap",
    "ริมถึงริม", "biên sang biên")
add("through the pivot", "通过中锋", "通過中鋒", "ピボット経由", "피벗을 통해",
    "por el pivote", "par le pivot", "lewat pivot", "melalui pivot",
    "ผ่านพิวอต", "qua trung phong")
add("with a second wave", "带第二波", "帶第二波", "第2波を伴って", "2차 파도와 함께",
    "con segunda oleada", "avec la deuxième vague", "dengan gelombang kedua",
    "dengan gelombang kedua", "พร้อมคลื่นที่สอง", "kèm đợt hai")
add("crossing the backs", "后卫交叉", "後衛交叉", "バックの交差", "백코트 교차",
    "cruce de laterales", "croisé des arrières", "silang pemain belakang",
    "silang pemain belakang", "ไขว้ตัวหลัง", "cắt chéo tuyến sau")
add("the wing break-in", "边锋切入", "邊鋒切入", "ウイングの切れ込み", "윙 침투",
    "entrada del extremo", "percée de l'ailier", "penetrasi sayap",
    "penembusan sayap", "ปีกตัดเข้า", "cánh cắt vào")
add("off the pivot's screen", "借中锋掩护", "借中鋒掩護", "ピボットのスクリーンから",
    "피벗 스크린 활용", "tras el bloqueo del pivote", "sur l'écran du pivot",
    "dari screen pivot", "dari screen pivot", "อาศัยการบังของพิวอต",
    "nhờ màn che của trung phong")
add("overloading the left", "左路超载", "左路超載", "左サイドのオーバーロード",
    "왼쪽 과부하", "sobrecarga por la izquierda", "surcharge à gauche",
    "penumpukan di kiri", "penumpuan di kiri", "โหลดคนด้านซ้าย",
    "dồn quân bên trái")
add("seven against six", "七打六", "七打六", "7対6", "7대6",
    "siete contra seis", "sept contre six", "tujuh lawan enam",
    "tujuh lawan enam", "เจ็ดต่อหก", "bảy đánh sáu")
add("the jump shot from 9 m", "九米跳射", "九米跳射", "9mからのジャンプシュート",
    "9m 점프슛", "el lanzamiento en salto desde 9 m", "le tir en suspension à 9 m",
    "tembakan lompat dari 9 m", "tembakan lompat dari 9 m",
    "ยิงกระโดดจากเก้าเมตร", "ném nhảy từ 9 m")
add("from the wing angle", "边锋小角度", "邊鋒小角度", "ウイングの角度から",
    "윙 각도에서", "desde el ángulo del extremo", "depuis l'angle de l'aile",
    "dari sudut sayap", "dari sudut sayap", "จากมุมปีก", "từ góc cánh")
add("the pivot's turn", "中锋转身", "中鋒轉身", "ピボットのターン", "피벗의 턴",
    "el giro del pivote", "la rotation du pivot", "putaran pivot",
    "pusingan pivot", "การหมุนตัวของพิวอต", "trung phong xoay người")
add("after breaking through", "突破之后", "突破之後", "突破の後", "돌파 후",
    "tras la penetración", "après la percée", "setelah menembus",
    "selepas menembusi", "หลังเจาะเข้าไป", "sau khi xuyên phá")
add("first wave", "第一波", "第一波", "第1波", "1차 파도",
    "primera oleada", "première vague", "gelombang pertama",
    "gelombang pertama", "คลื่นแรก", "đợt một")
add("second wave", "第二波", "第二波", "第2波", "2차 파도",
    "segunda oleada", "deuxième vague", "gelombang kedua",
    "gelombang kedua", "คลื่นที่สอง", "đợt hai")
add("third wave", "第三波", "第三波", "第3波", "3차 파도",
    "tercera oleada", "troisième vague", "gelombang ketiga",
    "gelombang ketiga", "คลื่นที่สาม", "đợt ba")
add("the 7 m throw", "七米球", "七米球", "7mスロー", "7m 스로",
    "el penalti de 7 m", "le jet de 7 m", "lemparan 7 m",
    "lemparan 7 m", "ลูกโทษเจ็ดเมตร", "ném phạt 7 m")
add("the 9 m free throw", "九米任意球", "九米任意球", "9mフリースロー",
    "9m 프리스로", "el golpe franco de 9 m", "le jet franc de 9 m",
    "lemparan bebas 9 m", "lemparan bebas 9 m", "ลูกฟรีโทรว์เก้าเมตร",
    "ném phạt tự do 9 m")
add("the throw-off", "开球", "開球", "スローオフ", "스로오프",
    "el saque de centro", "l'engagement", "lemparan awal",
    "lemparan permulaan", "การเปิดเกม", "ném phát bóng")
add("the sideline throw", "边线球", "邊線球", "サイドスロー", "사이드라인 스로",
    "el saque de banda", "la remise en jeu", "lemparan ke dalam",
    "lemparan ke dalam", "ลูกทุ่มข้างสนาม", "ném biên")

# ── rugby ────────────────────────────────────────────────────────────────────
add("in a grid", "网格内", "網格內", "グリッドで", "그리드에서",
    "en cuadrícula", "en quadrillage", "dalam grid", "dalam grid",
    "ในตาราง", "trong lưới ô")
add("in threes", "三人一组", "三人一組", "3人組で", "3인 1조",
    "en tríos", "par trois", "bertiga", "bertiga",
    "กลุ่มละสาม", "theo nhóm ba")
add("across the width", "横贯全宽", "橫貫全寬", "横幅いっぱいに", "폭 전체로",
    "a lo ancho", "sur toute la largeur", "sepanjang lebar",
    "sepanjang lebar", "ตลอดความกว้าง", "suốt chiều ngang")
add("left to right", "从左到右", "從左到右", "左から右へ", "왼쪽에서 오른쪽으로",
    "de izquierda a derecha", "de gauche à droite", "kiri ke kanan",
    "kiri ke kanan", "ซ้ายไปขวา", "trái sang phải")
add("the miss pass", "跳传", "跳傳", "ミスパス", "미스 패스",
    "el pase saltado", "la passe sautée", "miss pass", "miss pass",
    "การส่งข้ามคน", "chuyền vượt tuyến")
add("the switch", "换向", "換向", "スイッチ", "스위치",
    "el cambio de sentido", "le croisé", "switch", "switch",
    "การสลับทิศ", "đổi hướng")
add("the loop", "绕后", "繞後", "ループ", "루프",
    "el loop", "la boucle", "loop", "loop", "การอ้อมหลัง", "vòng sau")
add("the cut-out", "越位传球", "越位傳球", "カットアウト", "컷아웃",
    "el pase largo", "la passe sautée longue", "cut-out", "cut-out",
    "การส่งข้ามยาว", "chuyền cắt xa")
add("with a dummy runner", "带假跑动", "帶假跑動", "ダミーランナー付き",
    "더미 러너 포함", "con corredor señuelo", "avec un leurre",
    "dengan pelari umpan", "dengan pelari umpan", "มีคนวิ่งหลอก",
    "có người chạy nghi binh")
add("the box kick", "盒式踢", "盒式踢", "ボックスキック", "박스 킥",
    "la patada box", "le coup de pied en boîte", "box kick", "box kick",
    "บ็อกซ์คิก", "đá hộp")
add("the cross-field kick", "斜长踢", "斜長踢", "クロスフィールドキック",
    "크로스필드 킥", "la patada cruzada", "le coup de pied croisé",
    "tendangan menyilang", "sepakan menyilang", "เตะข้ามสนาม",
    "đá chéo sân")
add("for territory", "争地盘", "爭地盤", "陣地を取るために", "영역 확보용",
    "por territorio", "pour le terrain", "untuk teritori",
    "untuk wilayah", "เพื่อพื้นที่", "để lấy đất")
add("the grubber", "地滚踢", "地滾踢", "グラバーキック", "그러버 킥",
    "la patada rasa", "le coup de pied à suivre", "grubber", "grubber",
    "ลูกกลิ้งพื้น", "đá bóng sệt")
add("for quick ball", "求快速出球", "求快速出球", "速い球出しのため",
    "빠른 볼 확보", "para balón rápido", "pour un ballon rapide",
    "untuk bola cepat", "untuk bola pantas", "เพื่อบอลออกเร็ว",
    "để ra bóng nhanh")
add("the jackal", "抢断", "搶斷", "ジャッカル", "재칼",
    "el jackal", "le grattage", "jackal", "jackal",
    "การชิงบอล", "cướp bóng")
add("the counter-ruck", "反向争球", "反向爭球", "カウンターラック", "카운터 럭",
    "el contra-ruck", "le contre-ruck", "counter ruck", "counter ruck",
    "การสวนจุดปะทะ", "phản công điểm tranh chấp")
add("pick and go", "近身推进", "近身推進", "ピック＆ゴー", "픽 앤 고",
    "pick and go", "pick and go", "pick and go", "pick and go",
    "หยิบแล้วชน", "nhặt bóng và tiến")
add("in the corner", "角旗区", "角旗區", "コーナーで", "코너에서",
    "en la esquina", "dans le coin", "di sudut", "di sudut",
    "ที่มุมสนาม", "ở góc sân")
add("off the kick chase", "追踢得分", "追踢得分", "キックチェイスから",
    "킥 체이스 후", "tras la persecución", "sur la chasse au pied",
    "dari kejaran tendangan", "daripada kejaran sepakan",
    "จากการไล่ลูกเตะ", "từ pha đuổi bóng")
add("drifting", "横向滑防", "橫向滑防", "ドリフト", "드리프트",
    "en deslizamiento", "en glissement", "drift", "drift",
    "ไถลตาม", "trượt ngang")
add("the blitz", "闪电压上", "閃電壓上", "ブリッツ", "블리츠",
    "el blitz", "le blitz", "blitz", "blitz", "บลิตซ์", "áp sát chớp nhoáng")
add("scrambling back", "回追补位", "回追補位", "スクランブル", "스크램블 백",
    "repliegue de emergencia", "repli d'urgence", "mundur darurat",
    "berundur kecemasan", "ถอยกลับฉุกเฉิน", "lùi về vá lỗi")
add("the five-man lineout", "五人边线球", "五人邊線球", "5人ラインアウト",
    "5인 라인아웃", "el touch de cinco", "la touche à cinq",
    "lineout lima orang", "lineout lima orang", "ไลน์เอาท์ห้าคน",
    "ném biên năm người")
add("the seven-man lineout", "七人边线球", "七人邊線球", "7人ラインアウト",
    "7인 라인아웃", "el touch de siete", "la touche à sept",
    "lineout tujuh orang", "lineout tujuh orang", "ไลน์เอาท์เจ็ดคน",
    "ném biên bảy người")
add("the scrum", "争球", "爭球", "スクラム", "스크럼",
    "la melé", "la mêlée", "scrum", "scrum", "สครัม", "bó rối")
add("receiving the kick-off", "接开球", "接開球", "キックオフレシーブ",
    "킥오프 리시브", "la recepción del saque", "la réception du coup d'envoi",
    "menerima kick-off", "menerima sepak mula", "การรับลูกเปิดเกม",
    "nhận bóng phát")
add("handling", "传接", "傳接", "ハンドリング", "핸들링",
    "manejo", "maniement", "penguasaan", "pengendalian",
    "การรับส่ง", "xử lý bóng")

# ── field hockey ─────────────────────────────────────────────────────────────
add("dribbling gates", "带球过门", "帶球過門", "ゲートドリブル", "게이트 드리블",
    "puertas de conducción", "portes de conduite", "gerbang dribel",
    "pintu giring", "ประตูเลี้ยงบอล", "cổng dẫn bóng")
add("passing in pairs", "两人传球", "兩人傳球", "ペアパス", "2인 패스",
    "pases por parejas", "passes par deux", "operan berpasangan",
    "hantaran berpasangan", "ส่งบอลเป็นคู่", "chuyền theo cặp")
add("elimination skills", "过人技术", "過人技術", "抜きの技術", "제치기 기술",
    "recursos de desborde", "gestes d'élimination", "teknik melewati lawan",
    "teknik melepasi lawan", "ทักษะการเลี้ยงผ่าน", "kỹ thuật vượt người")
add("from the back", "从后场", "從後場", "後方から", "후방에서",
    "desde atrás", "depuis l'arrière", "dari belakang", "dari belakang",
    "จากแดนหลัง", "từ tuyến dưới")
add("through midfield", "经中场", "經中場", "中盤経由", "미드필드를 통해",
    "por el medio", "par le milieu", "lewat lini tengah",
    "melalui barisan tengah", "ผ่านกองกลาง", "qua tuyến giữa")
add("switching the ball", "转移球", "轉移球", "サイドチェンジ", "볼 전환",
    "cambiando el juego", "renversement", "memindahkan bola",
    "memindahkan bola", "การเปลี่ยนข้าง", "chuyển hướng bóng")
add("on the overlap", "套边跑", "套邊跑", "オーバーラップで", "오버래핑으로",
    "en el desdoble", "en débordement", "dengan overlap", "dengan overlap",
    "วิ่งอ้อมด้านนอก", "chồng biên")
add("give and go", "撞墙配合", "撞牆配合", "ワンツー", "원투 패스",
    "pared", "une-deux", "wall pass", "wall pass",
    "วันทู", "phối hợp một-hai")
add("along the baseline", "沿底线", "沿底線", "ゴールライン沿い", "골라인 따라",
    "por la línea de fondo", "le long de la ligne de but",
    "menyusur garis belakang", "menyusur garisan belakang",
    "ตามเส้นหลัง", "dọc đường biên ngang")
add("the deflection", "折射攻门", "折射攻門", "ディフレクション", "굴절 슛",
    "el desvío", "la déviation", "defleksi", "pesongan",
    "การเปลี่ยนทิศบอล", "đổi hướng bóng")
add("on the reverse", "反手推射", "反手推射", "リバースで", "리버스로",
    "de revés", "en revers", "dengan reverse", "dengan reverse",
    "ด้วยไม้กลับด้าน", "bằng mặt trái gậy")
add("the tomahawk", "反手抽射", "反手抽射", "トマホーク", "토마호크",
    "el tomahawk", "le tomahawk", "tomahawk", "tomahawk",
    "โทมาฮอว์ก", "cú tomahawk")
add("off the rebound", "补射", "補射", "リバウンドから", "리바운드에서",
    "al rechace", "sur le rebond", "dari bola muntah", "daripada bola muntah",
    "จากลูกกระดอน", "từ bóng bật ra")
add("in the circle", "圆圈内", "圓圈內", "サークル内で", "서클 안에서",
    "en el área", "dans le cercle", "di dalam lingkaran",
    "di dalam bulatan", "ในวงกลมยิง", "trong vòng cung")
add("pressing", "压迫", "壓迫", "プレス", "압박",
    "presionando", "en pressing", "pressing", "menekan",
    "การกดดัน", "gây áp lực")
add("the drag flick", "推射角球", "推射角球", "ドラッグフリック", "드래그 플릭",
    "el drag flick", "le drag-flick", "drag flick", "drag flick",
    "แดร็กฟลิก", "cú hất kéo")
add("the straight strike", "直接抽射", "直接抽射", "ストレートショット", "직선 슛",
    "el golpeo directo", "la frappe directe", "pukulan lurus",
    "pukulan lurus", "การตีตรง", "cú đánh thẳng")
add("a variation to the left", "左路变化", "左路變化", "左への変化", "왼쪽 변형",
    "una variante por la izquierda", "une variante à gauche",
    "variasi ke kiri", "variasi ke kiri", "แผนแปรทางซ้าย",
    "biến thể bên trái")
add("defending it", "防守短角球", "防守短角球", "その守り方", "그 수비",
    "defendiéndolo", "sa défense", "bertahan menghadapinya",
    "bertahan menghadapinya", "การป้องกันมัน", "cách phòng thủ")
add("into a free hit routine", "自由球战术", "自由球戰術", "フリーヒットの型",
    "프리 히트 루틴", "una jugada de golpe franco", "une routine de coup franc",
    "rutinitas free hit", "rutin free hit", "แผนลูกฟรีฮิต",
    "bài đánh phạt trực tiếp")

# ── water polo ───────────────────────────────────────────────────────────────
add("eggbeater and pass", "踩水传球", "踩水傳球", "巻き足とパス", "에그비터와 패스",
    "batido y pase", "rétropédalage et passe", "eggbeater dan umpan",
    "eggbeater dan hantaran", "ตีขาลอยตัวและส่งบอล", "đạp nước và chuyền")
add("swim and catch", "游动接球", "游動接球", "泳いでキャッチ", "헤엄쳐 받기",
    "nadar y recibir", "nager et attraper", "berenang dan menangkap",
    "berenang dan menangkap", "ว่ายและรับบอล", "bơi và bắt bóng")
add("wet passing", "湿手传球", "濕手傳球", "ウェットパス", "웨트 패스",
    "pase mojado", "passe mouillée", "umpan basah", "hantaran basah",
    "การส่งบอลเปียก", "chuyền bóng ướt")
add("through the centre", "通过中锋", "通過中鋒", "センター経由", "센터를 통해",
    "por el boya", "par la pointe", "lewat center", "melalui center",
    "ผ่านเซ็นเตอร์", "qua trung phong")
add("drive and kick", "突破分球", "突破分球", "ドライブ＆キック", "드라이브 앤 킥",
    "penetrar y descargar", "pénétrer et ressortir", "menerobos lalu umpan",
    "menerobos lalu hantar", "เจาะแล้วจ่ายออก", "xuyên phá rồi chuyền ra")
add("the umbrella", "伞形站位", "傘形站位", "アンブレラ", "엄브렐러",
    "la sombrilla", "le parapluie", "payung", "payung",
    "รูปร่ม", "hình ô")
add("the entry pass", "内传球", "內傳球", "エントリーパス", "엔트리 패스",
    "el pase interior", "la passe d'entrée", "umpan masuk",
    "hantaran masuk", "การส่งเข้าใน", "đường chuyền vào")
add("the backhand", "反手射门", "反手射門", "バックハンドシュート", "백핸드 슛",
    "el revés", "le revers", "backhand", "backhand",
    "ลูกแบ็กแฮนด์", "ném trái tay")
add("the sweep shot", "扫射", "掃射", "スイープシュート", "스윕 슛",
    "el barrido", "le tir balayé", "tembakan sapu", "tembakan sapu",
    "ลูกกวาด", "cú ném quét")
add("drawing the exclusion", "造罚出", "造罰出", "退水を誘う", "퇴수 유도",
    "provocando la expulsión", "provoquer l'exclusion",
    "memancing pengeluaran", "memancing pengusiran",
    "การล่อให้โดนไล่", "câu lỗi loại tạm")
add("five against six", "五打六", "五打六", "5対6", "5대6",
    "cinco contra seis", "cinq contre six", "lima lawan enam",
    "lima lawan enam", "ห้าต่อหก", "năm chống sáu")
add("fronting the centre", "绕前防中锋", "繞前防中鋒", "センターのフロント",
    "센터 앞막기", "fronteando al boya", "défense devant la pointe",
    "menutup depan center", "menutup depan center",
    "ยืนหน้าเซ็นเตอร์", "chặn trước trung phong")
add("the five-metre penalty", "五米点球", "五米點球", "5mペナルティ", "5m 페널티",
    "el penalti de cinco metros", "le penalty à cinq mètres",
    "penalti lima meter", "penalti lima meter",
    "ลูกโทษห้าเมตร", "phạt đền năm mét")
add("the quick free throw", "快发任意球", "快發任意球", "クイックフリースロー",
    "빠른 프리스로", "el libre rápido", "le coup franc rapide",
    "lemparan bebas cepat", "lemparan bebas pantas",
    "ลูกฟรีโทรว์เร็ว", "ném phạt nhanh")
add("the swim-off", "抢球开局", "搶球開局", "スイムオフ", "스윔오프",
    "el esprint inicial", "le sprint d'engagement", "sprint pembuka",
    "pecutan pembuka", "การว่ายชิงบอล", "bơi tranh bóng")

add("stack", "叠加站位", "疊加站位", "スタック", "스택",
    "apilado", "empilement", "stack", "stack", "การยืนซ้อน", "xếp chồng")
add("the drop", "吊小球", "吊小球", "ドロップ", "드롭",
    "la dejada", "l'amorti", "dropshot", "dropshot", "ลูกหยอด", "bỏ nhỏ")
add("the overhead", "高压球", "高壓球", "スマッシュ", "오버헤드",
    "el smash", "le smash", "smash", "smes", "ลูกเหนือหัว", "cú đập trên đầu")

add("touch 5v5", "触身式 5v5", "觸身式 5v5", "タッチ 5v5", "터치 5대5",
    "touch 5c5", "touch 5c5", "touch 5v5", "touch 5v5",
    "ทัชรักบี้ 5v5", "touch 5v5")
add("sevens 7v7", "七人制 7v7", "七人制 7v7", "セブンズ 7v7", "세븐스 7대7",
    "seven 7c7", "à sept 7c7", "rugby tujuh 7v7", "ragbi tujuh 7v7",
    "รักบี้เจ็ดคน 7v7", "rugby bảy người 7v7")
add("contact 8v8", "全接触 8v8", "全接觸 8v8", "コンタクト 8v8", "콘택트 8대8",
    "contacto 8c8", "avec contact 8c8", "kontak 8v8", "kontak 8v8",
    "ปะทะเต็มรูปแบบ 8v8", "va chạm 8v8")

# Volleyball zone numbers. Not neutral — a number alone is not what a coach
# in any of these languages calls the position.
for _n in range(1, 7):
    add(f"zone {_n}", f"{_n}号位", f"{_n}號位", f"ゾーン{_n}", f"{_n}번 자리",
        f"zona {_n}", f"zone {_n}", f"zona {_n}", f"zon {_n}",
        f"ตำแหน่ง {_n}", f"vị trí {_n}")

# ── baseball ─────────────────────────────────────────────────────────────────
add("long toss", "长传接球", "長傳接球", "ロングトス", "롱토스",
    "tiro largo", "longs lancers", "lempar jarak jauh", "balingan jarak jauh",
    "ขว้างระยะไกล", "ném xa")
add("infield and outfield", "内外野守备", "內外野守備", "シートノック",
    "내외야 수비", "cuadro y jardines", "champ intérieur et extérieur",
    "infield dan outfield", "infield dan outfield",
    "อินฟิลด์และเอาต์ฟิลด์", "trong sân và ngoài sân")
add("pitchers fielding practice", "投手守备练习", "投手守備練習", "投手の守備練習",
    "투수 수비 훈련", "defensa del lanzador", "défense du lanceur",
    "latihan bertahan pitcher", "latihan pertahanan pitcher",
    "ซ้อมรับของพิตเชอร์", "tập phòng thủ cho người ném")
add("to home", "传本垒", "傳本壘", "本塁へ", "홈으로",
    "a home", "vers le marbre", "ke home", "ke home",
    "ไปโฮมเพลต", "về chốt nhà")
add("to third", "传三垒", "傳三壘", "三塁へ", "3루로",
    "a tercera", "vers le troisième but", "ke base tiga", "ke base tiga",
    "ไปเบสสาม", "về chốt ba")
add("on the gap ball", "两人之间的球", "兩人之間的球", "ギャップへの打球",
    "갭 타구에서", "en la bola al hueco", "sur la balle dans l'intervalle",
    "pada bola di celah", "pada bola di celah", "ลูกลงช่องว่าง",
    "bóng vào khe")
add("reading the steal", "判断盗垒时机", "判斷盜壘時機", "スタートの見極め",
    "도루 타이밍 읽기", "leyendo el robo", "lecture du vol de but",
    "membaca waktu mencuri base", "membaca masa mencuri base",
    "อ่านจังหวะขโมยเบส", "đọc thời điểm cướp chốt")
add("the hit and run", "打带跑", "打帶跑", "ヒットエンドラン", "히트 앤 런",
    "el bateo y corrido", "le frappé-couru", "hit and run", "hit and run",
    "ฮิตแอนด์รัน", "đánh và chạy")
add("tagging up", "触垒再跑", "觸壘再跑", "タッチアップ", "태그업",
    "el toque y salida", "le renvoi après prise", "tag up", "tag up",
    "แตะเบสแล้ววิ่ง", "chạm chốt rồi chạy")
add("first to third", "一垒跑三垒", "一壘跑三壘", "一塁から三塁へ", "1루에서 3루로",
    "de primera a tercera", "de première à troisième",
    "dari base satu ke base tiga", "dari base satu ke base tiga",
    "จากเบสหนึ่งไปเบสสาม", "từ chốt một tới chốt ba")
add("the secondary lead", "二次离垒", "二次離壘", "セカンドリード", "세컨드 리드",
    "la segunda salida", "le second décollage", "lead kedua", "lead kedua",
    "การออกห่างเบสรอบสอง", "bước rời chốt lần hai")
add("the contact play", "击中即跑", "擊中即跑", "コンタクトプレー", "콘택트 플레이",
    "la jugada de contacto", "le jeu au contact", "contact play",
    "contact play", "การวิ่งเมื่อโดนบอล", "chạy khi chạm bóng")
add("the squeeze", "强迫取分", "強迫取分", "スクイズ", "스퀴즈",
    "el toque suicida", "le squeeze", "squeeze", "squeeze",
    "สควีซ", "đánh nhẹ ép điểm")
add("scoring from second", "二垒回本垒", "二壘回本壘", "二塁からの生還",
    "2루에서 득점", "anotar desde segunda", "marquer depuis le deuxième but",
    "mencetak dari base dua", "menjaringkan dari base dua",
    "ทำแต้มจากเบสสอง", "ghi điểm từ chốt hai")
add("against the bunt", "防触击", "防觸擊", "バント守備", "번트 수비",
    "contra el toque", "contre l'amorti", "melawan bunt", "melawan bunt",
    "รับลูกบันต์", "chống bóng chạm nhẹ")
add("first and third", "一三垒有人", "一三壘有人", "一三塁", "1·3루",
    "primera y tercera", "premier et troisième", "base satu dan tiga",
    "base satu dan tiga", "มีคนที่เบสหนึ่งและสาม", "có người ở chốt một và ba")
add("with the infield in", "内野前移", "內野前移", "前進守備", "내야 전진 수비",
    "con el cuadro adelantado", "champ intérieur avancé",
    "dengan infield maju", "dengan infield ke hadapan",
    "อินฟิลด์ขยับเข้า", "hàng trong dâng lên")
add("the pop-up priority", "高飞球呼叫顺位", "高飛球呼叫順位", "フライの優先順位",
    "뜬공 우선권", "la prioridad en el elevado", "la priorité sur la chandelle",
    "prioritas bola melambung", "keutamaan bola melambung",
    "ลำดับการเรียกลูกลอย", "quyền ưu tiên bóng bổng")
add("the pick-off at first", "一垒牵制", "一壘牽制", "一塁牽制", "1루 견제",
    "el pisa y corre en primera", "le tir au premier but",
    "pick-off di base satu", "pick-off di base satu",
    "การเช็คที่เบสหนึ่ง", "kiểm tra chốt một")
add("the pick-off at second", "二垒牵制", "二壘牽制", "二塁牽制", "2루 견제",
    "el pisa y corre en segunda", "le tir au deuxième but",
    "pick-off di base dua", "pick-off di base dua",
    "การเช็คที่เบสสอง", "kiểm tra chốt hai")
add("the rundown", "夹杀", "夾殺", "挟殺プレー", "런다운",
    "el atrapado entre bases", "la prise en souricière", "rundown", "rundown",
    "การไล่แท็กระหว่างเบส", "kẹp giữa hai chốt")
add("the pitch-out", "外角故意投偏", "外角故意投偏", "ピッチアウト", "피치아웃",
    "el lanzamiento fuera", "le lancer écarté", "pitch-out", "pitch-out",
    "การขว้างออกนอก", "ném lệch chủ động")
add("two outs, runner on second", "两出局二垒有人", "兩出局二壘有人",
    "2アウト二塁", "2아웃 주자 2루", "dos outs, corredor en segunda",
    "deux retraits, coureur au deuxième", "dua out, pelari di base dua",
    "dua out, pelari di base dua", "สองเอาต์ มีคนที่เบสสอง",
    "hai loại, người chạy ở chốt hai")
add("bases loaded", "满垒", "滿壘", "満塁", "만루",
    "bases llenas", "bases pleines", "base penuh", "base penuh",
    "เบสเต็ม", "đầy chốt")
add("the baserunning game", "跑垒对抗", "跑壘對抗", "走塁ゲーム", "주루 게임",
    "el juego de corrido", "le jeu de course sur les buts",
    "permainan lari base", "permainan larian base",
    "เกมวิ่งเบส", "trò chơi chạy chốt")

# ── sepak takraw ─────────────────────────────────────────────────────────────
add("juggling in pairs", "两人颠球", "兩人顛球", "二人でリフティング",
    "둘이 저글링", "malabares por parejas", "jonglage à deux",
    "juggling berpasangan", "juggling berpasangan", "เดาะบอลเป็นคู่",
    "tâng bóng theo cặp")
add("on every surface", "全部位触球", "全部位觸球", "全部位で",
    "모든 부위로", "con todas las superficies", "avec toutes les surfaces",
    "dengan semua bagian badan", "dengan semua bahagian badan",
    "ด้วยทุกส่วนของร่างกาย", "bằng mọi bộ phận")
add("keeping it up as three", "三人不落地", "三人不落地", "3人でつなぐ",
    "셋이 이어가기", "manteniéndola entre tres", "à trois sans faute",
    "bertahan bertiga", "bertahan bertiga", "สามคนไม่ให้ตก",
    "ba người giữ bóng")
add("receiving the serve", "接发球", "接發球", "サーブレシーブ", "서브 리시브",
    "recepción del saque", "réception du service", "menerima servis",
    "menerima servis", "การรับเสิร์ฟ", "đỡ giao cầu")
add("the high feed", "高传", "高傳", "高いトス", "높은 토스",
    "el pase alto", "la passe haute", "umpan tinggi", "umpanan tinggi",
    "การชงสูง", "chuyền cao")
add("the quick feed", "快传", "快傳", "速いトス", "빠른 토스",
    "el pase rápido", "la passe rapide", "umpan cepat", "umpanan pantas",
    "การชงเร็ว", "chuyền nhanh")
add("the roll spike", "转体倒钩", "轉體倒鉤", "ローリングアタック", "롤 스파이크",
    "el remate en giro", "l'attaque roulée", "smes gulung", "rejaman gulung",
    "ลูกฟาดม้วนตัว", "đá xoay người")
add("the scissor kick", "剪刀腿扣杀", "剪刀腿扣殺", "シザースキック", "가위차기",
    "la tijera", "le ciseau", "tendangan gunting", "sepakan gunting",
    "ลูกฟาดกรรไกร", "đá kéo")
add("the sunback spike", "背向倒挂", "背向倒掛", "サンバックアタック", "선백 스파이크",
    "el remate de espaldas", "l'attaque dos au filet", "smes sunback",
    "rejaman sunback", "ลูกฟาดหลังหัน", "đá lộn người")
add("the feint", "假动作", "假動作", "フェイント", "페인트",
    "la finta", "la feinte", "gerak tipu", "gerak tipu",
    "การหลอก", "động tác giả")
add("at the net", "网前", "網前", "ネット際で", "네트 앞에서",
    "en la red", "au filet", "di depan net", "di depan jaring",
    "หน้าเน็ต", "trên lưới")
add("behind the block", "拦网身后", "攔網身後", "ブロックの後ろ", "블록 뒤",
    "detrás del bloqueo", "derrière le contre", "di belakang blok",
    "di belakang blok", "หลังบล็อก", "sau hàng chắn")
add("covering the block", "保护拦网", "保護攔網", "ブロックのカバー",
    "블록 커버", "cubriendo el bloqueo", "couverture du contre",
    "menutup blok", "menutup blok", "คุมหลังบล็อก", "bọc lót hàng chắn")
add("with no block", "不设拦网", "不設攔網", "ブロックなしで", "블록 없이",
    "sin bloqueo", "sans contre", "tanpa blok", "tanpa blok",
    "ไม่มีบล็อก", "không hàng chắn")

# ── beach tennis and footvolley ──────────────────────────────────────────────
add("volley exchange", "截击对练", "截擊對練", "ボレーの打ち合い", "발리 주고받기",
    "intercambio de voleas", "échange de volées", "adu voli", "adu voli",
    "โต้วอลเลย์", "đôi công vô lê")
add("short court", "缩短场地", "縮短場地", "ショートコート", "숏 코트",
    "pista corta", "terrain réduit", "lapangan pendek", "gelanggang pendek",
    "คอร์ทสั้น", "sân ngắn")
add("king of the court", "擂台赛", "擂台賽", "キング・オブ・ザ・コート",
    "킹 오브 더 코트", "rey de la pista", "roi du terrain",
    "raja lapangan", "raja gelanggang", "คิงออฟเดอะคอร์ท", "vua sân")
add("chest control", "胸部停球", "胸部停球", "胸トラップ", "가슴 트래핑",
    "control de pecho", "contrôle de la poitrine", "kontrol dada",
    "kawalan dada", "การคุมบอลด้วยอก", "khống chế bằng ngực")
add("the shoulder pass", "肩传", "肩傳", "肩でのパス", "어깨 패스",
    "el pase de hombro", "la passe de l'épaule", "umpan bahu",
    "hantaran bahu", "การส่งด้วยไหล่", "chuyền bằng vai")
add("the shark attack", "鲨鱼式扣杀", "鯊魚式扣殺", "シャークアタック", "샤크 어택",
    "el ataque tiburón", "l'attaque requin", "serangan shark",
    "serangan shark", "ชาร์กแอทแทค", "cú tấn công cá mập")
add("the sombrero", "帽子过顶", "帽子過頂", "ソンブレロ", "솜브레로",
    "el sombrero", "le sombrero", "sombrero", "sombrero",
    "ซอมเบรโร", "cú sombrero")
add("the bicycle kick", "倒钩", "倒鉤", "オーバーヘッドキック", "오버헤드킥",
    "la chilena", "le retourné", "tendangan salto", "sepakan kilas",
    "ลูกจักรยานอากาศ", "cú ngả bàn đèn")
add("the header", "头球", "頭球", "ヘディング", "헤딩",
    "el cabezazo", "la tête", "sundulan", "tandukan",
    "ลูกโหม่ง", "cú đánh đầu")
add("the dig", "救球", "救球", "ディグ", "디그",
    "la defensa baja", "la défense basse", "dig", "dig",
    "การรับลูกต่ำ", "cú đỡ bóng")

# ── basketball ───────────────────────────────────────────────────────────────
add("top", "弧顶", "弧頂", "トップ", "탑",
    "frontal", "au sommet", "puncak", "puncak", "ยอดวงสามคะแนน", "đỉnh vòng")
add("the corner", "底角", "底角", "コーナー", "코너",
    "la esquina", "le corner", "sudut", "sudut", "มุมสนาม", "góc sân")
add("the elbow", "肘区", "肘區", "エルボー", "엘보우",
    "el codo", "le coude", "elbow", "elbow", "จุดเอลโบว์", "vị trí elbow")
add("the backdoor cut", "反跑空切", "反跑空切", "バックドアカット", "백도어 컷",
    "la puerta atrás", "la porte arrière", "backdoor cut", "backdoor cut",
    "การตัดหลัง", "cắt sau lưng")
add("the flare", "外弹掩护", "外彈掩護", "フレアカット", "플레어 컷",
    "el flare", "le flare", "flare cut", "flare cut",
    "การตัดออกด้านนอก", "cắt bung ra")
add("the drop step", "转身勾手", "轉身勾手", "ドロップステップ", "드롭 스텝",
    "el paso atrás", "le drop step", "drop step", "drop step",
    "ดรอปสเต็ป", "bước xoay lưng")
add("facing up", "面框单打", "面框單打", "フェイスアップ", "페이스업",
    "de cara al aro", "face au panier", "face up", "face up",
    "หันหน้าเข้าห่วง", "quay mặt rổ")
add("the kick-out", "分球外线", "分球外線", "キックアウト", "킥아웃",
    "la asistencia al exterior", "la ressortie", "kick-out", "kick-out",
    "การจ่ายออกนอก", "chuyền ra ngoài")
add("the short roll", "短顺下", "短順下", "ショートロール", "숏 롤",
    "el roll corto", "le roll court", "short roll", "short roll",
    "ชอร์ตโรล", "cắt xuống ngắn")
add("in drop coverage", "退防挡拆", "退防擋拆", "ドロップの守り方", "드롭 커버리지",
    "en drop", "en drop", "coverage drop", "coverage drop",
    "รับแบบดรอป", "phòng thủ lùi")
add("hedging", "上提延误", "上提延誤", "ヘッジ", "헤지",
    "en hedge", "en hedge", "hedging", "hedging",
    "ออกมาสกัดชั่วคราว", "chặn tạm")
add("switching", "换防", "換防", "スイッチ", "스위치",
    "cambiando", "en changement", "switching", "switching",
    "การสลับประกบ", "đổi người")
add("icing the side screen", "封边挡拆", "封邊擋拆", "アイス", "아이스",
    "haciendo ice", "en ice", "ice screen samping", "ice screen tepi",
    "การไอซ์สกรีนข้าง", "ép biên màn chắn")
add("the box", "盒式站位", "盒式站位", "ボックス", "박스",
    "la caja", "la boîte", "formasi kotak", "formasi kotak",
    "รูปกล่อง", "đội hình hộp")
add("the zipper", "拉链跑位", "拉鏈跑位", "ジッパー", "지퍼 컷",
    "la cremallera", "le zipper", "zipper", "zipper",
    "การวิ่งซิปเปอร์", "chạy zipper")
add("from the sideline", "边线发球", "邊線發球", "サイドラインから", "사이드라인에서",
    "desde la banda", "depuis la ligne de touche", "dari garis samping",
    "dari garisan tepi", "จากเส้นข้าง", "từ đường biên dọc")

# ── Seam repairs (2026-09-05 review) ─────────────────────────────────────────
# A family name composes as "<family> <variant>", and in these entries one
# locale's variant carried the family's own noun — "Spike the roll spike",
# "Passe haute passe avant". Only the broken locale is overridden; the key
# stays the full English term so the call sites read naturally.
def fix(key, **locs):
    for loc, text in locs.items():
        V[key][loc.replace('_', '-')] = text


fix("front set", fr_FR="vers l'avant")
fix("back set", fr_FR="vers l'arrière")
fix("jump set", fr_FR="en suspension")
fix("high block", fr_FR="haut")
fix("mid block", fr_FR="médian")
fix("low block", fr_FR="bas")
fix("spinning net", en="with spin", **{"en_GB": "with spin"})
fix("the shark attack", es_ES="el tiburón")
fix("half-long push rally", en="half-long pushes", en_GB="half-long pushes")
fix("counter-loop", en="countering", en_GB="countering")
fix("the short touch", en="the touch", en_GB="the touch")
fix("full match", en="a whole match", en_GB="a whole match")
fix("scoring from second", en="from second", en_GB="from second")
fix("third shot game", en="third shots only", en_GB="third shots only")
fix("chest control", en="with the chest", en_GB="with the chest")
fix("receiving the serve", en="off the serve", en_GB="off the serve")
fix("the high feed", en="high", en_GB="high")
fix("the quick feed", en="fast", en_GB="fast")
fix("the roll spike", en="the roll", en_GB="the roll",
    ja_JP="ローリング", ko_KR="롤", id_ID="gulung", ms_MY="gulung",
    es_ES="en giro", fr_FR="roulée", vi_VN="xoay người")
fix("the sunback spike", en="the sunback", en_GB="the sunback",
    ja_JP="サンバック", ko_KR="선백", id_ID="sunback", ms_MY="sunback",
    es_ES="de espaldas", fr_FR="dos au filet")
fix("the high feed", fr_FR="haute")
fix("the quick feed", fr_FR="rapide")
fix("receiving the serve", fr_FR="sur réception")
fix("scoring from second", fr_FR="depuis le deuxième but")
fix("front set", en="to the front", en_GB="to the front")
fix("back set", en="behind the head", en_GB="behind the head")
fix("jump set", en="off the jump", en_GB="off the jump")
fix("full match", en="a full game", en_GB="a full game")

# ── Coach-review corrections (2026-09-05) ────────────────────────────────────
# Volleyball floor-defence systems. "Man-up" is handball and water polo
# vocabulary; volleyball's third system is middle-up, 心跟进 in every Chinese
# textbook, with rotation being 边跟进. These three keys are used only by the
# volleyball defence family, so retargeting them is safe.
fix("man-up", en="middle-up", en_GB="middle-up",
    zh_CN="心跟进", zh_TW="心跟進", ja_JP="ミドルアップ", ko_KR="미들업",
    es_ES="con el 6 adelantado", fr_FR="6 avancé",
    id_ID="middle-up", ms_MY="middle-up", th_TH="ระบบ 6 ขึ้นหน้า",
    vi_VN="số 6 dâng")
fix("rotation", zh_CN="边跟进", zh_TW="邊跟進")
fix("perimeter", zh_CN="马蹄形站位", zh_TW="馬蹄形站位",
    ja_JP="ミドルバック", ko_KR="미들백")

add("set position", "预备姿势", "預備姿勢", "構え", "준비 자세",
    "posición de base", "position d'attente", "posisi siap", "kedudukan sedia",
    "ท่าเตรียมรับ", "tư thế chuẩn bị")
add("sweeping behind the line", "防线身后清扫", "防線身後清掃",
    "スイーパーキーパー", "스위퍼 키퍼", "de líbero tras la línea",
    "en libéro derrière la ligne", "menyapu di belakang garis",
    "menyapu di belakang barisan", "กวาดหลังแนวรับ", "quét sau hàng thủ")
add("driving from the lineout", "边线球起推", "邊線球起推",
    "ラインアウトからのドライブ", "라인아웃 드라이브",
    "desde el touch", "sur touche", "dorongan dari lineout",
    "tolakan dari lineout", "ดันจากไลน์เอาท์", "đẩy từ ném biên")
add("the middle ball", "中路球", "中路球", "真ん中のボール", "가운데 공",
    "la bola al medio", "la balle au milieu", "bola tengah", "bola tengah",
    "ลูกกลาง", "bóng vào giữa")
add("switching sides", "左右换位", "左右換位", "サイドチェンジ", "사이드 교대",
    "cambio de lados", "changement de côtés", "bertukar sisi",
    "bertukar sisi", "สลับฝั่ง", "đổi bên")
add("over the net pair", "越过网前二人", "越過網前二人", "前衛の頭上へ",
    "네트 조 머리 위로", "por encima de la pareja en red",
    "par-dessus la paire au filet", "melewati pasangan di net",
    "melepasi pasangan di jaring", "ข้ามคู่หน้าเน็ต", "qua đầu cặp trên lưới")
add("recovering it", "回追处理", "回追處理", "追って処理", "쫓아가 처리",
    "recuperándolo", "le rattraper", "mengejarnya", "mengejarnya",
    "ไล่เก็บ", "đuổi theo xử lý")
add("on the attack", "转入进攻", "轉入進攻", "攻めながら", "공격적으로",
    "atacando", "offensif", "sambil menyerang", "sambil menyerang",
    "เชิงรุก", "vừa đỡ vừa công")
add("with the thigh", "大腿停球", "大腿停球", "腿トラップ", "허벅지 트래핑",
    "con el muslo", "de la cuisse", "dengan paha", "dengan peha",
    "ด้วยต้นขา", "bằng đùi")
add("off the quick set", "快球进攻", "快球進攻", "クイックトスから", "퀵 세트에서",
    "tras colocación rápida", "sur passe rapide", "dari umpan cepat",
    "dari umpanan pantas", "จากการเซตเร็ว", "từ chuyền nhanh")
add("from the back court", "后场进攻", "後場進攻", "後方から", "후위에서",
    "desde el fondo", "depuis l'arrière", "dari belakang", "dari belakang",
    "จากแดนหลัง", "từ cuối sân")
add("attacking the second ball", "二次球突袭", "二次球突襲", "2タッチ目で攻める",
    "두 번째 터치 공격", "atacando el segundo toque",
    "attaquer la deuxième touche", "menyerang sentuhan kedua",
    "menyerang sentuhan kedua", "บุกด้วยสัมผัสที่สอง", "tấn công ngay chạm hai")
add("1v1 at the net", "网前 1v1", "網前 1v1", "ネット際の1対1", "네트 1대1",
    "1c1 en la red", "1c1 au filet", "1v1 di net", "1v1 di jaring",
    "1v1 หน้าเน็ต", "1v1 trên lưới")
add("off the high toss", "高抛", "高拋", "高いトスから", "높은 토스에서",
    "con lanzamiento alto", "sur lancer haut", "dari lambungan tinggi",
    "dari lambungan tinggi", "จากการโยนสูง", "từ cú tung cao")
add("driven low", "低平抽射", "低平抽射", "低く鋭く", "낮고 강하게",
    "raso y tenso", "tendu et bas", "mendatar rendah", "mendatar rendah",
    "เรียบต่ำ", "căng thấp")
add("on the left", "左侧", "左側", "左サイド", "왼쪽",
    "por la izquierda", "à gauche", "sisi kiri", "sebelah kiri",
    "ฝั่งซ้าย", "bên trái")
add("on the right", "右侧", "右側", "右サイド", "오른쪽",
    "por la derecha", "à droite", "sisi kanan", "sebelah kanan",
    "ฝั่งขวา", "bên phải")
add("behind your own attack", "攻手身后", "攻手身後", "自軍アタックの後ろ",
    "자기 공격 뒤", "tras vuestro remate", "derrière votre attaque",
    "di belakang serangan sendiri", "di belakang serangan sendiri",
    "หลังตัวฟาดฝั่งตัวเอง", "sau chân đá của đội mình")
add("full regu", "整队对抗", "整隊對抗", "レグ戦", "레구 경기",
    "regu completo", "regu complet", "regu penuh", "regu penuh",
    "เรกูเต็มทีม", "regu đầy đủ")
