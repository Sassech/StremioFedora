#!/bin/bash
# Cleanup script for Stremio build process

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/stremio-shell"

echo ""
echo -e "\e[93m\e[40m=============\e[0m"
echo -e "\e[93m\e[40mCleaning up\e[0m"
echo -e "\e[93m\e[40m=============\e[0m"

# ============================================
# Remove build directories
# ============================================
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
    echo "✓ Removed stremio-shell directory"
fi

if [ -d "$SCRIPT_DIR/rpmbuild" ]; then
    rm -rf "$SCRIPT_DIR/rpmbuild"
    echo "✓ Removed rpmbuild directory"
fi

# ============================================
# Remove manual installation
# ============================================
if [ -d "/opt/stremio" ]; then
    sudo rm -rf /opt/stremio
    echo "✓ Removed /opt/stremio"
fi

if [ -L "/usr/bin/stremio" ] || [ -f "/usr/bin/stremio" ]; then
    sudo rm -f /usr/bin/stremio
    echo "✓ Removed /usr/bin/stremio"
fi

if [ -f "/usr/share/applications/smartcode-stremio.desktop" ]; then
    sudo rm -f /usr/share/applications/smartcode-stremio.desktop
    echo "✓ Removed desktop entry (/usr/share/applications)"
    if command -v update-desktop-database &> /dev/null; then
        sudo update-desktop-database /usr/share/applications 2>/dev/null
    fi
fi

if [ -f "/usr/local/share/applications/smartcode-stremio.desktop" ]; then
    sudo rm -f /usr/local/share/applications/smartcode-stremio.desktop
    echo "✓ Removed desktop entry (/usr/local/share/applications)"
    if command -v update-desktop-database &> /dev/null; then
        sudo update-desktop-database /usr/local/share/applications 2>/dev/null
    fi
fi

# ============================================
# Remove build dependencies (optional)
# ============================================
echo ""
echo -e "\e[93m\e[40m================================\e[0m"
echo -e "\e[93m\e[40mRemove build dependencies?\e[0m"
echo -e "\e[93m\e[40m================================\e[0m"
echo ""
echo "The RPM has been created. Build dependencies are no longer needed."
echo -e "\e[91mWARNING: Only remove if you don't need these for other development work.\e[0m"
echo ""
read -p "Remove build dependencies? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    BUILD_DEPS=(
        "librsvg2-devel" "librsvg2-tools" "mpv-libs-devel"
        "qt5-qtbase-devel" "qt5-qtwebengine-devel"
        "qt5-qtquickcontrols" "qt5-qtquickcontrols2"
        "openssl-devel" "gcc" "gcc-c++" "make"
        "glibc-devel" "kernel-headers" "binutils"
        "rpm-build" "rpmdevtools"
    )
    
    echo "Removing build dependencies..."
    sudo dnf remove "${BUILD_DEPS[@]}" -y
    
    echo ""
    echo "Removing orphaned dependencies..."
    sudo dnf autoremove -y
    
    echo "✓ Build dependencies removed"
else
    echo "⊘ Keeping build dependencies"
fi

echo ""
echo "✓ Cleanup complete"
