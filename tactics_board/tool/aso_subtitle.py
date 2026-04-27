#!/usr/bin/env python3
"""Batch C: subtitle for 16 apps × 11 locales = 176 files.
30-char hard limit. Benefit-led, sport-flavored where space allows."""
import os
BASE = "/Users/zhenyusong/Desktop/projects/board100/tactics_board/fastlane/metadata"

# Per-locale benefit-led subtitle. {S} = sport noun (short form).
# Two variants per locale: SHORT (when sport name fits) vs FALLBACK (universal).
SUB = {
    "en-US":   {"with": "{S} plays, animated. Free.",   "fallback": "Animate any tactic. Free."},
    "zh-Hans": {"with": "{S}战术变动画·免费离线",        "fallback": "战术变动画·免费离线·零广告"},
    "zh-Hant": {"with": "{S}戰術變動畫·免費離線",        "fallback": "戰術變動畫·免費離線·零廣告"},
    "ja":      {"with": "{S}戦術を動画化・無料・広告0", "fallback": "戦術を動画化・無料・広告ゼロ"},
    "ko":      {"with": "{S} 전술 애니·무료·광고 0",   "fallback": "전술을 애니로·무료·광고 0"},
    "fr-FR":   {"with": "Tactiques {S} animées. Free.", "fallback": "Animez vos tactiques. Free."},
    "es-ES":   {"with": "Jugadas de {S} animadas.",     "fallback": "Anima jugadas. Sin anuncios."},
    "vi":      {"with": "Chiến thuật {S} thành phim.",  "fallback": "Biến chiến thuật thành phim."},
    "th":      {"with": "แผน{S} แอนิเมชัน ฟรี",         "fallback": "ทำแผนเป็นแอนิเมชัน ฟรี"},
    "id":      {"with": "Taktik {S}, dianimasikan.",    "fallback": "Animasikan taktik. Gratis."},
    "ms":      {"with": "Taktik {S}, dianimasikan.",    "fallback": "Animasikan taktik. Percuma."},
}

