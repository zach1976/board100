#!/bin/bash
# Build a single-sport macOS app — the desktop counterpart of tool/build_sport.sh.
# Mirrors the iOS per-sport model: each sport is its own app (own bundle id,
# display name, and icon). macOS has no ads (google_mobile_ads has no macOS
# build) and no native splash, so those steps from the iOS script are dropped.
#
# Usage: ./tool/build_sport_macos.sh <sport> [release|debug]
# Example: ./tool/build_sport_macos.sh badminton release
set -e
cd "$(dirname "$0")/.."

SPORT=${1:?Usage: build_sport_macos.sh <sport> [release|debug]}
MODE=${2:-release}

# ── Config per sport (bundle id + name mirror tool/build_sport.sh) ────────────
case "$SPORT" in
  badminton)    BUNDLE_ID="com.zach.badmintonBoard";    NAME="Badminton Board" ;;
  tableTennis)  BUNDLE_ID="com.zach.tableTennisBoard";  NAME="Table Tennis Board" ;;
  tennis)       BUNDLE_ID="com.zach.tennisBoard";       NAME="Tennis Board" ;;
  basketball)   BUNDLE_ID="com.zach.basketballBoard";   NAME="Basketball Board" ;;
  volleyball)   BUNDLE_ID="com.zach.volleyballBoard";   NAME="Volleyball Board" ;;
  pickleball)   BUNDLE_ID="com.zach.pickleballBoard";   NAME="Pickleball Board" ;;
  soccer)       BUNDLE_ID="com.zach.soccerBoard";       NAME="Soccer Board" ;;
  fieldHockey)  BUNDLE_ID="com.zach.fieldHockeyBoard";  NAME="Field Hockey Board" ;;
  rugby)        BUNDLE_ID="com.zach.rugbyBoard";        NAME="Rugby Board" ;;
  baseball)     BUNDLE_ID="com.zach.baseballBoard";     NAME="Baseball Board" ;;
  handball)     BUNDLE_ID="com.zach.handballBoard";     NAME="Handball Board" ;;
  waterPolo)    BUNDLE_ID="com.zach.waterPoloBoard";    NAME="Water Polo Board" ;;
  sepakTakraw)  BUNDLE_ID="com.zach.sepakTakrawBoard";  NAME="Sepak Takraw Board" ;;
  beachTennis)  BUNDLE_ID="com.zach.beachTennisBoard";  NAME="Beach Tennis Board" ;;
  footvolley)   BUNDLE_ID="com.zach.footvolleyBoard";   NAME="Footvolley Board" ;;
  *)
    echo "Unknown sport: $SPORT"
    echo "Available: badminton tableTennis tennis basketball volleyball pickleball soccer fieldHockey rugby baseball handball waterPolo sepakTakraw beachTennis footvolley"
    exit 1 ;;
esac

CONFIG=$([ "$MODE" = "release" ] && echo Release || echo Debug)

echo "══════════════════════════════════════"
echo "  Sport:     $SPORT"
echo "  Bundle ID: $BUNDLE_ID"
echo "  Name:      $NAME"
echo "  Mode:      $MODE (macOS)"
echo "══════════════════════════════════════"

XCCONFIG="macos/Runner/Configs/AppInfo.xcconfig"
cp "$XCCONFIG" "$XCCONFIG.bak"

# ── Restore the checked-in (default) state on exit ────────────────────────────
restore() {
  echo "Restoring configs..."
  [ -f "$XCCONFIG.bak" ] && mv "$XCCONFIG.bak" "$XCCONFIG"
  if [ -f "assets/icon/app_icon.png.bak" ]; then
    mv "assets/icon/app_icon.png.bak" "assets/icon/app_icon.png"
    # Regenerate icons back to the default (multi-sport) art so the working
    # tree matches the checked-in state; the built .app already baked in the
    # sport icon during the build above.
    dart run flutter_launcher_icons >/dev/null 2>&1 || true
    git checkout -- ios/Runner/Assets.xcassets/AppIcon.appiconset \
                    android/app/src/main/res 2>/dev/null || true
  fi
}
trap restore EXIT

# ── Patch macOS app name + bundle id ──────────────────────────────────────────
sed -i '' "s/^PRODUCT_NAME = .*/PRODUCT_NAME = $NAME/" "$XCCONFIG"
sed -i '' "s/^PRODUCT_BUNDLE_IDENTIFIER = .*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID/" "$XCCONFIG"

# ── Sport-specific icon ───────────────────────────────────────────────────────
SPORT_ICON="assets/icon/${SPORT}_icon.png"
if [ -f "$SPORT_ICON" ]; then
  cp "assets/icon/app_icon.png" "assets/icon/app_icon.png.bak"
  cp "$SPORT_ICON" "assets/icon/app_icon.png"
  echo "  Icon: $SPORT_ICON"
  dart run flutter_launcher_icons 2>&1 | tail -1
fi

# ── Build (single-sport flavor via --dart-define=SPORT) ───────────────────────
# flutter build bakes the dart-define into macos/Flutter/ephemeral so a
# follow-up xcodebuild reuses it. A brand-new bundle id has no provisioning
# profile yet and `flutter build` can't create one (it omits
# -allowProvisioningUpdates), so fall back to xcodebuild, which can.
APP_PATH="build/macos/Build/Products/$CONFIG/$NAME.app"
# Remove any stale product so its mere presence can't be mistaken for success.
rm -rf "build/macos/Build/Products/$CONFIG/"*.app
flutter build macos --$MODE --dart-define=SPORT="$SPORT" 2>&1 | tail -3 || true
if [ ! -d "$APP_PATH" ]; then
  echo "→ first-time provisioning for $BUNDLE_ID; retrying via xcodebuild -allowProvisioningUpdates…"
  # -derivedDataPath keeps the product next to flutter's output (build/macos/…)
  # instead of the default DerivedData location.
  ( cd macos && xcodebuild -workspace Runner.xcworkspace -scheme Runner \
      -configuration "$CONFIG" -destination 'platform=macOS' \
      -derivedDataPath ../build/macos \
      -allowProvisioningUpdates build >/tmp/xcodebuild_macos_$SPORT.log 2>&1 ) || {
        echo "xcodebuild failed — tail of log:"; tail -20 /tmp/xcodebuild_macos_$SPORT.log; exit 1; }
fi

APP_PATH=$(find build/macos/Build/Products/"$CONFIG" -maxdepth 1 -name "*.app" | head -1)
echo ""
echo "✅ Built: $APP_PATH"
echo "   Sport: $SPORT ($NAME), bundle $BUNDLE_ID — badminton-only, no ads."
