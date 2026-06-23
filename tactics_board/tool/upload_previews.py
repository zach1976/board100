#!/usr/bin/env python3 -u
"""Upload App Store preview videos to App Store Connect.

Adapts the screenshot-upload flow (reserve → PUT chunks → PATCH commit) to
the appPreviewSets / appPreviews API. One video per (app, locale).

  aso/previews/<sport>/<locale>/preview.mov  →  app's appPreviewSet (IPHONE_67)

The multi-sport app (tactics_board) uses the soccer video; every single-sport
app uses its own. Env vars:
  ONLY_APP=soccer        limit to one app (test runs)
  ONLY_LOCALE=en-US      limit to one locale
  SKIP_APPS=a,b          skip apps
"""
import hashlib
import os
import time

import jwt
import requests

KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/projects/keys/AuthKey_4A9Y2S3D6X.p8"
PREVIEWS_BASE = "/Users/zhenyusong/projects/board100/tactics_board/aso/previews"
BASE = "https://api.appstoreconnect.apple.com/v1"
PREVIEW_TYPE = "IPHONE_67"  # 6.7"/6.9" display — accepts 1320×2868

# app key → bundle id. The app key is also the video sport, except
# tactics_board (multi-sport) which reuses the soccer video.
APPS = {
    "tactics_board": "com.zach.tacticsBoard",
    "soccer": "com.zach.soccerBoard",
    "basketball": "com.zach.basketballBoard",
    "volleyball": "com.zach.volleyballBoard",
    "badminton": "com.zach.badmintonBoard",
    "tennis": "com.zach.tennisBoard",
    "tableTennis": "com.zach.tableTennisBoard",
    "pickleball": "com.zach.pickleballBoard",
    "baseball": "com.zach.baseballBoard",
    "handball": "com.zach.handballBoard",
    "rugby": "com.zach.rugbyBoard",
    "fieldHockey": "com.zach.fieldHockeyBoard",
    "waterPolo": "com.zach.waterPoloBoard",
    "sepakTakraw": "com.zach.sepakTakrawBoard",
    "beachTennis": "com.zach.beachTennisBoard",
    "footvolley": "com.zach.footvolleyBoard",
}
VIDEO_SPORT = {k: ("soccer" if k == "tactics_board" else k) for k in APPS}
LOCALES = ["en-US", "es-ES", "fr-FR", "id", "ja", "ko", "ms", "th", "vi",
           "zh-Hans", "zh-Hant"]

_token = ""
_token_time = 0


def get_token():
    global _token, _token_time
    now = int(time.time())
    if now - _token_time > 900:
        with open(KEY_FILE) as f:
            key = f.read()
        _token = jwt.encode(
            {"iss": ISSUER_ID, "iat": now, "exp": now + 1200,
             "aud": "appstoreconnect-v1"},
            key, algorithm="ES256", headers={"kid": KEY_ID})
        _token_time = now
    return _token


def _headers():
    return {"Authorization": f"Bearer {get_token()}",
            "Content-Type": "application/json"}


def _req(method, url, **kw):
    """requests wrapper with retry — the ASC API throws sporadic SSL EOFs."""
    for attempt in range(5):
        try:
            if method in ("GET", "DELETE"):
                r = requests.request(method, url, headers=_headers(), timeout=90)
            else:
                r = requests.request(method, url, headers=_headers(),
                                     timeout=90, **kw)
            return r
        except (requests.exceptions.RequestException, OSError) as e:
            if attempt == 4:
                raise
            time.sleep(2 + attempt * 3)
            print(f"    retry {attempt + 1} after {type(e).__name__}")


def api_get(url):
    return _req("GET", url).json()


def api_delete(url):
    return _req("DELETE", url).status_code


def api_post(url, data):
    r = _req("POST", url, json=data)
    if r.status_code >= 400:
        print(f"    POST {r.status_code}: {r.text[:300]}")
        return None
    return r.json()


def api_patch(url, data):
    r = _req("PATCH", url, json=data)
    if r.status_code >= 400:
        print(f"    PATCH {r.status_code}: {r.text[:300]}")
        return None
    return r.json() if r.text else {}


def upload_file(upload_ops, file_data):
    for op in upload_ops:
        chunk = file_data[op["offset"]:op["offset"] + op["length"]]
        hdrs = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        for attempt in range(5):
            try:
                r = requests.put(op["url"], headers=hdrs, data=chunk, timeout=300)
                break
            except (requests.exceptions.RequestException, OSError):
                if attempt == 4:
                    return False
                time.sleep(3 + attempt * 3)
        if r.status_code >= 400:
            print(f"    upload chunk {r.status_code}")
            return False
    return True


