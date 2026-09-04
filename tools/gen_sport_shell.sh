#!/bin/bash
# gen_sport_shell.sh <sport> [sport2 ...] — create/refresh a single-sport shell
# project from the shared core (tactics_board/) and tools/sports.tsv.
#
# A shell is a real Flutter app whose lib/ is ~20 lines: it sets ConfigConstants
# and calls tactics_board's mainReal(). Everything that used to be patched into
# the core at build time and restored afterwards — bundle id, display names,
# AdMob app id, icons, splash — is committed inside the shell instead. That is
# the whole point: no build ever mutates another app's files again.
#
# The platform folders are copied from the core's *tracked* files (git ls-files),
# so no build artifacts, Pods or generated splash assets come along, and every
# local customization (Podfile, entitlements, gradle signing, lproj, scenes)
# is preserved — `flutter create` would silently drop them.
#
# Re-running regenerates a shell in place (icons/splash included). Safe: the
# shell owns nothing hand-written except lib/main.dart, which is regenerated
# from the same table.
#
# Usage:
#   tools/gen_sport_shell.sh badminton
#   tools/gen_sport_shell.sh all          # every sport in the table
set -e
cd "$(dirname "$0")/.."

CORE="tactics_board"
TABLE="tools/sports.tsv"
[ -f "$TABLE" ] || { echo "missing $TABLE"; exit 1; }

row() {  # $1 = sport key -> tab-separated row, or empty
  awk -F'\t' -v k="$1" '$1 == k && $1 !~ /^#/ {print; exit}' "$TABLE"
}

all_keys() {
  awk -F'\t' '!/^#/ && NF >= 8 && $2 != "-" {print $1}' "$TABLE"
}

