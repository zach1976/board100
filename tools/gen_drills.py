#!/usr/bin/env python3
"""Build the shipped drill library from the specs in this file.

Why a generator: a drill is a board — players, cones, a ball, and a movement
path per player with a phase number so the play unfolds in order. Hand-writing
that JSON is unreadable and unmaintainable; hand-placing it in the app and
exporting is slow and can't be diffed. Here one drill is ~10 lines of intent
and the coordinates stay reviewable.

Positions are in a nominal 1000x1500 portrait canvas (attacking upward: the
opponent goal is at y=0). The app rescales a loaded board to whatever canvas
it is on, so these numbers are proportions, not pixels.

    python3 tools/gen_drills.py            # writes tactics_board/assets/drills/
    python3 tools/gen_drills.py --check    # verify the checked-in output matches
"""
import argparse
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT_DIR = REPO / "tactics_board" / "assets" / "drills"

CANVAS_W, CANVAS_H = 1000.0, 1500.0

SPORT_INDEX = {"soccer": 6}

TEAM_HOME, TEAM_AWAY, TEAM_NEUTRAL = 0, 1, 2
# MarkerShape enum order in lib/models/player_icon.dart
MARKER = {"none": 0, "circle": 1, "square": 2, "triangle": 3, "diamond": 4,
          "cone": 5, "text": 6, "zone": 7, "referee": 8, "coach": 9,
          "ladder": 10, "hurdle": 11, "arrow": 12}

MOVE_COLORS = [0xFF40C4FF, 0xFFFF6D6D, 0xFF69F0AE, 0xFFFFD740,
               0xFFEA80FC, 0xFF84FFFF, 0xFFFF9E80, 0xFFA5D6A7]


@dataclass
class P:
    """A player. `moves` is a list of (x, y, phase) — the run, in order."""
    x: float
    y: float
    label: str = ""
    role: str | None = None
    moves: list = field(default_factory=list)


@dataclass
class M:
    """A piece of equipment: cone, ladder, hurdle, a marked zone."""
    x: float
    y: float
    shape: str = "cone"
    label: str = ""


@dataclass
class Drill:
    id: str
    category: str          # warmup | possession | attacking | finishing | defending | setpiece | ssg
    minutes: int
    name: dict             # locale -> str  (en required)
    note: dict             # locale -> str  (en required; the coaching point)
    home: list             # [P]
    away: list = field(default_factory=list)
    markers: list = field(default_factory=list)
    # index into `home` whose feet the ball starts at, or an (x, y) for a loose ball
    ball: object = None

    @property
    def player_count(self) -> int:
        return len(self.home) + len(self.away)


def _player(idx, p: P, team: int, sport: str, color_idx: int) -> dict:
    moves = [[m[0], m[1]] for m in p.moves]
    phases = [m[2] for m in p.moves]
    return {
        "id": f"d{idx}",
        "label": p.label,
        "team": team,
        "sportType": None,
        "position": [p.x, p.y],
        "scale": 1.0,
        "moves": moves,
        "movePhases": phases,
        "moveColor": MOVE_COLORS[color_idx % len(MOVE_COLORS)],
        "customColor": None,
        "gender": 2,                      # unspecified
        "markerShape": MARKER["none"],
        "photoId": None,
        "role": p.role,
        "attachedTo": None,
    }


def _marker(idx, m: M) -> dict:
    return {
        "id": f"m{idx}",
        "label": m.label,
        "team": TEAM_NEUTRAL,
        "sportType": None,
        "position": [m.x, m.y],
        "scale": 1.0,
        "moves": [],
        "movePhases": [],
        "moveColor": MOVE_COLORS[0],
        "customColor": None,
        "gender": 2,
        "markerShape": MARKER[m.shape],
        "photoId": None,
        "role": None,
        "attachedTo": None,
    }


def _ball(idx, sport: str, x: float, y: float, attached_to: str | None) -> dict:
    return {
        "id": f"b{idx}",
        "label": "",
        "team": TEAM_NEUTRAL,
        "sportType": SPORT_INDEX[sport],   # a ball is neutral WITH a sport
        "position": [x, y],
        "scale": 1.0,
        "moves": [],
        "movePhases": [],
        "moveColor": MOVE_COLORS[0],
        "customColor": None,
        "gender": 2,
        "markerShape": MARKER["none"],
        "photoId": None,
        "role": None,
        "attachedTo": attached_to,
    }


def normalise_phases(drill: Drill) -> None:
    """Renumber phases to 0,1,2… across the whole drill.

    Playback walks steps in order, so a drill whose first movement sits at
    phase 1 opens with a step where nothing happens, and a gap in the middle
    is a dead press of the button. Authors think in "this happens after that",
    not in dense integers — so fix it here instead of in every spec.
    """
    used = sorted({m[2] for p in drill.home + drill.away for m in p.moves})
    if not used or used == list(range(len(used))):
        return
    remap = {old: new for new, old in enumerate(used)}
    for p in drill.home + drill.away:
        p.moves = [(x, y, remap[ph]) for (x, y, ph) in p.moves]


