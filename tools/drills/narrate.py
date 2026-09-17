"""The sequence section of a drill's note, derived from the board itself.

The notes were one hand-written coaching sentence, and the user's finding was
that they were too thin to run a session from — and, worse, nothing tied them
to the board: a note could describe a drill the phases no longer performed.
So the note becomes three parts:

    【组织】 setup   — hand-written when the author gives one, else a census
                      of what is on the board (players, equipment, the ball)
    【流程】 sequence — DERIVED from the same phase data that animates the
                      board, beat by beat, so text and animation cannot
                      disagree; edit the board and the words follow
    【要点】 point    — the hand-written coaching sentence, kept verbatim

Verbs the narration knows, best first:
  - a pass: a ball_to leg whose target is a player reference
  - a ball played to a spot: a ball_to leg with a point target
  - a carry: ball_follow (narrated once, with the carrier)
  - a follow: a run that ends near where the ball stopped the beat before —
    pass-and-follow detected from geometry, not annotation
  - a run: any other movement, named by its dominant direction

Twelve locales, the same set the drills ship. Adding a verb means adding
twelve strings here — the price of text that is never machine-translated.
"""
from __future__ import annotations

from .intents import RESET, RUN_WHY, why_text

LOCALES = ["en", "en-GB", "zh-CN", "zh-TW", "ja-JP", "ko-KR", "es-ES",
           "fr-FR", "id-ID", "ms-MY", "th-TH", "vi-VN"]

# ── section labels ──────────────────────────────────────────────────────────
SECTION = {
    "purpose": {
        "en": "Purpose: ", "en-GB": "Purpose: ",
        "zh-CN": "【目的】", "zh-TW": "【目的】",
        "ja-JP": "【目的】", "ko-KR": "【목적】",
        "es-ES": "Objetivo: ", "fr-FR": "Objectif : ",
        "id-ID": "Tujuan: ", "ms-MY": "Tujuan: ",
        "th-TH": "จุดประสงค์: ", "vi-VN": "Mục đích: ",
    },
    "freq": {
        "en": "Frequency: ", "en-GB": "Frequency: ",
        "zh-CN": "【频度】", "zh-TW": "【頻度】",
        "ja-JP": "【頻度】", "ko-KR": "【빈도】",
        "es-ES": "Frecuencia: ", "fr-FR": "Fréquence : ",
        "id-ID": "Frekuensi: ", "ms-MY": "Kekerapan: ",
        "th-TH": "ความถี่: ", "vi-VN": "Tần suất: ",
    },
    "origin": {
        "en": "Origin: ", "en-GB": "Origin: ",
        "zh-CN": "【来历】", "zh-TW": "【來歷】",
        "ja-JP": "【由来】", "ko-KR": "【유래】",
        "es-ES": "Origen: ", "fr-FR": "Origine : ",
        "id-ID": "Asal: ", "ms-MY": "Asal: ",
        "th-TH": "ที่มา: ", "vi-VN": "Nguồn gốc: ",
    },
    "setup": {
        "en": "Setup: ", "en-GB": "Setup: ",
        "zh-CN": "【组织】", "zh-TW": "【組織】",
        "ja-JP": "【準備】", "ko-KR": "【준비】",
        "es-ES": "Montaje: ", "fr-FR": "Mise en place : ",
        "id-ID": "Persiapan: ", "ms-MY": "Persediaan: ",
        "th-TH": "การจัด: ", "vi-VN": "Bố trí: ",
    },
    "seq": {
        "en": "Sequence: ", "en-GB": "Sequence: ",
        "zh-CN": "【流程】", "zh-TW": "【流程】",
        "ja-JP": "【流れ】", "ko-KR": "【진행】",
        "es-ES": "Secuencia: ", "fr-FR": "Déroulé : ",
        "id-ID": "Urutan: ", "ms-MY": "Urutan: ",
        "th-TH": "ลำดับ: ", "vi-VN": "Trình tự: ",
    },
    "route": {
        "en": "Ball path: ", "en-GB": "Ball path: ",
        "zh-CN": "【球路】", "zh-TW": "【球路】",
        "ja-JP": "【ボールの道筋】", "ko-KR": "【볼 경로】",
        "es-ES": "Recorrido del balón: ", "fr-FR": "Trajet du ballon : ",
        "id-ID": "Jalur bola: ", "ms-MY": "Laluan bola: ",
        "th-TH": "เส้นทางบอล: ", "vi-VN": "Đường bóng: ",
    },
    "rules": {
        "en": "Rules: ", "en-GB": "Rules: ",
        "zh-CN": "【规则】", "zh-TW": "【規則】",
        "ja-JP": "【ルール】", "ko-KR": "【규칙】",
        "es-ES": "Reglas: ", "fr-FR": "Règles : ",
        "id-ID": "Aturan: ", "ms-MY": "Peraturan: ",
        "th-TH": "กติกา: ", "vi-VN": "Luật: ",
    },
    "point": {
        "en": "Coaching point: ", "en-GB": "Coaching point: ",
        "zh-CN": "【要点】", "zh-TW": "【要點】",
        "ja-JP": "【ポイント】", "ko-KR": "【포인트】",
        "es-ES": "Punto clave: ", "fr-FR": "Point clé : ",
        "id-ID": "Poin utama: ", "ms-MY": "Poin utama: ",
        "th-TH": "จุดเน้น: ", "vi-VN": "Điểm chính: ",
    },
}

# ── beats ───────────────────────────────────────────────────────────────────
# Named the way the playback indicator counts ("0/4", stepped in 步), so a
# coach can hold the note against the stepper and follow beat for beat.
BEAT = {
    "en": "Step {n}: ", "en-GB": "Step {n}: ",
    "zh-CN": "第{n}步：", "zh-TW": "第{n}步：",
    "ja-JP": "ステップ{n}：", "ko-KR": "{n}단계: ",
    "es-ES": "Paso {n}: ", "fr-FR": "Étape {n} : ",
    "id-ID": "Langkah {n}: ", "ms-MY": "Langkah {n}: ",
    "th-TH": "ขั้นที่ {n}: ", "vi-VN": "Bước {n}: ",
}

# separators: inside a beat / between beats / end of section
AND = {
    "en": ", ", "en-GB": ", ", "zh-CN": "，", "zh-TW": "，",
    "ja-JP": "、", "ko-KR": ", ", "es-ES": ", ", "fr-FR": ", ",
    "id-ID": ", ", "ms-MY": ", ", "th-TH": " ", "vi-VN": ", ",
}
SEMI = {
    "en": "; ", "en-GB": "; ", "zh-CN": "；", "zh-TW": "；",
    "ja-JP": "。", "ko-KR": "; ", "es-ES": "; ", "fr-FR": " ; ",
    "id-ID": "; ", "ms-MY": "; ", "th-TH": " • ", "vi-VN": "; ",
}
DOT = {
    "en": ". ", "en-GB": ". ", "zh-CN": "。", "zh-TW": "。",
    "ja-JP": "。", "ko-KR": ". ", "es-ES": ". ", "fr-FR": ". ",
    "id-ID": ". ", "ms-MY": ". ", "th-TH": " ", "vi-VN": ". ",
}

