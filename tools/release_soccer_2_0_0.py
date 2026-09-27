#!/usr/bin/env python3 -u
"""Ship Soccer Board 2.0.0 to the App Store, one step at a time.

Soccer only. Every other app is untouched — zachs_app_base.md 6.4 says one
app at a time, and on 2026-09-27 all sixteen sat at 1.1.25 READY_FOR_SALE
with nothing in review.

Each step is idempotent and prints what it found before it changes anything,
so a half-finished run is resumed by running the next step rather than by
starting over.

    python3 tools/release_soccer_2_0_0.py version     # create/find 2.0.0
    python3 tools/release_soccer_2_0_0.py text        # name/subtitle + per-locale text
    python3 tools/release_soccer_2_0_0.py shots       # 5 screenshots x 11 locales
    python3 tools/release_soccer_2_0_0.py build       # attach the uploaded build
    python3 tools/release_soccer_2_0_0.py notes       # review notes + encryption
    python3 tools/release_soccer_2_0_0.py status      # read everything back
    python3 tools/release_soccer_2_0_0.py submit      # <- the irreversible one
"""
import hashlib
import json
import os
import sys
import time

import jwt
import requests
import urllib3

urllib3.disable_warnings()

BASE = "https://api.appstoreconnect.apple.com/v1"

# App Store Connect API credentials. Read from the environment, or from
# ~/projects/.env, rather than written down here: the other scripts in this
# repo hardcode them and should not.
#   ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_FILE


def _env(name, *, required=True):
    v = os.environ.get(name)
    if not v:
        envf = os.path.expanduser("~/projects/.env")
        if os.path.exists(envf):
            for line in open(envf):
                line = line.strip()
                if line.startswith(f"{name}="):
                    v = line.split("=", 1)[1].strip().strip("'\"")
                    break
    if not v and required:
        raise SystemExit(
            f"✗ 缺少 {name}。放进环境变量或 ~/projects/.env："
            f"\n    export {name}=...")
    return v


KEY_ID = _env("ASC_KEY_ID")
ISSUER_ID = _env("ASC_ISSUER_ID")
KEY_FILE = _env("ASC_KEY_FILE")

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, "tools"))
from apps import metadata_dir, screenshots_dir  # noqa: E402

KEY = "soccer"
BUNDLE = "com.zach.soccerBoard"
VERSION = "2.0.0"
BUILD_VERSION = "3"          # CFBundleVersion of the IPA
COPYRIGHT = "2026 Zhenyu Song"

# fastlane's folder name -> the locale App Store Connect uses.
LOCALE_MAP = {
    "en-US": "en-US", "en-GB": "en-GB", "es-ES": "es-ES", "fr-FR": "fr-FR",
    "id": "id", "ja": "ja", "ko": "ko", "ms": "ms", "th": "th", "vi": "vi",
    "zh-Hans": "zh-Hans", "zh-Hant": "zh-Hant",
}

_tok = {"t": None, "exp": 0}


def token():
    if _tok["t"] and time.time() < _tok["exp"] - 120:
        return _tok["t"]
    with open(KEY_FILE) as f:
        key = f.read()
    exp = int(time.time()) + 900
    _tok["t"] = jwt.encode(
        {"iss": ISSUER_ID, "exp": exp, "aud": "appstoreconnect-v1"},
        key, algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"})
    _tok["exp"] = exp
    return _tok["t"]


def call(method, path, payload=None, **params):
    url = path if path.startswith("http") else BASE + path
    for attempt in range(3):
        r = requests.request(
            method, url,
            headers={"Authorization": f"Bearer {token()}",
                     "Content-Type": "application/json"},
            params=params or None,
            data=json.dumps(payload) if payload is not None else None,
            verify=False, timeout=90)
        if r.status_code != 401 or attempt == 2:
            break
        _tok["exp"] = 0
    if r.status_code >= 400:
        detail = ""
        try:
            detail = "; ".join(
                f'{e.get("title")}: {e.get("detail")}' for e in r.json().get("errors", []))
        except Exception:
            detail = r.text[:300]
        raise SystemExit(f"✗ {method} {path} → {r.status_code}\n  {detail}")
    return r.json() if r.text else {}


get = lambda p, **q: call("GET", p, None, **q)
post = lambda p, d: call("POST", p, d)
patch = lambda p, d: call("PATCH", p, d)


def app_id():
    return get("/apps", **{"filter[bundleId]": BUNDLE})["data"][0]["id"]


def find_version(aid, create=False):
    """The editable iOS 2.0.0 version record, optionally creating it."""
    r = get(f"/apps/{aid}/appStoreVersions",
            **{"filter[platform]": "IOS", "limit": 20})
    for d in r["data"]:
        if d["attributes"]["versionString"] == VERSION:
            return d["id"], d["attributes"]["appStoreState"]
    if not create:
        return None, None
    made = post("/appStoreVersions", {
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": VERSION,
                           "copyright": COPYRIGHT,
                           "releaseType": "AFTER_APPROVAL"},
            "relationships": {"app": {"data": {"type": "apps", "id": aid}}},
        }})
    return made["data"]["id"], made["data"]["attributes"]["appStoreState"]


