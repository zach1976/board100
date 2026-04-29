#!/usr/bin/env python3 -u
"""Wire up screenshots on a metadata-bumped version after a fresh IPA upload.

Pipeline order (do these BEFORE running this script):
  1. Bump version in pubspec.yaml (e.g. 1.1.6+4 -> 1.1.7+1)
  2. tool/build_all_ipa.sh  (or just build the affected IPAs)
  3. tool/upload_all_ipa.sh (or upload the affected IPAs)
  4. Wait ~5-15 min for App Store Connect to finish processing the build

Then this script:
  - Finds or creates an App Store version with NEXT_VERSION (default = bump patch
    from the latest version)
  - Locates the build whose preReleaseVersion matches NEXT_VERSION and attaches it
  - Wipes existing screenshot sets + uploads fresh PNGs from fastlane/screenshots/
  - Writes whatsNew to every localization
  - Sets usesNonExemptEncryption=false on the build
  - Does NOT submit for review (run tool/submit_all.py separately when ready)

Env vars:
  SPORTS=pickleball,soccer       # comma-separated app_keys; default: pickleball
  NEXT_VERSION=1.1.7             # target version; default: bump patch from latest

Usage:
  python3 tool/update_live_screenshots.py
  SPORTS=pickleball NEXT_VERSION=1.1.7 python3 tool/update_live_screenshots.py
"""
import jwt, time, requests, warnings, os, hashlib
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8"
SCREENSHOTS_BASE = "/Users/zhenyusong/Desktop/projects/board100/tactics_board/fastlane/screenshots"
META_BASE = "/Users/zhenyusong/Desktop/projects/board100/tactics_board/fastlane/metadata"
B = "https://api.appstoreconnect.apple.com"

APPS = {
    "tactics_board": "com.zach.tacticsBoard",
    "soccer":        "com.zach.soccerBoard",
    "basketball":    "com.zach.basketballBoard",
    "volleyball":    "com.zach.volleyballBoard",
    "badminton":     "com.zach.badmintonBoard",
    "tennis":        "com.zach.tennisBoard",
    "tableTennis":   "com.zach.tableTennisBoard",
    "pickleball":    "com.zach.pickleballBoard",
    "fieldHockey":   "com.zach.fieldHockeyBoard",
    "rugby":         "com.zach.rugbyBoard",
    "baseball":      "com.zach.baseballBoard",
    "handball":      "com.zach.handballBoard",
    "waterPolo":     "com.zach.waterPoloBoard",
    "sepakTakraw":   "com.zach.sepakTakrawBoard",
    "beachTennis":   "com.zach.beachTennisBoard",
    "footvolley":    "com.zach.footvolleyBoard",
}

with open(KEY_FILE) as f:
    pk = f.read()

