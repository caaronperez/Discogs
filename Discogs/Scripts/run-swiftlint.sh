#!/bin/sh

if command -v swiftlint >/dev/null 2>&1; then
    swiftlint --config "$SRCROOT/.swiftlint.yml"
else
    echo "warning: SwiftLint not installed. Install via Homebrew: brew install swiftlint"
fi
