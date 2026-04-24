#!/usr/bin/env python3
"""Generate fastlane metadata for the 8 new sports across 11 locales.

Pattern matched from existing sports:
- en-US, zh-Hans: all 6 files (name, subtitle, keywords, description, promotional_text, release_notes)
- other 9 locales: 4 files (name, subtitle, keywords, release_notes)
"""
import os

BASE = os.path.join(os.path.dirname(__file__), "..", "fastlane", "metadata")

# Release notes for 1.1.6 across locales (single-sport apps)
RN = {
    "en-US":   "- iPad layout polish: player icons and popups scale correctly on 13-inch screens\n- External display: landscape canvas renders natively with upright player icons\n- Fixed move lines not auto-showing after animation playback\n",
    "zh-Hans": "- iPad 布局优化：13 寸屏幕上球员图标和弹窗缩放正确\n- 外接显示器：横屏画布原生渲染，球员图标朝向正确\n- 修复动画播放后移动轨迹线未自动显示\n",
    "zh-Hant": "- iPad 佈局優化：13 吋螢幕上球員圖示和彈窗縮放正確\n- 外接顯示器：橫屏畫布原生渲染，球員圖示朝向正確\n- 修復動畫播放後移動軌跡線未自動顯示\n",
    "ja":      "- iPad レイアウト調整：13 インチ画面で選手アイコンとポップアップが正しくスケール\n- 外部ディスプレイ：横向きキャンバスがネイティブレンダリング、選手アイコンが正しい向き\n- アニメーション再生後に移動ラインが自動表示されない問題を修正\n",
    "ko":      "- iPad 레이아웃 개선: 13인치 화면에서 선수 아이콘과 팝업이 올바르게 스케일\n- 외부 디스플레이: 가로 캔버스 네이티브 렌더링, 선수 아이콘 방향 수정\n- 애니메이션 재생 후 이동 선이 자동으로 표시되지 않던 문제 수정\n",
    "fr-FR":   "- Ajustement iPad : icônes et popups correctement dimensionnés sur écrans 13 pouces\n- Affichage externe : rendu natif paysage avec icônes de joueurs à l'endroit\n- Correction : lignes de déplacement ne s'affichaient pas après animation\n",
    "es-ES":   "- Ajuste iPad: iconos y pop-ups se escalan correctamente en pantallas de 13 pulgadas\n- Pantalla externa: lienzo horizontal se renderiza de forma nativa con iconos verticales\n- Corregido: las líneas de movimiento no se mostraban automáticamente tras la animación\n",
    "vi":      "- Tối ưu iPad: biểu tượng cầu thủ và popup hiển thị đúng trên màn hình 13 inch\n- Màn hình ngoài: khung ngang render gốc với biểu tượng cầu thủ đứng thẳng\n- Sửa lỗi: đường di chuyển không tự hiện sau khi chạy animation\n",
    "th":      "- ปรับ iPad: ไอคอนผู้เล่นและ popup ปรับขนาดถูกต้องบนหน้าจอ 13 นิ้ว\n- จอนอก: เรนเดอร์แคนวาสแนวนอนแบบเนทีฟพร้อมไอคอนผู้เล่นตั้งตรง\n- แก้ไข: เส้นเคลื่อนที่ไม่แสดงอัตโนมัติหลังเล่นแอนิเมชัน\n",
    "id":      "- Penyempurnaan iPad: ikon pemain dan popup diskalakan dengan benar di layar 13 inci\n- Layar eksternal: kanvas lanskap dirender native dengan ikon pemain tegak\n- Perbaikan: garis pergerakan tidak otomatis muncul setelah animasi\n",
    "ms":      "- Penambahbaikan iPad: ikon pemain dan popup diskalakan dengan betul pada skrin 13 inci\n- Paparan luaran: kanvas lanskap dirender secara asli dengan ikon pemain tegak\n- Pembetulan: garis pergerakan tidak dipaparkan secara automatik selepas animasi\n",
}

# Multi-sport extra note
RN_MULTI = {
    "en-US":   "- 8 new sports added: Field Hockey, Rugby, Baseball, Handball, Water Polo, Sepak Takraw, Beach Tennis, Footvolley\n",
    "zh-Hans": "- 新增 8 种运动：曲棍球、橄榄球、棒球、手球、水球、藤球、沙滩网球、足排球\n",
    "zh-Hant": "- 新增 8 種運動：曲棍球、橄欖球、棒球、手球、水球、藤球、沙灘網球、足排球\n",
    "ja":      "- 8 スポーツ追加：フィールドホッケー、ラグビー、野球、ハンドボール、水球、セパタクロー、ビーチテニス、フットボレー\n",
    "ko":      "- 8개 신규 스포츠 추가: 필드하키, 럭비, 야구, 핸드볼, 수구, 세팍타크로, 비치테니스, 풋발리\n",
    "fr-FR":   "- 8 nouveaux sports ajoutés : hockey sur gazon, rugby, baseball, handball, water-polo, sepak takraw, beach tennis, footvolley\n",
    "es-ES":   "- 8 nuevos deportes: hockey hierba, rugby, béisbol, balonmano, waterpolo, sepak takraw, tenis playa, futvóley\n",
    "vi":      "- Thêm 8 môn thể thao: khúc côn cầu, rugby, bóng chày, bóng ném, bóng nước, cầu mây, quần vợt bãi biển, bóng chuyền chân\n",
    "th":      "- เพิ่ม 8 กีฬา: ฮอกกี้สนาม, รักบี้, เบสบอล, แฮนด์บอล, โปโลน้ำ, ตะกร้อ, เทนนิสชายหาด, ฟุตวอลเลย์\n",
    "id":      "- 8 olahraga baru: hoki lapangan, rugby, bisbol, bola tangan, polo air, sepak takraw, tenis pantai, footvolley\n",
    "ms":      "- 8 sukan baru: hoki padang, ragbi, besbol, bola baling, polo air, sepak takraw, tenis pantai, footvolley\n",
}

