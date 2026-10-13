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

PEPPER3 = _t(
    "Hit, dig, set round the triangle without letting the ball drop; every ten contacts the three move on one role — hitter to digger, digger to setter, setter to hitter.",
    "扣、垫、传绕三角不落地；每 10 次触球三人轮换一个角色——扣球的去防守，防守的去二传，二传去扣球。",
    "扣、墊、傳繞三角不落地；每 10 次觸球三人輪換一個角色——扣球的去防守，防守的去二傳，二傳去扣球。")

PAIRS = _t(
    "Count the contacts without the ball touching the floor; at 50 both take a step further apart and start again, and when it drops the count goes back to zero.",
    "数不落地的触球次数；到 50 次两人各退一步重新开始，球落地就从零重数。",
    "數不落地的觸球次數；到 50 次兩人各退一步重新開始，球落地就從零重數。")

WASH = _t(
    "One side serves; the receiving side must win that rally and then the free ball the coach sends in straight after. Both won is a big point, a split is a wash and nobody scores. First to three big points, then both sides rotate one position.",
    "一方发球，接发方必须赢下这一分，再赢下教练紧接着送进来的调整球。两球都赢得一个大分，一胜一负算抵消、谁都不得分。先得 3 个大分的一方赢，然后两边各轮转一个位置。",
    "一方發球，接發方必須贏下這一分，再贏下教練緊接著送進來的調整球。兩球都贏得一個大分，一勝一負算抵消、誰都不得分。先得 3 個大分的一方贏，然後兩邊各輪轉一個位置。")

KING = _t(
    "The challengers serve. If they win the rally they walk round the post to the kings' side and the kings go to the back of the line; only the kings' side scores. First pair to seven wins, then the pairs are reshuffled.",
    "挑战者发球。挑战者赢下这一分就绕过网柱换到擂主一侧，原擂主排到队尾；只有擂主一侧赢球才得分。先得 7 分的一对获胜，然后重新分组。",
    "挑戰者發球。挑戰者贏下這一分就繞過網柱換到擂主一側，原擂主排到隊尾；只有擂主一側贏球才得分。先得 7 分的一對獲勝，然後重新分組。")

FLOW = {
    "vb_warm_pepper_three": PEPPER3,
    "vb_warm_partner_pass": PAIRS, "vb_warm_partner_set": PAIRS,
    "vb_pass_overhead": SERVE_RULES,
    "vb_pass_": FEED_RULES, "vb_oos_": FEED_RULES, "vb_dig_": FEED_RULES,
    "vb_spike_": FEED_RULES, "vb_offspeed_": FEED_RULES, "vb_combo_": FEED_RULES,
    "vb_setter_off_net": SERVE_IN_RULES,
    "vb_counter_cover": FEED_RULES, "vb_counter_": SERVE_IN_RULES,
    "vb_rot51_": ROTATION, "vb_rot62_": ROTATION,
    "vb_game_wash": WASH, "vb_game_king": KING,
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

SHOT = _t(
    "the shaded zone is where this shot has to land",
    "阴影区是这一种进攻要打到的落点",
    "陰影區是這一種進攻要打到的落點")

GEAR = {
    "vb_spike_": SHOT, "vb_offspeed_": SHOT, "vb_warm_hitting_lines": SHOT,
    "vb_pass_": TARGET, "vb_dig_": TARGET, "vb_combo_": TARGET,
    "vb_counter_": TARGET, "vb_rot51_": TARGET, "vb_rot62_": TARGET,
    "vb_game_wash": TARGET, "vb_setter_off_net": TARGET,
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
