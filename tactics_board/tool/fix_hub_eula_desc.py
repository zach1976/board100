#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fix the hub app's 3.1.2 rejection (auto-renewable subscription requires a
functional Terms of Use / EULA link in the app metadata).

Two edits per locale, applied to the editable appStoreVersionLocalizations:
  1. Replace the now-false "Free, no in-app purchases" bullet (1.1.17 ships the
     Remove-Ads products) with truthful localized copy.
  2. Append the standard Apple Terms of Use (EULA) link.

Idempotent-ish: asserts the old line is present and the footer is absent, so a
second run is a no-op (it will assert-fail loudly rather than double-append).

Run `dry` (default) to preview, `apply` to PATCH ASC.

NOTE: this only fixes metadata. The resubmit itself is Console-only — the first
IAP/subscription cannot be attached to a reviewSubmission via API (verified:
reviewSubmissionItems rejects inAppPurchaseV2/subscription relationships). After
this runs, open the 1.1.17 version in App Store Connect, attach both Remove-Ads
products, and Submit for Review.
"""
import jwt, time, requests, warnings, json, sys
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
PK = open("/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8").read()
B = "https://api.appstoreconnect.apple.com"
APP_ID = "6761408675"  # com.zach.tacticsBoard (hub)
EULA_URL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
APPLY = "apply" in sys.argv

# locale -> (old false line, truthful replacement, localized "Terms of Use" label)
REPL = {
    "zh-Hant": ("· 完全免費，無內購", "· 免費使用 — 可選購「移除廣告」", "使用條款 (EULA)："),
    "th": ("· ฟรี ไม่มีค่าใช้จ่ายในแอป", '· ใช้ฟรี — ซื้อ "ลบโฆษณา" ได้ตามต้องการ', "ข้อกำหนดการใช้งาน (EULA): "),
    "es-ES": ("- Gratis, sin compras integradas", "- Gratis — compra opcional para Quitar anuncios", "Términos de uso (EULA): "),
    "zh-Hans": ("· 完全免费，无内购", "· 免费使用 — 可选购「移除广告」", "使用条款 (EULA)："),
    "ms": ("- Percuma, tiada pembelian dalam aplikasi", "- Percuma — beli pilihan untuk Buang Iklan", "Terma Penggunaan (EULA): "),
    "fr-FR": ("- Gratuit, sans achat intégré", "- Gratuit — achat facultatif pour supprimer les pubs", "Conditions d’utilisation (EULA) : "),
    "id": ("- Gratis, tanpa pembelian dalam aplikasi", "- Gratis — pembelian opsional untuk Hapus Iklan", "Ketentuan Penggunaan (EULA): "),
    "en-US": ("- Free, no in-app purchases", "- Free to use — optional Remove Ads purchase", "Terms of Use (EULA): "),
    "ja": ("・完全無料、課金なし", "・無料で使える — 「広告除去」は任意購入", "利用規約 (EULA)："),
    "ko": ("· 완전 무료, 인앱결제 없음", "· 무료 사용 — 「광고 제거」 선택 구매", "이용약관 (EULA): "),
    "vi": ("- Miễn phí, không mua trong app", "- Miễn phí — tùy chọn mua Xóa quảng cáo", "Điều khoản sử dụng (EULA): "),
}


def tok():
    return jwt.encode({"iss": ISSUER, "iat": int(time.time()), "exp": int(time.time()) + 1200,
                       "aud": "appstoreconnect-v1"}, PK, algorithm="ES256", headers={"kid": KEY_ID})


def api(method, path, data=None):
    for _ in range(6):
        try:
            r = requests.request(method, B + path,
                                 headers={"Authorization": f"Bearer {tok()}", "Content-Type": "application/json"},
                                 json=data, verify=False, timeout=30)
            if r.status_code >= 400:
                return {"_err": r.status_code, "_body": r.json() if r.text else {}}
            return r.json() if r.text else {"_ok": True}
        except Exception:
            time.sleep(2)
    raise SystemExit("network fail")


def main():
    # newest editable version (REJECTED after the 3.1.2 bounce, or PREPARE_FOR_SUBMISSION)
    v = api("GET", f"/v1/apps/{APP_ID}/appStoreVersions"
                   "?filter[appStoreState]=PREPARE_FOR_SUBMISSION,REJECTED,DEVELOPER_REJECTED&limit=1")
    if not v.get("data"):
        sys.exit("no editable version found")
    vid = v["data"][0]["id"]
    print("version", v["data"][0]["attributes"]["versionString"], v["data"][0]["attributes"]["appStoreState"], vid)

    for loc in api("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations").get("data", []):
        a = loc["attributes"]
        code = a["locale"]
        if code not in REPL:
            print(f"  {code}: no rule, skipped")
            continue
        old, new, label = REPL[code]
        desc = a["description"] or ""
        footer = label + EULA_URL
        assert old in desc, f"{code}: old line not found (already edited?)"
        assert footer not in desc, f"{code}: footer already present"
        newdesc = desc.replace(old, new) + "\n\n" + footer
        print(f"\n### {code}  {len(desc)} -> {len(newdesc)} chars")
        print("  -", repr(old))
        print("  +", repr(new))
        print("  + footer:", repr(footer))
        if APPLY:
            r = api("PATCH", f"/v1/appStoreVersionLocalizations/{loc['id']}", {"data": {
                "type": "appStoreVersionLocalizations", "id": loc["id"],
                "attributes": {"description": newdesc}}})
            print("   PATCH:", "ok" if not r.get("_err") else "ERR " + json.dumps(r["_body"]))

    print("\n" + ("APPLIED — now Submit for Review in App Store Connect (attach both Remove-Ads products)."
                  if APPLY else "DRY-RUN (no changes written). Re-run with 'apply'."))


if __name__ == "__main__":
    main()
