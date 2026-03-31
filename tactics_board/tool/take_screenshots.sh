#!/bin/bash
# Automated screenshot capture for all sports × languages
# Usage: ./tool/take_screenshots.sh [device_id]

set -e
cd "$(dirname "$0")/.."

DEVICE=${1:-DC18AEE8-4BB3-42D1-BF28-55F85628415A}
SCREENSHOT_DIR="fastlane/screenshots"

SPORTS=(badminton basketball soccer tennis tableTennis volleyball pickleball)
# App Store locale codes → easy_localization locale codes
declare -A LOCALE_MAP
LOCALE_MAP[en-US]="en_US"
LOCALE_MAP[zh-Hans]="zh_CN"
LOCALE_MAP[zh-Hant]="zh_TW"
LOCALE_MAP[ja]="ja_JP"
LOCALE_MAP[ko]="ko_KR"
LOCALE_MAP[fr-FR]="fr_FR"
LOCALE_MAP[es-ES]="es_ES"
LOCALE_MAP[vi]="vi_VN"
LOCALE_MAP[th]="th_TH"
LOCALE_MAP[id]="id_ID"
LOCALE_MAP[ms]="ms_MY"

take_screenshot() {
  local name=$1
  sleep 2
  xcrun simctl io "$DEVICE" screenshot "$name" 2>/dev/null
  echo "  📸 $(basename $name)"
}

for sport in "${SPORTS[@]}"; do
  for store_lang in en-US zh-Hans ja ko; do
    echo "══════════════════════════════════════"
    echo "  Sport: $sport | Language: $store_lang"  
    echo "══════════════════════════════════════"
    
    dst_dir="$SCREENSHOT_DIR/$sport/$store_lang"
    mkdir -p "$dst_dir"
    
    locale_code="${LOCALE_MAP[$store_lang]}"
    
    # Kill any running flutter
    kill $(pgrep -f "flutter run") 2>/dev/null || true
    sleep 2
    
    # Launch app with this sport and wait for it to start
    flutter run -d "$DEVICE" \
      --dart-define=SPORT=$sport \
      --release \
      2>&1 &
    FLUTTER_PID=$!
    
    # Wait for app to launch
    sleep 15
    
    # Set locale via simctl (changes simulator system language)
    # Instead, we rely on the app's saved locale preference
    # Take the initial screenshot
    take_screenshot "$dst_dir/01_${sport}_hero.png"
    
    # Kill flutter
    kill $FLUTTER_PID 2>/dev/null || true
    sleep 2
    
    echo "  ✅ Done: $sport/$store_lang"
    echo ""
  done
done

echo "══ All screenshots complete ══"
