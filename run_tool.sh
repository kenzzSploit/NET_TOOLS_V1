#!/bin/bash
# ============================================================
#  Network Toolkit - Linux/macOS Launcher
#  Jalankan: chmod +x run_tool.sh && ./run_tool.sh
# ============================================================

# Warna terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${GREEN}  Network Toolkit Launcher${NC}"
echo "  ─────────────────────────────────"

# Cek Python3
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}  [ERROR] Python3 tidak ditemukan!${NC}"
    echo "  Install:"
    echo "    Debian/Ubuntu : sudo apt install python3"
    echo "    macOS         : brew install python3"
    exit 1
fi

PY_VER=$(python3 --version 2>&1)
echo -e "  ${GREEN}✓ ${PY_VER}${NC}"

# Cek Ruby
if ! command -v ruby &> /dev/null; then
    echo -e "${YELLOW}  ⚠ Ruby tidak ditemukan. Fitur Ruby (11-20) tidak tersedia.${NC}"
    echo "  Install:"
    echo "    Debian/Ubuntu : sudo apt install ruby"
    echo "    macOS         : brew install ruby"
    echo ""
else
    RUBY_VER=$(ruby --version 2>&1)
    echo -e "  ${GREEN}✓ ${RUBY_VER}${NC}"
fi

echo ""

# Pindah ke direktori script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Jalankan toolkit
python3 main.py
