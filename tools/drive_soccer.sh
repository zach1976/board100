#!/usr/bin/env bash
# Drive the Soccer Board UI on a simulator and save a screenshot per step.
#
# Local inspection only: the taps happen inside the app, so nothing touches
# the mouse.
#
# integration_test is added to SoccerBoard/pubspec.yaml for the run and taken
# out again afterwards, including when the run fails. It is NOT a permanent
# dev dependency: a release build of this shell was verified to bundle
# integration_test.framework when it is declared, which is exactly the pod
# ced2daa had to clean out of the core's lock.
#
#   tools/drive_soccer.sh [simulator-udid] [integration_test/<file>.dart]
set -euo pipefail

UDID="${1:-$(xcrun simctl list devices booted | sed -n 's/.*(\([0-9A-F-]\{36\}\)).*/\1/p' | head -1)}"
TEST="${2:-integration_test/drill_library_test.dart}"
cd "$(dirname "$0")/../SoccerBoard"

restore() {
  mv -f pubspec.yaml.driveback pubspec.yaml 2>/dev/null || true
  flutter pub get >/dev/null 2>&1 || true
  # Not optional: Xcode's copy-frameworks phase only adds to the .app, so an
  # incremental release build after this keeps integration_test.framework even
  # with every lock file clean. Verified by listing .app/Frameworks/.
  flutter clean >/dev/null 2>&1 || true
}
trap restore EXIT

cp pubspec.yaml pubspec.yaml.driveback
python3 - <<'PY'
import pathlib
p = pathlib.Path('pubspec.yaml'); s = p.read_text()
s = s.replace("""dev_dependencies:
  flutter_test:
    sdk: flutter""", """dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter""", 1)
p.write_text(s)
PY
flutter pub get >/dev/null

# The app-open ad covers the screen on cold start and a driven run cannot tap
# a native ad away, so mark this install as Pro — the same switch a purchase
# flips. Simulator container only; it does not touch the shipped app.
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.zach.soccerBoard data 2>/dev/null || true)
if [ -n "$CONTAINER" ]; then
  PLIST="$CONTAINER/Library/Preferences/com.zach.soccerBoard.plist"
  /usr/libexec/PlistBuddy -c "Delete :flutter.remove_ads_pro" "$PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :flutter.remove_ads_pro bool true" "$PLIST" 2>/dev/null || true
fi

rm -rf screenshots
flutter drive --driver=test_driver/integration_test.dart --target="$TEST" -d "$UDID"
echo
ls -1 screenshots/ 2>/dev/null || echo "no screenshots written"
