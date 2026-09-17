"""Tennis: what the cones and zones are, and how each drill keeps going."""
from .rules_common import FEED_RULES, POINT_RULES, RALLY_RULES, SERVE_RULES


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


FLOW = {
    "tn_warm_": RALLY_RULES,
    "tn_rally_": RALLY_RULES,
    "tn_serve_plus_one": SERVE_RULES, "tn_return_plus_one": SERVE_RULES,
    "tn_inside_out": FEED_RULES, "tn_approach": FEED_RULES,
    "tn_doubles_": POINT_RULES,
    "tn_net_": FEED_RULES,
    "tn_defend_": FEED_RULES,
    "tn_serve_": SERVE_RULES,
    "tn_game_": POINT_RULES,
    "tn_attack_drop_shot": RALLY_RULES,
}

ZONE = _t(
    "the shaded zone is where the shot has to land — count only the ones that do",
    "阴影区是这一拍要落的区域，只有落进去的才算",
    "陰影區是這一拍要落的區域，只有落進去的才算")

GEAR = {
    "tn_rally_": _t(
        "the two cones mark the targets on either baseline the rally is aimed at",
        "两个锥标是两边底线上对拉要打向的目标",
        "兩個錐標是兩邊底線上對拉要打向的目標"),
    "tn_serve_plus_one": ZONE, "tn_return_plus_one": ZONE, "tn_inside_out": ZONE,
    "tn_approach": ZONE, "tn_net_": ZONE, "tn_defend_": ZONE,
    "tn_serve_": _t(
        "the shaded zone is the part of the service box the serve has to land in",
        "阴影区是发球必须落进的发球区位置",
        "陰影區是發球必須落進的發球區位置"),
    "tn_game_half_court": _t(
        "the two cones mark the half of the court in play; a ball outside them is out",
        "两个锥标标出比赛用的半边场地，落在锥标外算出界",
        "兩個錐標標出比賽用的半邊場地，落在錐標外算出界"),
    "tn_serve_and_volley": _t(
        "the two shaded zones are where the serve has to land and where the first volley has to go",
        "两个阴影区分别是发球的落点和第一截击要打到的区域",
        "兩個陰影區分別是發球的落點和第一截擊要打到的區域"),
    "tn_attack_drop_shot": _t(
        "the two shaded zones are where the drop shot has to land and where the passing shot goes",
        "两个阴影区分别是放小球的落点和穿越球要打到的区域",
        "兩個陰影區分別是放小球的落點和穿越球要打到的區域"),
    "tn_doubles_poach": _t(
        "the two shaded zones are where the serve lands and where the poaching volley is put away",
        "两个阴影区分别是发球落点和网前拦截后要打到的区域",
        "兩個陰影區分別是發球落點和網前攔截後要打到的區域"),
}
