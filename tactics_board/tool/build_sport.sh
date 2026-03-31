#!/bin/bash
# Build a single-sport app with custom bundle ID and app name
# Usage: ./tool/build_sport.sh <sport> [debug|release] [device_id]
# Example: ./tool/build_sport.sh badminton release
#          ./tool/build_sport.sh soccer debug 6BA0E025-...

set -e
cd "$(dirname "$0")/.."

SPORT=${1:?Usage: build_sport.sh <sport> [debug|release] [device_id]}
MODE=${2:-debug}
DEVICE=${3:-}

# ── Config per sport ─────────────────────────────────────────────────────────
case "$SPORT" in
  badminton)    BUNDLE_ID="com.zach.badmintonBoard";    DISPLAY_NAME="Badminton Board" ;;
  tableTennis)  BUNDLE_ID="com.zach.tableTennisBoard";  DISPLAY_NAME="Table Tennis Board" ;;
  tennis)       BUNDLE_ID="com.zach.tennisBoard";       DISPLAY_NAME="Tennis Board" ;;
  basketball)   BUNDLE_ID="com.zach.basketballBoard";   DISPLAY_NAME="Basketball Board" ;;
  volleyball)   BUNDLE_ID="com.zach.volleyballBoard";   DISPLAY_NAME="Volleyball Board" ;;
  pickleball)   BUNDLE_ID="com.zach.pickleballBoard";   DISPLAY_NAME="Pickleball Board" ;;
  soccer)       BUNDLE_ID="com.zach.soccerBoard";       DISPLAY_NAME="Soccer Board" ;;
  *)
    echo "Unknown sport: $SPORT"
    echo "Available: badminton tableTennis tennis basketball volleyball pickleball soccer"
    exit 1 ;;
esac

echo "══════════════════════════════════════"
echo "  Sport:     $SPORT"
echo "  Bundle ID: $BUNDLE_ID"
echo "  Name:      $DISPLAY_NAME"
echo "  Mode:      $MODE"
echo "══════════════════════════════════════"

# ── Save originals ───────────────────────────────────────────────────────────
PBXPROJ="ios/Runner.xcodeproj/project.pbxproj"
PLIST="ios/Runner/Info.plist"

cp "$PBXPROJ" "$PBXPROJ.bak"
cp "$PLIST" "$PLIST.bak"

# ── Restore on exit ──────────────────────────────────────────────────────────
restore() {
  echo "Restoring original configs..."
  mv "$PBXPROJ.bak" "$PBXPROJ"
  mv "$PLIST.bak" "$PLIST"
  [ -f "assets/icon/app_icon.png.bak" ] && mv "assets/icon/app_icon.png.bak" "assets/icon/app_icon.png"
  [ -f "assets/icon/splash_logo.png.bak" ] && mv "assets/icon/splash_logo.png.bak" "assets/icon/splash_logo.png"
}
trap restore EXIT

# ── Patch iOS bundle ID ──────────────────────────────────────────────────────
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = com\.[^;]*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID/g" "$PBXPROJ"

# ── Patch iOS display name ───────────────────────────────────────────────────
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $DISPLAY_NAME" "$PLIST"

# ── Use sport-specific icon & splash if available ────────────────────────────
SPORT_ICON="assets/icon/${SPORT}_icon.png"
SPORT_SPLASH="assets/icon/${SPORT}_splash.png"
if [ -f "$SPORT_ICON" ]; then
  cp "assets/icon/app_icon.png" "assets/icon/app_icon.png.bak"
  cp "$SPORT_ICON" "assets/icon/app_icon.png"
fi
if [ -f "$SPORT_SPLASH" ]; then
  cp "assets/icon/splash_logo.png" "assets/icon/splash_logo.png.bak"
  cp "$SPORT_SPLASH" "assets/icon/splash_logo.png"
fi

# ── Build ────────────────────────────────────────────────────────────────────
DART_DEFINES="--dart-define=SPORT=$SPORT"

if [ "$MODE" = "release" ]; then
  flutter build ios --release $DART_DEFINES
  echo ""
  echo "✅ Built: build/ios/iphoneos/Runner.app"
  echo "   Bundle ID: $BUNDLE_ID"
  echo "   Name:      $DISPLAY_NAME"
  echo ""
  echo "Install with:"
  echo "   xcrun devicectl device install app --device <DEVICE_ID> build/ios/iphoneos/Runner.app"
else
  DEVICE_FLAG=""
  if [ -n "$DEVICE" ]; then
    DEVICE_FLAG="-d $DEVICE"
  fi
  flutter run $DEVICE_FLAG --$MODE $DART_DEFINES
fi