SPORTS=("$@")
[ ${#SPORTS[@]} -eq 0 ] && { echo "Usage: gen_sport_shell.sh <sport|all> ..."; exit 1; }
[ "${SPORTS[0]}" = "all" ] && SPORTS=($(all_keys))

for SPORT in "${SPORTS[@]}"; do
  ROW="$(row "$SPORT")"
  [ -n "$ROW" ] || { echo "❌ unknown sport '$SPORT' (not in $TABLE)"; exit 1; }
  IFS=$'\t' read -r KEY DIR BUNDLE NAME_EN NAME_ZH NAME_JA ADMOB_IOS ADMOB_ANDROID <<< "$ROW"
  [ "$DIR" = "-" ] && { echo "❌ $KEY is the hub — it lives in $CORE/, not a shell"; exit 1; }

  echo "═══════════════════════════════════════════════"
  echo "  $KEY → $DIR"
  echo "  bundle:  $BUNDLE"
  echo "  name:    $NAME_EN / $NAME_ZH / $NAME_JA"
  echo "  admob:   ios=$ADMOB_IOS android=$ADMOB_ANDROID"
  echo "═══════════════════════════════════════════════"

  # ── platform folders + project files, from the core's tracked files ────────
  # The shell OWNS its artwork and store metadata (assets/, fastlane/): those
  # are inputs, not generated, so a regeneration must preserve them. Everything
  # else under $DIR is reproducible from the core + this table.
  KEEP=$(mktemp -d)
  for own in assets fastlane; do
    [ -d "$DIR/$own" ] && mv "$DIR/$own" "$KEEP/$own"
  done
  rm -rf "$DIR"
  mkdir -p "$DIR"
  for own in assets fastlane; do
    [ -d "$KEEP/$own" ] && mv "$KEEP/$own" "$DIR/$own"
  done
  rmdir "$KEEP" 2>/dev/null || true
  (cd "$CORE" && git ls-files ios android macos analysis_options.yaml) | while read -r f; do
    mkdir -p "$DIR/$(dirname "$f")"
    cp "$CORE/$f" "$DIR/$f"
  done
  # Local signing secret (gitignored in both places); release builds need it.
  [ -f "$CORE/android/key.properties" ] && cp "$CORE/android/key.properties" "$DIR/android/key.properties"

  # ── pubspec: depends on the core, generates its own icons + splash ─────────
  VERSION=$(grep -E '^version:' "$CORE/pubspec.yaml" | sed 's/version: //')
  PKG=$(echo "$KEY" | tr '[:upper:]' '[:lower:]')_board
  cat > "$DIR/pubspec.yaml" <<YAML
name: ${PKG}
description: "${NAME_EN} — single-sport shell over the shared tactics_board core."
publish_to: 'none'
# Kept in lockstep with the core: every app in this repo ships one version.
version: ${VERSION}

environment:
  sdk: ^3.11.0

dependencies:
  flutter:
    sdk: flutter
  # The whole app. This shell only picks the sport and hands over — see
  # lib/main.dart and tactics_board/lib/config_constants.dart.
  tactics_board:
    path: ../${CORE}

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  flutter_launcher_icons: ^0.14.3
  flutter_native_splash: ^2.4.4

flutter:
  uses-material-design: true

# Native icons/splash are generated ONCE (by tools/gen_sport_shell.sh) and
# committed, so a build never regenerates assets into another app's folders.
# The sources are this app's own assets/icon/ — no other app's artwork is
# reachable from here.
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#1E1E2E"
  adaptive_icon_foreground: "assets/icon/app_icon.png"
  web:
    generate: false
  macos:
    generate: true
    image_path: "assets/icon/app_icon.png"

flutter_native_splash:
  color: "#1A3A4A"
  image: assets/icon/splash_logo.png
  ios_content_mode: scaleAspectFill
  android_gravity: fill
  android_12:
    color: "#1A3A4A"
    image: assets/icon/splash_logo.png
    icon_background_color: "#1A3A4A"
  fullscreen: true
  android: true
  ios: true
YAML

  # ── the shell's entire Dart source ────────────────────────────────────────
  mkdir -p "$DIR/lib"
  cat > "$DIR/lib/main.dart" <<DART
import 'package:tactics_board/config_constants.dart';
import 'package:tactics_board/main.dart';
import 'package:tactics_board/models/sport_type.dart';

/// ${NAME_EN} (${BUNDLE}) — a single-sport build of the shared board.
///
/// Everything below is configuration; the app itself is the tactics_board
/// package. Per-sport ad unit ids are NOT set here on purpose: AdService
/// looks them up by sport, so this shell cannot get them wrong.
void main() {
  ConfigConstants.fixedSportType = SportType.${KEY};
  // The core is a dependency here, so its assets live under
  // packages/tactics_board/ in this app's bundle.
  ConfigConstants.hasPackagePath = true;
  mainReal();
}
DART

  cat > "$DIR/.gitignore" <<'GIT'
# Generated by tools/gen_sport_shell.sh; everything else in here is committed.
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
build/
ios/Flutter/Generated.xcconfig
ios/Flutter/flutter_export_environment.sh
ios/Podfile.lock
ios/Pods/
ios/.symlinks/
macos/Flutter/ephemeral/
macos/Pods/
macos/Podfile.lock
android/.gradle/
android/local.properties
android/key.properties
GIT

  # ── iOS identity ──────────────────────────────────────────────────────────
  sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = com\.[^;]*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE/g" \
    "$DIR/ios/Runner.xcodeproj/project.pbxproj"
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $NAME_EN" "$DIR/ios/Runner/Info.plist"
  if [ "$ADMOB_IOS" != "-" ]; then
    /usr/libexec/PlistBuddy -c "Set :GADApplicationIdentifier $ADMOB_IOS" "$DIR/ios/Runner/Info.plist"
  fi
  # Localized display names (the store shows these per device language).
  echo "CFBundleDisplayName = \"$NAME_EN\";" > "$DIR/ios/Runner/en.lproj/InfoPlist.strings"
  for l in zh-Hans zh-Hant; do
    [ -d "$DIR/ios/Runner/$l.lproj" ] && echo "CFBundleDisplayName = \"$NAME_ZH\";" > "$DIR/ios/Runner/$l.lproj/InfoPlist.strings"
  done
  [ -d "$DIR/ios/Runner/ja.lproj" ] && echo "CFBundleDisplayName = \"$NAME_JA\";" > "$DIR/ios/Runner/ja.lproj/InfoPlist.strings"
  for l in ko fr es vi th id ms; do
    [ -d "$DIR/ios/Runner/$l.lproj" ] && echo "CFBundleDisplayName = \"$NAME_EN\";" > "$DIR/ios/Runner/$l.lproj/InfoPlist.strings"
  done

  # ── Android identity ──────────────────────────────────────────────────────
  # applicationId only: the Kotlin namespace stays com.zachsong.tactics_board so
  # MainActivity keeps its package (this mirrors the old build script exactly —
  # the store identity is the applicationId).
  sed -i '' "s/applicationId = \"[^\"]*\"/applicationId = \"$BUNDLE\"/" \
    "$DIR/android/app/build.gradle.kts"
  if [ "$ADMOB_ANDROID" != "-" ]; then
    sed -i '' "s|ca-app-pub-[0-9]*~[0-9]*|$ADMOB_ANDROID|" \
      "$DIR/android/app/src/main/AndroidManifest.xml"
  fi
  for d in "$DIR/android/app/src/main/res"/values "$DIR/android/app/src/main/res"/values-*; do
    f="$d/strings.xml"; [ -f "$f" ] || continue
    case "$(basename "$d")" in
      values-zh|values-zh-rTW) N="$NAME_ZH" ;;
      values-ja)               N="$NAME_JA" ;;
      *)                       N="$NAME_EN" ;;
    esac
    printf '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <string name="app_name">%s</string>\n</resources>\n' "$N" > "$f"
  done

  # ── macOS identity ────────────────────────────────────────────────────────
  XC="$DIR/macos/Runner/Configs/AppInfo.xcconfig"
  sed -i '' "s/^PRODUCT_NAME = .*/PRODUCT_NAME = $NAME_EN/" "$XC"
  sed -i '' "s/^PRODUCT_BUNDLE_IDENTIFIER = .*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE/" "$XC"

  # ── resolve deps, then generate the native icons + splash once ────────────
  for f in app_icon.png splash_logo.png; do
    [ -f "$DIR/assets/icon/$f" ] || {
      echo "❌ $DIR/assets/icon/$f missing — an app owns its artwork; add it first"
      exit 1
    }
  done
  # Start from the core's resolved versions: a shell that resolves a *newer*
  # google_mobile_ads than the core pinned would need a newer Google-Mobile-Ads
  # pod than the copied Podfile.lock (and the local CocoaPods spec cache) has.
  # Every app in this repo ships the same dependency set by construction.
  cp "$CORE/pubspec.lock" "$DIR/pubspec.lock"
  (cd "$DIR" && flutter pub get >/dev/null)
  (cd "$DIR" && dart run flutter_launcher_icons 2>&1 | tail -1)
  (cd "$DIR" && dart run flutter_native_splash:create 2>&1 | tail -1)

  echo "✅ $DIR ready"
done
