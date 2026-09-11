#!/usr/bin/env bash
# Stamps the version into project.yml.
#
# The build number is derived from git history rather than hand-incremented,
# so it moves on its own with every commit and can never be forgotten:
#
#   Tools/stamp_version.sh          # bump the build number only
#   Tools/stamp_version.sh 1.1      # also set the marketing version
#
# Run it before building. The app reads these back out of its bundle at
# runtime, so what is displayed is always what was actually shipped.
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD=$(( $(git rev-list --count HEAD) + 1 ))
sed -i '' -E "s/^([[:space:]]*CURRENT_PROJECT_VERSION: ).*/\1\"${BUILD}\"/" project.yml

if [ -n "${1:-}" ]; then
  sed -i '' -E "s/^([[:space:]]*MARKETING_VERSION: ).*/\1\"${1}\"/" project.yml
fi

MARKETING=$(grep -E "^[[:space:]]*MARKETING_VERSION:" project.yml | sed -E 's/.*: *"?([^"]*)"?.*/\1/')
echo "stamped ${MARKETING} (build ${BUILD})"
