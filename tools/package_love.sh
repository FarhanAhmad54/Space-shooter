#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/Starfall-Vengeance.love}"
cd "$ROOT"
rm -f "$OUT"

# LÖVE archives are ZIPs: package the runtime at the archive root while excluding
# repository metadata, generated build artifacts and the package itself.
zip -qr "$OUT" \
  main.lua conf.lua *.lua assets sounds web \
  -x '.git/*' -x '*.love' -x 'Starfall-Vengeance*' \
  -x 'tools/*' -x 'tests/*' -x 'docs/*'

echo "Created $OUT"
