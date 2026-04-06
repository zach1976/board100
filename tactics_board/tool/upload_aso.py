#!/usr/bin/env python3
"""Upload ASO metadata (keywords, promotional_text) to App Store Connect API."""
import jwt, time, requests, json, os, sys

KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
KEY_FILE = "/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8"
META_BASE = "/Users/zhenyusong/Desktop/projects/board100/tactics_board/fastlane/metadata"

APPS = {
    "tactics_board": "com.zach.tacticsBoard",
    "soccer": "com.zach.soccerBoard",
    "basketball": "com.zach.basketballBoard",
    "volleyball": "com.zach.volleyballBoard",
    "badminton": "com.zach.badmintonBoard",
    "tennis": "com.zach.tennisBoard",
    "tableTennis": "com.zach.tableTennisBoard",
    "pickleball": "com.zach.pickleballBoard",
}

def get_token():
    with open(KEY_FILE) as f:
        key = f.read()
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        key, algorithm="ES256", headers={"kid": KEY_ID}
    )

def api(method, url, data=None):
    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json",
    }
    r = getattr(requests, method)(url, headers=headers, json=data)
    if r.status_code >= 400:
        print(f"  ERROR {r.status_code}: {r.text[:200]}")
    return r.json() if r.text else {}

def read_file(app, locale, filename):
    path = os.path.join(META_BASE, app, locale, filename)
    if os.path.exists(path):
        with open(path) as f:
            return f.read().strip()
    return None

TOKEN = get_token()

for app_key, bundle_id in APPS.items():
    print(f"\n━━━ {app_key} ({bundle_id}) ━━━")

    # Get app ID
    r = api("get", f"https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={bundle_id}")
    if not r.get("data"):
        print(f"  App not found!")
        continue
    app_id = r["data"][0]["id"]

    # Find editable version (PREPARE_FOR_SUBMISSION first, then try READY_FOR_SALE)
    version_id = None
    for state in ["PREPARE_FOR_SUBMISSION", "READY_FOR_SALE"]:
        r = api("get", f"https://api.appstoreconnect.apple.com/v1/apps/{app_id}/appStoreVersions?filter[appStoreState]={state}")
        if r.get("data"):
            version_id = r["data"][0]["id"]
            version_state = state
            break

    if not version_id:
        print(f"  No editable version found!")
        continue
    print(f"  Version: {version_state} ({version_id})")

    # Get existing localizations
    r = api("get", f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=28")
    existing_locs = {loc["attributes"]["locale"]: loc["id"] for loc in r.get("data", [])}
    print(f"  Existing locales: {list(existing_locs.keys())}")

    # Update each locale
    locales_dir = os.path.join(META_BASE, app_key)
    updated = 0
    for locale in sorted(os.listdir(locales_dir)):
        locale_path = os.path.join(locales_dir, locale)
        if not os.path.isdir(locale_path):
            continue

        keywords = read_file(app_key, locale, "keywords.txt")
        promo = read_file(app_key, locale, "promotional_text.txt")

        if not keywords and not promo:
            continue

        attrs = {}
        if keywords:
            attrs["keywords"] = keywords
        if promo:
            attrs["promotionalText"] = promo

        if locale in existing_locs:
            # PATCH existing localization
            loc_id = existing_locs[locale]
            data = {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": loc_id,
                    "attributes": attrs,
                }
            }
            api("patch", f"https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/{loc_id}", data)
            updated += 1
        else:
            # POST new localization
            data = {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": {**attrs, "locale": locale},
                    "relationships": {
                        "appStoreVersion": {
                            "data": {"type": "appStoreVersions", "id": version_id}
                        }
                    },
                }
            }
            api("post", "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations", data)
            updated += 1

    print(f"  ✅ Updated {updated} locales")

print("\n🎉 Done!")