# ── verbs ───────────────────────────────────────────────────────────────────
# {a}/{b} are shirt labels. The ball word varies per sport family (a puck-less
# library: everything here is a ball, a shuttle, or a stone-cold "ball").
PASS = {
    "en": "{a} passes to {b}", "en-GB": "{a} passes to {b}",
    "zh-CN": "{a}把球传给{b}", "zh-TW": "{a}把球傳給{b}",
    "ja-JP": "{a}が{b}へパス", "ko-KR": "{a}가 {b}에게 패스",
    "es-ES": "{a} pasa a {b}", "fr-FR": "{a} passe à {b}",
    "id-ID": "{a} mengoper ke {b}", "ms-MY": "{a} menghantar kepada {b}",
    "th-TH": "{a} จ่ายให้ {b}", "vi-VN": "{a} chuyền cho {b}",
}
# Net sports: the ball crosses to the other side, "hit" reads better than
# "pass" for a shuttle or a spiked ball.
HIT = {
    "en": "{a} plays it to {b}", "en-GB": "{a} plays it to {b}",
    "zh-CN": "{a}把球击向{b}", "zh-TW": "{a}把球擊向{b}",
    "ja-JP": "{a}が{b}へ打つ", "ko-KR": "{a}가 {b} 쪽으로 친다",
    "es-ES": "{a} la juega hacia {b}", "fr-FR": "{a} joue vers {b}",
    "id-ID": "{a} memukul ke {b}", "ms-MY": "{a} memukul ke arah {b}",
    "th-TH": "{a} ตีไปที่ {b}", "vi-VN": "{a} đánh sang {b}",
}
THROW = {
    "en": "{a} throws to {b}", "en-GB": "{a} throws to {b}",
    "zh-CN": "{a}传给{b}", "zh-TW": "{a}傳給{b}",
    "ja-JP": "{a}が{b}へ送球", "ko-KR": "{a}가 {b}에게 송구",
    "es-ES": "{a} lanza a {b}", "fr-FR": "{a} lance à {b}",
    "id-ID": "{a} melempar ke {b}", "ms-MY": "{a} membaling kepada {b}",
    "th-TH": "{a} ขว้างให้ {b}", "vi-VN": "{a} ném cho {b}",
}
PASS_SPOT = {
    "en": "{a} plays the ball on", "en-GB": "{a} plays the ball on",
    "zh-CN": "{a}把球传到下一个点", "zh-TW": "{a}把球傳到下一個點",
    "ja-JP": "{a}が次のポイントへ送る", "ko-KR": "{a}가 다음 지점으로 보낸다",
    "es-ES": "{a} envía el balón al siguiente punto",
    "fr-FR": "{a} envoie le ballon au point suivant",
    "id-ID": "{a} memainkan bola ke titik berikutnya",
    "ms-MY": "{a} memainkan bola ke titik seterusnya",
    "th-TH": "{a} ส่งบอลไปจุดถัดไป", "vi-VN": "{a} đưa bóng tới điểm kế tiếp",
}
CARRY = {
    "en": "{a} carries the ball on the move",
    "en-GB": "{a} carries the ball on the move",
    "zh-CN": "{a}带球推进", "zh-TW": "{a}帶球推進",
    "ja-JP": "{a}がボールを運ぶ", "ko-KR": "{a}가 공을 몰고 이동",
    "es-ES": "{a} conduce el balón", "fr-FR": "{a} conduit le ballon",
    "id-ID": "{a} menggiring bola", "ms-MY": "{a} membawa bola",
    "th-TH": "{a} พาบอลไป", "vi-VN": "{a} dẫn bóng di chuyển",
}
# A ball that starts loose (a served ball, an opponent's pass into the
# board): there is no holder to name, so the ball itself is the subject.
PASS_IN = {
    "en": "the ball is played to {b}", "en-GB": "the ball is played to {b}",
    "zh-CN": "球被传给{b}", "zh-TW": "球被傳給{b}",
    "ja-JP": "ボールが{b}へ入る", "ko-KR": "공이 {b}에게 온다",
    "es-ES": "el balón llega a {b}", "fr-FR": "le ballon arrive sur {b}",
    "id-ID": "bola dimainkan ke {b}", "ms-MY": "bola dimainkan kepada {b}",
    "th-TH": "บอลถูกส่งมาที่ {b}", "vi-VN": "bóng được đưa tới {b}",
}
GOAL_WORD = {
    "en": "goal", "en-GB": "goal", "zh-CN": "球门", "zh-TW": "球門",
    "ja-JP": "ゴール", "ko-KR": "골문", "es-ES": "portería", "fr-FR": "but",
    "id-ID": "gawang", "ms-MY": "gol", "th-TH": "ประตู", "vi-VN": "khung thành",
}
# What the far end of the board is called in each sport. "goal" is right for
# four of the fifteen; a basketball coach shoots at the basket, a rugby kicker
# at the posts, a pitcher throws to the plate, and in every net sport a ball
# played to the far baseline is simply played deep.
BASKET_WORD = {
    "en": "basket", "en-GB": "basket", "zh-CN": "篮筐", "zh-TW": "籃框",
    "ja-JP": "リング", "ko-KR": "림", "es-ES": "canasta", "fr-FR": "panier",
    "id-ID": "ring", "ms-MY": "jaring", "th-TH": "ห่วง", "vi-VN": "rổ",
}
POSTS_WORD = {
    "en": "the posts", "en-GB": "the posts", "zh-CN": "门柱", "zh-TW": "門柱",
    "ja-JP": "ポスト", "ko-KR": "골포스트", "es-ES": "los palos",
    "fr-FR": "les poteaux", "id-ID": "tiang gawang", "ms-MY": "tiang gol",
    "th-TH": "เสาประตู", "vi-VN": "cột gôn",
}
PLATE_WORD = {
    "en": "the plate", "en-GB": "the plate", "zh-CN": "本垒", "zh-TW": "本壘",
    "ja-JP": "ホームベース", "ko-KR": "홈플레이트", "es-ES": "el plato",
    "fr-FR": "le marbre", "id-ID": "home plate", "ms-MY": "home plate",
    "th-TH": "โฮมเพลต", "vi-VN": "gôn nhà",
}
DEEP_WORD = {
    "en": "deep court", "en-GB": "deep court", "zh-CN": "后场深区",
    "zh-TW": "後場深區", "ja-JP": "コート奥", "ko-KR": "코트 깊숙한 곳",
    "es-ES": "el fondo de la pista", "fr-FR": "le fond du court",
    "id-ID": "lapangan belakang", "ms-MY": "bahagian belakang gelanggang",
    "th-TH": "ท้ายคอร์ต", "vi-VN": "cuối sân",
}
BACK_TO_START = {
    "en": "back to the start", "en-GB": "back to the start",
    "zh-CN": "回到起点", "zh-TW": "回到起點",
    "ja-JP": "スタート位置へ戻る", "ko-KR": "시작 지점으로",
    "es-ES": "de vuelta al inicio", "fr-FR": "retour au départ",
    "id-ID": "kembali ke awal", "ms-MY": "kembali ke permulaan",
    "th-TH": "กลับจุดเริ่ม", "vi-VN": "về điểm xuất phát",
}
SPOT_WORD = {
    "en": "the open spot", "en-GB": "the open spot", "zh-CN": "空位",
    "zh-TW": "空位", "ja-JP": "スペース", "ko-KR": "빈 자리",
    "es-ES": "el espacio libre", "fr-FR": "l'espace libre",
    "id-ID": "titik kosong", "ms-MY": "ruang kosong",
    "th-TH": "จุดว่าง", "vi-VN": "vị trí trống",
}
# A shot at a goal — soccer/hockey/handball/water polo.
SHOOT = {
    "en": "{a} shoots", "en-GB": "{a} shoots",
    "zh-CN": "{a}射门", "zh-TW": "{a}射門",
    "ja-JP": "{a}がシュート", "ko-KR": "{a} 슛",
    "es-ES": "{a} remata", "fr-FR": "{a} frappe",
    "id-ID": "{a} menembak", "ms-MY": "{a} menjaring",
    "th-TH": "{a} ยิงประตู", "vi-VN": "{a} dứt điểm",
}
# Basketball puts up a shot at the basket, not a 射门 at a goal — the word a
# basketball coach uses is different in most languages.
SHOOT_HOOP = {
    "en": "{a} puts up the shot", "en-GB": "{a} puts up the shot",
    "zh-CN": "{a}投篮", "zh-TW": "{a}投籃",
    "ja-JP": "{a}がシュートを放つ", "ko-KR": "{a} 슛을 던진다",
    "es-ES": "{a} lanza a canasta", "fr-FR": "{a} tire au panier",
    "id-ID": "{a} melepaskan tembakan", "ms-MY": "{a} melepaskan jaringan",
    "th-TH": "{a} ยิงเข้าห่วง", "vi-VN": "{a} ném rổ",
}
KICK_POSTS = {
    "en": "{a} kicks at the posts", "en-GB": "{a} kicks at the posts",
    "zh-CN": "{a}踢门", "zh-TW": "{a}踢門",
    "ja-JP": "{a}がゴールキック", "ko-KR": "{a} 골킥",
    "es-ES": "{a} patea a los palos", "fr-FR": "{a} tente les poteaux",
    "id-ID": "{a} menendang ke tiang", "ms-MY": "{a} menendang ke tiang gol",
    "th-TH": "{a} เตะเข้าเสา", "vi-VN": "{a} đá vào cột gôn",
}
PITCH = {
    "en": "{a} pitches", "en-GB": "{a} pitches",
    "zh-CN": "{a}投球", "zh-TW": "{a}投球",
    "ja-JP": "{a}が投球", "ko-KR": "{a} 투구",
    "es-ES": "{a} lanza", "fr-FR": "{a} lance",
    "id-ID": "{a} melempar", "ms-MY": "{a} membaling",
    "th-TH": "{a} ขว้าง", "vi-VN": "{a} ném bóng",
}
# Net sports: a ball played to a point is hit there, deep or to a spot.
HIT_DEEP = {
    "en": "{a} plays it deep", "en-GB": "{a} plays it deep",
    "zh-CN": "{a}把球打到后场深区", "zh-TW": "{a}把球打到後場深區",
    "ja-JP": "{a}がコート奥へ打つ", "ko-KR": "{a}가 깊게 친다",
    "es-ES": "{a} la juega al fondo", "fr-FR": "{a} joue long",
    "id-ID": "{a} memukul ke belakang", "ms-MY": "{a} memukul ke belakang",
    "th-TH": "{a} ตีลึก", "vi-VN": "{a} đánh sâu",
}
HIT_SPOT = {
    "en": "{a} plays it to the spot", "en-GB": "{a} plays it to the spot",
    "zh-CN": "{a}把球打到落点", "zh-TW": "{a}把球打到落點",
    "ja-JP": "{a}が狙った位置へ打つ", "ko-KR": "{a}가 목표 지점으로 친다",
    "es-ES": "{a} la coloca en el punto", "fr-FR": "{a} la place sur la zone",
    "id-ID": "{a} memukul ke titik sasaran", "ms-MY": "{a} memukul ke titik sasaran",
    "th-TH": "{a} ตีไปที่จุดเป้า", "vi-VN": "{a} đánh vào điểm rơi",
}
# In a net sport nobody carries the ball; a leg that stays with the holder
# is the player getting under it — the toss, the approach, the set-up step.
HIT_MOVE = {
    "en": "{a} moves into position to hit",
    "en-GB": "{a} moves into position to hit",
    "zh-CN": "{a}移动到击球位置", "zh-TW": "{a}移動到擊球位置",
    "ja-JP": "{a}が打点に入る", "ko-KR": "{a}가 타점으로 들어간다",
    "es-ES": "{a} se coloca para golpear", "fr-FR": "{a} se place pour frapper",
    "id-ID": "{a} mengambil posisi memukul", "ms-MY": "{a} mengambil posisi memukul",
    "th-TH": "{a} เข้าตำแหน่งตี", "vi-VN": "{a} vào vị trí đánh bóng",
}
# A loose ball fed from the player's own side of the net (a coach's toss,
# a partner's throw) has not crossed anything.
FEED = {
    "en": "{b} takes the feed", "en-GB": "{b} takes the feed",
    "zh-CN": "{b}接喂球", "zh-TW": "{b}接餵球",
    "ja-JP": "{b}が球出しを受ける", "ko-KR": "{b}가 토스를 받는다",
    "es-ES": "{b} recibe el envío", "fr-FR": "{b} reçoit l'envoi",
    "id-ID": "{b} menerima umpan latihan", "ms-MY": "{b} menerima suapan",
    "th-TH": "{b} รับลูกป้อน", "vi-VN": "{b} nhận bóng mớm",
}
# A loose ball in a net sport is on its way over the net, not "passed".
PASS_IN_NET = {
    "en": "the ball comes over to {b}", "en-GB": "the ball comes over to {b}",
    "zh-CN": "球过网来到{b}这边", "zh-TW": "球過網來到{b}這邊",
    "ja-JP": "ボールが{b}側へ来る", "ko-KR": "공이 {b} 쪽으로 넘어온다",
    "es-ES": "la bola pasa al lado de {b}", "fr-FR": "la balle arrive côté {b}",
    "id-ID": "bola menyeberang ke {b}", "ms-MY": "bola menyeberang ke {b}",
    "th-TH": "ลูกข้ามมาฝั่ง {b}", "vi-VN": "bóng sang phần sân {b}",
}
# The ball going to the OTHER side in an invasion sport is never a pass: it
# is a shot the keeper deals with, a kick downfield, a feed into the
# attacker, or a turnover. The text claims only what the board shows.
SHOT_AT_KEEPER = {
    "en": "{a} shoots, {b} saves", "en-GB": "{a} shoots, {b} saves",
    "zh-CN": "{a}射门，{b}扑救", "zh-TW": "{a}射門，{b}撲救",
    "ja-JP": "{a}がシュート、{b}がセーブ", "ko-KR": "{a} 슛, {b} 선방",
    "es-ES": "{a} remata, {b} para", "fr-FR": "{a} frappe, {b} arrête",
    "id-ID": "{a} menembak, {b} menyelamatkan",
    "ms-MY": "{a} menembak, {b} menyelamat",
    "th-TH": "{a} ยิง {b} เซฟ", "vi-VN": "{a} sút, {b} cản phá",
}
KEEPER_OUT = {
    "en": "{a} distributes to {b}", "en-GB": "{a} distributes to {b}",
    "zh-CN": "{a}把球分给{b}", "zh-TW": "{a}把球分給{b}",
    "ja-JP": "{a}が{b}へ配球", "ko-KR": "{a}가 {b}에게 배급",
    "es-ES": "{a} saca para {b}", "fr-FR": "{a} relance sur {b}",
    "id-ID": "{a} mendistribusikan ke {b}", "ms-MY": "{a} mengagihkan kepada {b}",
    "th-TH": "{a} จ่ายออกให้ {b}", "vi-VN": "{a} phát bóng cho {b}",
}
KICK_TO = {
    "en": "{a} kicks to {b}", "en-GB": "{a} kicks to {b}",
    "zh-CN": "{a}踢给{b}", "zh-TW": "{a}踢給{b}",
    "ja-JP": "{a}が{b}へキック", "ko-KR": "{a}가 {b}에게 킥",
    "es-ES": "{a} patea hacia {b}", "fr-FR": "{a} tape vers {b}",
    "id-ID": "{a} menendang ke {b}", "ms-MY": "{a} menendang ke {b}",
    "th-TH": "{a} เตะไปหา {b}", "vi-VN": "{a} đá về phía {b}",
}
# A leg from one side to the other is a turnover: nobody passes to an
# opponent. "The ball goes from 11 to 3" read as exactly that — 11 giving
# it away on purpose — so it says who won it.
CHANGES_HANDS = {
    "en": "{b} wins the ball off {a}",
    "en-GB": "{b} wins the ball off {a}",
    "zh-CN": "{b}断下{a}的球", "zh-TW": "{b}斷下{a}的球",
    "ja-JP": "{b}が{a}からボールを奪う", "ko-KR": "{b}가 {a}에게서 공을 빼앗는다",
    "es-ES": "{b} le roba el balón a {a}", "fr-FR": "{b} récupère le ballon sur {a}",
    "id-ID": "{b} merebut bola dari {a}",
    "ms-MY": "{b} merampas bola daripada {a}",
    "th-TH": "{b} แย่งบอลจาก {a}", "vi-VN": "{b} đoạt bóng từ {a}",
}
# Several players wearing the same letter doing the same thing: "3 Ds move
# back", not "D, D, D moves back".
COUNTED = {
    "en": "{n} {a}s", "en-GB": "{n} {a}s", "zh-CN": "{n} 名 {a}",
    "zh-TW": "{n} 名 {a}", "ja-JP": "{a}{n}人", "ko-KR": "{a} {n}명",
    "es-ES": "{n} {a}", "fr-FR": "{n} {a}", "id-ID": "{n} {a}",
    "ms-MY": "{n} {a}", "th-TH": "{a} {n} คน", "vi-VN": "{n} {a}",
}
# The whole side moving the same way is one idea, not ten subjects.
ALL_MOVE = {
    "en": "the whole team moves {dir}", "en-GB": "the whole team moves {dir}",
    "zh-CN": "全队整体{dir}移动", "zh-TW": "全隊整體{dir}移動",
    "ja-JP": "チーム全体が{dir}へスライド", "ko-KR": "팀 전체가 {dir} 이동",
    "es-ES": "todo el equipo bascula {dir}", "fr-FR": "tout le bloc coulisse {dir}",
    "id-ID": "seluruh tim bergerak {dir}", "ms-MY": "seluruh pasukan bergerak {dir}",
    "th-TH": "ทั้งทีมขยับ{dir}", "vi-VN": "cả đội di chuyển {dir}",
}