# Short sport noun for subtitle insertion (must be punchy)
SPORT = {
    "tactics_board": {"en-US":"sport","zh-Hans":"战术","zh-Hant":"戰術","ja":"全競技",
                      "ko":"전 종목","fr-FR":"sport","es-ES":"deporte",
                      "vi":"đa môn","th":"ทุกกีฬา","id":"olahraga","ms":"sukan"},
    "soccer":     {"en-US":"Soccer","zh-Hans":"足球","zh-Hant":"足球","ja":"サッカー",
                   "ko":"축구","fr-FR":"foot","es-ES":"fútbol",
                   "vi":"bóng đá","th":"ฟุตบอล","id":"sepak bola","ms":"bola sepak"},
    "basketball": {"en-US":"Hoops","zh-Hans":"篮球","zh-Hant":"籃球","ja":"バスケ",
                   "ko":"농구","fr-FR":"basket","es-ES":"básquet",
                   "vi":"bóng rổ","th":"บาส","id":"basket","ms":"bola keranjang"},
    "volleyball": {"en-US":"Volley","zh-Hans":"排球","zh-Hant":"排球","ja":"バレー",
                   "ko":"배구","fr-FR":"volley","es-ES":"vóley",
                   "vi":"bóng chuyền","th":"วอลเลย์","id":"voli","ms":"bola tampar"},
    "tennis":     {"en-US":"Tennis","zh-Hans":"网球","zh-Hant":"網球","ja":"テニス",
                   "ko":"테니스","fr-FR":"tennis","es-ES":"tenis",
                   "vi":"tennis","th":"เทนนิส","id":"tenis","ms":"tenis"},
    "badminton":  {"en-US":"Bad","zh-Hans":"羽球","zh-Hant":"羽球","ja":"バド",
                   "ko":"배드","fr-FR":"bad","es-ES":"bádminton",
                   "vi":"cầu lông","th":"แบด","id":"badminton","ms":"badminton"},
    "tableTennis":{"en-US":"TT","zh-Hans":"乒乓","zh-Hant":"桌球","ja":"卓球",
                   "ko":"탁구","fr-FR":"ping","es-ES":"tenis mesa",
                   "vi":"bóng bàn","th":"ปิงปอง","id":"tenis meja","ms":"ping pong"},
    "pickleball": {"en-US":"Pickle","zh-Hans":"匹克球","zh-Hant":"匹克球","ja":"ピックル",
                   "ko":"피클볼","fr-FR":"pickle","es-ES":"pickleball",
                   "vi":"pickle","th":"พิคเคิล","id":"pickleball","ms":"pickleball"},
    "fieldHockey":{"en-US":"Hockey","zh-Hans":"曲棍","zh-Hant":"曲棍","ja":"ホッケー",
                   "ko":"하키","fr-FR":"hockey","es-ES":"hockey",
                   "vi":"khúc côn cầu","th":"ฮอกกี้","id":"hoki","ms":"hoki"},
    "rugby":      {"en-US":"Rugby","zh-Hans":"橄榄球","zh-Hant":"橄欖球","ja":"ラグビー",
                   "ko":"럭비","fr-FR":"rugby","es-ES":"rugby",
                   "vi":"bầu dục","th":"รักบี้","id":"rugby","ms":"ragbi"},
    "baseball":   {"en-US":"Baseball","zh-Hans":"棒球","zh-Hant":"棒球","ja":"野球",
                   "ko":"야구","fr-FR":"baseball","es-ES":"béisbol",
                   "vi":"bóng chày","th":"เบสบอล","id":"bisbol","ms":"besbol"},
    "handball":   {"en-US":"Handball","zh-Hans":"手球","zh-Hant":"手球","ja":"ハンド",
                   "ko":"핸드볼","fr-FR":"hand","es-ES":"balonmano",
                   "vi":"bóng ném","th":"แฮนด์","id":"bola tangan","ms":"bola baling"},
    "waterPolo":  {"en-US":"Polo","zh-Hans":"水球","zh-Hant":"水球","ja":"水球",
                   "ko":"수구","fr-FR":"polo","es-ES":"waterpolo",
                   "vi":"bóng nước","th":"โปโลน้ำ","id":"polo air","ms":"polo air"},
    "sepakTakraw":{"en-US":"Takraw","zh-Hans":"藤球","zh-Hant":"藤球","ja":"セパタ",
                   "ko":"세팍","fr-FR":"takraw","es-ES":"takraw",
                   "vi":"cầu mây","th":"ตะกร้อ","id":"takraw","ms":"takraw"},
    "beachTennis":{"en-US":"Beach","zh-Hans":"沙滩网球","zh-Hant":"沙灘網球","ja":"ビーチ",
                   "ko":"비치","fr-FR":"beach","es-ES":"playa",
                   "vi":"bãi biển","th":"บีช","id":"pantai","ms":"pantai"},
    "footvolley": {"en-US":"Footvolley","zh-Hans":"足排","zh-Hant":"足排","ja":"フットボレ",
                   "ko":"풋발리","fr-FR":"footvolley","es-ES":"futvóley",
                   "vi":"footvolley","th":"ฟุตวอลเลย์","id":"footvolley","ms":"footvolley"},
}

LOCALES = list(SUB.keys())
SPORTS = list(SPORT.keys())

def pick(sport, loc):
    """Return subtitle: try `with` template; if >30 OR umbrella app, fall back."""
    if sport == "tactics_board":
        return SUB[loc]["fallback"]
    s = SPORT[sport][loc]
    cand = SUB[loc]["with"].format(S=s)
    if len(cand) <= 30:
        return cand
    return SUB[loc]["fallback"]

written = 0
overflow = []
for sport in SPORTS:
    for loc in LOCALES:
        text = pick(sport, loc)
        if len(text) > 30:
            overflow.append((sport, loc, len(text), text))
            continue
        path = f"{BASE}/{sport}/{loc}/subtitle.txt"
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        written += 1

print(f"✅ wrote {written} subtitle files")
if overflow:
    print(f"⚠ {len(overflow)} overflowed:")
    for o in overflow: print(f"  {o}")
