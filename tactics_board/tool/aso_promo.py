#!/usr/bin/env python3
"""Generate promotional_text for 16 apps × 11 locales = 176 files.
Post-approval editable (no review re-trigger). ≤170 chars each, locale-tone-tuned.

Pattern: [Urgency/Newness] + [Quantified Benefit] + [Permission to act]
Sport name is interpolated as {S} per locale.

Usage: python3 tool/aso_promo.py
"""
import os
BASE = "/Users/zhenyusong/Desktop/projects/board100/tactics_board/fastlane/metadata"

PROMO = {
    "en-US": "NEW Timeline Editor: animate multi-phase {S} plays step by step. Free, offline, no ads. Built for coaches who think in pictures.",
    "zh-Hans": "全新时间线编辑器：把多阶段{S}战术做成动画，一步一停。免费、离线、零广告。给「画面型」教练。",
    "zh-Hant": "全新時間線編輯器：多階段{S}戰術一步一停動畫播放。免費、離線、零廣告。為「畫面型」教練而生。",
    "ja": "新タイムラインエディタ：多段階{S}戦術を一歩ずつアニメ化。無料・オフライン・広告ゼロ。映像で考えるコーチへ。",
    "ko": "새 타임라인 에디터: 다단계 {S} 전술을 단계별 애니메이션으로. 무료·오프라인·광고 제로. 그림으로 생각하는 감독을 위해.",
    "fr-FR": "NOUVEAU : Éditeur Timeline. Animez les phases de {S} étape par étape. Gratuit, hors-ligne, sans pub. Pensé pour les coachs visuels.",
    "es-ES": "NUEVO Editor Timeline: anima jugadas de {S} fase a fase. Gratis, sin conexión, sin anuncios. Para entrenadores que piensan en imágenes.",
    "vi": "MỚI Trình Timeline: vẽ pha {S} nhiều giai đoạn, phát từng bước. Miễn phí, offline, không quảng cáo. Cho HLV tư duy bằng hình.",
    "th": "ใหม่! Timeline Editor วาดแผน {S} หลายเฟสและเล่นทีละจังหวะ ฟรี ออฟไลน์ ไม่มีโฆษณา สำหรับโค้ชที่คิดเป็นภาพ",
    "id": "BARU Timeline Editor: animasikan taktik {S} per fase. Gratis, offline, tanpa iklan. Untuk pelatih yang berpikir lewat gambar.",
    "ms": "BARU Timeline Editor: animasikan taktik {S} fasa demi fasa. Percuma, luar talian, tanpa iklan. Untuk jurulatih berfikir dengan gambar.",
}