# With a known destination (the spot the receiver vacates) the follow reads
# "2号球员跑位到3号球员的位置". Without one it falls back to FOLLOW_PLAIN.
# The passer follows his own pass and joins the queue BEHIND the receiver —
# on the board he stops short of the cone, because the receiver has not moved
# on yet. So the text says "behind {to}", matching where the token actually
# ends up; "takes {to}'s position" claimed an arrival the drawing does not
# show, and a coach noticed the gap.
FOLLOW = {
    "en": "{a} follows up behind {to}",
    "en-GB": "{a} follows up behind {to}",
    "zh-CN": "{a}跟上去，跑到{to}身后",
    "zh-TW": "{a}跟上去，跑到{to}身後",
    "ja-JP": "{a}が{to}の後ろへ入る",
    "ko-KR": "{a}가 {to} 뒤로 따라 들어간다",
    "es-ES": "{a} sube por detrás de {to}",
    "fr-FR": "{a} monte derrière {to}",
    "id-ID": "{a} maju di belakang {to}",
    "ms-MY": "{a} naik di belakang {to}",
    "th-TH": "{a} ตามขึ้นไปด้านหลัง{to}",
    "vi-VN": "{a} theo lên phía sau {to}",
}
FOLLOW_PLAIN = {
    "en": "{a} runs up in support", "en-GB": "{a} runs up in support",
    "zh-CN": "{a}跑上去接应", "zh-TW": "{a}跑上去接應",
    "ja-JP": "{a}がサポートに上がる", "ko-KR": "{a}가 지원하러 올라간다",
    "es-ES": "{a} sube en apoyo", "fr-FR": "{a} monte en soutien",
    "id-ID": "{a} maju mendukung", "ms-MY": "{a} naik menyokong",
    "th-TH": "{a} ขึ้นไปสนับสนุน", "vi-VN": "{a} dâng lên hỗ trợ",
}
RUN = {
    "en": "{a} moves {dir}", "en-GB": "{a} moves {dir}",
    "zh-CN": "{a}{dir}移动", "zh-TW": "{a}{dir}移動",
    "ja-JP": "{a}が{dir}へ移動", "ko-KR": "{a}는 {dir} 이동",
    "es-ES": "{a} se desplaza {dir}", "fr-FR": "{a} se déplace {dir}",
    "id-ID": "{a} bergerak {dir}", "ms-MY": "{a} bergerak {dir}",
    "th-TH": "{a} ขยับ{dir}", "vi-VN": "{a} di chuyển {dir}",
}
# Directions in board space: -y is toward the top of the phone. Whether that
# is "forward" depends on which half the player is in, which is more theory
# than a warm-up needs — up/down/left/right in pitch terms is unambiguous.
DIR = {
    "up": {"en": "up the board", "en-GB": "up the board", "zh-CN": "向前",
           "zh-TW": "向前", "ja-JP": "前方", "ko-KR": "앞으로",
           "es-ES": "hacia delante", "fr-FR": "vers l'avant",
           "id-ID": "ke depan", "ms-MY": "ke hadapan", "th-TH": "ไปข้างหน้า",
           "vi-VN": "lên phía trước"},
    "down": {"en": "back", "en-GB": "back", "zh-CN": "向后", "zh-TW": "向後",
             "ja-JP": "後方", "ko-KR": "뒤로", "es-ES": "hacia atrás",
             "fr-FR": "vers l'arrière", "id-ID": "ke belakang",
             "ms-MY": "ke belakang", "th-TH": "ถอยหลัง", "vi-VN": "lùi lại"},
    "left": {"en": "left", "en-GB": "left", "zh-CN": "向左", "zh-TW": "向左",
             "ja-JP": "左", "ko-KR": "왼쪽으로", "es-ES": "a la izquierda",
             "fr-FR": "à gauche", "id-ID": "ke kiri", "ms-MY": "ke kiri",
             "th-TH": "ไปทางซ้าย", "vi-VN": "sang trái"},
    "right": {"en": "right", "en-GB": "right", "zh-CN": "向右", "zh-TW": "向右",
              "ja-JP": "右", "ko-KR": "오른쪽으로", "es-ES": "a la derecha",
              "fr-FR": "à droite", "id-ID": "ke kanan", "ms-MY": "ke kanan",
              "th-TH": "ไปทางขวา", "vi-VN": "sang phải"},
}

