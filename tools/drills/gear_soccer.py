"""What the equipment on each soccer board is for — the 【器材】 line.

Keyed by drill id, or by the prefix a family shares. Written by hand:
four cones are a ring in one drill, a box in the next and two gates in a
third, and the picture cannot tell a coach which.
"""

def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


GEAR = {
    "rondo_4v2": _t(
        "four cones mark the ring; each passer stands on one and comes back to it",
        "四个锥标围出圈，每名传球人站一个锥标，传完回到自己的锥标",
        "四個錐標圍出圈，每名傳球人站一個錐標，傳完回到自己的錐標"),
    "rondo_": _t(
        "a cone under each passer marks the ring; the passers keep to their cones",
        "每名传球人脚下一个锥标，锥标连起来就是圈，传球人不离开自己的锥标",
        "每名傳球人腳下一個錐標，錐標連起來就是圈，傳球人不離開自己的錐標"),
    "rondo_5v2_split": _t(
        "five cones mark the ring; the split pass has to go between the two defenders inside it",
        "五个锥标围出圈，直塞必须从圈内两名防守者之间穿过",
        "五個錐標圍出圈，直塞必須從圈內兩名防守者之間穿過"),
    "dribble_slalom": _t(
        "four cones in a line are the poles to weave through; the ball must pass alternate sides of each",
        "四个锥标排成一列就是要绕的杆，球要从每个锥标的不同侧交替绕过",
        "四個錐標排成一列就是要繞的桿，球要從每個錐標的不同側交替繞過"),
    "possession_7v4": _t(
        "four cones mark the corners of the playing area; the ball is out if it crosses the line between them",
        "四个锥标标出场地的四个角，球越过锥标连线算出界",
        "四個錐標標出場地的四個角，球越過錐標連線算出界"),
    "ssg_4v4_four_goals": _t(
        "four cones mark the corners of the pitch; the four squares are small goals, one just inside each corner",
        "四个锥标标出场地四角，四个方块是小球门，各放在一个角的内侧",
        "四個錐標標出場地四角，四個方塊是小球門，各放在一個角的內側"),
    "warmup_y_pattern": _t(
        "four cones are the four stations of the Y: the start at the bottom, the pivot in the middle, one wide station each side",
        "四个锥标是 Y 字的四个站位：底端起点、中间支点、左右各一个分边点",
        "四個錐標是 Y 字的四個站位：底端起點、中間支點、左右各一個分邊點"),
    "warmup_first_touch_gate": _t(
        "the four cones make two gates a metre wide; the first touch has to take the ball through the next gate",
        "四个锥标摆成两个一米宽的门，第一脚触球要把球带过下一个门",
        "四個錐標擺成兩個一米寬的門，第一腳觸球要把球帶過下一個門"),
    "possession_3_zone": _t(
        "six cones mark three zones across the pitch; a point only counts when the ball is played through the middle one",
        "六个锥标把场地分成三个横向区域，球穿过中间区域才算得分",
        "六個錐標把場地分成三個橫向區域，球穿過中間區域才算得分"),
    "warmup_rotation_square": _t(
        "four cones are the four corners of the square and the four stations; a player runs to the cone he passed to",
        "四个锥标是方阵的四个角，也是四个站位，传给谁就跑到那个锥标",
        "四個錐標是方陣的四個角，也是四個站位，傳給誰就跑到那個錐標"),
    "warmup_two_ball": _t(
        "four cones are the four stations the two balls travel round",
        "四个锥标是四个站位，两个球沿着锥标转",
        "四個錐標是四個站位，兩個球沿著錐標轉"),
    "defend_1v1_channel": _t(
        "four cones mark the channel: the attacker starts through the bottom pair and scores by dribbling out through the top pair",
        "四个锥标围出通道：进攻者从底端两个锥标之间出发，把球带出顶端两个锥标之间算赢",
        "四個錐標圍出通道：進攻者從底端兩個錐標之間出發，把球帶出頂端兩個錐標之間算贏"),
    "ssg_5v5_two_touch": _t(
        "four cones mark the corners of the pitch and the two squares are the goals",
        "四个锥标标出场地四角，两个方块是两端的球门",
        "四個錐標標出場地四角，兩個方塊是兩端的球門"),
    "ssg_": _t(
        "four cones mark the corners of the pitch and the two squares are the goals",
        "四个锥标标出场地四角，两个方块是两端的球门",
        "四個錐標標出場地四角，兩個方塊是兩端的球門"),
    "ssg_6v6_transition": _t(
        "the two squares are the goals at either end; the game uses the full width between them",
        "两个方块是两端的球门，比赛用两门之间的整个宽度",
        "兩個方塊是兩端的球門，比賽用兩門之間的整個寬度"),
    "transition_": _t(
        "four cones mark the corners of the pitch and the two squares are the goals",
        "四个锥标标出场地四角，两个方块是两端的球门",
        "四個錐標標出場地四角，兩個方塊是兩端的球門"),
    "finish_penalty_routine": _t(
        "the cone is the turning mark of the sprint the taker runs before he steps up",
        "锥标是主罚者罚球前折返冲刺的转折点",
        "錐標是主罰者罰球前折返衝刺的轉折點"),
    "counter_": _t(
        "the square is the goal being attacked",
        "方块是进攻的球门",
        "方塊是進攻的球門"),
    "counter_3v2": _t(
        "the square is the goal being attacked",
        "方块是进攻的球门",
        "方塊是進攻的球門"),
    "halfspace_run": _t(
        "the square is the goal being attacked",
        "方块是进攻的球门",
        "方塊是進攻的球門"),
    "finish_first_time": _t(
        "the square is the goal",
        "方块是球门",
        "方塊是球門"),
    "finish_volley_side": _t(
        "the square is the goal",
        "方块是球门",
        "方塊是球門"),
    "throw_in_third": _t(
        "the square is the goal being attacked",
        "方块是进攻的球门",
        "方塊是進攻的球門"),
    "combo_": _t(
        "the square is the goal the combination finishes on",
        "方块是配合最后要攻的球门",
        "方塊是配合最後要攻的球門"),
    "passing_": _t(
        "a cone at each station of the shape; the passer runs to the cone he passed to and joins that line",
        "每个站位一个锥标，传给谁就跑到那个锥标排到队尾",
        "每個站位一個錐標，傳給誰就跑到那個錐標排到隊尾"),
    "cond_shuttle_finish": _t(
        "the two cones are the turning lines of the shuttle; touch the far one and come back",
        "两个锥标是折返的两条线，碰到远端锥标再回来",
        "兩個錐標是折返的兩條線，碰到遠端錐標再回來"),
    "cond_repeat_sprint": _t(
        "four cones in a line are the sprint marks; each leg goes to the next one and back",
        "四个锥标排成一列是冲刺标记，每段冲到下一个锥标再回来",
        "四個錐標排成一列是衝刺標記，每段衝到下一個錐標再回來"),
    "cond_box_to_box": _t(
        "the two cones mark the start line and the halfway turn",
        "两个锥标标出起点线和中场折返点",
        "兩個錐標標出起點線和中場折返點"),
    "touch_": _t(
        "four cones mark a box about 10 m square that the receiver has to keep the ball in",
        "四个锥标围出约 10 米见方的区域，接球人的第一脚要把球留在区域内",
        "四個錐標圍出約 10 米見方的區域，接球人的第一腳要把球留在區域內"),
    "overload_": _t(
        "four cones mark the corners of the playing area; the ball is out if it crosses the line between them",
        "四个锥标标出场地的四个角，球越过锥标连线算出界",
        "四個錐標標出場地的四個角，球越過錐標連線算出界"),
    "finish_long_range": _t(
        "the two cones mark the shooting line; the shot has to be struck before the ball crosses it",
        "两个锥标标出射门线，球过线之前必须出脚",
        "兩個錐標標出射門線，球過線之前必須出腳"),
}


def gear_of(drill_id: str):
    if drill_id in GEAR:
        return GEAR[drill_id]
    for key, text in GEAR.items():
        if key.endswith("_") and drill_id.startswith(key):
            return text
    return None
