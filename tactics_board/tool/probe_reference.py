#!/usr/bin/env python3
"""Probe the badmintonBoard app to extract all reference settings for cloning."""
import jwt, time, json, os, warnings
import requests as _requests

warnings.filterwarnings("ignore")

KEY_FILE = "/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8"
KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
BASE = "https://api.appstoreconnect.apple.com"

with open(KEY_FILE) as f:
    private_key = f.read()

def get_token():
    payload = {"iss": ISSUER_ID, "iat": int(time.time()), "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})

def api(method, path, data=None):
    token = get_token()
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    resp = _requests.request(method, f"{BASE}{path}", headers=headers, json=data, verify=False, timeout=60)
    if resp.status_code >= 400:
        return {"_error": True, "_status": resp.status_code, "_body": resp.json() if resp.text else {}}
    return resp.json() if resp.text else {"_ok": True}

def dump(label, obj):
    print(f"\n=== {label} ===")
    print(json.dumps(obj, indent=2)[:4000])

r = api("GET", "/v1/apps?filter[bundleId]=com.zach.badmintonBoard")
app_id = r["data"][0]["id"]
print(f"APP ID: {app_id}")

# appInfos: use the READY_FOR_DISTRIBUTION one
r_infos = api("GET", f"/v1/apps/{app_id}/appInfos")
app_info_id = None
for ai in r_infos["data"]:
    if ai["attributes"]["state"] == "READY_FOR_DISTRIBUTION":
        app_info_id = ai["id"]
        break
if not app_info_id:
    app_info_id = r_infos["data"][0]["id"]
print(f"APP INFO ID: {app_info_id}")

# ageRatingDeclaration on appInfo
r_ard = api("GET", f"/v1/appInfos/{app_info_id}/ageRatingDeclaration")
dump("ageRatingDeclaration", r_ard)

# appInfoLocalizations
r_ail = api("GET", f"/v1/appInfos/{app_info_id}/appInfoLocalizations?limit=20")
dump("appInfoLocalizations", r_ail)

# appStoreVersions (no sort)
r_vers = api("GET", f"/v1/apps/{app_id}/appStoreVersions?limit=5")
for v in r_vers["data"]:
    print(f"\nVersion: {v['attributes'].get('versionString')} state={v['attributes'].get('appStoreState')} id={v['id']}")

# Grab a LATEST LIVE version to probe its review detail + localizations
live_ver_id = None
for v in r_vers["data"]:
    if v["attributes"]["appStoreState"] in ("READY_FOR_SALE", "PROCESSING_FOR_APP_STORE", "WAITING_FOR_REVIEW", "IN_REVIEW", "PENDING_APPLE_RELEASE", "PENDING_DEVELOPER_RELEASE"):
        live_ver_id = v["id"]
        break
if not live_ver_id:
    live_ver_id = r_vers["data"][0]["id"]
print(f"\nLIVE VERSION ID: {live_ver_id}")

# appStoreReviewDetail
r_rvd = api("GET", f"/v1/appStoreVersions/{live_ver_id}/appStoreReviewDetail")
dump("appStoreReviewDetail", r_rvd)

# version localizations
r_loc = api("GET", f"/v1/appStoreVersions/{live_ver_id}/appStoreVersionLocalizations?limit=20")
dump("appStoreVersionLocalizations (list)", r_loc)

# Detail of en-US version localization
for loc in r_loc.get("data", []):
    if loc["attributes"]["locale"] == "en-US":
        r_loc_detail = api("GET", f"/v1/appStoreVersionLocalizations/{loc['id']}")
        dump(f"en-US appStoreVersionLocalization", r_loc_detail)
        break

# appStoreVersion ageRatingDeclaration (on version)
r_ard2 = api("GET", f"/v1/appStoreVersions/{live_ver_id}/ageRatingDeclaration")
dump("version ageRatingDeclaration", r_ard2)

# en-US appInfoLocalization full
for ail in r_ail.get("data", []):
    if ail["attributes"]["locale"] == "en-US":
        r_ail_detail = api("GET", f"/v1/appInfoLocalizations/{ail['id']}")
        dump("en-US appInfoLocalization", r_ail_detail)
        break

# Pricing: free tier lookup
r_free = api("GET", f"/v1/apps/{app_id}/appPricePoints?filter[territory]=USA&limit=1")
dump("USA price point (first)", r_free)