# ── setup census ────────────────────────────────────────────────────────────
SETUP_PLAYERS = {
    "en": "{n} players", "en-GB": "{n} players", "zh-CN": "{n} 人",
    "zh-TW": "{n} 人", "ja-JP": "{n}人", "ko-KR": "{n}명",
    "es-ES": "{n} jugadores", "fr-FR": "{n} joueurs", "id-ID": "{n} pemain",
    "ms-MY": "{n} pemain", "th-TH": "ผู้เล่น {n} คน", "vi-VN": "{n} cầu thủ",
}
SETUP_VS = {
    "en": "{h} v {a}", "en-GB": "{h} v {a}", "zh-CN": "{h} 对 {a}",
    "zh-TW": "{h} 對 {a}", "ja-JP": "{h}対{a}", "ko-KR": "{h}대{a}",
    "es-ES": "{h} contra {a}", "fr-FR": "{h} contre {a}",
    "id-ID": "{h} lawan {a}", "ms-MY": "{h} lawan {a}",
    "th-TH": "{h} ต่อ {a}", "vi-VN": "{h} đấu {a}",
}
SETUP_CONES = {
    "en": "{n} cones", "en-GB": "{n} cones", "zh-CN": "{n} 个锥标",
    "zh-TW": "{n} 個錐標", "ja-JP": "コーン{n}個", "ko-KR": "콘 {n}개",
    "es-ES": "{n} conos", "fr-FR": "{n} plots", "id-ID": "{n} kerucut",
    "ms-MY": "{n} kon", "th-TH": "กรวย {n} อัน", "vi-VN": "{n} cọc",
}
SETUP_BALL_AT = {
    "en": "ball with {a}", "en-GB": "ball with {a}", "zh-CN": "球在 {a} 脚下",
    "zh-TW": "球在 {a} 腳下", "ja-JP": "ボールは{a}", "ko-KR": "공은 {a}",
    "es-ES": "balón con {a}", "fr-FR": "ballon avec {a}",
    "id-ID": "bola pada {a}", "ms-MY": "bola dengan {a}",
    "th-TH": "บอลอยู่ที่ {a}", "vi-VN": "bóng ở chỗ {a}",
}
# "At his feet" is a football phrase. Chinese names where the ball is, so a
# setter, a pitcher or a server has it 手中 and a hockey player 杆下; the
# other locales' "ball with {a}" is already neutral.
_BALL_AT_ZH = {
    "hand": {"zh-CN": "球在 {a} 手中", "zh-TW": "球在 {a} 手中"},
    "stick": {"zh-CN": "球在 {a} 杆下", "zh-TW": "球在 {a} 桿下"},
}
FOOT_SPORTS = {"soccer", "footvolley", "sepakTakraw"}
STICK_SPORTS = {"fieldHockey"}


