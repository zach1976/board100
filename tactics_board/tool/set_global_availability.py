#!/usr/bin/env python3 -u
"""Make all 16 apps available in all 175 territories (App Store).

How it works:
  - Per (app, territory), compute base64(`{"s":AID,"t":TERR}`) as the territoryAvailability id
  - PATCH /v1/territoryAvailabilities/{tid} with `available: true`
  - This works for both existing and new entries, and lazily initializes the appAvailability resource

Notes:
  - 16 apps × 175 territories = 2800 PATCHes; runs ~5–10 min via 16-thread pool
  - Cannot toggle `availableInNewTerritories` post-creation via API (Apple FORBIDDEN_ERROR);
    do that in App Store Connect UI per app under Pricing & Availability.

Usage: python3 tool/set_global_availability.py
"""
import jwt, time, requests, warnings, base64, json
from concurrent.futures import ThreadPoolExecutor, as_completed
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8"
with open(KEY_FILE) as f:
    pk = f.read()

def tok():
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": int(time.time()), "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"},
        pk, algorithm="ES256", headers={"kid": KEY_ID})

def H():
    return {"Authorization": f"Bearer {tok()}", "Content-Type": "application/json"}

B = "https://api.appstoreconnect.apple.com"

ALL_APPS = [
    ("tactics_board", "6761408675"),
    ("soccer",        "6761409085"),
    ("basketball",    "6761409275"),
    ("volleyball",    "6761409137"),
    ("tennis",        "6761409239"),
    ("badminton",     "6761408995"),
    ("tableTennis",   "6761408930"),
    ("pickleball",    "6761409193"),
    ("fieldHockey",   "6763574203"),
    ("rugby",         "6763574953"),
    ("baseball",      "6763575410"),
    ("handball",      "6763575477"),
    ("waterPolo",     "6763575857"),
    ("sepakTakraw",   "6763575936"),
    ("beachTennis",   "6763576493"),
    ("footvolley",    "6763576836"),
]

r = requests.get(f"{B}/v1/territories?limit=200", headers=H(), verify=False, timeout=60).json()
TERRS = sorted([x["id"] for x in r["data"]])
print(f"territories: {len(TERRS)}")

def tid_for(aid, t):
    raw = json.dumps({"s": aid, "t": t}, separators=(",", ":")).encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")

def patch_avail(aid, t):
    tid = tid_for(aid, t)
    body = {"data": {"type": "territoryAvailabilities", "id": tid, "attributes": {"available": True}}}
    for attempt in range(4):
        try:
            r = requests.patch(f"{B}/v1/territoryAvailabilities/{tid}", headers=H(),
                               verify=False, timeout=60, json=body)
            if r.status_code == 200:
                return ("ok", t, None)
            if r.status_code == 429:
                time.sleep(8 + attempt * 4)
                continue
            return ("err", t, f"{r.status_code}: {r.text[:120]}")
        except Exception as e:
            if attempt == 3:
                return ("err", t, str(e))
            time.sleep(3 + attempt * 3)

def do_app(sport, aid):
    ok = err = 0
    err_samples = []
    for t in TERRS:
        status, terr, msg = patch_avail(aid, t)
        if status == "ok":
            ok += 1
        else:
            err += 1
            if len(err_samples) < 3:
                err_samples.append(f"{terr}:{msg}")
    return (sport, aid, ok, err, err_samples)

start = time.time()
print(f"\nStarting batch: {len(ALL_APPS)} apps × {len(TERRS)} territories = {len(ALL_APPS)*len(TERRS)} PATCHes\n")

with ThreadPoolExecutor(max_workers=16) as ex:
    futs = {ex.submit(do_app, sport, aid): sport for sport, aid in ALL_APPS}
    for f in as_completed(futs):
        sport, aid, ok, err, samples = f.result()
        marker = "✅" if err == 0 else "⚠"
        print(f"  {marker} {sport:<14} ok={ok} err={err}" + (f"  samples={samples}" if samples else ""))

print(f"\nelapsed: {time.time()-start:.0f}s")
