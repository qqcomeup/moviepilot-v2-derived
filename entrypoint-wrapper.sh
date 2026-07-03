#!/bin/bash
set -euo pipefail

src="/entrypoint.sh"
patched="/tmp/entrypoint.patched.sh"
wrapper_start_ns="$(date +%s%N)"

elapsed_ms() {
  echo $(( ($(date +%s%N) - "$1") / 1000000 ))
}

if [ ! -f "$src" ]; then
  echo "[ERROR] upstream entrypoint not found: $src" >&2
  exit 1
fi

echo "[INFO] [DERIVED] entrypoint-wrapper 开始，使用上游脚本: ${src}"

python3 - "$src" "$patched" <<'PY'
from pathlib import Path
import re
import sys

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
text = src.read_text()

replacements = {
    'groupmod -o -g "${PGID}" moviepilot':
        '__mp_t_groupmod=$(date +%s%N)\n: # skipped groupmod; moviepilot group is baked into derived image',
    'usermod -o -u "${PUID}" moviepilot':
        ': # skipped usermod; moviepilot user is baked into derived image\nINFO "[DERIVED] groupmod/usermod 已跳过，耗时: $(( ($(date +%s%N) - __mp_t_groupmod) / 1000000 )) ms"',
}

optional_replacements = {
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

for old, new in optional_replacements.items():
    if old in text:
        text = text.replace(old, new)

if missing:
    print("[WARN] Some upstream entrypoint patterns were not found:", file=sys.stderr)
    for item in missing:
        print(f"[WARN]   {item}", file=sys.stderr)

lines = []
skipped_app_path = False
skipped_public_path = False
for line in text.splitlines():
    if re.match(r'^\s*/app\s*\\?\s*$', line):
        skipped_app_path = True
        continue
    if re.match(r'^\s*/public\s*\\?\s*$', line):
        skipped_public_path = True
        continue
    lines.append(line)
text = "\n".join(lines) + "\n"

marker = 'chown moviepilot:moviepilot /etc/hosts /tmp'
if skipped_app_path or skipped_public_path:
    skipped = []
    if skipped_app_path:
        skipped.append('/app')
    if skipped_public_path:
        skipped.append('/public')
    message = ', '.join(skipped)
    text = text.replace(
        marker,
        f'INFO "[DERIVED] chown {message} 已跳过，权限已在派生镜像构建阶段处理"\\n{marker}',
        1,
    )

dst.write_text(text)
PY

chmod +x "$patched"
echo "[INFO] [DERIVED] entrypoint-wrapper patch 耗时: $(elapsed_ms "$wrapper_start_ns") ms"
exec "$patched" "$@"
