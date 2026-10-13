#!/usr/bin/env python3 -u
"""Ship Soccer Board 2.0.0 to the App Store, one step at a time.

Soccer only. Every other app is untouched — zachs_app_base.md 6.4 says one
app at a time, and on 2026-09-27 all sixteen sat at 1.1.25 READY_FOR_SALE
with nothing in review.

Each step is idempotent and prints what it found before it changes anything,
so a half-finished run is resumed by running the next step rather than by
starting over.

    APP=<sport> python3 tools/release_app.py version     # create/find the version in pubspec
    APP=<sport> python3 tools/release_app.py text        # name/subtitle + per-locale text
    APP=<sport> python3 tools/release_app.py shots       # 5 screenshots x 11 locales
    APP=<sport> python3 tools/release_app.py build       # attach the uploaded build
    APP=<sport> python3 tools/release_app.py notes       # review notes + encryption
    APP=<sport> python3 tools/release_app.py status      # read everything back
    APP=<sport> python3 tools/release_app.py submit      # <- the irreversible one
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

# Which app this run is releasing. One script, because the steps are the
# same for all sixteen and the second app to go out must not start from a
# copy of the first.
KEY = os.environ.get("APP", "soccer")
from apps import APPS, app_dir  # noqa: E402
if KEY not in APPS:
    raise SystemExit(f"✗ APP={KEY!r} 不在 tools/sports.tsv 里")
BUNDLE = APPS[KEY]["bundle"]
APP_DIR = str(app_dir(KEY))
# Read from the app's own pubspec.yaml — "version: 2.0.1+4" — so the release
# and the binary can never disagree about which version this is. The first
# run of this script was pinned to 2.0.0/3 in two constants, which is fine
# exactly once.
def _pubspec_version():
    path = os.path.join(APP_DIR, "pubspec.yaml")
    for line in open(path):
        if line.startswith("version:"):
            name, _, number = line.split(":", 1)[1].strip().partition("+")
            return name, number
    raise SystemExit(f"✗ {APP_DIR}/pubspec.yaml 里没有 version:")


VERSION, BUILD_VERSION = _pubspec_version()

# PLATFORM=MAC_OS switches the whole script to the Mac side of the same app
# record: a different version line, a different build line, a different
# screenshot display type, and its own Review Notes.
PLATFORM = os.environ.get("PLATFORM", "IOS")
IS_MAC = PLATFORM == "MAC_OS"
PHONE_TYPE = "APP_DESKTOP" if IS_MAC else "APP_IPHONE_67"
NOTES_FILE = ("REVIEW_NOTES_MAC_%s.md" % VERSION if IS_MAC
              else "REVIEW_NOTES_%s.md" % VERSION)
COPYRIGHT = "2026 Zhenyu Song"

# fastlane's folder name -> the locale App Store Connect uses.
LOCALE_MAP = {
    "en-US": "en-US", "en-GB": "en-GB", "es-ES": "es-ES", "fr-FR": "fr-FR",
    "id": "id", "ja": "ja", "ko": "ko", "ms": "ms", "th": "th", "vi": "vi",
    "zh-Hans": "zh-Hans", "zh-Hant": "zh-Hant",
    # Store-only listings (2026-10-13): the app's UI has no German or Dutch,
    # but these are field hockey's and soccer's biggest markets. A folder
    # that exists is created on ASC by step_text; apps without one skip it.
    "de-DE": "de-DE", "nl-NL": "nl-NL",
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
    # Deleting something that is already gone is the state we wanted. ASC
    # lists assets a moment behind itself, so a set read and then cleared can
    # name a screenshot that no longer exists, and a 404 there used to abort
    # a whole upload between its "delete the old" and "send the new" halves.
    if method == "DELETE" and r.status_code == 404:
        return {}
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
            **{"filter[platform]": PLATFORM, "limit": 20})
    for d in r["data"]:
        if d["attributes"]["versionString"] == VERSION:
            return d["id"], d["attributes"]["appStoreState"]
    if not create:
        return None, None
    # A rejected or draft version is editable and CAN be renamed; creating a
    # second one alongside it is refused with "You cannot create a new
    # version of the App in the current state". macOS sits at 1.1.24
    # REJECTED, so 2.0.0 is that record retargeted, which is also how the
    # 1.1.24 release itself was made.
    editable = [d for d in r["data"]
                if d["attributes"]["appStoreState"] in
                ("REJECTED", "DEVELOPER_REJECTED", "PREPARE_FOR_SUBMISSION",
                 "METADATA_REJECTED", "INVALID_BINARY")]
    if editable:
        d = editable[0]
        was = d["attributes"]["versionString"]
        patch(f"/appStoreVersions/{d['id']}",
              {"data": {"type": "appStoreVersions", "id": d["id"],
                        "attributes": {"versionString": VERSION,
                                       "copyright": COPYRIGHT,
                                       "releaseType": "AFTER_APPROVAL"}}})
        print(f"   复用 {was} ({d['attributes']['appStoreState']}) → {VERSION}")
        return d["id"], d["attributes"]["appStoreState"]
    made = post("/appStoreVersions", {
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": PLATFORM, "versionString": VERSION,
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
               **{"filter[platform]": PLATFORM, "limit": 1})["data"][0]["attributes"]
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
    info_state = info["attributes"].get("appStoreState")
    info_locked = info_state in ("WAITING_FOR_REVIEW", "IN_REVIEW")
    print(f"appInfo {info['id']} ({info_state})"
          + ("  ← 已锁，名称沿用现值" if info_locked else ""))
    iraw = get(f"/appInfos/{info['id']}/appInfoLocalizations")["data"]
    ilocs = {d["attributes"]["locale"]: d["id"] for d in iraw}
    vraw = get(f"/appStoreVersions/{vid}/appStoreVersionLocalizations",
               limit=40)["data"]
    vlocs = {d["attributes"]["locale"]: d["id"] for d in vraw}
    # A locale that is new to the listing (de-DE, nl-NL) starts with nothing,
    # but review wants a privacy URL on the app side and a support URL on the
    # version side for every language. Borrow them from en-US.
    en_info = next((d["attributes"] for d in iraw
                    if d["attributes"]["locale"] == "en-US"), {})
    en_ver = next((d["attributes"] for d in vraw
                   if d["attributes"]["locale"] == "en-US"), {})
    # Has this platform ever been on sale?
    hist = get(f"/apps/{aid}/appStoreVersions",
               **{"filter[platform]": PLATFORM, "limit": 20})["data"]
    first_release = not any(
        d["attributes"]["appStoreState"] in ("READY_FOR_SALE", "REPLACED_WITH_NEW_VERSION")
        for d in hist)
    if first_release:
        print(f"   {PLATFORM} 从未上架 → 首次发布，不填 whatsNew")

    for folder, locale in LOCALE_MAP.items():
        # Only the locales this app actually has text for. The map is the
        # fleet's full list and not every app ships every one — field hockey
        # has no en-GB — and running it blind created an EMPTY en-GB
        # localization on the version: no description, no keywords, no
        # What's New, which review rejects. A locale the app does not
        # translate should simply not exist on the listing.
        if not os.path.isdir(os.path.join(str(metadata_dir(KEY)), folder)):
            continue
        name, sub = read(folder, "name"), read(folder, "subtitle")
        # appInfo is shared by both platforms and locks while either one is in
        # review. The names are already the new ones, put there by the iOS
        # run, so skipping is right rather than merely unavoidable.
        if locale in ilocs and (name or sub) and not info_locked:
            attrs = {k: v for k, v in (("name", name), ("subtitle", sub)) if v}
            patch(f"/appInfoLocalizations/{ilocs[locale]}",
                  {"data": {"type": "appInfoLocalizations",
                            "id": ilocs[locale], "attributes": attrs}})
        elif locale not in ilocs and name:
            # A new store language: the app-level record (name, subtitle,
            # privacy URL) has to exist before the version's text means
            # anything. It cannot be added while the appInfo is locked.
            if info_locked:
                print(f"  ! {locale}: appInfo 已锁，无法新建名称，跳过此语言")
                continue
            attrs = {"locale": locale, "name": name}
            if sub:
                attrs["subtitle"] = sub
            for k in ("privacyPolicyUrl", "privacyChoicesUrl"):
                if en_info.get(k):
                    attrs[k] = en_info[k]
            made = post("/appInfoLocalizations", {
                "data": {"type": "appInfoLocalizations", "attributes": attrs,
                         "relationships": {"appInfo": {
                             "data": {"type": "appInfos", "id": info["id"]}}}}})
            ilocs[locale] = made["data"]["id"]
            print(f"  + {locale} appInfo: {name}")
            # Apple creates the version's localization along with it, so a
            # POST below would 409 ("de-DE already exists"). Re-read, and
            # give that empty record the en-US support URL like a new one.
            vraw = get(f"/appStoreVersions/{vid}/appStoreVersionLocalizations",
                       limit=40)["data"]
            vlocs = {d["attributes"]["locale"]: d["id"] for d in vraw}
        fields = [("description", read(folder, "description")),
                  ("keywords", read(folder, "keywords")),
                  ("promotionalText", read(folder, "promotional_text"))]
        # "What's New" belongs to an UPDATE. macOS has never shipped, so this
        # is a first release and the field is refused outright:
        # "Attribute 'whatsNew' cannot be edited at this time".
        if not first_release:
            fields.append(("whatsNew", read(folder, "release_notes")))
        body = {k: v for k, v in fields if v}
        if locale not in vlocs:
            body["locale"] = locale
            for k in ("supportUrl", "marketingUrl"):
                if en_ver.get(k):
                    body[k] = en_ver[k]
            made = post("/appStoreVersionLocalizations", {
                "data": {"type": "appStoreVersionLocalizations",
                         "attributes": body,
                         "relationships": {"appStoreVersion": {
                             "data": {"type": "appStoreVersions", "id": vid}}}}})
            vlocs[locale] = made["data"]["id"]
            print(f"  + {locale}")
        else:
            have = {d["attributes"]["locale"]: d["attributes"] for d in vraw}
            for k in ("supportUrl", "marketingUrl"):
                if en_ver.get(k) and not have.get(locale, {}).get(k):
                    body[k] = en_ver[k]
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
    mac_dir = os.path.join(APP_DIR, "fastlane", "screenshots_mac")
    for folder, locale in LOCALE_MAP.items():
        # One Mac set for every language: they are photographs of a running
        # window, and the window's own text is what the locale changes.
        d = mac_dir if IS_MAC else os.path.join(screenshots_dir(KEY), folder)
        if not os.path.isdir(d) or locale not in vlocs:
            continue
        pngs = sorted(f for f in os.listdir(d)
                      if f.endswith(".png") and not f.startswith("ipad"))
        if IS_MAC:
            pngs = [f for f in pngs if f[0].isdigit()]
        if not pngs:
            continue
        sets = get(f"/appStoreVersionLocalizations/{vlocs[locale]}/appScreenshotSets")["data"]
        sid = next((s["id"] for s in sets
                    if s["attributes"]["screenshotDisplayType"] == PHONE_TYPE), None)
        if sid is None:
            sid = post("/appScreenshotSets", {
                "data": {"type": "appScreenshotSets",
                         "attributes": {"screenshotDisplayType": PHONE_TYPE},
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

    PREVIEW_LOCALES picks which; the default is en-US alone, because a
    locale with no preview of its own falls back to the primary one.
    That default is right for a FIRST upload and wrong for a replacement:
    2.0.0 put the film in all twelve, and a locale that already has one does
    not fall back, so a new film has to be pushed to every locale that holds
    an old one. Apple transcodes after upload; the version can be submitted
    while that is still running.
    """
    aid = app_id()
    vid, _ = find_version(aid)
    # The one WITH an audio track. Apple transcodes a silent App Preview and
    # then fails it with MOV_RESAVE_STEREO — a preview must carry stereo
    # audio, even when there is nothing to hear. tools/record_preview.sh
    # records silent, so a muted stereo track is muxed on afterwards.
    mp4 = os.path.join(REPO, "build", "preview", f"{KEY}_av.mp4")
    if not os.path.exists(mp4):
        raise SystemExit(f"✗ 没有 build/preview/{KEY}_av.mp4（需要带静音立体声音轨）")
    vlocs = {d["attributes"]["locale"]: d["id"] for d in
             get(f"/appStoreVersions/{vid}/appStoreVersionLocalizations",
                 limit=40)["data"]}
    frame = _preview_frame()
    only = os.environ.get("PREVIEW_LOCALES", "en-US").split(",")
    targets = [(lc, vlocs[lc]) for lc in only if lc in vlocs]
    if not targets:
        raise SystemExit(f"✗ 这些语言不存在: {only}")
    made = []
    for lc, lid in targets:
        made.append((lc, _one_preview(lc, lid, mp4)))
    if frame:
        _set_preview_frames(made, frame)


