#!/bin/bash
set -euo pipefail


SCRIPT_DIR="/workspace"
# We will copy the final RPM(s) directly into the repo root (/workspace)
OUTPUT_DIR="$SCRIPT_DIR"

TMP_BUILD="/tmp/build"

mkdir -p "$TMP_BUILD"

echo "Running Stremio build inside container (working in $TMP_BUILD)..."

# Ensure scripts are executable inside the image copy (no new files created)
chmod +x /workspace/*.sh 2>/dev/null || true

cd "$TMP_BUILD"

# Download Stremio source into tmp
if [ -d "stremio-shell" ]; then
    echo "Removing old tmp source directory..."
    rm -rf stremio-shell
fi
git clone --recurse-submodules https://github.com/Stremio/stremio-shell.git

cd stremio-shell

# Patch for qmake
if [ -f release.makefile ]; then
    sed -i 's/qmake/qmake-qt5/g' release.makefile || true
fi

# Build
if command -v qmake-qt5 &> /dev/null; then
    qmake-qt5
else
    echo "qmake-qt5 not found; attempting qmake"
    qmake || true
fi
make -f release.makefile || true

# Install into a fake root under tmp
echo "Installing into fake root inside tmp..."
mkdir -p "$TMP_BUILD/fakeroot/opt/stremio"
make -f release.makefile install DESTDIR="$TMP_BUILD/fakeroot" || true
if [ -d "$TMP_BUILD/fakeroot/opt/stremio" ]; then
    mv "$TMP_BUILD/fakeroot/opt/stremio" "$TMP_BUILD/opt-stremio" || true
fi

cd "$TMP_BUILD"

# Generate spec and build RPM in tmp
RPM_TOP_DIR="$TMP_BUILD/rpmbuild"
RPM_NAME="${RPM_NAME:-stremio-custom}"
VERSION="${VERSION:-4.4.107}"

mkdir -p "$RPM_TOP_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Use the generate-spec.sh from the image copy (which was baked into the image at build time)
/workspace/generate-spec.sh "$RPM_NAME" "$VERSION" "$RPM_TOP_DIR/SPECS/${RPM_NAME}.spec"

# Copy installation into buildroot expected by spec by creating /opt/stremio inside a temp root
BUILDROOT="$RPM_TOP_DIR/BUILDROOT"
rm -rf "$BUILDROOT"
mkdir -p "$BUILDROOT/opt"
cp -r "$TMP_BUILD/opt-stremio" "$BUILDROOT/opt/stremio"

rpmbuild --define "_topdir ${RPM_TOP_DIR}" -bb "$RPM_TOP_DIR/SPECS/${RPM_NAME}.spec"

# Copy produced RPM(s) to the repository root mounted at /workspace
cp "$RPM_TOP_DIR/RPMS/x86_64/${RPM_NAME}-${VERSION}-1"*.rpm "$OUTPUT_DIR/" 2>/dev/null || true

echo "Build finished. RPMs (if created) are in repo root: $OUTPUT_DIR"
