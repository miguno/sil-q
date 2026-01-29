#!/usr/bin/env bash
#
# File: smoke-tests.sh
#
# Runs basic "smoke" tests to verify that a generated `sil` binary works as
# expected.
#
# Only Linux and (non-Cocoa) macOS builds are currently supported.

set -euo pipefail

# shellcheck disable=SC2155
readonly SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck disable=SC2155
readonly PROJECT_DIR=$(readlink -f "$SCRIPT_DIR/..")
readonly DEFINES_H="$PROJECT_DIR/src/defines.h"
readonly VERSION_FILE="$PROJECT_DIR/Sil-Q-version.txt"
readonly SIL_BINARY="$PROJECT_DIR/sil"

###
### Test 1: Check the `sil -v` version info against src/defines.h
###         (also verifies whether the `sil` executable can run at all)
###

# Get expected version from src/defines.h.
# shellcheck disable=SC2155
readonly expected_version_string=$(grep '#define VERSION_STRING' "$DEFINES_H" | sed 's/.*"\(.*\)"/\1/')
if [[ -z "$expected_version_string" ]]; then
    echo "[ERROR] Could not read VERSION_STRING from $DEFINES_H" >&2
    exit 1
fi

# Get actual version by running sil and capturing its version output.
readonly print_version_command="$SIL_BINARY -v"
# shellcheck disable=SC2155
readonly print_version_command_output=$(eval "$print_version_command")
readonly exe_version_string=${print_version_command_output#"Sil-Q version "}

if [[ "$exe_version_string" != "$expected_version_string" ]]; then
    echo "[ERROR] Version mismatch" >&2
    echo -e "  Expected: $expected_version_string\t(from $DEFINES_H)" >&2
    echo -e "  Actual:   $exe_version_string\t(from $print_version_command)" >&2
    exit 1
fi

###
### Test 2: Check Sil-Q-version.txt against src/defines.h
###

version_line=$(grep '^Sil-Q version:' "$VERSION_FILE")
if [[ -z "$version_line" ]]; then
    echo "[ERROR] Could not read 'Sil-Q version:' line from $VERSION_FILE" >&2
    exit 1
fi

# Extract VERSION_STRING
# shellcheck disable=SC2155
readonly file_version_string=$(echo "$version_line" | sed 's/^Sil-Q version:[[:space:]]*//' | sed 's/[[:space:]]*(.*//')
if [[ "$file_version_string" != "$expected_version_string" ]]; then
    echo "[ERROR] VERSION_STRING mismatch in $VERSION_FILE" >&2
    echo -e "  Expected: $expected_version_string\t(from $DEFINES_H)" >&2
    echo -e "  Actual:   $file_version_string\t(from $VERSION_FILE)" >&2
    exit 1
fi

# Extract a.b.c.d version and match against VERSION_MAJOR.MINOR.PATCH.EXTRA.
# shellcheck disable=SC2155
readonly actual_numeric=$(echo "$version_line" | sed -n 's/.*(\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\)).*/\1/p')
expected_major=$(grep '#define VERSION_MAJOR ' "$DEFINES_H" | sed 's/.*MAJOR[[:space:]]*//')
expected_minor=$(grep '#define VERSION_MINOR ' "$DEFINES_H" | sed 's/.*MINOR[[:space:]]*//')
expected_patch=$(grep '#define VERSION_PATCH ' "$DEFINES_H" | sed 's/.*PATCH[[:space:]]*//')
expected_extra=$(grep '#define VERSION_EXTRA ' "$DEFINES_H" | sed 's/.*EXTRA[[:space:]]*//')
readonly expected_numeric="${expected_major}.${expected_minor}.${expected_patch}.${expected_extra}"

if [[ "$actual_numeric" != "$expected_numeric" ]]; then
    echo "[ERROR] Numeric version mismatch in $VERSION_FILE" >&2
    echo -e "  Expected: $expected_numeric\t(from $DEFINES_H)" >&2
    echo -e "  Actual:   $actual_numeric\t(from $VERSION_FILE)" >&2
    exit 1
fi

# All tests passed.
echo "[SUCCESS] All tests passed"
exit 0
