"""Footvolley: what the squares and zones are, and how each drill keeps going."""
from .rules_common import FEED_RULES, POINT_RULES, RALLY_RULES, SERVE_RULES


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


JUGGLE = _t(
    "Keep the ball up between you as long as you can; when it drops, the one nearest picks it up and starts again. Count the run; two minutes, then change the surface you may use.",
    "两人尽量把球颠住不落地，落地由离球近的人捡起重新开始；数一次最多颠几下，2 分钟后限定只能用某个部位。",
    "兩人盡量把球顛住不落地，落地由離球近的人撿起重新開始；數一次最多顛幾下，2 分鐘後限定只能用某個部位。")

FLOW = {
    "fv_warm_": JUGGLE,
    "fv_control_": FEED_RULES, "fv_receive_": FEED_RULES,
    "fv_serve_": SERVE_RULES,
    "fv_attack_": FEED_RULES, "fv_combo_": RALLY_RULES, "fv_finish_": FEED_RULES,
    "fv_defence_": FEED_RULES, "fv_block_timing": FEED_RULES,
    "fv_game_": POINT_RULES,
}

ZONE = _t(
    "the shaded zone is where the ball has to land — count only the ones that do",
    "阴影区是球要落的区域，只有落进去的才算",
    "陰影區是球要落的區域，只有落進去的才算")

GEAR = {
    "fv_control_": _t(
        "the square is the spot the controlled ball has to be set to, for the next touch",
        "方块是停球后要把球放到的位置，为下一次触球准备",
        "方塊是停球後要把球放到的位置，為下一次觸球準備"),
    "fv_receive_": _t(
        "the square is where the first touch has to put the ball — up and in front, for the setter",
        "方块是一传要把球送到的位置：向上、向前，给二传",
        "方塊是一傳要把球送到的位置：向上、向前，給二傳"),
    "fv_serve_": _t(
        "the shaded zone is where the serve has to land",
        "阴影区是发球要落的区域",
        "陰影區是發球要落的區域"),
    "fv_attack_": ZONE, "fv_finish_": ZONE,
    "fv_combo_": _t(
        "the square is where the set has to be placed for the attacker",
        "方块是二传要把球送到的攻击点",
        "方塊是二傳要把球送到的攻擊點"),
}
