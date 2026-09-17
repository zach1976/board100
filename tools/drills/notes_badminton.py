"""Badminton: what the cones and zones are, and how each drill keeps going."""
from .rules_common import FEED_RULES, POINT_RULES, RALLY_RULES, SERVE_RULES


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
    "bd_clear_": RALLY_RULES, "bd_drive_": RALLY_RULES, "bd_drop_": RALLY_RULES,
    "bd_net_": RALLY_RULES, "bd_deception_": RALLY_RULES, "bd_smash_": RALLY_RULES,
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

GEAR = {
    "bd_footwork_": _t(
        "the four cones are the four corners of the court the player moves to; base is the centre between them",
        "四个锥标是要跑到的四个角，中心点在四个锥标之间",
        "四個錐標是要跑到的四個角，中心點在四個錐標之間"),
    "bd_multi_shuttle": _t(
        "the three cones are the three spots the feeder sends the shuttle to, in any order",
        "三个锥标是喂球者会送到的三个落点，顺序随机",
        "三個錐標是餵球者會送到的三個落點，順序隨機"),
    "bd_clear_": ZONE, "bd_drop_": ZONE, "bd_net_": ZONE, "bd_deception_": ZONE,
    "bd_smash_": ZONE, "bd_defence_": ZONE, "bd_net_battle": ZONE,
    "bd_serve_": _t(
        "the two cones mark the service target; the shaded zone is where the serve has to land",
        "两个锥标标出发球目标，阴影区是发球必须落进的区域",
        "兩個錐標標出發球目標，陰影區是發球必須落進的區域"),
    "bd_return_": _t(
        "the two cones mark where the serve comes from; the shaded zone is where the return has to land",
        "两个锥标标出发球的位置，阴影区是接发球要落的区域",
        "兩個錐標標出發球的位置，陰影區是接發球要落的區域"),
    "bd_game_half_court": _t(
        "the two cones mark the half of the court in play; a shuttle outside them is out",
        "两个锥标标出比赛用的半边场地，落在锥标外算出界",
        "兩個錐標標出比賽用的半邊場地，落在錐標外算出界"),
    "bd_clear_round_the_head": _t(
        "the cone is base: the player starts on it and gets back to it after every clear; the shaded zone is where the clear has to land",
        "锥标是中心位，每打完一拍高远球都要回到锥标；阴影区是高远球要落的区域",
        "錐標是中心位，每打完一拍高遠球都要回到錐標；陰影區是高遠球要落的區域"),
}
