#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ship v1.1.24 AABs to Google Play production for the apps that exist on Play.

Only 6 of the 16 apps are published on Play (the rest 404). Per app:
  1. edits.insert
  2. bundles.upload  (build/aab_play/<sport>-1.1.24.aab) -> versionCode
  3. tracks.update production: release {versionCodes:[code], status:'completed',
     releaseNotes: localized 1.1.24 notes}
  4. edits.validate -> edits.commit  (auto-sent for review; managed publishing
     off -> auto-publishes on approval)

Release notes are reused from fastlane/metadata/<sport>/<locale>/release_notes.txt
(the App Store notes), mapped App-Store-locale -> Play-locale.

Usage:
  python3 tool/play_release_1_1_24.py                 # DRY-RUN all Play apps
  python3 tool/play_release_1_1_24.py --commit        # actually release
  python3 tool/play_release_1_1_24.py --commit soccer # subset
"""
import os, sys, json
from google.oauth2 import service_account
import google.auth.transport.requests
from urllib.request import Request, urlopen
from urllib.error import HTTPError

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ_ENV = os.path.expanduser("~/projects/.env")
META = os.path.join(ROOT, "fastlane", "metadata")
AAB_DIR = os.path.join(ROOT, "build", "aab_play")
VERSION = "1.1.24"
API = "https://androidpublisher.googleapis.com/androidpublisher/v3"
UPLOAD = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]

# Apps actually present on Play (others 404). Water Polo is NOT on Play.
PLAY_SPORTS = ["tactics_board", "soccer", "basketball", "volleyball",
               "badminton", "fieldHockey"]

# Play release-notes language  ->  our fastlane/metadata locale dir.
PLAY_TO_META = {
    "en-US": "en-US", "es-ES": "es-ES", "fr-FR": "fr-FR", "id": "id",
    "ja-JP": "ja", "ko-KR": "ko", "ms": "ms", "th": "th", "vi": "vi",
    "zh-CN": "zh-Hans", "zh-TW": "zh-Hant",
}
PLAY_NOTES_LIMIT = 500


def load_key():
    p = os.environ.get("PLAY_SERVICE_ACCOUNT_KEY")
    if not p and os.path.exists(PROJ_ENV):
        for line in open(PROJ_ENV):
            s = line.strip()
            if s.startswith("PLAY_SERVICE_ACCOUNT_KEY") and "=" in s:
                p = s.split("=", 1)[1].strip().strip('"').strip("'"); break
    return p or "/Users/zhenyusong/projects/keys/learnthai-play-api.json"


def token():
    creds = service_account.Credentials.from_service_account_file(load_key(), scopes=SCOPES)
    creds.refresh(google.auth.transport.requests.Request())
    return creds.token


def pkg_for(sport):
    return "com.zach.tacticsBoard" if sport == "tactics_board" else f"com.zach.{sport}Board"


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
        return e.code, e.read().decode()[:800]


def upload_aab(tok, pkg, eid, path):
    with open(path, "rb") as f:
        data = f.read()
    url = f"{UPLOAD}/applications/{pkg}/edits/{eid}/bundles?uploadType=media"
    req = Request(url, method="POST", data=data)
    req.add_header("Authorization", f"Bearer {tok}")
    req.add_header("Content-Type", "application/octet-stream")
    try:
        with urlopen(req) as r:
            return r.status, json.loads(r.read().decode() or "{}")
    except HTTPError as e:
        return e.code, e.read().decode()[:800]


def release_notes(sport):
    out = []
    for play_loc, meta_loc in PLAY_TO_META.items():
        p = os.path.join(META, sport, meta_loc, "release_notes.txt")
        if not os.path.exists(p):
            p = os.path.join(META, sport, "en-US", "release_notes.txt")
        if not os.path.exists(p):
            continue
        text = open(p, encoding="utf-8").read().strip()[:PLAY_NOTES_LIMIT]
        out.append({"language": play_loc, "text": text})
    return out


def process(tok, sport, commit):
    pkg = pkg_for(sport)
    aab = os.path.join(AAB_DIR, f"{sport}-{VERSION}.aab")
    print(f"\n===== {sport}  →  {pkg} =====")
    if not os.path.exists(aab):
        print(f"  ❌ AAB missing: {aab}"); return False

    st, edit = api(tok, "POST", f"/applications/{pkg}/edits", {})
    if st != 200:
        print(f"  ❌ edits.insert {st}: {edit}"); return False
    eid = edit["id"]

    st, r = upload_aab(tok, pkg, eid, aab)
    if st != 200:
        api(tok, "DELETE", f"/applications/{pkg}/edits/{eid}")
        print(f"  ❌ bundles.upload {st}: {r}"); return False
    code = r.get("versionCode")
    print(f"  uploaded AAB → versionCode {code}")

    body = {"track": "production", "releases": [{
        "versionCodes": [str(code)], "status": "completed",
        "releaseNotes": release_notes(sport),
    }]}
    st, r = api(tok, "PUT",
                f"/applications/{pkg}/edits/{eid}/tracks/production", body)
    if st != 200:
        api(tok, "DELETE", f"/applications/{pkg}/edits/{eid}")
        print(f"  ❌ tracks.update {st}: {r}"); return False
    print("  production track set (100% rollout)")

    st, r = api(tok, "POST", f"/applications/{pkg}/edits/{eid}:validate", {})
    if st != 200:
        api(tok, "DELETE", f"/applications/{pkg}/edits/{eid}")
        print(f"  ❌ validate {st}: {r}"); return False
    print("  validate: ok")

    if not commit:
        api(tok, "DELETE", f"/applications/{pkg}/edits/{eid}")
        print("  DRY-RUN ok, edit discarded (re-run with --commit)."); return True

    st, r = api(tok, "POST", f"/applications/{pkg}/edits/{eid}:commit", {})
    if st != 200:
        print(f"  ❌ commit {st}: {r}"); return False
    print(f"  ✅ COMMITTED — {VERSION} (code {code}) sent for review")
    return True


def main():
    args = sys.argv[1:]
    commit = "--commit" in args
    sports = [a for a in args if not a.startswith("--")] or PLAY_SPORTS
    tok = token()
    ok = 0
    for s in sports:
        try:
            if process(tok, s, commit):
                ok += 1
        except Exception as e:
            print(f"  ❌ exception: {e}")
    print(f"\n==== {'committed' if commit else 'dry-ran'} {ok}/{len(sports)} apps ====")


if __name__ == "__main__":
    main()
