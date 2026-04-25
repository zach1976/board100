#!/usr/bin/env python3
"""Submit the 8 new apps for review (re-uses flow from submit_all.py)."""
import jwt, time, warnings
import requests as _requests

warnings.filterwarnings("ignore")

KEY_FILE = "/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8"
KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
BASE = "https://api.appstoreconnect.apple.com"

NEW_APPS = [
    ("com.zach.fieldHockeyBoard", "Field Hockey Board"),
    ("com.zach.rugbyBoard", "Rugby Board"),
    ("com.zach.baseballBoard", "Baseball Board"),
    ("com.zach.handballBoard", "Handball Board"),
    ("com.zach.waterPoloBoard", "Water Polo Board"),
    ("com.zach.sepakTakrawBoard", "Sepak Takraw Board"),
    ("com.zach.beachTennisBoard", "Beach Tennis Board"),
    ("com.zach.footvolleyBoard", "Footvolley Board"),
]

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
            resp = _requests.request(method, f"{BASE}{path}", headers=headers, json=data, verify=False, timeout=60)
            if resp.status_code >= 400:
                return {"_error": True, "_status": resp.status_code, "_body": resp.json() if resp.text else {}}
            return resp.json() if resp.text else {"_ok": True}
        except Exception:
            if attempt == 2:
                raise
            time.sleep(3)

def flat_errs(r):
    errs = r["_body"].get("errors", [])
    reasons = []
    for e in errs:
        meta = e.get("meta", {}).get("associatedErrors", {})
        if meta:
            for p, ae_list in meta.items():
                for ae in ae_list:
                    reasons.append(ae.get("detail", "?"))
        else:
            reasons.append(e.get("detail", "?"))
    return list(set(reasons))

for bundle_id, name in NEW_APPS:
    print(f"\n{name}...")
    r = api("GET", f"/v1/apps?filter[bundleId]={bundle_id}")
    app_id = r["data"][0]["id"]

    r_ver = api("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION")
    if not r_ver.get("data"):
        print("  ⚠️  no PREPARE_FOR_SUBMISSION version")
        continue
    version_id = r_ver["data"][0]["id"]

    # Clean old READY_FOR_REVIEW submissions
    r_subs = api("GET", f"/v1/apps/{app_id}/reviewSubmissions")
    for sub in r_subs.get("data", []):
        if sub["attributes"]["state"] == "READY_FOR_REVIEW":
            api("DELETE", f"/v1/reviewSubmissions/{sub['id']}")
    time.sleep(1)

    # Create review submission
    r1 = api("POST", "/v1/reviewSubmissions", {
        "data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                 "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}
    })
    if r1.get("_error"):
        reasons = flat_errs(r1)
        print(f"  ❌ sub: {'; '.join(reasons)}")
        continue
    sub_id = r1["data"]["id"]

    r2 = api("POST", "/v1/reviewSubmissionItems", {
        "data": {"type": "reviewSubmissionItems", "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
        }}
    })
    if r2.get("_error"):
        reasons = flat_errs(r2)
        print(f"  ❌ item: {'; '.join(reasons)}")
        continue

    r3 = api("PATCH", f"/v1/reviewSubmissions/{sub_id}", {
        "data": {"type": "reviewSubmissions", "id": sub_id, "attributes": {"submitted": True}}
    })
    if r3.get("_error"):
        reasons = flat_errs(r3)
        print(f"  ❌ submit: {'; '.join(reasons)}")
    else:
        print(f"  ✅ {r3['data']['attributes']['state']}")
