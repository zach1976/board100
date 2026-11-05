"""Volleyball: what the squares and zones are, and how each drill keeps going."""
from .rules_common import FEED_RULES, POINT_RULES, SERVE_IN_RULES, SERVE_RULES


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


PEPPER = _t(
    "Pass, set, hit back and forth without letting the ball drop; when it does, the one nearest picks it up and restarts. Two minutes, then swap partners.",
    "垫、传、扣来回不落地，落地由离球近的人捡起重来；2 分钟后换搭档。",
    "墊、傳、扣來回不落地，落地由離球近的人撿起重來；2 分鐘後換搭檔。")

ROTATION = _t(
    "One serve per rep; the side-out is played out, and after three serves the receiving side rotates one position so every rotation is drilled. Round the whole clock twice, then the servers swap.",
    "一球一发，打完一个接发回合；每发 3 球接发方轮转一个位置，六个轮次都练到。转两圈后换发球者。",
    "一球一發，打完一個接發回合；每發 3 球接發方輪轉一個位置，六個輪次都練到。轉兩圈後換發球者。")

PEPPER3 = _t(
    "Hit, dig, set round the triangle without letting the ball drop; every ten contacts the three move on one role — hitter to digger, digger to setter, setter to hitter.",
    "扣、垫、传绕三角不落地；每 10 次触球三人轮换一个角色——扣球的去防守，防守的去二传，二传去扣球。",
    "扣、墊、傳繞三角不落地；每 10 次觸球三人輪換一個角色——扣球的去防守，防守的去二傳，二傳去扣球。")

PAIRS = _t(
    "Count the contacts without the ball touching the floor; at 50 both take a step further apart and start again, and when it drops the count goes back to zero.",
    "数不落地的触球次数；到 50 次两人各退一步重新开始，球落地就从零重数。",
    "數不落地的觸球次數；到 50 次兩人各退一步重新開始，球落地就從零重數。")

WASH = _t(
    "One side serves; the receiving side must win that rally and then the free ball the coach sends in straight after. Both won is a big point, a split is a wash and nobody scores. First to three big points, then both sides rotate one position.",
    "一方发球，接发方必须赢下这一分，再赢下教练紧接着送进来的调整球。两球都赢得一个大分，一胜一负算抵消、谁都不得分。先得 3 个大分的一方赢，然后两边各轮转一个位置。",
    "一方發球，接發方必須贏下這一分，再贏下教練緊接著送進來的調整球。兩球都贏得一個大分，一勝一負算抵消、誰都不得分。先得 3 個大分的一方贏，然後兩邊各輪轉一個位置。")

KING = _t(
    "The challengers serve. If they win the rally they walk round the post to the kings' side and the kings go to the back of the line; only the kings' side scores. First pair to seven wins, then the pairs are reshuffled.",
    "挑战者发球。挑战者赢下这一分就绕过网柱换到擂主一侧，原擂主排到队尾；只有擂主一侧赢球才得分。先得 7 分的一对获胜，然后重新分组。",
    "挑戰者發球。挑戰者贏下這一分就繞過網柱換到擂主一側，原擂主排到隊尾；只有擂主一側贏球才得分。先得 7 分的一對獲勝，然後重新分組。")

FLOW = {
    "vb_warm_pepper_three": PEPPER3,
    "vb_warm_partner_pass": PAIRS, "vb_warm_partner_set": PAIRS,
    "vb_pass_overhead": SERVE_RULES,
    "vb_pass_": FEED_RULES, "vb_oos_": FEED_RULES, "vb_dig_": FEED_RULES,
    "vb_spike_": FEED_RULES, "vb_offspeed_": FEED_RULES, "vb_combo_": FEED_RULES,
    "vb_setter_off_net": SERVE_IN_RULES,
    "vb_counter_cover": FEED_RULES, "vb_counter_": SERVE_IN_RULES,
    "vb_rot51_": ROTATION, "vb_rot62_": ROTATION,
    "vb_game_wash": WASH, "vb_game_king": KING,
    "vb_warm_pepper": PEPPER,
    "vb_warm_": FEED_RULES,
    "vb_receive_": ROTATION,
    "vb_set_": FEED_RULES, "vb_setter_": FEED_RULES,
    "vb_free_ball": SERVE_IN_RULES, "vb_down_ball": SERVE_IN_RULES,
    "vb_attack_": FEED_RULES,
    "vb_block_": FEED_RULES, "vb_defense_": SERVE_IN_RULES, "vb_cover_hitter": FEED_RULES,
    "vb_serve_": SERVE_RULES,
    "vb_game_": POINT_RULES,
}

