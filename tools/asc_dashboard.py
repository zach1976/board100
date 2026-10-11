#!/usr/bin/env python3 -u
"""Everything App Store Connect holds for the 16 apps, on one HTML page.

Read-only: only GETs. Writes build/asc_dashboard.html and opens it.

    python3 tools/asc_dashboard.py            # all 16 apps
    python3 tools/asc_dashboard.py volleyball soccer
    python3 tools/asc_dashboard.py --full volleyball   # everything, one app

Per app: app info state + name/subtitle per locale, every iOS and macOS
version with its state, the newest version per platform in full (build,
review notes, each locale's text, screenshot thumbnails), recent builds and
review submissions.
"""
import html
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime

import jwt
import requests
import urllib3

urllib3.disable_warnings()

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, "tools"))
from apps import APPS  # noqa: E402

BASE = "https://api.appstoreconnect.apple.com/v1"
# --full: every version in full, plus pricing, territories, age rating,
# categories, in-app purchases, customer reviews and app previews. Meant for
# one app at a time (python3 tools/asc_dashboard.py --full volleyball), and
# then written to build/asc_<key>.html.
FULL = "--full" in sys.argv
_keys = [k for k in sys.argv[1:] if not k.startswith("--")]
OUT = os.path.join(REPO, "build", f"asc_{_keys[0]}.html" if FULL and len(_keys) == 1
                   else "asc_dashboard.html")


def _env(name):
    v = os.environ.get(name)
    envf = os.path.expanduser("~/projects/.env")
    if not v and os.path.exists(envf):
        for line in open(envf):
            line = line.strip()
            if line.startswith(f"{name}="):
                v = line.split("=", 1)[1].strip().strip("'\"")
    if not v:
        raise SystemExit(f"✗ 缺少 {name}（环境变量或 ~/projects/.env）")
    return v


KEY_ID, ISSUER_ID, KEY_FILE = _env("ASC_KEY_ID"), _env("ASC_ISSUER_ID"), _env("ASC_KEY_FILE")
_tok = {"t": None, "exp": 0}


def token():
    if _tok["t"] and time.time() < _tok["exp"] - 120:
        return _tok["t"]
    exp = int(time.time()) + 900
    _tok["t"] = jwt.encode({"iss": ISSUER_ID, "exp": exp, "aud": "appstoreconnect-v1"},
                           open(KEY_FILE).read(), algorithm="ES256",
                           headers={"kid": KEY_ID, "typ": "JWT"})
    _tok["exp"] = exp
    return _tok["t"]


def get(path, **params):
    """GET only. Errors come back as {"_error": ...} so one bad call shows on
    the page instead of killing the whole run."""
    url = path if path.startswith("http") else BASE + path
    for attempt in range(4):
        try:
            r = requests.get(url, headers={"Authorization": f"Bearer {token()}"},
                             params=params or None, verify=False, timeout=90)
        except Exception as e:  # network blip
            if attempt == 3:
                return {"_error": str(e), "data": []}
            time.sleep(2 + attempt * 2)
            continue
        if r.status_code == 429 or r.status_code >= 500:
            time.sleep(5 + attempt * 5)
            continue
        if r.status_code >= 400:
            return {"_error": f"{r.status_code} {r.text[:200]}", "data": []}
        return r.json()
    return {"_error": f"{r.status_code}", "data": []}


def version_detail(vid):
    out = {}
    b = get(f"/appStoreVersions/{vid}/build").get("data") or {}
    out["build"] = (b.get("attributes") or {}).get("version")
    d = get(f"/appStoreVersions/{vid}/appStoreReviewDetail").get("data") or {}
    out["review"] = d.get("attributes") or {}
    def one(l):
        a = l["attributes"]
        sets = get(f"/appStoreVersionLocalizations/{l['id']}/appScreenshotSets",
                   include="appScreenshots", **{"limit[appScreenshots]": 10})
        shots = {s["id"]: s["attributes"] for s in sets.get("included", [])
                 if s["type"] == "appScreenshots"}
        ss = []
        for s in sets["data"]:
            ids = [x["id"] for x in s["relationships"]["appScreenshots"].get("data") or []]
            ss.append({"type": s["attributes"]["screenshotDisplayType"],
                       "shots": [shots[i] for i in ids if i in shots]})
        pv = []
        if FULL:
            psets = get(f"/appStoreVersionLocalizations/{l['id']}/appPreviewSets",
                        include="appPreviews", **{"limit[appPreviews]": 10})
            pinc = {x["id"]: x["attributes"] for x in psets.get("included", [])}
            for ps in psets["data"]:
                ids = [x["id"] for x in ps["relationships"]["appPreviews"].get("data") or []]
                pv.append({"type": ps["attributes"]["previewType"],
                           "items": [pinc[i] for i in ids if i in pinc]})
        return {"locale": a["locale"], "attrs": a, "sets": ss, "previews": pv}
    with ThreadPoolExecutor(6) as ex:
        locs = list(ex.map(one, get(f"/appStoreVersions/{vid}/appStoreVersionLocalizations", limit=50)["data"]))
    out["locs"] = sorted(locs, key=lambda x: x["locale"])
    if FULL:
        ph = get(f"/appStoreVersions/{vid}/appStoreVersionPhasedRelease").get("data") or {}
        out["phased"] = ph.get("attributes")
    return out


