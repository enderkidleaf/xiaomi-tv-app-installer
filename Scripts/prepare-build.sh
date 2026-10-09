#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$TASK_ROOT/.build"
python3 - "$TASK_ROOT" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
directory = pathlib.Path('/Library/Developer/CommandLineTools/usr/include/swift')
roots = []
# Some CLT upgrades leave two identical SwiftBridging declarations. Hide only the
# redundant legacy map through a compiler VFS overlay; never alter the system SDK.
if (directory / 'module.modulemap').exists() and (directory / 'bridging.modulemap').exists():
    if all('module SwiftBridging' in (directory / name).read_text() for name in ['module.modulemap', 'bridging.modulemap']):
        empty = root / '.build/empty.modulemap'
        empty.write_text('// Redundant legacy map hidden for this build only.\n')
        roots.append({'type': 'file', 'name': str(directory / 'module.modulemap'), 'external-contents': str(empty)})
(root / '.build/swift-overlay.json').write_text(json.dumps({'version': 0, 'roots': roots}))
PY
