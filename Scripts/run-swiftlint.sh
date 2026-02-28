#!/bin/sh

# Xcode Run Script expects this path:
#   $SRCROOT/Scripts/run-swiftlint.sh
# Real script lives under Discogs/Scripts.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REAL_SCRIPT="${SCRIPT_DIR}/../Discogs/Scripts/run-swiftlint.sh"

if [ ! -f "${REAL_SCRIPT}" ]; then
    echo "warning: SwiftLint script not found at ${REAL_SCRIPT}"
    exit 0
fi

/bin/sh "${REAL_SCRIPT}"
