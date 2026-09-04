#!/bin/bash
# Generate App Store screenshots for all sports × languages
# Usage: ./tool/generate_all_screenshots.sh [device_id]
set -e
cd "$(dirname "$0")/.."

DEVICE=${1:-DC18AEE8-4BB3-42D1-BF28-55F85628415A}
# Each app owns its screenshots: <App>/fastlane/screenshots/<locale>/.
# tools/sports.tsv maps a sport key to its app directory.
app_dir() {  # $1 = sport key
  local d
  d=$(awk -F'	' -v k="$1" '$1 == k && $1 !~ /^#/ {print $2; exit}' ../tools/sports.tsv)
  [ -z "$d" ] && { echo "unknown sport: $1" >&2; return 1; }
  [ "$d" = "-" ] && d="tactics_board"
  echo "../$d"
}
SPORTS=(badminton basketball soccer tennis tableTennis volleyball pickleball fieldHockey rugby baseball handball waterPolo sepakTakraw beachTennis footvolley)

echo "══════════════════════════════════════"
echo "  Generating App Store Screenshots"
echo "  Device: $DEVICE"
echo "══════════════════════════════════════"

for sport in "${SPORTS[@]}"; do
  echo ""
  echo "── $sport ──"
  
  flutter test integration_test/appstore_screenshots.dart \
    -d "$DEVICE" \
    --dart-define=SPORT=$sport \
    2>&1 | grep -E "✅|All tests|failed"
  
  # Move screenshots to correct directories
  # Integration test screenshots go to build/ directory
  # We need to copy them to fastlane/screenshots/
  for lang_dir in en-US zh-Hans ja ko zh-Hant; do
    dst="$(app_dir "$sport")/fastlane/screenshots/$lang_dir"
    mkdir -p "$dst"
    # Screenshots from integration_test are saved with the name we specified
    # They should be in the build directory - find and copy
    find build/ -name "${sport}_${lang_dir}_*.png" -newer "$0" 2>/dev/null | while read f; do
      cp "$f" "$dst/"
      echo "  📸 $(basename $f) → $dst/"
    done
  done
done

echo ""
echo "══ All screenshots generated ══"
echo "Total:"
find ../*/fastlane/screenshots fastlane/screenshots -name "*.png" 2>/dev/null | wc -l
