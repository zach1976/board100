"""Table tennis: what the zones and cones are, and how each drill keeps going."""
from .rules_common import (FEED_RULES, POINT_RULES, RALLY_RULES,
                           SCORE_POINT_NET, SERVE_RULES)


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


FLOW = {
    "tt_warm_": RALLY_RULES,
    "tt_multiball": FEED_RULES,
    "tt_footwork_": FEED_RULES,
    "tt_rally_": RALLY_RULES,
    "tt_short_": FEED_RULES,
    "tt_loop_": RALLY_RULES,
    "tt_kill_": FEED_RULES,
    "tt_defence_": FEED_RULES,
    "tt_serve_": SERVE_RULES,
    "tt_game_": POINT_RULES,
}

ZONE = _t(
    "the shaded zone is the part of the table the ball has to land on — count only the ones that do",
    "阴影区是球要落的台面区域，只有落进去的才算",
    "陰影區是球要落的檯面區域，只有落進去的才算")

GEAR = {
    "tt_warm_": ZONE, "tt_rally_": ZONE, "tt_loop_": ZONE, "tt_kill_": ZONE,
    "tt_defence_": ZONE, "tt_game_serve_receive": ZONE,
    "tt_multiball": _t(
        "the two shaded zones are the two spots the coach alternates the balls to",
        "两个阴影区是教练交替喂球的两个落点",
        "兩個陰影區是教練交替餵球的兩個落點"),
    "tt_footwork_": _t(
        "the cones stand about a metre apart and mark the spots the player has to get to for each ball",
        "锥标相距约 1 米，标出每一球要移动到的击球位置",
        "錐標相距約 1 米，標出每一球要移動到的擊球位置"),
    "tt_short_": _t(
        "the cone marks the net-side spot the player steps in to; the shaded zone is where the short ball has to land",
        "锥标标出上步到台内的位置，阴影区是台内球要落的区域",
        "錐標標出上步到檯內的位置，陰影區是檯內球要落的區域"),
    "tt_serve_": _t(
        "the shaded zone is where the serve has to land",
        "阴影区是发球要落的区域",
        "陰影區是發球要落的區域"),
    "tt_game_half_table": _t(
        "the two cones mark the half of the table in play; a ball outside them is out",
        "两个锥标标出比赛用的半张台面，落在锥标外算出界",
        "兩個錐標標出比賽用的半張檯面，落在錐標外算出界"),
}


RULES = {
    "tt_game_": SCORE_POINT_NET,
}
