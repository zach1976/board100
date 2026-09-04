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

SPORT_INDEX = {"soccer": 6, "basketball": 3}

# Court geometry, mirroring SportType.fieldRect: the playing surface is
# centred in the canvas at a fixed aspect, so a basketball court leaves far
# more dead canvas at the sides than a football pitch does. Sports authored
# with rel=True give coordinates inside the court (0..1) and are mapped here,
# which is the only way to be sure a player isn't standing in the margin.
COURT_ASPECT = {"soccer": 68 / 105, "basketball": 15 / 28}
COURT_SCALE = {"soccer": 0.90, "basketball": 0.90}


def court_rect(sport: str) -> tuple[float, float, float, float]:
    aspect, scale = COURT_ASPECT[sport], COURT_SCALE[sport]
    if CANVAS_W / CANVAS_H > aspect:
        ch = CANVAS_H * scale
        cw = ch * aspect
    else:
        cw = CANVAS_W * scale
        ch = cw / aspect
    return ((CANVAS_W - cw) / 2, (CANVAS_H - ch) / 2, cw, ch)

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
    # Coordinates are relative to the court (0..1), not the canvas. Used by
    # every sport after soccer — soccer was authored in canvas coordinates,
    # where the pitch fills all but 6% of the width so it made little
    # difference. Anything narrower (a basketball court leaves 14% margins)
    # needs this or players stand off the floor.
    rel: bool = False
    # Some drills legitimately place a player off the playing surface: the
    # thrower at a throw-in stands behind the touchline, by the rules. Marked
    # so the "everyone is on the pitch" check can stay strict for the rest.
    off_surface: bool = False
    # In the free tier. The free set is chosen so a coach can run a whole
    # session on it — warm-up through small-sided game — because a starter
    # library that can't start anything is an advert, not a starter library.
    free: bool = False

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


def to_canvas(drill: Drill, sport: str) -> None:
    """Map a rel=True drill's court coordinates onto the canvas, in place."""
    if not drill.rel:
        return
    left, top, w, h = court_rect(sport)
    def fx(x): return left + x * w
    def fy(y): return top + y * h
    for p in drill.home + drill.away:
        p.x, p.y = fx(p.x), fy(p.y)
        p.moves = [(fx(mx), fy(my), ph) for (mx, my, ph) in p.moves]
    for m in drill.markers:
        m.x, m.y = fx(m.x), fy(m.y)
    if isinstance(drill.ball, tuple):
        drill.ball = (fx(drill.ball[0]), fy(drill.ball[1]))
    drill.rel = False


