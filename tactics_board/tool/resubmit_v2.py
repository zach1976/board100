#!/usr/bin/env python3 -u
# -*- coding: utf-8 -*-
"""V2 screenshot rollout: withdraw the in-review 1.1.19 version, swap in the new
PLAN-EVERY-RALLY screenshots, and resubmit — for all 16 sport-board apps.

Flow per app:
  1. find the 1.1.19 appStoreVersion (IN_REVIEW / WAITING_FOR_REVIEW)
  2. cancel its active reviewSubmission (PATCH canceled=true) -> frees the version
  3. wait for PREPARE_FOR_SUBMISSION (editable)
  4. wipe existing iPhone 6.7" screenshots, upload new ones from fastlane/screenshots
  5. create reviewSubmission, add the version item, PATCH submitted=true

Safety:
  python3 tool/resubmit_v2.py --dry-run            # report only, no changes
  python3 tool/resubmit_v2.py --only badminton --go # do ONE app for real
  python3 tool/resubmit_v2.py --go                 # do all 16 for real
"""
import jwt, time, requests, os, hashlib, sys, warnings
warnings.filterwarnings("ignore")
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

KEY_ID = "4A9Y2S3D6X"
ISSUER = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/projects/keys/AuthKey_4A9Y2S3D6X.p8"
SCREENSHOTS_BASE = "/Users/zhenyusong/projects/board100/tactics_board/fastlane/screenshots"
TARGET_VERSION = "1.1.19"
B = "https://api.appstoreconnect.apple.com"

APPS = {
    "tactics_board": "com.zach.tacticsBoard",
    "soccer": "com.zach.soccerBoard",
    "basketball": "com.zach.basketballBoard",
    "volleyball": "com.zach.volleyballBoard",
    "badminton": "com.zach.badmintonBoard",
    "tennis": "com.zach.tennisBoard",
    "tableTennis": "com.zach.tableTennisBoard",
    "pickleball": "com.zach.pickleballBoard",
    "baseball": "com.zach.baseballBoard",
    "beachTennis": "com.zach.beachTennisBoard",
    "fieldHockey": "com.zach.fieldHockeyBoard",
    "footvolley": "com.zach.footvolleyBoard",
    "handball": "com.zach.handballBoard",
    "rugby": "com.zach.rugbyBoard",
    "sepakTakraw": "com.zach.sepakTakrawBoard",
    "waterPolo": "com.zach.waterPoloBoard",
}

CANCELABLE = {"WAITING_FOR_REVIEW", "IN_REVIEW", "UNRESOLVED_ISSUES"}

session = requests.Session()
session.mount("https://", HTTPAdapter(max_retries=Retry(
    total=5, backoff_factor=2, status_forcelist=[500, 502, 503, 504])))
_tok, _tok_t = "", 0


def tok():
    global _tok, _tok_t
    if int(time.time()) - _tok_t > 900:
        _tok = jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200,
                           "aud": "appstoreconnect-v1"}, open(KEY_FILE).read(),
                          algorithm="ES256", headers={"kid": KEY_ID})
        _tok_t = int(time.time())
    return _tok


def Hd():
    return {"Authorization": f"Bearer {tok()}", "Content-Type": "application/json"}


def G(p):
    return session.get(B + p, headers=Hd(), verify=False, timeout=60).json()


def P(p, b):
    return session.post(B + p, headers=Hd(), json=b, verify=False, timeout=60)


def PATCH(p, b):
    return session.patch(B + p, headers=Hd(), json=b, verify=False, timeout=60)


def DEL(p):
    return session.delete(B + p, headers=Hd(), verify=False, timeout=60).status_code


def upload_file(ops, path):
    data = open(path, "rb").read()
    for op in ops:
        chunk = data[op["offset"]: op["offset"] + op["length"]]
        h = {x["name"]: x["value"] for x in op.get("requestHeaders", [])}
        for a in range(4):
            try:
                r = session.put(op["url"], headers=h, data=chunk, timeout=60)
                if r.status_code < 400:
                    break
            except Exception:
                time.sleep(2 ** a)
        else:
            return False
    return True


EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "METADATA_REJECTED",
            "REJECTED", "DEVELOPER_REMOVED_FROM_REVIEW", "INVALID_BINARY"}


