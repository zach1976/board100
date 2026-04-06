#!/usr/bin/env python3 -u
"""Upload screenshots to App Store Connect via API."""
import jwt, time, requests, json, os, hashlib, struct

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

LOCALE_MAP = {
    "en-US": "en-US", "zh-Hans": "zh-Hans", "zh-Hant": "zh-Hant",
    "ja": "ja", "ko": "ko", "es-ES": "es-ES", "fr-FR": "fr-FR",
    "vi": "vi", "th": "th", "id": "id", "ms": "ms",
}

_token_time = 0

def get_token():
    global TOKEN, _token_time
    now = int(time.time())
    if now - _token_time > 900:  # refresh every 15 min
        with open(KEY_FILE) as f:
            key = f.read()
        TOKEN = jwt.encode(
            {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
            key, algorithm="ES256", headers={"kid": KEY_ID}
        )
        _token_time = now
    return TOKEN

def auth_headers():
    t = get_token()
    return {"Authorization": f"Bearer {t}", "Content-Type": "application/json"}

def api_get(url):
    r = requests.get(url, headers=auth_headers())
    return r.json()

def api_delete(url):
    r = requests.delete(url, headers=auth_headers())
    return r.status_code

def api_post(url, data):
    r = requests.post(url, headers=auth_headers(), json=data)
    if r.status_code >= 400:
        print(f"    POST error {r.status_code}: {r.text[:200]}")
        return None
    return r.json()

def api_patch(url, data):
    r = requests.patch(url, headers=auth_headers(), json=data)
    if r.status_code >= 400:
        print(f"    PATCH error {r.status_code}: {r.text[:200]}")
    return r.json() if r.text else {}

def upload_screenshot_file(upload_ops, file_path):
    """Upload file using the upload operations from the reservation."""
    with open(file_path, "rb") as f:
        file_data = f.read()

    for op in upload_ops:
        offset = op["offset"]
        length = op["length"]
        url = op["url"]
        method = op["method"]
        req_headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}

        chunk = file_data[offset:offset + length]
        r = requests.put(url, headers=req_headers, data=chunk)
        if r.status_code >= 400:
            print(f"    Upload chunk error {r.status_code}")
            return False
    return True

TOKEN = ""
get_token()  # initialize
BASE = "https://api.appstoreconnect.apple.com/v1"

# Skip already uploaded apps
SKIP = set(os.environ.get("SKIP_APPS", "").split(",")) if os.environ.get("SKIP_APPS") else set()

for app_key, bundle_id in APPS.items():
    if app_key in SKIP:
        print(f"\n━━━ {app_key} (SKIPPED) ━━━")
        continue
    print(f"\n━━━ {app_key} ━━━")

    # Get app ID
    r = api_get(f"{BASE}/apps?filter[bundleId]={bundle_id}")
    app_id = r["data"][0]["id"]

    # Get PREPARE_FOR_SUBMISSION version
    r = api_get(f"{BASE}/apps/{app_id}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION")
    if not r.get("data"):
        # Try READY_FOR_SALE
        r = api_get(f"{BASE}/apps/{app_id}/appStoreVersions?filter[appStoreState]=READY_FOR_SALE")
    if not r.get("data"):
        print("  No version found!")
        continue
    version_id = r["data"][0]["id"]

    # Get all localizations
    r = api_get(f"{BASE}/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=28")
    locs = {loc["attributes"]["locale"]: loc["id"] for loc in r.get("data", [])}

    for locale, loc_id in locs.items():
        screenshot_dir = os.path.join(SCREENSHOTS_BASE, app_key, locale)
        if not os.path.isdir(screenshot_dir):
            continue

        # Get PNG files sorted by name
        pngs = sorted([f for f in os.listdir(screenshot_dir) if f.endswith(".png") and not f.startswith("ipad")])
        if not pngs:
            continue

        # Get existing screenshot sets for this locale
        r = api_get(f"{BASE}/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")
        iphone_set_id = None
        for ss in r.get("data", []):
            if ss["attributes"]["screenshotDisplayType"] == "APP_IPHONE_67":
                iphone_set_id = ss["id"]
                break

        # Create screenshot set if not exists
        if not iphone_set_id:
            result = api_post(f"{BASE}/appScreenshotSets", {
                "data": {
                    "type": "appScreenshotSets",
                    "attributes": {"screenshotDisplayType": "APP_IPHONE_67"},
                    "relationships": {
                        "appStoreVersionLocalization": {
                            "data": {"type": "appStoreVersionLocalizations", "id": loc_id}
                        }
                    }
                }
            })
            if result:
                iphone_set_id = result["data"]["id"]
            else:
                continue

        # Delete existing screenshots
        r = api_get(f"{BASE}/appScreenshotSets/{iphone_set_id}/appScreenshots")
        for existing in r.get("data", []):
            api_delete(f"{BASE}/appScreenshots/{existing['id']}")

        # Upload new screenshots
        uploaded = 0
        for png in pngs:
            file_path = os.path.join(screenshot_dir, png)
            file_size = os.path.getsize(file_path)

            with open(file_path, "rb") as f:
                file_data = f.read()
            checksum = hashlib.md5(file_data).hexdigest()

            # Reserve screenshot (no checksum in POST)
            result = api_post(f"{BASE}/appScreenshots", {
                "data": {
                    "type": "appScreenshots",
                    "attributes": {
                        "fileName": png,
                        "fileSize": file_size,
                    },
                    "relationships": {
                        "appScreenshotSet": {
                            "data": {"type": "appScreenshotSets", "id": iphone_set_id}
                        }
                    }
                }
            })

            if not result or "data" not in result:
                continue

            screenshot_id = result["data"]["id"]
            upload_ops = result["data"]["attributes"].get("uploadOperations", [])

            if upload_ops:
                success = upload_screenshot_file(upload_ops, file_path)
                if success:
                    # Commit
                    api_patch(f"{BASE}/appScreenshots/{screenshot_id}", {
                        "data": {
                            "type": "appScreenshots",
                            "id": screenshot_id,
                            "attributes": {
                                "sourceFileChecksum": checksum,
                                "uploaded": True,
                            }
                        }
                    })
                    uploaded += 1

        print(f"  {locale}: {uploaded}/{len(pngs)} screenshots uploaded")

print("\n🎉 Done!")