def _ball_at(sport: str, loc: str) -> str:
    if loc in ("zh-CN", "zh-TW") and sport not in FOOT_SPORTS:
        fam = "stick" if sport in STICK_SPORTS else "hand"
        return _BALL_AT_ZH[fam][loc]
    return SETUP_BALL_AT[loc]

# Sports where a ball_to leg reads as a throw / a hit rather than a kick-pass.
THROW_SPORTS = {"baseball", "handball", "waterPolo", "rugby", "basketball"}
HIT_SPORTS = {"volleyball", "tennis", "badminton", "tableTennis",
              "pickleball", "sepakTakraw", "beachTennis", "footvolley"}

# A run ending this close to where the ball stopped last beat is following
# the pass. Wide enough to cover the queue-behind offset (runs end 80 short
# of the cone) plus the ball's at-feet offset; the next cone is 400+ away.
FOLLOW_NEAR = 240.0


def _label(p) -> str:
    return p.label or ""


# The one player on a board wears no number (engine.unlabel_lone_player);
# in a sentence he is simply the player.
LONE = {
    "en": "the player", "en-GB": "the player",
    "zh-CN": "球员", "zh-TW": "球員", "ja-JP": "選手", "ko-KR": "선수",
    "es-ES": "el jugador", "fr-FR": "le joueur", "id-ID": "pemain",
    "ms-MY": "pemain", "th-TH": "ผู้เล่น", "vi-VN": "cầu thủ",
}


