#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Create the "Remove Ads" in-app products in App Store Connect via the API,
driving each to **Ready to Submit** without touching the ASC web UI.

Two products per app, in a "Tactics Board Pro" subscription group:
  * <prefix>remove_ads_lifetime  — NON_CONSUMABLE
  * <prefix>remove_ads_yearly    — auto-renewable subscription
Product IDs are GLOBALLY UNIQUE per developer account (and a deleted id is
reserved forever), so each app gets its own — see product_ids(). Hub = 2x the
single-sport price (see usd_prices()).

Reaching "Ready to Submit" needs, for EACH product: an en-US localization, a
price, availability in all territories, and an App Store review screenshot.

Hard-won API gotchas (all verified 2026-06-08 against com.zach.tacticsBoard):
  * Availability relationship is `inAppPurchase` / `subscription` (NOT the
    `...V2` name used by the localization relationship).
  * A subscription's FIRST ("starting") price must OMIT the startDate key
    (sending null fails on the price point; sending a date is treated as a
    future change and is rejected until a starting price exists) AND include a
    `territory` relationship alongside `subscriptionPricePoint`.
  * Subscriptions are NOT auto-equalized by the API: every available territory
    needs its own price. Use GET /subscriptionPricePoints/{base}/equalizations
    to get each territory's equivalent point, then POST one price per territory.
    (Non-consumables DO auto-equalize from baseTerritory via a price schedule.)
  * After everything is set, the subscription's top-level `state` can lag on
    MISSING_METADATA for a while even though all sub-objects are ready — Apple
    recomputes it asynchronously.

Usage:
  python3 tool/asc_iap.py status <bundleId>     # print both products' state
  python3 tool/asc_iap.py create <bundleId>     # create/complete both products