def _set_preview_frames(made, frame):
    """Set the poster frame once Apple has finished transcoding.

    Not inline with the upload: a preview that is still being processed
    answers "Asset Not in Complete state! can't update Image!" with a 409,
    and that used to abort the run after the first locale. The frame is a
    label on a finished asset, so it waits for one.
    """
    import time
    pending = list(made)
    for attempt in range(40):
        still = []
        for lc, pid in pending:
            st = get(f"/appPreviews/{pid}")["data"]["attributes"]
            if st["assetDeliveryState"]["state"] != "COMPLETE":
                still.append((lc, pid))
                continue
            patch(f"/appPreviews/{pid}", {
                "data": {"type": "appPreviews", "id": pid,
                         "attributes": {"previewFrameTimeCode": frame}}})
            print(f"   {lc}: 预览帧 {frame}")
        pending = still
        if not pending:
            print(f"✅ 预览帧 {frame} 已写入 {len(made)} 个语言")
            return
        time.sleep(15)
    print(f"⚠️  还有 {len(pending)} 个语言在转码，预览帧没设上："
          f"{[lc for lc, _ in pending]} — 重跑 preview 这一步即可")


def _preview_frame():
    """The frame the store shows before the film is played.

    From tools/preview_frames.tsv, because leaving it to ASC's default put a
    picture of an empty pitch on the soccer listing: the film opens by
    BUILDING a board, so its first seconds are the emptiest it ever looks.
    PREVIEW_FRAME overrides for a one-off.
    """
    env = os.environ.get("PREVIEW_FRAME")
    if env:
        return env
    table = os.path.join(REPO, "tools", "preview_frames.tsv")
    if os.path.exists(table):
        for line in open(table, encoding="utf-8"):
            if line.startswith("#") or not line.strip():
                continue
            # Columns are padded with tabs to line the file up, so take the
            # first non-empty one after the key rather than cols[1].
            cols = [c.strip() for c in line.split("\t")]
            if cols and cols[0] == KEY:
                rest = [c for c in cols[1:] if c]
                if rest:
                    return rest[0]
    return None


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
    return pv["id"]