def read(loc, name):
    p = os.path.join(metadata_dir(KEY), loc, f"{name}.txt")
    return open(p).read().strip() if os.path.exists(p) else None


# ── steps ────────────────────────────────────────────────────────────────
def step_version():
    aid = app_id()
    live = get(f"/apps/{aid}/appStoreVersions",
               **{"filter[platform]": "IOS", "limit": 1})["data"][0]["attributes"]
    print(f"线上: {live['versionString']} {live['appStoreState']}")
    vid, state = find_version(aid, create=True)
    print(f"✅ {VERSION} → {vid} ({state})")


def step_text():
    aid = app_id()
    vid, state = find_version(aid)
    if not vid:
        raise SystemExit("✗ 先跑 version")
    print(f"{VERSION} {state}")

    # name / subtitle live on the APP, not the version. Editing them needs the
    # appInfo that is still editable.
    infos = get(f"/apps/{aid}/appInfos")["data"]
    editable = [i for i in infos
                if i["attributes"].get("appStoreState") != "READY_FOR_SALE"]
    info = (editable or infos)[0]
    print(f"appInfo {info['id']} ({info['attributes'].get('appStoreState')})")
    ilocs = {d["attributes"]["locale"]: d["id"] for d in
             get(f"/appInfos/{info['id']}/appInfoLocalizations")["data"]}
    vlocs = {d["attributes"]["locale"]: d["id"] for d in
             get(f"/appStoreVersions/{vid}/appStoreVersionLocalizations",
                 limit=40)["data"]}

    for folder, locale in LOCALE_MAP.items():
        name, sub = read(folder, "name"), read(folder, "subtitle")
        if locale in ilocs and (name or sub):
            attrs = {k: v for k, v in (("name", name), ("subtitle", sub)) if v}
            patch(f"/appInfoLocalizations/{ilocs[locale]}",
                  {"data": {"type": "appInfoLocalizations",
                            "id": ilocs[locale], "attributes": attrs}})
        body = {k: v for k, v in (
            ("description", read(folder, "description")),
            ("keywords", read(folder, "keywords")),
            ("whatsNew", read(folder, "release_notes")),
            ("promotionalText", read(folder, "promotional_text")),
        ) if v}
        if locale not in vlocs:
            body["locale"] = locale
            made = post("/appStoreVersionLocalizations", {
                "data": {"type": "appStoreVersionLocalizations",
                         "attributes": body,
                         "relationships": {"appStoreVersion": {
                             "data": {"type": "appStoreVersions", "id": vid}}}}})
            vlocs[locale] = made["data"]["id"]
            print(f"  + {locale}")
        else:
            patch(f"/appStoreVersionLocalizations/{vlocs[locale]}",
                  {"data": {"type": "appStoreVersionLocalizations",
                            "id": vlocs[locale], "attributes": body}})
            print(f"  ✓ {locale}  name={bool(name)} kw={len(body.get('keywords',''))}")


