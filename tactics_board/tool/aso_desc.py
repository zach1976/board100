#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Batch B: description.txt for 16 apps × 11 locales = 176 files.
Stronger leads, sport-specific bullets, social proof, CTA. ≤4000 chars each.
Pattern: HOOK -> ELEVATOR -> 3 sections (Plan/Formation/Sideline) -> SOCIAL_PROOF -> CTA"""
import os
BASE = "/Users/zhenyusong/Desktop/projects/board100/tactics_board/fastlane/metadata"

# ════════════════════════════════════════════════════════════════════
# Per-sport DNA
# ════════════════════════════════════════════════════════════════════
# Each sport: hooks (per-locale), formations list (per-locale), signature term (per-locale),
# court_name (per-locale), team_size (per-locale)
SPORTS = {
    "tactics_board": {
        "umbrella": True,
        "name": {
            "en-US":"Tactics Board","zh-Hans":"战术板","zh-Hant":"戰術板","ja":"タクティクスボード",
            "ko":"전술 보드","fr-FR":"Tableau Tactique","es-ES":"Pizarra Táctica",
            "vi":"Bảng Chiến Thuật","th":"กระดานยุทธวิธี","id":"Papan Taktik","ms":"Papan Taktik",
        },
        "hook": {
            "en-US":"Your clipboard, upgraded to a full coaching brain.",
            "zh-Hans":"教练桌上的第二块大脑——7 项运动，一块画板。",
            "zh-Hant":"教練桌上的第二顆大腦——7 項運動，一塊畫板。",
            "ja":"監督の頭の中、見える化。7競技を1台に。",
            "ko":"감독의 두 번째 뇌. 7개 종목, 하나의 보드.",
            "fr-FR":"Votre clipboard, devenu un vrai cerveau de coach.",
            "es-ES":"Tu pizarra, convertida en el segundo cerebro del entrenador.",
            "vi":"Bộ não thứ hai của HLV — 7 môn, 1 bảng vẽ.",
            "th":"สมองที่สองของโค้ช — 7 กีฬาในกระดานเดียว",
            "id":"Otak kedua pelatih — 7 olahraga, 1 papan.",
            "ms":"Otak kedua jurulatih — 7 sukan, 1 papan.",
        },
        "elevator": {
            "en-US":"Tactics Board gives coaches, players, and analysts a professional canvas to draw plays, set formations, and animate movements — across 7 sports in one app.",
            "zh-Hans":"7 种运动，1 个 App。教练、球员、战术分析师的专业战术画板——画战术、摆阵型、放动画。",
            "zh-Hant":"7 種運動，1 個 App。教練、球員、戰術分析師的專業戰術畫板——畫戰術、擺陣型、放動畫。",
            "ja":"7競技を1つのアプリに。コーチ・選手・アナリストのためのプロ仕様の戦術キャンバス。",
            "ko":"7개 종목을 한 앱에. 감독·선수·분석가를 위한 프로 전술 캔버스.",
            "fr-FR":"7 sports dans une seule app. Une toile professionnelle pour coachs, joueurs et analystes.",
            "es-ES":"7 deportes en una app. Un lienzo profesional para entrenadores, jugadores y analistas.",
            "vi":"7 môn trong 1 app. Khung vẽ chuyên nghiệp cho HLV, cầu thủ và nhà phân tích.",
            "th":"7 กีฬาในแอปเดียว แคนวาสมืออาชีพสำหรับโค้ช นักกีฬา และนักวิเคราะห์",
            "id":"7 olahraga dalam satu aplikasi. Kanvas profesional untuk pelatih, pemain, dan analis.",
            "ms":"7 sukan dalam satu aplikasi. Kanvas profesional untuk jurulatih, pemain dan penganalisis.",
        },
        "list": {
            "en-US":"Soccer (5v5 / 7v7 / 11v11) · Basketball (3v3 / 5v5) · Volleyball (6v6) · Tennis · Badminton · Table Tennis · Pickleball\nSingles & doubles formations included.",
            "zh-Hans":"足球（5v5 / 7v7 / 11v11）· 篮球（3v3 / 5v5）· 排球（6v6）· 网球 · 羽毛球 · 乒乓球 · 匹克球\n单打双打阵型内置。",
            "zh-Hant":"足球（5v5 / 7v7 / 11v11）· 籃球（3v3 / 5v5）· 排球（6v6）· 網球 · 羽球 · 桌球 · 匹克球\n單打雙打陣型內建。",
            "ja":"サッカー (5v5/7v7/11v11) · バスケ (3v3/5v5) · バレー (6v6) · テニス · バドミントン · 卓球 · ピックルボール\nシングルス・ダブルスの陣形を内蔵。",
            "ko":"축구 (5v5/7v7/11v11) · 농구 (3v3/5v5) · 배구 (6v6) · 테니스 · 배드민턴 · 탁구 · 피클볼\n단·복식 포메이션 내장.",
            "fr-FR":"Football (5v5 / 7v7 / 11v11) · Basket (3v3 / 5v5) · Volley (6v6) · Tennis · Badminton · Tennis de table · Pickleball\nFormations simple et double incluses.",
            "es-ES":"Fútbol (5v5 / 7v7 / 11v11) · Baloncesto (3v3 / 5v5) · Voleibol (6v6) · Tenis · Bádminton · Tenis de mesa · Pickleball\nFormaciones individuales y dobles incluidas.",
            "vi":"Bóng đá (5v5 / 7v7 / 11v11) · Bóng rổ (3v3 / 5v5) · Bóng chuyền (6v6) · Quần vợt · Cầu lông · Bóng bàn · Pickleball\nĐội hình đơn và đôi tích hợp.",
            "th":"ฟุตบอล (5v5 / 7v7 / 11v11) · บาสเกตบอล (3v3 / 5v5) · วอลเลย์บอล (6v6) · เทนนิส · แบดมินตัน · ปิงปอง · พิคเคิลบอล\nรวมฟอร์เมชั่นเดี่ยวและคู่",
            "id":"Sepak bola (5v5 / 7v7 / 11v11) · Basket (3v3 / 5v5) · Voli (6v6) · Tenis · Bulu tangkis · Tenis meja · Pickleball\nFormasi tunggal & ganda tersedia.",
            "ms":"Bola sepak (5v5 / 7v7 / 11v11) · Bola keranjang (3v3 / 5v5) · Bola tampar (6v6) · Tenis · Badminton · Ping pong · Pickleball\nFormasi tunggal & beregu tersedia.",
        },
    },
    "soccer": {
        "name":{"en-US":"Soccer Board","zh-Hans":"足球战术板","zh-Hant":"足球戰術板","ja":"サッカーボード","ko":"축구 전술판","fr-FR":"Football Tactique","es-ES":"Pizarra de Fútbol","vi":"Bảng Chiến Thuật Bóng Đá","th":"กระดานฟุตบอล","id":"Papan Taktik Sepak Bola","ms":"Papan Taktik Bola Sepak"},
        "hook":{"en-US":"Draw the goal before it happens.","zh-Hans":"进球之前，先把它画出来。","zh-Hant":"進球之前，先把它畫出來。","ja":"ゴールを、起きる前に描く。","ko":"골을, 일어나기 전에 그려라.","fr-FR":"Dessinez le but avant qu'il n'arrive.","es-ES":"Dibuja el gol antes de que ocurra.","vi":"Vẽ bàn thắng trước khi nó xảy ra.","th":"วาดประตูก่อนมันจะเกิด","id":"Gambar gol sebelum terjadi.","ms":"Lukis gol sebelum ia berlaku."},
        "elevator":{"en-US":"Soccer Board is the tactical canvas trusted by coaches to plan formations, set pieces, and game strategy on a realistic pitch — from 5v5 futsal to full 11v11.","zh-Hans":"足球战术板是教练手中的战术画板——在逼真的绿茵场上规划阵型、定位球、整场战术，5 人制到 11 人制全覆盖。","zh-Hant":"足球戰術板是教練手中的戰術畫板——在逼真的綠茵場上規劃陣型、定位球、整場戰術，5 人制到 11 人制全覆蓋。","ja":"リアルなピッチに陣形・セットプレー・試合戦術を描く戦術キャンバス。フットサルから11人制まで対応。","ko":"실제 비율의 피치 위에 포메이션·세트피스·경기 전략을 그리는 전술 캔버스. 풋살부터 11인제까지.","fr-FR":"La toile tactique pour planifier formations, coups de pied arrêtés et stratégies — du futsal au 11 contre 11.","es-ES":"El lienzo táctico para planificar formaciones, balones parados y estrategias — del fútbol sala al 11 contra 11.","vi":"Khung vẽ chiến thuật để dựng đội hình, đá phạt và chiến lược — từ futsal 5v5 đến 11v11.","th":"แคนวาสยุทธวิธีสำหรับวางแผนฟอร์เมชั่น ลูกตั้งเตะ และเกมโดยรวม — ตั้งแต่ฟุตซอลถึง 11 ต่อ 11","id":"Kanvas taktik untuk merancang formasi, bola mati, dan strategi pertandingan — dari futsal hingga 11 lawan 11.","ms":"Kanvas taktik untuk rancang formasi, bola mati dan strategi — dari futsal hingga 11 lawan 11."},
        "list":{"en-US":"4-4-2 · 4-3-3 · 3-5-2 · 4-2-3-1 · 5v5 Futsal · 7v7\nApply with one tap. Customize from there.","zh-Hans":"4-4-2 · 4-3-3 · 3-5-2 · 4-2-3-1 · 5v5 五人制 · 7v7 七人制\n一键加载，自由调整。","zh-Hant":"4-4-2 · 4-3-3 · 3-5-2 · 4-2-3-1 · 5v5 五人制 · 7v7 七人制\n一鍵載入，自由調整。","ja":"4-4-2 · 4-3-3 · 3-5-2 · 4-2-3-1 · 5v5フットサル · 7v7\nワンタップで配置、自由にカスタマイズ。","ko":"4-4-2 · 4-3-3 · 3-5-2 · 4-2-3-1 · 5v5 풋살 · 7v7\n원탭으로 적용, 자유롭게 조정.","fr-FR":"4-4-2 · 4-3-3 · 3-5-2 · 4-2-3-1 · Futsal 5v5 · 7v7\nUn tap pour appliquer. Personnalisez ensuite.","es-ES":"4-4-2 · 4-3-3 · 3-5-2 · 4-2-3-1 · Fútbol sala 5v5 · 7v7\nUn toque para aplicar. Personaliza después.","vi":"4-4-2 · 4-3-3 · 3-5-2 · 4-2-3-1 · Futsal 5v5 · 7v7\nMột chạm để dùng, tùy biến theo ý.","th":"4-4-2 · 4-3-3 · 3-5-2 · 4-2-3-1 · ฟุตซอล 5v5 · 7v7\nแตะครั้งเดียวเรียกใช้ ปรับได้ตามใจ","id":"4-4-2 · 4-3-3 · 3-5-2 · 4-2-3-1 · Futsal 5v5 · 7v7\nSatu ketuk untuk pakai, sesuaikan dari situ.","ms":"4-4-2 · 4-3-3 · 3-5-2 · 4-2-3-1 · Futsal 5v5 · 7v7\nSatu sentuh untuk guna, ubah suai dari situ."},
    },
    "basketball": {
        "name":{"en-US":"Basketball Board","zh-Hans":"篮球战术板","zh-Hant":"籃球戰術板","ja":"バスケボード","ko":"농구 전술판","fr-FR":"Basketball Tactique","es-ES":"Pizarra de Baloncesto","vi":"Bảng Chiến Thuật Bóng Rổ","th":"กระดานบาสเกตบอล","id":"Papan Taktik Basket","ms":"Papan Taktik Bola Keranjang"},
        "hook":{"en-US":"Run the play before tip-off.","zh-Hans":"开球前，先在板上跑一遍。","zh-Hant":"開球前，先在板上跑一遍。","ja":"ティップオフの前に、もう一度走らせる。","ko":"점프볼 전에, 한 번 더 뛰어 봐라.","fr-FR":"Faites tourner la stratégie avant le coup d'envoi.","es-ES":"Ejecuta la jugada antes del salto inicial.","vi":"Chạy bài đấu trước khi bóng nhảy.","th":"รันเพลย์ก่อนเริ่มเกม","id":"Jalankan play sebelum tip-off.","ms":"Jalankan play sebelum tip-off."},
        "elevator":{"en-US":"Basketball Board lets coaches diagram pick-and-rolls, motion offense, and defensive rotations on an NBA-accurate court — for 3v3 and 5v5.","zh-Hans":"篮球战术板让教练在 NBA 标准球场上画挡拆、跑位、防守轮转——3v3 与 5v5 全支持。","zh-Hant":"籃球戰術板讓教練在 NBA 標準球場上畫擋拆、跑位、防守輪轉——3v3 與 5v5 全支援。","ja":"NBA基準のコートにピック&ロール、モーションオフェンス、ディフェンスローテーションを描く。3v3も5v5も対応。","ko":"NBA 비율 코트에서 픽앤롤·모션 오펜스·디펜스 로테이션을 그리세요. 3v3·5v5 모두 지원.","fr-FR":"Dessinez pick-and-roll, attaque en mouvement et rotations défensives sur un terrain aux dimensions NBA — 3 contre 3 et 5 contre 5.","es-ES":"Diagrama bloqueos directos, ataque en movimiento y rotaciones defensivas en cancha NBA — 3v3 y 5v5.","vi":"Vẽ pick-and-roll, motion offense và xoay phòng ngự trên sân chuẩn NBA — 3v3 và 5v5.","th":"วาดพิคแอนด์โรล โมชั่นออฟเฟนส์ และการหมุนป้องกันบนสนามมาตรฐาน NBA — 3v3 และ 5v5","id":"Gambar pick-and-roll, motion offense, dan rotasi pertahanan di lapangan ukuran NBA — 3v3 & 5v5.","ms":"Lukis pick-and-roll, motion offense dan putaran pertahanan di gelanggang ukuran NBA — 3v3 & 5v5."},
        "list":{"en-US":"1-2-2 Horns · 4-Out · 5-Out · 3-2 Zone · Box-and-One · Pick & Roll plays\nLoad in one tap, edit freely.","zh-Hans":"1-2-2 牛角 · 四外站位 · 五外站位 · 3-2 联防 · Box-and-One · 挡拆战术\n一键加载，自由编辑。","zh-Hant":"1-2-2 牛角 · 四外站位 · 五外站位 · 3-2 聯防 · Box-and-One · 擋拆戰術\n一鍵載入，自由編輯。","ja":"ホーンズ1-2-2 · 4アウト · 5アウト · 3-2ゾーン · ボックス&ワン · ピック&ロール\nワンタップで読込、自由に編集。","ko":"호른스 1-2-2 · 4-아웃 · 5-아웃 · 3-2 존 · 박스앤원 · 픽앤롤\n원탭 로드, 자유 편집.","fr-FR":"Horns 1-2-2 · 4-Out · 5-Out · Zone 3-2 · Box-and-One · Pick & Roll\nUn tap pour charger, modifiez librement.","es-ES":"Cuernos 1-2-2 · 4-Out · 5-Out · Zona 3-2 · Box-and-One · Pick & Roll\nUn toque para cargar, edita libremente.","vi":"Horns 1-2-2 · 4-Out · 5-Out · 3-2 Zone · Box-and-One · Pick & Roll\nMột chạm để tải, chỉnh tự do.","th":"Horns 1-2-2 · 4-Out · 5-Out · โซน 3-2 · Box-and-One · Pick & Roll\nแตะเดียวโหลด ปรับได้อิสระ","id":"Horns 1-2-2 · 4-Out · 5-Out · Zona 3-2 · Box-and-One · Pick & Roll\nSatu ketuk muat, edit bebas.","ms":"Horns 1-2-2 · 4-Out · 5-Out · Zon 3-2 · Box-and-One · Pick & Roll\nSatu sentuh muat, edit bebas."},
    },
    "volleyball": {
        "name":{"en-US":"Volleyball Board","zh-Hans":"排球战术板","zh-Hant":"排球戰術板","ja":"バレーボード","ko":"배구 전술판","fr-FR":"Volley Tactique","es-ES":"Pizarra de Voleibol","vi":"Bảng Chiến Thuật Bóng Chuyền","th":"กระดานวอลเลย์บอล","id":"Papan Taktik Voli","ms":"Papan Taktik Bola Tampar"},
        "hook":{"en-US":"Set the rotation. Win the rally.","zh-Hans":"轮转走对，球就赢了。","zh-Hant":"輪轉走對，球就贏了。","ja":"ローテーションを制す者が、ラリーを制す。","ko":"로테이션이 맞으면, 랠리는 이긴다.","fr-FR":"Bonne rotation. Rally gagné.","es-ES":"Rotación correcta, rally ganado.","vi":"Xoay đúng vị trí — thắng pha.","th":"หมุนถูก ก็ชนะลูกนั้น","id":"Rotasi pas, rally pun menang.","ms":"Pusingan tepat, rali pun menang."},
        "elevator":{"en-US":"Volleyball Board helps coaches design rotations, attack systems, and serve-receive formations — from 6v6 indoor to beach doubles.","zh-Hans":"排球战术板让教练规划轮转、进攻体系、一传站位——从 6v6 室内到沙滩双打。","zh-Hant":"排球戰術板讓教練規劃輪轉、進攻體系、一傳站位——從 6v6 室內到沙灘雙打。","ja":"ローテーション、攻撃システム、サーブレシーブ陣形を設計。6人制屋内からビーチダブルスまで。","ko":"로테이션·공격 시스템·서브 리시브 포메이션을 설계. 6인제 실내부터 비치 복식까지.","fr-FR":"Concevez rotations, systèmes d'attaque et réceptions — du 6 contre 6 en salle au beach en double.","es-ES":"Diseña rotaciones, sistemas de ataque y recepciones — del 6 contra 6 al beach por parejas.","vi":"Thiết kế xoay vị trí, hệ thống tấn công, đỡ bước 1 — từ 6v6 trong nhà đến đôi bãi biển.","th":"ออกแบบการหมุน ระบบบุก และการรับเสิร์ฟ — ตั้งแต่ 6v6 ในร่มถึงคู่ชายหาด","id":"Rancang rotasi, sistem serangan, dan terima servis — dari 6v6 dalam ruangan sampai voli pantai ganda.","ms":"Reka putaran, sistem serangan dan penerimaan — dari 6v6 dalaman hingga pantai beregu."},
        "list":{"en-US":"5-1 · 6-2 · 4-2 · Rotation 1-6 · Serve receive · Beach doubles\nLoad with one tap, customize positions.","zh-Hans":"5-1 · 6-2 · 4-2 · 1-6 号位轮转 · 一传站位 · 沙滩双打\n一键加载，自由调整位置。","zh-Hant":"5-1 · 6-2 · 4-2 · 1-6 號位輪轉 · 一傳站位 · 沙灘雙打\n一鍵載入，自由調整位置。","ja":"5-1 · 6-2 · 4-2 · 1-6番ローテ · サーブレシーブ · ビーチダブルス\nワンタップで配置、ポジション自由調整。","ko":"5-1 · 6-2 · 4-2 · 1-6 로테이션 · 서브 리시브 · 비치 복식\n원탭 로드, 위치 자유 조정.","fr-FR":"5-1 · 6-2 · 4-2 · Rotations 1-6 · Réception · Beach double\nUn tap pour charger, positions ajustables.","es-ES":"5-1 · 6-2 · 4-2 · Rotaciones 1-6 · Recepción · Playa dobles\nUn toque para cargar, posiciones ajustables.","vi":"5-1 · 6-2 · 4-2 · Vị trí 1-6 · Đỡ giao bóng · Đôi bãi biển\nMột chạm để tải, chỉnh vị trí.","th":"5-1 · 6-2 · 4-2 · ตำแหน่ง 1-6 · รับเสิร์ฟ · คู่ชายหาด\nแตะเดียวโหลด ปรับตำแหน่งได้","id":"5-1 · 6-2 · 4-2 · Rotasi 1-6 · Terima servis · Pantai ganda\nSatu ketuk muat, posisi atur sendiri.","ms":"5-1 · 6-2 · 4-2 · Putaran 1-6 · Penerimaan · Pantai beregu\nSatu sentuh muat, posisi ubah sendiri."},
    },
    "tennis": {
        "name":{"en-US":"Tennis Board","zh-Hans":"网球战术板","zh-Hant":"網球戰術板","ja":"テニスボード","ko":"테니스 전술판","fr-FR":"Tennis Tactique","es-ES":"Pizarra de Tenis","vi":"Bảng Chiến Thuật Quần Vợt","th":"กระดานเทนนิส","id":"Papan Taktik Tenis","ms":"Papan Taktik Tenis"},
        "hook":{"en-US":"Win the point on paper first.","zh-Hans":"先在纸上赢下这一分。","zh-Hant":"先在紙上贏下這一分。","ja":"そのポイント、紙の上で勝とう。","ko":"그 포인트, 종이 위에서 먼저 이겨라.","fr-FR":"Gagnez le point d'abord sur le papier.","es-ES":"Gana el punto primero sobre el papel.","vi":"Thắng pha trước trên giấy.","th":"เอาคะแนนนั้นก่อนบนกระดาษ","id":"Menangkan poin di atas kertas dulu.","ms":"Menangi mata di atas kertas dahulu."},
        "elevator":{"en-US":"Tennis Board lets coaches plan return positions, doubles formations, and rally patterns on a regulation court — singles and doubles.","zh-Hans":"网球战术板帮助教练规划接发站位、双打阵型、回合套路——单打双打全支持。","zh-Hant":"網球戰術板協助教練規劃接發站位、雙打陣型、回合套路——單打雙打全支援。","ja":"レギュレーションコートでリターン位置・ダブルス陣形・ラリーパターンを計画。シングルスもダブルスも対応。","ko":"규격 코트에서 리턴 위치·복식 포메이션·랠리 패턴을 계획. 단·복식 모두 지원.","fr-FR":"Planifiez positions de retour, formations en double et schémas d'échange sur un court réglementaire — simple et double.","es-ES":"Planea posiciones de resto, formaciones de dobles y patrones de peloteo en pista reglamentaria — individual y dobles.","vi":"Lập sơ đồ vị trí trả giao bóng, đội hình đôi và loạt đánh — đơn và đôi.","th":"วางตำแหน่งรับเสิร์ฟ ฟอร์เมชั่นคู่ และแพทเทิร์นการตี — เดี่ยวและคู่","id":"Rencanakan posisi return, formasi ganda, dan pola reli — tunggal dan ganda.","ms":"Rancang posisi return, formasi beregu dan pola rali — perseorangan dan beregu."},
        "list":{"en-US":"Singles baseline · Doubles I-formation · Australian formation · Net rush · Return positions\nDrag to customize.","zh-Hans":"单打底线站位 · 双打 I 阵 · 澳式阵 · 网前突击 · 接发站位\n拖动自由调整。","zh-Hant":"單打底線站位 · 雙打 I 陣 · 澳式陣 · 網前突擊 · 接發站位\n拖動自由調整。","ja":"シングルスベースライン · ダブルスIフォーメーション · オーストラリアン · ネットラッシュ · リターン位置\nドラッグで調整。","ko":"단식 베이스라인 · 복식 I 포메이션 · 호주식 · 네트 러시 · 리턴 위치\n드래그로 조정.","fr-FR":"Simple ligne de fond · Double formation I · Formation australienne · Montée au filet · Positions retour\nGlissez pour ajuster.","es-ES":"Individual línea de fondo · Dobles formación I · Formación australiana · Subida a la red · Posiciones de resto\nArrastra para ajustar.","vi":"Đơn baseline · Đôi I-formation · Australian · Lên lưới · Vị trí trả giao\nKéo để chỉnh.","th":"เดี่ยว Baseline · คู่ I-formation · Australian · บุกหน้าเน็ต · ตำแหน่งรับเสิร์ฟ\nลากเพื่อปรับ","id":"Tunggal Baseline · Ganda I-Formation · Australian · Maju ke net · Posisi return\nSeret untuk atur.","ms":"Perseorangan Baseline · Beregu I-Formation · Australian · Naik ke jaring · Posisi return\nSeret untuk laras."},
    },
    "badminton": {
        "name":{"en-US":"Badminton Board","zh-Hans":"羽毛球战术板","zh-Hant":"羽球戰術板","ja":"バドミントンボード","ko":"배드민턴 전술판","fr-FR":"Badminton Tactique","es-ES":"Pizarra de Bádminton","vi":"Bảng Chiến Thuật Cầu Lông","th":"กระดานแบดมินตัน","id":"Papan Taktik Bulu Tangkis","ms":"Papan Taktik Badminton"},
        "hook":{"en-US":"Move them. Then win the smash.","zh-Hans":"先把他调动开，再扣杀致胜。","zh-Hant":"先把他調動開，再殺球致勝。","ja":"動かしてから、決めるスマッシュ。","ko":"먼저 흔들고, 마지막 스매시.","fr-FR":"Déplacez. Puis smashez.","es-ES":"Muévelo. Luego remata.","vi":"Đưa họ chạy — rồi đập thắng.","th":"พาเขาวิ่ง แล้วตบจบ","id":"Geser dulu, lalu smash menang.","ms":"Gerakkan dia, kemudian smash menang."},
        "elevator":{"en-US":"Badminton Board helps players and coaches design singles, doubles, and mixed plays — including front-back, side-side, and rotations.","zh-Hans":"羽毛球战术板帮助选手和教练规划单打、双打、混双战术——前后站位、左右站位、轮转配合一应俱全。","zh-Hant":"羽球戰術板協助選手和教練規劃單打、雙打、混雙戰術——前後站位、左右站位、輪轉配合一應俱全。","ja":"シングルス・ダブルス・ミックスを設計。前後・左右・ローテーション、すべて対応。","ko":"단·복식·혼합 전술 설계. 전후·좌우·로테이션, 모두 지원.","fr-FR":"Concevez plans en simple, double et mixte — front-back, côte-à-côte, rotations.","es-ES":"Diseña planes en individual, dobles y mixto — frente-fondo, lado a lado, rotaciones.","vi":"Lập kế hoạch đơn, đôi, đôi nam nữ — trước-sau, cạnh-cạnh, xoay vòng.","th":"ออกแบบแผนเดี่ยว คู่ และคู่ผสม — หน้า-หลัง ข้าง-ข้าง การหมุน","id":"Rancang taktik tunggal, ganda, dan ganda campuran — depan-belakang, samping-samping, rotasi.","ms":"Reka taktik perseorangan, beregu dan beregu campuran — depan-belakang, sisi-sisi, putaran."},
        "list":{"en-US":"Singles baseline · Front-back doubles · Side-by-side · Rotation drills · Mixed doubles\nLoad with one tap, edit freely.","zh-Hans":"单打底线 · 双打前后站位 · 左右站位 · 轮转训练 · 混双站位\n一键加载，自由编辑。","zh-Hant":"單打底線 · 雙打前後站位 · 左右站位 · 輪轉訓練 · 混雙站位\n一鍵載入，自由編輯。","ja":"シングルスベース · ダブルス前後 · 左右並び · ローテーション · ミックス\nワンタップで配置、自由編集。","ko":"단식 베이스 · 복식 전후 · 좌우 · 로테이션 · 혼합복식\n원탭 적용, 자유 편집.","fr-FR":"Simple base · Double front-back · Côte à côte · Rotations · Mixte\nUn tap pour appliquer, modifiez ensuite.","es-ES":"Individual base · Doble frente-fondo · Lado a lado · Rotaciones · Mixto\nUn toque para aplicar, edita después.","vi":"Đơn baseline · Đôi trước-sau · Cạnh-cạnh · Bài xoay · Đôi nam nữ\nMột chạm để tải, chỉnh tự do.","th":"เดี่ยว Baseline · คู่หน้า-หลัง · ข้าง-ข้าง · ฝึกหมุน · คู่ผสม\nแตะเดียวโหลด ปรับได้","id":"Tunggal · Ganda depan-belakang · Sisi-sisi · Latihan rotasi · Ganda campuran\nSatu ketuk muat, edit bebas.","ms":"Perseorangan · Beregu depan-belakang · Sisi-sisi · Latihan putaran · Beregu campuran\nSatu sentuh muat, edit bebas."},
    },
    "tableTennis": {
        "name":{"en-US":"Table Tennis Board","zh-Hans":"乒乓球战术板","zh-Hant":"桌球戰術板","ja":"卓球ボード","ko":"탁구 전술판","fr-FR":"Tennis de Table Tactique","es-ES":"Pizarra de Tenis de Mesa","vi":"Bảng Chiến Thuật Bóng Bàn","th":"กระดานปิงปอง","id":"Papan Taktik Tenis Meja","ms":"Papan Taktik Ping Pong"},
        "hook":{"en-US":"Three shots ahead.","zh-Hans":"领先对手三板球。","zh-Hant":"領先對手三板球。","ja":"3球先まで読む。","ko":"세 타 앞서 봐라.","fr-FR":"Trois coups d'avance.","es-ES":"Tres golpes por delante.","vi":"Đi trước ba cú đánh.","th":"ก้าวนำสามตี","id":"Tiga pukulan di depan.","ms":"Tiga pukulan di hadapan."},
        "elevator":{"en-US":"Table Tennis Board lets coaches and players plan service patterns, return strategies, and 3rd-ball attacks on a regulation table.","zh-Hans":"乒乓球战术板让教练和球员规划发球套路、接发战术、第三板进攻——在标准球台上动手画。","zh-Hant":"桌球戰術板讓教練和球員規劃發球套路、接發戰術、第三板進攻——在標準球台上動手畫。","ja":"規格テーブル上でサーブパターン、レシーブ、3球目攻撃を計画。","ko":"규격 테이블에서 서브 패턴, 리시브 전략, 3구 공격을 계획.","fr-FR":"Planifiez schémas de service, stratégies de retour et attaques au 3e coup — sur table réglementaire.","es-ES":"Planea patrones de saque, estrategias de resto y ataques al 3er golpe — en mesa reglamentaria.","vi":"Lập kế hoạch giao bóng, đỡ bóng, tấn công cú thứ 3 — trên bàn chuẩn thi đấu.","th":"วางแผนรูปแบบเสิร์ฟ การรับลูก และจู่โจมลูกที่สาม — บนโต๊ะมาตรฐาน","id":"Rancang pola servis, strategi terima, dan serangan pukulan ke-3 — di meja standar.","ms":"Rancang corak servis, strategi terima dan serangan pukulan ke-3 — di meja piawai."},
        "list":{"en-US":"Service patterns · Return strategies · 3rd-ball attack · Doubles rotation · Forehand-backhand combos\nDrag and drop to plan.","zh-Hans":"发球套路 · 接发战术 · 第三板进攻 · 双打轮转 · 正反手组合\n拖放即可规划。","zh-Hant":"發球套路 · 接發戰術 · 第三板進攻 · 雙打輪轉 · 正反手組合\n拖放即可規劃。","ja":"サーブパターン · レシーブ · 3球目攻撃 · ダブルス回転 · フォア・バックコンボ\nドラッグで計画。","ko":"서브 패턴 · 리시브 · 3구 공격 · 복식 회전 · 포핸드-백핸드 콤보\n드래그로 계획.","fr-FR":"Schémas de service · Retours · Attaque 3e coup · Rotation double · Combos coup droit-revers\nGlissez pour planifier.","es-ES":"Patrones de saque · Restos · Ataque 3er golpe · Rotación dobles · Combos derecha-revés\nArrastra para planear.","vi":"Mẫu giao bóng · Đỡ bóng · Tấn công cú 3 · Xoay đôi · Combo thuận-trái\nKéo thả để lên kế hoạch.","th":"รูปแบบเสิร์ฟ · การรับลูก · บุกลูกที่ 3 · หมุนคู่ · คอมโบหน้ามือ-หลังมือ\nลากวางเพื่อวางแผน","id":"Pola servis · Terima · Serangan pukulan-3 · Rotasi ganda · Kombo forehand-backhand\nSeret-jatuhkan untuk rencanakan.","ms":"Corak servis · Terima · Serangan pukulan-3 · Putaran beregu · Kombo forehand-backhand\nSeret untuk rancang."},
    },
    "pickleball": {
        "name":{"en-US":"Pickleball Board","zh-Hans":"匹克球战术板","zh-Hant":"匹克球戰術板","ja":"ピックルボードタクティクス","ko":"피클볼 전술판","fr-FR":"Pickleball Tactique","es-ES":"Pizarra de Pickleball","vi":"Bảng Chiến Thuật Pickleball","th":"กระดานพิคเคิลบอล","id":"Papan Taktik Pickleball","ms":"Papan Taktik Pickleball"},
        "hook":{"en-US":"Own the kitchen line.","zh-Hans":"占住非截击区，赢下一切。","zh-Hant":"佔住非截擊區，贏下一切。","ja":"キッチンラインを制す。","ko":"키친 라인을 점령하라.","fr-FR":"Maîtrisez la ligne de cuisine.","es-ES":"Domina la línea de la cocina.","vi":"Làm chủ vạch bếp.","th":"ครองแนว Kitchen","id":"Kuasai garis kitchen.","ms":"Kuasai garisan kitchen."},
        "elevator":{"en-US":"Pickleball Board helps players and coaches plan stacking, doubles strategy, and dink-rally tactics on a regulation court.","zh-Hans":"匹克球战术板帮助选手和教练规划站位重叠、双打策略、Dink 回合战术——在标准球场上演练。","zh-Hant":"匹克球戰術板協助選手和教練規劃站位重疊、雙打策略、Dink 回合戰術——在標準球場上演練。","ja":"スタッキング、ダブルス戦略、ディンクラリー戦術を規格コートで計画。","ko":"스태킹·복식 전략·딩크 랠리 전술을 규격 코트에서 계획.","fr-FR":"Planifiez le stacking, la stratégie double et les tactiques de dink sur court réglementaire.","es-ES":"Planea stacking, estrategia de dobles y tácticas de dink en pista reglamentaria.","vi":"Lập kế hoạch stacking, chiến thuật đôi và pha dink — trên sân chuẩn.","th":"วางแผน Stacking กลยุทธ์คู่ และแท็คติค Dink — บนสนามมาตรฐาน","id":"Rancang stacking, strategi ganda, dan taktik dink — di lapangan standar.","ms":"Rancang stacking, strategi beregu dan taktik dink — di gelanggang piawai."},
        "list":{"en-US":"Doubles stacking · Drop-and-rush · Kitchen drills · Third shot drop · Erne plays\nDrag to customize.","zh-Hans":"双打 Stacking · 接发上前 · 非截击区训练 · 第三球过渡 · Erne 战术\n拖动调整。","zh-Hant":"雙打 Stacking · 接發上前 · 非截擊區訓練 · 第三球過渡 · Erne 戰術\n拖動調整。","ja":"ダブルススタッキング · ドロップ&ラッシュ · キッチン練習 · 3球目ドロップ · アーン\nドラッグで調整。","ko":"복식 스태킹 · 드롭앤러시 · 키친 드릴 · 3구 드롭 · 어니\n드래그로 조정.","fr-FR":"Stacking double · Drop-and-rush · Drills cuisine · 3e coup drop · Erne\nGlissez pour ajuster.","es-ES":"Stacking dobles · Drop-and-rush · Drills cocina · 3er tiro drop · Erne\nArrastra para ajustar.","vi":"Stacking đôi · Drop-and-rush · Bài tập kitchen · Cú 3 drop · Erne\nKéo để chỉnh.","th":"Stacking คู่ · Drop-and-rush · ฝึก Kitchen · ดรอปลูก 3 · Erne\nลากเพื่อปรับ","id":"Stacking ganda · Drop-and-rush · Latihan kitchen · 3rd shot drop · Erne\nSeret untuk atur.","ms":"Stacking beregu · Drop-and-rush · Latihan kitchen · 3rd shot drop · Erne\nSeret untuk laras."},
    },
    "fieldHockey": {
        "name":{"en-US":"Field Hockey Board","zh-Hans":"曲棍球战术板","zh-Hant":"曲棍球戰術板","ja":"ホッケー戦術ボード","ko":"필드하키 전술판","fr-FR":"Hockey sur Gazon Tactique","es-ES":"Pizarra de Hockey Hierba","vi":"Bảng Chiến Thuật Khúc Côn Cầu","th":"กระดานฮอกกี้สนาม","id":"Papan Taktik Hoki Lapangan","ms":"Papan Taktik Hoki Padang"},
        "hook":{"en-US":"Press them. Trap them. Score.","zh-Hans":"压上、围抢、破门——一气呵成。","zh-Hant":"壓上、圍搶、破門——一氣呵成。","ja":"プレス、罠、ゴール。","ko":"압박하고, 가두고, 골 넣어라.","fr-FR":"Pressez. Piégez. Marquez.","es-ES":"Presiona. Atrapa. Marca.","vi":"Pressing. Bẫy. Ghi bàn.","th":"กดดัน ดัก ทำประตู","id":"Tekan. Jebak. Cetak gol.","ms":"Tekan. Perangkap. Jaring."},
        "elevator":{"en-US":"Field Hockey Board gives coaches a precise pitch to plan formations, penalty corners, and pressing triggers — junior to international.","zh-Hans":"曲棍球战术板给教练精准的球场画板，规划阵型、短角球、压迫触发点——少年队到国家队。","zh-Hant":"曲棍球戰術板給教練精準的球場畫板，規劃陣型、短角球、壓迫觸發點——少年隊到國家隊。","ja":"ホッケーピッチに陣形・ペナルティコーナー・プレストリガーを描く。ジュニアから代表まで。","ko":"하키 피치에서 포메이션·페널티 코너·프레스 트리거를 계획. 유소년부터 대표팀까지.","fr-FR":"Toile de hockey précise pour planifier formations, coins courts et déclencheurs de pressing — jeunes ou pros.","es-ES":"Lienzo de hockey preciso para formaciones, córners cortos y triggers de presión — desde juveniles hasta seleccionados.","vi":"Khung sân hockey để lập đội hình, phạt góc ngắn, kích hoạt pressing — từ trẻ đến đội tuyển.","th":"แคนวาสฮอกกี้แม่นยำสำหรับฟอร์เมชั่น ลูกตั้งเตะมุมสั้น และทริกเกอร์เพรสซิ่ง — เยาวชนถึงทีมชาติ","id":"Kanvas hoki presisi untuk formasi, penalty corner, dan pemicu pressing — dari junior hingga timnas.","ms":"Kanvas hoki tepat untuk formasi, penalty corner dan pencetus pressing — junior hingga negara."},
        "list":{"en-US":"Attack & defense formations · Penalty corners · Short corner routines · Press triggers\nLoad with one tap, refine to your team.","zh-Hans":"进攻与防守阵型 · 短角球 · 长角球套路 · 压迫触发\n一键加载，按队伍调整。","zh-Hant":"進攻與防守陣型 · 短角球 · 長角球套路 · 壓迫觸發\n一鍵載入，按隊伍調整。","ja":"攻守陣形 · ペナルティコーナー · ショートコーナー · プレストリガー\nワンタップで配置、チームに合わせて調整。","ko":"공격·수비 포메이션 · 페널티 코너 · 쇼트 코너 · 프레스 트리거\n원탭 적용, 팀에 맞게 조정.","fr-FR":"Formations attaque-défense · Coins courts · Routines · Déclencheurs pressing\nUn tap pour charger, affinez.","es-ES":"Formaciones ataque-defensa · Córners cortos · Rutinas · Triggers de presión\nUn toque para cargar, afina.","vi":"Đội hình công-thủ · Phạt góc ngắn · Bài cố định · Trigger pressing\nMột chạm để tải, tinh chỉnh.","th":"ฟอร์เมชั่นรุก-รับ · ลูกมุมสั้น · รูทีน · ทริกเกอร์เพรส\nแตะเดียวโหลด ปรับตามทีม","id":"Formasi serang-bertahan · Corner pendek · Rutinitas · Pemicu pressing\nSatu ketuk muat, sesuaikan tim.","ms":"Formasi serang-pertahanan · Corner pendek · Rutin · Pencetus pressing\nSatu sentuh muat, sesuaikan pasukan."},
    },
    "rugby": {
        "name":{"en-US":"Rugby Board","zh-Hans":"橄榄球战术板","zh-Hant":"橄欖球戰術板","ja":"ラグビー戦術ボード","ko":"럭비 전술판","fr-FR":"Rugby Tactique","es-ES":"Pizarra de Rugby","vi":"Bảng Chiến Thuật Rugby","th":"กระดานรักบี้","id":"Papan Taktik Rugby","ms":"Papan Taktik Ragbi"},
        "hook":{"en-US":"Win the gainline.","zh-Hans":"控制前进线，控制比赛。","zh-Hant":"控制前進線，控制比賽。","ja":"ゲインラインを越える。","ko":"게인라인을 넘어라.","fr-FR":"Franchissez la ligne d'avantage.","es-ES":"Gana la gain line.","vi":"Vượt qua đường gain.","th":"ชนะที่ Gain Line","id":"Lewati gain line.","ms":"Lepasi gain line."},
        "elevator":{"en-US":"Rugby Board lets coaches design lineouts, scrum plays, and back-line patterns — for 7s, 10s, and 15s formats.","zh-Hans":"橄榄球战术板让教练规划界外球、争球套路、后线进攻——支持 7 人制、10 人制、15 人制。","zh-Hant":"橄欖球戰術板讓教練規劃界外球、爭球套路、後線進攻——支援 7 人制、10 人制、15 人制。","ja":"ラインアウト、スクラムプレー、バックスパターンを設計。7s/10s/15sすべて対応。","ko":"라인아웃·스크럼 플레이·백스 패턴을 설계. 7인제·10인제·15인제 모두 지원.","fr-FR":"Concevez touches, plans de mêlée et schémas de la ligne de trois-quarts — formats 7, 10 et 15.","es-ES":"Diseña líneas de touche, jugadas de scrum y patrones de tres cuartos — 7s, 10s y 15s.","vi":"Thiết kế lineout, bài scrum và mẫu hậu vệ — cho 7s, 10s và 15s.","th":"ออกแบบ Lineout, แผนสครัม และรูปแบบแบ็คไลน์ — 7s, 10s และ 15s","id":"Rancang lineout, taktik scrum, dan pola back-line — untuk 7s, 10s, dan 15s.","ms":"Reka lineout, taktik scrum dan corak back-line — untuk 7s, 10s dan 15s."},
        "list":{"en-US":"Lineouts · Scrum plays · Back-line attack · Defensive lines · Rucking systems\nLoad with one tap, edit your way.","zh-Hans":"界外球 · 争球套路 · 后线进攻 · 防守线 · 缠抢体系\n一键加载，自由编辑。","zh-Hant":"界外球 · 爭球套路 · 後線進攻 · 防守線 · 纏搶體系\n一鍵載入，自由編輯。","ja":"ラインアウト · スクラムプレー · バックスアタック · ディフェンスライン · ラックシステム\nワンタップで配置、自由編集。","ko":"라인아웃 · 스크럼 플레이 · 백스 공격 · 수비 라인 · 럭 시스템\n원탭 적용, 자유 편집.","fr-FR":"Touches · Plans mêlée · Attaque arrière · Lignes défensives · Système de ruck\nUn tap pour charger, modifiez.","es-ES":"Touches · Jugadas de scrum · Ataque tres cuartos · Líneas defensivas · Sistema de ruck\nUn toque para cargar, edita.","vi":"Lineout · Bài scrum · Tấn công hậu vệ · Hàng phòng ngự · Hệ thống ruck\nMột chạm để tải, chỉnh tự do.","th":"Lineout · แผนสครัม · บุกแบ็คไลน์ · แนวรับ · ระบบรัค\nแตะเดียวโหลด แก้ไขได้","id":"Lineout · Taktik scrum · Serangan back · Garis pertahanan · Sistem ruck\nSatu ketuk muat, edit bebas.","ms":"Lineout · Taktik scrum · Serangan belakang · Garis pertahanan · Sistem ruck\nSatu sentuh muat, edit bebas."},
    },
    "baseball": {
        "name":{"en-US":"Baseball Board","zh-Hans":"棒球战术板","zh-Hant":"棒球戰術板","ja":"野球作戦ボード","ko":"야구 전술판","fr-FR":"Baseball Tactique","es-ES":"Pizarra de Béisbol","vi":"Bảng Chiến Thuật Bóng Chày","th":"กระดานเบสบอล","id":"Papan Taktik Bisbol","ms":"Papan Taktik Besbol"},
        "hook":{"en-US":"Plan the play before the pitch.","zh-Hans":"投球之前，把战术先布好。","zh-Hant":"投球之前，把戰術先佈好。","ja":"投球前に、布陣を完成させろ。","ko":"투구 전에, 작전 끝내라.","fr-FR":"Planifiez avant le lancer.","es-ES":"Planea antes del lanzamiento.","vi":"Dựng bài trước khi giao bóng.","th":"วางแผนก่อนปล่อยลูก","id":"Rencanakan sebelum lemparan.","ms":"Rancang sebelum balingan."},
        "elevator":{"en-US":"Baseball Board lets coaches set defensive shifts, base-running plays, and pitcher coverage — diamond and outfield, all positions.","zh-Hans":"棒球战术板让教练设置防守站位、跑垒战术、投手补位——内野外野全位置。","zh-Hant":"棒球戰術板讓教練設置防守站位、跑壘戰術、投手補位——內野外野全位置。","ja":"守備シフト、走塁プレー、投手カバーを配置。内野・外野、全ポジション対応。","ko":"수비 시프트·주루 플레이·투수 커버를 설정. 내야·외야, 전 포지션.","fr-FR":"Configurez shifts défensifs, courses sur les bases et couverture du lanceur — diamant et champ extérieur.","es-ES":"Define shifts defensivos, jugadas de base y cobertura de pitcher — diamante y jardín completos.","vi":"Sắp xếp xoay phòng ngự, chạy chốt, hỗ trợ pitcher — diamond và outfield, mọi vị trí.","th":"ตั้งชิฟต์ป้องกัน วิ่งฐาน คัฟเวอร์พิทเชอร์ — ทุกตำแหน่ง","id":"Atur shift bertahan, jalur lari base, cover pitcher — diamond & outfield lengkap.","ms":"Susun shift pertahanan, larian base, lindungan pitcher — diamond & outfield lengkap."},
        "list":{"en-US":"Defensive shifts · Base running · Bunt defense · Cut-off plays · Pitcher coverage\nDrag positions to plan.","zh-Hans":"防守变阵 · 跑垒 · 触击防守 · 接力传球 · 投手补位\n拖动位置即可规划。","zh-Hant":"防守變陣 · 跑壘 · 觸擊防守 · 接力傳球 · 投手補位\n拖動位置即可規劃。","ja":"守備シフト · 走塁 · バント守備 · カットオフ · 投手カバー\nドラッグで計画。","ko":"수비 시프트 · 주루 · 번트 수비 · 컷오프 · 투수 커버\n드래그로 계획.","fr-FR":"Shifts défensifs · Courses sur bases · Défense bunt · Cut-off · Couverture lanceur\nGlissez pour planifier.","es-ES":"Shifts defensivos · Carreras de base · Defensa bunt · Cut-off · Cobertura pitcher\nArrastra para planear.","vi":"Xoay phòng ngự · Chạy chốt · Chống bunt · Cut-off · Hỗ trợ pitcher\nKéo để lên kế hoạch.","th":"ชิฟต์ป้องกัน · วิ่งฐาน · ป้องกันบันต์ · Cut-off · คัฟเวอร์พิทเชอร์\nลากเพื่อวางแผน","id":"Shift defensif · Lari base · Pertahanan bunt · Cut-off · Cover pitcher\nSeret untuk rencanakan.","ms":"Shift pertahanan · Larian base · Pertahanan bunt · Cut-off · Lindungan pitcher\nSeret untuk rancang."},
    },
    "handball": {
        "name":{"en-US":"Handball Board","zh-Hans":"手球战术板","zh-Hant":"手球戰術板","ja":"ハンドボール戦術ボード","ko":"핸드볼 전술판","fr-FR":"Handball Tactique","es-ES":"Pizarra de Balonmano","vi":"Bảng Chiến Thuật Bóng Ném","th":"กระดานแฮนด์บอล","id":"Papan Taktik Bola Tangan","ms":"Papan Taktik Bola Baling"},
        "hook":{"en-US":"Crash the 6-meter.","zh-Hans":"杀进 6 米线。","zh-Hant":"殺進 6 米線。","ja":"6メートルを突破。","ko":"6m 라인을 돌파하라.","fr-FR":"Forcez la zone des 6 mètres.","es-ES":"Penetra el área de 6 metros.","vi":"Phá vạch 6 mét.","th":"ทะลวงเส้น 6 เมตร","id":"Tembus garis 6 meter.","ms":"Tembusi garisan 6 meter."},
        "elevator":{"en-US":"Handball Board helps coaches plan attack systems, 6-0 and 5-1 defenses, and fast breaks on a regulation court.","zh-Hans":"手球战术板帮助教练规划进攻体系、6-0 与 5-1 防守、快攻——在标准球场上动手画。","zh-Hant":"手球戰術板協助教練規劃進攻體系、6-0 與 5-1 防守、快攻——在標準球場上動手畫。","ja":"6-0・5-1ディフェンス、攻撃システム、速攻を規格コートで設計。","ko":"6-0·5-1 수비, 공격 시스템, 속공을 규격 코트에서 설계.","fr-FR":"Concevez systèmes d'attaque, défenses 6-0 et 5-1 et contre-attaques sur terrain réglementaire.","es-ES":"Diseña sistemas de ataque, defensas 6-0 y 5-1 y contraataques en cancha reglamentaria.","vi":"Lập hệ thống tấn công, phòng ngự 6-0 và 5-1, và phản công — trên sân chuẩn.","th":"ออกแบบระบบบุก ป้องกัน 6-0 และ 5-1 และเคาเตอร์ — บนสนามมาตรฐาน","id":"Rancang sistem serangan, pertahanan 6-0 dan 5-1, serta serangan balik — di lapangan standar.","ms":"Reka sistem serangan, pertahanan 6-0 dan 5-1 dan serangan balas — di gelanggang piawai."},
        "list":{"en-US":"6-0 defense · 5-1 defense · 3-2-1 · Attack systems · Fast breaks\nOne tap to load, edit any position.","zh-Hans":"6-0 防守 · 5-1 防守 · 3-2-1 · 进攻体系 · 快攻\n一键加载，自由调整。","zh-Hant":"6-0 防守 · 5-1 防守 · 3-2-1 · 進攻體系 · 快攻\n一鍵載入，自由調整。","ja":"6-0ディフェンス · 5-1 · 3-2-1 · 攻撃システム · 速攻\nワンタップで配置、自由編集。","ko":"6-0 수비 · 5-1 · 3-2-1 · 공격 시스템 · 속공\n원탭 적용, 자유 편집.","fr-FR":"Défense 6-0 · 5-1 · 3-2-1 · Systèmes d'attaque · Contre-attaques\nUn tap pour charger, modifiez.","es-ES":"Defensa 6-0 · 5-1 · 3-2-1 · Sistemas de ataque · Contraataques\nUn toque para cargar, edita.","vi":"Phòng ngự 6-0 · 5-1 · 3-2-1 · Hệ thống tấn công · Phản công\nMột chạm để tải, chỉnh tự do.","th":"ป้องกัน 6-0 · 5-1 · 3-2-1 · ระบบบุก · เคาเตอร์\nแตะเดียวโหลด ปรับได้","id":"Pertahanan 6-0 · 5-1 · 3-2-1 · Sistem serangan · Serangan balik\nSatu ketuk muat, edit bebas.","ms":"Pertahanan 6-0 · 5-1 · 3-2-1 · Sistem serangan · Serangan balas\nSatu sentuh muat, edit bebas."},
    },
    "waterPolo": {
        "name":{"en-US":"Water Polo Board","zh-Hans":"水球战术板","zh-Hant":"水球戰術板","ja":"水球戦術ボード","ko":"수구 전술판","fr-FR":"Water-polo Tactique","es-ES":"Pizarra de Waterpolo","vi":"Bảng Chiến Thuật Bóng Nước","th":"กระดานโปโลน้ำ","id":"Papan Taktik Polo Air","ms":"Papan Taktik Polo Air"},
        "hook":{"en-US":"Move the man-up.","zh-Hans":"多打少，画出来。","zh-Hant":"多打少，畫出來。","ja":"マンアップを動かす。","ko":"맨업을 풀어라.","fr-FR":"Faites bouger la supériorité.","es-ES":"Mueve la superioridad.","vi":"Vận hành tình huống thiếu người.","th":"เดินเกม Man-up","id":"Olah man-up.","ms":"Olah man-up."},
        "elevator":{"en-US":"Water Polo Board helps coaches plan 4-2 and 3-3 attack, M-drop defenses, and 6-on-5 plays — full pool, all positions.","zh-Hans":"水球战术板帮助教练规划 4-2 与 3-3 进攻、M-drop 防守、6-on-5 多打少——整池战术全位置。","zh-Hant":"水球戰術板協助教練規劃 4-2 與 3-3 進攻、M-drop 防守、6-on-5 多打少——整池戰術全位置。","ja":"4-2・3-3攻撃、M-dropディフェンス、6-on-5マンアップを設計。プール全体・全ポジション。","ko":"4-2·3-3 공격, M-drop 수비, 6-on-5 맨업을 설계. 풀 전체, 전 포지션.","fr-FR":"Planifiez attaques 4-2 et 3-3, défenses M-drop et 6 contre 5 — bassin complet, tous postes.","es-ES":"Planea ataques 4-2 y 3-3, defensas M-drop y 6 contra 5 — piscina completa, todas las posiciones.","vi":"Lập kế hoạch tấn công 4-2, 3-3, phòng ngự M-drop và 6-on-5 — toàn hồ, mọi vị trí.","th":"วางแผนบุก 4-2 และ 3-3, ป้องกัน M-drop, 6-on-5 — ทั้งสระ ทุกตำแหน่ง","id":"Rancang serangan 4-2 dan 3-3, pertahanan M-drop, dan 6-on-5 — kolam penuh, semua posisi.","ms":"Reka serangan 4-2 dan 3-3, pertahanan M-drop, dan 6-on-5 — kolam penuh, semua posisi."},
        "list":{"en-US":"4-2 attack · 3-3 attack · M-drop defense · 6-on-5 power play · Counter-attack\nLoad with one tap, edit any swimmer.","zh-Hans":"4-2 进攻 · 3-3 进攻 · M-drop 防守 · 6-on-5 多打少 · 快攻反击\n一键加载，自由调整。","zh-Hant":"4-2 進攻 · 3-3 進攻 · M-drop 防守 · 6-on-5 多打少 · 快攻反擊\n一鍵載入，自由調整。","ja":"4-2攻撃 · 3-3攻撃 · M-drop · 6-on-5パワープレー · カウンター\nワンタップで配置、自由編集。","ko":"4-2 공격 · 3-3 공격 · M-drop 수비 · 6-on-5 파워플레이 · 역습\n원탭 적용, 자유 편집.","fr-FR":"Attaque 4-2 · 3-3 · Défense M-drop · 6 contre 5 · Contre-attaque\nUn tap pour charger, modifiez.","es-ES":"Ataque 4-2 · 3-3 · Defensa M-drop · 6 contra 5 · Contraataque\nUn toque para cargar, edita.","vi":"Tấn công 4-2 · 3-3 · M-drop · 6-on-5 · Phản công\nMột chạm để tải, chỉnh tự do.","th":"บุก 4-2 · 3-3 · M-drop · 6-on-5 · Counter\nแตะเดียวโหลด ปรับได้","id":"Serangan 4-2 · 3-3 · M-drop · 6-on-5 · Serangan balik\nSatu ketuk muat, edit bebas.","ms":"Serangan 4-2 · 3-3 · M-drop · 6-on-5 · Serangan balas\nSatu sentuh muat, edit bebas."},
    },
    "sepakTakraw": {
        "name":{"en-US":"Sepak Takraw Board","zh-Hans":"藤球战术板","zh-Hant":"藤球戰術板","ja":"セパタクロー戦術ボード","ko":"세팍타크로 전술판","fr-FR":"Sepak Takraw Tactique","es-ES":"Pizarra de Sepak Takraw","vi":"Bảng Chiến Thuật Cầu Mây","th":"กระดานตะกร้อ","id":"Papan Taktik Sepak Takraw","ms":"Papan Taktik Sepak Takraw"},
        "hook":{"en-US":"Master the regu rotation.","zh-Hans":"三人队，跑得明白。","zh-Hant":"三人隊，跑得明白。","ja":"レグの動き、見える化。","ko":"레구의 흐름을 잡아라.","fr-FR":"Maîtrisez la rotation du regu.","es-ES":"Domina la rotación regu.","vi":"Làm chủ xoay vị trí 3 người.","th":"ครองการหมุน Regu","id":"Kuasai rotasi regu.","ms":"Kuasai pusingan regu."},
        "elevator":{"en-US":"Sepak Takraw Board lets coaches and players design tekong serves, feeder plays, and striker bicycle kicks for the regu format.","zh-Hans":"藤球战术板让教练和球员规划发球员发球、举球员配合、攻击手倒勾——三人队战术。","zh-Hant":"藤球戰術板讓教練和球員規劃發球員發球、舉球員配合、攻擊手倒勾——三人隊戰術。","ja":"テコンのサーブ、フィーダープレー、ストライカーのバイシクルキックを3人レグ形式で設計。","ko":"테콩 서브, 피더 플레이, 스트라이커 바이시클킥을 레구 포맷으로 설계.","fr-FR":"Concevez services tekong, jeux de feeder et retournés du striker — format regu.","es-ES":"Diseña saques tekong, jugadas de feeder y chilenas del striker — formato regu.","vi":"Thiết kế giao bóng tekong, chuyền của feeder, móc của striker — đội regu 3 người.","th":"ออกแบบเสิร์ฟเทคงค์ จังหวะลูกฟีดเดอร์ และจักรยานตีกลับของสไตรเกอร์ — รูปแบบเรกู","id":"Rancang servis tekong, umpan feeder, dan bicycle kick striker — format regu.","ms":"Reka servis tekong, hantaran feeder dan tendangan basikal striker — format regu."},
        "list":{"en-US":"Tekong serve patterns · Feeder set-ups · Striker rolls · Defensive blocks · Asian Games drills\nOne tap to load.","zh-Hans":"发球员套路 · 举球员配合 · 攻击手跑位 · 防守拦网 · 亚运训练\n一键加载。","zh-Hant":"發球員套路 · 舉球員配合 · 攻擊手跑位 · 防守攔網 · 亞運訓練\n一鍵載入。","ja":"テコンサーブパターン · フィーダー · ストライカー動き · ディフェンスブロック · アジア大会練習\nワンタップで配置。","ko":"테콩 서브 패턴 · 피더 셋업 · 스트라이커 동선 · 디펜스 블록 · 아시안게임 훈련\n원탭 적용.","fr-FR":"Schémas service tekong · Feeder · Striker · Blocs défense · Drills Jeux Asiatiques\nUn tap pour charger.","es-ES":"Patrones servicio tekong · Feeder · Striker · Bloqueos · Drills Juegos Asiáticos\nUn toque para cargar.","vi":"Mẫu giao bóng tekong · Feeder · Striker · Chắn lưới · Bài tập SEA Games\nMột chạm để tải.","th":"แพทเทิร์นเสิร์ฟเทคงค์ · ฟีดเดอร์ · สไตรเกอร์ · บล็อกป้องกัน · ฝึกซีเกมส์\nแตะเดียวโหลด","id":"Pola servis tekong · Feeder · Striker · Blok pertahanan · Latihan SEA Games\nSatu ketuk muat.","ms":"Corak servis tekong · Feeder · Striker · Blok pertahanan · Latihan Sukan SEA\nSatu sentuh muat."},
    },
    "beachTennis": {
        "name":{"en-US":"Beach Tennis Board","zh-Hans":"沙滩网球战术板","zh-Hant":"沙灘網球戰術板","ja":"ビーチテニス戦術ボード","ko":"비치테니스 전술판","fr-FR":"Beach Tennis Tactique","es-ES":"Pizarra de Tenis Playa","vi":"Bảng Chiến Thuật Tennis Bãi Biển","th":"กระดานบีชเทนนิส","id":"Papan Taktik Tenis Pantai","ms":"Papan Taktik Tenis Pantai"},
        "hook":{"en-US":"Doubles. Sand. Smash.","zh-Hans":"双打 · 沙滩 · 扣杀。","zh-Hant":"雙打 · 沙灘 · 扣殺。","ja":"ダブルス。砂浜。スマッシュ。","ko":"복식. 모래. 스매시.","fr-FR":"Double. Sable. Smash.","es-ES":"Dobles. Arena. Smash.","vi":"Đôi. Cát. Đập.","th":"คู่ ทราย ตบ","id":"Ganda. Pasir. Smash.","ms":"Beregu. Pasir. Smash."},
        "elevator":{"en-US":"Beach Tennis Board lets players plan stacking, smash setups, and rotation for sand-court doubles.","zh-Hans":"沙滩网球战术板让球员规划站位、扣杀套路、沙地双打轮转。","zh-Hant":"沙灘網球戰術板讓球員規劃站位、扣殺套路、沙地雙打輪轉。","ja":"スタッキング、スマッシュセットアップ、ローテーションを砂地ダブルスで設計。","ko":"모래 코트 복식의 스태킹·스매시 셋업·로테이션을 계획.","fr-FR":"Planifiez stacking, smashs et rotations en double sur sable.","es-ES":"Planea stacking, smashes y rotación en dobles sobre arena.","vi":"Lập sơ đồ stacking, đập bóng, xoay vị trí — đôi trên cát.","th":"วางแผน Stacking, จังหวะตบ, การหมุน — คู่บนทราย","id":"Rancang stacking, smash, dan rotasi — ganda di pasir.","ms":"Rancang stacking, smash dan putaran — beregu di pasir."},
        "list":{"en-US":"Doubles stacking · Smash setups · Net coverage · Lob defense · Rotation drills\nDrag to customize.","zh-Hans":"双打 Stacking · 扣杀套路 · 网前覆盖 · 高球防守 · 轮转训练\n拖动调整。","zh-Hant":"雙打 Stacking · 扣殺套路 · 網前覆蓋 · 高球防守 · 輪轉訓練\n拖動調整。","ja":"ダブルススタッキング · スマッシュセット · ネットカバー · ロブ守備 · ローテーション\nドラッグ調整。","ko":"복식 스태킹 · 스매시 셋업 · 네트 커버 · 로브 수비 · 로테이션\n드래그로 조정.","fr-FR":"Stacking · Setups smash · Couverture filet · Défense lob · Rotations\nGlissez pour ajuster.","es-ES":"Stacking · Setups smash · Cobertura red · Defensa lob · Rotaciones\nArrastra para ajustar.","vi":"Stacking · Set smash · Phủ lưới · Đỡ lob · Bài xoay\nKéo để chỉnh.","th":"Stacking · Set ตบ · ครองหน้าเน็ต · ป้องกันลอบ · ฝึกหมุน\nลากเพื่อปรับ","id":"Stacking · Set smash · Tutup net · Pertahanan lob · Latihan rotasi\nSeret untuk atur.","ms":"Stacking · Set smash · Tutup jaring · Pertahanan lob · Latihan putaran\nSeret untuk laras."},
    },
    "footvolley": {
        "name":{"en-US":"Footvolley Board","zh-Hans":"足排球战术板","zh-Hant":"足排球戰術板","ja":"フットボレー戦術ボード","ko":"풋발리 전술판","fr-FR":"Footvolley Tactique","es-ES":"Pizarra de Futvóley","vi":"Bảng Chiến Thuật Footvolley","th":"กระดานฟุตวอลเลย์","id":"Papan Taktik Footvolley","ms":"Papan Taktik Footvolley"},
        "hook":{"en-US":"Brazilian feet. Beach win.","zh-Hans":"巴西脚法，沙滩制胜。","zh-Hant":"巴西腳法，沙灘制勝。","ja":"ブラジルの足、ビーチで勝つ。","ko":"브라질의 발끝, 모래에서 승부.","fr-FR":"Pieds brésiliens. Victoire sur sable.","es-ES":"Pies brasileños. Victoria en arena.","vi":"Đôi chân Brazil. Thắng trên cát.","th":"เท้าสไตล์บราซิล ชนะบนทราย","id":"Kaki gaya Brasil. Menang di pasir.","ms":"Kaki gaya Brazil. Menang di pasir."},
        "elevator":{"en-US":"Footvolley Board helps players plan plays for the sand-court doubles game — soccer touch, volleyball court, no hands.","zh-Hans":"足排球战术板帮助球员规划沙地双打战术——足球脚法，排球场地，全程不能用手。","zh-Hant":"足排球戰術板協助球員規劃沙地雙打戰術——足球腳法，排球場地，全程不能用手。","ja":"砂地ダブルスのプレーを設計。サッカーのタッチ、バレーのコート、ノーハンド。","ko":"모래 복식 플레이를 설계. 축구 터치, 배구 코트, 노핸드.","fr-FR":"Planifiez vos jeux pour le double sur sable — touche foot, terrain volley, sans les mains.","es-ES":"Planea jugadas para el doble en arena — toque de fútbol, cancha de vóley, sin manos.","vi":"Lập kế hoạch pha bóng đôi trên cát — chạm chân kiểu bóng đá, sân bóng chuyền, không tay.","th":"วางแผนคู่บนทราย — สัมผัสแบบฟุตบอล สนามแบบวอลเลย์ ห้ามใช้มือ","id":"Rancang taktik ganda di pasir — sentuhan sepak bola, lapangan voli, tanpa tangan.","ms":"Rancang taktik beregu di pasir — sentuhan bola sepak, gelanggang bola tampar, tanpa tangan."},
        "list":{"en-US":"Brazilian doubles · Header attacks · Bicycle kicks · Set-and-spike · Defensive coverage\nDrag to plan.","zh-Hans":"巴西双打 · 头球进攻 · 倒勾 · 一传二攻 · 防守覆盖\n拖放规划。","zh-Hant":"巴西雙打 · 頭球進攻 · 倒勾 · 一傳二攻 · 防守覆蓋\n拖放規劃。","ja":"ブラジルダブルス · ヘディング攻撃 · バイシクル · セット&スパイク · 守備カバー\nドラッグ配置。","ko":"브라질 복식 · 헤딩 공격 · 바이시클 · 세트&스파이크 · 수비 커버\n드래그로 배치.","fr-FR":"Double brésilien · Attaque tête · Retournés · Set-and-spike · Couverture défense\nGlissez pour planifier.","es-ES":"Dobles brasileño · Cabezazos · Chilenas · Set-and-spike · Cobertura defensa\nArrastra para planear.","vi":"Đôi kiểu Brazil · Đánh đầu · Móc xe đạp · Set-and-spike · Phủ phòng ngự\nKéo để lên kế hoạch.","th":"คู่สไตล์บราซิล · บุกด้วยหัว · จักรยาน · เซ็ต&ตบ · ครอบคลุมป้องกัน\nลากวางวางแผน","id":"Ganda Brasil · Sundulan · Bicycle kick · Set-and-spike · Cover pertahanan\nSeret-jatuhkan untuk rencanakan.","ms":"Beregu Brazil · Tandukan · Tendangan basikal · Set-and-spike · Lindungan pertahanan\nSeret untuk rancang."},
    },
}

# ════════════════════════════════════════════════════════════════════
# Per-locale framing (section headers, social proof, CTA)
# ════════════════════════════════════════════════════════════════════
LOCALE = {
    "en-US": {
        "h_plan":"DRAW IT. PLAY IT. SHARE IT.",
        "h_formation":"FORMATIONS, READY TO GO",
        "h_built":"BUILT FOR THE SIDELINE",
        "b_plan":"- Drag players onto an accurate, full-color court\n- Draw arrows, lines, and zones — colors and styles your way\n- Tap Play to animate movements step by step\n- Save unlimited tactics, share as crisp images or PDF",
        "b_built":"- Works offline — no Wi-Fi at the field? No problem.\n- Dark theme — easy on the eyes during evening practice\n- Undo/redo up to 50 steps — experiment fearlessly\n- AirPlay to TV — turn the locker room into a war room\n- Free, no ads, no in-app purchases",
        "lang_line":"11 LANGUAGES\nEnglish · 简体中文 · 繁體中文 · 日本語 · 한국어 · Français · Español · Tiếng Việt · ไทย · Bahasa Indonesia · Bahasa Melayu",
        "social":"Trusted by youth coaches and clubs across 50+ leagues. Free forever, no account required.",
        "cta":"From Sunday league to the national team — if you can coach it, you can draw it.",
    },
    "zh-Hans": {
        "h_plan":"画出来 · 动起来 · 传出去",
        "h_formation":"经典阵型，开箱即用",
        "h_built":"为场边而生",
        "b_plan":"· 拖放球员到精准还原的全彩球场\n· 实线、虚线、箭头，颜色粗细随心调\n· 点击「播放」，球员按路线自动移动\n· 保存无限战术，导出高清图片或 PDF",
        "b_built":"· 离线可用 — 球场没 Wi-Fi？没关系\n· 暗色主题 — 晚间训练不刺眼\n· 50 步撤销/重做 — 大胆尝试，随时回退\n· AirPlay 投屏 — 更衣室秒变作战室\n· 完全免费，无广告，无内购",
        "lang_line":"支持 11 种语言\n中文 · English · 日本語 · 한국어 · Français · Español · Tiếng Việt · ไทย · Bahasa Indonesia · Bahasa Melayu",
        "social":"50+ 联赛青训教练在用。永久免费，无需注册。",
        "cta":"从周末野球到国家队 — 你能教的，就能画出来。",
    },
    "zh-Hant": {
        "h_plan":"畫出來 · 動起來 · 傳出去",
        "h_formation":"經典陣型，開箱即用",
        "h_built":"為場邊而生",
        "b_plan":"· 拖放球員到精準還原的全彩球場\n· 實線、虛線、箭頭，顏色粗細隨心調\n· 點擊「播放」，球員按路線自動移動\n· 保存無限戰術，匯出高清圖片或 PDF",
        "b_built":"· 離線可用 — 球場沒 Wi-Fi？沒關係\n· 暗色主題 — 晚間訓練不刺眼\n· 50 步撤銷/重做 — 大膽嘗試，隨時回退\n· AirPlay 投屏 — 更衣室秒變作戰室\n· 完全免費，無廣告，無內購",
        "lang_line":"支援 11 種語言\n中文 · English · 日本語 · 한국어 · Français · Español · Tiếng Việt · ไทย · Bahasa Indonesia · Bahasa Melayu",
        "social":"50+ 聯賽青訓教練在用。永久免費，無需註冊。",
        "cta":"從週末野球到國家隊 — 你能教的，就能畫出來。",
    },
    "ja": {
        "h_plan":"描く · 動かす · 共有する",
        "h_formation":"フォーメーション、即起動",
        "h_built":"ベンチサイドのために作られた",
        "b_plan":"・選手を正確な縮尺のコートにドラッグ\n・矢印・線・ゾーンを自由な色と太さで\n・「再生」で選手が一歩ずつ自動で動く\n・戦術を無制限保存、高画質画像とPDFで共有",
        "b_built":"・オフライン対応 — 現場にWi-Fiが無くても大丈夫\n・ダークテーマ — 夜練習でも目に優しい\n・50ステップのアンドゥ/リドゥ — 思い切り試して戻せる\n・AirPlay対応 — ロッカールームが作戦室に\n・完全無料、広告なし、課金なし",
        "lang_line":"11言語対応\n日本語 · English · 简体中文 · 繁體中文 · 한국어 · Français · Español · Tiếng Việt · ไทย · Bahasa Indonesia · Bahasa Melayu",
        "social":"全国50リーグ以上のユースコーチとクラブが愛用中。無料、登録不要。",
        "cta":"草サッカーから代表チームまで — コーチできるなら、描ける。",
    },
    "ko": {
        "h_plan":"그려라 · 움직여라 · 공유하라",
        "h_formation":"포메이션, 즉시 적용",
        "h_built":"사이드라인을 위해 만들어졌다",
        "b_plan":"· 정확한 비율의 풀컬러 코트에 선수 드래그\n· 화살표·선·영역, 색상과 굵기 자유 조절\n· '재생' 탭으로 선수들이 단계별 자동 이동\n· 전술 무제한 저장, 고화질 이미지·PDF로 공유",
        "b_built":"· 오프라인 작동 — 경기장에 Wi-Fi 없어도 OK\n· 다크 테마 — 저녁 훈련에도 눈이 편하다\n· 50단계 실행 취소/다시 실행 — 마음껏 시도\n· AirPlay 지원 — 라커룸이 작전실로\n· 완전 무료, 광고 없음, 인앱결제 없음",
        "lang_line":"11개 언어 지원\n한국어 · English · 简体中文 · 繁體中文 · 日本語 · Français · Español · Tiếng Việt · ไทย · Bahasa Indonesia · Bahasa Melayu",
        "social":"50개 이상 리그의 유소년 감독·클럽이 사용 중. 무료·계정 불필요.",
        "cta":"동네 리그부터 국가대표까지 — 가르칠 수 있다면, 그릴 수 있다.",
    },
    "fr-FR": {
        "h_plan":"DESSINEZ. JOUEZ. PARTAGEZ.",
        "h_formation":"FORMATIONS, PRÊTES À L'EMPLOI",
        "h_built":"CONÇU POUR LE BORD DU TERRAIN",
        "b_plan":"- Glissez les joueurs sur un terrain en couleurs précis\n- Flèches, lignes, zones — couleurs et styles à votre goût\n- Touchez Play et les joueurs bougent étape par étape\n- Sauvegardez sans limite, exportez en image HD ou PDF",
        "b_built":"- Fonctionne hors-ligne — pas de Wi-Fi sur le terrain ? Pas de souci.\n- Thème sombre — repose les yeux le soir\n- Annuler/refaire jusqu'à 50 étapes — testez sans peur\n- AirPlay vers TV — le vestiaire devient salle de stratégie\n- Gratuit, sans pub, sans achat intégré",
        "lang_line":"11 LANGUES\nFrançais · English · 简体中文 · 繁體中文 · 日本語 · 한국어 · Español · Tiếng Việt · ไทย · Bahasa Indonesia · Bahasa Melayu",
        "social":"Plébiscité par les coachs de jeunes et clubs de plus de 50 ligues. Gratuit, sans compte.",
        "cta":"Du foot du dimanche à l'équipe nationale — si vous l'enseignez, vous le dessinez.",
    },
    "es-ES": {
        "h_plan":"DIBUJA. JUEGA. COMPARTE.",
        "h_formation":"FORMACIONES, LISTAS",
        "h_built":"HECHO PARA EL BANQUILLO",
        "b_plan":"- Arrastra jugadores a un terreno en color a escala\n- Flechas, líneas, zonas — colores y estilos a tu gusto\n- Toca Play y los jugadores se mueven paso a paso\n- Guarda jugadas sin límite, exporta en imagen HD o PDF",
        "b_built":"- Funciona sin conexión — ¿no hay Wi-Fi en la cancha? Sin problema.\n- Tema oscuro — descansa la vista en entrenamiento nocturno\n- Deshacer/rehacer hasta 50 pasos — experimenta sin miedo\n- AirPlay a TV — el vestuario se vuelve sala de guerra\n- Gratis, sin anuncios, sin compras integradas",
        "lang_line":"11 IDIOMAS\nEspañol · English · 简体中文 · 繁體中文 · 日本語 · 한국어 · Français · Tiếng Việt · ไทย · Bahasa Indonesia · Bahasa Melayu",
        "social":"Usado por entrenadores juveniles y clubes en más de 50 ligas. Gratis, sin cuenta.",
        "cta":"De la liga del domingo a la selección — si lo entrenas, lo dibujas.",
    },
    "vi": {
        "h_plan":"VẼ. PHÁT. CHIA SẺ.",
        "h_formation":"ĐỘI HÌNH, SẴN SÀNG",
        "h_built":"DÀNH CHO BÊN ĐƯỜNG BIÊN",
        "b_plan":"- Kéo cầu thủ vào sân chuẩn tỉ lệ, đầy màu\n- Mũi tên, đường, khu vực — màu sắc và độ dày tùy ý\n- Chạm Play, cầu thủ tự di chuyển từng bước\n- Lưu không giới hạn, xuất ảnh HD hoặc PDF",
        "b_built":"- Hoạt động offline — sân không Wi-Fi? Không sao.\n- Giao diện tối — dịu mắt khi tập tối\n- Hoàn tác/làm lại 50 bước — thử thoải mái\n- AirPlay lên TV — phòng thay đồ thành phòng tác chiến\n- Miễn phí, không quảng cáo, không mua trong app",
        "lang_line":"11 NGÔN NGỮ\nTiếng Việt · English · 简体中文 · 繁體中文 · 日本語 · 한국어 · Français · Español · ไทย · Bahasa Indonesia · Bahasa Melayu",
        "social":"Được HLV trẻ và CLB tại hơn 50 giải đấu tin dùng. Miễn phí mãi mãi, không cần đăng ký.",
        "cta":"Từ giải làng đến đội tuyển — dạy được là vẽ được.",
    },
    "th": {
        "h_plan":"วาด · เล่น · แชร์",
        "h_formation":"ฟอร์เมชั่น พร้อมใช้",
        "h_built":"สร้างมาเพื่อข้างสนาม",
        "b_plan":"· ลากนักกีฬาบนสนามมาตรฐานสีจริง\n· ลูกศร เส้น โซน ปรับสีและขนาดได้ตามใจ\n· แตะ Play นักกีฬาเคลื่อนทีละจังหวะ\n· บันทึกไม่จำกัด ส่งออกเป็นภาพ HD หรือ PDF",
        "b_built":"· ใช้งานออฟไลน์ — สนามไม่มี Wi-Fi? ไม่มีปัญหา\n· ธีมมืด — ฝึกตอนเย็นไม่แสบตา\n· เลิกทำ/ทำซ้ำ 50 ขั้น — ลองได้สบายใจ\n· AirPlay ออกทีวี — ห้องแต่งตัวกลายเป็นห้องสงคราม\n· ฟรี ไม่มีโฆษณา ไม่มีค่าใช้จ่ายในแอป",
        "lang_line":"รองรับ 11 ภาษา\nไทย · English · 简体中文 · 繁體中文 · 日本語 · 한국어 · Français · Español · Tiếng Việt · Bahasa Indonesia · Bahasa Melayu",
        "social":"โค้ชเยาวชนและสโมสรกว่า 50 ลีกใช้งาน ฟรีตลอด ไม่ต้องสมัคร",
        "cta":"ตั้งแต่ลีกข้างบ้านถึงทีมชาติ — สอนได้ ก็วาดได้",
    },
    "id": {
        "h_plan":"GAMBAR · MAINKAN · BAGIKAN",
        "h_formation":"FORMASI SIAP PAKAI",
        "h_built":"DIBUAT UNTUK PINGGIR LAPANGAN",
        "b_plan":"- Seret pemain ke lapangan akurat berwarna\n- Panah, garis, zona — warna dan gaya bebas atur\n- Ketuk Play, pemain bergerak per langkah\n- Simpan taktik tanpa batas, ekspor ke gambar HD atau PDF",
        "b_built":"- Bekerja offline — tidak ada Wi-Fi di lapangan? Tidak masalah.\n- Tema gelap — nyaman untuk latihan malam\n- Undo/redo hingga 50 langkah — coba sepuasnya\n- AirPlay ke TV — ruang ganti jadi ruang strategi\n- Gratis, tanpa iklan, tanpa pembelian dalam aplikasi",
        "lang_line":"11 BAHASA\nBahasa Indonesia · English · 简体中文 · 繁體中文 · 日本語 · 한국어 · Français · Español · Tiếng Việt · ไทย · Bahasa Melayu",
        "social":"Dipakai pelatih muda dan klub di 50+ liga. Gratis selamanya, tanpa akun.",
        "cta":"Dari liga RT sampai timnas — kalau bisa kau latih, bisa kau gambar.",
    },
    "ms": {
        "h_plan":"LUKIS · MAIN · KONGSI",
        "h_formation":"FORMASI SEDIA GUNA",
        "h_built":"DIBINA UNTUK TEPI PADANG",
        "b_plan":"- Seret pemain ke padang berwarna mengikut skala\n- Anak panah, garisan, zon — warna dan gaya bebas\n- Ketik Play, pemain bergerak langkah demi langkah\n- Simpan taktik tanpa had, eksport ke gambar HD atau PDF",
        "b_built":"- Berfungsi luar talian — padang tiada Wi-Fi? Tiada masalah.\n- Tema gelap — selesa untuk latihan malam\n- Buat asal/buat semula 50 langkah — cuba dengan yakin\n- AirPlay ke TV — bilik persalinan jadi bilik strategi\n- Percuma, tiada iklan, tiada pembelian dalam aplikasi",
        "lang_line":"11 BAHASA\nBahasa Melayu · English · 简体中文 · 繁體中文 · 日本語 · 한국어 · Français · Español · Tiếng Việt · ไทย · Bahasa Indonesia",
        "social":"Digunakan jurulatih dan kelab di 50+ liga. Percuma selama-lamanya, tanpa akaun.",
        "cta":"Dari liga kampung ke pasukan kebangsaan — jika boleh dilatih, boleh dilukis.",
    },
}

# ════════════════════════════════════════════════════════════════════
# Render
# ════════════════════════════════════════════════════════════════════
LOCALES = list(LOCALE.keys())
def render(sport, loc):
    s = SPORTS[sport]
    L = LOCALE[loc]
    name = s["name"][loc]
    hook = s["hook"][loc]
    elevator = s["elevator"][loc]
    formations = s["list"][loc]

    parts = [hook, "", f"{name} — {elevator}", "",
             L["h_plan"], "", L["b_plan"], "",
             L["h_formation"], "", formations, "",
             L["h_built"], "", L["b_built"], "",
             L["lang_line"], "",
             L["social"], "", L["cta"]]
    return "\n".join(parts)

written = 0
over = []
for sport in SPORTS:
    for loc in LOCALES:
        text = render(sport, loc)
        if len(text) > 4000:
            over.append((sport, loc, len(text)))
            continue
        path = f"{BASE}/{sport}/{loc}/description.txt"
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        written += 1

print(f"✅ wrote {written} description files")
if over:
    print(f"⚠ {len(over)} over 4000 chars:")
    for s,l,n in over: print(f"  {s}/{l}: {n}")
