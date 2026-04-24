#!/bin/bash
# Build IPA for all 16 apps (multi-sport + 15 single-sport)
# Usage: ./tool/build_all_ipa.sh
set -e
cd "$(dirname "$0")/.."

PBXPROJ="ios/Runner.xcodeproj/project.pbxproj"
PLIST="ios/Runner/Info.plist"
IPA_DIR="build/ipa_all"
mkdir -p "$IPA_DIR"

# Save originals
cp "$PBXPROJ" "$PBXPROJ.bak"
cp "$PLIST" "$PLIST.bak"
for lproj in ios/Runner/*.lproj/InfoPlist.strings; do
  [ -f "$lproj" ] && cp "$lproj" "$lproj.bak"
done
cp "assets/icon/app_icon.png" "assets/icon/app_icon.png.bak"
cp "assets/icon/splash_logo.png" "assets/icon/splash_logo.png.bak"

restore() {
  echo "Restoring original configs..."
  [ -f "$PBXPROJ.bak" ] && mv "$PBXPROJ.bak" "$PBXPROJ"
  [ -f "$PLIST.bak" ] && mv "$PLIST.bak" "$PLIST"
  [ -f "assets/icon/app_icon.png.bak" ] && mv "assets/icon/app_icon.png.bak" "assets/icon/app_icon.png"
  [ -f "assets/icon/splash_logo.png.bak" ] && mv "assets/icon/splash_logo.png.bak" "assets/icon/splash_logo.png"
  for lproj in ios/Runner/*.lproj/InfoPlist.strings.bak; do
    [ -f "$lproj" ] && mv "$lproj" "${lproj%.bak}"
  done
}
trap restore EXIT

build_ipa() {
  local SPORT=$1
  local BUNDLE_ID=$2
  local DISPLAY_NAME=$3
  local ZH_NAME=$4
  local JA_NAME=$5
  local DART_DEFINES=$6

  echo ""
  echo "══════════════════════════════════════"
  echo "  Building: $DISPLAY_NAME"
  echo "  Bundle:   $BUNDLE_ID"
  echo "══════════════════════════════════════"

  # Restore to original before each build
  cp "$PBXPROJ.bak" "$PBXPROJ"
  cp "$PLIST.bak" "$PLIST"
  for lproj in ios/Runner/*.lproj/InfoPlist.strings.bak; do
    [ -f "$lproj" ] && cp "$lproj" "${lproj%.bak}"
  done
  cp "assets/icon/app_icon.png.bak" "assets/icon/app_icon.png"
  cp "assets/icon/splash_logo.png.bak" "assets/icon/splash_logo.png"

  # Patch bundle ID
  sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = com\.[^;]*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID/g" "$PBXPROJ"

  # Patch display name
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $DISPLAY_NAME" "$PLIST"

  # Localized names
  local LPROJ_DIR="ios/Runner"
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

  # Sport-specific icon
  if [ -n "$SPORT" ]; then
    local SPORT_ICON="assets/icon/${SPORT}_icon.png"
    local SPORT_SPLASH="assets/icon/${SPORT}_splash.png"
    [ -f "$SPORT_ICON" ] && cp "$SPORT_ICON" "assets/icon/app_icon.png"
    [ -f "$SPORT_SPLASH" ] && cp "$SPORT_SPLASH" "assets/icon/splash_logo.png"
    dart run flutter_launcher_icons 2>&1 | tail -1
  fi

  # Build IPA
  flutter build ipa --release $DART_DEFINES 2>&1 | tail -3

  # Copy IPA
  local IPA_FILE=$(ls build/ios/ipa/*.ipa 2>/dev/null | head -1)
  if [ -n "$IPA_FILE" ]; then
    local DEST="$IPA_DIR/${BUNDLE_ID##*.}.ipa"
    cp "$IPA_FILE" "$DEST"
    echo "✅ $DEST ($(du -h "$DEST" | cut -f1))"
  else
    echo "❌ No IPA generated for $DISPLAY_NAME"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# Build all 16 apps
# ══════════════════════════════════════════════════════════════════════════════

# Multi-sport (no SPORT define)
build_ipa "" "com.zach.tacticsBoard" "Tactics Board" "战术板" "タクティクスボード" ""

# Single-sport apps
build_ipa "soccer"      "com.zach.soccerBoard"      "Soccer Board"       "足球战术板"     "サッカーボード"         "--dart-define=SPORT=soccer"
build_ipa "basketball"  "com.zach.basketballBoard"  "Basketball Board"   "篮球战术板"     "バスケボード"           "--dart-define=SPORT=basketball"
build_ipa "volleyball"  "com.zach.volleyballBoard"  "Volleyball Board"   "排球战术板"     "バレーボード"           "--dart-define=SPORT=volleyball"
build_ipa "badminton"   "com.zach.badmintonBoard"   "Badminton Board"    "羽毛球战术板"   "バドミントンボード"     "--dart-define=SPORT=badminton"
build_ipa "tennis"      "com.zach.tennisBoard"      "Tennis Board"       "网球战术板"     "テニスボード"           "--dart-define=SPORT=tennis"
build_ipa "tableTennis" "com.zach.tableTennisBoard" "Table Tennis Board" "乒乓球战术板"   "卓球ボード"             "--dart-define=SPORT=tableTennis"
build_ipa "pickleball"  "com.zach.pickleballBoard"  "Pickleball Board"   "匹克球战术板"   "ピックルボールボード"   "--dart-define=SPORT=pickleball"
build_ipa "fieldHockey" "com.zach.fieldHockeyBoard" "Field Hockey Board" "曲棍球战术板"   "フィールドホッケーボード" "--dart-define=SPORT=fieldHockey"
build_ipa "rugby"       "com.zach.rugbyBoard"       "Rugby Board"        "橄榄球战术板"   "ラグビーボード"         "--dart-define=SPORT=rugby"
build_ipa "baseball"    "com.zach.baseballBoard"    "Baseball Board"     "棒球战术板"     "野球ボード"             "--dart-define=SPORT=baseball"
build_ipa "handball"    "com.zach.handballBoard"    "Handball Board"     "手球战术板"     "ハンドボールボード"     "--dart-define=SPORT=handball"
build_ipa "waterPolo"   "com.zach.waterPoloBoard"   "Water Polo Board"   "水球战术板"     "水球ボード"             "--dart-define=SPORT=waterPolo"
build_ipa "sepakTakraw" "com.zach.sepakTakrawBoard" "Sepak Takraw Board" "藤球战术板"     "セパタクローボード"     "--dart-define=SPORT=sepakTakraw"
build_ipa "beachTennis" "com.zach.beachTennisBoard" "Beach Tennis Board" "沙滩网球战术板" "ビーチテニスボード"     "--dart-define=SPORT=beachTennis"
build_ipa "footvolley"  "com.zach.footvolleyBoard"  "Footvolley Board"   "足排球战术板"   "フットボレーボード"     "--dart-define=SPORT=footvolley"

echo ""
echo "══════════════════════════════════════"
echo "  All IPAs:"
echo "══════════════════════════════════════"
ls -lh "$IPA_DIR/"*.ipa 2>/dev/null
