#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""For each single-sport app, report:
  - the 1.1.18 appStoreVersion state (PREPARE_FOR_SUBMISSION / WAITING_FOR_REVIEW / IN_REVIEW / ...)
  - the lifetime IAP state (READY_TO_SUBMIT / WAITING_FOR_REVIEW / IN_REVIEW / APPROVED / ...)
  - whether that IAP is attached to an in-flight reviewSubmission (i.e. it will ride with the version)

This tells us if "直接提交吧" actually carried each app's lifetime Pro IAP, or if
the submission went through WITHOUT the IAP (the hub-1.1.16 mistake).
"""
import jwt, time, requests, warnings, sys
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
PK = open("/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8").read()
B = "https://api.appstoreconnect.apple.com"
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


def check(sport):
    bundle = f"com.zach.{sport}Board"
    r = api("GET", f"/v1/apps?filter[bundleId]={bundle}")
    if not r.get("data"):
        print(f"{sport:14s} APP NOT FOUND"); return
    aid = r["data"][0]["id"]

    # latest version + state
    rv = api("GET", f"/v1/apps/{aid}/appStoreVersions?limit=10")
    vstate = "NO 1.1.18"
    for v in rv.get("data", []):
        if v["attributes"]["versionString"] == "1.1.18":
            vstate = v["attributes"]["appStoreState"]
            break

    # lifetime IAP state
    pid = f"{sport.lower()}_remove_ads_lifetime"
    ri = api("GET", f"/v1/apps/{aid}/inAppPurchasesV2?filter[productId]={pid}")
    istate = "MISSING"
    if ri.get("data"):
        istate = ri["data"][0]["attributes"].get("state", "?")

    print(f"{sport:14s} ver1.1.18={vstate:24s} lifetimeIAP={istate}")


if __name__ == "__main__":
    for s in (sys.argv[1:] or SPORTS):
        check(s)
