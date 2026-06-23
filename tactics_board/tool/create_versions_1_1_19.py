#!/usr/bin/env python3
"""Create v1.1.19 App Store Versions + attach 1.1.19 builds for all 16 apps.

Run AFTER all 16 1.1.19 builds reach VALID processing state in ASC.
After this, the apps will be in PREPARE_FOR_SUBMISSION state and
fastlane deliver can patch metadata onto them.

Idempotent: if a v1.1.19 PREPARE_FOR_SUBMISSION version already exists
for an app, it's reused (just ensures build is attached).
"""
import jwt, time, sys, warnings
import requests
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/projects/keys/AuthKey_4A9Y2S3D6X.p8"
BASE = "https://api.appstoreconnect.apple.com"

APPS = [
    ("tactics_board", "com.zach.tacticsBoard"),
    ("soccer",        "com.zach.soccerBoard"),
    ("basketball",    "com.zach.basketballBoard"),
    ("volleyball",    "com.zach.volleyballBoard"),
    ("badminton",     "com.zach.badmintonBoard"),
    ("tennis",        "com.zach.tennisBoard"),
    ("tableTennis",   "com.zach.tableTennisBoard"),
    ("pickleball",    "com.zach.pickleballBoard"),
    ("baseball",      "com.zach.baseballBoard"),
    ("handball",      "com.zach.handballBoard"),
    ("rugby",         "com.zach.rugbyBoard"),
    ("fieldHockey",   "com.zach.fieldHockeyBoard"),
    ("waterPolo",     "com.zach.waterPoloBoard"),
    ("sepakTakraw",   "com.zach.sepakTakrawBoard"),
    ("beachTennis",   "com.zach.beachTennisBoard"),
    ("footvolley",    "com.zach.footvolleyBoard"),
]


def tok():
    with open(KEY_FILE) as f:
        pk = f.read()
    return jwt.encode({"iss": ISSUER_ID, "iat": int(time.time()), "exp": int(time.time()) + 1200,
                       "aud": "appstoreconnect-v1"},
                      pk, algorithm="ES256", headers={"kid": KEY_ID})


def api(method, path, data=None):
    headers = {"Authorization": f"Bearer {tok()}", "Content-Type": "application/json"}
    r = requests.request(method, f"{BASE}{path}", headers=headers, json=data, timeout=60, verify=False)
    if r.status_code >= 400:
        return {"_status": r.status_code, "_error": r.json() if r.text else {}}
    return r.json() if r.text else {"_ok": True}


def main():
    ok = err = 0
    for sku, bundle_id in APPS:
        print(f"\n━━━ {sku} ({bundle_id}) ━━━")
        # 1) Resolve app id
        r = api("GET", f"/v1/apps?filter[bundleId]={bundle_id}")
        if "_error" in r or not r.get("data"):
            print(f"  ✗ app not found"); err += 1; continue
        app_id = r["data"][0]["id"]

        # 2) Look for an existing PREPARE_FOR_SUBMISSION version
        r = api("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION")
        if r.get("data"):
            version_id = r["data"][0]["id"]
            existing_v = r["data"][0]["attributes"]["versionString"]
            if existing_v == "1.1.19":
                print(f"  ↷ v1.1.19 draft already exists ({version_id})")
            else:
                print(f"  ⚠ existing draft is v{existing_v}, not v1.1.19 — skipping (resolve manually)")
                err += 1
                continue
        else:
            # 3) Create v1.1.19 App Store Version
            r = api("POST", "/v1/appStoreVersions", {
                "data": {"type": "appStoreVersions",
                         "attributes": {"platform": "IOS", "versionString": "1.1.19"},
                         "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}},
            })
            if "_error" in r:
                errs = r["_error"].get("errors", [{}])
                detail = errs[0].get("detail", str(r["_error"]))[:200]
                print(f"  ✗ create v1.1.19: {detail}"); err += 1; continue
            version_id = r["data"]["id"]
            print(f"  ✓ created v1.1.19 draft ({version_id})")

        # 4) Find the 1.1.19 build
        r = api("GET", f"/v1/builds?filter[app]={app_id}&filter[preReleaseVersion.version]=1.1.19&sort=-uploadedDate&limit=1")
        if not r.get("data"):
            print(f"  ✗ no 1.1.19 build found in ASC"); err += 1; continue
        build = r["data"][0]
        build_id = build["id"]
        build_state = build["attributes"]["processingState"]
        if build_state != "VALID":
            print(f"  ⚠ build state {build_state}, expected VALID — attaching anyway")

        # 5) Attach build (idempotent)
        r = api("PATCH", f"/v1/appStoreVersions/{version_id}/relationships/build", {
            "data": {"type": "builds", "id": build_id}
        })
        if "_error" in r and r.get("_status", 0) not in (200, 204):
            errs = r["_error"].get("errors", [{}])
            detail = errs[0].get("detail", str(r["_error"]))[:200]
            print(f"  ⚠ attach build: {detail}")
        else:
            print(f"  ✓ build {build_id} attached")

        ok += 1

    print(f"\n{ok}/16 versions ready, {err} errors")
    return 0 if err == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
