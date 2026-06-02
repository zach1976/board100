#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Push a sport's Google Play store listing (text + en-US graphics) via the
androidpublisher Edits API.

Reads the assets produced by gen_play_metadata.py / gen_play_assets.py under
  fastlane/play/<sport>/metadata/android/<playLocale>/
and pushes, in ONE edit per app:
  - title / shortDescription / fullDescription for all 11 locales
  - en-US images: icon (512²), featureGraphic (1024×500), phoneScreenshots

The Play app must already exist (create it once in Play Console — the API has
no app-creation method). Listing/graphics only; the AAB + release notes
(changelogs) ship separately with a build. Commits with
changesNotSentForReview=true, so changes land in the app's draft and you click
"Send for review" in Console after finishing the manual forms (content rating,
data safety, etc.).

Usage:
  python3 tool/play_push.py tactics_board            # DRY-RUN: validate, no commit
  python3 tool/play_push.py --commit tactics_board   # actually push
  python3 tool/play_push.py --commit tennis rugby    # several apps

Service account: PLAY_SERVICE_ACCOUNT_KEY (env or ~/Desktop/projects/.env),
else the learnthai-play-api.json default (account-level Admin).
Deps: google-auth (already installed).
"""
import json
import os
import sys
import socket
from urllib.request import Request, urlopen
from urllib.error import HTTPError

from google.oauth2 import service_account
import google.auth.transport.requests

socket.setdefaulttimeout(180)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAY = os.path.join(ROOT, "fastlane", "play")
PROJ_ENV = os.path.expanduser("~/Desktop/projects/.env")

API = "https://androidpublisher.googleapis.com/androidpublisher/v3"
UPLOAD = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]

LOCALES = ["en-US", "es-ES", "fr-FR", "id", "ja-JP", "ko-KR",
           "ms", "th", "vi", "zh-CN", "zh-TW"]
LIMITS = {"title": 30, "shortDescription": 80, "fullDescription": 4000}


def load_key():
    p = os.environ.get("PLAY_SERVICE_ACCOUNT_KEY")
    if not p and os.path.exists(PROJ_ENV):
        for line in open(PROJ_ENV):
            s = line.strip()
            if s.startswith("PLAY_SERVICE_ACCOUNT_KEY") and "=" in s:
                p = s.split("=", 1)[1].strip().strip('"').strip("'")
                break
    return p or "/Users/zhenyusong/Desktop/projects/keys/learnthai-play-api.json"


KEY = load_key()


def pkg_for(sport):
    return "com.zach.tacticsBoard" if sport == "tactics_board" else f"com.zach.{sport}Board"


def token():
    creds = service_account.Credentials.from_service_account_file(KEY, scopes=SCOPES)
    creds.refresh(google.auth.transport.requests.Request())
    return creds.token


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read().strip()


def load_listings(sport):
    """Return {playLocale: {title, shortDescription, fullDescription}}."""
    out = {}
    base = os.path.join(PLAY, sport, "metadata", "android")
    for loc in LOCALES:
        d = os.path.join(base, loc)
        if not os.path.isdir(d):
            continue
        out[loc] = {
            "title": read(os.path.join(d, "title.txt")),
            "shortDescription": read(os.path.join(d, "short_description.txt")),
            "fullDescription": read(os.path.join(d, "full_description.txt")),
        }
    return out


def validate(sport, listings):
    ok = True
    for loc, d in listings.items():
        for field, lim in LIMITS.items():
            v = d.get(field, "")
            if not v:
                print(f"  !! {loc}: empty {field}"); ok = False
            if len(v) > lim:
                print(f"  !! {loc}: {field} {len(v)}>{lim}"); ok = False
    return ok


def api(tok, method, path, data=None, base=API):
    req = Request(base + path, method=method)
    req.add_header("Authorization", f"Bearer {tok}")
    if data is not None:
        req.add_header("Content-Type", "application/json")
        req.data = json.dumps(data).encode()
    try:
        with urlopen(req) as r:
            b = r.read().decode()
            return r.status, (json.loads(b) if b else {})
    except HTTPError as e:
        return e.code, e.read().decode()[:600]


def upload_image(tok, pkg, eid, locale, image_type, path):
    url = (f"{UPLOAD}/applications/{pkg}/edits/{eid}"
           f"/listings/{locale}/{image_type}?uploadType=media")
    with open(path, "rb") as f:
        data = f.read()
    req = Request(url, method="POST", data=data)
    req.add_header("Authorization", f"Bearer {tok}")
    req.add_header("Content-Type", "image/png")
    try:
        with urlopen(req) as r:
            return r.status, {}
    except HTTPError as e:
        return e.code, e.read().decode()[:400]


def push_images(tok, pkg, eid, sport):
    """Upload en-US icon, featureGraphic, phoneScreenshots. Returns ok bool."""
    imgdir = os.path.join(PLAY, sport, "metadata", "android", "en-US", "images")
    ok = True
    for itype, fname in [("icon", "icon.png"), ("featureGraphic", "featureGraphic.png")]:
        p = os.path.join(imgdir, fname)
        if not os.path.exists(p):
            continue
        st, r = upload_image(tok, pkg, eid, "en-US", itype, p)
        print(f"    image {itype:14} {'ok' if st == 200 else f'HTTP {st}: {r}'}")
        ok = ok and st == 200
    # phoneScreenshots: clear existing, then upload each in order
    ssdir = os.path.join(imgdir, "phoneScreenshots")
    shots = sorted(f for f in os.listdir(ssdir) if f.endswith(".png")) if os.path.isdir(ssdir) else []
    if shots:
        api(tok, "DELETE", f"/applications/{pkg}/edits/{eid}/listings/en-US/phoneScreenshots")
        for fn in shots:
            st, r = upload_image(tok, pkg, eid, "en-US", "phoneScreenshots",
                                 os.path.join(ssdir, fn))
            print(f"    screenshot {fn:9} {'ok' if st == 200 else f'HTTP {st}: {r}'}")
            ok = ok and st == 200
    return ok


def push(tok, sport, commit):
    pkg = pkg_for(sport)
    listings = load_listings(sport)
    print(f"===== {sport}  →  {pkg}  ({len(listings)} locales) =====")
    if not validate(sport, listings):
        print("  validation FAILED, skipping.\n"); return False

    st, edit = api(tok, "POST", f"/applications/{pkg}/edits", {})
    if st != 200:
        print(f"  edits.insert HTTP {st}: {edit}\n"); return False
    eid = edit["id"]

    failed = False
    for loc, d in listings.items():
        body = {"language": loc, **d}
        st, r = api(tok, "PUT",
                    f"/applications/{pkg}/edits/{eid}/listings/{loc}", body)
        print(f"  listing [{loc:6}] {'ok' if st == 200 else f'HTTP {st}: {r}'}")
        failed = failed or st != 200

    if not failed:
        failed = not push_images(tok, pkg, eid, sport)

    if failed:
        api(tok, "DELETE", f"/applications/{pkg}/edits/{eid}")
        print("  errors → edit discarded.\n"); return False

    st, r = api(tok, "POST", f"/applications/{pkg}/edits/{eid}:validate", {})
    if st != 200:
        api(tok, "DELETE", f"/applications/{pkg}/edits/{eid}")
        print(f"  validate HTTP {st}: {r} → discarded.\n"); return False
    print("  validate: ok")

    if not commit:
        api(tok, "DELETE", f"/applications/{pkg}/edits/{eid}")
        print("  DRY-RUN ok, edit discarded (re-run with --commit).\n"); return True

    # Google now sends listing edits for review automatically; the
    # changesNotSentForReview parameter is rejected (HTTP 400), so don't set it.
    st, r = api(tok, "POST",
                f"/applications/{pkg}/edits/{eid}:commit", {})
    if st != 200:
        print(f"  commit HTTP {st}: {r}\n"); return False
    print(f"  COMMITTED ✓ — listing+graphics pushed (auto-sent for review).\n")
    return True


def main():
    args = sys.argv[1:]
    commit = "--commit" in args
    sports = [a for a in args if not a.startswith("--")]
    if not sports:
        sys.exit("usage: play_push.py [--commit] <sport> [<sport> ...]")
    print(f"key={KEY}")
    print(f"mode={'COMMIT' if commit else 'DRY-RUN (validate only)'}\n")
    tok = token()
    results = {s: push(tok, s, commit) for s in sports}
    bad = [s for s, ok in results.items() if not ok]
    print(f"done. {len(results)-len(bad)}/{len(results)} ok" + (f", failed: {bad}" if bad else ""))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
