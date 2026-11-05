"""Which installed apps can take a drill pack.

A pack is data: names, notes, positions, moves. Changing any of that needs no
app release — the apps fetch packs and adopt a higher version on their own.
What DOES need a release is a pack that uses something an installed app does
not know how to draw: a new field, a new marker shape, a new category. Such a
pack must name the oldest release that can read it (minClient), so older
apps keep their working library instead of drawing a board with a piece
missing.

That number used to be written by hand in min_client.txt, which meant it was
either forgotten (old apps get a pack they cannot draw) or never lowered (a
text-only fix stops reaching apps it could have reached). Now it is derived:
client_schema.json lists every key and enum value the apps understand and the
first release that does, and a pack's minClient is the newest of the ones it
actually uses. Anything not listed fails the build — the person adding it has
to say which release reads it.
"""
from __future__ import annotations

import json
from pathlib import Path

_SCHEMA = json.loads((Path(__file__).parent / "client_schema.json")
                     .read_text(encoding="utf-8"))


def _v(s: str) -> tuple:
    return tuple(int(x) for x in s.split("."))


class UnknownToClients(ValueError):
    pass


def required_client(pack: dict, floor: str) -> str:
    """The minClient this pack needs; raises on anything unregistered."""
    keys, values = _SCHEMA["keys"], _SCHEMA["values"]
    need = [floor]
    problems = []

    def key(level: str, obj: dict, where: str):
        known = keys[level]
        for k in obj:
            if k not in known:
                problems.append(f"{where}: field {level}.{k!r}")
            else:
                need.append(known[k])

    def value(path: str, v, where: str):
        known = values[path]
        if str(v) not in known:
            problems.append(f"{where}: {path} = {v!r}")
        else:
            need.append(known[str(v)])

    key("pack", pack, pack.get("sport", "?"))
    for d in pack.get("drills", []):
        where = d.get("id", "?")
        key("drill", d, where)
        for f in ("category", "level", "usage"):
            if f in d:
                value(f"drill.{f}", d[f], where)
        board = d.get("board", {})
        key("board", board, where)
        for p in board.get("players", []):
            key("player", p, where)
            for f in ("team", "markerShape", "sportType"):
                if f in p:
                    value(f"player.{f}", p[f], where)
    if problems:
        raise UnknownToClients(
            "the pack uses things installed apps have never been told about — "
            "register each in tools/drills/client_schema.json with the first "
            "release that reads it:\n  " + "\n  ".join(sorted(set(problems))[:20]))
    return max(need, key=_v)