def pick_version(app_id):
    """Pick the appStoreVersion to attach previews to — the in-progress
    version if there is one, otherwise the live version."""
    r = api_get(f"{BASE}/apps/{app_id}/appStoreVersions?limit=10")
    versions = r.get("data", [])
    if not versions:
        return None
    for state in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED",
                  "REJECTED", "METADATA_REJECTED", "WAITING_FOR_REVIEW",
                  "IN_REVIEW", "PENDING_DEVELOPER_RELEASE"):
        for v in versions:
            if v["attributes"]["appStoreState"] == state:
                return v["id"]
    return versions[0]["id"]


def upload_one(loc_id, video_path, fname):
    """Find/create the IPHONE_67 appPreviewSet for a localization, clear it,
    and upload one preview video. Returns True on a committed upload."""
    r = api_get(f"{BASE}/appStoreVersionLocalizations/{loc_id}/appPreviewSets")
    set_id = None
    for ps in r.get("data", []):
        if ps["attributes"]["previewType"] == PREVIEW_TYPE:
            set_id = ps["id"]
            break
    if not set_id:
        res = api_post(f"{BASE}/appPreviewSets", {
            "data": {
                "type": "appPreviewSets",
                "attributes": {"previewType": PREVIEW_TYPE},
                "relationships": {"appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations",
                             "id": loc_id}}},
            }})
        if not res:
            return False
        set_id = res["data"]["id"]

    # Clear any existing previews in the set.
    r = api_get(f"{BASE}/appPreviewSets/{set_id}/appPreviews")
    for ex in r.get("data", []):
        api_delete(f"{BASE}/appPreviews/{ex['id']}")

    with open(video_path, "rb") as f:
        data = f.read()
    checksum = hashlib.md5(data).hexdigest()

    res = api_post(f"{BASE}/appPreviews", {
        "data": {
            "type": "appPreviews",
            "attributes": {"fileName": fname, "fileSize": len(data),
                           "mimeType": "video/quicktime"},
            "relationships": {"appPreviewSet": {
                "data": {"type": "appPreviewSets", "id": set_id}}},
        }})
    if not res or "data" not in res:
        return False
    prev_id = res["data"]["id"]
    ops = res["data"]["attributes"].get("uploadOperations", [])
    if not ops or not upload_file(ops, data):
        return False
    out = api_patch(f"{BASE}/appPreviews/{prev_id}", {
        "data": {"type": "appPreviews", "id": prev_id,
                 "attributes": {"uploaded": True,
                                "sourceFileChecksum": checksum}}})
    return out is not None


def main():
    only_app = os.environ.get("ONLY_APP")
    only_loc = os.environ.get("ONLY_LOCALE")
    skip = set(filter(None, os.environ.get("SKIP_APPS", "").split(",")))
    summary = []
    for app_key, bundle in APPS.items():
        if only_app and app_key != only_app:
            continue
        if app_key in skip:
            continue
        print(f"\n━━━ {app_key} ({bundle}) ━━━")
        r = api_get(f"{BASE}/apps?filter[bundleId]={bundle}")
        if not r.get("data"):
            print("  app not found"); summary.append(f"{app_key}: NO APP")
            continue
        app_id = r["data"][0]["id"]
        version_id = pick_version(app_id)
        if not version_id:
            print("  no version"); summary.append(f"{app_key}: NO VERSION")
            continue
        r = api_get(f"{BASE}/appStoreVersions/{version_id}"
                    f"/appStoreVersionLocalizations?limit=40")
        locs = {l["attributes"]["locale"]: l["id"] for l in r.get("data", [])}
        sport = VIDEO_SPORT[app_key]
        ok = 0
        total = 0
        for locale in LOCALES:
            if only_loc and locale != only_loc:
                continue
            if locale not in locs:
                print(f"  {locale}: no localization on this version")
                continue
            video = os.path.join(PREVIEWS_BASE, sport, locale, "preview.mov")
            if not os.path.isfile(video):
                print(f"  {locale}: video missing ({video})")
                continue
            total += 1
            fname = f"{app_key}_{locale}.mov"
            if upload_one(locs[locale], video, fname):
                ok += 1
                print(f"  {locale}: uploaded ✓")
            else:
                print(f"  {locale}: FAILED")
        summary.append(f"{app_key}: {ok}/{total} locales")
    print("\n══ SUMMARY ══")
    for s in summary:
        print(" ", s)


if __name__ == "__main__":
    main()