def build_board(drill: Drill, sport: str) -> dict:
    normalise_phases(drill)
    players, i, color = [], 0, 0
    home_ids = []
    for p in drill.home:
        players.append(_player(i, p, TEAM_HOME, sport, color))
        home_ids.append(f"d{i}")
        i += 1
        color += 1
    for p in drill.away:
        players.append(_player(i, p, TEAM_AWAY, sport, color))
        i += 1
        color += 1
    for j, m in enumerate(drill.markers):
        players.append(_marker(j, m))

    if drill.ball is not None:
        if isinstance(drill.ball, int):
            holder = drill.home[drill.ball]
            players.append(_ball(0, sport, holder.x, holder.y, home_ids[drill.ball]))
        else:
            players.append(_ball(0, sport, drill.ball[0], drill.ball[1], None))

    return {
        "sportType": SPORT_INDEX[sport],
        "players": players,
        "strokes": [],
        "canvasWidth": CANVAS_W,
        "canvasHeight": CANVAS_H,
    }


# ─────────────────────────────────────────────────────────────────────────────
# The library. Coordinates: x 0..1000 left→right, y 0..1500 with the attacking
# goal at the top (y=0), which is how the app draws a full pitch.
# ─────────────────────────────────────────────────────────────────────────────

def soccer_drills() -> list[Drill]:
    return [
        # ── warm-up ──────────────────────────────────────────────────────────
        Drill(
            id="rondo_4v2", category="possession", minutes=10,
            name={"en": "Rondo 4v2", "zh-CN": "4v2 抢圈", "zh-TW": "4v2 搶圈",
                  "ja-JP": "ロンド 4対2", "ko-KR": "론도 4대2", "es-ES": "Rondo 4v2",
                  "fr-FR": "Rondo 4c2", "id-ID": "Rondo 4v2", "ms-MY": "Rondo 4v2",
                  "th-TH": "รอนโด 4v2", "vi-VN": "Rondo 4v2", "en-GB": "Rondo 4v2"},
            note={"en": "Two touches. The pass that breaks the line is the one through the middle — look for it before playing round.",
                  "zh-CN": "限两脚触球。真正破防的是穿过中间那脚传球 —— 先找它，再考虑绕圈传。",
                  "zh-TW": "限兩腳觸球。真正破防的是穿過中間那腳傳球 —— 先找它，再考慮繞圈傳。",
                  "ja-JP": "2タッチ。中央を通すパスが最も効く。外に回す前にまず中を見る。",
                  "ko-KR": "두 번 터치. 가운데를 통과하는 패스가 수비를 무너뜨린다. 돌리기 전에 안쪽을 먼저 보라.",
                  "es-ES": "A dos toques. El pase que rompe es el interior: búscalo antes de girar por fuera.",
                  "fr-FR": "Deux touches. La passe qui casse la ligne passe au milieu : cherche-la avant de tourner.",
                  "id-ID": "Dua sentuhan. Umpan yang memecah pertahanan lewat tengah — cari itu dulu.",
                  "ms-MY": "Dua sentuhan. Hantaran yang memecah pertahanan melalui tengah — cari dahulu.",
                  "th-TH": "แตะสองครั้ง บอลที่เจาะได้คือบอลทะลุกลาง มองหาก่อนจะวนออกข้าง",
                  "vi-VN": "Hai chạm. Đường chuyền xuyên tuyến đi qua giữa — tìm nó trước khi chuyền vòng.",
                  "en-GB": "Two touches. The pass that breaks the line is the one through the middle — look for it before playing round."},
            home=[
                P(300, 500, "1", moves=[(300, 700, 0)]),
                P(700, 500, "2", moves=[(700, 700, 1)]),
                P(700, 900, "3", moves=[(700, 700, 2)]),
                P(300, 900, "4", moves=[(300, 700, 3)]),
            ],
            away=[
                P(450, 650, "A", moves=[(600, 650, 0), (450, 800, 2)]),
                P(550, 800, "B", moves=[(450, 800, 1), (600, 650, 3)]),
            ],
            markers=[M(280, 480), M(720, 480), M(720, 920), M(280, 920)],
            ball=0,
        ),
        Drill(
            id="passing_diamond", category="warmup", minutes=8,
            name={"en": "Passing diamond", "zh-CN": "菱形传球", "zh-TW": "菱形傳球",
                  "ja-JP": "ダイヤモンドパス", "ko-KR": "다이아몬드 패스", "es-ES": "Rombo de pases",
                  "fr-FR": "Losange de passes", "id-ID": "Umpan berlian", "ms-MY": "Hantaran berlian",
                  "th-TH": "ผ่านบอลรูปข้าวหลามตัด", "vi-VN": "Chuyền hình thoi", "en-GB": "Passing diamond"},
            note={"en": "Pass and follow your pass. Open your body before the ball arrives so the next pass is already on.",
                  "zh-CN": "传球后跟着球跑。球到之前先把身体打开，下一脚传球才接得上。",
                  "zh-TW": "傳球後跟著球跑。球到之前先把身體打開，下一腳傳球才接得上。",
                  "ja-JP": "パスしたら自分のパスを追う。ボールが来る前に体を開き、次のパスを準備する。",
                  "ko-KR": "패스한 뒤 그 패스를 따라 이동. 공이 오기 전에 몸을 열어 다음 패스를 준비하라.",
                  "es-ES": "Pasa y sigue tu pase. Abre el cuerpo antes de recibir para tener el siguiente pase.",
                  "fr-FR": "Passe et suis ta passe. Ouvre-toi avant la réception pour enchaîner.",
                  "id-ID": "Umpan lalu ikuti umpanmu. Buka badan sebelum bola datang.",
                  "ms-MY": "Hantar dan ikut hantaran anda. Buka badan sebelum bola tiba.",
                  "th-TH": "จ่ายแล้ววิ่งตามบอล เปิดลำตัวก่อนบอลมาถึง",
                  "vi-VN": "Chuyền rồi chạy theo. Mở người trước khi bóng đến.",
                  "en-GB": "Pass and follow your pass. Open your body before the ball arrives so the next pass is already on."},
            home=[
                P(500, 400, "1", moves=[(780, 700, 0)]),
                P(780, 700, "2", moves=[(500, 1000, 1)]),
                P(500, 1000, "3", moves=[(220, 700, 2)]),
                P(220, 700, "4", moves=[(500, 400, 3)]),
            ],
            markers=[M(500, 380), M(800, 700), M(500, 1020), M(200, 700)],
            ball=0,
        ),
        Drill(
            id="dribble_slalom", category="warmup", minutes=8,
            name={"en": "Dribble slalom", "zh-CN": "绕杆运球", "zh-TW": "繞桿運球",
                  "ja-JP": "スラロームドリブル", "ko-KR": "슬라럼 드리블", "es-ES": "Eslalon de conducción",
                  "fr-FR": "Slalom conduite", "id-ID": "Slalom menggiring", "ms-MY": "Slalom mengelecek",
                  "th-TH": "เลี้ยงบอลสลาลม", "vi-VN": "Dẫn bóng slalom", "en-GB": "Dribble slalom"},
            note={"en": "Small touches through the cones, then head up and one long touch into space.",
                  "zh-CN": "过杆时小碎步触球，出杆后抬头，一脚大力推进空当。",
                  "zh-TW": "過桿時小碎步觸球，出桿後抬頭，一腳大力推進空檔。",
                  "ja-JP": "コーン間は細かいタッチ、抜けたら顔を上げて大きく運ぶ。",
                  "ko-KR": "콘 사이는 짧은 터치, 빠져나오면 고개를 들고 크게 밀어라.",
                  "es-ES": "Toques cortos entre conos; al salir, levanta la cabeza y empuja largo.",
                  "fr-FR": "Petites touches entre les plots, puis tête haute et une longue touche.",
                  "id-ID": "Sentuhan kecil di antara kerucut, lalu angkat kepala dan dorong panjang.",
                  "ms-MY": "Sentuhan kecil antara kon, kemudian angkat kepala dan tolak jauh.",
                  "th-TH": "แตะสั้นๆ ระหว่างกรวย แล้วเงยหน้าดันบอลยาว",
                  "vi-VN": "Chạm ngắn qua nón, rồi ngẩng đầu đẩy bóng dài.",
                  "en-GB": "Small touches through the cones, then head up and one long touch into space."},
            home=[
                P(500, 1200, "1", moves=[(420, 1050, 0), (580, 900, 1), (420, 750, 2), (500, 500, 3)]),
            ],
            markers=[M(500, 1050), M(500, 900), M(500, 750), M(500, 620)],
            ball=0,
        ),

        # ── possession ───────────────────────────────────────────────────────
        Drill(
            id="possession_7v4", category="possession", minutes=15,
            name={"en": "7v4 possession", "zh-CN": "7v4 控球", "zh-TW": "7v4 控球",
                  "ja-JP": "7対4 ポゼッション", "ko-KR": "7대4 볼 소유", "es-ES": "Posesión 7v4",
                  "fr-FR": "Conservation 7c4", "id-ID": "Penguasaan 7v4", "ms-MY": "Penguasaan 7v4",
                  "th-TH": "ครองบอล 7v4", "vi-VN": "Giữ bóng 7v4", "en-GB": "7v4 possession"},
            note={"en": "Six passes then switch. The far side is only free while the ball travels — move it before they shift.",
                  "zh-CN": "六脚传球后转移。球在运行时对面才是空的 —— 趁他们没横移过来就传。",
                  "zh-TW": "六腳傳球後轉移。球在運行時對面才是空的 —— 趁他們沒橫移過來就傳。",
                  "ja-JP": "6本つないだら逆サイドへ。ボールが動いている間だけ逆が空く。",
                  "ko-KR": "여섯 번 연결 후 전환. 공이 이동하는 동안만 반대편이 비어 있다.",
                  "es-ES": "Seis pases y cambia. El lado lejano solo está libre mientras viaja el balón.",
                  "fr-FR": "Six passes puis renverse. Le côté opposé n'est libre que pendant le trajet du ballon.",
                  "id-ID": "Enam umpan lalu pindahkan. Sisi jauh hanya kosong saat bola bergerak.",
                  "ms-MY": "Enam hantaran kemudian tukar sisi. Sisi jauh hanya kosong ketika bola bergerak.",
                  "th-TH": "จ่ายหกครั้งแล้วเปลี่ยนข้าง ฝั่งไกลว่างเฉพาะตอนบอลกำลังเดินทาง",
                  "vi-VN": "Sáu đường chuyền rồi chuyển cánh. Cánh xa chỉ trống khi bóng đang di chuyển.",
                  "en-GB": "Six passes then switch. The far side is only free while the ball travels — move it before they shift."},
            home=[
                P(200, 500, "1"), P(500, 420, "2"), P(800, 500, "3", moves=[(820, 700, 1)]),
                P(200, 900, "4"), P(500, 980, "5"), P(800, 900, "6"),
                P(500, 700, "7", moves=[(620, 640, 0)]),
            ],
            away=[
                P(380, 620, "A", moves=[(500, 560, 0)]),
                P(620, 620, "B", moves=[(700, 600, 1)]),
                P(380, 800, "C"), P(620, 800, "D"),
            ],
            markers=[M(180, 400), M(820, 400), M(820, 1000), M(180, 1000)],
            ball=0,
        ),

        # ── attacking patterns ───────────────────────────────────────────────
        Drill(
            id="overlap_wide", category="attacking", minutes=12,
            name={"en": "Overlap and cross", "zh-CN": "边路套上传中", "zh-TW": "邊路套上傳中",
                  "ja-JP": "オーバーラップとクロス", "ko-KR": "오버래핑과 크로스", "es-ES": "Desdoble y centro",
                  "fr-FR": "Débordement et centre", "id-ID": "Overlap dan umpan silang", "ms-MY": "Overlap dan lambungan",
                  "th-TH": "โอเวอร์แล็ปและครอส", "vi-VN": "Chồng biên và tạt", "en-GB": "Overlap and cross"},
            note={"en": "The winger holds until the full-back is past him — the defender can't watch both.",
                  "zh-CN": "边锋要等边后卫套过自己再放球 —— 防守球员盯不住两个人。",
                  "zh-TW": "邊鋒要等邊後衛套過自己再放球 —— 防守球員盯不住兩個人。",
                  "ja-JP": "ウイングはSBが追い越すまで持つ。DFは二人同時に見られない。",
                  "ko-KR": "윙어는 풀백이 추월할 때까지 잡아둔다. 수비수는 둘을 동시에 볼 수 없다.",
                  "es-ES": "El extremo aguanta hasta que el lateral lo supera: el defensa no puede mirar a los dos.",
                  "fr-FR": "L'ailier retient jusqu'au dépassement du latéral : le défenseur ne peut voir les deux.",
                  "id-ID": "Sayap menahan bola sampai bek sayap melewatinya — bek lawan tak bisa menjaga keduanya.",
                  "ms-MY": "Pemain sayap tahan bola sehingga bek sayap melepasinya.",
                  "th-TH": "ปีกถือบอลไว้จนกว่าแบ็กจะแซงขึ้นไป กองหลังดูสองคนพร้อมกันไม่ได้",
                  "vi-VN": "Tiền vệ cánh giữ bóng đến khi hậu vệ biên vượt qua — hậu vệ không thể theo cả hai.",
                  "en-GB": "The winger holds until the full-back is past him — the defender can't watch both."},
            home=[
                P(820, 800, "7", moves=[(820, 620, 1)]),            # winger holds, then inside
                P(820, 1050, "2", moves=[(880, 700, 0), (880, 380, 2)]),  # overlapping full-back
                P(500, 700, "10", moves=[(560, 400, 2)]),
                P(560, 950, "9", moves=[(520, 300, 3)]),
            ],
            away=[
                P(760, 700, "D", moves=[(800, 560, 1)]),
                P(560, 480, "C"),
            ],
            ball=0,
        ),
        Drill(
            id="third_man_run", category="attacking", minutes=12,
            name={"en": "Third-man run", "zh-CN": "第三人跑动", "zh-TW": "第三人跑動",
                  "ja-JP": "サードマンラン", "ko-KR": "제3의 침투", "es-ES": "Tercer hombre",
                  "fr-FR": "Course du troisième homme", "id-ID": "Lari pemain ketiga", "ms-MY": "Larian pemain ketiga",
                  "th-TH": "การวิ่งของคนที่สาม", "vi-VN": "Chạy chỗ người thứ ba", "en-GB": "Third-man run"},
            note={"en": "The runner starts before the second pass, not after. If he waits, the space is already gone.",
                  "zh-CN": "第三人要在第二脚传球之前启动，不是之后。等球到了，空当就没了。",
                  "zh-TW": "第三人要在第二腳傳球之前啟動，不是之後。等球到了，空檔就沒了。",
                  "ja-JP": "3人目は2本目のパスの前に走り出す。待つとスペースは消える。",
                  "ko-KR": "세 번째 선수는 두 번째 패스 전에 출발한다. 기다리면 공간은 사라진다.",
                  "es-ES": "El tercer hombre arranca antes del segundo pase, no después.",
                  "fr-FR": "Le troisième homme part avant la deuxième passe, pas après.",
                  "id-ID": "Pemain ketiga berlari sebelum umpan kedua, bukan sesudah.",
                  "ms-MY": "Pemain ketiga berlari sebelum hantaran kedua, bukan selepas.",
                  "th-TH": "คนที่สามต้องออกตัวก่อนบอลจังหวะที่สอง ไม่ใช่หลังจากนั้น",
                  "vi-VN": "Người thứ ba chạy trước đường chuyền thứ hai, không phải sau.",
                  "en-GB": "The runner starts before the second pass, not after. If he waits, the space is already gone."},
            home=[
                P(300, 900, "6"),
                P(500, 700, "10", moves=[(430, 780, 0)]),          # drops to receive, lays off
                P(700, 950, "8", moves=[(700, 500, 0), (620, 320, 1)]),  # third man
            ],
            away=[P(520, 560, "C", moves=[(470, 660, 0)])],
            ball=0,
        ),
        Drill(
            id="switch_play", category="attacking", minutes=12,
            name={"en": "Switch the play", "zh-CN": "转移进攻", "zh-TW": "轉移進攻",
                  "ja-JP": "サイドチェンジ", "ko-KR": "방향 전환", "es-ES": "Cambio de orientación",
                  "fr-FR": "Renversement de jeu", "id-ID": "Pindah serangan", "ms-MY": "Tukar arah serangan",
                  "th-TH": "เปลี่ยนข้างเกม", "vi-VN": "Chuyển hướng tấn công", "en-GB": "Switch the play"},
            note={"en": "Draw them to one side first. A switch into a compact block just gives the ball away.",
                  "zh-CN": "先把对方拉到一边。对着密集防守转移，只是把球送出去。",
                  "zh-TW": "先把對方拉到一邊。對著密集防守轉移，只是把球送出去。",
                  "ja-JP": "まず一方に引きつける。密集した相手への展開はボールを渡すだけ。",
                  "ko-KR": "먼저 한쪽으로 끌어들여라. 밀집한 상대로의 전환은 공만 내주는 것이다.",
                  "es-ES": "Atráelos primero a un lado; cambiar contra un bloque junto es regalar el balón.",
                  "fr-FR": "Attire-les d'abord d'un côté : renverser sur un bloc compact, c'est perdre le ballon.",
                  "id-ID": "Tarik mereka ke satu sisi dulu. Pindah bola ke blok rapat hanya membuang bola.",
                  "ms-MY": "Tarik mereka ke satu sisi dahulu.",
                  "th-TH": "ดึงเขาไปด้านหนึ่งก่อน เปลี่ยนข้างใส่บล็อกที่แน่นคือการเสียบอล",
                  "vi-VN": "Kéo họ sang một bên trước. Chuyển cánh vào khối phòng ngự chặt là mất bóng.",
                  "en-GB": "Draw them to one side first. A switch into a compact block just gives the ball away."},
            home=[
                P(250, 900, "5"), P(180, 700, "3", moves=[(180, 560, 0)]),
                P(500, 800, "6", moves=[(500, 700, 0)]),
                P(820, 700, "7", moves=[(820, 460, 1)]),
                P(650, 500, "9"),
            ],
            away=[
                P(320, 760, "A", moves=[(250, 700, 0)]),
                P(430, 640, "B", moves=[(360, 620, 0)]),
                P(600, 620, "C", moves=[(520, 640, 0), (700, 560, 1)]),
            ],
            ball=0,
        ),

        # ── finishing ────────────────────────────────────────────────────────
        Drill(
            id="cutback_finish", category="finishing", minutes=12,
            name={"en": "Cutback finish", "zh-CN": "倒三角射门", "zh-TW": "倒三角射門",
                  "ja-JP": "マイナスの折り返し", "ko-KR": "컷백 마무리", "es-ES": "Pase atrás y remate",
                  "fr-FR": "Centre en retrait", "id-ID": "Umpan tarik dan penyelesaian", "ms-MY": "Hantaran tarik dan penamat",
                  "th-TH": "ตัดกลับแล้วจบสกอร์", "vi-VN": "Chuyền ngược và dứt điểm", "en-GB": "Cutback finish"},
            note={"en": "Three runners: near post, penalty spot, edge of the box. The cutback goes behind the first.",
                  "zh-CN": "三条跑动线路：近门柱、点球点、禁区弧顶。倒三角要传到第一个人身后。",
                  "zh-TW": "三條跑動路線：近門柱、罰球點、禁區弧頂。倒三角要傳到第一個人身後。",
                  "ja-JP": "3人が走る：ニア、PKスポット、ボックス外。折り返しは1人目の後ろへ。",
                  "ko-KR": "세 명의 침투: 니어포스트, 페널티 스폿, 박스 외곽. 컷백은 첫 번째 선수 뒤로.",
                  "es-ES": "Tres llegadas: primer palo, punto de penalti, frontal. El pase atrás va detrás del primero.",
                  "fr-FR": "Trois appels : premier poteau, point de penalty, entrée de surface. Le retrait passe derrière le premier.",
                  "id-ID": "Tiga pelari: tiang dekat, titik penalti, tepi kotak. Umpan tarik di belakang yang pertama.",
                  "ms-MY": "Tiga pelari: tiang dekat, titik penalti, tepi kotak.",
                  "th-TH": "สามคนวิ่ง: เสาแรก จุดโทษ ขอบกรอบ บอลตัดกลับไปหลังคนแรก",
                  "vi-VN": "Ba người chạy: cột gần, chấm phạt đền, rìa vòng cấm. Bóng chuyền ngược sau người thứ nhất.",
                  "en-GB": "Three runners: near post, penalty spot, edge of the box. The cutback goes behind the first."},
            home=[
                P(850, 500, "7", moves=[(850, 300, 0), (700, 330, 1)]),   # wide, to the byline, cutback
                P(600, 620, "9", moves=[(560, 220, 1)]),                  # near post
                P(500, 700, "10", moves=[(500, 330, 1)]),                 # penalty spot
                P(420, 800, "8", moves=[(460, 430, 1)]),                  # edge of the box
            ],
            away=[P(560, 300, "D"), P(480, 260, "E")],
            markers=[M(500, 120, "square", "")],
            ball=0,
        ),
        Drill(
            id="one_v_one_gk", category="finishing", minutes=10,
            name={"en": "1v1 with the keeper", "zh-CN": "单刀对门将", "zh-TW": "單刀對門將",
                  "ja-JP": "GKとの1対1", "ko-KR": "골키퍼와 1대1", "es-ES": "1v1 con el portero",
                  "fr-FR": "1c1 face au gardien", "id-ID": "1v1 dengan kiper", "ms-MY": "1v1 dengan penjaga gol",
                  "th-TH": "1v1 กับผู้รักษาประตู", "vi-VN": "1v1 với thủ môn", "en-GB": "1v1 with the keeper"},
            note={"en": "Decide early: shot across the keeper, or take him out of it with one touch wide.",
                  "zh-CN": "早做决定：要么打门将远角，要么一脚推向侧面把他晃开。",
                  "zh-TW": "早做決定：要麼打門將遠角，要麼一腳推向側面把他晃開。",
                  "ja-JP": "早く決める：GKの逆を突く一撃か、横に外して外す。",
                  "ko-KR": "빨리 결정하라: 골키퍼 반대편 슈팅이냐, 한 번에 옆으로 제치느냐.",
                  "es-ES": "Decide pronto: disparo cruzado o un toque al costado para superarlo.",
                  "fr-FR": "Décide tôt : frappe croisée, ou une touche sur le côté pour l'éliminer.",
                  "id-ID": "Putuskan lebih awal: tembak silang, atau satu sentuhan ke samping.",
                  "ms-MY": "Buat keputusan awal: tendang silang, atau satu sentuhan ke tepi.",
                  "th-TH": "ตัดสินใจเร็ว: ยิงตัดเสา หรือเขี่ยออกข้างเพื่อผ่านผู้รักษาประตู",
                  "vi-VN": "Quyết định sớm: sút chéo góc, hoặc đẩy bóng sang bên vượt qua thủ môn.",
                  "en-GB": "Decide early: shot across the keeper, or take him out of it with one touch wide."},
            home=[P(500, 900, "9", moves=[(500, 600, 0), (560, 380, 1)])],
            away=[P(500, 200, "GK", role="GK", moves=[(500, 330, 1)])],
            markers=[M(500, 120, "square", "")],
            ball=0,
        ),

        # ── defending ────────────────────────────────────────────────────────
        Drill(
            id="press_trigger", category="defending", minutes=12,
            name={"en": "Pressing trigger", "zh-CN": "压迫触发点", "zh-TW": "壓迫觸發點",
                  "ja-JP": "プレスのスイッチ", "ko-KR": "압박 트리거", "es-ES": "Gatillo de presión",
                  "fr-FR": "Signal de pressing", "id-ID": "Pemicu pressing", "ms-MY": "Pencetus tekanan",
                  "th-TH": "จังหวะเริ่มกดดัน", "vi-VN": "Tín hiệu pressing", "en-GB": "Pressing trigger"},
            note={"en": "The trigger is a pass backwards or a bad first touch. First man closes the ball, the rest close the passing lanes.",
                  "zh-CN": "触发点是回传球或一次糟糕的停球。第一个人上抢球，其余人封传球路线。",
                  "zh-TW": "觸發點是回傳球或一次糟糕的停球。第一個人上搶球，其餘人封傳球路線。",
                  "ja-JP": "スイッチはバックパスかトラップミス。1人目がボールへ、他はパスコースを消す。",
                  "ko-KR": "트리거는 백패스나 나쁜 첫 터치. 첫 번째가 공을 압박하고 나머지는 패스 길을 막는다.",
                  "es-ES": "El gatillo es un pase atrás o un mal control. El primero va al balón, el resto tapa líneas.",
                  "fr-FR": "Le signal : passe en retrait ou mauvais contrôle. Le premier va au ballon, les autres ferment les lignes.",
                  "id-ID": "Pemicunya umpan ke belakang atau kontrol buruk. Yang pertama menekan bola, lainnya menutup jalur.",
                  "ms-MY": "Pencetusnya hantaran ke belakang atau kawalan lemah.",
                  "th-TH": "ทริกเกอร์คือบอลย้อนหลังหรือการหยุดบอลพลาด คนแรกเข้าบอล คนอื่นปิดเส้นทางจ่าย",
                  "vi-VN": "Tín hiệu là đường chuyền về hoặc chạm bóng hỏng. Người đầu ép bóng, phần còn lại chặn hướng chuyền.",
                  "en-GB": "The trigger is a pass backwards or a bad first touch. First man closes the ball, the rest close the passing lanes."},
            home=[
                P(500, 620, "9", moves=[(500, 460, 1)]),
                P(300, 700, "11", moves=[(360, 560, 1)]),
                P(700, 700, "7", moves=[(640, 560, 1)]),
                P(500, 850, "8", moves=[(500, 700, 1)]),
            ],
            away=[
                P(500, 420, "6", moves=[(500, 330, 0)]),
                P(300, 350, "5"), P(700, 350, "4"),
            ],
            ball=None,
        ),
        Drill(
            id="defend_2v2", category="defending", minutes=12,
            name={"en": "2v2 recovery", "zh-CN": "2v2 回追防守", "zh-TW": "2v2 回追防守",
                  "ja-JP": "2対2 リカバリー", "ko-KR": "2대2 회복 수비", "es-ES": "Repliegue 2v2",
                  "fr-FR": "Repli 2c2", "id-ID": "Pemulihan 2v2", "ms-MY": "Pemulihan 2v2",
                  "th-TH": "ถอยกลับ 2v2", "vi-VN": "Lùi về 2v2", "en-GB": "2v2 recovery"},
            note={"en": "First defender delays, second covers the inside. Never both at the ball.",
                  "zh-CN": "第一防守人延缓，第二人保护内侧。两个人不能同时扑球。",
                  "zh-TW": "第一防守人延緩，第二人保護內側。兩個人不能同時撲球。",
                  "ja-JP": "1人目は遅らせ、2人目は内側をカバー。二人同時にボールへ行かない。",
                  "ko-KR": "첫 수비는 지연, 두 번째는 안쪽 커버. 둘이 동시에 공에 가지 마라.",
                  "es-ES": "El primer defensor retrasa, el segundo cubre por dentro. Nunca los dos al balón.",
                  "fr-FR": "Le premier temporise, le second couvre l'intérieur. Jamais les deux sur le ballon.",
                  "id-ID": "Bek pertama menunda, kedua menutup sisi dalam. Jangan keduanya ke bola.",
                  "ms-MY": "Bek pertama melengahkan, kedua menutup dalam.",
                  "th-TH": "คนแรกหน่วงเวลา คนที่สองคุมด้านใน อย่าเข้าบอลพร้อมกัน",
                  "vi-VN": "Hậu vệ thứ nhất trì hoãn, thứ hai bọc lót bên trong. Không cùng lao vào bóng.",
                  "en-GB": "First defender delays, second covers the inside. Never both at the ball."},
            home=[
                P(400, 500, "4", moves=[(430, 640, 0)]),
                P(600, 500, "5", moves=[(540, 700, 1)]),
            ],
            away=[
                P(380, 900, "9", moves=[(400, 720, 0)]),
                P(620, 900, "10", moves=[(600, 760, 1)]),
            ],
            ball=None,
        ),

        # ── set pieces ───────────────────────────────────────────────────────
        Drill(
            id="corner_near_post", category="setpiece", minutes=10,
            name={"en": "Corner: near post", "zh-CN": "角球：近门柱", "zh-TW": "角球：近門柱",
                  "ja-JP": "CK：ニアポスト", "ko-KR": "코너킥: 니어포스트", "es-ES": "Córner al primer palo",
                  "fr-FR": "Corner premier poteau", "id-ID": "Sepak pojok tiang dekat", "ms-MY": "Penjuru tiang dekat",
                  "th-TH": "เตะมุม: เสาแรก", "vi-VN": "Phạt góc: cột gần", "en-GB": "Corner: near post"},
            note={"en": "Two decoys pull the markers back, the near-post runner attacks the ball in front of them.",
                  "zh-CN": "两个人做诱饵把盯人拉向后点，近门柱的人从他们身前抢点。",
                  "zh-TW": "兩個人做誘餌把盯人拉向後點，近門柱的人從他們身前搶點。",
                  "ja-JP": "2人がおとりでマーカーを後ろに引き、ニアの選手がその前でボールに入る。",
                  "ko-KR": "두 명이 미끼로 수비를 뒤로 끌고, 니어포스트 선수가 그 앞에서 공을 잡는다.",
                  "es-ES": "Dos señuelos arrastran a los marcadores atrás; el del primer palo ataca por delante.",
                  "fr-FR": "Deux leurres attirent les marqueurs en arrière ; le joueur au premier poteau attaque devant eux.",
                  "id-ID": "Dua umpan tarik menarik penjaga ke belakang, pelari tiang dekat menyambut di depan.",
                  "ms-MY": "Dua umpan menarik penjaga ke belakang, pelari tiang dekat menyambut di depan.",
                  "th-TH": "สองคนล่อให้กองหลังถอย คนเสาแรกเข้าชิงบอลด้านหน้า",
                  "vi-VN": "Hai người nhử kéo hậu vệ lùi, người ở cột gần đón bóng phía trước.",
                  "en-GB": "Two decoys pull the markers back, the near-post runner attacks the ball in front of them."},
            home=[
                P(940, 140, "7", moves=[]),                       # corner taker
                P(620, 400, "9", moves=[(620, 300, 0), (700, 210, 1)]),   # near post run
                P(500, 420, "5", moves=[(430, 300, 0)]),          # decoy
                P(420, 400, "6", moves=[(360, 320, 0)]),          # decoy
                P(560, 560, "8", moves=[(540, 420, 1)]),          # edge of the box
            ],
            away=[
                P(700, 250, "A"), P(560, 260, "B"), P(460, 260, "C"),
                P(500, 180, "GK", role="GK"),
            ],
            markers=[M(500, 120, "square", "")],
            ball=0,
        ),
        Drill(
            id="free_kick_edge", category="setpiece", minutes=10,
            name={"en": "Free kick: edge of the box", "zh-CN": "禁区前任意球", "zh-TW": "禁區前任意球",
                  "ja-JP": "FK：ボックス手前", "ko-KR": "프리킥: 박스 외곽", "es-ES": "Falta al borde del área",
                  "fr-FR": "Coup franc à l'entrée", "id-ID": "Tendangan bebas tepi kotak", "ms-MY": "Sepakan percuma tepi kotak",
                  "th-TH": "ฟรีคิกขอบกรอบเขตโทษ", "vi-VN": "Đá phạt rìa vòng cấm", "en-GB": "Free kick: edge of the box"},
            note={"en": "Two over the ball. The runner across the wall is the shot; the strike is the decoy as often as not.",
                  "zh-CN": "两人站位。横穿人墙的跑动才是主攻手，直接射门往往只是幌子。",
                  "zh-TW": "兩人站位。橫穿人牆的跑動才是主攻手，直接射門往往只是幌子。",
                  "ja-JP": "2人がボールの上に。壁を横切るランが本命、直接シュートは囮のことが多い。",
                  "ko-KR": "두 명이 공 앞에. 벽을 가로지르는 침투가 진짜 슛, 직접 슛은 미끼일 때가 많다.",
                  "es-ES": "Dos sobre el balón. La carrera por delante de la barrera es el remate; el disparo suele ser el señuelo.",
                  "fr-FR": "Deux sur le ballon. La course devant le mur est la frappe ; le tir direct est souvent le leurre.",
                  "id-ID": "Dua orang di atas bola. Larian melewati pagar betis itu tembakannya.",
                  "ms-MY": "Dua orang di atas bola. Larian melintasi pagar adalah tendangan sebenar.",
                  "th-TH": "สองคนยืนที่บอล คนที่วิ่งตัดหน้ากำแพงคือคนยิงจริง",
                  "vi-VN": "Hai người đứng bóng. Người chạy cắt qua hàng rào mới là người dứt điểm.",
                  "en-GB": "Two over the ball. The runner across the wall is the shot; the strike is the decoy as often as not."},
            home=[
                P(470, 520, "10"), P(530, 520, "7", moves=[(560, 470, 0)]),
                P(700, 560, "8", moves=[(560, 400, 0), (500, 300, 1)]),
            ],
            away=[
                P(440, 380, "W1"), P(480, 380, "W2"), P(520, 380, "W3"), P(560, 380, "W4"),
                P(500, 180, "GK", role="GK"),
            ],
            markers=[M(500, 120, "square", "")],
            ball=0,
        ),

        # ── small-sided games ────────────────────────────────────────────────
        Drill(
            id="ssg_4v4_four_goals", category="ssg", minutes=20,
            name={"en": "4v4, four goals", "zh-CN": "4v4 四门球", "zh-TW": "4v4 四門球",
                  "ja-JP": "4対4 4ゴール", "ko-KR": "4대4 네 골대", "es-ES": "4v4 a cuatro porterías",
                  "fr-FR": "4c4 quatre buts", "id-ID": "4v4 empat gawang", "ms-MY": "4v4 empat gol",
                  "th-TH": "4v4 สี่ประตู", "vi-VN": "4v4 bốn khung thành", "en-GB": "4v4, four goals"},
            note={"en": "Two goals each forces a switch: attack the one they left open, not the one in front of you.",
                  "zh-CN": "每队两个球门，逼着你转移：攻他们放空的那个，不是眼前那个。",
                  "zh-TW": "每隊兩個球門，逼著你轉移：攻他們放空的那個，不是眼前那個。",
                  "ja-JP": "各チーム2ゴールで展開が必要になる。目の前ではなく、空いた方を狙う。",
                  "ko-KR": "각 팀 두 골대가 전환을 강제한다. 눈앞이 아니라 비어 있는 쪽을 노려라.",
                  "es-ES": "Dos porterías por equipo obligan a cambiar: ataca la que dejaron libre.",
                  "fr-FR": "Deux buts par équipe forcent le renversement : attaque celui qu'ils ont laissé.",
                  "id-ID": "Dua gawang per tim memaksa perpindahan: serang yang mereka tinggalkan.",
                  "ms-MY": "Dua gol setiap pasukan memaksa pertukaran sisi.",
                  "th-TH": "ทีมละสองประตูบังคับให้เปลี่ยนข้าง โจมตีประตูที่เขาทิ้งว่าง",
                  "vi-VN": "Mỗi đội hai khung thành buộc phải chuyển hướng: tấn công nơi họ bỏ trống.",
                  "en-GB": "Two goals each forces a switch: attack the one they left open, not the one in front of you."},
            home=[
                P(350, 850, "1", moves=[(300, 700, 0)]), P(650, 850, "2"),
                P(350, 1050, "3"), P(650, 1050, "4", moves=[(760, 900, 1)]),
            ],
            away=[
                P(350, 550, "A", moves=[(320, 680, 0)]), P(650, 550, "B"),
                P(350, 350, "C"), P(650, 350, "D"),
            ],
            markers=[
                M(250, 250, "square"), M(750, 250, "square"),
                M(250, 1150, "square"), M(750, 1150, "square"),
                M(200, 200), M(800, 200), M(200, 1200), M(800, 1200),
            ],
            ball=0,
        ),
    ]


