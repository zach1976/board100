#!/bin/bash
# release_1_1_24.sh — end-to-end iOS v1.1.24 code-fix release across all 16 apps.
#
# Ships: timeline-editor scroll fix, water-polo formation split, app-open ad
# resume gate. Reuses each app's pending ASO version (cancel review -> retarget
# to 1.1.24 -> attach new build -> resubmit), so the ASO metadata carries over.
#
# Checkpointed: rerun to resume from the last unfinished phase.
# State: build/release_1_1_24_state.txt
set -e
cd "$(dirname "$0")/.."

STATE_FILE="build/release_1_1_24_state.txt"
mkdir -p build
touch "$STATE_FILE"
did() { grep -qFx "$1" "$STATE_FILE"; }
mark() { echo "$1" >> "$STATE_FILE"; }

echo "═════════════════════════════════════════════════════════"
echo "  iOS v1.1.24 code-fix release — $(date)"
echo "  pubspec: $(grep '^version:' pubspec.yaml)"
echo "  done:    $(wc -l < "$STATE_FILE" | tr -d ' ') phases"
echo "═════════════════════════════════════════════════════════"

# ── Phase 1: build 16 IPAs ──
if ! did "ipas_built"; then
  echo "▶ Phase 1: building 16 IPAs (~2-3h)"
  ./tool/build_all_ipa.sh
  COUNT=$(ls build/ipa_all/*.ipa 2>/dev/null | wc -l | tr -d ' ')
  if [ "$COUNT" != "16" ]; then
    echo "❌ expected 16 IPAs, got $COUNT — aborting"; exit 1
  fi
  mark "ipas_built"; echo "✅ Phase 1 done: 16 IPAs"
else echo "↷ Phase 1 done"; fi

# ── Phase 2: upload IPAs ──
if ! did "ipas_uploaded"; then
  echo "▶ Phase 2: uploading 16 IPAs (~1h with retries)"
  ./tool/upload_all_ipa.sh
  mark "ipas_uploaded"; echo "✅ Phase 2 done"
else echo "↷ Phase 2 done"; fi

# ── Phase 3: wait for ASC processing ──
if ! did "builds_processed"; then
  echo "▶ Phase 3: polling until all 16 v1.1.24 builds are VALID (~20-30 min)"
  VERSION=1.1.24 python3 tool/wait_builds_processed.py
  mark "builds_processed"; echo "✅ Phase 3 done"
else echo "↷ Phase 3 done"; fi

# ── Phase 4: cancel pending ASO reviews, retarget to 1.1.24, submit ──
if ! did "ios_submitted"; then
  echo "▶ Phase 4: retarget + submit 1.1.24 for review (all 16)"
  python3 tool/submit_1_1_24.py
  mark "ios_submitted"; echo "✅ Phase 4 done"
else echo "↷ Phase 4 done"; fi

echo ""
echo "🎉 iOS v1.1.24 pipeline complete — all 16 apps submitted for review."
