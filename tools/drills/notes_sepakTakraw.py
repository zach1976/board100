"""Sepak takraw: what the circle, squares and zones are, and how each drill keeps going."""
from .rules_common import FEED_RULES, POINT_RULES, RALLY_RULES, SERVE_RULES


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


JUGGLE = _t(
    "Keep the ball up as long as you can; when it drops, the nearest player picks it up and starts again. Count the run; two minutes, then restrict the surface you may use.",
    "尽量把球颠住不落地，落地由离球近的人捡起重新开始；数一次最多颠几下，2 分钟后限定只能用某个部位。",
    "盡量把球顛住不落地，落地由離球近的人撿起重新開始；數一次最多顛幾下，2 分鐘後限定只能用某個部位。")

FLOW = {
    "st_warm_": JUGGLE,
    "st_receive_": FEED_RULES, "st_feed_": FEED_RULES,
    "st_attack_": RALLY_RULES, "st_spike_": FEED_RULES,
    "st_defence_": FEED_RULES, "st_cover_spike": FEED_RULES, "st_block_at_the_net": FEED_RULES,
    "st_serve_": SERVE_RULES, "st_tekong_": SERVE_RULES,
    "st_game_": POINT_RULES,
}

ZONE = _t(
    "the shaded zone is where the ball has to land — count only the ones that do",
    "阴影区是球要落的区域，只有落进去的才算",
    "陰影區是球要落的區域，只有落進去的才算")
SERVE = _t(
    "the circle is the service circle the tekong serves from; the shaded zone is where the serve has to land",
    "圆圈是发球手站的发球圈，阴影区是发球要落的区域",
    "圓圈是發球手站的發球圈，陰影區是發球要落的區域")

GEAR = {
    "st_receive_": _t(
        "the square is where the first touch has to put the ball, up for the feeder",
        "方块是一传要把球送到的位置，向上给传球手",
        "方塊是一傳要把球送到的位置，向上給傳球手"),
    "st_feed_": _t(
        "the square is the spot the feed has to be set to for the striker",
        "方块是传球要送到的攻手起跳点",
        "方塊是傳球要送到的攻手起跳點"),
    "st_attack_": ZONE, "st_spike_": ZONE, "st_block_at_the_net": ZONE,
    "st_serve_": SERVE,
    "st_tekong_": _t(
        "the circle is the service circle; the tekong's kicking foot stays inside it until contact",
        "圆圈是发球圈，发球手的支撑脚在触球前不能出圈",
        "圓圈是發球圈，發球手的支撐腳在觸球前不能出圈"),
    "st_game_no_block": _t(
        "the cone marks the line at the net nobody may cross to block",
        "锥标标出网前的线，任何人不得越过去拦网",
        "錐標標出網前的線，任何人不得越過去攔網"),
    "st_receive_header": SERVE,
}