def extras(aid, info_ids):
    x = {"categories": [], "age": []}
    for iid in info_ids:
        cats = []
        for rel in ("primaryCategory", "primarySubcategoryOne", "secondaryCategory"):
            c = get(f"/appInfos/{iid}/{rel}").get("data")
            if c:
                cats.append(f"{rel}: {c['id']}")
        x["categories"].append(cats)
        x["age"].append((get(f"/appInfos/{iid}/ageRatingDeclaration").get("data") or {})
                        .get("attributes") or {})
    pr = get(f"/appPriceSchedules/{aid}/manualPrices", include="appPricePoint,territory", limit=10)
    pts = {p["id"]: p["attributes"] for p in pr.get("included", []) if p["type"] == "appPricePoints"}
    x["prices"] = [dict(p["attributes"], price=pts.get(
        (p["relationships"]["appPricePoint"].get("data") or {}).get("id"), {}).get("customerPrice"))
        for p in pr["data"]]
    base = get(f"/appPriceSchedules/{aid}/baseTerritory").get("data") or {}
    x["base_territory"] = base.get("id")
    root = BASE.replace("/v1", "/v2")
    av = get(f"{root}/appAvailabilities/{aid}").get("data") or {}
    x["new_territories"] = (av.get("attributes") or {}).get("availableInNewTerritories")
    url, avail, unavail = f"{root}/appAvailabilities/{aid}/territoryAvailabilities?limit=200&include=territory", [], []
    while url:
        r = get(url)
        for t in r["data"]:
            tid = (t["relationships"]["territory"].get("data") or {}).get("id")
            (avail if t["attributes"].get("available") else unavail).append(tid)
        url = (r.get("links") or {}).get("next")
    x["territories"] = {"available": sorted(filter(None, avail)), "unavailable": sorted(filter(None, unavail))}
    rv = get(f"/apps/{aid}/customerReviews", sort="-createdDate", limit=100)
    x["reviews"] = [r["attributes"] for r in rv["data"]]
    x["iap"] = [i["attributes"] for i in get(f"/apps/{aid}/inAppPurchasesV2", limit=50)["data"]]
    return x


def fetch_app(key):
    bundle = APPS[key]["bundle"]
    r = get("/apps", **{"filter[bundleId]": bundle})
    if not r["data"]:
        return {"key": key, "bundle": bundle, "missing": True}
    app = r["data"][0]
    aid = app["id"]
    res = {"key": key, "bundle": bundle, "id": aid, "name": app["attributes"]["name"]}

    infos = []
    for i in get(f"/apps/{aid}/appInfos")["data"]:
        locs = get(f"/appInfos/{i['id']}/appInfoLocalizations", limit=50)["data"]
        infos.append({"state": i["attributes"].get("state") or i["attributes"].get("appStoreState"),
                      "locs": sorted((l["attributes"] for l in locs), key=lambda a: a["locale"])})
    res["infos"] = infos

    versions = get(f"/apps/{aid}/appStoreVersions", limit=50)["data"]
    res["versions"] = [dict(id=v["id"], **v["attributes"]) for v in versions]
    newest = {}
    for v in res["versions"]:  # ASC lists newest first
        newest.setdefault(v["platform"], v)
    res["detail"] = {p: dict(version=v, **version_detail(v["id"])) for p, v in newest.items()}
    if FULL:
        res["app_attrs"] = app["attributes"]
        newest_ids = {v["id"] for v in newest.values()}
        with ThreadPoolExecutor(3) as ex:
            res["older"] = list(ex.map(lambda v: dict(version=v, **version_detail(v["id"])),
                                       [v for v in res["versions"] if v["id"] not in newest_ids]))
        res["extras"] = extras(aid, [i["id"] for i in get(f"/apps/{aid}/appInfos")["data"]])

    builds = get("/builds", **{"filter[app]": aid, "sort": "-uploadedDate", "limit": 8,
                               "include": "preReleaseVersion"})
    pre = {x["id"]: x["attributes"] for x in builds.get("included", [])}
    res["builds"] = []
    for b in builds["data"]:
        pr = pre.get((b["relationships"]["preReleaseVersion"].get("data") or {}).get("id"), {})
        res["builds"].append(dict(b["attributes"], marketing=pr.get("version"),
                                  platform=pr.get("platform")))

    subs = get("/reviewSubmissions", **{"filter[app]": aid, "limit": 8})
    res["submissions"] = [s["attributes"] for s in subs["data"]]
    res["submissions"].sort(key=lambda s: s.get("submittedDate") or "", reverse=True)
    return res