CATALOGUE = {"soccer": soccer_drills}


def build(sport: str) -> dict:
    drills = CATALOGUE[sport]()
    ids = [d.id for d in drills]
    assert len(ids) == len(set(ids)), f"duplicate drill id in {sport}"
    return {
        "sport": sport,
        "version": 1,
        "drills": [
            {
                "id": d.id,
                "category": d.category,
                "minutes": d.minutes,
                "players": d.player_count,
                "name": d.name,
                "note": d.note,
                "board": build_board(d, sport),
            }
            for d in drills
        ],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true",
                    help="fail if the checked-in assets differ from this file")
    args = ap.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    failed = False
    for sport in CATALOGUE:
        payload = json.dumps(build(sport), ensure_ascii=False, indent=2) + "\n"
        path = OUT_DIR / f"{sport}.json"
        if args.check:
            current = path.read_text(encoding="utf-8") if path.exists() else ""
            if current != payload:
                print(f"✗ {path.relative_to(REPO)} is stale — run tools/gen_drills.py")
                failed = True
            else:
                print(f"✓ {path.relative_to(REPO)}")
        else:
            path.write_text(payload, encoding="utf-8")
            n = len(json.loads(payload)["drills"])
            print(f"{path.relative_to(REPO)}: {n} drills")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
