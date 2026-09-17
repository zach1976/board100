"""Water polo: what the cones and zones are, and how each drill keeps going."""
from .rules_common import (BUILDUP_RULES, GAME_RULES, GK_RULES, PATTERN_RULES,
                           QUEUE_RULES, SCORE_GOAL_WATER, SETPIECE_RULES,
                           SETPLAY_RULES)


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


SWIM_OFF = _t(
    "One sprint per rep for the ball at the centre; whoever gets there first plays it back and everyone swims back to the goal line. Six sprints, then rest.",
    "每次一冲，抢池中间的球；先到的把球回传，所有人游回门线。冲 6 次后休息。",
    "每次一衝，搶池中間的球；先到的把球回傳，所有人游回門線。衝 6 次後休息。")

FLOW = {
    "wp_warm_": QUEUE_RULES,
    "wp_perimeter_": PATTERN_RULES,
    "wp_counter_": SETPLAY_RULES,
    "wp_manup_": SETPLAY_RULES,
    "wp_centre_": QUEUE_RULES,
    "wp_defence_": BUILDUP_RULES,
    "wp_set_swim_off": SWIM_OFF,
    "wp_set_": SETPIECE_RULES,
    "wp_game_": GAME_RULES,
    "wp_shot_": QUEUE_RULES,
    "wp_gk_": GK_RULES,
}

POSTS = _t(
    "the two cones mark the two-metre line either side of the goal; the shaded zone is the corner of the goal the shot is aimed at",
    "两个锥标标出球门两侧的两米线，阴影区是射门要打的球门角落",
    "兩個錐標標出球門兩側的兩米線，陰影區是射門要打的球門角落")

GEAR = {
    "wp_centre_": POSTS,
    "wp_centre_draw_foul": _t(
        "the two cones mark the two-metre line the centre works in front of",
        "两个锥标标出中锋在其前方活动的两米线",
        "兩個錐標標出中鋒在其前方活動的兩米線"),
    "wp_defence_": _t(
        "the two cones mark the two-metre line the defence must not let the ball inside",
        "两个锥标标出两米线，防守不能让球进到线内",
        "兩個錐標標出兩米線，防守不能讓球進到線內"),
    "wp_set_penalty": _t(
        "the square is the five-metre penalty mark",
        "方块是五米点球点",
        "方塊是五米點球點"),
    "wp_shot_": POSTS,
    "wp_gk_": _t(
        "the two cones mark the two-metre line in front of the goal",
        "两个锥标标出球门前的两米线",
        "兩個錐標標出球門前的兩米線"),
}


RULES = {
    "wp_": SCORE_GOAL_WATER,
}
