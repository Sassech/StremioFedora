#!/bin/bash
set -euo pipefail

SCRIPT_DIR="/workspace"
OUTPUT_DIR="$SCRIPT_DIR/output"
TMP_BUILD="/tmp/build"
BUILD_LOG="/tmp/build.log"

mkdir -p "$TMP_BUILD" "$OUTPUT_DIR"

cd "$TMP_BUILD"

# Clean old build
if [ -d "stremio-shell" ]; then
    rm -rf stremio-shell
fi

echo "Downloading Stremio source code..."
if ! git clone --recurse-submodules https://github.com/Stremio/stremio-shell.git >> "$BUILD_LOG" 2>&1; then
    echo "Error downloading Stremio source"
    tail -n 20 "$BUILD_LOG"
    exit 1
fi

cd stremio-shell

# Patch for qmake
if [ -f release.makefile ]; then
    sed -i 's/qmake/qmake-qt5/g' release.makefile 2>/dev/null || true
fi

echo "Compiling Stremio..."
if command -v qmake-qt5 &> /dev/null; then
    qmake-qt5 >> "$BUILD_LOG" 2>&1
else
    qmake >> "$BUILD_LOG" 2>&1 || true
fi

if ! make -f release.makefile >> "$BUILD_LOG" 2>&1; then
    echo "Error compiling Stremio"
    tail -n 30 "$BUILD_LOG"
    exit 1
fi

echo "Installing Stremio files..."
mkdir -p "$TMP_BUILD/fakeroot/opt/stremio"

# First try with DESTDIR (this will get the binary)
make -f release.makefile install DESTDIR="$TMP_BUILD/fakeroot" >> "$BUILD_LOG" 2>&1 || true

# Move installed files to opt-stremio
if [ -d "$TMP_BUILD/fakeroot/opt/stremio" ]; then
    mv "$TMP_BUILD/fakeroot/opt/stremio" "$TMP_BUILD/opt-stremio" || true
else
    mkdir -p "$TMP_BUILD/opt-stremio"
fi

# Now manually copy the files that failed to install with DESTDIR
# Copy server.js if it exists
if [ -f "server.js" ]; then
    cp server.js "$TMP_BUILD/opt-stremio/"
fi

# Copy desktop file if it exists
if [ -f "smartcode-stremio.desktop" ]; then
    cp smartcode-stremio.desktop "$TMP_BUILD/opt-stremio/"
fi

# Copy icons directory if it exists
if [ -d "icons" ]; then
    cp -r icons "$TMP_BUILD/opt-stremio/"
fi

# Copy any other resources that might be needed
for file in *.png *.svg; do
    if [ -f "$file" ]; then
        cp "$file" "$TMP_BUILD/opt-stremio/" 2>/dev/null || true
    fi
done

cd "$TMP_BUILD"

# Generate spec and build RPM in tmp
RPM_TOP_DIR="$TMP_BUILD/rpmbuild"
RPM_NAME="${RPM_NAME:-stremio-custom}"
VERSION="${VERSION:-4.4.107}"

mkdir -p "$RPM_TOP_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

echo "Creating RPM package..."

# Create a tarball source that rpmbuild can use
SOURCE_DIR="$RPM_TOP_DIR/SOURCES"
mkdir -p "$SOURCE_DIR"
tar -czf "$SOURCE_DIR/${RPM_NAME}-${VERSION}.tar.gz" -C "$TMP_BUILD" opt-stremio 2>/dev/null

# Use the generate-spec.sh from the image copy
/workspace/generate-spec.sh "$RPM_NAME" "$VERSION" "$RPM_TOP_DIR/SPECS/${RPM_NAME}.spec" "$TMP_BUILD/opt-stremio" >> "$BUILD_LOG" 2>&1

if ! rpmbuild --define "_topdir ${RPM_TOP_DIR}" -bb "$RPM_TOP_DIR/SPECS/${RPM_NAME}.spec" >> "$BUILD_LOG" 2>&1; then
    echo "Error creating RPM package"
    tail -n 30 "$BUILD_LOG"
    exit 1
fi

# Create output directory and copy produced RPM(s)
mkdir -p "$OUTPUT_DIR"
if ! cp "$RPM_TOP_DIR/RPMS/x86_64/${RPM_NAME}-${VERSION}-1"*.rpm "$OUTPUT_DIR/" 2>/dev/null; then
    echo "Error: RPM file not found"
    exit 1
fi

rm -rf "$TMP_BUILD" "$BUILD_LOG" 2>/dev/null || true

echo "RPM package created successfully"
