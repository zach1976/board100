#!/usr/bin/env python3
"""Generate Google Play store *text* metadata from the iOS App Store copy.

For each sport, mirrors the established pattern of the first 4 Play apps
(basketball/soccer/volleyball/badminton):

  fastlane/play/<sport>/metadata/android/<playLocale>/
    title.txt              <- iOS name.txt          (<=30 chars)
    short_description.txt   <- iOS subtitle.txt, EXCEPT en-US which is custom (<=80)
    full_description.txt    <- iOS description.txt   (<=4000)
    changelogs/1.txt        <- generated (en-US only)

Non-English locales are a verbatim copy of the iOS metadata. en-US gets three
platform tweaks to match the existing Play listings:
  1. de-duplicate the "Name — Name lets/gives …" intro to "Name lets/gives …"
  2. insert a "Free forever · Works offline · No account" line after the intro
  3. genericise the iOS-only "AirPlay to TV …" bullet to "Big-screen ready …"

Graphics are produced separately by tool/gen_play_assets.py.

Usage:
  python3 tool/gen_play_metadata.py new          # the 12 apps without Play text
  python3 tool/gen_play_metadata.py all          # every sport (overwrites)
  python3 tool/gen_play_metadata.py tennis rugby # specific sports
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IOS = os.path.join(ROOT, "fastlane", "metadata")
PLAY = os.path.join(ROOT, "fastlane", "play")

# iOS locale dir -> Play locale dir
LOCALES = {
    "en-US": "en-US",
    "es-ES": "es-ES",
    "fr-FR": "fr-FR",
    "id": "id",
    "ja": "ja-JP",
    "ko": "ko-KR",
    "ms": "ms",
    "th": "th",
    "vi": "vi",
    "zh-Hans": "zh-CN",
    "zh-Hant": "zh-TW",
}

# The 4 apps already published to Play; "new" targets everything else.
EXISTING = {"basketball", "soccer", "volleyball", "badminton"}

# Custom en-US short descriptions (<=80). The iOS subtitle (<=30) is too terse
# for Play's 80-char slot, so en-US gets purpose-written copy like the first 4.
SHORT_EN = {
    "baseball": "Set defensive shifts, base-running and pitcher coverage. Free, offline.",
    "beachTennis": "Plan doubles formations and rally patterns on sand. Free, offline.",
    "fieldHockey": "Plan formations, penalty corners and pressing triggers. Free, offline.",
    "footvolley": "Plan doubles plays and rotations on the sand court. Free, offline.",
    "handball": "Design attack systems, 6-0 and 5-1 defenses, fast breaks. Free, offline.",
    "pickleball": "Plan kitchen tactics, stacking and serve patterns. Free, offline.",
    "rugby": "Design lineouts, scrum plays and back-line patterns. Free, offline.",
    "sepakTakraw": "Plan tekong serves, feeders and spikes for regu. Free, offline.",
    "tableTennis": "Plan serves, returns and 3rd-ball attacks. Free, offline.",
    "tennis": "Plan return positions, doubles formations and rallies. Free, offline.",
    "waterPolo": "Plan 4-2 attack, M-drop defense and 6-on-5 plays. Free, offline.",
    "tactics_board": "Draw plays, animate and share across every sport. Free, offline.",
}

AIRPLAY_IOS = "- AirPlay to TV — turn the locker room into a war room"
AIRPLAY_PLAY = "- Big-screen ready — mirror to a TV and turn the locker room into a war room"
FREE_LINE = "Free forever · Works offline · No account"


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def board_name(desc):
    """The board name, e.g. 'Baseball Board', taken from the intro line
    'Baseball Board — Baseball Board lets …'. Falls back to '' if not found."""
    for line in desc.splitlines():
        if " — " in line:
            return line.split(" — ", 1)[0].strip()
    return ""


def transform_en(desc):
    """Apply the three en-US platform tweaks to the iOS description."""
    board = board_name(desc)
    lines = desc.split("\n")
    # 1. de-duplicate the "Name — Name …" intro
    if board:
        lines = [ln.replace(f"{board} — {board}", board, 1) for ln in lines]
    # 2. insert the free/offline line as its own paragraph after the intro.
    #    Layout is: hook \n '' \n intro \n '' \n <body…>  -> insert at index 4.
    if len(lines) >= 4 and lines[1] == "" and lines[3] == "":
        lines = lines[:4] + [FREE_LINE, ""] + lines[4:]
    text = "\n".join(lines)
    # 3. genericise the iOS-only AirPlay bullet
    text = text.replace(AIRPLAY_IOS, AIRPLAY_PLAY)
    return text


def gen_changelog_en(desc):
    """First-release changelog (en-US) derived from the deduped intro line."""
    board = board_name(desc) or "the board"
    parts = desc.split("\n")
    intro = parts[2].replace(f"{board} — {board}", board, 1).strip() if len(parts) >= 3 else ""
    return (
        f"Welcome to {board}!\n\n"
        f"{intro}\n\n"
        "- Draw arrows, lines and zones\n"
        "- Save unlimited tactics, share as image or PDF\n"
        "- Tap Play to animate every move, step by step\n"
        "- Works fully offline — no account needed\n\n"
        "This is our first release. We'd love your feedback."
    )


def gen_sport(sport, fill_only=False):
    warnings = []
    for ios_loc, play_loc in LOCALES.items():
        sdir = os.path.join(IOS, sport, ios_loc)
        if not os.path.isdir(sdir):
            warnings.append(f"{sport}/{ios_loc}: missing iOS locale, skipped")
            continue
        out = os.path.join(PLAY, sport, "metadata", "android", play_loc)
        # fill mode: never overwrite a locale that already has copy (preserves
        # the hand-tuned en-US of already-published apps).
        if fill_only and os.path.exists(os.path.join(out, "full_description.txt")):
            continue

        name = read(os.path.join(sdir, "name.txt")).strip()
        if len(name) > 30:
            warnings.append(f"{sport}/{play_loc} title {len(name)}>30: {name}")
        write(os.path.join(out, "title.txt"), name + "\n")

        if play_loc == "en-US":
            short = SHORT_EN.get(sport, read(os.path.join(sdir, "subtitle.txt")).strip())
        else:
            short = read(os.path.join(sdir, "subtitle.txt")).strip()
        if len(short) > 80:
            warnings.append(f"{sport}/{play_loc} short {len(short)}>80: {short}")
        write(os.path.join(out, "short_description.txt"), short + "\n")

        desc = read(os.path.join(sdir, "description.txt")).rstrip("\n")
        full = transform_en(desc) if play_loc == "en-US" else desc
        if len(full) > 4000:
            warnings.append(f"{sport}/{play_loc} full {len(full)}>4000")
        write(os.path.join(out, "full_description.txt"), full + "\n")

        if play_loc == "en-US":
            write(
                os.path.join(out, "changelogs", "1.txt"),
                gen_changelog_en(desc) + "\n",
            )
    print(f"✓ {sport}")
    for w in warnings:
        print(f"  ⚠ {w}")
    return warnings


def main(argv):
    all_sports = sorted(
        d for d in os.listdir(IOS) if os.path.isdir(os.path.join(IOS, d))
    )
    fill_only = False
    if argv and argv[0] == "fill":
        fill_only = True
        argv = argv[1:]
    if not argv or argv[0] == "new":
        targets = [s for s in all_sports if s not in EXISTING]
    elif argv[0] == "all":
        targets = all_sports
    else:
        targets = argv
    mode = " (fill: only missing locales)" if fill_only else ""
    print(f"Generating Play text for: {', '.join(targets)}{mode}\n")
    warns = []
    for s in targets:
        warns += gen_sport(s, fill_only=fill_only)
    print(f"\nDone. {len(targets)} apps, {len(warns)} warnings.")


if __name__ == "__main__":
    main(sys.argv[1:])
