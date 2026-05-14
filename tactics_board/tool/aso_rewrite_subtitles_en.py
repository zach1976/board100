"""Rewrite en-US subtitle.txt across all 16 apps with benefit-driven copy.

Drops the lazy "<sport> plays, animated. Free." template. Each subtitle:
- ≤30 chars (Apple cap)
- Benefit > feature
- Concrete action verb where possible
- No "Free" (that belongs in description body, not headline real estate)

Run once. Idempotent — re-running just rewrites with the same values.
"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "fastlane" / "metadata"

# (app_folder, new_subtitle_en)
SUBTITLES_EN: dict[str, str] = {
    "badminton":     "Win Doubles Without Words.",
    "baseball":      "Every Pitch Has a Plan.",
    "basketball":    "Draw It. Run It. Score.",
    "beachTennis":   "Stack. Smash. Win the Sand.",
    "fieldHockey":   "Penalty Corners, Solved.",
    "footvolley":    "Plan the Touch. Own the Sand.",
    "handball":      "Draw the Break. Read the Wing.",
    "pickleball":    "Win the Kitchen. Win the Game.",
    "rugby":         "Win the Set Piece. Win Match.",
    "sepakTakraw":   "Tekong Serves. Striker Wins.",
    "soccer":        "Draw a Play. Watch It Run.",
    "tableTennis":   "Read the Spin. Plan the Rally.",
    "tactics_board": "15 Sports. One Tactical Board.",
    "tennis":        "See the Point Before You Play.",
    "volleyball":    "Rotations, Demystified.",
    "waterPolo":     "Plan the 6-on-5. Win the Pool.",
}

MAX_CHARS = 30


def main() -> None:
    rows = []
    for app, new_sub in SUBTITLES_EN.items():
        assert len(new_sub) <= MAX_CHARS, f"{app}: '{new_sub}' is {len(new_sub)} chars"
        target = ROOT / app / "en-US" / "subtitle.txt"
        old = target.read_text(encoding="utf-8").strip() if target.exists() else "<missing>"
        target.write_text(new_sub + "\n", encoding="utf-8")
        rows.append((app, old, new_sub, len(new_sub)))

    width_app = max(len(r[0]) for r in rows)
    print(f"{'app'.ljust(width_app)}  | chars | old → new")
    print("-" * 80)
    for app, old, new, ln in rows:
        print(f"{app.ljust(width_app)}  | {ln:>5} | {old!r}")
        print(f"{' ' * width_app}  |       → {new!r}")


if __name__ == "__main__":
    main()
