"""Drill libraries, one module per sport.

`CATALOGUE` is the only place a sport is switched on: add a module with a
function returning its drills, register it here, and `tools/gen_drills.py`
writes tactics_board/assets/drills/<sport>.json for it.
"""
from . import (badminton, baseball, basketball, beach_tennis, field_hockey,
               footvolley, handball,
               pickleball,
               soccer,
               rugby, sepak_takraw, table_tennis, tennis,
               volleyball, water_polo)

CATALOGUE = {
    "soccer": soccer.soccer_library,
    "basketball": basketball.basketball_library,
    "volleyball": volleyball.volleyball_library,
    "badminton": badminton.badminton_library,
    "tennis": tennis.tennis_library,
    "pickleball": pickleball.pickleball_library,
    "tableTennis": table_tennis.table_tennis_library,
    "handball": handball.handball_library,
    "rugby": rugby.rugby_library,
    "fieldHockey": field_hockey.field_hockey_library,
    "waterPolo": water_polo.water_polo_library,
    "baseball": baseball.baseball_library,
    "sepakTakraw": sepak_takraw.sepak_takraw_library,
    "beachTennis": beach_tennis.beach_tennis_library,
    "footvolley": footvolley.footvolley_library,
}
