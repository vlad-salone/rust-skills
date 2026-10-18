#!/usr/bin/env bash
# Thin wrapper: runs scripts/validate.py with whichever Python is on PATH.
# On Windows you can skip this and run:  python scripts\validate.py
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if command -v python3 >/dev/null 2>&1; then PY=python3; else PY=python; fi
exec "$PY" -I "$ROOT/scripts/validate.py" "$ROOT"
