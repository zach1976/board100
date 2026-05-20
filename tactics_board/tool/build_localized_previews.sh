#!/bin/bash
# build_localized_previews.sh
#
# For each sport: record the raw simulator footage once, then finalize an
# App Store preview video for every locale — identical footage, localized
# captions. The footage is locale-independent so it is only recorded once.
#
# Output: aso/previews/<sport>/<locale>/preview.mov
#
# Override the lists with env vars, e.g.
#   SPORTS="soccer badminton" LOCALES="en-US ja" bash tool/build_localized_previews.sh

cd "$(dirname "$0")/.."

SPORTS="${SPORTS:-badminton tableTennis tennis basketball volleyball pickleball soccer fieldHockey rugby baseball handball waterPolo sepakTakraw beachTennis footvolley}"
LOCALES="${LOCALES:-en-US es-ES fr-FR id ja ko ms th vi zh-Hans zh-Hant}"
NLOC=$(echo "$LOCALES" | wc -w | tr -d ' ')

SUMMARY=""
for sport in $SPORTS; do
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "  $sport"
  echo "════════════════════════════════════════════════════════"
  raw="/tmp/preview_${sport}_raw.mov"

  if bash tool/record_preview.sh "$sport" && [ -s "$raw" ]; then
    : # raw is ready
  else
    echo "▶ [$sport] recording failed — skipping finalize"
    SUMMARY="${SUMMARY}\n  ${sport}: rec:FAIL — skipped"
    rm -f "$raw"
    continue
  fi

  # Scan the raw once via the first locale (auto-detect trim/keep), then
  # reuse those values for every other locale so they skip the slow scan.
  ts=""; ks=""; ok=0
  for loc in $LOCALES; do
    out="aso/previews/${sport}/${loc}/preview.mov"
    if [ -z "$ts" ]; then
      log=$(python3 tool/finalize_preview.py --raw "$raw" --out "$out" --locale "$loc" 2>&1)
      echo "$log" | grep -E "app window|❌|✓ " | tail -2
      ts=$(echo "$log" | grep -oE "trim [0-9.]+s" | head -1 | grep -oE "[0-9.]+")
      ks=$(echo "$log" | grep -oE "keep [0-9.]+s" | head -1 | grep -oE "[0-9.]+")
    else
      python3 tool/finalize_preview.py --raw "$raw" --out "$out" --locale "$loc" \
        --trim-start "$ts" --keep "$ks" >/dev/null 2>&1
    fi
    [ -s "$out" ] && ok=$((ok + 1))
  done
  SUMMARY="${SUMMARY}\n  ${sport}: rec:PASS | ${ok}/${NLOC} locales finalized"
  rm -f "$raw"
done

echo ""
echo "════════════════════════════════════════════════════════"
echo "  BATCH SUMMARY"
echo -e "$SUMMARY"
echo "════════════════════════════════════════════════════════"