TARGET = _t(
    "the square is the setter's target — where the pass has to arrive",
    "方块是二传的目标点，一传要把球送到这里",
    "方塊是二傳的目標點，一傳要把球送到這裡")

SHOT = _t(
    "the shaded zone is where this shot has to land",
    "阴影区是这一种进攻要打到的落点",
    "陰影區是這一種進攻要打到的落點")

GEAR = {
    "vb_spike_": SHOT, "vb_offspeed_": SHOT, "vb_warm_hitting_lines": SHOT,
    "vb_pass_": TARGET, "vb_dig_": TARGET, "vb_combo_": TARGET,
    "vb_counter_": TARGET, "vb_rot51_": TARGET, "vb_rot62_": TARGET,
    "vb_game_wash": TARGET, "vb_setter_off_net": TARGET,
    "vb_receive_": TARGET,
    "vb_set_": _t(
        "the square is where the set has to be placed for the hitter",
        "方块是二传要把球送到的攻手起跳点",
        "方塊是二傳要把球送到的攻手起跳點"),
    "vb_setter_": _t(
        "the square is the spot the setter releases to, where the pass is aimed",
        "方块是二传插上要到的位置，一传瞄准这里",
        "方塊是二傳插上要到的位置，一傳瞄準這裡"),
    "vb_free_ball": TARGET, "vb_down_ball": TARGET,
    "vb_attack_": _t(
        "the square is where the set is placed for this attack",
        "方块是这一种进攻的二传落点",
        "方塊是這一種進攻的二傳落點"),
    "vb_serve_": _t(
        "the shaded zone is where the serve has to land",
        "阴影区是发球要落的区域",
        "陰影區是發球要落的區域"),
    "vb_cover_hitter": _t(
        "the shaded zone is where a blocked ball comes down — the cover has to be under it",
        "阴影区是被拦回的球会落下的区域，保护的人要站在下面",
        "陰影區是被攔回的球會落下的區域，保護的人要站在下面"),
    "vb_setter_dump": _t(
        "the shaded zone is where the dump has to drop, behind the block",
        "阴影区是二次球偷吊要落的区域，在拦网身后",
        "陰影區是二次球偷吊要落的區域，在攔網身後"),
}


# ── 2026-10-13: the rotation families (volleyball.py, after rotation_family) ─
#
# Written here in English and Chinese; the other locales are in
# i18n/volleyball.json, keyed by the English, and full() pulls in every
# locale that table has for a sentence — a missing one fails the build.

import json as _json
from pathlib import Path as _Path

_I18N = _json.loads((_Path(__file__).parent / "i18n" / "volleyball.json")
                    .read_text(encoding="utf-8"))


def full(t: dict) -> dict:
    """An en/zh text in every locale i18n/volleyball.json has for it."""
    extra = _I18N.get(t["en"])
    if not extra:
        raise KeyError(f"no i18n/volleyball.json entry for {t['en'][:70]!r}")
    out = dict(t)
    for loc, text in extra.items():
        out.setdefault(loc, text)
    return out


# Family names: "<name> <rotation>".
NAME_CUP51 = _t("5-1 four-passer cup rotation", "5-1 四人杯形接发轮次", "5-1 四人杯形接發輪次")
NAME_W51 = _t("5-1 five-passer W rotation", "5-1 五人W形接发轮次", "5-1 五人W形接發輪次")
NAME_CUP62 = _t("6-2 four-passer cup rotation", "6-2 四人杯形接发轮次", "6-2 四人杯形接發輪次")
NAME_W42 = _t("4-2 W receive rotation", "4-2 W形接发轮次", "4-2 W形接發輪次")
NAME_TRANS = _t("5-1 serve and transition rotation", "5-1 发球防反轮次", "5-1 發球防反輪次")
NAME_LIBERO = _t("Libero in for the middle, rotation", "自由人替换副攻轮次", "自由人替換副攻輪次")
NAME_TARGET = _t("Target serve", "定点发球", "定點發球")
NAME_SECOND = _t("Second ball off the net", "离网一传后的二传", "離網一傳後的二傳")

