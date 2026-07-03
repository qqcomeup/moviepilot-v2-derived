#!/bin/bash
set -euo pipefail

src="/entrypoint.sh"
patched="/tmp/entrypoint.patched.sh"

if [ ! -f "$src" ]; then
  echo "[ERROR] upstream entrypoint not found: $src" >&2
  exit 1
fi

python3 - "$src" "$patched" <<'PY'
from pathlib import Path
import re
import sys

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
text = src.read_text()

replacements = {
    'groupmod -o -g "${PGID}" moviepilot':
        ': # skipped groupmod; moviepilot group is baked into derived image',
    'usermod -o -u "${PUID}" moviepilot':
        ': # skipped usermod; moviepilot user is baked into derived image',
    'chown -R moviepilot:moviepilot /app':
        ': # skipped chown /app; ownership is baked into derived image',
    'chown -R moviepilot:moviepilot /public':
        ': # skipped chown /public; ownership is baked into derived image',
    'chown -R moviepilot:moviepilot /app/app/plugins':
        ': # skipped chown /app/app/plugins; ownership is baked into derived image',
}

missing = []
for old, new in replacements.items():
    if old in text:
        text = text.replace(old, new)
    else:
        missing.append(old)

if missing:
    print("[WARN] Some upstream entrypoint patterns were not found:", file=sys.stderr)
    for item in missing:
        print(f"[WARN]   {item}", file=sys.stderr)

lines = []
for line in text.splitlines():
    if re.match(r'^\s*/app\s*\\?\s*$', line):
        lines.append(': # skipped chown /app path entry; ownership is baked into derived image')
        continue
    if re.match(r'^\s*/public\s*\\?\s*$', line):
        lines.append(': # skipped chown /public path entry; ownership is baked into derived image')
        continue
    lines.append(line)
text = "\n".join(lines) + "\n"

dst.write_text(text)
PY

chmod +x "$patched"
exec "$patched" "$@"
