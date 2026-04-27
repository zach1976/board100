#!/usr/bin/env python3
"""Batch D: keywords + release_notes for 16 apps × 11 locales = 352 files.
keywords: ≤100 chars, comma-separated, no spaces around commas.
release_notes: marketing-toned changelog (≤4000, target ≤500)."""
import os
BASE = "/Users/zhenyusong/Desktop/projects/board100/tactics_board/fastlane/metadata"

# ════════════════════════════════════════════════════════════════════
# RELEASE NOTES — same hero feature across the lineup, locale-tuned tone
# ════════════════════════════════════════════════════════════════════
RN = {
    "en-US": "What's new:\n• Timeline Editor: animate multi-phase plays step by step\n• External display: landscape canvas with upright icons (AirPlay-ready)\n• Move lines auto-show after playback\n• iPad layout polish on 13-inch screens\n\nThanks for coaching with us. Keep the questions and ideas coming.",
    "zh-Hans": "本次更新：\n• 时间线编辑器：多阶段战术一步一停动画播放\n• 外接显示器：横屏画布原生渲染，图标正立（支持 AirPlay）\n• 动画结束后自动显示跑位线\n• iPad 13 寸屏布局精修\n\n感谢一直陪伴。继续把建议和想法发给我们。",
    "zh-Hant": "本次更新：\n• 時間線編輯器：多階段戰術一步一停動畫播放\n• 外接顯示器：橫屏畫布原生渲染，圖示正立（支援 AirPlay）\n• 動畫結束後自動顯示跑位線\n• iPad 13 吋螢幕版面精修\n\n感謝一路同行，繼續把建議與想法傳給我們。",
    "ja": "今回の更新：\n• タイムラインエディタ：多段階戦術を一歩ずつアニメ再生\n• 外部ディスプレイ：横向きキャンバスをネイティブ描画（AirPlay対応）\n• 再生後に走線を自動表示\n• iPad 13インチ画面のレイアウト調整\n\nいつもありがとうございます。ご意見・ご要望を引き続きお寄せください。",
    "ko": "이번 업데이트:\n• 타임라인 에디터: 다단계 전술을 단계별 애니메이션으로 재생\n• 외부 디스플레이: 가로 캔버스를 네이티브 렌더링, 아이콘 정방향 (AirPlay 지원)\n• 재생 후 이동선 자동 표시\n• iPad 13인치 레이아웃 다듬기\n\n언제나 감사합니다. 의견과 아이디어를 계속 보내주세요.",
    "fr-FR": "Nouveautés :\n• Éditeur Timeline : animez les phases tactiques pas à pas\n• Affichage externe : toile paysage en rendu natif, icônes droites (AirPlay)\n• Lignes de course visibles automatiquement après lecture\n• Mise en page iPad 13 pouces affinée\n\nMerci de coacher avec nous. Continuez à nous envoyer vos retours.",
    "es-ES": "Novedades:\n• Editor Timeline: anima jugadas multi-fase paso a paso\n• Pantalla externa: lienzo apaisado nativo, iconos en vertical (AirPlay)\n• Líneas de movimiento visibles tras la reproducción\n• Ajustes de diseño en iPad 13\"\n\nGracias por entrenar con nosotros. Sigue enviándonos ideas.",
    "vi": "Có gì mới:\n• Trình Timeline: phát từng bước các pha chiến thuật nhiều giai đoạn\n• Màn ngoài: canvas ngang dựng gốc, biểu tượng đứng thẳng (AirPlay)\n• Đường di chuyển tự hiện sau khi phát xong\n• Tinh chỉnh bố cục iPad 13 inch\n\nCảm ơn bạn đã đồng hành. Cứ gửi phản hồi và ý tưởng.",
    "th": "อัปเดตล่าสุด:\n• Timeline Editor: เล่นแผนหลายจังหวะทีละสเต็ป\n• จอภายนอก: เรนเดอร์แนวนอนแบบเนทีฟ ไอคอนตั้งตรง (รองรับ AirPlay)\n• เส้นการเคลื่อนที่โผล่อัตโนมัติหลังเล่นจบ\n• ปรับเลย์เอาต์ iPad 13 นิ้วให้สวย\n\nขอบคุณที่อยู่ด้วยกัน ส่งฟีดแบ็กและไอเดียมาได้เรื่อยๆ",
    "id": "Yang baru:\n• Timeline Editor: animasikan taktik multi-fase langkah demi langkah\n• Layar eksternal: kanvas landscape native, ikon tegak (AirPlay)\n• Garis pergerakan tampil otomatis setelah putar\n• Penyesuaian tata letak iPad 13 inci\n\nTerima kasih sudah melatih bersama kami. Lanjutkan kirim masukan dan ide.",
    "ms": "Yang baharu:\n• Timeline Editor: animasikan taktik berbilang fasa langkah demi langkah\n• Paparan luar: kanvas landskap natif, ikon menegak (AirPlay)\n• Garis pergerakan dipaparkan automatik selepas main\n• Halusan susun atur iPad 13 inci\n\nTerima kasih melatih bersama kami. Teruskan hantar maklum balas dan idea.",
}

