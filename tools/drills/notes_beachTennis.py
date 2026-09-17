"""Beach tennis: what the zones and cones are, and how each drill keeps going."""
from .rules_common import (FEED_RULES, POINT_RULES, RALLY_RULES,
                           SCORE_POINT_NET, SERVE_RULES)


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


KING = _t(
    "The winners of each point stay on the king's side; the losers go to the back of the queue and the next pair comes in to challenge. Ten minutes, then reshuffle the pairs.",
    "每一分赢的一对留在擂台侧，输的排到队尾，下一对上来挑战；打 10 分钟后重新组对。",
    "每一分贏的一對留在擂台側，輸的排到隊尾，下一對上來挑戰；打 10 分鐘後重新組對。")

FLOW = {
    "bt_warm_": RALLY_RULES,
    "bt_rally_": RALLY_RULES,
    "bt_return_": SERVE_RULES, "bt_serve_": SERVE_RULES,
    "bt_attack_": FEED_RULES, "bt_lob_": FEED_RULES, "bt_smash_": FEED_RULES,
    "bt_defence_": FEED_RULES, "bt_cover_": FEED_RULES,
    "bt_game_king_of_the_court": KING,
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
        "two cones on the ends of the centre line mark the half in play, about 4 m wide; a ball outside the line between them is out",
        "两个锥标摆在中线两端，标出比赛用的半边场地（宽约 4 米），落在锥标连线外算出界",
        "兩個錐標擺在中線兩端，標出比賽用的半邊場地（寬約 4 米），落在錐標連線外算出界"),
}


RULES = {
    "bt_game_": SCORE_POINT_NET,
}
