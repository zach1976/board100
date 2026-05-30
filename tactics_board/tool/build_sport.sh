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
# ADMOB_APP_ID: the sport's AdMob iOS *application* ID (the "~" form, NOT the
# "/" ad-unit IDs). Leave empty for sports without ads — the checked-in
# Info.plist keeps Google's sample App ID so those builds never crash, and
# AdService gates off live ads for them. See lib/services/ad_service.dart.
ADMOB_APP_ID=""
case "$SPORT" in
  badminton)    BUNDLE_ID="com.zach.badmintonBoard";    DISPLAY_NAME="Badminton Board";    ZH_NAME="羽毛球战术板";  JA_NAME="バドミントンボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~8533679872" ;;
  tableTennis)  BUNDLE_ID="com.zach.tableTennisBoard";  DISPLAY_NAME="Table Tennis Board"; ZH_NAME="乒乓球战术板";  JA_NAME="卓球ボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~2607096007" ;;
  tennis)       BUNDLE_ID="com.zach.tennisBoard";       DISPLAY_NAME="Tennis Board";       ZH_NAME="网球战术板";    JA_NAME="テニスボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~1321934499" ;;
  basketball)   BUNDLE_ID="com.zach.basketballBoard";   DISPLAY_NAME="Basketball Board";   ZH_NAME="篮球战术板";    JA_NAME="バスケボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~7734769370" ;;
  volleyball)   BUNDLE_ID="com.zach.volleyballBoard";   DISPLAY_NAME="Volleyball Board";   ZH_NAME="排球战术板";    JA_NAME="バレーボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~2373641809" ;;
  pickleball)   BUNDLE_ID="com.zach.pickleballBoard";   DISPLAY_NAME="Pickleball Board";   ZH_NAME="匹克球战术板";  JA_NAME="ピックルボールボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~3191899453" ;;
  soccer)       BUNDLE_ID="com.zach.soccerBoard";       DISPLAY_NAME="Soccer Board";       ZH_NAME="足球战术板";    JA_NAME="サッカーボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~2977796941" ;;
  fieldHockey)  BUNDLE_ID="com.zach.fieldHockeyBoard";  DISPLAY_NAME="Field Hockey Board"; ZH_NAME="曲棍球战术板";  JA_NAME="フィールドホッケーボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~7240475581" ;;
  rugby)        BUNDLE_ID="com.zach.rugbyBoard";        DISPLAY_NAME="Rugby Board";        ZH_NAME="橄榄球战术板";  JA_NAME="ラグビーボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~3301230572" ;;
  baseball)     BUNDLE_ID="com.zach.baseballBoard";     DISPLAY_NAME="Baseball Board";     ZH_NAME="棒球战术板";    JA_NAME="野球ボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~8270486222" ;;
  handball)     BUNDLE_ID="com.zach.handballBoard";     DISPLAY_NAME="Handball Board";     ZH_NAME="手球战术板";    JA_NAME="ハンドボールボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~1878817785" ;;
  waterPolo)    BUNDLE_ID="com.zach.waterPoloBoard";    DISPLAY_NAME="Water Polo Board";   ZH_NAME="水球战术板";    JA_NAME="水球ボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~6692160761" ;;
  sepakTakraw)  BUNDLE_ID="com.zach.sepakTakrawBoard";  DISPLAY_NAME="Sepak Takraw Board"; ZH_NAME="藤球战术板";    JA_NAME="セパタクローボード" ;;
  beachTennis)  BUNDLE_ID="com.zach.beachTennisBoard";  DISPLAY_NAME="Beach Tennis Board"; ZH_NAME="沙滩网球战术板"; JA_NAME="ビーチテニスボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~8509629141" ;;
  footvolley)   BUNDLE_ID="com.zach.footvolleyBoard";   DISPLAY_NAME="Footvolley Board";   ZH_NAME="足排球战术板";  JA_NAME="フットボレーボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~6721904756" ;;
  *)
    echo "Unknown sport: $SPORT"
    echo "Available: badminton tableTennis tennis basketball volleyball pickleball soccer fieldHockey rugby baseball handball waterPolo sepakTakraw beachTennis footvolley"
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
# Backup all InfoPlist.strings
for lproj in ios/Runner/*.lproj/InfoPlist.strings; do
  [ -f "$lproj" ] && cp "$lproj" "$lproj.bak"
done

# ── Restore on exit ──────────────────────────────────────────────────────────
restore() {
  echo "Restoring original configs..."
  mv "$PBXPROJ.bak" "$PBXPROJ"
  mv "$PLIST.bak" "$PLIST"
  [ -f "assets/icon/app_icon.png.bak" ] && mv "assets/icon/app_icon.png.bak" "assets/icon/app_icon.png"
  [ -f "assets/icon/splash_logo.png.bak" ] && mv "assets/icon/splash_logo.png.bak" "assets/icon/splash_logo.png"
  [ -f "pubspec.yaml.bak" ] && mv "pubspec.yaml.bak" "pubspec.yaml"
  for lproj in ios/Runner/*.lproj/InfoPlist.strings.bak; do
    [ -f "$lproj" ] && mv "$lproj" "${lproj%.bak}"
  done
}
trap restore EXIT

# ── Patch iOS bundle ID ──────────────────────────────────────────────────────
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = com\.[^;]*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID/g" "$PBXPROJ"

# ── Patch iOS display name ───────────────────────────────────────────────────
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $DISPLAY_NAME" "$PLIST"

# ── Patch AdMob application identifier (only for sports that ship ads) ────────
if [ -n "$ADMOB_APP_ID" ]; then
  echo "  AdMob App: $ADMOB_APP_ID"
  /usr/libexec/PlistBuddy -c "Set :GADApplicationIdentifier $ADMOB_APP_ID" "$PLIST"
fi

# ── Patch localized app names ────────────────────────────────────────────────
LPROJ_DIR="ios/Runner"
for lproj in en.lproj; do
  echo "CFBundleDisplayName = \"$DISPLAY_NAME\";" > "$LPROJ_DIR/$lproj/InfoPlist.strings"
done
for lproj in zh-Hans.lproj zh-Hant.lproj; do
  [ -d "$LPROJ_DIR/$lproj" ] && echo "CFBundleDisplayName = \"$ZH_NAME\";" > "$LPROJ_DIR/$lproj/InfoPlist.strings"
done
for lproj in ja.lproj; do
  [ -d "$LPROJ_DIR/$lproj" ] && echo "CFBundleDisplayName = \"$JA_NAME\";" > "$LPROJ_DIR/$lproj/InfoPlist.strings"
done
for lproj in ko.lproj fr.lproj es.lproj vi.lproj th.lproj id.lproj ms.lproj; do
  [ -d "$LPROJ_DIR/$lproj" ] && echo "CFBundleDisplayName = \"$DISPLAY_NAME\";" > "$LPROJ_DIR/$lproj/InfoPlist.strings"
done

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

# ── Regenerate app icons with sport-specific image ───────────────────────────
if [ -f "$SPORT_ICON" ]; then
  dart run flutter_launcher_icons 2>&1 | tail -2
fi

# ── Regenerate native splash assets with sport-specific image ────────────────
if [ -f "$SPORT_SPLASH" ]; then
  # Sports that ship full-bleed stadium artwork — fill the screen instead of
  # centering at native size. Other sports keep the centered-logo style.
  case "$SPORT" in soccer|basketball|volleyball|tennis|badminton|pickleball|tableTennis|fieldHockey|rugby|baseball|handball|waterPolo|sepakTakraw|beachTennis) FULL_BLEED=1 ;; *) FULL_BLEED=0 ;; esac
  if [ "$FULL_BLEED" = "1" ]; then
    cp "pubspec.yaml" "pubspec.yaml.bak"
    sed -i '' 's/^  ios_content_mode: center$/  ios_content_mode: scaleAspectFill/' pubspec.yaml
    sed -i '' 's/^  android_gravity: center$/  android_gravity: fill/' pubspec.yaml
  fi
  dart run flutter_native_splash:create 2>&1 | tail -2
  [ -f "pubspec.yaml.bak" ] && mv "pubspec.yaml.bak" "pubspec.yaml"
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
