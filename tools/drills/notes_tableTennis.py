"""Table tennis: what the zones and cones are, and how each drill keeps going."""
from .rules_common import FEED_RULES, POINT_RULES, RALLY_RULES, SERVE_RULES


def _t(en, zh, zht):
    return {"en": en, "en-GB": en, "zh-CN": zh, "zh-TW": zht}


FLOW = {
    "tt_warm_": RALLY_RULES,
    "tt_multiball": FEED_RULES,
    "tt_footwork_": FEED_RULES,
    "tt_rally_": RALLY_RULES,
    "tt_short_": FEED_RULES,
    "tt_loop_": RALLY_RULES,
    "tt_kill_": FEED_RULES,
    "tt_defence_": FEED_RULES,
    "tt_serve_": SERVE_RULES,
    "tt_game_": POINT_RULES,
}

ZONE = _t(
    "the shaded zone is the part of the table the ball has to land on — count only the ones that do",
    "阴影区是球要落的台面区域，只有落进去的才算",
    "陰影區是球要落的檯面區域，只有落進去的才算")

GEAR = {
    "tt_warm_": ZONE, "tt_rally_": ZONE, "tt_loop_": ZONE, "tt_kill_": ZONE,
    "tt_defence_": ZONE, "tt_game_serve_receive": ZONE,
    "tt_multiball": _t(
        "the coach alternates the feed between the forehand and the backhand corner; the two shaded zones on the coach's half are where the forehand and the backhand have to go back to",
        "教练交替把球喂到正手位和反手位；教练那半台的两个阴影区，是正手和反手回球要落的位置",
        "教練交替把球餵到正手位和反手位；教練那半檯的兩個陰影區，是正手和反手回球要落的位置"),
    "tt_footwork_": _t(
        "the cones stand on the floor just behind the end line and mark the spots the player has to get to for each ball",
        "锥标放在端线后面的地上，标出每一球要移动到的击球位置",
        "錐標放在端線後面的地上，標出每一球要移動到的擊球位置"),
    "tt_short_": _t(
        "the shaded zone on the far half is where the short-game stroke has to land",
        "对方半台的阴影区是台内球要落的区域",
        "對方半檯的陰影區是檯內球要落的區域"),
    "tt_serve_third_ball": _t(
        "the shaded zone near the net is where the serve has to land; the deep one is where the third-ball attack has to go",
        "靠网的阴影区是发球要落的区域，靠端线的那个是第三板抢攻要打到的区域",
        "靠網的陰影區是發球要落的區域，靠端線的那個是第三板搶攻要打到的區域"),
    "tt_serve_": _t(
        "the shaded zone is where the serve has to land",
        "阴影区是发球要落的区域",
        "陰影區是發球要落的區域"),
    "tt_game_half_table": _t(
        "the two shaded zones mark the backhand diagonal in play — each player's backhand half of the table; a ball that lands outside that half is out",
        "两个阴影区标出比赛用的反手斜线：各自的反手半台，落在这半台以外算出界",
        "兩個陰影區標出比賽用的反手斜線：各自的反手半檯，落在這半檯以外算出界"),
}


# Table tennis is not played inside lines: the ball has to land on the
# table, and the edges count. The court wording every other net sport uses
# ("inside the lines… a ball on the line is in") said nothing here.
TT_SCORE = {
    "en": "A ball that lands on the opponent's half of the table — the edge counts — wins the point; missing the table, the net, or letting it bounce twice on your own side loses it. Serve changes every two points.",
    "en-GB": "A ball that lands on the opponent's half of the table — the edge counts — wins the point; missing the table, the net, or letting it bounce twice on your own side loses it. Serve changes every two points.",
    "zh-CN": "球落在对方台面上（擦边算）得分；没上台、下网，或让球在本方台面弹两次失分。每两分换发球。",
    "zh-TW": "球落在對方檯面上（擦邊算）得分；沒上檯、下網，或讓球在本方檯面彈兩次失分。每兩分換發球。",
    "ja-JP": "相手コートの台上に落ちれば得点（エッジも有効）。台を外す、ネット、自コートでツーバウンドは失点。サーブは2本ごとに交代。",
    "ko-KR": "상대 쪽 테이블에 떨어지면 득점(엣지도 인정). 테이블을 벗어나거나 네트, 자기 쪽에서 두 번 튀면 실점. 서브는 2점마다 바뀐다.",
    "es-ES": "La bola que bota en la mitad de la mesa del rival —el canto cuenta— gana el punto; fallar la mesa, la red o dejar que bote dos veces en tu lado lo pierde. El saque cambia cada dos puntos.",
    "fr-FR": "La balle qui touche la demi-table adverse — l'arête compte — gagne le point ; rater la table, le filet ou laisser deux rebonds de son côté le perd. Le service change tous les deux points.",
    "id-ID": "Bola yang jatuh di separuh meja lawan — tepi meja dihitung — memenangkan poin; tidak mengenai meja, menyangkut net, atau memantul dua kali di sisi sendiri kehilangan poin. Servis berganti setiap dua poin.",
    "ms-MY": "Bola yang jatuh di separuh meja lawan — tepi meja dikira — memenangi mata; tidak mengena meja, tersangkut jaring, atau melantun dua kali di pihak sendiri kehilangan mata. Servis bertukar setiap dua mata.",
    "th-TH": "ลูกที่ตกบนโต๊ะฝั่งคู่แข่ง (ขอบโต๊ะนับ) ได้แต้ม ตีไม่ลงโต๊ะ ติดเน็ต หรือปล่อยให้เด้งสองครั้งฝั่งตัวเองเสียแต้ม เปลี่ยนเสิร์ฟทุกสองแต้ม",
    "vi-VN": "Bóng rơi trên nửa bàn đối phương — chạm cạnh bàn vẫn tính — thì thắng điểm; đánh ra ngoài bàn, vào lưới, hoặc để bóng nảy hai lần bên mình là mất điểm. Đổi giao bóng sau mỗi hai điểm.",
}

RULES = {
    "tt_game_": TT_SCORE,
}
