#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
python3 tools/qa.py
python3 tools/release_check.py
printf '%s\n' 'STARFALL RELEASE GATE: STATIC CHECKS PASS'
printf '%s\n' 'Native LÖVE 11.5 and browser/portal smoke tests remain required before submission.'
