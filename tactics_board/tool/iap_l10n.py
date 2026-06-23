#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Check / add localizations for the lifetime Remove-Ads IAP across the 15
single-sport apps (and hub). The app ships 12 locales but the IAP was created
en-US only; the system purchase sheet shows this name/description, so localize it.

  python3 tool/iap_l10n.py check              # report locale count per app
  python3 tool/iap_l10n.py add soccer         # add missing locales to one app
  python3 tool/iap_l10n.py add                # all apps
"""
import jwt, time, requests, warnings, sys
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
PK = open("/Users/zhenyusong/projects/keys/AuthKey_4A9Y2S3D6X.p8").read()
B = "https://api.appstoreconnect.apple.com"
SPORTS = ["soccer", "basketball", "volleyball", "badminton", "tennis",
          "tableTennis", "pickleball", "fieldHockey", "rugby", "baseball",
          "handball", "waterPolo", "beachTennis", "footvolley", "sepakTakraw"]

# name (<=30) / description (<=45) per locale. en-GB mirrors en-US.
L10N = {
    "en-GB": ("Remove Ads", "Remove all ads permanently."),
    "es-ES": ("Quitar anuncios", "Elimina los anuncios para siempre."),
    "fr-FR": ("Supprimer les pubs", "Supprime toutes les pubs définitivement."),
    "id": ("Hapus Iklan", "Hapus semua iklan secara permanen."),
    "ja": ("広告を削除", "すべての広告を完全に削除します。"),
    "ko": ("광고 제거", "모든 광고를 영구적으로 제거합니다."),
    "ms": ("Buang Iklan", "Buang semua iklan secara kekal."),
    "th": ("ลบโฆษณา", "ลบโฆษณาทั้งหมดอย่างถาวร"),
    "vi": ("Xóa quảng cáo", "Xóa toàn bộ quảng cáo vĩnh viễn."),
    "zh-Hans": ("移除广告", "永久移除所有广告。"),
    "zh-Hant": ("移除廣告", "永久移除所有廣告。"),
}


def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200,
                       "aud": "appstoreconnect-v1"}, PK, algorithm="ES256", headers={"kid": KEY_ID})


def G(path):
    return requests.get(B + path, headers={"Authorization": f"Bearer {tok()}"}, verify=False, timeout=60)


def P(path, body):
    return requests.post(B + path, headers={"Authorization": f"Bearer {tok()}",
                         "Content-Type": "application/json"}, json=body, verify=False, timeout=60)


def errs(r):
    try:
        return "; ".join(e.get("detail", e.get("title", "?")) for e in r.json().get("errors", []))
    except Exception:
        return r.text[:200]


def iap_id(sport):
    bundle = f"com.zach.{sport}Board"
    a = G(f"/v1/apps?filter[bundleId]={bundle}").json().get("data")
    if not a:
        return None, None
    aid = a[0]["id"]
    pid = f"{sport.lower()}_remove_ads_lifetime"
    d = G(f"/v1/apps/{aid}/inAppPurchasesV2?filter[productId]={pid}&limit=1").json().get("data")
    return (d[0]["id"] if d else None), (d[0]["attributes"]["state"] if d else None)


def existing_locales(iid):
    return {l["attributes"]["locale"]: l["id"]
            for l in G(f"/v2/inAppPurchases/{iid}/inAppPurchaseLocalizations").json().get("data", [])}


def check():
    for s in SPORTS:
        iid, st = iap_id(s)
        if not iid:
            print(f"{s:14s} NO IAP"); continue
        locs = existing_locales(iid)
        print(f"{s:14s} state={st:20s} locales({len(locs)}): {','.join(sorted(locs))}")


def add(sport):
    iid, st = iap_id(sport)
    if not iid:
        print(f"{sport:14s} NO IAP"); return
    have = existing_locales(iid)
    added = skipped = failed = 0
    for loc, (name, desc) in L10N.items():
        if loc in have:
            skipped += 1; continue
        r = P("/v1/inAppPurchaseLocalizations", {"data": {"type": "inAppPurchaseLocalizations",
            "attributes": {"name": name, "locale": loc, "description": desc},
            "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iid}}}}})
        if r.ok:
            added += 1
        else:
            failed += 1
            print(f"  {sport} {loc} ERR {r.status_code} {errs(r)}")
    print(f"{sport:14s} state={st:20s} +{added} added, {skipped} existed, {failed} failed")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "check"
    if cmd == "check":
        check()
    elif cmd == "add":
        for s in (sys.argv[2:] or SPORTS):
            add(s)
