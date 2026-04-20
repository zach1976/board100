#!/usr/bin/env python3 -u
"""Upload screenshots (if needed) and resubmit all DEVELOPER_REJECTED apps."""
import jwt, time, requests, os, hashlib
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8"
SCREENSHOTS_BASE = "/Users/zhenyusong/Desktop/projects/board100/tactics_board/fastlane/screenshots"

APPS = {
    "tactics_board": "com.zach.tacticsBoard",
    "soccer": "com.zach.soccerBoard",
    "basketball": "com.zach.basketballBoard",
    "volleyball": "com.zach.volleyballBoard",
    "badminton": "com.zach.badmintonBoard",
    "tennis": "com.zach.tennisBoard",
    "tableTennis": "com.zach.tableTennisBoard",
    "pickleball": "com.zach.pickleballBoard",
}

BASE = "https://api.appstoreconnect.apple.com/v1"
_token_time = 0
TOKEN = ""

session = requests.Session()
retries = Retry(total=5, backoff_factor=3, status_forcelist=[500, 502, 503, 504])
session.mount("https://", HTTPAdapter(max_retries=retries))


def get_token():
    global TOKEN, _token_time
    now = int(time.time())
    if now - _token_time > 900:
        with open(KEY_FILE) as f:
            key = f.read()
        TOKEN = jwt.encode(
            {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
            key, algorithm="ES256", headers={"kid": KEY_ID}
        )
        _token_time = now
    return TOKEN


def auth_headers():
    return {"Authorization": f"Bearer {get_token()}", "Content-Type": "application/json"}


def api_get(url):
    for attempt in range(4):
        try:
            r = session.get(url, headers=auth_headers(), timeout=30)
            return r.json()
        except Exception as e:
            print(f"    GET error (attempt {attempt+1}): {e}")
            time.sleep(2 ** attempt)
    return {}


def api_post(url, data):
    for attempt in range(4):
        try:
            r = session.post(url, headers=auth_headers(), json=data, timeout=30)
            if r.status_code >= 400:
                print(f"    POST {r.status_code}: {r.text[:300]}")
                return None
            return r.json() if r.text else {}
        except Exception as e:
            print(f"    POST error (attempt {attempt+1}): {e}")
            time.sleep(2 ** attempt)
    return None


def api_delete(url):
    for attempt in range(4):
        try:
            r = session.delete(url, headers=auth_headers(), timeout=30)
            return r.status_code
        except Exception as e:
            print(f"    DELETE error (attempt {attempt+1}): {e}")
            time.sleep(2 ** attempt)
    return 0


def api_patch(url, data):
    for attempt in range(4):
        try:
            r = session.patch(url, headers=auth_headers(), json=data, timeout=30)
            if r.status_code >= 400:
                print(f"    PATCH {r.status_code}: {r.text[:200]}")
            return r.json() if r.text else {}
        except Exception as e:
            print(f"    PATCH error (attempt {attempt+1}): {e}")
            time.sleep(2 ** attempt)
    return {}


def upload_file(upload_ops, file_path):
    with open(file_path, "rb") as f:
        file_data = f.read()
    for op in upload_ops:
        chunk = file_data[op["offset"]: op["offset"] + op["length"]]
        req_headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        for attempt in range(5):
            try:
                r = session.put(op["url"], headers=req_headers, data=chunk, timeout=90)
                if r.status_code < 400:
                    break
                print(f"    Chunk {r.status_code}, retry {attempt+1}")
                time.sleep(2 ** attempt)
            except Exception as e:
                print(f"    Chunk error: {e}, retry {attempt+1}")
                time.sleep(2 ** attempt)
        else:
            return False
    return True


def upload_screenshots_for_version(app_key, version_id):
    r = api_get(f"{BASE}/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=28")
    locs = {loc["attributes"]["locale"]: loc["id"] for loc in r.get("data", [])}

    total_uploaded = 0
    for locale, loc_id in locs.items():
        screenshot_dir = os.path.join(SCREENSHOTS_BASE, app_key, locale)
        if not os.path.isdir(screenshot_dir):
            continue
        pngs = sorted([f for f in os.listdir(screenshot_dir) if f.endswith(".png") and not f.startswith("ipad")])
        if not pngs:
            continue

        r = api_get(f"{BASE}/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")
        iphone_set_id = None
        for ss in r.get("data", []):
            if ss["attributes"]["screenshotDisplayType"] == "APP_IPHONE_67":
                iphone_set_id = ss["id"]
                break

        if not iphone_set_id:
            result = api_post(f"{BASE}/appScreenshotSets", {"data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": "APP_IPHONE_67"},
                "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}
            }})
            if result:
                iphone_set_id = result["data"]["id"]
            else:
                continue

        # Delete existing screenshots
        r = api_get(f"{BASE}/appScreenshotSets/{iphone_set_id}/appScreenshots")
        for existing in r.get("data", []):
            api_delete(f"{BASE}/appScreenshots/{existing['id']}")

        uploaded = 0
        for png in pngs:
            file_path = os.path.join(screenshot_dir, png)
            file_size = os.path.getsize(file_path)
            with open(file_path, "rb") as f:
                checksum = hashlib.md5(f.read()).hexdigest()

            result = api_post(f"{BASE}/appScreenshots", {"data": {
                "type": "appScreenshots",
                "attributes": {"fileName": png, "fileSize": file_size},
                "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": iphone_set_id}}}
            }})
            if not result or "data" not in result:
                continue

            screenshot_id = result["data"]["id"]
            upload_ops = result["data"]["attributes"].get("uploadOperations", [])
            if upload_ops and upload_file(upload_ops, file_path):
                api_patch(f"{BASE}/appScreenshots/{screenshot_id}", {"data": {
                    "type": "appScreenshots", "id": screenshot_id,
                    "attributes": {"sourceFileChecksum": checksum, "uploaded": True}
                }})
                uploaded += 1

        print(f"    {locale}: {uploaded}/{len(pngs)}")
        total_uploaded += uploaded
    return total_uploaded


get_token()

for app_key, bundle_id in APPS.items():
    print(f"\n{'━'*40}")
    print(f"  {app_key}")
    print(f"{'━'*40}")

    r = api_get(f"{BASE}/apps?filter[bundleId]={bundle_id}")
    app_id = r["data"][0]["id"]

    # Find current version
    r = api_get(f"{BASE}/apps/{app_id}/appStoreVersions?limit=3")
    versions = r.get("data", [])
    target = None
    for v in versions:
        state = v["attributes"]["appStoreState"]
        if state == "DEVELOPER_REJECTED":
            target = v
            break

    if not target:
        state = versions[0]["attributes"]["appStoreState"] if versions else "unknown"
        print(f"  Not in DEVELOPER_REJECTED (state: {state}), skipping")
        continue

    version_id = target["id"]
    ver_str = target["attributes"]["versionString"]
    print(f"  Version {ver_str} — DEVELOPER_REJECTED")

    # Upload screenshots
    print("  Uploading screenshots...")
    total = upload_screenshots_for_version(app_key, version_id)
    print(f"  Total uploaded: {total}")

    # Resubmit
    print("  Resubmitting...")
    result = api_post(f"{BASE}/appStoreVersionSubmissions", {"data": {
        "type": "appStoreVersionSubmissions",
        "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}
    }})
    if result is not None:
        print(f"  ✅ Resubmitted successfully")
    else:
        print(f"  ❌ Resubmit failed — check App Store Connect manually")

print("\n🎉 Done!")