# Target-serve variants, by key.
TARGET_VARIANT = {
    "zone1": _t("to zone 1", "1 号位", "1 號位"),
    "zone5": _t("to zone 5", "5 号位", "5 號位"),
    "zone6": _t("to zone 6", "6 号位", "6 號位"),
    "short2": _t("short to zone 2", "短球 2 号位", "短球 2 號位"),
    "short4": _t("short to zone 4", "短球 4 号位", "短球 4 號位"),
    "short3": _t("short to zone 3", "短球 3 号位", "短球 3 號位"),
    "seam56": _t("into the 5–6 seam", "5、6 号位结合部", "5、6 號位結合部"),
    "seam61": _t("into the 6–1 seam", "6、1 号位结合部", "6、1 號位結合部"),
    "hitter": _t("at the passing hitter", "接一传的攻手", "接一傳的攻手"),
    "path": _t("into the setter's path", "二传插上路线", "二傳插上路線"),
}

# Second-ball variants: the option, in rotation r.
SECOND_VARIANT = {
    (opt, r): _t(f"{en}, rotation {r}", f"{zh}，第 {r} 轮", f"{tw}，第 {r} 輪")
    for opt, en, zh, tw in (("back", "back set", "背传", "背傳"),
                            ("pipe", "pipe", "后排插上进攻", "後排插上進攻"),
                            ("dump", "setter dump", "二传二次球", "二傳二次球"))
    for r in (4, 5, 6)
}

# The coaching points.
POINT_CUP51 = _t(
    "Four passers means four seams. The two deep passers take everything at chest height and above, the wings take only the short ball in front of them, and every ball between two passers is called before it crosses the net.",
    "四人接发就有四条结合部。后面两人负责胸口以上的所有球，两翼只接落在自己身前的短球；两人之间的每一个球，都要在过网之前喊出来。",
    "四人接發就有四條結合部。後面兩人負責胸口以上的所有球，兩翼只接落在自己身前的短球；兩人之間的每一個球，都要在過網之前喊出來。")
POINT_W51 = _t(
    "Five passers cover the floor but crowd it. The front three let anything above the waist go to the two behind them, and the setter is the one player who never passes.",
    "五人接发把场地铺满，也把场地挤满。前排三人腰以上的球一律让给身后两人；二传是唯一一个永远不接一传的人。",
    "五人接發把場地鋪滿，也把場地擠滿。前排三人腰以上的球一律讓給身後兩人；二傳是唯一一個永遠不接一傳的人。")
POINT_CUP62 = _t(
    "Three front-row hitters every rotation only pays off if the pass lets the setter use them. The opposite who passes in the cup must be back in her approach before the setter's hands touch the ball.",
    "每一轮前排三个攻手，只有一传让二传用得上时才算优势。在杯形里接一传的接应，必须在二传触球之前回到助跑位置。",
    "每一輪前排三個攻手，只有一傳讓二傳用得上時才算優勢。在杯形裡接一傳的接應，必須在二傳觸球之前回到助跑位置。")
POINT_W42 = _t(
    "In a 4-2 the setter in the front row never passes: she waits at the net and the five behind her receive. Pass high to the middle of the net — she has no run to make, so a pass to her is a pass to the target.",
    "4-2 体系里前排的二传从不接一传：她在网前等，身后五个人接发。一传高高地垫到网中间——她不用插上，垫给她就是垫到目标点。",
    "4-2 體系裡前排的二傳從不接一傳：她在網前等，身後五個人接發。一傳高高地墊到網中間——她不用插上，墊給她就是墊到目標點。")
