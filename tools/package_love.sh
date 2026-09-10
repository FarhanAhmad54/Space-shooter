#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/Starfall-Vengeance.love}"
cd "$ROOT"
rm -f "$OUT"

# LÖVE archives are ZIPs. Keep the runtime at the archive root and include only
# files required by the native game; web hosting files are packaged separately.
zip -qr "$OUT" \
  main.lua conf.lua *.lua assets sounds \
  -x '.git/*' -x '*.love' -x 'Starfall-Vengeance*' \
  -x 'tools/*' -x 'tests/*' -x 'docs/*'

echo "Created $OUT"
