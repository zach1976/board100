"""One-shot: strip the duplicated App-name prefix from line 3 of description.txt.

Pattern: `<Name> — <Name> <rest>` collapses to `<Name> <rest>`.
Scans en-US, zh-Hans, zh-Hant across all apps; only edits when the duplication
actually exists (other locales use `<Name> — <descriptor>` intentionally).
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "fastlane" / "metadata"
LOCALES = ("en-US", "zh-Hans", "zh-Hant")
# Capture shortest leading run that repeats with " — " separator.
PATTERN = re.compile(r"^(.+?) — \1")


def main() -> None:
    fixed: list[str] = []
    skipped: list[str] = []
    for app_dir in sorted(p for p in ROOT.iterdir() if p.is_dir()):
        for locale in LOCALES:
            desc = app_dir / locale / "description.txt"
            if not desc.exists():
                continue
            lines = desc.read_text(encoding="utf-8").splitlines(keepends=True)
            if len(lines) < 3:
                continue
            line3 = lines[2]
            match = PATTERN.match(line3)
            if not match:
                skipped.append(f"{app_dir.name}/{locale}")
                continue
            prefix = match.group(1)
            # Drop the duplicated `<prefix> — ` while keeping the second `<prefix>`.
            lines[2] = line3[len(prefix) + len(" — ") :]
            desc.write_text("".join(lines), encoding="utf-8")
            fixed.append(f"{app_dir.name}/{locale}  (was: {prefix!r})")

    print(f"Fixed {len(fixed)} files:")
    for entry in fixed:
        print(f"  ✓ {entry}")
    print(f"\nSkipped {len(skipped)} files (no duplication pattern):")
    for entry in skipped:
        print(f"  - {entry}")


if __name__ == "__main__":
    main()