SPORT_NAME = {
    "tactics_board": {"en-US":"any-sport","zh-Hans":"全运动","zh-Hant":"全運動","ja":"全競技","ko":"전 종목","fr-FR":"tous-sports","es-ES":"multi-deporte","vi":"đa môn","th":"ทุกกีฬา","id":"multi-cabor","ms":"pelbagai sukan"},
    "soccer":       {"en-US":"soccer","zh-Hans":"足球","zh-Hant":"足球","ja":"サッカー","ko":"축구","fr-FR":"football","es-ES":"fútbol","vi":"bóng đá","th":"ฟุตบอล","id":"sepak bola","ms":"bola sepak"},
    "basketball":   {"en-US":"basketball","zh-Hans":"篮球","zh-Hant":"籃球","ja":"バスケ","ko":"농구","fr-FR":"basket","es-ES":"baloncesto","vi":"bóng rổ","th":"บาสเกตบอล","id":"basket","ms":"bola keranjang"},
    "volleyball":   {"en-US":"volleyball","zh-Hans":"排球","zh-Hant":"排球","ja":"バレー","ko":"배구","fr-FR":"volley","es-ES":"voleibol","vi":"bóng chuyền","th":"วอลเลย์บอล","id":"voli","ms":"bola tampar"},
    "tennis":       {"en-US":"tennis","zh-Hans":"网球","zh-Hant":"網球","ja":"テニス","ko":"테니스","fr-FR":"tennis","es-ES":"tenis","vi":"quần vợt","th":"เทนนิส","id":"tenis","ms":"tenis"},
    "badminton":    {"en-US":"badminton","zh-Hans":"羽毛球","zh-Hant":"羽球","ja":"バドミントン","ko":"배드민턴","fr-FR":"badminton","es-ES":"bádminton","vi":"cầu lông","th":"แบดมินตัน","id":"bulu tangkis","ms":"badminton"},
    "tableTennis":  {"en-US":"table tennis","zh-Hans":"乒乓球","zh-Hant":"桌球","ja":"卓球","ko":"탁구","fr-FR":"tennis de table","es-ES":"tenis de mesa","vi":"bóng bàn","th":"ปิงปอง","id":"tenis meja","ms":"ping pong"},
    "pickleball":   {"en-US":"pickleball","zh-Hans":"匹克球","zh-Hant":"匹克球","ja":"ピックルボール","ko":"피클볼","fr-FR":"pickleball","es-ES":"pickleball","vi":"pickleball","th":"พิคเคิลบอล","id":"pickleball","ms":"pickleball"},
    "fieldHockey":  {"en-US":"field hockey","zh-Hans":"曲棍球","zh-Hant":"曲棍球","ja":"ホッケー","ko":"필드하키","fr-FR":"hockey sur gazon","es-ES":"hockey hierba","vi":"khúc côn cầu","th":"ฮอกกี้สนาม","id":"hoki lapangan","ms":"hoki padang"},
    "rugby":        {"en-US":"rugby","zh-Hans":"橄榄球","zh-Hant":"橄欖球","ja":"ラグビー","ko":"럭비","fr-FR":"rugby","es-ES":"rugby","vi":"bóng bầu dục","th":"รักบี้","id":"rugby","ms":"ragbi"},
    "baseball":     {"en-US":"baseball","zh-Hans":"棒球","zh-Hant":"棒球","ja":"野球","ko":"야구","fr-FR":"baseball","es-ES":"béisbol","vi":"bóng chày","th":"เบสบอล","id":"bisbol","ms":"besbol"},
    "handball":     {"en-US":"handball","zh-Hans":"手球","zh-Hant":"手球","ja":"ハンドボール","ko":"핸드볼","fr-FR":"handball","es-ES":"balonmano","vi":"bóng ném","th":"แฮนด์บอล","id":"bola tangan","ms":"bola baling"},
    "waterPolo":    {"en-US":"water polo","zh-Hans":"水球","zh-Hant":"水球","ja":"水球","ko":"수구","fr-FR":"water-polo","es-ES":"waterpolo","vi":"bóng nước","th":"โปโลน้ำ","id":"polo air","ms":"polo air"},
    "sepakTakraw":  {"en-US":"sepak takraw","zh-Hans":"藤球","zh-Hant":"藤球","ja":"セパタクロー","ko":"세팍타크로","fr-FR":"sepak takraw","es-ES":"sepak takraw","vi":"cầu mây","th":"ตะกร้อ","id":"sepak takraw","ms":"sepak takraw"},
    "beachTennis":  {"en-US":"beach tennis","zh-Hans":"沙滩网球","zh-Hant":"沙灘網球","ja":"ビーチテニス","ko":"비치테니스","fr-FR":"beach tennis","es-ES":"tenis playa","vi":"tennis bãi biển","th":"บีชเทนนิส","id":"tenis pantai","ms":"tenis pantai"},
    "footvolley":   {"en-US":"footvolley","zh-Hans":"足排球","zh-Hant":"足排球","ja":"フットボレー","ko":"풋발리","fr-FR":"footvolley","es-ES":"futvóley","vi":"footvolley","th":"ฟุตวอลเลย์","id":"footvolley","ms":"footvolley"},
}

LOCALES = list(PROMO.keys())
SPORTS = list(SPORT_NAME.keys())

written = 0
skipped = 0
for sport in SPORTS:
    for loc in LOCALES:
        text = PROMO[loc].format(S=SPORT_NAME[sport][loc])
        if len(text) > 170:
            print(f"  ⚠ TOO LONG ({len(text)}) {sport}/{loc}: {text}")
            skipped += 1
            continue
        path = f"{BASE}/{sport}/{loc}/promotional_text.txt"
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        written += 1

print(f"\n✅ wrote {written} promotional_text files; skipped {skipped}")
