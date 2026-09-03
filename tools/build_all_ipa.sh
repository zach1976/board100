#!/bin/bash
# build_all_ipa.sh [key ...] — release IPAs for the 16 App Store apps.
#
# Replaces the old tactics_board/tool/build_all_ipa.sh, which built every app
# out of the one project by patching bundle id / plist / icons / splash in
# place and restoring afterwards. Each app now owns those files, so a build is
# just `cd <app> && flutter build ipa`: no mutation of shared files, no
# restore step to get wrong, and two builds can't contaminate each other.
#
# Apps and their identity come from tools/sports.tsv. The hub (tactics_board)
# is both the shared core and an App Store app; it is built first.
#
#   tools/build_all_ipa.sh                 # all 16
#   tools/build_all_ipa.sh soccer rugby    # a subset
#   tools/build_all_ipa.sh tactics_board   # the hub only
#
# Output: build/ipa_all/<bundleSuffix>.ipa at the repo root.
set -e
cd "$(dirname "$0")/.."

TABLE="tools/sports.tsv"
OUT="build/ipa_all"
mkdir -p "$OUT"

KEYS=("$@")
if [ ${#KEYS[@]} -eq 0 ]; then
  KEYS=($(awk -F'\t' '!/^#/ && NF >= 8 {print $1}' "$TABLE"))
fi

for KEY in "${KEYS[@]}"; do
  ROW=$(awk -F'\t' -v k="$KEY" '$1 == k && $1 !~ /^#/ {print; exit}' "$TABLE")
  [ -n "$ROW" ] || { echo "❌ unknown app '$KEY'"; exit 1; }
  IFS=$'\t' read -r _ DIR BUNDLE NAME_EN _ _ _ _ <<< "$ROW"

  # The hub has no shell directory — it is the core project itself, and opts
  # into its own AdMob app with HUB_ADS (see lib/services/ad_service.dart).
  DEFINES="--dart-define=IAP=1"
  if [ "$DIR" = "-" ]; then
    DIR="tactics_board"
    DEFINES="$DEFINES --dart-define=HUB_ADS=1"
  fi
  [ -d "$DIR" ] || { echo "❌ $DIR missing — run tools/gen_sport_shell.sh $KEY"; exit 1; }

  echo ""
  echo "══════════════════════════════════════"
  echo "  Building: $NAME_EN"
  echo "  Dir:      $DIR"
  echo "  Bundle:   $BUNDLE"
  echo "══════════════════════════════════════"

  # Clear the previous archive: the copy below just globs build/ios/ipa, so a
  # failed archive would otherwise ship the PREVIOUS app's IPA under this
  # app's name — a silent, dangerous mismatch.
  rm -f "$DIR/build/ios/ipa/"*.ipa
  # IAP=1 turns on the StoreKit "Remove Ads" purchase for every iOS release
  # build; see lib/services/purchase_service.dart.
  (cd "$DIR" && flutter build ipa --release $DEFINES 2>&1 | tail -3)

  IPA_FILE=$(ls "$DIR/build/ios/ipa/"*.ipa 2>/dev/null | head -1)
  if [ -z "$IPA_FILE" ]; then
    echo "❌ No IPA generated for $NAME_EN — archive failed, aborting"
    exit 1
  fi
  DEST="$OUT/${BUNDLE##*.}.ipa"
  cp "$IPA_FILE" "$DEST"
  echo "✅ $DEST ($(du -h "$DEST" | cut -f1))"
done

echo ""
echo "══════════════════════════════════════"
ls -lh "$OUT"/*.ipa 2>/dev/null
