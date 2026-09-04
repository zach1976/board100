"""Drill libraries, one module per sport.

`CATALOGUE` is the only place a sport is switched on: add a module with a
function returning its drills, register it here, and `tools/gen_drills.py`
writes tactics_board/assets/drills/<sport>.json for it.
"""
from . import badminton, basketball, soccer, volleyball

CATALOGUE = {
    "soccer": soccer.soccer_library,
    "basketball": basketball.basketball_drills,
    "volleyball": volleyball.volleyball_library,
    "badminton": badminton.badminton_library,
}
