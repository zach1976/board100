#!/bin/bash
# release_1_1_25.sh — iOS v1.1.25 build + upload for all 16 apps, then submit
# ONE of them (Phase 4 takes a sport key; see the cadence note there).
#
# Runs from the repo root: every app is its own project now (tactics_board/ is
# the hub + shared core, <Sport>Board/ are the shells), so the build phase no
# longer patches and restores one shared project per sport.
#
# Ships the AdMob accidental-click work (marketing/ADMOB_GROWTH_PLAN.md phase A/B3):
#   - TapGuard: never show a full-screen ad while a finger is mid-gesture.
#     This app family ran an 11.5% app-open CTR vs 2.5% for the flashcard apps
#     on the same ad stack — the driver is finger-on-glass, not frequency.
#   - Cold-start window (12s), first-launch grace, background-reopen grace,
#     daily caps (app-open 3/day, interstitial 6/day).
#   - App-open circuit-broken on pickleball / fieldHockey / rugby / volleyball
#     (CTR 13.7-21.3%); their interstitials stay live.
#   - Interstitial no longer preloaded at launch (5,520 requests -> 6 impressions
#     on 1.1.24); warmed up when a share flow starts instead.
#
# ⚠️ PRECONDITION — iOS 1.1.24 is WAITING_FOR_REVIEW as of 2026-07-26.
#    submit_1_1_25.py cancels the pending submission and retargets the version.
#    That forfeits 1.1.24's queue position. Before running Phase 4, check whether
#    1.1.24 has already been approved:
#        python3 tools/check_app_status.py
#    If it went READY_FOR_SALE, 1.1.25 submits cleanly on top with no cancel.
#
# Checkpointed: rerun to resume from the last unfinished phase.
# State: build/release_1_1_25_state.txt
set -e
cd "$(dirname "$0")/.."

STATE_FILE="build/release_1_1_25_state.txt"  # repo-root build/
mkdir -p build
touch "$STATE_FILE"
did() { grep -qFx "$1" "$STATE_FILE"; }
mark() { echo "$1" >> "$STATE_FILE"; }

echo "═════════════════════════════════════════════════════════"
echo "  iOS v1.1.25 release — $(date)"
echo "  pubspec: $(grep '^version:' tactics_board/pubspec.yaml)"
echo "  done:    $(wc -l < "$STATE_FILE" | tr -d ' ') phases"
echo "═════════════════════════════════════════════════════════"

# ── Phase 1: build 16 IPAs ──
# build/ipa_all is NOT cleaned by build_all_ipa.sh, so a partial build would
# leave last release's IPAs in place and still satisfy the count check below —
# uploading stale binaries under a new version number. Clear it first.
if ! did "ipas_built"; then
  echo "▶ Phase 1: building 16 IPAs (~2-3h)"
  if [ -n "$(ls build/ipa_all/*.ipa 2>/dev/null)" ]; then
    STAMP=$(date +%Y%m%d_%H%M%S)
    echo "  archiving pre-existing IPAs -> build/ipa_all_stale_$STAMP"
    mv build/ipa_all "build/ipa_all_stale_$STAMP"
    mkdir -p build/ipa_all
  fi
  ./tools/build_all_ipa.sh
  COUNT=$(ls build/ipa_all/*.ipa 2>/dev/null | wc -l | tr -d ' ')
  if [ "$COUNT" != "16" ]; then
    echo "❌ expected 16 IPAs, got $COUNT — aborting"; exit 1
  fi
  mark "ipas_built"; echo "✅ Phase 1 done: 16 IPAs"
else echo "↷ Phase 1 done"; fi

# ── Phase 1b: verify each IPA carries the right version + real AdMob App ID ──
# The playbook's #1 recurring bug is a batch build shipping the placeholder
# GADApplicationIdentifier. Cheap to check, expensive to miss.
if ! did "ipas_verified"; then
  echo "▶ Phase 1b: verifying versions + AdMob App IDs"
  python3 tools/verify_ipas.py 1.1.25
  mark "ipas_verified"; echo "✅ Phase 1b done"
else echo "↷ Phase 1b done"; fi

# ── Phase 2: upload IPAs ──
if ! did "ipas_uploaded"; then
  echo "▶ Phase 2: uploading 16 IPAs (~1h with retries)"
  ./tools/upload_all_ipa.sh
  mark "ipas_uploaded"; echo "✅ Phase 2 done"
else echo "↷ Phase 2 done"; fi

# ── Phase 3: wait for ASC processing ──
if ! did "builds_processed"; then
  echo "▶ Phase 3: polling until all 16 v1.1.25 builds are VALID (~20-30 min)"
  VERSION=1.1.25 python3 tools/wait_builds_processed.py
  mark "builds_processed"; echo "✅ Phase 3 done"
else echo "↷ Phase 3 done"; fi

# ── Phase 4: retarget + submit ONE app ──
# ★ Mandatory cadence (zachs_app_base.md 6.4): one app per review cycle, and
# only after the previous one has a verdict plus >=1 week. Same-day bulk
# submission is what triggered the 2026-08-09 Guideline 5.6 account
# suspension, so this phase never fans out — it takes exactly one sport key
# and refuses to guess. submit_1_1_25.py with no argument submits all 16.
SUBMIT_SPORT="${SUBMIT_SPORT:-${1:-}}"
if [ -z "$SUBMIT_SPORT" ]; then
  echo ""
  echo "▶ Phase 4: not run — no sport given (this is deliberate)."
  echo "   Submit one app, wait for its verdict, then wait >=1 week:"
  echo "       SUBMIT_SPORT=<sport> $0"
  echo "   Sport keys: tactics_board soccer basketball volleyball badminton"
  echo "               tennis tableTennis pickleball fieldHockey rugby baseball"
  echo "               handball waterPolo sepakTakraw beachTennis footvolley"
  echo "   See zachs_app_base.md 6.4 — one app per review cycle."
  exit 0
fi
if ! did "ios_submitted_$SUBMIT_SPORT"; then
  echo "▶ Phase 4: retarget + submit 1.1.25 for review — $SUBMIT_SPORT only"
  python3 tools/submit_1_1_25.py "$SUBMIT_SPORT"
  mark "ios_submitted_$SUBMIT_SPORT"; echo "✅ Phase 4 done ($SUBMIT_SPORT)"
else echo "↷ Phase 4 already done for $SUBMIT_SPORT"; fi

echo ""
echo "🎉 iOS v1.1.25: $SUBMIT_SPORT submitted for review."
echo "   Do NOT submit the next app until this one has a verdict + >=1 week."
echo "   Then: watch CTR weekly via marketing/tools/admob_report.py."
echo "   Target: board100 CTR <= 4% within 2 weeks (was 11.5%)."
