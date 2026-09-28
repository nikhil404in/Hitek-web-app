#!/usr/bin/env bash
# =================================================================
# Start API Script for Kali Linux / Debian
# Instant Phone Search API
# =================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PORT="${PORT:-8000}"
HOST="${HOST:-0.0.0.0}"

echo "============================================================="
echo "  Instant Phone Search API (Parquet Engine)"
echo "  Web UI   : http://127.0.0.1:${PORT}/ui"
echo "  API Docs : http://127.0.0.1:${PORT}/docs"
echo "============================================================="

# Free port 8000 if occupied
if command -v fuser >/dev/null 2>&1; then
    fuser -k "${PORT}/tcp" 2>/dev/null || true
elif command -v lsof >/dev/null 2>&1; then
    PID=$(lsof -t -i:"${PORT}" 2>/dev/null || true)
    if [ -n "$PID" ]; then
        echo "[*] Killing existing process on port ${PORT} (PID $PID)..."
        kill -9 $PID 2>/dev/null || true
    fi
fi

# Detect valid Python binary:
PYTHON_BIN=""
if [ -f "$SCRIPT_DIR/.venv_path" ]; then
    SAVED_VENV="$(cat "$SCRIPT_DIR/.venv_path" 2>/dev/null || true)"
    if [ -x "$SAVED_VENV/bin/python3" ]; then
        PYTHON_BIN="$SAVED_VENV/bin/python3"
    fi
fi

if [ -z "$PYTHON_BIN" ] && [ -x "$SCRIPT_DIR/venv/bin/python3" ]; then
    PYTHON_BIN="$SCRIPT_DIR/venv/bin/python3"
elif [ -z "$PYTHON_BIN" ] && [ -x "$HOME/.venvs/phonesearch/bin/python3" ]; then
    PYTHON_BIN="$HOME/.venvs/phonesearch/bin/python3"
elif [ -z "$PYTHON_BIN" ] && command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
else
    PYTHON_BIN="python"
fi

echo "[*] Starting server using ${PYTHON_BIN}..."
exec "$PYTHON_BIN" main.py
