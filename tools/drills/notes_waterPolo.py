"""Water polo: what the markers are, how each drill keeps going, and the one
rule each family actually trains.

The other eight locales of every sentence here live in i18n/waterPolo.json
(or the shared common.json), keyed by the English.
"""
from .rules_common import PATTERN_RULES, QUEUE_RULES, SETPLAY_RULES


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


SWIM_OFF = _t(
    "One sprint per rep for the ball at the centre; whoever gets there first plays it back and everyone swims back to the goal line. Six sprints, then rest.",
    "每次一冲，抢池中间的球；先到的把球回传，所有人游回门线。冲 6 次后休息。",
    "每次一衝，搶池中間的球；先到的把球回傳，所有人游回門線。衝 6 次後休息。")

DEFENCE_FLOW = _t(
    "The rep ends on a steal, a save or a shot; the ball goes back to the point and the six set up again. Five reps, then attack and defence swap.",
    "抢断、扑救或射门即结束这一次；球回到弧顶，六名进攻队员重新站位。做 5 次后攻守互换。",
    "搶斷、撲救或射門即結束這一次；球回到弧頂，六名進攻隊員重新站位。做 5 次後攻守互換。")

GAME_FLOW = _t(
    "After a goal the team that conceded restarts at halfway; a ball out at the side is the other team's free throw from where it went out. Four-minute games, then swap ends.",
    "进球后由失球方在中线重新开球；球从边线出界，由对方在出界处罚任意球。每局 4 分钟，然后交换场地。",
    "進球後由失球方在中線重新開球；球從邊線出界，由對方在出界處罰任意球。每局 4 分鐘，然後交換場地。")

OUTLET_FLOW = _t(
    "After each outlet the wings swim back to their own two-metre line and the coach gives the keeper the next ball; eight outlets, alternating sides, then the keepers swap.",
    "每次长传之后，两名边锋游回本方两米线，教练把下一个球交给门将；做 8 次，左右交替，然后换门将。",
    "每次長傳之後，兩名邊鋒游回本方兩米線，教練把下一個球交給門將；做 8 次，左右交替，然後換門將。")

GK_SHOT_FLOW = _t(
    "After each shot the keeper resets in the middle of his goal and the next shooter goes; ten shots a set, then the keepers swap.",
    "每次射门之后，门将回到球门中间预备，下一名射手出手；10 次一组，然后换门将。",
    "每次射門之後，門將回到球門中間預備，下一名射手出手；10 次一組，然後換門將。")

SET_FLOW = _t(
    "After each throw everyone goes back to the starting spots and the next taker steps up; eight in a row, then the keepers swap.",
    "每投一次，所有人回到起始位置，换下一名主罚；连续 8 次，然后换门将。",
    "每投一次，所有人回到起始位置，換下一名主罰；連續 8 次，然後換門將。")

FLOW = {
    "wp_warm_": QUEUE_RULES,
    "wp_perimeter_": PATTERN_RULES,
    "wp_counter_": SETPLAY_RULES,
    "wp_manup_": SETPLAY_RULES,
    "wp_centre_": QUEUE_RULES,
    "wp_defence_": DEFENCE_FLOW,
    "wp_set_swim_off": SWIM_OFF,
    "wp_set_": SET_FLOW,
    "wp_game_": GAME_FLOW,
    "wp_shot_": QUEUE_RULES,
    "wp_gk_outlet": OUTLET_FLOW,
    "wp_gk_": GK_SHOT_FLOW,
}

TARGET = _t(
    "the shaded zone inside the goal is the corner the shot is aimed at — the one away from the block and the keeper",
    "球门里的阴影区是这脚射门要打的角落——避开封挡和门将的那一侧",
    "球門裡的陰影區是這腳射門要打的角落——避開封擋和門將的那一側")

PENALTY_MARK = _t(
    "the square is the five-metre penalty mark",
    "方块是五米点球点",
    "方塊是五米點球點")

GEAR = {
    # No markers on these boards; the lines are painted on the pool.
    "wp_centre_draw_foul": None,
    "wp_centre_": TARGET,
    "wp_set_penalty": PENALTY_MARK,
    "wp_gk_penalty": PENALTY_MARK,
    "wp_shot_": TARGET,
}

# The rule each family trains, not one boilerplate line on every board.
TWO_METRE = _t(
    "No attacker may be inside the opponents' two-metre line ahead of the ball. A goal is the whole ball over the goal line between the posts, and 30 seconds without a shot loses possession.",
    "进攻队员不得在球之前进入对方两米线以内。球整体越过两门柱之间的门线算进球；30 秒内没有射门即失去球权。",
    "進攻隊員不得在球之前進入對方兩米線以內。球整體越過兩門柱之間的門線算進球；30 秒內沒有射門即失去球權。")

EXCLUSION = _t(
    "An excluded player swims to the re-entry area in the corner and sits out 20 seconds, or until his team wins the ball back or a goal is scored; those 20 seconds are the man-up.",
    "被罚出的队员游到角上的再入区，等待 20 秒，或直到本队重新得球、或有进球为止；这 20 秒就是多打少的时间。",
    "被罰出的隊員游到角上的再入區，等待 20 秒，或直到本隊重新得球、或有進球為止；這 20 秒就是多打少的時間。")

PENALTY = _t(
    "A penalty is thrown from the five-metre line in one uninterrupted movement, straight after the whistle. The keeper stays on his goal line until the ball leaves the hand; everyone else stays outside the five-metre area.",
    "点球在五米线上投出，哨响后一个连贯动作完成。球离手之前门将必须站在门线上；其他人都在五米区以外。",
    "點球在五米線上投出，哨響後一個連貫動作完成。球離手之前門將必須站在門線上；其他人都在五米區以外。")

SWIM_OFF_RULE = _t(
    "At a swim-off both teams line up on their own goal lines, a metre apart and a metre from the posts; the referee whistles and drops the ball at halfway.",
    "抢球时双方在本方门线上排开，彼此相隔一米、距门柱一米；裁判鸣哨后把球放在中线。",
    "搶球時雙方在本方門線上排開，彼此相隔一米、距門柱一米；裁判鳴哨後把球放在中線。")

FREE_THROW = _t(
    "A free throw is taken at once from where the foul was, with the ball visibly released; from outside the six-metre line it may be shot straight at goal.",
    "任意球在犯规地点立即发出，球要明显出手；在六米线以外可以直接射门。",
    "任意球在犯規地點立即發出，球要明顯出手；在六米線以外可以直接射門。")

GK_RULE = _t(
    "The goalkeeper may play the ball with both hands, and punch it, only inside his own six-metre area. A save that stays in the pool is a live ball.",
    "门将只能在本方六米区内用双手触球或击球。扑出后仍在池内的球是活球。",
    "門將只能在本方六米區內用雙手觸球或擊球。撲出後仍在池內的球是活球。")

RULES = {
    "wp_set_penalty": PENALTY,
    "wp_gk_penalty": PENALTY,
    "wp_set_swim_off": SWIM_OFF_RULE,
    "wp_set_free_throw": FREE_THROW,
    "wp_centre_draw_foul": EXCLUSION,
    "wp_defence_five_on_six": EXCLUSION,
    "wp_manup_": EXCLUSION,
    "wp_gk_": GK_RULE,
    "wp_warm_": None,
    "wp_": TWO_METRE,
}
