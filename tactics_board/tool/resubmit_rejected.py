#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Resubmit a REJECTED single-sport 1.1.18 version (its lifetime IAP rides along)
after fixing the Age-Rating advertising flag. Flow that works via API:

  1. cancel the rejected reviewSubmission (PATCH canceled=true)  -> frees the version
  2. find/create a READY_FOR_REVIEW reviewSubmission for the app
  3. add the appStoreVersion as a reviewSubmissionItem (retry until the cancel settles)
  4. PATCH submitted=true

  python3 tool/resubmit_rejected.py fieldHockey rugby handball footvolley sepakTakraw
  python3 tool/resubmit_rejected.py            # all 6 known-rejected
"""
import jwt, time, requests, warnings, sys
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
PK = open("/Users/zhenyusong/projects/keys/AuthKey_4A9Y2S3D6X.p8").read()
B = "https://api.appstoreconnect.apple.com"
DEFAULT = ["tennis", "fieldHockey", "rugby", "handball", "footvolley", "sepakTakraw"]


def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200,
                       "aud": "appstoreconnect-v1"}, PK, algorithm="ES256", headers={"kid": KEY_ID})


def H():
    return {"Authorization": f"Bearer {tok()}", "Content-Type": "application/json"}


def G(p):
    return requests.get(B + p, headers={"Authorization": f"Bearer {tok()}"}, verify=False, timeout=60).json()


def P(p, b):
    return requests.post(B + p, headers=H(), json=b, verify=False, timeout=60)


def PATCH(p, b):
    return requests.patch(B + p, headers=H(), json=b, verify=False, timeout=60)


def resubmit(sport):
    aid = G(f"/v1/apps?filter[bundleId]=com.zach.{sport}Board")["data"][0]["id"]
    v = next((v for v in G(f"/v1/apps/{aid}/appStoreVersions?limit=6")["data"]
              if v["attributes"]["versionString"] == "1.1.18"), None)
    if not v:
        print(f"{sport:14s} no 1.1.18"); return
    vid, vst = v["id"], v["attributes"]["appStoreState"]
    if vst in ("WAITING_FOR_REVIEW", "IN_REVIEW", "PENDING_APPLE_RELEASE", "READY_FOR_SALE"):
        print(f"{sport:14s} already {vst} — skip"); return

    subs = G(f"/v1/apps/{aid}/reviewSubmissions?limit=10").get("data", [])
    # cancel any rejected (UNRESOLVED_ISSUES) submission to free the version
    for s in subs:
        if s["attributes"]["state"] == "UNRESOLVED_ISSUES":
            PATCH(f"/v1/reviewSubmissions/{s['id']}", {"data": {"type": "reviewSubmissions",
                "id": s["id"], "attributes": {"canceled": True}}})
            print(f"{sport:14s} canceled rejected submission {s['id'][:8]}")
    # find an open READY_FOR_REVIEW submission, else create one
    sid = next((s["id"] for s in subs if s["attributes"]["state"] == "READY_FOR_REVIEW"), None)
    if not sid:
        r = P("/v1/reviewSubmissions", {"data": {"type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": aid}}}}})
        if not r.ok:
            print(f"{sport:14s} create submission ERR {r.status_code} {r.text[:160]}"); return
        sid = r.json()["data"]["id"]

    # add version (retry while the cancel settles)
    added = False
    for _ in range(15):
        r = P("/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems",
            "relationships": {"reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sid}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
        if r.ok:
            added = True; break
        time.sleep(8)
    if not added:
        print(f"{sport:14s} add version FAILED {r.status_code} {r.text[:160]}"); return

    r = PATCH(f"/v1/reviewSubmissions/{sid}", {"data": {"type": "reviewSubmissions",
        "id": sid, "attributes": {"submitted": True}}})
    print(f"{sport:14s} {'RESUBMITTED ✓' if r.ok else 'SUBMIT ERR ' + str(r.status_code) + ' ' + r.text[:160]}")


if __name__ == "__main__":
    for s in (sys.argv[1:] or DEFAULT):
        resubmit(s)
