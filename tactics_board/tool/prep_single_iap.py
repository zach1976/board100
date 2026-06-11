#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Prep the 15 single-sport iOS apps' v1.1.17 for review WITH their lifetime
Remove-Ads IAP — everything the API can do, stopping before submission.

Per app: find/create the appStoreVersion -> attach the processed build -> set
usesNonExemptEncryption=false -> set whatsNew on all localizations. The final
two steps are Console-only (the first IAP per app must ride with a version, and
the API can't attach IAPs to versions): open each app's version page, scroll to
"In-App Purchases and Subscriptions" -> Select -> add "Remove Ads (Lifetime)"
-> Done -> Submit for Review.

Strategy note: we ship LIFETIME-ONLY for single-sport apps while ASC's
subscription-pricing endpoint is broken (409 since 2026-06-09). The paywall
handles a missing yearly gracefully, and once each app's first IAP is approved
the yearly can be submitted later via the API without a new app version.

Usage:
  python3 tool/prep_single_iap.py            # all 15
  python3 tool/prep_single_iap.py soccer tennis
"""
import jwt, time, requests, warnings, sys
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
PK = open("/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8").read()
B = "https://api.appstoreconnect.apple.com"
VERSION = "1.1.17"
WHATS_NEW = ("• New: remove ads with a one-time purchase\n"
             "• Stability improvements")
SPORTS = ["soccer", "basketball", "volleyball", "badminton", "tennis",
          "tableTennis", "pickleball", "fieldHockey", "rugby", "baseball",
          "handball", "waterPolo", "beachTennis", "footvolley", "sepakTakraw"]


def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200,
                       "aud": "appstoreconnect-v1"}, PK, algorithm="ES256", headers={"kid": KEY_ID})


def api(method, path, data=None):
    h = {"Authorization": f"Bearer {tok()}", "Content-Type": "application/json"}
    for i in range(4):
        try:
            r = requests.request(method, B + path, headers=h, json=data, verify=False, timeout=60)
            break
        except requests.exceptions.RequestException:
            if i == 3:
                raise
            time.sleep(3 + i * 3)
    if r.status_code >= 400:
        return {"_err": r.status_code, "_body": r.json() if r.text else {}}
    return r.json() if r.text else {"_ok": True}


def detail(res):
    errs = res.get("_body", {}).get("errors", [])
    return "; ".join(dict.fromkeys(e.get("detail", e.get("title", "?")) for e in errs)) or str(res.get("_err"))


def prep(sport):
    bundle = f"com.zach.{sport}Board"
    r = api("GET", f"/v1/apps?filter[bundleId]={bundle}")
    if not r.get("data"):
        print(f"  {sport}: APP NOT FOUND"); return False
    aid = r["data"][0]["id"]

    # build must be processed first
    rb = api("GET", f"/v1/builds?filter[app]={aid}&filter[preReleaseVersion.version]={VERSION}&sort=-uploadedDate&limit=1")
    if not rb.get("data") or rb["data"][0]["attributes"].get("processingState") != "VALID":
        st = rb["data"][0]["attributes"].get("processingState") if rb.get("data") else "NO BUILD"
        print(f"  {sport}: build not ready ({st})"); return False
    bid = rb["data"][0]["id"]

    rv = api("GET", f"/v1/apps/{aid}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION")
    if rv.get("data"):
        vid = rv["data"][0]["id"]
    else:
        rv = api("POST", "/v1/appStoreVersions", {"data": {"type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": aid}}}}})
        if rv.get("_err"):
            print(f"  {sport}: create version ERR {detail(rv)}"); return False
        vid = rv["data"]["id"]

    api("PATCH", f"/v1/appStoreVersions/{vid}/relationships/build", {"data": {"type": "builds", "id": bid}})
    api("PATCH", f"/v1/builds/{bid}", {"data": {"type": "builds", "id": bid,
        "attributes": {"usesNonExemptEncryption": False}}})
    for loc in api("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations").get("data", []):
        api("PATCH", f"/v1/appStoreVersionLocalizations/{loc['id']}", {"data": {
            "type": "appStoreVersionLocalizations", "id": loc["id"],
            "attributes": {"whatsNew": WHATS_NEW}}})
    print(f"  {sport}: version {VERSION} prepped (build attached, whatsNew set)")
    return True


if __name__ == "__main__":
    wanted = sys.argv[1:] or SPORTS
    ok = sum(1 for s in wanted if prep(s))
    print(f"\n{ok}/{len(wanted)} prepped.")
    if ok:
        print("Console steps per app: version page -> In-App Purchases and "
              "Subscriptions -> Select -> add 'Remove Ads (Lifetime)' -> Done "
              "-> Submit for Review.")
