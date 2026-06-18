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
  [ -f "pubspec.yaml.splashbak" ] && mv "pubspec.yaml.splashbak" "pubspec.yaml"
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

  # Optional single-app filter: set ONLY to a sport key (or "" for the hub) to
  # build just that one app. Unset ONLY → build everything (default behavior).
  if [ -n "${ONLY+x}" ] && [ "$SPORT" != "$ONLY" ]; then return 0; fi

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

  # Patch AdMob App ID per sport (must match lib/services/ad_service.dart).
  # Sports without an AdMob app keep the checked-in sample ID — they run ad-free
  # at runtime (AdService has no ad units for them). Mirrors build_sport.sh.
  local ADMOB_APP_ID=""
  case "$SPORT" in
    "")          ADMOB_APP_ID="ca-app-pub-4247621509300508~5907516538" ;; # multi-sport hub (HUB_ADS build)
    badminton)   ADMOB_APP_ID="ca-app-pub-4247621509300508~8533679872" ;;
    tableTennis) ADMOB_APP_ID="ca-app-pub-4247621509300508~2607096007" ;;
    tennis)      ADMOB_APP_ID="ca-app-pub-4247621509300508~1321934499" ;;
    basketball)  ADMOB_APP_ID="ca-app-pub-4247621509300508~7734769370" ;;
    volleyball)  ADMOB_APP_ID="ca-app-pub-4247621509300508~2373641809" ;;
    pickleball)  ADMOB_APP_ID="ca-app-pub-4247621509300508~3191899453" ;;
    soccer)      ADMOB_APP_ID="ca-app-pub-4247621509300508~2977796941" ;;
    fieldHockey) ADMOB_APP_ID="ca-app-pub-4247621509300508~7240475581" ;;
    rugby)       ADMOB_APP_ID="ca-app-pub-4247621509300508~3301230572" ;;
    baseball)    ADMOB_APP_ID="ca-app-pub-4247621509300508~8270486222" ;;
    handball)    ADMOB_APP_ID="ca-app-pub-4247621509300508~1878817785" ;;
    waterPolo)   ADMOB_APP_ID="ca-app-pub-4247621509300508~6692160761" ;;
    beachTennis) ADMOB_APP_ID="ca-app-pub-4247621509300508~8509629141" ;;
    footvolley)  ADMOB_APP_ID="ca-app-pub-4247621509300508~6721904756" ;;
    sepakTakraw) ADMOB_APP_ID="ca-app-pub-4247621509300508~4478884795" ;;
  esac
  if [ -n "$ADMOB_APP_ID" ]; then
    /usr/libexec/PlistBuddy -c "Set :GADApplicationIdentifier $ADMOB_APP_ID" "$PLIST"
  fi

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
  fi

  # Always regenerate icons + native splash from the current source PNGs so the
  # multi-sport build doesn't ship leftover per-sport assets.
  dart run flutter_launcher_icons 2>&1 | tail -1
  # Sports that ship full-bleed stadium artwork; flip the splash content mode
  # for those builds only, then restore pubspec.yaml.
  local FULL_BLEED=0
  case "$SPORT" in ""|soccer|basketball|volleyball|tennis|badminton|pickleball|tableTennis|fieldHockey|rugby|baseball|handball|waterPolo|sepakTakraw|beachTennis) FULL_BLEED=1 ;; esac
  if [ "$FULL_BLEED" = "1" ]; then
    cp "pubspec.yaml" "pubspec.yaml.splashbak"
    sed -i '' 's/^  ios_content_mode: center$/  ios_content_mode: scaleAspectFill/' pubspec.yaml
    sed -i '' 's/^  android_gravity: center$/  android_gravity: fill/' pubspec.yaml
  fi
  dart run flutter_native_splash:create 2>&1 | tail -1
  [ -f "pubspec.yaml.splashbak" ] && mv "pubspec.yaml.splashbak" "pubspec.yaml"

  # Build IPA. IAP=1 turns on the in-app "Remove Ads" purchase (StoreKit) for
  # every iOS app; see lib/services/purchase_service.dart. Harmless until the
  # App Store Connect products (remove_ads_lifetime / remove_ads_yearly) exist.
  # Clear any prior app's IPA first: the copy step below just greps
  # build/ios/ipa, so a failed archive would otherwise ship the PREVIOUS
  # app's IPA under this app's name (a silent, dangerous mismatch).
  rm -f build/ios/ipa/*.ipa
  flutter build ipa --release $DART_DEFINES --dart-define=IAP=1 2>&1 | tail -3

  # Copy IPA
  local IPA_FILE=$(ls build/ios/ipa/*.ipa 2>/dev/null | head -1)
  if [ -n "$IPA_FILE" ]; then
    local DEST="$IPA_DIR/${BUNDLE_ID##*.}.ipa"
    cp "$IPA_FILE" "$DEST"
    echo "✅ $DEST ($(du -h "$DEST" | cut -f1))"
  else
    echo "❌ No IPA generated for $DISPLAY_NAME — archive failed, aborting"
    exit 1
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# Build all 16 apps
# ══════════════════════════════════════════════════════════════════════════════

# Multi-sport hub ("Coach Playbook") — no SPORT define, but opts into its own
# AdMob app (iOS App ID ~5907516538) via HUB_ADS. See lib/services/ad_service.dart.
build_ipa "" "com.zach.tacticsBoard" "Tactics Board" "战术板" "タクティクスボード" "--dart-define=HUB_ADS=1"

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
