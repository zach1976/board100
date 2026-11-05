#!/usr/bin/env python3
"""Publish one board app's Android bundle to Google Play, production track.

    python3 tools/play_release.py <key> <aab> <versionCode> [--no-listing] [--dry-run]

Opens an edit, uploads the bundle, puts that versionCode on the production
track as a completed release with the per-language "What's new" from
<App>/fastlane/play/metadata/android/<lang>/changelogs/<versionCode>.txt,
updates each language's store listing (title, short and full description)
from the same folders, and commits the edit, which sends it for review.
--dry-run does everything except the commit and throws the edit away.

The service-account key path is PLAY_SERVICE_ACCOUNT_KEY in ~/projects/.env
(the same key lang1000's scripts/play_upload_aab.py uses).
"""
import argparse
import socket
import sys
from pathlib import Path

socket.setdefaulttimeout(900)          # a 100 MB bundle on a slow link

from google.oauth2 import service_account          # noqa: E402
from googleapiclient.discovery import build          # noqa: E402
from googleapiclient.http import MediaFileUpload     # noqa: E402

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from apps import APPS, play_metadata_dir             # noqa: E402

SCOPE = ["https://www.googleapis.com/auth/androidpublisher"]


def service():
    key = None
    for line in open(Path.home() / "projects/.env"):
        if line.startswith("PLAY_SERVICE_ACCOUNT_KEY="):
            key = line.split("=", 1)[1].strip().strip("'\"")
    if not key:
        raise SystemExit("✗ PLAY_SERVICE_ACCOUNT_KEY 不在 ~/projects/.env")
    creds = service_account.Credentials.from_service_account_file(
        str(Path(key).expanduser()), scopes=SCOPE)
    return build("androidpublisher", "v3", credentials=creds, cache_discovery=False)


def read(p):
    return p.read_text(encoding="utf-8").strip() if p.exists() else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("key")
    ap.add_argument("aab")
    ap.add_argument("code", type=int)
    ap.add_argument("--no-listing", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    pkg = APPS[a.key]["bundle"]
    meta = play_metadata_dir(a.key)
    langs = sorted(p.name for p in meta.iterdir() if p.is_dir())
    notes, listings = [], {}
    for lang in langs:
        d = meta / lang
        t = read(d / "changelogs" / f"{a.code}.txt")
        if t:
            if len(t) > 500:
                raise SystemExit(f"✗ {lang} 更新说明 {len(t)} 字，Play 上限 500")
            notes.append({"language": lang, "text": t})
        title, short, full = read(d / "title.txt"), read(d / "short_description.txt"), read(d / "full_description.txt")
        if title and short and full:
            for name, v, lim in (("title", title, 30), ("short", short, 80), ("full", full, 4000)):
                if len(v) > lim:
                    raise SystemExit(f"✗ {lang} {name} {len(v)} 字，上限 {lim}")
            listings[lang] = {"title": title, "shortDescription": short, "fullDescription": full}
    if not notes:
        raise SystemExit(f"✗ 没有 changelogs/{a.code}.txt")

    svc = service()
    edits = svc.edits()
    eid = edits.insert(packageName=pkg, body={}).execute()["id"]
    print(f"{pkg}: edit {eid}")
    up = edits.bundles().upload(
        packageName=pkg, editId=eid,
        media_body=MediaFileUpload(a.aab, mimetype="application/octet-stream", resumable=True),
    ).execute()
    if int(up["versionCode"]) != a.code:
        edits.delete(packageName=pkg, editId=eid).execute()
        raise SystemExit(f"✗ 包里的 versionCode 是 {up['versionCode']}，不是 {a.code}")
    print(f"  ✓ bundle uploaded, versionCode {up['versionCode']}")
    edits.tracks().update(
        packageName=pkg, editId=eid, track="production",
        body={"track": "production", "releases": [{
            "versionCodes": [str(a.code)], "status": "completed", "releaseNotes": notes}]},
    ).execute()
    print(f"  ✓ production: completed, notes in {len(notes)} languages")
    if not a.no_listing:
        for lang, body in listings.items():
            edits.listings().update(packageName=pkg, editId=eid, language=lang, body=body).execute()
        print(f"  ✓ listings updated: {len(listings)} languages")
    if a.dry_run:
        edits.validate(packageName=pkg, editId=eid).execute()
        edits.delete(packageName=pkg, editId=eid).execute()
        print("  · dry run: validated and discarded")
        return
    edits.commit(packageName=pkg, editId=eid).execute()
    print("  🚀 committed — sent for review")


if __name__ == "__main__":
    main()
