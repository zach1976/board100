#!/usr/bin/env python3 -u
"""Scan all 16 apps: latest version, store state, price, available territory count.
Usage: python3 tool/check_app_status.py
"""
import jwt, time, requests, warnings
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8"

ALL_APPS = [
    ("tactics_board", "com.zach.tacticsBoard"),
    ("soccer",       "com.zach.soccerBoard"),
    ("basketball",   "com.zach.basketballBoard"),
    ("volleyball",   "com.zach.volleyballBoard"),
    ("tennis",       "com.zach.tennisBoard"),
    ("badminton",    "com.zach.badmintonBoard"),
    ("tableTennis",  "com.zach.tableTennisBoard"),
    ("pickleball",   "com.zach.pickleballBoard"),
    ("fieldHockey",  "com.zach.fieldHockeyBoard"),
    ("rugby",        "com.zach.rugbyBoard"),
    ("baseball",     "com.zach.baseballBoard"),
    ("handball",     "com.zach.handballBoard"),
    ("waterPolo",    "com.zach.waterPoloBoard"),
    ("sepakTakraw",  "com.zach.sepakTakrawBoard"),
    ("beachTennis",  "com.zach.beachTennisBoard"),
    ("footvolley",   "com.zach.footvolleyBoard"),
]

with open(KEY_FILE) as f:
    pk = f.read()

def tok():
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": int(time.time()), "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"},
        pk, algorithm="ES256", headers={"kid": KEY_ID})

def H():
    return {"Authorization": f"Bearer {tok()}"}

B = "https://api.appstoreconnect.apple.com"

def G(url):
    for i in range(5):
        try:
            return requests.get(url, headers=H(), verify=False, timeout=60)
        except Exception:
            if i == 4:
                raise
            time.sleep(2 + i * 2)

print(f"{'sport':<14} {'app_id':<12} {'ver':<8} {'state':<28} {'price$':<8} {'territs':<8} {'newTerrs'}")
print("-" * 90)
for sport, bid in ALL_APPS:
    r = G(f"{B}/v1/apps?filter[bundleId]={bid}").json()
    if not r.get("data"):
        print(f"{sport:<14} (not found)")
        continue
    aid = r["data"][0]["id"]

    vj = G(f"{B}/v1/apps/{aid}/appStoreVersions?limit=3").json()
    ver_str, state = "-", "-"
    if vj.get("data"):
        v = vj["data"][0]["attributes"]
        ver_str = v.get("versionString", "-")
        state = v.get("appStoreState", "-")

    pr = G(f"{B}/v1/appPriceSchedules/{aid}/manualPrices?include=appPricePoint&limit=5")
    price_str = "?"
    if pr.status_code == 200:
        pj = pr.json()
        pts = [x for x in pj.get("included", []) if x["type"] == "appPricePoints"]
        price_str = pts[0]["attributes"].get("customerPrice", "?") if pts else "(none)"
    else:
        price_str = f"E{pr.status_code}"

    # paginate to count all available territories
    url = f"{B}/v2/appAvailabilities/{aid}/territoryAvailabilities?limit=200"
    total_avail = 0
    while url:
        r = G(url).json()
        total_avail += sum(1 for x in r.get("data", []) if x["attributes"].get("available"))
        url = r.get("links", {}).get("next")

    av = G(f"{B}/v2/appAvailabilities/{aid}").json()
    new_str = str(av.get("data", {}).get("attributes", {}).get("availableInNewTerritories", "?"))

    print(f"{sport:<14} {aid:<12} {ver_str:<8} {state:<28} {price_str:<8} {total_avail:<8} {new_str}")
