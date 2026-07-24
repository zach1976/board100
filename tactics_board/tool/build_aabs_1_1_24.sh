#!/bin/bash
# Build the 6 Play apps' 1.1.24 AABs, each with its correct next versionCode
# (strictly higher than what's live on Play — discovered 2026-07-24).
set -e
cd "$(dirname "$0")/.."

# sport:nextVersionCode  (current live codes were tactics_board=3, basketball=2,
# badminton=2, fieldHockey=2, soccer=1, volleyball=1)
JOBS=("tactics_board:4" "soccer:2" "basketball:3" "volleyball:2" "badminton:3" "fieldHockey:3")

for j in "${JOBS[@]}"; do
  sport="${j%:*}"; code="${j#*:}"
  echo ""
  echo "██████████ $sport  (versionCode $code) ██████████"
  BUILD_NUMBER="$code" ./tool/build_sport_android.sh "$sport"
done

echo ""
echo "All 6 AABs built:"
ls -la build/aab_play/*.aab