POINT_TRANS = _t(
    "The serve is the first touch of your defence. The server runs straight to her base, the block is set before their setter touches the ball, and the dig goes high to the middle so the setter can get to it from wherever she is.",
    "发球是防守的第一次触球。发球员发完直接跑到自己的防守位置，对方二传触球前拦网就要站好，起球要高、要到场地中间，让二传无论在哪儿都能赶到。",
    "發球是防守的第一次觸球。發球員發完直接跑到自己的防守位置，對方二傳觸球前攔網就要站好，起球要高、要到場地中間，讓二傳無論在哪兒都能趕到。")
POINT_TARGET = _t(
    "Choose the target before the toss and serve at the rotation, not at the court: the passer who also has to attack, the seam between two passers, the lane the setter runs through. A serve aimed at a problem forces a bad pass even when it is not an ace.",
    "抛球之前就选好目标，发向对方的轮次而不是发向场地：既要接一传又要进攻的人、两个接球人之间的结合部、二传插上要跑的路线。瞄准问题发的球，即使不是直接得分，也能逼出一个坏一传。",
    "拋球之前就選好目標，發向對方的輪次而不是發向場地：既要接一傳又要進攻的人、兩個接球人之間的結合部、二傳插上要跑的路線。瞄準問題發的球，即使不是直接得分，也能逼出一個壞一傳。")
POINT_SECOND = _t(
    "When the pass is off the net, the setter's feet decide the options. Square to the left pin and the back set, the pipe and the dump all come out of the same posture; set from a different one and the block knows before the ball does.",
    "一传离网时，二传的脚决定了选择。身体正对 4 号位标志杆，背传、后排插上和二次球都从同一个姿势出手；换一个姿势传，对方拦网比球先知道去向。",
    "一傳離網時，二傳的腳決定了選擇。身體正對 4 號位標誌桿，背傳、後排插上和二次球都從同一個姿勢出手；換一個姿勢傳，對方攔網比球先知道去向。")
POINT_LIBERO = _t(
    "The libero comes on for the back-row middle between rallies, through the replacement zone on her own bench side, and passes in his lane; he waits there until he rotates to the front row and comes back on for her.",
    "自由人在两球之间从本方替补席一侧的替换区上场，换下后排副攻，接他那条通道的一传；副攻就在替换区等着，转到前排时再上来把她换下。",
    "自由人在兩球之間從本方替補席一側的替換區上場，換下後排副攻，接他那條通道的一傳；副攻就在替換區等著，轉到前排時再上來把她換下。")

# Hand-written 组织 lines: who the letters are.
SETUP_51 = _t(
    "S is the setter, O1 and O2 the outside hitters, M the front-row middle, OP the opposite and L the libero in for the back-row middle; their server (SV) stands behind their end line. Everyone is in a legal position when the serve is struck",
    "S 是二传，O1、O2 是主攻，M 是前排副攻，OP 是接应，L 是替换后排副攻的自由人；对方发球员（SV）站在对方端线后。发球击球时所有人站位合法",
    "S 是二傳，O1、O2 是主攻，M 是前排副攻，OP 是接應，L 是替換後排副攻的自由人；對方發球員（SV）站在對方端線後。發球擊球時所有人站位合法")
SETUP_62 = _t(
    "S1 and S2 are the two setters — the one in the back row sets, the one in the front row hits as the opposite — O1 and O2 the outside hitters, M the front-row middle and L the libero; their server (SV) stands behind their end line. Everyone is in a legal position when the serve is struck",
    "S1、S2 是两名二传——后排的那名组织，前排的那名当接应进攻；O1、O2 是主攻，M 是前排副攻，L 是自由人；对方发球员（SV）站在对方端线后。发球击球时所有人站位合法",
    "S1、S2 是兩名二傳——後排的那名組織，前排的那名當接應進攻；O1、O2 是主攻，M 是前排副攻，L 是自由人；對方發球員（SV）站在對方端線後。發球擊球時所有人站位合法")
SETUP_42 = _t(
    "S1 and S2 are the two setters — the one in the front row sets, the one in the back row passes and hits — O1 and O2 the outside hitters and M1 and M2 the middles, with no libero; their server (SV) stands behind their end line. Everyone is in a legal position when the serve is struck",
    "S1、S2 是两名二传——前排的那名组织，后排的那名接一传、进攻；O1、O2 是主攻，M1、M2 是副攻，不设自由人；对方发球员（SV）站在对方端线后。发球击球时所有人站位合法",
    "S1、S2 是兩名二傳——前排的那名組織，後排的那名接一傳、進攻；O1、O2 是主攻，M1、M2 是副攻，不設自由人；對方發球員（SV）站在對方端線後。發球擊球時所有人站位合法")