_t = [0, ""]
def tok():
    now = int(time.time())
    if now - _t[0] > 900:
        _t[0] = now
        _t[1] = jwt.encode(
            {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
            pk, algorithm="ES256", headers={"kid": KEY_ID})
    return _t[1]

def H(json_body=True):
    h = {"Authorization": f"Bearer {tok()}"}
    if json_body:
        h["Content-Type"] = "application/json"
    return h

def _retry(fn):
    last = None
    for i in range(5):
        try:
            return fn()
        except Exception as e:
            last = e
            time.sleep(2 + i * 3)
    raise last

def G(url):
    r = _retry(lambda: requests.get(url, headers=H(), verify=False, timeout=60))
    return r.json() if r.text else {}

def P(method, url, data=None):
    r = _retry(lambda: requests.request(method, url, headers=H(), json=data, verify=False, timeout=60))
    if r.status_code >= 400:
        return {"_err": r.status_code, "_body": r.text[:400]}
    return r.json() if r.text else {"_ok": True}

def D(url):
    return _retry(lambda: requests.delete(url, headers=H(), verify=False, timeout=60))

def bump_patch(v):
    parts = v.split(".")
    parts[-1] = str(int(parts[-1]) + 1)
    return ".".join(parts)

def read_notes(app_key, locale):
    for loc in (locale, "en-US"):
        p = os.path.join(META_BASE, app_key, loc, "release_notes.txt")
        if os.path.exists(p):
            return open(p).read().strip()
    return "Bug fixes and improvements."

def upload_chunks(ops, file_path):
    with open(file_path, "rb") as f:
        data = f.read()
    for op in ops:
        chunk = data[op["offset"]:op["offset"] + op["length"]]
        hdrs = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        r = _retry(lambda: requests.put(op["url"], headers=hdrs, data=chunk, verify=False, timeout=120))
        if r.status_code >= 400:
            return False
    return True

def find_build_for_version(app_id, ver):
    """Return build_id for the build whose preReleaseVersion.version == ver, newest first."""
    r = G(f"{B}/v1/builds?filter[app]={app_id}&filter[preReleaseVersion.version]={ver}&limit=10")
    builds = r.get("data", [])
    # Prefer VALID, non-expired
    for b in builds:
        a = b["attributes"]
        if a.get("processingState") == "VALID" and not a.get("expired"):
            return b["id"], a.get("version")
    return None, None

def ensure_editable_version(app_id, app_key):
    """Return version_id of a PREPARE_FOR_SUBMISSION version with a matching build attached."""
    # Find what target version we want
    r_latest = G(f"{B}/v1/apps/{app_id}/appStoreVersions?limit=1")
    if not r_latest.get("data"):
        print("    ❌ no existing versions on this app")
        return None
    latest_ver = r_latest["data"][0]["attributes"]["versionString"]
    latest_state = r_latest["data"][0]["attributes"]["appStoreState"]

    # If the latest version is already editable (PREPARE_FOR_SUBMISSION / DEVELOPER_REJECTED / METADATA_REJECTED / REJECTED),
    # reuse it — that's the version we should be working on.
    EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "METADATA_REJECTED", "REJECTED"}
    if latest_state in EDITABLE:
        vid = r_latest["data"][0]["id"]
        next_ver = latest_ver
        created_new = False
        print(f"    reusing existing {latest_state}: {latest_ver}")
    else:
        next_ver = os.environ.get("NEXT_VERSION") or bump_patch(latest_ver)
        print(f"    creating new version {next_ver} (current live = {latest_ver})")
        body = {
            "data": {
                "type": "appStoreVersions",
                "attributes": {"platform": "IOS", "versionString": next_ver},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            }
        }
        r = P("POST", f"{B}/v1/appStoreVersions", body)
        if "_err" in r:
            print(f"    ❌ create version: {r['_err']} {r['_body'][:200]}")
            return None
        vid = r["data"]["id"]
        created_new = True

    # Check if a build is already attached
    cur = G(f"{B}/v1/appStoreVersions/{vid}/build")
    if cur.get("data"):
        build_id = cur["data"]["id"]
        print(f"    build already attached: {build_id[:8]}")
    else:
        build_id, b_num = find_build_for_version(app_id, next_ver)
        if not build_id:
            print(f"    ❌ no VALID build found with preReleaseVersion={next_ver} — upload an IPA first")
            return None
        print(f"    attaching build {build_id[:8]} (build #{b_num})")
        rb = P("PATCH", f"{B}/v1/appStoreVersions/{vid}/relationships/build", {
            "data": {"type": "builds", "id": build_id}
        })
        if "_err" in rb:
            print(f"    ❌ attach build: {rb['_err']} {rb['_body'][:300]}")
            return None

    # Set encryption flag on the build (idempotent)
    P("PATCH", f"{B}/v1/builds/{build_id}", {
        "data": {"type": "builds", "id": build_id,
                 "attributes": {"usesNonExemptEncryption": False}}
    })

    # Set whatsNew on every localization
    locs = G(f"{B}/v1/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=40")
    for loc in locs.get("data", []):
        loc_id = loc["id"]
        locale = loc["attributes"]["locale"]
        notes = read_notes(app_key, locale)
        P("PATCH", f"{B}/v1/appStoreVersionLocalizations/{loc_id}", {
            "data": {"type": "appStoreVersionLocalizations", "id": loc_id,
                     "attributes": {"whatsNew": notes}}
        })
    return vid

