#!/usr/bin/env bash
# Drive one app's UI on a simulator and save a screenshot per step.
#
# Local inspection only: the taps happen inside the app, so nothing touches
# the mouse. Templates live in tools/drive/ and are copied into the app for
# the run, along with the integration_test dev dependency, and all of it is
# removed again afterwards — including on failure.
#
# integration_test is deliberately not a permanent dependency: a release build
# with it declared bundles integration_test.framework, which is the pod
# ced2daa had to clean out of the core's lock. Xcode's copy-frameworks phase
# only ever adds to the .app, so the restore runs flutter clean too.
#
#   tools/drive_app.sh <sport-key> [simulator-udid]
#   tools/drive_app.sh all         [simulator-udid]
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
KEY="${1:?usage: tools/drive_app.sh <sport-key|all> [udid]}"
UDID="${2:-$(xcrun simctl list devices booted | sed -n 's/.*(\([0-9A-F-]\{36\}\)).*/\1/p' | head -1)}"

drive_one() {
  local key="$1"
  local dir bundle pkg
  dir=$(python3 -c "import sys; sys.path.insert(0,'$REPO/tools'); from apps import APPS; print(APPS['$key']['dir'])")
  bundle=$(python3 -c "import sys; sys.path.insert(0,'$REPO/tools'); from apps import APPS; print(APPS['$key']['bundle'])")
  cd "$REPO/$dir"
  pkg=$(sed -n 's/^name: *//p' pubspec.yaml | head -1)

  echo "══ $key — $dir ($bundle, package $pkg)"

  restore() {
    mv -f pubspec.yaml.driveback pubspec.yaml 2>/dev/null || true
    rm -rf integration_test test_driver
    flutter pub get >/dev/null 2>&1 || true
    flutter clean >/dev/null 2>&1 || true
  }
  trap restore RETURN

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
  mkdir -p integration_test test_driver
  cp "$REPO/tools/drive/driver.dart" test_driver/integration_test.dart
  sed "s/__PACKAGE__/$pkg/" "$REPO/tools/drive/ui_walk.dart" > integration_test/ui_walk.dart
  flutter pub get >/dev/null

  # The cold-start app-open ad covers the screen and a driven run cannot tap a
  # native ad away, so mark this install as Pro — the switch a purchase flips.
  # Simulator container only.
  #
  # Install first: an app that has never been installed has no data container,
  # so writing the flag before this point writes it nowhere. The container then
  # survives the reinstall that flutter drive does.
  flutter install -d "$UDID" >/dev/null 2>&1 || true
  local container plist
  container=$(xcrun simctl get_app_container "$UDID" "$bundle" data 2>/dev/null || true)
  if [ -n "$container" ]; then
    plist="$container/Library/Preferences/$bundle.plist"
    /usr/libexec/PlistBuddy -c "Delete :flutter.remove_ads_pro" "$plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :flutter.remove_ads_pro bool true" "$plist" 2>/dev/null || true
  else
    echo "  ! no data container for $bundle — the app-open ad may cover the walk"
  fi

  rm -rf screenshots
  flutter drive --driver=test_driver/integration_test.dart \
                --target=integration_test/ui_walk.dart -d "$UDID"
  echo "  → $dir/screenshots: $(ls -1 screenshots 2>/dev/null | tr '\n' ' ')"
}

if [ "$KEY" = "all" ]; then
  for k in $(python3 -c "import sys; sys.path.insert(0,'$REPO/tools'); from apps import APPS; print(' '.join(APPS))"); do
    drive_one "$k" || echo "  ✗ $k FAILED"
  done
else
  drive_one "$KEY"
fi
