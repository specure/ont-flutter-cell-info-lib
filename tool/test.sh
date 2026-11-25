#!/usr/bin/env bash
# Runs every check that does not need a device:
#   1. Kotlin contract tests  - plugin mapping code + pinned NetMonster Core -> JSON fixtures
#   2. Dart tests             - Dart API and models against the same fixtures
#   3. Example app tests
#
# Usage: tool/test.sh [--update-fixtures]
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
update_fixtures=false
[[ "${1:-}" == "--update-fixtures" ]] && update_fixtures=true

echo "==> NetMonster Core pinned at $(grep '^commit=' "$root/android/netmonster.properties" | cut -d= -f2)"

echo "==> Kotlin contract tests"
(cd "$root/example" && flutter pub get >/dev/null && flutter build apk --debug --config-only >/dev/null)
(cd "$root/example/android" && ./gradlew :cell_info:testDebugUnitTest -PupdateFixtures="$update_fixtures" --console=plain -q)

echo "==> Dart tests"
(cd "$root" && flutter analyze && flutter test)

echo "==> Example app tests"
(cd "$root/example" && flutter analyze && flutter test)

echo "==> All host checks passed"
