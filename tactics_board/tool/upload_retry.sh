#!/bin/bash
# Retry upload for a list of failed IPAs with up to 5 attempts each
# Usage: ./tool/upload_retry.sh file1.ipa file2.ipa ...
set -u
cd "$(dirname "$0")/.."

KEY_ID="4A9Y2S3D6X"
ISSUER_ID="3d46fac5-4873-4806-bf23-3f8f17eddbbe"
IPA_DIR="build/ipa_all"
MAX_ATTEMPTS=5

for ipa in "$@"; do
  path="$IPA_DIR/$ipa"
  [ -f "$path" ] || { echo "❌ Missing: $path"; continue; }

  success=0
  for attempt in $(seq 1 $MAX_ATTEMPTS); do
    echo ""
    echo "══════════════════════════════════════"
    echo "  Attempt $attempt/$MAX_ATTEMPTS: $ipa"
    echo "══════════════════════════════════════"
    out=$(xcrun iTMSTransporter -m upload \
            -assetFile "$path" \
            -apiKey "$KEY_ID" \
            -apiIssuer "$ISSUER_ID" 2>&1)
    echo "$out" | tail -15
    if echo "$out" | grep -q "was uploaded successfully"; then
      echo "✅ $ipa uploaded on attempt $attempt"
      success=1
      break
    fi
    if echo "$out" | grep -qE "was already uploaded|ERROR ITMS-90062|bundle version.*already been used"; then
      echo "ℹ️  $ipa already uploaded — treating as success"
      success=1
      break
    fi
    echo "⚠️  attempt $attempt failed, sleeping 20s before retry"
    sleep 20
  done
  [ $success -eq 1 ] || echo "❌ $ipa FAILED after $MAX_ATTEMPTS attempts"
done

echo ""
echo "Retry run complete."
