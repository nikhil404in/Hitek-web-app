#!/usr/bin/env bash
# =================================================================
# Setup script for Kali Linux / Debian
# Instant Phone Search API & Parquet Importer
# =================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==============================================================="
echo "   Setting up Instant Phone Search API on Kali Linux"
echo "==============================================================="

# 1. Update and install required system packages
echo "[*] Step 1: Checking and installing system packages (apt)..."
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y python3 python3-pip python3-venv build-essential curl
else
    echo "[!] apt-get not found, skipping system package installation."
fi

# 2. Check and fix Python Virtual Environment
echo "[*] Step 2: Preparing Python environment..."

# If an existing venv is broken (copied from Windows/different path), delete it
if [ -d "venv" ]; then
    if ! venv/bin/python3 --version >/dev/null 2>&1; then
        echo "[!] Existing venv is invalid or was copied from Windows. Deleting old venv..."
        rm -rf venv
    fi
fi

VENV_PATH="$SCRIPT_DIR/venv"
USE_GLOBAL=false

# Try creating venv with --copies (essential for NTFS / external drives without Linux symlinks)
if [ ! -d "$VENV_PATH" ]; then
    echo "[*] Creating fresh virtual environment..."
    if python3 -m venv --copies "$VENV_PATH" 2>/dev/null && "$VENV_PATH/bin/python3" --version >/dev/null 2>&1; then
        echo "[+] Virtual environment created at $VENV_PATH"
    else
        echo "[!] Cannot create executable venv on this drive (e.g. NTFS /run/media mount)."
        echo "[*] Creating venv in home directory: $HOME/.venvs/phonesearch..."
        mkdir -p "$HOME/.venvs"
        VENV_PATH="$HOME/.venvs/phonesearch"
        rm -rf "$VENV_PATH"
        if python3 -m venv "$VENV_PATH" 2>/dev/null && "$VENV_PATH/bin/python3" --version >/dev/null 2>&1; then
            echo "[+] Virtual environment created in home: $VENV_PATH"
            echo "$VENV_PATH" > "$SCRIPT_DIR/.venv_path"
        else
            echo "[!] Fallback: Installing packages globally with --break-system-packages..."
            USE_GLOBAL=true
        fi
    fi
fi

# 3. Upgrade pip and install requirements
echo "[*] Step 3: Installing Python requirements..."
if [ "$USE_GLOBAL" = true ]; then
    pip install --upgrade pip --break-system-packages || true
    pip install -r requirements.txt --break-system-packages
else
    "$VENV_PATH/bin/pip" install --upgrade pip
    "$VENV_PATH/bin/pip" install -r requirements.txt
fi

# 4. Create .env if missing
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "[+] Created .env file from .env.example"
    fi
fi

# 5. Ensure parquet directory exists
mkdir -p "$SCRIPT_DIR/parquet"

# 6. Make start script executable
if [ -f "start_api.sh" ]; then
    chmod +x start_api.sh
fi

echo ""
echo "==============================================================="
echo "   Setup Complete!"
echo "   To start the API, run: ./start_api.sh"
echo "==============================================================="
