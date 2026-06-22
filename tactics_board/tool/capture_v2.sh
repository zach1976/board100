#!/bin/bash
# Capture v2 raw screenshots per-sport so one sport's abort can't kill the rest.
# Re-runs a sport until all 66 (11 locales x 6) PNGs exist, max 3 attempts.
set -u
cd "$(dirname "$0")/.."
SIM="0C1CA515-FFAA-423E-975A-FBA042C7F5CF"
RAW="aso/screenshots_v2_raw"
SPORTS="badminton tableTennis tennis basketball volleyball pickleball soccer fieldHockey rugby baseball handball waterPolo sepakTakraw beachTennis footvolley"

count_sport() { find "$RAW/$1" -name "*.png" 2>/dev/null | wc -l | tr -d ' '; }

for sp in $SPORTS; do
  for attempt in 1 2 3; do
    n=$(count_sport "$sp")
    if [ "$n" -ge 66 ]; then echo "✔ $sp complete ($n)"; break; fi
    echo "▶ $sp attempt $attempt (have $n/66)"
    flutter test integration_test/appstore_screenshots.dart -d "$SIM" \
      --plain-name "${sp}_" >/tmp/cap_${sp}.log 2>&1
    n=$(count_sport "$sp")
    echo "  → $sp now $n/66"
    [ "$n" -ge 66 ] && { echo "✔ $sp complete"; break; }
  done
done

total=$(find "$RAW" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
echo "ALL DONE total=$total / 990 (15 sports x 66)"
