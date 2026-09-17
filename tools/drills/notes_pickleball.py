"""Pickleball: what the cones and zones are, and how each drill keeps going."""
from .rules_common import FEED_RULES, POINT_RULES, RALLY_RULES, SERVE_RULES


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


FLOW = {
    "pb_warm_": RALLY_RULES,
    "pb_dink_": RALLY_RULES,
    "pb_serve_": SERVE_RULES,
    "pb_third_": RALLY_RULES,
    "pb_speedup_": FEED_RULES,
    "pb_putaway_": FEED_RULES,
    "pb_defend_": FEED_RULES,
    "pb_shape_": FEED_RULES,
    "pb_game_": POINT_RULES,
    "pb_two_bounce_rule": SERVE_RULES,
    "pb_attack_lob": FEED_RULES,
}

KITCHEN = _t(
    "the two cones mark the kitchen line on each side; feet stay behind it",
    "两个锥标标出两侧的厨房线（非截击区线），脚不能过线",
    "兩個錐標標出兩側的廚房線（非截擊區線），腳不能過線")
ZONE = _t(
    "the shaded zone is where the shot has to land — count only the ones that do",
    "阴影区是这一拍要落的区域，只有落进去的才算",
    "陰影區是這一拍要落的區域，只有落進去的才算")
ZONE_CONE = _t(
    "the cone marks the kitchen line the players work up to; the shaded zone is where the shot has to land",
    "锥标标出球员要推进到的厨房线，阴影区是这一拍要落的区域",
    "錐標標出球員要推進到的廚房線，陰影區是這一拍要落的區域")

GEAR = {
    "pb_warm_": KITCHEN, "pb_dink_": KITCHEN, "pb_shape_": KITCHEN, "pb_game_": KITCHEN,
    "pb_serve_": _t(
        "the shaded zone is where the serve or the return has to land — deep",
        "阴影区是发球或接发要落的深区",
        "陰影區是發球或接發要落的深區"),
    "pb_third_": ZONE_CONE, "pb_speedup_": ZONE_CONE, "pb_attack_lob": ZONE_CONE,
    "pb_putaway_": ZONE,
    "pb_defend_": _t(
        "the cone marks the kitchen line the defenders hold",
        "锥标标出防守方守住的厨房线",
        "錐標標出防守方守住的廚房線"),
    "pb_two_bounce_rule": _t(
        "the two cones mark the kitchen lines; the two shaded zones are where the serve and the return have to bounce before anyone may volley",
        "两个锥标标出厨房线，两个阴影区是发球和接发必须先落地的区域，之后才允许截击",
        "兩個錐標標出廚房線，兩個陰影區是發球和接發必須先落地的區域，之後才允許截擊"),
}