e.g. python3 tool/asc_iap.py create com.zach.tacticsBoard
"""
import jwt, time, requests, warnings, json, sys, hashlib, os
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8"
B = "https://api.appstoreconnect.apple.com"
SHOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "iap_review_screenshot.png")

GROUP_NAME = "Tactics Board Pro"

# The multi-sport hub bundles every sport, so it's priced at 2x a single-sport
# app. (USD base; Apple equalizes other territories.)
HUB_BUNDLE = "com.zach.tacticsBoard"


def usd_prices(bundle):
    """(lifetime, yearly) USD base prices for this app."""
    return ("13.99", "5.99") if bundle == HUB_BUNDLE else ("6.99", "2.99")


def product_ids(bundle):
    """(lifetime, yearly) App Store product IDs for this app. Product IDs are
    globally unique per developer account AND a deleted id is reserved forever,
    so every app needs its own. The hub keeps the original bare ids ('annual'
    because 'remove_ads_yearly' was burned by a delete); single-sport apps
    prefix the sport. Keep in sync with PurchaseService lifetimeId/yearlyId."""
    if bundle == HUB_BUNDLE:
        return ("remove_ads_lifetime", "remove_ads_annual")
    sport = bundle.removeprefix("com.zach.").removesuffix("Board").lower()
    return (f"{sport}_remove_ads_lifetime", f"{sport}_remove_ads_yearly")

PK = open(KEY_FILE).read()


def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200,
                       "aud": "appstoreconnect-v1"}, PK, algorithm="ES256", headers={"kid": KEY_ID})


def H(j=True):
    h = {"Authorization": f"Bearer {tok()}"}
    if j:
        h["Content-Type"] = "application/json"
    return h


def _do(method, url, **kw):
    # Retry transient network/SSL errors so a flaky connection doesn't abort a
    # long multi-app run mid-flight.
    for i in range(5):
        try:
            return requests.request(method, url, headers=H(), verify=False, timeout=60, **kw)
        except requests.exceptions.RequestException:
            if i == 4:
                raise
            time.sleep(3 + i * 3)


def G(u):
    return _do("GET", u if u.startswith("http") else B + u)


def P(path, body):
    return _do("POST", B + path, data=json.dumps(body))


def PATCH(path, body):
    return _do("PATCH", B + path, data=json.dumps(body))


def errs(r):
    try:
        return json.dumps(r.json().get("errors", []))[:260]
    except Exception:
        return r.text[:160]


def app_id(bundle):
    d = G(f"/v1/apps?filter[bundleId]={bundle}").json().get("data", [])
    return d[0]["id"] if d else None


def all_territories():
    terrs, url = [], B + "/v1/territories?limit=200"
    while url:
        j = G(url).json()
        terrs += [t["id"] for t in j.get("data", [])]
        url = j.get("links", {}).get("next")
    return terrs


def screenshot_ok(existing):
    """True if an existing review screenshot is fully delivered. A reserve that
    never got its bytes (e.g. the upload 500'd) sits in AWAITING_UPLOAD and must
    be deleted + re-uploaded, not skipped."""
    if not existing:
        return False
    state = (existing["attributes"].get("assetDeliveryState") or {}).get("state")
    return state == "COMPLETE"


def upload_screenshot(reserve_type, rel_name, parent_id, stale_id=None):
    if stale_id:  # clear a half-uploaded reservation first
        _do("DELETE", B + f"/v1/{reserve_type}/{stale_id}")
    b = open(SHOT, "rb").read()
    md5 = hashlib.md5(b).hexdigest()
    parent_type = "subscriptions" if rel_name == "subscription" else "inAppPurchases"
    r = P(f"/v1/{reserve_type}", {"data": {"type": reserve_type,
          "attributes": {"fileName": "iap_review.png", "fileSize": len(b)},
          "relationships": {rel_name: {"data": {"type": parent_type, "id": parent_id}}}}})
    if not r.ok:
        print("   screenshot reserve ERR", errs(r)); return
    d = r.json()["data"]; sid = d["id"]
    for op in d["attributes"]["uploadOperations"]:
        hdrs = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        requests.request(op["method"], op["url"], headers=hdrs,
                         data=b[op["offset"]:op["offset"] + op["length"]], verify=False, timeout=120)
    rc = PATCH(f"/v1/{reserve_type}/{sid}", {"data": {"type": reserve_type, "id": sid,
              "attributes": {"uploaded": True, "sourceFileChecksum": md5}}})
    print("   screenshot:", "OK" if rc.ok else errs(rc))


# ── Non-consumable (auto-equalizes price from USA via a price schedule) ──────
def create_lifetime(aid, usd, pid):
    ex = G(f"/v1/apps/{aid}/inAppPurchasesV2?filter[productId]={pid}&limit=1").json().get("data")
    if ex:
        iid = ex[0]["id"]; print(f"  lifetime exists id={iid} state={ex[0]['attributes']['state']}")
    else:
        r = P("/v2/inAppPurchases", {"data": {"type": "inAppPurchases", "attributes": {
            "name": "Remove Ads (Lifetime)", "productId": pid, "inAppPurchaseType": "NON_CONSUMABLE",
            "reviewNote": "One-time purchase that permanently removes all ads in the app."},
            "relationships": {"app": {"data": {"type": "apps", "id": aid}}}}})
        if not r.ok:
            print("  lifetime create ERR", errs(r)); return None
        iid = r.json()["data"]["id"]; print("  lifetime created id=", iid)
    # NB: the localizations READ path is /v2/ (the /v1/ one 404s, which reads as
    # "no localizations" and causes harmless-but-noisy duplicate POSTs).
    if not G(f"/v2/inAppPurchases/{iid}/inAppPurchaseLocalizations").json().get("data"):
        r = P("/v1/inAppPurchaseLocalizations", {"data": {"type": "inAppPurchaseLocalizations", "attributes": {
            "name": "Remove Ads", "locale": "en-US", "description": "Remove all ads permanently."},
            "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iid}}}}})
        if not r.ok:
            print("   localization ERR", errs(r))
    if G(f"/v2/inAppPurchases/{iid}/iapPriceSchedule").json().get("data") in (None, {}):
        pp = next((p["id"] for p in G(f"/v2/inAppPurchases/{iid}/pricePoints?filter[territory]=USA&limit=200").json()["data"]
                   if p["attributes"].get("customerPrice") == usd), None)
        P("/v1/inAppPurchasePriceSchedules", {"data": {"type": "inAppPurchasePriceSchedules", "relationships": {
            "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iid}},
            "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
            "manualPrices": {"data": [{"type": "inAppPurchasePrices", "id": "${p1}"}]}}},
            "included": [{"type": "inAppPurchasePrices", "id": "${p1}", "attributes": {"startDate": None},
            "relationships": {"inAppPurchasePricePoint": {"data": {"type": "inAppPurchasePricePoints", "id": pp}}}}]})
    if G(f"/v2/inAppPurchases/{iid}/inAppPurchaseAvailability").status_code == 404:
        P("/v1/inAppPurchaseAvailabilities", {"data": {"type": "inAppPurchaseAvailabilities",
            "attributes": {"availableInNewTerritories": True}, "relationships": {
            "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iid}},
            "availableTerritories": {"data": [{"type": "territories", "id": t} for t in all_territories()]}}}})
    shot = G(f"/v2/inAppPurchases/{iid}/appStoreReviewScreenshot").json().get("data")
    if not screenshot_ok(shot):
        upload_screenshot("inAppPurchaseAppStoreReviewScreenshots", "inAppPurchaseV2", iid,
                          stale_id=shot["id"] if shot else None)
    return iid


# ── Auto-renewable subscription (price must be set per territory) ────────────
def create_yearly(aid, usd, pid):
    grp = next((g for g in G(f"/v1/apps/{aid}/subscriptionGroups?limit=20").json().get("data", [])
                if g["attributes"]["referenceName"] == GROUP_NAME), None)
    gid = grp["id"] if grp else P("/v1/subscriptionGroups", {"data": {"type": "subscriptionGroups",
        "attributes": {"referenceName": GROUP_NAME},
        "relationships": {"app": {"data": {"type": "apps", "id": aid}}}}}).json()["data"]["id"]
    if not G(f"/v1/subscriptionGroups/{gid}/subscriptionGroupLocalizations").json().get("data"):
        P("/v1/subscriptionGroupLocalizations", {"data": {"type": "subscriptionGroupLocalizations",
            "attributes": {"name": GROUP_NAME, "locale": "en-US"},
            "relationships": {"subscriptionGroup": {"data": {"type": "subscriptionGroups", "id": gid}}}}})
    sub = G(f"/v1/subscriptionGroups/{gid}/subscriptions?filter[productId]={pid}&limit=5").json().get("data")
    if sub:
        sid = sub[0]["id"]; print(f"  yearly exists id={sid} state={sub[0]['attributes']['state']}")
    else:
        r = P("/v1/subscriptions", {"data": {"type": "subscriptions", "attributes": {
            "name": "Remove Ads (Yearly)", "productId": pid, "subscriptionPeriod": "ONE_YEAR",
            "familySharable": False, "reviewNote": "Auto-renewable subscription that removes all ads."},
            "relationships": {"group": {"data": {"type": "subscriptionGroups", "id": gid}}}}})
        if not r.ok:
            print("  yearly create ERR", errs(r)); return None
        sid = r.json()["data"]["id"]; print("  yearly created id=", sid)
    if not G(f"/v1/subscriptions/{sid}/subscriptionLocalizations").json().get("data"):
        r = P("/v1/subscriptionLocalizations", {"data": {"type": "subscriptionLocalizations", "attributes": {
            "name": "Remove Ads (Yearly)", "description": "Remove all ads, billed yearly.", "locale": "en-US"},
            "relationships": {"subscription": {"data": {"type": "subscriptions", "id": sid}}}}})
        if not r.ok:
            print("   sub localization ERR", errs(r))
    # Availability MUST be set BEFORE pricing — a subscription with no available
    # territories rejects every price POST with RELATIONSHIP.INVALID / "processing
    # pricing information" (SUBSCRIPTION_SETUP_GUIDE.md §1.4). Non-consumables don't
    # care about order; subscriptions do.
    if G(f"/v1/subscriptions/{sid}/subscriptionAvailability").status_code == 404:
        P("/v1/subscriptionAvailabilities", {"data": {"type": "subscriptionAvailabilities",
            "attributes": {"availableInNewTerritories": True}, "relationships": {
            "subscription": {"data": {"type": "subscriptions", "id": sid}},
            "availableTerritories": {"data": [{"type": "territories", "id": t} for t in all_territories()]}}}})
    if not G(f"/v1/subscriptions/{sid}/prices?limit=1").json().get("data"):
        def set_price(pp, terr):
            # Starting price: OMIT startDate; include territory + price point.
            return P("/v1/subscriptionPrices", {"data": {"type": "subscriptionPrices",
                "attributes": {"preserveCurrentPrice": False},
                "relationships": {"subscription": {"data": {"type": "subscriptions", "id": sid}},
                "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": pp}},
                "territory": {"data": {"type": "territories", "id": terr}}}}})

        # A just-created subscription's price points can lag a few seconds, so
        # retry the USA base price until it actually sticks.
        base = None
        for _ in range(18):  # a fresh subscription's price points can lag a couple minutes
            base = next((p["id"] for p in G(f"/v1/subscriptions/{sid}/pricePoints?filter[territory]=USA&limit=200").json().get("data", [])
                         if p["attributes"].get("customerPrice") == usd), None)
            if base and set_price(base, "USA").ok:
                break
            base = None
            time.sleep(10)
        if not base:
            print("   ERR: could not set USA base price"); return sid
        eq, url = [], B + f"/v1/subscriptionPricePoints/{base}/equalizations?include=territory&limit=200"
        while url:
            j = G(url).json()
            eq += [(p["relationships"]["territory"]["data"]["id"], p["id"]) for p in j.get("data", [])]
            url = j.get("links", {}).get("next")
        ok = sum(1 for terr, pp in eq if terr != "USA" and set_price(pp, terr).ok)
        print(f"   priced USA + {ok}/{len([e for e in eq if e[0] != 'USA'])} equalized territories")
    sshot = G(f"/v1/subscriptions/{sid}/appStoreReviewScreenshot").json().get("data")
    if not screenshot_ok(sshot):
        upload_screenshot("subscriptionAppStoreReviewScreenshots", "subscription", sid,
                          stale_id=sshot["id"] if sshot else None)
    # Nudge: a fresh subscription stays stuck on MISSING_METADATA even with every
    # field set, until a metadata PATCH re-triggers Apple's async recompute.
    PATCH(f"/v1/subscriptions/{sid}", {"data": {"type": "subscriptions", "id": sid,
        "attributes": {"reviewNote": "Auto-renewable yearly subscription that removes all ads while active."}}})
    return sid


def status(aid, life_id, year_id):
    li = G(f"/v1/apps/{aid}/inAppPurchasesV2?filter[productId]={life_id}&limit=1").json().get("data")
    print("  lifetime:", li[0]["attributes"]["state"] if li else "MISSING")
    for g in G(f"/v1/apps/{aid}/subscriptionGroups?limit=20").json().get("data", []):
        su = G(f"/v1/subscriptionGroups/{g['id']}/subscriptions?filter[productId]={year_id}&limit=1").json().get("data")
        if su:
            print("  yearly:  ", su[0]["attributes"]["state"]); return
    print("  yearly:   MISSING")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit("usage: asc_iap.py {create|status} <bundleId>")
    cmd, bundle = sys.argv[1], sys.argv[2]
    aid = app_id(bundle)
    if not aid:
        sys.exit(f"app not found for {bundle}")
    print(f"{bundle} -> app {aid}")
    if cmd == "status":
        life_id, year_id = product_ids(bundle)
        status(aid, life_id, year_id)
    elif cmd == "create":
        life_usd, year_usd = usd_prices(bundle)
        life_id, year_id = product_ids(bundle)
        create_lifetime(aid, life_usd, life_id)
        create_yearly(aid, year_usd, year_id)
        time.sleep(5)
        status(aid, life_id, year_id)
    elif cmd == "lifetime":
        # Non-consumable only — does NOT touch subscription pricing (useful while
        # ASC's subscription-price endpoint is failing).
        life_usd, _ = usd_prices(bundle)
        life_id, year_id = product_ids(bundle)
        create_lifetime(aid, life_usd, life_id)
        time.sleep(3)
        status(aid, life_id, year_id)