def build_board(drill: Drill, sport: str) -> dict:
    normalise_phases(drill)
    to_canvas(drill, sport)
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
            free=True,
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
            free=True,
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
            free=True,
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
            free=True,
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
            free=True,
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
            free=True,
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
            free=True,
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
            free=True,
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
            free=True,
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
            free=True,
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
            free=True,
        ),
        # ── warm-up ──────────────────────────────────────────────────────────
        Drill(
            id="warmup_y_pattern", category="warmup", minutes=8,
            name={"en": "Y-pattern passing", "en-GB": "Y-pattern passing", "zh-CN": "Y 字传球",
                  "zh-TW": "Y 字傳球", "ja-JP": "Yパターンパス", "ko-KR": "Y자 패스",
                  "es-ES": "Pase en Y", "fr-FR": "Passes en Y", "id-ID": "Umpan pola Y",
                  "ms-MY": "Hantaran corak Y", "th-TH": "จ่ายบอลรูปตัว Y", "vi-VN": "Chuyền hình chữ Y"},
            note={"en": "Set, back, spread. The lay-off is one touch or the pattern stalls.",
                  "en-GB": "Set, back, spread. The lay-off is one touch or the pattern stalls.",
                  "zh-CN": "做球、回做、分边。回做必须一脚出球，否则节奏就断了。",
                  "zh-TW": "做球、回做、分邊。回做必須一腳出球，否則節奏就斷了。",
                  "ja-JP": "当てて、落として、開く。落としは1タッチでないと止まる。",
                  "ko-KR": "대고, 내주고, 벌린다. 내주는 패스는 원터치라야 흐름이 산다.",
                  "es-ES": "Apoyo, descarga, apertura. La descarga es a un toque o se atasca.",
                  "fr-FR": "Appui, remise, écartement. La remise se fait à une touche.",
                  "id-ID": "Sentuh, kembalikan, lebarkan. Umpan balik harus satu sentuhan.",
                  "ms-MY": "Sentuh, pulangkan, luaskan. Hantaran balik mesti satu sentuhan.",
                  "th-TH": "ชน วางกลับ แล้วเปิดออก บอลวางกลับต้องแตะเดียว",
                  "vi-VN": "Đệm, trả, mở biên. Đường trả phải một chạm."},
            home=[
                P(500, 1100, "1", moves=[(500, 950, 0)]),
                P(500, 800, "2", moves=[(500, 900, 0)]),
                P(760, 640, "3", moves=[(760, 500, 1)]),
                P(240, 640, "4", moves=[(240, 500, 1)]),
            ],
            markers=[M(500, 1120), M(500, 780), M(780, 620), M(220, 620)],
            ball=0,
        ),
        Drill(
            id="warmup_first_touch_gate", category="warmup", minutes=8,
            name={"en": "First-touch gates", "en-GB": "First-touch gates", "zh-CN": "停球过门",
                  "zh-TW": "停球過門", "ja-JP": "ファーストタッチゲート", "ko-KR": "퍼스트 터치 게이트",
                  "es-ES": "Puertas de control", "fr-FR": "Portes de contrôle", "id-ID": "Gerbang sentuhan pertama",
                  "ms-MY": "Pintu sentuhan pertama", "th-TH": "ประตูจังหวะแรก", "vi-VN": "Cổng chạm đầu"},
            note={"en": "Receive across your body so the first touch already faces the next gate.",
                  "en-GB": "Receive across your body so the first touch already faces the next gate.",
                  "zh-CN": "侧身接球，第一脚就把球停向下一个门 —— 别停完再转身。",
                  "zh-TW": "側身接球，第一腳就把球停向下一個門 —— 別停完再轉身。",
                  "ja-JP": "体を斜めに開いて受け、ファーストタッチで次のゲートを向く。",
                  "ko-KR": "몸을 열어 받아 첫 터치가 다음 게이트를 향하게 하라.",
                  "es-ES": "Recibe de perfil: el primer control ya mira a la siguiente puerta.",
                  "fr-FR": "Reçois de profil : le premier contrôle oriente déjà vers la porte suivante.",
                  "id-ID": "Terima menyamping agar sentuhan pertama sudah menghadap gerbang berikutnya.",
                  "ms-MY": "Terima secara menyerong supaya sentuhan pertama menghadap pintu seterusnya.",
                  "th-TH": "รับบอลด้วยลำตัวเปิด ให้จังหวะแรกหันไปยังประตูถัดไป",
                  "vi-VN": "Nhận bóng mở người để chạm đầu đã hướng tới cổng kế tiếp."},
            home=[
                P(300, 1000, "1", moves=[(500, 850, 0), (700, 700, 1), (500, 520, 2)]),
                P(700, 1000, "2"),
            ],
            markers=[M(440, 880), M(560, 880), M(640, 730), M(760, 730), M(440, 550), M(560, 550)],
            ball=0,
            free=True,
        ),

        # ── possession ───────────────────────────────────────────────────────
        Drill(
            id="rondo_5v2_split", category="possession", minutes=12,
            name={"en": "Rondo 5v2 — split pass", "en-GB": "Rondo 5v2 — split pass", "zh-CN": "5v2 抢圈：穿裆直塞",
                  "zh-TW": "5v2 搶圈：穿襠直塞", "ja-JP": "5対2 ロンド：割るパス", "ko-KR": "5대2 론도 — 가르는 패스",
                  "es-ES": "Rondo 5v2 — pase interior", "fr-FR": "Rondo 5c2 — passe dans l'axe",
                  "id-ID": "Rondo 5v2 — umpan belah", "ms-MY": "Rondo 5v2 — hantaran belah",
                  "th-TH": "รอนโด 5v2 — บอลผ่ากลาง", "vi-VN": "Rondo 5v2 — chuyền xẻ nách"},
            note={"en": "A pass between the two defenders counts double. It only exists for a moment after they step.",
                  "en-GB": "A pass between the two defenders counts double. It only exists for a moment after they step.",
                  "zh-CN": "从两个防守人之间穿过算两分。那条线只在他们上抢的一瞬间存在。",
                  "zh-TW": "從兩個防守人之間穿過算兩分。那條線只在他們上搶的一瞬間存在。",
                  "ja-JP": "2人の間を通すパスは2点。相手が出た直後の一瞬しか開かない。",
                  "ko-KR": "두 수비 사이를 가르는 패스는 2점. 그들이 나온 직후 잠깐만 열린다.",
                  "es-ES": "El pase entre los dos defensores vale doble; solo existe un instante tras su salida.",
                  "fr-FR": "La passe entre les deux défenseurs compte double : elle n'existe qu'un instant.",
                  "id-ID": "Umpan di antara dua bek bernilai ganda; hanya ada sesaat setelah mereka maju.",
                  "ms-MY": "Hantaran antara dua bek bernilai dua kali ganda.",
                  "th-TH": "บอลที่ผ่ากลางระหว่างสองกองหลังนับสองแต้ม มีช่องแค่ชั่วขณะ",
                  "vi-VN": "Đường chuyền xuyên giữa hai hậu vệ tính điểm đôi, chỉ mở ra trong khoảnh khắc."},
            home=[
                P(500, 480, "1", moves=[(560, 520, 0)]),
                P(780, 640, "2"), P(700, 900, "3", moves=[(640, 860, 1)]),
                P(300, 900, "4"), P(220, 640, "5"),
            ],
            away=[
                P(430, 680, "A", moves=[(500, 600, 0)]),
                P(570, 780, "B", moves=[(560, 700, 1)]),
            ],
            markers=[M(480, 460), M(800, 620), M(720, 920), M(280, 920), M(200, 620)],
            ball=0,
        ),
        Drill(
            id="possession_3_zone", category="possession", minutes=15,
            name={"en": "Three-zone possession", "en-GB": "Three-zone possession", "zh-CN": "三区控球",
                  "zh-TW": "三區控球", "ja-JP": "3ゾーンポゼッション", "ko-KR": "3구역 점유",
                  "es-ES": "Posesión en tres zonas", "fr-FR": "Conservation en trois zones",
                  "id-ID": "Penguasaan tiga zona", "ms-MY": "Penguasaan tiga zon",
                  "th-TH": "ครองบอลสามโซน", "vi-VN": "Giữ bóng ba khu"},
            note={"en": "You can only score by playing through the middle zone, never around it.",
                  "en-GB": "You can only score by playing through the middle zone, never around it.",
                  "zh-CN": "只有球穿过中间区才算得分 —— 绕过去不算。",
                  "zh-TW": "只有球穿過中間區才算得分 —— 繞過去不算。",
                  "ja-JP": "中央ゾーンを通したときだけ得点。外を回るのは無効。",
                  "ko-KR": "가운데 구역을 통과해야만 득점. 돌아가는 것은 인정되지 않는다.",
                  "es-ES": "Solo puntúa el balón que pasa por la zona central, nunca por fuera.",
                  "fr-FR": "On ne marque qu'en passant par la zone centrale, jamais autour.",
                  "id-ID": "Poin hanya sah jika bola melewati zona tengah, bukan memutar.",
                  "ms-MY": "Mata hanya sah jika bola melalui zon tengah.",
                  "th-TH": "ทำแต้มได้เฉพาะเมื่อบอลผ่านโซนกลาง ห้ามอ้อม",
                  "vi-VN": "Chỉ ghi điểm khi bóng đi qua khu giữa, không được vòng ngoài."},
            home=[
                P(300, 1150, "1", moves=[(380, 1050, 0)]), P(700, 1150, "2"),
                P(500, 750, "3", moves=[(560, 800, 0), (560, 600, 1)]),
                P(300, 350, "4"), P(700, 350, "5", moves=[(640, 450, 1)]),
            ],
            away=[
                P(420, 950, "A", moves=[(440, 1030, 0)]),
                P(580, 620, "B", moves=[(560, 700, 1)]),
            ],
            markers=[M(120, 950, "zone"), M(880, 950, "zone"), M(120, 550, "zone"), M(880, 550, "zone")],
            ball=0,
        ),
        Drill(
            id="build_from_gk", category="possession", minutes=15,
            name={"en": "Building from the keeper", "en-GB": "Building from the keeper", "zh-CN": "门将脚下出球",
                  "zh-TW": "門將腳下出球", "ja-JP": "GKからのビルドアップ", "ko-KR": "골키퍼부터 빌드업",
                  "es-ES": "Salida desde el portero", "fr-FR": "Relance depuis le gardien",
                  "id-ID": "Membangun dari kiper", "ms-MY": "Bina dari penjaga gol",
                  "th-TH": "เปิดเกมจากผู้รักษาประตู", "vi-VN": "Triển khai từ thủ môn"},
            note={"en": "Centre-backs split wide of the box first. If they stay close, the keeper has no angle to play.",
                  "en-GB": "Centre-backs split wide of the box first. If they stay close, the keeper has no angle to play.",
                  "zh-CN": "中卫先拉开到禁区两侧。站得太近，门将根本没有出球角度。",
                  "zh-TW": "中衛先拉開到禁區兩側。站得太近，門將根本沒有出球角度。",
                  "ja-JP": "CBはまずボックス外へ開く。近すぎるとGKの出しどころがない。",
                  "ko-KR": "센터백이 먼저 박스 밖으로 벌린다. 붙어 있으면 골키퍼가 낼 각이 없다.",
                  "es-ES": "Los centrales se abren fuera del área; si están juntos, el portero no tiene ángulo.",
                  "fr-FR": "Les centraux s'écartent hors de la surface, sinon le gardien n'a aucun angle.",
                  "id-ID": "Bek tengah melebar keluar kotak dulu; jika rapat, kiper tak punya sudut.",
                  "ms-MY": "Bek tengah melebar keluar kotak dahulu.",
                  "th-TH": "เซ็นเตอร์แบ็กต้องถ่างออกนอกกรอบก่อน ไม่งั้นผู้รักษาประตูไม่มีมุมจ่าย",
                  "vi-VN": "Trung vệ dạt rộng ra ngoài vòng cấm trước, nếu đứng gần thủ môn không có góc chuyền."},
            home=[
                P(500, 1350, "GK", role="GK"),
                P(320, 1200, "4", role="LCB", moves=[(220, 1150, 0)]),
                P(680, 1200, "5", role="RCB", moves=[(780, 1150, 0)]),
                P(500, 1050, "6", role="CDM", moves=[(500, 980, 1)]),
                P(180, 900, "3", role="LB", moves=[(160, 780, 1)]),
                P(820, 900, "2", role="RB", moves=[(840, 780, 1)]),
            ],
            away=[
                P(430, 1120, "9", moves=[(330, 1120, 0)]),
                P(570, 1000, "10", moves=[(520, 1040, 1)]),
            ],
            ball=0,
        ),

        # ── attacking ────────────────────────────────────────────────────────
        Drill(
            id="wall_pass_wide", category="attacking", minutes=10,
            name={"en": "Wall pass on the wing", "en-GB": "Wall pass on the wing", "zh-CN": "边路撞墙配合",
                  "zh-TW": "邊路撞牆配合", "ja-JP": "サイドのワンツー", "ko-KR": "측면 월패스",
                  "es-ES": "Pared por la banda", "fr-FR": "Une-deux sur l'aile",
                  "id-ID": "Umpan satu dua di sayap", "ms-MY": "Hantaran dinding di sayap",
                  "th-TH": "วันทูที่ริมเส้น", "vi-VN": "Phối hợp một-hai biên"},
            note={"en": "Run past the defender before you pass, not after — the wall player returns it into space, not to feet.",
                  "en-GB": "Run past the defender before you pass, not after — the wall player returns it into space, not to feet.",
                  "zh-CN": "先启动再出球，不是传完才跑 —— 墙的回球要送到空当，不是脚下。",
                  "zh-TW": "先啟動再出球，不是傳完才跑 —— 牆的回球要送到空檔，不是腳下。",
                  "ja-JP": "パス前に相手を追い越す。壁役はスペースへ返す、足元ではない。",
                  "ko-KR": "패스 전에 수비를 지나쳐 뛰어라. 벽 역할은 발밑이 아니라 공간으로 돌려준다.",
                  "es-ES": "Arranca antes de pasar; la pared devuelve al espacio, no al pie.",
                  "fr-FR": "Pars avant de passer ; le mur remet dans l'espace, pas dans les pieds.",
                  "id-ID": "Berlari melewati bek sebelum mengumpan; bola dikembalikan ke ruang, bukan ke kaki.",
                  "ms-MY": "Lari melepasi bek sebelum menghantar; bola dipulangkan ke ruang.",
                  "th-TH": "วิ่งแซงกองหลังก่อนจ่าย บอลคืนต้องไปที่พื้นที่ ไม่ใช่ที่เท้า",
                  "vi-VN": "Chạy vượt hậu vệ trước khi chuyền; bóng trả vào khoảng trống, không vào chân."},
            home=[
                P(830, 900, "7", moves=[(830, 700, 0), (830, 480, 1)]),
                P(640, 760, "10", moves=[(660, 700, 0)]),
            ],
            away=[P(800, 780, "D", moves=[(780, 700, 0)])],
            ball=0,
        ),
        Drill(
            id="counter_3v2", category="attacking", minutes=12,
            name={"en": "3v2 counter", "en-GB": "3v2 counter", "zh-CN": "3v2 快速反击",
                  "zh-TW": "3v2 快速反擊", "ja-JP": "3対2 カウンター", "ko-KR": "3대2 역습",
                  "es-ES": "Contragolpe 3v2", "fr-FR": "Contre 3c2", "id-ID": "Serangan balik 3v2",
                  "ms-MY": "Serangan balas 3v2", "th-TH": "สวนกลับ 3v2", "vi-VN": "Phản công 3v2"},
            note={"en": "Carry until a defender commits, then release. Passing early turns 3v2 back into 3v3.",
                  "en-GB": "Carry until a defender commits, then release. Passing early turns 3v2 back into 3v3.",
                  "zh-CN": "带球逼到有人上抢再出球。传早了，3打2 就又变回 3打3。",
                  "zh-TW": "帶球逼到有人上搶再出球。傳早了，3打2 就又變回 3打3。",
                  "ja-JP": "相手が食いつくまで運んでから出す。早いパスは3対2を3対3に戻す。",
                  "ko-KR": "수비가 달려들 때까지 몰고 가서 내줘라. 일찍 주면 3대2가 3대3이 된다.",
                  "es-ES": "Conduce hasta que un defensa salga y entonces suelta; pasar pronto convierte el 3v2 en 3v3.",
                  "fr-FR": "Conduis jusqu'à ce qu'un défenseur sorte, puis donne. Trop tôt, le 3c2 redevient 3c3.",
                  "id-ID": "Giring sampai bek maju, baru lepaskan. Umpan terlalu cepat mengubah 3v2 jadi 3v3.",
                  "ms-MY": "Bawa bola sehingga bek maju, kemudian lepaskan.",
                  "th-TH": "เลี้ยงจนกองหลังออกมาแล้วค่อยจ่าย จ่ายเร็วไป 3v2 จะกลายเป็น 3v3",
                  "vi-VN": "Dẫn bóng đến khi hậu vệ lao ra rồi mới chuyền. Chuyền sớm biến 3v2 thành 3v3."},
            home=[
                P(500, 950, "9", moves=[(500, 680, 0), (500, 520, 1)]),
                P(260, 1000, "11", moves=[(300, 620, 0), (380, 420, 2)]),
                P(740, 1000, "7", moves=[(700, 620, 0), (620, 420, 2)]),
            ],
            away=[
                P(420, 620, "4", moves=[(470, 600, 1)]),
                P(580, 620, "5", moves=[(560, 520, 2)]),
            ],
            markers=[M(500, 120, "square", "")],
            ball=0,
        ),
        Drill(
            id="halfspace_run", category="attacking", minutes=12,
            name={"en": "Half-space run", "en-GB": "Half-space run", "zh-CN": "肋部插上",
                  "zh-TW": "肋部插上", "ja-JP": "ハーフスペースへのラン", "ko-KR": "하프스페이스 침투",
                  "es-ES": "Desmarque al medio espacio", "fr-FR": "Course dans le demi-espace",
                  "id-ID": "Lari ke half-space", "ms-MY": "Larian ke half-space",
                  "th-TH": "วิ่งเข้าฮาล์ฟสเปซ", "vi-VN": "Chạy vào nửa khoảng trống"},
            note={"en": "The winger holds the full-back wide; the run goes inside him, behind the centre-back.",
                  "en-GB": "The winger holds the full-back wide; the run goes inside him, behind the centre-back.",
                  "zh-CN": "边锋把边后卫钉在外侧，插上路线走他内侧、中卫身后。",
                  "zh-TW": "邊鋒把邊後衛釘在外側，插上路線走他內側、中衛身後。",
                  "ja-JP": "ウイングがSBを外に留め、ランはその内側、CBの背後へ。",
                  "ko-KR": "윙어가 풀백을 바깥에 묶고, 침투는 그 안쪽 센터백 뒤로.",
                  "es-ES": "El extremo fija al lateral por fuera; la carrera va por dentro, a la espalda del central.",
                  "fr-FR": "L'ailier fixe le latéral à l'extérieur ; la course passe à l'intérieur, dans le dos du central.",
                  "id-ID": "Sayap menahan bek sayap di luar; larian masuk ke dalam, di belakang bek tengah.",
                  "ms-MY": "Pemain sayap menahan bek di luar; larian masuk ke dalam.",
                  "th-TH": "ปีกตรึงแบ็กไว้ริมเส้น ส่วนคนวิ่งพุ่งด้านในหลังเซ็นเตอร์แบ็ก",
                  "vi-VN": "Tiền vệ cánh giữ hậu vệ biên ở ngoài; người chạy cắt vào trong, sau lưng trung vệ."},
            home=[
                P(500, 850, "6", moves=[(520, 800, 0)]),
                P(850, 700, "7"),
                P(680, 780, "8", moves=[(720, 560, 0), (700, 340, 1)]),
            ],
            away=[
                P(820, 620, "3", moves=[(830, 560, 0)]),
                P(640, 500, "4", moves=[(690, 460, 1)]),
            ],
            markers=[M(500, 120, "square", "")],
            ball=0,
        ),

        # ── finishing ────────────────────────────────────────────────────────
        Drill(
            id="finish_first_time", category="finishing", minutes=10,
            name={"en": "First-time finishing", "en-GB": "First-time finishing", "zh-CN": "一脚打门",
                  "zh-TW": "一腳打門", "ja-JP": "ダイレクトシュート", "ko-KR": "원터치 마무리",
                  "es-ES": "Remate de primeras", "fr-FR": "Frappe en une touche",
                  "id-ID": "Penyelesaian satu sentuhan", "ms-MY": "Penamat satu sentuhan",
                  "th-TH": "ยิงจังหวะแรก", "vi-VN": "Dứt điểm một chạm"},
            note={"en": "Body over the ball, side foot, low into the corner. Power is not the problem — placement is.",
                  "en-GB": "Body over the ball, side foot, low into the corner. Power is not the problem — placement is.",
                  "zh-CN": "身体压在球上，脚内侧推射死角贴地。问题从来不是力量，是位置。",
                  "zh-TW": "身體壓在球上，腳內側推射死角貼地。問題從來不是力量，是位置。",
                  "ja-JP": "体をボールの上に、インサイドで低くコーナーへ。強さではなくコース。",
                  "ko-KR": "몸을 공 위로, 인사이드로 낮게 구석으로. 문제는 힘이 아니라 코스다.",
                  "es-ES": "Cuerpo sobre el balón, interior, raso al palo. El problema no es la fuerza, es la colocación.",
                  "fr-FR": "Corps au-dessus du ballon, intérieur du pied, ras de terre. Ce n'est pas la puissance, c'est le placement.",
                  "id-ID": "Badan di atas bola, kaki bagian dalam, mendatar ke sudut. Bukan tenaga, tapi penempatan.",
                  "ms-MY": "Badan atas bola, kaki dalam, rendah ke sudut.",
                  "th-TH": "ลำตัวคร่อมบอล ใช้ข้างเท้ายิงต่ำเข้ามุม ไม่ใช่แรง แต่คือตำแหน่ง",
                  "vi-VN": "Người đổ trên bóng, má trong, sệt vào góc. Vấn đề không phải lực mà là điểm rơi."},
            home=[
                P(250, 620, "11", moves=[(300, 520, 0)]),
                P(520, 640, "9", moves=[(500, 480, 0), (500, 380, 1)]),
                P(750, 620, "7", moves=[(700, 520, 2)]),
            ],
            away=[P(500, 200, "GK", role="GK", moves=[(430, 260, 1)])],
            markers=[M(500, 120, "square", "")],
            ball=0,
        ),
        Drill(
            id="finish_turn_shoot", category="finishing", minutes=10,
            name={"en": "Receive, turn, shoot", "en-GB": "Receive, turn, shoot", "zh-CN": "接球转身射门",
                  "zh-TW": "接球轉身射門", "ja-JP": "受けて反転してシュート", "ko-KR": "받아 돌아 슛",
                  "es-ES": "Recibir, girar, disparar", "fr-FR": "Recevoir, se retourner, frapper",
                  "id-ID": "Terima, berbalik, tembak", "ms-MY": "Terima, pusing, tendang",
                  "th-TH": "รับ หมุน ยิง", "vi-VN": "Nhận, xoay, sút"},
            note={"en": "Check your shoulder before the ball comes. If the defender is tight, the turn is away from him, not through him.",
                  "en-GB": "Check your shoulder before the ball comes. If the defender is tight, the turn is away from him, not through him.",
                  "zh-CN": "球来之前先看肩后。防守贴得紧就朝反方向转，别硬顶。",
                  "zh-TW": "球來之前先看肩後。防守貼得緊就朝反方向轉，別硬頂。",
                  "ja-JP": "ボールが来る前に首を振る。密着されているなら相手と逆へ回る。",
                  "ko-KR": "공이 오기 전에 어깨 너머를 확인하라. 붙어 있으면 반대 방향으로 돌아라.",
                  "es-ES": "Mira por encima del hombro antes de recibir. Si te aprietan, gira al lado contrario.",
                  "fr-FR": "Regarde par-dessus l'épaule avant la réception. Si le défenseur colle, tourne à l'opposé.",
                  "id-ID": "Lihat ke belakang bahu sebelum bola datang. Jika dijaga ketat, berbalik menjauh.",
                  "ms-MY": "Tengok belakang bahu sebelum bola tiba.",
                  "th-TH": "เหลียวมองก่อนบอลมา ถ้าโดนประกบติดให้หมุนออกด้านตรงข้าม",
                  "vi-VN": "Ngoái nhìn trước khi bóng đến. Nếu bị kèm sát, xoay ra hướng ngược lại."},
            home=[
                P(500, 900, "10", moves=[(520, 800, 0)]),
                P(500, 620, "9", moves=[(560, 560, 0), (540, 380, 1)]),
            ],
            away=[
                P(520, 540, "4", moves=[(560, 500, 0)]),
                P(500, 200, "GK", role="GK"),
            ],
            markers=[M(500, 120, "square", "")],
            ball=0,
        ),

        # ── defending ────────────────────────────────────────────────────────
        Drill(
            id="defend_shape_shift", category="defending", minutes=12,
            name={"en": "Back four: shift and cover", "en-GB": "Back four: shift and cover", "zh-CN": "后防四人：横移与保护",
                  "zh-TW": "後防四人：橫移與保護", "ja-JP": "4バック：スライドとカバー", "ko-KR": "포백: 이동과 커버",
                  "es-ES": "Línea de cuatro: basculación", "fr-FR": "Ligne à quatre : coulissement",
                  "id-ID": "Empat bek: geser dan tutup", "ms-MY": "Empat bek: alih dan lindung",
                  "th-TH": "แนวรับสี่คน: ขยับและคุมพื้นที่", "vi-VN": "Bộ tứ vệ: dịch chuyển và bọc lót"},
            note={"en": "The far full-back tucks in as the ball travels. The line moves as one — a gap is one player being late.",
                  "en-GB": "The far full-back tucks in as the ball travels. The line moves as one — a gap is one player being late.",
                  "zh-CN": "球在运行时，远端边后卫要收进来。整条线一起动 —— 出现空当，就是有人慢了半拍。",
                  "zh-TW": "球在運行時，遠端邊後衛要收進來。整條線一起動 —— 出現空檔，就是有人慢了半拍。",
                  "ja-JP": "ボール移動中に逆SBが絞る。ラインは一体で動く。空くのは誰かが遅れた証拠。",
                  "ko-KR": "공이 이동하는 동안 반대편 풀백이 좁힌다. 라인은 하나로 움직인다.",
                  "es-ES": "El lateral lejano se cierra mientras viaja el balón. La línea se mueve como una.",
                  "fr-FR": "Le latéral opposé rentre pendant le trajet du ballon. La ligne bouge d'un bloc.",
                  "id-ID": "Bek sayap jauh masuk ke dalam saat bola bergerak. Lini bergerak sebagai satu.",
                  "ms-MY": "Bek sayap jauh masuk ke dalam ketika bola bergerak.",
                  "th-TH": "แบ็กฝั่งไกลต้องหุบเข้าในระหว่างบอลเดินทาง แนวรับต้องขยับพร้อมกัน",
                  "vi-VN": "Hậu vệ biên xa co vào khi bóng di chuyển. Cả tuyến dịch như một."},
            home=[
                P(200, 1000, "3", moves=[(300, 980, 0)]),
                P(400, 1030, "4", moves=[(500, 1010, 0)]),
                P(600, 1030, "5", moves=[(700, 1010, 0)]),
                P(800, 1000, "2", moves=[(860, 980, 0)]),
            ],
            away=[
                P(250, 800, "11"), P(500, 760, "10", moves=[(700, 780, 0)]),
                P(800, 800, "7", moves=[(880, 760, 0)]),
            ],
            ball=None,
        ),
        Drill(
            id="defend_counter_press", category="defending", minutes=12,
            name={"en": "Counter-press on loss", "en-GB": "Counter-press on loss", "zh-CN": "丢球后立刻反抢",
                  "zh-TW": "丟球後立刻反搶", "ja-JP": "即時奪回のプレス", "ko-KR": "볼 로스트 직후 압박",
                  "es-ES": "Contrapresión tras pérdida", "fr-FR": "Contre-pressing après perte",
                  "id-ID": "Counter-press setelah kehilangan bola", "ms-MY": "Tekanan balas selepas kehilangan bola",
                  "th-TH": "กดดันทันทีเมื่อเสียบอล", "vi-VN": "Pressing ngay khi mất bóng"},
            note={"en": "Five seconds. Closest player to the ball goes, the rest cut the forward pass — nobody runs home yet.",
                  "en-GB": "Five seconds. Closest player to the ball goes, the rest cut the forward pass — nobody runs home yet.",
                  "zh-CN": "五秒钟。离球最近的人上抢，其余人切断向前的传球线 —— 谁都先别回撤。",
                  "zh-TW": "五秒鐘。離球最近的人上搶，其餘人切斷向前的傳球線 —— 誰都先別回撤。",
                  "ja-JP": "5秒。最も近い選手が奪いに行き、他は前へのパスを消す。まだ戻らない。",
                  "ko-KR": "5초. 공에 가장 가까운 선수가 압박하고, 나머지는 전진 패스를 끊는다.",
                  "es-ES": "Cinco segundos. El más cercano va al balón; el resto corta el pase hacia delante.",
                  "fr-FR": "Cinq secondes. Le plus proche va au ballon, les autres coupent la passe vers l'avant.",
                  "id-ID": "Lima detik. Yang terdekat menekan bola, sisanya memotong umpan ke depan.",
                  "ms-MY": "Lima saat. Yang terdekat menekan bola, yang lain memotong hantaran ke depan.",
                  "th-TH": "ห้าวินาที คนใกล้บอลที่สุดเข้าไล่ คนอื่นตัดบอลไปข้างหน้า ยังไม่ต้องถอย",
                  "vi-VN": "Năm giây. Người gần bóng nhất áp sát, phần còn lại cắt đường chuyền lên."},
            home=[
                P(500, 700, "8", moves=[(520, 620, 0)]),
                P(340, 780, "10", moves=[(420, 700, 0)]),
                P(660, 780, "7", moves=[(600, 720, 0)]),
                P(500, 900, "6", moves=[(500, 800, 0)]),
            ],
            away=[
                P(520, 600, "5", moves=[(520, 520, 1)]),
                P(700, 560, "2"), P(320, 560, "3"),
            ],
            ball=None,
        ),

        # ── set pieces ───────────────────────────────────────────────────────
        Drill(
            id="corner_short", category="setpiece", minutes=8,
            name={"en": "Corner: short routine", "en-GB": "Corner: short routine", "zh-CN": "角球：短角球配合",
                  "zh-TW": "角球：短角球配合", "ja-JP": "CK：ショートコーナー", "ko-KR": "코너킥: 짧은 전개",
                  "es-ES": "Córner en corto", "fr-FR": "Corner joué court",
                  "id-ID": "Sepak pojok pendek", "ms-MY": "Penjuru pendek",
                  "th-TH": "เตะมุมสั้น", "vi-VN": "Phạt góc ngắn"},
            note={"en": "Two out drags one marker. The cross now comes from a better angle with one defender fewer in the box.",
                  "en-GB": "Two out drags one marker. The cross now comes from a better angle with one defender fewer in the box.",
                  "zh-CN": "两人出角把一个盯人拉出来。传中角度更好，禁区里还少了一个防守人。",
                  "zh-TW": "兩人出角把一個盯人拉出來。傳中角度更好，禁區裡還少了一個防守人。",
                  "ja-JP": "2人でショートにするとマーカーが1人出てくる。角度が良くなり、箱の中の相手が1人減る。",
                  "ko-KR": "두 명이 짧게 받으면 수비 한 명이 끌려 나온다. 각도가 좋아지고 박스 안 수비가 줄어든다.",
                  "es-ES": "Dos en corto arrastran a un marcador: mejor ángulo y un defensa menos en el área.",
                  "fr-FR": "Deux en jeu court attirent un marqueur : meilleur angle, un défenseur de moins dans la surface.",
                  "id-ID": "Dua orang pendek menarik satu penjaga keluar; sudut umpan lebih baik.",
                  "ms-MY": "Dua orang pendek menarik seorang penjaga keluar.",
                  "th-TH": "เล่นสั้นสองคนดึงกองหลังออกมาหนึ่ง มุมครอสดีขึ้นและในกรอบเหลือน้อยลง",
                  "vi-VN": "Hai người đá ngắn kéo một hậu vệ ra; góc tạt tốt hơn, trong vòng cấm bớt một người."},
            home=[
                P(940, 140, "7", moves=[(880, 240, 0)]),
                P(860, 300, "8", moves=[(900, 200, 0)]),
                P(620, 380, "9", moves=[(660, 260, 1)]),
                P(480, 400, "5", moves=[(520, 280, 1)]),
                P(520, 560, "6", moves=[(560, 440, 1)]),
            ],
            away=[
                P(800, 320, "A", moves=[(860, 280, 0)]),
                P(620, 260, "B"), P(500, 250, "C"),
                P(500, 180, "GK", role="GK"),
            ],
            markers=[M(500, 120, "square", "")],
            ball=0,
        ),
        Drill(
            id="throw_in_third", category="setpiece", minutes=8, off_surface=True,
            name={"en": "Attacking throw-in", "en-GB": "Attacking throw-in", "zh-CN": "前场界外球",
                  "zh-TW": "前場界外球", "ja-JP": "アタッキングサードのスローイン", "ko-KR": "공격 지역 스로인",
                  "es-ES": "Saque de banda ofensivo", "fr-FR": "Touche offensive",
                  "id-ID": "Lemparan ke dalam menyerang", "ms-MY": "Lontaran ke dalam menyerang",
                  "th-TH": "ทุ่มบอลในแดนบุก", "vi-VN": "Ném biên tấn công"},
            note={"en": "One player checks in to drag his marker, another goes long. The throw is to the space, not the crowd.",
                  "en-GB": "One player checks in to drag his marker, another goes long. The throw is to the space, not the crowd.",
                  "zh-CN": "一个人回撤把盯防拉出来，另一个反跑深处。球扔向空当，不是人堆。",
                  "zh-TW": "一個人回撤把盯防拉出來，另一個反跑深處。球扔向空檔，不是人堆。",
                  "ja-JP": "1人が寄ってマークを引き、もう1人が裏へ。投げるのは人ではなくスペース。",
                  "ko-KR": "한 명이 다가와 마크를 끌고, 다른 한 명은 뒤로 뛴다. 사람이 아니라 공간으로 던져라.",
                  "es-ES": "Uno se acerca para arrastrar a su marca, otro va largo. El saque va al espacio.",
                  "fr-FR": "Un joueur vient chercher pour attirer, l'autre part en profondeur. La touche va dans l'espace.",
                  "id-ID": "Satu menjemput untuk menarik penjaga, satu lagi lari jauh. Lempar ke ruang.",
                  "ms-MY": "Seorang menjemput untuk menarik penjaga, seorang lagi lari jauh.",
                  "th-TH": "คนหนึ่งเข้ามารับเพื่อดึงคนประกบ อีกคนวิ่งลึก ทุ่มไปที่พื้นที่ว่าง",
                  "vi-VN": "Một người lùi kéo người kèm, người kia chạy sâu. Ném vào khoảng trống."},
            home=[
                P(970, 620, "2"),
                P(830, 700, "7", moves=[(870, 620, 0)]),
                P(760, 480, "9", moves=[(840, 360, 1)]),
                P(600, 620, "10", moves=[(650, 500, 1)]),
            ],
            away=[
                P(800, 640, "A", moves=[(850, 660, 0)]),
                P(720, 420, "B", moves=[(780, 380, 1)]),
            ],
            markers=[M(500, 120, "square", "")],
            ball=0,
        ),

        # ── small-sided ──────────────────────────────────────────────────────
        Drill(
            id="ssg_6v6_transition", category="ssg", minutes=20,
            name={"en": "6v6 transition game", "en-GB": "6v6 transition game", "zh-CN": "6v6 攻防转换",
                  "zh-TW": "6v6 攻防轉換", "ja-JP": "6対6 トランジション", "ko-KR": "6대6 전환 게임",
                  "es-ES": "6v6 de transiciones", "fr-FR": "6c6 transitions",
                  "id-ID": "Permainan transisi 6v6", "ms-MY": "Permainan peralihan 6v6",
                  "th-TH": "เกมเปลี่ยนสถานะ 6v6", "vi-VN": "Trò chơi chuyển trạng thái 6v6"},
            note={"en": "Score within 10 seconds of winning it back. The first pass after the turnover decides the attack.",
                  "en-GB": "Score within 10 seconds of winning it back. The first pass after the turnover decides the attack.",
                  "zh-CN": "抢断后 10 秒内完成射门。转换后的第一脚传球决定这次进攻。",
                  "zh-TW": "抄截後 10 秒內完成射門。轉換後的第一腳傳球決定這次進攻。",
                  "ja-JP": "奪ってから10秒以内にシュート。奪取直後の1本目が攻撃を決める。",
                  "ko-KR": "빼앗은 뒤 10초 안에 마무리. 전환 직후 첫 패스가 공격을 결정한다.",
                  "es-ES": "Marca en los 10 segundos tras robar. El primer pase tras la recuperación decide.",
                  "fr-FR": "Marquer dans les 10 secondes après la récupération. La première passe décide.",
                  "id-ID": "Cetak gol dalam 10 detik setelah merebut bola. Umpan pertama menentukan.",
                  "ms-MY": "Jaring dalam 10 saat selepas merampas bola.",
                  "th-TH": "ทำประตูภายใน 10 วินาทีหลังแย่งบอลได้ บอลแรกหลังเปลี่ยนมือชี้ขาด",
                  "vi-VN": "Ghi bàn trong 10 giây sau khi đoạt bóng. Đường chuyền đầu quyết định."},
            home=[
                P(300, 1000, "1", moves=[(360, 880, 0)]), P(500, 1050, "2"),
                P(700, 1000, "3", moves=[(660, 860, 1)]),
                P(300, 780, "4"), P(500, 820, "5", moves=[(520, 700, 1)]), P(700, 780, "6"),
            ],
            away=[
                P(300, 600, "A", moves=[(360, 700, 0)]), P(500, 560, "B"),
                P(700, 600, "C"), P(300, 380, "D"), P(500, 340, "E"), P(700, 380, "F"),
            ],
            markers=[M(500, 140, "square"), M(500, 1360, "square")],
            ball=0,
        ),
        # ── batch 3 ──────────────────────────────────────────────────────────
        Drill(
            id="warmup_rotation_square", category="warmup", minutes=8,
            name={"en": "Rotation square", "en-GB": "Rotation square", "zh-CN": "轮转方阵",
                  "zh-TW": "輪轉方陣", "ja-JP": "ローテーションスクエア", "ko-KR": "회전 사각형",
                  "es-ES": "Cuadrado con rotación", "fr-FR": "Carré avec rotation",
                  "id-ID": "Kotak rotasi", "ms-MY": "Segi empat putaran",
                  "th-TH": "สี่เหลี่ยมหมุนเวียน", "vi-VN": "Ô vuông luân chuyển"},
            note={"en": "Take the place of the player you passed to. Talk before the pass, not after it.",
                  "en-GB": "Take the place of the player you passed to. Talk before the pass, not after it.",
                  "zh-CN": "传给谁就去补谁的位置。开口要在传球之前，不是之后。",
                  "zh-TW": "傳給誰就去補誰的位置。開口要在傳球之前，不是之後。",
                  "ja-JP": "パスした相手の位置に入る。声はパスの前に出す。",
                  "ko-KR": "패스한 상대의 자리로 들어간다. 말은 패스 전에 하라.",
                  "es-ES": "Ocupa el sitio de a quien pasaste. Habla antes del pase, no después.",
                  "fr-FR": "Prends la place de celui à qui tu passes. Parle avant la passe.",
                  "id-ID": "Ambil posisi pemain yang kamu umpan. Bicara sebelum mengumpan.",
                  "ms-MY": "Ambil tempat pemain yang anda hantar. Bercakap sebelum hantaran.",
                  "th-TH": "ไปยืนแทนคนที่คุณจ่ายให้ พูดก่อนจ่าย ไม่ใช่หลังจ่าย",
                  "vi-VN": "Vào chỗ người bạn vừa chuyền. Gọi trước khi chuyền, không phải sau."},
            home=[
                P(300, 600, "1", moves=[(700, 600, 0)]),
                P(700, 600, "2", moves=[(700, 900, 1)]),
                P(700, 900, "3", moves=[(300, 900, 2)]),
                P(300, 900, "4", moves=[(300, 600, 3)]),
            ],
            markers=[M(280, 580), M(720, 580), M(720, 920), M(280, 920)],
            ball=0,
        ),
        Drill(
            id="warmup_two_ball", category="warmup", minutes=6,
            name={"en": "Two-ball awareness", "en-GB": "Two-ball awareness", "zh-CN": "双球注意力",
                  "zh-TW": "雙球注意力", "ja-JP": "2ボール認知", "ko-KR": "두 개의 공 인지",
                  "es-ES": "Dos balones, atención", "fr-FR": "Deux ballons, vigilance",
                  "id-ID": "Dua bola, kesadaran", "ms-MY": "Dua bola, kesedaran",
                  "th-TH": "สองลูก ฝึกการรับรู้", "vi-VN": "Hai bóng, quan sát"},
            note={"en": "Two balls moving at once. Look up between touches — you can't react to what you haven't seen.",
                  "en-GB": "Two balls moving at once. Look up between touches — you can't react to what you haven't seen.",
                  "zh-CN": "两个球同时在转。触球间隙抬头看 —— 没看见的东西反应不了。",
                  "zh-TW": "兩個球同時在轉。觸球間隙抬頭看 —— 沒看見的東西反應不了。",
                  "ja-JP": "ボールが2つ同時に動く。タッチの合間に顔を上げる。見ていないものには反応できない。",
                  "ko-KR": "공 두 개가 동시에 움직인다. 터치 사이에 고개를 들어라.",
                  "es-ES": "Dos balones a la vez. Levanta la cabeza entre toques: no reaccionas a lo que no ves.",
                  "fr-FR": "Deux ballons en même temps. Lève la tête entre les touches.",
                  "id-ID": "Dua bola bergerak bersamaan. Angkat kepala di antara sentuhan.",
                  "ms-MY": "Dua bola bergerak serentak. Angkat kepala antara sentuhan.",
                  "th-TH": "สองลูกเคลื่อนพร้อมกัน เงยหน้าระหว่างการแตะ",
                  "vi-VN": "Hai bóng cùng lúc. Ngẩng đầu giữa các chạm."},
            home=[
                P(350, 600, "1", moves=[(350, 900, 0)]),
                P(650, 600, "2", moves=[(350, 600, 0)]),
                P(650, 900, "3", moves=[(650, 600, 1)]),
                P(350, 900, "4", moves=[(650, 900, 1)]),
            ],
            markers=[M(330, 580), M(670, 580), M(670, 920), M(330, 920)],
            ball=0,
        ),
        Drill(
            id="possession_overload_4v2_plus", category="possession", minutes=12,
            name={"en": "Overload to isolate", "en-GB": "Overload to isolate", "zh-CN": "以多打少再转弱侧",
                  "zh-TW": "以多打少再轉弱側", "ja-JP": "オーバーロードから逆サイド", "ko-KR": "한쪽 과부하 후 고립",
                  "es-ES": "Sobrecarga y aislar", "fr-FR": "Surcharger pour isoler",
                  "id-ID": "Menumpuk lalu isolasi", "ms-MY": "Kumpul sisi lalu asingkan",
                  "th-TH": "กดดันฝั่งเดียวแล้วเปิดอีกฝั่ง", "vi-VN": "Dồn một bên để cô lập bên kia"},
            note={"en": "Overload one side until they commit, then the isolated winger is 1v1 with the whole flank.",
                  "en-GB": "Overload one side until they commit, then the isolated winger is 1v1 with the whole flank.",
                  "zh-CN": "一侧堆人逼对方倾斜，弱侧边锋就得到一整条边路的 1v1。",
                  "zh-TW": "一側堆人逼對方傾斜，弱側邊鋒就得到一整條邊路的 1v1。",
                  "ja-JP": "片側に人数をかけて相手を寄せ、逆サイドのウイングを1対1にする。",
                  "ko-KR": "한쪽에 인원을 몰아 상대를 끌어낸 뒤, 반대편 윙어를 1대1로 만든다.",
                  "es-ES": "Sobrecarga un lado hasta que basculen; el extremo aislado queda 1v1 con toda la banda.",
                  "fr-FR": "Surcharge un côté jusqu'au basculement : l'ailier isolé se retrouve en 1c1.",
                  "id-ID": "Tumpuk satu sisi sampai lawan bergeser, sayap di sisi lain jadi 1v1.",
                  "ms-MY": "Kumpulkan satu sisi sehingga lawan beralih, sayap bertentangan jadi 1v1.",
                  "th-TH": "ดึงคนไปฝั่งหนึ่งจนคู่แข่งเอียง แล้วปีกอีกฝั่งจะได้ 1v1 ทั้งริมเส้น",
                  "vi-VN": "Dồn quân một bên đến khi đối thủ nghiêng, cánh còn lại được 1v1."},
            home=[
                P(250, 800, "6"), P(350, 650, "8", moves=[(300, 720, 0)]),
                P(200, 620, "3", moves=[(200, 520, 0)]),
                P(500, 750, "10", moves=[(560, 700, 1)]),
                P(850, 700, "7", moves=[(850, 520, 2)]),
            ],
            away=[
                P(330, 720, "A", moves=[(270, 700, 0)]),
                P(450, 640, "B", moves=[(380, 640, 0)]),
                P(620, 700, "C", moves=[(520, 720, 1)]),
            ],
            ball=1,
        ),
        Drill(
            id="attack_double_pivot_switch", category="attacking", minutes=12,
            name={"en": "Pivot switch", "en-GB": "Pivot switch", "zh-CN": "后腰转移",
                  "zh-TW": "後腰轉移", "ja-JP": "ピボットからの展開", "ko-KR": "피벗 전환",
                  "es-ES": "Cambio desde el pivote", "fr-FR": "Renversement par le pivot",
                  "id-ID": "Perpindahan lewat gelandang jangkar", "ms-MY": "Tukar arah melalui pivot",
                  "th-TH": "เปลี่ยนข้างผ่านตัวรับ", "vi-VN": "Chuyển hướng qua tiền vệ trụ"},
            note={"en": "Back to the pivot, then out. Playing backwards to go forwards is the fastest route on a packed side.",
                  "en-GB": "Back to the pivot, then out. Playing backwards to go forwards is the fastest route on a packed side.",
                  "zh-CN": "回传后腰再转边。密集一侧，往回传才是最快的向前。",
                  "zh-TW": "回傳後腰再轉邊。密集一側，往回傳才是最快的向前。",
                  "ja-JP": "ピボットに戻してから逆へ。密集側では下げるのが一番速い前進。",
                  "ko-KR": "피벗으로 내렸다가 전환. 밀집한 쪽에서는 뒤로 가는 것이 가장 빠른 전진이다.",
                  "es-ES": "Atrás al pivote y luego fuera. Jugar hacia atrás es el camino más rápido hacia delante.",
                  "fr-FR": "Retour au pivot puis ressortir. Reculer est parfois le plus rapide pour avancer.",
                  "id-ID": "Kembali ke gelandang jangkar lalu keluar. Mundur untuk maju lebih cepat.",
                  "ms-MY": "Pulangkan ke pivot kemudian keluar.",
                  "th-TH": "จ่ายกลับให้ตัวรับแล้วเปิดออก ถอยเพื่อไปข้างหน้าคือทางที่เร็วที่สุด",
                  "vi-VN": "Trả về tiền vệ trụ rồi mở biên. Lùi lại là cách tiến nhanh nhất."},
            home=[
                P(250, 700, "11", moves=[(230, 640, 0)]),
                P(450, 850, "6", moves=[(500, 820, 0)]),
                P(820, 720, "7", moves=[(830, 540, 1)]),
                P(600, 600, "9"),
            ],
            away=[
                P(330, 660, "A", moves=[(270, 640, 0)]),
                P(480, 700, "B", moves=[(430, 720, 0)]),
                P(700, 620, "C", moves=[(760, 600, 1)]),
            ],
            ball=0,
        ),
        Drill(
            id="attack_cross_far_post", category="attacking", minutes=10,
            name={"en": "Far-post cross", "en-GB": "Far-post cross", "zh-CN": "远门柱传中",
                  "zh-TW": "遠門柱傳中", "ja-JP": "ファーポストへのクロス", "ko-KR": "파포스트 크로스",
                  "es-ES": "Centro al segundo palo", "fr-FR": "Centre au second poteau",
                  "id-ID": "Umpan silang tiang jauh", "ms-MY": "Lambungan tiang jauh",
                  "th-TH": "ครอสเสาไกล", "vi-VN": "Tạt cột xa"},
            note={"en": "Attack the far post from behind the defender's shoulder — arriving late beats standing early.",
                  "en-GB": "Attack the far post from behind the defender's shoulder — arriving late beats standing early.",
                  "zh-CN": "从防守人肩后包抄远门柱 —— 晚到一步好过早早站住。",
                  "zh-TW": "從防守人肩後包抄遠門柱 —— 晚到一步好過早早站住。",
                  "ja-JP": "相手の肩の後ろからファーへ入る。早く立つより遅れて入る方が強い。",
                  "ko-KR": "수비 어깨 뒤에서 파포스트로 들어가라. 미리 서 있는 것보다 늦게 도착하는 편이 낫다.",
                  "es-ES": "Ataca el segundo palo desde detrás del hombro del defensa: llegar tarde gana a esperar.",
                  "fr-FR": "Attaque le second poteau depuis l'épaule du défenseur : arriver tard vaut mieux qu'attendre.",
                  "id-ID": "Serang tiang jauh dari belakang bahu bek — datang telat lebih baik daripada berdiri awal.",
                  "ms-MY": "Serang tiang jauh dari belakang bahu bek.",
                  "th-TH": "เข้าเสาไกลจากหลังไหล่กองหลัง มาช้าดีกว่ายืนรอ",
                  "vi-VN": "Tấn công cột xa từ sau vai hậu vệ — đến muộn hơn là đứng chờ."},
            home=[
                P(180, 520, "11", moves=[(180, 340, 0)]),
                P(520, 620, "9", moves=[(520, 340, 1)]),
                P(660, 700, "7", moves=[(720, 300, 1)]),
            ],
            away=[
                P(300, 400, "A", moves=[(240, 340, 0)]),
                P(560, 300, "B"), P(500, 180, "GK", role="GK", moves=[(430, 220, 1)]),
            ],
            markers=[M(500, 120, "square", "")],
            ball=0,
        ),
        Drill(
            id="finish_volley_side", category="finishing", minutes=10,
            name={"en": "Side volley from the cutback", "en-GB": "Side volley from the cutback",
                  "zh-CN": "倒三角凌空侧射", "zh-TW": "倒三角凌空側射",
                  "ja-JP": "折り返しからのサイドボレー", "ko-KR": "컷백 사이드 발리",
                  "es-ES": "Volea lateral tras pase atrás", "fr-FR": "Volée latérale sur retrait",
                  "id-ID": "Voli samping dari umpan tarik", "ms-MY": "Voli sisi daripada hantaran tarik",
                  "th-TH": "วอลเลย์ด้านข้างจากบอลตัดกลับ", "vi-VN": "Vô lê cạnh sườn từ đường chuyền ngược"},
            note={"en": "Feet set before the ball arrives. Half a step late and the strike goes over every time.",
                  "en-GB": "Feet set before the ball arrives. Half a step late and the strike goes over every time.",
                  "zh-CN": "球到之前脚步就要站好。慢半步，球必然打飞。",
                  "zh-TW": "球到之前腳步就要站好。慢半步，球必然打飛。",
                  "ja-JP": "ボールが来る前に足を作る。半歩遅れると必ず枠を越える。",
                  "ko-KR": "공이 오기 전에 발을 만들어라. 반 박자 늦으면 반드시 뜬다.",
                  "es-ES": "Pies colocados antes de que llegue el balón; medio paso tarde y se va arriba.",
                  "fr-FR": "Appuis posés avant l'arrivée du ballon ; un demi-pas de retard et ça passe au-dessus.",
                  "id-ID": "Kaki siap sebelum bola datang. Telat setengah langkah, bola pasti melambung.",
                  "ms-MY": "Kaki bersedia sebelum bola tiba.",
                  "th-TH": "ตั้งเท้าก่อนบอลมาถึง ช้าครึ่งก้าวบอลข้ามคานแน่นอน",
                  "vi-VN": "Đặt chân trước khi bóng đến. Chậm nửa nhịp là bóng bay vọt xà."},
            home=[
                P(840, 420, "7", moves=[(780, 320, 0)]),
                P(560, 600, "9", moves=[(520, 440, 0), (500, 400, 1)]),
            ],
            away=[P(500, 200, "GK", role="GK", moves=[(560, 250, 1)])],
            markers=[M(500, 120, "square", "")],
            ball=0,
        ),
        Drill(
            id="defend_1v1_channel", category="defending", minutes=10,
            name={"en": "1v1 defending in the channel", "en-GB": "1v1 defending in the channel",
                  "zh-CN": "边路 1v1 防守", "zh-TW": "邊路 1v1 防守",
                  "ja-JP": "サイドの1対1守備", "ko-KR": "측면 1대1 수비",
                  "es-ES": "Defensa 1v1 en el pasillo", "fr-FR": "Défense 1c1 dans le couloir",
                  "id-ID": "Bertahan 1v1 di sisi", "ms-MY": "Bertahan 1v1 di lorong",
                  "th-TH": "ป้องกัน 1v1 ริมเส้น", "vi-VN": "Phòng ngự 1v1 ở hành lang"},
            note={"en": "Show him down the line, never inside. Approach fast, arrive slow, and stay on your toes.",
                  "en-GB": "Show him down the line, never inside. Approach fast, arrive slow, and stay on your toes.",
                  "zh-CN": "把他逼向边线，绝不放内切。快速接近、减速到位、重心在前脚掌。",
                  "zh-TW": "把他逼向邊線，絕不放內切。快速接近、減速到位、重心在前腳掌。",
                  "ja-JP": "外へ誘導し、中を切る。速く寄せて、ゆっくり止まり、つま先で構える。",
                  "ko-KR": "라인 쪽으로 몰아라, 안쪽은 절대 금지. 빠르게 다가가 천천히 멈춰라.",
                  "es-ES": "Muéstrale la línea, nunca por dentro. Llega rápido, frena antes, apoya en la punta.",
                  "fr-FR": "Oriente-le vers la ligne, jamais à l'intérieur. Approche vite, arrive lentement.",
                  "id-ID": "Arahkan ke garis, jangan ke dalam. Datang cepat, berhenti pelan.",
                  "ms-MY": "Halakan dia ke garisan, jangan ke dalam.",
                  "th-TH": "บีบให้ออกริมเส้น อย่าปล่อยตัดเข้าใน เข้าเร็วแต่หยุดช้า",
                  "vi-VN": "Ép ra biên, không cho cắt vào trong. Áp sát nhanh, dừng chậm."},
            home=[P(820, 640, "3", moves=[(830, 760, 0), (860, 860, 1)])],
            away=[P(830, 950, "11", moves=[(840, 820, 0), (880, 700, 1)])],
            markers=[M(960, 560), M(960, 1040)],
            ball=None,
        ),
        Drill(
            id="setpiece_defend_corner", category="setpiece", minutes=10,
            name={"en": "Defending a corner", "en-GB": "Defending a corner", "zh-CN": "角球防守",
                  "zh-TW": "角球防守", "ja-JP": "CKの守備", "ko-KR": "코너킥 수비",
                  "es-ES": "Defender el córner", "fr-FR": "Défendre le corner",
                  "id-ID": "Bertahan sepak pojok", "ms-MY": "Bertahan penjuru",
                  "th-TH": "ป้องกันลูกเตะมุม", "vi-VN": "Phòng ngự phạt góc"},
            note={"en": "Two on the posts, one attacks the near-post ball, the rest mark space and start moving as the ball is struck.",
                  "en-GB": "Two on the posts, one attacks the near-post ball, the rest mark space and start moving as the ball is struck.",
                  "zh-CN": "两人守门柱，一人前顶抢近点，其余人盯区域，球一开就动。",
                  "zh-TW": "兩人守門柱，一人前頂搶近點，其餘人盯區域，球一開就動。",
                  "ja-JP": "2人がポスト、1人がニアを潰し、他はゾーンで蹴られた瞬間に動き出す。",
                  "ko-KR": "두 명은 골포스트, 한 명은 니어 볼 차단, 나머지는 지역 방어로 차는 순간 움직인다.",
                  "es-ES": "Dos en los palos, uno ataca el primer palo, el resto marca zona y arranca al golpeo.",
                  "fr-FR": "Deux aux poteaux, un attaque le premier poteau, les autres en zone et partent à la frappe.",
                  "id-ID": "Dua di tiang, satu memotong tiang dekat, sisanya menjaga zona dan bergerak saat bola ditendang.",
                  "ms-MY": "Dua di tiang, satu memotong tiang dekat, selebihnya menjaga zon.",
                  "th-TH": "สองคนยืนเสา หนึ่งคนสกัดบอลเสาแรก ที่เหลือคุมโซนและออกตัวเมื่อบอลถูกเตะ",
                  "vi-VN": "Hai người đứng cột, một người cắt bóng cột gần, còn lại kèm khu vực."},
            home=[
                P(430, 190, "2"), P(570, 190, "3"),
                P(640, 300, "4", moves=[(700, 250, 0)]),
                P(500, 320, "5", moves=[(520, 260, 0)]),
                P(380, 330, "6", moves=[(400, 280, 0)]),
                P(500, 180, "GK", role="GK", moves=[(540, 230, 0)]),
            ],
            away=[
                P(940, 140, "7"),
                P(700, 380, "9", moves=[(720, 260, 0)]),
                P(560, 420, "10", moves=[(560, 300, 0)]),
            ],
            markers=[M(500, 120, "square", "")],
            ball=None,
        ),
        Drill(
            id="ssg_5v5_two_touch", category="ssg", minutes=18,
            name={"en": "5v5, two touches", "en-GB": "5v5, two touches", "zh-CN": "5v5 两脚触球",
                  "zh-TW": "5v5 兩腳觸球", "ja-JP": "5対5 2タッチ", "ko-KR": "5대5 투터치",
                  "es-ES": "5v5 a dos toques", "fr-FR": "5c5 à deux touches",
                  "id-ID": "5v5 dua sentuhan", "ms-MY": "5v5 dua sentuhan",
                  "th-TH": "5v5 แตะสองครั้ง", "vi-VN": "5v5 hai chạm"},
            note={"en": "Two touches forces the scan before you receive. Nobody solves it with skill; they solve it by looking earlier.",
                  "en-GB": "Two touches forces the scan before you receive. Nobody solves it with skill; they solve it by looking earlier.",
                  "zh-CN": "限两脚，逼你在接球前就观察。这不是靠技术解决的，是靠提前看。",
                  "zh-TW": "限兩腳，逼你在接球前就觀察。這不是靠技術解決的，是靠提前看。",
                  "ja-JP": "2タッチ制限は受ける前の首振りを強制する。技術ではなく、早く見ることで解決する。",
                  "ko-KR": "투터치는 받기 전에 살피게 만든다. 기술이 아니라 먼저 보는 것으로 푼다.",
                  "es-ES": "Dos toques obligan a mirar antes de recibir. No se resuelve con técnica, sino mirando antes.",
                  "fr-FR": "Deux touches obligent à regarder avant de recevoir. Ce n'est pas la technique, c'est le regard.",
                  "id-ID": "Dua sentuhan memaksa memindai sebelum menerima bola.",
                  "ms-MY": "Dua sentuhan memaksa anda melihat sebelum menerima bola.",
                  "th-TH": "แตะสองครั้งบังคับให้มองก่อนรับบอล ไม่ใช่แก้ด้วยทักษะ แต่ด้วยการมองเร็วขึ้น",
                  "vi-VN": "Hai chạm buộc phải quan sát trước khi nhận bóng."},
            home=[
                P(500, 1050, "1", moves=[(540, 950, 0)]),
                P(280, 900, "2"), P(720, 900, "3", moves=[(760, 800, 1)]),
                P(400, 720, "4"), P(600, 720, "5", moves=[(620, 640, 1)]),
            ],
            away=[
                P(500, 450, "A", moves=[(500, 560, 0)]),
                P(280, 600, "B"), P(720, 600, "C"),
                P(400, 320, "D"), P(600, 320, "E"),
            ],
            markers=[M(500, 140, "square"), M(500, 1360, "square"),
                     M(180, 200), M(820, 200), M(180, 1300), M(820, 1300)],
            ball=0,
        ),
        Drill(
            id="possession_switch_two_touch", category="possession", minutes=12,
            name={"en": "Long switch, first time", "en-GB": "Long switch, first time",
                  "zh-CN": "一脚长传转移", "zh-TW": "一腳長傳轉移",
                  "ja-JP": "ダイレクトのサイドチェンジ", "ko-KR": "원터치 롱 스위치",
                  "es-ES": "Cambio largo de primeras", "fr-FR": "Renversement long en une touche",
                  "id-ID": "Pindah panjang satu sentuhan", "ms-MY": "Tukar panjang satu sentuhan",
                  "th-TH": "เปลี่ยนข้างยาวจังหวะเดียว", "vi-VN": "Chuyển cánh dài một chạm"},
            note={"en": "The receiver's first touch decides the switch — take it away from the pressure, then hit it.",
                  "en-GB": "The receiver's first touch decides the switch — take it away from the pressure, then hit it.",
                  "zh-CN": "转移成不成，看接球第一脚 —— 先把球停离压迫方向，再打。",
                  "zh-TW": "轉移成不成，看接球第一腳 —— 先把球停離壓迫方向，再打。",
                  "ja-JP": "展開の成否は受け手のファーストタッチ。プレスと逆に置いてから蹴る。",
                  "ko-KR": "전환의 성패는 첫 터치. 압박 반대쪽으로 놓고 차라.",
                  "es-ES": "El primer control decide el cambio: sácalo de la presión y golpea.",
                  "fr-FR": "Le premier contrôle décide du renversement : éloigne-le du pressing puis frappe.",
                  "id-ID": "Sentuhan pertama menentukan perpindahan: jauhkan dari tekanan lalu tendang.",
                  "ms-MY": "Sentuhan pertama menentukan pertukaran: jauhkan dari tekanan.",
                  "th-TH": "จังหวะแรกของคนรับตัดสินการเปลี่ยนข้าง เขี่ยออกจากแรงกดดันแล้วค่อยยิงยาว",
                  "vi-VN": "Chạm đầu của người nhận quyết định pha chuyển cánh."},
            home=[
                P(220, 700, "3", moves=[(200, 620, 0)]),
                P(500, 800, "6", moves=[(540, 740, 0)]),
                P(820, 620, "2", moves=[(840, 520, 1)]),
                P(700, 900, "8"),
            ],
            away=[
                P(320, 640, "A", moves=[(260, 640, 0)]),
                P(560, 700, "B", moves=[(520, 700, 0)]),
            ],
            ball=0,
        ),
        Drill(
            id="finish_penalty_routine", category="finishing", minutes=8,
            name={"en": "Penalties under fatigue", "en-GB": "Penalties under fatigue",
                  "zh-CN": "疲劳状态罚点球", "zh-TW": "疲勞狀態罰點球",
                  "ja-JP": "疲労下のPK", "ko-KR": "지친 상태의 페널티킥",
                  "es-ES": "Penaltis con fatiga", "fr-FR": "Penaltys sous fatigue",
                  "id-ID": "Penalti dalam kondisi lelah", "ms-MY": "Penalti ketika letih",
                  "th-TH": "จุดโทษตอนล้า", "vi-VN": "Phạt đền khi mệt"},
            note={"en": "Sprint the length first, then place it. Pick the corner before you walk up and do not change your mind.",
                  "en-GB": "Sprint the length first, then place it. Pick the corner before you walk up and do not change your mind.",
                  "zh-CN": "先冲刺一趟再罚。上前之前就选好角度，然后绝不改主意。",
                  "zh-TW": "先衝刺一趟再罰。上前之前就選好角度，然後絕不改主意。",
                  "ja-JP": "全力疾走してから蹴る。歩き出す前にコースを決め、変えない。",
                  "ko-KR": "먼저 전력 질주한 뒤 찬다. 걸어가기 전에 코스를 정하고 바꾸지 마라.",
                  "es-ES": "Esprinta primero y luego colócalo. Elige el palo antes de caminar y no cambies.",
                  "fr-FR": "Sprinte d'abord, puis place-le. Choisis ton côté avant de t'avancer, et n'en change pas.",
                  "id-ID": "Lari sprint dulu baru tendang. Pilih sudut sebelum berjalan dan jangan berubah.",
                  "ms-MY": "Pecut dahulu kemudian tendang. Pilih sudut sebelum melangkah.",
                  "th-TH": "วิ่งเต็มสปีดก่อนแล้วค่อยยิง เลือกมุมก่อนเดินเข้าไปและอย่าเปลี่ยนใจ",
                  "vi-VN": "Chạy nước rút trước rồi mới sút. Chọn góc trước khi bước lên và đừng đổi ý."},
            home=[P(500, 900, "9", moves=[(500, 1200, 0), (500, 560, 1), (500, 480, 2)])],
            away=[P(500, 200, "GK", role="GK", moves=[(430, 240, 2)])],
            markers=[M(500, 120, "square", ""), M(500, 480, "circle", "")],
            ball=None,
        ),
    ]