# ---------------------------------------------------------------- HTML

E = lambda s: html.escape(str(s if s is not None else ""))

STATE_CLASS = {
    "READY_FOR_SALE": "ok", "READY_FOR_DISTRIBUTION": "ok", "ACCEPTED": "ok",
    "COMPLETE": "ok", "VALID": "ok", "APPROVED": "ok",
    "WAITING_FOR_REVIEW": "wait", "IN_REVIEW": "wait", "PENDING_DEVELOPER_RELEASE": "wait",
    "PROCESSING": "wait", "READY_FOR_REVIEW": "wait", "WAITING_FOR_EXPORT_COMPLIANCE": "wait",
    "UNRESOLVED_ISSUES": "bad",
    "REJECTED": "bad", "METADATA_REJECTED": "bad", "INVALID_BINARY": "bad", "INVALID": "bad",
    "DEVELOPER_REJECTED": "muted", "REMOVED_FROM_SALE": "muted", "CANCELING": "muted",
    "PREPARE_FOR_SUBMISSION": "edit", "READY_FOR_SUBMISSION": "edit",
}


def pill(state):
    return f'<span class="pill {STATE_CLASS.get(state, "")}">{E(state or "—")}</span>'


def day(s):
    return E((s or "")[:16].replace("T", " "))


def thumb(a):
    t = (a.get("imageAsset") or {}).get("templateUrl")
    if not t:
        return f'<span class="noimg">{E(a.get("fileName"))}</span>'
    small = t.replace("{w}", "180").replace("{h}", "400").replace("{f}", "png")
    big = t.replace("{w}", "1290").replace("{h}", "2796").replace("{f}", "png")
    return f'<a href="{E(big)}" target="_blank"><img loading="lazy" src="{E(small)}" title="{E(a.get("fileName"))}"></a>'


def render_detail(p, d):
    v = d["version"]
    rv = d["review"]
    h = [f'<h4>{E(p)} {E(v["versionString"])} {pill(v["appStoreState"])} '
         f'<span class="dim">build {E(d["build"] or "未附加")} · {E(v.get("releaseType"))}'
         f' · 加密 {E(v.get("usesNonExemptEncryption"))} · 建于 {day(v.get("createdDate"))}</span></h4>']
    h.append('<details><summary>Review 信息'
             f' <span class="dim">notes {len(rv.get("notes") or "")} 字 · 联系人 '
             f'{E(rv.get("contactFirstName"))} {E(rv.get("contactLastName"))} '
             f'{E(rv.get("contactEmail"))} · demo 账号 {"需要" if rv.get("demoAccountRequired") else "不需要"}'
             f'</span></summary><pre>{E(rv.get("notes"))}</pre></details>')
    for l in d["locs"]:
        a = l["attrs"]
        nshots = sum(len(s["shots"]) for s in l["sets"])
        h.append(f'<details class="loc"><summary><b>{E(l["locale"])}</b> <span class="dim">'
                 f'desc {len(a.get("description") or "")} · kw {len(a.get("keywords") or "")} · '
                 f'新功能 {len(a.get("whatsNew") or "")} · 推广 {len(a.get("promotionalText") or "")} · '
                 f'截图 {len(l["sets"])} 组 {nshots} 张</span></summary>')
        h.append('<div class="grid2">')
        for label, k in (("关键词", "keywords"), ("推广文本", "promotionalText"),
                         ("新功能", "whatsNew"), ("描述", "description")):
            h.append(f'<div><div class="lbl">{label}</div><pre>{E(a.get(k))}</pre></div>')
        h.append(f'<div class="dim">support {E(a.get("supportUrl"))} · marketing {E(a.get("marketingUrl"))}</div>')
        h.append('</div>')
        for s in l["sets"]:
            h.append(f'<div class="lbl">{E(s["type"])} · {len(s["shots"])} 张</div><div class="shots">'
                     + "".join(thumb(x) for x in s["shots"]) + '</div>')
        for pv in l.get("previews") or []:
            h.append(f'<div class="lbl">预览片 {E(pv["type"])} · {len(pv["items"])} 段</div><div class="dim">'
                     + "、".join(f'{E(i.get("fileName"))}（{E((i.get("assetDeliveryState") or {}).get("state"))}）'
                                 for i in pv["items"]) + '</div>')
        h.append('</details>')
    if d.get("phased"):
        h.append(f'<div class="dim">分阶段发布：{E(d["phased"])}</div>')
    return "".join(h)


