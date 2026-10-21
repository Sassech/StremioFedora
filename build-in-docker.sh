#!/bin/bash
set -euo pipefail

SCRIPT_DIR="/workspace"
OUTPUT_DIR="$SCRIPT_DIR/output"
TMP_BUILD="/tmp/build"
BUILD_LOG="/tmp/build.log"

mkdir -p "$TMP_BUILD" "$OUTPUT_DIR"

cd "$TMP_BUILD"

# Limpiar cualquier build previo
if [ -d "stremio-shell" ]; then
    rm -rf stremio-shell
fi

echo "Downloading Stremio source code..."
if ! git clone --depth 1 --single-branch --recurse-submodules https://github.com/Stremio/stremio-shell.git >> "$BUILD_LOG" 2>&1; then
    echo "Error downloading Stremio source"
    tail -n 20 "$BUILD_LOG"
    exit 1
fi

cd stremio-shell

# Si existe release.makefile, reemplazar qmake por qmake-qt5
if [ -f release.makefile ]; then
    sed -i 's/qmake/qmake-qt5/g' release.makefile 2>/dev/null || true
fi

echo "Compiling Stremio..."
if command -v qmake-qt5 &> /dev/null; then
    qmake-qt5 >> "$BUILD_LOG" 2>&1
elif command -v qmake &> /dev/null; then
    qmake >> "$BUILD_LOG" 2>&1
else
    echo "Error: neither qmake-qt5 nor qmake found"
    exit 1
fi

if ! make -f release.makefile >> "$BUILD_LOG" 2>&1; then
    echo "Error compiling Stremio"
    tail -n 30 "$BUILD_LOG"
    exit 1
fi

echo "Installing Stremio files..."
mkdir -p "$TMP_BUILD/fakeroot/opt/stremio"

# Tratar el contenido de release.makefile para instalar en DESTDIR
make -f release.makefile install DESTDIR="$TMP_BUILD/fakeroot" >> "$BUILD_LOG" 2>&1 || echo "Warning: make install DESTDIR failed, falling back to manual copy" >> "$BUILD_LOG"

if [ -d "$TMP_BUILD/fakeroot/opt/stremio" ]; then
    mv "$TMP_BUILD/fakeroot/opt/stremio" "$TMP_BUILD/opt-stremio"
else
    echo "Warning: DESTDIR install did not populate /opt/stremio, using manual copy only" >> "$BUILD_LOG"
    mkdir -p "$TMP_BUILD/opt-stremio"
fi

# Manualmente copiar archivos binarios y recursos si no se instalaron correctamente
if [ -f "server.js" ]; then
    cp server.js "$TMP_BUILD/opt-stremio/"
fi

if [ -f "smartcode-stremio.desktop" ]; then
    cp smartcode-stremio.desktop "$TMP_BUILD/opt-stremio/"
fi

if [ -d "icons" ]; then
    cp -r icons "$TMP_BUILD/opt-stremio/"
fi

shopt -s nullglob
for file in *.png *.svg; do
    cp "$file" "$TMP_BUILD/opt-stremio/"
done
shopt -u nullglob

# Crea un wrapper para la aceleración de hardware VA-API
# Sobreescribe el driver en runtime: LIBVA_DRIVER_NAME=radeonsi stremio
#   Intel (default): iHD    AMD: radeonsi    NVIDIA: nouveau
cat > "$TMP_BUILD/opt-stremio/stremio-wrapper" << 'WRAPPER'
#!/bin/bash
export LIBVA_DRIVER_NAME="${LIBVA_DRIVER_NAME:-iHD}"
exec /opt/stremio/stremio "$@"
WRAPPER
chmod +x "$TMP_BUILD/opt-stremio/stremio-wrapper"

echo "Verifying streaming server..."
mkdir -p ~/.stremio-server
cd "$TMP_BUILD/opt-stremio"
node server.js > /tmp/server_test.log 2>&1 &
SERVER_PID=$!

POLL_ATTEMPTS=30
SERVER_READY=false
for ((i = 1; i <= POLL_ATTEMPTS; i++)); do
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "Error: streaming server crashed during startup (attempt $i)"
        cat /tmp/server_test.log
        exit 1
    fi
    if grep -q "EngineFS server started" /tmp/server_test.log 2>/dev/null; then
        SERVER_READY=true
        echo "Streaming server verified successfully"
        break
    fi
    sleep 1
done

if [ "$SERVER_READY" != "true" ]; then
    echo "Error: streaming server did not report ready within ${POLL_ATTEMPTS}s"
    cat /tmp/server_test.log
    kill "$SERVER_PID" 2>/dev/null || true
    exit 1
fi

kill "$SERVER_PID" 2>/dev/null || true
wait "$SERVER_PID" 2>/dev/null || true
cd "$SCRIPT_DIR"

cd "$TMP_BUILD"

# Genera el archivo spec para rpmbuild
RPM_TOP_DIR="$TMP_BUILD/rpmbuild"
RPM_NAME="stremio"
echo "Fetching latest Stremio version..."
VERSION="$(curl -s https://api.github.com/repos/Stremio/stremio-shell/releases/latest 2>/dev/null \
    | grep -oP '"tag_name":\s*"v?\K[^"]+')"
if [ -z "$VERSION" ]; then
    echo "Warning: could not fetch latest version from GitHub API, using fallback 4.4.107"
    VERSION="4.4.107"
fi
echo "Building Stremio version: $VERSION"
RPM_ARCH="${RPM_ARCH:-$(uname -m)}"

mkdir -p "$RPM_TOP_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

echo "Creating RPM package..."

SOURCE_DIR="$RPM_TOP_DIR/SOURCES"
mkdir -p "$SOURCE_DIR"
tar -czf "$SOURCE_DIR/${RPM_NAME}-${VERSION}.tar.gz" -C "$TMP_BUILD" opt-stremio 2>/dev/null

/workspace/generate-spec.sh "$RPM_NAME" "$VERSION" "$RPM_TOP_DIR/SPECS/${RPM_NAME}.spec" "$TMP_BUILD/opt-stremio" "$RPM_ARCH" >> "$BUILD_LOG" 2>&1

if ! rpmbuild --define "_topdir ${RPM_TOP_DIR}" -bb "$RPM_TOP_DIR/SPECS/${RPM_NAME}.spec" >> "$BUILD_LOG" 2>&1; then
    echo "Error creating RPM package"
    tail -n 30 "$BUILD_LOG"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
RPM_FILE=$(find "$RPM_TOP_DIR/RPMS" -name "${RPM_NAME}-${VERSION}-1*.rpm" -type f 2>/dev/null | head -n 1)
if [ -z "$RPM_FILE" ]; then
    echo "Error: RPM file not found in $RPM_TOP_DIR/RPMS/"
    find "$RPM_TOP_DIR/RPMS" -type f 2>/dev/null || true
    exit 1
fi
cp "$RPM_FILE" "$OUTPUT_DIR/"

echo "Verifying RPM package..."
if ! rpm -qpl "$OUTPUT_DIR/$(basename "$RPM_FILE")" &>/dev/null; then
    echo "Error: RPM package is empty or invalid"
    exit 1
fi
echo "RPM package verified: $(basename "$RPM_FILE")"

rm -rf "$TMP_BUILD" "$BUILD_LOG" 2>/dev/null || true

echo "RPM package created successfully"
