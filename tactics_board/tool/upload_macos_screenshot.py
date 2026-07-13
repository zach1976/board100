#!/usr/bin/env python3
"""Upload a macOS (APP_DESKTOP) screenshot to an app's MAC_OS version.

Reserves the screenshot, PUTs the bytes to Apple's upload URL(s), then commits
with the file checksum. Applies the same image to every localization of the
app's MAC_OS PREPARE_FOR_SUBMISSION version.

  python3 tool/upload_macos_screenshot.py <bundle_id> <image.png>
"""
import jwt, time, sys, os, hashlib, warnings
import requests
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY = "/Users/zhenyusong/projects/keys/AuthKey_4A9Y2S3D6X.p8"
B = "https://api.appstoreconnect.apple.com"
DISPLAY_TYPE = "APP_DESKTOP"


def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200,
                       "aud": "appstoreconnect-v1"}, open(KEY).read(), algorithm="ES256",
                      headers={"kid": KEY_ID})


def api(m, p, d=None):
    r = requests.request(m, f"{B}{p}", headers={"Authorization": f"Bearer {tok()}",
                         "Content-Type": "application/json"}, json=d, timeout=90, verify=False)
    try:
        body = r.json()
    except Exception:
        body = {}
    if r.status_code >= 400:
        return {"_err": True, "_status": r.status_code, "_body": body}
    return body if body else {"_ok": True}


def upload_one(loc_id, img, data, name, md5):
    # 1) reserve
    r = api("POST", "/v1/appScreenshotSets", {
        "data": {"type": "appScreenshotSets",
                 "attributes": {"screenshotDisplayType": DISPLAY_TYPE},
                 "relationships": {"appStoreVersionLocalization": {
                     "data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}}})
    if r.get("_err"):
        # a set for this display type may already exist — find it
        rs = api("GET", f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")
        set_id = None
        for s in rs.get("data", []):
            if s["attributes"]["screenshotDisplayType"] == DISPLAY_TYPE:
                set_id = s["id"]; break
        if not set_id:
            return f"set: {r['_body'].get('errors',[{}])[0].get('detail','?')[:120]}"
    else:
        set_id = r["data"]["id"]

    # 2) create screenshot reservation
    r = api("POST", "/v1/appScreenshots", {
        "data": {"type": "appScreenshots",
                 "attributes": {"fileName": name, "fileSize": len(data)},
                 "relationships": {"appScreenshotSet": {
                     "data": {"type": "appScreenshotSets", "id": set_id}}}}})
    if r.get("_err"):
        return f"reserve: {r['_body'].get('errors',[{}])[0].get('detail','?')[:120]}"
    sid = r["data"]["id"]
    ops = r["data"]["attributes"]["uploadOperations"]

    # 3) PUT bytes per operation
    for op in ops:
        headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        chunk = data[op["offset"]:op["offset"] + op["length"]]
        put = requests.request(op["method"], op["url"], headers=headers, data=chunk, timeout=120, verify=False)
        if put.status_code >= 400:
            return f"put {put.status_code}"

    # 4) commit
    r = api("PATCH", f"/v1/appScreenshots/{sid}", {
        "data": {"type": "appScreenshots", "id": sid,
                 "attributes": {"uploaded": True, "sourceFileChecksum": md5}}})
    if r.get("_err"):
        return f"commit: {r['_body'].get('errors',[{}])[0].get('detail','?')[:120]}"
    return None


def main():
    bundle_id, img = sys.argv[1], sys.argv[2]
    data = open(img, "rb").read()
    md5 = hashlib.md5(data).hexdigest()
    name = os.path.basename(img)

    r = api("GET", f"/v1/apps?filter[bundleId]={bundle_id}")
    app_id = r["data"][0]["id"]
    r = api("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[platform]=MAC_OS&filter[appStoreState]=PREPARE_FOR_SUBMISSION")
    if not r.get("data"):
        print("no MAC_OS draft version"); return 1
    vid = r["data"][0]["id"]
    r = api("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=50")
    locs = r.get("data", [])
    ok = err = 0
    for loc in locs:
        L = loc["attributes"]["locale"]
        e = upload_one(loc["id"], img, data, name, md5)
        if e:
            print(f"  ✗ {L}: {e}"); err += 1
        else:
            print(f"  ✓ {L}"); ok += 1
    print(f"{ok} uploaded, {err} errors")
    return 0 if err == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
