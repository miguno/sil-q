#!/usr/bin/env bash
#
# File: verify-tutorial.sh
#
# Verifies that the tutorial savefile's version header matches the expected
# game version from Sil-Q-version.txt.

set -euo pipefail

# shellcheck disable=SC2155
readonly SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck disable=SC2155
readonly PROJECT_DIR=$(readlink -f "$SCRIPT_DIR/..")
readonly VERSION_FILE="$PROJECT_DIR/Sil-Q-version.txt"
readonly TUTORIAL_SAVEFILE="$PROJECT_DIR/lib/xtra/tutorial"

# Get expected a.b.c.d version from version file.
expected_version=$(grep '^Sil-Q version:' "$VERSION_FILE" | sed -n 's/.*(\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\)).*/\1/p')
# Get actual a.b.c.d version from tutorial savefile.
actual_version=$("$SCRIPT_DIR/savefile.sh" "$TUTORIAL_SAVEFILE" | sed -n 's/.*: \([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*/\1/p')

echo "Tutorial savefile version: expected=$expected_version, actual=$actual_version"

if [ "$expected_version" != "$actual_version" ]; then
    echo "ERROR: tutorial savefile version mismatch (expected $expected_version, was $actual_version)" >&2
    exit 1
fi

echo "OK"
