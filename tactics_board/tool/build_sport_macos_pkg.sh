#!/bin/bash
# Build a Mac App Store .pkg for a single sport (archive + app-store export).
# The desktop counterpart of build_all_ipa.sh's per-sport iOS IPA build.
#
# macOS has no `flutter build pkg`, so this: patches the per-sport config,
# runs `flutter build macos` (to assemble Flutter + bake the SPORT define into
# the ephemeral xcconfig), then `xcodebuild archive` + `-exportArchive` with
# the app-store method to produce a signed .pkg.
#
# Usage: ./tool/build_sport_macos_pkg.sh <sport>
set -e
cd "$(dirname "$0")/.."

# An explicit empty arg ("") is the multi-sport hub; no arg at all is an error.
if [ $# -lt 1 ]; then echo "Usage: build_sport_macos_pkg.sh <sport|''>"; exit 1; fi
SPORT="$1"

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
  "")           BUNDLE_ID="com.zach.tacticsBoard";      NAME="Tactics Board" ;;  # hub
  *) echo "Unknown sport: $SPORT"; exit 1 ;;
esac

PKG_DIR="build/pkg_all"
mkdir -p "$PKG_DIR"
XCCONFIG="macos/Runner/Configs/AppInfo.xcconfig"
cp "$XCCONFIG" "$XCCONFIG.bak"

restore() {
  [ -f "$XCCONFIG.bak" ] && mv "$XCCONFIG.bak" "$XCCONFIG"
  if [ -f "assets/icon/app_icon.png.bak" ]; then
    mv "assets/icon/app_icon.png.bak" "assets/icon/app_icon.png"
    dart run flutter_launcher_icons >/dev/null 2>&1 || true
    git checkout -- ios/Runner/Assets.xcassets/AppIcon.appiconset \
                    android/app/src/main/res 2>/dev/null || true
  fi
}
trap restore EXIT

echo "══════════════════════════════════════"
echo "  macOS App Store pkg: $NAME ($BUNDLE_ID)"
echo "══════════════════════════════════════"

# Patch name + bundle id
sed -i '' "s/^PRODUCT_NAME = .*/PRODUCT_NAME = $NAME/" "$XCCONFIG"
sed -i '' "s/^PRODUCT_BUNDLE_IDENTIFIER = .*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID/" "$XCCONFIG"

# Sport icon
if [ -n "$SPORT" ] && [ -f "assets/icon/${SPORT}_icon.png" ]; then
  cp "assets/icon/app_icon.png" "assets/icon/app_icon.png.bak"
  cp "assets/icon/${SPORT}_icon.png" "assets/icon/app_icon.png"
  dart run flutter_launcher_icons 2>&1 | tail -1
fi

DEFINE=""
[ -n "$SPORT" ] && DEFINE="--dart-define=SPORT=$SPORT"

# 1) flutter build → assemble + bake ephemeral (SPORT define). May fail at the
#    dev-signing step for a fresh bundle id; the assemble still completes.
flutter build macos --release $DEFINE 2>&1 | tail -2 || true

# 2) Archive with app-store distribution signing (auto-provision if needed).
# The hub has an empty SPORT; use a non-empty label so paths aren't ".xcarchive".
LABEL="${SPORT:-hub}"
ARCHIVE="build/macos_archive/$LABEL.xcarchive"
rm -rf "$ARCHIVE"
# Archive with automatic (development) signing; the app-store export below
# re-signs with Apple Distribution + a Mac App Store profile. Forcing the
# distribution identity here conflicts with automatic signing.
( cd macos && xcodebuild -workspace Runner.xcworkspace -scheme Runner \
    -configuration Release -destination 'generic/platform=macOS' \
    -archivePath "../$ARCHIVE" \
    -allowProvisioningUpdates \
    archive >/tmp/mac_archive_$LABEL.log 2>&1 ) || {
      echo "❌ archive failed — tail:"; tail -20 /tmp/mac_archive_$LABEL.log; exit 1; }

# 3) Export as app-store .pkg (signed with the installer cert).
EXPORT="build/macos_export/$LABEL"
rm -rf "$EXPORT"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT" \
  -exportOptionsPlist tool/ExportOptions_macos_appstore.plist \
  -allowProvisioningUpdates >/tmp/mac_export_$LABEL.log 2>&1 || {
    echo "❌ export failed — tail:"; tail -25 /tmp/mac_export_$LABEL.log; exit 1; }

PKG=$(ls "$EXPORT"/*.pkg 2>/dev/null | head -1)
if [ -n "$PKG" ]; then
  DEST="$PKG_DIR/${BUNDLE_ID##*.}.pkg"
  cp "$PKG" "$DEST"
  echo "✅ $DEST ($(du -h "$DEST" | cut -f1))"
else
  echo "❌ no .pkg produced"; tail -15 /tmp/mac_export_$LABEL.log; exit 1
fi