def step_shots():
    aid = app_id()
    vid, _ = find_version(aid)
    if not vid:
        raise SystemExit("✗ 先跑 version")
    vlocs = {d["attributes"]["locale"]: d["id"] for d in
             get(f"/appStoreVersions/{vid}/appStoreVersionLocalizations",
                 limit=40)["data"]}
    for folder, locale in LOCALE_MAP.items():
        d = os.path.join(screenshots_dir(KEY), folder)
        if not os.path.isdir(d) or locale not in vlocs:
            continue
        pngs = sorted(f for f in os.listdir(d)
                      if f.endswith(".png") and not f.startswith("ipad"))
        if not pngs:
            continue
        sets = get(f"/appStoreVersionLocalizations/{vlocs[locale]}/appScreenshotSets")["data"]
        sid = next((s["id"] for s in sets
                    if s["attributes"]["screenshotDisplayType"] == "APP_IPHONE_67"), None)
        if sid is None:
            sid = post("/appScreenshotSets", {
                "data": {"type": "appScreenshotSets",
                         "attributes": {"screenshotDisplayType": "APP_IPHONE_67"},
                         "relationships": {"appStoreVersionLocalization": {
                             "data": {"type": "appStoreVersionLocalizations",
                                      "id": vlocs[locale]}}}}})["data"]["id"]
        # Replace wholesale: the set used to hold six, this release has five.
        for old in get(f"/appScreenshotSets/{sid}/appScreenshots", limit=20)["data"]:
            call("DELETE", f"/appScreenshots/{old['id']}")
        for i, fn in enumerate(pngs):
            blob = open(os.path.join(d, fn), "rb").read()
            res = post("/appScreenshots", {
                "data": {"type": "appScreenshots",
                         "attributes": {"fileSize": len(blob), "fileName": fn},
                         "relationships": {"appScreenshotSet": {
                             "data": {"type": "appScreenshotSets", "id": sid}}}}})
            shot = res["data"]
            for op in shot["attributes"]["uploadOperations"]:
                hdrs = {h["name"]: h["value"] for h in op["requestHeaders"]}
                chunk = blob[op["offset"]:op["offset"] + op["length"]]
                r = requests.request(op["method"], op["url"], headers=hdrs,
                                     data=chunk, verify=False, timeout=180)
                r.raise_for_status()
            patch(f"/appScreenshots/{shot['id']}", {
                "data": {"type": "appScreenshots", "id": shot["id"],
                         "attributes": {"uploaded": True,
                                        "sourceFileChecksum": hashlib.md5(blob).hexdigest()}}})
        print(f"  {locale}: {len(pngs)} 张")


def step_ipad():
    """iPad screenshots, replacing the bare grabs inherited from 1.1.x.

    The app's UIDeviceFamily is [1, 2], so iPad shots are required — the set
    cannot simply be deleted. What was there was four unretouched simulator
    grabs from the old UI, which 6.1 forbids outright.
    """
    aid = app_id()
    vid, _ = find_version(aid)
    root = os.path.join(REPO, "tactics_board", "fastlane",
                        "screenshots_ipad", KEY)
    if not os.path.isdir(root):
        raise SystemExit(f"✗ 没有 {root}")
    vlocs = {d["attributes"]["locale"]: d["id"] for d in
             get(f"/appStoreVersions/{vid}/appStoreVersionLocalizations",
                 limit=40)["data"]}
    for folder, locale in LOCALE_MAP.items():
        d = os.path.join(root, folder)
        # en-GB has no captures of its own; it reads the same English.
        if not os.path.isdir(d) and locale == "en-GB":
            d = os.path.join(root, "en-US")
        if not os.path.isdir(d) or locale not in vlocs:
            continue
        pngs = sorted(f for f in os.listdir(d) if f.endswith(".png"))
        if not pngs:
            continue
        sets = get(f"/appStoreVersionLocalizations/{vlocs[locale]}/appScreenshotSets")["data"]
        sid = next((x["id"] for x in sets
                    if x["attributes"]["screenshotDisplayType"]
                    == "APP_IPAD_PRO_3GEN_129"), None)
        if sid is None:
            sid = post("/appScreenshotSets", {
                "data": {"type": "appScreenshotSets",
                         "attributes": {"screenshotDisplayType":
                                        "APP_IPAD_PRO_3GEN_129"},
                         "relationships": {"appStoreVersionLocalization": {
                             "data": {"type": "appStoreVersionLocalizations",
                                      "id": vlocs[locale]}}}}})["data"]["id"]
        for stale in get(f"/appScreenshotSets/{sid}/appScreenshots", limit=20)["data"]:
            call("DELETE", f"/appScreenshots/{stale['id']}")
        for fn in pngs:
            blob = open(os.path.join(d, fn), "rb").read()
            sh = post("/appScreenshots", {
                "data": {"type": "appScreenshots",
                         "attributes": {"fileSize": len(blob),
                                        "fileName": f"ipad_{fn}"},
                         "relationships": {"appScreenshotSet": {
                             "data": {"type": "appScreenshotSets", "id": sid}}}}})["data"]
            for op in sh["attributes"]["uploadOperations"]:
                hdrs = {h["name"]: h["value"] for h in op["requestHeaders"]}
                r = requests.request(op["method"], op["url"], headers=hdrs,
                                     data=blob[op["offset"]:op["offset"] + op["length"]],
                                     verify=False, timeout=300)
                r.raise_for_status()
            patch(f"/appScreenshots/{sh['id']}", {
                "data": {"type": "appScreenshots", "id": sh["id"],
                         "attributes": {"uploaded": True,
                                        "sourceFileChecksum": hashlib.md5(blob).hexdigest()}}})
        print(f"  {locale}: {len(pngs)} 张 iPad")


