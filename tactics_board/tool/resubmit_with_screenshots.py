#!/usr/bin/env python3 -u
"""Withdraw from review, upload screenshots, then resubmit for all apps."""
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

# Session with retry for SSL issues
session = requests.Session()
retries = Retry(total=5, backoff_factor=2, status_forcelist=[500, 502, 503, 504])
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
    r = session.get(url, headers=auth_headers(), timeout=30)
    return r.json()


def api_post(url, data):
    r = session.post(url, headers=auth_headers(), json=data, timeout=30)
    if r.status_code >= 400:
        print(f"    POST {r.status_code}: {r.text[:300]}")
        return None
    return r.json() if r.text else {}


def api_delete(url):
    r = session.delete(url, headers=auth_headers(), timeout=30)
    return r.status_code


def api_patch(url, data):
    r = session.patch(url, headers=auth_headers(), json=data, timeout=30)
    if r.status_code >= 400:
        print(f"    PATCH {r.status_code}: {r.text[:300]}")
    return r.json() if r.text else {}


def upload_file(upload_ops, file_path):
    with open(file_path, "rb") as f:
        file_data = f.read()
    for op in upload_ops:
        chunk = file_data[op["offset"]: op["offset"] + op["length"]]
        req_headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        for attempt in range(4):
            try:
                r = session.put(op["url"], headers=req_headers, data=chunk, timeout=60)
                if r.status_code < 400:
                    break
                print(f"    Upload chunk {r.status_code}, retry {attempt+1}")
            except Exception as e:
                print(f"    Upload error: {e}, retry {attempt+1}")
                time.sleep(2 ** attempt)
        else:
            return False
    return True


def wait_for_state(app_id, version_id, target_state, max_wait=60):
    for _ in range(max_wait // 5):
        r = api_get(f"{BASE}/appStoreVersions/{version_id}")
        state = r["data"]["attributes"]["appStoreState"]
        if state == target_state:
            return True
        print(f"    State: {state}, waiting...")
        time.sleep(5)
    return False


def upload_screenshots_for_version(app_key, version_id):
    r = api_get(f"{BASE}/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=28")
    locs = {loc["attributes"]["locale"]: loc["id"] for loc in r.get("data", [])}

    for locale, loc_id in locs.items():
        screenshot_dir = os.path.join(SCREENSHOTS_BASE, app_key, locale)
        if not os.path.isdir(screenshot_dir):
            continue
        pngs = sorted([f for f in os.listdir(screenshot_dir) if f.endswith(".png") and not f.startswith("ipad")])
        if not pngs:
            continue

        # Get or create screenshot set
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

        # Delete existing
        r = api_get(f"{BASE}/appScreenshotSets/{iphone_set_id}/appScreenshots")
        for existing in r.get("data", []):
            api_delete(f"{BASE}/appScreenshots/{existing['id']}")

        # Upload new
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

        print(f"    {locale}: {uploaded}/{len(pngs)} uploaded")


get_token()

for app_key, bundle_id in APPS.items():
    print(f"\n{'━'*40}")
    print(f"  {app_key}")
    print(f"{'━'*40}")

    r = api_get(f"{BASE}/apps?filter[bundleId]={bundle_id}")
    app_id = r["data"][0]["id"]

    # Find WAITING_FOR_REVIEW version
    r = api_get(f"{BASE}/apps/{app_id}/appStoreVersions?filter[appStoreState]=WAITING_FOR_REVIEW")
    if not r.get("data"):
        print("  No WAITING_FOR_REVIEW version, skipping")
        continue
    version = r["data"][0]
    version_id = version["id"]
    ver_str = version["attributes"]["versionString"]
    print(f"  Version {ver_str} — withdrawing from review...")

    # Get submission ID and cancel
    r = api_get(f"{BASE}/appStoreVersions/{version_id}/appStoreVersionSubmission")
    if r.get("data"):
        sub_id = r["data"]["id"]
        status = api_delete(f"{BASE}/appStoreVersionSubmissions/{sub_id}")
        print(f"  Withdrawn (HTTP {status})")
    else:
        print("  No active submission found, proceeding anyway")

    # Wait for PREPARE_FOR_SUBMISSION
    print("  Waiting for PREPARE_FOR_SUBMISSION state...")
    if not wait_for_state(app_id, version_id, "PREPARE_FOR_SUBMISSION", max_wait=90):
        print("  ⚠️  Timed out waiting for state change, attempting upload anyway")

    # Upload screenshots
    print("  Uploading screenshots...")
    upload_screenshots_for_version(app_key, version_id)

    # Resubmit
    print("  Resubmitting for review...")
    result = api_post(f"{BASE}/appStoreVersionSubmissions", {"data": {
        "type": "appStoreVersionSubmissions",
        "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}
    }})
    if result is not None:
        print(f"  ✅ Resubmitted")
    else:
        print(f"  ❌ Resubmit failed")

print("\n🎉 Done!")
