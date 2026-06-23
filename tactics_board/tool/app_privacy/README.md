# App Privacy automation — Tactics Board (AdMob)

Sets the **App Store Connect → App Privacy** data-collection labels for the
14 ad-enabled Tactics Board iOS apps. Copy of the reusable ScoreSyncer tool,
with Tactics-Board-specific data files.

The official ASC API does **not** expose App Privacy (verified 2026-05-30:
`/v1/apps/{id}/appDataUsages` returns 0 rows even for apps with labels set), so
this uses fastlane's web-session auth — not the JWT API key the rest of `tool/`
uses.

## Files
- `ad_apps.json` — `key: bundle_id` for the 14 apps that show ads (matches the
  `ios` entries in `lib/services/ad_service.dart`). sepakTakraw and the
  multi-sport app have no ads and are excluded.
- `app_privacy_admob.json` — the nutrition label. **No-tracking** version:
  these apps do NOT show the ATT prompt, so ads are non-personalized and nothing
  is `DATA_USED_TO_TRACK_YOU`. Declaring tracking without an ATT prompt = a
  guaranteed App Store rejection. (This is the key difference from the
  ScoreSyncer template, whose apps show ATT.)
- `fastlane/Fastfile` — the `privacy` / `verify` lanes.
- `run.sh` — reads `FASTLANE_USER` / `FASTLANE_ITC_TEAM_ID` / `FASTLANE_SESSION`
  from `~/projects/.env` and runs the lane.

## One-time auth — needs 2FA, must be a REAL terminal (cannot be automated)
```bash
fastlane spaceauth -u zachsong@gmail.com   # Apple ID password + 2FA code
```
Paste the printed `FASTLANE_SESSION='...'` into `~/projects/.env`
(uncomment the `FASTLANE_SESSION=` line). Lasts ~30 days.

## Then push (from this folder)
```bash
./run.sh privacy app:basketball          # ONE app, DRAFT only — verify in ASC first
./run.sh verify app:basketball           # read back what's stored
./run.sh privacy publish:true            # all 14 apps, LIVE
```

App-level (not version-level): publishing updates the live listing without
resubmitting, but the in-review 1.1.14 builds will be checked against it.

Keep `app_privacy_admob.json` in sync with the in-app SDKs and the privacy
policy at https://tacticsboard.100for1.com/privacy.
