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
OUT="build/aab_play"
mkdir -p "$OUT"

# ── Backup originals ─────────────────────────────────────────────────────────
RES_BAK="$(mktemp -d)/res"
cp -R "$RES" "$RES_BAK"
cp "$GRADLE" "$GRADLE.bak"
cp "assets/icon/app_icon.png" "assets/icon/app_icon.png.bak"
cp "assets/icon/splash_logo.png" "assets/icon/splash_logo.png.bak"
cp "pubspec.yaml" "pubspec.yaml.bak"

restore() {
  echo "Restoring original configs..."
  [ -f "$GRADLE.bak" ] && mv "$GRADLE.bak" "$GRADLE"
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
  case "$SPORT" in
    basketball) BUNDLE_ID="com.zach.basketballBoard"; DISPLAY_NAME="Basketball Board"; ZH_NAME="篮球战术板";   JA_NAME="バスケボード" ;;
    soccer)     BUNDLE_ID="com.zach.soccerBoard";     DISPLAY_NAME="Soccer Board";     ZH_NAME="足球战术板";   JA_NAME="サッカーボード" ;;
    volleyball) BUNDLE_ID="com.zach.volleyballBoard"; DISPLAY_NAME="Volleyball Board"; ZH_NAME="排球战术板";   JA_NAME="バレーボード" ;;
    badminton)  BUNDLE_ID="com.zach.badmintonBoard";  DISPLAY_NAME="Badminton Board";  ZH_NAME="羽毛球战术板"; JA_NAME="バドミントンボード" ;;
    *) echo "Unknown sport: $SPORT"; echo "Available: basketball soccer volleyball badminton"; exit 1 ;;
  esac

  echo "══════════════════════════════════════"
  echo "  Sport:     $SPORT"
  echo "  App ID:    $BUNDLE_ID"
  echo "  Name:      $DISPLAY_NAME"
  echo "  Version:   $VERSION"
  echo "══════════════════════════════════════"

  # ── Patch applicationId ────────────────────────────────────────────────────
  sed -i '' "s/applicationId = \"[^\"]*\"/applicationId = \"$BUNDLE_ID\"/" "$GRADLE"

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
  cp "assets/icon/${SPORT}_icon.png" "assets/icon/app_icon.png"
  cp "assets/icon/${SPORT}_splash.png" "assets/icon/splash_logo.png"
  dart run flutter_launcher_icons 2>&1 | tail -2
  dart run flutter_native_splash:create 2>&1 | tail -2

  # ── Build signed app bundle ────────────────────────────────────────────────
  flutter build appbundle --release --dart-define=SPORT=$SPORT

  DEST="$OUT/${SPORT}-${VERSION}.aab"
  cp "build/app/outputs/bundle/release/app-release.aab" "$DEST"
  echo "✅ $SPORT → $DEST"
done

echo ""
echo "All signed AABs:"
ls -la "$OUT"
