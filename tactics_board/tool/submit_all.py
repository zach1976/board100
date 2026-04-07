#!/usr/bin/env python3
"""Submit all 8 Tactics Board apps for App Store review."""
import jwt, time, json, urllib.request, urllib.error, base64

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
    body = json.dumps(data).encode() if data else None
    req = urllib.request.Request(f"{BASE}{path}", data=body, headers=headers, method=method)
    try:
        resp = urllib.request.urlopen(req)
        raw = resp.read()
        return json.loads(raw) if raw else {"_ok": True}
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        return {"_error": True, "_status": e.code, "_body": json.loads(raw) if raw else {}}

APPS = [
    ("com.zach.tacticsBoard", "Tactics Board"),
    ("com.zach.soccerBoard", "Soccer Board"),
    ("com.zach.basketballBoard", "Basketball Board"),
    ("com.zach.volleyballBoard", "Volleyball Board"),
    ("com.zach.badmintonBoard", "Badminton Board"),
    ("com.zach.tennisBoard", "Tennis Board"),
    ("com.zach.tableTennisBoard", "Table Tennis Board"),
    ("com.zach.pickleballBoard", "Pickleball Board"),
]

for bundle_id, name in APPS:
    r = api("GET", f"/v1/apps?filter[bundleId]={bundle_id}")
    app_id = r["data"][0]["id"]

    r_ver = api("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION")
    if not r_ver["data"]:
        # Check if already submitted
        r_ver2 = api("GET", f"/v1/apps/{app_id}/appStoreVersions?limit=1")
        state = r_ver2["data"][0]["attributes"]["appStoreState"] if r_ver2["data"] else "?"
        print(f"  {name}: {state}")
        continue
    version_id = r_ver["data"][0]["id"]

    # Clean old submissions
    r_subs = api("GET", f"/v1/apps/{app_id}/reviewSubmissions")
    for sub in r_subs.get("data", []):
        if sub["attributes"]["state"] == "READY_FOR_REVIEW":
            api("DELETE", f"/v1/reviewSubmissions/{sub['id']}")

    time.sleep(2)

    # Create
    r1 = api("POST", "/v1/reviewSubmissions", {
        "data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                 "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}
    })
    if r1.get("_error"):
        errs = r1["_body"].get("errors", [])
        meta = errs[0].get("meta", {}).get("associatedErrors", {}) if errs else {}
        reasons = []
        for p, ae_list in meta.items():
            for ae in ae_list:
                reasons.append(f"{ae.get('code')}: {ae.get('title')}")
        if reasons:
            print(f"  {name}: ❌ {'; '.join(reasons)}")
        else:
            print(f"  {name}: ❌ {errs[0].get('detail','?') if errs else '?'}")
        continue

    sub_id = r1["data"]["id"]

    # Add item
    r2 = api("POST", "/v1/reviewSubmissionItems", {
        "data": {"type": "reviewSubmissionItems", "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
        }}
    })
    if r2.get("_error"):
        errs2 = r2["_body"].get("errors", [])
        meta2 = errs2[0].get("meta", {}).get("associatedErrors", {}) if errs2 else {}
        for p, ae_list in meta2.items():
            for ae in ae_list:
                print(f"  {name}: ❌ {ae.get('code')}: {ae.get('title')}")
        if not meta2:
            print(f"  {name}: ❌ {errs2[0].get('detail','?') if errs2 else '?'}")
        continue

    # Submit
    r3 = api("PATCH", f"/v1/reviewSubmissions/{sub_id}", {
        "data": {"type": "reviewSubmissions", "id": sub_id, "attributes": {"submitted": True}}
    })
    if r3.get("_error"):
        print(f"  {name}: ❌ {r3['_body'].get('errors',[{}])[0].get('detail','?')}")
    else:
        print(f"  {name}: ✅ {r3['data']['attributes']['state']}")
