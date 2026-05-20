#!/usr/bin/env python3
"""Poll App Store Connect until all 16 v{VERSION} builds finish processing.

VERSION defaults to the value in pubspec.yaml; override via env (e.g. VERSION=1.1.13).
"""
import jwt, time, sys, os, warnings
import requests
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8"

VERSION = os.environ.get("VERSION")
if not VERSION:
    try:
        with open(os.path.join(os.path.dirname(__file__), "..", "pubspec.yaml")) as _pf:
            for _ln in _pf:
                if _ln.startswith("version:"):
                    VERSION = _ln.split(":", 1)[1].strip().split("+", 1)[0]
                    break
    except Exception:
        pass
if not VERSION:
    print("❌ VERSION env var required (and pubspec.yaml not readable)")
    raise SystemExit(2)

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


def H():
    return {"Authorization": f"Bearer {tok()}"}


def get_app_id(bundle_id):
    r = requests.get(f"https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={bundle_id}",
                     headers=H(), timeout=30, verify=False)
    return r.json()["data"][0]["id"]


def latest_build_for_version(app_id):
    """Return (state, build_id) of the newest VERSION build, or None."""
    url = (f"https://api.appstoreconnect.apple.com/v1/builds?"
           f"filter[app]={app_id}&filter[preReleaseVersion.version]={VERSION}"
           f"&sort=-uploadedDate&limit=1")
    r = requests.get(url, headers=H(), timeout=30, verify=False).json()
    if not r.get("data"):
        return None, None
    b = r["data"][0]
    return b["attributes"]["processingState"], b["id"]


def main():
    app_ids = {sku: get_app_id(bid) for sku, bid in APPS}
    print(f"Polling 16 apps for {VERSION} build processing...")
    while True:
        states = {}
        all_valid = True
        for sku, _ in APPS:
            state, _ = latest_build_for_version(app_ids[sku])
            states[sku] = state or "MISSING"
            if state != "VALID":
                all_valid = False
        # Print compact status line
        sym = {"VALID": "✓", "PROCESSING": "·", "INVALID": "✗", "MISSING": "?"}
        line = " ".join(f"{sku[:4]}={sym.get(s, '?')}" for sku, s in states.items())
        print(f"[{time.strftime('%H:%M:%S')}] {line}")
        if all_valid:
            print("\n🎉 All 16 builds are VALID and ready for submission.")
            return 0
        time.sleep(60)


if __name__ == "__main__":
    raise SystemExit(main())
