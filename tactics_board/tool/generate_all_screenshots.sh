#!/bin/bash
# Generate App Store screenshots for all sports × languages
# Usage: ./tool/generate_all_screenshots.sh [device_id]
set -e
cd "$(dirname "$0")/.."

DEVICE=${1:-DC18AEE8-4BB3-42D1-BF28-55F85628415A}
SCREENSHOT_BASE="fastlane/screenshots"
SPORTS=(badminton basketball soccer tennis tableTennis volleyball pickleball)

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
    dst="$SCREENSHOT_BASE/$sport/$lang_dir"
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
find "$SCREENSHOT_BASE" -name "*.png" | wc -l
