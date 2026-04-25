#!/usr/bin/env python3
"""Populate required App Store metadata for the 8 new apps via ASC API.

Clones the reference settings from badmintonBoard:
- primaryCategory = SPORTS
- Age Rating = all NONE/false (4+)
- contentRightsDeclaration = DOES_NOT_USE_THIRD_PARTY_CONTENT
- Price = Free (USA base, no manual prices)
- Review contact info
- Privacy Policy URL, Support URL, Marketing URL
- description/keywords/whatsNew from fastlane/metadata/<sport>/<locale>/

Then attaches the 1.1.6 build to the appStoreVersion.
App Privacy (data collection answers) must still be set via web UI — this
script will print a warning if the endpoint isn't accessible.
"""
import jwt, time, json, os, sys, warnings
import requests as _requests

warnings.filterwarnings("ignore")

KEY_FILE = "/Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8"
KEY_ID = "4A9Y2S3D6X"
ISSUER_ID = "3d46fac5-4873-4806-bf23-3f8f17eddbbe"
BASE = "https://api.appstoreconnect.apple.com"
META_BASE = os.path.join(os.path.dirname(__file__), "..", "fastlane", "metadata")

NEW_APPS = [
    ("com.zach.fieldHockeyBoard", "fieldHockey"),
    ("com.zach.rugbyBoard", "rugby"),
    ("com.zach.baseballBoard", "baseball"),
    ("com.zach.handballBoard", "handball"),
    ("com.zach.waterPoloBoard", "waterPolo"),
    ("com.zach.sepakTakrawBoard", "sepakTakraw"),
    ("com.zach.beachTennisBoard", "beachTennis"),
    ("com.zach.footvolleyBoard", "footvolley"),
]

LOCALES = ["en-US", "zh-Hans", "zh-Hant", "ja", "ko", "fr-FR", "es-ES", "vi", "th", "id", "ms"]

AGE_RATING = {
    "advertising": False,
    "alcoholTobaccoOrDrugUseOrReferences": "NONE",
    "contests": "NONE",
    "gambling": False,
    "gamblingSimulated": "NONE",
    "gunsOrOtherWeapons": "NONE",
    "healthOrWellnessTopics": False,
    "lootBox": False,
    "medicalOrTreatmentInformation": "NONE",
    "messagingAndChat": False,
    "parentalControls": False,
    "profanityOrCrudeHumor": "NONE",
    "ageAssurance": False,
    "sexualContentGraphicAndNudity": "NONE",
    "sexualContentOrNudity": "NONE",
    "horrorOrFearThemes": "NONE",
    "matureOrSuggestiveThemes": "NONE",
    "unrestrictedWebAccess": False,
    "userGeneratedContent": False,
    "violenceCartoonOrFantasy": "NONE",
    "violenceRealisticProlongedGraphicOrSadistic": "NONE",
    "violenceRealistic": "NONE",
}

REVIEW_DETAIL = {
    "contactFirstName": "Zhenyu",
    "contactLastName": "Song",
    "contactPhone": "+16266166860",
    "contactEmail": "zach@100for1.com",
    "demoAccountRequired": False,
    "notes": "No login required. All features are accessible immediately.",
}

PRIVACY_POLICY_URL = "https://tacticsboard.100for1.com/privacy"
MARKETING_URL = "https://tacticsboard.100for1.com"
SUPPORT_URL = "https://tacticsboard.100for1.com"

with open(KEY_FILE) as f:
    private_key = f.read()