def basketball_drills() -> list[Drill]:
    """Half-court unless stated, attacking the basket at the top (y small).

    Landmarks in court coordinates: rim (0.5, 0.06), free-throw line
    (0.5, 0.19), top of the arc (0.5, 0.30), wings (0.15, 0.26) and
    (0.85, 0.26), corners (0.05, 0.11) / (0.95, 0.11), elbows (0.33, 0.19)
    and (0.67, 0.19), blocks (0.38, 0.10) / (0.62, 0.10), half court y = 0.5.
    """
    return [
        # ── warm-up ──────────────────────────────────────────────────────────
        Drill(
            id="bb_layup_lines", category="warmup", minutes=8, rel=True, free=True,
            name={"en": "Layup lines", "en-GB": "Layup lines", "zh-CN": "上篮轮转",
                  "zh-TW": "上籃輪轉", "ja-JP": "レイアップライン", "ko-KR": "레이업 라인",
                  "es-ES": "Filas de bandeja", "fr-FR": "Lignes de layup",
                  "id-ID": "Barisan layup", "ms-MY": "Barisan layup",
                  "th-TH": "แถวเลย์อัพ", "vi-VN": "Hàng lên rổ"},
            note={"en": "Inside foot, outside hand, eyes on the square — not on the ball.",
                  "en-GB": "Inside foot, outside hand, eyes on the square — not on the ball.",
                  "zh-CN": "内侧脚起跳、外侧手上篮，眼睛盯篮板方框，不是盯球。",
                  "zh-TW": "內側腳起跳、外側手上籃，眼睛盯籃板方框，不是盯球。",
                  "ja-JP": "内側の足で踏み切り外側の手で。目はボードの四角、ボールではない。",
                  "ko-KR": "안쪽 발로 점프, 바깥쪽 손으로 마무리. 시선은 백보드 사각형.",
                  "es-ES": "Pie interior, mano exterior, mirada al cuadro del tablero.",
                  "fr-FR": "Pied intérieur, main extérieure, regard sur le carré de la planche.",
                  "id-ID": "Kaki dalam, tangan luar, mata ke kotak papan.",
                  "ms-MY": "Kaki dalam, tangan luar, mata pada kotak papan.",
                  "th-TH": "เท้าใน มือนอก สายตาจับกรอบสี่เหลี่ยมบนแป้น",
                  "vi-VN": "Chân trong, tay ngoài, mắt nhìn ô vuông trên bảng."},
            home=[
                P(0.18, 0.45, "1", moves=[(0.34, 0.20, 0), (0.44, 0.09, 1)]),
                P(0.82, 0.45, "2", moves=[(0.66, 0.20, 0), (0.56, 0.09, 1)]),
                P(0.18, 0.58, "3"), P(0.82, 0.58, "4"),
            ],
            ball=0,
        ),
        Drill(
            id="bb_two_ball_dribble", category="warmup", minutes=6, rel=True, free=True,
            name={"en": "Two-ball dribbling", "en-GB": "Two-ball dribbling", "zh-CN": "双球运球",
                  "zh-TW": "雙球運球", "ja-JP": "2ボールドリブル", "ko-KR": "두 개 공 드리블",
                  "es-ES": "Bote con dos balones", "fr-FR": "Dribble à deux ballons",
                  "id-ID": "Dribel dua bola", "ms-MY": "Dribel dua bola",
                  "th-TH": "เลี้ยงสองลูก", "vi-VN": "Dẫn hai bóng"},
            note={"en": "Head up the whole way. If you can't call out the coach's fingers, you're watching the ball.",
                  "en-GB": "Head up the whole way. If you can't call out the coach's fingers, you're watching the ball.",
                  "zh-CN": "全程抬头。喊不出教练比的数字，就说明你在看球。",
                  "zh-TW": "全程抬頭。喊不出教練比的數字，就說明你在看球。",
                  "ja-JP": "最後まで顔を上げる。コーチの指の数が言えないなら、ボールを見ている証拠。",
                  "ko-KR": "끝까지 고개를 들어라. 코치의 손가락 수를 못 부르면 공을 보고 있는 것이다.",
                  "es-ES": "Cabeza arriba todo el rato: si no cantas los dedos del entrenador, miras el balón.",
                  "fr-FR": "Tête haute jusqu'au bout. Si tu ne peux pas annoncer les doigts du coach, tu regardes le ballon.",
                  "id-ID": "Kepala tegak terus. Kalau tak bisa menyebut jari pelatih, kamu melihat bola.",
                  "ms-MY": "Kepala tegak sepanjang masa.",
                  "th-TH": "เงยหน้าตลอด ถ้าบอกจำนวนนิ้วของโค้ชไม่ได้ แปลว่ากำลังมองบอล",
                  "vi-VN": "Ngẩng đầu suốt. Không đọc được số ngón tay của HLV nghĩa là đang nhìn bóng."},
            home=[P(0.5, 0.80, "1", moves=[(0.5, 0.55, 0), (0.5, 0.30, 1)])],
            markers=[M(0.35, 0.70), M(0.65, 0.70), M(0.35, 0.45), M(0.65, 0.45)],
            ball=0,
        ),
        Drill(
            id="bb_star_passing", category="warmup", minutes=8, rel=True,
            name={"en": "Star passing", "en-GB": "Star passing", "zh-CN": "五角星传球",
                  "zh-TW": "五角星傳球", "ja-JP": "スターパス", "ko-KR": "별 모양 패스",
                  "es-ES": "Pase en estrella", "fr-FR": "Passes en étoile",
                  "id-ID": "Umpan bintang", "ms-MY": "Hantaran bintang",
                  "th-TH": "ส่งบอลรูปดาว", "vi-VN": "Chuyền hình sao"},
            note={"en": "Pass and go — behind the player you passed to. A pass without movement is a stop.",
                  "en-GB": "Pass and go — behind the player you passed to. A pass without movement is a stop.",
                  "zh-CN": "传完就跑，跑到你传球对象身后。不带跑动的传球等于停球。",
                  "zh-TW": "傳完就跑，跑到你傳球對象身後。不帶跑動的傳球等於停球。",
                  "ja-JP": "パスしたら走る、渡した相手の後ろへ。動きのないパスは停滞。",
                  "ko-KR": "패스하고 달려라, 준 사람 뒤로. 움직임 없는 패스는 정지다.",
                  "es-ES": "Pasa y corre detrás de quien recibió. Un pase sin movimiento es una parada.",
                  "fr-FR": "Passe et cours derrière celui qui reçoit. Une passe sans mouvement est un arrêt.",
                  "id-ID": "Umpan lalu berlari di belakang penerima.",
                  "ms-MY": "Hantar dan berlari di belakang penerima.",
                  "th-TH": "ส่งแล้ววิ่งไปด้านหลังคนที่รับ การส่งที่ไม่มีการเคลื่อนที่คือการหยุด",
                  "vi-VN": "Chuyền rồi chạy ra sau người nhận."},
            home=[
                P(0.50, 0.30, "1", moves=[(0.85, 0.26, 0)]),
                P(0.85, 0.26, "2", moves=[(0.70, 0.62, 1)]),
                P(0.70, 0.62, "3", moves=[(0.30, 0.62, 2)]),
                P(0.30, 0.62, "4", moves=[(0.15, 0.26, 3)]),
                P(0.15, 0.26, "5", moves=[(0.50, 0.30, 4)]),
            ],
            ball=0,
        ),

        # ── offense / ball movement ──────────────────────────────────────────
        Drill(
            id="bb_five_out_spacing", category="possession", minutes=12, rel=True, free=True,
            name={"en": "Five-out spacing", "en-GB": "Five-out spacing", "zh-CN": "五外站位",
                  "zh-TW": "五外站位", "ja-JP": "ファイブアウトの間隔", "ko-KR": "파이브 아웃 간격",
                  "es-ES": "Espaciado 5 abiertos", "fr-FR": "Spacing cinq dehors",
                  "id-ID": "Spasi lima di luar", "ms-MY": "Jarak lima di luar",
                  "th-TH": "การยืนแบบไฟฟ์เอาท์", "vi-VN": "Giãn biên năm ngoài"},
            note={"en": "Fifteen feet apart. One defender must never be able to guard two of you.",
                  "en-GB": "Fifteen feet apart. One defender must never be able to guard two of you.",
                  "zh-CN": "间距保持四五米。**一个防守人永远不能同时看住你们两个**。",
                  "zh-TW": "間距保持四五米。一個防守人永遠不能同時看住你們兩個。",
                  "ja-JP": "4〜5m空ける。1人のディフェンスが2人を見られる距離に立たない。",
                  "ko-KR": "4~5m 간격. 수비 한 명이 둘을 동시에 볼 수 있으면 안 된다.",
                  "es-ES": "Cuatro o cinco metros entre vosotros: un defensor nunca debe poder marcar a dos.",
                  "fr-FR": "Quatre à cinq mètres d'écart : un défenseur ne doit jamais pouvoir en couvrir deux.",
                  "id-ID": "Jarak 4-5 meter. Satu pemain bertahan tak boleh bisa menjaga dua orang.",
                  "ms-MY": "Jarak 4-5 meter. Seorang bek tidak boleh menjaga dua orang.",
                  "th-TH": "ห่างกัน 4-5 เมตร อย่าให้กองหลังคนเดียวคุมได้สองคน",
                  "vi-VN": "Cách nhau 4-5 mét. Một hậu vệ không được kèm cùng lúc hai người."},
            home=[
                P(0.50, 0.32, "1", moves=[(0.30, 0.34, 0)]),
                P(0.15, 0.26, "2", moves=[(0.06, 0.12, 1)]),
                P(0.85, 0.26, "3"),
                P(0.05, 0.11, "4", moves=[(0.16, 0.24, 1)]),
                P(0.95, 0.11, "5"),
            ],
            ball=0,
        ),
        Drill(
            id="bb_pick_and_roll", category="attacking", minutes=15, rel=True, free=True,
            name={"en": "Pick and roll", "en-GB": "Pick and roll", "zh-CN": "挡拆下顺",
                  "zh-TW": "擋拆下順", "ja-JP": "ピック＆ロール", "ko-KR": "픽 앤 롤",
                  "es-ES": "Bloqueo y continuación", "fr-FR": "Pick and roll",
                  "id-ID": "Pick and roll", "ms-MY": "Pick and roll",
                  "th-TH": "พิคแอนด์โรล", "vi-VN": "Chắn và cắt"},
            note={"en": "Set the screen and hold it. The guard's job is to turn the corner tight enough that both defenders are behind him.",
                  "en-GB": "Set the screen and hold it. The guard's job is to turn the corner tight enough that both defenders are behind him.",
                  "zh-CN": "掩护要站稳别动。持球人要贴着掩护转过去，紧到两个防守人都被甩在身后。",
                  "zh-TW": "掩護要站穩別動。持球人要貼著掩護轉過去，緊到兩個防守人都被甩在身後。",
                  "ja-JP": "スクリーンは立てて動かない。ハンドラーは肩を擦るほど密着して回り、2人を背中に置く。",
                  "ko-KR": "스크린은 세우고 버텨라. 핸들러는 어깨를 스칠 만큼 붙어 돌아 두 수비를 등 뒤에 둔다.",
                  "es-ES": "Pon el bloqueo y aguántalo. El base debe girar tan pegado que ambos defensores queden detrás.",
                  "fr-FR": "Pose l'écran et tiens-le. Le meneur doit tourner assez serré pour laisser les deux défenseurs derrière.",
                  "id-ID": "Pasang screen dan tahan. Pengatur bola harus berputar rapat agar dua bek tertinggal.",
                  "ms-MY": "Pasang skrin dan tahan. Pengendali bola pusing rapat.",
                  "th-TH": "ตั้งสกรีนแล้วอยู่นิ่ง คนเลี้ยงต้องเลี้ยวชิดจนกองหลังทั้งสองอยู่ข้างหลัง",
                  "vi-VN": "Dựng màn chắn và giữ yên. Người cầm bóng phải vòng sát để cả hai hậu vệ ở lại sau lưng."},
            home=[
                P(0.50, 0.34, "1", moves=[(0.36, 0.28, 1), (0.40, 0.16, 2)]),
                P(0.38, 0.24, "5", moves=[(0.44, 0.30, 0), (0.52, 0.10, 2)]),
                P(0.85, 0.26, "2"), P(0.05, 0.11, "3"), P(0.95, 0.11, "4"),
            ],
            away=[
                P(0.50, 0.29, "x1", moves=[(0.46, 0.28, 1)]),
                P(0.40, 0.20, "x5", moves=[(0.42, 0.26, 1), (0.44, 0.20, 2)]),
            ],
            ball=0,
        ),
        Drill(
            id="bb_pick_and_pop", category="attacking", minutes=12, rel=True,
            name={"en": "Pick and pop", "en-GB": "Pick and pop", "zh-CN": "挡拆外弹",
                  "zh-TW": "擋拆外彈", "ja-JP": "ピック＆ポップ", "ko-KR": "픽 앤 팝",
                  "es-ES": "Bloqueo y salida", "fr-FR": "Pick and pop",
                  "id-ID": "Pick and pop", "ms-MY": "Pick and pop",
                  "th-TH": "พิคแอนด์ป๊อป", "vi-VN": "Chắn và bật ra"},
            note={"en": "Same screen, opposite read: if the big's defender steps up, he pops instead of rolling.",
                  "en-GB": "Same screen, opposite read: if the big's defender steps up, he pops instead of rolling.",
                  "zh-CN": "同样的掩护，反向判断：只要对方内线上提，掩护人就外弹而不是下顺。",
                  "zh-TW": "同樣的掩護，反向判斷：只要對方內線上提，掩護人就外彈而不是下順。",
                  "ja-JP": "同じスクリーン、逆の判断。ビッグのマークが出てきたらロールではなくポップ。",
                  "ko-KR": "같은 스크린, 반대 판단. 빅맨 수비가 나오면 롤 대신 팝.",
                  "es-ES": "Mismo bloqueo, lectura opuesta: si el defensor del pívot sale, éste abre en vez de continuar.",
                  "fr-FR": "Même écran, lecture inverse : si le défenseur du pivot monte, il ressort au lieu de plonger.",
                  "id-ID": "Screen sama, baca sebaliknya: kalau bek big man maju, dia keluar bukan masuk.",
                  "ms-MY": "Skrin sama, bacaan bertentangan.",
                  "th-TH": "สกรีนเดิม แต่อ่านตรงข้าม ถ้ากองหลังของบิ๊กแมนขึ้นมา ให้ถอยออกแทนการมุด",
                  "vi-VN": "Cùng màn chắn, đọc ngược lại: nếu hậu vệ kèm trung phong dâng lên thì bật ra thay vì cắt vào."},
            home=[
                P(0.50, 0.34, "1", moves=[(0.34, 0.28, 1)]),
                P(0.38, 0.24, "4", moves=[(0.44, 0.30, 0), (0.60, 0.32, 2)]),
                P(0.85, 0.26, "2"), P(0.05, 0.11, "3"), P(0.95, 0.11, "5"),
            ],
            away=[
                P(0.50, 0.29, "x1", moves=[(0.44, 0.28, 1)]),
                P(0.40, 0.20, "x4", moves=[(0.44, 0.26, 1)]),
            ],
            ball=0,
        ),
        Drill(
            id="bb_backdoor_cut", category="attacking", minutes=10, rel=True, free=True,
            name={"en": "Backdoor cut", "en-GB": "Backdoor cut", "zh-CN": "反跑空切",
                  "zh-TW": "反跑空切", "ja-JP": "バックドアカット", "ko-KR": "백도어 컷",
                  "es-ES": "Corte de puerta atrás", "fr-FR": "Backdoor",
                  "id-ID": "Potongan backdoor", "ms-MY": "Potongan backdoor",
                  "th-TH": "ตัดหลังแบ็คดอร์", "vi-VN": "Cắt sau lưng"},
            note={"en": "The cut is the answer to an overplay: two steps out, then hard to the rim the moment he turns his head.",
                  "en-GB": "The cut is the answer to an overplay: two steps out, then hard to the rim the moment he turns his head.",
                  "zh-CN": "对手过度贴防就反跑：先向外两步，等他一转头立刻直插篮下。",
                  "zh-TW": "對手過度貼防就反跑：先向外兩步，等他一轉頭立刻直插籃下。",
                  "ja-JP": "オーバープレイへの答え。外に2歩、相手が顔を向けた瞬間にリムへ全力。",
                  "ko-KR": "과도한 밀착에 대한 답. 밖으로 두 걸음, 상대가 고개를 돌리는 순간 림으로.",
                  "es-ES": "Respuesta al defensor que se pasa: dos pasos fuera y al aro en cuanto gire la cabeza.",
                  "fr-FR": "Réponse au surmarquage : deux pas dehors, puis plein axe dès qu'il tourne la tête.",
                  "id-ID": "Jawaban untuk penjagaan berlebihan: dua langkah keluar, lalu ke ring saat dia menoleh.",
                  "ms-MY": "Jawapan kepada penjagaan berlebihan.",
                  "th-TH": "คำตอบของการประกบเกิน ก้าวออกสองก้าวแล้วพุ่งเข้าห่วงทันทีที่เขาหันหน้า",
                  "vi-VN": "Câu trả lời cho kèm quá sát: bước ra hai bước rồi cắt thẳng vào rổ."},
            home=[
                P(0.50, 0.32, "1"),
                P(0.85, 0.26, "2", moves=[(0.90, 0.32, 0), (0.60, 0.08, 1)]),
                P(0.15, 0.26, "3"), P(0.38, 0.10, "5"),
            ],
            away=[P(0.80, 0.28, "x2", moves=[(0.86, 0.32, 0)])],
            ball=0,
        ),
        Drill(
            id="bb_dho", category="attacking", minutes=12, rel=True,
            name={"en": "Dribble handoff", "en-GB": "Dribble handoff", "zh-CN": "运球交手",
                  "zh-TW": "運球交手", "ja-JP": "ドリブルハンドオフ", "ko-KR": "드리블 핸드오프",
                  "es-ES": "Entrega en bote", "fr-FR": "Handoff en dribble",
                  "id-ID": "Serah bola sambil dribel", "ms-MY": "Serahan sambil dribel",
                  "th-TH": "ส่งมือต่อมือขณะเลี้ยง", "vi-VN": "Trao bóng khi dẫn"},
            note={"en": "Hand it off shoulder to shoulder — a gap the size of a defender is a gap he will use.",
                  "en-GB": "Hand it off shoulder to shoulder — a gap the size of a defender is a gap he will use.",
                  "zh-CN": "交手要肩碰肩，留出一个防守人宽的缝，他就会从缝里挤过来。",
                  "zh-TW": "交手要肩碰肩，留出一個防守人寬的縫，他就會從縫裡擠過來。",
                  "ja-JP": "肩と肩を触れさせて渡す。ディフェンス1人分の隙間は必ず通られる。",
                  "ko-KR": "어깨를 맞대고 건네라. 수비 한 명이 지나갈 틈이면 반드시 지나간다.",
                  "es-ES": "Entrega hombro con hombro: un hueco del tamaño de un defensor es un hueco que usará.",
                  "fr-FR": "Remise épaule contre épaule : un espace de la taille d'un défenseur sera utilisé.",
                  "id-ID": "Serahkan bahu ke bahu — celah seukuran pemain bertahan pasti dilewati.",
                  "ms-MY": "Serah bahu ke bahu.",
                  "th-TH": "ส่งบอลไหล่ชนไหล่ ช่องว่างขนาดคนหนึ่งคือช่องที่เขาจะเสียบ",
                  "vi-VN": "Trao bóng vai kề vai — khe hở vừa một hậu vệ là khe hở sẽ bị luồn."},
            home=[
                P(0.30, 0.32, "1", moves=[(0.44, 0.30, 0), (0.30, 0.16, 2)]),
                P(0.70, 0.30, "2", moves=[(0.52, 0.30, 1), (0.66, 0.14, 2)]),
                P(0.05, 0.11, "3"), P(0.95, 0.11, "4"), P(0.50, 0.09, "5"),
            ],
            away=[P(0.68, 0.26, "x2", moves=[(0.56, 0.26, 1)])],
            ball=0,
        ),
        Drill(
            id="bb_horns_set", category="possession", minutes=12, rel=True,
            name={"en": "Horns set", "en-GB": "Horns set", "zh-CN": "牛角战术",
                  "zh-TW": "牛角戰術", "ja-JP": "ホーンズ", "ko-KR": "혼스 세트",
                  "es-ES": "Sistema Horns", "fr-FR": "Système Horns",
                  "id-ID": "Set Horns", "ms-MY": "Set Horns",
                  "th-TH": "แผนฮอร์นส์", "vi-VN": "Đội hình Horns"},
            note={"en": "Two bigs at the elbows, two in the corners. Whichever screen the defence takes away, the other one is open.",
                  "en-GB": "Two bigs at the elbows, two in the corners. Whichever screen the defence takes away, the other one is open.",
                  "zh-CN": "两个内线站罚球线两肘，两人站底角。防守封掉哪一侧掩护，另一侧就是空的。",
                  "zh-TW": "兩個內線站罰球線兩肘，兩人站底角。防守封掉哪一側掩護，另一側就是空的。",
                  "ja-JP": "ビッグ2人がエルボー、2人がコーナー。守備がどちらのスクリーンを消しても、逆が空く。",
                  "ko-KR": "빅맨 둘은 엘보, 둘은 코너. 수비가 어느 스크린을 지우든 반대쪽이 열린다.",
                  "es-ES": "Dos altos en los codos, dos en las esquinas: el bloqueo que quiten deja libre el otro.",
                  "fr-FR": "Deux intérieurs aux coudes, deux aux corners : l'écran qu'ils enlèvent en libère un autre.",
                  "id-ID": "Dua big man di elbow, dua di sudut. Screen mana pun yang ditutup, satunya terbuka.",
                  "ms-MY": "Dua big man di elbow, dua di penjuru.",
                  "th-TH": "บิ๊กแมนสองคนที่เอลโบว์ อีกสองอยู่มุม ปิดสกรีนฝั่งไหน อีกฝั่งก็ว่าง",
                  "vi-VN": "Hai trung phong ở elbow, hai người ở góc. Chặn màn nào thì màn kia mở."},
            home=[
                P(0.50, 0.34, "1", moves=[(0.62, 0.26, 1)]),
                P(0.33, 0.19, "4", moves=[(0.42, 0.28, 0)]),
                P(0.67, 0.19, "5", moves=[(0.58, 0.28, 0), (0.52, 0.10, 2)]),
                P(0.05, 0.11, "2"), P(0.95, 0.11, "3"),
            ],
            ball=0,
        ),

        # ── finishing / shooting ─────────────────────────────────────────────
        Drill(
            id="bb_catch_and_shoot", category="finishing", minutes=10, rel=True, free=True,
            name={"en": "Catch and shoot", "en-GB": "Catch and shoot", "zh-CN": "接球就投",
                  "zh-TW": "接球就投", "ja-JP": "キャッチ＆シュート", "ko-KR": "캐치 앤 슛",
                  "es-ES": "Recibir y tirar", "fr-FR": "Catch and shoot",
                  "id-ID": "Tangkap dan tembak", "ms-MY": "Tangkap dan baling",
                  "th-TH": "รับแล้วยิง", "vi-VN": "Bắt và ném"},
            note={"en": "Feet and hands ready before the pass arrives. The shot starts on the catch, not after it.",
                  "en-GB": "Feet and hands ready before the pass arrives. The shot starts on the catch, not after it.",
                  "zh-CN": "球到之前脚步和手型就要准备好。出手动作从接球那一刻开始，不是接完再开始。",
                  "zh-TW": "球到之前腳步和手型就要準備好。出手動作從接球那一刻開始，不是接完再開始。",
                  "ja-JP": "パスが来る前に足と手を作る。シュートはキャッチの瞬間に始まる。",
                  "ko-KR": "패스가 오기 전에 발과 손을 준비하라. 슛은 잡는 순간 시작된다.",
                  "es-ES": "Pies y manos listos antes de recibir. El tiro empieza en la recepción.",
                  "fr-FR": "Appuis et mains prêts avant la passe. Le tir commence à la réception.",
                  "id-ID": "Kaki dan tangan siap sebelum bola datang. Tembakan mulai saat menangkap.",
                  "ms-MY": "Kaki dan tangan sedia sebelum bola tiba.",
                  "th-TH": "เตรียมเท้าและมือก่อนบอลมา การยิงเริ่มตั้งแต่จังหวะรับ",
                  "vi-VN": "Chân và tay sẵn sàng trước khi bóng đến. Cú ném bắt đầu từ lúc bắt bóng."},
            home=[
                P(0.50, 0.09, "5"),
                P(0.15, 0.26, "2", moves=[(0.10, 0.20, 0)]),
                P(0.85, 0.26, "3", moves=[(0.90, 0.20, 1)]),
            ],
            ball=0,
        ),
        Drill(
            id="bb_post_finish", category="finishing", minutes=10, rel=True,
            name={"en": "Post finishing", "en-GB": "Post finishing", "zh-CN": "低位终结",
                  "zh-TW": "低位終結", "ja-JP": "ポストの仕上げ", "ko-KR": "포스트 마무리",
                  "es-ES": "Definición en poste", "fr-FR": "Finition au poste",
                  "id-ID": "Penyelesaian di post", "ms-MY": "Penamat di post",
                  "th-TH": "จบสกอร์ในโพสต์", "vi-VN": "Kết thúc ở post"},
            note={"en": "Seal, catch, one dribble, finish over the shoulder away from the help.",
                  "en-GB": "Seal, catch, one dribble, finish over the shoulder away from the help.",
                  "zh-CN": "先卡住位、接球、一次运球、朝远离协防的那侧翻身出手。",
                  "zh-TW": "先卡住位、接球、一次運球、朝遠離協防的那側翻身出手。",
                  "ja-JP": "シール、キャッチ、ワンドリブル、ヘルプと逆の肩越しに決める。",
                  "ko-KR": "자리를 먼저 잡고, 받고, 원 드리블, 헬프 반대쪽 어깨로 마무리.",
                  "es-ES": "Gana la posición, recibe, un bote y define por el hombro contrario a la ayuda.",
                  "fr-FR": "Scelle, réceptionne, un dribble, finis par-dessus l'épaule opposée à l'aide.",
                  "id-ID": "Kunci posisi, tangkap, satu dribel, selesaikan menjauhi help.",
                  "ms-MY": "Kunci kedudukan, tangkap, satu dribel, selesaikan.",
                  "th-TH": "ปิดตัว รับบอล เลี้ยงหนึ่งครั้ง แล้วจบด้านตรงข้ามกับคนมาช่วย",
                  "vi-VN": "Chèn vị trí, bắt bóng, một nhịp dẫn, kết thúc phía xa người bọc lót."},
            home=[
                P(0.38, 0.12, "5", moves=[(0.44, 0.09, 1)]),
                P(0.50, 0.34, "1"),
            ],
            away=[
                P(0.34, 0.10, "x5", moves=[(0.38, 0.08, 1)]),
                P(0.62, 0.12, "x4", moves=[(0.52, 0.10, 1)]),
            ],
            ball=1,
        ),

        # ── defending ────────────────────────────────────────────────────────
        Drill(
            id="bb_closeout", category="defending", minutes=10, rel=True, free=True,
            name={"en": "Closeouts", "en-GB": "Closeouts", "zh-CN": "封盖扑防",
                  "zh-TW": "封蓋撲防", "ja-JP": "クローズアウト", "ko-KR": "클로즈아웃",
                  "es-ES": "Cierres", "fr-FR": "Close-out",
                  "id-ID": "Closeout", "ms-MY": "Closeout",
                  "th-TH": "โคลสเอาท์", "vi-VN": "Áp sát"},
            note={"en": "Sprint two thirds, chop the last third with short steps and a high hand. Flying at a shooter is how you foul him.",
                  "en-GB": "Sprint two thirds, chop the last third with short steps and a high hand. Flying at a shooter is how you foul him.",
                  "zh-CN": "前三分之二全速冲，最后三分之一碎步刹车、举手。冲太猛就是送犯规。",
                  "zh-TW": "前三分之二全速衝，最後三分之一碎步剎車、舉手。衝太猛就是送犯規。",
                  "ja-JP": "3分の2は全力、残りは細かいステップで減速し手を上げる。突っ込めばファウル。",
                  "ko-KR": "3분의 2는 전력, 마지막은 잔발로 감속하고 손을 든다. 날아들면 파울이다.",
                  "es-ES": "Esprinta dos tercios, frena el último con pasos cortos y mano arriba. Volar es hacer falta.",
                  "fr-FR": "Sprinte deux tiers, freine le dernier en petits pas, main haute. Foncer, c'est faire faute.",
                  "id-ID": "Sprint dua pertiga, rem sepertiga terakhir dengan langkah pendek dan tangan tinggi.",
                  "ms-MY": "Pecut dua pertiga, brek sepertiga akhir dengan langkah pendek.",
                  "th-TH": "วิ่งเต็มสองในสาม ที่เหลือย่อก้าวสั้นและยกมือ พุ่งใส่คือฟาวล์",
                  "vi-VN": "Chạy hai phần ba, phanh một phần ba cuối bằng bước ngắn và giơ tay cao."},
            home=[
                P(0.50, 0.12, "x1", moves=[(0.20, 0.24, 0)]),
                P(0.50, 0.09, "x2", moves=[(0.80, 0.24, 1)]),
            ],
            away=[P(0.15, 0.26, "2"), P(0.85, 0.26, "3")],
            ball=None,
        ),
        Drill(
            id="bb_help_and_recover", category="defending", minutes=12, rel=True,
            name={"en": "Help and recover", "en-GB": "Help and recover", "zh-CN": "协防与回位",
                  "zh-TW": "協防與回位", "ja-JP": "ヘルプ＆リカバー", "ko-KR": "헬프 앤 리커버",
                  "es-ES": "Ayuda y recuperación", "fr-FR": "Aide et récupération",
                  "id-ID": "Bantu dan kembali", "ms-MY": "Bantu dan pulih",
                  "th-TH": "ช่วยแล้วกลับ", "vi-VN": "Bọc lót và về vị trí"},
            note={"en": "Help early, recover on the pass — not on the catch. Recovering late is worse than never helping.",
                  "en-GB": "Help early, recover on the pass — not on the catch. Recovering late is worse than never helping.",
                  "zh-CN": "协防要早，回位要在**传球出手时**，不是等对方接到球。回位慢比不协防更糟。",
                  "zh-TW": "協防要早，回位要在傳球出手時，不是等對方接到球。回位慢比不協防更糟。",
                  "ja-JP": "ヘルプは早く、リカバーはパスと同時に。キャッチ後では遅く、助けない方がまし。",
                  "ko-KR": "헬프는 빨리, 복귀는 패스가 나가는 순간에. 늦은 복귀는 안 도운 것만 못하다.",
                  "es-ES": "Ayuda pronto y recupera con el pase, no con la recepción. Llegar tarde es peor que no ayudar.",
                  "fr-FR": "Aide tôt, récupère sur la passe, pas sur la réception. Trop tard vaut moins que rien.",
                  "id-ID": "Bantu lebih awal, kembali saat bola diumpan, bukan saat ditangkap.",
                  "ms-MY": "Bantu awal, pulih ketika bola dihantar.",
                  "th-TH": "ช่วยเร็ว กลับตอนบอลถูกส่ง ไม่ใช่ตอนรับ กลับช้ายังแย่กว่าไม่ช่วย",
                  "vi-VN": "Bọc lót sớm, về vị trí ngay khi bóng được chuyền, không phải khi đối thủ bắt bóng."},
            home=[
                P(0.35, 0.16, "x4", moves=[(0.46, 0.14, 0), (0.32, 0.20, 1)]),
                P(0.50, 0.26, "x1", moves=[(0.48, 0.22, 0)]),
            ],
            away=[
                P(0.55, 0.30, "1", moves=[(0.50, 0.16, 0)]),
                P(0.20, 0.24, "4", moves=[(0.14, 0.24, 1)]),
            ],
            ball=None,
        ),
        Drill(
            id="bb_box_out", category="defending", minutes=8, rel=True, free=True,
            name={"en": "Box out", "en-GB": "Box out", "zh-CN": "卡位篮板",
                  "zh-TW": "卡位籃板", "ja-JP": "ボックスアウト", "ko-KR": "박스아웃",
                  "es-ES": "Bloqueo de rebote", "fr-FR": "Écran retard au rebond",
                  "id-ID": "Box out", "ms-MY": "Box out",
                  "th-TH": "บ็อกซ์เอาท์", "vi-VN": "Chèn bắt bật"},
            note={"en": "Find your man before you find the ball. Contact first, then go get it — every rebound is won a second before it comes off.",
                  "en-GB": "Find your man before you find the ball. Contact first, then go get it — every rebound is won a second before it comes off.",
                  "zh-CN": "先找人，再找球。先接触卡住，再去抢 —— 篮板是在球弹出来之前一秒决定的。",
                  "zh-TW": "先找人，再找球。先接觸卡住，再去搶 —— 籃板是在球彈出來之前一秒決定的。",
                  "ja-JP": "ボールより先に人を見つける。当たってから取りに行く。リバウンドは落ちる1秒前に決まる。",
                  "ko-KR": "공보다 사람을 먼저 찾아라. 접촉 먼저, 그다음 잡으러 간다.",
                  "es-ES": "Encuentra a tu hombre antes que al balón. Contacto primero: el rebote se gana un segundo antes.",
                  "fr-FR": "Trouve ton joueur avant le ballon. Contact d'abord : le rebond se gagne une seconde plus tôt.",
                  "id-ID": "Temukan lawanmu sebelum bola. Kontak dulu, baru ambil.",
                  "ms-MY": "Cari lawan anda dahulu, bukan bola.",
                  "th-TH": "หาคนก่อนหาบอล ปะทะก่อนแล้วค่อยไปเก็บ",
                  "vi-VN": "Tìm người trước khi tìm bóng. Tiếp xúc trước rồi mới bắt bóng."},
            home=[
                P(0.38, 0.14, "x4", moves=[(0.38, 0.18, 0), (0.42, 0.10, 1)]),
                P(0.62, 0.14, "x5", moves=[(0.62, 0.18, 0), (0.58, 0.10, 1)]),
            ],
            away=[
                P(0.38, 0.22, "4", moves=[(0.38, 0.16, 0)]),
                P(0.62, 0.22, "5", moves=[(0.62, 0.16, 0)]),
            ],
            ball=None,
        ),

        # ── inbounds / special situations ────────────────────────────────────
        Drill(
            id="bb_blob_box", category="setpiece", minutes=10, rel=True, free=True,
            name={"en": "Baseline inbounds: box", "en-GB": "Baseline inbounds: box",
                  "zh-CN": "底线发球：箱型战术", "zh-TW": "底線發球：箱型戰術",
                  "ja-JP": "エンドラインOB：ボックス", "ko-KR": "엔드라인 인바운드: 박스",
                  "es-ES": "Saque de fondo: caja", "fr-FR": "Remise en jeu ligne de fond : boîte",
                  "id-ID": "Lemparan baseline: box", "ms-MY": "Lontaran baseline: box",
                  "th-TH": "ส่งบอลใต้แป้น: บ็อกซ์", "vi-VN": "Ném biên cuối sân: đội hình hộp"},
            note={"en": "The first cutter is a decoy; the screener becomes the target. Count out loud — five seconds goes fast.",
                  "en-GB": "The first cutter is a decoy; the screener becomes the target. Count out loud — five seconds goes fast.",
                  "zh-CN": "第一个跑动的人是幌子，掩护的人才是目标。出声数秒 —— 五秒过得很快。",
                  "zh-TW": "第一個跑動的人是幌子，掩護的人才是目標。出聲數秒 —— 五秒過得很快。",
                  "ja-JP": "最初のカッターは囮、スクリーナーが本命。声に出して数える。5秒は速い。",
                  "ko-KR": "첫 커터는 미끼, 스크리너가 목표다. 소리 내어 세라 — 5초는 짧다.",
                  "es-ES": "El primer cortador es señuelo; el bloqueador es el objetivo. Cuenta en voz alta.",
                  "fr-FR": "Le premier coupeur est un leurre, le poseur d'écran est la cible. Compte à voix haute.",
                  "id-ID": "Pemotong pertama umpan, pemasang screen targetnya. Hitung keras — 5 detik cepat.",
                  "ms-MY": "Pemotong pertama adalah umpan, pemasang skrin sasaran.",
                  "th-TH": "คนตัดคนแรกคือตัวล่อ คนตั้งสกรีนคือเป้าหมาย นับออกเสียง ห้าวินาทีหมดเร็ว",
                  "vi-VN": "Người cắt đầu là mồi nhử, người dựng màn mới là mục tiêu. Đếm to — năm giây trôi nhanh."},
            home=[
                P(0.50, 0.03, "1"),
                P(0.38, 0.10, "2", moves=[(0.10, 0.12, 0)]),
                P(0.62, 0.10, "3", moves=[(0.66, 0.16, 0)]),
                P(0.38, 0.20, "4", moves=[(0.44, 0.14, 0), (0.46, 0.07, 1)]),
                P(0.62, 0.20, "5", moves=[(0.86, 0.20, 0)]),
            ],
            away=[
                P(0.42, 0.14, "x2"), P(0.58, 0.14, "x3"), P(0.50, 0.20, "x4"),
            ],
            ball=0,
        ),
        Drill(
            id="bb_press_break", category="setpiece", minutes=12, rel=True,
            name={"en": "Press break", "en-GB": "Press break", "zh-CN": "破全场紧逼",
                  "zh-TW": "破全場緊逼", "ja-JP": "プレスブレイク", "ko-KR": "프레스 브레이크",
                  "es-ES": "Romper la presión", "fr-FR": "Casser la pression",
                  "id-ID": "Membongkar press", "ms-MY": "Memecah tekanan",
                  "th-TH": "แก้เพรส", "vi-VN": "Phá pressing toàn sân"},
            note={"en": "Get it to the middle. A ball in the centre of the floor beats a press; a ball on the sideline feeds it.",
                  "en-GB": "Get it to the middle. A ball in the centre of the floor beats a press; a ball on the sideline feeds it.",
                  "zh-CN": "把球送到中路。球在场地中间就破了紧逼，球贴边线就是在喂给他们。",
                  "zh-TW": "把球送到中路。球在場地中間就破了緊逼，球貼邊線就是在餵給他們。",
                  "ja-JP": "ボールを中央へ。中央のボールはプレスを破り、サイドラインのボールは餌になる。",
                  "ko-KR": "공을 가운데로. 중앙의 공은 프레스를 깨고, 사이드라인의 공은 먹잇감이다.",
                  "es-ES": "Lleva el balón al centro: en el medio rompes la presión, en la banda la alimentas.",
                  "fr-FR": "Amène le ballon au centre : au milieu tu casses la presse, sur la ligne tu la nourris.",
                  "id-ID": "Bawa bola ke tengah. Bola di tengah memecah press; di garis samping justru dimakan.",
                  "ms-MY": "Bawa bola ke tengah.",
                  "th-TH": "พาบอลเข้ากลางสนาม บอลกลางแก้เพรสได้ บอลริมเส้นคืออาหารของเขา",
                  "vi-VN": "Đưa bóng vào giữa sân. Bóng ở giữa phá được pressing, bóng sát biên là mồi."},
            home=[
                P(0.50, 0.97, "5"),
                P(0.22, 0.86, "1", moves=[(0.30, 0.78, 0)]),
                P(0.78, 0.86, "2", moves=[(0.70, 0.78, 0)]),
                P(0.50, 0.68, "3", moves=[(0.50, 0.56, 1)]),
                P(0.50, 0.40, "4"),
            ],
            away=[
                P(0.30, 0.88, "x1", moves=[(0.30, 0.82, 0)]),
                P(0.70, 0.88, "x2", moves=[(0.70, 0.82, 0)]),
                P(0.50, 0.74, "x3", moves=[(0.44, 0.66, 1)]),
            ],
            ball=0,
        ),

        # ── small-sided ──────────────────────────────────────────────────────
        Drill(
            id="bb_3v3_no_dribble", category="ssg", minutes=15, rel=True, free=True,
            name={"en": "3v3, no dribble", "en-GB": "3v3, no dribble", "zh-CN": "3v3 不许运球",
                  "zh-TW": "3v3 不許運球", "ja-JP": "3対3 ノードリブル", "ko-KR": "3대3 노 드리블",
                  "es-ES": "3v3 sin bote", "fr-FR": "3c3 sans dribble",
                  "id-ID": "3v3 tanpa dribel", "ms-MY": "3v3 tanpa dribel",
                  "th-TH": "3v3 ห้ามเลี้ยง", "vi-VN": "3v3 không dẫn bóng"},
            note={"en": "Without the dribble the only way to move the ball is to move yourself. Cut every time you pass.",
                  "en-GB": "Without the dribble the only way to move the ball is to move yourself. Cut every time you pass.",
                  "zh-CN": "不能运球，球就只能靠人跑动来移动。每传一次就切一次。",
                  "zh-TW": "不能運球，球就只能靠人跑動來移動。每傳一次就切一次。",
                  "ja-JP": "ドリブルがなければ、動かせるのは自分だけ。パスのたびにカットする。",
                  "ko-KR": "드리블이 없으면 공을 옮기는 유일한 방법은 내가 움직이는 것이다.",
                  "es-ES": "Sin bote, la única forma de mover el balón es moverte tú. Corta cada vez que pases.",
                  "fr-FR": "Sans dribble, la seule façon de faire circuler le ballon est de bouger. Coupe après chaque passe.",
                  "id-ID": "Tanpa dribel, satu-satunya cara memindahkan bola adalah bergerak.",
                  "ms-MY": "Tanpa dribel, satu-satunya cara ialah bergerak.",
                  "th-TH": "ไม่มีการเลี้ยง วิธีเดียวที่บอลจะเคลื่อนคือคนต้องเคลื่อน ส่งแล้วตัดทุกครั้ง",
                  "vi-VN": "Không dẫn bóng thì cách duy nhất để bóng di chuyển là người di chuyển."},
            home=[
                P(0.50, 0.34, "1", moves=[(0.40, 0.12, 1)]),
                P(0.15, 0.26, "2", moves=[(0.22, 0.30, 0)]),
                P(0.85, 0.26, "3"),
            ],
            away=[
                P(0.46, 0.28, "x1", moves=[(0.42, 0.24, 1)]),
                P(0.20, 0.22, "x2", moves=[(0.24, 0.26, 0)]),
                P(0.80, 0.22, "x3"),
            ],
            ball=0,
        ),
        Drill(
            id="bb_transition_2v1", category="ssg", minutes=10, rel=True,
            name={"en": "2v1 transition", "en-GB": "2v1 transition", "zh-CN": "2打1快攻",
                  "zh-TW": "2打1快攻", "ja-JP": "2対1 速攻", "ko-KR": "2대1 속공",
                  "es-ES": "Transición 2v1", "fr-FR": "Transition 2c1",
                  "id-ID": "Transisi 2v1", "ms-MY": "Peralihan 2v1",
                  "th-TH": "ทรานสิชัน 2v1", "vi-VN": "Chuyển đổi 2v1"},
            note={"en": "Attack the defender's inside shoulder. Pass only when he commits — an early pass lets him guard both.",
                  "en-GB": "Attack the defender's inside shoulder. Pass only when he commits — an early pass lets him guard both.",
                  "zh-CN": "冲击防守人内侧肩膀。等他站定再传 —— 传早了他一个人能防两个。",
                  "zh-TW": "衝擊防守人內側肩膀。等他站定再傳 —— 傳早了他一個人能防兩個。",
                  "ja-JP": "ディフェンスの内側の肩を攻める。相手が出てから出す。早いパスは1人に2人守らせる。",
                  "ko-KR": "수비의 안쪽 어깨를 공략하라. 그가 나올 때만 패스 — 일찍 주면 혼자 둘을 막는다.",
                  "es-ES": "Ataca el hombro interior del defensor. Pasa solo cuando se comprometa.",
                  "fr-FR": "Attaque l'épaule intérieure du défenseur. Ne passe que lorsqu'il s'engage.",
                  "id-ID": "Serang bahu dalam pemain bertahan. Umpan hanya saat dia maju.",
                  "ms-MY": "Serang bahu dalam pemain bertahan.",
                  "th-TH": "พุ่งเข้าหาไหล่ด้านในของกองหลัง จ่ายเมื่อเขาขยับเท่านั้น",
                  "vi-VN": "Tấn công vai trong của hậu vệ. Chỉ chuyền khi anh ta lao ra."},
            home=[
                P(0.35, 0.55, "1", moves=[(0.42, 0.26, 0), (0.46, 0.12, 1)]),
                P(0.70, 0.55, "2", moves=[(0.66, 0.26, 0), (0.58, 0.10, 1)]),
            ],
            away=[P(0.50, 0.22, "x1", moves=[(0.46, 0.20, 1)])],
            ball=0,
        ),
    ]


CATALOGUE = {"soccer": soccer_drills, "basketball": basketball_drills}


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
                "free": d.free,
                "offSurface": d.off_surface,
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
