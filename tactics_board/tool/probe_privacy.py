#!/usr/bin/env python3
"""Probe app privacy state for badminton vs new apps."""
import jwt, time, json, warnings
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
    print(json.dumps(obj, indent=2)[:3000])

for bundle in ["com.zach.badmintonBoard", "com.zach.fieldHockeyBoard"]:
    print(f"\n##################### {bundle} #####################")
    r = api("GET", f"/v1/apps?filter[bundleId]={bundle}")
    app_id = r["data"][0]["id"]
    print(f"APP ID: {app_id}")

    # app privacy endpoints
    for endpoint in [
        f"/v1/apps/{app_id}/dataUsagesPublishState",
        f"/v1/apps/{app_id}/appDataUsages",
        f"/v1/apps/{app_id}/appDataUsagesPublishState",
    ]:
        r2 = api("GET", endpoint)
        dump(endpoint, r2)

    # price schedule
    r3 = api("GET", f"/v1/apps/{app_id}/appPriceSchedule")
    dump("appPriceSchedule", r3)

    # category on app's appInfo
    r_infos = api("GET", f"/v1/apps/{app_id}/appInfos")
    for ai in r_infos.get("data", []):
        print(f"\nappInfo {ai['id']} state={ai['attributes'].get('state')}")
        r4 = api("GET", f"/v1/appInfos/{ai['id']}/primaryCategory")
        dump(f"  primaryCategory ({ai['attributes'].get('state')})", r4)

    # age rating declaration on appInfo
    for ai in r_infos.get("data", []):
        r5 = api("GET", f"/v1/appInfos/{ai['id']}/ageRatingDeclaration")
        dump(f"  ageRatingDeclaration on appInfo {ai['id']}", r5)
