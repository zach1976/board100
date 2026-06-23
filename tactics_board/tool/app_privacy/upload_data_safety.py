#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Submit Google Play **Data safety** declarations for the Tactics Board apps
via the androidpublisher `dataSafety` API, using the OFFICIAL 760-row CSV
template (vendored at data_safety/template_full.json, from the owenbean400
fastlane plugin — accepted by Play's API as of 2026-05-31).

Adapted from ScoreSyncer's uploader. The honest config for these apps:

  ADS (AdMob, NON-personalized — no ATT/UMP consent → "not linked to you"):
    Device ID, App interactions, Approx location  → collected + SHARED, ad+analytics purposes
    Crash logs, Diagnostics                       → collected only, app functionality
  OPTIONAL ACCOUNT (Google/Apple sign-in → tacticsboard.100for1.com, for cloud
  sync — first-party, NOT shared, user-optional):
    Name, Email                                   → collected, app functionality
    User-generated content (the synced tactic boards) → collected, app functionality

  ENCRYPTED_IN_TRANSIT = true (backend is https://tacticsboard.100for1.com).
  Account creation = OAUTH (Google / Apple). Data deletion = YES (in-app
  "Delete account" → /api/v1/auth/delete-account, see lib/pages/home_page.dart).

Only the multi-sport hub (com.zach.tacticsBoard) plus the single-sport apps that
actually ship Android ads need the ad data types; sports without an Android
AdMob app still collect the account data when a user signs in. APPS below maps
each package to whether it shows Android ads (`ads`); all apps share the account
+ sync declaration.

Usage:
    python3 upload_data_safety.py                       # DRY-RUN: validate keys + write CSVs
    python3 upload_data_safety.py --post tactics_board  # POST one app
    python3 upload_data_safety.py --post                # POST all configured apps

Service account key: PLAY_SERVICE_ACCOUNT_KEY (env or ~/projects/.env),
else the learnthai-play-api.json default. Deps: google-auth.
"""
import os, sys, json, io, csv, socket, urllib.request, urllib.error

BASE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(BASE, "data_safety", "template_full.json")
OUTDIR = os.path.join(BASE, "data_safety")
PROJ_ENV = os.path.expanduser("~/projects/.env")
API = "https://androidpublisher.googleapis.com/androidpublisher/v3"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def load_key():
    p = os.environ.get("PLAY_SERVICE_ACCOUNT_KEY")
    if not p and os.path.exists(PROJ_ENV):
        for line in open(PROJ_ENV):
            s = line.strip()
            if s.startswith("PLAY_SERVICE_ACCOUNT_KEY") and "=" in s:
                p = s.split("=", 1)[1].strip().strip('"').strip("'")
                break
    return p or "/Users/zhenyusong/projects/keys/learnthai-play-api.json"


KEY = load_key()

# package: {"ads": <bool ad-enabled on Android>}. Account+sync data applies to
# every app (the shared codebase has Google/Apple sign-in + cloud sync). The hub
# and the Android-ad sports also collect ad data types.
APPS = {
    "com.zach.tacticsBoard":   {"ads": True},   # multi-sport hub
    # add single-sport Android-ad apps here as they go live, e.g.:
    # "com.zach.basketballBoard": {"ads": True},
    # "com.zach.fieldHockeyBoard": {"ads": True},
}

AD_PURPOSES = ["PSL_ADVERTISING", "PSL_ANALYTICS", "PSL_FRAUD_PREVENTION_SECURITY"]
APP_PURPOSES = ["PSL_APP_FUNCTIONALITY"]


def answers(cfg):
    """Return dict {(question_id, response_id_or_''): 'true'/'false'}."""
    a = {}

    a[("PSL_DATA_COLLECTION_COLLECTS_PERSONAL_DATA", "")] = "true"
    a[("PSL_DATA_COLLECTION_ENCRYPTED_IN_TRANSIT", "")] = "true"   # https backend
    # Account via Google/Apple OAuth; users can delete their account in-app
    # (Settings → Delete account → /api/v1/auth/delete-account) or by email.
    # Declaring DATA_DELETION_YES makes both deletion URLs required by the API;
    # the privacy page documents the in-app + email deletion paths.
    a[("PSL_SUPPORTED_ACCOUNT_CREATION_METHODS", "PSL_ACM_OAUTH")] = "true"
    a[("PSL_SUPPORT_DATA_DELETION_BY_USER", "DATA_DELETION_YES")] = "true"
    DELETE_URL = "https://tacticsboard.100for1.com/privacy"
    a[("PSL_ACCOUNT_DELETION_URL", "")] = DELETE_URL
    a[("PSL_DATA_DELETION_URL", "")] = DELETE_URL

    def data_type(group, code, collected, shared, required, purposes):
        a[(group, code)] = "true"  # presence
        base = f"PSL_DATA_USAGE_RESPONSES:{code}"
        if collected:
            a[(f"{base}:PSL_DATA_USAGE_COLLECTION_AND_SHARING",
               "PSL_DATA_USAGE_ONLY_COLLECTED")] = "true"
        if shared:
            a[(f"{base}:PSL_DATA_USAGE_COLLECTION_AND_SHARING",
               "PSL_DATA_USAGE_ONLY_SHARED")] = "true"
        uc = "PSL_DATA_USAGE_USER_CONTROL_REQUIRED" if required \
             else "PSL_DATA_USAGE_USER_CONTROL_OPTIONAL"
        a[(f"{base}:DATA_USAGE_USER_CONTROL", uc)] = "true"
        # Persisted server-side (not ephemeral) → false, once a type is selected.
        a[(f"{base}:PSL_DATA_USAGE_EPHEMERAL", "")] = "false"
        for p in purposes:
            if collected:
                a[(f"{base}:DATA_USAGE_COLLECTION_PURPOSE", p)] = "true"
            if shared:
                a[(f"{base}:DATA_USAGE_SHARING_PURPOSE", p)] = "true"

    # ── Ads (AdMob, non-personalized) ───────────────────────────────────────
    if cfg["ads"]:
        # Device or other IDs — collected + shared, ad purposes, always-on
        data_type("PSL_DATA_TYPES_IDENTIFIERS", "PSL_DEVICE_ID",
                  True, True, True, AD_PURPOSES)
        # App interactions — collected + shared, ad/analytics
        data_type("PSL_DATA_TYPES_APP_ACTIVITY", "PSL_USER_INTERACTION",
                  True, True, True, AD_PURPOSES)
        # Approximate location (AdMob) — collected + shared
        data_type("PSL_DATA_TYPES_LOCATION", "PSL_APPROX_LOCATION",
                  True, True, True, AD_PURPOSES)

    # ── App info & performance (Crashlytics/SDK) — collected only ───────────
    data_type("PSL_DATA_TYPES_APP_PERFORMANCE", "PSL_CRASH_LOGS",
              True, False, True, APP_PURPOSES)
    data_type("PSL_DATA_TYPES_APP_PERFORMANCE", "PSL_PERFORMANCE_DIAGNOSTICS",
              True, False, True, APP_PURPOSES)

    # ── Optional account (Google/Apple sign-in → own backend) ───────────────
    # collected, NOT shared (first-party), user-optional (only if they sign in).
    data_type("PSL_DATA_TYPES_PERSONAL", "PSL_NAME",
              True, False, False, APP_PURPOSES)
    data_type("PSL_DATA_TYPES_PERSONAL", "PSL_EMAIL",
              True, False, False, APP_PURPOSES)
    # The tactic boards a signed-in user syncs to the server.
    data_type("PSL_DATA_TYPES_APP_ACTIVITY", "PSL_USER_GENERATED_CONTENT",
              True, False, False, APP_PURPOSES)
    return a


def build_csv(cfg):
    rows = json.load(open(TEMPLATE, encoding="utf-8"))
    header, body = rows[0], rows[1:]
    ans = answers(cfg)

    template_keys = {(r[0], (r[1] or "")) for r in body}
    missing = [k for k in ans if k not in template_keys]
    if missing:
        raise SystemExit("ANSWER KEYS NOT IN TEMPLATE:\n" +
                         "\n".join(f"  {q} | {r}" for q, r in missing))

    out = io.StringIO()
    w = csv.writer(out)
    w.writerow(header)
    filled = 0
    seen = set()
    for r in body:
        q, resp = r[0], (r[1] or "")
        if (q, resp) in seen:
            continue
        seen.add((q, resp))
        if (q, resp) in ans:
            v = ans[(q, resp)]
            # TRUE/FALSE answers are upper-cased; free-text (URLs) pass through.
            val = v.upper() if v.lower() in ("true", "false") else v
            filled += 1
        else:
            val = ""
        w.writerow([r[0], r[1] if r[1] is not None else "", val,
                    r[3] if r[3] is not None else "",
                    r[4] if r[4] is not None else ""])
    return out.getvalue(), filled, len(ans)


def token():
    from google.oauth2 import service_account
    import google.auth.transport.requests
    creds = service_account.Credentials.from_service_account_file(KEY, scopes=SCOPES)
    creds.refresh(google.auth.transport.requests.Request())
    return creds.token


def post(pkg, csv_text, tok):
    socket.setdefaulttimeout(60)
    body = json.dumps({"safetyLabels": csv_text}).encode()
    url = f"{API}/applications/{pkg}/dataSafety"
    req = urllib.request.Request(url, data=body, method="POST",
                                 headers={"Authorization": f"Bearer {tok}",
                                          "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, resp.read().decode()[:500]
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:900]
    except Exception as e:
        return -1, f"{type(e).__name__}: {e}"


def pkg_for(name):
    return name if name.startswith("com.zach.") else (
        "com.zach.tacticsBoard" if name == "tactics_board"
        else f"com.zach.{name}Board")


def main():
    args = sys.argv[1:]
    do_post = "--post" in args
    names = [a for a in args if not a.startswith("--")]
    pkgs = [pkg_for(n) for n in names] or list(APPS)

    built = {}
    for pkg in pkgs:
        if pkg not in APPS:
            sys.exit(f"unknown app {pkg}; add it to APPS")
        csv_text, filled, total = build_csv(APPS[pkg])
        out_path = os.path.join(OUTDIR, pkg + ".csv")
        open(out_path, "w", encoding="utf-8").write(csv_text)
        built[pkg] = csv_text
        print(f"[{pkg}] CSV ok: {filled}/{total} answers placed -> {out_path}")

    if not do_post:
        print("\nDRY-RUN: all answer keys matched the template. No POST.")
        print("Re-run with: --post tactics_board")
        return

    tok = token()
    for pkg in pkgs:
        st, msg = post(pkg, built[pkg], tok)
        ok = 200 <= st < 300
        print(f"\n[{pkg}] POST HTTP {st} {'OK ✓' if ok else 'ERR'}")
        if not ok:
            print("  ", msg)


if __name__ == "__main__":
    main()
