"""Basketball: what the cones are, and how each drill keeps going."""
from .rules_common import GAME_RULES, PATTERN_RULES, SETPLAY_RULES


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


LAYUP_LINES = _t(
    "Two lines: the passer joins the back of the shooting line, the shooter rebounds his own ball and joins the back of the passing line, and the next pair goes at once; two minutes each side, then switch hands.",
    "两列：传球的人传完排到上篮队队尾，上篮的人自己抢篮板后排到传球队队尾，下一对马上出发；每侧 2 分钟后换手。",
    "兩列：傳球的人傳完排到上籃隊隊尾，上籃的人自己搶籃板後排到傳球隊隊尾，下一對馬上出發；每側 2 分鐘後換手。")

SHOOTING = _t(
    "The passer feeds, the shooter shoots and chases his own rebound back to the passer; ten shots, then they swap. Count makes out of ten.",
    "传球者喂球，投篮者投完自己追篮板传回给传球者；投 10 次后互换，记录 10 投中几个。",
    "傳球者餵球，投籃者投完自己追籃板傳回給傳球者；投 10 次後互換，記錄 10 投中幾個。")

SHELL = _t(
    "The offence passes round the perimeter without scoring; every pass the defence slides to its new positions. Eight passes, then the ball is played live for one possession, then the groups swap.",
    "进攻方沿外线传球不投篮，每传一次防守整体轮转到新位置；传 8 次后打一次真实回合，然后攻守互换。",
    "進攻方沿外線傳球不投籃，每傳一次防守整體輪轉到新位置；傳 8 次後打一次真實回合，然後攻守互換。")

PRESS_BREAK = _t(
    "Over halfway inside eight seconds is a success; a turnover or a violation scores for the press. Either way the ball goes back to the baseline and the same five go again; five reps, then the groups swap.",
    "8 秒内把球带过半场算成功，被断或违例算压迫方得分；无论哪种球回底线由同一组再来，做 5 次后攻守互换。",
    "8 秒內把球帶過半場算成功，被斷或違例算壓迫方得分；無論哪種球回底線由同一組再來，做 5 次後攻守互換。")

FREE_THROW = _t(
    "Two free throws each, the shooter rebounding his own; then the next player steps up. Keep a running count of makes for the group.",
    "每人罚两次，自己抢篮板；然后换下一人。全组累计命中数。",
    "每人罰兩次，自己搶籃板；然後換下一人。全組累計命中數。")

TWO_BALL = _t(
    "Dribble both balls down and back between the cones without losing either; if one gets away, pick it up and go on from there. Six lengths, then change the pattern.",
    "两个球同时运，在锥标之间去回不丢球；丢了就捡起来从丢的地方继续。跑 6 趟后换一种运球方式。",
    "兩個球同時運，在錐標之間去回不丟球；丟了就撿起來從丟的地方繼續。跑 6 趟後換一種運球方式。")

FLOW = {
    "bb_layup_lines": LAYUP_LINES,
    "bb_two_ball_dribble": TWO_BALL,
    "bb_star_passing": PATTERN_RULES,
    "bb_five_out_spacing": PATTERN_RULES,
    "bb_horns_set": PATTERN_RULES,
    "bb_catch_and_shoot": SHOOTING,
    "bb_shot_": SHOOTING,
    "bb_free_throw": FREE_THROW,
    "bb_shell_4v4": SHELL,
    "bb_press_break": PRESS_BREAK,
    "bb_3v3_no_dribble": GAME_RULES,
    "bb_transition_": SETPLAY_RULES,
    "bb_": SETPLAY_RULES,
}

GEAR = {
    "bb_two_ball_dribble": _t(
        "the four cones mark the lane to dribble down and back",
        "四个锥标标出来回运球的通道",
        "四個錐標標出來回運球的通道"),
}