# How a shirt label reads as a sentence subject, per locale. "3" alone is a
# telegram; Chinese wants "3号球员". Letters (away A/B, GK, P) and non-CJK
# locales keep the bare label — "A号球员" is not a word.
_SUBJ = {
    "zh-CN": "{n}号球员", "zh-TW": "{n}號球員",
    "ja-JP": "{n}番", "ko-KR": "{n}번",
}


def _subj(label, loc):
    label = str(label)
    if not label:
        return LONE[loc]
    tmpl = _SUBJ.get(loc)
    if tmpl and label.isdigit():
        return tmpl.format(n=label)
    return label


def _pass_verb(sport: str) -> dict:
    if sport in THROW_SPORTS:
        return THROW
    if sport in HIT_SPORTS:
        return HIT
    return PASS


def _pass_in(sport: str, from_xy=None, to_xy=None) -> dict:
    if sport not in HIT_SPORTS:
        return PASS_IN
    if from_xy is not None and to_xy is not None:
        from .engine import court_rect
        _, top, _, ch = court_rect(sport)
        net = top + ch / 2
        if (from_xy[1] < net) == (to_xy[1] < net):
            return FEED
    return PASS_IN_NET


def _far_end(sport: str) -> tuple[dict, dict]:
    """(verb, place) for a ball played to the last twelfth of the board."""
    if sport == "basketball":
        return SHOOT_HOOP, BASKET_WORD
    if sport == "rugby":
        return KICK_POSTS, POSTS_WORD
    if sport == "baseball":
        return PITCH, PLATE_WORD
    if sport in HIT_SPORTS:
        return HIT_DEEP, DEEP_WORD
    return SHOOT, GOAL_WORD


def _is_far_end(sport: str, target) -> bool:
    """A point in the last twelfth of the board — past the try line in
    rugby, whose court drawing includes the in-goal areas."""
    from .engine import court_rect
    _, top, _, ch = court_rect(sport)
    frac = 0.16 if sport == "rugby" else 0.085
    return target[1] < top + ch * frac or target[1] > top + ch * (1 - frac)


def _spot_leg(sport: str) -> tuple[dict, dict]:
    """(verb, place) for a ball played to a point short of the far end."""
    if sport in HIT_SPORTS:
        return HIT_SPOT, SPOT_WORD
    return PASS_SPOT, SPOT_WORD


def _facing(p, drill, d: str) -> str:
    """"Forward" is toward the opponents.

    The board has no fixed direction of play: one drill lines the home side
    up at the bottom attacking upward, the next puts its defenders at the
    top pressing down. So a team's forward is worked out from where the
    other team stands, and a move toward them reads 向前 whichever way it
    is drawn. With nobody to face, up the board stays forward.
    """
    if d not in ("up", "down") or not (drill.home and drill.away):
        return d
    home_cy = sum(q.y for q in drill.home) / len(drill.home)
    away_cy = sum(q.y for q in drill.away) / len(drill.away)
    mine = drill.away if p in drill.away else drill.home
    theirs = drill.home if p in drill.away else drill.away
    my_cy = away_cy if mine is drill.away else home_cy
    their_cy = home_cy if theirs is drill.home else away_cy
    forward_is_down = their_cy > my_cy
    if forward_is_down:
        return "down" if d == "up" else "up"
    return d


def _holder(drill):
    """Who has the ball at the start, for the text.

    ball=<index> names him. A ball placed as a point (a kicker's tee, a
    fielder's glove written as coordinates) is his if he stands within
    reach of it — otherwise the first leg had no subject and a goal-kick
    drill narrated only the kicker's steps back, never the kick.
    """
    if isinstance(drill.ball, int):
        return drill.home[drill.ball]
    if isinstance(drill.ball, tuple):
        x, y = drill.ball
        best, who = 160.0, None
        # BOTH sides. Searching only home made every loose ball belong to the
        # nearest home player, so a ball placed on their setter was credited
        # to our blocker and seven volleyball boards read "B plays it to A"
        # over a picture of S setting.
        for pl in drill.home + drill.away:
            d = abs(pl.x - x) + abs(pl.y - y)
            if d < best:
                best, who = d, pl
        return who
    return None


def _narration_route(drill) -> list:
    """The ball's legs as (target, phase), for the text.

    ball_to when the author wrote one. A drill with hand-written ball_moves
    (a double play, a served shuttle) used to get no 球路 and no ball in its
    流程 at all — the legs are turned back into targets here: whichever
    player is standing where the ball stops on that beat, else the point.
    """
    if drill.ball_to or drill.ball_follow is not None:
        return drill.ball_to
    from .engine import _pos_at
    out = []
    for (x, y, ph) in drill.ball_moves:
        best, who = 160.0, None
        for i, pl in enumerate(drill.home):
            px, py = _pos_at(pl, ph)
            d = abs(px - x) + abs(py - y)
            if d < best:
                best, who = d, i
        for i, pl in enumerate(drill.away):
            px, py = _pos_at(pl, ph)
            d = abs(px - x) + abs(py - y)
            if d < best:
                best, who = d, f"a{i}"
        out.append((who if who is not None else (x, y), ph))
    return out