# ─── Per-sport metadata ──────────────────────────────────────────────────────
# Each sport: name, subtitle, keywords, description, promo (and localized)
SPORTS = {
    "fieldHockey": {
        "en-US": {
            "name": "Field Hockey Board - Tactics",
            "subtitle": "Formations & Set Pieces",
            "keywords": "hockey,field,stick,coach,tactics,formation,pitch,play,drill,strategy,press,corner,training",
            "promo": "NEW: Animated plays — draw a press, tap Play, watch every run. Visual coaching for field hockey.",
            "description": """See the pitch. Own the press.

Field Hockey Board gives coaches a precise pitch canvas to plan formations, corners, and pressing triggers — from junior sides to international hockey.

PLAN EVERY PRESS

- Accurate hockey pitch with 23m, 16-yard, and shooting circles
- Drag players, draw runs, tackles, and passing lanes
- Animate plays step by step — perfect for pre-game talks
- Save unlimited tactics and share as high-res images

SET PIECES MADE CLEAR

- Attack & defense formations pre-loaded
- Penalty corners and short corner routines
- Home & away team colors
- Customize player names

COACH-FRIENDLY DESIGN

- Offline · Dark theme · 50-step undo/redo · 11 languages

From school leagues to national squads — show your team exactly where to run.
""",
        },
        "zh-Hans": {
            "name": "曲棍球战术板 - 阵型",
            "subtitle": "阵型与定位球规划",
            "keywords": "曲棍球,球棍,教练,战术,阵型,球场,站位,定位球,短角球,压迫,训练,白板,作战板",
            "promo": "全新：动画战术 — 画出前压，一键播放，看每一次跑位。曲棍球的可视化教练工具。",
            "description": """看见球场。掌控压迫。

曲棍球战术板为教练提供精准的球场画布，规划阵型、角球和压迫触发 — 从青训到国际比赛。

每一次压迫都可视化

- 精准曲棍球场地，含 23 米线、禁区和射门圈
- 拖动球员，绘制跑位、抢断和传球线路
- 逐步动画播放 — 赛前战术会无需多言
- 保存无限战术，高清图片一键分享

定位球一目了然

- 进攻与防守阵型预设
- 长角与短角配合套路
- 主客队色彩区分
- 自定义球员名字

教练友好

- 离线 · 深色模式 · 50 步撤销/重做 · 11 种语言

从校队到国家队 — 把跑位讲清楚。
""",
        },
        "zh-Hant": {
            "name": "曲棍球戰術板 - 陣型",
            "subtitle": "陣型與定位球規劃",
            "keywords": "曲棍球,球棍,教練,戰術,陣型,球場,站位,定位球,短角球,壓迫,訓練,白板,作戰板",
        },
        "ja": {
            "name": "ホッケー戦術ボード",
            "subtitle": "フォーメーション・セットプレー",
            "keywords": "ホッケー,コーチ,戦術,フォーメーション,ピッチ,プレー,練習,戦略,プレス,コーナー,トレーニング",
        },
        "ko": {
            "name": "필드하키 전술판",
            "subtitle": "포메이션 & 세트피스",
            "keywords": "필드하키,하키,코치,전술,포메이션,피치,플레이,드릴,전략,프레싱,코너",
        },
        "fr-FR": {
            "name": "Hockey sur Gazon Tactique",
            "subtitle": "Formations et coups de pied",
            "keywords": "hockey,gazon,entraîneur,tactique,formation,terrain,corner,pression,exercice,stratégie",
        },
        "es-ES": {
            "name": "Pizarra de Hockey Hierba",
            "subtitle": "Formaciones y jugadas",
            "keywords": "hockey,hierba,entrenador,táctica,formación,campo,córner,presión,ejercicio,estrategia",
        },
        "vi": {
            "name": "Bảng chiến thuật Khúc côn cầu",
            "subtitle": "Đội hình & bóng chết",
            "keywords": "khúc côn cầu,huấn luyện,chiến thuật,đội hình,sân,phạt góc,pressing,tập luyện,chiến lược",
        },
        "th": {
            "name": "กระดานฮอกกี้สนาม",
            "subtitle": "รูปแบบและลูกตั้งเตะ",
            "keywords": "ฮอกกี้,สนาม,โค้ช,แทคติก,รูปแบบ,คอร์เนอร์,เพรส,ฝึกซ้อม,กลยุทธ์",
        },
        "id": {
            "name": "Papan Taktik Hoki Lapangan",
            "subtitle": "Formasi & bola mati",
            "keywords": "hoki,lapangan,pelatih,taktik,formasi,corner,pressing,latihan,strategi",
        },
        "ms": {
            "name": "Papan Taktik Hoki Padang",
            "subtitle": "Formasi & bola mati",
            "keywords": "hoki,padang,jurulatih,taktik,formasi,corner,pressing,latihan,strategi",
        },
    },
    "rugby": {
        "en-US": {
            "name": "Rugby Board - Tactics",
            "subtitle": "Lineouts, Scrums, Plays",
            "keywords": "rugby,scrum,lineout,ruck,maul,coach,tactics,formation,pitch,play,drill,union,league",
            "promo": "NEW: Animated plays — draw a lineout move, tap Play, watch every run. Rugby coaching made visual.",
            "description": """Call it. Draw it. Play it.

Rugby Board is the digital clipboard for coaches planning scrums, lineouts, and back-line moves — rugby union and league, 7s and 15s.

BUILT FOR THE BREAKDOWN

- Full rugby pitch with 22m, 10m, and halfway lines
- Drag forwards and backs into position
- Draw crash lines, switches, and defensive drift
- Animate plays step by step

SET PIECES COVERED

- Scrum setup with 8 forwards
- Lineout calls and lifting pods
- Attack phases and defensive line speed
- Home & away team colors

COACH-FRIENDLY DESIGN

- Offline · Dark theme · 50-step undo/redo · 11 languages

From club 7s to Test rugby — make every phase crystal clear.
""",
        },
        "zh-Hans": {
            "name": "橄榄球战术板 - 阵型",
            "subtitle": "定位球与攻防配合",
            "keywords": "橄榄球,英式橄榄球,司克兰,开边球,拉克,毛尔,教练,战术,阵型,球场,站位,训练",
            "promo": "全新：动画战术 — 画出开边球配合，一键播放，看每一次跑位。橄榄球的可视化教练工具。",
            "description": """喊出来。画出来。打出来。

橄榄球战术板是教练规划司克兰、开边球和后线配合的数字白板 — 英式橄榄球联盟/联赛、7 人制/15 人制通用。

拆解每一次冲撞

- 完整橄榄球场，含 22 米线、10 米线和中线
- 拖动前锋与后卫排兵布阵
- 绘制冲击线、交叉跑与防守漂移
- 逐步动画播放

定位球全覆盖

- 8 人司克兰站位
- 开边球战术与托举组合
- 进攻阶段与防守线压迫
- 主客队色彩区分

教练友好

- 离线 · 深色模式 · 50 步撤销/重做 · 11 种语言

从俱乐部 7 人制到测试赛 — 把每个阶段讲清楚。
""",
        },
        "zh-Hant": {
            "name": "橄欖球戰術板 - 陣型",
            "subtitle": "定位球與攻防配合",
            "keywords": "橄欖球,英式橄欖球,司克蘭,開邊球,拉克,毛爾,教練,戰術,陣型,球場,站位,訓練",
        },
        "ja": {
            "name": "ラグビー戦術ボード",
            "subtitle": "ラインアウト・スクラム",
            "keywords": "ラグビー,スクラム,ラインアウト,ラック,モール,コーチ,戦術,フォーメーション,練習,セブンズ",
        },
        "ko": {
            "name": "럭비 전술판",
            "subtitle": "라인아웃 & 스크럼",
            "keywords": "럭비,스크럼,라인아웃,럭,몰,코치,전술,포메이션,드릴,세븐스",
        },
        "fr-FR": {
            "name": "Rugby Tactique",
            "subtitle": "Mêlées, touches, combinaisons",
            "keywords": "rugby,mêlée,touche,ruck,maul,entraîneur,tactique,formation,exercice,union",
        },
        "es-ES": {
            "name": "Pizarra de Rugby",
            "subtitle": "Melés, touches y jugadas",
            "keywords": "rugby,melé,touche,ruck,maul,entrenador,táctica,formación,ejercicio,union",
        },
        "vi": {
            "name": "Bảng chiến thuật Rugby",
            "subtitle": "Hàng ngang & rúc bóng",
            "keywords": "rugby,scrum,lineout,ruck,maul,huấn luyện,chiến thuật,đội hình,tập luyện",
        },
        "th": {
            "name": "กระดานรักบี้",
            "subtitle": "สครัม ไลน์เอาต์ แผนเล่น",
            "keywords": "รักบี้,สครัม,ไลน์เอาต์,รัค,มอล,โค้ช,แทคติก,รูปแบบ,ฝึกซ้อม",
        },
        "id": {
            "name": "Papan Taktik Rugby",
            "subtitle": "Scrum, lineout, pola main",
            "keywords": "rugby,scrum,lineout,ruck,maul,pelatih,taktik,formasi,latihan",
        },
        "ms": {
            "name": "Papan Taktik Ragbi",
            "subtitle": "Scrum, lineout, strategi",
            "keywords": "ragbi,scrum,lineout,ruck,maul,jurulatih,taktik,formasi,latihan",
        },
    },
    "baseball": {
        "en-US": {
            "name": "Baseball Board - Tactics",
            "subtitle": "Defensive Shifts & Plays",
            "keywords": "baseball,diamond,coach,tactics,shift,infield,outfield,play,strategy,defense,lineup,softball,pitcher",
            "promo": "NEW: Animated plays — draw a shift, tap Play, watch every cover. Baseball strategy made visual.",
            "description": """See the diamond. Set the shift.

Baseball Board is the coach's clipboard for defensive shifts, pickoff plays, and base coaching signals — baseball and softball, youth through varsity.

DEFENSIVE SCHEMES

- Accurate baseball diamond with infield and outfield zones
- Drag the 9 defenders into position
- Plan shifts vs. lefty/righty hitters
- Animate double plays, relay throws, cutoffs

BASE RUNNING & PICKOFFS

- Diagram hit-and-runs, steals, squeeze plays
- Pickoff moves from the mound
- Home & away team colors

COACH-FRIENDLY DESIGN

- Offline · Dark theme · 50-step undo/redo · 11 languages

From little league to travel ball — show your team where to stand.
""",
        },
        "zh-Hans": {
            "name": "棒球战术板 - 阵型",
            "subtitle": "防守布阵与跑垒",
            "keywords": "棒球,垒包,教练,战术,防守布阵,内野,外野,战术,策略,投手,垒上跑,软式棒球,双杀",
            "promo": "全新：动画战术 — 画出防守布阵，一键播放，看每一次补位。棒球策略可视化。",
            "description": """看见内野。布好阵型。

棒球战术板是教练规划防守布阵、牵制和跑垒信号的数字白板 — 棒球与垒球，少年到校队。

防守战术

- 精准棒球场图，含内野与外野区域
- 拖动 9 名防守队员就位
- 针对左右打者的布阵
- 动画演示双杀、中继传球和切断

跑垒与牵制

- 绘制打带跑、盗垒、触击
- 投手的牵制动作
- 主客队色彩区分

教练友好

- 离线 · 深色模式 · 50 步撤销/重做 · 11 种语言

从少年棒球到巡回赛 — 告诉球员该站哪。
""",
        },
        "zh-Hant": {
            "name": "棒球戰術板 - 陣型",
            "subtitle": "防守佈陣與跑壘",
            "keywords": "棒球,壘包,教練,戰術,防守佈陣,內野,外野,策略,投手,跑壘,壘球,雙殺",
        },
        "ja": {
            "name": "野球戦術ボード",
            "subtitle": "守備シフト・作戦",
            "keywords": "野球,ダイヤモンド,コーチ,戦術,シフト,内野,外野,作戦,守備,打線,ソフトボール,投手",
        },
        "ko": {
            "name": "야구 전술판",
            "subtitle": "수비 시프트 & 작전",
            "keywords": "야구,다이아몬드,코치,전술,시프트,내야,외야,작전,수비,라인업,소프트볼,투수",
        },
        "fr-FR": {
            "name": "Pizarra de Baseball",
            "subtitle": "Défenses et stratégies",
            "keywords": "baseball,diamant,entraîneur,tactique,défense,intérieur,extérieur,jeu,stratégie,lanceur,softball",
        },
        "es-ES": {
            "name": "Pizarra de Béisbol",
            "subtitle": "Defensas y jugadas",
            "keywords": "béisbol,diamante,entrenador,táctica,defensa,cuadro,jardín,jugada,estrategia,lanzador,softbol",
        },
        "vi": {
            "name": "Bảng chiến thuật Bóng chày",
            "subtitle": "Phòng thủ & chạy chốt",
            "keywords": "bóng chày,sân,huấn luyện,chiến thuật,phòng thủ,sân trong,sân ngoài,chiến lược,ném bóng",
        },
        "th": {
            "name": "กระดานเบสบอล",
            "subtitle": "การจัดผู้เล่นและแผน",
            "keywords": "เบสบอล,ไดมอนด์,โค้ช,แทคติก,การจัด,อินฟิลด์,เอาต์ฟิลด์,แผน,กลยุทธ์,ซอฟต์บอล",
        },
        "id": {
            "name": "Papan Taktik Bisbol",
            "subtitle": "Pertahanan & rotasi",
            "keywords": "bisbol,diamond,pelatih,taktik,pertahanan,infield,outfield,strategi,pitcher,sofbol",
        },
        "ms": {
            "name": "Papan Taktik Besbol",
            "subtitle": "Pertahanan & pusingan",
            "keywords": "besbol,diamond,jurulatih,taktik,pertahanan,infield,outfield,strategi,pitcher",
        },
    },
    "handball": {
        "en-US": {
            "name": "Handball Board - Tactics",
            "subtitle": "Attack & Defense Setups",
            "keywords": "handball,court,coach,tactics,formation,attack,defense,6-0,5-1,play,drill,strategy,pivot",
            "promo": "NEW: Animated plays — draw a 3-3 defense, tap Play, watch every shift. Handball coaching made visual.",
            "description": """Set the defense. Run the attack.

Handball Board is the digital tactics tool for coaches planning 6-0, 5-1, and 3-2-1 defenses plus attacking positional play — indoor handball and beach.

DEFENSIVE SCHEMES

- Accurate 40×20 handball court with 6m and 9m arcs
- Drag defenders into 6-0, 5-1, 3-2-1, or man-to-man
- Plan double screens, switches, and trap zones
- Animate shifts step by step

ATTACKING PLAY

- Pivot moves and crossing runs
- Wing attacks and back-court combinations
- Home & away team colors
- Customize player names

COACH-FRIENDLY DESIGN

- Offline · Dark theme · 50-step undo/redo · 11 languages

From club training to EHF — make every defensive shift crystal clear.
""",
        },
        "zh-Hans": {
            "name": "手球战术板 - 阵型",
            "subtitle": "攻防阵型规划",
            "keywords": "手球,球场,教练,战术,阵型,进攻,防守,6-0,5-1,训练,策略,支点,沙滩手球",
            "promo": "全新：动画战术 — 画出 3-3 防守，一键播放，看每一次换防。手球的可视化教练工具。",
            "description": """布好防守。打出进攻。

手球战术板是教练规划 6-0、5-1、3-2-1 防守及进攻跑位的数字工具 — 室内手球与沙滩手球通用。

防守战术

- 精准 40×20 手球场，含 6 米与 9 米弧线
- 拖动防守队员组成 6-0、5-1、3-2-1 或盯人防守
- 规划双掩护、换防与陷阱区
- 逐步动画演示换防

进攻配合

- 支点球员跑位与交叉穿插
- 翼侧进攻与后场配合
- 主客队色彩区分
- 自定义球员名字

教练友好

- 离线 · 深色模式 · 50 步撤销/重做 · 11 种语言

从俱乐部训练到欧洲手球联合会 — 把每次换防讲清楚。
""",
        },
        "zh-Hant": {
            "name": "手球戰術板 - 陣型",
            "subtitle": "攻防陣型規劃",
            "keywords": "手球,球場,教練,戰術,陣型,進攻,防守,6-0,5-1,訓練,策略,支點",
        },
        "ja": {
            "name": "ハンドボール戦術ボード",
            "subtitle": "攻撃・防御フォーメーション",
            "keywords": "ハンドボール,コート,コーチ,戦術,フォーメーション,攻撃,防御,6-0,5-1,練習,ポスト",
        },
        "ko": {
            "name": "핸드볼 전술판",
            "subtitle": "공격 & 수비 포메이션",
            "keywords": "핸드볼,코트,코치,전술,포메이션,공격,수비,6-0,5-1,훈련,피벗",
        },
        "fr-FR": {
            "name": "Handball Tactique",
            "subtitle": "Attaque et défense",
            "keywords": "handball,terrain,entraîneur,tactique,formation,attaque,défense,6-0,5-1,exercice,pivot",
        },
        "es-ES": {
            "name": "Pizarra de Balonmano",
            "subtitle": "Ataque y defensa",
            "keywords": "balonmano,cancha,entrenador,táctica,formación,ataque,defensa,6-0,5-1,ejercicio,pivote",
        },
        "vi": {
            "name": "Bảng chiến thuật Bóng ném",
            "subtitle": "Tấn công & phòng thủ",
            "keywords": "bóng ném,sân,huấn luyện,chiến thuật,đội hình,tấn công,phòng thủ,6-0,5-1,tập luyện",
        },
        "th": {
            "name": "กระดานแฮนด์บอล",
            "subtitle": "รุกและตั้งรับ",
            "keywords": "แฮนด์บอล,สนาม,โค้ช,แทคติก,รูปแบบ,รุก,รับ,6-0,5-1,ฝึกซ้อม",
        },
        "id": {
            "name": "Papan Taktik Bola Tangan",
            "subtitle": "Serangan & pertahanan",
            "keywords": "bola tangan,lapangan,pelatih,taktik,formasi,serangan,pertahanan,6-0,5-1,latihan",
        },
        "ms": {
            "name": "Papan Taktik Bola Baling",
            "subtitle": "Serangan & pertahanan",
            "keywords": "bola baling,gelanggang,jurulatih,taktik,formasi,serangan,pertahanan,6-0,5-1,latihan",
        },
    },
    "waterPolo": {
        "en-US": {
            "name": "Water Polo Board - Tactics",
            "subtitle": "Pool Formations & Plays",
            "keywords": "water,polo,pool,coach,tactics,formation,attack,defense,play,drill,strategy,center,wing,6v5",
            "promo": "NEW: Animated plays — draw a 6v5 power play, tap Play, watch every swim. Water polo coaching made visual.",
            "description": """Read the pool. Swim the plan.

Water Polo Board is the coach's canvas for 6v5 power plays, pressing defense, and center forward setups — club through national squads.

POWER PLAY SETUPS

- Accurate 30×20 FINA pool with 2m, 5m, and 6m lines
- Drag 7 swimmers into 3-3, 4-2, or 2-1-2-1 formations
- Plan 6v5 rotations and penalty shots
- Animate player movements step by step

PRESSING & COUNTER

- Man-up defense and zone pressing
- Fast break and counter-attack plays
- Home & away team colors

COACH-FRIENDLY DESIGN

- Offline · Dark theme · 50-step undo/redo · 11 languages

From age-group swimming to LEN Championship — every swim, every pass, mapped out.
""",
        },
        "zh-Hans": {
            "name": "水球战术板 - 阵型",
            "subtitle": "泳池阵型与战术",
            "keywords": "水球,泳池,教练,战术,阵型,进攻,防守,策略,中锋,边锋,6人多,训练,白板",
            "promo": "全新：动画战术 — 画出 6 打 5 多一人配合，一键播放，看每一次游进。水球的可视化教练工具。",
            "description": """读懂泳池。游出战术。

水球战术板是教练规划 6 打 5、压迫防守和中锋跑位的画布 — 俱乐部到国家队通用。

多一人进攻

- 精准 30×20 FINA 泳池，含 2 米、5 米与 6 米线
- 拖动 7 名选手组成 3-3、4-2 或 2-1-2-1 阵型
- 规划 6 打 5 轮转与 5 米点球
- 逐步动画演示跑位

压迫与反击

- 盯人防守与区域压迫
- 快攻与反击战术
- 主客队色彩区分

教练友好

- 离线 · 深色模式 · 50 步撤销/重做 · 11 种语言

从青少年到欧锦赛 — 每一次游进、每一次传球都清晰可见。
""",
        },
        "zh-Hant": {
            "name": "水球戰術板 - 陣型",
            "subtitle": "泳池陣型與戰術",
            "keywords": "水球,泳池,教練,戰術,陣型,進攻,防守,策略,中鋒,邊鋒,6人多,訓練,白板",
        },
        "ja": {
            "name": "水球戦術ボード",
            "subtitle": "プールのフォーメーション",
            "keywords": "水球,プール,コーチ,戦術,フォーメーション,攻撃,防御,センター,6対5,練習,スイム",
        },
        "ko": {
            "name": "수구 전술판",
            "subtitle": "풀 포메이션 & 작전",
            "keywords": "수구,수영장,코치,전술,포메이션,공격,수비,센터,6대5,훈련,작전",
        },
        "fr-FR": {
            "name": "Water-polo Tactique",
            "subtitle": "Formations en piscine",
            "keywords": "water polo,piscine,entraîneur,tactique,formation,attaque,défense,6v5,exercice,centre",
        },
        "es-ES": {
            "name": "Pizarra de Waterpolo",
            "subtitle": "Formaciones de piscina",
            "keywords": "waterpolo,piscina,entrenador,táctica,formación,ataque,defensa,6v5,ejercicio,boya",
        },
        "vi": {
            "name": "Bảng chiến thuật Bóng nước",
            "subtitle": "Đội hình hồ bơi",
            "keywords": "bóng nước,hồ bơi,huấn luyện,chiến thuật,đội hình,tấn công,phòng thủ,6v5,trung phong",
        },
        "th": {
            "name": "กระดานโปโลน้ำ",
            "subtitle": "แผนในสระว่ายน้ำ",
            "keywords": "โปโลน้ำ,สระ,โค้ช,แทคติก,รูปแบบ,รุก,รับ,6v5,เซ็นเตอร์,ฝึกซ้อม",
        },
        "id": {
            "name": "Papan Taktik Polo Air",
            "subtitle": "Formasi kolam renang",
            "keywords": "polo air,kolam,pelatih,taktik,formasi,serangan,pertahanan,6v5,center,latihan",
        },
        "ms": {
            "name": "Papan Taktik Polo Air",
            "subtitle": "Formasi kolam",
            "keywords": "polo air,kolam,jurulatih,taktik,formasi,serangan,pertahanan,6v5,center,latihan",
        },
    },
    "sepakTakraw": {
        "en-US": {
            "name": "Sepak Takraw - Tactics",
            "subtitle": "Regu Rotations & Plays",
            "keywords": "sepak,takraw,rattan,coach,tactics,regu,formation,play,drill,strategy,kick,serve,asian,spike,asean",
            "promo": "NEW: Animated plays — map out your regu rotations, tap Play, watch every bicycle kick. Takraw coaching made visual.",
            "description": """Plan the regu. Own the rally.

Sepak Takraw Board is the coach's canvas for regu formations, serve patterns, and attacking rotations — ISTAF standards, ASEAN to world stage.

REGU FORMATIONS

- Accurate 13.4×6.1 ISTAF court with service circles
- Drag the 3 regu players — Tekong, Feeder, Killer
- Plan serve positioning and feeder angles
- Animate rotations and bicycle kick attacks

SERVE & DEFENSE

- Serve strategies by rotation
- Defensive block positioning
- Home & away team colors
- Customize player names

COACH-FRIENDLY DESIGN

- Offline · Dark theme · 50-step undo/redo · 11 languages

From village games to King's Cup — show every rotation, every kick.
""",
        },
        "zh-Hans": {
            "name": "藤球战术板 - 阵型",
            "subtitle": "三人队跑位配合",
            "keywords": "藤球,藤编,教练,战术,三人队,阵型,发球,倒勾,训练,策略,东南亚,扣球,亚洲,ISTAF",
            "promo": "全新：动画战术 — 规划三人队轮转，一键播放，看每一次倒勾扣杀。藤球可视化教练工具。",
            "description": """布好三人队。掌控每一回合。

藤球战术板是教练规划三人队（regu）阵型、发球和进攻轮转的画布 — ISTAF 国际标准，东南亚到世界赛。

三人队阵型

- 精准 13.4×6.1 米 ISTAF 场地，含发球圈
- 拖动 3 名球员：发球手、二传、主攻
- 规划发球站位与二传角度
- 动画演示轮转与倒勾扣杀

发球与防守

- 按轮次制定发球策略
- 拦网站位
- 主客队色彩区分
- 自定义球员名字

教练友好

- 离线 · 深色模式 · 50 步撤销/重做 · 11 种语言

从村际赛到国王杯 — 每一次轮转、每一次扣杀都可视化。
""",
        },
        "zh-Hant": {
            "name": "藤球戰術板 - 陣型",
            "subtitle": "三人隊跑位配合",
            "keywords": "藤球,藤編,教練,戰術,三人隊,陣型,發球,倒勾,訓練,策略,東南亞,扣球,亞洲",
        },
        "ja": {
            "name": "セパタクロー戦術ボード",
            "subtitle": "レグのローテーション",
            "keywords": "セパタクロー,ラタン,コーチ,戦術,レグ,フォーメーション,サーブ,練習,アジア,スパイク",
        },
        "ko": {
            "name": "세팍타크로 전술판",
            "subtitle": "레구 로테이션 & 작전",
            "keywords": "세팍타크로,라탄,코치,전술,레구,포메이션,서브,훈련,아시아,스파이크",
        },
        "fr-FR": {
            "name": "Sepak Takraw Tactique",
            "subtitle": "Rotations et jeu",
            "keywords": "sepak takraw,rotin,entraîneur,tactique,regu,formation,service,exercice,asie,bicyclette",
        },
        "es-ES": {
            "name": "Pizarra de Sepak Takraw",
            "subtitle": "Rotaciones y jugadas",
            "keywords": "sepak takraw,ratán,entrenador,táctica,regu,formación,saque,ejercicio,asia,chilena",
        },
        "vi": {
            "name": "Bảng chiến thuật Cầu mây",
            "subtitle": "Đội hình và chiến thuật",
            "keywords": "cầu mây,mây,huấn luyện,chiến thuật,đội hình,giao cầu,tập luyện,đông nam á,đá",
        },
        "th": {
            "name": "กระดานตะกร้อ",
            "subtitle": "การหมุนและแผน",
            "keywords": "ตะกร้อ,เซปักตะกร้อ,โค้ช,แทคติก,เรกู,รูปแบบ,เสิร์ฟ,ฝึกซ้อม,เตะ,ISTAF",
        },
        "id": {
            "name": "Papan Taktik Sepak Takraw",
            "subtitle": "Rotasi regu & strategi",
            "keywords": "sepak takraw,rotan,pelatih,taktik,regu,formasi,servis,latihan,asia,tendangan",
        },
        "ms": {
            "name": "Papan Taktik Sepak Takraw",
            "subtitle": "Pusingan regu & strategi",
            "keywords": "sepak takraw,rotan,jurulatih,taktik,regu,formasi,servis,latihan,asia,tendangan",
        },
    },
    "beachTennis": {
        "en-US": {
            "name": "Beach Tennis - Tactics",
            "subtitle": "Doubles Plays on Sand",
            "keywords": "beach,tennis,sand,doubles,coach,tactics,formation,play,drill,strategy,volley,smash,court,itf",
            "promo": "NEW: Animated plays — draw a doubles poach, tap Play, watch every sprint. Beach tennis coaching made visual.",
            "description": """Read the sand. Own the net.

Beach Tennis Board is the coach's canvas for doubles positioning, serve-and-volley plays, and smash setups — ITF standards, club to world tour.

DOUBLES POSITIONING

- Accurate 16×8 ITF sand court with net and serve lines
- Drag your 2 players into front-back or side-by-side setup
- Plan poaches, lobs, and net coverage
- Animate movements step by step

SMASH & SERVE

- Serve placement patterns
- Setup for the winning smash
- Defensive lob recovery
- Home & away team colors

COACH-FRIENDLY DESIGN

- Offline · Dark theme · 50-step undo/redo · 11 languages

From weekend tournaments to ITF finals — show every sprint across the sand.
""",
        },
        "zh-Hans": {
            "name": "沙滩网球战术板 - 双打",
            "subtitle": "沙滩双打站位",
            "keywords": "沙滩网球,沙滩,双打,教练,战术,阵型,截击,扣杀,训练,策略,发球,ITF,泛美网球",
            "promo": "全新：动画战术 — 画出双打交叉截击，一键播放，看每一次冲刺。沙滩网球可视化教练工具。",
            "description": """读懂沙场。掌控网前。

沙滩网球战术板是教练规划双打站位、发球上网和扣杀组合的画布 — ITF 国际标准，俱乐部到世界巡回赛。

双打站位

- 精准 16×8 米 ITF 沙场，含网柱与发球线
- 拖动 2 名球员，前后或平行站位
- 规划交叉截击、放高球与网前覆盖
- 逐步动画演示跑位

扣杀与发球

- 发球落点变化
- 制胜扣杀铺垫
- 防守放高球的回位
- 主客队色彩区分

教练友好

- 离线 · 深色模式 · 50 步撤销/重做 · 11 种语言

从周末业余赛到 ITF 总决赛 — 把沙滩上每一次冲刺讲清楚。
""",
        },
        "zh-Hant": {
            "name": "沙灘網球戰術板 - 雙打",
            "subtitle": "沙灘雙打站位",
            "keywords": "沙灘網球,沙灘,雙打,教練,戰術,陣型,截擊,扣殺,訓練,策略,發球,ITF",
        },
        "ja": {
            "name": "ビーチテニス戦術ボード",
            "subtitle": "ダブルスの戦略",
            "keywords": "ビーチテニス,ビーチ,砂浜,ダブルス,コーチ,戦術,フォーメーション,ボレー,スマッシュ,練習,サーブ",
        },
        "ko": {
            "name": "비치테니스 전술판",
            "subtitle": "복식 & 모래 코트",
            "keywords": "비치테니스,모래,복식,코치,전술,포메이션,발리,스매시,훈련,서브,ITF",
        },
        "fr-FR": {
            "name": "Beach Tennis Tactique",
            "subtitle": "Double sur sable",
            "keywords": "beach tennis,sable,double,entraîneur,tactique,formation,volée,smash,exercice,service",
        },
        "es-ES": {
            "name": "Pizarra de Tenis Playa",
            "subtitle": "Dobles en la arena",
            "keywords": "tenis playa,arena,dobles,entrenador,táctica,formación,volea,smash,ejercicio,saque",
        },
        "vi": {
            "name": "Bảng chiến thuật Tennis bãi biển",
            "subtitle": "Đôi trên cát",
            "keywords": "tennis bãi biển,cát,đôi,huấn luyện,chiến thuật,đội hình,bỏ nhỏ,đập bóng,tập luyện",
        },
        "th": {
            "name": "กระดานเทนนิสชายหาด",
            "subtitle": "คู่บนทราย",
            "keywords": "เทนนิสชายหาด,ทราย,คู่,โค้ช,แทคติก,รูปแบบ,วอลเลย์,สแมช,ฝึกซ้อม,ITF",
        },
        "id": {
            "name": "Papan Taktik Tenis Pantai",
            "subtitle": "Ganda di pasir",
            "keywords": "tenis pantai,pasir,ganda,pelatih,taktik,formasi,voli,smash,latihan,ITF",
        },
        "ms": {
            "name": "Papan Taktik Tenis Pantai",
            "subtitle": "Beregu di pasir",
            "keywords": "tenis pantai,pasir,beregu,jurulatih,taktik,formasi,voli,smash,latihan",
        },
    },
    "footvolley": {
        "en-US": {
            "name": "Footvolley Board - Tactics",
            "subtitle": "Beach Plays & Doubles",
            "keywords": "footvolley,beach,sand,soccer,doubles,coach,tactics,formation,play,drill,strategy,kick,volleyball,futvolei",
            "promo": "NEW: Animated plays — draw a bicycle kick attack, tap Play, watch every sprint. Footvolley coaching made visual.",
            "description": """Brazilian beach soccer meets volleyball.

Footvolley Board is the coach's canvas for doubles positioning, attacking kicks, and defensive bumps — from Rio beaches to world tour finals.

DOUBLES POSITIONING

- Accurate 18×9 beach court with net and service lines
- Drag your 2 players across the sand
- Plan shades, attacks, and defensive pickups
- Animate bicycle kicks and header defenses

ATTACK & DEFENSE

- Serve strategies and receive patterns
- Setup for the winning kick attack
- Block coverage and lob recovery
- Home & away team colors

COACH-FRIENDLY DESIGN

- Offline · Dark theme · 50-step undo/redo · 11 languages

From the boardwalk to the world final — show every move on the sand.
""",
        },
        "zh-Hans": {
            "name": "足排球战术板 - 双打",
            "subtitle": "沙滩脚法双打",
            "keywords": "足排球,沙滩排球,脚,沙滩,双打,教练,战术,阵型,倒勾,训练,策略,发球,巴西,futvolei",
            "promo": "全新：动画战术 — 画出倒勾攻击，一键播放，看每一次冲刺。足排球可视化教练工具。",
            "description": """巴西海滩足球与排球的结合。

足排球战术板是教练规划双打站位、脚法攻击与防守垫球的画布 — 从里约海滩到世界巡回赛总决赛。

双打站位

- 精准 18×9 米沙滩场地，含网柱与发球线
- 拖动 2 名球员在沙场上移动
- 规划掩护、攻击与防守接球
- 动画演示倒勾与头球防守

进攻与防守

- 发球策略与接发球套路
- 铺垫制胜脚法攻击
- 拦网覆盖与放高球回位
- 主客队色彩区分

教练友好

- 离线 · 深色模式 · 50 步撤销/重做 · 11 种语言

从海滨木板道到世界总决赛 — 把沙场上的每次触球讲清楚。
""",
        },
        "zh-Hant": {
            "name": "足排球戰術板 - 雙打",
            "subtitle": "沙灘腳法雙打",
            "keywords": "足排球,沙灘排球,腳,沙灘,雙打,教練,戰術,陣型,倒勾,訓練,策略,巴西",
        },
        "ja": {
            "name": "フットボレー戦術ボード",
            "subtitle": "ビーチのダブルス",
            "keywords": "フットボレー,ビーチ,砂浜,サッカー,ダブルス,コーチ,戦術,フォーメーション,キック,練習,ブラジル",
        },
        "ko": {
            "name": "풋발리 전술판",
            "subtitle": "비치 & 복식 플레이",
            "keywords": "풋발리,비치,모래,축구,복식,코치,전술,포메이션,킥,훈련,브라질",
        },
        "fr-FR": {
            "name": "Footvolley Tactique",
            "subtitle": "Jeu en double sur sable",
            "keywords": "footvolley,sable,plage,football,double,entraîneur,tactique,formation,coup,exercice,brésil",
        },
        "es-ES": {
            "name": "Pizarra de Futvóley",
            "subtitle": "Dobles en la arena",
            "keywords": "futvóley,playa,arena,fútbol,dobles,entrenador,táctica,formación,patada,ejercicio,brasil",
        },
        "vi": {
            "name": "Bảng chiến thuật Bóng chuyền chân",
            "subtitle": "Đôi trên cát",
            "keywords": "bóng chuyền chân,bãi biển,cát,bóng đá,đôi,huấn luyện,chiến thuật,đội hình,sút,brazil",
        },
        "th": {
            "name": "กระดานฟุตวอลเลย์",
            "subtitle": "คู่บนชายหาด",
            "keywords": "ฟุตวอลเลย์,ชายหาด,ทราย,ฟุตบอล,คู่,โค้ช,แทคติก,รูปแบบ,เตะ,ฝึกซ้อม,บราซิล",
        },
        "id": {
            "name": "Papan Taktik Footvolley",
            "subtitle": "Ganda di pantai",
            "keywords": "footvolley,pantai,pasir,sepak bola,ganda,pelatih,taktik,formasi,tendangan,latihan,brasil",
        },
        "ms": {
            "name": "Papan Taktik Footvolley",
            "subtitle": "Beregu di pantai",
            "keywords": "footvolley,pantai,pasir,bola sepak,beregu,jurulatih,taktik,formasi,tendangan,latihan",
        },
    },
}

FULL_LOCALES = ["en-US", "zh-Hans"]  # get description + promotional_text
ALL_LOCALES = ["en-US", "zh-Hans", "zh-Hant", "ja", "ko", "fr-FR", "es-ES", "vi", "th", "id", "ms"]


def write(sport_key, locale, filename, content):
    d = os.path.join(BASE, sport_key, locale)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, filename), "w", encoding="utf-8") as f:
        f.write(content)


for sport, by_locale in SPORTS.items():
    en = by_locale["en-US"]
    for locale in ALL_LOCALES:
        loc_data = by_locale.get(locale, en)
        # Always write name, subtitle, keywords
        write(sport, locale, "name.txt", loc_data["name"])
        write(sport, locale, "subtitle.txt", loc_data["subtitle"])
        write(sport, locale, "keywords.txt", loc_data["keywords"])
        # Release notes (localized)
        write(sport, locale, "release_notes.txt", RN[locale])
        # Full-content locales get description + promo
        if locale in FULL_LOCALES:
            write(sport, locale, "description.txt", loc_data["description"])
            write(sport, locale, "promotional_text.txt", loc_data["promo"])

print(f"Generated metadata for {len(SPORTS)} sports × {len(ALL_LOCALES)} locales")
