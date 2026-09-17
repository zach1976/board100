"""Volleyball: what the squares and zones are, and how each drill keeps going."""
from .rules_common import FEED_RULES, POINT_RULES, SERVE_IN_RULES, SERVE_RULES


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


PEPPER = _t(
    "Pass, set, hit back and forth without letting the ball drop; when it does, the one nearest picks it up and restarts. Two minutes, then swap partners.",
    "垫、传、扣来回不落地，落地由离球近的人捡起重来；2 分钟后换搭档。",
    "墊、傳、扣來回不落地，落地由離球近的人撿起重來；2 分鐘後換搭檔。")

ROTATION = _t(
    "One serve per rep; the side-out is played out, and after three serves the receiving side rotates one position so every rotation is drilled. Round the whole clock twice, then the servers swap.",
    "一球一发，打完一个接发回合；每发 3 球接发方轮转一个位置，六个轮次都练到。转两圈后换发球者。",
    "一球一發，打完一個接發回合；每發 3 球接發方輪轉一個位置，六個輪次都練到。轉兩圈後換發球者。")

FLOW = {
    "vb_warm_pepper": PEPPER,
    "vb_warm_": FEED_RULES,
    "vb_receive_": ROTATION,
    "vb_set_": FEED_RULES, "vb_setter_": FEED_RULES,
    "vb_free_ball": SERVE_IN_RULES, "vb_down_ball": SERVE_IN_RULES,
    "vb_attack_": FEED_RULES,
    "vb_block_": FEED_RULES, "vb_defense_": SERVE_IN_RULES, "vb_cover_hitter": FEED_RULES,
    "vb_serve_": SERVE_RULES,
    "vb_game_": POINT_RULES,
}

TARGET = _t(
    "the square is the setter's target — where the pass has to arrive",
    "方块是二传的目标点，一传要把球送到这里",
    "方塊是二傳的目標點，一傳要把球送到這裡")

GEAR = {
    "vb_receive_": TARGET,
    "vb_set_": _t(
        "the square is where the set has to be placed for the hitter",
        "方块是二传要把球送到的攻手起跳点",
        "方塊是二傳要把球送到的攻手起跳點"),
    "vb_setter_": _t(
        "the square is the spot the setter releases to, where the pass is aimed",
        "方块是二传插上要到的位置，一传瞄准这里",
        "方塊是二傳插上要到的位置，一傳瞄準這裡"),
    "vb_free_ball": TARGET, "vb_down_ball": TARGET,
    "vb_attack_": _t(
        "the square is where the set is placed for this attack",
        "方块是这一种进攻的二传落点",
        "方塊是這一種進攻的二傳落點"),
    "vb_serve_": _t(
        "the shaded zone is where the serve has to land",
        "阴影区是发球要落的区域",
        "陰影區是發球要落的區域"),
    "vb_cover_hitter": _t(
        "the shaded zone is where a blocked ball comes down — the cover has to be under it",
        "阴影区是被拦回的球会落下的区域，保护的人要站在下面",
        "陰影區是被攔回的球會落下的區域，保護的人要站在下面"),
    "vb_setter_dump": _t(
        "the shaded zone is where the dump has to drop, behind the block",
        "阴影区是二次球偷吊要落的区域，在拦网身后",
        "陰影區是二次球偷吊要落的區域，在攔網身後"),
}
