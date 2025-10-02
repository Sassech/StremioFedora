#!/bin/bash
# Stremio Codec Installer - Installs RPM Fusion and multimedia codecs

set -e

clear
echo -e "\e[96m================================\e[0m"
echo -e "\e[96mStremio Codec Installer\e[0m"
echo -e "\e[96m================================\e[0m"
echo ""

# Detect Fedora version
FEDORA_VERSION=$(rpm -E %fedora)
echo "Fedora version: $FEDORA_VERSION"
echo ""

# Install RPM Fusion Non-Free
echo "[1/3] Installing RPM Fusion Non-Free..."
if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm
fi
echo "✓ RPM Fusion installed"

# Install FFmpeg and MPV
echo ""
echo "[2/3] Installing FFmpeg and MPV..."
sudo dnf install -y --allowerasing ffmpeg mpv
echo "✓ Codecs installed"

# Install hardware acceleration
echo ""
echo "[3/3] Installing hardware acceleration..."
sudo dnf install -y gstreamer1-vaapi libva-utils
echo "✓ Hardware acceleration installed"

# Summary
echo ""
echo -e "\e[92m================================\e[0m"
echo -e "\e[92m✓ Installation Complete!\e[0m"
echo -e "\e[92m================================\e[0m"
echo ""