def sequence_texts(drill, sport: str) -> dict | None:
    """The 流程 section, one string per locale, from the resolved drill.

    Call after build_board has run resolve_ball and normalise_phases — the
    beats narrated here are exactly the beats the stepper walks.
    """
    # (verb_table_or_None, params) per beat, balls first within a beat.
    beats: dict[int, list] = {}

    def add(ph, table, **params):
        beats.setdefault(ph, []).append((table, params))

    people = drill.home + drill.away
    if drill.ball_follow is not None:
        carrier = drill.home[drill.ball_follow]
        for (_, _, ph) in carrier.moves[:1]:
            add(ph, CARRY, a=_label(carrier))
    route = _narration_route(drill)
    if route:
        from .engine import _pos_at
        holder = _holder(drill)
        prev = holder
        # Where the ball is before each leg, for the crossed-the-net test.
        legs = drill.ball_moves[len(drill.ball_moves) - len(route):]
        if holder is not None:
            from_xy = (holder.x, holder.y)
        else:
            from_xy = drill.ball if isinstance(drill.ball, tuple) else None
        for k, (target, ph) in enumerate(route):
            if k > 0 and k - 1 < len(legs):
                from_xy = legs[k - 1][:2]
            if isinstance(target, tuple):
                # A point at the far end of the board is a shot, a pitch, a
                # ball hit deep — not "the ball played on".
                shooty = _is_far_end(sport, target)
                tbl = (_far_end(sport) if shooty else _spot_leg(sport))[0]
                if prev:
                    add(ph, tbl, a=_label(prev))
                prev = None
            else:
                t = (drill.away[int(target[1:])] if isinstance(target, str)
                     else drill.home[target])
                if prev is None:
                    add(ph, _pass_in(sport, from_xy, _pos_at(t, ph)),
                        b=_label(t))
                elif t is prev:
                    # A leg whose target is the holder himself is a carry —
                    # the ball rides that player's run for this beat. The
                    # board draws it the same way (the escorted rule), and
                    # "2 passes to 2" is not a sentence.
                    add(ph, HIT_MOVE if sport in HIT_SPORTS else CARRY,
                        a=_label(t))
                elif (sport not in HIT_SPORTS
                      and (prev in drill.away) != (t in drill.away)):
                    if _label(t).upper() in ("GK", "G", "K"):
                        tbl = SHOT_AT_KEEPER
                    elif _label(prev).upper() in ("GK", "G", "K"):
                        tbl = KEEPER_OUT
                    elif sport == "rugby":
                        tbl = KICK_TO
                    else:
                        tbl = CHANGES_HANDS
                    add(ph, tbl, a=_label(prev), b=_label(t))
                else:
                    add(ph, _pass_verb(sport), a=_label(prev), b=_label(t))
                prev = t

    # The player who played the ball on each beat — a follow is that player
    # chasing his own pass, nobody else drifting near the ball.
    passer_on = {}
    if route:
        prev2 = _holder(drill)
        for (target, ph) in route:
            if prev2 is not None:
                passer_on[ph] = prev2
            if isinstance(target, tuple):
                prev2 = None
            else:
                prev2 = (drill.away[int(target[1:])]
                         if isinstance(target, str) else drill.home[target])

    # Where the ball stops per phase, for follow detection.
    stops = {ph: (x, y) for (x, y, ph) in drill.ball_moves}
    carrier = (drill.home[drill.ball_follow]
               if drill.ball_follow is not None else None)
    # Beats on which a player's run IS the ball's leg (a carry, a toss-and-
    # hit): the ball clause already says he moved.
    carried = set()
    if route:
        prev3 = _holder(drill)
        for (target, ph) in route:
            t3 = None if isinstance(target, tuple) else (
                drill.away[int(target[1:])] if isinstance(target, str)
                else drill.home[target])
            if t3 is not None and t3 is prev3:
                carried.add((id(t3), ph))
            prev3 = t3
    for p in people:
        for i, (x, y, ph) in enumerate(p.moves):
            if i > 0:
                continue  # narrate a player's first leg; chains stay terse
            if p is carrier or (id(p), ph) in carried:
                continue  # "1 carries the ball on" already said this leg
            prev_stop = stops.get(ph - 1)
            is_follow = (prev_stop is not None
                         and passer_on.get(ph - 1) is p
                         and abs(x - prev_stop[0]) + abs(y - prev_stop[1])
                         < FOLLOW_NEAR)
            if is_follow:
                # Name the spot: whichever OTHER player started nearest where
                # the ball stopped last beat is the receiver whose position
                # the follower is running into.
                dest = None
                best = 1e9
                for q in people:
                    # A team-mate: nobody follows up behind an opponent.
                    if q is p or (q in drill.away) != (p in drill.away):
                        continue
                    dq = abs(q.x - prev_stop[0]) + abs(q.y - prev_stop[1])
                    if dq < best:
                        best, dest = dq, q
                if dest is not None and best < FOLLOW_NEAR:
                    add(ph, FOLLOW, a=_label(p), to=_label(dest))
                else:
                    add(ph, FOLLOW_PLAIN, a=_label(p))
                continue
            dx, dy = x - p.x, y - p.y
            d = ("right" if dx > 0 else "left") if abs(dx) > abs(dy) else \
                ("down" if dy > 0 else "up")
            add(ph, RUN, a=_label(p), dir_key=_facing(p, drill, d),
                why=p.why.get(ph))

    # A chain's later legs are not narrated — until they are all a beat has.
    # A kicker who steps back (beat 1), steps in (beat 2) and kicks (beat 3)
    # read "第1步 … 第3步", and a reader takes a missing step for a mistake.
    if beats:
        for p in people:
            for i, (x, y, ph) in enumerate(p.moves):
                # A later leg with an authored reason is worth its clause
                # even on a beat that already has one: "A gets back to the
                # cone" is what closes the rondo's loop.
                if i == 0 or (ph in beats and not p.why.get(ph)):
                    continue
                px, py = p.moves[i - 1][:2]
                dx, dy = x - px, y - py
                d = ("right" if dx > 0 else "left") if abs(dx) > abs(dy) \
                    else ("down" if dy > 0 else "up")
                add(ph, RUN, a=_label(p), dir_key=_facing(p, drill, d),
                    why=p.why.get(ph))

    if not beats:
        return None
    out = {}
    LIST = {"zh-CN": "、", "zh-TW": "、", "ja-JP": "・"}
    for loc in LOCALES:
        parts = []
        for ph in sorted(beats):
            acts = []
            # Identical actions share one clause: a five-man push read as
            # "1 moves up, 2 moves up, 3 moves up, 4 moves up, 5 moves up" —
            # five copies of the same sentence. Grouped, it is one clause
            # with five subjects.
            grouped: dict[tuple, list] = {}
            for table, params in beats[ph]:
                if "b" in params or "to" in params:
                    acts.append((table, params))
                elif "dir_key" in params or len(params) == 1:
                    grouped.setdefault(
                        (id(table), params.get("dir_key"), params.get("why")),
                        [],
                    ).append(params["a"])
                else:
                    acts.append((table, params))
            rendered = []
            for table, params in acts:
                fmt = {k: (_subj(v, loc) if k in ("a", "b", "to") else v)
                       for k, v in params.items()}
                rendered.append(table[loc].format(**fmt))
            for (tid, dir_key, why), subjects in grouped.items():
                table = next(t for t in (RUN, FOLLOW_PLAIN, CARRY, HIT_MOVE,
                                         PASS_SPOT, HIT_SPOT, HIT_DEEP,
                                         KICK_POSTS, PITCH, SHOOT, SHOOT_HOOP,
                                         PASS_IN, PASS_IN_NET, FEED)
                             if id(t) == tid)
                # Same letter several times over ("D, D, D") is a count.
                names, counts = [], {}
                for x in subjects:
                    if x not in counts:
                        names.append(x)
                    counts[x] = counts.get(x, 0) + 1
                joined = LIST.get(loc, ", ").join(
                    COUNTED[loc].format(n=counts[x], a=_subj(x, loc))
                    if counts[x] > 1 else _subj(x, loc)
                    for x in names)
                if dir_key:
                    home_labels = [_label(q) for q in drill.home]
                    if len(drill.home) >= 6 and all(
                            l in subjects for l in home_labels) and \
                            len(subjects) == len(drill.home) + len(
                                [x for x in subjects
                                 if x not in home_labels]):
                        rendered.append(ALL_MOVE[loc].format(
                            dir=DIR[dir_key][loc]))
                        rest = [x for x in names if x not in home_labels]
                        if rest:
                            joined = LIST.get(loc, ", ").join(
                                COUNTED[loc].format(n=counts[x],
                                                    a=_subj(x, loc))
                                if counts[x] > 1 else _subj(x, loc)
                                for x in rest)
                            tmpl = RUN[loc]
                            if loc in ("en", "en-GB") and len(rest) > 1:
                                tmpl = tmpl.replace(" moves ", " move ")
                            rendered.append(tmpl.format(
                                a=joined, dir=DIR[dir_key][loc]))
                        continue
                    tmpl = RUN[loc]
                    if loc in ("en", "en-GB") and len(subjects) > 1:
                        tmpl = tmpl.replace(" moves ", " move ")
                    run = tmpl.format(a=joined, dir=DIR[dir_key][loc])
                    if why == "reset":
                        run = RESET[loc].format(a=joined)
                    elif why:
                        run = RUN_WHY[loc].format(run=run,
                                                  why=why_text(why, loc))
                    rendered.append(run)
                else:
                    rendered.append(table[loc].format(a=joined))
            parts.append(BEAT[loc].format(n=ph + 1) + AND[loc].join(rendered))
        out[loc] = SEMI[loc].join(parts) + DOT[loc].strip() \
            if loc in ("zh-CN", "zh-TW", "ja-JP", "th-TH") \
            else SEMI[loc].join(parts) + "."
    return out


