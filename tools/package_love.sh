#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/Starfall-Vengeance.love}"
cd "$ROOT"
rm -f "$OUT"
zip -qr "$OUT" . -x '.git/*' -x 'Starfall-Vengeance.love' -x '*.love'
echo "Created $OUT"
