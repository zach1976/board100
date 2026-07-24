#!/usr/bin/env python3
"""Ship v1.1.24 (code fixes) to all 16 apps, reusing the ASO metadata already
sitting on each app's pending (Waiting-for-Review) version.

Per app:
  1. Locate the app's newest editable version (the pending ASO one, whatever
     number — 1.1.21 / .22 / .23).
  2. Cancel its WAITING_FOR_REVIEW / delete stale READY_FOR_REVIEW submission.
  3. Retarget that version's versionString -> 1.1.24 (keeps its ASO
     localizations: description / keywords / promo text).
  4. Attach the uploaded 1.1.24 build (must be VALID), set
     usesNonExemptEncryption=false, and push localized whatsNew.
  5. Create a fresh reviewSubmission + item and submit.

Idempotent-ish: safe to re-run; skips apps whose 1.1.24 build isn't VALID yet
and re-submits any app not already in review at 1.1.24.

Usage:
  python3 tool/submit_1_1_24.py            # all 16
  python3 tool/submit_1_1_24.py waterPolo  # subset by sport key
"""
import jwt, time, os, sys
import requests, urllib3
urllib3.disable_warnings()

KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/projects/keys/AuthKey_4A9Y2S3D6X.p8"
META_BASE = os.path.join(os.path.dirname(__file__), "..", "fastlane", "metadata")
BASE = "https://api.appstoreconnect.apple.com"
TARGET_VERSION = "1.1.24"

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
# ASC states that are still editable (not live, not in review).
EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
            "METADATA_REJECTED", "INVALID_BINARY"}

with open(KEY_FILE) as f:
    private_key = f.read()


def token():
    now = int(time.time())
    return jwt.encode({"iss": ISSUER_ID, "iat": now, "exp": now + 1200,
                       "aud": "appstoreconnect-v1"},
                      private_key, algorithm="ES256", headers={"kid": KEY_ID})


