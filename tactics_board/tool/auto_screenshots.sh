#!/bin/bash
# Automated App Store screenshots using cliclick + simctl
# Usage: ./tool/auto_screenshots.sh
set -e
cd "$(dirname "$0")/.."

SIM_ID=DC18AEE8-4BB3-42D1-BF28-55F85628415A
SSDIR="$(pwd)/screenshots"

# Get simulator window position
get_sim_pos() {
  osascript -e '
  tell application "Simulator" to activate
  delay 0.3
  tell application "System Events"
    tell process "Simulator"
      set win to first window
      set winPos to position of win
      set winSize to size of win
      return (item 1 of winPos as text) & "," & (item 2 of winPos as text) & "," & (item 1 of winSize as text) & "," & (item 2 of winSize as text)
    end tell
  end tell
  '
}

# Parse window position
IFS=',' read -r WIN_X WIN_Y WIN_W WIN_H <<< "$(get_sim_pos)"
echo "Simulator window: x=$WIN_X y=$WIN_Y w=$WIN_W h=$WIN_H"

# The simulator has a bezel/chrome. The actual screen content area offset:
# Top bezel ~38px, side bezels ~10px each
BEZEL_TOP=38
BEZEL_LEFT=10
SCREEN_W=$((WIN_W - 20))  # minus left+right bezel
SCREEN_H=$((WIN_H - BEZEL_TOP - 10))  # minus top+bottom bezel

# Convert simulator screen coordinates (0-1 normalized) to screen coordinates
tap() {
  local nx=$1  # 0.0 - 1.0
  local ny=$2  # 0.0 - 1.0
  local sx=$(python3 -c "print(int($WIN_X + $BEZEL_LEFT + $SCREEN_W * $nx))")
  local sy=$(python3 -c "print(int($WIN_Y + $BEZEL_TOP + $SCREEN_H * $ny))")
  cliclick c:$sx,$sy
  sleep 0.5
}

screenshot() {
  local name=$1
  sleep 1
  xcrun simctl io $SIM_ID screenshot "$name" 2>/dev/null
  echo "  📸 $(basename $name)"
}

take_sport_screenshots() {
  local sport=$1
  local lang=$2
  local dir="$SSDIR/$sport/$lang"
  mkdir -p "$dir"

  echo "── $sport / $lang ──"

  # 1. Empty court
  screenshot "$dir/01_empty.png"

  # 2. Tap "Add Player" button (bottom center-left area)
  tap 0.42 0.96
  sleep 1
  screenshot "$dir/02_add_sheet.png"

  # 3. Tap first formation card (top of sheet, first card)
  tap 0.25 0.72
  sleep 1
  screenshot "$dir/03_formation.png"

  # 4. Close sheet by tapping on court
  tap 0.5 0.3
  sleep 0.5

  # 5. Tap player 1 (home, bottom half)
  tap 0.35 0.72
  sleep 0.5

  # Add move 1
  tap 0.5 0.55
  sleep 0.3
  # Add move 2
  tap 0.65 0.45
  sleep 0.3
  # Add move 3
  tap 0.4 0.40
  sleep 0.5

  screenshot "$dir/04_moves.png"

  # 6. Deselect
  tap 0.1 0.1
  sleep 0.5

  # 7. Tap step forward (play controls area)
  # Play controls are in the middle row between court and toolbar
  tap 0.55 0.91  # step forward button
  sleep 1.5
  screenshot "$dir/05_playing.png"

  echo "  ✅ $sport/$lang done"
}

# ── Main flow ──
SPORTS=(badminton basketball soccer tennis tableTennis volleyball pickleball)

for sport in "${SPORTS[@]}"; do
  echo ""
  echo "══════════════════════════════════"
  echo "  Starting: $sport"
  echo "══════════════════════════════════"

  # Kill previous flutter
  kill $(pgrep -f "flutter run") 2>/dev/null || true
  sleep 2

  # Launch app for this sport
  flutter run -d $SIM_ID --dart-define=SPORT=$sport 2>&1 &
  sleep 15

  # Take English screenshots
  take_sport_screenshots "$sport" "en-US"

  # Switch language to Chinese via menu
  # Tap menu button (top right)
  tap 0.95 0.08
  sleep 0.5
  # Tap "Language" (first menu item)
  tap 0.8 0.15
  sleep 0.5
  # Tap "简体中文" (second item in language list)
  tap 0.5 0.35
  sleep 1

  # Reset state - tap clear all
  # ...actually the state is preserved, just retake
  take_sport_screenshots "$sport" "zh-Hans"

  echo "  ✅ $sport complete"
done

echo ""
echo "══ All screenshots complete ══"
find "$SSDIR" -name "*.png" | wc -l
