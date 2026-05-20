#!/bin/bash
# record_preview.sh <sport>
#
# Boots the iPhone 17 Pro Max simulator, runs the preview-video integration
# test for the given sport, and screen-records the entire session.
#
#   <sport> = a SportType enum name: soccer, basketball, tennis, badminton,
#             tableTennis, volleyball, pickleball, fieldHockey, rugby,
#             baseball, handball, waterPolo, sepakTakraw, beachTennis,
#             footvolley
#
# Output: /tmp/preview_<sport>_raw.mov
#         /tmp/preview_test_<sport>.log

set -e
cd "$(dirname "$0")/.."

SPORT="${1:?usage: record_preview.sh <sport-enum-name>}"
DEVICE="${DEVICE:-F237E798-FBA9-44F8-81B4-71F160131DF9}"
RAW="/tmp/preview_${SPORT}_raw.mov"
LOG="/tmp/preview_test_${SPORT}.log"

echo "▶ [$SPORT] booting simulator $DEVICE"
xcrun simctl bootstatus "$DEVICE" -b 2>&1 | tail -1 || true
open -a Simulator
until xcrun simctl list devices | grep -E "$DEVICE.*Booted" > /dev/null 2>&1; do
  sleep 1
done

echo "▶ [$SPORT] erasing app data so the photo library starts fresh"
# The integration test always builds the dev bundle (com.zach.tacticsBoard)
# regardless of the SPORT dart-define — uninstall it so the photo library
# starts empty (stale photos would mismatch the imported faces).
xcrun simctl uninstall "$DEVICE" com.zach.tacticsBoard 2>/dev/null || true

# Pick the team photo for this sport: open-field team sports import an
# all-male squad; racquet / small-net sports import a mixed male+female
# photo (their preview places a mixed doubles pair). The chosen file is
# copied to the asset path the import hook reads.
TEAM_SPORTS="soccer basketball volleyball handball rugby fieldHockey baseball waterPolo"
if echo " $TEAM_SPORTS " | grep -q " $SPORT "; then
  SRC="assets/preview/team_male.jpg"
else
  SRC="assets/preview/team_mixed.jpg"
fi
[ -f "$SRC" ] || SRC="assets/preview/team_male.jpg"  # fallback if mixed not built yet
echo "▶ [$SPORT] using team photo $SRC"
cp "$SRC" assets/preview/team_photo.jpg

echo "▶ [$SPORT] starting screen recording → $RAW"
rm -f "$RAW"
xcrun simctl io "$DEVICE" recordVideo --codec=h264 "$RAW" &
REC_PID=$!
sleep 2

echo "▶ [$SPORT] running preview integration test"
flutter test integration_test/preview_sport.dart \
  -d "$DEVICE" \
  --dart-define=SPORT="$SPORT" \
  --dart-define=PREVIEW_PHOTO_PATH=asset:assets/preview/team_photo.jpg \
  2>&1 | tee "$LOG" | tail -20
TEST_EXIT=${PIPESTATUS[0]}

echo "▶ [$SPORT] stopping recording (test exit=$TEST_EXIT)"
kill -INT $REC_PID 2>/dev/null || true
wait $REC_PID 2>/dev/null || true

ls -lh "$RAW"
exit $TEST_EXIT