SETUP_TRANS = _t(
    "Our six in a 5-1 serve from behind our end line: S the setter, O1 and O2 the outside hitters, M the middles, OP the opposite and L the libero, in for the back-row middle unless he is the one serving. Their passer (P), setter (S) and hitter (A) play the ball back over the net",
    "我方 5-1 阵容六人从本方端线后发球：S 是二传，O1、O2 是主攻，M 是副攻，OP 是接应，L 是自由人——替换后排副攻，轮到副攻发球时除外。对方的接球人（P）、二传（S）和攻手（A）把球打回来",
    "我方 5-1 陣容六人從本方端線後發球：S 是二傳，O1、O2 是主攻，M 是副攻，OP 是接應，L 是自由人——替換後排副攻，輪到副攻發球時除外。對方的接球人（P）、二傳（S）和攻手（A）把球打回來")
SETUP_TARGET = _t(
    "Our server (SV) stands behind our end line. Across the net their six stand in the receive formation of the rotation the serve is aimed at: S the setter, O1 and O2 the outside hitters, M the front-row middle, OP the opposite and L the libero",
    "我方发球员（SV）站在本方端线后。网对面，对方六人按这一发要针对的轮次站好接发球阵型：S 是二传，O1、O2 是主攻，M 是前排副攻，OP 是接应，L 是自由人",
    "我方發球員（SV）站在本方端線後。網對面，對方六人按這一發要針對的輪次站好接發球陣型：S 是二傳，O1、O2 是主攻，M 是前排副攻，OP 是接應，L 是自由人")
SETUP_SECOND = _t(
    "S is the setter, O1 and O2 the outside hitters, M the front-row middle, OP the opposite and L the libero; their server (SV) stands behind their end line and two blockers (B) wait at the net",
    "S 是二传，O1、O2 是主攻，M 是前排副攻，OP 是接应，L 是自由人；对方发球员（SV）站在对方端线后，两名拦网队员（B）在网前等着",
    "S 是二傳，O1、O2 是主攻，M 是前排副攻，OP 是接應，L 是自由人；對方發球員（SV）站在對方端線後，兩名攔網隊員（B）在網前等著")
SETUP_LIBERO = _t(
    "S is the setter, O1 and O2 the outside hitters, M1 and M2 the middles and OP the opposite; L, the libero, waits in the replacement zone beside the court, and their server (SV) stands behind their end line",
    "S 是二传，O1、O2 是主攻，M1、M2 是副攻，OP 是接应；自由人 L 在场边的替换区等候，对方发球员（SV）站在对方端线后",
    "S 是二傳，O1、O2 是主攻，M1、M2 是副攻，OP 是接應；自由人 L 在場邊的替換區等候，對方發球員（SV）站在對方端線後")

TRANSITION = _t(
    "Our side serves every ball; the far side plays it back at the base defence and the rally runs to the floor. Six serves, then both sides rotate one position.",
    "每一球都由我方发球，对方把球打回我方的基本防守阵型，打到落地为止。发 6 球后两边各轮转一个位置。",
    "每一球都由我方發球，對方把球打回我方的基本防守陣型，打到落地為止。發 6 球後兩邊各輪轉一個位置。")
OFF_NET = _t(
    "the square is the setter's target; this pass misses it, two metres off the net",
    "方块是二传的目标点；这一传没到位，离网两米",
    "方塊是二傳的目標點；這一傳沒到位，離網兩米")

# Families' 连贯 and 器材 lines, ahead of the prefixes that would catch them.
# The receive boards are vb_receive_* and pick up ROTATION and TARGET there.
FLOW = {"vb_transition_": full(TRANSITION), "vb_second_ball_": SERVE_IN_RULES,
        **FLOW}
GEAR = {"vb_transition_": TARGET, "vb_second_ball_": full(OFF_NET), **GEAR}