def wait_editable(vid, max_wait=120):
    for _ in range(max_wait // 5):
        st = G(f"/v1/appStoreVersions/{vid}")["data"]["attributes"]["appStoreState"]
        if st in EDITABLE:
            print(f"      editable (state={st})")
            return True
        print(f"      state={st}, waiting…")
        time.sleep(5)
    return False


def upload_screenshots(app_key, vid, dry):
    locs = {l["attributes"]["locale"]: l["id"]
            for l in G(f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=40").get("data", [])}
    for locale, loc_id in sorted(locs.items()):
        d = os.path.join(SCREENSHOTS_BASE, app_key, locale)
        if not os.path.isdir(d):
            continue
        pngs = sorted(f for f in os.listdir(d) if f.endswith(".png") and not f.startswith("ipad"))
        if not pngs:
            continue
        if dry:
            print(f"      {locale}: would upload {len(pngs)}")
            continue
        sets = G(f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets").get("data", [])
        set_id = next((s["id"] for s in sets if s["attributes"]["screenshotDisplayType"] == "APP_IPHONE_67"), None)
        if not set_id:
            r = P("/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": "APP_IPHONE_67"},
                "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}}})
            if not r.ok:
                print(f"      {locale}: set create ERR {r.status_code}"); continue
            set_id = r.json()["data"]["id"]
        for ex in G(f"/v1/appScreenshotSets/{set_id}/appScreenshots").get("data", []):
            DEL(f"/v1/appScreenshots/{ex['id']}")
        up = 0
        for png in pngs:
            fp = os.path.join(d, png)
            size = os.path.getsize(fp)
            checksum = hashlib.md5(open(fp, "rb").read()).hexdigest()
            r = P("/v1/appScreenshots", {"data": {"type": "appScreenshots",
                "attributes": {"fileName": png, "fileSize": size},
                "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})
            if not r.ok:
                continue
            j = r.json()["data"]
            if upload_file(j["attributes"].get("uploadOperations", []), fp):
                PATCH(f"/v1/appScreenshots/{j['id']}", {"data": {"type": "appScreenshots",
                    "id": j["id"], "attributes": {"sourceFileChecksum": checksum, "uploaded": True}}})
                up += 1
        print(f"      {locale}: {up}/{len(pngs)} uploaded")


def rollout(app_key, dry):
    bundle = APPS[app_key]
    print(f"\n{'━'*44}\n  {app_key}  ({bundle})\n{'━'*44}")
    apps = G(f"/v1/apps?filter[bundleId]={bundle}").get("data", [])
    if not apps:
        print("  app not found"); return
    aid = apps[0]["id"]
    v = next((v for v in G(f"/v1/apps/{aid}/appStoreVersions?limit=6")["data"]
              if v["attributes"]["versionString"] == TARGET_VERSION), None)
    if not v:
        print(f"  no {TARGET_VERSION} version"); return
    vid, vst = v["id"], v["attributes"]["appStoreState"]
    print(f"  {TARGET_VERSION} state = {vst}")

    subs = G(f"/v1/apps/{aid}/reviewSubmissions?limit=10").get("data", [])
    active = [s for s in subs if s["attributes"]["state"] in CANCELABLE]
    if dry:
        print(f"  would cancel {len(active)} submission(s); then wipe+upload; then resubmit")
        upload_screenshots(app_key, vid, dry=True)
        return

    for s in active:
        r = PATCH(f"/v1/reviewSubmissions/{s['id']}", {"data": {"type": "reviewSubmissions",
            "id": s["id"], "attributes": {"canceled": True}}})
        print(f"  canceled submission {s['id'][:8]} ({s['attributes']['state']}) ok={r.ok}")

    if vst not in EDITABLE:
        print("  waiting for editable state…")
        wait_editable(vid, max_wait=150)

    print("  uploading screenshots…")
    upload_screenshots(app_key, vid, dry=False)

    # resubmit
    subs = G(f"/v1/apps/{aid}/reviewSubmissions?limit=10").get("data", [])
    sid = next((s["id"] for s in subs if s["attributes"]["state"] == "READY_FOR_REVIEW"), None)
    if not sid:
        r = P("/v1/reviewSubmissions", {"data": {"type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": aid}}}}})
        if not r.ok:
            print(f"  create submission ERR {r.status_code} {r.text[:160]}"); return
        sid = r.json()["data"]["id"]
    for _ in range(15):
        r = P("/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems",
            "relationships": {"reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sid}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
        if r.ok:
            break
        time.sleep(8)
    else:
        print(f"  add version FAILED {r.status_code} {r.text[:160]}"); return
    r = PATCH(f"/v1/reviewSubmissions/{sid}", {"data": {"type": "reviewSubmissions",
        "id": sid, "attributes": {"submitted": True}}})
    print(f"  {'RESUBMITTED ✓' if r.ok else 'SUBMIT ERR ' + str(r.status_code) + ' ' + r.text[:200]}")


if __name__ == "__main__":
    args = sys.argv[1:]
    dry = "--go" not in args
    only = None
    if "--only" in args:
        only = args[args.index("--only") + 1]
    keys = [only] if only else list(APPS)
    if dry:
        print("DRY-RUN (no changes). Add --go to execute.\n")
    for k in keys:
        rollout(k, dry)
    print("\nDone.")
