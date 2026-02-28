#!/bin/sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_PATH="${PROJECT_DIR}/.swiftlint.yml"

# Find SwiftLint in PATH first, then common Homebrew locations.
if command -v swiftlint >/dev/null 2>&1; then
    SWIFTLINT_BIN="$(command -v swiftlint)"
elif [ -x "/opt/homebrew/bin/swiftlint" ]; then
    SWIFTLINT_BIN="/opt/homebrew/bin/swiftlint"
elif [ -x "/usr/local/bin/swiftlint" ]; then
    SWIFTLINT_BIN="/usr/local/bin/swiftlint"
else
    echo "warning: SwiftLint not installed. Install via Homebrew: brew install swiftlint"
    exit 0
fi

if [ ! -f "${CONFIG_PATH}" ]; then
    echo "warning: SwiftLint config not found at ${CONFIG_PATH}"
    exit 0
fi

echo "Running SwiftLint with config: ${CONFIG_PATH}"
"${SWIFTLINT_BIN}" lint --config "${CONFIG_PATH}"
SWIFTLINT_EXIT_CODE=$?

# Keep local builds green by default; enable strict mode in CI if needed.
# Set SWIFTLINT_STRICT=1 to make lint failures break the build.
if [ "${SWIFTLINT_EXIT_CODE}" -ne 0 ]; then
    if [ "${SWIFTLINT_STRICT:-0}" = "1" ]; then
        exit "${SWIFTLINT_EXIT_CODE}"
    fi
    echo "warning: SwiftLint found issues (exit ${SWIFTLINT_EXIT_CODE}). Set SWIFTLINT_STRICT=1 to fail build."
    exit 0
fi