def step_preview():
    """The App Preview film, en-US only.

    A locale with no preview falls back to the primary one, so eleven copies
    of the same silent film would buy nothing. Apple transcodes it after
    upload; the version can be submitted while that is still running.
    """
    aid = app_id()
    vid, _ = find_version(aid)
    # The one WITH an audio track. Apple transcodes a silent App Preview and
    # then fails it with MOV_RESAVE_STEREO — a preview must carry stereo
    # audio, even when there is nothing to hear. tools/record_preview.sh
    # records silent, so a muted stereo track is muxed on afterwards.
    mp4 = os.path.join(REPO, "build", "preview", "soccer_av.mp4")
    if not os.path.exists(mp4):
        raise SystemExit("✗ 没有 build/preview/soccer_av.mp4（需要带静音立体声音轨）")
    vlocs = {d["attributes"]["locale"]: d["id"] for d in
             get(f"/appStoreVersions/{vid}/appStoreVersionLocalizations",
                 limit=40)["data"]}
    only = os.environ.get("PREVIEW_LOCALES", "en-US").split(",")
    targets = [(lc, vlocs[lc]) for lc in only if lc in vlocs]
    if not targets:
        raise SystemExit(f"✗ 这些语言不存在: {only}")
    for lc, lid in targets:
        _one_preview(lc, lid, mp4)


def _one_preview(lc, lid, mp4):
    sets = get(f"/appStoreVersionLocalizations/{lid}/appPreviewSets")["data"]
    sid = next((s["id"] for s in sets
                if s["attributes"]["previewType"] == "IPHONE_67"), None)
    if sid is None:
        sid = post("/appPreviewSets", {
            "data": {"type": "appPreviewSets",
                     "attributes": {"previewType": "IPHONE_67"},
                     "relationships": {"appStoreVersionLocalization": {
                         "data": {"type": "appStoreVersionLocalizations",
                                  "id": lid}}}}})["data"]["id"]
    for old_p in get(f"/appPreviewSets/{sid}/appPreviews", limit=10)["data"]:
        call("DELETE", f"/appPreviews/{old_p['id']}")
    blob = open(mp4, "rb").read()
    res = post("/appPreviews", {
        "data": {"type": "appPreviews",
                 "attributes": {"fileSize": len(blob),
                                "fileName": os.path.basename(mp4)},
                 "relationships": {"appPreviewSet": {
                     "data": {"type": "appPreviewSets", "id": sid}}}}})
    pv = res["data"]
    for op in pv["attributes"]["uploadOperations"]:
        hdrs = {h["name"]: h["value"] for h in op["requestHeaders"]}
        r = requests.request(op["method"], op["url"], headers=hdrs,
                             data=blob[op["offset"]:op["offset"] + op["length"]],
                             verify=False, timeout=300)
        r.raise_for_status()
    patch(f"/appPreviews/{pv['id']}", {
        "data": {"type": "appPreviews", "id": pv["id"],
                 "attributes": {"uploaded": True,
                                "sourceFileChecksum": hashlib.md5(blob).hexdigest()}}})
    print(f"✅ {lc}: 预览视频 {len(blob)/1048576:.1f} MB 已上传，Apple 转码中")


def step_build():
    aid = app_id()
    vid, _ = find_version(aid)
    r = get("/builds", **{"filter[app]": aid, "limit": 20, "sort": "-uploadedDate"})
    cands = [b for b in r["data"]
             if b["attributes"].get("version") == BUILD_VERSION]
    if not cands:
        vers = sorted({b["attributes"].get("version") for b in r["data"]})
        raise SystemExit(f"✗ 没有 build {BUILD_VERSION}；已上传的: {vers}")
    b = cands[0]
    st = b["attributes"].get("processingState")
    print(f"build {b['attributes']['version']} {st} {b['attributes']['uploadedDate']}")
    if st != "VALID":
        raise SystemExit(f"✗ 还在处理（{st}），等它变 VALID 再跑")
    patch(f"/appStoreVersions/{vid}/relationships/build",
          {"data": {"type": "builds", "id": b["id"]}})
    # usesNonExemptEncryption lives on the BUILD, not the version; setting it
    # on the version is a 409 with a message that names the right resource.
    patch(f"/builds/{b['id']}",
          {"data": {"type": "builds", "id": b["id"],
                    "attributes": {"usesNonExemptEncryption": False}}})
    print("✅ 已附加，加密声明 false")


