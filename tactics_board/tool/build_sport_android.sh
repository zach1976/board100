#!/bin/bash
# Build signed Android App Bundles (.aab) for single-sport apps.
#
# Android counterpart of tool/build_sport.sh. For each sport it patches the
# applicationId, the localized app_name strings, and swaps in the sport icon
# and splash, then builds a release .aab signed with the upload keystore
# (android/key.properties). All originals are restored on exit.
#
# Usage: ./tool/build_sport_android.sh <sport> [sport2 ...]
#        ./tool/build_sport_android.sh basketball soccer volleyball badminton
set -e
set -o pipefail
cd "$(dirname "$0")/.."

SPORTS=("$@")
[ ${#SPORTS[@]} -eq 0 ] && { echo "Usage: build_sport_android.sh <sport> [sport2 ...]"; exit 1; }

GRADLE="android/app/build.gradle.kts"
RES="android/app/src/main/res"
MANIFEST="android/app/src/main/AndroidManifest.xml"
OUT="build/aab_play"
mkdir -p "$OUT"

# ── Backup originals ─────────────────────────────────────────────────────────
RES_BAK="$(mktemp -d)/res"
cp -R "$RES" "$RES_BAK"
cp "$GRADLE" "$GRADLE.bak"
cp "$MANIFEST" "$MANIFEST.bak"
cp "assets/icon/app_icon.png" "assets/icon/app_icon.png.bak"
cp "assets/icon/splash_logo.png" "assets/icon/splash_logo.png.bak"
cp "pubspec.yaml" "pubspec.yaml.bak"

restore() {
  echo "Restoring original configs..."
  [ -f "$GRADLE.bak" ] && mv "$GRADLE.bak" "$GRADLE"
  [ -f "$MANIFEST.bak" ] && mv "$MANIFEST.bak" "$MANIFEST"
  [ -d "$RES_BAK" ] && { rm -rf "$RES"; mv "$RES_BAK" "$RES"; }
  [ -f "assets/icon/app_icon.png.bak" ] && mv "assets/icon/app_icon.png.bak" "assets/icon/app_icon.png"
  [ -f "assets/icon/splash_logo.png.bak" ] && mv "assets/icon/splash_logo.png.bak" "assets/icon/splash_logo.png"
  [ -f "pubspec.yaml.bak" ] && mv "pubspec.yaml.bak" "pubspec.yaml"
}
trap restore EXIT

# ── Limit icon/splash regeneration to Android (leave iOS assets untouched) ───
sed -i '' 's/^  ios: true$/  ios: false/' pubspec.yaml

write_strings() {  # $1 = strings.xml path, $2 = app name
  cat > "$1" <<XML
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">$2</string>
</resources>
XML
}

VERSION=$(grep -E '^version:' pubspec.yaml.bak | sed 's/version: //; s/+.*//')

for SPORT in "${SPORTS[@]}"; do
  # ADMOB_APP_ID: the sport's AdMob *Android* application ID (the "~" form, NOT
  # the "/" ad-unit IDs). Leave empty for sports without ads — the checked-in
  # manifest keeps Google's sample App ID so those builds never crash, and
  # AdService gates off live ads for them. See lib/services/ad_service.dart.
  ADMOB_APP_ID=""
  case "$SPORT" in
    basketball) BUNDLE_ID="com.zach.basketballBoard"; DISPLAY_NAME="Basketball Board"; ZH_NAME="篮球战术板";   JA_NAME="バスケボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~2744495676" ;;
    soccer)     BUNDLE_ID="com.zach.soccerBoard";     DISPLAY_NAME="Soccer Board";     ZH_NAME="足球战术板";   JA_NAME="サッカーボード" ;;
    volleyball) BUNDLE_ID="com.zach.volleyballBoard"; DISPLAY_NAME="Volleyball Board"; ZH_NAME="排球战术板";   JA_NAME="バレーボード" ;;
    badminton)  BUNDLE_ID="com.zach.badmintonBoard";  DISPLAY_NAME="Badminton Board";  ZH_NAME="羽毛球战术板"; JA_NAME="バドミントンボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~5809946636" ;;
    fieldHockey) BUNDLE_ID="com.zach.fieldHockeyBoard"; DISPLAY_NAME="Field Hockey Board"; ZH_NAME="曲棍球战术板"; JA_NAME="フィールドホッケーボード" ;; # Android: no AdMob app → ad-free
    # Below: no Android AdMob app → ad-free on Android (keep checked-in sample ID).
    tennis)      BUNDLE_ID="com.zach.tennisBoard";      DISPLAY_NAME="Tennis Board";       ZH_NAME="网球战术板";     JA_NAME="テニスボード" ;;
    tableTennis) BUNDLE_ID="com.zach.tableTennisBoard"; DISPLAY_NAME="Table Tennis Board"; ZH_NAME="乒乓球战术板";   JA_NAME="卓球ボード" ;;
    pickleball)  BUNDLE_ID="com.zach.pickleballBoard";  DISPLAY_NAME="Pickleball Board";   ZH_NAME="匹克球战术板";   JA_NAME="ピックルボールボード" ;;
    beachTennis) BUNDLE_ID="com.zach.beachTennisBoard"; DISPLAY_NAME="Beach Tennis Board"; ZH_NAME="沙滩网球战术板"; JA_NAME="ビーチテニスボード" ;;
    footvolley)  BUNDLE_ID="com.zach.footvolleyBoard";  DISPLAY_NAME="Footvolley Board";   ZH_NAME="足排球战术板";   JA_NAME="フットボレーボード" ;;
    baseball)    BUNDLE_ID="com.zach.baseballBoard";    DISPLAY_NAME="Baseball Board";     ZH_NAME="棒球战术板";     JA_NAME="野球ボード" ;;
    handball)    BUNDLE_ID="com.zach.handballBoard";    DISPLAY_NAME="Handball Board";     ZH_NAME="手球战术板";     JA_NAME="ハンドボールボード" ;;
    waterPolo)   BUNDLE_ID="com.zach.waterPoloBoard";   DISPLAY_NAME="Water Polo Board";   ZH_NAME="水球战术板";     JA_NAME="水球ボード" ;;
    rugby)       BUNDLE_ID="com.zach.rugbyBoard";       DISPLAY_NAME="Rugby Board";        ZH_NAME="橄榄球战术板";   JA_NAME="ラグビーボード" ;;
    sepakTakraw) BUNDLE_ID="com.zach.sepakTakrawBoard"; DISPLAY_NAME="Sepak Takraw Board"; ZH_NAME="藤球战术板";     JA_NAME="セパタクローボード" ;;
    # Multi-sport hub: built with NO SPORT define, uses the default app icon/splash,
    # and serves ads via HUB_ADS (its own Android AdMob app ~4532136942).
    tactics_board) BUNDLE_ID="com.zach.tacticsBoard"; DISPLAY_NAME="Tactics Board"; ZH_NAME="战术板"; JA_NAME="タクティクスボード"; ADMOB_APP_ID="ca-app-pub-4247621509300508~4532136942" ;;
    *) echo "Unknown sport: $SPORT"; echo "Available: basketball soccer volleyball badminton fieldHockey tennis tableTennis pickleball beachTennis footvolley baseball handball waterPolo rugby sepakTakraw tactics_board"; exit 1 ;;
  esac

  echo "══════════════════════════════════════"
  echo "  Sport:     $SPORT"
  echo "  App ID:    $BUNDLE_ID"
  echo "  Name:      $DISPLAY_NAME"
  echo "  Version:   $VERSION"
  echo "══════════════════════════════════════"

  # ── Patch applicationId ────────────────────────────────────────────────────
  sed -i '' "s/applicationId = \"[^\"]*\"/applicationId = \"$BUNDLE_ID\"/" "$GRADLE"

  # ── Patch AdMob application identifier (only for sports that ship ads) ──────
  if [ -n "$ADMOB_APP_ID" ]; then
    echo "  AdMob App: $ADMOB_APP_ID"
    sed -i '' "s|ca-app-pub-[0-9]*~[0-9]*|$ADMOB_APP_ID|" "$MANIFEST"
  fi

  # ── Patch localized app_name (mirror iOS build_sport.sh) ───────────────────
  for dir in "$RES"/values "$RES"/values-*; do
    f="$dir/strings.xml"
    [ -f "$f" ] || continue
    case "$(basename "$dir")" in
      values-zh|values-zh-rTW) write_strings "$f" "$ZH_NAME" ;;
      values-ja)               write_strings "$f" "$JA_NAME" ;;
      *)                       write_strings "$f" "$DISPLAY_NAME" ;;
    esac
  done

  # ── Swap sport icon + splash, regenerate native assets ─────────────────────
  # The hub has no per-sport asset; it keeps the checked-in default app icon/splash.
  if [ "$SPORT" != "tactics_board" ]; then
    cp "assets/icon/${SPORT}_icon.png" "assets/icon/app_icon.png"
    cp "assets/icon/${SPORT}_splash.png" "assets/icon/splash_logo.png"
  fi
  dart run flutter_launcher_icons 2>&1 | tail -2
  dart run flutter_native_splash:create 2>&1 | tail -2

  # ── Build signed app bundle ────────────────────────────────────────────────
  # Play needs a versionCode strictly higher than what's already live. Override
  # via BUILD_NUMBER env (e.g. BUILD_NUMBER=2) since pubspec's "+1" → code 1.
  # The hub builds with NO SPORT define (multi-sport) but opts into ads via
  # HUB_ADS=1, matching build_all_ipa.sh. Single sports pass their SPORT.
  if [ "$SPORT" = "tactics_board" ]; then
    DART_DEFINES="--dart-define=HUB_ADS=1"
  else
    DART_DEFINES="--dart-define=SPORT=$SPORT"
  fi
  flutter build appbundle --release $DART_DEFINES \
    ${BUILD_NUMBER:+--build-number="$BUILD_NUMBER"}

  DEST="$OUT/${SPORT}-${VERSION}.aab"
  cp "build/app/outputs/bundle/release/app-release.aab" "$DEST"
  echo "✅ $SPORT → $DEST"
done

echo ""
echo "All signed AABs:"
ls -la "$OUT"
