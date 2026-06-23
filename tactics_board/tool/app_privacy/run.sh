#!/usr/bin/env bash
# Run an App Privacy fastlane lane with shared creds from projects/.env.
# Other projects can reuse this: copy this folder, share the same projects/.env.
#
# Usage:
#   ./run.sh verify                       # read back live labels (all ad apps)
#   ./run.sh privacy app:pingpong         # draft only (skip_publish), safe
#   ./run.sh privacy app:pingpong publish:true
#   ./run.sh privacy publish:true         # all apps in ad_apps.json
#
# Override the env file location with PROJECTS_ENV=/path/to/.env
set -euo pipefail

ENV_FILE="${PROJECTS_ENV:-$HOME/projects/.env}"
[[ -f "$ENV_FILE" ]] || { echo "env file not found: $ENV_FILE" >&2; exit 1; }

# Extract only the FASTLANE_* keys (the .env has other, non-sourceable content).
getenv() { grep -E "^$1=" "$ENV_FILE" | head -1 | cut -d= -f2- | sed -E "s/^['\"]//; s/['\"]$//"; }
export FASTLANE_USER="$(getenv FASTLANE_USER)"
export FASTLANE_ITC_TEAM_ID="$(getenv FASTLANE_ITC_TEAM_ID)"
export FASTLANE_SESSION="$(getenv FASTLANE_SESSION)"
export FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_HIDE_CHANGELOG=1

[[ -n "$FASTLANE_USER" ]] || { echo "FASTLANE_USER missing in $ENV_FILE" >&2; exit 1; }
if [[ -z "$FASTLANE_SESSION" ]]; then
  echo "FASTLANE_SESSION is empty/expired in $ENV_FILE." >&2
  echo "Refresh it in a real terminal:  fastlane spaceauth -u $FASTLANE_USER" >&2
  echo "then paste the printed value into $ENV_FILE (uncomment FASTLANE_SESSION=)." >&2
  exit 1
fi

cd "$(dirname "$0")"
exec fastlane ios "$@"
