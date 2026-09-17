"""Baseball: what the squares and zones are, and how each drill keeps going."""
from .rules_common import BASEBALL_RULES


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


WARM_FLOW = _t(
    "Throw and catch without a break, backing up a few steps every ten throws until the distance is right, then closing back in; five minutes, then into the next drill.",
    "不间断地传接，每 10 次后退几步拉开距离到位，再逐步收回来；做 5 分钟进入下一项。",
    "不間斷地傳接，每 10 次後退幾步拉開距離到位，再逐步收回來；做 5 分鐘進入下一項。")

BULLPEN_FLOW = _t(
    "A bullpen is thrown in sets of fifteen pitches with the catcher calling each one; rest a minute between sets, three sets, and the next pitcher steps in.",
    "牛棚每组 15 球，由捕手配每一球；组间休息 1 分钟，投 3 组换下一名投手。",
    "牛棚每組 15 球，由捕手配每一球；組間休息 1 分鐘，投 3 組換下一名投手。")

FLOW = {
    "bb_warm_long_toss": WARM_FLOW,
    "bb_warm_": BASEBALL_RULES,
    "bb_pitch_bullpen": BULLPEN_FLOW,
    "bb_": BASEBALL_RULES,
}

BASES = _t(
    "the squares are the bases — home, first, second, third",
    "方块是垒包：本垒、一垒、二垒、三垒",
    "方塊是壘包：本壘、一壘、二壘、三壘")

GEAR = {
    "bb_warm_long_toss": _t(
        "the square is the throwing partner's target: aim every throw at his chest",
        "方块是传球目标，每一球都对着搭档胸口传",
        "方塊是傳球目標，每一球都對著搭檔胸口傳"),
    "bb_warm_infield_outfield": _t(
        "the square is home plate, where the fungo hitter stands and the throws come back to",
        "方块是本垒板，打击手在这里打球，球也传回这里",
        "方塊是本壘板，打擊手在這裡打球，球也傳回這裡"),
    "bb_warm_pitchers_fielding": _t(
        "the square is home plate; the pitcher works from the mound in front of it",
        "方块是本垒板，投手在它前方的投手丘上练习",
        "方塊是本壘板，投手在它前方的投手丘上練習"),
    "bb_dp_": BASES,
    "bb_relay_": _t(
        "the two squares are the bases the throw is going to; the shaded zone is where the cut-off man has to be standing",
        "两个方块是要传向的垒包，阴影区是切传手必须站的位置",
        "兩個方塊是要傳向的壘包，陰影區是切傳手必須站的位置"),
    "bb_run_": BASES,
    "bb_score_": _t(
        "the shaded zone is home plate and the area the runner has to reach",
        "阴影区是本垒板和跑者要冲进的区域",
        "陰影區是本壘板和跑者要衝進的區域"),
    "bb_defence_": BASES,
    "bb_pick_": _t(
        "the squares are the bases in play; the runner starts on the one the pick-off is aimed at",
        "方块是这一球涉及的垒包，跑者站在被牵制的那个垒上",
        "方塊是這一球涉及的壘包，跑者站在被牽制的那個壘上"),
    "bb_game_": BASES,
    "bb_hit_tee_and_toss": _t(
        "the square is home plate; the shaded zone is where the hit has to go",
        "方块是本垒板，阴影区是击球要打向的区域",
        "方塊是本壘板，陰影區是擊球要打向的區域"),
    "bb_hit_": _t(
        "the square is home plate; the two shaded zones are the strike zone and where the ball has to be hit to",
        "方块是本垒板，两个阴影区分别是好球带和击球要打向的区域",
        "方塊是本壘板，兩個陰影區分別是好球帶和擊球要打向的區域"),
    "bb_catch_blocking": _t(
        "the square is home plate; the catcher sets up behind it",
        "方块是本垒板，捕手在它后面蹲好",
        "方塊是本壘板，捕手在它後面蹲好"),
    "bb_catch_throw_down": _t(
        "the two squares are home plate and second base, the throw goes from one to the other",
        "两个方块是本垒板和二垒，传杀从本垒传到二垒",
        "兩個方塊是本壘板和二壘，傳殺從本壘傳到二壘"),
    "bb_field_ground_ball": _t(
        "the two squares are home plate, where the balls are hit from, and first base, where the throw goes",
        "两个方块是本垒板（击球出发点）和一垒（传球目标）",
        "兩個方塊是本壘板（擊球出發點）和一壘（傳球目標）"),
    "bb_field_fly_ball": _t(
        "the square is home plate, where the fly balls are hit from",
        "方块是本垒板，高飞球从这里打出",
        "方塊是本壘板，高飛球從這裡打出"),
    "bb_pitch_bullpen": _t(
        "the square is home plate; the two shaded zones are the low and the high strike-zone targets the catcher calls",
        "方块是本垒板，两个阴影区是捕手要求的低位和高位好球带目标",
        "方塊是本壘板，兩個陰影區是捕手要求的低位和高位好球帶目標"),
}
