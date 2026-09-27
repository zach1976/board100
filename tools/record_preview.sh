#!/usr/bin/env bash
# Record an App Store preview video of one app on a simulator.
#
#   tools/record_preview.sh <sport-key> [simulator-udid]
#
# What happens: the simulator's display is recorded while tools/drive_app.sh
# runs the paced tour in tools/drive/preview_video.dart. The tour prints two
# marks; the film is cut to them, so the build, the install, the springboard
# and the splash never appear.
#
# Output: build/preview/<key>.mp4 — H.264, 30fps, the device's own
# resolution, which is what App Store Connect wants for that size class.
# mp4 rather than the mov simctl records: App Store Connect takes either,
# but a browser will not play a file whose type says quicktime, and the
# release review page embeds this film.
# Apple takes 15–30 seconds; anything outside that is reported here rather
# than discovered at upload.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
KEY="${1:?usage: tools/record_preview.sh <sport-key> [udid]}"
UDID="${2:-$(xcrun simctl list devices booted | sed -n 's/.*(\([0-9A-F-]\{36\}\)).*/\1/p' | head -1)}"

OUT="$REPO/build/preview"
mkdir -p "$OUT"
RAW="$OUT/$KEY-raw.mov"
FINAL="$OUT/$KEY.mp4"
LOG="$OUT/$KEY-drive.log"
RECLOG="$OUT/$KEY-record.log"

now_ms() { python3 -c 'import time; print(int(time.time()*1000))'; }

echo "══ recording $KEY on $UDID"
rm -f "$RAW" "$FINAL" "$LOG" "$RECLOG"

xcrun simctl io "$UDID" recordVideo --codec h264 --force "$RAW" 2>"$RECLOG" &
REC_PID=$!

# simctl says so on stderr once the first frame is in. Waiting for the line
# rather than sleeping is what makes the offsets below mean anything: the
# clock starts at the first recorded frame, not at the fork.
for _ in $(seq 1 100); do
  grep -q "Recording started" "$RECLOG" 2>/dev/null && break
  sleep 0.2
done
grep -q "Recording started" "$RECLOG" || { echo "✗ recorder never started"; kill $REC_PID 2>/dev/null; exit 1; }
REC_START=$(now_ms)
echo "  recorder up at $REC_START"

set +e
# IAP=1 so the saved ad-removal flag is actually read — see drive_app.sh.
WALK=preview_video DRIVE_DEFINES="--dart-define=IAP=1" \
  "$REPO/tools/drive_app.sh" "$KEY" "$UDID" >"$LOG" 2>&1
DRIVE_RC=$?
set -e

kill -INT $REC_PID 2>/dev/null || true
wait $REC_PID 2>/dev/null || true
[ -s "$RAW" ] || { echo "✗ nothing recorded"; exit 1; }

if [ $DRIVE_RC -ne 0 ]; then
  echo "  ! the tour exited $DRIVE_RC — film kept for inspection"
  tail -20 "$LOG"
fi

MARK_START=$(sed -n 's/.*PREVIEW_MARK start \([0-9]*\).*/\1/p' "$LOG" | head -1)
MARK_END=$(sed -n 's/.*PREVIEW_MARK end \([0-9]*\).*/\1/p' "$LOG" | head -1)
if [ -z "$MARK_START" ] || [ -z "$MARK_END" ]; then
  echo "✗ the tour printed no marks; raw film at $RAW"
  exit 1
fi

SS=$(python3 -c "print(max(0,($MARK_START-$REC_START)/1000))")
DUR=$(python3 -c "print(($MARK_END-$MARK_START)/1000)")
echo "  cut from ${SS}s for ${DUR}s"

# -ss before -i seeks, then re-encode: the raw film is variable frame rate
# and App Store Connect wants a constant 30. yuv420p because anything else
# will not play everywhere.
# A muted STEREO track, not -an. Apple transcodes a silent App Preview and
# then fails it with MOV_RESAVE_STEREO; the film has to carry audio even
# when there is nothing to hear.
ffmpeg -loglevel error -y -ss "$SS" -i "$RAW" -t "$DUR" \
  -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
  -r 30 -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p \
  -c:a aac -b:a 128k -shortest -movflags +faststart "$FINAL"

read -r W H FPS SECS < <(ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate -show_entries format=duration \
  -of default=nw=1:nk=1 "$FINAL" | paste -sd' ' -)
MB=$(python3 -c "import os;print(round(os.path.getsize('$FINAL')/1048576,1))")
echo "✅ $FINAL"
echo "   ${W}x${H} · ${FPS} · ${SECS}s · ${MB} MB"
python3 - "$SECS" <<'PY'
import sys
d = float(sys.argv[1])
if d < 15 or d > 30:
    print(f"   ⚠️  App Store wants 15–30s; this is {d:.1f}s")
PY
