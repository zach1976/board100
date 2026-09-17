"""Field hockey: what the cones and zones are, and how each drill keeps going."""
from .rules_common import (BUILDUP_RULES, DUEL_RULES, GAME_RULES, GK_RULES,
                           PATTERN_RULES, QUEUE_RULES, RALLY_RULES,
                           SETPIECE_RULES)


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


PAIRS = _t(
    "Pass and receive without a break, first stationary then on the move; two minutes, then swap the stick side you receive on.",
    "不间断地传接，先原地再移动中；2 分钟后换用另一侧接球。",
    "不間斷地傳接，先原地再移動中；2 分鐘後換用另一側接球。")

FLOW = {
    "fh_warm_gates": QUEUE_RULES,
    "fh_warm_pairs": PAIRS,
    "fh_warm_elimination": DUEL_RULES,
    "fh_build_": BUILDUP_RULES,
    "fh_entry_": PATTERN_RULES,
    "fh_shot_": QUEUE_RULES,
    "fh_press_": BUILDUP_RULES,
    "fh_corner_": SETPIECE_RULES, "fh_set_": SETPIECE_RULES,
    "fh_game_": GAME_RULES,
    "fh_defend_tackle": DUEL_RULES,
    "fh_counter_attack": PATTERN_RULES,
    "fh_gk_": GK_RULES,
}

GEAR = {
    "fh_warm_gates": _t(
        "the six cones make three gates; the ball is carried through each gate in turn",
        "六个锥标摆成三个门，带球依次穿过每个门",
        "六個錐標擺成三個門，帶球依次穿過每個門"),
    "fh_warm_elimination": _t(
        "the cone stands in for the defender to beat; go past it on either side with the move being practised",
        "锥标代表要过掉的防守者，用练习的动作从它任一侧过去",
        "錐標代表要過掉的防守者，用練習的動作從它任一側過去"),
    "fh_defend_tackle": _t(
        "the two cones mark the channel the attacker has to come through; the tackle is made inside it",
        "两个锥标标出进攻者必须通过的通道，抢断在通道内完成",
        "兩個錐標標出進攻者必須通過的通道，搶斷在通道內完成"),
    "fh_build_aerial": _t(
        "the shaded zone is where the aerial has to land, in front of the receiver, not on him",
        "阴影区是高球的落点，落在接球人前方，不是砸在他身上",
        "陰影區是高球的落點，落在接球人前方，不是砸在他身上"),
    "fh_gk_clearing": _t(
        "the cone marks where the clearance has to go — out of the circle and wide",
        "锥标标出解围要踢向的位置：出圆圈、向边路",
        "錐標標出解圍要踢向的位置：出圓圈、向邊路"),
}
