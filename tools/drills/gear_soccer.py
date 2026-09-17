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
        "four cones mark the corners of a 30 by 30 m square; the line between two cones is the boundary, and the ball is out the moment it crosses it",
        "四个锥标围出约 30 米见方的场地；两个锥标之间的连线就是边界，球一越线就算出界",
        "四個錐標圍出約 30 米見方的場地；兩個錐標之間的連線就是邊界，球一越線就算出界"),
    "ssg_4v4_four_goals": _t(
        "four cones mark the corners of a 30 by 40 m pitch; the four squares are 2 m goals, one a couple of metres inside each corner",
        "四个锥标围出 30×40 米的场地；四个方块是 2 米宽的小球门，各放在离角两米左右的内侧",
        "四個錐標圍出 30×40 米的場地；四個方塊是 2 米寬的小球門，各放在離角兩米左右的內側"),
    "warmup_y_pattern": _t(
        "four cones are the four stations of the Y: the start, the pivot 15 m in front of it, and a wide station 12 m to each side of the pivot and 10 m beyond it",
        "四个锥标是 Y 字的四个站位：起点；支点在起点前方 15 米；两个分边点在支点左右各 12 米、再往前 10 米",
        "四個錐標是 Y 字的四個站位：起點；支點在起點前方 15 米；兩個分邊點在支點左右各 12 米、再往前 10 米"),
    "warmup_first_touch_gate": _t(
        "the four cones make two gates, each a metre and a half wide, one ahead-left and one ahead-right of the receiver: the first touch has to take the ball through one of them, alternating left and right",
        "四个锥标摆成两个门，各约 1.5 米宽，一个在接球人的左前方、一个在右前方；第一脚触球要把球带过其中一个门，左右交替",
        "四個錐標擺成兩個門，各約 1.5 米寬，一個在接球人的左前方、一個在右前方；第一腳觸球要把球帶過其中一個門，左右交替"),
    "possession_3_zone": _t(
        "four cones mark the corners of the 25 by 40 m grid and four more the two dividing lines across it, 13 m apart; the line between two cones is the boundary of a zone",
        "四个锥标围出 25×40 米的场地，另外四个标出两条横贯场地的分区线，两条线相距 13 米；两个锥标之间的连线就是分区和场地的边界",
        "四個錐標圍出 25×40 米的場地，另外四個標出兩條橫貫場地的分區線，兩條線相距 13 米；兩個錐標之間的連線就是分區和場地的邊界"),
    "warmup_rotation_square": _t(
        "four cones 12 m apart make a square; each is a station, and a player runs to the cone he passed to",
        "四个锥标相距 12 米摆成正方形，每个锥标是一个站位，传给谁就跑到那个锥标",
        "四個錐標相距 12 米擺成正方形，每個錐標是一個站位，傳給誰就跑到那個錐標"),
    "warmup_two_ball": _t(
        "four cones 12 m apart make a square; they are the four stations the two balls travel round",
        "四个锥标相距 12 米摆成正方形，是两个球轮转经过的四个站位",
        "四個錐標相距 12 米擺成正方形，是兩個球輪轉經過的四個站位"),
    "defend_1v1_channel": _t(
        "four cones mark the channel: the attacker starts through the bottom pair and scores by dribbling out through the top pair",
        "四个锥标围出通道：进攻者从底端两个锥标之间出发，把球带出顶端两个锥标之间算赢",
        "四個錐標圍出通道：進攻者從底端兩個錐標之間出發，把球帶出頂端兩個錐標之間算贏"),
    "ssg_5v5_two_touch": _t(
        "four cones mark the corners of the pitch and the two squares are the goals",
        "四个锥标标出场地四角，两个方块是两端的球门",
        "四個錐標標出場地四角，兩個方塊是兩端的球門"),
    "ssg_": _t(
        "four cones mark the corners of the pitch — its size is in the set-up line — and the two squares are 2 m goals on the two end lines",
        "四个锥标标出场地四角（尺寸见【组织】），两个方块是两端线上各 2 米宽的小球门",
        "四個錐標標出場地四角（尺寸見【組織】），兩個方塊是兩端線上各 2 米寬的小球門"),
    "ssg_6v6_transition": _t(
        "the two squares are the goals at either end; the game uses the full width between them",
        "两个方块是两端的球门，比赛用两门之间的整个宽度",
        "兩個方塊是兩端的球門，比賽用兩門之間的整個寬度"),
    "transition_": _t(
        "four cones mark the corners of the pitch — its size is in the set-up line — and the two squares are 2 m goals on the two end lines",
        "四个锥标标出场地四角（尺寸见【组织】），两个方块是两端线上各 2 米宽的小球门",
        "四個錐標標出場地四角（尺寸見【組織】），兩個方塊是兩端線上各 2 米寬的小球門"),
    "finish_penalty_routine": _t(
        "the cone is the turning mark of the sprint the taker runs before he steps up",
        "锥标是主罚者罚球前折返冲刺的转折点",
        "錐標是主罰者罰球前折返衝刺的轉折點"),
    "passing_": _t(
        "a cone at each station of the shape, 10 to 12 m apart; the passer runs to the cone he passed to and joins that line",
        "每个站位一个锥标，相邻锥标相距 10–12 米；传给谁就跑到那个锥标排到队尾",
        "每個站位一個錐標，相鄰錐標相距 10–12 米；傳給誰就跑到那個錐標排到隊尾"),
    "cond_shuttle_finish": _t(
        "the two cones are 20 m apart and are the turning lines of the shuttle; touch the far one and come back",
        "两个锥标相距 20 米，是折返的两条线，碰到远端锥标再回来",
        "兩個錐標相距 20 米，是折返的兩條線，碰到遠端錐標再回來"),
    "cond_repeat_sprint": _t(
        "four cones in a line 10 m apart are the sprint marks; each leg goes to the next one and back",
        "四个锥标排成一列、相距 10 米，是冲刺标记；每段冲到下一个锥标再回来",
        "四個錐標排成一列、相距 10 米，是衝刺標記；每段衝到下一個錐標再回來"),
    "cond_box_to_box": _t(
        "the two cones are 60 m apart — the start on the edge of one box and the turn on the halfway line",
        "两个锥标相距 60 米：起点在一侧禁区线上，折返点在中线上",
        "兩個錐標相距 60 米：起點在一側禁區線上，折返點在中線上"),
    "touch_": _t(
        "four cones mark a box 10 m square; the first touch has to keep the ball inside it, and a ball that crosses a cone line is a loss",
        "四个锥标围出 10 米见方的区域；第一脚触球要把球留在区域内，球越过锥标连线算丢球",
        "四個錐標圍出 10 米見方的區域；第一腳觸球要把球留在區域內，球越過錐標連線算丟球"),
    "overload_": _t(
        "four cones mark the corners of a grid about 30 m long and 25 m wide; the line between two cones is the boundary, and the ball is out the moment it crosses it",
        "四个锥标围出约 30 米长、25 米宽的场地；两个锥标之间的连线就是边界，球一越线就算出界",
        "四個錐標圍出約 30 米長、25 米寬的場地；兩個錐標之間的連線就是邊界，球一越線就算出界"),
    "finish_long_range": _t(
        "the two cones stand 6 m apart on a line 25 m from goal; the shot has to be struck before the ball crosses that line",
        "两个锥标相距 6 米，摆在离球门 25 米处标出射门线；球过线之前必须出脚",
        "兩個錐標相距 6 米，擺在離球門 25 米處標出射門線；球過線之前必須出腳"),
}