def get_token():
    payload = {"iss": ISSUER_ID, "iat": int(time.time()), "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})

def api(method, path, data=None):
    token = get_token()
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    for attempt in range(3):
        try:
            resp = _requests.request(method, f"{BASE}{path}", headers=headers,
                                     json=data, verify=False, timeout=60)
            if resp.status_code >= 400:
                return {"_error": True, "_status": resp.status_code, "_body": resp.json() if resp.text else {}}
            return resp.json() if resp.text else {"_ok": True}
        except Exception:
            if attempt == 2:
                raise
            time.sleep(3)

def err(r, prefix=""):
    if r.get("_error"):
        errs = r["_body"].get("errors", [])
        if errs:
            print(f"    ⚠️  {prefix}[{r['_status']}] {errs[0].get('detail','?')}")
        return True
    return False

def read_meta(sport, locale, field):
    p = os.path.join(META_BASE, sport, locale, f"{field}.txt")
    if os.path.exists(p):
        return open(p).read().strip()
    return None

def ensure_category(app_info_id):
    """Set primaryCategory = SPORTS via PATCH on appInfo relationships."""
    r = api("PATCH", f"/v1/appInfos/{app_info_id}", {
        "data": {
            "type": "appInfos",
            "id": app_info_id,
            "relationships": {
                "primaryCategory": {"data": {"type": "appCategories", "id": "SPORTS"}},
            },
        }
    })
    if err(r, "category: "):
        return False
    print("    ✓ primaryCategory=SPORTS")
    return True

def patch_age_rating(app_info_id):
    """PATCH ageRatingDeclaration with all NONE/false values."""
    # The ageRatingDeclaration's ID equals the appInfo's ID
    r = api("PATCH", f"/v1/ageRatingDeclarations/{app_info_id}", {
        "data": {
            "type": "ageRatingDeclarations",
            "id": app_info_id,
            "attributes": AGE_RATING,
        }
    })
    if err(r, "ageRating: "):
        return False
    print("    ✓ ageRatingDeclaration filled")
    return True

def patch_app_content_rights(app_id):
    """Set contentRightsDeclaration + isOrEverWasMadeForKids on app."""
    r = api("PATCH", f"/v1/apps/{app_id}", {
        "data": {
            "type": "apps",
            "id": app_id,
            "attributes": {
                "contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT",
            },
        }
    })
    if err(r, "contentRights: "):
        return False
    print("    ✓ contentRightsDeclaration=DOES_NOT_USE_THIRD_PARTY_CONTENT")
    return True

def ensure_app_info_localizations(app_info_id, sport):
    """For each locale, PATCH existing or POST new appInfoLocalization with name/subtitle/privacyPolicyUrl."""
    r = api("GET", f"/v1/appInfos/{app_info_id}/appInfoLocalizations?limit=50")
    existing = {}
    for loc in r.get("data", []):
        existing[loc["attributes"]["locale"]] = loc["id"]
    for locale in LOCALES:
        name = read_meta(sport, locale, "name")
        subtitle = read_meta(sport, locale, "subtitle")
        attrs = {"privacyPolicyUrl": PRIVACY_POLICY_URL}
        if name:
            attrs["name"] = name
        if subtitle:
            attrs["subtitle"] = subtitle
        if locale in existing:
            r2 = api("PATCH", f"/v1/appInfoLocalizations/{existing[locale]}", {
                "data": {"type": "appInfoLocalizations", "id": existing[locale], "attributes": attrs}
            })
            if err(r2, f"appInfoLoc PATCH {locale}: "):
                continue
            print(f"    ✓ appInfoLoc PATCH {locale}")
        else:
            attrs["locale"] = locale
            r2 = api("POST", "/v1/appInfoLocalizations", {
                "data": {
                    "type": "appInfoLocalizations",
                    "attributes": attrs,
                    "relationships": {
                        "appInfo": {"data": {"type": "appInfos", "id": app_info_id}}
                    },
                }
            })
            if err(r2, f"appInfoLoc POST {locale}: "):
                continue
            print(f"    ✓ appInfoLoc POST {locale}")

def set_price_free(app_id):
    """Create appPriceSchedule with USA baseTerritory + no manual prices (free)."""
    free_price_point_id = None
    r = api("GET", f"/v1/apps/{app_id}/appPricePoints?filter[territory]=USA&limit=1")
    if r.get("data"):
        free_price_point_id = r["data"][0]["id"]
    if not free_price_point_id:
        print("    ⚠️  no USA price point found for free tier")
        return False
    r2 = api("POST", "/v1/appPriceSchedules", {
        "data": {
            "type": "appPriceSchedules",
            "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}},
                "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                "manualPrices": {
                    "data": [{"type": "appPrices", "id": "${price0}"}],
                },
            },
        },
        "included": [{
            "type": "appPrices",
            "id": "${price0}",
            "attributes": {"startDate": None},
            "relationships": {
                "appPricePoint": {"data": {"type": "appPricePoints", "id": free_price_point_id}}
            },
        }],
    })
    if err(r2, "price: "):
        return False
    print("    ✓ appPriceSchedule=Free (USA)")
    return True

def ensure_review_detail(version_id):
    """Create or PATCH appStoreReviewDetail."""
    r = api("GET", f"/v1/appStoreVersions/{version_id}/appStoreReviewDetail")
    if r.get("data"):
        detail_id = r["data"]["id"]
        r2 = api("PATCH", f"/v1/appStoreReviewDetails/{detail_id}", {
            "data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": REVIEW_DETAIL}
        })
        if err(r2, "reviewDetail PATCH: "):
            return False
        print("    ✓ appStoreReviewDetail PATCHed")
    else:
        r2 = api("POST", "/v1/appStoreReviewDetails", {
            "data": {
                "type": "appStoreReviewDetails",
                "attributes": REVIEW_DETAIL,
                "relationships": {
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
                },
            }
        })
        if err(r2, "reviewDetail POST: "):
            return False
        print("    ✓ appStoreReviewDetail POSTed")
    return True

