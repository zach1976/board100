#!/usr/bin/env python3 -u
"""Upload screenshots for the 8 new sport apps.

Strategy:
- iPhone (APP_IPHONE_67): same en-US screenshot uploaded to ALL 11 locales.
- iPad (APP_IPAD_PRO_3GEN_129): uploaded to en-US ONLY (mirrors badminton config).
"""
import jwt, time, requests, os, hashlib, warnings
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8"
SCREENSHOTS_BASE = "/Users/zhenyusong/Desktop/projects/board100/tactics_board/fastlane/screenshots"

NEW_APPS = [
    ("fieldHockey", "com.zach.fieldHockeyBoard"),
    ("rugby",       "com.zach.rugbyBoard"),
    ("baseball",    "com.zach.baseballBoard"),
    ("handball",    "com.zach.handballBoard"),
    ("waterPolo",   "com.zach.waterPoloBoard"),
    ("sepakTakraw", "com.zach.sepakTakrawBoard"),
    ("beachTennis", "com.zach.beachTennisBoard"),
    ("footvolley",  "com.zach.footvolleyBoard"),
]

LOCALES = ["en-US", "zh-Hans", "zh-Hant", "ja", "ko", "es-ES", "fr-FR", "vi", "th", "id", "ms"]

with open(KEY_FILE) as f:
    private_key = f.read()

def get_token():
    payload = {"iss": ISSUER_ID, "iat": int(time.time()), "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})

def auth_headers():
    return {"Authorization": f"Bearer {get_token()}", "Content-Type": "application/json"}

def _retry(fn):
    last = None
    for i in range(5):
        try:
            return fn()
        except Exception as e:
            last = e
            time.sleep(2 + i * 2)
    raise last

def api_get(url):
    return _retry(lambda: requests.get(url, headers=auth_headers(), verify=False, timeout=60).json())

def api_post(url, data):
    def _do():
        r = requests.post(url, headers=auth_headers(), json=data, verify=False, timeout=60)
        if r.status_code >= 400:
            print(f"    POST {r.status_code}: {r.text[:300]}")
            return None
        return r.json()
    return _retry(_do)

def api_patch(url, data):
    def _do():
        r = requests.patch(url, headers=auth_headers(), json=data, verify=False, timeout=60)
        if r.status_code >= 400:
            print(f"    PATCH {r.status_code}: {r.text[:300]}")
        return r.json() if r.text else {}
    return _retry(_do)

def api_delete(url):
    return _retry(lambda: requests.delete(url, headers=auth_headers(), verify=False, timeout=60).status_code)

def upload_chunks(upload_ops, file_data):
    for op in upload_ops:
        offset = op["offset"]
        length = op["length"]
        chunk = file_data[offset:offset + length]
        req_headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        def _put():
            r = requests.put(op["url"], headers=req_headers, data=chunk, verify=False, timeout=120)
            if r.status_code >= 400:
                raise Exception(f"chunk PUT {r.status_code}")
            return True
        try:
            _retry(_put)
        except Exception as e:
            print(f"    chunk failed after retries: {e}")
            return False
    return True

def upload_one(file_path, set_id, file_name):
    file_size = os.path.getsize(file_path)
    with open(file_path, "rb") as f:
        file_data = f.read()
    checksum = hashlib.md5(file_data).hexdigest()
    result = api_post("https://api.appstoreconnect.apple.com/v1/appScreenshots", {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": file_name, "fileSize": file_size},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}
        }
    })
    if not result:
        return False
    ss_id = result["data"]["id"]
    upload_ops = result["data"]["attributes"].get("uploadOperations", [])
    if not upload_ops:
        return False
    if not upload_chunks(upload_ops, file_data):
        return False
    api_patch(f"https://api.appstoreconnect.apple.com/v1/appScreenshots/{ss_id}", {
        "data": {"type": "appScreenshots", "id": ss_id,
                 "attributes": {"sourceFileChecksum": checksum, "uploaded": True}}
    })
    return True

def get_or_create_set(loc_id, display_type):
    r = api_get(f"https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")
    for ss in r.get("data", []):
        if ss["attributes"]["screenshotDisplayType"] == display_type:
            return ss["id"]
    result = api_post("https://api.appstoreconnect.apple.com/v1/appScreenshotSets", {
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": display_type},
            "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}
        }
    })
    return result["data"]["id"] if result else None

def clear_set(set_id):
    r = api_get(f"https://api.appstoreconnect.apple.com/v1/appScreenshotSets/{set_id}/appScreenshots")
    for s in r.get("data", []):
        api_delete(f"https://api.appstoreconnect.apple.com/v1/appScreenshots/{s['id']}")

SKIP = set(os.environ.get("SKIP_SPORTS", "").split(",")) if os.environ.get("SKIP_SPORTS") else set()
INCLUDE = set(os.environ.get("INCLUDE_SPORTS", "").split(",")) if os.environ.get("INCLUDE_SPORTS") else None

for sport, bundle_id in NEW_APPS:
    if sport in SKIP:
        print(f"\n━━━ {sport} (SKIPPED) ━━━")
        continue
    if INCLUDE is not None and sport not in INCLUDE:
        continue
    print(f"\n━━━ {sport} ({bundle_id}) ━━━", flush=True)
    r = api_get(f"https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={bundle_id}")
    app_id = r["data"][0]["id"]

    r = api_get(f"https://api.appstoreconnect.apple.com/v1/apps/{app_id}/appStoreVersions?limit=5")
    editable = [v for v in r.get("data", []) if v["attributes"].get("appStoreState") in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED")]
    if not editable:
        states = [v["attributes"].get("appStoreState") for v in r.get("data", [])]
        print(f"  no editable version (states={states})")
        continue
    version_id = editable[0]["id"]
    print(f"  version {version_id} state={editable[0]['attributes'].get('appStoreState')}")

    r = api_get(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=20")
    locs = {loc["attributes"]["locale"]: loc["id"] for loc in r.get("data", [])}

    iphone_paths = [f"{SCREENSHOTS_BASE}/{sport}/en-US/0{n}_{sport}.png" for n in range(1, 7)]
    ipad_path = f"{SCREENSHOTS_BASE}/{sport}/en-US/01_{sport}_ipad.png"

    missing = [p for p in iphone_paths if not os.path.exists(p)]
    if missing:
        print(f"  missing iPhone files: {missing}")
        continue

    # iPhone (6 stages) in all locales
    for locale in LOCALES:
        if locale not in locs:
            continue
        loc_id = locs[locale]
        set_id = get_or_create_set(loc_id, "APP_IPHONE_67")
        if not set_id:
            print(f"  {locale} iPhone: failed to create set")
            continue
        clear_set(set_id)
        all_ok = True
        for p in iphone_paths:
            ok = upload_one(p, set_id, os.path.basename(p))
            if not ok:
                all_ok = False
                break
        print(f"  {locale} iPhone (6): {'OK' if all_ok else 'FAIL'}")

    # iPad only en-US (single placeholder, unchanged)
    if "en-US" in locs and os.path.exists(ipad_path):
        set_id = get_or_create_set(locs["en-US"], "APP_IPAD_PRO_3GEN_129")
        if set_id:
            clear_set(set_id)
            ok = upload_one(ipad_path, set_id, f"01_{sport}_ipad.png")
            print(f"  en-US iPad: {'OK' if ok else 'FAIL'}")

print("\nDone.")