def step_notes():
    aid = app_id()
    vid, _ = find_version(aid)
    notes_path = os.path.join(REPO, "SoccerBoard", "docs",
                              f"REVIEW_NOTES_{VERSION}.md")
    text = open(notes_path).read()
    # 6.4: a draft with placeholders must never reach Apple.
    for marker in ("[REJECTION REASON", "[FINAL DEVICE QA", "TODO", "TBD"):
        if marker in text:
            raise SystemExit(f"✗ Review Notes 还有占位符 {marker!r} — 拒绝提交")
    body = text.split("Dear App Review team,", 1)[1]
    body = "Dear App Review team," + body.split("Thank you for reviewing.")[0] \
        + "Thank you for reviewing."
    body = "\n".join(l for l in body.splitlines() if not l.startswith(">")).strip()
    if len(body) > 4000:
        raise SystemExit(f"✗ Notes {len(body)} 字符，上限 4000")
    detail = get(f"/appStoreVersions/{vid}/appStoreReviewDetail")
    attrs = {"notes": body, "demoAccountRequired": False}
    if detail.get("data"):
        patch(f"/appStoreReviewDetails/{detail['data']['id']}",
              {"data": {"type": "appStoreReviewDetails",
                        "id": detail["data"]["id"], "attributes": attrs}})
    else:
        post("/appStoreReviewDetails", {
            "data": {"type": "appStoreReviewDetails", "attributes": attrs,
                     "relationships": {"appStoreVersion": {
                         "data": {"type": "appStoreVersions", "id": vid}}}}})
    print(f"✅ Review Notes {len(body)} 字符")
    print("   加密声明在 build 上，由 build 步骤设置")


def step_status():
    aid = app_id()
    vid, state = find_version(aid)
    print(f"app {aid}  version {VERSION} {state} ({vid})")
    v = get(f"/appStoreVersions/{vid}")["data"]["attributes"]
    print(f"  releaseType={v.get('releaseType')} encryption={v.get('usesNonExemptEncryption')}")
    b = get(f"/appStoreVersions/{vid}/build")
    print("  build:", (b.get("data") or {}).get("attributes", {}).get("version", "未附加"))
    locs = get(f"/appStoreVersions/{vid}/appStoreVersionLocalizations", limit=40)["data"]
    print(f"  语言 {len(locs)}")
    for l in sorted(locs, key=lambda x: x["attributes"]["locale"]):
        lid, a = l["id"], l["attributes"]
        n = len(get(f"/appStoreVersionLocalizations/{lid}/appScreenshotSets")["data"])
        shots = 0
        for s in get(f"/appStoreVersionLocalizations/{lid}/appScreenshotSets")["data"]:
            shots += len(get(f"/appScreenshotSets/{s['id']}/appScreenshots", limit=20)["data"])
        print(f"    {a['locale']:8s} desc={len(a.get('description') or ''):4d} "
              f"kw={len(a.get('keywords') or ''):3d} new={len(a.get('whatsNew') or ''):4d} "
              f"sets={n} shots={shots}")
    d = get(f"/appStoreVersions/{vid}/appStoreReviewDetail").get("data")
    print("  notes:", len((d or {}).get("attributes", {}).get("notes") or ""), "字符")


def step_submit():
    aid = app_id()
    vid, state = find_version(aid)
    print(f"{VERSION} {state}")
    subs = get(f"/apps/{aid}/reviewSubmissions",
               **{"filter[state]": "READY_FOR_REVIEW", "limit": 5})["data"]
    sub = subs[0] if subs else post("/reviewSubmissions", {
        "data": {"type": "reviewSubmissions",
                 "attributes": {"platform": "IOS"},
                 "relationships": {"app": {"data": {"type": "apps", "id": aid}}}}})["data"]
    print("submission", sub["id"], sub["attributes"]["state"])
    items = get(f"/reviewSubmissions/{sub['id']}/items")["data"]
    if not any((i.get("relationships", {}).get("appStoreVersion", {}).get("data") or {}).get("id") == vid
               for i in items):
        post("/reviewSubmissionItems", {
            "data": {"type": "reviewSubmissionItems",
                     "relationships": {
                         "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub["id"]}},
                         "appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
        print("  + item")
    patch(f"/reviewSubmissions/{sub['id']}",
          {"data": {"type": "reviewSubmissions", "id": sub["id"],
                    "attributes": {"submitted": True}}})
    print("🚀 已送审")


STEPS = {"version": step_version, "text": step_text, "shots": step_shots,
         "ipad": step_ipad,
         "preview": step_preview, "build": step_build, "notes": step_notes,
         "status": step_status, "submit": step_submit}

if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in STEPS:
        raise SystemExit(__doc__)
    STEPS[sys.argv[1]]()
