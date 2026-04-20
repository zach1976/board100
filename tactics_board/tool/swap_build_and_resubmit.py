#!/usr/bin/env python3
"""Cancel the current 1.1.4 review submission, swap to build 2, re-submit."""
import jwt, time, os, sys
import requests, urllib3
urllib3.disable_warnings()

KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8"
META_BASE = os.path.join(os.path.dirname(__file__), "..", "fastlane", "metadata")
BASE = "https://api.appstoreconnect.apple.com"

APP_KEY = {
    "com.zach.tacticsBoard": "tactics_board",
    "com.zach.soccerBoard": "soccer",
    "com.zach.basketballBoard": "basketball",
    "com.zach.volleyballBoard": "volleyball",
    "com.zach.badmintonBoard": "badminton",
    "com.zach.tennisBoard": "tennis",
    "com.zach.tableTennisBoard": "tableTennis",
    "com.zach.pickleballBoard": "pickleball",
}

APPS = list(APP_KEY.keys())
TARGET_BUILD_VERSION = "2"  # CFBundleVersion

with open(KEY_FILE) as f:
    private_key = f.read()

def token():
    now = int(time.time())
    return jwt.encode({"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
                      private_key, algorithm="ES256", headers={"kid": KEY_ID})

def api(method, path, data=None):
    h = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}
    r = requests.request(method, f"{BASE}{path}", headers=h, json=data, verify=False, timeout=60)
    if r.status_code >= 400:
        return {"_error": True, "_status": r.status_code, "_body": r.json() if r.text else {}}
    return r.json() if r.text else {"_ok": True}

def read_notes(app_key, locale):
    for loc in (locale, "en-US"):
        p = os.path.join(META_BASE, app_key, loc, "release_notes.txt")
        if os.path.exists(p):
            return open(p).read().strip()
    return "Bug fixes and improvements."

def process(bundle_id):
    app_key = APP_KEY[bundle_id]
    print(f"\n=== {app_key} ({bundle_id}) ===")
    r = api("GET", f"/v1/apps?filter[bundleId]={bundle_id}")
    app_id = r["data"][0]["id"]

    # Find 1.1.4 version (any state)
    rv = api("GET", f"/v1/apps/{app_id}/appStoreVersions")
    v114 = next((v for v in rv["data"] if v["attributes"].get("versionString") == "1.1.4"), None)
    if not v114:
        print("  ❌ no 1.1.4 version"); return
    version_id = v114["id"]
    state = v114["attributes"].get("appStoreState")
    print(f"  version {version_id} state={state}")

    # Find build 2
    rb = api("GET", f"/v1/builds?filter[app]={app_id}&filter[preReleaseVersion.version]=1.1.4&sort=-uploadedDate&limit=5")
    build2 = next((b for b in rb.get("data", []) if b["attributes"].get("version") == TARGET_BUILD_VERSION), None)
    if not build2:
        print(f"  ❌ no build {TARGET_BUILD_VERSION} uploaded yet"); return
    if build2["attributes"].get("processingState") != "VALID":
        print(f"  ⏳ build {TARGET_BUILD_VERSION} state={build2['attributes'].get('processingState')}, not VALID yet"); return
    build_id = build2["id"]
    print(f"  build_id {build_id} VALID")

    # Cancel any WAITING_FOR_REVIEW / READY_FOR_REVIEW submissions
    rs = api("GET", f"/v1/apps/{app_id}/reviewSubmissions")
    for s in rs.get("data", []):
        st = s["attributes"].get("state")
        if st == "WAITING_FOR_REVIEW":
            print(f"  cancelling WAITING submission {s['id']}")
            res = api("PATCH", f"/v1/reviewSubmissions/{s['id']}", {
                "data": {"type": "reviewSubmissions", "id": s["id"],
                         "attributes": {"canceled": True}}
            })
            if res.get("_error"):
                print(f"    cancel error: {res['_body']}")
        elif st == "READY_FOR_REVIEW":
            print(f"  deleting stale READY submission {s['id']}")
            api("DELETE", f"/v1/reviewSubmissions/{s['id']}")

    # Wait for state transition
    time.sleep(5)

    # Swap build relationship on the version
    print(f"  attaching build {build_id}")
    res = api("PATCH", f"/v1/appStoreVersions/{version_id}/relationships/build", {
        "data": {"type": "builds", "id": build_id}
    })
    if res.get("_error"):
        print(f"    attach error: {res['_body']}")

    # Set usesNonExemptEncryption=false + whatsNew
    api("PATCH", f"/v1/builds/{build_id}", {
        "data": {"type": "builds", "id": build_id,
                 "attributes": {"usesNonExemptEncryption": False}}
    })
    rl = api("GET", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=40")
    for loc in rl.get("data", []):
        loc_id = loc["id"]
        locale = loc["attributes"]["locale"]
        notes = read_notes(app_key, locale)
        api("PATCH", f"/v1/appStoreVersionLocalizations/{loc_id}", {
            "data": {"type": "appStoreVersionLocalizations", "id": loc_id,
                     "attributes": {"whatsNew": notes}}
        })

    time.sleep(2)

    # Create new reviewSubmission + item + submit
    r1 = api("POST", "/v1/reviewSubmissions", {
        "data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                 "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}
    })
    if r1.get("_error"):
        print(f"  ❌ create submission: {r1['_body']}"); return
    sub_id = r1["data"]["id"]
    r2 = api("POST", "/v1/reviewSubmissionItems", {
        "data": {"type": "reviewSubmissionItems", "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
        }}
    })
    if r2.get("_error"):
        print(f"  ❌ add item: {r2['_body']}"); return
    r3 = api("PATCH", f"/v1/reviewSubmissions/{sub_id}", {
        "data": {"type": "reviewSubmissions", "id": sub_id,
                 "attributes": {"submitted": True}}
    })
    if r3.get("_error"):
        print(f"  ❌ submit: {r3['_body']}")
    else:
        print(f"  ✅ {r3['data']['attributes']['state']}")

if __name__ == "__main__":
    targets = sys.argv[1:] if len(sys.argv) > 1 else APPS
    for bid in targets:
        try:
            process(bid)
        except Exception as e:
            print(f"  ❌ exception: {e}")
