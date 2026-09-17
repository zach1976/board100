"""Rugby: what the cones and zones are, and how each drill keeps going."""
from .rules_common import (DUEL_RULES, GAME_RULES, PATTERN_RULES, QUEUE_RULES,
                           SCORE_TRY, SETPIECE_RULES, SETPLAY_RULES)


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


HANDLING = _t(
    "The ball goes down the line and back without stopping; after each length the players step across one position so everyone passes both ways. Two minutes, then the other direction.",
    "球沿线传到底再传回来，不停；每传完一趟所有人横移一个位置，每人两个方向都练到。2 分钟后换方向。",
    "球沿線傳到底再傳回來，不停；每傳完一趟所有人橫移一個位置，每人兩個方向都練到。2 分鐘後換方向。")

BREAKDOWN = _t(
    "One breakdown per rep: the carrier goes to ground, the support arrives, the ball is played away, and everyone resets. Six reps, then the carrier, supports and defenders rotate roles.",
    "一次一个争球点：持球者倒地、支援到位、球传出去，全部回位。做 6 次后持球者、支援者、防守者轮换角色。",
    "一次一個爭球點：持球者倒地、支援到位、球傳出去，全部回位。做 6 次後持球者、支援者、防守者輪換角色。")

KICKING = _t(
    "Kick, chase, and the receiving side counts where it landed; the ball is jogged back and the next kicker steps up. Eight kicks each, then the sides swap.",
    "踢出、追球，接球方记录落点；球跑回来交给下一名踢球者。每人 8 脚后两边互换。",
    "踢出、追球，接球方記錄落點；球跑回來交給下一名踢球者。每人 8 腳後兩邊互換。")

DEFENCE = _t(
    "The attack runs its line once and the defence answers; the rep ends at the tackle or the try. Reset to the start; six reps, then the sides swap.",
    "进攻跑一次线路，防守做出应对；擒抱或达阵即一回合结束。回到起点，做 6 次后攻守互换。",
    "進攻跑一次線路，防守做出應對；擒抱或達陣即一回合結束。回到起點，做 6 次後攻守互換。")

FLOW = {
    "rg_handling_": HANDLING,
    "rg_phase_": PATTERN_RULES,
    "rg_breakdown_": BREAKDOWN,
    "rg_move_": PATTERN_RULES,
    "rg_kick_": KICKING,
    "rg_finish_": SETPLAY_RULES,
    "rg_defence_tackle": DUEL_RULES,
    "rg_defence_": DEFENCE,
    "rg_set_": SETPIECE_RULES, "rg_maul_": SETPIECE_RULES,
    "rg_game_": GAME_RULES,
    "rg_kick_at_goal": QUEUE_RULES,
    "rg_kick_exit": PATTERN_RULES,
    "rg_kick_high_ball": DEFENCE,
}

GEAR = {
    "rg_handling_grid": _t(
        "the four cones mark the grid the passing stays inside",
        "四个锥标围出传接球的方格区域",
        "四個錐標圍出傳接球的方格區域"),
    "rg_handling_threes": _t(
        "the three cones stand 5 m apart and are the three lanes the runners keep to",
        "三个锥标相距 5 米，标出三名跑动者各自的通道",
        "三個錐標相距 5 米，標出三名跑動者各自的通道"),
    "rg_handling_wide": _t(
        "six cones 8 m apart mark the lanes across the full width, one per player",
        "六个锥标相距 8 米，横贯全宽标出六条通道，每人一条",
        "六個錐標相距 8 米，橫貫全寬標出六條通道，每人一條"),
    "rg_kick_": _t(
        "the shaded zone is where the kick has to land",
        "阴影区是踢球要落的区域",
        "陰影區是踢球要落的區域"),
    "rg_finish_": _t(
        "the shaded zone is the in-goal area the try has to be scored in",
        "阴影区是要达阵的得分区",
        "陰影區是要達陣的得分區"),
    "rg_set_kick_off": _t(
        "the shaded zone is where the kick-off has to land, past the ten-metre line",
        "阴影区是开球要落的区域，必须过十米线",
        "陰影區是開球要落的區域，必須過十米線"),
    "rg_defence_tackle": _t(
        "the two cones stand 5 m apart and mark the channel the carrier runs through; the tackle is made inside it",
        "两个锥标相距 5 米，标出持球者跑动的通道，擒抱在通道内完成",
        "兩個錐標相距 5 米，標出持球者跑動的通道，擒抱在通道內完成"),
    "rg_kick_at_goal": _t(
        "the square is the tee on the kicking spot; the shaded zone is the target between the posts",
        "方块是放球的踢球点，阴影区是门柱之间的目标",
        "方塊是放球的踢球點，陰影區是門柱之間的目標"),
    "rg_kick_exit": _t(
        "the shaded zone is where the exit kick has to land, beyond the 22 and towards touch",
        "阴影区是出球踢的落点：过 22 米线、靠近边线",
        "陰影區是出球踢的落點：過 22 米線、靠近邊線"),
    "rg_kick_high_ball": _t(
        "the shaded zone is where the high ball comes down and the contest happens",
        "阴影区是高球落点和争顶发生的位置",
        "陰影區是高球落點和爭頂發生的位置"),
}


RULES = {
    "rg_": SCORE_TRY,
}
