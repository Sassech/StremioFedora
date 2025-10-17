#!/bin/bash
# Stremio Installer for Fedora 30+ with RPM generation

set -e  # Exit on error

# ============================================
# Configuration
# ============================================
VERSION="4.4.107"
RPM_NAME="stremio-custom"
INSTALL_PREFIX="/opt/stremio"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/stremio-shell"

clear
echo -e "\e[96m\e[40m================================\e[0m"
echo -e "\e[96m\e[40mStremio RPM Builder for Fedora\e[0m"
echo -e "\e[96m\e[40m================================\e[0m"
echo ""

# ============================================
# Install dependencies
# ============================================
dep_install() {
    echo ""
    echo -e "\e[93m\e[40m==========================\e[0m"
    echo -e "\e[93m\e[40mInstalling Dependencies\e[0m"
    echo -e "\e[93m\e[40m==========================\e[0m"
    
    sudo dnf install -y \
        nodejs wget git \
        librsvg2-devel librsvg2-tools \
        mpv-libs-devel \
        qt5-qtbase-devel qt5-qtwebengine-devel \
        qt5-qtquickcontrols qt5-qtquickcontrols2 \
        openssl-devel \
        gcc gcc-c++ make \
        glibc-devel kernel-headers binutils \
        rpm-build rpmdevtools
    
    echo "✓ Dependencies installed"
}

# ============================================
# Download Stremio source
# ============================================
main_download() {
    echo ""
    echo -e "\e[93m\e[40m===================\e[0m"
    echo -e "\e[93m\e[40mDownloading Stremio\e[0m"
    echo -e "\e[93m\e[40m===================\e[0m"
    
    cd "$SCRIPT_DIR"
    
    # Remove old source if exists
    if [ -d "$BUILD_DIR" ]; then
        echo "Removing old source directory..."
        rm -rf "$BUILD_DIR"
    fi
    
    git clone --recurse-submodules https://github.com/Stremio/stremio-shell.git
    echo "✓ Source code downloaded"
}

# ============================================
# Patch files
# ============================================
patching() {
    echo ""
    echo -e "\e[93m\e[40m==============\e[0m"
    echo -e "\e[93m\e[40mPatching files\e[0m"
    echo -e "\e[93m\e[40m==============\e[0m"
    
    sed -i 's/qmake/qmake-qt5/g' release.makefile
    echo "✓ Files patched"
}

# ============================================
# Clean previous installation (external script)
# ============================================
clean_previous_install() {
    if [ -x "$SCRIPT_DIR/stremio-previous-installation.sh" ]; then
        "$SCRIPT_DIR/stremio-previous-installation.sh"
    else
        echo -e "\e[91m✗ stremio-previous-installation.sh not found or not executable\e[0m"
        return 1
    fi
}

# ============================================
# Compile and install Stremio
# ============================================
compile_install() {
    echo ""
    echo -e "\e[93m\e[40m================================\e[0m"
    echo -e "\e[93m\e[40mCompiling and installing Stremio\e[0m"
    echo -e "\e[93m\e[40m================================\e[0m"
    
    qmake-qt5
    make -f release.makefile
    sudo make -f release.makefile install
    sudo ./dist-utils/common/postinstall
    
    echo "✓ Stremio compiled and installed"
}

# ============================================
# Create RPM package
# ============================================
create_rpm() {
    echo ""
    echo -e "\e[93m\e[40m===================\e[0m"
    echo -e "\e[93m\e[40mCreating RPM package\e[0m"
    echo -e "\e[93m\e[40m===================\e[0m"
    
    # Check if Stremio is installed
    if [ ! -d "/opt/stremio" ]; then
        echo -e "\e[91m✗ Stremio not found at /opt/stremio\e[0m"
        return 1
    fi
    
    # Setup RPM build directory
    local RPM_TOP_DIR="$SCRIPT_DIR/rpmbuild"
    local BUILD_NAME="${RPM_NAME}-${VERSION}-build"
    
    mkdir -p "$RPM_TOP_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    mkdir -p "$RPM_TOP_DIR/BUILD/$BUILD_NAME"
    
    # Generate spec file
    echo "Generating spec file..."
    if [ ! -x "$SCRIPT_DIR/generate-spec.sh" ]; then
        chmod +x "$SCRIPT_DIR/generate-spec.sh"
    fi
    
    "$SCRIPT_DIR/generate-spec.sh" "${RPM_NAME}" "${VERSION}" "$RPM_TOP_DIR/SPECS/${RPM_NAME}.spec"
    
    # Build RPM
    echo "Building RPM..."
    rpmbuild --define "_topdir ${RPM_TOP_DIR}" -bb "$RPM_TOP_DIR/SPECS/${RPM_NAME}.spec"
    
    # Copy RPM to current directory
    cp "$RPM_TOP_DIR/RPMS/x86_64/${RPM_NAME}-${VERSION}-1"*.rpm "$SCRIPT_DIR/" 2>/dev/null
    
    echo "✓ RPM package created"
    ls -lh "$SCRIPT_DIR"/${RPM_NAME}-${VERSION}-*.rpm
}

# ============================================
# Cleanup temporary files (external script)
# ============================================
cleanup() {
    if [ -x "$SCRIPT_DIR/stremio-cleanup-build.sh" ]; then
        "$SCRIPT_DIR/stremio-cleanup-build.sh"
    else
        echo -e "\e[91m✗ stremio-cleanup-build.sh not found or not executable\e[0m"
        return 1
    fi
}

# ============================================
# Main execution
# ============================================


# Make all scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

# Install codecs first
if [ -x "$SCRIPT_DIR/stremio-install-codecs.sh" ]; then
    "$SCRIPT_DIR/stremio-install-codecs.sh"
else
    echo -e "\e[91m✗ stremio-install-codecs.sh not found\e[0m"
    echo "Codecs are required for video playback!"
    exit 1
fi

# Run installation steps
dep_install
main_download

cd "$BUILD_DIR" || exit 1
patching
clean_previous_install
compile_install
cd "$SCRIPT_DIR" || exit 1

create_rpm
cleanup

# ============================================
# Final summary
# ============================================
echo ""
echo -e "\e[92m\e[40m================================\e[0m"
echo -e "\e[92m\e[40m✓ Build Complete!\e[0m"
echo -e "\e[92m\e[40m================================\e[0m"
echo ""
echo -e "\e[92mRPM package created:\e[0m"
echo "  $SCRIPT_DIR/${RPM_NAME}-${VERSION}-1*.rpm"
echo ""
echo -e "\e[93mTo install Stremio:\e[0m"
echo -e "\e[96m  sudo dnf install ./${RPM_NAME}-${VERSION}-1*.rpm\e[0m"
echo ""
echo -e "\e[93mTo uninstall (manual installations):\e[0m"
echo -e "\e[96m  ./stremio-cleanup-build.sh\e[0m"
echo ""
read -n 1 -s -r -p "Press any key to exit"
exit 0