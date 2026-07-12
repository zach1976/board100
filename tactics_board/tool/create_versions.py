#!/usr/bin/env python3
"""Create App Store Versions + attach builds for all 16 apps, VERSION-parameterized.

Generic successor to create_versions_1_1_<x>.py. Reads the target version from
the VERSION env var (falls back to pubspec.yaml), so no per-version copy is
needed. Run AFTER all 16 builds for VERSION reach VALID processing in ASC.
After this the apps sit in PREPARE_FOR_SUBMISSION so fastlane deliver can patch
metadata onto them.

Idempotent: an existing PREPARE_FOR_SUBMISSION version matching VERSION is
reused (just ensures the build is attached); a draft at a *different* version
is left alone and reported.

Usage:  VERSION=1.1.20 python3 tool/create_versions.py
"""
import jwt, time, os, warnings
import requests
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/projects/keys/AuthKey_4A9Y2S3D6X.p8"
BASE = "https://api.appstoreconnect.apple.com"


def _resolve_version():
    v = os.environ.get("VERSION")
    if v:
        return v
    # Fall back to pubspec.yaml's version: line (strip the +build suffix).
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    with open(os.path.join(here, "pubspec.yaml")) as f:
        for ln in f:
            if ln.startswith("version:"):
                return ln.split(":", 1)[1].strip().split("+", 1)[0]
    raise SystemExit("Could not resolve VERSION (env unset, pubspec.yaml has no version:)")


VERSION = _resolve_version()

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
    print(f"Creating v{VERSION} versions across {len(APPS)} apps")
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
            if existing_v == VERSION:
                print(f"  ↷ v{VERSION} draft already exists ({version_id})")
            else:
                print(f"  ⚠ existing draft is v{existing_v}, not v{VERSION} — skipping (resolve manually)")
                err += 1
                continue
        else:
            # 3) Create the App Store Version
            r = api("POST", "/v1/appStoreVersions", {
                "data": {"type": "appStoreVersions",
                         "attributes": {"platform": "IOS", "versionString": VERSION},
                         "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}},
            })
            if "_error" in r:
                errs = r["_error"].get("errors", [{}])
                detail = errs[0].get("detail", str(r["_error"]))[:200]
                print(f"  ✗ create v{VERSION}: {detail}"); err += 1; continue
            version_id = r["data"]["id"]
            print(f"  ✓ created v{VERSION} draft ({version_id})")

        # 4) Find the build for this version
        r = api("GET", f"/v1/builds?filter[app]={app_id}&filter[preReleaseVersion.version]={VERSION}&sort=-uploadedDate&limit=1")
        if not r.get("data"):
            print(f"  ✗ no {VERSION} build found in ASC"); err += 1; continue
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

    print(f"\n{ok}/{len(APPS)} versions ready, {err} errors")
    return 0 if err == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