def upload_screenshots_for_version(version_id, app_key):
    locs = G(f"{B}/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=40")
    by_locale = {l["attributes"]["locale"]: l["id"] for l in locs.get("data", [])}

    total_ok = total_attempt = 0
    for locale, loc_id in by_locale.items():
        ss_dir = os.path.join(SCREENSHOTS_BASE, app_key, locale)
        if not os.path.isdir(ss_dir):
            continue
        pngs = sorted(f for f in os.listdir(ss_dir)
                      if f.endswith(".png") and not f.startswith("ipad"))
        if not pngs:
            continue

        # Find or create the iPhone 6.7 screenshot set
        sets = G(f"{B}/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")
        set_id = None
        for ss in sets.get("data", []):
            if ss["attributes"]["screenshotDisplayType"] == "APP_IPHONE_67":
                set_id = ss["id"]
                break
        if not set_id:
            r = P("POST", f"{B}/v1/appScreenshotSets", {
                "data": {"type": "appScreenshotSets",
                         "attributes": {"screenshotDisplayType": "APP_IPHONE_67"},
                         "relationships": {"appStoreVersionLocalization": {
                             "data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}}
            })
            if "_err" in r:
                print(f"      [{locale}] ❌ create set: {r['_err']}")
                continue
            set_id = r["data"]["id"]

        # Wipe existing screenshots in that set
        existing = G(f"{B}/v1/appScreenshotSets/{set_id}/appScreenshots")
        for s in existing.get("data", []):
            try:
                D(f"{B}/v1/appScreenshots/{s['id']}")
            except Exception as e:
                print(f"      [{locale}] ⚠ delete old screenshot failed: {e}")

        ok = 0
        for png in pngs:
            p = os.path.join(ss_dir, png)
            size = os.path.getsize(p)
            with open(p, "rb") as f:
                checksum = hashlib.md5(f.read()).hexdigest()
            r = P("POST", f"{B}/v1/appScreenshots", {
                "data": {"type": "appScreenshots",
                         "attributes": {"fileName": png, "fileSize": size},
                         "relationships": {"appScreenshotSet": {
                             "data": {"type": "appScreenshotSets", "id": set_id}}}}
            })
            if "_err" in r:
                continue
            sid = r["data"]["id"]
            ops = r["data"]["attributes"].get("uploadOperations", [])
            if ops and upload_chunks(ops, p):
                P("PATCH", f"{B}/v1/appScreenshots/{sid}", {
                    "data": {"type": "appScreenshots", "id": sid,
                             "attributes": {"sourceFileChecksum": checksum, "uploaded": True}}
                })
                ok += 1
        total_ok += ok
        total_attempt += len(pngs)
        print(f"      [{locale}] {ok}/{len(pngs)}")
    return total_ok, total_attempt

def main():
    sports = os.environ.get("SPORTS", "pickleball").split(",")
    print(f"Targets: {sports}\n")
    for sport in sports:
        sport = sport.strip()
        if sport not in APPS:
            print(f"❌ unknown sport: {sport}")
            continue
        bid = APPS[sport]
        print(f"━━━ {sport} ({bid}) ━━━")
        r = G(f"{B}/v1/apps?filter[bundleId]={bid}")
        if not r.get("data"):
            print("    ❌ app not found")
            continue
        app_id = r["data"][0]["id"]
        vid = ensure_editable_version(app_id, sport)
        if not vid:
            continue
        ok, total = upload_screenshots_for_version(vid, sport)
        print(f"    ✅ uploaded {ok}/{total} screenshots\n")
    print("Done. Submit for review via tool/submit_all.py or App Store Connect.")

if __name__ == "__main__":
    main()
