#!/usr/bin/env python3
"""Submit all 16 Tactics Board apps for App Store review."""
import jwt, time, json, os, urllib.request, urllib.error, base64
import requests as _requests

KEY_FILE = "/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8"
KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
BASE = "https://api.appstoreconnect.apple.com"
META_BASE = os.path.join(os.path.dirname(__file__), "..", "fastlane", "metadata")

APP_KEY = {
    "com.zach.tacticsBoard": "tactics_board",
    "com.zach.soccerBoard": "soccer",
    "com.zach.basketballBoard": "basketball",
    "com.zach.volleyballBoard": "volleyball",
    "com.zach.badmintonBoard": "badminton",
    "com.zach.tennisBoard": "tennis",
    "com.zach.tableTennisBoard": "tableTennis",
    "com.zach.pickleballBoard": "pickleball",
    "com.zach.fieldHockeyBoard": "fieldHockey",
    "com.zach.rugbyBoard": "rugby",
    "com.zach.baseballBoard": "baseball",
    "com.zach.handballBoard": "handball",
    "com.zach.waterPoloBoard": "waterPolo",
    "com.zach.sepakTakrawBoard": "sepakTakraw",
    "com.zach.beachTennisBoard": "beachTennis",
    "com.zach.footvolleyBoard": "footvolley",
}

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
        except Exception:
            if attempt == 2:
                raise
            time.sleep(3)

def read_notes(app_key, locale):
    p = os.path.join(META_BASE, app_key, locale, "release_notes.txt")
    if os.path.exists(p):
        return open(p).read().strip()
    p2 = os.path.join(META_BASE, app_key, "en-US", "release_notes.txt")
    if os.path.exists(p2):
        return open(p2).read().strip()
    return "Bug fixes and improvements."

def prepare_version(version_id, app_key):
    """Set usesNonExemptEncryption on build and whatsNew on all localizations."""
    # Set usesNonExemptEncryption=false on the build
    r_build = api("GET", f"/v1/appStoreVersions/{version_id}/build")
    if r_build.get("data"):
        build_id = r_build["data"]["id"]
        api("PATCH", f"/v1/builds/{build_id}", {
            "data": {"type": "builds", "id": build_id,
                     "attributes": {"usesNonExemptEncryption": False}}
        })
    # Set whatsNew on all localizations
    r_locs = api("GET", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")
    for loc in r_locs.get("data", []):
        loc_id = loc["id"]
        locale = loc["attributes"]["locale"]
        notes = read_notes(app_key, locale)
        api("PATCH", f"/v1/appStoreVersionLocalizations/{loc_id}", {
            "data": {"type": "appStoreVersionLocalizations", "id": loc_id,
                     "attributes": {"whatsNew": notes}}
        })

APPS = [
    ("com.zach.tacticsBoard", "Tactics Board"),
    ("com.zach.soccerBoard", "Soccer Board"),
    ("com.zach.basketballBoard", "Basketball Board"),
    ("com.zach.volleyballBoard", "Volleyball Board"),
    ("com.zach.badmintonBoard", "Badminton Board"),
    ("com.zach.tennisBoard", "Tennis Board"),
    ("com.zach.tableTennisBoard", "Table Tennis Board"),
    ("com.zach.pickleballBoard", "Pickleball Board"),
    ("com.zach.fieldHockeyBoard", "Field Hockey Board"),
    ("com.zach.rugbyBoard", "Rugby Board"),
    ("com.zach.baseballBoard", "Baseball Board"),
    ("com.zach.handballBoard", "Handball Board"),
    ("com.zach.waterPoloBoard", "Water Polo Board"),
    ("com.zach.sepakTakrawBoard", "Sepak Takraw Board"),
    ("com.zach.beachTennisBoard", "Beach Tennis Board"),
    ("com.zach.footvolleyBoard", "Footvolley Board"),
]

for bundle_id, name in APPS:
    print(f"\n{name}...")
    r = api("GET", f"/v1/apps?filter[bundleId]={bundle_id}")
    app_id = r["data"][0]["id"]
    app_key = APP_KEY[bundle_id]

    r_ver = api("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION")
    if not r_ver["data"]:
        # Create a new 1.1.6 version
        r_new = api("POST", "/v1/appStoreVersions", {
            "data": {"type": "appStoreVersions",
                     "attributes": {"platform": "IOS", "versionString": "1.1.6"},
                     "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}
        })
        if r_new.get("_error"):
            errs = r_new["_body"].get("errors", [])
            print(f"  ❌ create version: {errs[0].get('detail','?') if errs else '?'}")
            continue
        version_id = r_new["data"]["id"]
        # Find the uploaded 1.1.6 build
        r_builds = api("GET", f"/v1/builds?filter[app]={app_id}&filter[preReleaseVersion.version]=1.1.6&sort=-uploadedDate&limit=1")
        if not r_builds.get("data"):
            print(f"  ❌ no 1.1.6 build found in App Store Connect yet, try again later")
            continue
        build_id = r_builds["data"][0]["id"]
        api("PATCH", f"/v1/appStoreVersions/{version_id}/relationships/build", {
            "data": {"type": "builds", "id": build_id}
        })
        time.sleep(2)
    else:
        version_id = r_ver["data"][0]["id"]

    # Prepare version: set encryption flag + whatsNew
    prepare_version(version_id, app_key)
    time.sleep(1)

    # Clean old READY_FOR_REVIEW submissions
    r_subs = api("GET", f"/v1/apps/{app_id}/reviewSubmissions")
    for sub in r_subs.get("data", []):
        if sub["attributes"]["state"] == "READY_FOR_REVIEW":
            api("DELETE", f"/v1/reviewSubmissions/{sub['id']}")

    time.sleep(2)

    # Create review submission
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
                reasons.append(f"{ae.get('detail','?')}")
        if reasons:
            print(f"  ❌ {'; '.join(set(reasons))}")
        else:
            print(f"  ❌ {errs[0].get('detail','?') if errs else '?'}")
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
        reasons2 = []
        for p, ae_list in meta2.items():
            for ae in ae_list:
                reasons2.append(ae.get("detail", "?"))
        if reasons2:
            print(f"  ❌ item: {'; '.join(set(reasons2))}")
        else:
            print(f"  ❌ item: {errs2[0].get('detail','?') if errs2 else '?'}")
        continue

    # Submit
    r3 = api("PATCH", f"/v1/reviewSubmissions/{sub_id}", {
        "data": {"type": "reviewSubmissions", "id": sub_id, "attributes": {"submitted": True}}
    })
    if r3.get("_error"):
        print(f"  ❌ {r3['_body'].get('errors',[{}])[0].get('detail','?')}")
    else:
        print(f"  ✅ {r3['data']['attributes']['state']}")
