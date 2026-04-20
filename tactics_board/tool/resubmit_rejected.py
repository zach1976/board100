#!/usr/bin/env python3
"""Resubmit all DEVELOPER_REJECTED 1.1.4 apps for review (screenshots already uploaded)."""
import jwt, time, requests as _requests

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
    for attempt in range(3):
        try:
            resp = _requests.request(method, f"{BASE}{path}", headers=headers,
                                     json=data, verify=False, timeout=60)
            if resp.status_code >= 400:
                return {"_error": True, "_status": resp.status_code, "_body": resp.json() if resp.text else {}}
            return resp.json() if resp.text else {"_ok": True}
        except Exception as e:
            if attempt == 2:
                raise
            print(f"    retry {attempt+1}: {e}")
            time.sleep(3)

APPS = [
    ("com.zach.tacticsBoard",    "Tactics Board"),
    ("com.zach.soccerBoard",     "Soccer Board"),
    ("com.zach.basketballBoard", "Basketball Board"),
    ("com.zach.volleyballBoard", "Volleyball Board"),
    ("com.zach.badmintonBoard",  "Badminton Board"),
    ("com.zach.tennisBoard",     "Tennis Board"),
    ("com.zach.tableTennisBoard","Table Tennis Board"),
    ("com.zach.pickleballBoard", "Pickleball Board"),
]

for bundle_id, name in APPS:
    print(f"\n{name}...")
    r = api("GET", f"/v1/apps?filter[bundleId]={bundle_id}")
    app_id = r["data"][0]["id"]

    # Find DEVELOPER_REJECTED version
    r_ver = api("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[appStoreState]=DEVELOPER_REJECTED&limit=1")
    if not r_ver.get("data"):
        r_cur = api("GET", f"/v1/apps/{app_id}/appStoreVersions?limit=1")
        state = r_cur["data"][0]["attributes"]["appStoreState"] if r_cur.get("data") else "unknown"
        print(f"  Not DEVELOPER_REJECTED (state: {state}), skipping")
        continue

    version_id = r_ver["data"][0]["id"]
    ver_str = r_ver["data"][0]["attributes"]["versionString"]
    print(f"  Version {ver_str} — submitting...")

    # Clean up any existing READY_FOR_REVIEW submissions
    r_subs = api("GET", f"/v1/apps/{app_id}/reviewSubmissions")
    for sub in r_subs.get("data", []):
        if sub["attributes"]["state"] in ("READY_FOR_REVIEW", "WAITING_FOR_REVIEW"):
            api("DELETE", f"/v1/reviewSubmissions/{sub['id']}")
            print(f"  Cleaned up existing submission")

    time.sleep(1)

    # Create review submission
    r1 = api("POST", "/v1/reviewSubmissions", {
        "data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                 "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}
    })
    if r1.get("_error"):
        errs = r1["_body"].get("errors", [])
        print(f"  ❌ create submission: {errs[0].get('detail','?') if errs else r1}")
        continue
    sub_id = r1["data"]["id"]

    # Add version item
    r2 = api("POST", "/v1/reviewSubmissionItems", {
        "data": {"type": "reviewSubmissionItems", "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
        }}
    })
    if r2.get("_error"):
        errs2 = r2["_body"].get("errors", [])
        meta2 = errs2[0].get("meta", {}).get("associatedErrors", {}) if errs2 else {}
        reasons = [ae.get("detail", "?") for ae_list in meta2.values() for ae in ae_list]
        msg = "; ".join(set(reasons)) if reasons else (errs2[0].get("detail", "?") if errs2 else str(r2))
        print(f"  ❌ add item: {msg}")
        api("DELETE", f"/v1/reviewSubmissions/{sub_id}")
        continue

    # Submit
    r3 = api("PATCH", f"/v1/reviewSubmissions/{sub_id}", {
        "data": {"type": "reviewSubmissions", "id": sub_id, "attributes": {"submitted": True}}
    })
    if r3.get("_error"):
        errs3 = r3["_body"].get("errors", [])
        print(f"  ❌ submit: {errs3[0].get('detail','?') if errs3 else r3}")
    else:
        print(f"  ✅ {r3['data']['attributes']['state']}")

print("\n🎉 Done!")