def route_texts(drill, sport: str) -> dict | None:
    """One line: where the ball goes, start to finish — 2 → 3 → 4 → goal.

    The step-by-step below it is precise but sequential; this is the shape of
    the whole drill in a glance, and it is what makes the steps scannable.
    """
    route = _narration_route(drill)
    if not route:
        return None
    stops_by_loc = {loc: [] for loc in LOCALES}
    holder = _holder(drill)
    start = _label(holder) if holder is not None else None
    for loc in LOCALES:
        stops = [start] if start is not None else []
        for (t, ph) in route:
            if isinstance(t, tuple):
                shooty = _is_far_end(sport, t)
                sx, sy = ((drill.home[drill.ball].x, drill.home[drill.ball].y)
                          if isinstance(drill.ball, int) else
                          (drill.ball if isinstance(drill.ball, tuple)
                           else (None, None)))
                if shooty:
                    stops.append(_far_end(sport)[1][loc])
                elif sx is not None and abs(t[0]-sx) + abs(t[1]-sy) < 120:
                    stops.append(BACK_TO_START[loc])
                else:
                    stops.append(_spot_leg(sport)[1][loc])
            elif isinstance(t, str):
                stops.append(_label(drill.away[int(t[1:])]))
            else:
                stops.append(_label(drill.home[t]))
        # A carry leg repeats the holder; collapse runs of the same stop so
        # the path reads 9 → 11 → goal, not 9 → 9 → 9 → 11 → goal.
        clean = [x for i, x in enumerate(stops) if i == 0 or x != stops[i-1]]
        if len(clean) < 2:
            return None
        stops_by_loc[loc] = " → ".join(x or LONE[loc] for x in clean)
    return stops_by_loc


def setup_texts(drill, sport: str) -> dict:
    """The 组织 census — overridden by a hand-written drill.setup when given."""
    hand = getattr(drill, "setup", None)
    if hand:
        return {loc: hand.get(loc, hand["en"]) for loc in LOCALES}
    out = {}
    for loc in LOCALES:
        bits = []
        if drill.away:
            bits.append(SETUP_VS[loc].format(h=len(drill.home),
                                             a=len(drill.away)))
        else:
            bits.append(SETUP_PLAYERS[loc].format(n=len(drill.home)))
        cones = sum(1 for m in drill.markers if m.shape == "cone")
        if cones:
            bits.append(SETUP_CONES[loc].format(n=cones))
        if isinstance(drill.ball, int):
            bits.append(_ball_at(sport, loc).format(
                a=_subj(_label(drill.home[drill.ball]), loc)))
        out[loc] = AND[loc].join(bits)
    return out


def compose_note(drill, sport: str) -> None:
    """Rebuild drill.note as 组织+流程+要点, keeping the hand-written point.

    Mutates the note in place; the point is whatever the author wrote as the
    note. Runs once per drill at the end of build_board, after phases are
    final. A drill with no movement keeps its plain note untouched.
    """
    from .purposes import purpose_texts
    from .background import background_texts
    seq = sequence_texts(drill, sport)
    purpose = purpose_texts(sport, drill.category)
    freq, origin = background_texts(sport, drill.category, drill.id)
    # A drill with no movement (shadow footwork) still gets a purpose and a
    # setup; only the sequence line is skipped when there is nothing to walk.
    if seq is None and purpose is None:
        return
    setup = setup_texts(drill, sport)
    route = route_texts(drill, sport)
    new = {}
    for loc in LOCALES:
        point = drill.note.get(loc) or drill.note["en"]
        parts = []
        if purpose:
            parts.append(SECTION["purpose"][loc] + purpose[loc])
        if freq:
            parts.append(SECTION["freq"][loc] + freq[loc])
        if origin:
            parts.append(SECTION["origin"][loc] + origin[loc])
        parts.append(SECTION["setup"][loc] + setup[loc] + DOT[loc].rstrip())
        if route:
            parts.append(SECTION["route"][loc] + route[loc])
        if seq is not None:
            parts.append(SECTION["seq"][loc] + seq[loc])
        if drill.rules:
            parts.append(SECTION["rules"][loc]
                         + (drill.rules.get(loc) or drill.rules["en"]))
        parts.append(SECTION["point"][loc] + point)
        # One section per line: as a single run-on paragraph the note made
        # the reader find the section markers themselves.
        new[loc] = "\n".join(parts)
    drill.note = new
