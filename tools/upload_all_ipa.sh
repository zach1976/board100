#!/bin/bash
# Upload all 16 IPAs to App Store Connect via iTMSTransporter
# Usage: ./tool/upload_all_ipa.sh
set -u
cd "$(dirname "$0")/.."

KEY_ID="4A9Y2S3D6X"
ISSUER_ID="3d46fac5-4873-4806-bf23-3f8f17eddbbe"
IPA_DIR="build/ipa_all"

IPAS=(
  tacticsBoard.ipa
  soccerBoard.ipa
  basketballBoard.ipa
  volleyballBoard.ipa
  badmintonBoard.ipa
  tennisBoard.ipa
  tableTennisBoard.ipa
  pickleballBoard.ipa
  fieldHockeyBoard.ipa
  rugbyBoard.ipa
  baseballBoard.ipa
  handballBoard.ipa
  waterPoloBoard.ipa
  sepakTakrawBoard.ipa
  beachTennisBoard.ipa
  footvolleyBoard.ipa
)

for ipa in "${IPAS[@]}"; do
  path="$IPA_DIR/$ipa"
  echo ""
  echo "══════════════════════════════════════"
  echo "  Uploading: $ipa"
  echo "══════════════════════════════════════"
  if [ ! -f "$path" ]; then
    echo "  ❌ Missing: $path"
    continue
  fi
  # altool can hang for hours on bad ASC sessions — wrap in gtimeout, retry once.
  for attempt in 1 2; do
    if gtimeout 420 xcrun altool --upload-app -f "$path" -t ios \
        --apiKey "$KEY_ID" \
        --apiIssuer "$ISSUER_ID" 2>&1 | tail -5; then
      break
    fi
    if [ "$attempt" = "1" ]; then
      echo "  ⏳ altool failed/timed out — retrying once..."
      sleep 5
    fi
  done
  echo "── done: $ipa ──"
done

echo ""
echo "All uploads complete."
