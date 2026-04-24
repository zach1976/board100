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
  xcrun altool --upload-app -f "$path" -t ios \
    --apiKey "$KEY_ID" \
    --apiIssuer "$ISSUER_ID" 2>&1 | tail -5
  echo "── done: $ipa ──"
done

echo ""
echo "All uploads complete."
