#!/bin/bash
# record_all_previews.sh
#
# Records, finalizes and audits an App Store preview video for every sport.
# Output: aso/previews/<sport>/en-US/preview.mov
#
# Override the sport list with the SPORTS env var, e.g.
#   SPORTS="basketball tennis" bash tool/record_all_previews.sh

cd "$(dirname "$0")/.."

SPORTS="${SPORTS:-badminton tableTennis tennis basketball volleyball pickleball soccer fieldHockey rugby baseball handball waterPolo sepakTakraw beachTennis footvolley}"

SUMMARY=""
for sport in $SPORTS; do
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "  $sport"
  echo "════════════════════════════════════════════════════════"
  raw="/tmp/preview_${sport}_raw.mov"
  out="aso/previews/${sport}/en-US/preview.mov"

  if bash tool/record_preview.sh "$sport"; then
    test_tag="test:PASS"
  else
    test_tag="test:FAIL"
  fi

  python3 tool/finalize_preview.py --raw "$raw" --out "$out" 2>&1 \
    | grep -vE "DeprecationWarning|getdata" | tail -3 || true

  if [ -f "$out" ]; then
    audit=$(python3 tool/test_preview_video.py "$out" 2>/dev/null \
      | grep "tests passed" | tail -1 | tr -s ' ')
    SUMMARY="${SUMMARY}\n  ${sport}: ${test_tag} | audit:${audit} | ${out}"
  else
    SUMMARY="${SUMMARY}\n  ${sport}: ${test_tag} | finalize:FAIL (no output)"
  fi
  rm -f "$raw"
done

echo ""
echo "════════════════════════════════════════════════════════"
echo "  BATCH SUMMARY"
echo -e "$SUMMARY"
echo "════════════════════════════════════════════════════════"