def step_build():
    aid = app_id()
    vid, _ = find_version(aid)
    # /builds carries no platform in its attributes — it hangs off the
    # preReleaseVersion relationship, which is why filtering on the attribute
    # silently matched nothing.
    r = get("/builds", **{"filter[app]": aid, "limit": 20,
                          "sort": "-uploadedDate",
                          "filter[preReleaseVersion.platform]": PLATFORM,
                          "filter[preReleaseVersion.version]": VERSION})
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
    notes_path = os.path.join(APP_DIR, "docs", NOTES_FILE)
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
    print(f"app {aid}  {PLATFORM} {VERSION} {state} ({vid})")
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
    # Only this platform's. Badminton and pickleball still carry MAC_OS
    # drafts left over from the July 4.3 cleanup — READY_FOR_REVIEW, never
    # submitted, and the API will not delete them. Taking the first open
    # submission handed an iOS version to a Mac submission, which Apple
    # answers with "Supported platforms are not compatible".
    subs = [x for x in get(f"/apps/{aid}/reviewSubmissions",
                           **{"filter[state]": "READY_FOR_REVIEW",
                              "limit": 20})["data"]
            if x["attributes"].get("platform") == PLATFORM]
    sub = subs[0] if subs else post("/reviewSubmissions", {
        "data": {"type": "reviewSubmissions",
                 "attributes": {"platform": PLATFORM},
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