def gear_of(drill_id: str):
    if drill_id in GEAR:
        return GEAR[drill_id]
    for key, text in GEAR.items():
        if key.endswith("_") and drill_id.startswith(key):
            return text
    return None


# How a drill is scored and what counts as out — the two words a note uses
# without ever defining them. Keyed like GEAR: by id, or by the prefix a
# family shares.
RULES = {
    "possession_3_zone": _t(
        "A point is one ball played out of an end zone, through the middle zone, and controlled by a player in the far end zone; round the outside of the grid does not count. The ball is out the moment it crosses a cone line, and the team that touched it last gives it up.",
        "一分 = 球从一端区传出、穿过中间区、被另一端区的人停住；从场地外侧绕过去不算。球一越过锥标连线就算出界，最后触球的一方交出球权。",
        "一分 = 球從一端區傳出、穿過中間區、被另一端區的人停住；從場地外側繞過去不算。球一越過錐標連線就算出界，最後觸球的一方交出球權。"),
    "possession_7v4": _t(
        "Eight consecutive passes is a point for the team keeping it; winning the ball or forcing it over a cone line is a point for the four. The ball is out the moment it crosses a line between two cones.",
        "控球方连续传 8 脚算一分；防守方断下球或把球逼出边线算一分。球越过两个锥标之间的连线即算出界。",
        "控球方連續傳 8 腳算一分；防守方斷下球或把球逼出邊線算一分。球越過兩個錐標之間的連線即算出界。"),
    "overload_": _t(
        "Eight consecutive passes is a point; the defenders score by winning the ball or putting it over a cone line. The ball is out the moment it crosses a line between two cones.",
        "连续传 8 脚算一分；防守方断球或把球弄出锥标连线算一分。球越过两个锥标之间的连线即算出界。",
        "連續傳 8 腳算一分；防守方斷球或把球弄出錐標連線算一分。球越過兩個錐標之間的連線即算出界。"),
    "possession_overload_4v2_plus": _t(
        "Six passes then a switch to the far side is a point; a turnover is a point for the defenders. The ball is out when it crosses the touchline the drill is played inside.",
        "传 6 脚后转移到弱侧算一分；被断球算防守方一分。球越出练习使用的边线即算出界。",
        "傳 6 腳後轉移到弱側算一分；被斷球算防守方一分。球越出練習使用的邊線即算出界。"),
    "rondo_": _t(
        "Two touches each. Ten consecutive passes is a point for the outside, and a pass split between two defenders counts two; the defenders score by winning it or knocking it out of the ring.",
        "限两脚触球。圈外连续传 10 脚算一分，从两名防守者之间穿过的那一脚算两分；防守方断球或把球破坏出圈算一分。",
        "限兩腳觸球。圈外連續傳 10 腳算一分，從兩名防守者之間穿過的那一腳算兩分；防守方斷球或把球破壞出圈算一分。"),
    "ssg_": _t(
        "A goal is the whole ball through a mini-goal along the ground; head height and above does not count. The ball is out when it crosses the line between two corner cones, and it restarts from where it went out.",
        "球贴地整体穿过小球门算进球，高于头部不算。球越过两个角上锥标之间的连线算出界，从出界处重新开始。",
        "球貼地整體穿過小球門算進球，高於頭部不算。球越過兩個角上錐標之間的連線算出界，從出界處重新開始。"),
    "ssg_4v4_four_goals": _t(
        "A goal is the whole ball through either of the two goals a team is attacking, along the ground. The ball is out when it crosses the line between two corner cones, and it restarts from where it went out.",
        "球贴地整体穿过本队进攻的那两个小球门之一算进球。球越过两个角上锥标之间的连线算出界，从出界处重新开始。",
        "球貼地整體穿過本隊進攻的那兩個小球門之一算進球。球越過兩個角上錐標之間的連線算出界，從出界處重新開始。"),
    "transition_": _t(
        "A goal is the whole ball through a mini-goal along the ground. The ball is out when it crosses the line between two corner cones; whoever wins it there attacks the other way at once.",
        "球贴地整体穿过小球门算进球。球越过两个角上锥标之间的连线算出界；在那里得球的一方立刻向另一侧进攻。",
        "球貼地整體穿過小球門算進球。球越過兩個角上錐標之間的連線算出界；在那裡得球的一方立刻向另一側進攻。"),
    "duel_": _t(
        "The rep is scored if the ball crosses the goal line between the posts; it ends when the defender wins it, the keeper holds it, or the ball leaves the playing area.",
        "球从门柱之间越过门线算得分；防守者断球、门将控住球或球出练习区域，本回合结束。",
        "球從門柱之間越過門線算得分；防守者斷球、門將控住球或球出練習區域，本回合結束。"),
    "defend_1v1_channel": _t(
        "The attacker scores by dribbling the ball out between the two top cones under control; the defender scores by winning the ball or forcing it out of the channel.",
        "进攻者把球控住带出顶端两个锥标之间算赢；防守者断下球或把球逼出通道算赢。",
        "進攻者把球控住帶出頂端兩個錐標之間算贏；防守者斷下球或把球逼出通道算贏。"),
}


def rules_of(drill_id: str):
    if drill_id in RULES:
        return RULES[drill_id]
    for key, text in RULES.items():
        if key.endswith("_") and drill_id.startswith(key):
            return text
    return None
