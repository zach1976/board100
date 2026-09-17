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

def _with_notes(sport: str, lib):
    """Wrap a library so every drill carries its 【连贯】 and 【器材】 lines.

    The texts live in drills/notes_<sport>.py as FLOW and GEAR tables keyed
    by drill id or by the prefix a family shares; a drill that writes its
    own keeps it. Every drill needs a flow; every board with equipment
    needs gear — the build refuses one without.
    """
    import importlib

    def lookup(table, drill_id):
        if drill_id in table:
            return table[drill_id]
        for key, text in table.items():
            if key.endswith("_") and drill_id.startswith(key):
                return text
        return None

    def build():
        from .fitness_all import fitness_for
        # Conditioning is part of every library, and it is the same eight
        # or three drills whatever else the sport has, so it is added here
        # rather than in fifteen library functions. Soccer has its own,
        # inside soccer.py, and fitness_for returns nothing for it.
        drills = lib() + fitness_for(sport)
        try:
            notes = importlib.import_module(f".notes_{sport}", __package__)
        except ModuleNotFoundError:
            return drills
        for d in drills:
            if d.flow is None:
                d.flow = lookup(notes.FLOW, d.id)
            if d.gear is None:
                d.gear = lookup(notes.GEAR, d.id)
            if d.rules is None and hasattr(notes, "RULES"):
                d.rules = lookup(notes.RULES, d.id)
            assert d.flow, f"{sport}/{d.id}: no flow (【连贯】) text"
            assert not d.markers or d.gear, f"{sport}/{d.id}: markers but no gear text"
        return drills
    return build


CATALOGUE = {
    "soccer": _with_notes("soccer", soccer.soccer_library),
    "basketball": _with_notes("basketball", basketball.basketball_library),
    "volleyball": _with_notes("volleyball", volleyball.volleyball_library),
    "badminton": _with_notes("badminton", badminton.badminton_library),
    "tennis": _with_notes("tennis", tennis.tennis_library),
    "pickleball": _with_notes("pickleball", pickleball.pickleball_library),
    "tableTennis": _with_notes("tableTennis", table_tennis.table_tennis_library),
    "handball": _with_notes("handball", handball.handball_library),
    "rugby": _with_notes("rugby", rugby.rugby_library),
    "fieldHockey": _with_notes("fieldHockey", field_hockey.field_hockey_library),
    "waterPolo": _with_notes("waterPolo", water_polo.water_polo_library),
    "baseball": _with_notes("baseball", baseball.baseball_library),
    "sepakTakraw": _with_notes("sepakTakraw", sepak_takraw.sepak_takraw_library),
    "beachTennis": _with_notes("beachTennis", beach_tennis.beach_tennis_library),
    "footvolley": _with_notes("footvolley", footvolley.footvolley_library),
}
