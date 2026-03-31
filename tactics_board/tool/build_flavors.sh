#!/bin/bash
# Build separate apps for each sport
# Usage: ./tool/build_flavors.sh [sport] [platform]
# Example: ./tool/build_flavors.sh badminton ios
#          ./tool/build_flavors.sh all ios

set -e
cd "$(dirname "$0")/.."

SPORTS=(badminton tableTennis tennis basketball volleyball pickleball soccer)
BUNDLE_PREFIX="com.zach"

# App names per sport
declare -A APP_NAMES
APP_NAMES[badminton]="Badminton Board"
APP_NAMES[tableTennis]="Table Tennis Board"
APP_NAMES[tennis]="Tennis Board"
APP_NAMES[basketball]="Basketball Board"
APP_NAMES[volleyball]="Volleyball Board"
APP_NAMES[pickleball]="Pickleball Board"
APP_NAMES[soccer]="Soccer Board"

# Bundle ID suffixes
declare -A BUNDLE_IDS
BUNDLE_IDS[badminton]="${BUNDLE_PREFIX}.badmintonBoard"
BUNDLE_IDS[tableTennis]="${BUNDLE_PREFIX}.tableTennisBoard"
BUNDLE_IDS[tennis]="${BUNDLE_PREFIX}.tennisBoard"
BUNDLE_IDS[basketball]="${BUNDLE_PREFIX}.basketballBoard"
BUNDLE_IDS[volleyball]="${BUNDLE_PREFIX}.volleyballBoard"
BUNDLE_IDS[pickleball]="${BUNDLE_PREFIX}.pickleballBoard"
BUNDLE_IDS[soccer]="${BUNDLE_PREFIX}.soccerBoard"

SPORT=${1:-all}
PLATFORM=${2:-ios}

build_sport() {
  local sport=$1
  local name="${APP_NAMES[$sport]}"
  local bundle="${BUNDLE_IDS[$sport]}"

  echo "========================================="
  echo "Building: $name ($bundle)"
  echo "Sport: $sport, Platform: $PLATFORM"
  echo "========================================="

  if [ "$PLATFORM" = "ios" ]; then
    flutter build ios --release \
      --dart-define=SPORT=$sport \
      --dart-define=APP_NAME="$name" \
      --dart-define=BUNDLE_ID=$bundle
  elif [ "$PLATFORM" = "android" ]; then
    flutter build apk --release \
      --dart-define=SPORT=$sport \
      --dart-define=APP_NAME="$name" \
      --dart-define=BUNDLE_ID=$bundle
  fi

  echo "Done: $name"
  echo ""
}

if [ "$SPORT" = "all" ]; then
  for s in "${SPORTS[@]}"; do
    build_sport "$s"
  done
else
  build_sport "$SPORT"
fi

echo "All builds complete!"