def kv_table(d):
    return ('<table>' + "".join(f'<tr><td class="dim">{E(k)}</td><td>{E(v)}</td></tr>'
                                for k, v in d.items() if not isinstance(v, (dict, list)))
            + '</table>')


def render_extras(a):
    x = a["extras"]
    h = ['<div class="ver"><h4>App 资料</h4>', kv_table(a.get("app_attrs") or {})]
    for i, cats in enumerate(x["categories"]):
        h.append(f'<div class="lbl">分类（App 信息 #{i + 1}）</div><div>{E("；".join(cats) or "—")}</div>')
    for i, age in enumerate(x["age"]):
        h.append(f'<details><summary>年龄分级问卷（App 信息 #{i + 1}）</summary>{kv_table(age)}</details>')
    h.append('<h4>价格与上架区域</h4><table><tr><th>价格</th><th>起</th><th>止</th><th>手动</th></tr>')
    for p in x["prices"]:
        h.append(f'<tr><td>{E(p.get("price"))}</td><td>{E(p.get("startDate"))}</td>'
                 f'<td>{E(p.get("endDate"))}</td><td>{E(p.get("manual"))}</td></tr>')
    t = x["territories"]
    h.append(f'</table><div>基准地区 {E(x["base_territory"])} · 新地区自动上架 {E(x["new_territories"])} · '
             f'上架 <b>{len(t["available"])}</b> 个，未上架 {len(t["unavailable"])} 个</div>'
             f'<details><summary>地区清单</summary><div class="lbl">上架</div><pre>{E(" ".join(t["available"]))}</pre>'
             f'<div class="lbl">未上架</div><pre>{E(" ".join(t["unavailable"]))}</pre></details>')
    h.append(f'<h4>App 内购买 <span class="dim">{len(x["iap"])} 个</span></h4>')
    for i in x["iap"]:
        h.append(kv_table(i))
    h.append(f'<h4>用户评价 <span class="dim">{len(x["reviews"])} 条</span></h4><table>'
             '<tr><th>日期</th><th>地区</th><th>星</th><th>标题</th><th>内容</th></tr>')
    for r in x["reviews"]:
        h.append(f'<tr><td>{day(r.get("createdDate"))}</td><td>{E(r.get("territory"))}</td>'
                 f'<td>{"★" * (r.get("rating") or 0)}</td><td>{E(r.get("title"))}</td>'
                 f'<td>{E(r.get("body"))}</td></tr>')
    h.append('</table></div>')
    return "".join(h)