def ensure_version_localizations(version_id, sport):
    """For each locale, PATCH existing or POST new appStoreVersionLocalization with description/keywords/etc."""
    r = api("GET", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=50")
    existing = {}
    for loc in r.get("data", []):
        existing[loc["attributes"]["locale"]] = loc["id"]
    # en-US is the required fallback language; read it once so we can fall back
    en_desc = read_meta(sport, "en-US", "description")
    en_promo = read_meta(sport, "en-US", "promotional_text")
    for locale in LOCALES:
        description = read_meta(sport, locale, "description") or en_desc
        keywords = read_meta(sport, locale, "keywords")
        promo = read_meta(sport, locale, "promotional_text") or en_promo
        # whatsNew is not editable for first-version apps (no prior version)
        attrs = {
            "supportUrl": SUPPORT_URL,
            "marketingUrl": MARKETING_URL,
        }
        if description:
            attrs["description"] = description
        if keywords:
            attrs["keywords"] = keywords
        if promo:
            attrs["promotionalText"] = promo
        if locale in existing:
            r2 = api("PATCH", f"/v1/appStoreVersionLocalizations/{existing[locale]}", {
                "data": {"type": "appStoreVersionLocalizations", "id": existing[locale], "attributes": attrs}
            })
            if err(r2, f"versionLoc PATCH {locale}: "):
                continue
            print(f"    ✓ versionLoc PATCH {locale}")
        else:
            attrs["locale"] = locale
            r2 = api("POST", "/v1/appStoreVersionLocalizations", {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": attrs,
                    "relationships": {
                        "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
                    },
                }
            })
            if err(r2, f"versionLoc POST {locale}: "):
                continue
            print(f"    ✓ versionLoc POST {locale}")

def set_version_attrs(version_id):
    """Set copyright, releaseType, usesIdfa on the appStoreVersion."""
    r = api("PATCH", f"/v1/appStoreVersions/{version_id}", {
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {
                "copyright": "2026 Zach Song",
                "releaseType": "AFTER_APPROVAL",
                "usesIdfa": False,
            },
        }
    })
    if err(r, "version attrs: "):
        return False
    print("    ✓ version copyright/releaseType/usesIdfa set")
    return True

def ensure_build_attached(app_id, version_id):
    """Ensure 1.1.6 build is attached to the appStoreVersion."""
    r = api("GET", f"/v1/appStoreVersions/{version_id}/build")
    if r.get("data"):
        print(f"    ✓ build already attached: {r['data']['id']}")
        return True
    r_builds = api("GET", f"/v1/builds?filter[app]={app_id}&filter[preReleaseVersion.version]=1.1.6&limit=5")
    if not r_builds.get("data"):
        print("    ⚠️  no 1.1.6 build yet")
        return False
    build_id = r_builds["data"][0]["id"]
    r2 = api("PATCH", f"/v1/appStoreVersions/{version_id}/relationships/build", {
        "data": {"type": "builds", "id": build_id}
    })
    if err(r2, "attach build: "):
        return False
    print(f"    ✓ build {build_id} attached")
    return True

def set_encryption_flag(version_id):
    """Set usesNonExemptEncryption=false on attached build."""
    r = api("GET", f"/v1/appStoreVersions/{version_id}/build")
    if not r.get("data"):
        return
    build_id = r["data"]["id"]
    api("PATCH", f"/v1/builds/{build_id}", {
        "data": {"type": "builds", "id": build_id,
                 "attributes": {"usesNonExemptEncryption": False}}
    })
    print("    ✓ build usesNonExemptEncryption=false")

def complete_app(bundle_id, sport):
    print(f"\n=== {bundle_id} ({sport}) ===")
    r = api("GET", f"/v1/apps?filter[bundleId]={bundle_id}")
    if not r.get("data"):
        print(f"    ❌ app not found")
        return
    app_id = r["data"][0]["id"]
    print(f"    app_id: {app_id}")

    # appInfo (PREPARE_FOR_SUBMISSION state)
    r_infos = api("GET", f"/v1/apps/{app_id}/appInfos")
    app_info_id = None
    for ai in r_infos.get("data", []):
        if ai["attributes"]["state"] in ("PREPARE_FOR_SUBMISSION", "READY_FOR_DISTRIBUTION"):
            app_info_id = ai["id"]
            break
    if not app_info_id:
        app_info_id = r_infos["data"][0]["id"]
    print(f"    app_info_id: {app_info_id}")

    # appStoreVersion (PREPARE_FOR_SUBMISSION)
    r_vers = api("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION")
    if not r_vers.get("data"):
        print("    ❌ no PREPARE_FOR_SUBMISSION version")
        return
    version_id = r_vers["data"][0]["id"]
    print(f"    version_id: {version_id}")

    # 1. Content rights
    patch_app_content_rights(app_id)
    # 2. Primary category
    ensure_category(app_info_id)
    # 3. Age rating
    patch_age_rating(app_info_id)
    # 4. AppInfo localizations (name/subtitle/privacyPolicyUrl)
    ensure_app_info_localizations(app_info_id, sport)
    # 5. Pricing (free)
    set_price_free(app_id)
    # 6. Review detail
    ensure_review_detail(version_id)
    # 7. Version localizations (description/keywords/etc.)
    ensure_version_localizations(version_id, sport)
    # 8. Version attributes (copyright etc.)
    set_version_attrs(version_id)
    # 9. Build attachment + encryption flag
    ensure_build_attached(app_id, version_id)
    set_encryption_flag(version_id)

if __name__ == "__main__":
    for bundle_id, sport in NEW_APPS:
        complete_app(bundle_id, sport)
        time.sleep(1)
    print("\n\nDone. Next: run submit_all.py (or submit_new_apps.py) to create review submissions.")
    print("Note: App Privacy data usage answers must be confirmed via ASC web UI if not already set.")
