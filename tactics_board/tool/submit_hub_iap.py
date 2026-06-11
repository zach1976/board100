#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Submit the multi-sport hub iOS version FOR REVIEW together with its two
Remove-Ads in-app products (first IAP submission must ride with an app version).

Flow: find/create the v1.1.16 appStoreVersion -> attach the processed build ->
set usesNonExemptEncryption=false + whatsNew -> clear stale submissions ->
create a reviewSubmission -> add items (version + lifetime IAP + yearly
subscription) -> submit.

Run only after the 1.1.16 build shows processingState=VALID in ASC.

⚠️ KNOWN API LIMITATION (verified 2026-06-09): the FIRST non-consumable IAP /
subscription for an app CANNOT be submitted via the API — reviewSubmissionItems
rejects inAppPurchaseV2/subscription relationships, and inAppPurchaseSubmissions
/ subscriptionSubmissions return 409
STATE_ERROR.FIRST_NON_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION (Apple requires the
first IAP to ride atomically with an app-version submission, which only the
Console does). So this script prepares everything (version + build + whatsNew +
encryption) and adds the version item, but the final "submit version + IAPs
together" must be clicked in App Store Connect. After the first IAP is approved,
later IAPs CAN be submitted via inAppPurchaseSubmissions.
"""
import jwt, time, requests, warnings, sys
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
PK = open("/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8").read()
B = "https://api.appstoreconnect.apple.com"

APP_ID = "6761408675"          # com.zach.tacticsBoard
VERSION = "1.1.17"
LIFETIME_IAP_ID = "6778069876"  # remove_ads_lifetime
YEARLY_SUB_ID = "6778464630"    # remove_ads_annual
WHATS_NEW = ("• New: remove ads with a one-time purchase or yearly plan\n"
             "• Stability improvements")


def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200,
                       "aud": "appstoreconnect-v1"}, PK, algorithm="ES256", headers={"kid": KEY_ID})


def api(method, path, data=None):
    h = {"Authorization": f"Bearer {tok()}", "Content-Type": "application/json"}
    r = requests.request(method, B + path, headers=h, json=data, verify=False, timeout=60)
    if r.status_code >= 400:
        return {"_err": r.status_code, "_body": r.json() if r.text else {}}
    return r.json() if r.text else {"_ok": True}


def detail(res):
    errs = res.get("_body", {}).get("errors", [])
    out = []
    for e in errs:
        out.append(e.get("detail", e.get("title", "?")))
        for _, ae in (e.get("meta", {}).get("associatedErrors", {}) or {}).items():
            out += [a.get("detail", "?") for a in ae]
    return "; ".join(dict.fromkeys(out)) or str(res.get("_err"))


def main():
    # 1. version
    r = api("GET", f"/v1/apps/{APP_ID}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION")
    if r.get("data"):
        vid = r["data"][0]["id"]
        print("version exists", vid)
    else:
        r = api("POST", "/v1/appStoreVersions", {"data": {"type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}}})
        if r.get("_err"):
            sys.exit("create version: " + detail(r))
        vid = r["data"]["id"]
        print("version created", vid)

    # 2. attach build
    rb = api("GET", f"/v1/builds?filter[app]={APP_ID}&filter[preReleaseVersion.version]={VERSION}&sort=-uploadedDate&limit=1")
    if not rb.get("data"):
        sys.exit("no processed build for " + VERSION)
    bid = rb["data"][0]["id"]
    api("PATCH", f"/v1/appStoreVersions/{vid}/relationships/build", {"data": {"type": "builds", "id": bid}})
    print("build attached", bid)

    # 3. encryption + whatsNew
    api("PATCH", f"/v1/builds/{bid}", {"data": {"type": "builds", "id": bid,
        "attributes": {"usesNonExemptEncryption": False}}})
    for loc in api("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations").get("data", []):
        api("PATCH", f"/v1/appStoreVersionLocalizations/{loc['id']}", {"data": {
            "type": "appStoreVersionLocalizations", "id": loc["id"],
            "attributes": {"whatsNew": WHATS_NEW}}})
    print("prepared (encryption + whatsNew)")

    if "prep" in sys.argv:
        print("PREP-ONLY done. Now in App Store Connect: open the version, "
              "In-App Purchases and Subscriptions -> Select -> add both Remove "
              "Ads products, then Submit for Review.")
        return

    # 4. clear stale submissions
    for sub in api("GET", f"/v1/apps/{APP_ID}/reviewSubmissions").get("data", []):
        if sub["attributes"]["state"] in ("READY_FOR_REVIEW",):
            api("DELETE", f"/v1/reviewSubmissions/{sub['id']}")
    time.sleep(2)

    # 5. create review submission
    r = api("POST", "/v1/reviewSubmissions", {"data": {"type": "reviewSubmissions",
        "attributes": {"platform": "IOS"},
        "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}}})
    if r.get("_err"):
        sys.exit("create submission: " + detail(r))
    sid = r["data"]["id"]
    print("reviewSubmission", sid)

    # 6. items: version + IAP + subscription. The relationship KEY and the
    #    resource TYPE differ (e.g. key appStoreVersion -> type appStoreVersions).
    def add_item(relkey, dtype, rid, label):
        r = api("POST", "/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sid}},
                relkey: {"data": {"type": dtype, "id": rid}}}}})
        print(f"  item {label} ({relkey}):", "ok" if not r.get("_err") else "ERR " + detail(r))
        return not r.get("_err")

    ok = True
    ok &= add_item("appStoreVersion", "appStoreVersions", vid, "version")
    ok &= add_item("inAppPurchaseV2", "inAppPurchases", LIFETIME_IAP_ID, "lifetime")
    ok &= add_item("subscription", "subscriptions", YEARLY_SUB_ID, "yearly")
    if not ok:
        sys.exit("an item failed to attach — NOT submitting (reviewSubmission "
                 f"{sid} left as draft to fix/retry)")

    # 7. submit
    r = api("PATCH", f"/v1/reviewSubmissions/{sid}", {"data": {"type": "reviewSubmissions",
        "id": sid, "attributes": {"submitted": True}}})
    if r.get("_err"):
        sys.exit("submit: " + detail(r))
    print("SUBMITTED state:", r["data"]["attributes"]["state"])


if __name__ == "__main__":
    main()