def render_app(a):
    if a.get("missing"):
        return f'<section id="{E(a["key"])}"><h2>{E(a["key"])}</h2><p class="bad">ASC 里找不到 {E(a["bundle"])}</p></section>'
    h = [f'<section id="{E(a["key"])}"><h2>{E(a["name"])} <span class="dim">{E(a["key"])} · '
         f'{E(a["bundle"])} · <a href="https://appstoreconnect.apple.com/apps/{E(a["id"])}/distribution" '
         f'target="_blank">{E(a["id"])}</a></span></h2>']

    for info in a["infos"]:
        h.append(f'<details><summary>App 信息 {pill(info["state"])} <span class="dim">'
                 f'{len(info["locs"])} 语言</span></summary><table><tr><th>语言</th><th>名称</th>'
                 '<th>副标题</th><th>隐私政策</th></tr>')
        for l in info["locs"]:
            h.append(f'<tr><td>{E(l["locale"])}</td><td>{E(l.get("name"))}</td>'
                     f'<td>{E(l.get("subtitle"))}</td><td class="dim">{E(l.get("privacyPolicyUrl"))}</td></tr>')
        h.append('</table></details>')

    h.append('<details><summary>全部版本 <span class="dim">'
             f'{len(a["versions"])} 个</span></summary><table><tr><th>平台</th><th>版本</th>'
             '<th>状态</th><th>建于</th><th>发布方式</th></tr>')
    for v in a["versions"]:
        h.append(f'<tr><td>{E(v["platform"])}</td><td>{E(v["versionString"])}</td>'
                 f'<td>{pill(v["appStoreState"])}</td><td>{day(v.get("createdDate"))}</td>'
                 f'<td>{E(v.get("releaseType"))}</td></tr>')
    h.append('</table></details>')

    h.append('<details><summary>最近 build</summary><table><tr><th>平台</th><th>版本</th>'
             '<th>build</th><th>处理</th><th>上传</th><th>过期</th></tr>')
    for b in a["builds"]:
        h.append(f'<tr><td>{E(b.get("platform"))}</td><td>{E(b.get("marketing"))}</td>'
                 f'<td>{E(b.get("version"))}</td><td>{pill(b.get("processingState"))}</td>'
                 f'<td>{day(b.get("uploadedDate"))}</td><td>{"已过期" if b.get("expired") else ""}</td></tr>')
    h.append('</table></details>')

    h.append('<details><summary>送审记录</summary><table><tr><th>平台</th><th>状态</th>'
             '<th>提交时间</th></tr>')
    for s in a["submissions"]:
        h.append(f'<tr><td>{E(s.get("platform"))}</td><td>{pill(s.get("state"))}</td>'
                 f'<td>{day(s.get("submittedDate"))}</td></tr>')
    h.append('</table></details>')

    for p in sorted(a["detail"]):
        h.append(f'<div class="ver">{render_detail(p, a["detail"][p])}</div>')
    if a.get("older"):
        h.append(f'<div class="ver"><h4>更早的版本（{len(a["older"])} 个，全部内容）</h4>')
        for d in a["older"]:
            h.append(f'<details><summary>{E(d["version"]["platform"])} {E(d["version"]["versionString"])} '
                     f'{pill(d["version"]["appStoreState"])}</summary>{render_detail(d["version"]["platform"], d)}</details>')
        h.append('</div>')
    if a.get("extras"):
        h.append(render_extras(a))
    h.append('</section>')
    return "".join(h)


def live(a, platform):
    for v in a.get("versions", []):
        if v["platform"] == platform and v["appStoreState"] in ("READY_FOR_SALE", "READY_FOR_DISTRIBUTION"):
            return v["versionString"]
    return "—"


def render_summary(apps):
    rows = ['<table class="summary"><tr><th>App</th><th>iOS 线上</th><th>iOS 最新</th>'
            '<th>build</th><th>macOS 线上</th><th>macOS 最新</th><th>App 信息</th><th>最近送审</th></tr>']
    for a in apps:
        if a.get("missing"):
            rows.append(f'<tr><td>{E(a["key"])}</td><td colspan="7" class="bad">找不到</td></tr>')
            continue
        cells = [f'<td><a href="#{E(a["key"])}">{E(a["name"])}</a></td>', f'<td>{E(live(a, "IOS"))}</td>']
        for p in ("IOS", "MAC_OS"):
            d = a["detail"].get(p)
            if p == "MAC_OS":
                cells.append(f'<td>{E(live(a, "MAC_OS"))}</td>')
            if d:
                cells.append(f'<td>{E(d["version"]["versionString"])} {pill(d["version"]["appStoreState"])}</td>')
            else:
                cells.append('<td>—</td>')
            if p == "IOS":
                cells.append(f'<td>{E(d["build"] if d else "") or "—"}</td>')
        cells.append('<td>' + " ".join(pill(i["state"]) for i in a["infos"]) + '</td>')
        s = a["submissions"][0] if a["submissions"] else {}
        cells.append(f'<td>{pill(s.get("state")) if s else "—"} <span class="dim">'
                     f'{E(s.get("platform"))} {day(s.get("submittedDate"))}</span></td>')
        rows.append("<tr>" + "".join(cells) + "</tr>")
    rows.append("</table>")
    return "".join(rows)


