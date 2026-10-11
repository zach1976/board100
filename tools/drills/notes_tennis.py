"""Tennis: what the cones and zones are, and how each drill keeps going."""
from .rules_common import (FEED_RULES, POINT_RULES, RALLY_RULES,
                           SCORE_POINT_NET, SERVE_RULES)


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


# A 1v1 game has no partners to swap.
SINGLES_POINT_RULES = _t(
    "Play each point out and keep score; serve alternates every two points. Games to 11, then swap ends and opponents.",
    "每一分打到底并计分，每两分换发球；打到 11 分一局，局间换边、换对手。",
    "每一分打到底並計分，每兩分換發球；打到 11 分一局，局間換邊、換對手。")

FIRST_TO_SEVEN_RULES = _t(
    "Play each point out and keep score; serve alternates every two points. First to seven points wins the game, then swap ends and opponents.",
    "每一分打到底并计分，每两分换发球；先得 7 分者赢下这一局，然后换边、换对手。",
    "每一分打到底並計分，每兩分換發球；先得 7 分者贏下這一局，然後換邊、換對手。")

FLOW = {
    "tn_game_half_court": SINGLES_POINT_RULES,
    "tn_game_first_to_seven": FIRST_TO_SEVEN_RULES,
    "tn_game_approach_only": SINGLES_POINT_RULES,
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
        "the two cones mark the deep targets the rally is aimed at, about 1.5 m inside each baseline in the corner the pattern is played to",
        "两个锥标是对拉要打向的深区目标，在两边底线内约 1.5 米、本练习所打的那个角上",
        "兩個錐標是對拉要打向的深區目標，在兩邊底線內約 1.5 公尺、本練習所打的那個角上"),
    "tn_serve_plus_one": ZONE, "tn_return_plus_one": ZONE, "tn_inside_out": ZONE,
    "tn_approach": ZONE, "tn_net_": ZONE, "tn_defend_": ZONE,
    "tn_serve_": _t(
        "the shaded zone is the part of the service box the serve has to land in",
        "阴影区是发球必须落进的发球区位置",
        "陰影區是發球必須落進的發球區位置"),
    "tn_game_half_court": _t(
        "two cones on the centre marks of both baselines: the line between them splits the court lengthwise, and only the half the players stand in is in — singles sideline to that line, about 4 m wide",
        "两个锥标摆在两条底线的中点上：两点连线把球场纵向一分为二，只有球员所在的那一半算界内——单打边线到这条线，宽约 4 米",
        "兩個錐標擺在兩條底線的中點上：兩點連線把球場縱向一分為二，只有球員所在的那一半算界內——單打邊線到這條線，寬約 4 公尺"),
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


RULES = {
    "tn_game_": SCORE_POINT_NET,
}