# ════════════════════════════════════════════════════════════════════
# KEYWORDS — per sport per locale (≤100 chars, comma-separated, no extra spaces)
# Strategy: alt sport names, role/play terms, format/intent terms, market-specific search
# ════════════════════════════════════════════════════════════════════
KW = {
    "tactics_board": {
        "en-US": "tactics,coach,playbook,whiteboard,formation,drill,strategy,team,training,lineup,sport,board",
        "zh-Hans": "战术板,教练,阵型,跑位,训练,白板,球队,策略,运动,画板,投屏,演练",
        "zh-Hant": "戰術板,教練,陣型,跑位,訓練,白板,球隊,策略,運動,畫板,投屏,演練",
        "ja": "戦術ボード,コーチ,フォーメーション,作戦,練習,ホワイトボード,チーム,戦略,スポーツ,投影",
        "ko": "전술판,코치,포메이션,작전,훈련,화이트보드,팀,전략,스포츠,라인업",
        "fr-FR": "tactique,coach,plan,formation,entraînement,équipe,stratégie,sport,whiteboard,schéma",
        "es-ES": "táctica,entrenador,pizarra,formación,jugada,entrenamiento,equipo,deporte,esquema,plantilla",
        "vi": "chiến thuật,huấn luyện viên,đội hình,bảng,tập luyện,đội,sơ đồ,thể thao,playbook,sa bàn",
        "th": "แผน,โค้ช,ฟอร์เมชัน,กระดาน,ฝึกซ้อม,ทีม,กลยุทธ์,กีฬา,ผังเล่น,ไวท์บอร์ด",
        "id": "taktik,pelatih,formasi,papan,latihan,tim,strategi,olahraga,playbook,whiteboard",
        "ms": "taktik,jurulatih,formasi,papan,latihan,pasukan,strategi,sukan,playbook,whiteboard",
    },
    "soccer": {
        "en-US": "football,futsal,4-4-2,4-3-3,3-5-2,formation,coach,playbook,set piece,corner,free kick,pitch",
        "zh-Hans": "足球,五人制,4-4-2,4-3-3,3-5-2,阵型,教练,战术板,角球,任意球,跑位,五人足球",
        "zh-Hant": "足球,五人制,4-4-2,4-3-3,3-5-2,陣型,教練,戰術板,角球,任意球,跑位,室內足球",
        "ja": "サッカー,フットサル,4-4-2,4-3-3,3-5-2,フォーメーション,コーチ,作戦盤,コーナー,FK,セットプレー",
        "ko": "축구,풋살,4-4-2,4-3-3,3-5-2,포메이션,코치,전술판,코너킥,프리킥,세트피스,라인업",
        "fr-FR": "football,futsal,4-4-2,4-3-3,3-5-2,formation,coach,plan,corner,coup franc,coup de pied,équipe",
        "es-ES": "fútbol,futsal,4-4-2,4-3-3,3-5-2,formación,entrenador,pizarra,córner,tiro libre,jugada,plantilla",
        "vi": "bóng đá,futsal,4-4-2,4-3-3,3-5-2,đội hình,huấn luyện,sơ đồ,phạt góc,đá phạt,sút phạt,đội bóng",
        "th": "ฟุตบอล,ฟุตซอล,4-4-2,4-3-3,3-5-2,ฟอร์เมชัน,โค้ช,กระดาน,ลูกเตะมุม,ฟรีคิก,เซตพีซ,ทีม",
        "id": "sepak bola,futsal,4-4-2,4-3-3,3-5-2,formasi,pelatih,papan,sepak pojok,tendangan bebas,set piece,tim",
        "ms": "bola sepak,futsal,4-4-2,4-3-3,3-5-2,formasi,jurulatih,papan,sepak penjuru,sepakan bebas,set piece",
    },
    "basketball": {
        "en-US": "hoops,3v3,5v5,pick roll,horns,zone defense,man to man,offense,playbook,coach,court,lineup",
        "zh-Hans": "篮球,3v3,5v5,挡拆,牛角,联防,人盯人,进攻,战术板,教练,球场,跑位",
        "zh-Hant": "籃球,3v3,5v5,擋拆,牛角,聯防,人盯人,進攻,戰術板,教練,球場,跑位",
        "ja": "バスケ,3x3,5v5,ピックロール,ホーンズ,ゾーン,マンツーマン,オフェンス,作戦盤,コーチ,コート",
        "ko": "농구,3v3,5v5,픽앤롤,혼스,지역방어,맨투맨,공격,전술판,코치,코트,라인업",
        "fr-FR": "basket,3v3,5v5,pick and roll,horns,zone,man to man,attaque,plan,coach,terrain,lineup",
        "es-ES": "básquet,3v3,5v5,bloqueo,horns,zona,hombre a hombre,ataque,pizarra,entrenador,cancha,jugada",
        "vi": "bóng rổ,3v3,5v5,pick roll,horns,phòng ngự khu vực,kèm người,tấn công,sơ đồ,huấn luyện,sân,đội hình",
        "th": "บาส,3x3,5v5,pick and roll,horns,โซน,ตัวต่อตัว,รุก,กระดาน,โค้ช,สนาม,ทีม",
        "id": "basket,3v3,5v5,pick roll,horns,zona,man to man,serangan,papan,pelatih,lapangan,formasi",
        "ms": "bola keranjang,3v3,5v5,pick roll,horns,zon,man to man,serangan,papan,jurulatih,gelanggang",
    },
    "volleyball": {
        "en-US": "volleyball,6v6,4-2,5-1,6-2,setter,libero,rotation,serve,attack,block,coach",
        "zh-Hans": "排球,6v6,4-2,5-1,6-2,二传,自由人,轮换,发球,扣球,拦网,教练",
        "zh-Hant": "排球,6v6,4-2,5-1,6-2,舉球員,自由人,輪轉,發球,扣球,攔網,教練",
        "ja": "バレー,6v6,4-2,5-1,6-2,セッター,リベロ,ローテーション,サーブ,アタック,ブロック",
        "ko": "배구,6v6,4-2,5-1,6-2,세터,리베로,로테이션,서브,스파이크,블로킹,감독",
        "fr-FR": "volley,6v6,4-2,5-1,6-2,passeur,libéro,rotation,service,attaque,bloc,coach",
        "es-ES": "voleibol,6v6,4-2,5-1,6-2,colocador,líbero,rotación,saque,ataque,bloqueo,entrenador",
        "vi": "bóng chuyền,6v6,4-2,5-1,6-2,chuyền hai,libero,xoay vòng,phát bóng,đập,chắn,huấn luyện",
        "th": "วอลเลย์,6v6,4-2,5-1,6-2,ตัวเซต,ลิเบโร,หมุนตำแหน่ง,เสิร์ฟ,ตบ,บล็อก,โค้ช",
        "id": "voli,6v6,4-2,5-1,6-2,tosser,libero,rotasi,servis,smash,blok,pelatih",
        "ms": "bola tampar,6v6,4-2,5-1,6-2,setter,libero,rotasi,servis,rejaman,sekat,jurulatih",
    },
    "tennis": {
        "en-US": "tennis,doubles,singles,serve,return,volley,baseline,deuce,ad,court,coach,strategy",
        "zh-Hans": "网球,双打,单打,发球,接发,截击,底线,平分,占先,球场,教练,战术",
        "zh-Hant": "網球,雙打,單打,發球,接發,截擊,底線,平分,占先,球場,教練,戰術",
        "ja": "テニス,ダブルス,シングルス,サーブ,リターン,ボレー,ベースライン,デュース,コート,コーチ",
        "ko": "테니스,복식,단식,서브,리턴,발리,베이스라인,듀스,코트,코치,전술,라인업",
        "fr-FR": "tennis,double,simple,service,retour,volée,fond de court,égalité,terrain,coach,tactique",
        "es-ES": "tenis,dobles,individuales,saque,resto,volea,fondo,deuce,pista,entrenador,táctica,jugada",
        "vi": "tennis,đánh đôi,đánh đơn,giao bóng,trả giao,volley,cuối sân,deuce,sân,huấn luyện,chiến thuật",
        "th": "เทนนิส,คู่,เดี่ยว,เสิร์ฟ,รีเทิร์น,วอลเลย์,เบสไลน์,deuce,สนาม,โค้ช,กลยุทธ์",
        "id": "tenis,ganda,tunggal,servis,return,voli,baseline,deuce,lapangan,pelatih,taktik",
        "ms": "tenis,beregu,perseorangan,servis,return,voli,baseline,deuce,gelanggang,jurulatih,taktik",
    },
    "badminton": {
        "en-US": "badminton,doubles,singles,smash,clear,drop,net shot,front back,side by side,court,coach",
        "zh-Hans": "羽毛球,双打,单打,杀球,高远,放网,前后场,左右站位,球场,教练,跑位,战术",
        "zh-Hant": "羽球,雙打,單打,殺球,高遠球,放網,前後場,左右站位,球場,教練,跑位,戰術",
        "ja": "バドミントン,ダブルス,シングルス,スマッシュ,クリア,ドロップ,ヘアピン,前衛,後衛,コート,コーチ",
        "ko": "배드민턴,복식,단식,스매시,클리어,드롭,헤어핀,전위,후위,코트,코치,전술,라인업",
        "fr-FR": "badminton,double,simple,smash,dégagement,amorti,filet,avant arrière,terrain,coach,tactique",
        "es-ES": "bádminton,dobles,individuales,smash,clear,drop,red,delante atrás,cancha,entrenador,táctica",
        "vi": "cầu lông,đánh đôi,đánh đơn,đập cầu,phông cầu,bỏ nhỏ,lưới,trước sau,sân,huấn luyện,chiến thuật",
        "th": "แบดมินตัน,คู่,เดี่ยว,ตบลูก,ลูกโด่ง,หยอด,หน้าเน็ต,หน้าหลัง,สนาม,โค้ช,กลยุทธ์",
        "id": "bulu tangkis,ganda,tunggal,smash,lob,drop,netting,depan belakang,lapangan,pelatih,taktik",
        "ms": "badminton,beregu,perseorangan,smash,lob,dropshot,jaring,depan belakang,gelanggang,jurulatih",
    },
    "tableTennis": {
        "en-US": "table tennis,ping pong,topspin,backspin,loop,smash,push,serve,doubles,coach,paddle,strategy",
        "zh-Hans": "乒乓球,上旋,下旋,弧圈,扣杀,搓球,发球,双打,教练,球拍,战术,反手",
        "zh-Hant": "桌球,乒乓,上旋,下旋,弧圈,扣殺,搓球,發球,雙打,教練,球拍,戰術",
        "ja": "卓球,ピンポン,トップスピン,バックスピン,ループ,スマッシュ,ツッツキ,サーブ,ダブルス,コーチ,戦術",
        "ko": "탁구,핑퐁,톱스핀,백스핀,루프,스매시,푸시,서브,복식,코치,라켓,전술",
        "fr-FR": "tennis de table,ping pong,topspin,coupé,lift,smash,poussette,service,double,coach,raquette,tactique",
        "es-ES": "tenis de mesa,ping pong,topspin,cortado,liftado,smash,empuje,saque,dobles,entrenador,pala,táctica",
        "vi": "bóng bàn,ping pong,xoáy lên,xoáy xuống,giật,đập,gò,giao bóng,đôi,huấn luyện,vợt,chiến thuật",
        "th": "ปิงปอง,เทเบิลเทนนิส,topspin,backspin,ลูป,ตบ,ดัน,เสิร์ฟ,คู่,โค้ช,ไม้,กลยุทธ์",
        "id": "tenis meja,ping pong,topspin,backspin,loop,smash,push,servis,ganda,pelatih,bet,taktik",
        "ms": "ping pong,tenis meja,topspin,backspin,loop,smash,push,servis,beregu,jurulatih,bet,taktik",
    },
    "pickleball": {
        "en-US": "pickleball,dink,kitchen,third shot,drop,doubles,stacking,erne,ATP,coach,paddle,strategy",
        "zh-Hans": "匹克球,小球,厨房,第三球,过渡球,双打,叠站,挑边,教练,球拍,战术,跑位",
        "zh-Hant": "匹克球,小球,廚房,第三拍,過渡球,雙打,疊站,挑邊,教練,球拍,戰術",
        "ja": "ピックルボール,ディンク,キッチン,サードショット,ドロップ,ダブルス,スタッキング,コーチ,戦術",
        "ko": "피클볼,딩크,키친,서드샷,드롭,복식,스태킹,코치,라켓,전술,라인업,전략",
        "fr-FR": "pickleball,dink,kitchen,third shot,drop,double,stacking,coach,raquette,tactique,plan,équipe",
        "es-ES": "pickleball,dink,cocina,tercer golpe,drop,dobles,stacking,entrenador,pala,táctica,jugada",
        "vi": "pickleball,dink,kitchen,cú thứ ba,drop,đôi,stacking,huấn luyện,vợt,chiến thuật,sơ đồ",
        "th": "พิคเคิลบอล,dink,kitchen,third shot,drop,คู่,stacking,โค้ช,ไม้,กลยุทธ์,ผังเล่น",
        "id": "pickleball,dink,kitchen,third shot,drop,ganda,stacking,pelatih,raket,taktik,strategi",
        "ms": "pickleball,dink,kitchen,third shot,drop,beregu,stacking,jurulatih,raket,taktik,strategi",
    },
    "fieldHockey": {
        "en-US": "field hockey,hockey,penalty corner,short corner,press,formation,coach,stick,playbook,drill",
        "zh-Hans": "曲棍球,草地曲棍,角球,逼抢,阵型,教练,球棍,战术板,演练,跑位,训练,球队",
        "zh-Hant": "曲棍球,草地曲棍,角球,逼搶,陣型,教練,球棍,戰術板,演練,跑位,訓練,球隊",
        "ja": "ホッケー,フィールドホッケー,ペナルティコーナー,プレス,フォーメーション,コーチ,スティック,作戦",
        "ko": "필드하키,하키,페널티코너,프레스,포메이션,코치,스틱,전술판,훈련,라인업",
        "fr-FR": "hockey sur gazon,hockey,corner,pressing,formation,coach,crosse,plan,entraînement,équipe",
        "es-ES": "hockey hierba,hockey,córner corto,presión,formación,entrenador,palo,pizarra,jugada,equipo",
        "vi": "khúc côn cầu,hockey,phạt góc,pressing,đội hình,huấn luyện,gậy,sơ đồ,tập luyện,đội bóng",
        "th": "ฮอกกี้สนาม,ฮอกกี้,ลูกเตะมุม,เพรส,ฟอร์เมชัน,โค้ช,ไม้ฮอกกี้,กระดาน,ฝึกซ้อม,ทีม",
        "id": "hoki lapangan,hoki,sepak pojok,pressing,formasi,pelatih,stik,papan,latihan,tim",
        "ms": "hoki padang,hoki,sepak penjuru,pressing,formasi,jurulatih,kayu hoki,papan,latihan,pasukan",
    },
    "rugby": {
        "en-US": "rugby,union,sevens,scrum,lineout,maul,ruck,backs,forwards,playbook,coach,strategy",
        "zh-Hans": "橄榄球,联合式,七人制,争球,边线球,猛攻,贴身,后卫,前锋,战术板,教练,跑位",
        "zh-Hant": "橄欖球,聯合式,七人制,爭球,邊線球,猛攻,貼身,後衛,前鋒,戰術板,教練,跑位",
        "ja": "ラグビー,ユニオン,セブンズ,スクラム,ラインアウト,モール,ラック,バックス,フォワード,コーチ",
        "ko": "럭비,유니언,세븐스,스크럼,라인아웃,몰,럭,백스,포워드,전술판,코치,전략",
        "fr-FR": "rugby,union,à sept,mêlée,touche,maul,ruck,arrières,avants,plan,coach,tactique",
        "es-ES": "rugby,union,seven,melé,touche,maul,ruck,zagueros,delanteros,pizarra,entrenador,jugada",
        "vi": "bóng bầu dục,rugby,bảy người,scrum,lineout,maul,ruck,hậu vệ,tiền vệ,sơ đồ,huấn luyện",
        "th": "รักบี้,ยูเนียน,เซเว่นส์,scrum,lineout,maul,ruck,หลัง,หน้า,กระดาน,โค้ช,กลยุทธ์",
        "id": "rugby,union,sevens,scrum,lineout,maul,ruck,bek,depan,papan,pelatih,taktik",
        "ms": "ragbi,union,sevens,scrum,lineout,maul,ruck,belakang,depan,papan,jurulatih,taktik",
    },
    "baseball": {
        "en-US": "baseball,softball,pitching,batting,fielding,bunt,steal,double play,signs,coach,lineup,strategy",
        "zh-Hans": "棒球,垒球,投球,打击,守备,触击,盗垒,双杀,暗号,教练,打线,战术",
        "zh-Hant": "棒球,壘球,投球,打擊,守備,觸擊,盜壘,雙殺,暗號,教練,打線,戰術",
        "ja": "野球,ソフトボール,投球,打撃,守備,バント,盗塁,ダブルプレー,サイン,監督,打順,戦術",
        "ko": "야구,소프트볼,투구,타격,수비,번트,도루,더블플레이,사인,감독,라인업,전술",
        "fr-FR": "baseball,softball,lancer,frappe,défense,amorti,vol,double jeu,signes,coach,alignement,tactique",
        "es-ES": "béisbol,sóftbol,lanzamiento,bateo,defensa,toque,robo,doble play,señas,entrenador,alineación,jugada",
        "vi": "bóng chày,bóng mềm,ném bóng,đánh bóng,thủ,bunt,trộm chốt,double play,ký hiệu,huấn luyện,đội hình",
        "th": "เบสบอล,ซอฟต์บอล,ขว้าง,ตี,รับ,bunt,ขโมยเบส,double play,สัญญาณ,โค้ช,รายชื่อ,กลยุทธ์",
        "id": "bisbol,softbol,pitching,batting,fielding,bunt,curi base,double play,sandi,pelatih,susunan,taktik",
        "ms": "besbol,softbol,balingan,memukul,bertahan,bunt,curi base,double play,isyarat,jurulatih,susunan",
    },
    "handball": {
        "en-US": "handball,6-0,5-1,3-2-1,wing,pivot,back,fast break,playbook,coach,formation,strategy",
        "zh-Hans": "手球,6-0,5-1,3-2-1,边锋,中锋,后卫,快攻,战术板,教练,阵型,跑位",
        "zh-Hant": "手球,6-0,5-1,3-2-1,邊鋒,中鋒,後衛,快攻,戰術板,教練,陣型,跑位",
        "ja": "ハンドボール,6-0,5-1,3-2-1,ウイング,ピボット,バック,速攻,作戦,コーチ,フォーメーション",
        "ko": "핸드볼,6-0,5-1,3-2-1,윙,피벗,백,속공,전술판,코치,포메이션,전술",
        "fr-FR": "handball,6-0,5-1,3-2-1,ailier,pivot,arrière,contre attaque,plan,coach,formation,tactique",
        "es-ES": "balonmano,6-0,5-1,3-2-1,extremo,pivote,lateral,contraataque,pizarra,entrenador,formación,jugada",
        "vi": "bóng ném,6-0,5-1,3-2-1,cánh,trung phong,hậu vệ,phản công,sơ đồ,huấn luyện,đội hình",
        "th": "แฮนด์บอล,6-0,5-1,3-2-1,ปีก,ตัวกลาง,หลัง,เคาน์เตอร์,กระดาน,โค้ช,ฟอร์เมชัน",
        "id": "bola tangan,6-0,5-1,3-2-1,sayap,pivot,belakang,serangan balik,papan,pelatih,formasi",
        "ms": "bola baling,6-0,5-1,3-2-1,sayap,pivot,belakang,serangan balas,papan,jurulatih,formasi",
    },
    "waterPolo": {
        "en-US": "water polo,6v5,man up,zone,press,counter,driver,hole set,coach,playbook,strategy,formation",
        "zh-Hans": "水球,6v5,以多打少,联防,逼抢,反击,中锋,战术板,教练,跑位,阵型,训练",
        "zh-Hant": "水球,6v5,以多打少,聯防,逼搶,反擊,中鋒,戰術板,教練,跑位,陣型,訓練",
        "ja": "水球,6v5,パワープレー,ゾーン,プレス,カウンター,フローター,ホールセット,コーチ,作戦",
        "ko": "수구,6v5,파워플레이,지역방어,프레스,역습,홀셋,전술판,코치,라인업,전술",
        "fr-FR": "water polo,6v5,supériorité,zone,pressing,contre,pivot,plan,coach,formation,tactique",
        "es-ES": "waterpolo,6v5,superioridad,zona,presión,contra,boya,pizarra,entrenador,formación,jugada",
        "vi": "bóng nước,6v5,hơn người,phòng ngự khu vực,pressing,phản công,trung phong,sơ đồ,huấn luyện",
        "th": "โปโลน้ำ,6v5,ผู้เล่นเกิน,โซน,เพรส,เคาน์เตอร์,กระดาน,โค้ช,ฟอร์เมชัน,กลยุทธ์",
        "id": "polo air,6v5,kelebihan pemain,zona,pressing,serangan balik,pivot,papan,pelatih,formasi",
        "ms": "polo air,6v5,lebih pemain,zon,pressing,serangan balas,pivot,papan,jurulatih,formasi",
    },
    "sepakTakraw": {
        "en-US": "sepak takraw,takraw,regu,tekong,feeder,striker,doubles,SEA Games,coach,kick volleyball",
        "zh-Hans": "藤球,东南亚运动会,发球,助攻,杀球,双人,教练,战术,跑位,训练,球队",
        "zh-Hant": "藤球,東南亞運動會,發球,助攻,殺球,雙人,教練,戰術,跑位,訓練,球隊",
        "ja": "セパタクロー,テコン,フィーダー,ストライカー,東南アジア,コーチ,作戦,フォーメーション",
        "ko": "세팍타크로,테콩,피더,스트라이커,동남아,코치,전술,포메이션,훈련,라인업",
        "fr-FR": "sepak takraw,takraw,tekong,feeder,striker,Asie du Sud Est,coach,tactique,formation",
        "es-ES": "sepak takraw,takraw,tekong,feeder,striker,Sudeste Asiático,entrenador,táctica,formación",
        "vi": "cầu mây,sepak takraw,tekong,chuyền,tấn công,SEA Games,huấn luyện,chiến thuật,đội hình",
        "th": "ตะกร้อ,เซปักตะกร้อ,เทคองค์,ฟีดเดอร์,สไตรเกอร์,ซีเกมส์,โค้ช,กลยุทธ์,ฟอร์เมชัน",
        "id": "sepak takraw,takraw,tekong,feeder,striker,SEA Games,pelatih,taktik,formasi,strategi",
        "ms": "sepak takraw,takraw,tekong,feeder,striker,Sukan SEA,jurulatih,taktik,formasi,strategi",
    },
    "beachTennis": {
        "en-US": "beach tennis,beach,doubles,smash,lob,sand court,coach,paddle,strategy,playbook,formation",
        "zh-Hans": "沙滩网球,沙滩,双打,扣杀,挑高球,沙地,教练,球拍,战术,跑位,阵型,海滩",
        "zh-Hant": "沙灘網球,沙灘,雙打,扣殺,挑高球,沙地,教練,球拍,戰術,跑位,陣型,海灘",
        "ja": "ビーチテニス,ビーチ,ダブルス,スマッシュ,ロブ,砂浜,コーチ,ラケット,作戦,フォーメーション",
        "ko": "비치테니스,해변,복식,스매시,로브,모래,코치,라켓,전술,포메이션,라인업,전략",
        "fr-FR": "beach tennis,plage,double,smash,lob,sable,coach,raquette,tactique,plan,formation",
        "es-ES": "tenis playa,playa,dobles,smash,globo,arena,entrenador,pala,táctica,jugada,formación",
        "vi": "tennis bãi biển,bãi biển,đôi,đập bóng,bóng bổng,cát,huấn luyện,vợt,chiến thuật,sơ đồ",
        "th": "บีชเทนนิส,ชายหาด,คู่,smash,lob,ทราย,โค้ช,ไม้,กลยุทธ์,ผังเล่น,ฟอร์เมชัน",
        "id": "tenis pantai,pantai,ganda,smash,lob,pasir,pelatih,raket,taktik,strategi,formasi",
        "ms": "tenis pantai,pantai,beregu,smash,lob,pasir,jurulatih,raket,taktik,strategi,formasi",
    },
    "footvolley": {
        "en-US": "footvolley,futevolei,beach,doubles,Brazil,sand,coach,bicycle kick,playbook,strategy,header",
        "zh-Hans": "足排球,巴西,沙滩,双人,沙地,教练,倒钩,头球,战术,跑位,训练,球队",
        "zh-Hant": "足排球,巴西,沙灘,雙人,沙地,教練,倒鉤,頭球,戰術,跑位,訓練,球隊",
        "ja": "フットボレー,ブラジル,ビーチ,ダブルス,砂浜,コーチ,バイシクル,ヘディング,作戦,フォーメーション",
        "ko": "풋발리,브라질,해변,복식,모래,코치,바이시클킥,헤딩,전술,포메이션,훈련,라인업",
        "fr-FR": "footvolley,Brésil,plage,double,sable,coach,bicyclette,tête,plan,tactique,formation,équipe",
        "es-ES": "futvóley,Brasil,playa,dobles,arena,entrenador,chilena,cabeza,pizarra,jugada,formación,equipo",
        "vi": "footvolley,Brazil,bãi biển,đôi,cát,huấn luyện,xe đạp chổng ngược,đánh đầu,sơ đồ,chiến thuật",
        "th": "ฟุตวอลเลย์,บราซิล,ชายหาด,คู่,ทราย,โค้ช,จักรยานอากาศ,โหม่ง,กระดาน,กลยุทธ์,ฟอร์เมชัน",
        "id": "footvolley,Brasil,pantai,ganda,pasir,pelatih,salto,sundulan,papan,taktik,formasi,strategi",
        "ms": "footvolley,Brazil,pantai,beregu,pasir,jurulatih,tendang kayang,tanduk,papan,taktik,formasi",
    },
}

LOCALES = list(RN.keys())
SPORTS = list(KW.keys())

written_kw = 0
written_rn = 0
overflow_kw = []
for sport in SPORTS:
    for loc in LOCALES:
        # KEYWORDS
        kw = KW[sport][loc]
        if len(kw) > 100:
            overflow_kw.append((sport, loc, len(kw), kw))
        else:
            path = f"{BASE}/{sport}/{loc}/keywords.txt"
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w", encoding="utf-8") as f:
                f.write(kw)
            written_kw += 1
        # RELEASE NOTES
        rn = RN[loc]
        path = f"{BASE}/{sport}/{loc}/release_notes.txt"
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(rn)
        written_rn += 1

print(f"✅ wrote {written_kw} keywords + {written_rn} release_notes")
if overflow_kw:
    print(f"⚠ {len(overflow_kw)} keyword overflows:")
    for o in overflow_kw: print(f"  {o[0]}/{o[1]} = {o[2]}: {o[3]}")
