#!/usr/bin/env python3
"""
upload_promo_only.py — push promotional_text.txt to App Store Connect across
all 16 apps × 11 locales WITHOUT bumping a version.

Promotional text is the only listing field Apple lets you edit on the live
(READY_FOR_SALE) version. Description / subtitle / keywords / screenshots
require creating a new app version draft first — those are out of scope
for this script.

Usage:
    python3 tool/upload_promo_only.py              # all 16 apps
    python3 tool/upload_promo_only.py --sku soccer # one app
    python3 tool/upload_promo_only.py --dry-run    # print plan, no API writes
"""
import argparse, jwt, os, sys, time, warnings
import requests
warnings.filterwarnings("ignore")

KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/projects/keys/AuthKey_4A9Y2S3D6X.p8"
META_BASE = "/Users/zhenyusong/projects/board100/tactics_board/fastlane/metadata"

APPS = {
    "tactics_board": "com.zach.tacticsBoard",
    "soccer":        "com.zach.soccerBoard",
    "basketball":    "com.zach.basketballBoard",
    "volleyball":    "com.zach.volleyballBoard",
    "badminton":     "com.zach.badmintonBoard",
    "tennis":        "com.zach.tennisBoard",
    "tableTennis":   "com.zach.tableTennisBoard",
    "pickleball":    "com.zach.pickleballBoard",
    "baseball":      "com.zach.baseballBoard",
    "handball":      "com.zach.handballBoard",
    "rugby":         "com.zach.rugbyBoard",
    "fieldHockey":   "com.zach.fieldHockeyBoard",
    "waterPolo":     "com.zach.waterPoloBoard",
    "sepakTakraw":   "com.zach.sepakTakrawBoard",
    "beachTennis":   "com.zach.beachTennisBoard",
    "footvolley":    "com.zach.footvolleyBoard",
}


def token():
    with open(KEY_FILE) as f:
        pk = f.read()
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        pk, algorithm="ES256", headers={"kid": KEY_ID},
    )


def api(method, url, tok, data=None):
    headers = {"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}
    r = getattr(requests, method)(url, headers=headers, json=data, timeout=30)
    return r.status_code, (r.json() if r.text else {})


def read_promo(app_key, locale):
    path = os.path.join(META_BASE, app_key, locale, "promotional_text.txt")
    if not os.path.exists(path):
        return None
    with open(path) as f:
        s = f.read().strip()
    return s if s else None


def upload_one(app_key, bundle_id, tok, dry_run=False):
    print(f"\n━━━ {app_key} ({bundle_id}) ━━━")

    # Find the live (READY_FOR_SALE) version — promo text is editable there.
    sc, r = api("get", f"https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={bundle_id}", tok)
    if not r.get("data"):
        print(f"  ✗ app not found in ASC (status {sc})")
        return 0, 0
    app_id = r["data"][0]["id"]

    version_id = None
    version_state = None
    for state in ("PREPARE_FOR_SUBMISSION", "READY_FOR_SALE"):
        sc, r = api("get",
                    f"https://api.appstoreconnect.apple.com/v1/apps/{app_id}/appStoreVersions?filter[appStoreState]={state}",
                    tok)
        if r.get("data"):
            version_id = r["data"][0]["id"]
            version_state = state
            break
    if not version_id:
        print(f"  ✗ no PREPARE_FOR_SUBMISSION / READY_FOR_SALE version found")
        return 0, 0
    print(f"  version: {version_state} ({version_id})")

    sc, r = api("get",
                f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=28",
                tok)
    existing = {loc["attributes"]["locale"]: loc["id"] for loc in r.get("data", [])}

    ok = err = 0
    locales_dir = os.path.join(META_BASE, app_key)
    for locale in sorted(os.listdir(locales_dir)):
        if not os.path.isdir(os.path.join(locales_dir, locale)):
            continue
        promo = read_promo(app_key, locale)
        if not promo:
            continue
        if locale not in existing:
            print(f"  - {locale}: ASC has no localization for this locale; skip")
            continue
        loc_id = existing[locale]
        if dry_run:
            print(f"  ⊙ {locale}: would PATCH {len(promo)} chars → {promo[:60]}{'…' if len(promo) > 60 else ''}")
            ok += 1
            continue
        payload = {"data": {"type": "appStoreVersionLocalizations", "id": loc_id,
                            "attributes": {"promotionalText": promo}}}
        sc, r = api("patch",
                    f"https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/{loc_id}",
                    tok, data=payload)
        if 200 <= sc < 300:
            ok += 1
            print(f"  ✓ {locale} ({len(promo)} chars)")
        else:
            err += 1
            errs = r.get("errors", [{}])
            detail = errs[0].get("detail", str(r))[:160] if errs else str(r)[:160]
            print(f"  ✗ {locale}: {sc} — {detail}")
    print(f"  → {ok} updated, {err} errors")
    return ok, err


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sku", help="single SKU (default: all 16)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    targets = [args.sku] if args.sku else list(APPS.keys())
    bad = [s for s in targets if s not in APPS]
    if bad:
        print(f"unknown SKU(s): {bad}", file=sys.stderr); return 2

    tok = token()
    total_ok = total_err = 0
    for sku in targets:
        ok, err = upload_one(sku, APPS[sku], tok, dry_run=args.dry_run)
        total_ok += ok
        total_err += err
    print(f"\n{'DRY-RUN' if args.dry_run else 'DONE'}: {total_ok} locales updated, {total_err} errors")
    return 0 if total_err == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
