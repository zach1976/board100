#!/bin/bash
# build_all_aab.sh <key> [key ...] — signed Play bundles, one per app.
#
# Android counterpart of tools/build_all_ipa.sh, replacing
# tactics_board/tool/build_sport_android.sh (which patched applicationId,
# strings.xml, icons and splash into the shared project per sport, then
# restored). Each app owns those files now.
#
# Only 6 of the 16 apps exist on Play — tactics_board, soccer, basketball,
# volleyball, badminton, fieldHockey — so this takes an explicit list rather
# than defaulting to everything.
#
# Play needs a versionCode strictly higher than what is already live, and the
# live codes differ per app, so pass BUILD_NUMBER per app:
#   BUILD_NUMBER=5 tools/build_all_aab.sh tactics_board
#
# Output: build/aab_play/<key>-<version>.aab at the repo root.
set -e
cd "$(dirname "$0")/.."

TABLE="tools/sports.tsv"
OUT="build/aab_play"
mkdir -p "$OUT"

KEYS=("$@")
[ ${#KEYS[@]} -eq 0 ] && { echo "Usage: build_all_aab.sh <key> [key ...]"; exit 1; }

for KEY in "${KEYS[@]}"; do
  ROW=$(awk -F'\t' -v k="$KEY" '$1 == k && $1 !~ /^#/ {print; exit}' "$TABLE")
  [ -n "$ROW" ] || { echo "❌ unknown app '$KEY'"; exit 1; }
  IFS=$'\t' read -r _ DIR BUNDLE NAME_EN _ _ _ _ <<< "$ROW"

  # Each app's own version, like build_all_ipa.sh reads it. This used to come
  # from the core's pubspec, which is a library and does not move with the
  # apps: it still said 2.0.0 while every shell had gone to 2.2.0, so the
  # bundles would have been named — and the settings page would have shown —
  # a version nothing was shipping.
  VERSION=$(awk -F'[:+]' '/^version:/{gsub(/ /,"",$2); print $2; exit}' "$DIR/pubspec.yaml")

  # The settings page shows the version the build actually is; see kAppVersion.
  DEFINES="--dart-define=APP_VERSION=$VERSION"
  # The hub is a shell like the others (HubBoard/); it alone opts into its
  # own AdMob app with HUB_ADS (see lib/services/ad_service.dart).
  if [ "$KEY" = "tactics_board" ]; then
    DEFINES="$DEFINES --dart-define=HUB_ADS=1"
  fi
  [ -d "$DIR" ] || { echo "❌ $DIR missing — run tools/gen_sport_shell.sh $KEY"; exit 1; }

  echo "══════════════════════════════════════"
  echo "  $NAME_EN ($BUNDLE) — v$VERSION${BUILD_NUMBER:+ code $BUILD_NUMBER}"
  echo "══════════════════════════════════════"

  (cd "$DIR" && flutter build appbundle --release $DEFINES \
      ${BUILD_NUMBER:+--build-number="$BUILD_NUMBER"} 2>&1 | tail -3)

  DEST="$OUT/${KEY}-${VERSION}.aab"
  cp "$DIR/build/app/outputs/bundle/release/app-release.aab" "$DEST"
  echo "✅ $DEST"
done

ls -lh "$OUT"/*.aab 2>/dev/null