def api(method, path, data=None):
    for attempt in range(3):
        h = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}
        try:
            r = requests.request(method, f"{BASE}{path}", headers=h, json=data,
                                 verify=False, timeout=60)
            if r.status_code >= 400:
                return {"_error": True, "_status": r.status_code,
                        "_body": r.json() if r.text else {}}
            return r.json() if r.text else {"_ok": True}
        except Exception:
            if attempt == 2:
                raise
            time.sleep(3)


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
    if r.get("_error") or not r.get("data"):
        print("  ❌ app not found"); return False
    app_id = r["data"][0]["id"]

    # 1.1.24 build must be uploaded + VALID.
    rb = api("GET", f"/v1/builds?filter[app]={app_id}"
                    f"&filter[preReleaseVersion.version]={TARGET_VERSION}"
                    f"&sort=-uploadedDate&limit=10")
    build = next((b for b in rb.get("data", [])
                  if b["attributes"].get("processingState") == "VALID"), None)
    if not build:
        states = [b["attributes"].get("processingState") for b in rb.get("data", [])]
        print(f"  ⏳ no VALID {TARGET_VERSION} build yet (states={states}) — skip"); return False
    build_id = build["id"]
    print(f"  build {build_id} VALID")

    # Pick the version to reuse: an existing 1.1.24, else the newest non-live one.
    # MUST filter platform=IOS — these apps also have macOS version records, and
    # attaching an iOS build to a macOS version 409s ("different platform").
    rv = api("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=10")
    vers = [v for v in rv.get("data", [])
            if v["attributes"].get("platform") == "IOS"]
    version = next((v for v in vers
                    if v["attributes"].get("versionString") == TARGET_VERSION), None)
    if not version:
        # newest editable-or-in-review version that isn't a live/rejected-live one
        version = next((v for v in vers if v["attributes"].get("appStoreState")
                        in EDITABLE | {"WAITING_FOR_REVIEW", "IN_REVIEW",
                                       "PENDING_DEVELOPER_RELEASE"}), None)
    if not version:
        print("  ❌ no reusable version record found"); return False
    version_id = version["id"]
    cur_ver = version["attributes"].get("versionString")
    state = version["attributes"].get("appStoreState")
    print(f"  reusing version {version_id} ({cur_ver}, {state})")

    # Already submitted at the target version — leave it alone. Re-processing
    # would cancel the live review and race the re-attach (INVALID_STATE).
    if cur_ver == TARGET_VERSION and state in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
        print("  ↷ already in review at 1.1.24 — skip"); return True

    # Cancel any in-review IOS submission so the version becomes editable.
    # Only touch IOS submissions — never the macOS ones (separate platform).
    rs = api("GET", f"/v1/apps/{app_id}/reviewSubmissions")
    for s in rs.get("data", []):
        if s["attributes"].get("platform") != "IOS":
            continue
        st = s["attributes"].get("state")
        if st in ("WAITING_FOR_REVIEW", "IN_REVIEW"):
            print(f"  cancelling {st} submission {s['id']}")
            api("PATCH", f"/v1/reviewSubmissions/{s['id']}",
                {"data": {"type": "reviewSubmissions", "id": s["id"],
                          "attributes": {"canceled": True}}})
        elif st in ("READY_FOR_REVIEW", "UNRESOLVED_ISSUES"):
            print(f"  deleting stale {st} submission {s['id']}")
            api("DELETE", f"/v1/reviewSubmissions/{s['id']}")
    time.sleep(6)

    # Retarget versionString -> 1.1.24 (no-op if already 1.1.24).
    if cur_ver != TARGET_VERSION:
        r = api("PATCH", f"/v1/appStoreVersions/{version_id}",
                {"data": {"type": "appStoreVersions", "id": version_id,
                          "attributes": {"versionString": TARGET_VERSION}}})
        if r.get("_error"):
            print(f"  ❌ retarget versionString: {r['_body']}"); return False
        print(f"  versionString -> {TARGET_VERSION}")

    # Attach build.
    r = api("PATCH", f"/v1/appStoreVersions/{version_id}/relationships/build",
            {"data": {"type": "builds", "id": build_id}})
    if r.get("_error"):
        print(f"  ❌ attach build: {r['_body']}"); return False

    # Encryption declaration.
    api("PATCH", f"/v1/builds/{build_id}",
        {"data": {"type": "builds", "id": build_id,
                  "attributes": {"usesNonExemptEncryption": False}}})

    # Localized whatsNew.
    rl = api("GET", f"/v1/appStoreVersions/{version_id}"
                    f"/appStoreVersionLocalizations?limit=40")
    for loc in rl.get("data", []):
        notes = read_notes(app_key, loc["attributes"]["locale"])
        api("PATCH", f"/v1/appStoreVersionLocalizations/{loc['id']}",
            {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"],
                      "attributes": {"whatsNew": notes}}})
    time.sleep(2)

    # Fresh reviewSubmission + item + submit.
    r1 = api("POST", "/v1/reviewSubmissions",
             {"data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                       "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})
    if r1.get("_error"):
        print(f"  ❌ create submission: {r1['_body']}"); return False
    sub_id = r1["data"]["id"]
    r2 = api("POST", "/v1/reviewSubmissionItems",
             {"data": {"type": "reviewSubmissionItems", "relationships": {
                 "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
                 "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}}})
    if r2.get("_error"):
        print(f"  ❌ add item: {r2['_body']}"); return False
    r3 = api("PATCH", f"/v1/reviewSubmissions/{sub_id}",
             {"data": {"type": "reviewSubmissions", "id": sub_id,
                       "attributes": {"submitted": True}}})
    if r3.get("_error"):
        print(f"  ❌ submit: {r3['_body']}"); return False
    print(f"  ✅ submitted {TARGET_VERSION} for review")
    return True


def main():
    keys = sys.argv[1:]
    bundles = list(APP_KEY.keys())
    if keys:
        bundles = [b for b, k in APP_KEY.items() if k in keys]
    ok = 0
    for b in bundles:
        try:
            if process(b):
                ok += 1
        except Exception as e:
            print(f"  ❌ exception: {e}")
    print(f"\n==== submitted {ok}/{len(bundles)} apps ====")


if __name__ == "__main__":
    main()
