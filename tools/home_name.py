#!/usr/bin/env python3
"""The name an app puts under its icon, from the name it is sold under.

The home screen truncates: "Field Hockey Board" arrived as "Field Hockey…",
so every sport's icon dropped the word Board. That was right for the long
ones and wrong for the short — "Soccer Board" is narrower than "Tactics
Board", which the hub has shipped under since the beginning and which has
never been reported as cut.

So the hub is the ruler. A name no wider than "Tactics Board" keeps its full
form; anything wider loses " Board". Measured in SF, the font iOS actually
sets the label in, rather than counted in characters — "Tennis Board" is one
character longer than "Rugby Board" and four points narrower than
"Baseball Board".

    python3 tools/home_name.py "Soccer Board"   ->  Soccer Board
    python3 tools/home_name.py "Baseball Board" ->  Baseball

Only English. The Chinese and Japanese names are set in PingFang and
Hiragino, which are not on every machine that runs this, and a name measured
against the wrong face is a name cut on a phone; they keep the plain rule of
dropping the suffix. If anything goes wrong — no Pillow, no SF — the answer
is the short form, which fits by construction.
"""
import sys

ANCHOR = "Tactics Board"
SF = "/System/Library/Fonts/SFNS.ttf"


def home_name(full: str) -> str:
    short = full[: -len(" Board")] if full.endswith(" Board") else full
    try:
        from PIL import ImageFont

        f = ImageFont.truetype(SF, 22)
        return full if f.getlength(full) <= f.getlength(ANCHOR) else short
    except Exception:
        return short


if __name__ == "__main__":
    print(home_name(sys.argv[1] if len(sys.argv) > 1 else ""))
