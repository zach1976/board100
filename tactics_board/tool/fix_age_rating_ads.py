#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Guideline 2.3.6 fix: every app serves ads, so the Age Rating must declare
"Advertising: Yes". The field is ageRatingDeclaration.advertising, reached via
each app's editable (non-READY_FOR_SALE) appInfo. PATCH it to true.

  python3 tool/fix_age_rating_ads.py check          # report advertising flag per app
  python3 tool/fix_age_rating_ads.py fix            # PATCH editable appInfo to true (all)
  python3 tool/fix_age_rating_ads.py fix handball   # one app
"""
import jwt, time, requests, warnings, sys
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
PK = open("/Users/zhenyusong/projects/keys/AuthKey_4A9Y2S3D6X.p8").read()
B = "https://api.appstoreconnect.apple.com"
# bundle ids: 15 single sports + hub
APPS = {s: f"com.zach.{s}Board" for s in [
    "soccer", "basketball", "volleyball", "badminton", "tennis", "tableTennis",
    "pickleball", "fieldHockey", "rugby", "baseball", "handball", "waterPolo",
    "beachTennis", "footvolley", "sepakTakraw"]}
APPS["hub"] = "com.zach.tacticsBoard"


def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200,
                       "aud": "appstoreconnect-v1"}, PK, algorithm="ES256", headers={"kid": KEY_ID})


def G(path):
    return requests.get(B + path, headers={"Authorization": f"Bearer {tok()}"}, verify=False, timeout=60).json()


def PATCH(path, body):
    return requests.patch(B + path, headers={"Authorization": f"Bearer {tok()}",
                          "Content-Type": "application/json"}, json=body, verify=False, timeout=60)


def app_id(bundle):
    d = G(f"/v1/apps?filter[bundleId]={bundle}").get("data")
    return d[0]["id"] if d else None


def info(name, bundle):
    aid = app_id(bundle)
    if not aid:
        print(f"{name:14s} APP NOT FOUND"); return
    rows = []
    for a in G(f"/v1/apps/{aid}/appInfos").get("data", []):
        st = a["attributes"].get("appStoreState")
        d = G(f"/v1/appInfos/{a['id']}/ageRatingDeclaration").get("data", {})
        rows.append((a["id"], st, d.get("id"), d.get("attributes", {}).get("advertising")))
    print(f"{name:14s} " + " | ".join(f"{st}:adv={adv}" for _, st, _, adv in rows))
    return aid, rows


def fix(name, bundle):
    res = info(name, bundle)
    if not res:
        return
    aid, rows = res
    for infoid, st, did, adv in rows:
        if st == "READY_FOR_SALE":
            continue  # live listing — locked / leave as-is
        if adv is True:
            print(f"  {name}/{st}: already advertising=true"); continue
        r = PATCH(f"/v1/ageRatingDeclarations/{did}", {"data": {"type": "ageRatingDeclarations",
            "id": did, "attributes": {"advertising": True}}})
        if r.ok:
            print(f"  {name}/{st}: advertising -> TRUE (200)")
        else:
            try:
                msg = "; ".join(e.get("detail", e.get("title", "?")) for e in r.json().get("errors", []))
            except Exception:
                msg = r.text[:160]
            print(f"  {name}/{st}: PATCH {r.status_code} {msg}")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "check"
    wanted = sys.argv[2:] or list(APPS)
    for name in wanted:
        if cmd == "check":
            info(name, APPS[name])
        elif cmd == "fix":
            fix(name, APPS[name])
