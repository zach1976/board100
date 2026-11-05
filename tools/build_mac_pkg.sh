#!/bin/bash
# Build a Mac App Store .pkg for one app — the desktop counterpart of
# build_all_ipa.sh.
#
# macOS has no `flutter build pkg`, so this runs `flutter build macos` to
# assemble Flutter and bake the ephemeral xcconfig, then `xcodebuild archive`
# + `-exportArchive` with the app-store method to get a signed .pkg.
#
# It patches nothing: since 2026-09 each app owns its own macos/ project with
# its own bundle id and icon (CLAUDE.md, "one app = one directory"), so the
# old sed-the-core dance is gone.
#
# Usage: tools/build_mac_pkg.sh <sport>
set -e
cd "$(dirname "$0")/.."
[ $# -eq 1 ] || { echo "Usage: build_mac_pkg.sh <sport>"; exit 1; }
KEY="$1"

read -r DIR BUNDLE <<EOF
$(python3 -c "
import sys; sys.path.insert(0,'tools')
import apps
print(apps.app_dir('$KEY'), apps.bundle_id('$KEY'))")
EOF
[ -n "$DIR" ] || { echo "Unknown sport: $KEY"; exit 1; }

echo "══════════════════════════════════════"
echo "  macOS App Store pkg: $BUNDLE"
echo "  Dir: $DIR"
echo "══════════════════════════════════════"

cd "$DIR"
# May fail at the dev-signing step for a fresh bundle id; the assemble still
# completes, and the archive below does the real signing.
flutter build macos --release 2>&1 | tail -2 || true

ARCHIVE="build/macos_archive/$KEY.xcarchive"
rm -rf "$ARCHIVE"
# Automatic (development) signing here; the app-store export re-signs with
# Apple Distribution + a Mac App Store profile. Forcing the distribution
# identity at archive time conflicts with automatic signing.
( cd macos && xcodebuild -workspace Runner.xcworkspace -scheme Runner \
    -configuration Release -destination 'generic/platform=macOS' \
    -archivePath "../$ARCHIVE" -allowProvisioningUpdates \
    archive > "/tmp/mac_archive_$KEY.log" 2>&1 ) || {
      echo "❌ archive failed — tail:"; tail -20 "/tmp/mac_archive_$KEY.log"; exit 1; }

EXPORT="build/macos_export/$KEY"
rm -rf "$EXPORT"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT" \
  -exportOptionsPlist ../tactics_board/tool/ExportOptions_macos_appstore.plist \
  -allowProvisioningUpdates > "/tmp/mac_export_$KEY.log" 2>&1 || {
    echo "❌ export failed — tail:"; tail -25 "/tmp/mac_export_$KEY.log"; exit 1; }

PKG=$(ls "$EXPORT"/*.pkg 2>/dev/null | head -1)
[ -n "$PKG" ] || { echo "❌ no .pkg produced"; tail -15 "/tmp/mac_export_$KEY.log"; exit 1; }
mkdir -p ../build/pkg_all
DEST="../build/pkg_all/${BUNDLE##*.}.pkg"
cp "$PKG" "$DEST"
echo "✅ build/pkg_all/${BUNDLE##*.}.pkg ($(du -h "$DEST" | cut -f1))"
