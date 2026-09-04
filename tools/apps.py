#!/usr/bin/env python3
"""Where each app's files live. Import this instead of hardcoding paths.

Since 2026-09-04 every app owns its store assets, the way it already owns its
platform folders and artwork:

    SoccerBoard/fastlane/metadata/<locale>/*.txt      App Store text
    SoccerBoard/fastlane/screenshots/<locale>/*.png   App Store screenshots
    SoccerBoard/fastlane/play/metadata/android/...    Play listing
    SoccerBoard/assets/icon/app_icon.png              icon + splash sources

The hub (tactics_board) has the same shape inside tactics_board/. Nothing
lives under "<core>/fastlane/<some other app>/" any more, so no script can
reach into another app's listing by accident.

    from apps import APPS, metadata_dir, screenshots_dir, play_metadata_dir
"""
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
TABLE = Path(__file__).resolve().parent / "sports.tsv"

_FIELDS = ("key", "dir", "bundle", "name_en", "name_zh", "name_ja",
           "admob_ios", "admob_android")


def _load() -> dict:
    apps = {}
    for line in TABLE.read_text(encoding="utf-8").splitlines():
        if line.startswith("#") or not line.strip():
            continue
        cols = line.split("\t")
        if len(cols) < len(_FIELDS):
            continue
        row = dict(zip(_FIELDS, cols))
        # "-" in the dir column means the hub, which is the core project itself.
        row["dir"] = "tactics_board" if row["dir"] == "-" else row["dir"]
        row["is_hub"] = row["key"] == "tactics_board"
        for f in ("admob_ios", "admob_android"):
            row[f] = None if row[f] == "-" else row[f]
        apps[row["key"]] = row
    return apps


APPS = _load()
KEYS = list(APPS)


def app_dir(key: str) -> Path:
    """Project directory of one app (raises for an unknown key)."""
    return REPO / APPS[key]["dir"]


def metadata_dir(key: str) -> Path:
    """App Store metadata root — contains one folder per locale."""
    return app_dir(key) / "fastlane" / "metadata"


def screenshots_dir(key: str) -> Path:
    """App Store screenshots root — contains one folder per locale."""
    return app_dir(key) / "fastlane" / "screenshots"


def play_metadata_dir(key: str) -> Path:
    """Play listing root — .../metadata/android/<playLocale>/."""
    return app_dir(key) / "fastlane" / "play" / "metadata" / "android"


def icon_source(key: str) -> Path:
    """The 1024px icon an app's native icons are generated from."""
    return app_dir(key) / "assets" / "icon" / "app_icon.png"


def splash_source(key: str) -> Path:
    return app_dir(key) / "assets" / "icon" / "splash_logo.png"


def bundle_id(key: str) -> str:
    return APPS[key]["bundle"]


if __name__ == "__main__":
    for k in KEYS:
        print(f"{k:15} {APPS[k]['dir']:20} {APPS[k]['bundle']}")
