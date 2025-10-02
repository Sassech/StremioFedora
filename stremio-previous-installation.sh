#!/bin/bash
# Clean previous Stremio installation script

set -e  # Exit on error

echo ""
echo -e "\e[93m\e[40m=============================\e[0m"
echo -e "\e[93m\e[40mCleaning previous installation\e[0m"
echo -e "\e[93m\e[40m=============================\e[0m"

cleaned=false

if [ -d "/opt/stremio" ]; then
    sudo rm -rf /opt/stremio
    echo "✓ Removed /opt/stremio"
    cleaned=true
fi

if [ -L "/usr/bin/stremio" ] || [ -f "/usr/bin/stremio" ]; then
    sudo rm -f /usr/bin/stremio
    echo "✓ Removed /usr/bin/stremio"
    cleaned=true
fi

if [ -f "/usr/share/applications/smartcode-stremio.desktop" ]; then
    sudo rm -f /usr/share/applications/smartcode-stremio.desktop
    echo "✓ Removed desktop entry (/usr/share/applications)"
    if command -v update-desktop-database &> /dev/null; then
        sudo update-desktop-database /usr/share/applications 2>/dev/null
    fi
    cleaned=true
fi

if [ -f "/usr/local/share/applications/smartcode-stremio.desktop" ]; then
    sudo rm -f /usr/local/share/applications/smartcode-stremio.desktop
    echo "✓ Removed desktop entry (/usr/local/share/applications)"
    if command -v update-desktop-database &> /dev/null; then
        sudo update-desktop-database /usr/local/share/applications 2>/dev/null
    fi
    cleaned=true
fi

if [ "$cleaned" = false ]; then
    echo "⊘ No previous installation found"
fi