CSS = """
:root{--bg:#f6f7f9;--card:#fff;--fg:#1d2128;--dim:#6b7380;--line:#e3e6eb;
--ok:#1f8a4c;--okb:#e3f5ea;--wait:#a86b00;--waitb:#fff3dc;--bad:#c62f2f;--badb:#fde8e8;
--edit:#2b5fc7;--editb:#e6eeff;--mutedb:#eceef1}
@media (prefers-color-scheme:dark){:root{--bg:#121417;--card:#1b1e23;--fg:#e6e8eb;--dim:#959ba5;
--line:#2c3138;--okb:#163223;--waitb:#3a2d10;--badb:#3d1717;--editb:#18264a;--mutedb:#262a30;
--ok:#5fd08d;--wait:#f0b44c;--bad:#ff7b7b;--edit:#86a8ff}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);
font:14px/1.5 -apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif}
main{max-width:1200px;margin:0 auto;padding:24px 16px}
h1{font-size:22px;margin:0 0 4px}h2{font-size:18px;margin:0 0 10px}h4{margin:14px 0 6px;font-size:15px}
a{color:var(--edit)}.dim{color:var(--dim);font-weight:normal;font-size:12.5px}
section{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:16px;margin:16px 0}
table{border-collapse:collapse;width:100%;font-size:13px;margin:6px 0}
th,td{text-align:left;padding:5px 8px;border-bottom:1px solid var(--line);vertical-align:top}
th{color:var(--dim);font-weight:600}
.summary{background:var(--card);border:1px solid var(--line);border-radius:12px;overflow:hidden}
.wrap{overflow-x:auto}
.pill{display:inline-block;padding:1px 7px;border-radius:99px;font-size:11.5px;font-weight:600;
background:var(--mutedb);color:var(--dim);white-space:nowrap}
.pill.ok{background:var(--okb);color:var(--ok)}.pill.wait{background:var(--waitb);color:var(--wait)}
.pill.bad{background:var(--badb);color:var(--bad)}.pill.edit{background:var(--editb);color:var(--edit)}
p.bad{color:var(--bad)}
details{margin:4px 0}summary{cursor:pointer;padding:3px 0}
details.loc{border-top:1px solid var(--line);padding:2px 0}
pre{white-space:pre-wrap;word-break:break-word;background:var(--bg);border-radius:8px;padding:8px;
margin:4px 0;font:12.5px/1.45 ui-monospace,Menlo,monospace;max-height:320px;overflow:auto}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:8px}
@media (max-width:700px){.grid2{grid-template-columns:1fr}}
.lbl{font-size:12px;color:var(--dim);margin-top:6px}
.shots{display:flex;gap:6px;overflow-x:auto;padding:4px 0}
.shots img{height:160px;border-radius:6px;border:1px solid var(--line);display:block}
.ver{border-top:2px solid var(--line);margin-top:10px}
"""


def main():
    keys = [k for k in sys.argv[1:] if not k.startswith("--")] or list(APPS)
    bad = [k for k in keys if k not in APPS]
    if bad:
        raise SystemExit(f"✗ 不认识：{bad}")
    t0 = time.time()
    with ThreadPoolExecutor(4) as ex:
        apps = list(ex.map(fetch_app, keys))
    for a in apps:
        print(f"  {a['key']:14s} {'找不到' if a.get('missing') else 'ok'}")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    page = (f'<!doctype html><html lang="zh"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width,initial-scale=1">'
            f'<title>ASC 总览</title><style>{CSS}</style></head><body><main>'
            f'<h1>App Store Connect 总览</h1><div class="dim">{now} 拉取 · {len(apps)} 个 app · '
            f'只读 · 重新生成：python3 tools/asc_dashboard.py</div>'
            f'<div class="wrap">{render_summary(apps)}</div>'
            + "".join(render_app(a) for a in apps) + '</main></body></html>')
    open(OUT, "w").write(page)
    json.dump(apps, open(OUT.replace(".html", ".json"), "w"), ensure_ascii=False, indent=1)
    print(f"✓ {OUT}  ({time.time() - t0:.0f}s)")
    if os.environ.get("NO_OPEN") != "1":
        subprocess.run(["open", OUT])


if __name__ == "__main__":
    main()
