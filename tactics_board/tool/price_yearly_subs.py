#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Price the single-sport yearly Remove-Ads subscriptions — in the CORRECT order.

Root cause of the 6-day "409 pricing outage": asc_iap.create_yearly set the price
BEFORE setting subscriptionAvailabilities, and returned early when pricing 409'd —
so availability was never set, so pricing kept 409'ing. Subscriptions (unlike
non-consumables) REQUIRE available territories to exist *before* any price POST
(SUBSCRIPTION_SETUP_GUIDE.md §1.4). Order that works:

  availability (all territories) -> USA base price -> equalize 174 others
  -> PATCH a localization to trigger the MISSING_METADATA -> READY_TO_SUBMIT recompute

Idempotent: skips availability if present, skips territories already priced.

  python3 tool/price_yearly_subs.py            # all 15 singles @ $2.99
  python3 tool/price_yearly_subs.py soccer tennis
"""
import jwt, time, requests, warnings, sys, os, hashlib
from concurrent.futures import ThreadPoolExecutor
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
PK = open("/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8").read()
B = "https://api.appstoreconnect.apple.com"
SHOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "iap_review_screenshot.png")
USD = "2.99"   # single-sport yearly
SPORTS = ["soccer", "basketball", "volleyball", "badminton", "tennis",
          "tableTennis", "pickleball", "fieldHockey", "rugby", "baseball",
          "handball", "waterPolo", "beachTennis", "footvolley", "sepakTakraw"]


def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200,
                       "aud": "appstoreconnect-v1"}, PK, algorithm="ES256", headers={"kid": KEY_ID})


def H():
    return {"Authorization": f"Bearer {tok()}", "Content-Type": "application/json"}


def G(p):
    return requests.get(B + p, headers={"Authorization": f"Bearer {tok()}"}, verify=False, timeout=60).json()


def Graw(p):
    return requests.get(B + p, headers={"Authorization": f"Bearer {tok()}"}, verify=False, timeout=60)


def P(p, b):
    return requests.post(B + p, headers=H(), json=b, verify=False, timeout=60)


def PATCH(p, b):
    return requests.patch(B + p, headers=H(), json=b, verify=False, timeout=60)


def all_territories():
    terrs, url = [], "/v1/territories?limit=200"
    while url:
        j = G(url)
        terrs += [t["id"] for t in j.get("data", [])]
        nxt = j.get("links", {}).get("next")
        url = nxt.replace(B, "") if nxt else None
    return terrs


def set_price(sid, pp, terr):
    return P("/v1/subscriptionPrices", {"data": {"type": "subscriptionPrices",
        "attributes": {"preserveCurrentPrice": False},
        "relationships": {"subscription": {"data": {"type": "subscriptions", "id": sid}},
        "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": pp}},
        "territory": {"data": {"type": "territories", "id": terr}}}}})


def screenshot_ok(existing):
    if not existing:
        return False
    return (existing["attributes"].get("assetDeliveryState") or {}).get("state") == "COMPLETE"


def upload_screenshot(sid, stale_id=None):
    if stale_id:
        requests.delete(B + f"/v1/subscriptionAppStoreReviewScreenshots/{stale_id}",
                        headers={"Authorization": f"Bearer {tok()}"}, verify=False, timeout=60)
    b = open(SHOT, "rb").read()
    md5 = hashlib.md5(b).hexdigest()
    r = P("/v1/subscriptionAppStoreReviewScreenshots", {"data": {
        "type": "subscriptionAppStoreReviewScreenshots",
        "attributes": {"fileName": "iap_review.png", "fileSize": len(b)},
        "relationships": {"subscription": {"data": {"type": "subscriptions", "id": sid}}}}})
    if not r.ok:
        return False
    d = r.json()["data"]; ssid = d["id"]
    for op in d["attributes"]["uploadOperations"]:
        hdrs = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        requests.request(op["method"], op["url"], headers=hdrs,
                         data=b[op["offset"]:op["offset"] + op["length"]], verify=False, timeout=120)
    rc = PATCH(f"/v1/subscriptionAppStoreReviewScreenshots/{ssid}", {"data": {
        "type": "subscriptionAppStoreReviewScreenshots", "id": ssid,
        "attributes": {"uploaded": True, "sourceFileChecksum": md5}}})
    return rc.ok


def find_sub(sport):
    aid = G(f"/v1/apps?filter[bundleId]=com.zach.{sport}Board")["data"][0]["id"]
    pid = f"{sport.lower()}_remove_ads_yearly"
    for g in G(f"/v1/apps/{aid}/subscriptionGroups?limit=20").get("data", []):
        su = G(f"/v1/subscriptionGroups/{g['id']}/subscriptions?filter[productId]={pid}&limit=1").get("data")
        if su:
            return su[0]["id"], su[0]["attributes"]["state"]
    return None, None


def price(sport):
    sid, st = find_sub(sport)
    if not sid:
        print(f"{sport:14s} NO yearly subscription"); return
    # 1) availability FIRST (skip if already set)
    if Graw(f"/v1/subscriptions/{sid}/subscriptionAvailability").status_code == 404:
        terrs = all_territories()
        r = P("/v1/subscriptionAvailabilities", {"data": {"type": "subscriptionAvailabilities",
            "attributes": {"availableInNewTerritories": True}, "relationships": {
            "subscription": {"data": {"type": "subscriptions", "id": sid}},
            "availableTerritories": {"data": [{"type": "territories", "id": t} for t in terrs]}}}})
        if not r.ok:
            print(f"{sport:14s} availability ERR {r.status_code} {r.text[:160]}"); return
    # 2) USA base price (retry — fresh price points can lag)
    already = {p["relationships"]["territory"]["data"]["id"]
               for p in G(f"/v1/subscriptions/{sid}/prices?include=territory&limit=200").get("data", [])
               if p.get("relationships", {}).get("territory", {}).get("data")}
    base = None
    if "USA" not in already:
        for _ in range(18):
            base = next((p["id"] for p in G(f"/v1/subscriptions/{sid}/pricePoints?filter[territory]=USA&limit=200").get("data", [])
                         if p["attributes"].get("customerPrice") == USD), None)
            if base and set_price(sid, base, "USA").ok:
                break
            base = None; time.sleep(8)
        if not base:
            print(f"{sport:14s} could not set USA base price"); return
    # 3) equalize the rest
    if not base:
        base = next((p["id"] for p in G(f"/v1/subscriptions/{sid}/pricePoints?filter[territory]=USA&limit=200").get("data", [])
                     if p["attributes"].get("customerPrice") == USD), None)
    eq, url = [], f"/v1/subscriptionPricePoints/{base}/equalizations?include=territory&limit=200"
    while url:
        j = G(url)
        eq += [(p["relationships"]["territory"]["data"]["id"], p["id"]) for p in j.get("data", [])]
        nxt = j.get("links", {}).get("next")
        url = nxt.replace(B, "") if nxt else None
    todo = [(t, pp) for t, pp in eq if t != "USA" and t not in already]
    ok = 0
    with ThreadPoolExecutor(max_workers=6) as ex:
        for r in ex.map(lambda tp: set_price(sid, tp[1], tp[0]), todo):
            ok += 1 if r.ok else 0
    # 3b) fill any gaps (a concurrent batch occasionally drops 1)
    priced = {p["relationships"]["territory"]["data"]["id"]
              for p in G(f"/v1/subscriptions/{sid}/prices?include=territory&limit=200").get("data", [])
              if p.get("relationships", {}).get("territory", {}).get("data")}
    for t, pp in eq:
        if t not in priced:
            set_price(sid, pp, t)
    # 3c) review screenshot (required for READY — a reserve stuck in AWAITING_UPLOAD is re-done)
    sc = G(f"/v1/subscriptions/{sid}/appStoreReviewScreenshot").get("data")
    if not screenshot_ok(sc):
        upload_screenshot(sid, stale_id=sc["id"] if sc else None)
    # 4) trigger recompute by PATCHing a localization
    locs = G(f"/v1/subscriptions/{sid}/subscriptionLocalizations").get("data", [])
    if locs:
        lid = locs[0]["id"]
        PATCH(f"/v1/subscriptionLocalizations/{lid}", {"data": {"type": "subscriptionLocalizations",
            "id": lid, "attributes": {"description": locs[0]["attributes"].get("description", "Remove all ads, billed yearly.")}}})
    time.sleep(8)
    _, st2 = find_sub(sport)
    print(f"{sport:14s} priced {len(todo)+1} terr (eq ok {ok}) -> state={st2}")


if __name__ == "__main__":
    for s in (sys.argv[1:] or SPORTS):
        price(s)
