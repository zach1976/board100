"""Beach tennis: what the zones and cones are, and how each drill keeps going."""
from .rules_common import (FEED_RULES, POINT_RULES, RALLY_RULES,
                           SCORE_POINT_NET, SERVE_RULES)


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


KING = _t(
    "The winners of each point stay on the king's side; the losers go to the back of the queue and the next pair comes in to challenge. Ten minutes, then reshuffle the pairs.",
    "每一分赢的一对留在擂台侧，输的排到队尾，下一对上来挑战；打 10 分钟后重新组对。",
    "每一分贏的一對留在擂台側，輸的排到隊尾，下一對上來挑戰；打 10 分鐘後重新組對。")

# A 1v1 game has no partners to swap.
SINGLES_POINT_RULES = _t(
    "Play each point out and keep score; serve alternates every two points. Games to 11, then swap ends and opponents.",
    "每一分打到底并计分，每两分换发球；打到 11 分一局，局间换边、换对手。",
    "每一分打到底並計分，每兩分換發球；打到 11 分一局，局間換邊、換對手。")

FLOW = {
    "bt_warm_": RALLY_RULES,
    "bt_rally_": RALLY_RULES,
    "bt_return_": SERVE_RULES, "bt_serve_": SERVE_RULES,
    "bt_attack_": FEED_RULES, "bt_lob_": FEED_RULES, "bt_smash_": FEED_RULES,
    "bt_defence_": FEED_RULES, "bt_cover_": FEED_RULES,
    "bt_game_king_of_the_court": KING,
    "bt_game_half_court": SINGLES_POINT_RULES,
    "bt_game_": POINT_RULES,
}

ZONE = _t(
    "the shaded zone is where the shot has to land — count only the ones that do",
    "阴影区是这一拍要落的区域，只有落进去的才算",
    "陰影區是這一拍要落的區域，只有落進去的才算")

GEAR = {
    "bt_return_": _t(
        "the shaded zone is where the return has to be played to",
        "阴影区是接发球要打到的区域",
        "陰影區是接發球要打到的區域"),
    "bt_serve_": _t(
        "the shaded zone is where the serve has to land",
        "阴影区是发球要落的区域",
        "陰影區是發球要落的區域"),
    "bt_attack_": ZONE, "bt_lob_": ZONE, "bt_smash_": ZONE, "bt_defence_": ZONE,
    "bt_game_half_court": _t(
        "a beach-tennis court has no centre line: two cones in the middle of the two baselines mark it, and only the half the players stand in, about 4 m wide, is in",
        "沙滩网球场没有中线：两个锥标摆在两条底线的中点上代替它，只有球员所在的那一半（宽约 4 米）算界内",
        "沙灘網球場沒有中線：兩個錐標擺在兩條底線的中點上代替它，只有球員所在的那一半（寬約 4 公尺）算界內"),
}


# Beach tennis has no bounce at all: the shared net-sport rule's "a second
# bounce loses it" implied a first one is legal.
NO_BOUNCE_RULES = _t(
    "A ball that lands inside the opponents' lines wins the point. Nothing may bounce: any ball that touches the sand on your side loses the point, and so does a ball out or into the net. Serve changes every two points, and a ball on the line is in.",
    "球落在对方界内即得分。球不能落地：在本方一侧碰到沙子就失分，出界或下网也失分。每两分换发球，压线算界内。",
    "球落在對方界內即得分。球不能落地：在本方一側碰到沙子就失分，出界或下網也失分。每兩分換發球，壓線算界內。")

RULES = {
    "bt_game_": NO_BOUNCE_RULES,
}
