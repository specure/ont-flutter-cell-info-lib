#!/usr/bin/env bash
# Moves the NetMonster Core pin and runs the contract tests against the new version.
#
# Usage: tool/update_netmonster.sh [commit-sha | branch | tag]     (default: upstream HEAD)
#
# Outcomes:
#   - Kotlin does not compile: upstream changed an API the plugin (or its tests) uses.
#   - A fixture comparison fails: the JSON delivered to Flutter changed. If that is intended,
#     run `tool/test.sh --update-fixtures`, review `git diff test/fixtures` and adapt the Dart models.
#   - Everything passes: the Flutter-facing interface is unchanged. Finish with tool/device_test.sh.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
properties="$root/android/netmonster.properties"
repository="$(grep '^repository=' "$properties" | cut -d= -f2-)"
ref="${1:-HEAD}"

if [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then
  commit="$ref"
else
  commit="$(git ls-remote "$repository" "$ref" | awk 'NR == 1 { print $1 }')"
  if [[ -z "$commit" ]]; then
    echo "Could not resolve '$ref' in $repository (use a full 40-character SHA for arbitrary commits)" >&2
    exit 1
  fi
fi

previous="$(grep '^commit=' "$properties" | cut -d= -f2)"
echo "==> NetMonster Core: $previous -> $commit"
sed -i.bak "s/^commit=.*/commit=$commit/" "$properties" && rm "$properties.bak"

"$root/tool/test.sh"
