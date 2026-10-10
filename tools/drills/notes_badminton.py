"""Badminton: what the cones and zones are, and how each drill keeps going."""
from .rules_common import (FEED_RULES, POINT_RULES, RALLY_RULES,
                           SCORE_POINT_NET, SERVE_RULES)


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


FOOTWORK_FLOW = _t(
    "The feeder (or the coach's pointing) sends the player to the corner; he plays the shadow stroke there and gets back to base before the next one. Thirty seconds on, thirty off, six sets, then swap.",
    "喂球者（或教练手指）指向哪个角，练习者就跑到那个角做完击球动作，回到中心再接下一个；做 30 秒歇 30 秒，6 组后互换。",
    "餵球者（或教練手指）指向哪個角，練習者就跑到那個角做完擊球動作，回到中心再接下一個；做 30 秒歇 30 秒，6 組後互換。")

DOUBLES_FLOW = _t(
    "Every ball starts from the side shown and the pair run the positions drawn, then play the point out; after ten points the pairs swap roles, and after twenty they swap ends.",
    "每一球从图中发起方开始，两人先按图跑到位再把这一分正常打完；10 分后攻守互换，20 分后换边。",
    "每一球從圖中發起方開始，兩人先按圖跑到位再把這一分正常打完；10 分後攻守互換，20 分後換邊。")

FLOW = {
    "bd_footwork_": FOOTWORK_FLOW,
    "bd_multi_shuttle": FEED_RULES,
    # Fed from a box, these are not rallies: nobody "plays it until it
    # breaks down", the next shuttle is already coming.
    "bd_clear_": RALLY_RULES, "bd_drive_": RALLY_RULES, "bd_drop_": FEED_RULES,
    "bd_net_": FEED_RULES, "bd_deception_": FEED_RULES, "bd_smash_": FEED_RULES,
    "bd_doubles_": DOUBLES_FLOW,
    "bd_defence_": FEED_RULES,
    "bd_serve_": SERVE_RULES, "bd_return_": SERVE_RULES,
    "bd_game_": POINT_RULES,
    "bd_clear_round_the_head": FEED_RULES,
    "bd_net_battle": POINT_RULES,
}

ZONE = _t(
    "the shaded zone is where the shot has to land — count only the ones that do",
    "阴影区是这一拍要落的区域，只有落进去的才算",
    "陰影區是這一拍要落的區域，只有落進去的才算")
# The same, on a board where the other figure is the coach feeding — in
# slate, labelled C — rather than an opponent.
ZONE_COACH = _t(
    "C in slate is the coach, feeding shuttle after shuttle from a box — a multi-shuttle drill; 1 is the player. The shaded zone is where the shot has to land — count only the ones that do",
    "深灰色的 C 是教练，从球筐里一个接一个喂球 —— 多球训练；1 是练习者。阴影区是这一拍要落的区域，只有落进去的才算",
    "深灰色的 C 是教練，從球筐裡一個接一個餵球 —— 多球訓練；1 是練習者。陰影區是這一拍要落的區域，只有落進去的才算")

GEAR = {
    # Two entries, because one prefix used to cover five boards: the four
    # that work a single corner and the one that works all four. The old
    # wording — "the four cones are the four corners the player moves to" —
    # was true of the last of them only, and on the other four it described
    # three cones nobody goes near.
    "bd_footwork_four_corner": _t(
        "the four cones are the four corners of the court the player moves to; base is the centre between them",
        "四个锥标是要跑到的四个角，中心点在四个锥标之间",
        "四個錐標是要跑到的四個角，中心點在四個錐標之間"),
    "bd_footwork_": _t(
        "C in slate is the coach, pointing; 1 is the player. The cone marks the corner the player moves to; base is the centre of the court, and there is no shuttle — the stroke at the corner is a shadow one",
        "深灰色的 C 是教练，负责指方向；1 是练习者。锥标标出这一拍要跑到的角，中心点是场地中心；不用球，到角上做的是影子击球动作",
        "深灰色的 C 是教練，負責指方向；1 是練習者。錐標標出這一拍要跑到的角，中心點是場地中心；不用球，到角上做的是影子擊球動作"),
    "bd_multi_shuttle": _t(
        "C in slate is the coach, feeding; 1 is the player. A cone on each of the four corners; the coach sends the shuttle to them in any order and the player recovers to base between every one",
        "深灰色的 C 是教练，负责喂球；1 是练习者。四个角各摆一个锥标，喂球顺序随机，每球之后都要回到中心点",
        "深灰色的 C 是教練，負責餵球；1 是練習者。四個角各擺一個錐標，餵球順序隨機，每球之後都要回到中心點"),
    "bd_doubles_": _t(
        "the shaded zone is the gap the opponents' shape leaves open, and it is where the pair's reply has to land",
        "阴影区是对手站位留出的空当，这一对的回球必须落在那里",
        "陰影區是對手站位留出的空當，這一對的回球必須落在那裡"),
    "bd_clear_": ZONE, "bd_drop_": ZONE_COACH, "bd_net_": ZONE_COACH,
    "bd_deception_": ZONE_COACH, "bd_smash_": ZONE_COACH, "bd_defence_": ZONE_COACH,
    "bd_net_battle": ZONE,
    "bd_serve_": _t(
        "the two cones sit on the short service lines, one each side of the net, so the serve's legal depth is marked; the shaded zone is where this serve has to land",
        "两个锥标各摆在一侧的前发球线上，标出发球的合法深度；阴影区是这一种发球必须落进的区域",
        "兩個錐標各擺在一側的前發球線上，標出發球的合法深度；陰影區是這一種發球必須落進的區域"),
    "bd_return_": _t(
        "the two cones mark where the serve comes from; the shaded zone is where the return has to land",
        "两个锥标标出发球的位置，阴影区是接发球要落的区域",
        "兩個錐標標出發球的位置，陰影區是接發球要落的區域"),
    "bd_game_half_court": _t(
        "two cones on the ends of the centre line mark the half in play, about 3 m wide; a shuttle outside the line between them is out",
        "两个锥标摆在中线的两端，标出比赛用的半边场地（宽约 3 米），落在锥标连线外算出界",
        "兩個錐標擺在中線的兩端，標出比賽用的半邊場地（寬約 3 米），落在錐標連線外算出界"),
    "bd_clear_round_the_head": _t(
        "C in slate is the coach, feeding from a box — a multi-shuttle drill; 1 is the player. The cone is base: the player starts on it and gets back to it after every clear; the shaded zone is where the clear has to land",
        "深灰色的 C 是教练，从球筐里喂球 —— 多球训练；1 是练习者。锥标是中心位，每打完一拍高远球都要回到锥标；阴影区是高远球要落的区域",
        "深灰色的 C 是教練，從球筐裡餵球 —— 多球訓練；1 是練習者。錐標是中心位，每打完一拍高遠球都要回到錐標；陰影區是高遠球要落的區域"),
}


RULES = {
    "bd_game_": SCORE_POINT_NET,
}
