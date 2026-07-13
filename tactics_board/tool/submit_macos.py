#!/usr/bin/env python3
"""Submit macOS (MAC_OS) App Store versions for review — the macOS counterpart
of submit_all.py.

For each app: finds the MAC_OS PREPARE_FOR_SUBMISSION version, attaches the
uploaded macOS build, sets encryption + whatsNew (reused release notes), then
creates and submits a MAC_OS review submission.

  VERSION=1.1.20 python3 tool/submit_macos.py            # all 16
  SPORTS=badminton VERSION=1.1.20 python3 tool/submit_macos.py   # subset
"""
import jwt, time, os, warnings
import requests
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY = "/Users/zhenyusong/projects/keys/AuthKey_4A9Y2S3D6X.p8"
BASE = "https://api.appstoreconnect.apple.com"
META = os.path.join(os.path.dirname(__file__), "..", "fastlane", "metadata")
VERSION = os.environ.get("VERSION", "1.1.20")

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

_filter = os.environ.get("SPORTS")
if _filter:
    keep = set(_filter.split(","))
    APPS = [a for a in APPS if a[0] in keep]


def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 900,
                       "aud": "appstoreconnect-v1"}, open(KEY).read(), algorithm="ES256",
                      headers={"kid": KEY_ID})


def api(m, p, d=None):
    r = requests.request(m, f"{BASE}{p}", headers={"Authorization": f"Bearer {tok()}",
                         "Content-Type": "application/json"}, json=d, timeout=60, verify=False)
    body = {}
    try:
        body = r.json()
    except Exception:
        pass
    if r.status_code >= 400:
        return {"_status": r.status_code, "_error": True, "_body": body}
    return body if body else {"_ok": True}


def read_meta(app_key, locale, fname):
    """Read a metadata file for a locale, falling back to en-US, then None."""
    for loc in (locale, "en-US"):
        p = os.path.join(META, app_key, loc, fname)
        if os.path.exists(p):
            return open(p).read().strip()
    return None


def read_notes(app_key, locale):
    return read_meta(app_key, locale, "release_notes.txt") or "Bug fixes and improvements."


def err_detail(r):
    errs = r.get("_body", {}).get("errors", [{}])
    reasons = []
    for e in errs:
        ae = e.get("meta", {}).get("associatedErrors", {})
        for _, lst in ae.items():
            for x in lst:
                reasons.append(x.get("detail", "?"))
        if not ae:
            reasons.append(e.get("detail", e.get("title", "?")))
    return "; ".join(sorted(set(reasons)))[:400]


def main():
    print(f"Submitting macOS v{VERSION} across {len(APPS)} apps")
    ok = err = 0
    for app_key, bundle_id in APPS:
        print(f"\n{bundle_id} ...")
        r = api("GET", f"/v1/apps?filter[bundleId]={bundle_id}")
        if r.get("_error") or not r.get("data"):
            print("  ❌ app not found"); err += 1; continue
        app_id = r["data"][0]["id"]

        # MAC_OS draft version
        r = api("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[platform]=MAC_OS&filter[appStoreState]=PREPARE_FOR_SUBMISSION")
        if not r.get("data"):
            print("  ❌ no MAC_OS PREPARE_FOR_SUBMISSION version"); err += 1; continue
        version_id = r["data"][0]["id"]

        # macOS build (VALID) for this version
        r = api("GET", f"/v1/builds?filter[app]={app_id}&filter[preReleaseVersion.version]={VERSION}&filter[preReleaseVersion.platform]=MAC_OS&sort=-uploadedDate&limit=1")
        if not r.get("data"):
            print("  ❌ no MAC_OS build in ASC yet"); err += 1; continue
        build = r["data"][0]
        build_id = build["id"]
        state = build["attributes"]["processingState"]
        if state != "VALID":
            print(f"  ⚠ build state {state}, not VALID yet — skipping"); err += 1; continue

        # Attach build
        api("PATCH", f"/v1/appStoreVersions/{version_id}/relationships/build",
            {"data": {"type": "builds", "id": build_id}})

        # Encryption flag on build
        api("PATCH", f"/v1/builds/{build_id}",
            {"data": {"type": "builds", "id": build_id,
                      "attributes": {"usesNonExemptEncryption": False}}})

        # Set description / keywords / promo from fastlane metadata. whatsNew is
        # intentionally NOT set — this is the app's first macOS version, and
        # App Store rejects "What's New" on a first release ("Attribute
        # 'whatsNew' cannot be edited at this time"). Screenshots are uploaded
        # separately (upload_macos_screenshot.py).
        r = api("GET", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=50")
        for loc in r.get("data", []):
            L = loc["attributes"]["locale"]
            attrs = {}
            for key, fname in (("description", "description.txt"),
                               ("keywords", "keywords.txt"),
                               ("promotionalText", "promotional_text.txt")):
                val = read_meta(app_key, L, fname)
                if val:
                    attrs[key] = val
            if attrs:
                api("PATCH", f"/v1/appStoreVersionLocalizations/{loc['id']}",
                    {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": attrs}})
        time.sleep(1)

        # Clean old READY_FOR_REVIEW MAC_OS submissions
        r = api("GET", f"/v1/apps/{app_id}/reviewSubmissions")
        for sub in r.get("data", []):
            a = sub["attributes"]
            if a.get("state") == "READY_FOR_REVIEW" and a.get("platform") == "MAC_OS":
                api("DELETE", f"/v1/reviewSubmissions/{sub['id']}")
        time.sleep(1)

        # Create MAC_OS review submission
        r1 = api("POST", "/v1/reviewSubmissions",
                 {"data": {"type": "reviewSubmissions", "attributes": {"platform": "MAC_OS"},
                           "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})
        if r1.get("_error"):
            print(f"  ❌ create submission: {err_detail(r1)}"); err += 1; continue
        sub_id = r1["data"]["id"]

        # Add the version as an item
        r2 = api("POST", "/v1/reviewSubmissionItems",
                 {"data": {"type": "reviewSubmissionItems", "relationships": {
                     "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
                     "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}}})
        if r2.get("_error"):
            print(f"  ❌ add item: {err_detail(r2)}"); err += 1; continue

        # Submit
        r3 = api("PATCH", f"/v1/reviewSubmissions/{sub_id}",
                 {"data": {"type": "reviewSubmissions", "id": sub_id, "attributes": {"submitted": True}}})
        if r3.get("_error"):
            print(f"  ❌ submit: {err_detail(r3)}"); err += 1; continue
        print(f"  ✅ {r3['data']['attributes']['state']}")
        ok += 1

    print(f"\n{ok}/{len(APPS)} submitted, {err} errors")
    return 0 if err == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
