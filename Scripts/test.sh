#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$TASK_ROOT/.build"
bash "$TASK_ROOT/Scripts/prepare-build.sh"
swiftc -vfsoverlay "$TASK_ROOT/.build/swift-overlay.json" -swift-version 5 -module-cache-path "$TASK_ROOT/.build/module-cache" \
    "$TASK_ROOT/Sources/Core.swift" "$TASK_ROOT/Tests/CoreTests.swift" -o "$TASK_ROOT/.build/core-tests"
"$TASK_ROOT/.build/core-tests"
