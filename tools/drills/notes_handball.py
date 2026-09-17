"""Handball: what the zones and squares are, and how each drill keeps going."""
from .rules_common import (BUILDUP_RULES, GAME_RULES, GK_RULES, PATTERN_RULES,
                           QUEUE_RULES, SCORE_GOAL_HAND, SETPIECE_RULES,
                           SETPLAY_RULES)


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


FLOW = {
    "hb_warm_star_passing": PATTERN_RULES,
    "hb_warm_three_lane": QUEUE_RULES,
    "hb_warm_keeper": QUEUE_RULES,
    "hb_circulation_": PATTERN_RULES,
    "hb_attack_": SETPLAY_RULES,
    "hb_break_": QUEUE_RULES,
    "hb_shot_": QUEUE_RULES,
    "hb_defence_": BUILDUP_RULES,
    "hb_set_": SETPIECE_RULES,
    "hb_game_": GAME_RULES,
    "hb_gk_": GK_RULES,
}

TARGET = _t(
    "the shaded zone is the part of the goal the shot has to hit",
    "阴影区是射门要打到的球门位置",
    "陰影區是射門要打到的球門位置")

GEAR = {
    "hb_shot_": TARGET,
    "hb_attack_one_v_one": TARGET,
    "hb_set_seven_metre": _t(
        "the square is the seven-metre line the taker stands behind; the shaded zone is the corner the throw is aimed at",
        "方块是主罚站在其后的七米线，阴影区是要打的球门角落",
        "方塊是主罰站在其後的七米線，陰影區是要打的球門角落"),
    "hb_gk_angles": _t(
        "the two shaded zones are the two corners the shooter alternates between; the keeper's set position has to cover both",
        "两个阴影区是射手轮流打的两个角，门将的站位要同时能顾到两边",
        "兩個陰影區是射手輪流打的兩個角，門將的站位要同時能顧到兩邊"),
    "hb_gk_one_v_one": TARGET,
    "hb_gk_seven_metre": _t(
        "the square is the seven-metre line",
        "方块是七米线",
        "方塊是七米線"),
    "hb_gk_outlet": _t(
        "the two shaded zones are the two outlets the keeper's first pass can go to — the near wing and the breaking back",
        "两个阴影区是门将一传的两个出球点：近侧边锋和插上的后卫",
        "兩個陰影區是門將一傳的兩個出球點：近側邊鋒和插上的後衛"),
}


RULES = {
    "hb_": SCORE_GOAL_HAND,
}
