#!/usr/bin/env bash
# Shoot one app's raw store screenshots on a simulator.
#
# The harness is tactics_board/integration_test/appstore_screenshots.dart,
# and it has to run from a SHELL — the core is a library, and a board shot
# from it has no ball on it. A shell does not carry integration_test as a
# dependency (a release build that declares it bundles the framework), so
# this script patches it in, copies the harness over, runs, and takes both
# out again — the same dance as tools/drive_app.sh, including on failure.
#
#   tools/capture_store_shots.sh <sport-key> <phone-udid>          # phone set
#   tools/capture_store_shots.sh <sport-key> <ipad-udid>  ipad     # iPad set, landscape
#
# SHELL=<key> shoots from another app. The home page's name comes from
# sport.displayName, not from the bundle, so every sport looks the same shot
# from any shell that HAS its assets — and the hub has all fifteen. One run
# of SHELL=tactics_board with no sport filter replaces fifteen separate ones.
# SPORTS="a b" narrows a multi-sport run; empty shoots every sport.
#
# Phone shots land in tactics_board/aso/screenshots_v2_raw/<sport>/<locale>/,
# iPad shots in tactics_board/aso/screenshots_v2_raw_ipad/ — the harness
# chooses by SHOT_ROOT, so one set never overwrites the other.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
KEY="${1:?usage: tools/capture_store_shots.sh <sport-key|all> <udid> [ipad]}"
UDID="${2:?usage: tools/capture_store_shots.sh <sport-key|all> <udid> [ipad]}"
MODE="${3:-phone}"
SHELL_KEY="${SHELL_APP:-$KEY}"

DIR=$(python3 -c "import sys; sys.path.insert(0,'$REPO/tools'); from apps import APPS; print(APPS['$SHELL_KEY']['dir'])")
HARNESS="$REPO/tactics_board/integration_test/appstore_screenshots.dart"
cd "$REPO/$DIR"

DEFINES=()
if [ "$MODE" = "ipad" ]; then
  DEFINES+=(--dart-define=LANDSCAPE=true
            --dart-define=SHOT_ROOT="$REPO/tactics_board/aso/screenshots_v2_raw_ipad")
fi

restore() {
  mv -f pubspec.yaml.shotback pubspec.yaml 2>/dev/null || true
  rm -f integration_test/appstore_screenshots.dart
  rmdir integration_test 2>/dev/null || true
  flutter pub get >/dev/null 2>&1 || true
  # Xcode's copy-frameworks phase only ever adds to the .app: without a
  # clean the next release build would ship integration_test.framework.
  flutter clean >/dev/null 2>&1 || true
}
trap restore EXIT

if [ -f pubspec.yaml.shotback ]; then
  echo "! recovering pubspec.yaml from a previous run"
  mv -f pubspec.yaml.shotback pubspec.yaml
fi
cp pubspec.yaml pubspec.yaml.shotback
python3 - <<'PY'
import pathlib
p = pathlib.Path('pubspec.yaml'); s = p.read_text()
assert 'integration_test' not in s, 'pubspec is already patched'
s = s.replace("""dev_dependencies:
  flutter_test:
    sdk: flutter""", """dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter""", 1)
p.write_text(s)
PY
mkdir -p integration_test
cp "$HARNESS" integration_test/appstore_screenshots.dart
flutter pub get >/dev/null

# "all" shoots every sport the shell carries — no name filter at all.
# NAME_RE=<regex> picks a set of them instead: the test names are
# <sport>_<locale>_s<n>, so "(rugby|handball)_" is two sports, every locale.
FILTER=()
if [ -n "${NAME_RE:-}" ]; then
  FILTER=(--name "$NAME_RE")
elif [ "$KEY" != "all" ]; then
  FILTER=(--plain-name "${KEY}_")
fi

echo "══ $KEY — shell $DIR → $MODE on $UDID"
flutter test integration_test/appstore_screenshots.dart -d "$UDID" \
  ${FILTER[@]+"${FILTER[@]}"} ${DEFINES[@]+"${DEFINES[@]}"} 2>&1 \
  | grep -E "📸|✓|✗|Error|error|failed|passed" || true
