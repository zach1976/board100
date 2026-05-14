#!/bin/bash
# release_1_1_11.sh — end-to-end v1.1.11 metadata-only rollout.
#
# 16 apps × 11 locales = 176 listings. ~3-5 hours wall time total.
# Run this from tactics_board/ root.
#
# Each phase is checkpointed; rerunning the script resumes from the last
# unfinished phase. State is tracked in build/release_state.txt.
#
# Required:
#   - flutter, dart, Xcode toolchain configured for iOS signing
#   - ASC API key at /Users/zhenyusong/Desktop/projects/keys/AuthKey_4A9Y2S3D6X.p8
#   - bundle gem install fastlane (Fastfile lane setup)
#   - gtimeout (brew install coreutils)

set -e
cd "$(dirname "$0")/.."

STATE_FILE="build/release_state.txt"
mkdir -p build
touch "$STATE_FILE"

did() { grep -qFx "$1" "$STATE_FILE"; }
mark() { echo "$1" >> "$STATE_FILE"; }

echo "═════════════════════════════════════════════════════════"
echo "  ASO v1.1.11 metadata-only release — $(date)"
echo "═════════════════════════════════════════════════════════"
echo ""
echo "Pre-flight:"
echo "  pubspec version: $(grep '^version:' pubspec.yaml)"
echo "  state file:      $STATE_FILE"
echo "  done so far:     $(wc -l < "$STATE_FILE" | tr -d ' ') phases"
echo ""

# ───────── Phase 1: build 16 IPAs ─────────
if ! did "ipas_built"; then
  echo "▶ Phase 1: building 16 IPAs (expect ~2-3h)"
  ./tool/build_all_ipa.sh
  COUNT=$(ls build/ipa_all/*.ipa 2>/dev/null | wc -l | tr -d ' ')
  if [ "$COUNT" != "16" ]; then
    echo "❌ expected 16 IPAs in build/ipa_all/, got $COUNT — aborting"
    exit 1
  fi
  mark "ipas_built"
  echo "✅ Phase 1 done"
else
  echo "↷ Phase 1 already done (ipas_built)"
fi

# ───────── Phase 2: upload IPAs to ASC ─────────
if ! did "ipas_uploaded"; then
  echo ""
  echo "▶ Phase 2: uploading 16 IPAs via altool (expect ~1h with retries)"
  ./tool/upload_all_ipa.sh
  mark "ipas_uploaded"
  echo "✅ Phase 2 done"
else
  echo "↷ Phase 2 already done (ipas_uploaded)"
fi

# ───────── Phase 3: wait for ASC build processing ─────────
if ! did "builds_processed"; then
  echo ""
  echo "▶ Phase 3: waiting for ASC to finish processing 16 builds (~20-30 min)"
  echo "   Manually verify all 16 builds appear in App Store Connect, then:"
  echo "   echo builds_processed >> $STATE_FILE"
  echo "   and re-run this script."
  exit 0
else
  echo "↷ Phase 3 already confirmed (builds_processed)"
fi

# ───────── Phase 4: upload metadata (screenshots deferred to v1.1.12) ─────────
if ! did "metadata_uploaded"; then
  echo ""
  echo "▶ Phase 4: upload version-level metadata (description / subtitle / keywords / release_notes)"
  echo "  (screenshots intentionally skipped — existing 1320×2868 prod set stays; new"
  echo "  captioned screenshots ship in v1.1.12 once designer reviews all 11 locales)"
  ( cd fastlane && fastlane upload_all_metadata )
  mark "metadata_uploaded"
  echo "✅ Phase 4 done"
else
  echo "↷ Phase 4 already done (metadata_uploaded)"
fi

# ───────── Phase 5: submit 16 apps for review ─────────
if ! did "submitted_for_review"; then
  echo ""
  echo "▶ Phase 5: submit_all.py — create v1.1.11 versions + submit for review"
  python3 tool/submit_all.py
  mark "submitted_for_review"
  echo "✅ Phase 5 done"
else
  echo "↷ Phase 5 already done"
fi

echo ""
echo "═════════════════════════════════════════════════════════"
echo "  🎉 v1.1.11 release submitted for all 16 apps."
echo "     Apple review: 1-3 days per app. Monitor in ASC."
echo "═════════════════════════════════════════════════════════"
