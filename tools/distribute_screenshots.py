#!/usr/bin/env python3
"""Put the composited store screenshots where the uploader reads them.

tool/aso_design_compositor.py writes to
`tactics_board/fastlane/screenshots/<sport>/<locale>/` — the hub's tree, one
folder per sport, which is where the pipeline was built when every app came
out of the hub. `upload_screenshots.py` asks tools/apps.py for
`screenshots_dir(key)` and reads `<App>/fastlane/screenshots/<locale>/`.
Nothing joined the two, so running the documented `--all` refreshed nothing
that gets uploaded. This is the missing step.

    python3 tools/distribute_screenshots.py soccer
    python3 tools/distribute_screenshots.py all
"""
import pathlib, shutil, sys

REPO = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / 'tools'))
from apps import APPS, screenshots_dir


def distribute(key: str) -> int:
    sport = 'tactics_board' if key == 'tactics_board' else key
    src = REPO / 'tactics_board' / 'fastlane' / 'screenshots' / sport
    if not src.is_dir():
        print(f'⚠️  {key}: nothing composited at {src}')
        return 0
    dst_root = pathlib.Path(screenshots_dir(key))
    n = 0
    for loc in sorted(p for p in src.iterdir() if p.is_dir()):
        dst = dst_root / loc.name
        dst.mkdir(parents=True, exist_ok=True)
        # iPad shots are made by a different lane and are not ours to clear.
        for old in dst.glob('*.png'):
            if not old.name.startswith('ipad'):
                old.unlink()
        for f in sorted(loc.glob('*.png')):
            shutil.copy2(f, dst / f.name)
            n += 1
    print(f'✅ {key}: {n} files → {dst_root}')
    return n


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    keys = list(APPS) if sys.argv[1] == 'all' else [sys.argv[1]]
    total = sum(distribute(k) for k in keys)
    print(f'{total} files')


if __name__ == '__main__':
    main()
